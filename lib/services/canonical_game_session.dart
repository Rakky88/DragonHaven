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
import 'canonical_game_prediction.dart';

/// One detached, account-scoped game session for the staging client. It owns
/// its connection and journals; it never imports a projection into a legacy save.
/// Cached inventory can be displayed offline but never authorizes a new action.
class CanonicalGameSession extends ChangeNotifier {
  CanonicalGameSession(
      {required this.connection,
      required Directory directory,
      this.expectedAuthority = CanonicalGameAuthority.shadow,
      String Function()? requestIdGenerator})
      : snapshots = CanonicalGameSnapshotStore(directory,
            expectedAuthority: expectedAuthority),
        intents = CanonicalGameIntentStore(directory),
        _requestId = requestIdGenerator ?? const Uuid().v4 {
    _owner = connection.currentOwner;
    _epoch = connection.sessionEpoch;
    _changes = connection.accountChanges.listen((_) => _accountChanged(),
        onError: (Object _, StackTrace __) => _accountChanged());
  }

  final CanonicalGameConnection connection;
  final CanonicalGameAuthority expectedAuthority;
  final CanonicalGameSnapshotStore snapshots;
  final CanonicalGameIntentStore intents;
  final String Function() _requestId;
  late final StreamSubscription<int> _changes;
  String? _owner;
  int _epoch = 0;
  int _minimumServerRevision = 0;
  bool _disposed = false;
  bool _fresh = false;
  bool _foreground = true;
  CanonicalGameSnapshot? _snapshot;
  CanonicalGameSnapshot? _preview;
  final _sinceConfirmation = Stopwatch();
  String? _errorCode;
  Future<CanonicalGameReceipt?>? _operation;
  Future<void>? _backgroundRefresh;
  final _admitted = <Future<CanonicalGameReceipt?>>{};
  bool _retiring = false;
  Future<void>? _closing;
  Future<void>? _connectionClosing;
  String? _operationKey;
  final _commands = <_QueuedCommand>[];

  bool get _sameSession =>
      !_disposed &&
      _owner == connection.currentOwner &&
      _epoch == connection.sessionEpoch;
  CanonicalGameSnapshot? get snapshot =>
      _sameSession ? (_preview ?? _snapshot) : null;
  CanonicalGameSnapshot? get confirmedSnapshot =>
      _sameSession ? _snapshot : null;
  String? get errorCode => _sameSession ? _errorCode : null;
  bool get busy => _sameSession && (_operation != null || _commands.isNotEmpty);
  bool get fresh => _sameSession && _fresh;

  /// Automatic refresh/reveal/hatch work must not enter the player's queue.
  bool get canRunAutomatic => canAct && !busy;
  bool get canAct =>
      !_retiring &&
      _foreground &&
      fresh &&
      (!busy || _commands.isNotEmpty) &&
      snapshot?.mutationsEnabled == true;

  /// Returning from the background requires a new read. A command already in
  /// flight still finishes its durable reconciliation, without enabling taps.
  void setForeground(bool value) {
    if (_disposed || value == _foreground) return;
    _foreground = value;
    _fresh = false;
    notifyListeners();
  }

  void _accountChanged() {
    if (_disposed) return;
    _owner = connection.currentOwner;
    _epoch = connection.sessionEpoch;
    _fresh = false;
    _snapshot = null;
    _preview = null;
    _minimumServerRevision = 0;
    _errorCode = null;
    _operation = null;
    _operationKey = null;
    _backgroundRefresh = null;
    _cancelCommands(const CanonicalGameException('game_account_changed'));
    notifyListeners();
  }

  /// Resume a pending command/recovery first, then obtain a fresh server view.
  /// The handoff supplies its confirmed revision before opening server UI.
  /// Retain this lower bound for retries, including an already-pending read.
  Future<CanonicalGameReceipt?> synchronize({int minimumServerRevision = 0}) {
    if (minimumServerRevision < 0 || minimumServerRevision > 9007199254740991) {
      return Future.error(ArgumentError.value(minimumServerRevision));
    }
    if (!_sameSession) _accountChanged();
    if (_commands.isNotEmpty) {
      return _commands.last.completion.future.then(
          (_) => synchronize(minimumServerRevision: minimumServerRevision));
    }
    if (minimumServerRevision > _minimumServerRevision) {
      _minimumServerRevision = minimumServerRevision;
      _fresh = false;
    }
    return _run('synchronize', (owner, epoch, requireSession) async {
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
            minimumRevision: cached.minimumRevision > _minimumServerRevision
                ? cached.minimumRevision
                : _minimumServerRevision,
            minimumRulesetRevision: cached.minimumRulesetRevision);
        requireSession();
        await snapshots.persistFresh(value);
        requireSession();
        _accept(value);
      }
      return receipt;
    });
  }

  /// Best-effort authoritative read for periodic UI polling.
  ///
  /// Unlike [synchronize], this never invalidates the current playable view and
  /// never resumes a durable intent. A player command or another synchronize
  /// always wins: if session state changes while the read is in flight, the
  /// reply is discarded instead of being allowed to replace that newer state.
  Future<void> refreshSnapshotInBackground() {
    if (!_sameSession) _accountChanged();
    final pending = _backgroundRefresh;
    if (pending != null) return pending;
    final owner = _owner;
    final epoch = _epoch;
    final observed = _snapshot;
    if (_disposed ||
        _retiring ||
        !_foreground ||
        !_fresh ||
        owner == null ||
        observed == null ||
        _operation != null ||
        _commands.isNotEmpty) {
      return Future.value();
    }

    final completion = Completer<void>();
    final future = completion.future;
    _backgroundRefresh = future;
    bool unchanged() =>
        !_disposed &&
        !_retiring &&
        _foreground &&
        _fresh &&
        _owner == owner &&
        _epoch == epoch &&
        connection.currentOwner == owner &&
        connection.sessionEpoch == epoch &&
        identical(_snapshot, observed) &&
        _operation == null &&
        _commands.isEmpty;
    unawaited(() async {
      try {
        if (!unchanged() || await intents.pending(owner) != null) return;
        if (!unchanged()) return;
        final value = await _reader().fetch(owner,
            minimumRevision: observed.serverRevision,
            minimumRulesetRevision: observed.rulesetRevision);
        if (!unchanged()) return;
        await snapshots.persistFresh(value);
        if (unchanged()) _accept(value);
      } on Object {
        // Periodic reads are opportunistic. Manual synchronization and command
        // reconciliation remain responsible for surfacing recovery failures.
      } finally {
        if (identical(_backgroundRefresh, future)) {
          _backgroundRefresh = null;
        }
        completion.complete();
      }
    }());
    return future;
  }

  /// Predictable actions can be admitted against the projected display while
  /// one durable command is sent at a time. Identical pending taps share a
  /// result. Unknown outcomes remain exclusive and are never fabricated.
  Future<CanonicalGameReceipt?> execute(
      String action, Map<String, dynamic> payload,
      {bool optimistic = true}) {
    if (!_sameSession) _accountChanged();
    final ordered = {
      for (final key in payload.keys.toList()..sort()) key: payload[key]
    };
    final key = jsonEncode([action, ordered]);
    if (_commands.isNotEmpty && _commands.last.key == key) {
      return _commands.last.completion.future;
    }
    final observed = confirmedSnapshot;
    final allowed = canAct;
    final prediction = optimistic && allowed && observed != null
        ? predictGameDisplay(observed, action, ordered,
            observed.serverTime.add(_sinceConfirmation.elapsed),
            preceding: _preview)
        : null;
    if (_commands.isNotEmpty && prediction == null) {
      return Future.error(const CanonicalGameException('game_command_busy'));
    }
    if (prediction != null) {
      if (_commands.length >= 32) {
        return Future.error(const CanonicalGameException('game_command_busy'));
      }
      final startDrain = _commands.isEmpty;
      final CanonicalGameIntent validated;
      try {
        validated = CanonicalGameIntent(
            ownerId: observed!.ownerId,
            requestId: _requestId(),
            action: action,
            payload: ordered,
            minimumRevision: observed.serverRevision);
      } on Object catch (error) {
        return Future.error(error);
      }
      final command = _QueuedCommand(key, validated);
      _commands.add(command);
      _admitted.add(command.completion.future);
      _preview = prediction;
      notifyListeners();
      if (startDrain) unawaited(_drainCommands());
      return command.completion.future;
    }
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
    }, invalidateFresh: false);
  }

  void _cancelCommands(CanonicalGameException error) {
    final cancelled = _commands.toList();
    _commands.clear();
    _preview = null;
    for (final command in cancelled) {
      _admitted.remove(command.completion.future);
      if (!command.completion.isCompleted) {
        command.completion.completeError(error);
      }
    }
  }

  void _rebaseCommands({bool skipCurrent = false}) {
    _preview = null;
    final confirmed = _snapshot;
    if (confirmed == null) return;
    for (final command in _commands.skip(skipCurrent ? 1 : 0)) {
      final next = predictGameDisplay(confirmed, command.action,
          command.payload, confirmed.serverTime.add(_sinceConfirmation.elapsed),
          preceding: _preview);
      // A server rejection may remove resources another queued action needs.
      // Do not display that effect or dispatch it from an invalid projection.
      command.valid = next != null;
      if (next != null) _preview = next;
    }
  }

  Future<void> _drainCommands() async {
    while (_commands.isNotEmpty) {
      final command = _commands.first;
      if (!command.valid) {
        _commands.removeAt(0);
        _admitted.remove(command.completion.future);
        command.completion.completeError(
            const CanonicalGameException('game_refresh_required'));
        _rebaseCommands();
        if (!_disposed) notifyListeners();
        continue;
      }
      try {
        final receipt =
            await _run(command.key, (owner, epoch, requireSession) async {
          final observed = confirmedSnapshot;
          if (observed == null) {
            throw const CanonicalGameException('game_account_changed');
          }
          final intent = CanonicalGameIntent(
              ownerId: owner,
              requestId: command.intent.requestId,
              action: command.action,
              payload: command.payload,
              minimumRevision: observed.serverRevision);
          await intents.prepare(intent);
          requireSession();
          return _reconciler(_reader(), (value) async {
            requireSession();
            _accept(value);
          }).resume(owner);
        }, preview: _preview, admitted: true);
        if (!command.completion.isCompleted) {
          command.completion.complete(receipt);
        }
      } on Object catch (error, stack) {
        if (!command.completion.isCompleted) {
          command.completion.completeError(error, stack);
        }
        if (_commands.isNotEmpty && identical(_commands.first, command)) {
          _commands.removeAt(0);
          _admitted.remove(command.completion.future);
          // Unknown delivery stops the queue; only the original durable intent
          // may be recovered before any new economic command is dispatched.
          _cancelCommands(
              const CanonicalGameException('game_refresh_required'));
          if (!_disposed) notifyListeners();
        }
        return;
      }
      _admitted.remove(command.completion.future);
      if (_commands.isEmpty || !identical(_commands.first, command)) return;
      _commands.removeAt(0);
      _rebaseCommands();
      if (!_disposed) notifyListeners();
    }
  }

  CanonicalGameReader _reader() => CanonicalGameReader(
      invoke: connection.read,
      expectedAuthority: expectedAuthority,
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
    if (value.isSpeculative || value.authorityMode != expectedAuthority.name) {
      throw const CanonicalGameException('game_snapshot_invalid');
    }
    if (value.serverRevision < _minimumServerRevision) {
      throw const CanonicalGameException('game_snapshot_stale');
    }
    final current = _snapshot;
    if (current != null &&
        (value.serverRevision < current.serverRevision ||
            value.rulesetRevision < current.rulesetRevision)) {
      throw const CanonicalGameException('game_snapshot_stale');
    }
    _snapshot = value;
    _preview = null;
    _sinceConfirmation
      ..reset()
      ..start();
    _fresh = _foreground;
    _rebaseCommands(skipCurrent: true);
    notifyListeners();
  }

  Future<CanonicalGameReceipt?> _run(
      String key,
      Future<CanonicalGameReceipt?> Function(String, int, void Function())
          action,
      {CanonicalGameSnapshot? preview,
      bool admitted = false,
      bool invalidateFresh = true}) {
    if (!_sameSession) _accountChanged();
    final owner = _owner;
    final epoch = _epoch;
    if (_disposed || (_retiring && !admitted) || owner == null) {
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

    // An exclusive command may need an authoritative result before it can be
    // predicted (for example opening a chest), but that does not make the
    // already-confirmed inventory stale while the request is in flight. Keep
    // the visible view steady and fence further mutations through [busy]. An
    // unknown outcome still marks the session stale in the catch block below
    // so its durable intent must be reconciled before play continues.
    if (!admitted && invalidateFresh) _fresh = false;
    _errorCode = null;
    _operationKey = key;
    final completion = Completer<CanonicalGameReceipt?>();
    _operation = completion.future;
    _preview = preview;
    _admitted.add(completion.future);
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
        _admitted.remove(completion.future);
        if (!_disposed && identical(_operation, completion.future)) {
          if (admitted && _fresh) {
            _rebaseCommands(skipCurrent: true);
          } else {
            _preview = null;
          }
          _operation = null;
          _operationKey = null;
          notifyListeners();
        }
      }
    }());
    return completion.future;
  }

  /// Hide gameplay first, then drain admitted receipts before another lease
  /// opens the same journals. Account changes cannot lose this drain barrier.
  Future<void> close() => _closing ??= (() async {
        _retiring = true;
        setForeground(false);
        await Future.wait(_admitted.toList().map((future) async {
          try {
            await future;
          } on Object {/* Durable recovery owns failures. */}
        }));
        dispose();
        await _connectionClosing;
      })();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelCommands(const CanonicalGameException('game_account_changed'));
    _snapshot = null;
    _preview = null;
    _backgroundRefresh = null;
    _sinceConfirmation.stop();
    _fresh = false;
    unawaited(_changes.cancel());
    _connectionClosing ??= connection.dispose();
    unawaited(_connectionClosing);
    super.dispose();
  }
}

class _QueuedCommand {
  _QueuedCommand(this.key, this.intent);
  final String key;
  final CanonicalGameIntent intent;
  String get action => intent.action;
  Map<String, dynamic> get payload => intent.payload;
  final completion = Completer<CanonicalGameReceipt?>();
  bool valid = true;
}
