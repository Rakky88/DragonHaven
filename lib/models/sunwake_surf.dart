import 'dart:math';

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
      : _random = Random(seed),
        reefWidth = .25 - might.clamp(0, 1) * .025,
        pickupRadius = .10 + arcana.clamp(0, 1) * .025,
        currentScale = 1 - spirit.clamp(0, 1) * .25;
  final Random _random;
  final double reefWidth, pickupRadius, currentScale;
  final gates = <SurfGate>[];
  static const playerY = .80;
  static const maximumSteeringSpeed = 1.65;
  double x = .5, targetX = .5, time = 0;
  double _accumulator = 0, _nextGate = .20;
  bool _steering = false;
  int _serial = 0, mistakes = 0;
  bool get finished => mistakes >= 3;
  double get current => sin(time * .85) * .052 * currentScale;
  double get speed => min(1.4, .42 + time * .004 + time * time * .00011);
  double get interval => max(.56, 1.05 - time * .0065);

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
    _accumulator += min(seconds, 80);
    const dt = 1 / 120;
    while (_accumulator >= dt && !finished) {
      _accumulator -= dt;
      time += dt;
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
