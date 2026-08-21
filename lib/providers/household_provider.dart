import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/achievement.dart';
import '../models/adventure.dart';
import '../models/activity_entry.dart';
import '../models/chest.dart';
import '../models/dragon_egg.dart';
import '../models/dragon_lineage.dart';
import '../models/house.dart';
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
  })  : _random = random ?? Random.secure(),
        _clock = clock ?? DateTime.now {
    if (initialize) _initializeFresh();
  }

  final Random _random;
  final DateTime Function() _clock;
  final _uuid = const Uuid();
  Future<void> _saveQueue = Future<void>.value();

  String languageCode = 'en';
  String accountName = '';
  bool onboardingComplete = false;
  bool musicEnabled = true;
  bool soundEffectsEnabled = true;
  bool achievementsCompact = false;
  late Pet pet;
  List<DragonEgg> eggStash = [];
  List<Pet> sanctuaryDragons = [];
  Map<ChestTier, int> chestInventory = {
    for (final tier in ChestTier.values) tier: 0,
  };
  Set<String> discoveredForms = {};
  Set<String> prismaticForms = {};
  Set<String> unlockedAchievementIds = {};
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
  Set<String> dismissedAdventureIds = {};
  Map<AdventureKind, List<String>> adventureOptionIds = {
    AdventureKind.short: <String>[],
    AdventureKind.long: <String>[],
  };
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

  static const _schemaVersion = 23;

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
      provider._evaluateAchievements(addActivities: false);
      if (schemaChanged || changed) await provider._save();
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
    eggStash = mapsFromJson(data['eggStash']).map(DragonEgg.fromJson).toList();
    sanctuaryDragons = mapsFromJson(data['sanctuaryDragons'])
        .map(Pet.fromJson)
        .where((dragon) => !dragon.isEgg)
        .toList();
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
    discoveredForms = stringSetFromJson(data['discoveredForms']);
    prismaticForms = stringSetFromJson(data['prismaticForms']);
    unlockedAchievementIds = stringSetFromJson(data['achievements']);
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
    dismissedAdventureIds = stringSetFromJson(data['dismissedAdventureIds']);
    final rawAdventureOptions = mapFromJson(data['adventureOptionIds']);
    adventureOptionIds = {
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
  }

  int chestCount(ChestTier tier) => chestInventory[tier] ?? 0;
  int get totalChestCount => chestInventory.values.fold(0, (a, b) => a + b);
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
    final xp = switch (tier) {
      ChestTier.wooden => 15,
      ChestTier.silver => 35,
      ChestTier.gold => 80,
      ChestTier.dragon => 150,
      ChestTier.mythical || ChestTier.sinister => 300,
    };
    final eggChance = switch (tier) {
      ChestTier.wooden => 0.01,
      ChestTier.silver => 0.04,
      ChestTier.gold => 0.12,
      ChestTier.dragon || ChestTier.mythical || ChestTier.sinister => 1.0,
    };
    final eggFound = _random.nextDouble() < eggChance;
    DragonEgg? foundEgg;
    pet.coins += coins;
    pet.gems += gems;
    pet.xp += xp;
    totalChestsOpened++;
    if (eggFound) {
      foundEgg = _createEgg(sourceTier: tier);
      eggStash.add(foundEgg);
    }
    _addActivity(
      message: '${tier.name} chest opened.',
      type: ActivityType.discovery,
      code: ActivityCode.chestOpened,
      subject: tier.name,
      xp: xp,
      coins: coins,
      gems: gems,
    );
    _evaluateAchievements();
    await _notifyAndSave();
    return ChestReward(
        tier: tier,
        coins: coins,
        gems: gems,
        xp: xp,
        eggFound: eggFound,
        sinisterEgg: foundEgg?.sinister ?? false);
  }

  Future<bool> hatchActiveDragon() async {
    final now = _clock();
    if (!pet.canHatch(now)) return false;
    pet.hatch(now);
    totalHatched++;
    _registerCurrentStage();
    _addActivity(
        message: 'A ${pet.lineage.nameEn} hatched in a burst of starlight.',
        type: ActivityType.milestone,
        code: ActivityCode.hatched,
        subject: pet.lineageId);
    _evaluateAchievements();
    await _notifyAndSave();
    return true;
  }

  Future<bool> nameActiveDragon(String value) async {
    final name = value.trim();
    if (pet.isEgg || name.isEmpty || name.length > 24) return false;
    final firstName = pet.name.trim().isEmpty;
    pet.name = name;
    if (firstName) totalNamed++;
    _evaluateAchievements();
    await _notifyAndSave();
    return true;
  }

  Future<bool> evolveActiveDragon() async {
    final now = _clock();
    if (!pet.canEvolve(now)) return false;
    pet.evolve(now);
    if (pet.stage == DragonStage.wyrmling) totalWyrmling++;
    if (pet.stage == DragonStage.ascended) totalAscended++;
    _registerCurrentStage();
    _addActivity(
        message: '${pet.displayName} reached the ${pet.stage.name} form.',
        type: ActivityType.milestone,
        code: ActivityCode.evolved,
        subject: pet.lineageId);
    final form = pet.stage == DragonStage.wyrmling ? 'Wyrmling' : 'Ascended';
    unawaited(HavenNotifications.evolutionUnlocked(
      id: 'evolution-${pet.id}-${pet.stage.name}',
      title: languageCode == 'nl' ? 'Nieuwe evolutie!' : 'New evolution!',
      body: languageCode == 'nl'
          ? '${pet.displayName} is geëvolueerd naar $form.'
          : '${pet.displayName} evolved into $form.',
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
    if (index < 0 || pet.isEgg) return false;
    final egg = eggStash.removeAt(index);
    sanctuaryDragons.insert(0, pet);
    final coins = pet.coins;
    final gems = pet.gems;
    pet = egg.activate(coins: coins, gems: gems, activatedAt: _clock());
    await HavenNotifications.schedule(
      id: 'egg-${pet.id}',
      at: pet.stageStartedAt.add(Duration(hours: pet.incubationHours)),
      title: 'Your Mysterious Egg is ready',
      body: 'Something inside wants to hatch in the Rooftop Nest.',
    );
    _evaluateAchievements();
    await _notifyAndSave();
    return true;
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
      ...?adventureOptionIds[AdventureKind.short],
      '#',
      ...?adventureOptionIds[AdventureKind.long],
      shortAdventureRefilledAt?.toIso8601String() ?? '',
      longAdventureRefillDay,
    ].join('|');
    adventuresFor(AdventureKind.short);
    adventuresFor(AdventureKind.long);
    final adventureOptionsAfter = [
      ...?adventureOptionIds[AdventureKind.short],
      '#',
      ...?adventureOptionIds[AdventureKind.long],
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

  bool _registerCurrentStage() {
    if (pet.isEgg) return false;
    final collection = pet.prismatic ? prismaticForms : discoveredForms;
    final forms = <String>['hatchling'];
    if (pet.stage.index >= DragonStage.wyrmling.index) forms.add('wyrmling');
    if (pet.stage == DragonStage.ascended) {
      forms.add('ascended:${pet.activeEvolutionPath}');
    }
    var changed = false;
    for (final form in forms) {
      changed = collection.add('${pet.lineageId}:$form') || changed;
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
      final title =
          languageCode == 'nl' ? achievement.titleNl : achievement.titleEn;
      unawaited(HavenNotifications.achievementUnlocked(
        id: achievement.id,
        title: languageCode == 'nl'
            ? 'Achievement behaald!'
            : 'Achievement unlocked!',
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
    final state = <String, dynamic>{
      'schemaVersion': _schemaVersion,
      'languageCode': languageCode,
      'accountName': accountName,
      'onboardingComplete': onboardingComplete,
      'musicEnabled': musicEnabled,
      'soundEffectsEnabled': soundEffectsEnabled,
      'achievementsCompact': achievementsCompact,
      'pet': pet.toJson(),
      'eggStash': eggStash.map((egg) => egg.toJson()).toList(),
      'sanctuaryDragons':
          sanctuaryDragons.map((dragon) => dragon.toJson()).toList(),
      'chestInventory': {
        for (final entry in chestInventory.entries) entry.key.name: entry.value
      },
      'discoveredForms': discoveredForms.toList(),
      'prismaticForms': prismaticForms.toList(),
      'achievements': unlockedAchievementIds.toList(),
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
      'dismissedAdventureIds': dismissedAdventureIds.toList(),
      'adventureOptionIds': {
        for (final entry in adventureOptionIds.entries)
          entry.key.name: entry.value,
      },
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
