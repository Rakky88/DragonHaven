import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_school.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';

class DragonSchoolScreen extends StatelessWidget {
  const DragonSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    return Scaffold(
      appBar:
          AppBar(title: Text(strings.pick('Dragon School', 'Drakenschool'))),
      body: ListView(
        key: const Key('dragon-school-games'),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: [
          Container(
            height: 214,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.gold),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x332A1E50),
                    blurRadius: 18,
                    offset: Offset(0, 8)),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/ui/dragon_school.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Color(0xFF302454),
                        Color(0xFF7961A8),
                      ]),
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xE51D1436)],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.pick('Practice makes legends',
                            'Oefening baart legenden'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(blurRadius: 8)],
                        ),
                      ),
                      Text(
                        strings.pick(
                          'Ten short lessons, no attempts or rewards—just your personal bests.',
                          'Tien korte lessen, geen pogingen of beloningen—alleen jouw records.',
                        ),
                        style: const TextStyle(
                            color: Color(0xFFE9DFF9), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < dragonSchoolGames.length; index++) ...[
            _SchoolLessonCard(
              number: index + 1,
              definition: dragonSchoolGames[index],
              record:
                  game.dragonSchoolRecords[dragonSchoolGames[index].id] ?? 0,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SchoolLessonCard extends StatelessWidget {
  const _SchoolLessonCard({
    required this.number,
    required this.definition,
    required this.record,
  });

  final int number;
  final DragonSchoolGameDefinition definition;
  final int record;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = _schoolColors(definition.kind);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        key: Key('dragon-school-game-${definition.id}'),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => DragonSchoolGameScreen(definition: definition),
        )),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_schoolIcon(definition.kind),
                    color: Colors.white, size: 29),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number. ${strings.pick(definition.titleEn, definition.titleNl)}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.pick(
                          definition.descriptionEn, definition.descriptionNl),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Text('$record',
                      style: const TextStyle(
                          color: AppColors.twilight,
                          fontWeight: FontWeight.w900,
                          fontSize: 17)),
                  Text(strings.pick('BEST', 'BESTE'),
                      style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 8,
                          fontWeight: FontWeight.w900)),
                ],
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class DragonSchoolGameScreen extends StatefulWidget {
  const DragonSchoolGameScreen({super.key, required this.definition});

  final DragonSchoolGameDefinition definition;

  @override
  State<DragonSchoolGameScreen> createState() => _DragonSchoolGameScreenState();
}

class _DragonSchoolGameScreenState extends State<DragonSchoolGameScreen> {
  final _random = Random();
  Timer? _ticker;
  Timer? _challengeTimer;
  DateTime? _endsAt;
  Duration _remaining = const Duration(seconds: 20);
  int _score = 0;
  int _target = 0;
  int _expected = 1;
  List<int> _order = [1, 2, 3, 4, 5, 6];
  bool _started = false;
  bool _ended = false;
  bool _cueReady = false;
  bool _memoryVisible = true;
  double _phase = 0;

  DragonSchoolGameKind get kind => widget.definition.kind;

  @override
  void dispose() {
    _ticker?.cancel();
    _challengeTimer?.cancel();
    super.dispose();
  }

  void _start() {
    _ticker?.cancel();
    _challengeTimer?.cancel();
    _score = 0;
    _target = _random.nextInt(9);
    _expected = 1;
    _order = [1, 2, 3, 4, 5, 6]..shuffle(_random);
    _started = true;
    _ended = false;
    _cueReady = false;
    _memoryVisible = true;
    _remaining = const Duration(seconds: 20);
    _endsAt = DateTime.now().add(_remaining);
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
    if (kind == DragonSchoolGameKind.emberReflex) _scheduleReflexCue();
    if (kind == DragonSchoolGameKind.sigilMemory) _scheduleMemoryHide();
    setState(() {});
  }

  void _tick() {
    if (!_started || _ended || !mounted) return;
    final remaining = _endsAt!.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _finish();
      return;
    }
    setState(() {
      _remaining = remaining;
      _phase = (_phase + .035) % 1;
    });
  }

  Future<void> _finish() async {
    if (_ended) return;
    _ended = true;
    _ticker?.cancel();
    _challengeTimer?.cancel();
    final game = context.read<HouseholdProvider>();
    final oldBest = game.dragonSchoolRecords[widget.definition.id] ?? 0;
    final newBest = _score > oldBest;
    if (newBest) {
      await game.recordDragonSchoolScore(widget.definition.id, _score);
    }
    if (mounted) setState(() {});
  }

  void _scheduleReflexCue() {
    _challengeTimer?.cancel();
    _cueReady = false;
    _challengeTimer = Timer(
      Duration(milliseconds: 650 + _random.nextInt(900)),
      () {
        if (mounted && !_ended) setState(() => _cueReady = true);
      },
    );
  }

  void _scheduleMemoryHide() {
    _challengeTimer?.cancel();
    _target = _random.nextInt(6);
    _memoryVisible = true;
    _challengeTimer = Timer(const Duration(milliseconds: 850), () {
      if (mounted && !_ended) setState(() => _memoryVisible = false);
    });
  }

  void _tap(int index) {
    if (!_started || _ended) return;
    setState(() {
      switch (kind) {
        case DragonSchoolGameKind.runeRush:
          _score++;
          break;
        case DragonSchoolGameKind.crystalChase:
          _score = max(0, _score + (index == _target ? 1 : -1));
          _target = _random.nextInt(9);
          break;
        case DragonSchoolGameKind.emberReflex:
          if (_cueReady) {
            _score++;
            _scheduleReflexCue();
          } else {
            _score = max(0, _score - 1);
          }
          break;
        case DragonSchoolGameKind.sigilMemory:
          if (_memoryVisible) return;
          _score = max(0, _score + (index == _target ? 2 : -1));
          _scheduleMemoryHide();
          break;
        case DragonSchoolGameKind.scaleOrder:
          if (_order[index] == _expected) {
            _score++;
            _expected++;
            if (_expected > 6) {
              _expected = 1;
              _order.shuffle(_random);
            }
          } else {
            _score = max(0, _score - 1);
            _expected = 1;
          }
          break;
        case DragonSchoolGameKind.shadowMatch:
          _score = max(0, _score + (index == _target ? 2 : -1));
          _target = _random.nextInt(6);
          break;
        case DragonSchoolGameKind.breathBalance:
          _score += (_phase - .5).abs() < .12 ? 2 : 0;
          break;
        case DragonSchoolGameKind.wingRhythm:
          _score += (_phase - .5).abs() < .10 ? 2 : 0;
          break;
        case DragonSchoolGameKind.safeHoard:
          _score = max(0, _score + (index == _target ? -2 : 1));
          _target = _random.nextInt(6);
          break;
        case DragonSchoolGameKind.starCompass:
          _score += (_phase - .75).abs() < .10 ? 3 : 0;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = _schoolColors(kind);
    final best = context
            .watch<HouseholdProvider>()
            .dragonSchoolRecords[widget.definition.id] ??
        0;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            strings.pick(widget.definition.titleEn, widget.definition.titleNl)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.first.withValues(alpha: .13), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    _GameScore(
                        label: strings.pick('SCORE', 'SCORE'), value: _score),
                    const Spacer(),
                    _GameScore(
                        label: strings.pick('TIME', 'TIJD'),
                        value: (_remaining.inMilliseconds / 1000).ceil()),
                    const Spacer(),
                    _GameScore(
                        label: strings.pick('BEST', 'BESTE'), value: best),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    key: Key('school-session-${widget.definition.id}'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(28),
                      border:
                          Border.all(color: colors.last.withValues(alpha: .35)),
                    ),
                    child: _ended
                        ? _result(strings, best)
                        : !_started
                            ? _intro(strings)
                            : _gameArea(strings),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _intro(AppStrings strings) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_schoolIcon(kind), size: 94, color: _schoolColors(kind).last),
          const SizedBox(height: 12),
          Text(
            strings.pick(widget.definition.descriptionEn,
                widget.definition.descriptionNl),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            strings.pick(
                'A practice round lasts 20 seconds and gives no rewards.',
                'Een oefenronde duurt 20 seconden en geeft geen beloningen.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('start-school-game'),
            onPressed: _start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(strings.pick('Start lesson', 'Start les')),
          ),
        ],
      );

  Widget _result(AppStrings strings, int best) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school_rounded, size: 88, color: AppColors.twilight),
          Text(strings.pick('Lesson complete', 'Les voltooid'),
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('$_score',
              style: const TextStyle(
                  color: AppColors.twilight,
                  fontSize: 54,
                  fontWeight: FontWeight.w900)),
          Text('${strings.pick('Personal best', 'Persoonlijk record')}: $best'),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('replay-school-game'),
            onPressed: _start,
            icon: const Icon(Icons.replay_rounded),
            label: Text(strings.pick('Practice again', 'Opnieuw oefenen')),
          ),
        ],
      );

  Widget _gameArea(AppStrings strings) => switch (kind) {
        DragonSchoolGameKind.runeRush => Center(
            child: InkWell(
              key: const Key('school-rune-rush-target'),
              borderRadius: BorderRadius.circular(90),
              onTap: () => _tap(0),
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: _schoolColors(kind)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 20)
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 82, color: Colors.white),
              ),
            ),
          ),
        DragonSchoolGameKind.crystalChase => _choiceGrid(
            9,
            (index) => Icon(Icons.diamond_rounded,
                color: index == _target
                    ? const Color(0xFF7B48D6)
                    : const Color(0xFFD7CDEA),
                size: index == _target ? 43 : 29),
          ),
        DragonSchoolGameKind.emberReflex => Center(
            child: FilledButton(
              key: const Key('school-reflex-button'),
              style: FilledButton.styleFrom(
                backgroundColor: _cueReady
                    ? const Color(0xFFE14E32)
                    : const Color(0xFF736A80),
                fixedSize: const Size(210, 210),
                shape: const CircleBorder(),
              ),
              onPressed: () => _tap(0),
              child: Icon(
                _cueReady
                    ? Icons.local_fire_department_rounded
                    : Icons.hourglass_top_rounded,
                size: 90,
              ),
            ),
          ),
        DragonSchoolGameKind.sigilMemory => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _memoryVisible
                    ? strings.pick('Remember…', 'Onthoud…')
                    : strings.pick('Which sigil?', 'Welk sigil?'),
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _choiceGrid(
                  6,
                  (index) => Icon(_memoryIcon(index),
                      size: 38,
                      color: _memoryVisible && index != _target
                          ? Colors.transparent
                          : AppColors.twilight),
                ),
              ),
            ],
          ),
        DragonSchoolGameKind.scaleOrder => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  '${strings.pick('Next scale', 'Volgende schub')}: $_expected',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 16),
              Expanded(
                child: _choiceGrid(
                  6,
                  (index) => Text('${_order[index]}',
                      style: const TextStyle(
                          color: AppColors.twilight,
                          fontSize: 30,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        DragonSchoolGameKind.shadowMatch => _choiceGrid(
            6,
            (index) => Transform(
              alignment: Alignment.center,
              transform:
                  Matrix4.diagonal3Values(index == _target ? -1 : 1, 1, 1),
              child: const Icon(Icons.flutter_dash_rounded,
                  size: 42, color: Color(0xFF443858)),
            ),
          ),
        DragonSchoolGameKind.breathBalance ||
        DragonSchoolGameKind.wingRhythm ||
        DragonSchoolGameKind.starCompass =>
          _timingGame(strings),
        DragonSchoolGameKind.safeHoard => _choiceGrid(
            6,
            (index) => Icon(
              index == _target
                  ? Icons.inventory_2_rounded
                  : Icons.redeem_rounded,
              size: 40,
              color: index == _target
                  ? const Color(0xFF6D3856)
                  : const Color(0xFFD49B26),
            ),
          ),
      };

  Widget _choiceGrid(int count, Widget Function(int) child) => GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
        ),
        itemCount: count,
        itemBuilder: (context, index) => InkWell(
          key: Key('school-choice-$index'),
          onTap: () => _tap(index),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFF4EFFA),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD7CDEA)),
            ),
            child: Center(child: child(index)),
          ),
        ),
      );

  Widget _timingGame(AppStrings strings) {
    final target = kind == DragonSchoolGameKind.starCompass ? .75 : .5;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_schoolIcon(kind), size: 82, color: _schoolColors(kind).last),
        const SizedBox(height: 28),
        SizedBox(
          height: 54,
          child: LayoutBuilder(builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8DFF3),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * target - 28,
                  width: 56,
                  top: 3,
                  bottom: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0x88FFD75E),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Positioned(
                  left: (constraints.maxWidth - 22) * _phase,
                  top: 6,
                  child: const Icon(Icons.navigation_rounded,
                      size: 42, color: AppColors.twilight),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          key: const Key('school-timing-stop'),
          onPressed: () => _tap(0),
          icon: const Icon(Icons.touch_app_rounded),
          label: Text(strings.pick('Stop', 'Stop')),
        ),
      ],
    );
  }
}

class _GameScore extends StatelessWidget {
  const _GameScore({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCD2E8)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: const TextStyle(
                    color: AppColors.twilight,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

IconData _schoolIcon(DragonSchoolGameKind kind) => switch (kind) {
      DragonSchoolGameKind.runeRush => Icons.auto_awesome_rounded,
      DragonSchoolGameKind.crystalChase => Icons.diamond_rounded,
      DragonSchoolGameKind.emberReflex => Icons.local_fire_department_rounded,
      DragonSchoolGameKind.sigilMemory => Icons.psychology_alt_rounded,
      DragonSchoolGameKind.scaleOrder => Icons.format_list_numbered_rounded,
      DragonSchoolGameKind.shadowMatch => Icons.contrast_rounded,
      DragonSchoolGameKind.breathBalance => Icons.air_rounded,
      DragonSchoolGameKind.wingRhythm => Icons.music_note_rounded,
      DragonSchoolGameKind.safeHoard => Icons.inventory_2_rounded,
      DragonSchoolGameKind.starCompass => Icons.explore_rounded,
    };

IconData _memoryIcon(int index) => const [
      Icons.local_fire_department_rounded,
      Icons.water_drop_rounded,
      Icons.nightlight_round,
      Icons.auto_awesome_rounded,
      Icons.air_rounded,
      Icons.diamond_rounded,
    ][index];

List<Color> _schoolColors(DragonSchoolGameKind kind) =>
    switch (kind.index % 5) {
      0 => const [Color(0xFF5B3D91), Color(0xFF9A66C7)],
      1 => const [Color(0xFF246C8C), Color(0xFF55A9BB)],
      2 => const [Color(0xFF9B3C38), Color(0xFFE17743)],
      3 => const [Color(0xFF4D598E), Color(0xFF7F78C5)],
      _ => const [Color(0xFF47765A), Color(0xFF75A966)],
    };
