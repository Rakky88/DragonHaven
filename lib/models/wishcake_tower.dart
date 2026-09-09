import 'dart:math';

class WishcakeLayer {
  const WishcakeLayer(this.left, this.width, this.number);
  final double left;
  final double width;
  final int number;
  double get right => left + width;
}

class WishcakeDrop {
  const WishcakeDrop(
      {required this.hit,
      required this.perfect,
      required this.falling,
      required this.offcuts});
  final bool hit;
  final bool perfect;
  final WishcakeLayer falling;
  final List<WishcakeLayer> offcuts;
  int get points => perfect ? 130 : 85;
}

/// Normalized geometry keeps timing and overlap identical on every screen size.
class WishcakeTower {
  WishcakeTower(
      {required int seed,
      double might = 0,
      double arcana = 0,
      double spirit = 0})
      : baseWidth = .44 + might.clamp(0, 1) * .04,
        perfectTolerance = .018 + arcana.clamp(0, 1) * .007,
        speedAssist = 1 + spirit.clamp(0, 1) * .08,
        _fromRight = Random(seed).nextBool() {
    layers.add(WishcakeLayer((1 - baseWidth) / 2, baseWidth, 0));
  }

  final double baseWidth;
  final double perfectTolerance;
  final double speedAssist;
  final layers = <WishcakeLayer>[];
  bool _fromRight;
  double readyAt = 0;
  int perfectStreak = 0;
  int mistakes = 0;
  int placed = 0;
  bool get finished => mistakes >= 3;
  WishcakeLayer get top => layers.last;

  double crossingSeconds(double seconds) =>
      max(.48, 1.65 - max(0, seconds) * .012 - placed * .009) * speedAssist;

  double movingLeft(double seconds) {
    final phase = (max(0, seconds - readyAt) / crossingSeconds(readyAt)) % 2;
    final progress = phase <= 1 ? phase : 2 - phase;
    return (1 - top.width) * (_fromRight ? 1 - progress : progress);
  }

  WishcakeDrop? drop(double seconds) {
    if (finished || seconds < readyAt) return null;
    final falling = WishcakeLayer(movingLeft(seconds), top.width, placed + 1);
    final overlapLeft = max(top.left, falling.left);
    final overlapRight = min(top.right, falling.right);
    final perfect = (falling.left - top.left).abs() <= perfectTolerance;
    final hit = perfect || overlapRight - overlapLeft >= .07;
    final offcuts = <WishcakeLayer>[];
    if (hit) {
      perfectStreak = perfect ? perfectStreak + 1 : 0;
      var left = perfect ? top.left : overlapLeft;
      var width = perfect ? top.width : overlapRight - overlapLeft;
      if (perfectStreak > 0 && perfectStreak % 3 == 0) {
        final restored = min(baseWidth, width + .025);
        left = (left - (restored - width) / 2).clamp(0, 1 - restored);
        width = restored;
      }
      if (!perfect) {
        if (falling.left < overlapLeft) {
          offcuts.add(WishcakeLayer(
              falling.left, overlapLeft - falling.left, falling.number));
        }
        if (falling.right > overlapRight) {
          offcuts.add(WishcakeLayer(
              overlapRight, falling.right - overlapRight, falling.number));
        }
      }
      layers.add(WishcakeLayer(left, width, ++placed));
    } else {
      mistakes++;
      perfectStreak = 0;
      offcuts.add(falling);
      // A fresh base after a miss keeps a tiny remnant from making the next
      // attempt impossible. Earned points and the number of misses persist.
      layers
        ..clear()
        ..add(WishcakeLayer((1 - baseWidth) / 2, baseWidth, placed));
    }
    _fromRight = !_fromRight;
    readyAt = seconds + .42;
    return WishcakeDrop(
        hit: hit, perfect: perfect, falling: falling, offcuts: offcuts);
  }
}
