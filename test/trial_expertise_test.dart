import 'dart:convert';

import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/seasonal_minigame.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/trial_expertise.dart';
import 'package:dragon_haven/models/trial_input.dart';
import 'package:dragon_haven/models/trial_run_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/trial_input_pilot.dart';

void main() {
  test('expertise uses all actual points, including focused mastery totals',
      () {
    expect(TrialExpertise.cavernHitbox(950), closeTo(.905, 1e-12));
    expect(TrialExpertise.cavernHitbox(1100), closeTo(.89, 1e-12));
    expect(TrialExpertise.ruinSuccess(1000), closeTo(1.15, 1e-12));
    expect(TrialExpertise.ruinPerfect(1000), closeTo(1.05, 1e-12));
    expect(TrialExpertise.runePreviewMs(950), 595);
    expect(TrialExpertise.pumpkinPreviewMs(0), 100);
    expect(TrialExpertise.pumpkinPreviewMs(950), 950);
    expect(TrialExpertise.pumpkinPreviewMs(1200, initial: true), 2900);
    expect(TrialExpertise.pathRadius(1000), 17);
    expect(TrialExpertise.chimeWindow(1000), closeTo(.28, 1e-12));
    expect(TrialExpertise.chimePreviewSeconds(1000), closeTo(.4, 1e-12));
    expect(TrialExpertise.cakeWidth(1000), closeTo(.484, 1e-12));
    expect(TrialExpertise.cakeTolerance(1000), closeTo(.0198, 1e-12));
    expect(TrialExpertise.speedScale(1000), .9);
    expect(TrialExpertise.reefWidth(1000), closeTo(.225, 1e-12));
    expect(TrialExpertise.pickupRadius(1000), closeTo(.11, 1e-12));
    expect(TrialExpertise.currentScale(1000), .9);
    expect(TrialExpertise.smallPieceChance(0, 0, 0), .1);
    expect(TrialExpertise.smallPieceChance(400, 400, 400), closeTo(.34, 1e-12));
    expect(TrialExpertise.smallPieceChance(0, 1200, 0), closeTo(.34, 1e-12));
    for (final (points, hints) in [
      (0, 1),
      (399, 1),
      (400, 2),
      (799, 2),
      (800, 3),
      (1199, 3),
      (1200, 4)
    ]) {
      expect(TrialExpertise.hints(points), hints);
    }
  });

  test(
      'Christmas assist buys lifetime and slows progression instead of spawning',
      () {
    expect(
        SeasonalArcadePacing.parcelLifetime(20, 1000, 0) -
            SeasonalArcadePacing.parcelLifetime(20, 0, 0),
        closeTo(3, 1e-12));
    expect(SeasonalArcadePacing.parcelLifetime(20, 0, 1000),
        SeasonalArcadePacing.parcelLifetime(18, 0, 0));
    expect(SeasonalArcadePacing.parcelInterval(20, 1000),
        SeasonalArcadePacing.parcelInterval(18, 0));
  });

  test('timed trials retain total-point time plus the separate Spirit bonus',
      () {
    for (final kind in [
      TrialKind.witchlightWard,
      TrialKind.hollyfrostGiftforge,
      TrialKind.moonlitOrchard
    ]) {
      expect(
          TrialRunModel(
              kind: kind,
              seed: 9,
              training: {TrainingFocus.arcana: 1200}).durationMs,
          78600);
    }
    for (final kind in [TrialKind.rosevowRelay, TrialKind.prismaticParade]) {
      final model = TrialRunModel(
          kind: kind, seed: 9, training: {TrainingFocus.spirit: 1200});
      expect(model.durationMs, 90600);
      for (var at = 0; at < model.durationMs; at += 10) {
        model.advanceTo(at);
        pilotTrial(
            model,
            at,
            (at, control, [a = 0, b = 0]) =>
                model.apply(TrialInput(at, control, a, b)));
      }
      expect(model.arcade!.time, greaterThan(90));
      expect(model.ended, isFalse);
      model.advanceTo(90600);
      expect(model.ended, isTrue);
      expect(model.correctActions, greaterThan(200));
      expect(model.score, greaterThan(20000));
    }
  });

  test(
      'birthday survives 6000 layers, restores bounded state, and ends on one miss',
      () {
    var model =
        TrialRunModel(kind: TrialKind.wishcakeTower, seed: 4, training: {});
    for (var layer = 0; layer < 6000; layer++) {
      final cake = model.cake!;
      // Perfect midpoint on every alternating pass; score and time must keep growing.
      final at =
          ((cake.readyAt + cake.crossingSeconds(cake.readyAt) / 2) * 1000)
              .round();
      model.apply(TrialInput(at, TrialControl.dropCake));
      expect(model.ended, isFalse);
      if (layer % 100 == 99) {
        final data = jsonEncode(model.checkpoint());
        expect(data.length, lessThan(1700));
        final restored = TrialRunModel.fromCheckpoint(jsonDecode(data));
        expect(restored.checkpoint(), model.checkpoint());
        model = restored;
      }
    }
    expect(model.totalActions, 6000);
    expect(model.score, greaterThan(1000000));
    expect(model.elapsedMs, greaterThan(3600000));
    for (var miss = 0; miss < 6 && !model.ended; miss++) {
      model.apply(TrialInput(
          (model.cake!.readyAt * 1000).ceil(), TrialControl.dropCake));
    }
    expect(model.mistakes, 1);
    expect(model.ended, isTrue);
  });
}
