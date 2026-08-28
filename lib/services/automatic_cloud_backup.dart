import 'dart:async';

import '../providers/household_provider.dart';
import '../providers/online_account_provider.dart';
import 'storage_service.dart';

/// Non-blocking cloud-save cadence for signed-in keepers.
///
/// A meaningful local mutation is uploaded immediately when the account has
/// not auto-backed-up in the last fifteen minutes. Further mutations are
/// coalesced into one upload at the next boundary. Conflicts and foreground
/// online operations are never overridden.
class AutomaticCloudBackupCoordinator {
  AutomaticCloudBackupCoordinator({
    required HouseholdProvider game,
    required OnlineAccountProvider online,
    DateTime Function()? clock,
    this.minimumInterval = const Duration(minutes: 15),
    Future<DateTime?> Function(String userId)? loadLastSuccessfulAt,
    Future<void> Function(String userId, DateTime at)? saveLastSuccessfulAt,
  })  : _game = game,
        _online = online,
        _clock = clock ?? DateTime.now,
        _loadLastSuccessfulAt =
            loadLastSuccessfulAt ?? StorageService.loadAutomaticCloudBackupAt,
        _saveLastSuccessfulAt =
            saveLastSuccessfulAt ?? StorageService.saveAutomaticCloudBackupAt;

  final HouseholdProvider _game;
  final OnlineAccountProvider _online;
  final DateTime Function() _clock;
  final Duration minimumInterval;
  final Future<DateTime?> Function(String userId) _loadLastSuccessfulAt;
  final Future<void> Function(String userId, DateTime at) _saveLastSuccessfulAt;

  Timer? _timer;
  int _observedRevision = 0;
  bool _dirty = false;
  bool _attempting = false;
  bool _disposed = false;
  String? _loadedUserId;
  DateTime? _lastSuccessfulAt;
  DateTime? _retryNotBefore;

  Future<void> initialize() async {
    _loadedUserId = _online.currentUserId;
    _observedRevision = _game.localMutationRevision;
    _game.addListener(_onGameChanged);
    _online.addListener(_onOnlineChanged);
    await _loadAccountCadence();
  }

  void _onGameChanged() {
    final revision = _game.localMutationRevision;
    if (revision == _observedRevision) return;
    _observedRevision = revision;
    _dirty = true;
    _schedule();
  }

  void _onOnlineChanged() {
    if (_online.currentUserId != _loadedUserId) {
      unawaited(_loadAccountCadence().then((_) => _schedule()));
      return;
    }
    _schedule();
  }

  Future<void> _loadAccountCadence() async {
    final userId = _online.currentUserId;
    if (userId != _loadedUserId) {
      // Never carry an unsaved mutation across accounts. A new account starts
      // auto-backup tracking from its next local change.
      _dirty = false;
      _observedRevision = _game.localMutationRevision;
      _retryNotBefore = null;
    }
    _loadedUserId = userId;
    _lastSuccessfulAt = userId == null || userId.isEmpty
        ? null
        : await _loadLastSuccessfulAt(userId);
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (_disposed || !_dirty || !_canAttempt) return;
    final now = _clock();
    var dueAt = _lastSuccessfulAt?.add(minimumInterval);
    if (_retryNotBefore case final retryAt?) {
      if (dueAt == null || retryAt.isAfter(dueAt)) dueAt = retryAt;
    }
    if (dueAt == null || !dueAt.isAfter(now)) {
      unawaited(_attempt());
      return;
    }
    _timer = Timer(dueAt.difference(now), () => unawaited(_attempt()));
  }

  bool get _canAttempt =>
      _online.isSignedIn &&
      _online.isEmailVerified &&
      !_online.busy &&
      !_attempting &&
      _online.cloudConflictSave == null &&
      (_online.currentUserId?.isNotEmpty ?? false);

  Future<bool> tryWhenBackgrounded() async {
    if (!_dirty || !_canAttempt) return false;
    // A foreground timer cannot be trusted after Android suspends or stops the
    // process. Flush outstanding progress now, while still respecting a short
    // retry backoff after a real server failure.
    if (_retryNotBefore case final retryAt?) {
      if (retryAt.isAfter(_clock())) return false;
    }
    return _attempt();
  }

  Future<bool> _attempt() async {
    if (_disposed || !_dirty || !_canAttempt) return false;
    final userId = _online.currentUserId!;
    final uploadingRevision = _game.localMutationRevision;
    _attempting = true;
    try {
      final success = await _online.backupToCloud(automatic: true);
      if (!success) {
        _retryNotBefore = _clock().add(const Duration(minutes: 2));
        return false;
      }
      final completedAt = _clock();
      _lastSuccessfulAt = completedAt;
      _retryNotBefore = null;
      _dirty = _game.localMutationRevision != uploadingRevision;
      await _saveLastSuccessfulAt(userId, completedAt);
      return true;
    } finally {
      _attempting = false;
      if (_dirty) _schedule();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _game.removeListener(_onGameChanged);
    _online.removeListener(_onOnlineChanged);
  }
}
