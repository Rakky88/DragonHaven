import 'dart:convert';
import 'dart:math';

import 'package:dragon_haven/models/achievement.dart';
import 'package:dragon_haven/models/account_title.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/dragon_egg.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/dragon_school.dart';
import 'package:dragon_haven/models/game_presentation.dart';
import 'package:dragon_haven/models/house.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/music_track.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/profile_portrait.dart';
import 'package:dragon_haven/models/shop_item.dart';
import 'package:dragon_haven/models/supporter_pack.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/storage_service.dart';
import 'package:dragon_haven/services/audio_service.dart';
import 'package:dragon_haven/services/notification_service.dart';
import 'package:flutter/services.dart';
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

  test('starter egg taps remove one second but preserve the final second', () {
    final now = DateTime.utc(2026, 8, 27, 20);
    final game = HouseholdProvider(
      random: Random(38),
      clock: () => now,
      persistenceEnabled: false,
    );
    game.pet.stageStartedAt = now.subtract(
      game.pet.incubationDuration - const Duration(seconds: 3),
    );

    expect(game.accelerateStarterEgg(), isTrue);
    expect(game.pet.remainingForNextStage(now), const Duration(seconds: 2));
    expect(game.accelerateStarterEgg(), isTrue);
    expect(game.pet.remainingForNextStage(now), const Duration(seconds: 1));
    expect(game.accelerateStarterEgg(), isFalse);
    expect(game.pet.canHatch(now), isFalse);

    game.pet.firstEgg = false;
    expect(game.accelerateStarterEgg(), isFalse);
    game.dispose();
  });

  test('egg clues reveal lineage affinity but never moral or order', () {
    String hintFor(LawAxis law, MoralAxis moral) {
      final game = HouseholdProvider(
        initialize: false,
        persistenceEnabled: false,
      )..pet = Pet(
          stage: DragonStage.egg,
          firstEgg: true,
          lineageId: 'quietstar',
          lawAxis: law,
          moralAxis: moral,
        );
      return game.eggHint(locale: 'en');
    }

    final lawfulGood = hintFor(LawAxis.lawful, MoralAxis.good);
    expect(hintFor(LawAxis.chaotic, MoralAxis.evil), lawfulGood);
    expect(hintFor(LawAxis.neutral, MoralAxis.neutral), lawfulGood);
    expect(lawfulGood, isNot(contains('rhythm')));
    expect(lawfulGood, isNot(contains('glow')));
    expect(lawfulGood, isNot(contains('tapped back')));
  });

  test('release demo exposes portraits, all Relics and three roaming dragons',
      () {
    final game = HouseholdProvider.createReleaseDemo();
    expect(game.onboardingComplete, isTrue);
    expect(game.pet.isEgg, isFalse);
    expect(game.chestCount(ChestTier.portrait), 2);
    expect(game.chestCount(ChestTier.title), 2);
    expect(game.portraitCount, 8);
    expect(game.selectedPortrait, isNotNull);
    expect(game.titleCount, 8);
    expect(game.selectedAccountTitle, isNotNull);
    expect(game.totalRelicCount, MysticRelic.values.length);
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

  test('a corrupt current save automatically restores the last valid backup',
      () async {
    final game = HouseholdProvider(random: Random(12));
    await game.setLanguage('nl');
    await game.setLanguage('de');
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(StorageService.currentKey, '{broken json');

    final restored = await HouseholdProvider.loadFromStorage();

    expect(restored.languageCode, 'nl');
    expect(StorageService.lastLoadRecoveredFromBackup, isTrue);
    expect(
      preferences.getString(StorageService.recoveryKey),
      '{broken json',
    );
  });

  test('a structurally invalid save also falls back without deleting recovery',
      () async {
    final game = HouseholdProvider(random: Random(13));
    await game.setLanguage('nl');
    await game.setLanguage('de');
    final preferences = await SharedPreferences.getInstance();
    const invalidState = '{"schemaVersion":39,"languageCode":"de"}';
    await preferences.setString(StorageService.currentKey, invalidState);

    final restored = await HouseholdProvider.loadFromStorage();

    expect(restored.languageCode, 'nl');
    expect(StorageService.lastLoadRecoveredFromBackup, isTrue);
    expect(preferences.getString(StorageService.recoveryKey), invalidState);
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
    var restored = await HouseholdProvider.loadFromStorage();

    expect(
      restored.notificationEnabled(HavenNotificationCategory.tradeReturns),
      isFalse,
    );
    expect(
      restored.notificationEnabled(HavenNotificationCategory.tradeRequests),
      isTrue,
    );

    await restored.setNotificationEnabled(
      HavenNotificationCategory.specialEvents,
      false,
    );
    restored = await HouseholdProvider.loadFromStorage();
    expect(
      restored.notificationEnabled(HavenNotificationCategory.specialEvents),
      isFalse,
    );
  });

  test('an exact-alarm permission change reschedules pending game timers',
      () async {
    const channel = MethodChannel('nl.dragonhaven.app/notifications');
    var exactAlarmGranted = false;
    final scheduledIds = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'permissionStatus':
          return 'granted';
        case 'exactAlarmGranted':
          return exactAlarmGranted;
        case 'schedule':
          scheduledIds.add((call.arguments as Map)['id'] as String);
          return true;
        default:
          return true;
      }
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final now = DateTime(2036, 8, 31, 12);
    final game = HouseholdProvider(
      random: Random(301),
      clock: () => now,
      persistenceEnabled: false,
    )..trialOffers = [
        TrialOffer(
          id: 'remaining-one',
          kind: TrialKind.ruinBreaker,
          appearedAt: now,
        ),
        TrialOffer(
          id: 'remaining-two',
          kind: TrialKind.runeweaver,
          appearedAt: now,
        ),
      ];
    addTearDown(game.dispose);

    await game.synchronizeNotificationPermissionWithPlatform();
    expect(scheduledIds, isEmpty);
    exactAlarmGranted = true;
    await game.synchronizeNotificationPermissionWithPlatform();
    await Future<void>.delayed(Duration.zero);

    expect(scheduledIds, contains('trials-full'));
  });

  test('existing saves inherit Special Event notifications as default on',
      () async {
    SharedPreferences.setMockInitialValues({
      'dragon_haven_state_v1': '{"enabledNotificationCategories":["eggReady"]}',
    });

    final restored = await HouseholdProvider.loadFromStorage();
    expect(
      restored.notificationEnabled(HavenNotificationCategory.specialEvents),
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
    expect(reward!.gems, 0, reason: 'Wooden Chests must never contain gems.');
    expect(game.pet.coins, beforeCoins + reward.coins);
    expect(game.pet.xp, beforeXp,
        reason: 'Adventure XP must never be part of a chest.');
    expect(game.totalChestsOpened, 1);
    expect(game.chestCount(ChestTier.wooden), 0);
    expect(await game.openChest(ChestTier.wooden), isNull);
  });

  test('ten matching chests open as one bundle with ten independent rewards',
      () async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: Random(310),
    )
      ..pet = Pet(stage: DragonStage.hatchling, firstEgg: false)
      ..chestInventory[ChestTier.wooden] = 12;
    final beforeCoins = game.pet.coins;

    final bundle = await game.openChests(ChestTier.wooden, count: 10);

    expect(bundle, isNotNull);
    expect(bundle!.openedCount, 10);
    expect(bundle.rewards, hasLength(10));
    expect(bundle.rewards.every((reward) => reward.tier == ChestTier.wooden),
        isTrue);
    expect(bundle.gems, 0);
    expect(game.pet.coins, beforeCoins + bundle.coins);
    expect(game.chestCount(ChestTier.wooden), 2);
    expect(game.totalChestsOpened, 10);
  });

  test('a ten-chest batch never consumes chests reserved for an online trade',
      () async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: Random(311),
    )
      ..pet = Pet(stage: DragonStage.hatchling, firstEgg: false)
      ..chestInventory[ChestTier.gold] = 12
      ..reservedOnlineTradeChests[ChestTier.gold.name] = 3;

    expect(game.openableChestCount(ChestTier.gold), 9);
    expect(await game.openChests(ChestTier.gold, count: 10), isNull);
    expect(game.chestCount(ChestTier.gold), 12);
    expect(game.totalChestsOpened, 0);
  });

  test('ten Sinister Chests aggregate every Sinister Egg and relic roll',
      () async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: _ZeroRandom(),
    )
      ..pet = Pet(stage: DragonStage.hatchling, firstEgg: false)
      ..chestInventory[ChestTier.sinister] = 10;

    final bundle = await game.openChests(ChestTier.sinister, count: 10);

    expect(bundle, isNotNull);
    expect(bundle!.openedCount, 10);
    expect(bundle.sinisterEggCount, 10);
    expect(bundle.mysteriousEggCount, 0);
    expect(bundle.relics, hasLength(10));
    expect(game.eggStash, hasLength(10));
    expect(game.eggStash.every((egg) => egg.isSinisterEgg), isTrue);
    expect(game.chestCount(ChestTier.sinister), 0);
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
    expect(game.sinisterEggDropChance(ChestTier.sinister), .5);
    expect(game.sinisterEggDropChance(ChestTier.mythical), 0);
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

  test('Sinister Chests replace the normal egg with Sinisterra half the time',
      () async {
    final sinisterGame = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: _ZeroRandom(),
    )
      ..pet = Pet(stage: DragonStage.hatchling, firstEgg: false)
      ..chestInventory[ChestTier.sinister] = 1;

    final sinisterReward = await sinisterGame.openChest(ChestTier.sinister);
    final sinisterEgg = sinisterGame.eggStash.single;
    expect(sinisterReward?.eggFound, isTrue);
    expect(sinisterReward?.sinisterEgg, isTrue);
    expect(sinisterEgg.isSinisterEgg, isTrue);
    expect(sinisterEgg.lineageId, 'sinisterra');
    expect(sinisterEgg.moralAxis, MoralAxis.evil);
    expect(sinisterEgg.incubationDuration,
        const Duration(hours: 6, minutes: 6, seconds: 6));
    expect(sinisterEgg.incubationSeconds, 21966);
    expect(sinisterEgg.incubationMinutes, 367,
        reason: 'legacy minute snapshots must round up, never hatch early');
    expect(
      DragonEgg.fromJson(sinisterEgg.toJson()).incubationDuration,
      const Duration(hours: 6, minutes: 6, seconds: 6),
    );

    final normalGame = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: _HighRandom(),
    )
      ..pet = Pet(stage: DragonStage.hatchling, firstEgg: false)
      ..chestInventory[ChestTier.sinister] = 1;
    final normalReward = await normalGame.openChest(ChestTier.sinister);
    expect(normalReward?.eggFound, isTrue);
    expect(normalReward?.sinisterEgg, isFalse);
    expect(normalGame.eggStash.single.isSinisterEgg, isFalse);
    expect(normalGame.eggStash.single.sinister, isFalse);
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

  test('every chest relic chance remains explicit and exact', () {
    final game = HouseholdProvider(random: Random(204));
    expect(game.relicDropChance(ChestTier.wooden), 0);
    expect(game.relicDropChance(ChestTier.silver), 0);
    expect(game.relicDropChance(ChestTier.gold), .01);
    expect(game.relicDropChance(ChestTier.dragon), .02);
    expect(game.relicDropChance(ChestTier.mythical), .04);
    expect(game.relicDropChance(ChestTier.sinister), 1);
    expect(game.relicDropChance(ChestTier.portrait), 0);
    expect(game.relicDropChance(ChestTier.title), 0);
    expect(game.relicDropChance(ChestTier.music), 0);
  });

  test('using each relic reveals only its secret and persists it', () async {
    final game = HouseholdProvider(random: Random(203));
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Nova';
    game.relicInventory = {
      for (final relic in MysticRelic.values) relic: 0,
      MysticRelic.moralPrism: 1,
      MysticRelic.orderCompass: 1,
      MysticRelic.soulMirror: 1,
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

  test('shop relics cost 500 gems, persist and cannot be traded', () async {
    final game = HouseholdProvider(random: Random(204));
    game.pet
      ..stage = DragonStage.hatchling
      ..gems = 1000;

    expect(
      await game.purchaseRelic(MysticRelic.moralPrism),
      MysticRelicPurchaseResult.purchased,
    );
    expect(
      await game.purchaseRelic(MysticRelic.moralPrism),
      MysticRelicPurchaseResult.purchased,
    );
    expect(game.pet.gems, 0);
    expect(game.relicCount(MysticRelic.moralPrism), 2);
    expect(game.untradeableRelicCount(MysticRelic.moralPrism), 2);
    expect(game.tradeableRelicCount(MysticRelic.moralPrism), 0);
    expect(
      await game.purchaseRelic(MysticRelic.moralPrism),
      MysticRelicPurchaseResult.insufficientGems,
    );

    final restored = await HouseholdProvider.loadFromStorage();
    expect(restored.relicCount(MysticRelic.moralPrism), 2);
    expect(restored.untradeableRelicCount(MysticRelic.moralPrism), 2);
    expect(restored.tradeableRelicCount(MysticRelic.moralPrism), 0);

    restored.relicInventory[MysticRelic.moralPrism] = 3;
    expect(restored.gameplayRelicCount(MysticRelic.moralPrism), 1);
    expect(restored.tradeableRelicCount(MysticRelic.moralPrism), 1);
    expect(
      await restored.useRelic(MysticRelic.moralPrism, restored.pet.id),
      MysticRelicUseResult.revealed,
    );
    expect(restored.relicCount(MysticRelic.moralPrism), 2);
    expect(restored.untradeableRelicCount(MysticRelic.moralPrism), 1,
        reason: 'using a Relic consumes an untradeable shop copy first');
    expect(restored.gameplayRelicCount(MysticRelic.moralPrism), 1);
  });

  test('new Relics keep their distinct use, shop and trade rules', () async {
    var now = DateTime.utc(2026, 8, 28, 12);
    final game = HouseholdProvider(
      random: Random(852),
      clock: () => now,
      persistenceEnabled: false,
    );
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Nova';
    final egg = DragonEgg(
      id: 'relic-test-egg',
      lineageId: dragonLineages.last.id,
      acquiredAt: now,
      hatchSeed: 852,
      prismatic: false,
      incubationMinutes: 100,
    );
    game.eggStash.add(egg);
    game.relicInventory[MysticRelic.astralLens] = 1;
    expect(
      await game.useAstralLens(egg.id),
      AstralLensUseResult.revealed,
    );
    expect(game.isEggRarityKnown(egg.id), isTrue);
    expect(game.relicCount(MysticRelic.astralLens), 0);
    expect(game.pet.moralAxisKnown, isFalse);
    expect(game.pet.lawAxisKnown, isFalse);

    expect(await game.activateEgg(egg.id), isTrue);
    final before = game.nestEgg!.remainingForNextStage(now);
    game.relicInventory[MysticRelic.chronoshard] = 1;
    game.chronoshardReductions = [37];
    expect(
      await game.useChronoshard(37),
      ChronoshardUseResult.accelerated,
    );
    final after = game.nestEgg!.remainingForNextStage(now);
    expect(after.inMilliseconds, closeTo(before.inMilliseconds * .63, 2));
    expect(game.chronoshardReductions, isEmpty);
    expect(game.relicCount(MysticRelic.chronoshard), 0);

    game.relicInventory[MysticRelic.wayfinderSigil] = 1;
    final original = game.adventuresFor(AdventureKind.mini).first.id;
    expect(
      await game.useWayfinderSigil(
        AdventureKind.mini,
        replaceAdventureId: original,
      ),
      WayfinderSigilUseResult.changed,
    );
    expect(
        game.adventureOptionIds[AdventureKind.mini], isNot(contains(original)));
    expect(game.relicCount(MysticRelic.wayfinderSigil), 0);

    game.pet.gems = 1500;
    expect(
      await game.purchaseRelic(MysticRelic.astralLens),
      MysticRelicPurchaseResult.purchased,
    );
    expect(game.untradeableRelicCount(MysticRelic.astralLens), 1);
    expect(
      await game.purchaseRelic(MysticRelic.chronoshard),
      MysticRelicPurchaseResult.notAvailable,
    );
    expect(
      await game.purchaseRelic(MysticRelic.wayfinderSigil),
      MysticRelicPurchaseResult.notAvailable,
    );
    expect(game.pet.gems, 1000);
  });

  test('Twinstar Brooch moves, unequips and doubles XP only for its wearer',
      () async {
    final game = HouseholdProvider(
      random: Random(853),
      persistenceEnabled: false,
    );
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Nova'
      ..gems = 9;
    final other = Pet(
      id: 'twinstar-other',
      name: 'Ember',
      stage: DragonStage.hatchling,
      firstEgg: false,
    );
    game.sanctuaryDragons.add(other);
    game.relicInventory[MysticRelic.twinstarBrooch] = 1;
    game.untradeableRelicInventory[MysticRelic.twinstarBrooch] = 1;
    game.twinstarBroochEverObtained = true;

    expect(await game.equipTwinstarBrooch(game.pet.id), isTrue);
    expect(await game.buyStarlightTreat(), isTrue);
    expect(game.pet.xp, 50);
    expect(game.tradeableRelicCount(MysticRelic.twinstarBrooch), 0);
    expect(await game.equipTwinstarBrooch(other.id), isTrue);
    expect(game.isTwinstarEquippedOn(game.pet.id), isFalse);
    expect(game.isTwinstarEquippedOn(other.id), isTrue);
    expect(await game.buyStarlightTreat(), isTrue);
    expect(game.pet.xp, 75,
        reason: 'moving the Brooch restores normal XP for the old wearer');
    expect(await game.equipTwinstarBrooch(null), isTrue);
    expect(await game.buyStarlightTreat(), isTrue);
    expect(game.pet.xp, 100);
    expect(game.twinstarBroochDragonId, isNull);
  });

  test('Music Chests cost 250 gems, roll at open and never duplicate',
      () async {
    final game = HouseholdProvider(random: Random(854));
    game.pet
      ..stage = DragonStage.hatchling
      ..gems = 500;
    expect(game.ownedMusicTrackIds, {'reverie'});
    expect(game.enabledMusicTrackIds, {'reverie'});
    expect(
      await game.purchaseMusicChest(),
      MusicChestPurchaseResult.purchased,
    );
    expect(game.pet.gems, 250);
    expect(game.musicTrackCount, 1,
        reason: 'the song is rolled only when the chest opens');
    final first = await game.openChest(ChestTier.music);
    expect(first?.musicTrackFound, isNotNull);
    expect(first?.musicTrackFound?.id, isNot('reverie'));
    expect(game.musicTrackCount, 2);
    expect(
      game.enabledMusicTrackIds,
      contains(first!.musicTrackFound!.id),
    );

    expect(
      await game.purchaseMusicChest(),
      MusicChestPurchaseResult.purchased,
    );
    final second = await game.openChest(ChestTier.music);
    expect(second?.musicTrackFound?.id, isNot(first.musicTrackFound!.id));
    expect(game.pet.gems, 0);
    expect(game.chestCount(ChestTier.music), 0);

    await game.setMusicTrackEnabled('reverie', false);
    await game.setJukeboxShuffle(true);
    await game.setJukeboxRepeat(false);
    final restored = await HouseholdProvider.loadFromStorage();
    expect(restored.musicTrackCount, 3);
    expect(restored.enabledMusicTrackIds, isNot(contains('reverie')));
    expect(restored.jukeboxShuffle, isTrue);
    expect(restored.jukeboxRepeat, isFalse);
  });

  test('collection chest batches reveal ten distinct collection rewards',
      () async {
    for (final tier in const [
      ChestTier.portrait,
      ChestTier.title,
      ChestTier.music,
    ]) {
      final game = HouseholdProvider(
        initialize: false,
        persistenceEnabled: false,
        random: Random(860 + tier.index),
      )
        ..pet = Pet(stage: DragonStage.hatchling, firstEgg: false)
        ..chestInventory[tier] = 10;

      final bundle = await game.openChests(tier, count: 10);

      expect(bundle, isNotNull, reason: tier.name);
      expect(bundle!.openedCount, 10, reason: tier.name);
      expect(game.chestCount(tier), 0, reason: tier.name);
      final ids = switch (tier) {
        ChestTier.portrait =>
          bundle.portraits.map((portrait) => portrait.id).toSet(),
        ChestTier.title => bundle.titles.map((title) => title.id).toSet(),
        ChestTier.music => bundle.musicTracks.map((track) => track.id).toSet(),
        _ => <String>{},
      };
      expect(ids, hasLength(10), reason: '${tier.name} must not duplicate');
    }
  });

  test('Music Chest capacity counts unopened chests against all 80 tracks',
      () async {
    final game = HouseholdProvider(
      random: Random(855),
      persistenceEnabled: false,
    );
    game.pet.gems = musicChestGemPrice;
    game.ownedMusicTrackIds = musicCatalog
        .take(musicCatalog.length - 1)
        .map((track) => track.id)
        .toSet();
    expect(game.musicChestCapacityReached, isFalse);
    expect(
      await game.purchaseMusicChest(),
      MusicChestPurchaseResult.purchased,
    );
    expect(game.musicChestCapacityReached, isTrue);
    expect(
      await game.purchaseMusicChest(),
      MusicChestPurchaseResult.collectionComplete,
    );
    final reward = await game.openChest(ChestTier.music);
    expect(reward?.musicTrackFound?.id, musicCatalog.last.id);
    expect(game.hasEveryMusicTrack, isTrue);
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

  test('aborting a solo Adventure gives nothing and frees only its dragon',
      () async {
    final game = HouseholdProvider(
      random: Random(845),
      persistenceEnabled: false,
    );
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Ember';
    final adventure = game.adventuresFor(AdventureKind.mini).first;
    final startingXp = game.pet.xp;
    final startingTraining = game.pet.trainingFor(adventure.focus);
    final startingChests = game.totalChestCount;

    final run = AdventureRun(
      id: 'abort-unit-run',
      adventureId: adventure.id,
      dragonId: game.pet.id,
      startedAt: DateTime.now(),
      endsAt: DateTime.now().add(const Duration(minutes: 2)),
      status: AdventureRunStatus.running,
    );
    game.adventureRuns = [run];
    game.pet.activeAdventureId = run.id;
    expect(await game.abortAdventure(run.id), isTrue);
    expect(game.adventureRuns, isEmpty);
    expect(game.pet.activeAdventureId, isNull);
    expect(game.pet.xp, startingXp);
    expect(game.pet.trainingFor(adventure.focus), startingTraining);
    expect(game.totalChestCount, startingChests);
    expect(game.totalAdventuresCompleted, 0);
    expect(await game.abortAdventure(run.id), isFalse);
  });

  test('a solo Adventure keeps its hidden chest roll across a save', () async {
    final game = HouseholdProvider(
      random: Random(852),
      persistenceEnabled: false,
    );
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Ember';
    final adventure = game.adventuresFor(AdventureKind.short).first;

    expect(
      await game.startAdventure(adventure, dragonId: game.pet.id),
      AdventureStartResult.started,
    );
    final startedRun = game.adventureRuns.single;
    expect(startedRun.rewardTier, isNotNull);

    final restoredRun = AdventureRun.fromJson(startedRun.toJson());
    expect(restoredRun.rewardTier, startedRun.rewardTier);
  });

  test('Adventure return reminders match the claimable boundary exactly', () {
    final game = HouseholdProvider(
      random: Random(851),
      persistenceEnabled: false,
    );
    final endsAt = DateTime.utc(2026, 8, 28, 12, 30, 0, 750);
    final reminderAt = game.adventureReturnNotificationAt(endsAt);

    expect(reminderAt, endsAt);
  });

  test('a Group Adventure cannot be aborted through the local safety API',
      () async {
    final game = HouseholdProvider(
      random: Random(846),
      persistenceEnabled: false,
    );
    game.pet
      ..stage = DragonStage.hatchling
      ..activeAdventureId = 'legacy-group-run';
    final group = AdventureCatalog.group.first;
    game.adventureRuns = [
      AdventureRun(
        id: 'legacy-group-run',
        adventureId: group.id,
        dragonId: game.pet.id,
        startedAt: DateTime.now(),
        endsAt: DateTime.now().add(const Duration(days: 2)),
        status: AdventureRunStatus.running,
        participantCount: 2,
      ),
    ];

    expect(await game.abortAdventure('legacy-group-run'), isFalse);
    expect(game.adventureRuns, hasLength(1));
    expect(game.pet.activeAdventureId, 'legacy-group-run');
  });

  test('the achievement catalog has 33 unique humorous milestones', () {
    expect(achievementCatalog, hasLength(33));
    expect(achievementCatalog.map((entry) => entry.id).toSet(), hasLength(33));
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
    expect(game.pet.gems, 50);
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

  test('unopened Portrait Chests reserve the remaining collection capacity',
      () async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
    )
      ..pet = Pet(stage: DragonStage.hatchling, firstEgg: false, gems: 999)
      ..ownedPortraitIds = profilePortraitCatalog
          .take(profilePortraitCatalog.length - 2)
          .map((portrait) => portrait.id)
          .toSet()
      ..chestInventory[ChestTier.portrait] = 2;

    expect(game.hasEveryPortrait, isFalse);
    expect(game.portraitChestCapacityReached, isTrue);
    expect(await game.purchasePortraitChest(),
        PortraitChestPurchaseResult.collectionComplete);
    expect(game.pet.gems, 999);
    expect(game.remainingPortraitsByRarity.values.fold(0, (a, b) => a + b), 2);
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
    expect(game.pet.coins, 50);
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

  test('unopened Title Chests reserve the remaining collection capacity',
      () async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
    )
      ..pet = Pet(stage: DragonStage.hatchling, firstEgg: false, coins: 999)
      ..ownedTitleIds = accountTitleCatalog
          .take(accountTitleCatalog.length - 1)
          .map((title) => title.id)
          .toSet()
      ..chestInventory[ChestTier.title] = 1;

    expect(game.hasEveryTitle, isFalse);
    expect(game.titleChestCapacityReached, isTrue);
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

  test('loading an older save rebuilds discoveries for every owned dragon',
      () async {
    final normalLineage = dragonLineages.first.id;
    final prismaticLineage = dragonLineages[1].id;
    await StorageService.save({
      'schemaVersion': 31,
      'pet': Pet(
        id: 'active-old-save',
        lineageId: normalLineage,
        stage: DragonStage.wyrmling,
        firstEgg: false,
      ).toJson(),
      'sanctuaryDragons': [
        Pet(
          id: 'sanctuary-old-save',
          lineageId: prismaticLineage,
          stage: DragonStage.ascended,
          firstEgg: false,
          prismatic: true,
          evolutionPath: 'arcana',
        ).toJson(),
      ],
    });

    final restored = await HouseholdProvider.loadFromStorage();

    expect(restored.discoveredForms, contains('$normalLineage:hatchling'));
    expect(restored.discoveredForms, contains('$normalLineage:wyrmling'));
    expect(restored.prismaticForms, contains('$prismaticLineage:hatchling'));
    expect(restored.prismaticForms, contains('$prismaticLineage:wyrmling'));
    expect(
        restored.prismaticForms, contains('$prismaticLineage:ascended:arcana'));
    expect(restored.discoveredLineageCount, 1);
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
    expect(restored.pet.gems, 50);
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
    expect(restored.pet.coins, 50);
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

  test('released dragons get one persisted 10% roll at a random daily time',
      () {
    var now = DateTime(2026, 8, 28, 8);
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: _DailyReturningRandom(),
      clock: () => now,
    )..pet = Pet(
        id: 'active-dragon',
        name: 'Ember',
        stage: DragonStage.hatchling,
        firstEgg: false,
        favorite: true,
      );

    expect(game.processDailyReturningDragonForTesting(), isFalse);
    expect(game.lastReturningDayKey, isEmpty,
        reason: 'No daily roll is consumed without a released dragon.');
    expect(game.scheduledReturningAt, isNull);

    game.releasedDragons.add(Pet(
      id: 'released-dragon',
      name: 'Cinder',
      stage: DragonStage.hatchling,
      firstEgg: false,
      moralAxis: MoralAxis.good,
      lawAxis: LawAxis.lawful,
    ));

    expect(game.processDailyReturningDragonForTesting(), isTrue);
    expect(game.lastReturningDayKey, '2026-08-28');
    expect(game.scheduledReturningAt, DateTime(2026, 8, 28, 18));
    expect(game.totalReleasedReturns, 0);

    now = DateTime(2026, 8, 28, 17, 59);
    expect(game.processDailyReturningDragonForTesting(), isFalse);
    now = DateTime(2026, 8, 28, 18);
    expect(game.processDailyReturningDragonForTesting(), isTrue);
    expect(game.totalReleasedReturns, 1);
    expect(game.chestCount(ChestTier.wooden), 1);
    expect(game.scheduledReturningAt, isNull);

    now = DateTime(2026, 8, 28, 23);
    expect(game.processDailyReturningDragonForTesting(), isFalse);
    expect(game.totalReleasedReturns, 1,
        reason: 'A local day may only resolve one newly rolled return.');

    now = DateTime(2026, 8, 29, 8);
    expect(game.processDailyReturningDragonForTesting(), isTrue);
    expect(game.lastReturningDayKey, '2026-08-29');
    expect(game.scheduledReturningAt, DateTime(2026, 8, 29, 18));
    final state = game.exportState();
    expect(state['lastReturningDayKey'], '2026-08-29');
    expect(state['scheduledReturningAt'], '2026-08-29T18:00:00.000');
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

  test('a dragon away on any Adventure cannot be released', () async {
    final game = HouseholdProvider(random: Random(611));
    game.pet
      ..stage = DragonStage.hatchling
      ..favorite = true;
    final away = Pet(
      id: 'away-dragon',
      name: 'Voyager',
      stage: DragonStage.ascended,
      evolutionPath: 'spirit',
      activeAdventureId: 'group-lobby-or-local-run',
    );
    game.sanctuaryDragons.add(away);

    expect(await game.releaseDragon(away.id), isFalse);
    expect(game.ownedDragons, contains(away));
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

  test('Tower room reorder keeps dragons and damage attached to rooms',
      () async {
    final game = HouseholdProvider(
      random: Random(900),
      persistenceEnabled: false,
    );
    game.pet
      ..stage = DragonStage.hatchling
      ..currentFloorIndex = 0
      ..currentRoomId = 'hearth';
    game.towerFloorRoomIds = ['hearth', 'crystal', 'garden'];
    game.damagedTowerFloors = {1};
    game.damagedTowerRepairFactors = {1: .4};

    expect(await game.reorderTowerFloor(2, 0), isTrue);

    expect(game.towerFloorRoomIds, ['crystal', 'garden', 'hearth']);
    expect(game.pet.currentFloorIndex, 2);
    expect(game.damagedTowerFloors, {0});
    expect(game.damagedTowerRepairFactors[0], .4);
    game.dispose();
  });

  test('Trial streak resets to zero after a missed day', () async {
    var now = DateTime(2026, 8, 24, 12);
    final game = HouseholdProvider(
      random: Random(901),
      clock: () => now,
      persistenceEnabled: false,
    );
    game.pet.stage = DragonStage.hatchling;

    Future<void> completeToday(String id) async {
      game
        ..trialOffers = [
          TrialOffer(id: id, kind: TrialKind.ruinBreaker, appearedAt: now),
        ]
        ..trialRefilledAt = now;
      expect(
        await game.completeTrial(offerId: id, dragonId: game.pet.id, score: 1),
        isNotNull,
      );
    }

    await completeToday('day-one');
    expect(game.trialStreakCount, 1);
    now = now.add(const Duration(days: 2));
    await game.refreshForCurrentDate();
    expect(game.trialStreakCount, 0);
    expect(game.trialStreakLastDayKey, isEmpty);

    await completeToday('day-three');
    expect(game.trialStreakCount, 1);
    expect(game.trialStreakLastDayKey, '2026-08-26');
    game.dispose();
  });

  test('full Trial streak carries at most one latest day after claim',
      () async {
    var now = DateTime(2026, 8, 20, 12);
    final game = HouseholdProvider(
      random: _ZeroRandom(),
      clock: () => now,
      persistenceEnabled: false,
    );
    game.pet.stage = DragonStage.hatchling;

    Future<void> completeToday(String id) async {
      game
        ..trialOffers = [
          TrialOffer(id: id, kind: TrialKind.ruinBreaker, appearedAt: now),
        ]
        ..trialRefilledAt = now;
      await game.completeTrial(offerId: id, dragonId: game.pet.id, score: 1);
    }

    for (var day = 0; day < 7; day++) {
      if (day > 0) now = now.add(const Duration(days: 1));
      await completeToday('streak-$day');
    }
    expect(game.trialStreakRewardReady, isTrue);
    expect(game.trialStreakCount, 7);

    now = now.add(const Duration(days: 1));
    await completeToday('waiting-eight');
    now = now.add(const Duration(days: 1));
    await completeToday('waiting-nine');
    expect(game.trialStreakCarryDayKey, '2026-08-28');

    expect(await game.claimTrialStreakReward(), ChestTier.mythical);
    expect(game.trialStreakCount, 1);
    expect(game.trialStreakLastDayKey, '2026-08-28');
    expect(game.trialStreakRewardReady, isFalse);
    game.dispose();
  });

  test('missed carried Trial day resets next streak to zero', () async {
    var now = DateTime(2026, 8, 20, 12);
    final game = HouseholdProvider(
      random: _ZeroRandom(),
      clock: () => now,
      persistenceEnabled: false,
    )
      ..trialStreakCount = 7
      ..trialStreakLastDayKey = '2026-08-20'
      ..trialStreakRewardReady = true;

    now = now.add(const Duration(days: 1));
    game
      ..trialOffers = [
        TrialOffer(
          id: 'carried-day',
          kind: TrialKind.ruinBreaker,
          appearedAt: now,
        ),
      ]
      ..trialRefilledAt = now
      ..pet.stage = DragonStage.hatchling;
    await game.completeTrial(
      offerId: 'carried-day',
      dragonId: game.pet.id,
      score: 1,
    );
    expect(game.trialStreakCarryDayKey, '2026-08-21');

    now = now.add(const Duration(days: 2));
    expect(await game.claimTrialStreakReward(), ChestTier.mythical);
    expect(game.trialStreakCount, 0);
    expect(game.trialStreakLastDayKey, isEmpty);
    game.dispose();
  });

  test('Sinisterra is always Evil and its moral alignment is known', () {
    final direct = Pet(
      stage: DragonStage.hatchling,
      lineageId: 'sinisterra',
      moralAxis: MoralAxis.good,
      moralAxisKnown: false,
    );
    final restored = Pet.fromJson({
      'id': 'legacy-sinister',
      'stage': 'hatchling',
      'lineageId': 'sinisterra',
      'moralAxis': 'neutral',
      'moralAxisKnown': false,
    });
    final egg = DragonEgg(
      id: 'sinister-egg',
      lineageId: 'sinisterra',
      acquiredAt: DateTime(2026),
      hatchSeed: 5,
      prismatic: false,
      moralAxis: MoralAxis.good,
    ).activate(coins: 0, gems: 0);

    for (final dragon in [direct, restored, egg]) {
      expect(dragon.sinister, isTrue);
      expect(dragon.moralAxis, MoralAxis.evil);
      expect(dragon.moralAxisKnown, isTrue);
    }
  });

  test('Supporter cosmetics stay outside chest pools and grant idempotently',
      () async {
    final game = HouseholdProvider(
      random: Random(902),
      persistenceEnabled: false,
    );
    final chestPortraitsBefore = game.chestPortraitCount;
    final chestTitlesBefore = game.chestTitleCount;

    expect(await game.applyVerifiedSupporterPack('verified-order-1'), isTrue);
    expect(await game.applyVerifiedSupporterPack('verified-order-1'), isFalse);
    expect(game.supporterPackOwned, isTrue);
    expect(game.ownedPortraitIds, contains(supporterProfilePortrait.id));
    expect(game.ownedTitleIds, contains(supporterAccountTitle.id));
    expect(game.ownedBadgeIds, contains(supporterBadge.id));
    expect(game.ownedFrameIds, contains(supporterFrame.id));
    expect(game.ownedItemIds,
        containsAll(supporterFurnitureCatalog.map((item) => item.id)));
    final throne = supporterFurnitureCatalog.first;
    expect(
      await game.placeHouseItem(
        throne.id,
        roomId: 'hearth',
        x: .5,
        y: .7,
      ),
      isTrue,
    );
    expect(
      game.placementsForRoom('hearth').map((placement) => placement.itemId),
      contains(throne.id),
    );
    expect(game.chestPortraitCount, chestPortraitsBefore);
    expect(game.chestTitleCount, chestTitlesBefore);
    game.dispose();
  });

  test('Dragon Academy unlocks at five floors and only stores higher records',
      () async {
    final game = HouseholdProvider(
      random: Random(903),
      persistenceEnabled: false,
    );
    game.towerFloorRoomIds = List.filled(4, 'hearth');
    expect(game.dragonSchoolUnlocked, isFalse);
    expect(await game.recordDragonSchoolScore('runeRush', 5), isFalse);

    game.towerFloorRoomIds = [...game.towerFloorRoomIds, 'crystal'];
    expect(game.dragonSchoolUnlocked, isTrue);
    expect(await game.recordDragonSchoolScore('runeRush', 5), isTrue);
    expect(await game.recordDragonSchoolScore('runeRush', 3), isFalse);
    expect(game.dragonSchoolRecords['runeRush'], 5);
    game.dispose();
  });

  test('ISUPPORTRICK grants the Supporter Pack once', () async {
    final game = HouseholdProvider(
      random: Random(904),
      persistenceEnabled: false,
    );

    expect(await game.redeemCode('ISUPPORTRICK'), 'redeemed');
    expect(game.supporterPackOwned, isTrue);
    expect(game.ownedBadgeIds, contains(supporterBadge.id));
    expect(await game.redeemCode('ISUPPORTRICK'), 'already_redeemed');
    expect(await game.redeemCode('isupportrick'), 'invalid_format');
    game.dispose();
  });

  test('Dragon Academy rewards only new stars and doubles equipped XP',
      () async {
    final game = HouseholdProvider(
      random: Random(905),
      persistenceEnabled: false,
    )
      ..towerFloorRoomIds = List.filled(5, 'hearth')
      ..pet.stage = DragonStage.hatchling
      ..pet.firstEgg = false;
    final dragon = game.pet;
    final startingXp = dragon.xp;

    final bronze = await game.completeDragonSchoolLesson(
      gameId: 'runeRush',
      score: 8,
      dragonIds: [dragon.id],
    );
    expect(bronze.accepted, isTrue);
    expect(bronze.newStarsByDragon[dragon.id], 1);
    expect(dragon.xp, startingXp + 5);
    expect(dragon.trainingFor(TrainingFocus.arcana), 1);

    final repeat = await game.completeDragonSchoolLesson(
      gameId: 'runeRush',
      score: 8,
      dragonIds: [dragon.id],
    );
    expect(repeat.totalNewStars, 0);
    expect(dragon.xp, startingXp + 5);

    game
      ..relicInventory[MysticRelic.twinstarBrooch] = 1
      ..twinstarBroochDragonId = dragon.id;
    final gold = await game.completeDragonSchoolLesson(
      gameId: 'runeRush',
      score: 25,
      dragonIds: [dragon.id],
    );
    expect(gold.newStarsByDragon[dragon.id], 2);
    expect(gold.xpByDragon[dragon.id], 20);
    expect(dragon.xp, startingXp + 25);
    expect(dragon.trainingFor(TrainingFocus.arcana), 3);
    expect(dragon.schoolAttempts('runeRush'), 3);

    final blocked = await game.completeDragonSchoolLesson(
      gameId: 'runeRush',
      score: 100,
      dragonIds: [dragon.id],
    );
    expect(blocked.accepted, isFalse);
    expect(dragon.schoolAttempts('runeRush'), 3);
    expect(dragon.schoolBest('runeRush'), 25);
    game.dispose();
  });

  test('Dragon Academy team lessons validate availability and track mentors',
      () async {
    final game = HouseholdProvider(
      random: Random(906),
      persistenceEnabled: false,
    )
      ..towerFloorRoomIds = List.filled(5, 'hearth')
      ..pet.stage = DragonStage.hatchling
      ..pet.firstEgg = false;
    final pupil = Pet(
      id: 'school-pupil',
      stage: DragonStage.wyrmling,
      firstEgg: false,
    );
    final mentor = Pet(
      id: 'school-mentor',
      stage: DragonStage.ascended,
      firstEgg: false,
      evolutionPath: 'might',
    );
    game.sanctuaryDragons.addAll([pupil, mentor]);

    final result = await game.completeDragonSchoolLesson(
      gameId: 'safeHoard',
      score: 5,
      dragonIds: [game.pet.id, pupil.id],
      mentorDragonId: mentor.id,
    );
    expect(result.accepted, isTrue);
    expect(result.newStarsByDragon.keys,
        containsAll(<String>[game.pet.id, pupil.id]));
    expect(mentor.dragonSchoolMentorLessons, 1);

    pupil.activeAdventureId = 'away';
    final rejected = await game.completeDragonSchoolLesson(
      gameId: 'safeHoard',
      score: 10,
      dragonIds: [game.pet.id, pupil.id],
      mentorDragonId: mentor.id,
    );
    expect(rejected.accepted, isFalse);
    expect(mentor.dragonSchoolMentorLessons, 1);
    game.dispose();
  });

  test('Dragon Academy report data survives Pet serialization', () {
    final dragon = Pet(
      stage: DragonStage.hatchling,
      firstEgg: false,
      dragonSchoolRecords: const {'runeRush': 24},
      dragonSchoolStars: const {'runeRush': 2, 'safeHoard': 3},
      dragonSchoolAttempts: const {'runeRush': 2, 'safeHoard': 3},
      dragonSchoolFinalizedEarly: true,
      dragonSchoolMentorLessons: 7,
    );
    final restored = Pet.fromJson(dragon.toJson());

    expect(restored.schoolBest('runeRush'), 24);
    expect(restored.schoolStars('runeRush'), 2);
    expect(restored.dragonSchoolStarTotal, 5);
    expect(restored.schoolAttempts('runeRush'), 2);
    expect(restored.schoolAttempts('safeHoard'), 3);
    expect(restored.dragonSchoolAttemptTotal, 5);
    expect(restored.dragonSchoolFinalizedEarly, isTrue);
    expect(restored.dragonSchoolMentorLessons, 7);
  });

  test(
      'Dragon Academy permits passing early graduation after every lesson once',
      () async {
    final game = HouseholdProvider(
      random: Random(907),
      persistenceEnabled: false,
    )
      ..towerFloorRoomIds = List.filled(5, 'hearth')
      ..pet.stage = DragonStage.hatchling
      ..pet.firstEgg = false;
    final dragon = game.pet;
    final teammate = Pet(
      id: 'academy-teammate',
      stage: DragonStage.hatchling,
      firstEgg: false,
    );
    game.sanctuaryDragons.add(teammate);

    for (var index = 0; index < dragonSchoolGames.length; index++) {
      final lesson = dragonSchoolGames[index];
      final score = index < 5 ? lesson.silverScore : lesson.bronzeScore;
      final result = await game.completeDragonSchoolLesson(
        gameId: lesson.id,
        score: score,
        dragonIds: [
          dragon.id,
          if (lesson.minimumDragons > 1) teammate.id,
        ],
      );
      expect(result.accepted, isTrue, reason: lesson.id);
    }

    expect(dragon.dragonSchoolAttemptTotal, dragonSchoolLessonCount);
    expect(dragon.dragonSchoolStarTotal, 15);
    expect(dragon.canGraduateDragonSchoolEarly, isTrue);
    expect(dragon.dragonSchoolComplete, isFalse);
    expect(await game.graduateDragonFromAcademy(dragon.id), isTrue);
    expect(dragon.dragonSchoolComplete, isTrue);
    expect(dragon.dragonSchoolGraduated, isTrue);
    expect(dragon.dragonSchoolOutcome, DragonSchoolOutcome.graduate);
    expect(await game.graduateDragonFromAcademy(dragon.id), isFalse);

    final blocked = await game.completeDragonSchoolLesson(
      gameId: dragonSchoolGames.first.id,
      score: dragonSchoolGames.first.goldScore,
      dragonIds: [dragon.id],
    );
    expect(blocked.accepted, isFalse);
    game.dispose();
  });

  test('collection view and order preferences are included in saved state',
      () async {
    final game = HouseholdProvider(
      random: Random(908),
      persistenceEnabled: false,
    );
    await game.setMyDragonsCollectionPreferences(
      viewMode: 'compact',
      sortMode: 'rarity',
      descending: false,
    );
    await game.setEggInventoryCollectionPreferences(
      viewMode: 'list',
      sortMode: 'hatchTime',
      descending: false,
    );

    final state = game.exportState();
    expect(state['myDragonsViewMode'], 'compact');
    expect(state['myDragonsSortMode'], 'rarity');
    expect(state['myDragonsSortDescending'], isFalse);
    expect(state['eggInventoryViewMode'], 'list');
    expect(state['eggInventorySortMode'], 'hatchTime');
    expect(state['eggInventorySortDescending'], isFalse);
    final restored = HouseholdProvider(
      random: Random(909),
      persistenceEnabled: false,
    );
    expect(await restored.restoreCloudState(state), isTrue);
    expect(restored.myDragonsViewMode, 'compact');
    expect(restored.myDragonsSortMode, 'rarity');
    expect(restored.myDragonsSortDescending, isFalse);
    expect(restored.eggInventoryViewMode, 'list');
    expect(restored.eggInventorySortMode, 'hatchTime');
    expect(restored.eggInventorySortDescending, isFalse);
    restored.dispose();
    game.dispose();
  });

  test('Dragon Academy final outcomes and ranking use all thirty attempts', () {
    expect(
      dragonSchoolGames.map((lesson) => lesson.id).toSet(),
      dragonSchoolLessonIds,
    );
    final attempts = {
      for (final lesson in dragonSchoolGames)
        lesson.id: dragonSchoolAttemptsPerLesson,
    };
    final dropout = Pet(
      stage: DragonStage.hatchling,
      firstEgg: false,
      dragonSchoolAttempts: attempts,
      dragonSchoolStars: {
        for (final lesson in dragonSchoolGames) lesson.id: 1,
      },
    );
    final graduate = Pet(
      stage: DragonStage.hatchling,
      firstEgg: false,
      dragonSchoolAttempts: attempts,
      dragonSchoolStars: {
        for (var index = 0; index < dragonSchoolGames.length; index++)
          dragonSchoolGames[index].id: index < 5 ? 2 : 1,
      },
    );
    final valedictorian = Pet(
      stage: DragonStage.hatchling,
      firstEgg: false,
      dragonSchoolAttempts: attempts,
      dragonSchoolStars: {
        for (final lesson in dragonSchoolGames) lesson.id: 3,
      },
      dragonSchoolRecords: {
        for (final lesson in dragonSchoolGames) lesson.id: lesson.goldScore * 2,
      },
    );
    final honors = Pet(
      stage: DragonStage.hatchling,
      firstEgg: false,
      dragonSchoolAttempts: attempts,
      dragonSchoolStars: {
        for (var index = 0; index < dragonSchoolGames.length; index++)
          dragonSchoolGames[index].id: index == 0 ? 3 : 2,
      },
    );
    final highHonors = Pet(
      stage: DragonStage.hatchling,
      firstEgg: false,
      dragonSchoolAttempts: attempts,
      dragonSchoolStars: {
        for (var index = 0; index < dragonSchoolGames.length; index++)
          dragonSchoolGames[index].id: index < 7 ? 3 : 2,
      },
    );

    expect(dropout.dragonSchoolOutcome, DragonSchoolOutcome.dropout);
    expect(dropout.dragonSchoolGraduated, isFalse);
    expect(graduate.dragonSchoolOutcome, DragonSchoolOutcome.graduate);
    expect(graduate.dragonSchoolGraduated, isTrue);
    expect(honors.dragonSchoolOutcome, DragonSchoolOutcome.honorsGraduate);
    expect(highHonors.dragonSchoolOutcome, DragonSchoolOutcome.highHonors);
    expect(
        valedictorian.dragonSchoolOutcome, DragonSchoolOutcome.valedictorian);
    expect(valedictorian.dragonSchoolValedictorian, isTrue);
    expect(dragonSchoolAcademyScore(valedictorian),
        dragonSchoolMaximumAcademyScore);
  });

  test('the thirtieth attempt finalizes a dropout and its achievement',
      () async {
    final game = HouseholdProvider(
      random: Random(907),
      persistenceEnabled: false,
    )
      ..towerFloorRoomIds = List.filled(5, 'hearth')
      ..pet.stage = DragonStage.hatchling
      ..pet.firstEgg = false;
    for (final lesson in dragonSchoolGames) {
      game.pet.dragonSchoolAttempts[lesson.id] =
          lesson.id == 'runeRush' ? 2 : dragonSchoolAttemptsPerLesson;
      game.pet.dragonSchoolStars[lesson.id] = 1;
    }

    final result = await game.completeDragonSchoolLesson(
      gameId: 'runeRush',
      score: 0,
      dragonIds: [game.pet.id],
    );

    expect(result.accepted, isTrue);
    expect(result.finalizedDragonIds, contains(game.pet.id));
    expect(result.graduatedDragonIds, isEmpty);
    expect(game.pet.dragonSchoolOutcome, DragonSchoolOutcome.dropout);
    expect(game.achievementProgress('dragon_school_dropout'), 1);
    expect(game.achievementProgress('academy_graduate'), 0);
    game.dispose();
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

class _HighRandom implements Random {
  @override
  bool nextBool() => true;

  @override
  double nextDouble() => .75;

  @override
  int nextInt(int max) => max - 1;
}

class _DailyReturningRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => .05;

  @override
  int nextInt(int max) =>
      max == Duration.secondsPerDay ? const Duration(hours: 18).inSeconds : 0;
}
