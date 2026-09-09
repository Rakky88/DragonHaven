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
        reefWidth = .21 - might.clamp(0, 1) * .025,
        pickupRadius = .10 + arcana.clamp(0, 1) * .025,
        currentScale = 1 - spirit.clamp(0, 1) * .25;
  final Random _random;
  final double reefWidth, pickupRadius, currentScale;
  final gates = <SurfGate>[];
  static const playerY = .80;
  double x = .5, targetX = .5, time = 0;
  double _accumulator = 0, _nextGate = 1.0;
  int _serial = 0, mistakes = 0;
  bool get finished => mistakes >= 3;
  double get current => sin(time * .85) * .052 * currentScale;
  double get speed => min(.62, .22 + time * .005);
  double get interval => max(.78, 1.7 - time * .013);

  void steer(double position) => targetX = position.clamp(.055, .945);

  List<SurfAction> advance(double seconds) {
    final actions = <SurfAction>[];
    if (finished || !seconds.isFinite || seconds <= 0) return actions;
    _accumulator += min(seconds, 80);
    const dt = 1 / 120;
    while (_accumulator >= dt && !finished) {
      _accumulator -= dt;
      time += dt;
      x = (x + (targetX - x).clamp(-dt * 1.45, dt * 1.45) + current * dt)
          .clamp(.045, .955);
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
