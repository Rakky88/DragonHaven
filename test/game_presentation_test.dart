import 'dart:math';

import 'package:dragon_haven/models/achievement.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/game_presentation.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 8, 22, 12);

  Pet readyDragon(String id, DateTime acquiredAt) => Pet(
        id: id,
        name: id,
        stage: DragonStage.hatchling,
        xp: Pet.wyrmlingXp,
        firstEgg: false,
        acquiredAt: acquiredAt,
        stageStartedAt: now.subtract(const Duration(days: 4)),
        needsUpdatedAt: now,
        hatchSeed: id.hashCode,
      );

  test('hatch is first, evolutions are oldest first, achievements are last',
      () async {
    final game = HouseholdProvider(
      random: Random(11),
      clock: () => now,
      persistenceEnabled: false,
    );
    game.pet
      ..xp = Pet.hatchXpFirst
      ..stageStartedAt = now.subtract(const Duration(days: 1));
    final old = readyDragon('oldest', now.subtract(const Duration(days: 40)));
    final young =
        readyDragon('youngest', now.subtract(const Duration(days: 10)));
    game.sanctuaryDragons = [young, old];

    // Deliberately queue in the opposite order to prove sorting is semantic.
    expect(await game.evolveDragon(young.id), isTrue);
    expect(await game.evolveDragon(old.id), isTrue);
    expect(await game.hatchActiveDragon(), isTrue);

    final ordered = game.orderedPendingPresentations;
    expect(ordered.first.type, GamePresentationType.hatch);
    final evolutions = ordered
        .where((item) => item.type == GamePresentationType.evolution)
        .toList();
    expect(evolutions.map((item) => item.dragonId), ['oldest', 'youngest']);
    final lastEvolution = ordered
        .lastIndexWhere((item) => item.type == GamePresentationType.evolution);
    final firstAchievement = ordered
        .indexWhere((item) => item.type == GamePresentationType.achievement);
    expect(firstAchievement, greaterThan(lastEvolution));
  });

  test('a presentation remains queued until it is explicitly completed',
      () async {
    final game = HouseholdProvider(
      random: Random(12),
      clock: () => now,
      persistenceEnabled: false,
    );
    game.pet
      ..xp = Pet.hatchXpFirst
      ..stageStartedAt = now.subtract(const Duration(days: 1));
    await game.hatchActiveDragon();
    final first = game.nextPresentation!;

    expect(game.nextPresentation?.id, first.id);
    await game.completePresentation(first.id);
    expect(
        game.pendingPresentations.any((item) => item.id == first.id), isFalse);
  });

  test('presentation data survives JSON round trips', () {
    final presentation = GamePresentation(
      id: 'evolution-dragon-wyrmling',
      type: GamePresentationType.evolution,
      createdAt: now,
      sortAt: now.subtract(const Duration(days: 3)),
      dragonId: 'dragon',
      previousStageKey: 'spark',
      payload: const {
        'sentKind': 'chest',
        'sentKey': 'gold',
        'receivedData': {'id': 'egg-1'},
      },
    );
    expect(GamePresentation.fromJson(presentation.toJson()).toJson(),
        presentation.toJson());
  });

  test('showcase contains the complete collection without persistence', () {
    final game = HouseholdProvider.createShowcase();
    expect(game.showcaseMode, isTrue);
    expect(game.ownedDragons, hasLength(dragonLineages.length * 10));
    expect(game.discoveredForms, hasLength(dragonLineages.length * 5));
    expect(game.prismaticForms, hasLength(dragonLineages.length * 5));
    expect(game.towerFloorRoomIds, hasLength(20));
    expect(game.ownedItemIds, hasLength(200));
    expect(game.unlockedAchievementIds, hasLength(achievementCatalog.length));
    expect(game.pendingPresentations, isEmpty);
  });
}
