import 'dart:convert';
import 'dart:math';

import 'package:dragon_haven/models/achievement.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/dragon_egg.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/house.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/shop_item.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a fresh game starts in English with one fixed mysterious egg', () {
    final game = HouseholdProvider(random: Random(37));
    final identity = game.pet.lineageId;

    expect(game.languageCode, 'en');
    expect(game.pet.stage, DragonStage.egg);
    expect(game.pet.firstEgg, isTrue);
    expect(game.pet.displayName, 'Mysterious Egg');
    expect(game.pet.lineageId, identity);
    expect(game.pet.lineage.rarity, DragonRarity.common);
    expect(game.pet.incubationMinutes, 60);
    expect(game.onboardingComplete, isFalse);
    expect(game.musicEnabled, isTrue);
    expect(game.soundEffectsEnabled, isTrue);
    expect(game.totalChestCount, 0);
  });

  test('the emulator hatch demo starts with about three minutes remaining', () {
    final game = HouseholdProvider.createHatchDemo();
    final remaining = game.pet.remainingForNextStage(DateTime.now());

    expect(game.accountName, 'Three-Minute Keeper');
    expect(game.onboardingComplete, isTrue);
    expect(game.pet.firstEgg, isTrue);
    expect(game.pet.isEgg, isTrue);
    expect(remaining, greaterThan(const Duration(minutes: 2, seconds: 55)));
    expect(remaining, lessThanOrEqualTo(const Duration(minutes: 3)));
  });

  test('the emulator hatch demo accepts a short countdown for UI checks', () {
    final game = HouseholdProvider.createHatchDemo(
      countdown: const Duration(seconds: 8),
    );
    final remaining = game.pet.remainingForNextStage(DateTime.now());

    expect(remaining, greaterThan(const Duration(seconds: 7)));
    expect(remaining, lessThanOrEqualTo(const Duration(seconds: 8)));
  });

  test('language and hidden egg identity persist after restart', () async {
    final game = HouseholdProvider(random: Random(11));
    final lineage = game.pet.lineageId;
    final seed = game.pet.hatchSeed;
    await game.setLanguage('nl');

    final restored = await HouseholdProvider.loadFromStorage();
    expect(restored.languageCode, 'nl');
    expect(restored.pet.lineageId, lineage);
    expect(restored.pet.hatchSeed, seed);
  });

  test('music and sound effects persist independently', () async {
    final game = HouseholdProvider(random: Random(19));
    await game.setMusicEnabled(false);

    var restored = await HouseholdProvider.loadFromStorage();
    expect(restored.musicEnabled, isFalse);
    expect(restored.soundEffectsEnabled, isTrue);

    await restored.setMusicEnabled(true);
    await restored.setSoundEffectsEnabled(false);
    restored = await HouseholdProvider.loadFromStorage();
    expect(restored.musicEnabled, isTrue);
    expect(restored.soundEffectsEnabled, isFalse);
  });

  test('the preferred achievement view persists', () async {
    final game = HouseholdProvider(random: Random(29));
    expect(game.achievementsCompact, isFalse);
    await game.setAchievementsCompact(true);

    final restored = await HouseholdProvider.loadFromStorage();
    expect(restored.achievementsCompact, isTrue);
  });

  test('dismissed Short Adventures refill one slot after a full hour',
      () async {
    var now = DateTime(2026, 8, 21, 10, 15);
    final game = HouseholdProvider(random: Random(12), clock: () => now);
    final initial = game.adventuresFor(AdventureKind.short);
    expect(initial, hasLength(3));

    await game.dismissAdventure(initial.first);
    expect(game.adventuresFor(AdventureKind.short), hasLength(2));
    now = now.add(const Duration(minutes: 59));
    expect(game.adventuresFor(AdventureKind.short), hasLength(2));
    now = now.add(const Duration(minutes: 1));
    expect(game.adventuresFor(AdventureKind.short), hasLength(3));
  });

  test('dismissed Long Adventures stay gone until the next local day',
      () async {
    var now = DateTime(2026, 8, 21, 10, 15);
    final game = HouseholdProvider(random: Random(112), clock: () => now);
    final initial = game.adventuresFor(AdventureKind.long);
    expect(initial, hasLength(3));

    await game.dismissAdventure(initial.first);
    expect(game.adventuresFor(AdventureKind.long), hasLength(2));
    now = DateTime(2026, 8, 21, 23, 59);
    expect(game.adventuresFor(AdventureKind.long), hasLength(2));
    now = DateTime(2026, 8, 22);
    expect(game.adventuresFor(AdventureKind.long), hasLength(3));
  });

  test('dismissed Mini Adventure slots refill every fifteen minutes', () async {
    var now = DateTime(2026, 8, 21, 10, 15);
    final game = HouseholdProvider(random: Random(120), clock: () => now);
    final initial = game.adventuresFor(AdventureKind.mini);
    expect(initial, hasLength(3));
    expect(
        initial.every((item) => item.knownChest == ChestTier.wooden), isTrue);

    await game.dismissAdventure(initial.first);
    now = now.add(const Duration(minutes: 14));
    expect(game.adventuresFor(AdventureKind.mini), hasLength(2));
    now = now.add(const Duration(minutes: 1));
    expect(game.adventuresFor(AdventureKind.mini), hasLength(3));
  });

  test('legacy egg incubation hours migrate to one tenth immediately', () {
    final stageStart = DateTime.utc(2026, 8, 20, 10);
    final laterEgg = Pet.fromJson({
      'id': 'legacy-active-egg',
      'stage': 'egg',
      'firstEgg': false,
      'stageStartedAt': stageStart.toIso8601String(),
      'incubationHours': 168,
      'hatchSeed': 71,
    });
    final stashedEgg = DragonEgg.fromJson({
      'id': 'legacy-stashed-egg',
      'lineageId': dragonLineages.first.id,
      'acquiredAt': stageStart.toIso8601String(),
      'hatchSeed': 72,
      'incubationHours': 48,
    });

    expect(laterEgg.incubationDuration, const Duration(hours: 16, minutes: 48));
    expect(
        stashedEgg.incubationDuration, const Duration(hours: 4, minutes: 48));
    expect(Pet.fromJson(laterEgg.toJson()).incubationMinutes,
        laterEgg.incubationMinutes,
        reason: 'new saves must not be divided a second time');
  });

  test('Special Adventures only appear from an active special source', () {
    final game = HouseholdProvider(random: Random(13));
    expect(game.adventuresFor(AdventureKind.special), isEmpty);
    expect(game.adventuresFor(AdventureKind.group), hasLength(1));
  });

  test('Group Adventure refreshes at Sunday noon Europe/Amsterdam', () {
    var now = DateTime.utc(2026, 8, 23, 9, 59);
    final game = HouseholdProvider(random: Random(23), clock: () => now);
    final beforeSummerRefresh =
        game.adventuresFor(AdventureKind.group).single.id;
    now = DateTime.utc(2026, 8, 23, 10);
    final afterSummerRefresh =
        game.adventuresFor(AdventureKind.group).single.id;
    expect(afterSummerRefresh, isNot(beforeSummerRefresh));

    now = DateTime.utc(2026, 1, 4, 10, 59);
    final beforeWinterRefresh =
        game.adventuresFor(AdventureKind.group).single.id;
    now = DateTime.utc(2026, 1, 4, 11);
    final afterWinterRefresh =
        game.adventuresFor(AdventureKind.group).single.id;
    expect(afterWinterRefresh, isNot(beforeWinterRefresh));
  });

  test('a chest can only be opened when it exists', () async {
    final game = HouseholdProvider(random: Random(3));
    game.chestInventory[ChestTier.wooden] = 1;
    final beforeCoins = game.pet.coins;
    final beforeXp = game.pet.xp;
    final reward = await game.openChest(ChestTier.wooden);

    expect(reward, isNotNull);
    expect(game.pet.coins, beforeCoins + reward!.coins);
    expect(game.pet.xp, beforeXp,
        reason: 'Adventure XP must never be part of a chest.');
    expect(game.totalChestsOpened, 1);
    expect(game.chestCount(ChestTier.wooden), 0);
    expect(await game.openChest(ChestTier.wooden), isNull);
  });

  test('mystic relics only drop from Gold Chests and rarer tiers', () async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: _ZeroRandom(),
    )..pet = Pet(stage: DragonStage.hatchling, firstEgg: false);

    for (final tier in const [ChestTier.wooden, ChestTier.silver]) {
      game.chestInventory[tier] = 1;
      final reward = await game.openChest(tier);
      expect(reward?.relicFound, isNull, reason: tier.name);
    }
    for (final tier in const [
      ChestTier.gold,
      ChestTier.dragon,
      ChestTier.mythical,
      ChestTier.sinister,
    ]) {
      game.chestInventory[tier] = 1;
      final reward = await game.openChest(tier);
      expect(reward?.relicFound, MysticRelic.moralPrism, reason: tier.name);
    }
    expect(game.relicCount(MysticRelic.moralPrism), 4);
  });

  test('using each relic reveals only its secret and persists it', () async {
    final game = HouseholdProvider(random: Random(203));
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Nova';
    game.relicInventory = {
      for (final relic in MysticRelic.values) relic: 1,
    };

    expect(
      await game.useRelic(MysticRelic.moralPrism, game.pet.id),
      MysticRelicUseResult.revealed,
    );
    expect(game.pet.moralAxisKnown, isTrue);
    expect(game.pet.lawAxisKnown, isFalse);
    expect(game.pet.personalityKnown, isFalse);
    expect(game.relicCount(MysticRelic.moralPrism), 0);
    expect(
      await game.useRelic(MysticRelic.orderCompass, game.pet.id),
      MysticRelicUseResult.revealed,
    );
    expect(
      await game.useRelic(MysticRelic.soulMirror, game.pet.id),
      MysticRelicUseResult.revealed,
    );
    expect(game.pet.personalityTraitIds, isNotEmpty);

    final restored = await HouseholdProvider.loadFromStorage();
    expect(restored.pet.moralAxisKnown, isTrue);
    expect(restored.pet.lawAxisKnown, isTrue);
    expect(restored.pet.personalityKnown, isTrue);
    expect(restored.pet.personalityTraitIds, game.pet.personalityTraitIds);
    expect(restored.totalRelicCount, 0);
  });

  test('dragon levels expose the exact next evolution milestone', () {
    final hatchling = Pet(
      stage: DragonStage.hatchling,
      firstEgg: false,
      xp: 599,
    );
    expect(hatchling.level, 3);
    expect(hatchling.nextEvolutionXp, Pet.wyrmlingXp);
    expect(hatchling.nextEvolutionLevel, 3);
    expect(hatchling.nextEvolutionStage, DragonStage.wyrmling);

    final wyrmling = Pet(
      stage: DragonStage.wyrmling,
      firstEgg: false,
      xp: 2199,
    );
    expect(wyrmling.level, 7);
    expect(wyrmling.nextEvolutionXp, Pet.ascendedXp);
    expect(wyrmling.nextEvolutionLevel, 7);
    expect(wyrmling.nextEvolutionStage, DragonStage.ascended);
  });

  test('a later egg incubates beside the active dragon until it hatches',
      () async {
    var now = DateTime.utc(2026, 7, 2);
    final game = HouseholdProvider(random: Random(4), clock: () => now);
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Nimbus'
      ..coins = 444
      ..gems = 19;
    final egg = DragonEgg(
      id: 'later-egg',
      lineageId: 'quietstar',
      acquiredAt: DateTime.utc(2026, 7, 1),
      hatchSeed: 88,
      prismatic: true,
    );
    game.eggStash.add(egg);

    expect(await game.activateEgg(egg.id), isTrue);
    expect(game.sanctuaryDragons, isEmpty);
    expect(game.pet.name, 'Nimbus');
    expect(game.pet.coins, 444);
    expect(game.pet.gems, 19);
    expect(game.incubatingEgg?.id, 'later-egg');
    expect(game.incubatingEgg?.lineageId, 'quietstar');
    expect(game.incubatingEgg?.prismatic, isTrue);
    expect(game.incubatingEgg?.firstEgg, isFalse);
    expect(game.incubatingEgg?.coins, 0);
    expect(game.incubatingEgg?.gems, 0);
    expect(await game.activateEgg(egg.id), isFalse);

    final restored = await HouseholdProvider.loadFromStorage();
    expect(restored.pet.name, 'Nimbus');
    expect(restored.incubatingEgg?.id, 'later-egg');
    expect(restored.eggStash, isEmpty);

    now = now.add(const Duration(days: 7));
    expect(await game.hatchActiveDragon(), isTrue);
    expect(game.incubatingEgg, isNull);
    expect(game.pet.id, 'later-egg');
    expect(game.pet.stage, DragonStage.hatchling);
    expect(game.pet.coins, 444);
    expect(game.pet.gems, 19);
    expect(game.sanctuaryDragons.single.name, 'Nimbus');
  });

  test('the achievement catalog has twenty unique humorous milestones', () {
    expect(achievementCatalog, hasLength(20));
    expect(achievementCatalog.map((entry) => entry.id).toSet(), hasLength(20));
    expect(achievementCatalog.every((entry) => entry.target > 0), isTrue);
    expect(
        achievementCatalog.every((entry) =>
            entry.titleEn.isNotEmpty &&
            entry.titleNl.isNotEmpty &&
            entry.descriptionEn.isNotEmpty &&
            entry.descriptionNl.isNotEmpty),
        isTrue);
  });

  test('Common-family achievements do not count rarer discoveries', () {
    final game = HouseholdProvider(random: Random(41));
    final common = dragonLineages
        .firstWhere((lineage) => lineage.rarity == DragonRarity.common);
    final rare = dragonLineages
        .firstWhere((lineage) => lineage.rarity == DragonRarity.rare);
    game.discoveredForms = {
      '${common.id}:hatchling',
      '${rare.id}:hatchling',
    };

    expect(game.discoveredLineageCount, 2);
    expect(game.achievementProgress('book_wyrm'), 1);
    expect(game.achievementProgress('well_read_scaled'), 1);
    expect(game.achievementProgress('scale_every_tale'), 2);
  });

  test('rooms and furniture use coins and persist valid placement', () async {
    final game = HouseholdProvider(random: Random(5));
    game.pet
      ..xp = 5000
      ..coins = 5000;
    final room = houseRoomCatalog[2];
    expect(await game.unlockRoom(room), RoomUnlockResult.unlocked);
    expect(game.activeRoomId, room.id);

    final item =
        shopCatalog.firstWhere((item) => item.id == 'decor_aurora_orb');
    expect(await game.purchaseOrEquip(item), PurchaseResult.purchased);
    expect(game.owns(item), isTrue);
    expect(game.placementsForRoom(room.id).any((p) => p.itemId == item.id),
        isTrue);
  });

  test('Tower roaming is per dragon, persistent and uses one room at a time',
      () async {
    final game = HouseholdProvider(random: Random(51));
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Nova'
      ..currentRoomId = 'hearth'
      ..currentFloorIndex = 0;
    final older = Pet(
      id: 'older-dragon',
      name: 'Cinder',
      stage: DragonStage.wyrmling,
      firstEgg: false,
      currentRoomId: 'hearth',
      currentFloorIndex: 1,
      acquiredAt: DateTime.utc(2025),
    );
    game.sanctuaryDragons.add(older);
    game.towerFloorRoomIds = ['hearth', 'hearth', 'crystal'];
    game.unlockedRoomIds.addAll(game.towerFloorRoomIds);

    await game.setDragonRoaming(older.id, false);
    expect(older.roamsTower, isFalse);
    expect(game.towerDragons.map((dragon) => dragon.id),
        isNot(contains(older.id)));

    var restored = await HouseholdProvider.loadFromStorage();
    final restoredOlder =
        restored.sanctuaryDragons.firstWhere((dragon) => dragon.id == older.id);
    expect(restoredOlder.roamsTower, isFalse);

    await restored.setDragonRoaming(older.id, true);
    expect(restoredOlder.currentFloorIndex, 1);
    expect(await restored.clearDragonsFromRoom(0), isTrue);
    expect(restored.pet.currentFloorIndex, 2,
        reason: 'Clearing prefers the least occupied available floor.');
    expect(restoredOlder.currentFloorIndex, 1,
        reason: 'The same room type on another floor must not be cleared.');
    expect(await restored.callControllableDragonToRoom('hearth', 0), isTrue);
    expect(restored.pet.currentFloorIndex, 0);
    expect(restored.pet.currentRoomId, 'hearth');
  });

  test('the first dragon is favorite and exactly one favorite always remains',
      () async {
    final now = DateTime.utc(2026, 8, 22, 12);
    final game = HouseholdProvider(random: Random(61), clock: () => now);
    game.pet.stageStartedAt = now.subtract(const Duration(hours: 24));

    expect(await game.hatchActiveDragon(), isTrue);
    expect(game.pet.favorite, isTrue);
    await game.toggleFavorite(game.pet.id);
    expect(game.pet.favorite, isTrue,
        reason: 'The current favorite cannot be switched off directly.');

    final other = Pet(
      id: 'favorite-successor',
      name: 'Cinder',
      stage: DragonStage.hatchling,
      firstEgg: false,
      acquiredAt: now.add(const Duration(minutes: 1)),
    );
    game.sanctuaryDragons.add(other);
    await game.toggleFavorite(other.id);
    expect(game.ownedDragons.where((dragon) => dragon.favorite), [other]);
    expect(await game.releaseDragon(other.id), isFalse,
        reason: 'A favorite dragon can never be released.');
    expect(await game.releaseDragon(game.pet.id), isTrue);
    expect(game.ownedDragons, [other]);
    expect(other.favorite, isTrue);
  });

  test('Tower selection and room occupancy are capped at three per floor',
      () async {
    final game = HouseholdProvider(random: Random(62));
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Nova'
      ..favorite = true;
    game.towerFloorRoomIds = ['hearth', 'crystal'];
    game.unlockedRoomIds.addAll(game.towerFloorRoomIds);
    for (var index = 0; index < 6; index++) {
      game.sanctuaryDragons.add(Pet(
        id: 'roamer-$index',
        name: 'Roamer $index',
        stage: DragonStage.hatchling,
        firstEgg: false,
        acquiredAt: DateTime.utc(2026, 1, index + 1),
      ));
    }
    for (final dragon in game.ownedDragons) {
      dragon.roamsTower = false;
    }

    for (final dragon in game.ownedDragons.take(6)) {
      expect(
        await game.setDragonRoaming(dragon.id, true),
        DragonRoamingResult.updated,
      );
    }
    expect(game.selectedRoamingDragonCount, 6);
    expect(game.towerRoamingCapacity, 6);
    expect(
      await game.setDragonRoaming(game.ownedDragons.last.id, true),
      DragonRoamingResult.towerFull,
    );
    expect(game.ownedDragons.last.roamsTower, isFalse);
    for (var floor = 0; floor < game.towerFloorCount; floor++) {
      expect(
        game.towerDragons
            .where((dragon) => dragon.currentFloorIndex == floor)
            .length,
        lessThanOrEqualTo(3),
      );
    }
  });

  test('new saves contain no task or chore game data', () async {
    final game = HouseholdProvider(random: Random(6));
    await game.setLanguage('nl');
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(StorageService.currentKey);
    expect(raw, isNotNull);
    final data = jsonDecode(raw!) as Map<String, dynamic>;
    expect(data.containsKey('tasks'), isFalse);
    expect(data.containsKey('completedQuestTotal'), isFalse);
    expect(raw.toLowerCase().contains('complete quest'), isFalse);
  });
}

class _ZeroRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}
