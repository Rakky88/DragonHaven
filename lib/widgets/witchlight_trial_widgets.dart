import '../services/trial_gameplay_controller.dart';
import '../models/trial_input.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/witchlight_trace.dart';

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
    this.controller,
  });

  final TrialGameplayController? controller;
  final bool enabled;
  final bool mirrored;
  final int seed;
  final double tolerance;
  final ValueChanged<bool> onResult;

  static List<Offset> points(Size size,
          {bool mirrored = false, int seed = 0}) =>
      WitchlightTrace.points(size.width, size.height,
              mirrored: mirrored, seed: seed)
          .map((p) => Offset(p.x, p.y))
          .toList();

  @override
  State<WitchlightTracePath> createState() => _WitchlightTracePathState();
}

class _WitchlightTracePathState extends State<WitchlightTracePath>
    with SingleTickerProviderStateMixin {
  late final _glimmer = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800));
  int? _pointer;
  Offset? _position;
  WitchlightTrace? _trace;
  Size? _traceSize;
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
    if (oldWidget.seed != widget.seed ||
        oldWidget.mirrored != widget.mirrored ||
        oldWidget.tolerance != widget.tolerance) {
      _trace = null;
      _reported = false;
    }
    _syncAnimation();
  }

  @override
  void dispose() {
    _glimmer.dispose();
    super.dispose();
  }

  void _result(bool success) {
    if (_reported) return;
    _reported = true;
    _pointer = null;
    widget.onResult(success);
  }

  Offset _quantize(Offset point) => widget.controller == null
      ? point
      : Offset((point.dx * 4).round() / 4, (point.dy * 4).round() / 4);
  void _move(Offset next) {
    next = _quantize(next);
    if (widget.controller case final controller?) {
      controller.input(
          TrialControl.followPath,
          (next.dx * 4).round().clamp(-65535, 65535),
          (next.dy * 4).round().clamp(-65535, 65535));
    } else {
      _trace!.move(math.Point(next.dx, next.dy));
    }
    if (_trace!.result == false) {
      _result(false);
      return;
    }
    setState(() {
      _position = next;
      _trail.add(next);
    });
    if (_trace!.result == true) _result(true);
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final size = widget.controller == null
            ? constraints.biggest
            : Size((constraints.maxWidth * 4).round() / 4,
                (constraints.maxHeight * 4).round() / 4);
        if (_trace == null ||
            (_traceSize != size && _pointer == null && !_reported)) {
          _traceSize = size;
          _trace = WitchlightTrace(
              width: size.width,
              height: size.height,
              seed: widget.seed,
              mirrored: widget.mirrored,
              tolerance: widget.tolerance);
          _pointer = null;
          _position = null;
          _trail.clear();
        }
        final points = _trace!.route.map((p) => Offset(p.x, p.y)).toList();
        final radius = 12.0 + widget.tolerance.clamp(0.0, 1.0) * 4;
        return Listener(
          key: const Key('witchlight-trace-surface'),
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (!widget.enabled || _reported || _pointer != null) return;
            final point = _quantize(event.localPosition);
            if (widget.controller case final controller?) {
              if (controller.model.trace == null) {
                controller.input(
                    TrialControl.configureTrace,
                    (_traceSize!.width * 4).round(),
                    (_traceSize!.height * 4).round());
              }
              controller.input(TrialControl.beginPath, (point.dx * 4).round(),
                  (point.dy * 4).round());
              _trace = controller.model.trace;
              if (_trace?.active != true) return;
            } else if (!_trace!.begin(math.Point(point.dx, point.dy))) {
              return;
            }
            setState(() {
              _pointer = event.pointer;
              _position = event.localPosition;
              _trail.add(event.localPosition);
            });
          },
          onPointerMove: (event) {
            if (widget.enabled && event.pointer == _pointer) {
              _move(event.localPosition);
            }
          },
          onPointerUp: (event) {
            if (event.pointer == _pointer) {
              if (widget.controller case final controller?) {
                controller.input(TrialControl.releasePath);
              } else {
                _trace!.release();
              }
              _result(false);
            }
          },
          onPointerCancel: (event) {
            if (event.pointer == _pointer) {
              if (widget.controller case final controller?) {
                controller.input(TrialControl.releasePath);
              } else {
                _trace!.release();
              }
              _result(false);
            }
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
      // Leave twinkling stardust only where the finger has already travelled.
      // Arc-length placement stays steady as new pointer samples arrive. The
      // deterministic shimmer adds no randomness to the game's seeded rules.
      final metric = traced.computeMetrics().firstOrNull;
      if (metric != null) {
        final spacing = math.max(7.0, metric.length / 240);
        final dust = Paint();
        for (var i = 0; i * spacing < metric.length; i++) {
          final tangent = metric.getTangentForOffset(i * spacing);
          if (tangent == null) continue;
          final pulse = (math.sin(phase * math.pi * 2 + i * 2.4) + 1) / 2;
          final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
          final position = tangent.position +
              normal * (math.sin(i * 2.39996) * 5 + (pulse - .5) * 2);
          final color =
              i.isEven ? const Color(0xFFADFFE0) : const Color(0xFFFFEDB4);
          final size = (i % 3 == 0 ? 2.7 : 1.0) + pulse * 1.1;
          canvas.drawCircle(
              position,
              size * 1.8,
              dust
                ..color = color.withValues(alpha: .16 + pulse * .18)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5));
          dust
            ..maskFilter = null
            ..color = color.withValues(alpha: .45 + pulse * .5);
          if (i % 3 == 0) {
            // Slender four-point sparkles surrounded by smaller floating dust.
            final star = Path();
            for (var tip = 0; tip < 8; tip++) {
              final angle = tip * math.pi / 4;
              final reach = tip.isEven ? size : size * .27;
              final point = position +
                  Offset(math.sin(angle) * reach, math.cos(angle) * reach);
              if (tip == 0) {
                star.moveTo(point.dx, point.dy);
              } else {
                star.lineTo(point.dx, point.dy);
              }
            }
            canvas.drawPath(star..close(), dust);
            canvas.drawCircle(
                position,
                .65,
                Paint()
                  ..color = Colors.white.withValues(alpha: .6 + pulse * .4));
          } else {
            canvas.drawCircle(position, size, dust);
          }
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
