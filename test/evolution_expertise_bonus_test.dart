import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 24, 12);

  Future<Map<String, dynamic>> evolveThroughServer(Pet dragon) async {
    final game = HouseholdProvider(
      persistenceEnabled: false,
      clock: () => now,
    )..pet = dragon;
    final state = game.exportState();
    game.dispose();
    return GameCommandEngine.execute(
      state: state,
      action: 'evolve_dragon',
      payload: {'dragonId': dragon.id},
      secretSeed: sha256.convert(utf8.encode(dragon.id)).toString(),
      now: now,
      keeperId: '11111111-1111-4111-8111-111111111111',
    );
  }

  test('specialist Ascension gifts ten matching Expertise above the old cap',
      () async {
    final result = await evolveThroughServer(Pet(
      id: 'might-specialist',
      stage: DragonStage.wyrmling,
      xp: Pet.ascendedXp,
      dragonSpark: 0,
      firstEgg: false,
      favorite: true,
      acquiredAt: now,
      stageStartedAt: now,
      needsUpdatedAt: now,
      training: const {'might': 200, 'arcana': 60, 'spirit': 40},
    ));

    expect(result['result'], isTrue);
    final saved = Map<String, dynamic>.from(result['state']['pet'] as Map);
    expect(saved['stage'], 'ascended');
    expect(saved['evolutionPath'], 'might');
    expect(saved['training'], {'might': 210, 'arcana': 60, 'spirit': 40});
    expect(saved['ascensionExpertiseGiftGranted'], isTrue);
    final restored = Pet.fromJson(saved);
    expect(restored.maximumTotalExpertise, ordinaryExpertiseBudget + 10);
    expect(restored.remainingExpertise,
        ordinaryExpertiseBudget + 10 - restored.totalTraining);

    final retry = await GameCommandEngine.execute(
      state: Map<String, dynamic>.from(result['state'] as Map),
      action: 'evolve_dragon',
      payload: const {'dragonId': 'might-specialist'},
      secretSeed: 'ab' * 32,
      now: now,
      keeperId: '11111111-1111-4111-8111-111111111111',
    );
    expect(retry['result'], isFalse);
    expect(retry['state']['pet']['training'], saved['training']);
  });

  test('a full specialist receives ten points beyond the previous maximum', () {
    final dragon = Pet(
      id: 'full-specialist',
      stage: DragonStage.wyrmling,
      xp: Pet.ascendedXp,
      dragonSpark: 0,
      training: const {'might': 950, 'arcana': 0, 'spirit': 0},
    );
    expect(dragon.expertiseMaximum(TrainingFocus.might), 950);

    dragon.evolve(now);

    expect(dragon.trainingFor(TrainingFocus.might), 960);
    expect(dragon.expertiseMaximum(TrainingFocus.might), 960);
    expect(dragon.expertiseMaxed, isTrue);
  });

  test('Mastery Ascension gifts five Expertise in all three paths', () async {
    final result = await evolveThroughServer(Pet(
      id: 'mastery-dragon',
      stage: DragonStage.wyrmling,
      xp: Pet.ascendedXp,
      dragonSpark: 0,
      firstEgg: false,
      favorite: true,
      acquiredAt: now,
      stageStartedAt: now,
      needsUpdatedAt: now,
      training: const {'might': 100, 'arcana': 100, 'spirit': 100},
    ));

    final saved = Map<String, dynamic>.from(result['state']['pet'] as Map);
    expect(saved['evolutionPath'], 'mastery');
    expect(saved['training'], {'might': 105, 'arcana': 105, 'spirit': 105});
    final restored = Pet.fromJson(saved);
    expect(
      restored.maximumTotalExpertise,
      ordinaryExpertiseBudget +
          masteryExpertiseBonus +
          masteryAscensionExpertiseGiftTotal,
    );
  });

  test('legacy final forms receive the gift exactly once on upgrade', () {
    final specialistJson = <String, dynamic>{
      'id': 'legacy-specialist',
      'stage': 'ascended',
      'evolutionPath': 'arcana',
      'hatchSeed': 17,
      'dragonSpark': 0,
      'training': {'might': 40, 'arcana': 220, 'spirit': 40},
    };
    final specialist = Pet.fromJson(specialistJson);
    expect(specialist.training, {'might': 40, 'arcana': 230, 'spirit': 40});
    expect(specialist.ascensionExpertiseGiftGranted, isTrue);
    expect(Pet.fromJson(specialist.toJson()).training, specialist.training);

    final mastery = Pet.fromJson({
      'id': 'legacy-mastery',
      'stage': 'ascended',
      'evolutionPath': 'mastery',
      'hatchSeed': 18,
      'dragonSpark': 0,
      'training': {'might': 100, 'arcana': 100, 'spirit': 100},
    });
    expect(mastery.training, {'might': 105, 'arcana': 105, 'spirit': 105});
    expect(Pet.fromJson(mastery.toJson()).training, mastery.training);

    final oldPerFocusMaximum = Pet.fromJson({
      'id': 'legacy-mastery-at-old-cap',
      'stage': 'ascended',
      'evolutionPath': 'mastery',
      'hatchSeed': 19,
      'dragonSpark': 0,
      'training': {'might': 350, 'arcana': 350, 'spirit': 350},
    });
    expect(oldPerFocusMaximum.training,
        {'might': 355, 'arcana': 355, 'spirit': 355});
    for (final focus in TrainingFocus.values) {
      expect(oldPerFocusMaximum.expertiseMaximum(focus), 355);
    }
  });

  test('trusted legacy server state backfills once and persists its marker',
      () async {
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => now)
      ..pet = Pet(
        id: 'server-legacy-specialist',
        stage: DragonStage.ascended,
        evolutionPath: 'spirit',
        xp: Pet.ascendedXp,
        dragonSpark: 0,
        firstEgg: false,
        favorite: true,
        acquiredAt: now,
        stageStartedAt: now,
        needsUpdatedAt: now,
        training: const {'might': 40, 'arcana': 40, 'spirit': 220},
      );
    final state = game.exportState();
    game.dispose();
    (state['pet'] as Map).remove('ascensionExpertiseGiftGranted');

    final first = await GameCommandEngine.execute(
      state: state,
      action: 'refresh',
      payload: const {},
      secretSeed: 'cd' * 32,
      now: now,
      keeperId: '11111111-1111-4111-8111-111111111111',
    );
    expect(first['state']['pet']['training'],
        {'might': 40, 'arcana': 40, 'spirit': 230});
    expect(first['state']['pet']['ascensionExpertiseGiftGranted'], isTrue);

    final second = await GameCommandEngine.execute(
      state: Map<String, dynamic>.from(first['state'] as Map),
      action: 'refresh',
      payload: const {},
      secretSeed: 'ef' * 32,
      now: now,
      keeperId: '11111111-1111-4111-8111-111111111111',
    );
    expect(second['state']['pet']['training'],
        {'might': 40, 'arcana': 40, 'spirit': 230});
  });

  test('server transport accepts the largest gifted Expertise state', () {
    expect(
        dragonExpertiseBudget(
            stage: DragonStage.ascended,
            sinister: false,
            evolutionPath: 'might'),
        960);
    expect(
        dragonExpertiseBudget(
            stage: DragonStage.ascended,
            sinister: false,
            evolutionPath: 'mastery'),
        1015);
    expect(
        dragonExpertiseBudget(
            stage: DragonStage.ascended,
            sinister: true,
            evolutionPath: 'mastery'),
        1165);
    expect(largestExpertiseBudget, 1215);
    final migration =
        File('supabase/migrations/202609240096_ascension_expertise_gifts.sql')
            .readAsStringSync();
    expect(migration, contains('private.dragon_expertise_maximum'));
    expect(migration, contains("p_evolution_path='mastery' then 15"));
    expect(RegExp(r'between 0 and 1215').allMatches(migration).length, 18);
    final contract =
        File('tool/shared_expertise_contract.sql').readAsStringSync();
    expect(contract, contains('might=1216'),
        reason: 'The rolled-back contract owns the overflow assertion.');
  });
}
