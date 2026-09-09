import 'dart:io';
import 'package:dragon_haven/models/moonlit_orchard.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/seasonal_conclave_project.dart';
import 'package:dragon_haven/models/sunwake_surf.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('surf starts promptly, accelerates, and dragging cannot teleport', () {
    final game = SunwakeSurf(seed: 42);
    final startSpeed = game.speed;
    expect(startSpeed, greaterThanOrEqualTo(.4));
    game.steer(.85);
    expect(game.x, .5);
    game.advance(.1);
    expect(game.x, greaterThan(.5));
    expect(game.x - .5,
        lessThanOrEqualTo(SunwakeSurf.maximumSteeringSpeed * .1 + .000001));
    game.advance(.2);
    expect(game.gates, isNotEmpty);
    expect(game.speed, greaterThan(startSpeed));
    expect(game.x, closeTo(.85, .000001));
    game.steer(.2);
    game.releaseSteering();
    final released = game.x;
    game.advance(.1);
    expect((game.x - released).abs(), lessThan(.006));
    expect(game.targetX, released);
  });
  test('surf collisions and three lives are independent of frame rate', () {
    List<bool> run(int fps) {
      final game = SunwakeSurf(seed: 42);
      final results = <bool>[];
      for (var i = 0; i < fps * 75; i++) {
        results.addAll(game.advance(1 / fps).map((a) => a.correct));
      }
      expect(game.mistakes, 3);
      expect(game.advance(5), isEmpty);
      return results;
    }

    expect(run(30), run(120));
    expect(run(60), run(120));
  });
  test('twenty surf seeds remain navigable as the gates accelerate', () {
    final routes = <String>{};
    for (var seed = 0; seed < 20; seed++) {
      final game = SunwakeSurf(seed: seed);
      var successes = 0;
      final route = <int>[];
      var last = -1;
      for (var frame = 0; frame < 75 * 120; frame++) {
        final next = game.gates.where((g) => !g.resolved).firstOrNull;
        if (next != null) {
          game.steer(next.pearlX);
          if (next.id != last) {
            route.add(next.safeLane);
            last = next.id;
          }
        }
        successes += game.advance(1 / 120).where((a) => a.correct).length;
      }
      expect(game.mistakes, 0, reason: 'seed $seed');
      expect(successes, greaterThan(35));
      routes.add(route.join());
    }
    expect(routes.length, 20);
  });
  test('rotation preserves every shape, placement respects bounds and overlap',
      () {
    for (final shape in MoonlitOrchard.shapes) {
      var p = OrchardPiece(shape, 1);
      for (var i = 0; i < 4; i++) {
        p = p.rotated();
      }
      expect(p.cells.toSet(), shape.toSet());
    }
    final game = MoonlitOrchard(seed: 1);
    game.tray[0] = const OrchardPiece([(0, 0), (1, 0)], 1);
    expect(game.place(0, 5, 6), isNull);
    expect(game.place(0, 0, 6)!.fruitCount, 2);
    game.tray[1] = const OrchardPiece([(0, 0)], 0);
    expect(game.place(1, 0, 6), isNull);
    expect(game.board[36], 1);
  });
  test('full rows harvest and the remaining fruit sinks exactly one row', () {
    final game = MoonlitOrchard(seed: 1);
    for (var x = 0; x < 5; x++) {
      game.board[36 + x] = 0;
    }
    game.board[30] = 2;
    game.tray[0] = const OrchardPiece([(0, 0)], 1);
    final result = game.place(0, 5, 6)!;
    expect(result.rows, 1);
    expect(result.clearedRows, [6]);
    expect(result.boardBeforeHarvest[30], 2);
    expect(result.boardBeforeHarvest[41], 1);
    expect(game.harvestedRows, 1);
    expect(game.board[36], 2);
    expect(game.board.whereType<int>(), hasLength(1));
    game.board[36] = 0;
    expect(result.boardBeforeHarvest[36], 0);
    expect(result.boardBeforeHarvest[30], 2);
    expect(() => result.boardBeforeHarvest[0] = 2, throwsUnsupportedError);
  });
  test('three blocked baskets finish and cannot be reset for extra points', () {
    final game = MoonlitOrchard(seed: 8);
    for (var miss = 0; miss < 3; miss++) {
      for (var y = 0; y < 7; y++) {
        for (var x = 0; x < 6; x++) {
          game.board[y * 6 + x] = x == 5 ? null : 1;
        }
      }
      game.board[0] = null;
      game.tray.setAll(0, [
        const OrchardPiece([(0, 0)], 0),
        const OrchardPiece([(0, 0), (1, 0), (0, 1), (1, 1)], 1),
        const OrchardPiece([(0, 0), (1, 0), (0, 1), (1, 1)], 2)
      ]);
      expect(game.place(0, 0, 0)!.overflow, true);
      expect(game.mistakes, miss + 1);
      game.freshBasket();
    }
    expect(game.finished, true);
    expect(game.place(0, 5, 0), isNull);
  });
  test('shared cosmetic project stages never exceed five', () {
    for (final (count, stage) in [
      (0, 0),
      (1, 1),
      (5, 2),
      (15, 3),
      (30, 4),
      (60, 5),
      (999, 5)
    ]) {
      final p = SeasonalConclaveProject(
          eventId: 'sunwake_summer_sea',
          occurrenceKey: '2027',
          completedTrials: count);
      expect(p.stage, stage);
      expect(p.fraction, inInclusiveRange(0, 1));
      expect(File(p.asset).existsSync(), true);
    }
  });
  test(
      'both previews fill slots, grant ordinary rewards once and restore bests',
      () async {
    for (final (code, id, kind) in [
      ('SUNWAKEEVENT', 'sunwake_summer_sea', TrialKind.sunwakeSurf),
      (
        'HARVESTMOONEVENT',
        'harvestmoon_moonlit_orchard',
        TrialKind.moonlitOrchard
      )
    ]) {
      final now = DateTime.utc(2026, 9, 9, 12);
      final game =
          HouseholdProvider(clock: () => now, persistenceEnabled: false)
            ..pet = Pet(
                id: 'test-dragon',
                firstEgg: false,
                stage: DragonStage.hatchling);
      addTearDown(game.dispose);
      await game.redeemCode(code, keeperId: 'DH-AAAA0001');
      expect(game.activeSpecialAdventureWindows.single.event.id, id);
      expect(game.availableTrials.map((o) => o.kind), everyElement(kind));
      final offer = game.availableTrials.first;
      final xp = game.pet.xp;
      final reward = await game.completeTrial(
          offerId: offer.id, dragonId: game.pet.id, score: 8000);
      expect(reward!.testEvent, true);
      expect(reward.simulated, false);
      expect(reward.reward.grade, TrialGrade.sPlus);
      expect(game.pet.xp, greaterThan(xp));
      expect(
          await game.completeTrial(
              offerId: offer.id, dragonId: game.pet.id, score: 8000),
          isNull);
      expect(Pet.fromJson(game.pet.toJson()).trialHighScores[kind.name], 8000);
    }
  });
}
