import 'dart:convert';
import 'dart:math';

import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/domain/game_public_projection.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const owner = '11111111-1111-4111-8111-111111111111';
  late DateTime now;
  late HouseholdProvider game;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime.utc(2026, 9, 20, 12);
    game = HouseholdProvider(
        persistenceEnabled: false, random: Random(17), clock: () => now);
    game.pet = Pet(
        id: 'budget-dragon',
        hatchSeed: 42,
        dragonSpark: 0,
        stage: DragonStage.ascended,
        evolutionPath: 'mastery',
        xp: 3400,
        favorite: true,
        firstEgg: false,
        acquiredAt: now,
        stageStartedAt: now,
        needsUpdatedAt: now);
  });
  tearDown(() => game.dispose());

  test('exactly half each regular catalog retrains, both cost directions occur',
      () {
    for (final catalog in [
      AdventureCatalog.mini,
      AdventureCatalog.short,
      AdventureCatalog.long
    ]) {
      final altered = catalog.where((a) => a.expertiseCost > 0).toList();
      expect(altered.length * 2, catalog.length);
      for (final a in altered) {
        expect(
            a.expertiseRewards.values.fold(0, (a, b) => a + b), a.statPoints);
        expect(a.expertiseCostFocus, isNot(a.focus));
        expect(a.expertiseRewards[a.focus], greaterThan(a.statPoints));
      }
      for (final focus in TrainingFocus.values) {
        expect(
            altered
                .where((a) => a.focus == focus)
                .map((a) => a.expertiseCostFocus)
                .toSet(),
            TrainingFocus.values.where((f) => f != focus).toSet());
      }
    }
    expect(AdventureCatalog.group.every((a) => a.expertiseCost == 0), isTrue);
  });

  test(
      'full dragon pays before gains; no negative stat, fixed Mastery, one claim',
      () async {
    final a = AdventureCatalog.mini.firstWhere((a) => a.expertiseCost > 0);
    game.adventureOptionIds[AdventureKind.mini] = [a.id];
    game.pet.training[a.focus.name] = 999;
    expect(
        await game.startAdventure(a), AdventureStartResult.requirementsNotMet);
    expect(game.adventureRuns, isEmpty);
    game.pet.training[a.expertiseCostFocus!.name] = 1;
    expect(game.pet.expertiseMaxed, isTrue);
    expect(await game.startAdventure(a), AdventureStartResult.started);
    final run = game.adventureRuns.single;
    expect(run.retraining, isTrue);
    expect(AdventureRun.fromJson(run.toJson()).retraining, isTrue);
    now = run.endsAt.add(const Duration(seconds: 1));
    expect(await game.claimAdventure(run.id), isNotNull);
    expect(game.pet.trainingFor(a.expertiseCostFocus!), 0);
    expect(game.pet.trainingFor(a.focus), 1000);
    expect(game.pet.totalTraining, 1000);
    expect(game.pet.isMastery, isTrue);
    expect(await game.claimAdventure(run.id), isNull);
  });

  test('adventures started on an older app retain their positive-only reward',
      () async {
    final a = AdventureCatalog.long.firstWhere((a) => a.expertiseCost > 0);
    final run = AdventureRun.fromJson({
      'id': 'legacy-run',
      'adventureId': a.id,
      'dragonId': game.pet.id,
      'startedAt': now.subtract(const Duration(days: 7)).toIso8601String(),
      'endsAt': now.subtract(const Duration(seconds: 1)).toIso8601String(),
      'status': 'running',
      'rewardTier': 'gold',
    });
    game.adventureRuns.add(run);
    game.pet.activeAdventureId = run.id;
    expect(await game.claimAdventure(run.id), isNotNull);
    expect(game.pet.trainingFor(a.expertiseCostFocus!), 0);
    expect(game.pet.trainingFor(a.focus), a.statPoints);
  });

  test('Spark is absent from public facts until one Astrolabe is consumed',
      () async {
    game.pet = Pet.fromJson(game.pet.toJson()..['dragonSpark'] = 37);
    game.relicInventory[MysticRelic.sparkAstrolabe] = 2;
    var state = game.exportState();
    Map<String, dynamic> project() =>
        GamePublicProjection.project(state: state, ownerId: owner, now: now);
    expect(project()['dragons'].single['dragonSpark'], isNull);
    expect(jsonEncode(project()), isNot(contains('dragonSparkKnown')));
    final result = await GameCommandEngine.execute(
        state: state,
        action: 'use_relic',
        payload: {'relic': 'sparkAstrolabe', 'dragonId': game.pet.id},
        secretSeed: 'ab' * 32,
        now: now,
        keeperId: owner);
    state = result['state'] as Map<String, dynamic>;
    expect(project()['dragons'].single['dragonSpark'], 37);
    expect(state['relicInventory']['sparkAstrolabe'], 1);
    final retry = await GameCommandEngine.execute(
        state: state,
        action: 'use_relic',
        payload: {'relic': 'sparkAstrolabe', 'dragonId': game.pet.id},
        secretSeed: 'cd' * 32,
        now: now,
        keeperId: owner);
    expect(retry['state']['relicInventory']['sparkAstrolabe'], 1);
    expect(retry['state']['pet']['dragonSpark'], 37);
  });

  test(
      'Astrolabe has brooch rarity, repeats as a consumable and only S+ drops it',
      () {
    final r = MysticRelic.sparkAstrolabe;
    final pool = mysticRelicDropPool();
    expect(r.dropWeight, MysticRelic.twinstarBrooch.dropWeight);
    expect(r.isShopAvailable, isFalse);
    expect(r.isConsumable, isTrue);
    expect(r.isEquipable, isFalse);
    expect(r.isAlwaysUntradeable, isTrue);
    final slot = pool.indexOf(r);
    expect(slot, greaterThanOrEqualTo(0));
    for (final grade in TrialGrade.values) {
      expect(
          trialRewardForGrade(grade, 0, relicRoll: 0, relicChoice: slot).relic,
          grade == TrialGrade.sPlus ? r : null);
    }
    expect(
        mysticRelicDropPool(
            excluded: MysticRelic.values.where((r) => r.isEquipable).toSet()),
        contains(r));
  });
}
