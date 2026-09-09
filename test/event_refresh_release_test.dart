import 'dart:math';

import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/seasonal_minigame.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/event_branding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('500 paired mazes are varied, reachable and never reward revisits', () {
    final boards = <String>{};
    for (var seed = 0; seed < 500; seed++) {
      final maze = HeartMaze.generate(Random(seed));
      boards.add('${maze.leftWalls}:${maze.rightWalls}');
      final solution = maze.solution();
      expect(solution, isNotNull, reason: 'seed $seed');
      expect(solution!.length, inInclusiveRange(6, 16));
      for (final direction in solution) {
        expect(maze.move(direction), isTrue);
        expect(maze.leftWalls, isNot(contains(maze.left)));
        expect(maze.rightWalls, isNot(contains(maze.right)));
      }
      expect(maze.solved, isTrue);
      for (var i = 0; i < 30; i++) {
        final before = maze.visited.toSet();
        final moved = maze.move(HeartDirection.values[i % 4]);
        if (before.contains(maze.left * 15 + maze.right)) {
          expect(moved, isNot(isTrue));
        }
      }
    }
    expect(boards.length, greaterThan(450));
  });

  test('500 prism circuits have rotatable solutions and no automatic wins', () {
    final boards = <String>{};
    for (var seed = 0; seed < 500; seed++) {
      final circuit = PrismCircuit.generate(Random(seed));
      boards.add('${circuit.source}:${circuit.sink}:${circuit.connectors}');
      expect(circuit.solved, isFalse);
      for (final solution in circuit.solutionMasks.entries) {
        for (var i = 0;
            i < 4 && circuit.connectors[solution.key] != solution.value;
            i++) {
          circuit.rotate(solution.key);
        }
        expect(circuit.connectors[solution.key], solution.value);
      }
      expect(circuit.solved, isTrue, reason: 'seed $seed');
      final credited = circuit.litCells.where(circuit.credited.add).toList();
      expect(credited, isNotEmpty);
      expect(circuit.litCells.where(circuit.credited.add), isEmpty);
    }
    expect(boards.length, greaterThan(450));
  });

  test('seasonal highlights require all three; standard trials retain one', () {
    final dragon = Pet(
        id: 'marked',
        stage: DragonStage.hatchling,
        training: const {'might': 10, 'arcana': 20, 'spirit': 30});
    for (final definition in trialDefinitions.values) {
      dragon.highlightedExpertises
        ..clear()
        ..add(definition.focus);
      expect(definition.highlightedFor(dragon), !definition.isSeasonal);
      if (definition.isSeasonal) {
        expect(definition.assistingExpertises, TrainingFocus.values);
        expect(definition.combinedExpertise(dragon), 60);
      }
      dragon.highlightedExpertises.addAll(TrainingFocus.values);
      expect(definition.highlightedFor(dragon), isTrue);
    }
  });

  test(
      'activation fills only empty slots once; stopping preserves started trials',
      () async {
    var now = DateTime.utc(2026, 9, 9, 12);
    final game = HouseholdProvider(
        clock: () => now, random: Random(8), persistenceEnabled: false);
    addTearDown(game.dispose);
    game.availableTrials;
    final original = game.trialOffers.first;
    game.trialOffers = [original];
    await game.synchronizeSeasonalEventPreviews(
        {'christmas_winter_hearth': now.add(const Duration(hours: 48))});
    final offers = game.availableTrials;
    expect(offers.map((o) => o.id), contains(original.id));
    expect(offers.where((o) => o.kind == TrialKind.hollyfrostGiftforge),
        hasLength(2));
    final started = offers.last;
    expect(await game.beginTrial(started.id), isTrue);
    await game.dismissTrial(offers[1].id);
    expect(game.availableTrials, hasLength(2),
        reason: 'No repeated activation refill');
    await game.synchronizeSeasonalEventPreviews({});
    expect(
        game.availableTrials
            .any((o) => o.id == started.id && o.startedAt != null),
        isTrue);
    expect(game.activeSpecialAdventureWindows, isEmpty);
    expect(game.activeSeasonalMusicTracks, isEmpty);
    now = now.add(const Duration(minutes: 15));
    expect(game.availableTrials, hasLength(3));
  });

  test('calendar dismissal removes app and launcher theme until next edition',
      () async {
    final now = DateTime.utc(2026, 12, 25, 12);
    final game = HouseholdProvider(clock: () => now, persistenceEnabled: false);
    addTearDown(game.dispose);
    final window = game.activeSpecialAdventureWindows.single;
    await game
        .synchronizeSeasonalEventDismissals({window.event.id: window.endsAt});
    expect(game.activeSpecialAdventureWindows, isEmpty);
    final schedule = eventBrandingSchedule(
        now, game.activeSpecialAdventureWindows,
        dismissedUntil: game.seasonalEventDismissedUntil);
    expect(schedule.any((w) => w['key'] == window.key), isFalse);
    expect(schedule.any((w) => w['logo'] == 'christmas'), isTrue,
        reason: 'Next year is still scheduled');
    expect(game.exportState()['seasonalEventDismissedUntil'], isNotEmpty);
    // An explicit new preview can start even during a dismissed calendar event.
    await game.synchronizeSeasonalEventPreviews(
        {window.event.id: now.add(const Duration(hours: 48))});
    expect(
        game.activeSpecialAdventureWindows.single.key, contains(':preview:'));
  });
}
