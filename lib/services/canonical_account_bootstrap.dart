import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'canonical_account_handoff.dart';
import 'canonical_game_snapshot.dart';

enum CanonicalBootstrapPhase { checking, signedOut, legacy, server, failed }

/// A root-owned game instance. Closing it must stop and drain every writer;
/// hiding its widgets alone is not sufficient for an authority transition.
class CanonicalGameplayLease<T> {
  CanonicalGameplayLease(this.value, {required Future<void> Function() close})
      : _close = close;
  final T value;
  final Future<void> Function() _close;
  Future<void>? _closing;
  Future<void> close() => _closing ??= Future<void>.sync(_close);
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

  /// Polls a tiny authenticated status, never an inventory snapshot. Failure
  /// retires the entire game and its writers before a reconnect can open it.
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
        }
      } on Object {
        if (current()) await synchronize();
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

  /// Backgrounding hides the old root immediately. Resume rechecks authority
  /// after its writers drain, rather than resuming a possibly migrated save.
  Future<void> setForeground(bool foreground) {
    if (_disposed || _foreground == foreground) {
      return _pending ?? Future.value();
    }
    _foreground = foreground;
    _lifecycleEpoch++;
    return synchronize();
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

  /// A caller that replaces the entire controller awaits this barrier first.
  Future<void> shutdown() {
    if (_shutdown != null) return _shutdown!;
    _disposed = true;
    _again = false;
    final stoppingAccounts = _accounts.cancel();
    final pending = _pending;
    final activeLease = pending == null ? _lease : null;
    Future<void>? closingLease;
    if (activeLease != null) {
      // Begin retirement before returning from widget disposal. Lease close
      // synchronously cancels periodic work before its first asynchronous
      // barrier, so no account timers can outlive a removed application root.
      _lease = null;
      closingLease = activeLease.close();
    }
    return _shutdown = (() async {
      await stoppingAccounts;
      await pending;
      _handoff?.dispose();
      _handoff = null;
      await closingLease;
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
