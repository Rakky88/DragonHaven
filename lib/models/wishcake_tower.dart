import 'dart:math';

import 'trial_expertise.dart';

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
      : baseWidth = TrialExpertise.cakeWidth(might),
        perfectTolerance = TrialExpertise.cakeTolerance(arcana),
        speedAssist = 1 / TrialExpertise.speedScale(spirit),
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
  bool get finished => mistakes >= 1;
  WishcakeLayer get top => layers.last;

  Map<String, dynamic> checkpoint() => {
        'fromRight': _fromRight,
        'readyAt': readyAt,
        'perfectStreak': perfectStreak,
        'mistakes': mistakes,
        'placed': placed,
        'layers': [
          for (final l in layers) [l.left, l.width, l.number]
        ],
      };

  void restoreCheckpoint(Map<String, dynamic> state) {
    _fromRight = state['fromRight'] as bool;
    readyAt = (state['readyAt'] as num).toDouble();
    perfectStreak = state['perfectStreak'] as int;
    mistakes = state['mistakes'] as int;
    placed = state['placed'] as int;
    layers.clear();
    for (final l in state['layers'] as List) {
      layers.add(WishcakeLayer(
          (l[0] as num).toDouble(), (l[1] as num).toDouble(), l[2] as int));
    }
  }

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
      // Only eight layers can be visible. Keep endless runs bounded without
      // changing their height, top geometry, score or perfect-layer streak.
      if (layers.length > 8) layers.removeAt(0);
    } else {
      mistakes++;
      perfectStreak = 0;
      offcuts.add(falling);
      // Keep the earned tower visible. The first miss ends this attempt.
    }
    _fromRight = !_fromRight;
    readyAt = seconds + .42;
    return WishcakeDrop(
        hit: hit, perfect: perfect, falling: falling, offcuts: offcuts);
  }
}
