part of 'household_provider.dart';

extension EventPointsSystems on HouseholdProvider {
  bool recordGroupEventCompletion(String id, DateTime endsAt) {
    if (endsAt.isAfter(_clock()) || eventPointGroupIds.contains(id)) {
      return false;
    }
    eventPointGroupIds.add(id);
    awardEventPoints(50, completedAt: endsAt);
    return true;
  }

  Future<void> saveGroupEventCompletions(Map<String, DateTime> groups) async {
    var changed = false;
    for (final e in groups.entries) {
      changed = recordGroupEventCompletion(e.key, e.value) || changed;
    }
    if (changed) await _notifyAndSave();
  }

  EventProgress _progressForWindow(SpecialAdventureWindow window) {
    return eventProgress.putIfAbsent(window.key, () {
      final event = window.event;
      final duration = window.key.contains(':preview:')
          ? Duration(hours: event.previewHours)
          : window.key.contains(':launch:')
              ? event.initialAvailability
              : event.recurrenceAvailability!;
      final perDay = event.pointsPerDay;
      return EventProgress(
          eventId: event.id,
          key: window.key,
          startsAt: window.startsAt,
          endsAt: window.endsAt,
          target: (duration.inMinutes * perDay / Duration.minutesPerDay).ceil(),
          chestId: event.rewards.specialChestId!,
          preview: window.key.contains(':preview:'));
    });
  }

  bool initializeEventProgress() {
    final before = eventProgress.length;
    for (final window in activeSpecialAdventureWindows) {
      _progressForWindow(window);
    }
    return before != eventProgress.length;
  }

  List<EventProgress> get activeEventProgress => [
        for (final window in activeSpecialAdventureWindows)
          _progressForWindow(window)
      ];

  List<EventProgress> get visibleEventProgress {
    final activeKeys = activeEventProgress.map((p) => p.key).toSet();
    return eventProgress.values
        .where((p) => activeKeys.contains(p.key) || p.complete)
        .toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
  }

  /// Completion time, rather than reward collection time, determines eligibility.
  void awardEventPoints(int points, {DateTime? completedAt}) {
    if (points <= 0) return;
    final at = completedAt ?? _clock();
    final windows = <String, SpecialAdventureWindow>{
      for (final w in specialAdventureWindowsAt(at))
        if (seasonalEventDismissedUntil[w.event.id]?.isAfter(at) != true)
          w.key: w,
      for (final w in activeSpecialAdventureWindows)
        if (w.contains(at)) w.key: w,
    };
    // Persisted preview windows can still receive an adventure that finished
    // before closing while the app was offline.
    final eligible = <String, EventProgress>{
      for (final p in eventProgress.values)
        if (p.activeAt(at) &&
            seasonalEventDismissedUntil[p.eventId]?.isAfter(at) != true)
          p.key: p,
      for (final w in windows.values) w.key: _progressForWindow(w),
    };
    final previews = eligible.values.where((p) => p.preview).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    if (previews.isNotEmpty) {
      final selected = previews.first;
      eligible.removeWhere((key, _) => key != selected.key);
    }
    for (final p in eligible.values) {
      p.points += points;
    }
  }

  /// Database-authenticated partner totals; never accepted from a client command.
  void applyEventPartnerPoints(Map<String, dynamic>? verified, String owner) {
    if (verified == null) return;
    if (verified['ownerId'] != owner ||
        verified['version'] != 1 ||
        verified['progress'] is! List) {
      throw const FormatException('Invalid event partner progress');
    }
    for (final raw in verified['progress'] as List) {
      final incoming =
          EventProgress.fromJson(Map<String, dynamic>.from(raw as Map));
      if (incoming.eventId != 'valentine_two_heartlights') {
        throw const FormatException('Invalid event partner');
      }
      final local = eventProgress.putIfAbsent(incoming.key, () => incoming);
      local.partnerPoints = max(local.partnerPoints, incoming.partnerPoints);
    }
  }

  Future<void> synchronizeEventPartnerPoints(
      Map<String, dynamic> verified, String owner) async {
    final before = eventProgress.values
        .map((p) => '${p.key}:${p.partnerPoints}')
        .join('|');
    applyEventPartnerPoints(verified, owner);
    final after = eventProgress.values
        .map((p) => '${p.key}:${p.partnerPoints}')
        .join('|');
    if (before != after) await _notifyAndSave();
  }

  Future<bool> claimEventReward(String key) async {
    final progress = eventProgress[key];
    if (progress == null || !progress.canClaim) return false;
    // Preview chests keep their established simulated reward policy.
    if (!progress.preview || persistentSeasonalPreviewRewards) {
      specialChestInventory.update(progress.chestId, (n) => n + 1,
          ifAbsent: () => 1);
    }
    progress.claimed = true;
    await _notifyAndSave();
    return true;
  }
}
