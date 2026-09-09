import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/game_domain_probe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  String dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  Future<void> complete(HouseholdProvider game, DateTime now, String id) async {
    game.trialRefilledAt = now;
    game.trialOffers = [
      TrialOffer(id: id, kind: TrialKind.cavernFlight, appearedAt: now)
    ];
    expect(
        await game.completeTrial(offerId: id, dragonId: game.pet.id, score: 10),
        isNotNull);
  }

  HouseholdProvider gameAt(DateTime Function() clock) {
    final game = HouseholdProvider(
        random: Random(23), clock: clock, persistenceEnabled: false);
    game.pet
      ..stage = DragonStage.hatchling
      ..firstEgg = false;
    return game;
  }

  test('a backward date cannot refill long offers, even after a dismissal',
      () async {
    var now = DateTime(2026, 9, 8, 12);
    final game = gameAt(() => now);
    addTearDown(game.dispose);
    final offers = game.adventuresFor(AdventureKind.long).toList();
    for (final offer in offers) {
      await game.dismissAdventure(offer);
    }
    expect(game.adventuresFor(AdventureKind.long), isEmpty);
    now = DateTime(2026, 9, 7, 12);
    expect(game.adventuresFor(AdventureKind.long), isEmpty);
    await game.dismissAdventure(offers.first);
    expect(game.longAdventureRefillDay, '2026-09-08');
    now = DateTime(2026, 9, 8, 23, 59);
    expect(game.adventuresFor(AdventureKind.long), isEmpty);
    now = DateTime(2026, 9, 9);
    expect(game.adventuresFor(AdventureKind.long), hasLength(3));
  });

  test('backward and repeated days preserve streak credit and ready rewards',
      () async {
    var now = DateTime(2026, 9, 1, 12);
    final game = gameAt(() => now);
    addTearDown(game.dispose);
    for (var day = 1; day <= 7; day++) {
      now = DateTime(2026, 9, day, 12);
      await complete(game, now, 'forward-$day');
    }
    expect(game.trialStreakRewardReady, isTrue);
    final keys = {...game.trialStreakCreditedDayKeys};
    now = DateTime(2026, 9, 6, 12);
    await complete(game, now, 'backward');
    expect(game.trialStreakCreditedDayKeys, keys);
    expect(game.trialStreakCarryDayKey, isEmpty);
    expect(game.trialStreakLastCompletionDayKey, '2026-09-07');
    expect(await game.claimTrialStreakReward(), isNotNull);
    expect(await game.claimTrialStreakReward(), isNull);
    now = DateTime(2026, 9, 7, 23, 59);
    await complete(game, now, 'repeated');
    expect(game.trialStreakCount, 0);
    now = DateTime(2026, 9, 8);
    await complete(game, now, 'new-day');
    expect(game.trialStreakCount, 1);
  });

  test(
      'seven calendar days stay consecutive across both US and European DST transitions',
      () async {
    // Linux CI runs this file separately in both regions, not only UTC. Check
    // that the process actually loaded DST rules before testing date labels.
    if (const ['Europe/Amsterdam', 'America/New_York']
        .contains(Platform.environment['TZ'])) {
      expect(DateTime(2026, 3, 1).timeZoneOffset,
          isNot(DateTime(2026, 4, 1).timeZoneOffset));
    }
    for (final start in [
      DateTime(2026, 3, 6),
      DateTime(2026, 3, 27),
      DateTime(2026, 10, 23),
      DateTime(2026, 10, 30)
    ]) {
      var now = start;
      final game = gameAt(() => now);
      try {
        for (var i = 0; i < 7; i++) {
          now = DateTime(start.year, start.month, start.day + i, 12);
          await complete(game, now, 'calendar-$i');
          expect(game.trialStreakCount, i + 1);
        }
        expect(game.trialStreakRewardReady, isTrue);
        expect(game.trialStreakCreditedDayKeys, {
          for (var i = 0; i < 7; i++)
            dayKey(DateTime(start.year, start.month, start.day + i))
        });
      } finally {
        game.dispose();
      }
    }
  });

  test(
      'server refresh derives one UTC day from the database instant regardless of its representation',
      () async {
    final fixture =
        (await runGameDomainProbe())['state'] as Map<String, dynamic>;
    fixture['longAdventureRefillDay'] = '';
    final now = DateTime.utc(2026, 9, 8, 0, 30);
    Future<Map<String, dynamic>> refresh(DateTime at) =>
        GameCommandEngine.execute(
            state: jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>,
            action: 'refresh',
            payload: {},
            secretSeed: 'ab' * 32,
            now: at,
            keeperId: '11111111-1111-4111-8111-111111111111');
    final utc = await refresh(now);
    final local = await refresh(now.toLocal());
    expect(utc['state']['longAdventureRefillDay'], '2026-09-08');
    expect(local['state'], utc['state']);
    // The command protocol continues to reject client time/day parameters.
    await expectLater(
        GameCommandEngine.execute(
            state: fixture,
            action: 'refresh',
            payload: {'now': '2099-01-01'},
            secretSeed: 'ab' * 32,
            now: now,
            keeperId: '11111111-1111-4111-8111-111111111111'),
        throwsA(isA<GameCommandException>()
            .having((e) => e.code, 'code', 'invalid_command')));
  });
  test(
      'daily returning-dragon rolls cannot be retried by revisiting older dates',
      () {
    var now = DateTime(2026, 9, 8, 12);
    final random = _CountingRandom();
    final game = HouseholdProvider(
        random: random, clock: () => now, persistenceEnabled: false);
    addTearDown(game.dispose);
    game.releasedDragons.add(Pet(
        id: 'released-calendar',
        stage: DragonStage.hatchling,
        firstEgg: false));
    game.processDailyReturningDragonForTesting();
    final draws = random.draws;
    expect(game.lastReturningDayKey, '2026-09-08');
    now = DateTime(2026, 9, 7, 12);
    game.processDailyReturningDragonForTesting();
    now = DateTime(2026, 9, 8, 23, 59);
    game.processDailyReturningDragonForTesting();
    expect(random.draws, draws);
    expect(game.lastReturningDayKey, '2026-09-08');
    now = DateTime(2026, 9, 9);
    game.processDailyReturningDragonForTesting();
    expect(random.draws, draws + 1);
    expect(game.lastReturningDayKey, '2026-09-09');
  });
}

class _CountingRandom implements Random {
  int draws = 0;
  @override
  double nextDouble() {
    draws++;
    return .99;
  }

  @override
  int nextInt(int max) {
    draws++;
    return max - 1;
  }

  @override
  bool nextBool() {
    draws++;
    return true;
  }
}
