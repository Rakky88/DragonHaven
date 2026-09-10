import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'canonical_game_connection.dart';
import 'canonical_game_intent.dart';
import 'canonical_game_intent_store.dart';
import 'canonical_game_reader.dart';
import 'canonical_game_snapshot.dart';
import 'canonical_game_snapshot_store.dart';

export 'canonical_game_connection.dart' show CanonicalGameHttpReply;

class CanonicalGameReceipt {
  const CanonicalGameReceipt._(this.requestId, this.serverRevision,
      this.replayed, this.failureCode, this._resultJson, this.stateHash);
  final String requestId;
  final int serverRevision;
  final bool replayed;
  final String? failureCode;
  final String? _resultJson;
  final String? stateHash;
  bool get succeeded => failureCode == null;
  Object? get result => _resultJson == null ? null : jsonDecode(_resultJson);

  static CanonicalGameReceipt parse(
      CanonicalGameHttpReply reply, CanonicalGameIntent intent,
      {CanonicalGameAuthority expectedAuthority =
          CanonicalGameAuthority.shadow}) {
    final body = reply.body;
    if (body is! Map<String, dynamic> ||
        body['request_id'] != intent.requestId ||
        body['replayed'] is! bool) {
      throw const CanonicalGameException('game_command_unavailable');
    }
    if (reply.status == 422 &&
        body.length == 3 &&
        _durableFailures.contains(body['error'])) {
      return CanonicalGameReceipt._(intent.requestId, intent.minimumRevision,
          body['replayed'] as bool, body['error'] as String, null, null);
    }
    if (reply.status != 200 ||
        body.length != 8 ||
        body['protocol'] != 2 ||
        body['owner_id'] != intent.ownerId ||
        body['authority_mode'] != expectedAuthority.name ||
        body['server_revision'] is! int ||
        (body['server_revision'] as int) <= 0 ||
        (body['server_revision'] as int) > 9007199254740991 ||
        body['state_sha256'] is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(body['state_sha256'] as String) ||
        !body.containsKey('result')) {
      throw const CanonicalGameException('game_command_unavailable');
    }
    final result = jsonEncode(body['result']);
    if (utf8.encode(result).length > 30000) {
      throw const CanonicalGameException('game_command_unavailable');
    }
    return CanonicalGameReceipt._(
        intent.requestId,
        body['server_revision'] as int,
        body['replayed'] as bool,
        null,
        result,
        body['state_sha256'] as String);
  }

  static const _durableFailures = {
    'game_action_unavailable',
    'game_social_claim_unavailable',
    'game_social_state_changed',
    'game_attempt_unavailable',
    'game_attempt_time_invalid',
    'game_attempt_input_limit',
    'game_attempt_incomplete',
    'game_attempt_state_changed',
    'game_attempt_in_progress',
    'invalid_command',
    'invalid_argument',
    'unknown_item',
    'special_chest_id_required',
    'unknown_adventure',
    'unknown_room',
    'game_state_reconciliation_required',
    'game_state_owner_mismatch',
    'altar_busy',
    'altar_sign_in_required',
    'altar_pending',
    'egg_not_found',
    'sinister_confirmation_required',
    'invalid_relic',
    'insufficient_materials',
    'already_known',
    'egg_reserved',
    'relic_not_owned',
    'invalid_name',
    'invalid_action',
    'egg_tagged',
    'special_egg',
    'egg_in_nest',
    'already_returned',
    'game_state_changed',
    'game_command_recovered',
  };
}

/// Detached client reconciliation; shadow snapshots cannot overwrite a live
/// game. A receipt reports an outcome, never a currency delta to apply locally.
class CanonicalGameReconciler {
  CanonicalGameReconciler(
      {required this.intents,
      required this.snapshots,
      required this.reader,
      required this.currentOwner,
      required this.sessionEpoch,
      required this.send,
      required this.applyDisplay,
      this.recoverCommands,
      this.newRecoveryId = _newRecoveryId,
      this.timeout = const Duration(seconds: 20)});
  final CanonicalGameIntentStore intents;
  final CanonicalGameSnapshotStore snapshots;
  final CanonicalGameReader reader;
  final String? Function() currentOwner;
  final int Function() sessionEpoch;
  final Future<CanonicalGameHttpReply> Function(CanonicalGameIntent) send;
  // Must check current account/epoch, reject older revisions, and durably apply
  // the absolute detached display before returning. Never add receipt rewards.
  final Future<void> Function(CanonicalGameSnapshot) applyDisplay;
  final Duration timeout;
  final Future<Object?> Function(String requestId)? recoverCommands;
  final String Function() newRecoveryId;
  static String _newRecoveryId() => const Uuid().v4();
  Future<CanonicalGameReceipt?>? _pending;
  String? _pendingOwner;
  int? _pendingEpoch;

  Future<CanonicalGameReceipt?> resume(String owner) {
    final epoch = sessionEpoch();
    if (currentOwner() != owner ||
        _pending != null &&
            (_pendingOwner != owner || _pendingEpoch != epoch)) {
      return Future.error(const CanonicalGameException('game_account_changed'));
    }
    if (_pending != null) return _pending!;
    _pendingOwner = owner;
    _pendingEpoch = epoch;
    final future = _resume(owner, epoch);
    _pending = future;
    return future.whenComplete(() {
      _pending = null;
      _pendingOwner = null;
      _pendingEpoch = null;
    });
  }

  Future<CanonicalGameReceipt?> _resume(String owner, int epoch) async {
    void requireSession() {
      if (currentOwner() != owner || sessionEpoch() != epoch) {
        throw const CanonicalGameException('game_account_changed');
      }
    }

    requireSession();
    final CanonicalGameIntent? intent;
    try {
      intent = await intents.pending(owner);
    } on CanonicalGameException catch (error) {
      if (error.code != 'game_intent_recovery_required' ||
          recoverCommands == null) {
        rethrow;
      }
      requireSession();
      await _recover(owner, requireSession);
      return null;
    }
    requireSession();
    if (intent == null) return null;
    // Repair the second journal copy, if needed, before any HTTP request.
    await intents.prepare(intent);
    requireSession();
    final CanonicalGameHttpReply reply;
    try {
      reply = await send(intent).timeout(timeout);
    } on TimeoutException {
      throw const CanonicalGameException('game_command_unavailable');
    }
    requireSession();
    final receipt = CanonicalGameReceipt.parse(reply, intent,
        expectedAuthority: reader.expectedAuthority);
    final cached = await snapshots.inspect(owner);
    requireSession();
    final minimum = [
      intent.minimumRevision,
      receipt.serverRevision,
      cached.minimumRevision
    ].reduce((a, b) => a > b ? a : b);
    final snapshot = await reader.fetch(owner,
        minimumRevision: minimum,
        minimumRulesetRevision: cached.minimumRulesetRevision);
    requireSession();
    if (receipt.stateHash != null &&
        snapshot.serverRevision == receipt.serverRevision &&
        receipt.stateHash != snapshot.stateHash) {
      throw const CanonicalGameException('game_snapshot_conflict');
    }
    await snapshots.persistFresh(snapshot);
    requireSession();
    await applyDisplay(snapshot);
    requireSession();
    await intents.acknowledge(owner, intent.requestId);
    requireSession();
    return receipt;
  }

  Future<void> _recover(String owner, void Function() requireSession) async {
    final requestId = await intents.beginRecovery(owner, newRecoveryId());
    requireSession();
    final Object? response;
    try {
      response = await recoverCommands!(requestId).timeout(timeout);
    } on TimeoutException {
      throw const CanonicalGameException('game_recovery_unavailable');
    }
    requireSession();
    if (response is! Map<String, dynamic> ||
        response.length != 7 ||
        response['protocol'] != 2 ||
        response['owner_id'] != owner ||
        response['request_id'] != requestId ||
        response['authority_mode'] != reader.expectedAuthority.name ||
        response['barrier_revision'] is! int ||
        (response['barrier_revision'] as int) < 1 ||
        (response['barrier_revision'] as int) > 9007199254740991 ||
        response['cancelled_commands'] is! int ||
        ![0, 1].contains(response['cancelled_commands']) ||
        response['replayed'] is! bool) {
      throw const CanonicalGameException('game_recovery_unavailable');
    }
    final cached = await snapshots.inspect(owner);
    requireSession();
    final barrier = response['barrier_revision'] as int;
    final snapshot = await reader.fetch(owner,
        minimumRevision:
            barrier > cached.minimumRevision ? barrier : cached.minimumRevision,
        minimumRulesetRevision: cached.minimumRulesetRevision);
    requireSession();
    await snapshots.persistFresh(snapshot);
    requireSession();
    await applyDisplay(snapshot);
    requireSession();
    await intents.finishRecovery(owner, requestId);
    requireSession();
  }
}
