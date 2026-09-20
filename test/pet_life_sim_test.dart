import 'package:dragon_haven/models/pet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime.utc(2026, 8, 1, 12);

  test('the dragon inside an egg is fixed and survives serialization', () {
    final egg = Pet(
      id: 'egg-fixed',
      hatchSeed: 37,
      lineageId: 'quietstar',
      prismatic: true,
      acquiredAt: start,
      stageStartedAt: start,
    );

    final restored = Pet.fromJson(egg.toJson());
    expect(restored.id, 'egg-fixed');
    expect(restored.lineageId, 'quietstar');
    expect(restored.hatchSeed, 37);
    expect(restored.prismatic, isTrue);
    expect(restored.stage, DragonStage.egg);
  });

  test('the first egg hatches after one complete hour', () {
    final egg = Pet(acquiredAt: start, stageStartedAt: start, hatchSeed: 1);

    expect(egg.canHatch(start.add(const Duration(minutes: 59))), isFalse);
    expect(egg.canHatch(start.add(const Duration(hours: 1))), isTrue);
  });

  test('an older saved starter egg is migrated to one hour', () {
    final restored = Pet.fromJson({
      'id': 'legacy-starter-egg',
      'stage': 'egg',
      'firstEgg': true,
      'incubationMinutes': 24 * 60,
      'stageStartedAt': start.toIso8601String(),
      'hatchSeed': 9,
    });

    expect(restored.incubationDuration, const Duration(hours: 1));
    expect(restored.canHatch(start.add(const Duration(minutes: 59))), isFalse);
    expect(restored.canHatch(start.add(const Duration(hours: 1))), isTrue);
  });

  test('later eggs use their fixed accelerated incubation roll', () {
    final egg = Pet(
      firstEgg: false,
      xp: Pet.hatchXpLater,
      acquiredAt: start,
      stageStartedAt: start,
      hatchSeed: 2,
      incubationMinutes: 15 * 60,
    );

    expect(egg.canHatch(start.add(const Duration(hours: 14, minutes: 59))),
        isFalse);
    expect(egg.canHatch(start.add(const Duration(hours: 15))), isTrue);
  });

  test('evolution is level-driven and locks the leading Expertise', () {
    final dragon = Pet(
      stage: DragonStage.hatchling,
      xp: Pet.wyrmlingXp,
      acquiredAt: start,
      stageStartedAt: start,
      hatchSeed: 3,
    );
    expect(dragon.canEvolve(start), isTrue);
    dragon.evolve(start);
    expect(dragon.stage, DragonStage.wyrmling);

    dragon
      ..xp = Pet.ascendedXp
      ..stageStartedAt = start
      ..addTraining(TrainingFocus.might, 80)
      ..addTraining(TrainingFocus.arcana, 180)
      ..addTraining(TrainingFocus.spirit, 40);
    expect(dragon.canEvolve(start), isTrue);
    dragon.evolve(start);
    expect(dragon.stage, DragonStage.ascended);
    expect(dragon.evolutionPath, 'arcana');

    dragon.addTraining(TrainingFocus.might, 500);
    expect(dragon.trainingFor(TrainingFocus.might), 580);
    expect(dragon.activeEvolutionPath, 'arcana');
  });

  test('all stages share one budget and specialization has no separate cap',
      () {
    for (final stage in DragonStage.values) {
      final dragon = Pet(stage: stage, dragonSpark: 0);
      dragon.addTraining(TrainingFocus.arcana, 5000);
      dragon.addTraining(TrainingFocus.might, 200);
      expect(dragon.trainingFor(TrainingFocus.arcana), 950);
      expect(dragon.trainingFor(TrainingFocus.might), 0);
      expect(dragon.expertiseMaxed, isTrue);
    }
  });

  test('Mastery adds 50 to each type and retains its form after retraining',
      () {
    for (final sinister in [false, true]) {
      final dragon = Pet(
          stage: DragonStage.wyrmling,
          xp: Pet.ascendedXp,
          sinister: sinister,
          dragonSpark: 0,
          training: const {'might': 100, 'arcana': 100, 'spirit': 100});
      final before = sinister ? 1100 : 950;
      expect(dragon.maximumTotalExpertise, before);
      dragon.evolve(start);
      expect(dragon.isMastery, isTrue);
      expect(dragon.maximumTotalExpertise, before + 50);
      expect(dragon.applyExpertiseCosts({TrainingFocus.spirit: -100}), isTrue);
      dragon.addTraining(TrainingFocus.might, 5000);
      expect(dragon.totalTraining, before + 50);
      expect(dragon.trainingFor(TrainingFocus.spirit), 0);
      expect(dragon.isMastery, isTrue);
      expect(Pet.fromJson(dragon.toJson()).isMastery, isTrue);
    }
  });

  test('migration preserves earned over-budget points but never adds more', () {
    for (final sinister in [false, true]) {
      final old = sinister ? 400 : 350;
      final dragon = Pet.fromJson({
        'id': 'old',
        'hatchSeed': 42,
        'stage': 'ascended',
        'evolutionPath': 'mastery',
        'sinister': sinister,
        'dragonSpark': 0,
        'training': {'might': old, 'arcana': old, 'spirit': old}
      });
      expect(dragon.totalTraining, old * 3);
      dragon.addTraining(TrainingFocus.might, 100);
      expect(dragon.totalTraining, old * 3);
      expect(dragon.expertiseMaxed, isTrue);
      expect(dragon.applyExpertiseCosts({TrainingFocus.arcana: -100}), isTrue);
      dragon.addTraining(TrainingFocus.spirit, 200);
      expect(dragon.totalTraining, sinister ? 1150 : 1000);
    }
  });

  test('negative input cannot reduce training and invalid costs change nothing',
      () {
    final dragon = Pet(
        dragonSpark: 0,
        training: const {'might': 12, 'arcana': -5, 'spirit': 1});
    dragon.addTraining(TrainingFocus.might, -50);
    expect(dragon.trainingFor(TrainingFocus.might), 12);
    expect(dragon.trainingFor(TrainingFocus.arcana), 0);
    expect(
        dragon.applyExpertiseCosts(
            {TrainingFocus.might: -1, TrainingFocus.spirit: -2}),
        isFalse);
    expect(dragon.training, {'might': 12, 'arcana': 0, 'spirit': 1});
  });

  test('Dragon Spark is stable, inclusive 0 to 50, and survives evolution', () {
    final seen = <int>{};
    for (var seed = 0; seed < 1000; seed++) {
      final dragon = Pet(hatchSeed: seed);
      final rolled = dragon.dragonSpark;
      seen.add(rolled);
      expect(rolled, inInclusiveRange(0, 50));
      expect(Pet.fromJson(dragon.toJson()).dragonSpark, rolled);
      final legacy = dragon.toJson()..remove('dragonSpark');
      expect(Pet.fromJson(legacy).dragonSpark, rolled);
      dragon.stage = DragonStage.wyrmling;
      dragon.xp = Pet.ascendedXp;
      for (final focus in TrainingFocus.values) {
        dragon.addTraining(focus, 100);
      }
      dragon.evolve(start);
      expect(dragon.dragonSpark, rolled);
      expect(dragon.maximumTotalExpertise, 1000 + rolled);
    }
    expect(seen, Set<int>.from(List.generate(51, (i) => i)));
  });

  test('equal expertises unlock the secret Mastery form', () {
    final dragon = Pet(
      stage: DragonStage.wyrmling,
      xp: Pet.ascendedXp,
      acquiredAt: start,
      stageStartedAt: start,
      training: const {'might': 100, 'arcana': 100, 'spirit': 100},
    );

    expect(dragon.hasMasteryBalance, isTrue);
    dragon.evolve(start);

    expect(dragon.stage, DragonStage.ascended);
    expect(dragon.evolutionPath, 'mastery');
    expect(dragon.isMastery, isTrue);
  });

  test('Mastery balance has no separate minimum expertise', () {
    final dragon = Pet(
      stage: DragonStage.wyrmling,
      xp: Pet.ascendedXp,
      acquiredAt: start,
      stageStartedAt: start,
      training: const {'might': 99, 'arcana': 99, 'spirit': 99},
    );

    expect(dragon.hasMasteryBalance, isTrue);
    expect(dragon.canEvolve(start), isFalse);
  });

  test('Ascension requires its named XP and total Expertise thresholds', () {
    final missingXp = Pet(
      stage: DragonStage.wyrmling,
      xp: Pet.ascendedXp - 1,
      training: const {'might': 100, 'arcana': 100, 'spirit': 100},
    );
    final missingExpertise = Pet(
      stage: DragonStage.wyrmling,
      xp: Pet.ascendedXp,
      training: const {'might': 99, 'arcana': 100, 'spirit': 100},
    );
    final ready = Pet(
      stage: DragonStage.wyrmling,
      xp: Pet.ascendedXp,
      training: const {'might': 100, 'arcana': 100, 'spirit': 100},
    );

    expect(Pet.ascensionExpertiseRequirement, 300);
    expect(missingXp.canEvolve(start), isFalse);
    expect(missingExpertise.canEvolve(start), isFalse);
    expect(ready.canEvolve(start), isTrue);
  });

  test('a spectral Mastery dragon keeps both forms after serialization', () {
    final dragon = Pet(
      stage: DragonStage.wyrmling,
      xp: Pet.ascendedXp,
      prismatic: true,
      acquiredAt: start,
      stageStartedAt: start,
      training: const {'might': 180, 'arcana': 180, 'spirit': 180},
    )..evolve(start);

    final restored = Pet.fromJson(dragon.toJson());
    expect(restored.isMastery, isTrue);
    expect(restored.prismatic, isTrue);
  });

  test('legacy evolution values migrate to the new training paths', () {
    final restored = Pet.fromJson({
      'xp': 2300,
      'stage': 'ascended',
      'hatchSeed': 5,
      'evolutionPath': 'bond',
      'pathEnergy': {'earth': 10, 'storm': 20, 'bond': 30},
    });
    expect(restored.evolutionPath, 'spirit');
    expect(restored.trainingFor(TrainingFocus.might), 10);
    expect(restored.trainingFor(TrainingFocus.arcana), 20);
    expect(restored.trainingFor(TrainingFocus.spirit), 30);
  });
}
