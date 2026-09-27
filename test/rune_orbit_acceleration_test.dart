import 'dart:math';

import 'package:dragon_haven/models/standard_trial_games.dart';
import 'package:flutter_test/flutter_test.dart';

int _captureAt(RuneOrbitGame game, int rune) =>
    (game.roundStartedAt + (rune + .5) * game.visibleMs).floor();

void _match(RuneOrbitGame game) {
  game.advanceTo(game.nextRoundAt!);
  expect(game.tap(game.targetRune, _captureAt(game, game.targetRune)), isTrue);
}

void main() {
  test('every match accelerates beyond the former speed ceiling', () {
    final game = RuneOrbitGame(seed: 41, arcana: 125);
    for (var point = 1; point <= 100; point++) {
      final previousDuration = game.visibleMs;
      _match(game);
      expect(game.rounds, point);
      expect(game.visibleMs, lessThan(previousDuration));
      expect(previousDuration / game.visibleMs, closeTo(1.045, 1e-12));
    }
    expect(game.visibleMs, lessThan(10));
    expect(game.misses, 0);
  });

  test('high Arcana assistance never delays the first acceleration', () {
    final game = RuneOrbitGame(seed: 91, arcana: 10000);
    expect(game.visibleMs, 800);
    _match(game);
    expect(game.visibleMs, closeTo(800 / 1.045, 1e-10));
    _match(game);
    expect(game.visibleMs, closeTo(800 / pow(1.045, 2), 1e-10));
  });

  test('fractional timing continues accelerating below a millisecond', () {
    final game = RuneOrbitGame(seed: 13, arcana: 0)..rounds = 180;
    expect(game.visibleMs, lessThan(1));
    var previousDuration = game.visibleMs;
    for (var points = 181; points <= 1000; points++) {
      game.rounds = points;
      expect(game.visibleMs.isFinite, isTrue);
      expect(game.visibleMs, greaterThan(0));
      expect(game.visibleMs, lessThan(previousDuration));
      previousDuration = game.visibleMs;
    }
  });

  test('misses and ignored intermission taps do not accelerate', () {
    final game = RuneOrbitGame(seed: 24, arcana: 40);
    _match(game);
    final duration = game.visibleMs;
    expect(game.tap(0, game.milliseconds), isFalse);
    expect(game.visibleMs, duration);
    for (var misses = 1; misses <= 3; misses++) {
      game.advanceTo(game.nextRoundAt!);
      final wrong = (game.targetRune + 1) % 5;
      expect(game.tap(wrong, _captureAt(game, wrong)), isTrue);
      expect(game.misses, misses);
      expect(game.rounds, 1);
      expect(game.visibleMs, duration);
    }
    expect(game.ended, isTrue);
  });

  test('uncapped checkpoints resume the same targets and timing', () {
    final game = RuneOrbitGame(seed: 712, arcana: 87);
    for (var point = 0; point < 50; point++) {
      _match(game);
    }
    final checkpoint = game.checkpoint();
    expect(checkpoint['version'], 2);
    final restored = RuneOrbitGame.fromCheckpoint(checkpoint, arcana: 87);
    expect(restored.uncappedSpeed, isTrue);
    expect(restored.checkpoint(), checkpoint);
    for (var point = 0; point < 25; point++) {
      _match(game);
      _match(restored);
      expect(restored.visibleMs, game.visibleMs);
      expect(restored.checkpoint(), game.checkpoint());
    }
  });

  test('existing version one checkpoints retain original capped timing', () {
    final legacy =
        RuneOrbitGame(seed: 312, arcana: 10000, uncappedSpeed: false);
    _match(legacy);
    expect(legacy.visibleMs, 800,
        reason: 'Keep the original high-Arcana plateau for an in-flight run');
    for (var point = 1; point < 60; point++) {
      _match(legacy);
    }
    expect(legacy.visibleMs, 260);
    final checkpoint = legacy.checkpoint();
    expect(checkpoint['version'], 1);
    final restored = RuneOrbitGame.fromCheckpoint(checkpoint, arcana: 10000);
    expect(restored.uncappedSpeed, isFalse);
    expect(restored.checkpoint(), checkpoint);
    for (var point = 0; point < 5; point++) {
      _match(legacy);
      _match(restored);
      expect(restored.visibleMs, 260);
      expect(restored.checkpoint(), legacy.checkpoint());
    }
  });

  test('unknown checkpoint versions are rejected', () {
    final checkpoint = RuneOrbitGame(seed: 8, arcana: 0).checkpoint()
      ..['version'] = 3;
    expect(() => RuneOrbitGame.fromCheckpoint(checkpoint, arcana: 0),
        throwsFormatException);
  });
}
