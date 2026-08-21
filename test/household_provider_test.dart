import 'dart:convert';
import 'dart:math';

import 'package:dragon_haven/models/achievement.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/dragon_egg.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/house.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/sanctuary_activity.dart';
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
    expect(game.pet.incubationHours, 24);
    expect(game.onboardingComplete, isFalse);
    expect(game.musicEnabled, isTrue);
    expect(game.soundEffectsEnabled, isTrue);
    expect(game.totalChestCount, 0);
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

  test('daily activity limits reset on a new calendar day', () async {
    var now = DateTime.utc(2026, 8, 1, 10);
    final game = HouseholdProvider(
      random: Random(2),
      clock: () => now,
    );
    final activity = sanctuaryActivities.first;
    expect(game.activityUsesRemaining(activity), 1);
    expect(await game.performActivity(activity), isNotNull);
    expect(await game.performActivity(activity), isNull);

    now = now.add(const Duration(days: 1));
    await game.refreshForCurrentDate();
    expect(game.activityUsesRemaining(activity), 1);
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

  test('Special Adventures only appear from an active special source', () {
    final game = HouseholdProvider(random: Random(13));
    expect(game.adventuresFor(AdventureKind.special), isEmpty);
    expect(game.adventuresFor(AdventureKind.group), hasLength(1));
  });

  test('a chest can only be opened when it exists', () async {
    final game = HouseholdProvider(random: Random(3));
    game.chestInventory[ChestTier.wooden] = 1;
    final beforeCoins = game.pet.coins;
    final reward = await game.openChest(ChestTier.wooden);

    expect(reward, isNotNull);
    expect(game.pet.coins, beforeCoins + reward!.coins);
    expect(game.totalChestsOpened, 1);
    expect(game.chestCount(ChestTier.wooden), 0);
    expect(await game.openChest(ChestTier.wooden), isNull);
  });

  test('activating a stash egg archives the dragon and keeps currencies',
      () async {
    final game = HouseholdProvider(random: Random(4));
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
    expect(game.sanctuaryDragons.single.name, 'Nimbus');
    expect(game.pet.id, 'later-egg');
    expect(game.pet.lineageId, 'quietstar');
    expect(game.pet.prismatic, isTrue);
    expect(game.pet.firstEgg, isFalse);
    expect(game.pet.coins, 444);
    expect(game.pet.gems, 19);
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

  test('the retired map id migrates without losing owned furniture', () async {
    final pet = Pet(hatchSeed: 9, lineageId: 'quietstar');
    SharedPreferences.setMockInitialValues({
      'chore_quest_state_v2': jsonEncode({
        'pet': pet.toJson(),
        'ownedItemIds': ['quest_map'],
        'equippedItemIds': {'wall': 'quest_map'},
        'unlockedRoomIds': ['nest'],
        'activeRoomId': 'nest',
        'housePlacements': [
          {
            'itemId': 'quest_map',
            'roomId': 'nest',
            'x': .4,
            'y': .3,
            'scale': 1,
          }
        ],
      }),
    });

    final restored = await HouseholdProvider.loadFromStorage();
    expect(restored.ownedItemIds, contains('spire_map'));
    expect(restored.equippedItemIds[ItemSlot.wall], 'spire_map');
    expect(restored.housePlacements.single.itemId, 'spire_map');
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
