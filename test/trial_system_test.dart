import 'dart:math';

import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/dragon_emote.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
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

  test('using a Trial schedules one full-board notification at the right slot',
      () async {
    const channel = MethodChannel('nl.dragonhaven.app/notifications');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    var now = DateTime(2036, 8, 26, 10, 7);
    final game = HouseholdProvider(random: Random(48), clock: () => now);
    final offer = game.availableTrials.first;

    await game.dismissTrial(offer.id);

    final scheduled = calls.where((call) => call.method == 'schedule').last;
    expect((scheduled.arguments as Map)['id'], 'trials-full');
    expect(
      (scheduled.arguments as Map)['at'],
      DateTime(2036, 8, 26, 10, 15).millisecondsSinceEpoch,
    );
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
        training: const {'spirit': 5},
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
      score: 249,
    );

    expect(result?.baseScore, 249);
    expect(result?.score, 250);
    expect(result?.expertise, 5);
    expect(result?.expertiseMultiplier, closeTo(1.005, .000001));
    expect(result?.reward.grade, TrialGrade.c);
    expect(result?.reward.chestTier, ChestTier.wooden);
    expect(result?.newDragonBest, isTrue);
    expect(game.pet.coins, 10);
    expect(game.pet.xp, 20);
    expect(game.pet.trainingFor(TrainingFocus.spirit), 7);
    expect(game.pet.trialBest(TrialKind.cavernFlight.name), 250);
    expect(game.accountTrialBest(TrialKind.cavernFlight), 250);
    expect(game.chestCount(ChestTier.wooden), 1);
    expect(game.availableTrials.any((item) => item.id == offer.id), isFalse);

    final duplicate = await game.completeTrial(
      offerId: offer.id,
      dragonId: game.pet.id,
      score: 999,
    );
    expect(duplicate, isNull);
    expect(game.pet.coins, 10);
    expect(game.pet.trialBest(TrialKind.cavernFlight.name), 250);
  });

  test('Trial score tiers and reward chest tables use performance', () {
    final flightBoundaries = <int, TrialGrade>{
      0: TrialGrade.d,
      249: TrialGrade.d,
      250: TrialGrade.c,
      599: TrialGrade.c,
      600: TrialGrade.b,
      1099: TrialGrade.b,
      1100: TrialGrade.a,
      1699: TrialGrade.a,
      1700: TrialGrade.s,
      2499: TrialGrade.s,
      2500: TrialGrade.sPlus,
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
    expect(trialGradeForScore(TrialKind.runeweaver, 14), TrialGrade.s);
    expect(trialGradeForScore(TrialKind.runeweaver, 15), TrialGrade.sPlus);
    expect(trialGradeForScore(TrialKind.runeweaver, 999), TrialGrade.sPlus);

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

  test('Trial expertise uses an exact three-decimal score multiplier', () {
    expect(trialExpertiseMultiplier(0), 1);
    expect(trialExpertiseMultiplier(5), closeTo(1.005, .000001));
    expect(trialExpertiseMultiplier(300), closeTo(1.300, .000001));
    expect(trialExpertiseMultiplier(400), closeTo(1.400, .000001));
    expect(trialScoreWithExpertise(1000, 5), 1005);
    expect(trialScoreWithExpertise(100, 5), 101);
    expect(trialScoreWithExpertise(249, 5), 250);
    expect(trialScoreWithExpertise(1000, -5), 1000);
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

  test('only S+ Trials can win unique Trial emotes', () async {
    final now = DateTime(2026, 9, 2, 12);
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: _ZeroRandom(),
      clock: () => now,
    )
      ..pet = Pet(
        id: 'emote-trial-dragon',
        stage: DragonStage.hatchling,
        firstEgg: false,
      )
      ..trialRefilledAt = now
      ..trialOffers = [
        for (var index = 0; index < 3; index++)
          TrialOffer(
            id: 'emote-offer-$index',
            kind: TrialKind.runeweaver,
            appearedAt: now,
          ),
      ];

    final first = await game.completeTrial(
      offerId: 'emote-offer-0',
      dragonId: game.pet.id,
      score: 15,
    );
    final second = await game.completeTrial(
      offerId: 'emote-offer-1',
      dragonId: game.pet.id,
      score: 15,
    );
    final sRank = await game.completeTrial(
      offerId: 'emote-offer-2',
      dragonId: game.pet.id,
      score: 14,
    );

    expect(first?.reward.emote, isNotNull);
    expect(second?.reward.emote, isNotNull);
    expect(first!.reward.emote!.id, isNot(second!.reward.emote!.id));
    expect(sRank?.reward.emote, isNull);
    expect(
      game.ownedDragonEmoteIds.every(
        (id) => dragonEmoteById(id)?.source == DragonEmoteSource.trial,
      ),
      isTrue,
    );
  });

  test('each Trial S+ rank unlocks its dedicated achievement', () async {
    final now = DateTime(2026, 8, 26, 10);
    final game = HouseholdProvider(random: Random(47), clock: () => now)
      ..pet = Pet(
        id: 's-plus-dragon',
        name: 'Astra',
        stage: DragonStage.hatchling,
        firstEgg: false,
      )
      ..trialOffers = [
        TrialOffer(
          id: 's-plus-might',
          kind: TrialKind.ruinBreaker,
          appearedAt: now,
        ),
        TrialOffer(
          id: 's-plus-spirit',
          kind: TrialKind.cavernFlight,
          appearedAt: now,
        ),
        TrialOffer(
          id: 's-plus-arcana',
          kind: TrialKind.runeweaver,
          appearedAt: now,
        ),
      ]
      ..trialRefilledAt = now;

    await game.completeTrial(
      offerId: 's-plus-might',
      dragonId: game.pet.id,
      score: 9000,
    );
    await game.completeTrial(
      offerId: 's-plus-spirit',
      dragonId: game.pet.id,
      score: 2500,
    );
    await game.completeTrial(
      offerId: 's-plus-arcana',
      dragonId: game.pet.id,
      score: 15,
    );

    expect(game.unlockedAchievementIds, contains('trial_might_s_plus'));
    expect(game.unlockedAchievementIds, contains('trial_spirit_s_plus'));
    expect(game.unlockedAchievementIds, contains('trial_arcana_s_plus'));
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
    expect(showcase['dragon_count'], 2);
    expect(showcase['achievement_count'], 0);
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
      'achievement_count': 19,
      'dragon_count': 7,
      'favorite_dragon_id': 'favorite-trial-dragon',
      'favorite_dragon_cavern_flight_best': 148,
      'favorite_dragon_ruin_breaker_best': 900,
      'favorite_dragon_runeweaver_best': 7,
    });
    expect(profile.cavernFlightBest, 222);
    expect(profile.achievementCount, 19);
    expect(profile.dragonCount, 7);
    expect(profile.favoriteDragon?.runeweaverBest, 7);
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
