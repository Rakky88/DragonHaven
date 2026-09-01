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
    expect(dragon.trainingFor(TrainingFocus.might), maxDragonExpertise);
    expect(dragon.activeEvolutionPath, 'arcana');
  });

  test('pre-Ascension expertise is capped at 300 including migrated saves', () {
    final dragon = Pet(
      training: const {'might': 999, 'arcana': 300, 'spirit': -5},
    );
    expect(dragon.trainingFor(TrainingFocus.might), maxDragonExpertise);
    expect(dragon.trainingFor(TrainingFocus.arcana), maxDragonExpertise);
    expect(dragon.trainingFor(TrainingFocus.spirit), 0);

    dragon
      ..addTraining(TrainingFocus.might, 100)
      ..addTraining(TrainingFocus.spirit, 500);
    expect(dragon.trainingFor(TrainingFocus.might), maxDragonExpertise);
    expect(dragon.trainingFor(TrainingFocus.spirit), maxDragonExpertise);

    final restored = Pet.fromJson({
      'training': {'might': 301, 'arcana': 900, 'spirit': 450},
    });
    expect(
      TrainingFocus.values.map(restored.trainingFor),
      everyElement(maxDragonExpertise),
    );
  });

  test('Ascension paths raise only their intended expertise maximum', () {
    final might = Pet(
      stage: DragonStage.ascended,
      evolutionPath: 'might',
      training: const {'might': 999, 'arcana': 999, 'spirit': 999},
    );
    expect(might.trainingFor(TrainingFocus.might), 350);
    expect(might.trainingFor(TrainingFocus.arcana), 300);
    expect(might.trainingFor(TrainingFocus.spirit), 300);

    final arcana = Pet(
      stage: DragonStage.ascended,
      evolutionPath: 'arcana',
      training: const {'might': 999, 'arcana': 999, 'spirit': 999},
    );
    expect(arcana.trainingFor(TrainingFocus.might), 300);
    expect(arcana.trainingFor(TrainingFocus.arcana), 350);
    expect(arcana.trainingFor(TrainingFocus.spirit), 300);

    final spirit = Pet(
      stage: DragonStage.ascended,
      evolutionPath: 'spirit',
      training: const {'might': 999, 'arcana': 999, 'spirit': 999},
    );
    expect(spirit.trainingFor(TrainingFocus.might), 300);
    expect(spirit.trainingFor(TrainingFocus.arcana), 300);
    expect(spirit.trainingFor(TrainingFocus.spirit), 350);

    final mastery = Pet(
      stage: DragonStage.ascended,
      evolutionPath: 'mastery',
      training: const {'might': 999, 'arcana': 999, 'spirit': 999},
    );
    expect(
      TrainingFocus.values.map(mastery.trainingFor),
      everyElement(350),
    );
    expect(mastery.maximumTotalExpertise, 1050);
  });

  test('Infernal dragons have 350 base and 400 Ascension maximums', () {
    final hatchling = Pet(
      sinister: true,
      stage: DragonStage.hatchling,
      training: const {'might': 999, 'arcana': 999, 'spirit': 999},
    );
    expect(
      TrainingFocus.values.map(hatchling.trainingFor),
      everyElement(350),
    );

    final specialist = Pet(
      sinister: true,
      stage: DragonStage.ascended,
      evolutionPath: 'spirit',
      training: const {'might': 999, 'arcana': 999, 'spirit': 999},
    );
    expect(specialist.trainingFor(TrainingFocus.might), 350);
    expect(specialist.trainingFor(TrainingFocus.arcana), 350);
    expect(specialist.trainingFor(TrainingFocus.spirit), 400);
    expect(specialist.maximumTotalExpertise, 1100);

    final mastery = Pet(
      sinister: true,
      stage: DragonStage.ascended,
      evolutionPath: 'mastery',
      training: const {'might': 999, 'arcana': 999, 'spirit': 999},
    );
    expect(
      TrainingFocus.values.map(mastery.trainingFor),
      everyElement(400),
    );
    expect(mastery.maximumTotalExpertise, 1200);
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
