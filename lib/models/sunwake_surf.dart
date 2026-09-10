import 'dart:math';

import 'trial_random.dart';

class SurfGate {
  SurfGate(
      {required this.id,
      required this.safeLane,
      required this.y,
      required this.reefWidth});
  final int id, safeLane;
  final double reefWidth;
  double y;
  bool resolved = false;
  double get pearlX => (safeLane + .5) / 3;
}

class SurfAction {
  const SurfAction(this.correct, this.points, this.x, this.y);
  final bool correct;
  final int points;
  final double x, y;
}

/// Fixed-step simulation: collision and current assistance do not depend on FPS.
class SunwakeSurf {
  SunwakeSurf(
      {required int seed,
      double might = 0,
      double arcana = 0,
      double spirit = 0})
      : _random = TrialRandom(seed),
        reefWidth = .25 - might.clamp(0, 1) * .025,
        pickupRadius = .10 + arcana.clamp(0, 1) * .025,
        currentScale = 1 - spirit.clamp(0, 1) * .25;
  SunwakeSurf._(
      this._random, this.reefWidth, this.pickupRadius, this.currentScale);

  factory SunwakeSurf.fromCheckpoint(Map<String, dynamic> state) {
    if (state['version'] != 1 ||
        state['random'] is! int ||
        (state['random'] as int) <= 0 ||
        (state['random'] as int) > 0xffffffff) {
      throw const FormatException('checkpoint_invalid');
    }
    final game = SunwakeSurf._(
        TrialRandom(state['random'] as int),
        (state['reefWidth'] as num).toDouble(),
        (state['pickupRadius'] as num).toDouble(),
        (state['currentScale'] as num).toDouble());
    game.x = (state['x'] as num).toDouble();
    game.targetX = (state['targetX'] as num).toDouble();
    game._elapsedMicroseconds = state['elapsedUs'] as int;
    game._ticks = state['ticks'] as int;
    game.time = game._ticks / 120;
    game._nextGate = (state['nextGate'] as num).toDouble();
    game._serial = state['serial'] as int;
    game._steering = state['steering'] as bool;
    game.mistakes = state['mistakes'] as int;
    for (final entry in state['gates'] as List) {
      final gate = SurfGate(
          id: entry['id'] as int,
          safeLane: entry['safeLane'] as int,
          y: (entry['y'] as num).toDouble(),
          reefWidth: game.reefWidth);
      gate.resolved = entry['resolved'] as bool;
      game.gates.add(gate);
    }
    return game;
  }

  Map<String, dynamic> checkpoint() => {
        'version': 1,
        'random': _random.state,
        'reefWidth': reefWidth,
        'pickupRadius': pickupRadius,
        'currentScale': currentScale,
        'x': x,
        'targetX': targetX,
        'elapsedUs': _elapsedMicroseconds,
        'ticks': _ticks,
        'nextGate': _nextGate,
        'serial': _serial,
        'steering': _steering,
        'mistakes': mistakes,
        'gates': [
          for (final gate in gates)
            {
              'id': gate.id,
              'safeLane': gate.safeLane,
              'y': gate.y,
              'resolved': gate.resolved,
            }
        ],
      };

  final TrialRandom _random;
  final double reefWidth, pickupRadius, currentScale;
  final gates = <SurfGate>[];
  static const playerY = .80;
  static const maximumSteeringSpeed = 1.65;
  double x = .5, targetX = .5, time = 0;
  double _nextGate = .20;
  int _elapsedMicroseconds = 0, _ticks = 0;
  bool _steering = false;
  int _serial = 0, mistakes = 0;
  bool get finished => mistakes >= 3;
  double get current => sin(time * .85) * .052 * currentScale;
  double get speed => min(1.6, .55 + time * .004 + time * time * .00011);
  double get interval => max(.56, .98 - time * .0055);

  void steer(double position) {
    if (finished || !position.isFinite) return;
    _steering = true;
    targetX = position.clamp(.055, .945);
  }

  void releaseSteering() {
    _steering = false;
    targetX = x;
  }

  List<SurfAction> advance(double seconds) {
    final actions = <SurfAction>[];
    if (finished || !seconds.isFinite || seconds <= 0) return actions;
    _elapsedMicroseconds += (min(seconds, 80) * 1000000).round();
    final targetTick = _elapsedMicroseconds * 120 ~/ 1000000;
    const dt = 1 / 120;
    while (_ticks < targetTick && !finished) {
      _ticks++;
      time = _ticks / 120;
      // Dragging sets a target, never a teleport. Stop pursuing it on release;
      // Spirit softens the passive current while the player is not steering.
      if (_steering) {
        x += (targetX - x)
            .clamp(-dt * maximumSteeringSpeed, dt * maximumSteeringSpeed);
      } else {
        x = (x + current * dt).clamp(.055, .945);
      }
      if (time >= _nextGate) {
        gates.add(SurfGate(
            id: _serial++,
            safeLane: _random.nextInt(3),
            y: -.12,
            reefWidth: reefWidth));
        _nextGate = time + interval;
      }
      for (final gate in gates) {
        final previous = gate.y;
        gate.y += speed * dt;
        if (!gate.resolved && previous < playerY && gate.y >= playerY) {
          gate.resolved = true;
          final hit = List.generate(3, (i) => i)
              .where((i) => i != gate.safeLane)
              .any((i) => (x - (i + .5) / 3).abs() < gate.reefWidth / 2 + .026);
          if (hit) mistakes++;
          final pearl = (x - gate.pearlX).abs() <= pickupRadius;
          actions
              .add(SurfAction(!hit, hit ? 0 : (pearl ? 130 : 70), x, playerY));
          if (finished) break;
        }
      }
      gates.removeWhere((gate) => gate.y > 1.16);
    }
    return actions;
  }
}
