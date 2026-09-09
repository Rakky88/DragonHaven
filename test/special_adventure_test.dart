import 'dart:math';

import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('birthday relic surprise includes all four configured relics', () {
    final rewards = specialAdventureEventById('golden_wings_birthday')!.rewards;
    expect(
      rewards.randomRelicPool,
      containsAll(<MysticRelic>[
        MysticRelic.moralPrism,
        MysticRelic.orderCompass,
        MysticRelic.soulMirror,
        MysticRelic.astralLens,
      ]),
    );
    expect(
      rewards.randomRelicPool,
      hasLength(4),
    );
    expect(rewards.expertiseRewards, const {
      TrainingFocus.might: 25,
      TrainingFocus.spirit: 25,
      TrainingFocus.arcana: 25,
    });
  });

  test('launch and yearly birthday windows use Europe/Amsterdam boundaries',
      () {
    expect(specialAdventureWindowsAt(DateTime.utc(2026, 8, 31, 21, 59, 59)),
        isEmpty);
    expect(
        specialAdventureWindowsAt(DateTime.utc(2026, 8, 31, 22)), hasLength(1));
    expect(specialAdventureWindowsAt(DateTime.utc(2026, 9, 2, 21, 59, 59)),
        hasLength(1));
    expect(specialAdventureWindowsAt(DateTime.utc(2026, 9, 2, 22)), isEmpty);

    final birthday =
        specialAdventureWindowsAt(DateTime.utc(2027, 5, 12, 22)).single;
    expect(birthday.key, 'golden_wings_birthday:year:2027');
    expect(birthday.endsAt, DateTime.utc(2027, 5, 13, 22));
  });

  test('event can start once per instance and remains active after expiry',
      () async {
    var now = DateTime.utc(2026, 8, 31, 22);
    final game = HouseholdProvider(
      persistenceEnabled: false,
      random: Random(269),
      clock: () => now,
    );
    game.pet
      ..stage = DragonStage.hatchling
      ..training.addAll({'might': 24, 'arcana': 24, 'spirit': 24});

    final adventure = game.adventuresFor(AdventureKind.special).single;
    expect(adventure.id, AdventureCatalog.goldenWingsBirthday.id);
    expect(
      await game.startAdventure(adventure, dragonId: game.pet.id),
      AdventureStartResult.started,
    );
    expect(game.adventureRuns.single.endsAt, now.add(const Duration(days: 7)));
    expect(game.adventuresFor(AdventureKind.special), isEmpty);

    now = DateTime.utc(2026, 9, 3);
    expect(game.adventureRuns, hasLength(1));
    expect(
      game.exportState()['startedSeasonalSpecialEventKeys'],
      contains('golden_wings_birthday:launch:2026'),
    );
  });

  test('claim grants bundle and Special Chest yields exact egg contents',
      () async {
    var now = DateTime.utc(2026, 8, 31, 22);
    final game = HouseholdProvider(
      persistenceEnabled: false,
      random: Random(513),
      clock: () => now,
    );
    game.pet.stage = DragonStage.hatchling;
    game.pet.training.addAll({
      TrainingFocus.might.name: 40,
      TrainingFocus.spirit.name: 50,
      TrainingFocus.arcana.name: 60,
    });
    final adventure = game.adventuresFor(AdventureKind.special).single;
    await game.startAdventure(adventure, dragonId: game.pet.id);
    now = game.adventureRuns.single.endsAt;

    expect(await game.claimAdventure(game.adventureRuns.single.id),
        ChestTier.special);
    expect(game.chestCount(ChestTier.special), 1);
    expect(game.chestCount(ChestTier.music), 1);
    expect(game.totalRelicCount, 1);
    expect(game.pet.trainingFor(TrainingFocus.might), 65);
    expect(game.pet.trainingFor(TrainingFocus.spirit), 75);
    expect(game.pet.trainingFor(TrainingFocus.arcana), 85);

    final coinsBefore = game.pet.coins;
    final gemsBefore = game.pet.gems;
    final reward = await game.openChest(ChestTier.special);
    expect(reward?.coins, 269);
    expect(reward?.gems, 10);
    expect(reward?.specialEgg, isTrue);
    expect(game.pet.coins, coinsBefore + 269);
    expect(game.pet.gems, gemsBefore + 10);
    final egg = game.eggStash.single;
    expect(egg.lineageId, 'cluckatrice');
    expect(egg.incubationMinutes, 21 * 60);
    expect(egg.isSpecialEgg, isTrue);
    expect(game.eggHintForEgg(egg), contains('truly special'));

    await game.activateEgg(egg.id);
    now = now.add(const Duration(hours: 21));
    expect(await game.hatchActiveDragon(), isTrue);
    expect(game.pet.lineageId, 'cluckatrice');
    expect(game.unlockedAchievementIds, contains('winner_chicken_dinner'));
  });

  test('ordinary chest rolls never include the secret event lineage', () async {
    final game = HouseholdProvider(
      persistenceEnabled: false,
      random: Random(42),
    );
    for (var index = 0; index < 300; index++) {
      game.chestInventory[ChestTier.mythical] = 1;
      await game.openChest(ChestTier.mythical);
    }
    expect(game.eggStash.any((egg) => egg.lineage.secret), isFalse);
  });

  for (final (eventId, date, family, hours, achievement) in [
    (
      'sunwake_summer_sea',
      DateTime.utc(2027, 7, 19, 22),
      'solmanta',
      20,
      'light_across_the_lagoon'
    ),
    (
      'harvestmoon_moonlit_orchard',
      DateTime.utc(2027, 9, 6, 22),
      'ciderhorn',
      18,
      'beneath_the_harvest_moon'
    ),
  ]) {
    test('$family adventure survives event end and grants its own egg once',
        () async {
      var now = date;
      final game = HouseholdProvider(
          persistenceEnabled: false, random: Random(513), clock: () => now);
      addTearDown(game.dispose);
      game.pet.stage = DragonStage.hatchling;
      game.pet.training.addAll({'might': 100, 'arcana': 100, 'spirit': 100});
      final offer = game.adventuresFor(AdventureKind.special).single;
      expect(offer.id, 'special_$eventId');
      await game.startAdventure(offer, dragonId: game.pet.id);
      final run = game.adventureRuns.single;
      expect(run.endsAt.difference(now), const Duration(hours: 24));
      now = now.add(const Duration(days: 8));
      expect(await game.claimAdventure(run.id), ChestTier.special);
      expect(await game.claimAdventure(run.id), isNull);
      expect(game.pet.trainingFor(TrainingFocus.might), 110);
      final reward = await game.openChest(ChestTier.special);
      expect(reward!.coins, 300);
      expect(reward.gems, 12);
      expect(reward.specialEgg, true);
      expect(await game.openChest(ChestTier.special), isNull);
      final egg = game.eggStash.single;
      expect(egg.lineageId, family);
      expect(egg.incubationMinutes, hours * 60);
      expect(egg.isSpecialEgg, true);
      expect(Pet.fromJson(egg.toJson()).lineageId, family);
      await game.activateEgg(egg.id);
      now = now.add(Duration(hours: hours));
      expect(await game.hatchActiveDragon(), true);
      expect(game.pet.lineageId, family);
      expect(game.unlockedAchievementIds, contains(achievement));
    });
  }
}
