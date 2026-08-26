import 'dart:convert';
import 'dart:math';

import 'package:dragon_haven/models/achievement.dart';
import 'package:dragon_haven/models/account_title.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/dragon_egg.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/game_presentation.dart';
import 'package:dragon_haven/models/house.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/profile_portrait.dart';
import 'package:dragon_haven/models/shop_item.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/storage_service.dart';
import 'package:dragon_haven/services/audio_service.dart';
import 'package:dragon_haven/services/notification_service.dart';
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
    expect(game.musicStyle, HavenMusicStyle.classic);
    expect(game.soundEffectsEnabled, isTrue);
    expect(game.totalChestCount, 0);
    expect(game.portraitCount, 1);
    expect(game.selectedPortrait?.rarity, PortraitRarity.common);
    expect(game.titleCount, 1);
    expect(game.selectedAccountTitle, isNotNull);
  });

  test('release demo exposes portraits, Relics and three roaming dragons', () {
    final game = HouseholdProvider.createReleaseDemo();
    expect(game.onboardingComplete, isTrue);
    expect(game.pet.isEgg, isFalse);
    expect(game.chestCount(ChestTier.portrait), 2);
    expect(game.chestCount(ChestTier.title), 2);
    expect(game.portraitCount, 8);
    expect(game.selectedPortrait, isNotNull);
    expect(game.titleCount, 8);
    expect(game.selectedAccountTitle, isNotNull);
    expect(game.totalRelicCount, 3);
    expect(
      game.ownedDragons.where(
        (dragon) => dragon.roamsTower && dragon.currentFloorIndex == 0,
      ),
      hasLength(3),
    );
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
    await restored.setMusicStyle(HavenMusicStyle.classic);
    await restored.setSoundEffectsEnabled(false);
    restored = await HouseholdProvider.loadFromStorage();
    expect(restored.musicEnabled, isTrue);
    expect(restored.musicStyle, HavenMusicStyle.classic);
    expect(restored.soundEffectsEnabled, isFalse);
  });

  test('retired basic soundtrack preferences migrate to Rêverie', () async {
    SharedPreferences.setMockInitialValues({
      'dragon_haven_state_v1': '{"musicStyle":"basic"}',
    });

    final restored = await HouseholdProvider.loadFromStorage();
    expect(restored.musicStyle, HavenMusicStyle.classic);
  });

  test('notification reasons default on and persist independently', () async {
    final game = HouseholdProvider(random: Random(30));
    expect(
      game.enabledNotificationCategories,
      containsAll(HavenNotificationCategory.values),
    );

    await game.setNotificationEnabled(
      HavenNotificationCategory.tradeReturns,
      false,
    );
    final restored = await HouseholdProvider.loadFromStorage();

    expect(
      restored.notificationEnabled(HavenNotificationCategory.tradeReturns),
      isFalse,
    );
    expect(
      restored.notificationEnabled(HavenNotificationCategory.tradeRequests),
      isTrue,
    );
  });

  test('the preferred achievement view persists', () async {
    final game = HouseholdProvider(random: Random(29));
    expect(game.achievementsCompact, isFalse);
    await game.setAchievementsCompact(true);

    final restored = await HouseholdProvider.loadFromStorage();
    expect(restored.achievementsCompact, isTrue);
  });

  test('dismissed Short Adventures refill on the next whole hour', () async {
    var now = DateTime(2026, 8, 21, 10, 7);
    final game = HouseholdProvider(random: Random(12), clock: () => now);
    final initial = game.adventuresFor(AdventureKind.short);
    expect(initial, hasLength(3));

    await game.dismissAdventure(initial.first);
    expect(game.adventuresFor(AdventureKind.short), hasLength(2));
    now = DateTime(2026, 8, 21, 10, 59, 59);
    expect(game.adventuresFor(AdventureKind.short), hasLength(2));
    now = DateTime(2026, 8, 21, 11);
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
    var now = DateTime(2026, 8, 21, 10, 7);
    final game = HouseholdProvider(random: Random(120), clock: () => now);
    final initial = game.adventuresFor(AdventureKind.mini);
    expect(initial, hasLength(3));
    expect(
        initial.every((item) => item.knownChest == ChestTier.wooden), isTrue);

    await game.dismissAdventure(initial.first);
    now = DateTime(2026, 8, 21, 10, 14, 59);
    expect(game.adventuresFor(AdventureKind.mini), hasLength(2));
    now = DateTime(2026, 8, 21, 10, 15);
    expect(game.adventuresFor(AdventureKind.mini), hasLength(3));
  });

  test('Adventure countdowns follow fixed calendar boundaries', () {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
    );
    final now = DateTime.utc(2026, 8, 23, 9, 7, 8);

    expect(
      game.adventureRefreshRemaining(AdventureKind.mini, from: now),
      const Duration(minutes: 7, seconds: 52),
    );
    expect(
      game.adventureRefreshRemaining(AdventureKind.short, from: now),
      const Duration(minutes: 52, seconds: 52),
    );
    expect(
      game.adventureRefreshRemaining(AdventureKind.long, from: now),
      const Duration(hours: 14, minutes: 52, seconds: 52),
    );
    expect(
      game.adventureRefreshRemaining(AdventureKind.group, from: now),
      const Duration(minutes: 52, seconds: 52),
      reason: 'Sunday noon in Amsterdam is 10:00 UTC during summer time.',
    );
    expect(
      game.adventureRefreshRemaining(AdventureKind.special, from: now),
      isNull,
    );
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

  test('every player sees the same Group Adventure at the same moment', () {
    final now = DateTime.utc(2026, 8, 24, 14, 30);
    final firstPlayer = HouseholdProvider(
      random: Random(1),
      clock: () => now,
    );
    final secondPlayer = HouseholdProvider(
      random: Random(999),
      clock: () => now,
    );

    expect(
      firstPlayer.adventuresFor(AdventureKind.group).single.id,
      secondPlayer.adventuresFor(AdventureKind.group).single.id,
    );
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

  test('egg pity triples common chest odds only while no egg is owned', () {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: Random(303),
    )..pet = Pet(stage: DragonStage.hatchling, firstEgg: false);

    expect(game.eggPityActive, isTrue);
    expect(game.eggDropChance(ChestTier.wooden), .03);
    expect(game.eggDropChance(ChestTier.silver), .12);
    expect(game.eggDropChance(ChestTier.gold), .36);
    expect(game.eggDropChance(ChestTier.dragon), 1);
    expect(game.eggDropChance(ChestTier.mythical), 1);
    expect(game.eggDropChance(ChestTier.sinister), 1);
    expect(game.eggDropChance(ChestTier.portrait), 0);

    game.eggStash.add(DragonEgg(
      id: 'pity-stash-egg',
      lineageId: 'quietstar',
      acquiredAt: DateTime.utc(2026, 8, 23),
      hatchSeed: 17,
      prismatic: false,
    ));
    expect(game.eggPityActive, isFalse);
    expect(game.eggDropChance(ChestTier.wooden), .01);
    expect(game.eggDropChance(ChestTier.silver), .04);
    expect(game.eggDropChance(ChestTier.gold), .12);

    game.eggStash.clear();
    game.incubatingEgg = Pet(
      id: 'pity-nest-egg',
      lineageId: 'quietstar',
      stage: DragonStage.egg,
      firstEgg: false,
      acquiredAt: DateTime.utc(2026, 8, 23),
      hatchSeed: 18,
      prismatic: false,
    );
    expect(game.eggPityActive, isFalse);
    expect(game.eggDropChance(ChestTier.gold), .12);
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
      xp: Pet.wyrmlingXp - 1,
    );
    expect(hatchling.level, 2);
    expect(hatchling.nextEvolutionXp, Pet.wyrmlingXp);
    expect(hatchling.nextEvolutionLevel, 3);
    expect(hatchling.nextEvolutionStage, DragonStage.wyrmling);

    final wyrmling = Pet(
      stage: DragonStage.wyrmling,
      firstEgg: false,
      xp: Pet.ascendedXp - 1,
    );
    expect(wyrmling.level, 6);
    expect(wyrmling.nextEvolutionXp, Pet.ascendedXp);
    expect(wyrmling.nextEvolutionLevel, 7);
    expect(wyrmling.nextEvolutionStage, DragonStage.ascended);
  });

  test('reaching level three starts evolution automatically', () async {
    final now = DateTime.utc(2026, 8, 23, 12);
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      clock: () => now,
    )..pet = Pet(
        id: 'automatic-level-three',
        name: 'Nova',
        stage: DragonStage.hatchling,
        firstEgg: false,
        xp: Pet.wyrmlingXp - 25,
        gems: 3,
        acquiredAt: now.subtract(const Duration(days: 3)),
      );

    expect(await game.buyStarlightTreat(), isTrue);
    expect(game.pet.level, 3);
    expect(game.pet.stage, DragonStage.wyrmling);
    expect(game.nextPresentation?.type, GamePresentationType.evolution);
    expect(game.nextPresentation?.previousStageKey, 'spark');
  });

  test('an existing level-three dragon is repaired on refresh', () async {
    final now = DateTime.utc(2026, 8, 23, 12);
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      clock: () => now,
    )..pet = Pet(
        id: 'existing-level-three',
        stage: DragonStage.hatchling,
        firstEgg: false,
        xp: Pet.wyrmlingXp,
        acquiredAt: now.subtract(const Duration(days: 5)),
      );

    await game.refreshForCurrentDate();
    expect(game.pet.stage, DragonStage.wyrmling);
    expect(game.nextPresentation?.type, GamePresentationType.evolution);
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

  test('the achievement catalog has 29 unique humorous milestones', () {
    expect(achievementCatalog, hasLength(29));
    expect(achievementCatalog.map((entry) => entry.id).toSet(), hasLength(29));
    expect(achievementCatalog.every((entry) => entry.target > 0), isTrue);
    expect(
        achievementCatalog.every((entry) =>
            entry.titleEn.isNotEmpty &&
            entry.titleNl.isNotEmpty &&
            entry.descriptionEn.isNotEmpty &&
            entry.descriptionNl.isNotEmpty),
        isTrue);
  });

  test('the guided tour achievement requires a fully viewed tutorial',
      () async {
    final game = HouseholdProvider(random: Random(48));

    await game.completeTutorial();
    expect(game.tutorialCompleted, isTrue);
    expect(game.tutorialFullyViewed, isFalse);
    expect(game.achievementProgress('guided_tour'), 0);
    expect(game.unlockedAchievementIds, isNot(contains('guided_tour')));

    await game.completeTutorial(fullyViewed: true);
    expect(game.tutorialFullyViewed, isTrue);
    expect(game.achievementProgress('guided_tour'), 1);
    expect(game.unlockedAchievementIds, contains('guided_tour'));
    expect(
      game.pendingPresentations
          .where((event) => event.achievementId == 'guided_tour'),
      hasLength(1),
    );

    await game.completeTutorial(fullyViewed: true);
    expect(
      game.pendingPresentations
          .where((event) => event.achievementId == 'guided_tour'),
      hasLength(1),
    );
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
    expect(game.isEquipped(item), isFalse);
    expect(game.achievementProgress('feed_furniture'), 0);
    expect(
      await game.placeHouseItem(
        item.id,
        roomId: room.id,
        x: .42,
        y: .70,
      ),
      isTrue,
    );
    expect(game.placementsForRoom(room.id).any((p) => p.itemId == item.id),
        isTrue);
    expect(game.achievementProgress('feed_furniture'), 1);
  });

  test('Portrait Chests cost gems and reveal one unowned portrait on open',
      () async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: Random(808),
    )..pet = Pet(stage: DragonStage.hatchling, firstEgg: false, gems: 150);

    expect(await game.purchasePortraitChest(),
        PortraitChestPurchaseResult.purchased);
    expect(game.pet.gems, 51);
    expect(game.chestCount(ChestTier.portrait), 1);
    expect(game.portraitCount, 0);

    final reward = await game.openChest(ChestTier.portrait);
    expect(reward?.portraitFound, isNotNull);
    expect(reward?.coins, 0);
    expect(reward?.gems, 0);
    expect(reward?.eggFound, isFalse);
    expect(game.portraitCount, 1);
    expect(game.selectedPortrait, isNull);
    expect(game.chestCount(ChestTier.portrait), 0);
    expect(game.totalPortraitChestsOpened, 1);
    expect(game.achievementProgress('profile_picture_perfect'), 1);
    expect(game.unlockedAchievementIds, contains('profile_picture_perfect'));

    final portrait = reward!.portraitFound!;
    expect(await game.selectProfilePortrait(portrait.id), isTrue);
    expect(game.selectedPortraitId, portrait.id);
  });

  test('a Portrait Chest remains closed after all portraits are collected',
      () async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
    )
      ..pet = Pet(stage: DragonStage.hatchling, firstEgg: false, gems: 999)
      ..ownedPortraitIds =
          profilePortraitCatalog.map((portrait) => portrait.id).toSet()
      ..chestInventory[ChestTier.portrait] = 1;

    expect(await game.openChest(ChestTier.portrait), isNull);
    expect(game.chestCount(ChestTier.portrait), 1);
    expect(game.totalPortraitChestsOpened, 0);
    expect(game.unlockedAchievementIds,
        isNot(contains('profile_picture_perfect')));
    expect(await game.purchasePortraitChest(),
        PortraitChestPurchaseResult.collectionComplete);
    expect(game.pet.gems, 999);
  });

  test(
      'Title Chests cost coins and reveal one unowned title without selecting it',
      () async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: Random(810),
    )..pet = Pet(stage: DragonStage.hatchling, firstEgg: false, coins: 150);

    expect(await game.purchaseTitleChest(), TitleChestPurchaseResult.purchased);
    expect(game.pet.coins, 51);
    expect(game.chestCount(ChestTier.title), 1);
    expect(game.titleCount, 0);

    final reward = await game.openChest(ChestTier.title);
    expect(reward?.titleFound, isNotNull);
    expect(reward?.coins, 0);
    expect(reward?.gems, 0);
    expect(reward?.eggFound, isFalse);
    expect(game.titleCount, 1);
    expect(game.selectedAccountTitle, isNull);
    expect(game.chestCount(ChestTier.title), 0);
    expect(game.totalTitleChestsOpened, 1);
    expect(game.achievementProgress('highly_titled'), 1);
    expect(game.unlockedAchievementIds, contains('highly_titled'));

    final title = reward!.titleFound!;
    expect(await game.selectAccountTitle(title.id), isTrue);
    expect(game.selectedTitleId, title.id);
  });

  test('a Title Chest remains closed after all titles are collected', () async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
    )
      ..pet = Pet(stage: DragonStage.hatchling, firstEgg: false, coins: 999)
      ..ownedTitleIds = accountTitleCatalog.map((title) => title.id).toSet()
      ..chestInventory[ChestTier.title] = 1;

    expect(await game.openChest(ChestTier.title), isNull);
    expect(game.chestCount(ChestTier.title), 1);
    expect(game.totalTitleChestsOpened, 0);
    expect(game.unlockedAchievementIds, isNot(contains('highly_titled')));
    expect(await game.purchaseTitleChest(),
        TitleChestPurchaseResult.collectionComplete);
    expect(game.pet.coins, 999);
  });

  test('favorite achievement starts only after the first actual switch',
      () async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
    )..pet = Pet(
        id: 'starter',
        stage: DragonStage.hatchling,
        firstEgg: false,
        favorite: true,
      );
    game.sanctuaryDragons.add(Pet(
      id: 'second',
      stage: DragonStage.hatchling,
      firstEgg: false,
    ));
    expect(game.achievementProgress('not_picking_favorites'), 0);
    await game.toggleFavorite('second');
    expect(game.favoriteChanges, 1);
    expect(game.achievementProgress('not_picking_favorites'), 1);
  });

  test('legacy automatic favorite achievement is removed during migration',
      () async {
    await StorageService.save({
      'schemaVersion': 31,
      'pet': Pet(
        id: 'legacy-favorite',
        stage: DragonStage.hatchling,
        firstEgg: false,
        favorite: true,
      ).toJson(),
      'achievements': ['not_picking_favorites'],
    });

    final restored = await HouseholdProvider.loadFromStorage();
    expect(restored.favoriteChanges, 0);
    expect(restored.unlockedAchievementIds,
        isNot(contains('not_picking_favorites')));
  });

  test('portrait collection and chosen account portrait persist', () async {
    final game = HouseholdProvider(
      initialize: false,
      random: Random(809),
    )..pet = Pet(stage: DragonStage.hatchling, firstEgg: false, gems: 150);
    expect(await game.purchasePortraitChest(),
        PortraitChestPurchaseResult.purchased);
    final reward = await game.openChest(ChestTier.portrait);
    expect(reward?.portraitFound, isNotNull);
    await game.selectProfilePortrait(reward!.portraitFound!.id);

    final restored = await HouseholdProvider.loadFromStorage();
    expect(restored.ownedPortraitIds, contains(reward.portraitFound!.id));
    expect(restored.selectedPortraitId, reward.portraitFound!.id);
    expect(restored.pet.gems, 51);
    expect(restored.totalPortraitChestsOpened, 1);
    expect(
        restored.unlockedAchievementIds, contains('profile_picture_perfect'));
  });

  test('title collection and chosen account title persist', () async {
    final game = HouseholdProvider(
      initialize: false,
      random: Random(811),
    )..pet = Pet(stage: DragonStage.hatchling, firstEgg: false, coins: 150);
    expect(await game.purchaseTitleChest(), TitleChestPurchaseResult.purchased);
    final reward = await game.openChest(ChestTier.title);
    expect(reward?.titleFound, isNotNull);
    await game.selectAccountTitle(reward!.titleFound!.id);

    final restored = await HouseholdProvider.loadFromStorage();
    expect(restored.ownedTitleIds, contains(reward.titleFound!.id));
    expect(restored.selectedTitleId, reward.titleFound!.id);
    expect(restored.pet.coins, 51);
    expect(restored.totalTitleChestsOpened, 1);
    expect(restored.unlockedAchievementIds, contains('highly_titled'));
  });

  test('Tower floor construction and repair prices are ten times higher',
      () async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
    )
      ..pet = Pet(
        stage: DragonStage.hatchling,
        firstEgg: false,
        coins: 10000,
      )
      ..towerFloorRoomIds = [];

    expect(game.nextTowerFloorPrice, 1200);
    expect(await game.buildTowerFloor('hearth'), TowerBuildResult.built);
    expect(game.pet.coins, 8800);
    expect(game.nextTowerFloorPrice, 2050);

    game.damagedTowerFloors.add(0);
    game.damagedTowerRepairFactors[0] = .40;
    expect(game.repairTowerFloorPrice(0), 180);
    expect(await game.repairTowerFloor(0), isTrue);
    expect(game.pet.coins, 8620);
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

  test('refresh repairs an invited favorite with a stale Tower assignment',
      () async {
    final game = HouseholdProvider(random: Random(76));
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Ember'
      ..favorite = true
      ..roamsTower = true
      ..currentFloorIndex = 308
      ..currentRoomId = 'nest';

    expect(game.towerDragons, isNot(contains(game.pet)));
    await game.refreshForCurrentDate();

    expect(game.pet.currentFloorIndex, 0);
    expect(game.pet.currentRoomId, game.towerFloorRoomIds.first);
    expect(game.towerDragons, contains(game.pet));
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
