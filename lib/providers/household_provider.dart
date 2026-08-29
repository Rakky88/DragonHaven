import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_strings.dart';
import '../models/account_title.dart';
import '../models/achievement.dart';
import '../models/adventure.dart';
import '../models/activity_entry.dart';
import '../models/chest.dart';
import '../models/dragon_egg.dart';
import '../models/dragon_lineage.dart';
import '../models/game_presentation.dart';
import '../models/house.dart';
import '../models/mystic_relic.dart';
import '../models/music_track.dart';
import '../models/pet.dart';
import '../models/profile_portrait.dart';
import '../models/shop_item.dart';
import '../models/tower_interaction.dart';
import '../models/trial.dart';
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

enum MysticRelicPurchaseResult {
  purchased,
  insufficientGems,
  notAvailable,
}

enum AstralLensUseResult { revealed, notOwned, eggNotFound, alreadyKnown }

enum ChronoshardUseResult { accelerated, notOwned, noEggInNest }

enum WayfinderSigilUseResult {
  changed,
  notOwned,
  unsupportedAdventure,
  adventureNotFound,
  noCapacity,
}

enum PortraitChestPurchaseResult {
  purchased,
  insufficientGems,
  collectionComplete,
}

enum TitleChestPurchaseResult {
  purchased,
  insufficientCoins,
  collectionComplete,
}

enum MusicChestPurchaseResult {
  purchased,
  insufficientGems,
  collectionComplete,
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
  static const saveSchemaVersion = 44;

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
  Timer? _starterEggTapPersistenceTimer;
  int _localMutationRevision = 0;
  int _presentationDeferralDepth = 0;

  String languageCode = 'en';
  String accountName = '';
  bool onboardingComplete = false;
  bool musicEnabled = true;
  HavenMusicStyle musicStyle = HavenMusicStyle.classic;
  Set<String> ownedMusicTrackIds = {'reverie'};
  Set<String> enabledMusicTrackIds = {'reverie'};
  bool jukeboxShuffle = false;
  bool jukeboxRepeat = true;
  bool soundEffectsEnabled = true;
  Set<HavenNotificationCategory> enabledNotificationCategories =
      HavenNotificationCategory.values.toSet();
  bool achievementsCompact = false;
  bool tutorialCompleted = false;
  bool tutorialFullyViewed = false;
  bool showcaseMode = false;

  int get localMutationRevision => _localMutationRevision;
  bool get presentationsDeferred => _presentationDeferralDepth > 0;

  void beginPresentationDeferral() {
    _presentationDeferralDepth++;
  }

  void endPresentationDeferral() {
    if (_presentationDeferralDepth == 0) return;
    _presentationDeferralDepth--;
    if (_presentationDeferralDepth == 0) notifyListeners();
  }

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
  Map<MysticRelic, int> untradeableRelicInventory = {
    for (final relic in MysticRelic.values) relic: 0,
  };
  Set<String> ownedPortraitIds = {};
  String? selectedPortraitId;
  Set<String> ownedTitleIds = {};
  String? selectedTitleId;
  Set<String> eggRarityRevealedIds = {};
  List<int> chronoshardReductions = [];
  bool twinstarBroochEverObtained = false;
  String? twinstarBroochDragonId;
  Set<String> discoveredForms = {};
  Set<String> prismaticForms = {};
  Set<String> unlockedAchievementIds = {};
  List<GamePresentation> pendingPresentations = [];
  int totalHatched = 0;
  int totalNamed = 0;
  int totalWyrmling = 0;
  int totalAscended = 0;
  int totalChestsOpened = 0;
  int totalPortraitChestsOpened = 0;
  int totalTitleChestsOpened = 0;
  int totalMusicChestsOpened = 0;
  int totalAdventuresCompleted = 0;
  int totalShortAdventuresCompleted = 0;
  int totalGroupFourCompleted = 0;
  int totalReleasedReturns = 0;
  int totalSinisterAdventuresCompleted = 0;
  int favoriteChanges = 0;

  List<AdventureRun> adventureRuns = [];
  List<TrialOffer> trialOffers = [];
  DateTime? trialRefilledAt;
  Set<String> appliedOnlineGroupRewardIds = {};
  Set<String> appliedOnlineTradeIds = {};
  Set<String> reservedOnlineTradeEggIds = {};
  Map<String, int> reservedOnlineTradeChests = {};
  Map<String, int> reservedOnlineTradeRelics = {};
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
  String lastReturningDayKey = '';
  DateTime? scheduledReturningAt;
  String? latestReturningEvent;
  String? returningSpecialAdventureId;
  DateTime? returningSpecialAvailableUntil;
  Set<String> startedSeasonalSpecialEventKeys = {};
  Set<String> notifiedSeasonalSpecialEventKeys = {};

  Set<String> ownedItemIds = {};
  Map<ItemSlot, String> equippedItemIds = {};
  Set<String> unlockedRoomIds = {'nest'};
  String activeRoomId = 'nest';
  List<HousePlacement> housePlacements = [];
  List<ActivityEntry> activities = [];

  static const _schemaVersion = saveSchemaVersion;

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

  /// Creates a non-persistent focused account for Android release UI audits.
  static HouseholdProvider createReleaseDemo() {
    final now = DateTime.now();
    final provider = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: Random(20260824),
      clock: DateTime.now,
    );
    provider._initializeFresh();
    provider
      ..accountName = 'Release Keeper'
      ..onboardingComplete = true
      ..tutorialCompleted = true
      ..tutorialFullyViewed = true
      ..musicEnabled = true
      ..soundEffectsEnabled = true
      ..pet = Pet(
        id: 'release-demo-favorite',
        name: 'Nova',
        stage: DragonStage.wyrmling,
        firstEgg: false,
        favorite: true,
        roamsTower: true,
        currentRoomId: 'hearth',
        currentFloorIndex: 0,
        coins: 12500,
        gems: 499,
        hatchSeed: 20260824,
        lineageId: dragonLineages.first.id,
        acquiredAt: now.subtract(const Duration(days: 18)),
        stageStartedAt: now.subtract(const Duration(days: 6)),
      )
      ..sanctuaryDragons = [
        Pet(
          id: 'release-demo-roommate-a',
          name: 'Cinder',
          stage: DragonStage.hatchling,
          firstEgg: false,
          roamsTower: true,
          currentRoomId: 'hearth',
          currentFloorIndex: 0,
          hatchSeed: 20260825,
          lineageId: dragonLineages[1].id,
        ),
        Pet(
          id: 'release-demo-roommate-b',
          name: 'Mistral',
          stage: DragonStage.wyrmling,
          firstEgg: false,
          roamsTower: true,
          currentRoomId: 'hearth',
          currentFloorIndex: 0,
          hatchSeed: 20260826,
          lineageId: dragonLineages[2].id,
        ),
      ]
      ..towerFloorRoomIds = ['hearth', 'crystal', 'garden']
      ..unlockedRoomIds = {'nest', 'hearth', 'crystal', 'garden'}
      ..activeRoomId = 'hearth'
      ..chestInventory[ChestTier.portrait] = 2
      ..chestInventory[ChestTier.title] = 2
      ..ownedPortraitIds =
          profilePortraitCatalog.take(8).map((portrait) => portrait.id).toSet()
      ..selectedPortraitId = profilePortraitCatalog.first.id
      ..ownedTitleIds =
          accountTitleCatalog.take(8).map((title) => title.id).toSet()
      ..selectedTitleId = accountTitleCatalog.first.id
      ..relicInventory = {
        for (final relic in MysticRelic.values) relic: 1,
      }
      ..trialOffers = [
        TrialOffer(
          id: 'release-demo-flight',
          kind: TrialKind.cavernFlight,
          appearedAt: now,
        ),
        TrialOffer(
          id: 'release-demo-ruin',
          kind: TrialKind.ruinBreaker,
          appearedAt: now,
        ),
        TrialOffer(
          id: 'release-demo-rune',
          kind: TrialKind.runeweaver,
          appearedAt: now,
        ),
      ]
      ..trialRefilledAt = now
      ..unlockedAchievementIds =
          achievementCatalog.map((achievement) => achievement.id).toSet()
      ..pendingPresentations = [];
    provider._ensureFavoriteDragon();
    provider._normalizeRoamingState();
    return provider;
  }

  /// Creates a non-persistent account that immediately presents the automatic
  /// Hatchling-to-Wyrmling evolution on an emulator or test device.
  static HouseholdProvider createEvolutionDemo() {
    final now = DateTime.now();
    final provider = HouseholdProvider(
      persistenceEnabled: false,
      random: Random(20260823),
      clock: DateTime.now,
    );
    provider
      ..accountName = 'Evolution Keeper'
      ..onboardingComplete = true
      ..tutorialCompleted = true
      ..tutorialFullyViewed = true;
    provider.pet
      ..name = 'Nova'
      ..stage = DragonStage.hatchling
      ..xp = Pet.wyrmlingXp
      ..stageStartedAt = now.subtract(const Duration(days: 3))
      ..favorite = true;
    return provider;
  }

  /// Creates a non-persistent full Tower account with a normal egg visibly
  /// incubating in the Rooftop Nest for emulator layout reviews.
  static HouseholdProvider createNestDemo() {
    final provider = createShowcase();
    final now = DateTime.now();
    provider
      ..accountName = 'Rooftop Nest Keeper'
      ..incubatingEgg = Pet(
        id: 'nest-layout-demo-egg',
        stage: DragonStage.egg,
        firstEgg: false,
        incubationMinutes: 144,
        acquiredAt: now,
        stageStartedAt: now,
        needsUpdatedAt: now,
        hatchSeed: 20260824,
        lineageId: dragonLineages[3].id,
      )
      ..pendingPresentations = [];
    return provider;
  }

  /// Creates a non-persistent emulator account whose Starter Egg hatches
  /// three minutes after the app starts.
  static HouseholdProvider createHatchDemo({
    Duration countdown = const Duration(minutes: 3),
  }) {
    if (countdown <= Duration.zero || countdown > const Duration(hours: 1)) {
      throw ArgumentError.value(
        countdown,
        'countdown',
        'Must be greater than zero and at most one hour.',
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
          provider.pet.incubationDuration - countdown,
        );
    return provider;
  }

  static Future<HouseholdProvider> loadFromStorage() async {
    var provider = HouseholdProvider(initialize: false);
    final data = await StorageService.load();
    if (data == null) {
      provider._initializeFresh();
      await provider._save();
      return provider;
    }
    try {
      await _restoreStoredState(provider, data);
    } on Object {
      await StorageService.preserveCurrentForRecovery();
      final backup = await StorageService.loadBackup();
      var recovered = false;
      if (backup != null) {
        final backupProvider = HouseholdProvider(initialize: false);
        try {
          await _restoreStoredState(backupProvider, backup);
          if (await StorageService.promoteBackup()) {
            provider = backupProvider;
            recovered = true;
          }
        } on Object {
          recovered = false;
        }
      }
      if (!recovered) {
        const supportedLanguages = {
          'en',
          'nl',
          'de',
          'fr',
          'es',
          'pt',
          'it',
          'ja'
        };
        final rawLanguage = stringFromJson(data['languageCode']);
        final savedLanguage =
            supportedLanguages.contains(rawLanguage) ? rawLanguage! : 'en';
        provider._initializeFresh();
        provider.languageCode = savedLanguage;
        await provider._save();
      }
    }
    await provider._rescheduleNestEggNotification();
    return provider;
  }

  static Future<void> _restoreStoredState(
    HouseholdProvider provider,
    Map<String, dynamic> data,
  ) async {
    final storedPet = data['pet'];
    if (storedPet is! Map || storedPet.isEmpty) {
      throw const FormatException('Stored game has no dragon state.');
    }
    provider._restore(data);
    final schemaChanged = data['schemaVersion'] != _schemaVersion;
    final evolutionChanged = provider._evolveReadyDragons(provider._clock());
    final changed = provider.pet.applyTimeDecay(provider._clock()) |
        provider._registerOwnedDragonStages();
    final achievementsChanged =
        provider._evaluateAchievements(addActivities: false);
    if (schemaChanged || evolutionChanged || changed || achievementsChanged) {
      await provider._save();
    }
  }

  void _initializeFresh() {
    enabledNotificationCategories = HavenNotificationCategory.values.toSet();
    HavenNotifications.configure(enabledNotificationCategories);
    ownedMusicTrackIds = {'reverie'};
    enabledMusicTrackIds = {'reverie'};
    jukeboxShuffle = false;
    jukeboxRepeat = true;
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
      incubationMinutes: 60,
      acquiredAt: now,
      stageStartedAt: now,
    );
    incubatingEgg = null;
    tutorialCompleted = false;
    tutorialFullyViewed = false;
    final commonPortraits = profilePortraitCatalog
        .where((portrait) => portrait.rarity == PortraitRarity.common)
        .toList(growable: false);
    final starterPortrait =
        commonPortraits[_random.nextInt(commonPortraits.length)];
    ownedPortraitIds = {starterPortrait.id};
    selectedPortraitId = starterPortrait.id;
    final starterTitle =
        accountTitleCatalog[_random.nextInt(accountTitleCatalog.length)];
    ownedTitleIds = {starterTitle.id};
    selectedTitleId = starterTitle.id;
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
    tutorialCompleted = true;
    tutorialFullyViewed = true;

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
    totalPortraitChestsOpened = 1;
    totalTitleChestsOpened = 1;
    totalMusicChestsOpened = musicCatalog.length;
    totalAdventuresCompleted = 1000;
    totalShortAdventuresCompleted = 100;
    totalGroupFourCompleted = 10;
    totalReleasedReturns = 20;
    totalSinisterAdventuresCompleted = 5;
    chestInventory = {for (final tier in ChestTier.values) tier: 25};
    relicInventory = {for (final relic in MysticRelic.values) relic: 3};
    relicInventory[MysticRelic.twinstarBrooch] = 1;
    untradeableRelicInventory[MysticRelic.twinstarBrooch] = 1;
    chronoshardReductions = [25, 50, 75];
    twinstarBroochEverObtained = true;
    twinstarBroochDragonId = pet.id;
    ownedPortraitIds =
        profilePortraitCatalog.map((portrait) => portrait.id).toSet();
    selectedPortraitId = profilePortraitCatalog.last.id;
    ownedTitleIds = accountTitleCatalog.map((title) => title.id).toSet();
    selectedTitleId = accountTitleCatalog.last.id;
    ownedMusicTrackIds = musicCatalog.map((track) => track.id).toSet();
    enabledMusicTrackIds = {...ownedMusicTrackIds};
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
    const supportedLanguages = {'en', 'nl', 'de', 'fr', 'es', 'pt', 'it', 'ja'};
    final storedLanguage = stringFromJson(data['languageCode']);
    languageCode =
        supportedLanguages.contains(storedLanguage) ? storedLanguage! : 'en';
    accountName = stringFromJson(data['accountName'])?.trim() ?? '';
    onboardingComplete = data['onboardingComplete'] is bool
        ? data['onboardingComplete'] as bool
        : true;
    musicEnabled =
        data['musicEnabled'] is! bool || data['musicEnabled'] as bool;
    // Rêverie is DragonHaven's sole soundtrack. Older saves can still contain
    // the retired "basic" preference, which deliberately migrates to classic.
    musicStyle = HavenMusicStyle.classic;
    ownedMusicTrackIds = stringSetFromJson(data['ownedMusicTrackIds'])
        .where(musicTracksById.containsKey)
        .toSet();
    if (ownedMusicTrackIds.isEmpty) ownedMusicTrackIds.add('reverie');
    enabledMusicTrackIds = data.containsKey('enabledMusicTrackIds')
        ? stringSetFromJson(data['enabledMusicTrackIds'])
            .where(ownedMusicTrackIds.contains)
            .toSet()
        : {'reverie'};
    jukeboxShuffle =
        data['jukeboxShuffle'] is bool && data['jukeboxShuffle'] as bool;
    jukeboxRepeat =
        data['jukeboxRepeat'] is! bool || data['jukeboxRepeat'] as bool;
    soundEffectsEnabled = data['soundEffectsEnabled'] is! bool ||
        data['soundEffectsEnabled'] as bool;
    final storedNotificationCategories = data['enabledNotificationCategories'];
    enabledNotificationCategories = storedNotificationCategories is List
        ? storedNotificationCategories
            .whereType<String>()
            .map((name) => HavenNotificationCategory.values
                .cast<HavenNotificationCategory?>()
                .firstWhere(
                  (category) => category?.name == name,
                  orElse: () => null,
                ))
            .whereType<HavenNotificationCategory>()
            .toSet()
        : HavenNotificationCategory.values.toSet();
    // Version 2 introduced Special Event notifications. Existing saves inherit
    // the requested default-on setting once; afterwards an explicit opt-out is
    // preserved because version 2 is saved alongside the category list.
    if ((data['notificationSettingsVersion'] as num?)?.toInt() != 2) {
      enabledNotificationCategories
          .add(HavenNotificationCategory.specialEvents);
    }
    HavenNotifications.configure(enabledNotificationCategories);
    achievementsCompact = data['achievementsCompact'] is bool &&
        data['achievementsCompact'] as bool;
    pet = Pet.fromJson(mapFromJson(data['pet']));
    tutorialCompleted = data['tutorialCompleted'] is bool
        ? data['tutorialCompleted'] as bool
        : !pet.isEgg;
    tutorialFullyViewed = data['tutorialFullyViewed'] is bool &&
        data['tutorialFullyViewed'] as bool;
    final storedIncubatingEgg = mapFromJson(data['incubatingEgg']);
    incubatingEgg =
        storedIncubatingEgg.isEmpty ? null : Pet.fromJson(storedIncubatingEgg);
    if (incubatingEgg?.isEgg != true) incubatingEgg = null;
    eggStash = mapsFromJson(data['eggStash']).map(DragonEgg.fromJson).toList();
    final currentEggIds = {
      if (pet.isEgg) pet.id,
      if (incubatingEgg?.isEgg == true) incubatingEgg!.id,
      for (final egg in eggStash) egg.id,
    };
    eggRarityRevealedIds = stringSetFromJson(data['eggRarityRevealedIds'])
        .where(currentEggIds.contains)
        .toSet();
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
    final rawUntradeableRelics = mapFromJson(data['untradeableRelicInventory']);
    untradeableRelicInventory = {
      for (final relic in MysticRelic.values)
        relic: min(
          relicCount(relic),
          nonNegativeIntFromJson(
            rawUntradeableRelics[relic.name],
            fallback: 0,
          ),
        ),
    };
    twinstarBroochEverObtained = data['twinstarBroochEverObtained'] == true ||
        relicCount(MysticRelic.twinstarBrooch) > 0;
    if (twinstarBroochEverObtained) {
      relicInventory[MysticRelic.twinstarBrooch] = 1;
      untradeableRelicInventory[MysticRelic.twinstarBrooch] = 1;
      final equippedDragonId = stringFromJson(data['twinstarBroochDragonId']);
      twinstarBroochDragonId = ownedDragons.any(
        (dragon) => dragon.id == equippedDragonId,
      )
          ? equippedDragonId
          : null;
    } else {
      relicInventory[MysticRelic.twinstarBrooch] = 0;
      untradeableRelicInventory[MysticRelic.twinstarBrooch] = 0;
      twinstarBroochDragonId = null;
    }
    final storedChronoshards = (data['chronoshardReductions'] is List
            ? data['chronoshardReductions'] as List
            : const [])
        .whereType<num>()
        .map((value) => value.toInt().clamp(10, 90))
        .take(relicCount(MysticRelic.chronoshard))
        .toList();
    while (storedChronoshards.length < relicCount(MysticRelic.chronoshard)) {
      storedChronoshards.add(10 + _random.nextInt(81));
    }
    chronoshardReductions = storedChronoshards;
    ownedPortraitIds = stringSetFromJson(data['ownedPortraitIds'])
        .where((id) => profilePortraitById(id) != null)
        .toSet();
    final storedPortraitId = stringFromJson(data['selectedPortraitId']);
    selectedPortraitId =
        ownedPortraitIds.contains(storedPortraitId) ? storedPortraitId : null;
    if (ownedPortraitIds.isEmpty) {
      final commonPortraits = profilePortraitCatalog
          .where((portrait) => portrait.rarity == PortraitRarity.common)
          .toList(growable: false);
      final starter = commonPortraits[_random.nextInt(commonPortraits.length)];
      ownedPortraitIds.add(starter.id);
      selectedPortraitId = starter.id;
    } else {
      selectedPortraitId ??= ownedPortraitIds.first;
    }
    ownedTitleIds = stringSetFromJson(data['ownedTitleIds'])
        .where((id) => accountTitleById(id) != null)
        .toSet();
    final storedTitleId = stringFromJson(data['selectedTitleId']);
    selectedTitleId =
        ownedTitleIds.contains(storedTitleId) ? storedTitleId : null;
    if (ownedTitleIds.isEmpty) {
      final starter =
          accountTitleCatalog[_random.nextInt(accountTitleCatalog.length)];
      ownedTitleIds.add(starter.id);
      selectedTitleId = starter.id;
    } else {
      selectedTitleId ??= ownedTitleIds.first;
    }
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
    totalPortraitChestsOpened =
        nonNegativeIntFromJson(data['totalPortraitChestsOpened'], fallback: 0);
    totalTitleChestsOpened =
        nonNegativeIntFromJson(data['totalTitleChestsOpened'], fallback: 0);
    totalMusicChestsOpened =
        nonNegativeIntFromJson(data['totalMusicChestsOpened'], fallback: 0);
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
    favoriteChanges =
        nonNegativeIntFromJson(data['favoriteChanges'], fallback: 0);
    appliedOnlineGroupRewardIds =
        stringSetFromJson(data['appliedOnlineGroupRewardIds'])
            .take(500)
            .toSet();
    appliedOnlineTradeIds =
        stringSetFromJson(data['appliedOnlineTradeIds']).take(500).toSet();
    reservedOnlineTradeEggIds =
        stringSetFromJson(data['reservedOnlineTradeEggIds']);
    final rawReservedTradeChests =
        mapFromJson(data['reservedOnlineTradeChests']);
    reservedOnlineTradeChests = {
      for (final entry in rawReservedTradeChests.entries)
        entry.key: nonNegativeIntFromJson(entry.value, fallback: 0),
    }..removeWhere((_, value) => value <= 0);
    final rawReservedTradeRelics =
        mapFromJson(data['reservedOnlineTradeRelics']);
    reservedOnlineTradeRelics = {
      for (final entry in rawReservedTradeRelics.entries)
        entry.key: nonNegativeIntFromJson(entry.value, fallback: 0),
    }..removeWhere((_, value) => value <= 0);
    final restoredSchema = nonNegativeIntFromJson(
      data['schemaVersion'],
      fallback: 0,
    );
    if (restoredSchema < 32 && favoriteChanges == 0) {
      unlockedAchievementIds.remove('not_picking_favorites');
    }
    adventureRuns = mapsFromJson(data['adventureRuns'])
        .map(AdventureRun.fromJson)
        .where((run) => AdventureCatalog.byId.containsKey(run.adventureId))
        .toList();
    trialOffers = mapsFromJson(data['trialOffers'])
        .map(TrialOffer.fromJson)
        .where((offer) => offer.id.isNotEmpty)
        .take(3)
        .toList();
    trialRefilledAt =
        DateTime.tryParse(stringFromJson(data['trialRefilledAt']) ?? '');
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
    lastReturningDayKey = stringFromJson(data['lastReturningDayKey']) ?? '';
    scheduledReturningAt =
        DateTime.tryParse(stringFromJson(data['scheduledReturningAt']) ?? '');
    latestReturningEvent = stringFromJson(data['latestReturningEvent']);
    returningSpecialAdventureId =
        stringFromJson(data['returningSpecialAdventureId']);
    returningSpecialAvailableUntil = DateTime.tryParse(
        stringFromJson(data['returningSpecialAvailableUntil']) ?? '');
    startedSeasonalSpecialEventKeys =
        stringSetFromJson(data['startedSeasonalSpecialEventKeys'])
            .take(50)
            .toSet();
    notifiedSeasonalSpecialEventKeys =
        stringSetFromJson(data['notifiedSeasonalSpecialEventKeys'])
            .take(50)
            .toSet();

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
  int openableChestCount(ChestTier tier) {
    final available = tradeableChestCount(tier);
    return switch (tier) {
      ChestTier.portrait => min(available, remainingPortraitCount),
      ChestTier.title => min(
          available,
          max(0, accountTitleCatalog.length - titleCount),
        ),
      ChestTier.music => min(available, remainingMusicTrackCount),
      _ => available,
    };
  }

  int relicCount(MysticRelic relic) => relicInventory[relic] ?? 0;
  int untradeableRelicCount(MysticRelic relic) =>
      untradeableRelicInventory[relic] ?? 0;
  int gameplayRelicCount(MysticRelic relic) =>
      max(0, relicCount(relic) - untradeableRelicCount(relic));
  int reservedOnlineRelicCount(MysticRelic relic) =>
      reservedOnlineTradeRelics.entries
          .where((entry) =>
              entry.key == relic.name || entry.key.startsWith('${relic.name}:'))
          .fold(0, (total, entry) => total + entry.value);
  int usableRelicCount(MysticRelic relic) => max(
        0,
        relicCount(relic) - reservedOnlineRelicCount(relic),
      );

  bool isChronoshardReserved(int reductionPercent) {
    final owned = chronoshardReductions
        .where((value) => value == reductionPercent)
        .length;
    final reserved = reservedOnlineTradeRelics[
            '${MysticRelic.chronoshard.name}:$reductionPercent'] ??
        0;
    return owned <= reserved;
  }

  int get totalRelicCount => relicInventory.values.fold(0, (a, b) => a + b);
  ProfilePortrait? get selectedPortrait =>
      profilePortraitById(selectedPortraitId);
  int get portraitCount => ownedPortraitIds.length;
  bool get hasEveryPortrait =>
      ownedPortraitIds.length >= profilePortraitCatalog.length;
  bool get portraitChestCapacityReached =>
      portraitCount + chestCount(ChestTier.portrait) >=
      profilePortraitCatalog.length;
  int get remainingPortraitCount =>
      max(0, profilePortraitCatalog.length - portraitCount);
  Map<PortraitRarity, int> get remainingPortraitsByRarity => {
        for (final rarity in PortraitRarity.values)
          rarity: profilePortraitCatalog
              .where((portrait) =>
                  portrait.rarity == rarity &&
                  !ownedPortraitIds.contains(portrait.id))
              .length,
      };
  AccountTitle? get selectedAccountTitle => accountTitleById(selectedTitleId);
  int get titleCount => ownedTitleIds.length;
  bool get hasEveryTitle => ownedTitleIds.length >= accountTitleCatalog.length;
  bool get titleChestCapacityReached =>
      titleCount + chestCount(ChestTier.title) >= accountTitleCatalog.length;
  List<MusicTrack> get ownedMusicTracks => musicCatalog
      .where((track) => ownedMusicTrackIds.contains(track.id))
      .toList(growable: false);
  int get musicTrackCount => ownedMusicTrackIds.length;
  bool get hasEveryMusicTrack => musicTrackCount >= musicCatalog.length;
  bool get musicChestCapacityReached =>
      musicTrackCount + chestCount(ChestTier.music) >= musicCatalog.length;
  int get remainingMusicTrackCount =>
      max(0, musicCatalog.length - musicTrackCount);
  List<String> get enabledMusicResourceIds => musicCatalog
      .where((track) => enabledMusicTrackIds.contains(track.id))
      .map((track) => track.rawResourceId)
      .toList(growable: false);

  Future<void> _syncJukeboxAudio() => HavenAudio.configureJukebox(
        trackIds: enabledMusicResourceIds,
        shuffle: jukeboxShuffle,
        repeat: jukeboxRepeat,
      );

  Future<void> setMusicTrackEnabled(String trackId, bool enabled) async {
    if (!ownedMusicTrackIds.contains(trackId)) return;
    final changed = enabled
        ? enabledMusicTrackIds.add(trackId)
        : enabledMusicTrackIds.remove(trackId);
    if (!changed) return;
    await _syncJukeboxAudio();
    await _notifyAndSave();
  }

  Future<void> setJukeboxShuffle(bool value) async {
    if (jukeboxShuffle == value) return;
    jukeboxShuffle = value;
    await _syncJukeboxAudio();
    await _notifyAndSave();
  }

  Future<void> setJukeboxRepeat(bool value) async {
    if (jukeboxRepeat == value) return;
    jukeboxRepeat = value;
    await _syncJukeboxAudio();
    await _notifyAndSave();
  }

  Future<bool> selectProfilePortrait(String portraitId) async {
    if (!ownedPortraitIds.contains(portraitId) ||
        selectedPortraitId == portraitId) {
      return false;
    }
    selectedPortraitId = portraitId;
    await _notifyAndSave();
    return true;
  }

  Future<bool> selectAccountTitle(String titleId) async {
    if (!ownedTitleIds.contains(titleId) || selectedTitleId == titleId) {
      return false;
    }
    selectedTitleId = titleId;
    await _notifyAndSave();
    return true;
  }

  bool notificationEnabled(HavenNotificationCategory category) =>
      enabledNotificationCategories.contains(category);

  Future<void> setNotificationEnabled(
    HavenNotificationCategory category,
    bool enabled,
  ) async {
    final changed = enabled
        ? enabledNotificationCategories.add(category)
        : enabledNotificationCategories.remove(category);
    if (!changed) return;
    HavenNotifications.configure(enabledNotificationCategories);
    if (!enabled) {
      if (category == HavenNotificationCategory.trialsFull) {
        await HavenNotifications.cancel('trials-full');
      } else if (category == HavenNotificationCategory.eggReady) {
        for (final egg in [pet, incubatingEgg].whereType<Pet>()) {
          if (egg.isEgg) await HavenNotifications.cancel('egg-${egg.id}');
        }
      } else if (category == HavenNotificationCategory.specialEvents) {
        await cancelSpecialAdventureNotifications();
      }
    } else if (category == HavenNotificationCategory.trialsFull) {
      _scheduleTrialsFullNotification();
    } else if (category == HavenNotificationCategory.eggReady) {
      await _rescheduleNestEggNotification();
    } else if (category == HavenNotificationCategory.specialEvents) {
      await refreshSpecialAdventureNotifications();
    }
    await _notifyAndSave();
  }

  Future<PortraitChestPurchaseResult> purchasePortraitChest() async {
    if (portraitChestCapacityReached) {
      return PortraitChestPurchaseResult.collectionComplete;
    }
    if (pet.gems < portraitChestGemPrice) {
      return PortraitChestPurchaseResult.insufficientGems;
    }
    pet.gems -= portraitChestGemPrice;
    chestInventory.update(
      ChestTier.portrait,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    _addActivity(
      message: 'A Portrait Chest was purchased.',
      type: ActivityType.purchase,
      code: ActivityCode.portraitChestPurchased,
      subject: ChestTier.portrait.name,
      gems: -portraitChestGemPrice,
    );
    await _notifyAndSave();
    return PortraitChestPurchaseResult.purchased;
  }

  Future<TitleChestPurchaseResult> purchaseTitleChest() async {
    if (titleChestCapacityReached) {
      return TitleChestPurchaseResult.collectionComplete;
    }
    if (pet.coins < titleChestCoinPrice) {
      return TitleChestPurchaseResult.insufficientCoins;
    }
    pet.coins -= titleChestCoinPrice;
    chestInventory.update(
      ChestTier.title,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    _addActivity(
      message: 'A Title Chest was purchased.',
      type: ActivityType.purchase,
      code: ActivityCode.titleChestPurchased,
      subject: ChestTier.title.name,
      coins: -titleChestCoinPrice,
    );
    await _notifyAndSave();
    return TitleChestPurchaseResult.purchased;
  }

  Future<MusicChestPurchaseResult> purchaseMusicChest() async {
    if (musicChestCapacityReached) {
      return MusicChestPurchaseResult.collectionComplete;
    }
    if (pet.gems < musicChestGemPrice) {
      return MusicChestPurchaseResult.insufficientGems;
    }
    pet.gems -= musicChestGemPrice;
    chestInventory.update(
      ChestTier.music,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    _addActivity(
      message: 'A Music Chest was purchased.',
      type: ActivityType.purchase,
      code: ActivityCode.bonusFound,
      subject: ChestTier.music.name,
      gems: -musicChestGemPrice,
    );
    await _notifyAndSave();
    return MusicChestPurchaseResult.purchased;
  }

  bool get hasTwinstarBrooch => relicCount(MysticRelic.twinstarBrooch) > 0;

  bool isTwinstarEquippedOn(String dragonId) =>
      hasTwinstarBrooch && twinstarBroochDragonId == dragonId;

  int _grantDragonXp(Pet dragon, int baseXp) {
    final normalized = baseXp.clamp(0, 100000000).toInt();
    final granted =
        isTwinstarEquippedOn(dragon.id) ? normalized * 2 : normalized;
    dragon.xp += granted;
    return granted;
  }

  Future<bool> equipTwinstarBrooch(String? dragonId) async {
    if (!hasTwinstarBrooch) return false;
    if (dragonId != null &&
        !ownedDragons.any((dragon) => dragon.id == dragonId)) {
      return false;
    }
    if (twinstarBroochDragonId == dragonId) return true;
    twinstarBroochDragonId = dragonId;
    _addActivity(
      message: dragonId == null
          ? 'The Twinstar Brooch was unequipped.'
          : 'The Twinstar Brooch was equipped.',
      type: ActivityType.discovery,
      code: ActivityCode.bonusFound,
      subject: '${MysticRelic.twinstarBrooch.name}:${dragonId ?? 'none'}',
    );
    await _notifyAndSave();
    return true;
  }

  bool isRelicKnownFor(MysticRelic relic, Pet dragon) => switch (relic) {
        MysticRelic.moralPrism => dragon.moralAxisKnown,
        MysticRelic.orderCompass => dragon.lawAxisKnown,
        MysticRelic.soulMirror => dragon.personalityKnown,
        MysticRelic.twinstarBrooch => isTwinstarEquippedOn(dragon.id),
        MysticRelic.astralLens ||
        MysticRelic.chronoshard ||
        MysticRelic.wayfinderSigil =>
          false,
      };

  void _grantRelic(
    MysticRelic relic, {
    bool untradeable = false,
    int? chronoshardReduction,
  }) {
    if (relic == MysticRelic.twinstarBrooch) {
      if (twinstarBroochEverObtained) return;
      twinstarBroochEverObtained = true;
      relicInventory[relic] = 1;
      untradeableRelicInventory[relic] = 1;
      return;
    }
    relicInventory.update(relic, (count) => count + 1, ifAbsent: () => 1);
    if (untradeable || relic.isAlwaysUntradeable) {
      untradeableRelicInventory.update(
        relic,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    if (relic == MysticRelic.chronoshard) {
      chronoshardReductions.add(
        (chronoshardReduction ?? 10 + _random.nextInt(81)).clamp(10, 90),
      );
    }
  }

  void _consumeRelic(MysticRelic relic) {
    if (!relic.isConsumable || relicCount(relic) <= 0) return;
    relicInventory[relic] = relicCount(relic) - 1;
    if (untradeableRelicCount(relic) > 0) {
      untradeableRelicInventory[relic] = untradeableRelicCount(relic) - 1;
    }
  }

  Future<MysticRelicUseResult> useRelic(
    MysticRelic relic,
    String dragonId,
  ) async {
    if (usableRelicCount(relic) <= 0) {
      return MysticRelicUseResult.notOwned;
    }
    final dragon = ownedDragons.cast<Pet?>().firstWhere(
          (candidate) => candidate?.id == dragonId,
          orElse: () => null,
        );
    if (dragon == null) return MysticRelicUseResult.dragonNotFound;
    if (isRelicKnownFor(relic, dragon)) {
      return MysticRelicUseResult.alreadyKnown;
    }
    if (!relic.hasUseAnimation) return MysticRelicUseResult.alreadyKnown;
    _consumeRelic(relic);
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
      case MysticRelic.astralLens:
      case MysticRelic.chronoshard:
      case MysticRelic.wayfinderSigil:
      case MysticRelic.twinstarBrooch:
        return MysticRelicUseResult.alreadyKnown;
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

  Future<MysticRelicPurchaseResult> purchaseRelic(
    MysticRelic relic,
  ) async {
    if (!relic.isShopAvailable) {
      return MysticRelicPurchaseResult.notAvailable;
    }
    if (pet.gems < relicShopGemPrice) {
      return MysticRelicPurchaseResult.insufficientGems;
    }
    pet.gems -= relicShopGemPrice;
    _grantRelic(relic, untradeable: true);
    _addActivity(
      message: 'A ${relic.nameEn} was purchased for $relicShopGemPrice gems.',
      type: ActivityType.purchase,
      code: ActivityCode.bonusFound,
      subject: relic.name,
      gems: -relicShopGemPrice,
    );
    await _notifyAndSave();
    return MysticRelicPurchaseResult.purchased;
  }

  bool isEggRarityKnown(String eggId) => eggRarityRevealedIds.contains(eggId);

  Future<AstralLensUseResult> useAstralLens(String eggId) async {
    if (usableRelicCount(MysticRelic.astralLens) <= 0) {
      return AstralLensUseResult.notOwned;
    }
    final exists =
        nestEgg?.id == eggId || eggStash.any((egg) => egg.id == eggId);
    if (!exists) return AstralLensUseResult.eggNotFound;
    if (isEggRarityKnown(eggId)) return AstralLensUseResult.alreadyKnown;
    _consumeRelic(MysticRelic.astralLens);
    eggRarityRevealedIds.add(eggId);
    _addActivity(
      message: 'An Astral Lens revealed an egg rarity.',
      type: ActivityType.discovery,
      code: ActivityCode.bonusFound,
      subject: '${MysticRelic.astralLens.name}:$eggId',
    );
    await _notifyAndSave();
    return AstralLensUseResult.revealed;
  }

  Future<ChronoshardUseResult> useChronoshard(int reductionPercent) async {
    final index = chronoshardReductions.indexOf(reductionPercent);
    if (index < 0 ||
        usableRelicCount(MysticRelic.chronoshard) <= 0 ||
        isChronoshardReserved(reductionPercent)) {
      return ChronoshardUseResult.notOwned;
    }
    final egg = nestEgg;
    if (egg == null || !egg.isEgg) return ChronoshardUseResult.noEggInNest;
    final now = _clock();
    final hatchAt = egg.stageStartedAt.add(egg.incubationDuration);
    final remaining = hatchAt.difference(now);
    if (remaining > const Duration(seconds: 1)) {
      final reductionMs =
          (remaining.inMilliseconds * reductionPercent / 100).round();
      final nextRemainingMs = max(1000, remaining.inMilliseconds - reductionMs);
      egg.stageStartedAt = now
          .add(Duration(milliseconds: nextRemainingMs))
          .subtract(egg.incubationDuration);
    }
    chronoshardReductions.removeAt(index);
    _consumeRelic(MysticRelic.chronoshard);
    _addActivity(
      message:
          'A Chronoshard shortened the remaining incubation by $reductionPercent%.',
      type: ActivityType.discovery,
      code: ActivityCode.bonusFound,
      subject: '${MysticRelic.chronoshard.name}:$reductionPercent',
    );
    await _rescheduleNestEggNotification();
    await _notifyAndSave();
    return ChronoshardUseResult.accelerated;
  }

  Pet? get nestEgg => pet.isEgg ? pet : incubatingEgg;
  bool get hasEggInNest => nestEgg != null;
  bool get eggPityActive => eggStash.isEmpty && !hasEggInNest;

  double eggDropChance(ChestTier tier) {
    final baseChance = switch (tier) {
      ChestTier.wooden => 0.01,
      ChestTier.silver => 0.04,
      ChestTier.gold => 0.12,
      ChestTier.dragon || ChestTier.mythical || ChestTier.sinister => 1.0,
      ChestTier.special ||
      ChestTier.portrait ||
      ChestTier.title ||
      ChestTier.music =>
        0.0,
    };
    final pityEligible = tier == ChestTier.wooden ||
        tier == ChestTier.silver ||
        tier == ChestTier.gold;
    return eggPityActive && pityEligible ? baseChance * 3 : baseChance;
  }

  double sinisterEggDropChance(ChestTier tier) =>
      tier == ChestTier.sinister ? .5 : 0;

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
    const supported = {'en', 'nl', 'de', 'fr', 'es', 'pt', 'it', 'ja'};
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

  bool get canStartTutorial =>
      !pet.isEgg &&
      pet.name.trim().isNotEmpty &&
      unlockedAchievementIds.contains('hello_little_one');

  bool get shouldStartTutorial => !tutorialCompleted && canStartTutorial;

  Future<void> completeTutorial({bool fullyViewed = false}) async {
    var changed = false;
    if (!tutorialCompleted) {
      tutorialCompleted = true;
      changed = true;
    }
    if (fullyViewed && !tutorialFullyViewed) {
      tutorialFullyViewed = true;
      changed = _evaluateAchievements() || changed;
    }
    if (!changed) return;
    await _notifyAndSave();
  }

  Future<ChestReward?> openChest(ChestTier tier) =>
      _openChest(tier, persist: true);

  Future<ChestRewardBundle?> openChests(
    ChestTier tier, {
    required int count,
  }) async {
    if (count <= 0 || openableChestCount(tier) < count) return null;
    final rewards = <ChestReward>[];
    for (var index = 0; index < count; index++) {
      final reward = await _openChest(tier, persist: false);
      if (reward == null) return null;
      rewards.add(reward);
    }
    if (tier == ChestTier.music) await _syncJukeboxAudio();
    await _notifyAndSave();
    return ChestRewardBundle(tier: tier, rewards: rewards);
  }

  Future<ChestReward?> _openChest(
    ChestTier tier, {
    required bool persist,
  }) async {
    if (tradeableChestCount(tier) <= 0) return null;
    if (tier == ChestTier.portrait) {
      return _openPortraitChest(persist: persist);
    }
    if (tier == ChestTier.title) return _openTitleChest(persist: persist);
    if (tier == ChestTier.music) return _openMusicChest(persist: persist);
    if (tier == ChestTier.special) return _openSpecialChest(persist: persist);
    chestInventory[tier] = chestCount(tier) - 1;
    final coins = switch (tier) {
      ChestTier.wooden => 20 + _random.nextInt(21),
      ChestTier.silver => 45 + _random.nextInt(36),
      ChestTier.gold => 90 + _random.nextInt(71),
      ChestTier.dragon => 180 + _random.nextInt(121),
      ChestTier.mythical || ChestTier.sinister => 400 + _random.nextInt(251),
      ChestTier.special => 269,
      ChestTier.portrait || ChestTier.title || ChestTier.music => 0,
    };
    final gems = switch (tier) {
      ChestTier.wooden => 0,
      ChestTier.silver =>
        _random.nextDouble() < .50 ? 1 + _random.nextInt(2) : 0,
      ChestTier.gold => _random.nextDouble() < .72 ? 2 + _random.nextInt(3) : 0,
      ChestTier.dragon =>
        _random.nextDouble() < .9 ? 4 + _random.nextInt(4) : 0,
      ChestTier.mythical || ChestTier.sinister => 8 + _random.nextInt(6),
      ChestTier.special => 10,
      ChestTier.portrait || ChestTier.title || ChestTier.music => 0,
    };
    final eggChance = eggDropChance(tier);
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
      _grantRelic(relicFound);
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
    if (persist) await _notifyAndSave();
    return ChestReward(
        tier: tier,
        coins: coins,
        gems: gems,
        eggFound: eggFound,
        sinisterEgg: foundEgg?.sinister ?? false,
        relicFound: relicFound);
  }

  Future<ChestReward?> _openSpecialChest({required bool persist}) async {
    chestInventory[ChestTier.special] = chestCount(ChestTier.special) - 1;
    eggStash.add(_createSpecialEgg());
    pet.coins += 269;
    pet.gems += 10;
    totalChestsOpened++;
    _addActivity(
      message: 'A Special Chest revealed a one-of-a-kind egg.',
      type: ActivityType.discovery,
      code: ActivityCode.chestOpened,
      subject: ChestTier.special.name,
      coins: 269,
      gems: 10,
    );
    _evaluateAchievements();
    if (persist) await _notifyAndSave();
    return const ChestReward(
      tier: ChestTier.special,
      coins: 269,
      gems: 10,
      eggFound: true,
      specialEgg: true,
    );
  }

  Future<ChestReward?> _openPortraitChest({required bool persist}) async {
    final remaining = profilePortraitCatalog
        .where((portrait) => !ownedPortraitIds.contains(portrait.id))
        .toList(growable: false);
    if (remaining.isEmpty) return null;
    final portrait = remaining[_random.nextInt(remaining.length)];
    chestInventory[ChestTier.portrait] = chestCount(ChestTier.portrait) - 1;
    ownedPortraitIds.add(portrait.id);
    totalChestsOpened++;
    totalPortraitChestsOpened++;
    _addActivity(
      message: 'A new account portrait was revealed.',
      type: ActivityType.discovery,
      code: ActivityCode.portraitRevealed,
      subject: ChestTier.portrait.name,
    );
    _evaluateAchievements();
    if (persist) await _notifyAndSave();
    return ChestReward(
      tier: ChestTier.portrait,
      coins: 0,
      gems: 0,
      eggFound: false,
      portraitFound: portrait,
    );
  }

  Future<ChestReward?> _openTitleChest({required bool persist}) async {
    final remaining = accountTitleCatalog
        .where((title) => !ownedTitleIds.contains(title.id))
        .toList(growable: false);
    if (remaining.isEmpty) return null;
    final title = remaining[_random.nextInt(remaining.length)];
    chestInventory[ChestTier.title] = chestCount(ChestTier.title) - 1;
    ownedTitleIds.add(title.id);
    totalChestsOpened++;
    totalTitleChestsOpened++;
    _addActivity(
      message: 'A new account title was revealed.',
      type: ActivityType.discovery,
      code: ActivityCode.titleRevealed,
      subject: ChestTier.title.name,
    );
    _evaluateAchievements();
    if (persist) await _notifyAndSave();
    return ChestReward(
      tier: ChestTier.title,
      coins: 0,
      gems: 0,
      eggFound: false,
      titleFound: title,
    );
  }

  Future<ChestReward?> _openMusicChest({required bool persist}) async {
    final remaining = musicCatalog
        .where((track) => !ownedMusicTrackIds.contains(track.id))
        .toList(growable: false);
    if (remaining.isEmpty) return null;
    final track = remaining[_random.nextInt(remaining.length)];
    chestInventory[ChestTier.music] = chestCount(ChestTier.music) - 1;
    ownedMusicTrackIds.add(track.id);
    enabledMusicTrackIds.add(track.id);
    totalChestsOpened++;
    totalMusicChestsOpened++;
    _addActivity(
      message: '${track.title} was added to the Jukebox.',
      type: ActivityType.discovery,
      code: ActivityCode.bonusFound,
      subject: track.id,
    );
    if (persist) {
      await _syncJukeboxAudio();
      await _notifyAndSave();
    }
    return ChestReward(
      tier: ChestTier.music,
      coins: 0,
      gems: 0,
      eggFound: false,
      musicTrackFound: track,
    );
  }

  double relicDropChance(ChestTier tier) => switch (tier) {
        ChestTier.wooden || ChestTier.silver => 0.0,
        ChestTier.gold => .01,
        ChestTier.dragon => .02,
        ChestTier.mythical => .04,
        ChestTier.sinister => 1.0,
        ChestTier.special ||
        ChestTier.portrait ||
        ChestTier.title ||
        ChestTier.music =>
          0.0,
      };

  MysticRelic? _rollRelicDrop(ChestTier tier) {
    final chance = relicDropChance(tier);
    if (_random.nextDouble() >= chance) return null;
    final eligible = MysticRelic.values
        .where(
          (relic) =>
              relic != MysticRelic.twinstarBrooch ||
              !twinstarBroochEverObtained,
        )
        .toList(growable: false);
    return eligible[_random.nextInt(eligible.length)];
  }

  bool accelerateStarterEgg() {
    final egg = nestEgg;
    if (egg == null || !egg.isEgg || !egg.firstEgg) return false;
    final now = _clock();
    final hatchAt = egg.stageStartedAt.add(egg.incubationDuration);
    final earliestHatchAt = now.add(const Duration(seconds: 1));
    if (!hatchAt.isAfter(earliestHatchAt)) return false;
    final acceleratedHatchAt = hatchAt.subtract(const Duration(seconds: 1));
    final nextHatchAt = acceleratedHatchAt.isBefore(earliestHatchAt)
        ? earliestHatchAt
        : acceleratedHatchAt;
    egg.stageStartedAt = nextHatchAt.subtract(egg.incubationDuration);
    _localMutationRevision++;
    notifyListeners();

    // A player may tap hundreds of times in quick succession. Persist and
    // replace the ready notification once after that burst, rather than doing
    // a full encrypted save and platform notification call for every tap.
    _starterEggTapPersistenceTimer?.cancel();
    _starterEggTapPersistenceTimer = Timer(
      const Duration(milliseconds: 300),
      () {
        unawaited(_save());
        final currentEgg = nestEgg;
        if (onboardingComplete && currentEgg?.isEgg == true) {
          unawaited(_scheduleEggReadyNotification(currentEgg!));
        }
      },
    );
    return true;
  }

  Future<bool> hatchActiveDragon() async {
    final now = _clock();
    final egg = nestEgg;
    if (egg == null || !egg.canHatch(now)) return false;
    final dragonId = egg.id;
    final acquiredAt = egg.acquiredAt;
    _starterEggTapPersistenceTimer?.cancel();
    _starterEggTapPersistenceTimer = null;
    unawaited(HavenNotifications.cancel('egg-${egg.id}'));
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
    _performEvolution(dragon, now);
    _evaluateAchievements();
    await _notifyAndSave();
    return true;
  }

  bool _evolveReadyDragons(DateTime now) {
    final dragons = ownedDragons.toList()
      ..sort((a, b) {
        final acquired = a.acquiredAt.compareTo(b.acquiredAt);
        return acquired != 0 ? acquired : a.id.compareTo(b.id);
      });
    var changed = false;
    var queueOrder = 0;
    for (final dragon in dragons) {
      while (dragon.canEvolve(now)) {
        _performEvolution(dragon, now, queueOrder: queueOrder++);
        changed = true;
      }
    }
    return changed;
  }

  void _performEvolution(
    Pet dragon,
    DateTime now, {
    int queueOrder = 0,
  }) {
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
      createdAt: now.add(Duration(microseconds: queueOrder)),
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
  }

  Future<bool> buyStarlightTreat() async {
    if (pet.gems < 3 || pet.isEgg) return false;
    pet.gems -= 3;
    _grantDragonXp(pet, 25);
    pet.joy = min(100, pet.joy + 12);
    pet.energy = min(100, pet.energy + 12);
    pet.comfort = min(100, pet.comfort + 12);
    _evolveReadyDragons(_clock());
    _evaluateAchievements();
    await _notifyAndSave();
    return true;
  }

  Future<bool> activateEgg(String eggId) async {
    if (isEggReservedForTrade(eggId)) return false;
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
    final eggName = strings.eggName(
      sinister: egg.isSinisterEgg,
      special: egg.isSpecialEgg,
    );
    await HavenNotifications.eggReady(
      id: 'egg-${egg.id}',
      at: egg.stageStartedAt.add(egg.incubationDuration),
      title: strings.pick('Your $eggName is ready', 'Je $eggName is klaar'),
      body: strings.pick(
        'Something inside wants to hatch in the Rooftop Nest.',
        'Iets binnenin wil uitkomen in het Daknest.',
      ),
    );
  }

  int achievementProgress(String id) => switch (id) {
        'hello_little_one' => totalHatched,
        'guided_tour' => tutorialFullyViewed ? 1 : 0,
        'first_flight' => totalShortAdventuresCompleted,
        'chest_expectations' => totalChestsOpened,
        'profile_picture_perfect' => totalPortraitChestsOpened,
        'highly_titled' => totalTitleChestsOpened,
        'room_to_roost' ||
        'halfway_clouds' ||
        'sky_ceiling' =>
          towerFloorRoomIds.length,
        'feed_furniture' => housePlacements.length,
        'book_wyrm' || 'well_read_scaled' => discoveredCommonLineageCount,
        'scale_every_tale' => discoveredLineageCount,
        'growing_pains' => totalWyrmling,
        'not_picking_favorites' => favoriteChanges,
        'ascension_day' => totalAscended,
        'something_spectral' => prismaticForms.isEmpty ? 0 : 1,
        'frequent_flyer' || 'are_we_there_yet' => totalAdventuresCompleted,
        'full_party' => totalGroupFourCompleted,
        'triple_expertise' =>
          [pet, ...sanctuaryDragons].any((dragon) => TrainingFocus.values.every(
                    (focus) => dragon.trainingFor(focus) >= maxDragonExpertise,
                  ))
              ? 1
              : 0,
        'hidden_mastery' =>
          [pet, ...sanctuaryDragons].any((dragon) => dragon.isMastery) ? 1 : 0,
        'came_crawling_back' => totalReleasedReturns,
        'ghost_writer' =>
          prismaticForms.map((key) => key.split(':').first).toSet().length,
        'myth_made_real' => [pet, ...sanctuaryDragons]
                .any((dragon) => dragon.lineage.rarity == DragonRarity.mythical)
            ? 1
            : 0,
        'trial_might_s_plus' => trialGradeForScore(TrialKind.ruinBreaker,
                    accountTrialBest(TrialKind.ruinBreaker)) ==
                TrialGrade.sPlus
            ? 1
            : 0,
        'trial_spirit_s_plus' => trialGradeForScore(TrialKind.cavernFlight,
                    accountTrialBest(TrialKind.cavernFlight)) ==
                TrialGrade.sPlus
            ? 1
            : 0,
        'trial_arcana_s_plus' => trialGradeForScore(TrialKind.runeweaver,
                    accountTrialBest(TrialKind.runeweaver)) ==
                TrialGrade.sPlus
            ? 1
            : 0,
        'probably_fine' => totalSinisterAdventuresCompleted,
        'winner_chicken_dinner' =>
          discoveredForms.contains('cluckatrice:hatchling') ? 1 : 0,
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
    _addActivity(
        message: '${item.name} was purchased and stored in Inventory.',
        type: ActivityType.purchase,
        code: ActivityCode.itemPurchased,
        subject: item.id,
        coins: item.currency == ItemCurrency.coins ? -item.price : 0,
        gems: item.currency == ItemCurrency.gems ? -item.price : 0);
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
    final specialNotificationsChanged =
        await refreshSpecialAdventureNotifications();
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
    final trialsBefore = [
      ...trialOffers.map((offer) => '${offer.id}:${offer.kind.name}'),
      trialRefilledAt?.toIso8601String() ?? '',
    ].join('|');
    adventuresFor(AdventureKind.mini);
    adventuresFor(AdventureKind.short);
    adventuresFor(AdventureKind.long);
    availableTrials;
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
    final trialsAfter = [
      ...trialOffers.map((offer) => '${offer.id}:${offer.kind.name}'),
      trialRefilledAt?.toIso8601String() ?? '',
    ].join('|');
    final roamingAssignmentsChanged = _normalizeRoamingState();
    final changed = specialNotificationsChanged |
        (adventureOptionsBefore != adventureOptionsAfter) |
        (trialsBefore != trialsAfter) |
        pet.applyTimeDecay(_clock()) |
        _registerCurrentStage() |
        _evolveReadyDragons(_clock()) |
        _refreshAdventureRuns() |
        _expireReturningVisitors() |
        _processDailyReturningDragon() |
        roamingAssignmentsChanged |
        roamIdleDragons();
    final achievementsChanged = _evaluateAchievements();
    if (changed || achievementsChanged) await _notifyAndSave();
  }

  DragonEgg _createEgg({required ChestTier sourceTier}) {
    final seed = _random.nextInt(0x7fffffff);
    if (sourceTier == ChestTier.sinister &&
        _random.nextDouble() < sinisterEggDropChance(sourceTier)) {
      return DragonEgg(
        id: _uuid.v4(),
        lineageId: 'sinisterra',
        acquiredAt: _clock(),
        hatchSeed: seed,
        prismatic: _random.nextInt(20) == 0,
        lawAxis: LawAxis.values[_random.nextInt(LawAxis.values.length)],
        moralAxis: MoralAxis.evil,
        sizeFactor: _dragonSizeFromRoll(_random.nextDouble()),
        incubationSeconds: const Duration(
          hours: 6,
          minutes: 6,
          seconds: 6,
        ).inSeconds,
        sinister: true,
      );
    }
    final lineage = _rollEggLineage(sourceTier);
    final sizeRoll = _random.nextDouble();
    return DragonEgg(
      id: _uuid.v4(),
      lineageId: lineage.id,
      acquiredAt: _clock(),
      hatchSeed: seed,
      prismatic: _random.nextInt(20) == 0,
      lawAxis: LawAxis.values[_random.nextInt(LawAxis.values.length)],
      moralAxis: MoralAxis.values[_random.nextInt(MoralAxis.values.length)],
      sizeFactor: _dragonSizeFromRoll(sizeRoll),
      incubationMinutes: (48 + _random.nextInt(289)) * 6,
      sinister: false,
    );
  }

  DragonEgg _createSpecialEgg() => DragonEgg(
        id: _uuid.v4(),
        lineageId: 'cluckatrice',
        acquiredAt: _clock(),
        hatchSeed: _random.nextInt(0x7fffffff),
        prismatic: false,
        lawAxis: LawAxis.values[_random.nextInt(LawAxis.values.length)],
        moralAxis: MoralAxis.values[_random.nextInt(MoralAxis.values.length)],
        sizeFactor: _dragonSizeFromRoll(_random.nextDouble()),
        incubationMinutes: 21 * 60,
      );

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
      ChestTier.special ||
      ChestTier.portrait ||
      ChestTier.title ||
      ChestTier.music =>
        const [.75, .95, .995, .9995, .99999],
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
    final candidates = standardDragonLineages
        .where((lineage) => lineage.rarity == rarity)
        .toList();
    return candidates[_random.nextInt(candidates.length)];
  }

  bool _registerCurrentStage() => _registerDragonStage(pet);

  bool _registerOwnedDragonStages() {
    var changed = false;
    for (final dragon in [pet, ...sanctuaryDragons]) {
      changed = _registerDragonStage(dragon) || changed;
    }
    return changed;
  }

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
    _localMutationRevision++;
    notifyListeners();
    await _save();
  }

  Map<String, dynamic> exportState() => <String, dynamic>{
        'schemaVersion': _schemaVersion,
        'languageCode': languageCode,
        'accountName': accountName,
        'onboardingComplete': onboardingComplete,
        'musicEnabled': musicEnabled,
        'musicStyle': musicStyle.name,
        'ownedMusicTrackIds': ownedMusicTrackIds.toList(),
        'enabledMusicTrackIds': enabledMusicTrackIds.toList(),
        'jukeboxShuffle': jukeboxShuffle,
        'jukeboxRepeat': jukeboxRepeat,
        'soundEffectsEnabled': soundEffectsEnabled,
        'enabledNotificationCategories': enabledNotificationCategories
            .map((category) => category.name)
            .toList(),
        'notificationSettingsVersion': 2,
        'achievementsCompact': achievementsCompact,
        'tutorialCompleted': tutorialCompleted,
        'tutorialFullyViewed': tutorialFullyViewed,
        'pet': pet.toJson(),
        'incubatingEgg': incubatingEgg?.toJson(),
        'eggStash': eggStash.map((egg) => egg.toJson()).toList(),
        'sanctuaryDragons':
            sanctuaryDragons.map((dragon) => dragon.toJson()).toList(),
        'chestInventory': {
          for (final entry in chestInventory.entries)
            entry.key.name: entry.value
        },
        'relicInventory': {
          for (final entry in relicInventory.entries)
            entry.key.name: entry.value
        },
        'untradeableRelicInventory': {
          for (final entry in untradeableRelicInventory.entries)
            entry.key.name: entry.value
        },
        'chronoshardReductions': chronoshardReductions,
        'eggRarityRevealedIds': eggRarityRevealedIds.toList(),
        'twinstarBroochEverObtained': twinstarBroochEverObtained,
        'twinstarBroochDragonId': twinstarBroochDragonId,
        'ownedPortraitIds': ownedPortraitIds.toList(),
        'selectedPortraitId': selectedPortraitId,
        'ownedTitleIds': ownedTitleIds.toList(),
        'selectedTitleId': selectedTitleId,
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
        'totalPortraitChestsOpened': totalPortraitChestsOpened,
        'totalTitleChestsOpened': totalTitleChestsOpened,
        'totalMusicChestsOpened': totalMusicChestsOpened,
        'totalAdventuresCompleted': totalAdventuresCompleted,
        'totalShortAdventuresCompleted': totalShortAdventuresCompleted,
        'totalGroupFourCompleted': totalGroupFourCompleted,
        'totalReleasedReturns': totalReleasedReturns,
        'totalSinisterAdventuresCompleted': totalSinisterAdventuresCompleted,
        'favoriteChanges': favoriteChanges,
        'adventureRuns': adventureRuns.map((run) => run.toJson()).toList(),
        'trialOffers': trialOffers.map((offer) => offer.toJson()).toList(),
        'trialRefilledAt': trialRefilledAt?.toIso8601String(),
        'appliedOnlineGroupRewardIds': appliedOnlineGroupRewardIds.toList(),
        'appliedOnlineTradeIds': appliedOnlineTradeIds.toList(),
        'reservedOnlineTradeEggIds': reservedOnlineTradeEggIds.toList(),
        'reservedOnlineTradeChests': reservedOnlineTradeChests,
        'reservedOnlineTradeRelics': reservedOnlineTradeRelics,
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
        'lastReturningDayKey': lastReturningDayKey,
        'scheduledReturningAt': scheduledReturningAt?.toIso8601String(),
        'latestReturningEvent': latestReturningEvent,
        'returningSpecialAdventureId': returningSpecialAdventureId,
        'returningSpecialAvailableUntil':
            returningSpecialAvailableUntil?.toIso8601String(),
        'startedSeasonalSpecialEventKeys':
            startedSeasonalSpecialEventKeys.toList(),
        'notifiedSeasonalSpecialEventKeys':
            notifiedSeasonalSpecialEventKeys.toList(),
        'ownedItemIds': ownedItemIds.toList(),
        'equippedItemIds': {
          for (final entry in equippedItemIds.entries)
            entry.key.name: entry.value
        },
        'unlockedRoomIds': unlockedRoomIds.toList(),
        'activeRoomId': activeRoomId,
        'housePlacements':
            housePlacements.map((placement) => placement.toJson()).toList(),
        'activities': activities.map((entry) => entry.toJson()).toList(),
      };

  Future<bool> restoreCloudState(Map<String, dynamic> state) async {
    final candidate = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
    );
    try {
      await _restoreStoredState(candidate, state);
      _restore(state);
      _evolveReadyDragons(_clock());
      pet.applyTimeDecay(_clock());
      _registerOwnedDragonStages();
      _evaluateAchievements(addActivities: false);
      await _save();
      await _rescheduleNestEggNotification();
      await _syncJukeboxAudio();
      await HavenAudio.applyPreferences(
        musicEnabled: musicEnabled,
        soundEffectsEnabled: soundEffectsEnabled,
        musicStyle: musicStyle,
      );
      notifyListeners();
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _save() {
    if (!_persistenceEnabled) return Future<void>.value();
    final state = exportState();
    final operation = _saveQueue.then((_) => StorageService.save(state),
        onError: (_) => StorageService.save(state));
    _saveQueue = operation;
    return operation;
  }

  @override
  void dispose() {
    _starterEggTapPersistenceTimer?.cancel();
    super.dispose();
  }

  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
