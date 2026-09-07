import 'dart:async';
import 'dart:convert';

import 'canonical_game_intent.dart';
import 'canonical_game_intent_store.dart';
import 'canonical_game_reader.dart';
import 'canonical_game_snapshot.dart';
import 'canonical_game_snapshot_store.dart';

class CanonicalGameHttpReply {
  const CanonicalGameHttpReply(this.status, this.body);
  final int status;
  final Object? body;
}

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
      CanonicalGameHttpReply reply, CanonicalGameIntent intent) {
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
        body['authority_mode'] != 'shadow' ||
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
    final intent = await intents.pending(owner);
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
    final receipt = CanonicalGameReceipt.parse(reply, intent);
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
}
