import 'dart:math';

/// The renderer and the verifier use these exact bends and corridor edges.
class WitchlightTrace {
  WitchlightTrace(
      {required double width,
      required double height,
      required int seed,
      required double tolerance,
      bool mirrored = false})
      : route = points(width, height, seed: seed, mirrored: mirrored),
        radius = 12 + tolerance.clamp(0, 1) * 4;
  final List<Point<double>> route;
  final double radius;
  Point<double>? position;
  int segment = 0;
  bool? result;
  bool get active => position != null && result == null;

  static List<Point<double>> points(double width, double height,
      {bool mirrored = false, int seed = 0}) {
    final original = [
      Point(.16 * width, .84 * height),
      Point(.32 * width, .64 * height),
      Point(.72 * width, .64 * height),
      Point(.80 * width, .40 * height),
      Point(.40 * width, .30 * height),
      Point(.24 * width, .12 * height),
    ];
    double length(List<Point<double>> path) =>
        List.generate(path.length - 1, (i) => path[i + 1].distanceTo(path[i]))
            .fold(0.0, (a, b) => a + b);
    final targetLength = length(original), random = Random(seed);
    for (var attempt = 0; attempt < 256; attempt++) {
      var route = original
          .map((p) =>
              p +
              Point((random.nextDouble() - .5) * width * .18,
                  (random.nextDouble() - .5) * height * .12))
          .toList();
      final scale = targetLength / length(route);
      route = route.map((p) => p * scale).toList();
      final left = route.map((p) => p.x).reduce(min);
      final right = route.map((p) => p.x).reduce(max);
      final top = route.map((p) => p.y).reduce(min);
      final bottom = route.map((p) => p.y).reduce(max);
      if (right - left > width * .82 || bottom - top > height * .82) continue;
      final center = Point((left + right) / 2, (top + bottom) / 2);
      final flip = random.nextBool() != mirrored;
      return route.map((p) {
        final centered = p - center;
        return Point(width / 2 + (flip ? -centered.x : centered.x),
            height / 2 + centered.y);
      }).toList();
    }
    return original
        .map((p) => Point(mirrored ? width - p.x : p.x, p.y))
        .toList();
  }

  bool begin(Point<double> point) {
    if (!point.x.isFinite ||
        !point.y.isFinite ||
        active ||
        result != null ||
        point.distanceTo(route.first) > radius) {
      return false;
    }
    position = point;
    segment = 0;
    return true;
  }

  static double distance(Point<double> p, Point<double> a, Point<double> b) {
    final vector = b - a, relative = p - a;
    final denominator = vector.x * vector.x + vector.y * vector.y;
    final t = ((relative.x * vector.x + relative.y * vector.y) / denominator)
        .clamp(0.0, 1.0);
    return p.distanceTo(a + vector * t);
  }

  void move(Point<double> next) {
    if (!active) return;
    if (!next.x.isFinite ||
        !next.y.isFinite ||
        next.distanceTo(position!) > 4096) {
      result = false;
      return;
    }
    final previous = position!;
    final steps = max(1, (next.distanceTo(previous) / 2).ceil());
    for (var i = 1; i <= steps; i++) {
      final sample = previous + (next - previous) * (i / steps);
      if (segment < route.length - 2 &&
          sample.distanceTo(route[segment + 1]) <= radius) {
        segment++;
      }
      if (distance(sample, route[segment], route[segment + 1]) > radius) {
        result = false;
        return;
      }
    }
    position = next;
    if (segment == route.length - 2 && next.distanceTo(route.last) <= radius) {
      result = true;
    }
  }

  void release() {
    if (active) result = false;
  }
}
