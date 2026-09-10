import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/trial_input.dart';
import 'package:dragon_haven/models/trial_run_model.dart';

/// Synthetic input pilot used only by replay/VM parity checks, never the app.
void pilotTrial(TrialRunModel model, int at,
    void Function(int, TrialControl, [int, int]) press) {
  switch (model.kind) {
    case TrialKind.cavernFlight:
      if (at % 660 == 0) press(at, TrialControl.flap);
    case TrialKind.ruinBreaker:
      if (!model.ruin!.locked && (model.ruin!.meter - .5).abs() < .015) {
        press(at, TrialControl.strikeRuin);
      }
    case TrialKind.runeweaver:
      if (model.runes!.accepting) {
        if (model.runes!.rounds >= 8) {
          press(
              at, TrialControl.tapRune, (model.runes!.sequence.first + 1) % 5);
        } else {
          for (final rune in List.of(model.runes!.sequence)) {
            press(at, TrialControl.tapRune, rune);
          }
        }
      }
    case TrialKind.witchlightWard:
      if (model.phase == 0 && model.witchReady && at > model.promptUntilMs) {
        press(at, TrialControl.choosePumpkin, model.pumpkinPosition);
      } else if (model.phase == 1 && model.witchReady) {
        press(at, TrialControl.configureTrace, 320 * 4, 400 * 4);
        final points = List.of(model.trace!.route);
        press(at, TrialControl.beginPath, (points.first.x * 4).round(),
            (points.first.y * 4).round());
        for (final p in points.skip(1)) {
          press(at, TrialControl.followPath, (p.x * 4).round(),
              (p.y * 4).round());
        }
      }
    case TrialKind.hollyfrostGiftforge:
      if (model.arcade!.parcels.isNotEmpty) {
        final p = model.arcade!.parcels.first;
        press(at, TrialControl.deliverGift, p.id, p.type);
      }
    case TrialKind.midnightChime:
      for (final note in model.arcade!.notes
          .where((n) => (n.strikeAt - at / 1000).abs() < .02)
          .toList()) {
        press(at, TrialControl.strikeChime, note.lane);
      }
    case TrialKind.rosevowRelay:
      if (model.arcade!.canInput) {
        press(at, TrialControl.moveHearts,
            model.arcade!.maze.solution()!.first.index);
      }
    case TrialKind.prismaticParade:
      if (model.arcade!.canInput) {
        final cell = model.arcade!.prisms.solutionMasks.keys
            .where((i) =>
                model.arcade!.prisms.connectors[i] !=
                model.arcade!.prisms.solutionMasks[i])
            .firstOrNull;
        if (cell != null) press(at, TrialControl.rotatePrism, cell);
      }
    case TrialKind.wishcakeTower:
      if ((model.cake!.movingLeft(at / 1000) - model.cake!.top.left).abs() <
          .02) {
        press(at, TrialControl.dropCake);
      }
    case TrialKind.moonlitOrchard:
      if (model.orchardReady) {
        var placed = false;
        for (var index = 0; index < 3 && !placed; index++) {
          final piece = model.orchard!.tray[index];
          if (piece == null) continue;
          for (var cell = 0; cell < 42; cell++) {
            if (model.orchard!.fits(piece, cell % 6, cell ~/ 6)) {
              press(at, TrialControl.placeFruit, index, cell);
              placed = true;
              break;
            }
          }
        }
        if (!placed) {
          press(at, TrialControl.rotateFruit,
              model.orchard!.tray.indexWhere((p) => p != null));
        }
      }
    case TrialKind.sunwakeSurf:
      if (!model.surfHeld) {
        press(at, TrialControl.grabDragon, (model.surf!.x * 4096).round(),
            (.8 * 4096).round());
      }
      final next = model.surf!.gates.where((g) => !g.resolved).firstOrNull;
      if (next != null) {
        final x =
            at < 130000 ? next.pearlX : ((next.safeLane + 1) % 3 + .5) / 3;
        press(at, TrialControl.steerDragon, (x * 4096).round());
      }
  }
}
