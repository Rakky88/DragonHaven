import 'dart:convert';
import 'dart:math';

import 'package:dragon_haven/models/seasonal_arcade_game.dart';
import 'package:dragon_haven/models/classic_trial_game.dart';
import 'package:dragon_haven/models/witchlight_trace.dart';
import 'package:dragon_haven/models/sunwake_surf.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/trial_input.dart';
import 'package:flutter_test/flutter_test.dart';

List<Object> signature(List<ArcadeAction> actions) =>
    actions.map((a) => [a.correct, a.points, a.complete]).toList();

void main() {
  test(
      'one hour of Sunwake checkpoints preserves inputs and bounded state exactly',
      () {
    final uninterrupted = SunwakeSurf(seed: 918);
    var restored = SunwakeSurf(seed: 918);
    var score = 0;
    for (var frame = 0; frame < 3600 * 50; frame++) {
      final next = uninterrupted.gates.where((g) => !g.resolved).firstOrNull;
      if (next != null) {
        uninterrupted.steer(next.pearlX);
        restored.steer(next.pearlX);
      }
      final first = uninterrupted.advance(.02);
      final second = restored.advance(.02);
      expect(second.map((a) => [a.correct, a.points, a.x, a.y]),
          first.map((a) => [a.correct, a.points, a.x, a.y]));
      score +=
          first.where((a) => a.correct).fold(0, (sum, a) => sum + a.points);
      if (frame % 250 == 249) {
        final snapshot = jsonEncode(restored.checkpoint());
        expect(snapshot.length, lessThan(2400));
        restored = SunwakeSurf.fromCheckpoint(jsonDecode(snapshot));
        expect(restored.checkpoint(), uninterrupted.checkpoint());
      }
    }
    expect(restored.mistakes, 0);
    expect(score, greaterThan(500000));
  });

  test(
      'Cavern flight uses identical collision frames between renders and replay',
      () {
    final live = CavernFlightGame(seed: 10, spirit: 300);
    final replay = CavernFlightGame(seed: 10, spirit: 300);
    for (var ms = 0; ms <= 16000; ms += 10) {
      live.advanceTo(ms);
      if (ms % 650 == 0) {
        live.flap(ms);
        replay.flap(ms);
      }
    }
    replay.advanceTo(16000);
    expect(replay.ended, isTrue);
    expect([replay.score, replay.milliseconds, replay.passed, replay.dragonY],
        [live.score, live.milliseconds, live.passed, live.dragonY]);
    final score = replay.score;
    replay.flap(17000);
    expect(replay.score, score);
  });

  test(
      'Ruin Breaker replays thirty perfect strikes and three misses exactly once',
      () {
    final game = RuinBreakerGame(might: 300);
    for (var round = 0; round < 30; round++) {
      final at = game.roundStartedAt +
          (pi / 2 / (1.8 + min(round * .10, 2.2)) * 1000).round();
      expect(game.strike(at), isTrue);
      expect(game.combo, round + 1);
      expect(game.strike(at), isFalse);
      game.advanceTo(at + 330);
    }
    expect(game.ended, isTrue);
    expect(game.round, 30);
    expect(game.score, greaterThan(10000));
    final misses = RuinBreakerGame(might: 300);
    for (var round = 0; round < 3; round++) {
      misses.strike(round * 330);
      misses.advanceTo((round + 1) * 330);
    }
    expect(misses.ended, isTrue);
    expect(misses.misses, 3);
    expect(misses.score, 0);
  });

  test(
      'Runeweaver closes rapid rounds, retains the echo and has no idle time limit',
      () {
    final game = RuneweaverGame(seed: 7, arcana: 300);
    var at = 0;
    for (var round = 0; round < 12; round++) {
      while (!game.accepting) {
        game.advanceTo(at += 10);
      }
      if (round == 3) expect(game.echoRune, game.sequence.last);
      if (round == 4) expect(game.echoRune, isNull);
      for (final rune in List.of(game.sequence)) {
        expect(game.tap(rune, at), isTrue);
      }
      expect(game.rounds, round + 1);
      expect(game.tap(game.sequence.last, at), isFalse);
    }
    game.advanceTo(at += 10000000);
    expect(game.accepting, isTrue);
    expect(game.ended, isFalse);
    expect(game.tap((game.sequence.first + 1) % 5, at), isTrue);
    expect(game.ended, isTrue);
    expect(game.rounds, 12);
  });

  test(
      'Witchlight verifies every bend, rejects shortcuts and releases, and preserves length',
      () {
    double length(List<Point<double>> route) => List.generate(
            route.length - 1, (i) => route[i].distanceTo(route[i + 1]))
        .fold(0.0, (a, b) => a + b);
    var expected = 0.0;
    final starts = <String>{};
    for (var seed = 0; seed < 50; seed++) {
      final trace =
          WitchlightTrace(width: 320, height: 400, seed: seed, tolerance: .7);
      if (seed == 0) expected = length(trace.route);
      expect(length(trace.route), closeTo(expected, .00001));
      starts.add(trace.route.first.toString());
      expect(trace.begin(const Point(double.nan, 0)), isFalse);
      expect(trace.begin(trace.route.first), isTrue);
      for (final point in trace.route.skip(1)) {
        trace.move(point);
      }
      expect(trace.result, isTrue);
      trace.release();
      expect(trace.result, isTrue);
      final shortcut =
          WitchlightTrace(width: 320, height: 400, seed: seed, tolerance: .7);
      shortcut.begin(shortcut.route.first);
      shortcut.move(shortcut.route.last);
      expect(shortcut.result, isFalse);
      final released =
          WitchlightTrace(width: 320, height: 400, seed: seed, tolerance: .7);
      released.begin(released.route.first);
      released.release();
      expect(released.result, isFalse);
    }
    expect(starts, hasLength(50));
  });

  test('bounded input chunks retain long-run timestamps and signed coordinates',
      () {
    const origin = 9007199000000;
    final inputs = [
      const TrialInput(origin, TrialControl.grabDragon, -65535, 65535),
      const TrialInput(origin + 12345, TrialControl.steerDragon, 32767, -12),
      const TrialInput(origin + 60000, TrialControl.releaseDragon),
    ];
    final encoded =
        TrialInputTranscript.encode(inputs, startMilliseconds: origin);
    final restored =
        TrialInputTranscript.decode(encoded, startMilliseconds: origin);
    expect(restored.map((i) => [i.milliseconds, i.control, i.a, i.b]),
        inputs.map((i) => [i.milliseconds, i.control, i.a, i.b]));
    expect(encoded.length, lessThan(3200));
  });

  test('malformed, oversized, reversed and ambiguous chunks are refused', () {
    for (final bytes in [
      <int>[],
      [0],
      [1, 128],
      [1, 128, 0, 0, 0, 0],
      [1, 0, 255, 0, 0],
      [1, 0, 0, 255, 255, 255, 255],
      [1, ...List.filled(2400, 0)],
    ]) {
      expect(
          () => TrialInputTranscript.decode(base64Encode(bytes),
              startMilliseconds: 0),
          throwsFormatException);
    }
    expect(() => TrialInputTranscript.decode('AQ==extra', startMilliseconds: 0),
        throwsFormatException);
    expect(
        () => TrialInputTranscript.encode([
              const TrialInput(10, TrialControl.flap),
              const TrialInput(9, TrialControl.flap)
            ], startMilliseconds: 0),
        throwsFormatException);
    expect(
        () => TrialInputTranscript.encode(
            [const TrialInput(60001, TrialControl.flap)],
            startMilliseconds: 0),
        throwsFormatException);
  });

  for (final kind in [
    TrialKind.hollyfrostGiftforge,
    TrialKind.midnightChime,
    TrialKind.rosevowRelay,
    TrialKind.prismaticParade
  ]) {
    test('${kind.name} replays timed controls independently of render frames',
        () {
      final live = SeasonalArcadeGame(
          kind: kind, seed: 94, might: .6, arcana: .8, spirit: .7);
      final replay = SeasonalArcadeGame(
          kind: kind, seed: 94, might: .6, arcana: .8, spirit: .7);
      final recording = <TrialInput>[];
      final liveActions = <ArcadeAction>[];
      final random = Random(28);
      for (var ms = 10; ms < 75000; ms += 10) {
        live.advanceTo(ms);
        if (ms % 20 == 0 && live.canInput) {
          TrialInput? input;
          if (kind == TrialKind.hollyfrostGiftforge &&
              live.parcels.isNotEmpty) {
            final p = live.parcels.first;
            input = TrialInput(ms, TrialControl.deliverGift, p.id, p.type);
          } else if (kind == TrialKind.midnightChime) {
            final notes = live.notes
                .where((n) => (n.strikeAt - live.time).abs() < .015)
                .toList();
            for (final note in notes) {
              final press = TrialInput(ms, TrialControl.strikeChime, note.lane);
              recording.add(press);
              live.applyInput(press);
            }
          } else if (kind == TrialKind.rosevowRelay) {
            final next = live.maze.solution()!.first;
            input = TrialInput(ms, TrialControl.moveHearts, next.index);
          } else if (kind == TrialKind.prismaticParade) {
            final choices = live.prisms.solutionMasks.keys
                .where((i) =>
                    live.prisms.connectors[i] != live.prisms.solutionMasks[i])
                .toList();
            input = TrialInput(ms, TrialControl.rotatePrism,
                choices.isEmpty ? random.nextInt(16) : choices.first);
          }
          if (input != null) {
            recording.add(input);
            live.applyInput(input);
          }
        }
        liveActions.addAll(live.takeActions());
      }
      final replayActions = <ArcadeAction>[];
      for (final input in recording) {
        replay.applyInput(input);
        replayActions.addAll(replay.takeActions());
      }
      replay.advanceTo(74990);
      replayActions.addAll(replay.takeActions());
      expect(signature(replayActions), signature(liveActions));
      expect(liveActions.where((a) => a.correct).length, greaterThan(25));
      expect(live.mistakes, 0);
      expect(replay.mistakes, 0);
      expect(
          () => replay.applyInput(const TrialInput(74999, TrialControl.flap)),
          throwsFormatException);
    });
  }

  test(
      'gift/chime expiry stops at the third error even after a suspended frame',
      () {
    for (final kind in [
      TrialKind.hollyfrostGiftforge,
      TrialKind.midnightChime
    ]) {
      final game = SeasonalArcadeGame(kind: kind, seed: 1)..advanceTo(75000);
      expect(game.lost, isTrue);
      expect(game.takeActions().where((a) => !a.correct), hasLength(3));
      game.advanceTo(78000);
      expect(game.takeActions(), isEmpty);
    }
  });
}
