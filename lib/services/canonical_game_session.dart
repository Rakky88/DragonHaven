import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'canonical_game_connection.dart';
import 'canonical_game_intent.dart';
import 'canonical_game_intent_store.dart';
import 'canonical_game_reader.dart';
import 'canonical_game_reconciler.dart';
import 'canonical_game_snapshot.dart';
import 'canonical_game_snapshot_store.dart';

/// One detached, account-scoped game session for the staging client. It owns
/// its connection and journals; it never imports a projection into a legacy save.
/// Cached inventory can be displayed offline but never authorizes a new action.
class CanonicalGameSession extends ChangeNotifier {
  CanonicalGameSession(
      {required this.connection,
      required Directory directory,
      String Function()? requestIdGenerator})
      : snapshots = CanonicalGameSnapshotStore(directory),
        intents = CanonicalGameIntentStore(directory),
        _requestId = requestIdGenerator ?? const Uuid().v4 {
    _owner = connection.currentOwner;
    _epoch = connection.sessionEpoch;
    _changes = connection.accountChanges.listen((_) => _accountChanged(),
        onError: (Object _, StackTrace __) => _accountChanged());
  }

  final CanonicalGameConnection connection;
  final CanonicalGameSnapshotStore snapshots;
  final CanonicalGameIntentStore intents;
  final String Function() _requestId;
  late final StreamSubscription<int> _changes;
  String? _owner;
  int _epoch = 0;
  bool _disposed = false;
  bool _fresh = false;
  CanonicalGameSnapshot? _snapshot;
  String? _errorCode;
  Future<CanonicalGameReceipt?>? _operation;
  String? _operationKey;

  bool get _sameSession =>
      !_disposed &&
      _owner == connection.currentOwner &&
      _epoch == connection.sessionEpoch;
  CanonicalGameSnapshot? get snapshot => _sameSession ? _snapshot : null;
  String? get errorCode => _sameSession ? _errorCode : null;
  bool get busy => _sameSession && _operation != null;
  bool get fresh => _sameSession && _fresh;
  bool get canAct => fresh && !busy && snapshot?.mutationsEnabled == true;

  void _accountChanged() {
    if (_disposed) return;
    _owner = connection.currentOwner;
    _epoch = connection.sessionEpoch;
    _fresh = false;
    _snapshot = null;
    _errorCode = null;
    _operation = null;
    _operationKey = null;
    notifyListeners();
  }

  /// Resume a pending command/recovery first, then obtain a fresh server view.
  Future<CanonicalGameReceipt?> synchronize() =>
      _run('synchronize', (owner, epoch, requireSession) async {
        final cached = await snapshots.inspect(owner);
        requireSession();
        if (_snapshot == null && cached.snapshot != null) {
          _snapshot = cached.snapshot;
          notifyListeners();
        }
        var applied = false;
        final reader = _reader();
        final reconciler = _reconciler(reader, (value) async {
          requireSession();
          _accept(value);
          applied = true;
        });
        final receipt = await reconciler.resume(owner);
        requireSession();
        if (!applied) {
          final value = await reader.fetch(owner,
              minimumRevision: cached.minimumRevision,
              minimumRulesetRevision: cached.minimumRulesetRevision);
          requireSession();
          await snapshots.persistFresh(value);
          requireSession();
          _accept(value);
        }
        return receipt;
      });

  /// Duplicate taps share the original request. A different action while one
  /// is pending is refused; economic actions are never queued against stale UI.
  Future<CanonicalGameReceipt?> execute(
      String action, Map<String, dynamic> payload) {
    final ordered = {
      for (final key in payload.keys.toList()..sort()) key: payload[key]
    };
    final key = jsonEncode([action, ordered]);
    final observed = snapshot;
    final allowed = canAct;
    return _run(key, (owner, epoch, requireSession) async {
      if (!allowed || observed == null) {
        throw CanonicalGameException(observed?.mutationsEnabled == false
            ? 'game_engine_disabled'
            : 'game_refresh_required');
      }
      final intent = CanonicalGameIntent(
          ownerId: owner,
          requestId: _requestId(),
          action: action,
          payload: ordered,
          minimumRevision: observed.serverRevision);
      await intents.prepare(intent);
      requireSession();
      return _reconciler(_reader(), (value) async {
        requireSession();
        _accept(value);
      }).resume(owner);
    });
  }

  CanonicalGameReader _reader() => CanonicalGameReader(
      invoke: connection.read,
      currentOwner: () => connection.currentOwner,
      sessionEpoch: () => connection.sessionEpoch);

  CanonicalGameReconciler _reconciler(CanonicalGameReader reader,
          Future<void> Function(CanonicalGameSnapshot) apply) =>
      CanonicalGameReconciler(
          intents: intents,
          snapshots: snapshots,
          reader: reader,
          currentOwner: () => connection.currentOwner,
          sessionEpoch: () => connection.sessionEpoch,
          send: connection.send,
          recoverCommands: connection.recover,
          newRecoveryId: _requestId,
          applyDisplay: apply);

  void _accept(CanonicalGameSnapshot value) {
    final current = _snapshot;
    if (current != null &&
        (value.serverRevision < current.serverRevision ||
            value.rulesetRevision < current.rulesetRevision)) {
      throw const CanonicalGameException('game_snapshot_stale');
    }
    _snapshot = value;
    _fresh = true;
    notifyListeners();
  }

  Future<CanonicalGameReceipt?> _run(
      String key,
      Future<CanonicalGameReceipt?> Function(String, int, void Function())
          action) {
    if (!_sameSession) _accountChanged();
    final owner = _owner;
    final epoch = _epoch;
    if (_disposed || owner == null) {
      return Future.error(const CanonicalGameException('game_login_required'));
    }
    if (_operation != null) {
      if (_operationKey == key) return _operation!;
      return Future.error(const CanonicalGameException('game_command_busy'));
    }
    void requireSession() {
      if (_disposed ||
          connection.currentOwner != owner ||
          connection.sessionEpoch != epoch) {
        throw const CanonicalGameException('game_account_changed');
      }
    }

    _fresh = false;
    _errorCode = null;
    _operationKey = key;
    final completion = Completer<CanonicalGameReceipt?>();
    _operation = completion.future;
    notifyListeners();
    unawaited(() async {
      try {
        requireSession();
        final result = await action(owner, epoch, requireSession);
        requireSession();
        _errorCode = result?.failureCode;
        completion.complete(result);
      } on Object catch (error, stack) {
        final safeError = error is CanonicalGameException
            ? error
            : CanonicalGameException(error is FileSystemException
                ? 'game_storage_unavailable'
                : 'game_command_unavailable');
        if (!_disposed && _sameSession && _owner == owner && _epoch == epoch) {
          _fresh = false;
          _errorCode = safeError.code;
        }
        completion.completeError(safeError, stack);
      } finally {
        if (!_disposed && identical(_operation, completion.future)) {
          _operation = null;
          _operationKey = null;
          notifyListeners();
        }
      }
    }());
    return completion.future;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _snapshot = null;
    _fresh = false;
    unawaited(_changes.cancel());
    unawaited(connection.dispose());
    super.dispose();
  }
}
