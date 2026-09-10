import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import '../models/seasonal_minigame.dart';
import '../models/seasonal_arcade_game.dart';
import '../models/trial.dart';
import '../models/trial_input.dart';
import '../services/audio_service.dart';

typedef SeasonalArcadeAction = void Function(bool correct,
    {required int points, required bool completesRound});

/// Four independent games. Only the timer, results and reward flow are shared.
class SeasonalMinigames extends StatefulWidget {
  const SeasonalMinigames(
      {super.key,
      required this.kind,
      required this.dragon,
      required this.seed,
      required this.running,
      required this.clock,
      required this.onAction,
      this.onInput});
  final TrialKind kind;
  final Pet dragon;
  final int seed;
  final bool running;
  final DateTime Function() clock;
  final SeasonalArcadeAction onAction;
  final ValueChanged<TrialInput>? onInput;

  @override
  State<SeasonalMinigames> createState() => _SeasonalMinigamesState();
}

class _SeasonalMinigamesState extends State<SeasonalMinigames> {
  late final SeasonalArcadeGame _game;
  Timer? _ticker;
  DateTime? _lastTick;
  int _elapsedMilliseconds = 0;
  int? _draggingParcel;
  Offset? _drag;
  final _surface = GlobalKey();
  double get _time => _game.time;
  double get _spirit => _game.spirit;
  bool get _lost => _game.lost;
  bool get _canInput => widget.running && _game.canInput;
  bool get _reducedMotion => MediaQuery.disableAnimationsOf(context);
  HeartMaze get _maze => _game.maze;
  PrismCircuit get _prisms => _game.prisms;
  int get _hints => _game.hints;
  HeartDirection? get _hint => _game.hint;
  int? get _prismHint => _game.prismHint;
  int? get _errorCell => _game.errorCell;
  List<GiftParcel> get _parcels => _game.parcels;
  List<ChimeNote> get _notes => _game.notes;
  Map<int, double> get _flares => _game.flares;

  @override
  void initState() {
    super.initState();
    double expertise(TrainingFocus focus) =>
        widget.dragon.trainingFor(focus).clamp(0, 400) / 400;
    _game = SeasonalArcadeGame(
        kind: widget.kind,
        seed: widget.seed,
        might: expertise(TrainingFocus.might),
        arcana: expertise(TrainingFocus.arcana),
        spirit: expertise(TrainingFocus.spirit));
    _lastTick = widget.clock();
    _ticker = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (mounted && widget.running && !_lost) setState(_synchronize);
    });
  }

  @override
  void didUpdateWidget(SeasonalMinigames old) {
    super.didUpdateWidget(old);
    if (old.running != widget.running) _lastTick = widget.clock();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _synchronize() {
    if (!widget.running || _lost) return;
    final now = widget.clock();
    _elapsedMilliseconds += max(0, now.difference(_lastTick!).inMilliseconds);
    _lastTick = now;
    _game.advanceTo(_elapsedMilliseconds);
    if (_draggingParcel != null &&
        !_parcels.any((p) => p.id == _draggingParcel)) {
      _draggingParcel = null;
      _drag = null;
    }
    _emitActions();
  }

  void _emitActions() {
    for (final action in _game.takeActions()) {
      widget.onAction(action.correct,
          points: action.points, completesRound: action.complete);
    }
  }

  void _record(TrialControl control, [int a = 0, int b = 0]) =>
      widget.onInput?.call(TrialInput(_elapsedMilliseconds, control, a, b));

  void _hintRequest() {
    if (!_canInput) return;
    setState(() {
      _synchronize();
      _record(TrialControl.requestHint);
      _game.requestHint();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return IgnorePointer(
        ignoring: !widget.running || _lost,
        child: switch (widget.kind) {
          TrialKind.hollyfrostGiftforge => _giftforge(s),
          TrialKind.midnightChime => _chimes(s),
          TrialKind.rosevowRelay => _hearts(s),
          TrialKind.prismaticParade => _circuit(s),
          _ => const SizedBox.shrink(),
        });
  }

  Widget _panel(
          {required String instruction,
          required String detail,
          required Widget child,
          Widget? controls}) =>
      Container(
        key: Key('unique-game-${widget.kind.name}'),
        decoration: BoxDecoration(
            color: const Color(0xB311142A),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white24),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 18)
            ]),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(children: [
          Text(instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFFDDE4F4), fontSize: 11, height: 1.25)),
          const SizedBox(height: 10),
          Expanded(child: child),
          if (controls != null) ...[const SizedBox(height: 8), controls],
        ]),
      );

  static const _giftColors = [
    Color(0xFFED799B),
    Color(0xFF78DCC3),
    Color(0xFF97BCFF)
  ];
  static const _giftSymbols = [
    Icons.favorite_rounded,
    Icons.star_rounded,
    Icons.ac_unit_rounded
  ];

  Widget _parcelArt(int type, {double size = 64}) => Image.asset(
      'assets/images/events/christmas/arcade_gift_${const [
        'heart',
        'star',
        'snow'
      ][type]}.png',
      width: size,
      height: size,
      cacheWidth: 192,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true);

  Widget _giftforge(AppStrings s) => _panel(
        instruction:
            s.pick('Keep the sleigh supplied', 'Vul de sterrenlichtslee'),
        detail: s.pick(
            'Drag gifts to matching symbols. More keep arriving, faster and faster. Three mistakes end the Trial.',
            'Sleep cadeaus naar hetzelfde symbool. Er blijven nieuwe komen, steeds sneller. Bij drie fouten eindigt de proef.'),
        child: LayoutBuilder(builder: (context, box) {
          final size = Size(box.maxWidth, box.maxHeight);
          final giftSize = min(66.0, size.width / 4);
          return Stack(key: _surface, clipBehavior: Clip.hardEdge, children: [
            Positioned(
                left: 0,
                right: 0,
                top: size.height * .27 - 8,
                child: Container(
                    height: giftSize * .7,
                    decoration: BoxDecoration(
                        color: const Color(0xFF45615F),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: const Color(0xFF9DBBB0), width: 3)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          for (var i = 0; i < 7; i++)
                            const Icon(Icons.circle_outlined,
                                size: 18, color: Color(0xFF9DBBB0)),
                        ]))),
            Positioned(
                top: size.height * .50,
                left: 0,
                right: 0,
                child: Icon(Icons.keyboard_double_arrow_down_rounded,
                    color: Colors.white.withValues(alpha: .5), size: 28)),
            for (var i = 0; i < 3; i++)
              Positioned(
                  left: i * size.width / 3 + 3,
                  bottom: 4,
                  width: size.width / 3 - 6,
                  height: min(104, size.height * .32),
                  child: Semantics(
                      label: '${s.pick('Delivery bay', 'Sleevak')} ${i + 1}',
                      child: Container(
                          key: Key('giftforge-bay-$i'),
                          decoration: BoxDecoration(
                              color: _giftColors[i].withValues(alpha: .13),
                              border:
                                  Border.all(color: _giftColors[i], width: 2),
                              borderRadius: BorderRadius.circular(18)),
                          child: Icon(_giftSymbols[i],
                              color: _giftColors[i], size: 35)))),
            // The parcel being held stays above the moving queue.
            for (final parcel in [
              ..._parcels.where((p) => p.id != _draggingParcel),
              ..._parcels.where((p) => p.id == _draggingParcel),
            ])
              _giftParcel(s, parcel, size, giftSize),
          ]);
        }),
      );

  Widget _giftParcel(
      AppStrings s, GiftParcel parcel, Size size, double giftSize) {
    final progress = ((_time - parcel.born) / parcel.duration).clamp(0.0, 1.0);
    final held = _draggingParcel == parcel.id;
    final center = held && _drag != null
        ? _drag!
        : Offset(giftSize / 2 + (size.width - giftSize) * (1 - progress),
            size.height * .27);
    void dragTo(Offset global) {
      if (!_canInput ||
          !_parcels.contains(parcel) ||
          (_draggingParcel != null && _draggingParcel != parcel.id)) {
        return;
      }
      final render = _surface.currentContext!.findRenderObject()! as RenderBox;
      setState(() {
        _draggingParcel = parcel.id;
        _drag = render.globalToLocal(global);
      });
    }

    void releaseDrag() {
      if (_draggingParcel != parcel.id) return;
      setState(() {
        _draggingParcel = null;
        _drag = null;
      });
    }

    return Positioned(
        key: ValueKey('giftforge-position-${parcel.id}'),
        left: center.dx - giftSize / 2,
        top: center.dy - giftSize / 2,
        child: GestureDetector(
            key: ValueKey('giftforge-parcel-${parcel.id}'),
            onPanStart: (d) => dragTo(d.globalPosition),
            onPanUpdate: (d) => dragTo(d.globalPosition),
            onPanCancel: releaseDrag,
            onPanEnd: (_) {
              if (!_canInput ||
                  !_parcels.contains(parcel) ||
                  _draggingParcel != parcel.id ||
                  _drag == null) {
                return;
              }
              final dropped = _drag!;
              final bay = (dropped.dx / (size.width / 3)).floor();
              final isDelivery = dropped.dy >=
                      size.height -
                          min(104, size.height * .32) -
                          12 -
                          _spirit * 8 &&
                  dropped.dy <= size.height + 16 &&
                  bay >= 0 &&
                  bay < 3;
              setState(() {
                _draggingParcel = null;
                _drag = null;
                if (isDelivery) {
                  _synchronize();
                  _record(TrialControl.deliverGift, parcel.id, bay);
                  _game.deliver(parcel.id, bay);
                  _emitActions();
                }
              });
            },
            child: Semantics(
                label: '${s.pick('Parcel', 'Cadeau')} ${parcel.type + 1}',
                child: _parcelArt(parcel.type, size: giftSize))));
  }

  void _strike(int lane) {
    if (!_canInput) return;
    bool? correct;
    setState(() {
      _synchronize();
      _record(TrialControl.strikeChime, lane);
      correct = _game.strike(lane);
      _emitActions();
    });
    if (correct == true) {
      unawaited(HavenAudio.playAsset('event_firstlight_note_${lane + 1}'));
    }
  }

  Widget _chimes(AppStrings s) => _panel(
        instruction:
            s.pick('Play the midnight sky', 'Bespeel de middernachthemel'),
        detail: s.pick(
            'Tap 1–4 as stars reach the gold line. The melody speeds up and later plays two notes together. Three mistakes end the Trial; sound is optional.',
            'Tik op 1–4 als sterren de gouden lijn raken. De melodie versnelt en speelt later twee noten tegelijk. Bij drie fouten stopt de proef; geluid is optioneel.'),
        child: LayoutBuilder(builder: (context, box) {
          final laneWidth = box.maxWidth / 4;
          final strikeY = max(70.0, box.maxHeight - 68);
          return Stack(clipBehavior: Clip.hardEdge, children: [
            for (var i = 0; i < 4; i++)
              Positioned(
                  left: i * laneWidth + 3,
                  top: 0,
                  bottom: 0,
                  width: laneWidth - 6,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: .02),
                                const Color(0xFF90BFFF).withValues(alpha: .12)
                              ]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12)))),
            Positioned(
                top: strikeY - 5,
                left: 0,
                right: 0,
                child: Container(
                    key: const Key('midnight-strike-line'),
                    height: 10,
                    decoration: BoxDecoration(
                        color: const Color(0x55FFDA84),
                        border: Border.symmetric(
                            horizontal: BorderSide(
                                color: const Color(0xFFFFDA84), width: 2))))),
            for (final note in _notes)
              Positioned(
                  key: Key('midnight-note-${note.id}'),
                  left: note.lane * laneWidth + laneWidth / 2 - 20,
                  top: strikeY * (1 - (note.strikeAt - _time) / note.travel) -
                      20,
                  child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFCDE99),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF81BFFF)
                                    .withValues(alpha: .65),
                                blurRadius: _reducedMotion ? 0 : 18)
                          ]),
                      child: const Icon(Icons.star_rounded,
                          color: Color(0xFF3C5488), size: 30))),
            for (var i = 0; i < 4; i++)
              Positioned(
                  left: i * laneWidth + 3,
                  bottom: 3,
                  width: laneWidth - 6,
                  height: 54,
                  child: Material(
                      color: _flares.containsKey(i)
                          ? _errorCell == i
                              ? const Color(0xFFB62E48)
                              : const Color(0xFF567EA8)
                          : const Color(0xFF263F6C),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                          key: Key('midnight-chime-$i'),
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _strike(i),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                    'assets/images/events/new_year/arcade_chime.png',
                                    cacheWidth: 192,
                                    width: 28,
                                    height: 46,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    excludeFromSemantics: true),
                                const SizedBox(width: 2),
                                Text('${i + 1}',
                                    style: const TextStyle(
                                        color: Color(0xFFFFE8A6),
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900)),
                              ])))),
          ]);
        }),
      );

  void _move(HeartDirection direction) {
    if (!_canInput) return;
    setState(() {
      _synchronize();
      _record(TrialControl.moveHearts, direction.index);
      _game.move(direction);
      _emitActions();
    });
  }

  Widget _hearts(AppStrings s) => _panel(
        instruction:
            s.pick('Two hearts, one promise', 'Twee harten, één belofte'),
        detail: s.pick(
            'Move both hearts to their roses. Left and right are mirrored; a blocked heart waits.',
            'Breng beide harten naar hun roos. Links en rechts zijn gespiegeld; een geblokkeerd hart wacht.'),
        child: GestureDetector(
            key: const Key('rosevow-boards'),
            onPanStart: (d) => _drag = d.localPosition,
            onPanEnd: (_) => _drag = null,
            onPanUpdate: (d) {
              if (_drag == null) return;
              final delta = d.localPosition - _drag!;
              if (delta.distance < 26) return;
              _drag = null;
              _move(delta.dx.abs() > delta.dy.abs()
                  ? delta.dx > 0
                      ? HeartDirection.right
                      : HeartDirection.left
                  : delta.dy > 0
                      ? HeartDirection.down
                      : HeartDirection.up);
            },
            child: Row(children: [
              for (var side = 0; side < 2; side++) ...[
                if (side > 0) const SizedBox(width: 12),
                Expanded(
                    child: Center(
                        child: AspectRatio(
                            aspectRatio: 3 / 5,
                            child: LayoutBuilder(builder: (context, box) {
                              final cell = box.maxWidth / 3;
                              final heart =
                                  side == 0 ? _maze.left : _maze.right;
                              final goal = side == 0
                                  ? HeartMaze.leftGoal
                                  : HeartMaze.rightGoal;
                              final walls = side == 0
                                  ? _maze.leftWalls
                                  : _maze.rightWalls;
                              return Stack(children: [
                                for (var i = 0; i < 15; i++)
                                  Positioned(
                                      left: i % 3 * cell,
                                      top: i ~/ 3 * cell,
                                      width: cell,
                                      height: cell,
                                      child: Container(
                                          margin: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                              color: walls.contains(i)
                                                  ? const Color(0xFF632F4D)
                                                  : const Color(0xFF351D36),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFF926A88))),
                                          child: walls.contains(i)
                                              ? const Icon(Icons.grass_rounded,
                                                  color: Color(0xFFDA83A0),
                                                  size: 24)
                                              : i == goal
                                                  ? Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              3),
                                                      child: Image.asset(
                                                          'assets/images/events/valentine/arcade_rose.png',
                                                          cacheWidth: 192,
                                                          fit: BoxFit.contain,
                                                          filterQuality:
                                                              FilterQuality
                                                                  .high,
                                                          excludeFromSemantics:
                                                              true))
                                                  : null)),
                                AnimatedPositioned(
                                    duration: Duration(
                                        milliseconds: _reducedMotion ? 0 : 110),
                                    left: heart % 3 * cell,
                                    top: heart ~/ 3 * cell,
                                    width: cell,
                                    height: cell,
                                    child: Container(
                                        key: Key('rosevow-heart-$side'),
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(colors: [
                                              (side == 0
                                                      ? const Color(0xFFFF98C5)
                                                      : const Color(0xFFFFD3AF))
                                                  .withValues(alpha: .4),
                                              Colors.transparent
                                            ])),
                                        child: Image.asset(
                                            'assets/images/events/valentine/arcade_heart.png',
                                            cacheWidth: 192,
                                            fit: BoxFit.contain,
                                            filterQuality: FilterQuality.high,
                                            excludeFromSemantics: true))),
                              ]);
                            })))),
              ],
            ])),
        controls: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final direction in HeartDirection.values)
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: IconButton.filledTonal(
                      key: Key('rosevow-move-${direction.name}'),
                      tooltip: s.pick(
                          direction.name,
                          const [
                            'Omhoog',
                            'Rechts',
                            'Omlaag',
                            'Links'
                          ][direction.index]),
                      style: IconButton.styleFrom(
                          backgroundColor: _hint == direction
                              ? const Color(0xFFFFDB9B)
                              : const Color(0xFF713B5E),
                          foregroundColor: _hint == direction
                              ? const Color(0xFF351D36)
                              : Colors.white),
                      onPressed: () => _move(direction),
                      icon: Icon(const [
                        Icons.arrow_upward_rounded,
                        Icons.arrow_forward_rounded,
                        Icons.arrow_downward_rounded,
                        Icons.arrow_back_rounded
                      ][direction.index]))),
          ]),
          _hintButton(s, _hintRequest),
        ]),
      );

  void _rotatePrism(int cell) {
    if (!_canInput) return;
    setState(() {
      _synchronize();
      _record(TrialControl.rotatePrism, cell);
      _game.rotatePrism(cell);
      _emitActions();
    });
  }

  Widget _hintButton(AppStrings s, VoidCallback onPressed) => TextButton.icon(
        key: const Key('seasonal-puzzle-hint'),
        onPressed: _hints > 0 && _canInput ? onPressed : null,
        style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFFDE9C),
            disabledForegroundColor: Colors.white38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(44, 36)),
        icon: const Icon(Icons.lightbulb_outline_rounded, size: 17),
        label: Text('${s.pick('Hint', 'Hint')} · $_hints',
            style: const TextStyle(fontSize: 12)),
      );

  Widget _circuit(AppStrings s) => _panel(
        instruction: s.pick('Connect the rainbow', 'Verbind de regenboog'),
        detail: s.pick(
            'Tap prisms to rotate their channels. Lead the light from the arrow to the star.',
            'Tik op prisma’s om hun kanalen te draaien. Leid het licht van de pijl naar de ster.'),
        child: Center(
            child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(builder: (context, box) {
                  final edge = 20.0;
                  final cell = (box.maxWidth - edge * 2) / 4;
                  final lit = _prisms.litCells.toSet();
                  return Stack(children: [
                    Positioned(
                        left: 0,
                        top: _prisms.source ~/ 4 * cell + cell / 2 - 10,
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 20)),
                    Positioned(
                        right: 0,
                        top: _prisms.sink ~/ 4 * cell + cell / 2 - 10,
                        child: const Icon(Icons.star_rounded,
                            color: Color(0xFFFFE389), size: 20)),
                    for (var i = 0; i < 16; i++)
                      Positioned(
                        left: edge + i % 4 * cell,
                        top: i ~/ 4 * cell,
                        width: cell,
                        height: cell,
                        child: Semantics(
                            button: true,
                            label: '${s.pick('Prism', 'Prisma')} ${i + 1}',
                            child: GestureDetector(
                                key: Key('prismatic-tile-$i'),
                                onTap: () => _rotatePrism(i),
                                child: Container(
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(11),
                                        gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              const Color(0xFF3E315D),
                                              const Color(0xFF211C37)
                                            ]),
                                        border: Border.all(
                                            color: _prismHint == i
                                                ? Colors.white
                                                : lit.contains(i)
                                                    ? HSVColor.fromAHSV(1, i * 360 / 16, .55, 1)
                                                        .toColor()
                                                    : Colors.white24,
                                            width: _prismHint == i ? 2.5 : 1)),
                                    child: CustomPaint(
                                        painter: _PrismPainter(
                                            mask: _prisms.connectors[i],
                                            color: lit.contains(i)
                                                ? HSVColor.fromAHSV(
                                                        1, i * 360 / 16, .55, 1)
                                                    .toColor()
                                                : const Color(0xFF88849D),
                                            lit: lit.contains(i),
                                            glow: !_reducedMotion),
                                        child: Center(
                                            child: Opacity(
                                                opacity:
                                                    lit.contains(i) ? 1 : .5,
                                                child: Image.asset(
                                                    'assets/images/events/pride/arcade_prism.png',
                                                    cacheWidth: 192,
                                                    width: cell * .58,
                                                    height: cell * .58,
                                                    fit: BoxFit.contain,
                                                    filterQuality:
                                                        FilterQuality.high,
                                                    excludeFromSemantics: true))))))),
                      ),
                  ]);
                }))),
        controls: _hintButton(s, _hintRequest),
      );
}

class _PrismPainter extends CustomPainter {
  const _PrismPainter(
      {required this.mask,
      required this.color,
      required this.lit,
      required this.glow});
  final int mask;
  final Color color;
  final bool lit;
  final bool glow;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ends = [
      Offset(center.dx, 0),
      Offset(size.width, center.dy),
      Offset(center.dx, size.height),
      Offset(0, center.dy)
    ];
    final path = Path();
    for (var d = 0; d < 4; d++) {
      if (mask & (1 << d) != 0) {
        path.moveTo(center.dx, center.dy);
        path.lineTo(ends[d].dx, ends[d].dy);
      }
    }
    if (lit && glow) {
      canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: .55)
            ..strokeWidth = 13
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke);
    canvas.drawCircle(center, 7, Paint()..color = color);
    canvas.drawCircle(center, 3,
        Paint()..color = lit ? Colors.white : const Color(0xFF48405D));
  }

  @override
  bool shouldRepaint(_PrismPainter old) =>
      old.mask != mask ||
      old.color != color ||
      old.lit != lit ||
      old.glow != glow;
}
