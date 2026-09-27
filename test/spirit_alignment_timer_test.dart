import 'dart:convert';

import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/standard_trial_games.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/trial_input.dart';
import 'package:dragon_haven/models/trial_run_model.dart';
import 'package:flutter_test/flutter_test.dart';

int _perfect(SpiritAlignmentGame game, int at, {List<TrialInput>? inputs}) {
  while ((game.playerY - game.targetY).abs() >
      SpiritAlignmentGeometry.snapTolerance * .75) {
    game.advanceTo(++at);
    expect(game.ended, isFalse);
  }
  expect(game.tap(at), isTrue);
  inputs?.add(TrialInput(at, TrialControl.flap));
  while ((game.playerX - game.targetX).abs() >
      SpiritAlignmentGeometry.snapTolerance * .75) {
    game.advanceTo(++at);
    expect(game.ended, isFalse);
  }
  expect(game.tap(at), isTrue);
  inputs?.add(TrialInput(at, TrialControl.flap));
  expect(game.latestOverlap, 100);
  return at;
}

void main() {
  test('new game starts at exactly one minute regardless of expertise', () {
    for (final spirit in [0, 300, 450]) {
      final game = SpiritAlignmentGame(seed: 4, spirit: spirit);
      expect(game.timed, isTrue);
      expect(game.remainingMs, 60000);
      expect(game.perfectPlacements, 0);
      game.advanceTo(59999);
      expect(game.ended, isFalse);
      expect(game.remainingMs, 1);
      game.advanceTo(60000);
      expect(game.ended, isTrue);
      expect(game.remainingMs, 0);
      expect(game.tap(60000), isFalse);
      expect(game.score, 0);
      game.advanceTo(90000);
      expect(game.remainingMs, 0);
    }
    final definition = trialDefinitions[TrialKind.spiritAlignment]!;
    expect(definition.durationMilliseconds({TrainingFocus.spirit: 450}), 60000);
  });

  test('any number of imperfect sets continue while the timer has time', () {
    final game = SpiritAlignmentGame(seed: 10, spirit: 300);
    var at = 0;
    for (var shape = 0; shape < 24; shape++) {
      expect(game.shapeIndex, shape % 3);
      expect(game.tap(at), isTrue);
      expect(game.tap(at), isTrue);
      expect(game.latestOverlap, 0);
      game.advanceTo(at += 700);
      expect(game.ended, isFalse);
      expect(game.roundSpeed, 1);
    }
    expect(game.round, 9);
    expect(game.score, 0);
    expect(game.perfectPlacements, 0);
    expect(game.remainingMs, 60000 - at);
    game.advanceTo(60000);
    expect(game.ended, isTrue);
  });

  test(
      'each individual perfect adds five seconds once, including after restore',
      () {
    var game = SpiritAlignmentGame(seed: 41, spirit: 300);
    var at = 0;
    for (var i = 1; i <= 6; i++) {
      at = _perfect(game, at);
      expect(game.perfectPlacements, i);
      expect(game.score, i * 100);
      expect(game.remainingMs, 60000 + i * 5000 - at);
      expect(game.tap(at), isFalse);
      expect(game.perfectPlacements, i);
      final checkpoint = jsonDecode(jsonEncode(game.checkpoint()));
      game = SpiritAlignmentGame.fromCheckpoint(checkpoint, spirit: 300);
      expect(game.checkpoint(), checkpoint);
      expect(game.tap(at + 100), isFalse);
      expect(game.perfectPlacements, i);
      game.advanceTo(at += 700);
    }
    expect(game.round, 3);
    expect(game.roundSpeed, 1);
    game.advanceTo(89999);
    expect(game.ended, isFalse);
    game.advanceTo(90000);
    expect(game.ended, isTrue);
    expect(game.remainingMs, 0);
    expect(game.score, 600);
  });

  test('time can expire while showing a result or while aligning horizontally',
      () {
    final resultGame = SpiritAlignmentGame(seed: 4, spirit: 0);
    resultGame.tap(59700);
    resultGame.tap(59700);
    expect(resultGame.waitingForResult, isTrue);
    expect(resultGame.resultUntil, 60400);
    resultGame.advanceTo(60000);
    expect(resultGame.ended, isTrue);
    expect(resultGame.score, 0);

    final horizontal = SpiritAlignmentGame(seed: 4, spirit: 0);
    horizontal.tap(59999);
    expect(horizontal.phase, SpiritAlignmentPhase.horizontal);
    expect(horizontal.tap(60000), isFalse);
    expect(horizontal.ended, isTrue);
    expect(horizontal.score, 0);
    expect(horizontal.perfectPlacements, 0);
  });

  test('timer and bonus replay identically with bounded checkpoint state', () {
    final live = SpiritAlignmentGame(seed: 32, spirit: 300);
    var replay = TrialRunModel(
        kind: TrialKind.spiritAlignment,
        seed: 32,
        training: const {TrainingFocus.spirit: 300});
    var at = 0;
    for (var shape = 0; shape < 40; shape++) {
      final inputs = <TrialInput>[];
      at = _perfect(live, at, inputs: inputs);
      for (final input in inputs) {
        replay.apply(input);
      }
      live.advanceTo(at += 700);
      replay.advanceTo(at);
      expect(replay.alignment!.checkpoint(), live.checkpoint());
      expect(replay.remainingMs, live.remainingMs);
      final checkpoint = jsonEncode(replay.checkpoint());
      expect(checkpoint.length, lessThan(1500));
      replay = TrialRunModel.fromCheckpoint(jsonDecode(checkpoint));
      expect(replay.alignment!.checkpoint(), live.checkpoint());
    }
    expect(at, greaterThan(60000));
    expect(live.ended, isFalse);
    expect(live.score, 4000);
    expect(live.perfectPlacements, 40);
    live.advanceTo(260000);
    replay.advanceTo(260000);
    expect(live.ended, isTrue);
    expect(replay.ended, isTrue);
    expect(replay.alignment!.checkpoint(), live.checkpoint());
  });

  test('old checkpoints preserve their original untimed rules after upgrade',
      () {
    final legacy = TrialRunModel(
        kind: TrialKind.spiritAlignment,
        seed: 41,
        training: const {TrainingFocus.spirit: 300},
        timedSpiritAlignment: false);
    legacy.advanceTo(120000);
    final checkpoint = jsonDecode(jsonEncode(legacy.checkpoint()));
    expect(checkpoint['alignment']['version'], 1);
    expect(checkpoint['alignment'].containsKey('perfectPlacements'), isFalse);
    final restored = TrialRunModel.fromCheckpoint(checkpoint);
    expect(restored.alignment!.timed, isFalse);
    expect(restored.ended, isFalse);
    expect(restored.checkpoint(), checkpoint);
    var at = 120000;
    for (var shape = 0; shape < 3; shape++) {
      restored.apply(TrialInput(at, TrialControl.flap));
      restored.apply(TrialInput(at, TrialControl.flap));
      restored.advanceTo(at += 700);
    }
    expect(restored.ended, isTrue);
    expect(restored.alignment!.round, 1);
  });

  test('timed checkpoint rejects impossible or missing bonus counts', () {
    final checkpoint = SpiritAlignmentGame(seed: 1, spirit: 0).checkpoint();
    for (final value in [-1, 1, 1.5, null]) {
      expect(
          () => SpiritAlignmentGame.fromCheckpoint(
              {...checkpoint, 'perfectPlacements': value},
              spirit: 0),
          throwsFormatException);
    }
  });
}
