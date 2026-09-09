import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Six similar lanterns: the eyes and the missing tooth identify the match.
class WitchlightPumpkin extends StatelessWidget {
  const WitchlightPumpkin({super.key, required this.variant});

  final int variant;

  static String assetFor(int variant) =>
      'assets/images/events/halloween/arcana_pumpkin_${variant % 6}.webp';

  @override
  Widget build(BuildContext context) => Image.asset(
        assetFor(variant),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      );
}

/// The same centerline and width drive drawing and pointer validation.
class WitchlightTracePath extends StatefulWidget {
  const WitchlightTracePath({
    super.key,
    required this.enabled,
    this.mirrored = false,
    this.seed = 0,
    required this.tolerance,
    required this.onResult,
  });

  final bool enabled;
  final bool mirrored;
  final int seed;
  final double tolerance;
  final ValueChanged<bool> onResult;

  static List<Offset> points(Size size, {bool mirrored = false, int seed = 0}) {
    final original = [
      const Offset(.16, .84),
      const Offset(.32, .64),
      const Offset(.72, .64),
      const Offset(.80, .40),
      const Offset(.40, .30),
      const Offset(.24, .12),
    ].map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();
    double length(List<Offset> points) => List.generate(
            points.length - 1, (i) => (points[i + 1] - points[i]).distance)
        .fold(0.0, (a, b) => a + b);
    final targetLength = length(original);
    final random = math.Random(seed);
    // Jitter bends, then normalize the whole route to the original arc length.
    // Reject shapes that would push any of the corridor outside the arena.
    for (var attempt = 0; attempt < 256; attempt++) {
      var route = original
          .map((p) =>
              p +
              Offset((random.nextDouble() - .5) * size.width * .18,
                  (random.nextDouble() - .5) * size.height * .12))
          .toList();
      final scale = targetLength / length(route);
      route = route.map((p) => p * scale).toList();
      final left = route.map((p) => p.dx).reduce(math.min);
      final right = route.map((p) => p.dx).reduce(math.max);
      final top = route.map((p) => p.dy).reduce(math.min);
      final bottom = route.map((p) => p.dy).reduce(math.max);
      if (right - left > size.width * .82 || bottom - top > size.height * .82) {
        continue;
      }
      final center = Offset((left + right) / 2, (top + bottom) / 2);
      final flip = random.nextBool() != mirrored;
      return route.map((p) {
        final centered = p - center;
        return Offset(size.width / 2 + (flip ? -centered.dx : centered.dx),
            size.height / 2 + centered.dy);
      }).toList();
    }
    return original
        .map((p) => Offset(mirrored ? size.width - p.dx : p.dx, p.dy))
        .toList();
  }

  @override
  State<WitchlightTracePath> createState() => _WitchlightTracePathState();
}

class _WitchlightTracePathState extends State<WitchlightTracePath>
    with SingleTickerProviderStateMixin {
  late final _glimmer = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800));
  int? _pointer;
  Offset? _position;
  int _segment = 0;
  bool _reported = false;
  final _trail = <Offset>[];

  void _syncAnimation() {
    if (widget.enabled && !MediaQuery.disableAnimationsOf(context)) {
      if (!_glimmer.isAnimating) _glimmer.repeat();
    } else {
      _glimmer.stop();
      _glimmer.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(WitchlightTracePath oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    _glimmer.dispose();
    super.dispose();
  }

  double _distance(Offset p, Offset a, Offset b) {
    final vector = b - a;
    final t = (((p - a).dx * vector.dx + (p - a).dy * vector.dy) /
            vector.distanceSquared)
        .clamp(0.0, 1.0);
    return (p - (a + vector * t)).distance;
  }

  void _result(bool success) {
    if (_reported) return;
    _reported = true;
    _pointer = null;
    widget.onResult(success);
  }

  void _move(Offset next, List<Offset> points, double radius) {
    final previous = _position!;
    // Validate the entire movement, including sparse fast-swipe events.
    final steps = math.max(1, ((next - previous).distance / 2).ceil());
    for (var i = 1; i <= steps; i++) {
      final sample = Offset.lerp(previous, next, i / steps)!;
      if (_segment < points.length - 2 &&
          (sample - points[_segment + 1]).distance <= radius) {
        _segment++;
      }
      if (_distance(sample, points[_segment], points[_segment + 1]) > radius) {
        _result(false);
        return;
      }
    }
    setState(() {
      _position = next;
      _trail.add(next);
    });
    if (_segment == points.length - 2 &&
        (next - points.last).distance <= radius) {
      _result(true);
    }
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final size = constraints.biggest;
        final points = WitchlightTracePath.points(size,
            mirrored: widget.mirrored, seed: widget.seed);
        final radius = 12.0 + widget.tolerance.clamp(0.0, 1.0) * 4;
        return Listener(
          key: const Key('witchlight-trace-surface'),
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (!widget.enabled || _reported || _pointer != null) return;
            if ((event.localPosition - points.first).distance > radius) return;
            setState(() {
              _pointer = event.pointer;
              _position = event.localPosition;
              _segment = 0;
              _trail.add(event.localPosition);
            });
          },
          onPointerMove: (event) {
            if (widget.enabled && event.pointer == _pointer) {
              _move(event.localPosition, points, radius);
            }
          },
          onPointerUp: (event) {
            if (event.pointer == _pointer) _result(false);
          },
          onPointerCancel: (event) {
            if (event.pointer == _pointer) _result(false);
          },
          child: AnimatedBuilder(
              animation: _glimmer,
              builder: (context, _) {
                final shimmer = math.sin(_glimmer.value * math.pi * 2);
                final wisp = _position ?? points.first;
                return IgnorePointer(
                    child: Stack(clipBehavior: Clip.none, children: [
                  Positioned.fill(
                      child: CustomPaint(
                          painter: _TracePainter(points, radius,
                              List.of(_trail), _glimmer.value))),
                  Positioned(
                      left: points.last.dx - 30,
                      top: points.last.dy - 32,
                      width: 60,
                      height: 64,
                      child: Transform.scale(
                          scale: 1 + shimmer * .025,
                          child: Image.asset(
                              'assets/images/events/halloween/arcade_lantern.png',
                              cacheWidth: 192,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              excludeFromSemantics: true))),
                  Positioned(
                      left: wisp.dx - 20,
                      top: wisp.dy - 25 + (_pointer == null ? shimmer * 2 : 0),
                      width: 40,
                      height: 44,
                      child: Transform.scale(
                          scale: 1 + shimmer * .055,
                          child: Image.asset(
                              'assets/images/events/halloween/arcade_wisp.png',
                              cacheWidth: 144,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              excludeFromSemantics: true))),
                ]));
              }),
        );
      });
}

class _TracePainter extends CustomPainter {
  const _TracePainter(this.points, this.radius, this.trail, this.phase);
  final List<Offset> points;
  final double radius;
  final List<Offset> trail;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
        path,
        paint
          ..color = const Color(0x668F63D9)
          ..strokeWidth = radius * 2 + 12
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    paint.maskFilter = null;
    canvas.drawPath(
        path,
        paint
          ..color = const Color(0xFFFFBC63)
          ..strokeWidth = radius * 2 + 4);
    canvas.drawPath(
        path,
        paint
          ..color = Colors.black
          ..strokeWidth = radius * 2);
    if (trail.length > 1) {
      final traced = Path()..moveTo(trail.first.dx, trail.first.dy);
      for (final p in trail.skip(1)) {
        traced.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
          traced,
          paint
            ..color = const Color(0x9978F2BF)
            ..strokeWidth = 9
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      paint.maskFilter = null;
      canvas.drawPath(
          traced,
          paint
            ..color = const Color(0xFFC5FFB2)
            ..strokeWidth = 5);
      // Embers only travel over the line the player has actually traced.
      final metric = traced.computeMetrics().firstOrNull;
      for (var i = 0; metric != null && i < 4; i++) {
        final ember =
            metric.getTangentForOffset(metric.length * ((phase + i / 4) % 1));
        if (ember != null) {
          canvas.drawCircle(
              ember.position, 2, Paint()..color = const Color(0xFFFFF1C6));
        }
      }
    }
    // The start marker remains visible beneath the hovering spirit.
    canvas.drawCircle(
        points.first, radius - 3, Paint()..color = const Color(0x5578F2BF));
  }

  @override
  bool shouldRepaint(_TracePainter oldDelegate) => true;
}
