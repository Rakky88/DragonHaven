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
  static const int maxDragonsPerTowerFloor = 3;

  DateTime get currentTime => _clock();

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
  int get towerRoamingCapacity => towerFloorCount * maxDragonsPerTowerFloor;
  int get selectedRoamingDragonCount =>
      ownedDragons.where((dragon) => dragon.roamsTower).length;
  bool get hasSpectralCollection => prismaticForms.isNotEmpty;

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
    final name = dragon.displayName;
    final strings = AppStrings(languageCode);
    return strings
        .pick(interaction.messageEn, interaction.messageNl)
        .replaceAll('{dragon}', name);
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
    );
    await _notifyAndSave();
  }

  Future<void> setSoundEffectsEnabled(bool enabled) async {
    if (soundEffectsEnabled == enabled) return;
    soundEffectsEnabled = enabled;
    await HavenAudio.applyPreferences(
      musicEnabled: musicEnabled,
      soundEffectsEnabled: soundEffectsEnabled,
    );
    await _notifyAndSave();
  }

  List<AdventureDefinition> adventuresFor(AdventureKind kind) {
    _refreshAdventureRuns();
    final now = _clock();
    if (kind == AdventureKind.special) {
      final returningId = returningSpecialAdventureId;
      if (returningId == null ||
          returningSpecialAvailableUntil?.isAfter(now) != true) {
        return const [];
      }
      final definition = AdventureCatalog.byId[returningId];
      return definition == null ? const [] : [definition];
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
      refillCount =
          longAdventureRefillDay.isEmpty || longAdventureRefillDay != day
              ? 3
              : 0;
      longAdventureRefillDay = day;
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
    final run = AdventureRun(
      id: _uuid.v4(),
      adventureId: adventure.id,
      dragonId: dragon.id,
      startedAt: now,
      endsAt: now.add(adventure.duration),
      status: AdventureRunStatus.running,
      participantCount: participantCount,
    );
    dragon.activeAdventureId = run.id;
    adventureRuns.add(run);
    final strings = AppStrings(languageCode);
    await HavenNotifications.schedule(
      id: 'adventure-${run.id}',
      at: run.endsAt,
      title: strings.pick('${dragon.displayName} has returned',
          '${dragon.displayName} is teruggekeerd'),
      body: strings.pick(
        'An Adventure reward is ready in DragonHaven.',
        'Er staat een Adventure-beloning klaar in DragonHaven.',
      ),
    );
    adventureOptionIds[adventure.kind]?.remove(adventure.id);
    if (adventure.kind == AdventureKind.mini) {
      miniAdventureRefilledAt = now;
    } else if (adventure.kind == AdventureKind.short) {
      shortAdventureRefilledAt = now;
    }
    await _notifyAndSave();
    return AdventureStartResult.started;
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
      longAdventureRefillDay = HouseholdProvider._dayKey(now);
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
    dragon.xp += definition.xp;
    dragon.addTraining(definition.focus, definition.statPoints);
    _evolveReadyDragons(_clock());
    dragon.activeAdventureId = null;
    chestInventory.update(tier, (value) => value + 1, ifAbsent: () => 1);
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
      xp: definition.xp,
    );
    _evaluateAchievements();
    await _notifyAndSave();
    return tier;
  }

  bool _refreshAdventureRuns() {
    final now = _clock();
    var changed = false;
    for (var index = 0; index < adventureRuns.length; index++) {
      final run = adventureRuns[index];
      if (run.status == AdventureRunStatus.running &&
          !run.endsAt.isAfter(now)) {
        final definition = AdventureCatalog.byId[run.adventureId];
        final reward = definition?.knownChest ??
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
    final roll = _random.nextDouble();
    return switch (kind) {
      AdventureKind.mini => ChestTier.wooden,
      AdventureKind.short => roll < .50
          ? ChestTier.wooden
          : roll < .80
              ? ChestTier.silver
              : roll < .995
                  ? ChestTier.gold
                  : roll < .9995
                      ? ChestTier.dragon
                      : ChestTier.mythical,
      AdventureKind.long => roll < .55
          ? ChestTier.silver
          : roll < .90
              ? ChestTier.gold
              : roll < .995
                  ? ChestTier.dragon
                  : ChestTier.mythical,
      AdventureKind.group => roll < .70
          ? ChestTier.gold
          : roll < .98
              ? ChestTier.dragon
              : ChestTier.mythical,
      AdventureKind.special => ChestTier.gold,
    };
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
    final price = 120 + towerFloorRoomIds.length * 85;
    if (pet.coins < price) return TowerBuildResult.insufficientCoins;
    pet.coins -= price;
    towerFloorRoomIds.add(room.id);
    unlockedRoomIds.add(room.id);
    activeRoomId = room.id;
    _evaluateAchievements();
    await _notifyAndSave();
    return TowerBuildResult.built;
  }

  int get nextTowerFloorPrice => 120 + towerFloorRoomIds.length * 85;

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
    return max(1, ((room?.price ?? 100) * factor).round());
  }

  bool _expireReturningVisitors() {
    final now = _clock();
    final before = returningVisitors.length;
    returningVisitors.removeWhere((_, until) => !until.isAfter(now));
    return returningVisitors.length != before;
  }

  Future<bool> discardEgg(String eggId) async {
    final before = eggStash.length;
    eggStash.removeWhere((egg) => egg.id == eggId);
    if (eggStash.length == before) return false;
    await _notifyAndSave();
    return true;
  }

  Future<bool> upgradeDragonWard() async {
    if (dragonWardLevel >= 3 || damagedTowerFloors.isEmpty) return false;
    final price = [0, 150, 400, 850][dragonWardLevel + 1];
    if (pet.coins < price) return false;
    pet.coins -= price;
    dragonWardLevel++;
    await _notifyAndSave();
    return true;
  }

  Future<String> redeemCode(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty || !RegExp(r'^[A-Z]+$').hasMatch(code)) {
      return 'invalid_format';
    }
    return 'inactive';
  }

  String eggHint({bool? isDutch, String? locale}) {
    final strings = AppStrings(locale ?? (isDutch == true ? 'nl' : 'en'));
    final egg = nestEgg ?? pet;
    return _eggHintFor(
      strings,
      lineage: egg.lineage,
      lawAxis: egg.lawAxis,
      moralAxis: egg.moralAxis,
    );
  }

  String eggHintForEgg(DragonEgg egg, {String? locale}) => _eggHintFor(
        AppStrings(locale ?? languageCode),
        lineage: egg.lineage,
        lawAxis: egg.lawAxis,
        moralAxis: egg.moralAxis,
      );

  String _eggHintFor(
    AppStrings strings, {
    required DragonLineage lineage,
    required LawAxis lawAxis,
    required MoralAxis moralAxis,
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
    final rhythm = switch (lawAxis) {
      LawAxis.lawful => strings.pick(
          'The movements inside follow a precise rhythm.',
          'De bewegingen binnenin volgen een precies ritme.'),
      LawAxis.neutral => strings.pick(
          'It goes quiet whenever you try to find a pattern.',
          'Het wordt stil zodra je probeert een patroon te vinden.'),
      LawAxis.chaotic => strings.pick('The egg rolls a little. Uphill.',
          'Het ei rolt een stukje. Tegen de helling op.'),
    };
    final aura = switch (moralAxis) {
      MoralAxis.good => strings.pick('A gentle glow lingers beneath your hand.',
          'Een zachte gloed blijft even onder je hand hangen.'),
      MoralAxis.neutral => strings.pick(
          'Something inside seems to listen back.',
          'Iets binnenin luistert aandachtig terug.'),
      MoralAxis.evil => strings.pick(
          'You are fairly sure the egg just tapped back.',
          'Je weet vrij zeker dat het ei net terug tikte.'),
    };
    return '$affinity $rhythm $aura';
  }

  String dragonSizeLabel(Pet dragon) {
    if (dragon.sizeFactor > 1.4) return 'XXL';
    if (dragon.sizeFactor > 1.3) return 'XL';
    if (dragon.sizeFactor < .6) return 'XXS';
    if (dragon.sizeFactor < .7) return 'XS';
    return '';
  }

  bool _processWeeklyReturningDragon() {
    if (releasedDragons.isEmpty) return false;
    final now = _clock();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekKey = '${monday.year}-${monday.month}-${monday.day}';
    if (lastReturningWeekKey == weekKey) return false;
    lastReturningWeekKey = weekKey;
    if (_random.nextDouble() >= .10) {
      latestReturningEvent = null;
      return true;
    }
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
    return true;
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

  void _normalizeRoamingState() {
    if (towerFloorRoomIds.isEmpty) return;
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
        continue;
      }
      dragon
        ..currentFloorIndex = floor
        ..currentRoomId = towerFloorRoomIds[floor];
      occupancy[floor] = (occupancy[floor] ?? 0) + 1;
      selected++;
    }
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
