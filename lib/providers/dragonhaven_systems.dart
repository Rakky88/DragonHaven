part of 'household_provider.dart';

enum _ReturnOutcome {
  wooden,
  silver,
  gold,
  dragon,
  mythical,
  visit,
  special,
  nothing,
  mischief,
  minorDamage,
  damage,
  majorDamage,
  sinister,
  spotted,
  majorMischief,
}

enum AdventureStartResult {
  started,
  eggCannotAdventure,
  dragonBusy,
  groupNeedsFriends,
  requirementsNotMet,
  unavailable,
}

enum TowerBuildResult { built, maximumReached, insufficientCoins, invalidRoom }

const int towerFloorPriceMultiplier = houseTowerPriceMultiplier;

DateTime _adventureRefillBoundary(DateTime value, int intervalMinutes) {
  final minute = value.minute - value.minute.remainder(intervalMinutes);
  return value.isUtc
      ? DateTime.utc(value.year, value.month, value.day, value.hour, minute)
      : DateTime(value.year, value.month, value.day, value.hour, minute);
}

DateTime _lastSundayOfUtcMonth(int year, int month) {
  final lastDay = DateTime.utc(year, month + 1, 0);
  return lastDay.subtract(Duration(days: lastDay.weekday % 7));
}

Duration _amsterdamOffsetAtUtc(DateTime instant) {
  final utc = instant.toUtc();
  final daylightStart = _lastSundayOfUtcMonth(utc.year, DateTime.march)
      .add(const Duration(hours: 1));
  final daylightEnd = _lastSundayOfUtcMonth(utc.year, DateTime.october)
      .add(const Duration(hours: 1));
  return !utc.isBefore(daylightStart) && utc.isBefore(daylightEnd)
      ? const Duration(hours: 2)
      : const Duration(hours: 1);
}

class SpecialAdventureWindow {
  const SpecialAdventureWindow({
    required this.event,
    required this.key,
    required this.startsAt,
    required this.endsAt,
  });

  final SpecialAdventureEventDefinition event;
  final String key;
  final DateTime startsAt;
  final DateTime endsAt;

  bool contains(DateTime instant) {
    final utc = instant.toUtc();
    return !utc.isBefore(startsAt) && utc.isBefore(endsAt);
  }
}

DateTime _amsterdamWallTimeToUtc(
  int year,
  int month,
  int day, [
  int hour = 0,
]) {
  final wall = DateTime.utc(year, month, day, hour);
  for (final offset in const [Duration(hours: 2), Duration(hours: 1)]) {
    final candidate = wall.subtract(offset);
    if (_amsterdamOffsetAtUtc(candidate) == offset) return candidate;
  }
  throw StateError('Invalid Europe/Amsterdam wall time: $wall');
}

SpecialAdventureWindow _initialSpecialWindow(
  SpecialAdventureEventDefinition event,
) {
  final start = _amsterdamWallTimeToUtc(
    event.initialYear,
    event.initialMonth,
    event.initialDay,
    event.initialHour,
  );
  final endWall = DateTime.utc(
    event.initialYear,
    event.initialMonth,
    event.initialDay,
    event.initialHour,
  ).add(event.initialAvailability);
  return SpecialAdventureWindow(
    event: event,
    key: '${event.id}:launch:${event.initialYear}',
    startsAt: start,
    endsAt: _amsterdamWallTimeToUtc(
      endWall.year,
      endWall.month,
      endWall.day,
      endWall.hour,
    ),
  );
}

SpecialAdventureWindow? _annualSpecialWindow(
  SpecialAdventureEventDefinition event,
  int year,
) {
  final firstYear = event.recursYearlyFrom;
  final month = event.recurrenceMonth;
  final day = event.recurrenceDay;
  final availability = event.recurrenceAvailability;
  if (firstYear == null ||
      year < firstYear ||
      month == null ||
      day == null ||
      availability == null) {
    return null;
  }
  final start = _amsterdamWallTimeToUtc(
    year,
    month,
    day,
    event.recurrenceHour,
  );
  final endWall =
      DateTime.utc(year, month, day, event.recurrenceHour).add(availability);
  return SpecialAdventureWindow(
    event: event,
    key: '${event.id}:year:$year',
    startsAt: start,
    endsAt: _amsterdamWallTimeToUtc(
      endWall.year,
      endWall.month,
      endWall.day,
      endWall.hour,
    ),
  );
}

List<SpecialAdventureWindow> specialAdventureWindowsAt(DateTime instant) {
  final windows = <SpecialAdventureWindow>[];
  final utc = instant.toUtc();
  final amsterdamYear = utc.add(_amsterdamOffsetAtUtc(utc)).year;
  for (final event in specialAdventureEventCatalog) {
    final initial = _initialSpecialWindow(event);
    if (initial.contains(instant)) windows.add(initial);
    // A December occurrence can remain active into the next Amsterdam year.
    for (final year in [amsterdamYear - 1, amsterdamYear]) {
      final annual = _annualSpecialWindow(event, year);
      if (annual != null && annual.contains(instant)) windows.add(annual);
    }
  }
  return windows;
}

/// Includes the event itself and the three-day results window.
List<SpecialAdventureWindow> specialAdventureRankingWindowsAt(
    DateTime instant) {
  final utc = instant.toUtc();
  final year = utc.add(_amsterdamOffsetAtUtc(utc)).year;
  final candidates = [
    for (final event in specialAdventureEventCatalog) ...[
      _initialSpecialWindow(event),
      for (final y in [year - 1, year])
        if (_annualSpecialWindow(event, y) case final window?) window,
    ],
  ];
  return candidates
      .where((w) =>
          !utc.isBefore(w.startsAt) &&
          utc.isBefore(w.endsAt.add(w.event.rankingVisibleAfterEvent)))
      .toList();
}

SpecialAdventureWindow? specialAdventureWindowAt(DateTime instant) {
  final windows = specialAdventureWindowsAt(instant);
  return windows.isEmpty ? null : windows.first;
}

List<SpecialAdventureWindow> nextSpecialAdventureWindowsAfter(
  DateTime instant,
) {
  final utc = instant.toUtc();
  final amsterdamYear =
      utc.add(_amsterdamOffsetAtUtc(utc)).year.clamp(2027, 9996).toInt();
  final result = <SpecialAdventureWindow>[];
  for (final event in specialAdventureEventCatalog) {
    final candidates = <SpecialAdventureWindow>[_initialSpecialWindow(event)];
    for (var year = amsterdamYear; year <= amsterdamYear + 2; year++) {
      final annual = _annualSpecialWindow(event, year);
      if (annual != null) candidates.add(annual);
    }
    candidates.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final future = candidates
        .where((window) => window.startsAt.isAfter(utc))
        .toList(growable: false);
    if (future.isNotEmpty) result.add(future.first);
  }
  return result;
}

SpecialAdventureWindow nextSpecialAdventureWindowAfter(DateTime instant) {
  final windows = nextSpecialAdventureWindowsAfter(instant)
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  if (windows.isEmpty) {
    throw StateError('No future Special Adventure is configured.');
  }
  return windows.first;
}

/// Stable weekly slot anchored to Sunday 12:00 in Europe/Amsterdam, including
/// the European daylight-saving transition rules used by the Netherlands.
int _amsterdamGroupAdventureSlot(DateTime instant) {
  final utc = instant.toUtc();
  final wallTime = utc.add(_amsterdamOffsetAtUtc(utc));
  var latestSundayNoon = DateTime.utc(
    wallTime.year,
    wallTime.month,
    wallTime.day,
    12,
  ).subtract(Duration(days: wallTime.weekday % 7));
  if (wallTime.isBefore(latestSundayNoon)) {
    latestSundayNoon = latestSundayNoon.subtract(const Duration(days: 7));
  }
  const anchor = Duration(days: 7);
  return latestSundayNoon
          .difference(DateTime.utc(2020, DateTime.january, 5, 12))
          .inDays ~/
      anchor.inDays;
}

DateTime _nextAmsterdamGroupAdventureAt(DateTime instant) {
  final utc = instant.toUtc();
  final wallTime = utc.add(_amsterdamOffsetAtUtc(utc));
  var daysUntilSunday = (DateTime.sunday - wallTime.weekday) % 7;
  var candidateWall = DateTime.utc(
    wallTime.year,
    wallTime.month,
    wallTime.day + daysUntilSunday,
    12,
  );
  if (!candidateWall.isAfter(wallTime)) {
    candidateWall = candidateWall.add(const Duration(days: 7));
  }
  for (final offset in const [Duration(hours: 2), Duration(hours: 1)]) {
    final candidateUtc = candidateWall.subtract(offset);
    if (_amsterdamOffsetAtUtc(candidateUtc) == offset) {
      return instant.isUtc ? candidateUtc : candidateUtc.toLocal();
    }
  }
  final fallback = candidateWall.subtract(const Duration(hours: 1));
  return instant.isUtc ? fallback : fallback.toLocal();
}

extension DragonHavenSystems on HouseholdProvider {
  static const int maxDragonsPerTowerFloor = towerFloorDragonCapacity;

  DateTime get currentTime => _clock();

  bool _isSimulatedSeasonalPreview(String? key) =>
      key?.contains(':preview:') == true && !persistentSeasonalPreviewRewards;

  bool isSimulatedSeasonalPreviewKey(String? key) =>
      _isSimulatedSeasonalPreview(key);

  List<SpecialAdventureWindow> _activeSpecialAdventureWindows(DateTime now) {
    final windows = specialAdventureWindowsAt(now)
        .where((window) =>
            seasonalEventDismissedUntil[window.event.id]?.isAfter(now) != true)
        .toList();
    seasonalEventPreviewExpiresAt.removeWhere(
      (_, expiresAt) => !expiresAt.isAfter(now),
    );
    for (final entry in seasonalEventPreviewExpiresAt.entries) {
      final event = specialAdventureEventById(entry.key);
      if (event == null) continue;
      final startsAt =
          entry.value.subtract(Duration(hours: event.previewHours));
      windows.add(SpecialAdventureWindow(
        event: event,
        key: '${event.id}:preview:${entry.value.millisecondsSinceEpoch}',
        startsAt: startsAt,
        endsAt: entry.value,
      ));
    }
    windows.sort((a, b) {
      final preview = (a.key.contains(':preview:') ? 0 : 1)
          .compareTo(b.key.contains(':preview:') ? 0 : 1);
      if (preview != 0) return preview;
      final start = b.startsAt.compareTo(a.startsAt);
      return start == 0 ? a.key.compareTo(b.key) : start;
    });
    return windows.take(1).toList();
  }

  List<SpecialAdventureWindow> get activeSpecialAdventureWindows =>
      List.unmodifiable(_activeSpecialAdventureWindows(_clock()));

  Future<bool> refreshSpecialAdventureNotifications() async {
    // Retire IDs from the old December-start schedule.
    await HavenNotifications.cancel(
        'special-adventure-new_year_first_dawn:launch:2026');
    await HavenNotifications.cancel(
        'special-adventure-new_year_first_dawn:year:2027');
    if (!notificationEnabled(HavenNotificationCategory.specialEvents)) {
      return false;
    }
    final now = _clock();
    var changed = false;
    final strings = GameStrings(languageCode);
    for (final current in specialAdventureWindowsAt(now)) {
      if (seasonalEventDismissedUntil[current.event.id]?.isAfter(now) == true) {
        await HavenNotifications.cancel('special-adventure-${current.key}');
        continue;
      }
      if (!notifiedSeasonalSpecialEventKeys.contains(current.key)) {
        final adventure = AdventureCatalog.byId[current.event.adventureId];
        await HavenNotifications.specialAdventureAvailable(
          id: 'special-adventure-${current.key}',
          title: strings.pick(
            'An event has begun',
            'Er is een event begonnen',
          ),
          body: strings.pick(
            '${adventure?.titleEn ?? 'A rare route'} is live. Complete Trials and Adventures to earn your event chest.',
            '${adventure?.titleNl ?? 'Een zeldzame route'} is begonnen. Voltooi proeven en avonturen voor je eventkist.',
          ),
        );
        notifiedSeasonalSpecialEventKeys.add(current.key);
        changed = true;
      }
    }
    for (final next in nextSpecialAdventureWindowsAfter(now)) {
      if (seasonalEventDismissedUntil[next.event.id]?.isAfter(next.startsAt) ==
          true) {
        continue;
      }
      final adventure = AdventureCatalog.byId[next.event.adventureId];
      await HavenNotifications.specialAdventureAvailable(
        id: 'special-adventure-${next.key}',
        at: next.startsAt,
        title: strings.pick(
          'An event has begun',
          'Er is een event begonnen',
        ),
        body: strings.pick(
          '${adventure?.titleEn ?? 'A rare route'} is live. Complete Trials and Adventures to earn your event chest.',
          '${adventure?.titleNl ?? 'Een zeldzame route'} is begonnen. Voltooi proeven en avonturen voor je eventkist.',
        ),
      );
    }
    if (notifiedSeasonalSpecialEventKeys.length > 20) {
      notifiedSeasonalSpecialEventKeys =
          notifiedSeasonalSpecialEventKeys.skip(10).toSet();
      changed = true;
    }
    return changed;
  }

  Future<void> cancelSpecialAdventureNotifications() async {
    final now = _clock();
    final windows = <SpecialAdventureWindow>{
      ...specialAdventureWindowsAt(now),
      ...nextSpecialAdventureWindowsAfter(now),
    };
    for (final window in windows) {
      await HavenNotifications.cancel('special-adventure-${window.key}');
    }
  }

  DateTime? nextAdventureRefreshAt(
    AdventureKind kind, {
    DateTime? from,
  }) {
    final now = from ?? _clock();
    return switch (kind) {
      AdventureKind.mini =>
        _adventureRefillBoundary(now, 15).add(const Duration(minutes: 15)),
      AdventureKind.short =>
        _adventureRefillBoundary(now, 60).add(const Duration(hours: 1)),
      AdventureKind.long => now.isUtc
          ? DateTime.utc(now.year, now.month, now.day + 1)
          : DateTime(now.year, now.month, now.day + 1),
      AdventureKind.group => _nextAmsterdamGroupAdventureAt(now),
      AdventureKind.special => null,
    };
  }

  Duration? adventureRefreshRemaining(
    AdventureKind kind, {
    DateTime? from,
  }) {
    final now = from ?? _clock();
    final refreshAt = nextAdventureRefreshAt(kind, from: now);
    if (refreshAt == null) return null;
    final remaining = refreshAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  DateTime nextTrialRefreshAt({DateTime? from}) {
    final now = from ?? _clock();
    return _adventureRefillBoundary(now, 15).add(const Duration(minutes: 15));
  }

  Duration trialRefreshRemaining({DateTime? from}) {
    final now = from ?? _clock();
    final remaining = nextTrialRefreshAt(from: now).difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  List<Pet> get ownedDragons => [
        if (!pet.isEgg) pet,
        ...sanctuaryDragons.where((dragon) => !dragon.isEgg),
      ];
  List<Pet> get visitingDragons => releasedDragons
      .where(
          (dragon) => returningVisitors[dragon.id]?.isAfter(_clock()) == true)
      .toList(growable: false);
  List<Pet> get towerDragons {
    final result = <Pet>[];
    final floorCounts = <int, int>{};
    for (final dragon in [
      ...ownedDragons.where((dragon) => dragon.roamsTower),
      ...visitingDragons,
    ]) {
      final floor = dragon.currentFloorIndex;
      if (floor < 0 || floor >= towerFloorRoomIds.length) continue;
      final count = floorCounts[floor] ?? 0;
      if (count >= maxDragonsPerTowerFloor) continue;
      result.add(dragon);
      floorCounts[floor] = count + 1;
    }
    return result;
  }

  Pet get towerControllableDragon => ownedDragons.firstWhere(
        (dragon) => dragon.favorite,
        orElse: () => pet,
      );

  int get coins => pet.coins;
  int get gems => pet.gems;
  int get towerFloorCount => towerFloorRoomIds.length;
  bool get dragonSchoolUnlocked => towerFloorCount >= 5;
  int get towerRoamingCapacity => towerFloorCount * maxDragonsPerTowerFloor;
  int get selectedRoamingDragonCount =>
      ownedDragons.where((dragon) => dragon.roamsTower).length;
  bool get hasSpectralCollection => prismaticForms.isNotEmpty;

  Future<bool> recordDragonSchoolScore(String gameId, int score) async {
    if (!dragonSchoolUnlocked || gameId.trim().isEmpty || score < 0) {
      return false;
    }
    final oldScore = dragonSchoolRecords[gameId] ?? 0;
    if (score <= oldScore) return false;
    dragonSchoolRecords[gameId] = score.clamp(0, 1000000000);
    await _notifyAndSave();
    return true;
  }

  ({
    DragonSchoolGameDefinition definition,
    List<Pet> participants,
    Pet? mentor
  })? dragonSchoolEnrollment(
      {required String gameId,
      required List<String> dragonIds,
      String? mentorDragonId}) {
    final definition = dragonSchoolGameById(gameId);
    final uniqueIds = dragonIds.toSet().toList(growable: false);
    if (!dragonSchoolUnlocked ||
        definition == null ||
        uniqueIds.length != dragonIds.length ||
        uniqueIds.length < definition.minimumDragons ||
        uniqueIds.length > definition.maximumDragons) {
      return null;
    }

    final participants = <Pet>[];
    for (final id in uniqueIds) {
      final matches = ownedDragons.where((dragon) => dragon.id == id);
      if (matches.isEmpty) {
        return null;
      }
      final dragon = matches.first;
      if (dragon.isEgg ||
          dragon.activeAdventureId != null ||
          dragon.dragonSchoolComplete ||
          dragon.schoolAttempts(definition.id) >=
              dragonSchoolAttemptsPerLesson) {
        return null;
      }
      participants.add(dragon);
    }

    Pet? mentor;
    if (mentorDragonId != null) {
      final matches = ownedDragons.where(
        (dragon) =>
            dragon.id == mentorDragonId &&
            !uniqueIds.contains(dragon.id) &&
            dragon.stage == DragonStage.ascended &&
            dragon.activeAdventureId == null,
      );
      final hasYoungPupil = participants.any(
        (dragon) =>
            dragon.stage == DragonStage.hatchling ||
            dragon.stage == DragonStage.wyrmling,
      );
      if (matches.isEmpty || !hasYoungPupil) {
        return null;
      }
      mentor = matches.first;
    }

    return (definition: definition, participants: participants, mentor: mentor);
  }

  Future<DragonSchoolLessonResult> completeDragonSchoolLesson({
    required String gameId,
    required int score,
    required List<String> dragonIds,
    String? mentorDragonId,
  }) async {
    final enrollment = dragonSchoolEnrollment(
        gameId: gameId, dragonIds: dragonIds, mentorDragonId: mentorDragonId);
    if (score < 0 || enrollment == null) {
      return const DragonSchoolLessonResult(
          accepted: false, keeperBestImproved: false);
    }
    final (:definition, :participants, :mentor) = enrollment;
    final oldKeeperBest = dragonSchoolRecords[definition.id] ?? 0;
    final keeperBestImproved = score > oldKeeperBest;
    if (keeperBestImproved) {
      dragonSchoolRecords[definition.id] = score.clamp(0, 1000000000);
    }

    final newStarsByDragon = <String, int>{};
    final xpByDragon = <String, int>{};
    final graduatedDragonIds = <String>{};
    final finalizedDragonIds = <String>{};
    final attemptsByDragon = <String, int>{};
    final earnedStars = definition.starsForScore(score);
    for (final dragon in participants) {
      final wasComplete = dragon.dragonSchoolComplete;
      final nextAttempts = dragon.schoolAttempts(definition.id) + 1;
      dragon.dragonSchoolAttempts[definition.id] = nextAttempts;
      attemptsByDragon[dragon.id] = nextAttempts;
      final previousStars = dragon.schoolStars(definition.id);
      if (score > dragon.schoolBest(definition.id)) {
        dragon.dragonSchoolRecords[definition.id] = score.clamp(0, 1000000000);
      }
      var grantedXp = 0;
      var newStars = 0;
      if (earnedStars > previousStars) {
        newStars = earnedStars - previousStars;
        dragon.dragonSchoolStars[definition.id] = earnedStars;
        grantedXp = _grantDragonXp(dragon, newStars * 5);
        newStarsByDragon[dragon.id] = newStars;
        xpByDragon[dragon.id] = grantedXp;

        for (var index = 0; index < newStars; index++) {
          final focus = definition.focus ?? _lowestSchoolExpertise(dragon);
          dragon.addTraining(focus, 1);
        }
      }

      if (!wasComplete && dragon.dragonSchoolComplete) {
        finalizedDragonIds.add(dragon.id);
        if (dragon.dragonSchoolGraduated) graduatedDragonIds.add(dragon.id);
        final outcome = dragon.dragonSchoolOutcome;
        final message = switch (outcome) {
          DragonSchoolOutcome.valedictorian =>
            '${dragon.displayName} became Dragon Academy Valedictorian with 30 stars.',
          DragonSchoolOutcome.dropout =>
            '${dragon.displayName} finished all lessons as a Dragon Academy Dropout.',
          _ =>
            '${dragon.displayName} completed Dragon Academy as ${outcome.titleEn}.',
        };
        _addActivity(
          message: message,
          type: ActivityType.milestone,
          code: ActivityCode.bonusFound,
          subject: 'dragon-school-final:${outcome.name}:${dragon.id}',
          xp: grantedXp,
        );
      } else if (newStars > 0) {
        _addActivity(
          message:
              '${dragon.displayName} earned $newStars new Dragon Academy ${newStars == 1 ? 'star' : 'stars'}.',
          type: ActivityType.milestone,
          code: ActivityCode.bonusFound,
          subject: 'dragon-school:${definition.id}:${dragon.id}',
          xp: grantedXp,
        );
      }
    }

    if (mentor != null) {
      mentor.dragonSchoolMentorLessons =
          (mentor.dragonSchoolMentorLessons + 1).clamp(0, 1000000000);
    }
    _evaluateAchievements();
    await _notifyAndSave();
    return DragonSchoolLessonResult(
      accepted: true,
      keeperBestImproved: keeperBestImproved,
      newStarsByDragon: newStarsByDragon,
      xpByDragon: xpByDragon,
      graduatedDragonIds: graduatedDragonIds,
      finalizedDragonIds: finalizedDragonIds,
      attemptsByDragon: attemptsByDragon,
    );
  }

  Future<bool> graduateDragonFromAcademy(String dragonId) async {
    final matches = ownedDragons.where((dragon) => dragon.id == dragonId);
    if (matches.isEmpty) return false;
    final dragon = matches.first;
    if (!dragon.canGraduateDragonSchoolEarly) return false;

    dragon.dragonSchoolFinalizedEarly = true;
    final outcome = dragon.dragonSchoolOutcome;
    final message = switch (outcome) {
      DragonSchoolOutcome.valedictorian =>
        '${dragon.displayName} became Dragon Academy Valedictorian with 30 stars.',
      _ =>
        '${dragon.displayName} graduated early from Dragon Academy as ${outcome.titleEn}.',
    };
    _addActivity(
      message: message,
      type: ActivityType.milestone,
      code: ActivityCode.bonusFound,
      subject: 'dragon-school-final:${outcome.name}:${dragon.id}',
    );
    _evaluateAchievements();
    await _notifyAndSave();
    return true;
  }

  TrainingFocus _lowestSchoolExpertise(Pet dragon) {
    final values = TrainingFocus.values.toList(growable: false)
      ..sort((a, b) {
        final comparison =
            dragon.trainingFor(a).compareTo(dragon.trainingFor(b));
        return comparison != 0 ? comparison : a.index.compareTo(b.index);
      });
    return values.first;
  }

  bool roamIdleDragons() {
    final accessible = <int>[
      for (var index = 0; index < towerFloorRoomIds.length; index++)
        if (!damagedTowerFloors.contains(index)) index,
    ];
    if (accessible.isEmpty) return false;

    var changed = false;
    final roaming = towerDragons;
    for (final dragon in roaming) {
      if (!dragon.roamsTower || dragon.activeAdventureId != null) continue;
      final needsRoom = !accessible.contains(dragon.currentFloorIndex) ||
          towerFloorRoomIds[dragon.currentFloorIndex] != dragon.currentRoomId;
      if (!needsRoom && _random.nextDouble() >= .20) continue;

      final lineage = dragon.lineage;
      final available = accessible.where((floor) {
        return roaming.where((candidate) {
              return candidate.id != dragon.id &&
                  candidate.currentFloorIndex == floor;
            }).length <
            maxDragonsPerTowerFloor;
      }).toList(growable: false);
      if (available.isEmpty) continue;
      final preferred = <int>[
        ...available.where(
            (index) => towerFloorRoomIds[index] == lineage.primaryRoomId),
        ...available.where(
            (index) => towerFloorRoomIds[index] == lineage.primaryRoomId),
        ...available.where((index) =>
            lineage.secondaryRoomIds.contains(towerFloorRoomIds[index])),
      ];
      final alternatives = available
          .where((index) => !preferred.contains(index))
          .toList(growable: false);
      final usePreferred = preferred.isNotEmpty &&
          (alternatives.isEmpty || _random.nextDouble() < .65);
      final choices = usePreferred ? preferred : alternatives;
      final nextFloor = choices[_random.nextInt(choices.length)];
      if (nextFloor != dragon.currentFloorIndex || needsRoom) {
        dragon
          ..currentFloorIndex = nextFloor
          ..currentRoomId = towerFloorRoomIds[nextFloor];
        changed = true;
      }
    }
    return changed;
  }

  Future<String?> maybeTriggerRoomInteraction(
      String roomId, int floorIndex) async {
    final event = await triggerRoomInteraction(roomId, floorIndex);
    if (event == null) return null;
    final dragon = ownedDragons.firstWhere((d) => d.id == event.dragonId);
    final interaction = [...towerInteractions, roomOnlyInteraction]
        .firstWhere((i) => i.id == event.interactionId);
    return GameStrings(languageCode)
        .pick(interaction.messageEn, interaction.messageNl)
        .replaceAll('{dragon}', dragon.displayName);
  }

  /// Public display identities only; no translated text or rewards come from
  /// the caller. The same private roll and cooldown serve local and server play.
  Future<({String dragonId, String interactionId})?> triggerRoomInteraction(
      String roomId, int floorIndex) async {
    if (floorIndex < 0 ||
        floorIndex >= towerFloorRoomIds.length ||
        towerFloorRoomIds[floorIndex] != roomId ||
        damagedTowerFloors.contains(floorIndex)) {
      return null;
    }
    final now = _clock();
    final candidates = ownedDragons.where((dragon) {
      if (dragon.activeAdventureId != null ||
          dragon.currentRoomId != roomId ||
          dragon.currentFloorIndex != floorIndex) {
        return false;
      }
      final lineage = dragon.lineage;
      if (lineage.primaryRoomId != roomId &&
          !lineage.secondaryRoomIds.contains(roomId)) {
        return false;
      }
      final previous = rareInteractionAt[dragon.id];
      return previous == null ||
          now.difference(previous) >= const Duration(hours: 12);
    }).toList(growable: false);
    if (candidates.isEmpty || _random.nextDouble() >= .05) return null;

    final dragon = candidates[_random.nextInt(candidates.length)];
    final tags = <String>{
      for (final placement in placementsForRoom(roomId))
        ...?shopItemById(placement.itemId)?.interactionTags,
    };
    final matching = towerInteractions
        .where((interaction) => tags.contains(interaction.requiredTag))
        .toList(growable: false);
    final interaction = matching.isEmpty
        ? roomOnlyInteraction
        : matching[_random.nextInt(matching.length)];
    rareInteractionAt[dragon.id] = now;
    await _notifyAndSave();
    return (dragonId: dragon.id, interactionId: interaction.id);
  }

  Future<bool> callControllableDragonToRoom(
      String roomId, int floorIndex) async {
    final dragon = towerControllableDragon;
    if (dragon.isEgg ||
        !dragon.roamsTower ||
        dragon.activeAdventureId != null ||
        floorIndex < 0 ||
        floorIndex >= towerFloorRoomIds.length ||
        towerFloorRoomIds[floorIndex] != roomId ||
        damagedTowerFloors.contains(floorIndex) ||
        dragon.currentFloorIndex == floorIndex ||
        _visibleFloorOccupancy(floorIndex, exceptDragonId: dragon.id) >=
            maxDragonsPerTowerFloor) {
      return false;
    }
    dragon
      ..currentFloorIndex = floorIndex
      ..currentRoomId = roomId;
    await _notifyAndSave();
    return true;
  }

  Future<DragonRoamingResult> setDragonRoaming(
      String dragonId, bool enabled) async {
    final dragon = ownedDragons.cast<Pet?>().firstWhere(
          (candidate) => candidate?.id == dragonId,
          orElse: () => null,
        );
    if (dragon == null) return DragonRoamingResult.dragonNotFound;
    if (dragon.roamsTower == enabled) {
      if (!enabled) return DragonRoamingResult.unchanged;
      final previousFloor = dragon.currentFloorIndex;
      final previousRoom = dragon.currentRoomId;
      _normalizeRoamingState();
      if (dragon.currentFloorIndex != previousFloor ||
          dragon.currentRoomId != previousRoom) {
        await _notifyAndSave();
        return DragonRoamingResult.updated;
      }
      return DragonRoamingResult.unchanged;
    }
    if (enabled && selectedRoamingDragonCount >= towerRoamingCapacity) {
      return DragonRoamingResult.towerFull;
    }
    final targetFloor = enabled ? _availableFloorFor(dragon) : null;
    if (enabled && targetFloor == null) return DragonRoamingResult.towerFull;
    dragon.roamsTower = enabled;
    if (enabled &&
        targetFloor != null &&
        (dragon.currentFloorIndex != targetFloor ||
            towerFloorRoomIds[targetFloor] != dragon.currentRoomId)) {
      dragon
        ..currentFloorIndex = targetFloor
        ..currentRoomId = towerFloorRoomIds[targetFloor];
    }
    await _notifyAndSave();
    return DragonRoamingResult.updated;
  }

  Future<bool> clearDragonsFromRoom(int floorIndex) async {
    final alternatives = <int>[
      for (var index = 0; index < towerFloorRoomIds.length; index++)
        if (index != floorIndex && !damagedTowerFloors.contains(index)) index,
    ].toList(growable: false);
    if (alternatives.isEmpty) return false;
    final dragons = towerDragons
        .where((dragon) =>
            dragon.activeAdventureId == null &&
            dragon.currentFloorIndex == floorIndex)
        .toList()
      ..sort((a, b) => a.acquiredAt.compareTo(b.acquiredAt));
    if (dragons.isEmpty) return true;
    final occupancy = <int, int>{
      for (final floor in alternatives)
        floor: _visibleFloorOccupancy(
          floor,
          exceptDragonIds: dragons.map((dragon) => dragon.id).toSet(),
        ),
    };
    final openSlots = occupancy.values.fold<int>(
      0,
      (total, count) => total + max(0, maxDragonsPerTowerFloor - count),
    );
    if (openSlots < dragons.length) return false;
    for (final dragon in dragons) {
      final available = alternatives
          .where((floor) => (occupancy[floor] ?? 0) < maxDragonsPerTowerFloor)
          .toList(growable: false);
      if (available.isEmpty) return false;
      available
          .sort((a, b) => (occupancy[a] ?? 0).compareTo(occupancy[b] ?? 0));
      final targetFloor = available.first;
      dragon
        ..currentFloorIndex = targetFloor
        ..currentRoomId = towerFloorRoomIds[targetFloor];
      occupancy[targetFloor] = (occupancy[targetFloor] ?? 0) + 1;
    }
    await _notifyAndSave();
    return true;
  }

  Future<void> completeOnboarding(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 24) return;
    accountName = normalized;
    onboardingComplete = true;
    await _notifyAndSave();
    await _scheduleEggReadyNotification(pet);
  }

  Future<void> updateAccountName(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty ||
        normalized.length > 24 ||
        normalized == accountName) {
      return;
    }
    accountName = normalized;
    await _notifyAndSave();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    if (musicEnabled == enabled) return;
    musicEnabled = enabled;
    await HavenAudio.applyPreferences(
      musicEnabled: musicEnabled,
      soundEffectsEnabled: soundEffectsEnabled,
      musicStyle: musicStyle,
    );
    await _syncJukeboxAudio(force: true);
    await _notifyAndSave();
  }

  Future<void> setMusicStyle(HavenMusicStyle style) async {
    if (musicStyle == style) return;
    musicStyle = style;
    await HavenAudio.applyPreferences(
      musicEnabled: musicEnabled,
      soundEffectsEnabled: soundEffectsEnabled,
      musicStyle: musicStyle,
    );
    await _notifyAndSave();
  }

  Future<void> setSoundEffectsEnabled(bool enabled) async {
    if (soundEffectsEnabled == enabled) return;
    soundEffectsEnabled = enabled;
    await HavenAudio.applyPreferences(
      musicEnabled: musicEnabled,
      soundEffectsEnabled: soundEffectsEnabled,
      musicStyle: musicStyle,
    );
    await _notifyAndSave();
  }

  List<AdventureDefinition> adventuresFor(AdventureKind kind) {
    _refreshAdventureRuns();
    final now = _clock();
    if (kind == AdventureKind.special) {
      final available = <AdventureDefinition>[];
      final returningId = returningSpecialAdventureId;
      if (returningId != null &&
          returningSpecialAvailableUntil?.isAfter(now) == true) {
        final definition = AdventureCatalog.byId[returningId];
        if (definition != null) available.add(definition);
      }
      return available;
    }
    if (kind == AdventureKind.group) {
      final slot = _amsterdamGroupAdventureSlot(now);
      return [AdventureCatalog.group[(slot * 17).abs() % 200]];
    }

    final source = switch (kind) {
      AdventureKind.mini => AdventureCatalog.mini,
      AdventureKind.short => AdventureCatalog.short,
      AdventureKind.long => AdventureCatalog.long,
      AdventureKind.group ||
      AdventureKind.special =>
        const <AdventureDefinition>[],
    };
    final ids = adventureOptionIds.putIfAbsent(kind, () => <String>[]);
    ids.removeWhere((id) =>
        AdventureCatalog.byId[id]?.kind != kind ||
        adventureRuns.any((run) => run.adventureId == id));

    final seed = now.millisecondsSinceEpoch ~/
        switch (kind) {
          AdventureKind.mini => const Duration(minutes: 15).inMilliseconds,
          AdventureKind.short => Duration.millisecondsPerHour,
          _ => Duration.millisecondsPerDay,
        };
    int refillCount;
    if (kind == AdventureKind.mini) {
      final currentBoundary = _adventureRefillBoundary(now, 15);
      final previous = miniAdventureRefilledAt;
      if (previous == null) {
        refillCount = 3;
        miniAdventureRefilledAt = currentBoundary;
      } else {
        final previousBoundary = _adventureRefillBoundary(previous, 15);
        final elapsedSlots =
            currentBoundary.difference(previousBoundary).inMinutes ~/ 15;
        refillCount = elapsedSlots.clamp(0, 3);
        if (currentBoundary.isAfter(previousBoundary)) {
          miniAdventureRefilledAt = currentBoundary;
        }
      }
    } else if (kind == AdventureKind.short) {
      final currentBoundary = _adventureRefillBoundary(now, 60);
      final previous = shortAdventureRefilledAt;
      if (previous == null) {
        refillCount = 3;
        shortAdventureRefilledAt = currentBoundary;
      } else {
        final previousBoundary = _adventureRefillBoundary(previous, 60);
        final elapsedHours =
            currentBoundary.difference(previousBoundary).inHours;
        refillCount = elapsedHours.clamp(0, 3);
        if (currentBoundary.isAfter(previousBoundary)) {
          shortAdventureRefilledAt = currentBoundary;
        }
      }
    } else {
      final day = HouseholdProvider._dayKey(now);
      final newDay = longAdventureRefillDay.isEmpty ||
          day.compareTo(longAdventureRefillDay) > 0;
      refillCount = newDay ? 3 : 0;
      if (newDay) longAdventureRefillDay = day;
    }
    _addAdventureOptions(
      ids: ids,
      source: source,
      count: refillCount.clamp(0, 3 - ids.length),
      seed: seed,
    );
    return ids
        .map((id) => AdventureCatalog.byId[id])
        .whereType<AdventureDefinition>()
        .toList(growable: false);
  }

  Future<WayfinderSigilUseResult> useWayfinderSigil(
    AdventureKind kind, {
    String? replaceAdventureId,
  }) async {
    if (usableRelicCount(MysticRelic.wayfinderSigil) <= 0) {
      return WayfinderSigilUseResult.notOwned;
    }
    if (kind != AdventureKind.mini &&
        kind != AdventureKind.short &&
        kind != AdventureKind.long) {
      return WayfinderSigilUseResult.unsupportedAdventure;
    }
    adventuresFor(kind);
    final ids = adventureOptionIds.putIfAbsent(kind, () => <String>[]);
    if (replaceAdventureId != null && !ids.contains(replaceAdventureId)) {
      return WayfinderSigilUseResult.adventureNotFound;
    }
    if (replaceAdventureId == null && ids.length >= 3) {
      return WayfinderSigilUseResult.noCapacity;
    }
    final source = switch (kind) {
      AdventureKind.mini => AdventureCatalog.mini,
      AdventureKind.short => AdventureCatalog.short,
      AdventureKind.long => AdventureCatalog.long,
      AdventureKind.group ||
      AdventureKind.special =>
        const <AdventureDefinition>[],
    };
    if (replaceAdventureId != null) {
      ids.remove(replaceAdventureId);
    }
    final candidates = source
        .where(
          (adventure) =>
              !ids.contains(adventure.id) &&
              adventure.id != replaceAdventureId &&
              !adventureRuns.any((run) => run.adventureId == adventure.id),
        )
        .toList(growable: false);
    if (candidates.isEmpty) {
      if (replaceAdventureId != null) ids.add(replaceAdventureId);
      return WayfinderSigilUseResult.noCapacity;
    }
    final replacement = candidates[_random.nextInt(candidates.length)];
    ids.add(replacement.id);
    _consumeRelic(MysticRelic.wayfinderSigil);
    _addActivity(
      message: replaceAdventureId == null
          ? 'A Wayfinder Sigil discovered ${replacement.titleEn}.'
          : 'A Wayfinder Sigil rerolled an Adventure into ${replacement.titleEn}.',
      type: ActivityType.discovery,
      code: ActivityCode.bonusFound,
      subject: '${MysticRelic.wayfinderSigil.name}:${kind.name}',
    );
    await _notifyAndSave();
    return WayfinderSigilUseResult.changed;
  }

  List<TrialOffer> get availableTrials {
    _refreshTrialOffers();
    return List.unmodifiable(trialOffers);
  }

  int accountTrialBest(TrialKind kind) => ownedDragons.fold(
        0,
        (best, dragon) => max(best, dragon.trialBest(kind.name)),
      );

  bool _refreshTrialOffers() {
    final now = _clock();
    final offerCountBeforeExpiry = trialOffers.length;
    final activeEventKeys =
        _activeSpecialAdventureWindows(now).map((window) => window.key).toSet();
    trialOffers.removeWhere((offer) =>
        offer.definition.isSeasonal &&
        offer.startedAt == null &&
        !activeEventKeys.contains(offer.specialEventKey));
    final currentBoundary = _adventureRefillBoundary(now, 15);
    final previous = trialRefilledAt;
    var refillCount = 0;
    if (previous == null) {
      refillCount = 3;
    } else {
      final previousBoundary = _adventureRefillBoundary(previous, 15);
      refillCount =
          (currentBoundary.difference(previousBoundary).inMinutes ~/ 15)
              .clamp(0, 3)
              .toInt();
    }
    final oldBoundary = trialRefilledAt;
    if (previous == null || currentBoundary.isAfter(previous)) {
      trialRefilledAt = currentBoundary;
    }
    var added = false;
    final activeWindows = _activeSpecialAdventureWindows(now);
    final seasonalKinds = activeWindows
        .map((window) => trialKindByName(window.event.trialKindName))
        .whereType<TrialKind>()
        .toList(growable: false);
    final eligibleKinds = <TrialKind>[...standardTrialKinds, ...seasonalKinds];
    final activationKey =
        seasonalKinds.isEmpty ? null : activeWindows.first.key;
    final newlyActivated =
        activationKey != null && activationKey != lastTrialEventActivationKey;
    final activationChanged = activationKey != lastTrialEventActivationKey;
    lastTrialEventActivationKey = activationKey;
    if (newlyActivated) refillCount = 3;
    while (refillCount > 0 && trialOffers.length < 3) {
      final kind = newlyActivated
          ? seasonalKinds.first
          : eligibleKinds[_random.nextInt(eligibleKinds.length)];
      final eventId = trialDefinitions[kind]?.specialEventId;
      final specialWindow = eventId == null
          ? null
          : activeWindows.cast<SpecialAdventureWindow?>().firstWhere(
                (window) => window?.event.id == eventId,
                orElse: () => null,
              );
      trialOffers.add(TrialOffer(
        id: _newId(),
        kind: kind,
        appearedAt: currentBoundary,
        specialEventKey: specialWindow?.key,
      ));
      refillCount--;
      added = true;
    }
    return added ||
        activationChanged ||
        oldBoundary != trialRefilledAt ||
        offerCountBeforeExpiry != trialOffers.length;
  }

  void _scheduleTrialsFullNotification() {
    final missingOffers = 3 - trialOffers.length;
    if (missingOffers <= 0) return;
    final fullAt = nextTrialRefreshAt().add(
      Duration(minutes: 15 * (missingOffers - 1)),
    );
    final strings = GameStrings(languageCode);
    unawaited(HavenNotifications.trialsFull(
      at: fullAt,
      title: strings.pick('Three Trials are ready', 'Drie Trials staan klaar'),
      body: strings.pick(
        'Your Trial board is full. Choose a dragon and chase a new high score.',
        'Je Trial-bord is vol. Kies een draak en jaag op een nieuwe highscore.',
      ),
    ));
  }

  Future<void> dismissTrial(String offerId) async {
    _refreshTrialOffers();
    final before = trialOffers.length;
    trialOffers.removeWhere((offer) => offer.id == offerId);
    if (trialOffers.length == before) return;
    _scheduleTrialsFullNotification();
    await _notifyAndSave();
  }

  Future<bool> beginTrial(String offerId) async {
    _refreshTrialOffers();
    final index = trialOffers.indexWhere((offer) => offer.id == offerId);
    if (index < 0) return false;
    final offer = trialOffers[index];
    if (offer.startedAt != null) return true;
    if (offer.definition.isSeasonal) {
      final activeKeys = _activeSpecialAdventureWindows(_clock())
          .map((window) => window.key)
          .toSet();
      if (!activeKeys.contains(offer.specialEventKey)) return false;
    }
    trialOffers[index] = offer.copyWith(startedAt: _clock());
    await _notifyAndSave();
    return true;
  }

  Future<TrialCompletion?> completeTrial({
    required String offerId,
    required String dragonId,
    required int score,
  }) async {
    _refreshTrialOffers();
    final offerIndex = trialOffers.indexWhere((offer) => offer.id == offerId);
    if (offerIndex < 0 || score < 0) return null;
    final dragon = ownedDragons.cast<Pet?>().firstWhere(
          (candidate) => candidate?.id == dragonId,
          orElse: () => null,
        );
    if (dragon == null) return null;
    final offer = trialOffers[offerIndex];
    // Test event Trials award the ordinary Trial reward. Special Adventures
    // and Special Chests retain their separate preview exclusions.
    final testEvent = offer.specialEventKey?.contains(':preview:') == true;
    final grade = trialGradeForScore(offer.kind, score);
    final rolledReward = trialRewardForGrade(
      grade,
      _random.nextDouble(),
      relicRoll: _random.nextDouble(),
      relicChoice: _random
          .nextInt(mysticRelicDropPool(excluded: obtainedUniqueRelics).length),
      excludedRelics: obtainedUniqueRelics,
    );
    final earnedRelic = rolledReward.relic;
    final newBest = dragon.recordTrialScore(offer.kind.name, score);
    final earnedEmote = grade == TrialGrade.sPlus
        ? _rollUniqueDragonEmote(DragonEmoteSource.trial, .10)
        : null;
    pet.coins += rolledReward.coins;
    final grantedXp = _grantDragonXp(dragon, rolledReward.xp);
    final expertiseRewards = offer.definition.isSeasonal
        ? _grantSeasonalTrialExpertise(dragon, grade)
        : <TrainingFocus, int>{
            offer.definition.focus: _grantAdventureTrialExpertise(
                dragon, offer.definition.focus, rolledReward.statPoints),
          };
    final reward = TrialReward(
      grade: rolledReward.grade,
      coins: rolledReward.coins,
      xp: grantedXp,
      statPoints: expertiseRewards.values.fold(0, (sum, value) => sum + value),
      chestTier: rolledReward.chestTier,
      relic: earnedRelic,
      emote: earnedEmote,
      expertiseRewards: expertiseRewards,
    );
    final chestTier = reward.chestTier;
    if (chestTier != null) {
      chestInventory.update(
        chestTier,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final relic = reward.relic;
    if (relic != null) {
      _grantRelic(relic);
    }
    awardEventPoints(eventTrialPoints(grade));
    trialOffers.removeAt(offerIndex);
    _recordTrialStreakCompletion(_clock());
    _scheduleTrialsFullNotification();
    _evolveReadyDragons(_clock());
    _addActivity(
      message:
          '${dragon.displayName} earned ${trialGradeLabel(grade)} in ${offer.definition.titleEn}.',
      type: ActivityType.explore,
      code: ActivityCode.activityCompleted,
      subject: offer.kind.name,
      xp: reward.xp,
    );
    _evaluateAchievements();
    await _notifyAndSave();
    return TrialCompletion(
      kind: offer.kind,
      score: score,
      newDragonBest: newBest,
      reward: reward,
      testEvent: testEvent,
    );
  }

  /// Applies a server-finalized seasonal podium prize exactly once.
  ///
  /// The server owns placement and prize identity. The local save only applies
  /// the awarded cosmetic/chest and remembers the immutable prize id so a
  /// refresh, restore, or second device can never duplicate the chest.
  Future<bool> applySeasonalPodiumPrize({
    required String prizeId,
    required String eventId,
    required int position,
  }) async {
    if (prizeId.isEmpty ||
        appliedSeasonalPrizeIds.contains(prizeId) ||
        specialAdventureEventById(eventId) == null ||
        position < 1 ||
        position > 3) {
      return false;
    }
    final chest = switch (position) {
      1 => ChestTier.mythical,
      2 => ChestTier.dragon,
      _ => ChestTier.gold,
    };
    final eventSlug = switch (eventId) {
      'halloween_witchlight' => 'halloween',
      'christmas_winter_hearth' => 'christmas',
      'new_year_first_dawn' => 'new_year',
      'valentine_two_heartlights' => 'valentine',
      'pride_every_color' => 'pride',
      'harvestmoon_moonlit_orchard' => 'harvestmoon',
      'sunwake_summer_sea' => 'sunwake',
      _ => '',
    };
    if (eventSlug.isEmpty) return false;
    final medal =
        switch (position) { 1 => 'gold', 2 => 'silver', _ => 'bronze' };
    final emoteId = 'seasonal_${eventSlug}_$medal';
    if (!dragonEmotesById.containsKey(emoteId)) return false;

    appliedSeasonalPrizeIds.add(prizeId);
    chestInventory.update(chest, (count) => count + 1, ifAbsent: () => 1);
    ownedDragonEmoteIds.add(emoteId);
    seasonalPodiumEmoteWinCounts.update(
      emoteId,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    _addActivity(
      message:
          'Seasonal ranking reward claimed: #$position, ${chest.label(false)} and a podium emote.',
      type: ActivityType.discovery,
      code: ActivityCode.bonusFound,
      subject: '$eventId:$position',
    );
    await _notifyAndSave();
    return true;
  }

  bool _normalizeTrialStreakForDate(DateTime now) {
    _reconcileTrialStreakCredits();
    final today = DateTime.utc(now.year, now.month, now.day);
    if (trialStreakRewardReady) {
      if (trialStreakCarryDayKey.isEmpty) return false;
      final carriedDay = DateTime.tryParse(trialStreakCarryDayKey);
      final distance = carriedDay == null
          ? 2
          : today
              .difference(DateTime.utc(
                  carriedDay.year, carriedDay.month, carriedDay.day))
              .inDays;
      if (distance <= 1) return false;
      // The pending seven-day reward remains claimable, but a day missed
      // behind it may not survive as the first day of the next streak.
      trialStreakCreditedDayKeys.remove(trialStreakCarryDayKey);
      trialStreakCarryDayKey = '';
      return true;
    }
    if (trialStreakCount == 0) return false;
    final lastDay = DateTime.tryParse(trialStreakLastDayKey);
    if (lastDay == null) {
      trialStreakCount = 0;
      trialStreakLastDayKey = '';
      trialStreakCreditedDayKeys.clear();
      return true;
    }
    final normalizedLast =
        DateTime.utc(lastDay.year, lastDay.month, lastDay.day);
    final distance = today.difference(normalizedLast).inDays;
    if (distance <= 1) return false;
    trialStreakCount = 0;
    trialStreakLastDayKey = '';
    trialStreakCreditedDayKeys.clear();
    return true;
  }

  void _recordTrialStreakCompletion(DateTime now) {
    final dayKey = HouseholdProvider._dayKey(now);
    // A backward day cannot erase already earned progress or earn it twice.
    // Keep imported future date labels until the authoritative day catches up.
    if (dayKey.compareTo(trialStreakLastCompletionDayKey) <= 0 ||
        dayKey.compareTo(trialStreakLastDayKey) < 0) {
      return;
    }
    _normalizeTrialStreakForDate(now);
    if (dayKey == trialStreakLastCompletionDayKey ||
        trialStreakCreditedDayKeys.contains(dayKey)) {
      return;
    }
    trialStreakLastCompletionDayKey = dayKey;
    if (trialStreakRewardReady) {
      if (dayKey != trialStreakLastDayKey) {
        // At most one day may wait behind an unclaimed seven-day reward. The
        // latest completed day is retained so the next streak can continue.
        trialStreakCreditedDayKeys.remove(trialStreakCarryDayKey);
        trialStreakCreditedDayKeys.add(dayKey);
        trialStreakCarryDayKey = dayKey;
      }
      return;
    }

    if (dayKey == trialStreakLastDayKey) return;
    final lastDay = DateTime.tryParse(trialStreakLastDayKey);
    final today = DateTime.utc(now.year, now.month, now.day);
    final consecutive = lastDay != null &&
        today
                .difference(
                    DateTime.utc(lastDay.year, lastDay.month, lastDay.day))
                .inDays ==
            1;
    if (!consecutive) trialStreakCreditedDayKeys.clear();
    trialStreakCreditedDayKeys.add(dayKey);
    trialStreakCount = consecutive ? trialStreakCount + 1 : 1;
    trialStreakLastDayKey = dayKey;
    if (trialStreakCount >= 7) {
      trialStreakCount = 7;
      trialStreakRewardReady = true;
      trialStreakCarryDayKey = '';
    }
  }

  Future<ChestTier?> claimTrialStreakReward() async {
    if (!trialStreakRewardReady) return null;
    _normalizeTrialStreakForDate(_clock());
    final reward =
        _random.nextDouble() < .05 ? ChestTier.mythical : ChestTier.dragon;
    chestInventory.update(reward, (count) => count + 1, ifAbsent: () => 1);

    trialStreakRewardReady = false;
    if (trialStreakCarryDayKey.isNotEmpty) {
      trialStreakCount = 1;
      trialStreakLastDayKey = trialStreakCarryDayKey;
      trialStreakCreditedDayKeys = {trialStreakCarryDayKey};
    } else {
      trialStreakCount = 0;
      trialStreakLastDayKey = '';
      trialStreakCreditedDayKeys.clear();
    }
    trialStreakCarryDayKey = '';
    _addActivity(
      message: 'A seven-day Trial streak earned a ${reward.name} chest.',
      type: ActivityType.milestone,
      code: ActivityCode.bonusFound,
      subject: reward.name,
    );
    await _notifyAndSave();
    return reward;
  }

  void _migrateLegacyTrialStreakCredits({
    required bool hadStoredCompletionDay,
  }) {
    if (!trialStreakRewardReady &&
        trialStreakCount > 0 &&
        hadStoredCompletionDay &&
        trialStreakLastCompletionDayKey != trialStreakLastDayKey) {
      final creditedThrough =
          DateTime.tryParse(trialStreakLastCompletionDayKey);
      final countedThrough = DateTime.tryParse(trialStreakLastDayKey);
      if (creditedThrough != null && countedThrough != null) {
        final unverifiedDays = DateTime.utc(
          countedThrough.year,
          countedThrough.month,
          countedThrough.day,
        )
            .difference(DateTime.utc(
              creditedThrough.year,
              creditedThrough.month,
              creditedThrough.day,
            ))
            .inDays;
        if (unverifiedDays > 0) {
          trialStreakCount = max(0, trialStreakCount - unverifiedDays);
          trialStreakLastDayKey = trialStreakCount == 0
              ? ''
              : HouseholdProvider._dayKey(creditedThrough);
        }
      }
    }

    final endingDay = DateTime.tryParse(trialStreakLastDayKey);
    if (endingDay != null && trialStreakCount > 0) {
      for (var offset = 0; offset < trialStreakCount; offset++) {
        trialStreakCreditedDayKeys.add(
          HouseholdProvider._dayKey(
            DateTime.utc(endingDay.year, endingDay.month, endingDay.day)
                .subtract(Duration(days: offset)),
          ),
        );
      }
    }
    if (trialStreakCarryDayKey.isNotEmpty) {
      trialStreakCreditedDayKeys.add(trialStreakCarryDayKey);
    }
  }

  void _reconcileTrialStreakCredits() {
    trialStreakCreditedDayKeys = trialStreakCreditedDayKeys.where((key) {
      final parsed = DateTime.tryParse(key);
      return parsed != null && HouseholdProvider._dayKey(parsed) == key;
    }).toSet();

    if (trialStreakRewardReady) {
      trialStreakCount = 7;
      if (trialStreakCarryDayKey.isNotEmpty &&
          !trialStreakCreditedDayKeys.contains(trialStreakCarryDayKey)) {
        trialStreakCarryDayKey = '';
      }
      return;
    }
    trialStreakCarryDayKey = '';
    if (trialStreakCount <= 0) {
      trialStreakCount = 0;
      trialStreakLastDayKey = '';
      trialStreakCreditedDayKeys.clear();
      return;
    }

    final endingDay = DateTime.tryParse(trialStreakLastDayKey);
    if (endingDay == null ||
        !trialStreakCreditedDayKeys.contains(trialStreakLastDayKey)) {
      trialStreakCount = 0;
      trialStreakLastDayKey = '';
      trialStreakCreditedDayKeys.clear();
      return;
    }

    var verifiedCount = 0;
    final verifiedKeys = <String>{};
    while (verifiedCount < trialStreakCount) {
      final key = HouseholdProvider._dayKey(
        DateTime.utc(endingDay.year, endingDay.month, endingDay.day)
            .subtract(Duration(days: verifiedCount)),
      );
      if (!trialStreakCreditedDayKeys.contains(key)) break;
      verifiedKeys.add(key);
      verifiedCount++;
    }
    trialStreakCount = verifiedCount;
    trialStreakCreditedDayKeys = verifiedKeys;
    if (verifiedCount == 0) trialStreakLastDayKey = '';
  }

  void _addAdventureOptions({
    required List<String> ids,
    required List<AdventureDefinition> source,
    required int count,
    required int seed,
  }) {
    for (var offset = 0;
        offset < source.length && count > 0 && ids.length < 3;
        offset++) {
      final definition =
          source[(seed * 17 + offset * 37).abs() % source.length];
      if (ids.contains(definition.id)) continue;
      ids.add(definition.id);
      count--;
    }
  }

  List<AdventureRun> get activeAdventureRuns {
    _refreshAdventureRuns();
    return List.unmodifiable(adventureRuns);
  }

  Future<void> synchronizeOnlineTradeReservations(
    Set<String> eggIds,
    Map<String, int> chests,
    Map<String, int> relics,
  ) async {
    final normalizedChests = Map<String, int>.from(chests)
      ..removeWhere((key, value) =>
          value <= 0 ||
          !ChestTier.values
              .any((tier) => tier.name == key && tier.isTradeable));
    final normalizedRelics = Map<String, int>.from(relics)
      ..removeWhere((key, value) =>
          value <= 0 ||
          !(MysticRelic.values.any(
                (relic) => relic.name == key && !relic.isAlwaysUntradeable,
              ) ||
              RegExp(r'^chronoshard:(?:[1-8][0-9]|90)$').hasMatch(key)));
    if (setEquals(reservedOnlineTradeEggIds, eggIds) &&
        mapEquals(reservedOnlineTradeChests, normalizedChests) &&
        mapEquals(reservedOnlineTradeRelics, normalizedRelics)) {
      return;
    }
    reservedOnlineTradeEggIds = Set<String>.from(eggIds);
    reservedOnlineTradeChests = normalizedChests;
    reservedOnlineTradeRelics = normalizedRelics;
    await _notifyAndSave();
  }

  bool isEggReservedForTrade(String eggId) =>
      reservedOnlineTradeEggIds.contains(eggId);

  int tradeableChestCount(ChestTier tier) =>
      max(0, chestCount(tier) - (reservedOnlineTradeChests[tier.name] ?? 0));

  int tradeableRelicCount(MysticRelic relic) => relic.isAlwaysUntradeable
      ? 0
      : max(
          0,
          gameplayRelicCount(relic) - reservedOnlineRelicCount(relic),
        );

  Future<bool> applyOnlineTradeSettlement({
    required String tradeId,
    required String sentKind,
    required String sentKey,
    required Map<String, dynamic> sentData,
    required String receivedKind,
    required String receivedKey,
    required Map<String, dynamic> receivedData,
  }) async {
    if (appliedOnlineTradeIds.contains(tradeId)) return true;

    final sentEggIndex = sentKind == 'egg'
        ? eggStash.indexWhere((egg) => egg.id == sentKey)
        : -1;
    final sentChest = sentKind == 'chest'
        ? ChestTier.values.cast<ChestTier?>().firstWhere(
              (tier) => tier?.name == sentKey,
              orElse: () => null,
            )
        : null;
    final sentRelic = sentKind == 'relic'
        ? MysticRelic.values.cast<MysticRelic?>().firstWhere(
              (relic) => relic?.name == sentKey,
              orElse: () => null,
            )
        : null;
    final sentChronoshardReduction = sentRelic == MysticRelic.chronoshard
        ? (sentData['reductionPercent'] as num?)?.toInt()
        : null;
    final sentChronoshardInvalid = sentRelic == MysticRelic.chronoshard &&
        (sentChronoshardReduction == null ||
            sentChronoshardReduction < 10 ||
            sentChronoshardReduction > 90 ||
            !chronoshardReductions.contains(sentChronoshardReduction));
    if ((sentKind == 'egg' && sentEggIndex < 0) ||
        (sentKind == 'chest' &&
            (sentChest == null ||
                !sentChest.isTradeable ||
                chestCount(sentChest) <= 0)) ||
        (sentKind == 'relic' &&
            (sentRelic == null ||
                sentRelic.isAlwaysUntradeable ||
                gameplayRelicCount(sentRelic) <= 0 ||
                sentChronoshardInvalid)) ||
        !const {'egg', 'chest', 'relic'}.contains(sentKind)) {
      return false;
    }

    DragonEgg? receivedEgg;
    ChestTier? receivedChest;
    MysticRelic? receivedRelic;
    if (receivedKind == 'egg') {
      receivedEgg = DragonEgg.fromJson({...receivedData, 'id': receivedKey});
      if (ownedDragons.any((dragon) => dragon.id == receivedKey) ||
          nestEgg?.id == receivedKey ||
          releasedDragons.any((dragon) => dragon.id == receivedKey) ||
          eggAltar.returnedIds.contains(receivedKey) ||
          eggStash.any((egg) => egg.id == receivedKey)) {
        return false;
      }
    } else if (receivedKind == 'chest') {
      receivedChest = ChestTier.values.cast<ChestTier?>().firstWhere(
            (tier) => tier?.name == receivedKey,
            orElse: () => null,
          );
      if (receivedChest == null || !receivedChest.isTradeable) return false;
    } else if (receivedKind == 'relic') {
      receivedRelic = MysticRelic.values.cast<MysticRelic?>().firstWhere(
            (relic) => relic?.name == receivedKey,
            orElse: () => null,
          );
      if (receivedRelic == null || receivedRelic.isAlwaysUntradeable) {
        return false;
      }
      if (receivedRelic == MysticRelic.chronoshard) {
        final reduction = (receivedData['reductionPercent'] as num?)?.toInt();
        if (reduction == null || reduction < 10 || reduction > 90) {
          return false;
        }
      }
    } else {
      return false;
    }

    if (sentEggIndex >= 0) {
      eggStash.removeAt(sentEggIndex);
      eggRarityRevealedIds.remove(sentKey);
    }
    if (sentChest != null) {
      chestInventory[sentChest] = chestCount(sentChest) - 1;
    }
    if (sentRelic != null) {
      relicInventory[sentRelic] = relicCount(sentRelic) - 1;
      if (sentRelic == MysticRelic.chronoshard) {
        final reductionIndex =
            chronoshardReductions.indexOf(sentChronoshardReduction!);
        if (reductionIndex >= 0) {
          chronoshardReductions.removeAt(reductionIndex);
        }
      }
    }
    if (receivedEgg != null) {
      eggStash.add(receivedEgg);
      if (eggKnowledge(receivedEgg.id).rarity) {
        eggRarityRevealedIds.add(receivedEgg.id);
      }
    }
    if (receivedChest != null) {
      chestInventory.update(receivedChest, (value) => value + 1,
          ifAbsent: () => 1);
    }
    if (receivedRelic != null) {
      _grantRelic(
        receivedRelic,
        chronoshardReduction:
            (receivedData['reductionPercent'] as num?)?.toInt(),
      );
    }
    appliedOnlineTradeIds.add(tradeId);
    if (appliedOnlineTradeIds.length > 500) {
      appliedOnlineTradeIds = appliedOnlineTradeIds.skip(100).toSet();
    }
    _addActivity(
      message: 'A trade was completed.',
      type: ActivityType.discovery,
      code: ActivityCode.bonusFound,
      subject: tradeId,
    );
    final completedAt = _clock();
    _queuePresentation(GamePresentation(
      id: 'trade-$tradeId',
      type: GamePresentationType.trade,
      createdAt: completedAt,
      sortAt: completedAt,
      payload: {
        'sentKind': sentKind,
        'sentKey': sentKey,
        'sentData': sentData,
        'receivedKind': receivedKind,
        'receivedKey': receivedKey,
        'receivedData': receivedData,
      },
    ));
    await _notifyAndSave();
    return true;
  }

  Future<void> synchronizeOnlineGroupReservations(
    Map<String, String> reservations,
  ) async {
    var changed = false;
    for (final dragon in ownedDragons) {
      final expectedLobby = reservations[dragon.id];
      final current = dragon.activeAdventureId;
      if (current?.startsWith('online-group:') == true) {
        final expected =
            expectedLobby == null ? null : 'online-group:$expectedLobby';
        if (current != expected) {
          dragon.activeAdventureId = null;
          changed = true;
        }
      }
      if (expectedLobby != null &&
          (dragon.activeAdventureId == null ||
              dragon.activeAdventureId!.startsWith('online-group:'))) {
        final expected = 'online-group:$expectedLobby';
        if (dragon.activeAdventureId != expected) {
          dragon.activeAdventureId = expected;
          changed = true;
        }
      }
    }
    if (changed) await _notifyAndSave();
  }

  Future<void> synchronizeOnlineSeasonalPairReservations(
    Map<String, String> reservations,
  ) async {
    var changed = false;
    for (final dragon in ownedDragons) {
      final expectedAdventure = reservations[dragon.id];
      final current = dragon.activeAdventureId;
      if (current?.startsWith('online-seasonal:') == true) {
        final expected = expectedAdventure == null
            ? null
            : 'online-seasonal:$expectedAdventure';
        if (current != expected) {
          dragon.activeAdventureId = null;
          changed = true;
        }
      }
      if (expectedAdventure != null &&
          (dragon.activeAdventureId == null ||
              dragon.activeAdventureId!.startsWith('online-seasonal:'))) {
        final expected = 'online-seasonal:$expectedAdventure';
        if (dragon.activeAdventureId != expected) {
          dragon.activeAdventureId = expected;
          changed = true;
        }
      }
    }
    if (changed) await _notifyAndSave();
  }

  Future<bool> applyOnlineSeasonalPairReward({
    required String adventureId,
    required String eventId,
    required String dragonId,
    required int xp,
    required int might,
    required int arcana,
    required int spirit,
    required String specialChestId,
    required bool simulated,
  }) async {
    if (appliedOnlineSeasonalPairRewardIds.contains(adventureId)) return true;
    final event = specialAdventureEventById(eventId);
    final definition =
        event == null ? null : AdventureCatalog.byId[event.adventureId];
    final dragon = dragonById(dragonId);
    if (event == null ||
        definition == null ||
        !definition.requiresOnlinePartner ||
        dragon == null ||
        specialChestById(specialChestId) == null) {
      return false;
    }
    if (simulated && !persistentSeasonalPreviewRewards) {
      if (dragon.activeAdventureId == 'online-seasonal:$adventureId') {
        dragon.activeAdventureId = null;
      }
      appliedOnlineSeasonalPairRewardIds.add(adventureId);
      await _notifyAndSave();
      return true;
    }
    final grantedXp = _grantDragonXp(dragon, xp.clamp(0, 1000));
    _grantAdventureTrialExpertise(
        dragon, TrainingFocus.might, might.clamp(0, 25));
    _grantAdventureTrialExpertise(
        dragon, TrainingFocus.arcana, arcana.clamp(0, 25));
    _grantAdventureTrialExpertise(
        dragon, TrainingFocus.spirit, spirit.clamp(0, 25));
    final keeperBadgeId = event.rewards.keeperBadgeId;
    if (keeperBadgeId != null && keeperBadgeById(keeperBadgeId) != null) {
      ownedBadgeIds.add(keeperBadgeId);
    }
    specialChestInventory.update(
      specialChestId,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    if (dragon.activeAdventureId == 'online-seasonal:$adventureId') {
      dragon.activeAdventureId = null;
    }
    appliedOnlineSeasonalPairRewardIds.add(adventureId);
    totalAdventuresCompleted++;
    _evolveReadyDragons(_clock());
    _addActivity(
      message: '${dragon.displayName} returned from ${definition.titleEn}.',
      type: ActivityType.explore,
      code: ActivityCode.activityCompleted,
      subject: definition.id,
      xp: grantedXp,
    );
    _evaluateAchievements();
    await _notifyAndSave();
    return true;
  }

  Future<bool> applyOnlineGroupReward({
    required String lobbyId,
    required String adventureId,
    required String dragonId,
    required int xp,
    required String focus,
    required int statPoints,
    required String chestTier,
    required int participantCount,
    DateTime? completedAt,
  }) async {
    if (appliedOnlineGroupRewardIds.contains(lobbyId)) return true;
    final definition = AdventureCatalog.byId[adventureId];
    if (definition?.kind != AdventureKind.group) return false;
    final dragon = ownedDragons.cast<Pet?>().firstWhere(
          (candidate) => candidate?.id == dragonId,
          orElse: () => null,
        );
    final parsedFocus = TrainingFocus.values.cast<TrainingFocus?>().firstWhere(
          (value) => value?.name == focus,
          orElse: () => null,
        );
    final parsedChest = ChestTier.values.cast<ChestTier?>().firstWhere(
          (value) => value?.name == chestTier,
          orElse: () => null,
        );
    if (dragon == null || parsedFocus == null || parsedChest == null) {
      return false;
    }

    final grantedXp = _grantDragonXp(dragon, xp);
    _grantAdventureTrialExpertise(
      dragon,
      parsedFocus,
      statPoints.clamp(0, dragon.expertiseMaximum(parsedFocus)),
    );
    if (dragon.activeAdventureId?.startsWith('online-group:') == true) {
      dragon.activeAdventureId = null;
    }
    chestInventory.update(parsedChest, (value) => value + 1, ifAbsent: () => 1);
    totalAdventuresCompleted++;
    if (participantCount >= 4) totalGroupFourCompleted++;
    appliedOnlineGroupRewardIds.add(lobbyId);
    if (completedAt != null) recordGroupEventCompletion(lobbyId, completedAt);
    if (appliedOnlineGroupRewardIds.length > 500) {
      appliedOnlineGroupRewardIds =
          appliedOnlineGroupRewardIds.skip(100).toSet();
    }
    _evolveReadyDragons(_clock());
    _addActivity(
      message: '${dragon.displayName} returned from ${definition!.titleEn}.',
      type: ActivityType.explore,
      code: ActivityCode.activityCompleted,
      subject: definition.id,
      xp: grantedXp,
    );
    _evaluateAchievements();
    await _notifyAndSave();
    return true;
  }

  Future<AdventureStartResult> startAdventure(
    AdventureDefinition adventure, {
    String? dragonId,
    int participantCount = 1,
  }) async {
    if (!adventuresFor(adventure.kind).any((item) => item.id == adventure.id)) {
      return AdventureStartResult.unavailable;
    }
    if (pet.isEgg && sanctuaryDragons.isEmpty) {
      return AdventureStartResult.eggCannotAdventure;
    }
    if (adventure.kind == AdventureKind.group) {
      return AdventureStartResult.groupNeedsFriends;
    }
    if (adventure.requiresOnlinePartner) {
      return AdventureStartResult.groupNeedsFriends;
    }
    final candidates = ownedDragons;
    final dragon = candidates.cast<Pet?>().firstWhere(
          (candidate) =>
              candidate?.id == (dragonId ?? candidates.firstOrNull?.id),
          orElse: () => null,
        );
    if (dragon == null) return AdventureStartResult.eggCannotAdventure;
    if (dragon.activeAdventureId != null) {
      return AdventureStartResult.dragonBusy;
    }
    final now = _clock();
    if (adventure.seasonalSpecial) return AdventureStartResult.unavailable;
    final duration = expertiseAdjustedAdventureDuration(adventure, [dragon]);
    final run = AdventureRun(
      id: _newId(),
      adventureId: adventure.id,
      dragonId: dragon.id,
      startedAt: now,
      endsAt: now.add(duration),
      status: AdventureRunStatus.running,
      // Roll once when the run is persisted, but keep the result hidden until
      // completion. The completed card can then show an exact reward that
      // cannot silently change after an app restart.
      rewardTier: adventure.knownChest ?? _rollAdventureChest(adventure.kind),
      participantCount: participantCount,
    );
    dragon.activeAdventureId = run.id;
    adventureRuns.add(run);
    await _scheduleAdventureReturnNotification(run, dragon);
    adventureOptionIds[adventure.kind]?.remove(adventure.id);
    if (adventure.kind == AdventureKind.mini) {
      miniAdventureRefilledAt = now;
    } else if (adventure.kind == AdventureKind.short) {
      shortAdventureRefilledAt = now;
    }
    await _notifyAndSave();
    return AdventureStartResult.started;
  }

  DateTime adventureReturnNotificationAt(DateTime endsAt) => endsAt;

  Future<void> _scheduleAdventureReturnNotification(
    AdventureRun run,
    Pet dragon,
  ) async {
    final strings = GameStrings(languageCode);
    await HavenNotifications.schedule(
      id: 'adventure-${run.id}',
      at: adventureReturnNotificationAt(run.endsAt),
      title: strings.pick('${dragon.displayName} has returned',
          '${dragon.displayName} is teruggekeerd'),
      body: strings.pick(
        'An Adventure reward is ready in DragonHaven.',
        'Er staat een Adventure-beloning klaar in DragonHaven.',
      ),
      kind: 'adventure_complete',
    );
  }

  Future<void> _rescheduleAdventureReturnNotifications() async {
    final now = _clock();
    for (final run in adventureRuns.where(
      (run) =>
          run.status == AdventureRunStatus.running && run.endsAt.isAfter(now),
    )) {
      final dragon = dragonById(run.dragonId);
      if (dragon != null) {
        await _scheduleAdventureReturnNotification(run, dragon);
      }
    }
  }

  Future<void> dismissAdventure(AdventureDefinition adventure) async {
    if ((adventure.kind != AdventureKind.mini &&
            adventure.kind != AdventureKind.short &&
            adventure.kind != AdventureKind.long) ||
        adventureRuns.any((run) => run.adventureId == adventure.id)) {
      return;
    }
    adventureOptionIds[adventure.kind]?.remove(adventure.id);
    final now = _clock();
    if (adventure.kind == AdventureKind.mini) {
      miniAdventureRefilledAt = now;
    } else if (adventure.kind == AdventureKind.short) {
      shortAdventureRefilledAt = now;
    } else {
      final day = HouseholdProvider._dayKey(now);
      if (day.compareTo(longAdventureRefillDay) > 0) {
        longAdventureRefillDay = day;
      }
    }
    await _notifyAndSave();
  }

  Future<ChestTier?> claimAdventure(String runId) async {
    _refreshAdventureRuns();
    final index = adventureRuns.indexWhere((run) => run.id == runId);
    if (index < 0 ||
        adventureRuns[index].status != AdventureRunStatus.rewardReady) {
      return null;
    }
    final run = adventureRuns[index];
    final definition = AdventureCatalog.byId[run.adventureId];
    if (definition == null) return null;
    final dragon = ownedDragons.cast<Pet?>().firstWhere(
          (candidate) => candidate?.id == run.dragonId,
          orElse: () => null,
        );
    if (dragon == null) return null;
    final tier = run.rewardTier ?? _rollAdventureChest(definition.kind);
    if (_isSimulatedSeasonalPreview(run.specialEventKey)) {
      dragon.activeAdventureId = null;
      adventureRuns.removeAt(index);
      await _notifyAndSave();
      return tier;
    }
    final grantedXp = _grantDragonXp(dragon, definition.xp);
    _grantAdventureTrialExpertise(
        dragon, definition.focus, definition.statPoints);
    _evolveReadyDragons(_clock());
    dragon.activeAdventureId = null;
    final event = specialAdventureEventById(run.specialEventId);
    final specialChestId = event?.rewards.specialChestId;
    if (specialChestId != null) {
      specialChestInventory.update(
        specialChestId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    } else {
      chestInventory.update(tier, (value) => value + 1, ifAbsent: () => 1);
    }
    if (event != null) {
      for (final reward in event.rewards.expertiseRewards.entries) {
        _grantAdventureTrialExpertise(dragon, reward.key, reward.value);
      }
      final relics = event.rewards.randomRelicPool;
      if (relics.isNotEmpty) {
        _grantRelic(relics[_random.nextInt(relics.length)]);
      }
      if (event.rewards.musicChest && !musicChestCapacityReached) {
        chestInventory.update(
          ChestTier.music,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
      final accountTitleId = event.rewards.accountTitleId;
      if (accountTitleId != null && accountTitleById(accountTitleId) != null) {
        ownedTitleIds.add(accountTitleId);
      }
      final keeperBadgeId = event.rewards.keeperBadgeId;
      if (keeperBadgeId != null && keeperBadgeById(keeperBadgeId) != null) {
        ownedBadgeIds.add(keeperBadgeId);
      }
    }
    if (!run.eventPointsAwarded) {
      awardEventPoints(eventAdventurePoints(definition.kind),
          completedAt: run.endsAt);
    }
    adventureRuns.removeAt(index);
    totalAdventuresCompleted++;
    if (definition.kind == AdventureKind.short) totalShortAdventuresCompleted++;
    if (definition.kind == AdventureKind.group && run.participantCount >= 4) {
      totalGroupFourCompleted++;
    }
    if (definition.sinister) totalSinisterAdventuresCompleted++;
    _addActivity(
      message: '${dragon.displayName} returned from ${definition.titleEn}.',
      type: ActivityType.explore,
      code: ActivityCode.activityCompleted,
      subject: definition.id,
      xp: grantedXp,
    );
    _evaluateAchievements();
    await _notifyAndSave();
    return tier;
  }

  Future<bool> abortAdventure(String runId) async {
    _refreshAdventureRuns();
    final index = adventureRuns.indexWhere((run) => run.id == runId);
    if (index < 0) return false;
    final run = adventureRuns[index];
    final definition = AdventureCatalog.byId[run.adventureId];
    if (run.status != AdventureRunStatus.running ||
        definition == null ||
        definition.kind == AdventureKind.group ||
        definition.requiresOnlinePartner) {
      return false;
    }
    final dragon = ownedDragons.cast<Pet?>().firstWhere(
          (candidate) => candidate?.id == run.dragonId,
          orElse: () => null,
        );
    if (dragon?.activeAdventureId == run.id) {
      dragon!.activeAdventureId = null;
    }
    adventureRuns.removeAt(index);
    await HavenNotifications.cancel('adventure-${run.id}');
    await _notifyAndSave();
    return true;
  }

  bool _refreshAdventureRuns() {
    final now = _clock();
    var changed = false;
    for (var index = 0; index < adventureRuns.length; index++) {
      final run = adventureRuns[index];
      if (run.status == AdventureRunStatus.running &&
          !run.endsAt.isAfter(now)) {
        final definition = AdventureCatalog.byId[run.adventureId];
        final reward = run.rewardTier ??
            definition?.knownChest ??
            _rollAdventureChest(definition?.kind ?? AdventureKind.short);
        adventureRuns[index] = run.copyWith(
          status: AdventureRunStatus.rewardReady,
          rewardTier: reward,
        );
        changed = true;
      }
    }
    return changed;
  }

  ChestTier _rollAdventureChest(AdventureKind kind) {
    return adventureChestForRoll(kind, _random.nextDouble());
  }

  Future<void> toggleDragonExpertiseHighlight(
      String dragonId, TrainingFocus focus) async {
    final selected = ownedDragons.cast<Pet?>().firstWhere(
          (dragon) => dragon?.id == dragonId,
          orElse: () => null,
        );
    if (selected == null || selected.isEgg) return;
    if (!selected.highlightedExpertises.remove(focus)) {
      selected.highlightedExpertises.add(focus);
    }
    await _notifyAndSave();
  }

  Future<void> toggleFavorite(String dragonId) async {
    final selected = ownedDragons.cast<Pet?>().firstWhere(
          (dragon) => dragon?.id == dragonId,
          orElse: () => null,
        );
    if (selected == null || selected.favorite) return;
    for (final dragon in ownedDragons) {
      dragon.favorite = dragon.id == dragonId;
    }
    favoriteChanges++;
    _evaluateAchievements();
    await _notifyAndSave();
  }

  Future<bool> releaseDragon(String dragonId) async {
    final all = ownedDragons;
    final dragon = all.cast<Pet?>().firstWhere(
          (candidate) => candidate?.id == dragonId,
          orElse: () => null,
        );
    if (dragon == null ||
        dragon.favorite ||
        dragon.activeAdventureId != null ||
        all.length <= 1) {
      return false;
    }
    if (dragon.id == pet.id) {
      final replacement = sanctuaryDragons.removeAt(0);
      // Coins and gems belong to the keeper account. Older dragon saves may
      // contain the balance from the moment they became inactive.
      replacement.coins = pet.coins;
      replacement.gems = pet.gems;
      sanctuaryDragons.add(pet);
      pet = replacement;
      sanctuaryDragons.removeWhere((item) => item.id == dragon.id);
    } else {
      sanctuaryDragons.removeWhere((item) => item.id == dragon.id);
    }
    dragon.favorite = false;
    equippedRelicDragonIds.removeWhere((_, id) => id == dragon.id);
    if (twinstarBroochDragonId == dragon.id) {
      twinstarBroochDragonId = null;
    }
    releasedDragons.add(dragon);
    _ensureFavoriteDragon();
    _normalizeRoamingState();
    await _notifyAndSave();
    return true;
  }

  Future<TowerBuildResult> buildTowerFloor(String roomId) async {
    final room = houseRoomById(roomId);
    if (room == null || room.id == 'nest') return TowerBuildResult.invalidRoom;
    if (towerFloorRoomIds.length >= 20) return TowerBuildResult.maximumReached;
    final price = nextTowerFloorPrice;
    if (pet.coins < price) return TowerBuildResult.insufficientCoins;
    pet.coins -= price;
    towerFloorRoomIds.add(room.id);
    unlockedRoomIds.add(room.id);
    activeRoomId = room.id;
    _evaluateAchievements();
    await _notifyAndSave();
    return TowerBuildResult.built;
  }

  /// Changes the scenery of an existing floor for free. Occupants and damage
  /// stay attached to the floor; furniture layouts remain saved per room type.
  Future<bool> changeTowerFloorRoom(int index, String roomId) async {
    final room = houseRoomById(roomId);
    if (index < 0 ||
        index >= towerFloorRoomIds.length ||
        room == null ||
        room.id == 'nest') {
      return false;
    }
    if (towerFloorRoomIds[index] == room.id) return true;
    towerFloorRoomIds[index] = room.id;
    unlockedRoomIds.add(room.id);
    for (final dragon in {...ownedDragons, ...releasedDragons}) {
      if (dragon.currentFloorIndex == index) dragon.currentRoomId = room.id;
    }
    await _notifyAndSave();
    return true;
  }

  /// Reorders the visible Tower floors from top to bottom. The Rooftop Nest
  /// is not part of [towerFloorRoomIds], so it can never be moved. Dragons,
  /// visitors and floor damage follow the room they were attached to.
  Future<bool> reorderTowerFloor(
    int oldVisualIndex,
    int newVisualIndex,
  ) async {
    final count = towerFloorRoomIds.length;
    if (count < 2 ||
        oldVisualIndex < 0 ||
        oldVisualIndex >= count ||
        newVisualIndex < 0 ||
        newVisualIndex >= count ||
        oldVisualIndex == newVisualIndex) {
      return false;
    }

    final topToBottomOldIndices = List<int>.generate(
      count,
      (visualIndex) => count - visualIndex - 1,
    );
    final moved = topToBottomOldIndices.removeAt(oldVisualIndex);
    topToBottomOldIndices.insert(newVisualIndex, moved);
    final bottomToTopOldIndices = topToBottomOldIndices.reversed.toList();
    final oldRooms = List<String>.of(towerFloorRoomIds);
    towerFloorRoomIds = [
      for (final oldIndex in bottomToTopOldIndices) oldRooms[oldIndex],
    ];
    final newIndexForOld = <int, int>{
      for (var newIndex = 0;
          newIndex < bottomToTopOldIndices.length;
          newIndex++)
        bottomToTopOldIndices[newIndex]: newIndex,
    };

    for (final dragon in {...ownedDragons, ...releasedDragons}) {
      final nextFloor = newIndexForOld[dragon.currentFloorIndex];
      if (nextFloor != null) dragon.currentFloorIndex = nextFloor;
    }
    damagedTowerFloors = {
      for (final oldIndex in damagedTowerFloors)
        if (newIndexForOld[oldIndex] case final newIndex?) newIndex,
    };
    damagedTowerRepairFactors = {
      for (final entry in damagedTowerRepairFactors.entries)
        if (newIndexForOld[entry.key] case final newIndex?)
          newIndex: entry.value,
    };
    await _notifyAndSave();
    return true;
  }

  int get nextTowerFloorPrice => towerBuildPrice(towerFloorRoomIds.length);

  Future<bool> repairTowerFloor(int index) async {
    if (!damagedTowerFloors.contains(index) ||
        index >= towerFloorRoomIds.length) {
      return false;
    }
    final price = repairTowerFloorPrice(index);
    if (pet.coins < price) return false;
    pet.coins -= price;
    damagedTowerFloors.remove(index);
    damagedTowerRepairFactors.remove(index);
    await _notifyAndSave();
    return true;
  }

  int repairTowerFloorPrice(int index) {
    if (index < 0 || index >= towerFloorRoomIds.length) return 0;
    final room = houseRoomById(towerFloorRoomIds[index]);
    final factor = damagedTowerRepairFactors[index] ?? .40;
    return towerRepairPrice(room, factor);
  }

  bool _expireReturningVisitors() {
    final now = _clock();
    final before = returningVisitors.length;
    returningVisitors.removeWhere((_, until) => !until.isAfter(now));
    return returningVisitors.length != before;
  }

  Future<bool> discardEgg(String eggId) async {
    if (isEggReservedForTrade(eggId)) return false;
    final before = eggStash.length;
    eggStash.removeWhere((egg) => egg.id == eggId);
    if (eggStash.length == before) return false;
    await _notifyAndSave();
    return true;
  }

  Future<bool> upgradeDragonWard() async {
    if (dragonWardLevel >= 3 || damagedTowerFloors.isEmpty) return false;
    final price = dragonWardUpgradePrice(dragonWardLevel)!;
    if (pet.coins < price) return false;
    pet.coins -= price;
    dragonWardLevel++;
    await _notifyAndSave();
    return true;
  }

  Future<String> redeemCode(
    String rawCode, {
    String? keeperId,
  }) async {
    final code = rawCode.trim();
    if (code.isEmpty || !RegExp(r'^[A-Z0-9]+$').hasMatch(code)) {
      return 'invalid_format';
    }
    final definition = redeemCodeDefinition(code);
    if (definition == null) return 'inactive';
    final restrictedKeeperId = definition.restrictedKeeperId;
    if (restrictedKeeperId != null && keeperId != restrictedKeeperId) {
      return 'restricted';
    }
    switch (definition.rewardType) {
      case RedeemRewardType.endSeasonalEvent:
        // Online authorization is required; the UI uses the authenticated RPC.
        return 'online_login_required';
      case RedeemRewardType.dragonEmotePack:
        final pack = dragonEmotePackById(definition.rewardId);
        if (pack == null) return 'inactive';
        return await _grantDragonEmotePackContents(pack)
            ? 'redeemed_emote_pack'
            : 'already_redeemed';
      case RedeemRewardType.seasonalEventPreview:
        final event = specialAdventureEventById(definition.rewardId);
        if (event == null || event.previewHours <= 0) return 'inactive';
        final now = _clock();
        if (seasonalEventPreviewExpiresAt[event.id]?.isAfter(now) == true) {
          return 'preview_active';
        }
        seasonalEventPreviewExpiresAt = {
          event.id: now.add(Duration(hours: event.previewHours)),
        };
        trialRefilledAt = null;
        await _syncJukeboxAudio();
        await _notifyAndSave();
        return 'redeemed_event_preview';
    }
  }

  Future<void> synchronizeSeasonalEventDismissals(
      Map<String, DateTime> dismissals) async {
    final now = _clock();
    final normalized = <String, DateTime>{
      for (final entry in dismissals.entries)
        if (specialAdventureEventById(entry.key) != null &&
            entry.value.isAfter(now))
          entry.key: entry.value,
    };
    if (mapEquals(normalized, seasonalEventDismissedUntil)) return;
    seasonalEventDismissedUntil = normalized;
    await refreshForCurrentDate();
    // An end-event response must repaint and persist even when no timer,
    // daily reward or offer changed during the refresh.
    await _notifyAndSave();
  }

  Future<void> synchronizeSeasonalEventPreviews(
    Map<String, DateTime> previews,
  ) async {
    final now = _clock();
    final normalized = <String, DateTime>{
      for (final entry in previews.entries)
        if (specialAdventureEventById(entry.key) != null &&
            entry.value.isAfter(now))
          entry.key: entry.value,
    };
    if (normalized.length > 1) {
      final latest = normalized.entries.toList()
        ..sort((a, b) {
          final time = b.value.compareTo(a.value);
          return time == 0 ? a.key.compareTo(b.key) : time;
        });
      normalized.removeWhere((key, _) => key != latest.first.key);
    }
    final unchanged =
        normalized.length == seasonalEventPreviewExpiresAt.length &&
            normalized.entries.every(
              (entry) =>
                  seasonalEventPreviewExpiresAt[entry.key] == entry.value,
            );
    if (unchanged) return;
    seasonalEventPreviewExpiresAt = normalized;
    trialRefilledAt = null;
    await refreshForCurrentDate();
  }

  Map<TrainingFocus, int> _grantSeasonalTrialExpertise(
    Pet dragon,
    TrialGrade grade,
  ) {
    final ranked = TrainingFocus.values.toList()
      ..sort((a, b) {
        final score = dragon.trainingFor(a).compareTo(dragon.trainingFor(b));
        return score != 0 ? score : a.index.compareTo(b.index);
      });
    final planned = switch (grade) {
      TrialGrade.d => <int>[1, 0, 0],
      TrialGrade.c => <int>[1, 1, 0],
      TrialGrade.b => <int>[1, 1, 1],
      TrialGrade.a => <int>[2, 1, 1],
      TrialGrade.s => <int>[2, 2, 1],
      TrialGrade.sPlus => <int>[3, 2, 2],
    };
    final granted = <TrainingFocus, int>{};
    var overflow = 0;
    for (var index = 0; index < ranked.length; index++) {
      final focus = ranked[index];
      final capacity =
          dragon.expertiseMaximum(focus) - dragon.trainingFor(focus);
      final amount = planned[index].clamp(0, max(0, capacity)).toInt();
      if (amount > 0) {
        dragon.addTraining(focus, amount);
        granted[focus] = amount;
      }
      overflow += planned[index] - amount;
    }
    while (overflow > 0) {
      final candidates = TrainingFocus.values
          .where((focus) =>
              dragon.trainingFor(focus) < dragon.expertiseMaximum(focus))
          .toList()
        ..sort((a, b) {
          final score = dragon.trainingFor(a).compareTo(dragon.trainingFor(b));
          return score != 0 ? score : a.index.compareTo(b.index);
        });
      if (candidates.isEmpty) break;
      final focus = candidates.first;
      dragon.addTraining(focus, 1);
      granted.update(focus, (value) => value + 1, ifAbsent: () => 1);
      overflow--;
    }
    // Allocate the ordinary reward first, including its existing overflow
    // rule, then double only the wearer's matching Expertise within its cap.
    final boostedFocus = equippedRelicFor(dragon.id)?.boostedExpertise;
    if (boostedFocus != null) {
      final before = dragon.trainingFor(boostedFocus);
      dragon.addTraining(boostedFocus, granted[boostedFocus] ?? 0);
      final bonus = dragon.trainingFor(boostedFocus) - before;
      if (bonus > 0) granted.update(boostedFocus, (value) => value + bonus);
    }
    return Map.unmodifiable(granted);
  }

  String eggHint({bool? isDutch, String? locale}) {
    final strings = GameStrings(locale ?? (isDutch == true ? 'nl' : 'en'));
    final egg = nestEgg ?? pet;
    return _eggHintFor(
      strings,
      lineage: egg.lineage,
      specialEgg: specialEggForLineage(egg.lineageId),
    );
  }

  String eggHintForEgg(DragonEgg egg, {String? locale}) => _eggHintFor(
        GameStrings(locale ?? languageCode),
        lineage: egg.lineage,
        specialEgg: specialEggById(egg.specialEggId) ??
            (egg.isSpecialEgg ? specialEggForLineage(egg.lineageId) : null),
      );

  String _eggHintFor(
    GameStrings strings, {
    required DragonLineage lineage,
    SpecialEggDefinition? specialEgg,
  }) {
    final affinity = switch (lineage.affinityCategory) {
      'ember' || 'solar' => strings.pick(
          'The shell feels unusually warm.', 'De schaal voelt ongewoon warm.'),
      'tide' || 'abyssal' => strings.pick(
          'You hear something almost like distant waves.',
          'Je hoort iets dat bijna op golven lijkt.'),
      'tempest' => strings.pick('A tiny spark skips across the shell.',
          'Een piepklein vonkje danst over de schaal.'),
      'moon' || 'eclipse' || 'cosmic' => strings.pick(
          'The egg grows restless when the stars appear.',
          'Het ei wordt onrustig zodra de sterren verschijnen.'),
      'wildwood' || 'bloom' || 'earthlight' || 'primordial' => strings.pick(
          'The nest suddenly smells of rain and moss.',
          'Het nest ruikt plotseling naar regen en mos.'),
      _ => strings.pick('A strange musical tap answers from within.',
          'Er klinkt een vreemd muzikaal tikje van binnen.'),
    };
    if (!lineage.secret) return affinity;
    final specialFeeling = switch (specialEgg?.id) {
      'witchlight_egg_v1' => strings.pick(
          'A watchful green flame curls around the shell. This egg feels bound to a rare autumn night.',
          'Een waakzame groene vlam krult rond de schaal. Dit ei voelt verbonden met een zeldzame herfstnacht.',
        ),
      'starlit_evergreen_egg_v1' => strings.pick(
          'A winter star seems to breathe beneath the shell. This egg carries the warmth of a special hearth.',
          'Een winterster lijkt onder de schaal te ademen. Dit ei draagt de warmte van een bijzondere haard.',
        ),
      'turning_year_egg_v1' => strings.pick(
          'A distant bell answers the first light within. This egg belongs to a turning of the year.',
          'Een verre klok antwoordt het eerste licht binnenin. Dit ei hoort bij een jaarwende.',
        ),
      'rosebound_egg_v1' => strings.pick(
          'Two quiet heartbeats echo through the shell. This egg remembers a promise shared.',
          'Twee zachte hartslagen klinken door de schaal. Dit ei herinnert zich een gedeelde belofte.',
        ),
      'truecolor_egg_v1' => strings.pick(
          'Every color glimmers without hiding another. This egg feels joyfully, unmistakably special.',
          'Elke kleur schittert zonder een andere te verbergen. Dit ei voelt vreugdevol en onmiskenbaar bijzonder.',
        ),
      _ => strings.pick(
          'A gentle golden warmth lingers around this egg, as if it carries a wish meant for someone truly special.',
          'Rond dit ei blijft een zachte gouden warmte hangen, alsof het een wens draagt voor iemand die echt bijzonder is.',
        ),
    };
    return '$affinity\n\n$specialFeeling';
  }

  String dragonSizeLabel(Pet dragon) {
    if (dragon.sizeFactor > 1.4) return 'XXL';
    if (dragon.sizeFactor > 1.3) return 'XL';
    if (dragon.sizeFactor < .6) return 'XXS';
    if (dragon.sizeFactor < .7) return 'XS';
    return '';
  }

  bool _processDailyReturningDragon() {
    if (releasedDragons.isEmpty) return false;
    final now = _clock();
    var changed = false;

    // Always resolve a persisted overdue arrival before rolling the new day,
    // so returning dragons are not lost when the game stayed closed overnight.
    if (scheduledReturningAt?.isAfter(now) == false) {
      scheduledReturningAt = null;
      _resolveReturningDragon(now);
      changed = true;
    }

    final dayKey = HouseholdProvider._dayKey(now);
    if (lastReturningDayKey.isEmpty ||
        dayKey.compareTo(lastReturningDayKey) > 0) {
      lastReturningDayKey = dayKey;
      final dayStart = now.isUtc
          ? DateTime.utc(now.year, now.month, now.day)
          : DateTime(now.year, now.month, now.day);
      scheduledReturningAt = _random.nextDouble() < .10
          ? dayStart.add(
              Duration(seconds: _random.nextInt(Duration.secondsPerDay)),
            )
          : null;
      changed = true;
    }

    // A roll can land earlier than the first time the app opened that day.
    // In that case the return is resolved immediately and still counts once.
    if (scheduledReturningAt?.isAfter(now) == false) {
      scheduledReturningAt = null;
      _resolveReturningDragon(now);
      changed = true;
    }
    return changed;
  }

  @visibleForTesting
  bool processDailyReturningDragonForTesting() =>
      _processDailyReturningDragon();

  void _resolveReturningDragon(DateTime now) {
    final dragon = releasedDragons[_random.nextInt(releasedDragons.length)];
    totalReleasedReturns++;
    if (returningSpecialAvailableUntil?.isAfter(now) != true) {
      returningSpecialAdventureId = null;
      returningSpecialAvailableUntil = null;
    }
    final outcome = _rollReturnOutcome(dragon);
    switch (outcome) {
      case _ReturnOutcome.wooden:
        _grantReturningChest(dragon, ChestTier.wooden);
      case _ReturnOutcome.silver:
        _grantReturningChest(dragon, ChestTier.silver);
      case _ReturnOutcome.gold:
        _grantReturningChest(dragon, ChestTier.gold);
      case _ReturnOutcome.dragon:
        _grantReturningChest(dragon, ChestTier.dragon);
      case _ReturnOutcome.mythical:
        _grantReturningChest(dragon, ChestTier.mythical);
      case _ReturnOutcome.visit:
        _beginReturningVisit(dragon, now);
      case _ReturnOutcome.special:
        if (returningSpecialAdventureId == null) {
          _beginReturningSpecial(dragon, now, sinister: false);
        } else {
          _beginReturningVisit(dragon, now);
        }
      case _ReturnOutcome.sinister:
        if (returningSpecialAdventureId == null) {
          _beginReturningSpecial(dragon, now, sinister: true);
        } else {
          _recordMischief(dragon, major: dragon.stage == DragonStage.ascended);
        }
      case _ReturnOutcome.minorDamage:
        _applyReturningDamage(dragon, factor: .25, major: false);
      case _ReturnOutcome.damage:
        _applyReturningDamage(dragon, factor: .40, major: false);
      case _ReturnOutcome.majorDamage:
        _applyReturningDamage(dragon, factor: .60, major: true);
      case _ReturnOutcome.mischief:
        _recordMischief(dragon, major: false);
      case _ReturnOutcome.majorMischief:
        _recordMischief(dragon, major: true);
      case _ReturnOutcome.spotted:
        latestReturningEvent =
            '${dragon.displayName} was spotted near the Tower, then vanished.';
      case _ReturnOutcome.nothing:
        latestReturningEvent =
            '${dragon.displayName} passed nearby without leaving a reward or causing harm.';
    }
    _evaluateAchievements();
  }

  _ReturnOutcome _rollReturnOutcome(Pet dragon) {
    var roll = _random.nextInt(100);
    for (final entry in _returnOutcomeTable(dragon)) {
      if (roll < entry.$1) return entry.$2;
      roll -= entry.$1;
    }
    return _ReturnOutcome.nothing;
  }

  @visibleForTesting
  List<int> returnOutcomeWeightsForTesting(Pet dragon) =>
      _returnOutcomeTable(dragon).map((entry) => entry.$1).toList();

  void _grantReturningChest(Pet dragon, ChestTier tier) {
    chestInventory.update(tier, (value) => value + 1, ifAbsent: () => 1);
    latestReturningEvent =
        '${dragon.displayName} returned with a ${tier.label(false)}.';
  }

  void _beginReturningVisit(Pet dragon, DateTime now) {
    final hours = switch (dragon.stage) {
      DragonStage.hatchling => 24,
      DragonStage.wyrmling => 48,
      DragonStage.ascended => 72,
      DragonStage.egg => 24,
    };
    returningVisitors[dragon.id] = now.add(Duration(hours: hours));
    final targetFloor = _availableFloorFor(dragon);
    if (targetFloor != null &&
        (dragon.currentFloorIndex != targetFloor ||
            towerFloorRoomIds[targetFloor] != dragon.currentRoomId)) {
      dragon
        ..currentFloorIndex = targetFloor
        ..currentRoomId = towerFloorRoomIds[targetFloor];
    }
    latestReturningEvent =
        '${dragon.displayName} is visiting the Dragon Tower for $hours hours.';
  }

  void _ensureFavoriteDragon() {
    final dragons = ownedDragons;
    if (dragons.isEmpty) return;
    final favorites = dragons.where((dragon) => dragon.favorite).toList()
      ..sort((a, b) => a.acquiredAt.compareTo(b.acquiredAt));
    final chosen = favorites.isEmpty ? dragons.first : favorites.first;
    for (final dragon in dragons) {
      dragon.favorite = dragon.id == chosen.id;
    }
  }

  int _visibleFloorOccupancy(
    int floor, {
    String? exceptDragonId,
    Set<String> exceptDragonIds = const {},
  }) =>
      [
        ...ownedDragons.where((dragon) => dragon.roamsTower),
        ...visitingDragons,
      ].where((dragon) {
        return dragon.id != exceptDragonId &&
            !exceptDragonIds.contains(dragon.id) &&
            dragon.currentFloorIndex == floor;
      }).length;

  int? _availableFloorFor(Pet dragon) {
    final accessible = <int>[
      for (var index = 0; index < towerFloorRoomIds.length; index++)
        if (!damagedTowerFloors.contains(index) &&
            _visibleFloorOccupancy(index, exceptDragonId: dragon.id) <
                maxDragonsPerTowerFloor)
          index,
    ];
    if (accessible.isEmpty) return null;
    if (accessible.contains(dragon.currentFloorIndex) &&
        towerFloorRoomIds[dragon.currentFloorIndex] == dragon.currentRoomId) {
      return dragon.currentFloorIndex;
    }
    final preferred = accessible.where((index) {
      final roomId = towerFloorRoomIds[index];
      return roomId == dragon.lineage.primaryRoomId ||
          dragon.lineage.secondaryRoomIds.contains(roomId);
    }).toList(growable: false);
    final choices = preferred.isEmpty ? accessible : preferred;
    choices.sort((a, b) =>
        _visibleFloorOccupancy(a).compareTo(_visibleFloorOccupancy(b)));
    return choices.first;
  }

  bool _normalizeRoamingState() {
    if (towerFloorRoomIds.isEmpty) return false;
    var changed = false;
    final dragons = ownedDragons.toList()
      ..sort((a, b) {
        if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
        return a.acquiredAt.compareTo(b.acquiredAt);
      });
    var selected = 0;
    final occupancy = <int, int>{};
    for (final dragon in dragons) {
      if (!dragon.roamsTower) continue;
      if (selected >= towerRoamingCapacity) {
        dragon.roamsTower = false;
        changed = true;
        continue;
      }
      final current = dragon.currentFloorIndex;
      final currentIsValid = current >= 0 &&
          current < towerFloorRoomIds.length &&
          !damagedTowerFloors.contains(current) &&
          towerFloorRoomIds[current] == dragon.currentRoomId &&
          (occupancy[current] ?? 0) < maxDragonsPerTowerFloor;
      final floor = currentIsValid
          ? current
          : List.generate(towerFloorRoomIds.length, (index) => index)
              .where((index) =>
                  !damagedTowerFloors.contains(index) &&
                  (occupancy[index] ?? 0) < maxDragonsPerTowerFloor)
              .firstOrNull;
      if (floor == null) {
        dragon.roamsTower = false;
        changed = true;
        continue;
      }
      if (dragon.currentFloorIndex != floor ||
          dragon.currentRoomId != towerFloorRoomIds[floor]) {
        changed = true;
      }
      dragon
        ..currentFloorIndex = floor
        ..currentRoomId = towerFloorRoomIds[floor];
      occupancy[floor] = (occupancy[floor] ?? 0) + 1;
      selected++;
    }
    return changed;
  }

  void _beginReturningSpecial(
    Pet dragon,
    DateTime now, {
    required bool sinister,
  }) {
    final definition = sinister
        ? AdventureCatalog.special[90 + dragon.hatchSeed.abs() % 10]
        : AdventureCatalog.special[switch (dragon.stage) {
              DragonStage.hatchling => 0,
              DragonStage.wyrmling => 30,
              DragonStage.ascended => 60,
              DragonStage.egg => 0,
            } +
            dragon.hatchSeed.abs() % 30];
    returningSpecialAdventureId = definition.id;
    returningSpecialAvailableUntil = now.add(const Duration(hours: 48));
    latestReturningEvent = sinister
        ? '${dragon.displayName} left a Sinister Adventure. It is available for 48 hours.'
        : '${dragon.displayName} revealed a Special Adventure. It is available for 48 hours.';
    final strings = GameStrings(languageCode);
    unawaited(HavenNotifications.specialAdventureAvailable(
      id: 'returning-special-${definition.id}-${now.millisecondsSinceEpoch}',
      title: strings.pick(
        'An event has begun',
        'Er is een event begonnen',
      ),
      body: strings.pick(
        '${dragon.displayName} revealed a rare route. It is available for 48 hours.',
        '${dragon.displayName} onthulde een zeldzame route. Deze is 48 uur beschikbaar.',
      ),
    ));
  }

  void _recordMischief(Pet dragon, {required bool major}) {
    latestReturningEvent = major
        ? '${dragon.displayName} caused spectacular temporary chaos, but no possessions were lost.'
        : '${dragon.displayName} caused temporary mischief, but nothing was lost.';
  }

  void _applyReturningDamage(
    Pet dragon, {
    required double factor,
    required bool major,
  }) {
    final candidates = List.generate(towerFloorRoomIds.length, (index) => index)
        .where((index) => !damagedTowerFloors.contains(index))
        .toList(growable: false);
    if (candidates.isEmpty) {
      _recordMischief(dragon, major: major);
      return;
    }
    final wardChance = [0.0, .5, .75, .9][dragonWardLevel];
    if (_random.nextDouble() < wardChance) {
      latestReturningEvent =
          'Dragon Repelled! The Dragon Ward protected the Tower from ${dragon.displayName}.';
      return;
    }
    final target = dragon.lawAxis == LawAxis.lawful
        ? candidates.reduce((a, b) =>
            (houseRoomById(towerFloorRoomIds[a])?.price ?? 0) >=
                    (houseRoomById(towerFloorRoomIds[b])?.price ?? 0)
                ? a
                : b)
        : candidates[_random.nextInt(candidates.length)];
    damagedTowerFloors.add(target);
    damagedTowerRepairFactors[target] = factor;
    latestReturningEvent =
        '${dragon.displayName} damaged floor ${target + 1}. Repair costs ${(factor * 100).round()}% of the room price.';
  }

  List<(int, _ReturnOutcome)> _returnOutcomeTable(Pet dragon) =>
      switch ((dragon.stage, dragon.moralAxis, dragon.lawAxis)) {
        (DragonStage.hatchling, MoralAxis.good, LawAxis.lawful) => const [
            (80, _ReturnOutcome.wooden),
            (15, _ReturnOutcome.silver),
            (5, _ReturnOutcome.visit),
          ],
        (DragonStage.hatchling, MoralAxis.good, LawAxis.neutral) => const [
            (65, _ReturnOutcome.wooden),
            (20, _ReturnOutcome.silver),
            (10, _ReturnOutcome.visit),
            (5, _ReturnOutcome.special),
          ],
        (DragonStage.hatchling, MoralAxis.good, LawAxis.chaotic) => const [
            (50, _ReturnOutcome.wooden),
            (20, _ReturnOutcome.silver),
            (5, _ReturnOutcome.gold),
            (15, _ReturnOutcome.visit),
            (10, _ReturnOutcome.special),
          ],
        (DragonStage.hatchling, MoralAxis.neutral, LawAxis.lawful) => const [
            (70, _ReturnOutcome.visit),
            (20, _ReturnOutcome.special),
            (10, _ReturnOutcome.nothing),
          ],
        (DragonStage.hatchling, MoralAxis.neutral, LawAxis.neutral) => const [
            (50, _ReturnOutcome.visit),
            (25, _ReturnOutcome.special),
            (25, _ReturnOutcome.nothing),
          ],
        (DragonStage.hatchling, MoralAxis.neutral, LawAxis.chaotic) => const [
            (30, _ReturnOutcome.visit),
            (30, _ReturnOutcome.special),
            (40, _ReturnOutcome.nothing),
          ],
        (DragonStage.hatchling, MoralAxis.evil, LawAxis.lawful) => const [
            (45, _ReturnOutcome.mischief),
            (25, _ReturnOutcome.minorDamage),
            (20, _ReturnOutcome.sinister),
            (10, _ReturnOutcome.spotted),
          ],
        (DragonStage.hatchling, MoralAxis.evil, LawAxis.neutral) => const [
            (40, _ReturnOutcome.mischief),
            (30, _ReturnOutcome.minorDamage),
            (20, _ReturnOutcome.sinister),
            (10, _ReturnOutcome.spotted),
          ],
        (DragonStage.hatchling, MoralAxis.evil, LawAxis.chaotic) => const [
            (50, _ReturnOutcome.mischief),
            (20, _ReturnOutcome.minorDamage),
            (15, _ReturnOutcome.sinister),
            (15, _ReturnOutcome.spotted),
          ],
        (DragonStage.wyrmling, MoralAxis.good, LawAxis.lawful) => const [
            (70, _ReturnOutcome.silver),
            (24, _ReturnOutcome.gold),
            (1, _ReturnOutcome.dragon),
            (5, _ReturnOutcome.visit),
          ],
        (DragonStage.wyrmling, MoralAxis.good, LawAxis.neutral) => const [
            (55, _ReturnOutcome.silver),
            (25, _ReturnOutcome.gold),
            (2, _ReturnOutcome.dragon),
            (8, _ReturnOutcome.visit),
            (10, _ReturnOutcome.special),
          ],
        (DragonStage.wyrmling, MoralAxis.good, LawAxis.chaotic) => const [
            (40, _ReturnOutcome.silver),
            (25, _ReturnOutcome.gold),
            (5, _ReturnOutcome.dragon),
            (1, _ReturnOutcome.mythical),
            (14, _ReturnOutcome.visit),
            (15, _ReturnOutcome.special),
          ],
        (DragonStage.wyrmling, MoralAxis.neutral, LawAxis.lawful) => const [
            (60, _ReturnOutcome.visit),
            (30, _ReturnOutcome.special),
            (10, _ReturnOutcome.nothing),
          ],
        (DragonStage.wyrmling, MoralAxis.neutral, LawAxis.neutral) => const [
            (40, _ReturnOutcome.visit),
            (35, _ReturnOutcome.special),
            (25, _ReturnOutcome.nothing),
          ],
        (DragonStage.wyrmling, MoralAxis.neutral, LawAxis.chaotic) => const [
            (25, _ReturnOutcome.visit),
            (40, _ReturnOutcome.special),
            (35, _ReturnOutcome.nothing),
          ],
        (DragonStage.wyrmling, MoralAxis.evil, LawAxis.lawful) => const [
            (50, _ReturnOutcome.damage),
            (20, _ReturnOutcome.mischief),
            (25, _ReturnOutcome.sinister),
            (5, _ReturnOutcome.spotted),
          ],
        (DragonStage.wyrmling, MoralAxis.evil, LawAxis.neutral) => const [
            (45, _ReturnOutcome.damage),
            (25, _ReturnOutcome.mischief),
            (25, _ReturnOutcome.sinister),
            (5, _ReturnOutcome.spotted),
          ],
        (DragonStage.wyrmling, MoralAxis.evil, LawAxis.chaotic) => const [
            (35, _ReturnOutcome.damage),
            (35, _ReturnOutcome.mischief),
            (20, _ReturnOutcome.sinister),
            (10, _ReturnOutcome.spotted),
          ],
        (DragonStage.ascended, MoralAxis.good, LawAxis.lawful) => const [
            (55, _ReturnOutcome.gold),
            (35, _ReturnOutcome.dragon),
            (5, _ReturnOutcome.mythical),
            (5, _ReturnOutcome.visit),
          ],
        (DragonStage.ascended, MoralAxis.good, LawAxis.neutral) => const [
            (45, _ReturnOutcome.gold),
            (30, _ReturnOutcome.dragon),
            (3, _ReturnOutcome.mythical),
            (10, _ReturnOutcome.visit),
            (12, _ReturnOutcome.special),
          ],
        (DragonStage.ascended, MoralAxis.good, LawAxis.chaotic) => const [
            (30, _ReturnOutcome.silver),
            (30, _ReturnOutcome.gold),
            (20, _ReturnOutcome.dragon),
            (4, _ReturnOutcome.mythical),
            (6, _ReturnOutcome.visit),
            (10, _ReturnOutcome.special),
          ],
        (DragonStage.ascended, MoralAxis.neutral, LawAxis.lawful) => const [
            (50, _ReturnOutcome.visit),
            (40, _ReturnOutcome.special),
            (10, _ReturnOutcome.nothing),
          ],
        (DragonStage.ascended, MoralAxis.neutral, LawAxis.neutral) => const [
            (30, _ReturnOutcome.visit),
            (45, _ReturnOutcome.special),
            (25, _ReturnOutcome.nothing),
          ],
        (DragonStage.ascended, MoralAxis.neutral, LawAxis.chaotic) => const [
            (20, _ReturnOutcome.visit),
            (50, _ReturnOutcome.special),
            (30, _ReturnOutcome.nothing),
          ],
        (DragonStage.ascended, MoralAxis.evil, LawAxis.lawful) => const [
            (60, _ReturnOutcome.majorDamage),
            (10, _ReturnOutcome.mischief),
            (25, _ReturnOutcome.sinister),
            (5, _ReturnOutcome.spotted),
          ],
        (DragonStage.ascended, MoralAxis.evil, LawAxis.neutral) => const [
            (50, _ReturnOutcome.majorDamage),
            (15, _ReturnOutcome.mischief),
            (30, _ReturnOutcome.sinister),
            (5, _ReturnOutcome.spotted),
          ],
        (DragonStage.ascended, MoralAxis.evil, LawAxis.chaotic) => const [
            (40, _ReturnOutcome.majorDamage),
            (30, _ReturnOutcome.majorMischief),
            (25, _ReturnOutcome.sinister),
            (5, _ReturnOutcome.spotted),
          ],
        _ => const [(100, _ReturnOutcome.nothing)],
      };
}
