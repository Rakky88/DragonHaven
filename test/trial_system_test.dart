import 'dart:math';

import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Trials begin with three random offers and a quarter-hour timer', () {
    final now = DateTime(2026, 8, 24, 10, 7, 8);
    final game = HouseholdProvider(random: Random(41), clock: () => now);

    expect(game.availableTrials, hasLength(3));
    expect(game.availableTrials.map((offer) => offer.kind),
        everyElement(isIn(TrialKind.values)));
    expect(
      game.trialRefreshRemaining(from: now),
      const Duration(minutes: 7, seconds: 52),
    );
  });

  test('dismissed Trial refills only at the next quarter-hour', () async {
    var now = DateTime(2026, 8, 24, 10, 7);
    final game = HouseholdProvider(random: Random(42), clock: () => now);
    final dismissed = game.availableTrials.first;

    await game.dismissTrial(dismissed.id);
    expect(game.availableTrials, hasLength(2));
    now = DateTime(2026, 8, 24, 10, 14, 59);
    expect(game.availableTrials, hasLength(2));
    now = DateTime(2026, 8, 24, 10, 15);
    expect(game.availableTrials, hasLength(3));
  });

  test('a Trial pays once and records dragon and account best scores',
      () async {
    final game = HouseholdProvider(random: Random(43))
      ..pet = Pet(
        id: 'trial-dragon',
        name: 'Moss',
        stage: DragonStage.hatchling,
        firstEgg: false,
        coins: 10,
        xp: 0,
      );
    game.availableTrials;
    game
      ..trialOffers = [
        TrialOffer(
          id: 'flight-reward-offer',
          kind: TrialKind.cavernFlight,
          appearedAt: DateTime.now(),
        ),
      ]
      ..trialRefilledAt = DateTime.now();
    final offer = game.availableTrials
        .firstWhere((item) => item.kind == TrialKind.cavernFlight);

    final result = await game.completeTrial(
      offerId: offer.id,
      dragonId: game.pet.id,
      score: 150,
    );

    expect(result?.reward.grade, TrialGrade.c);
    expect(result?.reward.chestTier, ChestTier.wooden);
    expect(result?.newDragonBest, isTrue);
    expect(game.pet.coins, 10);
    expect(game.pet.xp, 20);
    expect(game.pet.trainingFor(TrainingFocus.spirit), 2);
    expect(game.pet.trialBest(TrialKind.cavernFlight.name), 150);
    expect(game.accountTrialBest(TrialKind.cavernFlight), 150);
    expect(game.chestCount(ChestTier.wooden), 1);
    expect(game.availableTrials.any((item) => item.id == offer.id), isFalse);

    final duplicate = await game.completeTrial(
      offerId: offer.id,
      dragonId: game.pet.id,
      score: 999,
    );
    expect(duplicate, isNull);
    expect(game.pet.coins, 10);
    expect(game.pet.trialBest(TrialKind.cavernFlight.name), 150);
  });

  test('Trial score tiers and reward chest tables use performance', () {
    final flightBoundaries = <int, TrialGrade>{
      0: TrialGrade.d,
      149: TrialGrade.d,
      150: TrialGrade.c,
      349: TrialGrade.c,
      350: TrialGrade.b,
      649: TrialGrade.b,
      650: TrialGrade.a,
      999: TrialGrade.a,
      1000: TrialGrade.s,
      1499: TrialGrade.s,
      1500: TrialGrade.sPlus,
    };
    for (final entry in flightBoundaries.entries) {
      expect(
        trialGradeForScore(TrialKind.cavernFlight, entry.key),
        entry.value,
        reason: 'Cavern Flight ${entry.key}',
      );
    }

    final ruinBoundaries = <int, TrialGrade>{
      0: TrialGrade.d,
      899: TrialGrade.d,
      900: TrialGrade.c,
      2249: TrialGrade.c,
      2250: TrialGrade.b,
      3999: TrialGrade.b,
      4000: TrialGrade.a,
      6749: TrialGrade.a,
      6750: TrialGrade.s,
      8999: TrialGrade.s,
      9000: TrialGrade.sPlus,
    };
    for (final entry in ruinBoundaries.entries) {
      expect(
        trialGradeForScore(TrialKind.ruinBreaker, entry.key),
        entry.value,
        reason: 'Ruin Breaker ${entry.key}',
      );
    }
    expect(trialGradeForScore(TrialKind.runeweaver, 12), TrialGrade.s);

    expect(
      trialRewardForGrade(TrialGrade.b, .84).chestTier,
      ChestTier.wooden,
    );
    expect(
      trialRewardForGrade(TrialGrade.b, .85).chestTier,
      ChestTier.silver,
    );
    expect(
      trialRewardForGrade(TrialGrade.sPlus, .999).chestTier,
      ChestTier.mythical,
    );

    final sPlusRelic = trialRewardForGrade(
      TrialGrade.sPlus,
      .50,
      relicRoll: .009,
      relicChoice: 2,
    );
    expect(sPlusRelic.relic, MysticRelic.soulMirror);
    expect(
      trialRewardForGrade(
        TrialGrade.sPlus,
        .50,
        relicRoll: .01,
      ).relic,
      isNull,
    );
    expect(
      trialRewardForGrade(
        TrialGrade.s,
        .50,
        relicRoll: 0,
      ).relic,
      isNull,
    );
  });

  test('Trial rewards match every grade table without coins', () {
    final rewards = <TrialGrade, (int, int, ChestTier?)>{
      TrialGrade.d: (10, 1, null),
      TrialGrade.c: (20, 2, ChestTier.wooden),
      TrialGrade.b: (30, 3, ChestTier.wooden),
      TrialGrade.a: (40, 4, ChestTier.wooden),
      TrialGrade.s: (50, 5, ChestTier.silver),
      TrialGrade.sPlus: (69, 7, ChestTier.gold),
    };
    for (final entry in rewards.entries) {
      final reward = trialRewardForGrade(entry.key, 0);
      expect(reward.coins, 0, reason: entry.key.name);
      expect(reward.xp, entry.value.$1, reason: entry.key.name);
      expect(reward.statPoints, entry.value.$2, reason: entry.key.name);
      expect(reward.chestTier, entry.value.$3, reason: entry.key.name);
    }

    expect(
        trialRewardForGrade(TrialGrade.b, .9499).chestTier, ChestTier.silver);
    expect(trialRewardForGrade(TrialGrade.b, .95).chestTier, ChestTier.gold);
    expect(trialRewardForGrade(TrialGrade.a, .30).chestTier, ChestTier.silver);
    expect(trialRewardForGrade(TrialGrade.a, .80).chestTier, ChestTier.gold);
    expect(trialRewardForGrade(TrialGrade.s, .30).chestTier, ChestTier.gold);
    expect(trialRewardForGrade(TrialGrade.s, .99).chestTier, ChestTier.dragon);
    expect(
        trialRewardForGrade(TrialGrade.sPlus, .90).chestTier, ChestTier.dragon);
    expect(trialRewardForGrade(TrialGrade.sPlus, .99).chestTier,
        ChestTier.mythical);
  });

  test('dragon expertise applies only the requested subtle gameplay assists',
      () {
    expect(cavernFlightHitboxScale(0), 1);
    expect(cavernFlightHitboxScale(300), closeTo(.90, .0001));
    expect(ruinBreakerSuccessZoneScale(300), closeTo(1.15, .0001));
    expect(ruinBreakerPerfectZoneScale(300), closeTo(1.05, .0001));
    expect(runeweaverRuneDuration(0), const Duration(milliseconds: 500));
    expect(runeweaverRuneDuration(300), const Duration(milliseconds: 600));
  });

  test('Trial highscores and unplayed offers survive a restart', () async {
    final game = HouseholdProvider(random: Random(44))
      ..pet = Pet(
        id: 'persistent-trial-dragon',
        name: 'Rune',
        stage: DragonStage.hatchling,
        firstEgg: false,
      );
    game.availableTrials;
    game
      ..trialOffers = [
        TrialOffer(
          id: 'rune-persistence-offer',
          kind: TrialKind.runeweaver,
          appearedAt: DateTime.now(),
        ),
        TrialOffer(
          id: 'flight-persistence-offer',
          kind: TrialKind.cavernFlight,
          appearedAt: DateTime.now(),
        ),
        TrialOffer(
          id: 'ruin-persistence-offer',
          kind: TrialKind.ruinBreaker,
          appearedAt: DateTime.now(),
        ),
      ]
      ..trialRefilledAt = DateTime.now();
    final offer = game.availableTrials
        .firstWhere((item) => item.kind == TrialKind.runeweaver);
    await game.completeTrial(
      offerId: offer.id,
      dragonId: game.pet.id,
      score: 8,
    );

    final restored = await HouseholdProvider.loadFromStorage();
    expect(restored.pet.trialBest(TrialKind.runeweaver.name), 8);
    expect(restored.availableTrials, hasLength(2));
    expect(
      restored.availableTrials.any((item) => item.id == offer.id),
      isFalse,
    );
  });

  test('social showcase carries account and favorite-dragon Trial records', () {
    final game = HouseholdProvider(random: Random(45))
      ..pet = Pet(
        id: 'favorite-trial-dragon',
        name: 'Moss',
        stage: DragonStage.hatchling,
        firstEgg: false,
        favorite: true,
        trialHighScores: const {
          'cavernFlight': 148,
          'ruinBreaker': 900,
          'runeweaver': 7,
        },
      );
    game.sanctuaryDragons.add(Pet(
      id: 'record-trial-dragon',
      name: 'Flint',
      stage: DragonStage.wyrmling,
      firstEgg: false,
      trialHighScores: const {
        'cavernFlight': 222,
        'ruinBreaker': 600,
        'runeweaver': 12,
      },
    ));

    final showcase = OnlineInventorySnapshot.fromGame(game).toShowcaseJson();
    expect(showcase['trial_high_scores'], {
      'cavernFlight': 222,
      'ruinBreaker': 900,
      'runeweaver': 12,
    });
    expect(
      (showcase['favorite_dragon'] as Map)['trial_high_scores'],
      {
        'cavernFlight': 148,
        'ruinBreaker': 900,
        'runeweaver': 7,
      },
    );

    final profile = KeeperProfile.fromJson({
      'user_id': 'friend',
      'cavern_flight_best': 222,
      'ruin_breaker_best': 900,
      'runeweaver_best': 12,
      'favorite_dragon_id': 'favorite-trial-dragon',
      'favorite_dragon_cavern_flight_best': 148,
      'favorite_dragon_ruin_breaker_best': 900,
      'favorite_dragon_runeweaver_best': 7,
    });
    expect(profile.cavernFlightBest, 222);
    expect(profile.favoriteDragon?.runeweaverBest, 7);
  });
}
