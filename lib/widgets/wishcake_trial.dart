import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import '../models/wishcake_tower.dart';

/// The birthday game has its own geometry and input, sharing only run results.
class WishcakeTrial extends StatefulWidget {
  const WishcakeTrial(
      {super.key,
      required this.dragon,
      required this.seed,
      required this.running,
      required this.clock,
      required this.onAction});
  final Pet dragon;
  final int seed;
  final bool running;
  final DateTime Function() clock;
  final void Function(bool correct,
      {required int points, required bool completesRound}) onAction;

  @override
  State<WishcakeTrial> createState() => _WishcakeTrialState();
}

class _WishcakeTrialState extends State<WishcakeTrial> {
  late final WishcakeTower _tower;
  Timer? _ticker;
  DateTime? _lastTick;
  double _time = 0;
  double _droppedAt = -1;
  WishcakeDrop? _drop;
  bool get _enabled =>
      widget.running && !_tower.finished && _time >= _tower.readyAt;

  @override
  void initState() {
    super.initState();
    double expertise(TrainingFocus focus) =>
        widget.dragon.trainingFor(focus).clamp(0, 400) / 400;
    _tower = WishcakeTower(
        seed: widget.seed,
        might: expertise(TrainingFocus.might),
        arcana: expertise(TrainingFocus.arcana),
        spirit: expertise(TrainingFocus.spirit));
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || !widget.running || _tower.finished) return;
      final now = widget.clock();
      final delta = _lastTick == null
          ? 0.0
          : max(0.0, now.difference(_lastTick!).inMicroseconds / 1000000);
      _lastTick = now;
      if (delta > 0) setState(() => _time += delta);
    });
  }

  @override
  void didUpdateWidget(WishcakeTrial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.running != widget.running) _lastTick = widget.clock();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _place() {
    if (!_enabled) return;
    final result = _tower.drop(_time);
    if (result == null) return;
    setState(() {
      _drop = result;
      _droppedAt = _time;
    });
    widget.onAction(result.hit, points: result.points, completesRound: true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final dropAge = _time - _droppedAt;
    final feedback = _drop == null || dropAge > .9
        ? strings.pick('Only the overlapping slice stays',
            'Alleen het overlappende stuk blijft')
        : _drop!.perfect
            ? strings.pick('Perfect fit!', 'Perfect gestapeld!')
            : _drop!.hit
                ? strings.pick('Keep your next layer centered',
                    'Houd de volgende laag in het midden')
                : strings.pick('Missed! Try the fresh cake base',
                    'Gemist! Probeer de nieuwe taartbodem');
    return Container(
      key: const Key('unique-game-wishcakeTower'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF0442939), Color(0xF0231930)]),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x99E8BB73)),
      ),
      child: Column(children: [
        Text(
            strings.pick('Stack a birthday wish', 'Stapel een verjaardagswens'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFFFFE3A1),
                fontSize: 17,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(feedback,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFFF3DCD0), fontSize: 12, height: 1.25)),
        Expanded(
            child: LayoutBuilder(
                builder: (context, box) => GestureDetector(
                      key: const Key('wishcake-drop-surface'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _enabled ? _place : null,
                      excludeFromSemantics: true,
                      child: ClipRect(
                          child: CustomPaint(
                        key: const Key('wishcake-canvas'),
                        size: Size(box.maxWidth, box.maxHeight),
                        painter: WishcakePainter(
                            layers: List.of(_tower.layers),
                            movingLeft: _tower.movingLeft(_time),
                            movingWidth: _tower.top.width,
                            showMoving: _enabled,
                            time: reduced ? 0 : _time,
                            drop: _drop,
                            dropAge: reduced ? 2 : dropAge),
                      )),
                    ))),
        const SizedBox(height: 6),
        SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('wishcake-drop-button'),
              onPressed: _enabled ? _place : null,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEAC17F),
                  foregroundColor: const Color(0xFF352435),
                  disabledBackgroundColor: const Color(0xFF826455)),
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Text(strings.pick('Drop layer', 'Laat laag vallen'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w900))),
            )),
      ]),
    );
  }
}

class WishcakePainter extends CustomPainter {
  WishcakePainter(
      {required this.layers,
      required this.movingLeft,
      required this.movingWidth,
      required this.showMoving,
      required this.time,
      this.drop,
      this.dropAge = 2});
  final List<WishcakeLayer> layers;
  final double movingLeft, movingWidth, time, dropAge;
  final bool showMoving;
  final WishcakeDrop? drop;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final layerH = min(30.0, max(15.0, (h - 90) / 8));
    final visible = max(2, min(8, ((h - 95) / layerH).floor()));
    final start = max(0, layers.length - visible);
    final shown = layers.skip(start).toList();
    final baseY = h - 28;
    final topY = baseY - shown.length * layerH;
    final movingY = max(32.0, topY - layerH - 28);
    final halo =
        Rect.fromCircle(center: Offset(w / 2, h * .48), radius: w * .5);
    canvas.drawOval(
        halo,
        Paint()
          ..shader = const RadialGradient(
                  colors: [Color(0x29FFD980), Colors.transparent])
              .createShader(halo));
    // Quiet hanging golden decorations; essential layer movement remains visible
    // in reduced-motion mode while glimmers, offcuts and confetti are suppressed.
    for (var i = 0; i < 11; i++) {
      final x = (i * .371 % 1) * w;
      final y = (i * .213 % 1) * h * .85;
      final radius = 1.0 + (sin(time * 1.5 + i) + 1) * .65;
      canvas.drawCircle(
          Offset(x, y), radius, Paint()..color = const Color(0x60ECCC8A));
    }
    final plate = Rect.fromLTWH(w * .14, baseY - 3, w * .72, 14);
    canvas.drawOval(plate.shift(const Offset(0, 8)),
        Paint()..color = const Color(0x44000000));
    canvas.drawOval(
        plate,
        Paint()
          ..shader = const LinearGradient(colors: [
            Color(0xFFA76D38),
            Color(0xFFFFE6A8),
            Color(0xFFAD783B)
          ]).createShader(plate));
    for (var i = 0; i < shown.length; i++) {
      final layer = shown[i];
      var y = baseY - (i + 1) * layerH;
      if (i == shown.length - 1 &&
          drop?.hit == true &&
          dropAge >= 0 &&
          dropAge < .28) {
        y -= (1 - Curves.easeInCubic.transform((dropAge / .28).clamp(0, 1))) *
            38;
      }
      _cake(canvas, Rect.fromLTWH(layer.left * w, y, layer.width * w, layerH),
          layer.number);
    }
    if (showMoving) {
      final rect =
          Rect.fromLTWH(movingLeft * w, movingY, movingWidth * w, layerH);
      // Fine guide lines stop at the previous layer so alignment is readable.
      final guide = Paint()
        ..color = const Color(0x66FFE3A1)
        ..strokeWidth = 1;
      for (final x in [layers.last.left * w, layers.last.right * w]) {
        for (var y = movingY + layerH; y < topY - 3; y += 8) {
          canvas.drawLine(Offset(x, y), Offset(x, min(y + 3, topY - 3)), guide);
        }
      }
      _cake(canvas, rect, layers.last.number + 1);
      _candle(canvas, Offset(rect.center.dx, rect.top), time);
    } else if (dropAge >= .28) {
      _candle(canvas,
          Offset((layers.last.left + layers.last.width / 2) * w, topY), time);
    }
    if (dropAge >= 0 && dropAge < .85 && drop != null) {
      final t = dropAge;
      for (final piece in drop!.offcuts) {
        canvas.save();
        final center =
            Offset((piece.left + piece.width / 2) * w, topY + 12 + t * t * 470);
        canvas.translate(center.dx, center.dy);
        canvas.rotate(t * (piece.left < .5 ? -1.7 : 1.7));
        _cake(
            canvas,
            Rect.fromCenter(
                center: Offset.zero, width: piece.width * w, height: layerH),
            piece.number);
        canvas.restore();
      }
      if (drop!.perfect) {
        for (var i = 0; i < 22; i++) {
          final angle = i * 2.399;
          final origin =
              Offset((layers.last.left + layers.last.width / 2) * w, topY);
          final offset = Offset(cos(angle) * t * (55 + i * 17 % 95),
              sin(angle) * t * (40 + i * 29 % 85) + t * t * 70);
          canvas.drawCircle(
              origin + offset,
              2.3 * (1 - t / .85),
              Paint()
                ..color = i.isEven
                    ? const Color(0xFFFFD777)
                    : const Color(0xFFFFB4CE));
        }
      }
    }
  }

  void _cake(Canvas canvas, Rect rect, int number) {
    if (rect.width <= 0) return;
    final icing =
        number.isEven ? const Color(0xFFFFE6C5) : const Color(0xFFF8BDD0);
    final body = RRect.fromRectAndRadius(rect, const Radius.circular(5));
    canvas.drawRRect(body.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x50000000));
    canvas.drawRRect(
        body,
        Paint()
          ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFFE4AD),
                const Color(0xFFC98650),
                const Color(0xFFF5CE8D)
              ]).createShader(rect));
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top + rect.height * .45, rect.width,
            rect.height * .14),
        Paint()..color = const Color(0xFFAC4666));
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, rect.width, 5),
        Paint()..color = icing);
    for (double x = rect.left + 4; x < rect.right; x += 10) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, rect.top + 3),
              width: 12,
              height: 12 + sin(x) * 3),
          Paint()..color = icing);
      canvas.drawCircle(Offset(x, rect.bottom - 3), 1.2,
          Paint()..color = const Color(0xFFFFEBAA));
    }
    canvas.restore();
    canvas.drawLine(
        Offset(rect.left + 4, rect.top + 1),
        Offset(rect.right - 4, rect.top + 1),
        Paint()
          ..color = const Color(0xAAFFFFFF)
          ..strokeWidth = 1);
  }

  void _candle(Canvas canvas, Offset base, double time) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(base.dx - 3, base.dy - 19, 6, 19),
            const Radius.circular(2)),
        Paint()..color = const Color(0xFFFFE7AF));
    final flame = base.translate(sin(time * 3) * 1.3, -24);
    canvas.drawCircle(
        flame,
        8,
        Paint()
          ..color = const Color(0x40FFB849)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawOval(Rect.fromCenter(center: flame, width: 6, height: 11),
        Paint()..color = const Color(0xFFFFBE56));
    canvas.drawOval(
        Rect.fromCenter(center: flame.translate(0, 2), width: 3, height: 6),
        Paint()..color = const Color(0xFFFFF0C0));
  }

  @override
  bool shouldRepaint(covariant WishcakePainter oldDelegate) => true;
}
