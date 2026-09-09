import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/moonlit_orchard.dart';
import '../models/pet.dart';
import '../models/sunwake_surf.dart';
import '../models/trial.dart';
import 'dragon_art.dart';

class SummerTrials extends StatefulWidget {
  const SummerTrials(
      {super.key,
      required this.kind,
      required this.dragon,
      required this.seed,
      required this.running,
      required this.clock,
      required this.onAction});
  final TrialKind kind;
  final Pet dragon;
  final int seed;
  final bool running;
  final DateTime Function() clock;
  final void Function(bool correct,
      {required int points, required bool completesRound}) onAction;
  @override
  State<SummerTrials> createState() => _SummerTrialsState();
}

class _SummerTrialsState extends State<SummerTrials> {
  late final SunwakeSurf _surf;
  late final MoonlitOrchard _orchard;
  Timer? _ticker;
  DateTime? _lastTick;
  double _time = 0, _basketResetAt = 0, _lastHarvest = -10;
  int _selected = 0;
  final _sparkles = <({double x, double y, double at})>[];
  String _hint = '';
  bool get _sunwake => widget.kind == TrialKind.sunwakeSurf;
  bool get _enabled =>
      widget.running &&
      (_sunwake
          ? !_surf.finished
          : !_orchard.finished && _time >= _basketResetAt);

  @override
  void initState() {
    super.initState();
    double stat(TrainingFocus f) =>
        widget.dragon.trainingFor(f).clamp(0, 400) / 400;
    _surf = SunwakeSurf(
        seed: widget.seed,
        might: stat(TrainingFocus.might),
        arcana: stat(TrainingFocus.arcana),
        spirit: stat(TrainingFocus.spirit));
    _orchard = MoonlitOrchard(
        seed: widget.seed,
        might: stat(TrainingFocus.might),
        arcana: stat(TrainingFocus.arcana),
        spirit: stat(TrainingFocus.spirit));
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || !widget.running) return;
      final now = widget.clock();
      final elapsed = _lastTick == null
          ? 0.0
          : max(0.0, now.difference(_lastTick!).inMicroseconds / 1000000);
      _lastTick = now;
      if (elapsed <= 0) return;
      final actions = _sunwake ? _surf.advance(elapsed) : <SurfAction>[];
      setState(() {
        _time += elapsed;
        _sparkles.removeWhere((s) => _time - s.at > .9);
        for (final action in actions.where((a) => a.correct)) {
          _sparkles.add((x: action.x, y: action.y, at: _time));
        }
      });
      for (final action in actions) {
        widget.onAction(action.correct,
            points: action.points, completesRound: true);
      }
    });
  }

  @override
  void didUpdateWidget(SummerTrials oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.running != widget.running) _lastTick = widget.clock();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Widget _sprite(String path, {double? width, double? height}) =>
      Image.asset(path,
          width: width,
          height: height,
          fit: BoxFit.contain,
          cacheWidth: 192,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true);

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      key: ValueKey('unique-game-${widget.kind.name}'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: _sunwake ? const Color(0xED123E46) : const Color(0xEF34291D),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
              color: _sunwake
                  ? const Color(0xFF9DE8D3)
                  : const Color(0xFFEAC286))),
      child: _sunwake ? _buildSurf(s) : _buildOrchard(s),
    );
  }

  Widget _buildSurf(AppStrings s) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Column(children: [
      Text(s.pick('Follow the sunpearls', 'Volg de zonneparels'),
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Color(0xFFFFE6B4), fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Expanded(child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        void steer(Offset p) {
          if (_enabled) setState(() => _surf.steer(p.dx / w));
        }

        return Semantics(
            label: s.pick('Slide left or right to steer',
                'Schuif naar links of rechts om te sturen'),
            child: GestureDetector(
                key: const Key('sunwake-steering'),
                behavior: HitTestBehavior.opaque,
                onPanDown: (d) => steer(d.localPosition),
                onPanUpdate: (d) => steer(d.localPosition),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(children: [
                      Positioned.fill(
                          child: DecoratedBox(
                              decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                            Color(0xFF267F87),
                            Color(0xFF0E495D),
                            Color(0xFF0A3446)
                          ])))),
                      Positioned.fill(
                          child: CustomPaint(
                              painter: _SurfWater(reduced ? 0 : _surf.time))),
                      for (final gate in _surf.gates) ...[
                        for (var lane = 0; lane < 3; lane++)
                          if (lane != gate.safeLane)
                            Positioned(
                                left: (lane + .5) / 3 * w - w * .16,
                                top: gate.y * h - w * .13,
                                width: w * .32,
                                height: w * .26,
                                child: _sprite(
                                    'assets/images/events/sunwake/arcade_reef.png')),
                        if (!gate.resolved)
                          Positioned(
                              left: gate.pearlX * w - w * .075,
                              top: gate.y * h - w * .075,
                              width: w * .15,
                              height: w * .15,
                              child: Transform.rotate(
                                  angle: reduced
                                      ? 0
                                      : sin(_time * 2 + gate.id) * .10,
                                  child: _sprite(
                                      'assets/images/events/sunwake/arcade_pearl.png'))),
                      ],
                      Positioned(
                          left: _surf.x * w - 38,
                          top: SunwakeSurf.playerY * h - 38,
                          width: 76,
                          height: 76,
                          child: Transform.rotate(
                              angle: (_surf.targetX - _surf.x).clamp(-.18, .18),
                              child: DragonArt(
                                  height: 76,
                                  animate: false,
                                  stageKey: widget.dragon.stageKey,
                                  lineageId: widget.dragon.lineageId,
                                  evolutionPath:
                                      widget.dragon.evolutionPath ?? 'earth',
                                  prismatic: widget.dragon.spectral))),
                      if (!reduced)
                        for (final sparkle in _sparkles)
                          Positioned(
                              left: sparkle.x * w - 35,
                              top: sparkle.y * h -
                                  35 -
                                  (_time - sparkle.at) * 50,
                              child: Opacity(
                                  opacity: (1 - (_time - sparkle.at) / .9)
                                      .clamp(0, 1),
                                  child: Icon(Icons.auto_awesome_rounded,
                                      color: const Color(0xFFFFE4A0),
                                      size: 70 + (_time - sparkle.at) * 20))),
                    ]))));
      })),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
            tooltip: s.pick('Steer left', 'Stuur naar links'),
            onPressed: _enabled
                ? () => setState(() => _surf.steer(_surf.targetX - .25))
                : null,
            icon: const Icon(Icons.chevron_left, color: Colors.white)),
        Flexible(
            child: Text(s.pick('Slide to steer', 'Schuif om te sturen'),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Color(0xFFCDF6EA), fontSize: 12))),
        IconButton(
            tooltip: s.pick('Steer right', 'Stuur naar rechts'),
            onPressed: _enabled
                ? () => setState(() => _surf.steer(_surf.targetX + .25))
                : null,
            icon: const Icon(Icons.chevron_right, color: Colors.white)),
      ]),
    ]);
  }

  void _placeFruit(int index, int x, int y) {
    if (!_enabled) return;
    final result = _orchard.place(index, x, y);
    final s = AppStrings.of(context);
    if (result == null) {
      setState(() => _hint = s.pick(
          'Leave room for every fruit', 'Maak ruimte voor elk stuk fruit'));
      return;
    }
    setState(() {
      _hint = result.rows > 0
          ? s.pick('A beautiful harvest!', 'Een prachtige oogst!')
          : '';
      if (result.rows > 0) _lastHarvest = _time;
      _selected = _orchard.tray.indexWhere((v) => v != null);
      if (result.overflow) {
        _hint = s.pick('Basket full!', 'Mand vol!');
        _basketResetAt = _time + .85;
        _orchard.freshBasket();
        _selected = 0;
      }
    });
    widget.onAction(true,
        points: result.rows > 0 ? 130 : 55 + result.fruitCount * 12,
        completesRound: true);
    if (result.overflow) {
      widget.onAction(false, points: 0, completesRound: true);
    }
  }

  String _fruitAsset(int type) =>
      'assets/images/events/harvestmoon/fruit_${const [
        'apple',
        'pear',
        'plum'
      ][type]}.png';

  Widget _piece(OrchardPiece piece, double side) => SizedBox(
      width: side,
      height: side,
      child: Center(
          child: SizedBox(
              width: side / 3 * piece.width,
              height: side / 3 * piece.height,
              child: Stack(children: [
                for (final c in piece.cells)
                  Positioned(
                      left: c.$1 * side / 3,
                      top: c.$2 * side / 3,
                      width: side / 3,
                      height: side / 3,
                      child: _sprite(_fruitAsset(piece.fruit)))
              ]))));

  Widget _buildOrchard(AppStrings s) => Column(children: [
        Text(
            _hint.isEmpty
                ? s.pick('Fill a row to harvest', 'Vul een rij om te oogsten')
                : _hint,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFFFFE0A8), fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Expanded(child: LayoutBuilder(builder: (context, box) {
          final cell = min(box.maxWidth / 6, box.maxHeight / 7);
          return Center(
              child: Container(
                  width: cell * 6,
                  height: cell * 7,
                  decoration: BoxDecoration(
                      color: const Color(0xFF5B4230),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFB89055), width: 2)),
                  child: GridView.builder(
                      key: const Key('orchard-basket'),
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6),
                      itemCount: 42,
                      itemBuilder: (context, i) => DragTarget<int>(
                          onWillAcceptWithDetails: (d) =>
                              _enabled &&
                              _orchard.tray[d.data] != null &&
                              _orchard.fits(
                                  _orchard.tray[d.data]!, i % 6, i ~/ 6),
                          onAcceptWithDetails: (d) =>
                              _placeFruit(d.data, i % 6, i ~/ 6),
                          builder: (context, candidate, rejected) => Semantics(
                              label:
                                  '${s.pick('Basket', 'Mand')} ${i ~/ 6 + 1}, ${i % 6 + 1}',
                              button: true,
                              child: GestureDetector(
                                  key: ValueKey('orchard-cell-$i'),
                                  onTap: () =>
                                      _placeFruit(_selected, i % 6, i ~/ 6),
                                  child: Container(
                                      margin: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: candidate.isNotEmpty
                                              ? const Color(0xFF849754)
                                              : _time - _lastHarvest < .4
                                                  ? const Color(0xFF967345)
                                                  : (i + i ~/ 6).isEven
                                                      ? const Color(0xFF3B3024)
                                                      : const Color(
                                                          0xFF46382B)),
                                      child: _orchard.board[i] == null
                                          ? null
                                          : _sprite(_fruitAsset(
                                              _orchard.board[i]!)))))))));
        })),
        const SizedBox(height: 6),
        Row(children: [
          for (var i = 0; i < 3; i++)
            Expanded(child: LayoutBuilder(builder: (context, box) {
              final piece = _orchard.tray[i],
                  side = min(64.0, box.maxWidth - 6);
              final child = Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                      color: _selected == i
                          ? const Color(0xFF77603A)
                          : const Color(0xFF463827),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _selected == i
                              ? const Color(0xFFFFDC96)
                              : const Color(0xFF806742),
                          width: 2)),
                  child: SizedBox(
                      height: side,
                      child: Center(
                          child: piece == null
                              ? const SizedBox.shrink()
                              : _piece(piece, side))));
              return Semantics(
                  label: '${s.pick('Fruit shape', 'Fruitvorm')} ${i + 1}',
                  selected: _selected == i,
                  button: true,
                  child: GestureDetector(
                      key: ValueKey('orchard-tray-$i'),
                      onTap: _enabled && piece != null
                          ? () => setState(() => _selected = i)
                          : null,
                      child: piece == null || !_enabled
                          ? child
                          : Draggable<int>(
                              data: i,
                              feedback: Material(
                                  color: Colors.transparent,
                                  child: _piece(piece, 90)),
                              childWhenDragging:
                                  Opacity(opacity: .35, child: child),
                              child: child)));
            })),
          IconButton(
              key: const Key('orchard-rotate'),
              tooltip: s.pick('Rotate shape', 'Draai vorm'),
              onPressed: _enabled
                  ? () => setState(() => _orchard.rotate(_selected))
                  : null,
              icon: const Icon(Icons.rotate_right, color: Color(0xFFFFDEA7))),
        ]),
        const SizedBox(height: 4),
        Text(
            s.pick('Choose a shape, then tap the basket. Rotate to fit.',
                'Kies een vorm en tik op de mand. Draai om hem passend te maken.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFE4D2B7), fontSize: 11)),
      ]);
}

class _SurfWater extends CustomPainter {
  _SurfWater(this.time);
  final double time;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x267FEACF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var row = 0; row < 14; row++) {
      final y = ((row / 14 + time * .07) % 1) * size.height;
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 5) {
        path.lineTo(x, y + sin(x * .035 + time + row) * 7);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_SurfWater old) => old.time != time;
}
