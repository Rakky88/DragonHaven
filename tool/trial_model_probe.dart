import 'dart:convert';

import 'package:dragon_haven/models/classic_trial_game.dart';
import 'package:dragon_haven/models/seasonal_arcade_game.dart';
import 'package:dragon_haven/models/sunwake_surf.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/trial_input.dart';
import 'package:dragon_haven/models/trial_random.dart';
import 'package:dragon_haven/models/witchlight_trace.dart';

/// Synthetic public-layout proof included in the native/JavaScript comparison.
Map<String, Object?> trialModelProbe() {
  final rng = TrialRandom(0xffffffff);
  var surf = SunwakeSurf(seed: 918, might: .7, arcana: .4, spirit: .3);
  final surfActions = <Object>[];
  for (var frame = 0; frame < 1200; frame++) {
    final next = surf.gates.where((g) => !g.resolved).firstOrNull;
    if (next != null) surf.steer(next.pearlX);
    for (final action in surf.advance(.02)) {
      surfActions.add([action.correct, action.points, action.x, action.y]);
    }
    if (frame % 100 == 99) {
      surf =
          SunwakeSurf.fromCheckpoint(jsonDecode(jsonEncode(surf.checkpoint())));
    }
  }
  final classic = <Object>[];
  final cavern = CavernFlightGame(seed: 1, spirit: 300);
  for (var at = 0; at < 15000; at += 650) {
    cavern.flap(at);
  }
  classic.add([cavern.score, cavern.milliseconds, cavern.dragonY]);
  final ruin = RuinBreakerGame(might: 300);
  for (var at = 0; at < 15000; at += 777) {
    ruin.strike(at);
  }
  classic.add([ruin.score, ruin.round, ruin.misses, ruin.meter]);
  final runes = RuneweaverGame(seed: 87, arcana: 300);
  for (var at = 0; at < 20000; at += 10) {
    runes.advanceTo(at);
    if (runes.accepting) {
      for (final rune in List.of(runes.sequence)) {
        runes.tap(rune, at);
      }
    }
  }
  classic.add([runes.sequence, runes.positions, runes.rounds]);
  final arcade = <Object>[];
  for (final kind in [
    TrialKind.hollyfrostGiftforge,
    TrialKind.midnightChime,
    TrialKind.rosevowRelay,
    TrialKind.prismaticParade
  ]) {
    final game = SeasonalArcadeGame(
        kind: kind, seed: 17, might: .5, arcana: .5, spirit: .5);
    final actions = <Object>[];
    for (var at = 0; at <= 15000; at += 100) {
      game.advanceTo(at);
      switch (kind) {
        case TrialKind.hollyfrostGiftforge:
          if (game.parcels.isNotEmpty) {
            final parcel = game.parcels.first;
            game.deliver(parcel.id, parcel.type);
          }
        case TrialKind.midnightChime:
          for (final note in game.notes
              .where((n) => (n.strikeAt - game.time).abs() < .06)
              .toList()) {
            game.strike(note.lane);
          }
        case TrialKind.rosevowRelay:
          if (game.canInput) game.move(game.maze.solution()!.first);
        case TrialKind.prismaticParade:
          if (game.canInput) game.rotatePrism((at ~/ 100) % 16);
        default:
          break;
      }
      for (final action in game.takeActions()) {
        actions.add([action.correct, action.points, action.complete]);
      }
    }
    arcade.add([kind.name, actions, game.mistakes]);
  }
  final path =
      WitchlightTrace(width: 320, height: 400, seed: 17, tolerance: .7);
  path.begin(path.route.first);
  for (final point in path.route.skip(1)) {
    path.move(point);
  }
  return {
    'random': List.generate(100,
        (_) => [rng.nextInt(3), rng.nextDouble(), rng.nextBool(), rng.state]),
    'surf': surf.checkpoint(),
    'surfActions': surfActions,
    'classic': classic,
    'arcade': arcade,
    'path': [
      path.result,
      for (final point in path.route) [point.x, point.y]
    ],
    'encoded': TrialInputTranscript.encode(
        const [TrialInput(199999999999, TrialControl.steerDragon, -99, 65235)],
        startMilliseconds: 199999999990),
  };
}
