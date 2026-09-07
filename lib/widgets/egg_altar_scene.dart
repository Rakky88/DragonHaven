import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/dragon_egg.dart';
import 'egg_art.dart';

/// One fixed altar, correctly occluded egg and continuous light choreography.
/// The twelve beats blend continuously; no mismatched sprite frames crossfade.
class EggAltarScene extends StatelessWidget {
  const EggAltarScene({super.key, this.egg, this.progress});
  final DragonEgg? egg;
  final double? progress;
  static const backdrop = 'assets/images/egg_altar/altar_grove.png';
  static const altar = 'assets/images/egg_altar/altar_empty.png';

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: LayoutBuilder(builder: (_, bounds) {
            final width = bounds.maxWidth;
            final height = bounds.maxHeight;
            final side = math.min(width * .94, height * 1.24);
            final left = (width - side) / 2;
            final top = height - side * .99;
            final p = (progress ?? 0).clamp(0.0, 1.0);
            final rise = Curves.easeInOutCubic
                .transform(((p - .16) / .42).clamp(0.0, 1.0));
            final dissolve = ((p - .43) / .25).clamp(0.0, 1.0);
            final charge = math.sin(math.pi * (p / .8).clamp(0.0, 1.0));
            Widget stone() => Image.asset(altar,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true);
            return Stack(children: [
              Positioned.fill(
                  child: Image.asset(backdrop,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      cacheWidth: 1024)),
              Positioned.fill(
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                    const Color(0x22100B23),
                    const Color(0x00100B23),
                    const Color(0xAA100B23)
                  ])))),
              Positioned(
                  left: left,
                  top: top,
                  width: side,
                  height: side,
                  child: stone()),
              if (egg != null && dissolve < 1) ...[
                // Contact shadow and reflected basin light anchor the egg in space.
                Positioned(
                    left: left + side * .36,
                    top: top + side * .513,
                    width: side * .28,
                    height: side * .052,
                    child: Opacity(
                        opacity: (1 - rise) * .24,
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: const [
                              BoxShadow(
                                  color: Color(0xEE241232),
                                  blurRadius: 8,
                                  spreadRadius: 2)
                            ])))),
                Positioned(
                    left: left + side * .30,
                    top: math.max(12.0, top + side * (.285 - rise * .24)),
                    width: side * .40,
                    height: side * .29,
                    child: Transform.scale(
                        scale: 1 + .045 * charge,
                        child: ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (rect) => LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: const [
                                      Colors.transparent,
                                      Colors.white,
                                      Colors.white
                                    ],
                                    stops: [
                                      math.max(0, dissolve * 1.3 - .25),
                                      (dissolve * 1.3).clamp(.001, 1.0),
                                      1
                                    ]).createShader(rect),
                            child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                    Color.lerp(Colors.transparent,
                                        const Color(0xFFFFEABC), charge * .50)!,
                                    BlendMode.srcATop),
                                child: EggArt(
                                    lineageId: egg!.lineageId,
                                    specialEggId: egg!.specialEggId,
                                    height: side * .29))))),
                // The near lip is above the egg, while the far rim is behind it.
                Positioned(
                    left: left,
                    top: top,
                    width: side,
                    height: side,
                    child: ClipPath(
                        clipper: const _AltarNearRim(), child: stone())),
              ],
              if (progress != null && p > 0 && p < 1)
                Positioned.fill(
                    child: IgnorePointer(
                        child: CustomPaint(
                            painter: _WeaveLightPainter(
                                progress: p, side: side, altarTop: top)))),
              Positioned.fill(
                  child: IgnorePointer(
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                  color: const Color(0x66D8BF87), width: 1))))),
            ]);
          }),
        ),
      );
}

class _AltarNearRim extends CustomClipper<Path> {
  const _AltarNearRim();
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, size.height * .45)
    ..lineTo(size.width * .17, size.height * .47)
    ..quadraticBezierTo(size.width * .50, size.height * .665, size.width * .84,
        size.height * .47)
    ..lineTo(size.width, size.height * .45)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();
  @override
  bool shouldReclip(_AltarNearRim oldClipper) => false;
}

class _WeaveLightPainter extends CustomPainter {
  _WeaveLightPainter(
      {required this.progress, required this.side, required this.altarTop});
  final double progress;
  final double side;
  final double altarTop;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress;
    final origin = Offset(size.width / 2, altarTop + side * .49);
    final strength = math.sin(math.pi * p).clamp(0.0, 1.0);
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        Color(0xFFFFDCA0).withValues(alpha: strength * .30),
        Color(0xFFBB9BFF).withValues(alpha: strength * .14),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: origin, radius: side * .33));
    canvas.drawCircle(origin, side * .33, glow);
    // Twelve overlapping ribbons give a steady build, lift, unweaving and rest.
    for (var beat = 0; beat < 12; beat++) {
      final t = ((p - beat * .035) / .60).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final opacity = math.sin(t * math.pi) * strength;
      final direction = beat.isEven ? 1.0 : -1.0;
      final x =
          math.sin(t * math.pi * 1.7 + beat * .52) * side * .14 * direction;
      final end = origin + Offset(x * (1 - t), -side * .50 * t);
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..cubicTo(origin.dx + x, origin.dy - side * .13, end.dx - x * .65,
            end.dy + side * .13, end.dx, end.dy);
      final color =
          beat % 3 == 0 ? const Color(0xFFF9DD9B) : const Color(0xFFD7C2FF);
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = color.withValues(alpha: opacity * .15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .65
            ..color = color.withValues(alpha: opacity * .60));
    }
    for (var i = 0; i < 52; i++) {
      final start = .22 + (i % 13) * .025;
      final t = ((p - start) / .43).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final angle = i * 2.39996;
      final spread = side * (.04 + .15 * math.sin(math.pi * t));
      final point = origin +
          Offset(math.cos(angle + t * 2) * spread,
              -side * (.1 + .47 * t) + math.sin(angle) * side * .05 * (1 - t));
      final alpha = math.sin(math.pi * t) * .85;
      final color =
          i.isEven ? const Color(0xFFFFE8AD) : const Color(0xFFC9AEFF);
      canvas.drawCircle(
          point,
          2.6,
          Paint()
            ..color = color.withValues(alpha: alpha * .4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawCircle(point, .7 + (i % 3) * .3,
          Paint()..color = color.withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(_WeaveLightPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      side != oldDelegate.side ||
      altarTop != oldDelegate.altarTop;
}
