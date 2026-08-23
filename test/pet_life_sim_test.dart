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
    expect(dragon.activeEvolutionPath, 'arcana');
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
