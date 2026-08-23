import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_strings.dart';
import '../models/achievement.dart';
import '../models/adventure.dart';
import '../models/activity_entry.dart';
import '../models/chest.dart';
import '../models/dragon_egg.dart';
import '../models/dragon_lineage.dart';
import '../models/game_presentation.dart';
import '../models/house.dart';
import '../models/mystic_relic.dart';
import '../models/pet.dart';
import '../models/shop_item.dart';
import '../models/tower_interaction.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../utils/json_utils.dart';

part 'dragonhaven_systems.dart';

enum PurchaseResult {
  purchased,
  equipped,
  insufficientCoins,
  insufficientGems,
  alreadyEquipped,
}

enum DragonRoamingResult {
  updated,
  unchanged,
  dragonNotFound,
  towerFull,
}

enum MysticRelicUseResult {
  revealed,
  notOwned,
  dragonNotFound,
  alreadyKnown,
}

double _dragonSizeFromRoll(double roll) =>
    1 + .5 * (roll >= .5 ? 1 : -1) * pow((2 * roll - 1).abs(), 2);

enum RoomUnlockResult {
  unlocked,
  insufficientCoins,
  levelLocked,
  alreadyUnlocked
}

class HouseholdProvider extends ChangeNotifier {
  HouseholdProvider({
    Random? random,
    DateTime Function()? clock,
    bool initialize = true,
    bool persistenceEnabled = true,
  })  : _random = random ?? Random.secure(),
        _clock = clock ?? DateTime.now,
        _persistenceEnabled = persistenceEnabled {
    if (initialize) _initializeFresh();
  }

  final Random _random;
  final DateTime Function() _clock;
  final bool _persistenceEnabled;
  final _uuid = const Uuid();
  Future<void> _saveQueue = Future<void>.value();

  String languageCode = 'en';
  String accountName = '';
  bool onboardingComplete = false;
  bool musicEnabled = true;
  bool soundEffectsEnabled = true;
  bool achievementsCompact = false;
  bool showcaseMode = false;
  late Pet pet;
  Pet? incubatingEgg;
  List<DragonEgg> eggStash = [];
  List<Pet> sanctuaryDragons = [];
  Map<ChestTier, int> chestInventory = {
    for (final tier in ChestTier.values) tier: 0,
  };
  Map<MysticRelic, int> relicInventory = {
    for (final relic in MysticRelic.values) relic: 0,
  };
  Set<String> discoveredForms = {};
  Set<String> prismaticForms = {};
  Set<String> unlockedAchievementIds = {};
  List<GamePresentation> pendingPresentations = [];
  int totalHatched = 0;
  int totalNamed = 0;
  int totalWyrmling = 0;
  int totalAscended = 0;
  int totalChestsOpened = 0;
  int totalAdventuresCompleted = 0;
  int totalShortAdventuresCompleted = 0;
  int totalGroupFourCompleted = 0;
  int totalReleasedReturns = 0;
  int totalSinisterAdventuresCompleted = 0;

  List<AdventureRun> adventureRuns = [];
  Map<AdventureKind, List<String>> adventureOptionIds = {
    AdventureKind.mini: <String>[],
    AdventureKind.short: <String>[],
    AdventureKind.long: <String>[],
  };
  DateTime? miniAdventureRefilledAt;
  DateTime? shortAdventureRefilledAt;
  String longAdventureRefillDay = '';
  List<String> towerFloorRoomIds = ['hearth'];
  List<Pet> releasedDragons = [];
  int dragonWardLevel = 0;
  Set<int> damagedTowerFloors = {};
  Map<int, double> damagedTowerRepairFactors = {};
  Map<String, DateTime> returningVisitors = {};
  Map<String, DateTime> rareInteractionAt = {};
  String lastReturningWeekKey = '';
  String? latestReturningEvent;
  String? returningSpecialAdventureId;
  DateTime? returningSpecialAvailableUntil;

  Set<String> ownedItemIds = {};
  Map<ItemSlot, String> equippedItemIds = {};
  Set<String> unlockedRoomIds = {'nest'};
  String activeRoomId = 'nest';
  List<HousePlacement> housePlacements = [];
  List<ActivityEntry> activities = [];

  static const _schemaVersion = 29;

  static HouseholdProvider createShowcase() {
    final provider = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: Random(20260822),
      clock: DateTime.now,
    );
    provider._initializeShowcase();
    return provider;
  }

  /// Creates a non-persistent emulator account whose Starter Egg hatches
  /// three minutes after the app starts.
  static HouseholdProvider createHatchDemo({
    Duration countdown = const Duration(minutes: 3),
  }) {
    if (countdown <= Duration.zero || countdown > const Duration(hours: 24)) {
      throw ArgumentError.value(
        countdown,
        'countdown',
        'Must be greater than zero and at most 24 hours.',
      );
    }
    final provider = HouseholdProvider(
      persistenceEnabled: false,
      random: Random(20260822),
      clock: DateTime.now,
    );
    provider
      ..accountName = 'Three-Minute Keeper'
      ..onboardingComplete = true
      ..musicEnabled = true
      ..soundEffectsEnabled = true;
    provider.pet.stageStartedAt = provider._clock().subtract(
          Duration(hours: provider.pet.incubationHours) - countdown,
        );
    return provider;
  }

  static Future<HouseholdProvider> loadFromStorage() async {
    final provider = HouseholdProvider(initialize: false);
    final data = await StorageService.load();
    if (data == null) {
      provider._initializeFresh();
      await provider._save();
      return provider;
    }
    try {
      provider._restore(data);
      final schemaChanged = data['schemaVersion'] != _schemaVersion;
      final changed = provider.pet.applyTimeDecay(provider._clock()) |
          provider._registerCurrentStage();
      final achievementsChanged =
          provider._evaluateAchievements(addActivities: false);
      if (schemaChanged || changed || achievementsChanged) {
        await provider._save();
      }
    } on Object {
      const supportedLanguages = {
        'en',
        'nl',
        'de',
        'fr',
        'es',
        'pt',
        'it',
        'zh',
        'ja'
      };
      final rawLanguage = stringFromJson(data['languageCode']);
      final savedLanguage =
          supportedLanguages.contains(rawLanguage) ? rawLanguage! : 'en';
      provider._initializeFresh();
      provider.languageCode = savedLanguage;
      await provider._save();
    }
    await provider._rescheduleNestEggNotification();
    return provider;
  }

  void _initializeFresh() {
    final now = _clock();
    final seed = _random.nextInt(0x7fffffff);
    final sizeRoll = _random.nextDouble();
    final starterLineages = dragonLineages
        .where((lineage) => lineage.rarity == DragonRarity.common)
        .toList(growable: false);
    pet = Pet(
      id: _uuid.v4(),
      hatchSeed: seed,
      lineageId: starterLineages[seed.remainder(starterLineages.length)].id,
      prismatic: _random.nextInt(20) == 0,
      lawAxis: LawAxis.values[_random.nextInt(LawAxis.values.length)],
      moralAxis: MoralAxis.values[_random.nextInt(MoralAxis.values.length)],
      sizeFactor: _dragonSizeFromRoll(sizeRoll),
      incubationHours: 24,
      acquiredAt: now,
      stageStartedAt: now,
    );
    incubatingEgg = null;
    unlockedRoomIds = {'nest', 'hearth'};
    towerFloorRoomIds = ['hearth'];
    activities = [
      ActivityEntry(
        id: _uuid.v4(),
        message: 'A Mysterious Egg appeared in the tower nest.',
        createdAt: now,
        type: ActivityType.milestone,
        code: ActivityCode.welcome,
      ),
    ];
    _ensureFavoriteDragon();
    _normalizeRoamingState();
  }

  void _initializeShowcase() {
    final now = _clock();
    showcaseMode = true;
    languageCode = 'en';
    accountName = 'Dragonkeeper Showcase';
    onboardingComplete = true;
    musicEnabled = true;
    soundEffectsEnabled = true;
    achievementsCompact = false;

    final dragons = <Pet>[];
    var serial = 0;
    for (final lineage in dragonLineages) {
      final acquired = now.subtract(Duration(days: 1000 - serial));
      dragons.add(Pet(
        id: 'showcase-${lineage.id}-hatchling',
        name: '${lineage.nameEn} Hatchling',
        xp: Pet.wyrmlingXp - 1,
        stage: DragonStage.hatchling,
        firstEgg: false,
        acquiredAt: acquired,
        stageStartedAt: now.subtract(const Duration(days: 30)),
        needsUpdatedAt: now,
        hatchSeed: 10000 + serial++,
        lineageId: lineage.id,
      ));
      dragons.add(Pet(
        id: 'showcase-${lineage.id}-hatchling-spectral',
        name: 'Spectral ${lineage.nameEn} Hatchling',
        xp: Pet.wyrmlingXp - 1,
        stage: DragonStage.hatchling,
        firstEgg: false,
        prismatic: true,
        acquiredAt: acquired.add(const Duration(minutes: 20)),
        stageStartedAt: now.subtract(const Duration(days: 30)),
        needsUpdatedAt: now,
        hatchSeed: 10000 + serial++,
        lineageId: lineage.id,
      ));
      dragons.add(Pet(
        id: 'showcase-${lineage.id}-wyrmling',
        name: '${lineage.nameEn} Wyrmling',
        xp: Pet.ascendedXp - 1,
        stage: DragonStage.wyrmling,
        firstEgg: false,
        acquiredAt: acquired.add(const Duration(hours: 1)),
        stageStartedAt: now.subtract(const Duration(days: 30)),
        needsUpdatedAt: now,
        training: const {'might': 99, 'arcana': 99, 'spirit': 99},
        hatchSeed: 10000 + serial++,
        lineageId: lineage.id,
      ));
      dragons.add(Pet(
        id: 'showcase-${lineage.id}-wyrmling-spectral',
        name: 'Spectral ${lineage.nameEn} Wyrmling',
        xp: Pet.ascendedXp - 1,
        stage: DragonStage.wyrmling,
        firstEgg: false,
        prismatic: true,
        acquiredAt: acquired.add(const Duration(hours: 1, minutes: 20)),
        stageStartedAt: now.subtract(const Duration(days: 30)),
        needsUpdatedAt: now,
        training: const {'might': 99, 'arcana': 99, 'spirit': 99},
        hatchSeed: 10000 + serial++,
        lineageId: lineage.id,
      ));
      for (final focus in TrainingFocus.values) {
        dragons.add(Pet(
          id: 'showcase-${lineage.id}-ascended-${focus.name}',
          name: '${lineage.nameEn} ${focus.name}',
          xp: 5000,
          stage: DragonStage.ascended,
          firstEgg: false,
          favorite:
              lineage == dragonLineages.first && focus == TrainingFocus.spirit,
          acquiredAt: acquired.add(Duration(hours: 2 + focus.index)),
          stageStartedAt: now.subtract(const Duration(days: 30)),
          needsUpdatedAt: now,
          training: {
            'might': focus == TrainingFocus.might ? 400 : 25,
            'arcana': focus == TrainingFocus.arcana ? 400 : 25,
            'spirit': focus == TrainingFocus.spirit ? 400 : 25,
          },
          hatchSeed: 10000 + serial++,
          lineageId: lineage.id,
          evolutionPath: focus.name,
        ));
        dragons.add(Pet(
          id: 'showcase-${lineage.id}-ascended-${focus.name}-spectral',
          name: 'Spectral ${lineage.nameEn} ${focus.name}',
          xp: 5000,
          stage: DragonStage.ascended,
          firstEgg: false,
          prismatic: true,
          acquiredAt:
              acquired.add(Duration(hours: 2 + focus.index, minutes: 20)),
          stageStartedAt: now.subtract(const Duration(days: 30)),
          needsUpdatedAt: now,
          training: {
            'might': focus == TrainingFocus.might ? 400 : 25,
            'arcana': focus == TrainingFocus.arcana ? 400 : 25,
            'spirit': focus == TrainingFocus.spirit ? 400 : 25,
          },
          hatchSeed: 10000 + serial++,
          lineageId: lineage.id,
          evolutionPath: focus.name,
        ));
      }
    }
    pet = dragons.firstWhere((dragon) => dragon.stage == DragonStage.ascended)
      ..coins = 999999
      ..gems = 99999;
    sanctuaryDragons = dragons.where((dragon) => dragon.id != pet.id).toList();
    incubatingEgg = null;

    discoveredForms = {
      for (final lineage in dragonLineages) '${lineage.id}:hatchling',
      for (final lineage in dragonLineages) '${lineage.id}:wyrmling',
      for (final lineage in dragonLineages)
        for (final focus in TrainingFocus.values)
          '${lineage.id}:ascended:${focus.name}',
    };
    prismaticForms = {...discoveredForms};
    unlockedAchievementIds =
        achievementCatalog.map((achievement) => achievement.id).toSet();
    pendingPresentations = [];
    totalHatched = dragons.length;
    totalNamed = dragons.length;
    totalWyrmling = dragonLineages.length;
    totalAscended = dragonLineages.length * TrainingFocus.values.length;
    totalChestsOpened = 250;
    totalAdventuresCompleted = 250;
    totalShortAdventuresCompleted = 100;
    totalGroupFourCompleted = 10;
    totalReleasedReturns = 20;
    totalSinisterAdventuresCompleted = 5;
    chestInventory = {for (final tier in ChestTier.values) tier: 25};
    relicInventory = {for (final relic in MysticRelic.values) relic: 3};
    for (final dragon in dragons) {
      dragon
        ..lawAxisKnown = true
        ..moralAxisKnown = true
        ..revealPersonality();
    }

    final buildableRooms =
        houseRoomCatalog.where((room) => room.id != 'nest').toList();
    towerFloorRoomIds = List.generate(
      20,
      (index) => buildableRooms[index % buildableRooms.length].id,
    );
    for (var index = 0; index < dragons.length; index++) {
      final floorIndex = index % towerFloorRoomIds.length;
      dragons[index]
        ..currentFloorIndex = floorIndex
        ..currentRoomId = towerFloorRoomIds[floorIndex];
    }
    unlockedRoomIds = houseRoomCatalog.map((room) => room.id).toSet();
    activeRoomId = 'hearth';
    ownedItemIds = shopCatalog.map((item) => item.id).toSet();
    housePlacements = [
      for (var index = 0; index < min(28, shopCatalog.length); index++)
        defaultPlacementFor(
          shopCatalog[index],
          buildableRooms[index % buildableRooms.length].id,
          index ~/ buildableRooms.length,
        ),
    ];
    _rebuildEquippedItems();
    dragonWardLevel = 3;
    damagedTowerFloors = {};
    damagedTowerRepairFactors = {};
    eggStash = [];
    releasedDragons = [];
    adventureRuns = [];
    adventureOptionIds = {
      AdventureKind.mini: <String>[],
      AdventureKind.short: <String>[],
      AdventureKind.long: <String>[],
    };
    activities = [
      ActivityEntry(
        id: 'showcase-ready',
        message: 'The complete DragonHaven showcase is ready.',
        createdAt: now,
        type: ActivityType.milestone,
        code: ActivityCode.welcome,
      ),
    ];
    _ensureFavoriteDragon();
    _normalizeRoamingState();
  }

  void _restore(Map<String, dynamic> data) {
    const supportedLanguages = {
      'en',
      'nl',
      'de',
      'fr',
      'es',
      'pt',
      'it',
      'zh',
      'ja'
    };
    final storedLanguage = stringFromJson(data['languageCode']);
    languageCode =
        supportedLanguages.contains(storedLanguage) ? storedLanguage! : 'en';
    accountName = stringFromJson(data['accountName'])?.trim() ?? '';
    onboardingComplete = data['onboardingComplete'] is bool
        ? data['onboardingComplete'] as bool
        : true;
    musicEnabled =
        data['musicEnabled'] is! bool || data['musicEnabled'] as bool;
    soundEffectsEnabled = data['soundEffectsEnabled'] is! bool ||
        data['soundEffectsEnabled'] as bool;
    achievementsCompact = data['achievementsCompact'] is bool &&
        data['achievementsCompact'] as bool;
    pet = Pet.fromJson(mapFromJson(data['pet']));
    final storedIncubatingEgg = mapFromJson(data['incubatingEgg']);
    incubatingEgg =
        storedIncubatingEgg.isEmpty ? null : Pet.fromJson(storedIncubatingEgg);
    if (incubatingEgg?.isEgg != true) incubatingEgg = null;
    eggStash = mapsFromJson(data['eggStash']).map(DragonEgg.fromJson).toList();
    sanctuaryDragons = mapsFromJson(data['sanctuaryDragons'])
        .map(Pet.fromJson)
        .where((dragon) => !dragon.isEgg)
        .toList();
    // v0.00.10 and older temporarily replaced the active dragon with every
    // later egg. Preserve that egg's fixed identity and incubation progress,
    // but restore the previous dragon so the complete app remains available.
    if (pet.isEgg && !pet.firstEgg && sanctuaryDragons.isNotEmpty) {
      incubatingEgg = pet;
      final restoredActiveDragon = sanctuaryDragons.removeAt(0);
      restoredActiveDragon.coins = pet.coins;
      restoredActiveDragon.gems = pet.gems;
      incubatingEgg!
        ..coins = 0
        ..gems = 0;
      pet = restoredActiveDragon;
    }
    if (pet.isEgg && pet.firstEgg) incubatingEgg = null;
    final rawChests = mapFromJson(data['chestInventory']);
    chestInventory = {
      for (final tier in ChestTier.values)
        tier: nonNegativeIntFromJson(
          rawChests[tier.name] ??
              switch (tier) {
                ChestTier.wooden => rawChests['woodland'],
                ChestTier.silver => rawChests['moonsteel'],
                ChestTier.gold => rawChests['celestial'],
                _ => null,
              },
          fallback: 0,
        ),
    };
    final rawRelics = mapFromJson(data['relicInventory']);
    relicInventory = {
      for (final relic in MysticRelic.values)
        relic: nonNegativeIntFromJson(rawRelics[relic.name], fallback: 0),
    };
    discoveredForms = stringSetFromJson(data['discoveredForms']);
    prismaticForms = stringSetFromJson(data['prismaticForms']);
    unlockedAchievementIds = stringSetFromJson(data['achievements']);
    pendingPresentations = <String, GamePresentation>{
      for (final presentation in mapsFromJson(data['pendingPresentations'])
          .map(GamePresentation.fromJson))
        presentation.id: presentation,
    }.values.take(100).toList();
    totalHatched = nonNegativeIntFromJson(data['totalHatched'],
        fallback: pet.isEgg ? 0 : 1);
    totalNamed = nonNegativeIntFromJson(data['totalNamed'],
        fallback: pet.name.trim().isEmpty ? 0 : 1);
    totalWyrmling = nonNegativeIntFromJson(data['totalWyrmling'],
        fallback: pet.stage.index >= DragonStage.wyrmling.index ? 1 : 0);
    totalAscended = nonNegativeIntFromJson(data['totalAscended'],
        fallback: pet.stage == DragonStage.ascended ? 1 : 0);
    totalChestsOpened =
        nonNegativeIntFromJson(data['totalChestsOpened'], fallback: 0);
    totalAdventuresCompleted =
        nonNegativeIntFromJson(data['totalAdventuresCompleted'], fallback: 0);
    totalShortAdventuresCompleted = nonNegativeIntFromJson(
        data['totalShortAdventuresCompleted'],
        fallback: 0);
    totalGroupFourCompleted =
        nonNegativeIntFromJson(data['totalGroupFourCompleted'], fallback: 0);
    totalReleasedReturns =
        nonNegativeIntFromJson(data['totalReleasedReturns'], fallback: 0);
    totalSinisterAdventuresCompleted = nonNegativeIntFromJson(
        data['totalSinisterAdventuresCompleted'],
        fallback: 0);
    adventureRuns = mapsFromJson(data['adventureRuns'])
        .map(AdventureRun.fromJson)
        .where((run) => AdventureCatalog.byId.containsKey(run.adventureId))
        .toList();
    final rawAdventureOptions = mapFromJson(data['adventureOptionIds']);
    adventureOptionIds = {
      AdventureKind.mini: (rawAdventureOptions['mini'] as List?)
              ?.whereType<String>()
              .where(AdventureCatalog.byId.containsKey)
              .take(3)
              .toList() ??
          <String>[],
      AdventureKind.short: (rawAdventureOptions['short'] as List?)
              ?.whereType<String>()
              .where(AdventureCatalog.byId.containsKey)
              .take(3)
              .toList() ??
          <String>[],
      AdventureKind.long: (rawAdventureOptions['long'] as List?)
              ?.whereType<String>()
              .where(AdventureCatalog.byId.containsKey)
              .take(3)
              .toList() ??
          <String>[],
    };
    miniAdventureRefilledAt = DateTime.tryParse(
        stringFromJson(data['miniAdventureRefilledAt']) ?? '');
    shortAdventureRefilledAt = DateTime.tryParse(
        stringFromJson(data['shortAdventureRefilledAt']) ?? '');
    longAdventureRefillDay =
        stringFromJson(data['longAdventureRefillDay']) ?? '';
    towerFloorRoomIds = (data['towerFloorRoomIds'] as List?)
            ?.whereType<String>()
            .where((id) => houseRoomById(id) != null && id != 'nest')
            .take(20)
            .toList() ??
        <String>[];
    if (towerFloorRoomIds.isEmpty) towerFloorRoomIds = ['hearth'];
    releasedDragons = mapsFromJson(data['releasedDragons'])
        .map(Pet.fromJson)
        .where((dragon) => !dragon.isEgg)
        .toList();
    dragonWardLevel =
        nonNegativeIntFromJson(data['dragonWardLevel'], fallback: 0)
            .clamp(0, 3)
            .toInt();
    damagedTowerFloors = (data['damagedTowerFloors'] as List?)
            ?.whereType<num>()
            .map((value) => value.toInt())
            .where((index) => index >= 0 && index < towerFloorRoomIds.length)
            .toSet() ??
        <int>{};
    final rawRepairFactors = mapFromJson(data['damagedTowerRepairFactors']);
    damagedTowerRepairFactors = {
      for (final index in damagedTowerFloors)
        index: (rawRepairFactors['$index'] as num?)
                ?.toDouble()
                .clamp(.25, .60)
                .toDouble() ??
            .40,
    };
    returningVisitors = {
      for (final entry in mapFromJson(data['returningVisitors']).entries)
        if (DateTime.tryParse(entry.value.toString()) case final time?)
          entry.key: time,
    };
    rareInteractionAt = {
      for (final entry in mapFromJson(data['rareInteractionAt']).entries)
        if (DateTime.tryParse(entry.value.toString()) case final time?)
          entry.key: time,
    };
    lastReturningWeekKey = stringFromJson(data['lastReturningWeekKey']) ?? '';
    latestReturningEvent = stringFromJson(data['latestReturningEvent']);
    returningSpecialAdventureId =
        stringFromJson(data['returningSpecialAdventureId']);
    returningSpecialAvailableUntil = DateTime.tryParse(
        stringFromJson(data['returningSpecialAvailableUntil']) ?? '');

    ownedItemIds = stringSetFromJson(data['ownedItemIds'])
        .where((id) => shopItemById(id) != null)
        .toSet();
    final storedEquipped = mapFromJson(data['equippedItemIds']);
    equippedItemIds = {};
    for (final slot in ItemSlot.values) {
      final storedItemId = stringFromJson(storedEquipped[slot.name]);
      final itemId = storedItemId;
      final item = itemId == null ? null : shopItemById(itemId);
      if (item != null && item.slot == slot) {
        ownedItemIds.add(item.id);
        equippedItemIds[slot] = item.id;
      }
    }
    unlockedRoomIds = {'nest', ...stringSetFromJson(data['unlockedRoomIds'])}
      ..removeWhere((id) => houseRoomById(id) == null);
    final storedActiveRoom = stringFromJson(data['activeRoomId']) ?? 'nest';
    activeRoomId =
        unlockedRoomIds.contains(storedActiveRoom) ? storedActiveRoom : 'nest';
    final placementsByItem = <String, HousePlacement>{};
    for (final entry in mapsFromJson(data['housePlacements'])) {
      final storedPlacement = HousePlacement.fromJson(entry);
      final placement = storedPlacement;
      if (shopItemById(placement.itemId) == null ||
          !unlockedRoomIds.contains(placement.roomId)) {
        continue;
      }
      ownedItemIds.add(placement.itemId);
      placementsByItem[placement.itemId] = placement;
    }
    housePlacements = placementsByItem.values.toList();
    if (housePlacements.isEmpty && equippedItemIds.isNotEmpty) {
      for (final itemId in equippedItemIds.values.toList()) {
        final item = shopItemById(itemId);
        if (item != null) _autoPlace(item, roomId: 'nest');
      }
    } else {
      _rebuildEquippedItems();
    }
    activities = <String, ActivityEntry>{
      for (final activity
          in mapsFromJson(data['activities']).map(ActivityEntry.fromJson))
        activity.id: activity,
    }.values.where((entry) => entry.code != ActivityCode.legacy).toList();
    _trimActivities();
    _ensureFavoriteDragon();
    _normalizeRoamingState();
  }

  int chestCount(ChestTier tier) => chestInventory[tier] ?? 0;
  int get totalChestCount => chestInventory.values.fold(0, (a, b) => a + b);
  int relicCount(MysticRelic relic) => relicInventory[relic] ?? 0;
  int get totalRelicCount => relicInventory.values.fold(0, (a, b) => a + b);

  bool isRelicKnownFor(MysticRelic relic, Pet dragon) => switch (relic) {
        MysticRelic.moralPrism => dragon.moralAxisKnown,
        MysticRelic.orderCompass => dragon.lawAxisKnown,
        MysticRelic.soulMirror => dragon.personalityKnown,
      };

  Future<MysticRelicUseResult> useRelic(
    MysticRelic relic,
    String dragonId,
  ) async {
    if (relicCount(relic) <= 0) return MysticRelicUseResult.notOwned;
    final dragon = ownedDragons.cast<Pet?>().firstWhere(
          (candidate) => candidate?.id == dragonId,
          orElse: () => null,
        );
    if (dragon == null) return MysticRelicUseResult.dragonNotFound;
    if (isRelicKnownFor(relic, dragon)) {
      return MysticRelicUseResult.alreadyKnown;
    }
    relicInventory[relic] = relicCount(relic) - 1;
    switch (relic) {
      case MysticRelic.moralPrism:
        dragon.moralAxisKnown = true;
        break;
      case MysticRelic.orderCompass:
        dragon.lawAxisKnown = true;
        break;
      case MysticRelic.soulMirror:
        dragon.revealPersonality();
        break;
    }
    _addActivity(
      message:
          '${relic.nameEn} revealed something about ${dragon.displayName}.',
      type: ActivityType.discovery,
      code: ActivityCode.bonusFound,
      subject: '${relic.name}:${dragon.id}',
    );
    await _notifyAndSave();
    return MysticRelicUseResult.revealed;
  }

  Pet? get nestEgg => pet.isEgg ? pet : incubatingEgg;
  bool get hasEggInNest => nestEgg != null;

  Pet? dragonById(String? id) {
    if (id == null) return null;
    if (pet.id == id) return pet;
    if (incubatingEgg?.id == id) return incubatingEgg;
    for (final dragon in sanctuaryDragons) {
      if (dragon.id == id) return dragon;
    }
    return null;
  }

  List<GamePresentation> get orderedPendingPresentations {
    final ordered = [...pendingPresentations];
    ordered.sort((a, b) {
      final priority = a.priority.compareTo(b.priority);
      if (priority != 0) return priority;
      final age = a.sortAt.compareTo(b.sortAt);
      if (age != 0) return age;
      final queued = a.createdAt.compareTo(b.createdAt);
      return queued != 0 ? queued : a.id.compareTo(b.id);
    });
    return ordered;
  }

  GamePresentation? get nextPresentation =>
      orderedPendingPresentations.firstOrNull;

  Future<void> completePresentation(String id) async {
    final before = pendingPresentations.length;
    pendingPresentations.removeWhere((presentation) => presentation.id == id);
    if (pendingPresentations.length != before) await _notifyAndSave();
  }

  void _queuePresentation(GamePresentation presentation) {
    if (pendingPresentations.any((queued) => queued.id == presentation.id)) {
      return;
    }
    pendingPresentations.add(presentation);
  }

  int get discoveredLineageCount =>
      discoveredForms.map((key) => key.split(':').first).toSet().length;
  int get discoveredCommonLineageCount {
    final discoveredIds =
        discoveredForms.map((key) => key.split(':').first).toSet();
    return dragonLineages
        .where((lineage) =>
            lineage.rarity == DragonRarity.common &&
            discoveredIds.contains(lineage.id))
        .length;
  }

  List<ShopItem> get equippedItems =>
      equippedItemIds.values.map(shopItemById).whereType<ShopItem>().toList();
  HouseRoomDefinition get activeRoom =>
      houseRoomById(activeRoomId) ?? houseRoomCatalog.first;
  List<HousePlacement> placementsForRoom(String roomId) =>
      housePlacements.where((placement) => placement.roomId == roomId).toList();
  List<ShopItem> get unplacedOwnedItems => ownedItemIds
      .where(
          (id) => !housePlacements.any((placement) => placement.itemId == id))
      .map(shopItemById)
      .whereType<ShopItem>()
      .toList();
  bool isRoomUnlocked(String roomId) => unlockedRoomIds.contains(roomId);

  Future<void> setLanguage(String code) async {
    const supported = {'en', 'nl', 'de', 'fr', 'es', 'pt', 'it', 'zh', 'ja'};
    final normalized = supported.contains(code) ? code : 'en';
    if (normalized == languageCode) return;
    languageCode = normalized;
    await _notifyAndSave();
  }

  Future<void> setAchievementsCompact(bool value) async {
    if (achievementsCompact == value) return;
    achievementsCompact = value;
    await _notifyAndSave();
  }

  Future<ChestReward?> openChest(ChestTier tier) async {
    if (chestCount(tier) <= 0) return null;
    chestInventory[tier] = chestCount(tier) - 1;
    final coins = switch (tier) {
      ChestTier.wooden => 20 + _random.nextInt(21),
      ChestTier.silver => 45 + _random.nextInt(36),
      ChestTier.gold => 90 + _random.nextInt(71),
      ChestTier.dragon => 180 + _random.nextInt(121),
      ChestTier.mythical || ChestTier.sinister => 400 + _random.nextInt(251),
    };
    final gems = switch (tier) {
      ChestTier.wooden => _random.nextDouble() < .25 ? 1 : 0,
      ChestTier.silver =>
        _random.nextDouble() < .50 ? 1 + _random.nextInt(2) : 0,
      ChestTier.gold => _random.nextDouble() < .72 ? 2 + _random.nextInt(3) : 0,
      ChestTier.dragon =>
        _random.nextDouble() < .9 ? 4 + _random.nextInt(4) : 0,
      ChestTier.mythical || ChestTier.sinister => 8 + _random.nextInt(6),
    };
    final eggChance = switch (tier) {
      ChestTier.wooden => 0.01,
      ChestTier.silver => 0.04,
      ChestTier.gold => 0.12,
      ChestTier.dragon || ChestTier.mythical || ChestTier.sinister => 1.0,
    };
    final eggFound = _random.nextDouble() < eggChance;
    final relicFound = _rollRelicDrop(tier);
    DragonEgg? foundEgg;
    pet.coins += coins;
    pet.gems += gems;
    totalChestsOpened++;
    if (eggFound) {
      foundEgg = _createEgg(sourceTier: tier);
      eggStash.add(foundEgg);
    }
    if (relicFound != null) {
      relicInventory.update(
        relicFound,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    _addActivity(
      message: '${tier.name} chest opened.',
      type: ActivityType.discovery,
      code: ActivityCode.chestOpened,
      subject: tier.name,
      coins: coins,
      gems: gems,
    );
    _evaluateAchievements();
    await _notifyAndSave();
    return ChestReward(
        tier: tier,
        coins: coins,
        gems: gems,
        eggFound: eggFound,
        sinisterEgg: foundEgg?.sinister ?? false,
        relicFound: relicFound);
  }

  MysticRelic? _rollRelicDrop(ChestTier tier) {
    final chance = switch (tier) {
      ChestTier.wooden || ChestTier.silver => 0.0,
      ChestTier.gold => .015,
      ChestTier.dragon => .04,
      ChestTier.mythical => .09,
      ChestTier.sinister => .06,
    };
    if (_random.nextDouble() >= chance) return null;
    return MysticRelic.values[_random.nextInt(MysticRelic.values.length)];
  }

  Future<bool> hatchActiveDragon() async {
    final now = _clock();
    final egg = nestEgg;
    if (egg == null || !egg.canHatch(now)) return false;
    final dragonId = egg.id;
    final acquiredAt = egg.acquiredAt;
    egg.hatch(now);
    if (!identical(egg, pet)) {
      final previousActiveDragon = pet;
      egg
        ..coins = previousActiveDragon.coins
        ..gems = previousActiveDragon.gems;
      sanctuaryDragons.insert(0, previousActiveDragon);
      pet = egg;
      incubatingEgg = null;
    }
    _ensureFavoriteDragon();
    _normalizeRoamingState();
    totalHatched++;
    _registerCurrentStage();
    _addActivity(
        message: 'A ${pet.lineage.nameEn} hatched in a burst of starlight.',
        type: ActivityType.milestone,
        code: ActivityCode.hatched,
        subject: pet.lineageId);
    _queuePresentation(GamePresentation(
      id: 'hatch-$dragonId',
      type: GamePresentationType.hatch,
      dragonId: dragonId,
      createdAt: now,
      sortAt: acquiredAt,
    ));
    _evaluateAchievements();
    await _notifyAndSave();
    return true;
  }

  Future<bool> nameActiveDragon(String value) => nameDragon(pet.id, value);

  Future<bool> nameDragon(String dragonId, String value) async {
    final name = value.trim();
    final dragon = dragonById(dragonId);
    if (dragon == null || dragon.isEgg || name.isEmpty || name.length > 24) {
      return false;
    }
    final firstName = dragon.name.trim().isEmpty;
    dragon.name = name;
    if (firstName) totalNamed++;
    _evaluateAchievements();
    await _notifyAndSave();
    return true;
  }

  Future<bool> evolveActiveDragon() => evolveDragon(pet.id);

  Future<bool> evolveDragon(String dragonId) async {
    final now = _clock();
    final dragon = dragonById(dragonId);
    if (dragon == null || !dragon.canEvolve(now)) return false;
    final previousStageKey = dragon.stageKey;
    dragon.evolve(now);
    if (dragon.stage == DragonStage.wyrmling) totalWyrmling++;
    if (dragon.stage == DragonStage.ascended) totalAscended++;
    _registerDragonStage(dragon);
    _addActivity(
        message: '${dragon.displayName} reached the ${dragon.stage.name} form.',
        type: ActivityType.milestone,
        code: ActivityCode.evolved,
        subject: dragon.lineageId);
    _queuePresentation(GamePresentation(
      id: 'evolution-${dragon.id}-${dragon.stage.name}',
      type: GamePresentationType.evolution,
      dragonId: dragon.id,
      previousStageKey: previousStageKey,
      createdAt: now,
      sortAt: dragon.acquiredAt,
    ));
    final strings = AppStrings(languageCode);
    final form = strings.petStage(dragon);
    unawaited(HavenNotifications.evolutionUnlocked(
      id: 'evolution-${dragon.id}-${dragon.stage.name}',
      title: strings.pick('New evolution!', 'Nieuwe evolutie!'),
      body: strings.pick(
        '${dragon.displayName} evolved into $form.',
        '${dragon.displayName} is geëvolueerd naar $form.',
      ),
    ));
    _evaluateAchievements();
    await _notifyAndSave();
    return true;
  }

  Future<bool> buyStarlightTreat() async {
    if (pet.gems < 3 || pet.isEgg) return false;
    pet.gems -= 3;
    pet.xp += 25;
    pet.joy = min(100, pet.joy + 12);
    pet.energy = min(100, pet.energy + 12);
    pet.comfort = min(100, pet.comfort + 12);
    _evaluateAchievements();
    await _notifyAndSave();
    return true;
  }

  Future<bool> activateEgg(String eggId) async {
    final index = eggStash.indexWhere((egg) => egg.id == eggId);
    if (index < 0 || pet.isEgg || incubatingEgg != null) return false;
    final egg = eggStash.removeAt(index);
    incubatingEgg = egg.activate(coins: 0, gems: 0, activatedAt: _clock());
    final activeEgg = incubatingEgg!;
    _evaluateAchievements();
    await _notifyAndSave();
    await _scheduleEggReadyNotification(activeEgg);
    return true;
  }

  Future<void> _rescheduleNestEggNotification() async {
    if (!onboardingComplete) return;
    final egg = nestEgg;
    if (egg == null) return;
    await _scheduleEggReadyNotification(egg);
  }

  Future<void> _scheduleEggReadyNotification(Pet egg) async {
    final strings = AppStrings(languageCode);
    await HavenNotifications.eggReady(
      id: 'egg-${egg.id}',
      at: egg.stageStartedAt.add(Duration(hours: egg.incubationHours)),
      title: strings.pick(
          'Your Mysterious Egg is ready', 'Je Mysterieus Ei is klaar'),
      body: strings.pick(
        'Something inside wants to hatch in the Rooftop Nest.',
        'Iets binnenin wil uitkomen in het Daknest.',
      ),
    );
  }

  int achievementProgress(String id) => switch (id) {
        'hello_little_one' => totalHatched,
        'first_flight' => totalShortAdventuresCompleted,
        'chest_expectations' => totalChestsOpened,
        'room_to_roost' ||
        'halfway_clouds' ||
        'sky_ceiling' =>
          towerFloorRoomIds.length,
        'feed_furniture' => housePlacements.length,
        'book_wyrm' || 'well_read_scaled' => discoveredCommonLineageCount,
        'scale_every_tale' => discoveredLineageCount,
        'growing_pains' => totalWyrmling,
        'not_picking_favorites' =>
          [pet, ...sanctuaryDragons].any((dragon) => dragon.favorite) ? 1 : 0,
        'ascension_day' => totalAscended,
        'something_spectral' => prismaticForms.isEmpty ? 0 : 1,
        'frequent_flyer' => totalAdventuresCompleted,
        'full_party' => totalGroupFourCompleted,
        'came_crawling_back' => totalReleasedReturns,
        'ghost_writer' =>
          prismaticForms.map((key) => key.split(':').first).toSet().length,
        'myth_made_real' => [pet, ...sanctuaryDragons]
                .any((dragon) => dragon.lineage.rarity == DragonRarity.mythical)
            ? 1
            : 0,
        'probably_fine' => totalSinisterAdventuresCompleted,
        _ => 0,
      };

  bool hasDiscovered(String lineageId, String formKey,
      {bool prismatic = false}) {
    final key = '$lineageId:$formKey';
    return (prismatic ? prismaticForms : discoveredForms).contains(key);
  }

  Future<PurchaseResult> purchaseOrEquip(ShopItem item) async {
    if (housePlacements.any((placement) => placement.itemId == item.id)) {
      return PurchaseResult.alreadyEquipped;
    }
    if (ownedItemIds.contains(item.id)) {
      _autoPlace(item);
      _evaluateAchievements();
      await _notifyAndSave();
      return PurchaseResult.equipped;
    }
    if (item.currency == ItemCurrency.coins && pet.coins < item.price) {
      return PurchaseResult.insufficientCoins;
    }
    if (item.currency == ItemCurrency.gems && pet.gems < item.price) {
      return PurchaseResult.insufficientGems;
    }
    if (item.currency == ItemCurrency.coins) {
      pet.coins -= item.price;
    } else {
      pet.gems -= item.price;
    }
    ownedItemIds.add(item.id);
    _autoPlace(item);
    _addActivity(
        message: '${item.name} was placed in ${activeRoom.id}.',
        type: ActivityType.purchase,
        code: ActivityCode.itemPlaced,
        subject: item.id,
        coins: item.currency == ItemCurrency.coins ? -item.price : 0,
        gems: item.currency == ItemCurrency.gems ? -item.price : 0);
    _evaluateAchievements();
    await _notifyAndSave();
    return PurchaseResult.purchased;
  }

  bool owns(ShopItem item) => ownedItemIds.contains(item.id);
  bool isEquipped(ShopItem item) =>
      housePlacements.any((placement) => placement.itemId == item.id);

  Future<RoomUnlockResult> unlockRoom(HouseRoomDefinition room) async {
    if (unlockedRoomIds.contains(room.id)) {
      if (activeRoomId != room.id) {
        activeRoomId = room.id;
        await _notifyAndSave();
      }
      return RoomUnlockResult.alreadyUnlocked;
    }
    if (pet.level < room.unlockLevel) return RoomUnlockResult.levelLocked;
    if (pet.coins < room.price) return RoomUnlockResult.insufficientCoins;
    pet.coins -= room.price;
    unlockedRoomIds.add(room.id);
    activeRoomId = room.id;
    _evaluateAchievements();
    await _notifyAndSave();
    return RoomUnlockResult.unlocked;
  }

  Future<bool> selectRoom(String roomId) async {
    if (!unlockedRoomIds.contains(roomId) || activeRoomId == roomId) {
      return false;
    }
    activeRoomId = roomId;
    await _notifyAndSave();
    return true;
  }

  Future<bool> placeHouseItem(String itemId,
      {required String roomId, required double x, required double y}) async {
    if (!x.isFinite ||
        !y.isFinite ||
        !ownedItemIds.contains(itemId) ||
        !unlockedRoomIds.contains(roomId)) {
      return false;
    }
    final item = shopItemById(itemId);
    if (item == null) return false;
    housePlacements.removeWhere((placement) => placement.itemId == itemId);
    housePlacements.add(HousePlacement(
        itemId: itemId,
        roomId: roomId,
        x: x.clamp(0.04, 0.96).toDouble(),
        y: y.clamp(0.04, 0.96).toDouble()));
    equippedItemIds[item.slot] = item.id;
    _evaluateAchievements();
    await _notifyAndSave();
    return true;
  }

  Future<bool> moveHouseItem(String itemId, double x, double y) async {
    if (!x.isFinite || !y.isFinite) return false;
    final index =
        housePlacements.indexWhere((placement) => placement.itemId == itemId);
    if (index < 0) return false;
    housePlacements[index] = housePlacements[index].copyWith(x: x, y: y);
    await _notifyAndSave();
    return true;
  }

  Future<bool> removeHouseItem(String itemId) async {
    final before = housePlacements.length;
    housePlacements.removeWhere((placement) => placement.itemId == itemId);
    if (before == housePlacements.length) return false;
    _rebuildEquippedItems();
    await _notifyAndSave();
    return true;
  }

  Future<void> refreshForCurrentDate() async {
    final adventureOptionsBefore = [
      ...?adventureOptionIds[AdventureKind.mini],
      '#',
      ...?adventureOptionIds[AdventureKind.short],
      '#',
      ...?adventureOptionIds[AdventureKind.long],
      miniAdventureRefilledAt?.toIso8601String() ?? '',
      shortAdventureRefilledAt?.toIso8601String() ?? '',
      longAdventureRefillDay,
    ].join('|');
    adventuresFor(AdventureKind.mini);
    adventuresFor(AdventureKind.short);
    adventuresFor(AdventureKind.long);
    final adventureOptionsAfter = [
      ...?adventureOptionIds[AdventureKind.mini],
      '#',
      ...?adventureOptionIds[AdventureKind.short],
      '#',
      ...?adventureOptionIds[AdventureKind.long],
      miniAdventureRefilledAt?.toIso8601String() ?? '',
      shortAdventureRefilledAt?.toIso8601String() ?? '',
      longAdventureRefillDay,
    ].join('|');
    final changed = (adventureOptionsBefore != adventureOptionsAfter) |
        pet.applyTimeDecay(_clock()) |
        _registerCurrentStage() |
        _refreshAdventureRuns() |
        _expireReturningVisitors() |
        _processWeeklyReturningDragon() |
        roamIdleDragons();
    final achievementsChanged = _evaluateAchievements();
    if (changed || achievementsChanged) await _notifyAndSave();
  }

  DragonEgg _createEgg({required ChestTier sourceTier}) {
    final seed = _random.nextInt(0x7fffffff);
    final lineage = _rollEggLineage(sourceTier);
    final sinister = sourceTier == ChestTier.sinister &&
        lineage.rarity == DragonRarity.mythical &&
        _random.nextBool();
    final sizeRoll = _random.nextDouble();
    return DragonEgg(
      id: _uuid.v4(),
      lineageId: lineage.id,
      acquiredAt: _clock(),
      hatchSeed: seed,
      prismatic: _random.nextInt(20) == 0,
      lawAxis: LawAxis.values[_random.nextInt(LawAxis.values.length)],
      moralAxis: sinister
          ? MoralAxis.evil
          : MoralAxis.values[_random.nextInt(MoralAxis.values.length)],
      sizeFactor: _dragonSizeFromRoll(sizeRoll),
      incubationHours: 48 + _random.nextInt(289),
      sinister: sinister,
    );
  }

  DragonLineage _rollEggLineage(ChestTier sourceTier) {
    // Every chest tier has its own rarity curve. The later curves deliberately
    // make exceptional families more plausible without making Mythical routine.
    final roll = _random.nextDouble();
    final thresholds = switch (sourceTier) {
      ChestTier.wooden => const [.75, .95, .995, .9995, .99999],
      ChestTier.silver => const [.65, .90, .98, .997, .9998],
      ChestTier.gold => const [.50, .80, .94, .99, .999],
      ChestTier.dragon => const [.25, .55, .80, .95, .995],
      ChestTier.mythical || ChestTier.sinister => const [
          .10,
          .30,
          .55,
          .80,
          .97
        ],
    };
    final rarity = roll < thresholds[0]
        ? DragonRarity.common
        : roll < thresholds[1]
            ? DragonRarity.uncommon
            : roll < thresholds[2]
                ? DragonRarity.rare
                : roll < thresholds[3]
                    ? DragonRarity.veryRare
                    : roll < thresholds[4]
                        ? DragonRarity.legendary
                        : DragonRarity.mythical;
    final candidates =
        dragonLineages.where((lineage) => lineage.rarity == rarity).toList();
    return candidates[_random.nextInt(candidates.length)];
  }

  bool _registerCurrentStage() => _registerDragonStage(pet);

  bool _registerDragonStage(Pet dragon) {
    if (dragon.isEgg) return false;
    final collection = dragon.prismatic ? prismaticForms : discoveredForms;
    final forms = <String>['hatchling'];
    if (dragon.stage.index >= DragonStage.wyrmling.index) {
      forms.add('wyrmling');
    }
    if (dragon.stage == DragonStage.ascended) {
      forms.add('ascended:${dragon.activeEvolutionPath}');
    }
    var changed = false;
    for (final form in forms) {
      changed = collection.add('${dragon.lineageId}:$form') || changed;
    }
    return changed;
  }

  bool _evaluateAchievements({bool addActivities = true}) {
    var changed = false;
    for (final achievement in achievementCatalog) {
      if (unlockedAchievementIds.contains(achievement.id) ||
          achievementProgress(achievement.id) < achievement.target) {
        continue;
      }
      unlockedAchievementIds.add(achievement.id);
      changed = true;
      final unlockedAt = _clock();
      _queuePresentation(GamePresentation(
        id: 'achievement-${achievement.id}',
        type: GamePresentationType.achievement,
        achievementId: achievement.id,
        createdAt: unlockedAt,
        sortAt: unlockedAt,
      ));
      final strings = AppStrings(languageCode);
      final title = strings.achievementTitle(achievement);
      unawaited(HavenNotifications.achievementUnlocked(
        id: achievement.id,
        title: strings.tr('achievement_unlocked'),
        body: title,
      ));
      if (addActivities) {
        _addActivity(
            message: 'Achievement unlocked: ${achievement.titleEn}',
            type: ActivityType.milestone,
            code: ActivityCode.achievement,
            subject: achievement.id);
      }
    }
    return changed;
  }

  void _addActivity(
      {required String message,
      required ActivityType type,
      required ActivityCode code,
      String? subject,
      int xp = 0,
      int coins = 0,
      int gems = 0}) {
    activities.insert(
        0,
        ActivityEntry(
            id: _uuid.v4(),
            message: message,
            createdAt: _clock(),
            type: type,
            code: code,
            subject: subject,
            xp: xp,
            coins: coins,
            gems: gems));
    _trimActivities();
  }

  void _trimActivities() {
    if (activities.length > 40) activities = activities.take(40).toList();
  }

  void _autoPlace(ShopItem item, {String? roomId}) {
    final targetRoom = unlockedRoomIds.contains(roomId ?? activeRoomId)
        ? roomId ?? activeRoomId
        : 'nest';
    housePlacements.removeWhere((placement) => placement.itemId == item.id);
    final slotIndex = placementsForRoom(targetRoom)
        .where((placement) => shopItemById(placement.itemId)?.slot == item.slot)
        .length;
    housePlacements.add(defaultPlacementFor(item, targetRoom, slotIndex));
    equippedItemIds[item.slot] = item.id;
  }

  void _rebuildEquippedItems() {
    equippedItemIds.clear();
    for (final placement in housePlacements) {
      final item = shopItemById(placement.itemId);
      if (item != null) equippedItemIds[item.slot] = item.id;
    }
  }

  Future<void> _notifyAndSave() async {
    notifyListeners();
    await _save();
  }

  Future<void> _save() {
    if (!_persistenceEnabled) return Future<void>.value();
    final state = <String, dynamic>{
      'schemaVersion': _schemaVersion,
      'languageCode': languageCode,
      'accountName': accountName,
      'onboardingComplete': onboardingComplete,
      'musicEnabled': musicEnabled,
      'soundEffectsEnabled': soundEffectsEnabled,
      'achievementsCompact': achievementsCompact,
      'pet': pet.toJson(),
      'incubatingEgg': incubatingEgg?.toJson(),
      'eggStash': eggStash.map((egg) => egg.toJson()).toList(),
      'sanctuaryDragons':
          sanctuaryDragons.map((dragon) => dragon.toJson()).toList(),
      'chestInventory': {
        for (final entry in chestInventory.entries) entry.key.name: entry.value
      },
      'relicInventory': {
        for (final entry in relicInventory.entries) entry.key.name: entry.value
      },
      'discoveredForms': discoveredForms.toList(),
      'prismaticForms': prismaticForms.toList(),
      'achievements': unlockedAchievementIds.toList(),
      'pendingPresentations':
          pendingPresentations.map((event) => event.toJson()).toList(),
      'totalHatched': totalHatched,
      'totalNamed': totalNamed,
      'totalWyrmling': totalWyrmling,
      'totalAscended': totalAscended,
      'totalChestsOpened': totalChestsOpened,
      'totalAdventuresCompleted': totalAdventuresCompleted,
      'totalShortAdventuresCompleted': totalShortAdventuresCompleted,
      'totalGroupFourCompleted': totalGroupFourCompleted,
      'totalReleasedReturns': totalReleasedReturns,
      'totalSinisterAdventuresCompleted': totalSinisterAdventuresCompleted,
      'adventureRuns': adventureRuns.map((run) => run.toJson()).toList(),
      'adventureOptionIds': {
        for (final entry in adventureOptionIds.entries)
          entry.key.name: entry.value,
      },
      'miniAdventureRefilledAt': miniAdventureRefilledAt?.toIso8601String(),
      'shortAdventureRefilledAt': shortAdventureRefilledAt?.toIso8601String(),
      'longAdventureRefillDay': longAdventureRefillDay,
      'towerFloorRoomIds': towerFloorRoomIds,
      'releasedDragons':
          releasedDragons.map((dragon) => dragon.toJson()).toList(),
      'dragonWardLevel': dragonWardLevel,
      'damagedTowerFloors': damagedTowerFloors.toList(),
      'damagedTowerRepairFactors': {
        for (final entry in damagedTowerRepairFactors.entries)
          '${entry.key}': entry.value,
      },
      'returningVisitors': {
        for (final entry in returningVisitors.entries)
          entry.key: entry.value.toIso8601String(),
      },
      'rareInteractionAt': {
        for (final entry in rareInteractionAt.entries)
          entry.key: entry.value.toIso8601String(),
      },
      'lastReturningWeekKey': lastReturningWeekKey,
      'latestReturningEvent': latestReturningEvent,
      'returningSpecialAdventureId': returningSpecialAdventureId,
      'returningSpecialAvailableUntil':
          returningSpecialAvailableUntil?.toIso8601String(),
      'ownedItemIds': ownedItemIds.toList(),
      'equippedItemIds': {
        for (final entry in equippedItemIds.entries) entry.key.name: entry.value
      },
      'unlockedRoomIds': unlockedRoomIds.toList(),
      'activeRoomId': activeRoomId,
      'housePlacements':
          housePlacements.map((placement) => placement.toJson()).toList(),
      'activities': activities.map((entry) => entry.toJson()).toList(),
    };
    final operation = _saveQueue.then((_) => StorageService.save(state),
        onError: (_) => StorageService.save(state));
    _saveQueue = operation;
    return operation;
  }

  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
