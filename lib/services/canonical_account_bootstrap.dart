import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'canonical_account_handoff.dart';
import 'canonical_game_snapshot.dart';

enum CanonicalBootstrapPhase { checking, signedOut, legacy, server, failed }

/// A root-owned game instance. Closing it must stop and drain every writer;
/// hiding its widgets alone is not sufficient for an authority transition.
class CanonicalGameplayLease<T> {
  CanonicalGameplayLease(this.value,
      {required Future<void> Function() close,
      void Function()? quiesce,
      Future<void> Function()? reconnect,
      bool Function()? requiresReconnect,
      void Function(bool foreground)? setForeground})
      : _close = close,
        _quiesce = quiesce,
        _reconnect = reconnect,
        _requiresReconnect = requiresReconnect,
        _setForeground = setForeground;
  final T value;
  final Future<void> Function() _close;
  final void Function()? _quiesce;
  final Future<void> Function()? _reconnect;
  final bool Function()? _requiresReconnect;
  final void Function(bool foreground)? _setForeground;
  bool _quiesced = false;
  Future<void>? _closing;

  void quiesce() {
    if (_quiesced) return;
    _quiesced = true;
    _quiesce?.call();
  }

  Future<void> close() {
    quiesce();
    return _closing ??= Future<void>.sync(_close);
  }

  /// Reconciles the existing server-owned game without replacing its widget
  /// tree, Navigator or account-scoped journals.
  Future<void> reconnect() =>
      _closing != null || _reconnect == null ? Future.value() : _reconnect!();
  bool get supportsReconnect => _closing == null && _reconnect != null;
  bool get requiresReconnect =>
      _closing == null && (_requiresReconnect?.call() ?? false);

  /// Pauses automatic work while Android is in the background. A retained
  /// server lease still finishes any already-admitted durable command.
  void setForeground(bool foreground) {
    if (_closing == null) _setForeground?.call(foreground);
  }
}

/// Resolves account authority before loading any gameplay or legacy save.
/// One root owns this controller across account changes and foreground returns.
/// The legacy-source callback must independently establish source ownership;
/// a signed-in identity alone never authorizes importing device-global data.
class CanonicalAccountBootstrap<T> extends ChangeNotifier {
  CanonicalAccountBootstrap({
    required this.directory,
    required this.currentOwner,
    required this.sessionEpoch,
    required Stream<int> accountChanges,
    required this.readStatus,
    required this.prepareAndUploadLegacy,
    required this.activate,
    required this.openLegacy,
    required this.openServer,
    this.beforeRetire,
    this.checkConnection,
  }) {
    _accounts = accountChanges.listen((_) {
      unawaited(synchronize());
    }, onError: (Object _, StackTrace __) {
      unawaited(synchronize());
    });
  }

  final Directory directory;

  /// A UI root waits until its old gameplay subtree is removed before draining.
  final Future<void> Function()? beforeRetire;
  final String? Function() currentOwner;
  final int Function() sessionEpoch;
  final Future<CanonicalAccountStatus> Function(String owner) readStatus;
  final Future<CanonicalAccountStatus> Function(String owner)? checkConnection;
  Future<void>? _heartbeat;
  Future<void>? _reconnect;
  CanonicalGameplayLease<T>? _reconnectLease;
  String? _reconnectOwner;
  int? _reconnectEpoch;
  int? _reconnectLifecycle;

  /// Polls a tiny authenticated status, never an inventory snapshot. Legacy
  /// authority remains fail-closed. A live server root is never retired only
  /// because this opportunistic probe timed out: its commands still require
  /// the server, and replacing it would discard navigation and make a short
  /// network handover look like an account restart.
  Future<void> verifyConnection() {
    if (_disposed ||
        !_foreground ||
        _pending != null ||
        checkConnection == null) {
      return Future.value();
    }
    if (_heartbeat != null) return _heartbeat!;
    if (gameplay == null) {
      return phase == CanonicalBootstrapPhase.failed
          ? synchronize()
          : Future.value();
    }
    final owner = _owner!;
    final epoch = _epoch;
    final lifecycle = _lifecycleEpoch;
    return _heartbeat = (() async {
      bool current() =>
          _current &&
          _epoch == epoch &&
          _owner == owner &&
          _lifecycleEpoch == lifecycle;
      try {
        final status =
            await checkConnection!(owner).timeout(const Duration(seconds: 5));
        if (!current()) return;
        if (status.ownerId != owner ||
            (status.phase == 'active') !=
                (phase == CanonicalBootstrapPhase.server) ||
            status.migrationEnabled &&
                phase == CanonicalBootstrapPhase.legacy) {
          await synchronize();
        } else if (phase == CanonicalBootstrapPhase.server &&
            _lease?.requiresReconnect == true) {
          await reconnectGameplay();
        }
      } on Object catch (error) {
        if (!current()) return;
        if (phase == CanonicalBootstrapPhase.server &&
            _isHeartbeatTransportFailure(error)) {
          return;
        }
        await synchronize();
      } finally {
        _heartbeat = null;
      }
    })();
  }

  final Future<int> Function(String owner) prepareAndUploadLegacy;
  final Future<int> Function(String owner, String request, int sourceRevision)
      activate;
  final Future<CanonicalGameplayLease<T>> Function(String owner) openLegacy;
  final Future<CanonicalGameplayLease<T>> Function(
      String owner, int minimumRevision) openServer;
  late final StreamSubscription<int> _accounts;
  CanonicalGameplayLease<T>? _lease;
  CanonicalAccountHandoff? _handoff;
  CanonicalBootstrapPhase _phase = CanonicalBootstrapPhase.checking;
  String? _owner;
  int? _epoch;
  String? _error;
  bool _foreground = true;
  int _lifecycleEpoch = 0;
  int? _resolvedLifecycle;
  bool _disposed = false;
  bool _again = false;
  Future<void>? _pending;
  Future<void>? _shutdown;

  bool get _current =>
      !_disposed &&
      _foreground &&
      currentOwner() == _owner &&
      sessionEpoch() == _epoch &&
      _resolvedLifecycle == _lifecycleEpoch;
  CanonicalBootstrapPhase get phase =>
      _current ? _phase : CanonicalBootstrapPhase.checking;
  String? get errorCode => _current ? _error : null;
  T? get gameplay => _current &&
          (phase == CanonicalBootstrapPhase.legacy ||
              phase == CanonicalBootstrapPhase.server)
      ? _lease?.value
      : null;
  bool get gameplayNavigationReady =>
      gameplay != null &&
      _reconnect == null &&
      _lease?.requiresReconnect != true;

  /// Server gameplay retains its Navigator while backgrounded and reconciles
  /// the same fenced session on resume. Legacy gameplay still performs a full
  /// authority recheck before it is shown again.
  Future<void> setForeground(bool foreground) {
    if (_disposed || _foreground == foreground) {
      return _pending ?? Future.value();
    }
    _foreground = foreground;
    _lifecycleEpoch++;
    final retained = _lease;
    if (_phase == CanonicalBootstrapPhase.server &&
        retained != null &&
        retained.supportsReconnect &&
        currentOwner() == _owner &&
        sessionEpoch() == _epoch) {
      retained.setForeground(foreground);
      // Keep the retained server root current as soon as the app resumes. Its
      // session is still fenced by setForeground(true) until reconnect has
      // confirmed a fresh snapshot, but retaining this lifecycle prevents the
      // Navigator and the player's current screen from being rebuilt.
      if (foreground) _resolvedLifecycle = _lifecycleEpoch;
      notifyListeners();
      if (!foreground) return Future.value();
      return reconnectGameplay(revealRetainedLease: true);
    }
    return synchronize();
  }

  /// Reconciles a retained server lease in place. This is used after Android
  /// reports that validated connectivity returned and on foreground resume.
  /// The gameplay session keeps mutations fenced until its durable intent and
  /// absolute snapshot have been confirmed, so this cannot duplicate a spend.
  Future<void> reconnectGameplay({bool revealRetainedLease = false}) {
    if (_disposed || !_foreground) return Future.value();
    final lease = _lease;
    final owner = _owner;
    final epoch = _epoch;
    final lifecycle = _lifecycleEpoch;
    final pending = _reconnect;
    if (pending != null) {
      if (identical(_reconnectLease, lease) &&
          _reconnectOwner == owner &&
          _reconnectEpoch == epoch &&
          _reconnectLifecycle == lifecycle) {
        return pending;
      }
      // A background/foreground transition can invalidate an in-flight
      // reconnect without cancelling its durable transport. Queue one new
      // reconciliation for the current lifecycle after that transport drains;
      // otherwise the public phase can remain `checking` indefinitely.
      return pending.then(
          (_) => reconnectGameplay(revealRetainedLease: revealRetainedLease));
    }
    if (lease == null ||
        _phase != CanonicalBootstrapPhase.server ||
        owner == null ||
        currentOwner() != owner ||
        sessionEpoch() != epoch) {
      return synchronize();
    }
    final completion = Completer<void>();
    _reconnect = completion.future;
    _reconnectLease = lease;
    _reconnectOwner = owner;
    _reconnectEpoch = epoch;
    _reconnectLifecycle = lifecycle;
    if (revealRetainedLease) notifyListeners();
    unawaited(() async {
      try {
        await lease.reconnect();
        if (_disposed ||
            !_foreground ||
            !identical(_lease, lease) ||
            currentOwner() != owner ||
            sessionEpoch() != epoch ||
            _lifecycleEpoch != lifecycle) {
          return;
        }
        _resolvedLifecycle = lifecycle;
        _error = null;
        notifyListeners();
      } on Object catch (error) {
        if (_disposed ||
            !_foreground ||
            !identical(_lease, lease) ||
            currentOwner() != owner ||
            sessionEpoch() != epoch ||
            _lifecycleEpoch != lifecycle) {
          return;
        }
        if (error is CanonicalGameException &&
            (error.code == 'game_login_required' ||
                error.code == 'game_account_changed' ||
                error.code == 'privacy_confirmation_required')) {
          // Authentication changed or a new privacy notice must be shown. The
          // normal resolver removes the old root before handling either flow.
          unawaited(synchronize());
          return;
        }
        // The retained CanonicalGameSession exposes its cached snapshot but
        // keeps `fresh == false`, so users keep their screen while all writes
        // remain fenced until a later retry confirms the durable result.
        _resolvedLifecycle = lifecycle;
        notifyListeners();
      } finally {
        if (identical(_reconnect, completion.future)) {
          _reconnect = null;
          _reconnectLease = null;
          _reconnectOwner = null;
          _reconnectEpoch = null;
          _reconnectLifecycle = null;
          if (!_disposed && identical(_lease, lease)) notifyListeners();
        }
        if (!completion.isCompleted) completion.complete();
      }
    }());
    return completion.future;
  }

  Future<void> synchronize() {
    if (_disposed) return Future.value();
    if (_pending != null) {
      if (!_current) _again = true;
      notifyListeners();
      return _pending!;
    }
    _again = true;
    _phase = CanonicalBootstrapPhase.checking;
    _error = null;
    final settled = Completer<void>();
    _pending = settled.future;
    notifyListeners();
    unawaited(() async {
      try {
        while (_again && !_disposed) {
          _again = false;
          await _resolve();
        }
      } finally {
        _pending = null;
        settled.complete();
      }
    }());
    return settled.future;
  }

  Future<void> _resolve() async {
    final owner = currentOwner();
    final epoch = sessionEpoch();
    final lifecycle = _lifecycleEpoch;
    _owner = owner;
    _epoch = epoch;
    _resolvedLifecycle = lifecycle;
    bool current() =>
        !_disposed &&
        _foreground &&
        currentOwner() == owner &&
        sessionEpoch() == epoch &&
        _lifecycleEpoch == lifecycle;
    void requireCurrent() {
      if (!current()) {
        throw const CanonicalGameException('game_account_changed');
      }
    }

    CanonicalGameplayLease<T>? opened;
    try {
      // Retain a failed close: losing that reference could open a second root
      // while the previous root still has unconfirmed writes in progress.
      if (_lease != null) await beforeRetire?.call();
      await _lease?.close();
      _lease = null;
      _handoff?.dispose();
      _handoff = null;
      if (!_foreground || _disposed) return;
      requireCurrent();
      if (owner == null) {
        _phase = CanonicalBootstrapPhase.signedOut;
        notifyListeners();
        return;
      }
      final handoff = _handoff = CanonicalAccountHandoff(
        directory: directory,
        currentOwner: currentOwner,
        sessionEpoch: sessionEpoch,
        readStatus: readStatus,
        prepareAndUploadLegacy: prepareAndUploadLegacy,
        activate: activate,
      );
      await handoff.synchronize();
      requireCurrent();
      final server = handoff.phase == CanonicalHandoffPhase.server;
      if (!server && handoff.phase != CanonicalHandoffPhase.legacy) {
        throw const CanonicalGameException('game_migration_unavailable');
      }
      opened = server
          ? await openServer(owner, handoff.minimumServerRevision!)
          : await openLegacy(owner);
      requireCurrent();
      _lease = opened;
      opened = null;
      _phase = server
          ? CanonicalBootstrapPhase.server
          : CanonicalBootstrapPhase.legacy;
      notifyListeners();
    } on Object catch (error) {
      if (opened != null) {
        // Also close a game that finished loading after its account vanished.
        _lease = opened;
        try {
          await opened.close();
          _lease = null;
        } on Object {
          // A failed close remains a barrier on the next attempt.
        }
      }
      if (current()) {
        _error = error is CanonicalGameException
            ? error.code
            : 'game_migration_unavailable';
        _phase = CanonicalBootstrapPhase.failed;
        notifyListeners();
      }
    } finally {
      if (!_disposed &&
          _foreground &&
          (currentOwner() != owner ||
              sessionEpoch() != epoch ||
              _lifecycleEpoch != lifecycle)) {
        _again = true;
      }
    }
  }

  bool _isHeartbeatTransportFailure(Object error) =>
      error is SocketException ||
      error is TimeoutException ||
      error is CanonicalGameException &&
          error.code == 'game_command_unavailable';

  /// A caller that replaces the entire controller awaits this barrier first.
  Future<void> shutdown() {
    if (_shutdown != null) return _shutdown!;
    _disposed = true;
    _again = false;
    // Stop periodic work synchronously when a widget tree is removed. The
    // ordered asynchronous close still waits for in-flight authority work and
    // retires the lease only after its gameplay subtree has unmounted.
    _lease?.quiesce();
    return _shutdown = (() async {
      await _accounts.cancel();
      await _pending;
      _handoff?.dispose();
      _handoff = null;
      await _lease?.close();
      _lease = null;
    })();
  }

  @override
  void dispose() {
    unawaited(shutdown().catchError((Object _) {}));
    super.dispose();
  }
}
