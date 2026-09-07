import 'dart:math';

import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final now = DateTime.utc(2026, 9, 7, 12);
  HouseholdProvider game() => HouseholdProvider(
      persistenceEnabled: false, random: Random(187), clock: () => now)
    ..pet.stage = DragonStage.hatchling
    ..pet.firstEgg = false;

  Map<String, dynamic> rewards(HouseholdProvider game) {
    final save = game.exportState();
    return {
      for (final key in [
        'chestInventory',
        'specialChestInventory',
        'relicInventory',
        'untradeableRelicInventory',
        'chronoshardReductions',
        'eggStash',
        'ownedDragonEmoteIds',
        'ownedBadgeIds',
        'ownedTitleIds',
        'achievements',
        'trialStreakCount',
        'totalAdventuresCompleted',
        'appliedSeasonalPrizeIds',
      ])
        key: save[key],
      'coins': game.pet.coins,
      'gems': game.pet.gems,
      'xp': game.pet.xp,
      'training': game.pet.toJson()['training'],
      'trialBest': game.pet.trialBest(TrialKind.witchlightWard.name),
    };
  }

  test('production Halloween test Trial displays rewards but persists none',
      () async {
    final g = game();
    addTearDown(g.dispose);
    await g.redeemCode('HALLOWEENEVENT', keeperId: 'DH-OTHER123');
    final window = g.activeSpecialAdventureWindows.firstWhere(
        (window) => window.event.id == 'halloween_witchlight');
    g.trialRefilledAt = now;
    g.trialOffers = [
      TrialOffer(
          id: 'preview-trial',
          kind: TrialKind.witchlightWard,
          appearedAt: now,
          specialEventKey: window.key)
    ];
    final before = rewards(g);
    final result = await g.completeTrial(
        offerId: 'preview-trial', dragonId: g.pet.id, score: 4200);
    expect(result!.simulated, isTrue);
    expect(result.reward.xp, greaterThan(0));
    expect(rewards(g), before);
  });

  test(
      'production Halloween test adventure does not grant its displayed chest or progress',
      () async {
    final g = game();
    addTearDown(g.dispose);
    final event = specialAdventureEventById('halloween_witchlight')!;
    g.adventureRuns = [
      AdventureRun(
          id: 'preview-trip',
          adventureId: event.adventureId,
          dragonId: g.pet.id,
          startedAt: now.subtract(const Duration(days: 2)),
          endsAt: now,
          status: AdventureRunStatus.rewardReady,
          rewardTier: ChestTier.special,
          specialEventId: event.id,
          specialEventKey: '${event.id}:preview:test')
    ];
    g.pet.activeAdventureId = 'preview-trip';
    final before = rewards(g);
    expect(await g.claimAdventure('preview-trip'), ChestTier.special);
    expect(rewards(g), before);
    expect(g.pet.activeAdventureId, isNull);
    expect(g.adventureRuns, isEmpty);
  });

  test(
      'simulated online event adventure remains reward-free even when claimed twice',
      () async {
    final g = game();
    addTearDown(g.dispose);
    final event = specialAdventureEventById('valentine_two_heartlights')!;
    final before = rewards(g);
    for (var attempt = 0; attempt < 2; attempt++) {
      expect(
          await g.applyOnlineSeasonalPairReward(
              adventureId: 'preview-pair',
              eventId: event.id,
              dragonId: g.pet.id,
              xp: 999,
              might: 25,
              arcana: 25,
              spirit: 25,
              specialChestId: event.rewards.specialChestId!,
              simulated: true),
          isTrue);
    }
    expect(rewards(g), before);
  });
}
