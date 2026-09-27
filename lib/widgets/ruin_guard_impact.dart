import 'dart:math' as math;

import 'package:flutter/material.dart';

const ruinGuardBoulderAsset = 'assets/images/ui/trials/ruin_guard_boulder.png';

/// Shared by the falling stone and its fragments, so the impact breaks the
/// actual stone artwork apart without loading seven different textures.
class RuinGuardBoulder extends StatelessWidget {
  const RuinGuardBoulder({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        ruinGuardBoulderAsset,
        width: size,
        height: size,
        cacheWidth: 224,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );
}

/// Presentation only: [progress] follows the game's existing impact pause.
class RuinGuardImpact extends StatelessWidget {
  const RuinGuardImpact({
    super.key,
    required this.progress,
    required this.stoneSize,
    required this.rotation,
    this.reducedMotion = false,
  });

  final double progress;
  final double stoneSize;
  final double rotation;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final t = reducedMotion ? .32 : progress.clamp(0.0, 1.0);
    final spread = Curves.easeOutCubic.transform(t);
    final opacity = reducedMotion ? 1.0 : (1 - (t - .4) / .6).clamp(0.0, 1.0);
    return IgnorePointer(
      child: SizedBox.square(
        dimension: stoneSize * 3,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StoneImpactPainter(t, reducedMotion),
              ),
            ),
            Opacity(
              opacity: opacity,
              child: Transform.rotate(
                angle: rotation,
                child: SizedBox.square(
                  dimension: stoneSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < _fragments.length; i++)
                        Transform.translate(
                          key: ValueKey('ruin-guard-fragment-$i'),
                          offset: _fragments[i].direction * stoneSize * spread +
                              Offset(0, stoneSize * .55 * t * t),
                          child: Transform.rotate(
                            angle: _fragments[i].spin * t,
                            alignment: _fragments[i].pivot,
                            child: ClipPath(
                              clipper: _StoneFragmentClipper(_fragments[i]),
                              child: RuinGuardBoulder(size: stoneSize),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (reducedMotion)
              const Icon(Icons.verified_rounded,
                  color: Color(0xFFFFE08A), size: 30),
          ],
        ),
      ),
    );
  }
}

class _StoneFragment {
  const _StoneFragment(this.points, this.direction, this.spin, this.pivot);

  final List<Offset> points;
  final Offset direction;
  final double spin;
  final Alignment pivot;
}

// These polygons tessellate the intact sprite. Their motion is deterministic
// and consumes none of the Trial's random numbers or input transcript.
const _fragments = [
  _StoneFragment([
    Offset(0, 0),
    Offset(.48, 0),
    Offset(.44, .27),
    Offset(.55, .45),
    Offset(.27, .40),
    Offset(0, .58),
  ], Offset(-.9, -.95), -2.1, Alignment(-.5, -.5)),
  _StoneFragment([
    Offset(.48, 0),
    Offset(1, 0),
    Offset(.78, .27),
    Offset(.72, .48),
    Offset(.55, .45),
    Offset(.44, .27),
  ], Offset(.4, -1.3), 1.7, Alignment(.4, -.5)),
  _StoneFragment([
    Offset(1, 0),
    Offset(1, .62),
    Offset(.80, .58),
    Offset(.72, .48),
    Offset(.78, .27),
  ], Offset(1.2, -.45), 2.5, Alignment(.8, -.2)),
  _StoneFragment([
    Offset(0, .58),
    Offset(.27, .40),
    Offset(.55, .45),
    Offset(.50, .70),
    Offset(.29, .83),
    Offset(0, .90),
  ], Offset(-1.15, .1), -1.4, Alignment(-.5, .3)),
  _StoneFragment([
    Offset(.55, .45),
    Offset(.72, .48),
    Offset(.80, .58),
    Offset(.76, .87),
    Offset(.50, .70),
  ], Offset(.65, .3), 2.3, Alignment(.3, .3)),
  _StoneFragment([
    Offset(1, .62),
    Offset(1, 1),
    Offset(.63, 1),
    Offset(.76, .87),
    Offset(.80, .58),
  ], Offset(1.0, .7), 1.8, Alignment(.7, .7)),
  _StoneFragment([
    Offset(0, .90),
    Offset(.29, .83),
    Offset(.50, .70),
    Offset(.76, .87),
    Offset(.63, 1),
    Offset(0, 1),
  ], Offset(-.35, .85), -1.7, Alignment(-.2, .8)),
];

class _StoneFragmentClipper extends CustomClipper<Path> {
  const _StoneFragmentClipper(this.fragment);
  final _StoneFragment fragment;

  @override
  Path getClip(Size size) => Path()
    ..addPolygon([
      for (final point in fragment.points)
        Offset(point.dx * size.width, point.dy * size.height),
    ], true);

  @override
  bool shouldReclip(_StoneFragmentClipper oldClipper) =>
      fragment != oldClipper.fragment;
}

class _StoneImpactPainter extends CustomPainter {
  const _StoneImpactPainter(this.progress, this.reducedMotion);
  final double progress;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final strength = (1 - progress).clamp(0.0, 1.0);
    final radius = size.shortestSide * (.12 + .32 * progress);
    if (!reducedMotion) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFD978).withValues(alpha: strength * .32),
            const Color(0x00FFD978),
          ]).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * strength
          ..color = const Color(0xFFFFE08A).withValues(alpha: strength * .8),
      );
    }
    for (var i = 0; i < 10; i++) {
      final angle = i * math.pi / 5 + .2;
      final distance = radius * (i.isEven ? 1 : .8);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(
        point,
        (i.isEven ? 2.5 : 1.5) * strength,
        Paint()..color = const Color(0xFFFFE6A6).withValues(alpha: strength),
      );
    }
  }

  @override
  bool shouldRepaint(_StoneImpactPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      reducedMotion != oldDelegate.reducedMotion;
}
