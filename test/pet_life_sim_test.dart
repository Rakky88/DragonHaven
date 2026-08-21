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

  test('the first egg needs care, experience and a complete day', () {
    final egg = Pet(acquiredAt: start, stageStartedAt: start, hatchSeed: 1);
    for (final action in DragonCareAction.values) {
      expect(egg.careFor(action, start), isTrue);
    }
    egg.xp = Pet.hatchXpFirst;

    expect(egg.canHatch(start.add(const Duration(hours: 23))), isFalse);
    expect(egg.canHatch(start.add(const Duration(days: 1))), isTrue);
  });

  test('later eggs use their fixed two-to-fourteen-day incubation roll', () {
    final egg = Pet(
      firstEgg: false,
      careScore: 999,
      careActions: 99,
      xp: Pet.hatchXpLater,
      acquiredAt: start,
      stageStartedAt: start,
      hatchSeed: 2,
      incubationHours: 9 * 24,
    );

    expect(egg.requiredIncubationDays(), 9);
    expect(
        egg.canHatch(start.add(const Duration(days: 8, hours: 23))), isFalse);
    expect(egg.canHatch(start.add(const Duration(days: 9))), isTrue);
  });

  test('evolution respects minimum ages and locks the leading path', () {
    final dragon = Pet(
      stage: DragonStage.hatchling,
      xp: Pet.wyrmlingXp,
      acquiredAt: start,
      stageStartedAt: start,
      hatchSeed: 3,
    );
    expect(dragon.canEvolve(start.add(const Duration(days: 2))), isFalse);
    dragon.evolve(start.add(const Duration(days: 3)));
    expect(dragon.stage, DragonStage.wyrmling);

    dragon
      ..xp = Pet.ascendedXp
      ..stageStartedAt = start
      ..addTraining(TrainingFocus.might, 80)
      ..addTraining(TrainingFocus.arcana, 180)
      ..addTraining(TrainingFocus.spirit, 40);
    final ascensionDay = start.add(const Duration(days: 7));
    expect(dragon.canEvolve(ascensionDay), isTrue);
    dragon.evolve(ascensionDay);
    expect(dragon.stage, DragonStage.ascended);
    expect(dragon.evolutionPath, 'arcana');

    dragon.addTraining(TrainingFocus.might, 500);
    expect(dragon.activeEvolutionPath, 'arcana');
  });

  test('care actions have independent four-hour cooldowns', () {
    final dragon = Pet(
      stage: DragonStage.hatchling,
      acquiredAt: start,
      stageStartedAt: start,
      hatchSeed: 4,
    );
    expect(dragon.careFor(DragonCareAction.play, start), isTrue);
    expect(dragon.careFor(DragonCareAction.play, start), isFalse);
    expect(dragon.careFor(DragonCareAction.rest, start), isTrue);
    expect(
        dragon.careFor(
            DragonCareAction.play, start.add(const Duration(hours: 4))),
        isTrue);
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
