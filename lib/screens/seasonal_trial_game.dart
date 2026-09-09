import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import '../models/trial.dart';
import '../services/audio_service.dart';
import '../widgets/dragon_art.dart';
import '../widgets/witchlight_trial_widgets.dart';
import '../widgets/seasonal_minigames.dart';

class SeasonalTrialRunResult {
  const SeasonalTrialRunResult({
    required this.score,
    required this.correctActions,
    required this.totalActions,
    required this.duration,
  });

  final int score;
  final int correctActions;
  final int totalActions;
  final Duration duration;
}

typedef SeasonalTrialFinished = Future<void> Function(
  SeasonalTrialRunResult result,
);

class SeasonalTrialGame extends StatefulWidget {
  const SeasonalTrialGame({
    super.key,
    required this.offer,
    required this.dragon,
    required this.onFinished,
    this.randomSeed,
    this.clock,
  });

  final TrialOffer offer;
  final Pet dragon;
  final SeasonalTrialFinished onFinished;
  final int? randomSeed;
  final DateTime Function()? clock;

  @override
  State<SeasonalTrialGame> createState() => _SeasonalTrialGameState();
}

class _SeasonalTrialGameState extends State<SeasonalTrialGame>
    with SingleTickerProviderStateMixin {
  late final Random _random;
  Timer? _ticker;
  late final AnimationController _ambient;
  late int _remainingMilliseconds;
  var _started = false;
  var _ending = false;
  var _score = 0;
  var _combo = 0;
  var _bestCombo = 0;
  var _phase = 0;
  var _round = 1;
  var _correctActions = 0;
  var _totalActions = 0;
  var _mistakes = 0;
  var _pathSeed = 0;
  DateTime? _errorFlashUntil;
  var _target = 0;
  late final int _arcadeSeed;
  var _targetColor = 0;
  var _correctChoicePosition = 0;
  var _promptVisible = true;
  var _inputLocked = false;
  var _status = '';
  DateTime? _promptHidesAt;
  DateTime? _feedbackUntil;
  DateTime? _runStartedAt;

  TrialDefinition get definition => widget.offer.definition;
  DateTime _now() => (widget.clock ?? DateTime.now)();
  bool get _isWitchlight => widget.offer.kind == TrialKind.witchlightWard;
  bool get _threeMistakeLimit =>
      _isWitchlight ||
      widget.offer.kind == TrialKind.hollyfrostGiftforge ||
      widget.offer.kind == TrialKind.midnightChime;
  _SeasonalTheme get theme => _themeFor(widget.offer.kind);
  TrainingFocus get _currentPhaseFocus =>
      widget.offer.kind == TrialKind.hollyfrostGiftforge
          ? const [
              TrainingFocus.arcana,
              TrainingFocus.might,
              TrainingFocus.spirit,
            ][_phase.clamp(0, 2)]
          : const [
              TrainingFocus.arcana,
              TrainingFocus.spirit,
              TrainingFocus.might,
            ][_phase.clamp(0, 2)];

  @override
  void initState() {
    super.initState();
    _random = Random(widget.randomSeed);
    final totalExpertise = TrainingFocus.values.fold<int>(
      0,
      (total, focus) => total + widget.dragon.trainingFor(focus),
    );
    // Expertise assists play in a small, capped way and never multiplies score.
    final assistance = (totalExpertise / 300).clamp(0, 3).round();
    _remainingMilliseconds =
        definition.duration.inMilliseconds + assistance * 1000;
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _newChallenge(initial: true);
    _arcadeSeed = _isWitchlight ? 0 : _random.nextInt(1 << 31);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ambient.dispose();
    super.dispose();
  }

  bool _pumpkinsPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isWitchlight || _pumpkinsPrecached) return;
    _pumpkinsPrecached = true;
    for (var variant = 0; variant < 6; variant++) {
      unawaited(precacheImage(
          AssetImage(WitchlightPumpkin.assetFor(variant)), context));
    }
    for (final art in const {'lantern': 192, 'wisp': 144}.entries) {
      unawaited(precacheImage(
          ResizeImage(
              AssetImage(
                  'assets/images/events/halloween/arcade_${art.key}.png'),
              width: art.value),
          context));
    }
  }

  void _start() {
    if (_started) return;
    setState(() {
      _started = true;
      _runStartedAt = _now();
      _newChallenge(initial: true);
    });
    var previous = _now();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _ending) return;
      final now = _now();
      final elapsed = now.difference(previous).inMilliseconds;
      previous = now;
      setState(() {
        if (_errorFlashUntil?.isBefore(now) == true) _errorFlashUntil = null;
        _remainingMilliseconds = max(0, _remainingMilliseconds - elapsed);
        if (_promptHidesAt?.isBefore(now) == true) {
          _promptVisible = false;
          _promptHidesAt = null;
        }
        if (_feedbackUntil?.isBefore(now) == true) {
          _status = '';
          _feedbackUntil = null;
          _inputLocked = false;
        }
      });
      if (_remainingMilliseconds <= 0) _finish();
    });
  }

  Future<void> _finish() async {
    if (_ending) return;
    _ticker?.cancel();
    setState(() {
      _ending = true;
      _remainingMilliseconds = 0;
      _status = _threeMistakeLimit && _mistakes >= 3
          ? AppStrings.of(context).pick('Game over', 'Spel afgelopen')
          : AppStrings.of(context).pick(
              'The final light is sealed!',
              'Het laatste licht is verzegeld!',
            );
    });
    unawaited(HavenAudio.playAsset('event_${theme.soundPrefix}_finish'));
    final elapsed = _runStartedAt == null
        ? 0
        : _now().difference(_runStartedAt!).inMilliseconds;
    await Future<void>.delayed(
        Duration(milliseconds: max(900, 1000 - elapsed)));
    if (mounted) {
      await widget.onFinished(SeasonalTrialRunResult(
        score: _score,
        correctActions: _correctActions,
        totalActions: _totalActions,
        duration: _runStartedAt == null
            ? Duration.zero
            : _now().difference(_runStartedAt!),
      ));
    }
  }

  void _newChallenge({bool initial = false}) {
    _phase = 0;
    if (_isWitchlight) _pathSeed = _random.nextInt(1 << 32);
    _target = _random.nextInt(6);
    _random.nextInt(2); // Preserve the Witchlight seed sequence.
    _targetColor = _random.nextInt(theme.palette.length);
    _correctChoicePosition = _random.nextInt(6);
    _promptVisible = true;
    _promptHidesAt = _now().add(
      Duration(
        milliseconds: (_isWitchlight ? 1000 : 0) +
            (initial
                ? 1900
                : (widget.offer.kind == TrialKind.hollyfrostGiftforge
                        ? 950
                        : 1150) +
                    _arcanaAssistanceMilliseconds),
      ),
    );
  }

  int get _arcanaAssistanceMilliseconds =>
      (widget.dragon.trainingFor(TrainingFocus.arcana).clamp(0, 400) * 2)
          .round();

  double get _spiritTolerance =>
      widget.dragon.trainingFor(TrainingFocus.spirit).clamp(0, 400) / 400;

  int _optionSprite(int position, {bool unique = false}) => unique
      ? (_target + position - _correctChoicePosition) % 6
      : position == _correctChoicePosition
          ? _target
          : (_target + position + 1).remainder(6) == _target
              ? (_target + position + 2).remainder(6)
              : (_target + position + 1).remainder(6);

  int _optionColor(int position) => position == _correctChoicePosition
      ? _targetColor
      : (_targetColor + position + 1).remainder(theme.palette.length);

  void _answer(
    bool correct, {
    int basePoints = 70,
    bool completesRound = false,
  }) {
    if (!_started || _ending || _inputLocked) return;
    setState(() {
      _inputLocked = true;
      _totalActions++;
      if (correct) {
        _correctActions++;
        _score += basePoints + min(90, _combo * 6);
        if (completesRound) {
          _combo++;
          _bestCombo = max(_bestCombo, _combo);
          _round++;
        } else {
          _phase++;
        }
        _status = theme.successText(AppStrings.of(context));
        unawaited(HavenAudio.playAsset('event_${theme.soundPrefix}_success'));
      } else {
        _mistakes++;
        if (_isWitchlight) {
          _errorFlashUntil = _now().add(const Duration(milliseconds: 300));
        }
        _combo = 0;
        _remainingMilliseconds = max(0, _remainingMilliseconds - 2000);
        _status = theme.failureText(AppStrings.of(context));
        unawaited(HavenAudio.playAsset('event_${theme.soundPrefix}_failure'));
      }
      _feedbackUntil = _now().add(const Duration(milliseconds: 650));
      if ((!correct || completesRound) && (!_isWitchlight || _mistakes < 3)) {
        _newChallenge();
      }
    });
    if (_remainingMilliseconds <= 0 || (_isWitchlight && _mistakes >= 3)) {
      unawaited(_finish());
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return PopScope(
      canPop: !_started || _ending,
      child: Scaffold(
        backgroundColor: theme.deepColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(theme.backgroundAsset, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .18),
                    theme.deepColor.withValues(alpha: .70),
                    theme.deepColor.withValues(alpha: .92),
                  ],
                  stops: const [0, .58, 1],
                ),
              ),
            ),
            _SeasonalAmbientOrnaments(
              theme: theme,
              animation: _ambient,
            ),
            SafeArea(
              child: Column(
                children: [
                  _SeasonalHud(
                    theme: theme,
                    title: definition.title(strings.languageCode),
                    score: _score,
                    combo: _combo,
                    phase: _isWitchlight ? _phase : -1,
                    phaseLabel: _currentPhaseFocus.name.toUpperCase(),
                    round: _round,
                    remaining: Duration(milliseconds: _remainingMilliseconds),
                    accent: theme.accentColor,
                    onClose: _started && !_ending
                        ? null
                        : () => Navigator.pop(context),
                  ),
                  if (_threeMistakeLimit)
                    Text(
                      '${strings.pick('Mistakes', 'Fouten')}: $_mistakes / 3',
                      key: const Key('witchlight-mistakes'),
                      style: TextStyle(
                          color:
                              _mistakes > 0 ? Colors.redAccent : Colors.white70,
                          fontWeight: FontWeight.w700),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: _buildGame(strings),
                    ),
                  ),
                  _DragonStudentStrip(
                    dragon: widget.dragon,
                    success: _combo > 0,
                    accent: theme.accentColor,
                    status: _status,
                  ),
                ],
              ),
            ),
            if (!_started) _IntroOverlay(theme: theme, onStart: _start),
            if (_ending)
              _EndingVeil(
                theme: theme,
                score: _score,
                combo: _bestCombo,
                accuracy:
                    _totalActions == 0 ? 0 : _correctActions / _totalActions,
                elapsed: _runStartedAt == null
                    ? Duration.zero
                    : _now().difference(_runStartedAt!),
              ),
            if (_errorFlashUntil != null)
              IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('witchlight-error-flash-$_mistakes'),
                  tween: Tween(begin: .48, end: 0),
                  duration: const Duration(milliseconds: 300),
                  builder: (_, alpha, __) =>
                      ColoredBox(color: Colors.red.withValues(alpha: alpha)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame(AppStrings strings) => _isWitchlight
      ? _buildWitchlight(strings)
      : SeasonalMinigames(
          kind: widget.offer.kind,
          dragon: widget.dragon,
          seed: _arcadeSeed,
          running: _started && !_ending,
          clock: _now,
          onAction: _arcadeAction);

  void _arcadeAction(bool correct,
      {required int points, required bool completesRound}) {
    if (!_started || _ending || _totalActions >= 200) return;
    setState(() {
      _totalActions++;
      if (correct) {
        _correctActions++;
        _score =
            min(20000, _score + points.clamp(0, 130) + min(90, _combo * 6));
        if (completesRound) {
          _combo++;
          _bestCombo = max(_bestCombo, _combo);
          _round++;
        }
        _status = theme.successText(AppStrings.of(context));
      } else {
        _mistakes++;
        _combo = 0;
        _score = max(0, _score - 30);
        _errorFlashUntil = _now().add(const Duration(milliseconds: 300));
        _status = theme.failureText(AppStrings.of(context));
      }
      _feedbackUntil = _now().add(const Duration(milliseconds: 650));
    });
    if (!correct ||
        (completesRound && widget.offer.kind != TrialKind.midnightChime)) {
      unawaited(HavenAudio.playAsset(
          'event_${theme.soundPrefix}_${correct ? 'success' : 'failure'}'));
    }
    if (_remainingMilliseconds <= 0 || (_threeMistakeLimit && _mistakes >= 3)) {
      unawaited(_finish());
    }
  }

  Widget _glassPanel({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: theme.panelColor.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: theme.accentColor.withValues(alpha: .72),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.glowColor.withValues(alpha: .28),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      );

  Widget _buildChoicePhase(
    AppStrings strings, {
    Key? key,
    required String instructionEn,
    required String instructionNl,
    required String keyPrefix,
    int optionCount = 6,
    bool colored = false,
    bool pumpkins = false,
  }) =>
      Column(
        key: key,
        children: [
          const SizedBox(height: 8),
          Text(
            strings.pick(instructionEn, instructionNl),
            textAlign: TextAlign.center,
            style: _instructionStyle,
          ),
          const SizedBox(height: 9),
          Container(
            width: 112,
            height: 112,
            padding: EdgeInsets.all(pumpkins ? 6 : 12),
            decoration: BoxDecoration(
              color: (colored ? theme.palette[_targetColor] : theme.glowColor)
                  .withValues(alpha: .20),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    colored ? theme.palette[_targetColor] : theme.accentColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.glowColor.withValues(alpha: .25),
                  blurRadius: 22,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _promptVisible
                  ? pumpkins
                      ? WitchlightPumpkin(variant: _target)
                      : _EventTrialSprite(
                          key: ValueKey('prompt-$_target-$_round'),
                          theme: theme,
                          index: _target,
                        )
                  : const Icon(
                      Icons.help_rounded,
                      key: ValueKey('hidden-prompt'),
                      color: Colors.white38,
                      size: 54,
                    ),
            ),
          ),
          const Spacer(),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var position = 0; position < optionCount; position++)
                _SpriteTapTarget(
                  key: Key('$keyPrefix-$position'),
                  theme: theme,
                  index: _optionSprite(position, unique: pumpkins),
                  artwork: pumpkins
                      ? WitchlightPumpkin(
                          variant: _optionSprite(position, unique: pumpkins))
                      : null,
                  color: colored ? theme.palette[_optionColor(position)] : null,
                  onTap: _promptVisible
                      ? null
                      : () => _answer(
                            _optionSprite(position, unique: pumpkins) ==
                                    _target &&
                                (!colored ||
                                    _optionColor(position) == _targetColor),
                          ),
                ),
            ],
          ),
          const SizedBox(height: 22),
        ],
      );

  Widget _buildWitchlight(AppStrings strings) => _glassPanel(
        child: AnimatedSwitcher(
          duration: Duration(
              milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 260),
          child: switch (_phase) {
            0 => _buildChoicePhase(
                strings,
                key: const ValueKey('witchlight-arcana'),
                instructionEn: 'Arcana · remember the pumpkin face',
                instructionNl: 'Arcana · onthoud het pompoengezicht',
                keyPrefix: 'witchlight-rune',
                pumpkins: true,
              ),
            1 => Column(
                key: const ValueKey('witchlight-spirit'),
                children: [
                  const SizedBox(height: 12),
                  Text(
                    strings.pick(
                      'Spirit · trace the path to the lantern',
                      'Spirit · volg het pad naar de lantaarn',
                    ),
                    textAlign: TextAlign.center,
                    style: _instructionStyle,
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      strings.pick(
                        'Start at the wisp. Keep your finger down and inside the edges.',
                        'Begin bij het dwaallicht. Houd je vinger op het scherm en binnen de randen.',
                      ),
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: WitchlightTracePath(
                      key: ValueKey('witchlight-path-$_pathSeed'),
                      enabled: _started && !_ending && !_inputLocked,
                      seed: _pathSeed,
                      tolerance: _spiritTolerance,
                      onResult: (correct) =>
                          _answer(correct, completesRound: true),
                    ),
                  ),
                ],
              ),
            _ => const SizedBox.shrink(),
          },
        ),
      );

  TextStyle get _instructionStyle => const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w900,
        shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
      );
}

class _SeasonalHud extends StatelessWidget {
  const _SeasonalHud({
    required this.theme,
    required this.title,
    required this.score,
    required this.combo,
    required this.phase,
    required this.phaseLabel,
    required this.round,
    required this.remaining,
    required this.accent,
    required this.onClose,
  });

  final _SeasonalTheme theme;
  final String title;
  final int score;
  final int combo;
  final int phase;
  final String phaseLabel;
  final int round;
  final Duration remaining;
  final Color accent;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.panelColor.withValues(alpha: .96),
            theme.deepColor.withValues(alpha: .96),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: .70)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: Colors.white,
            disabledColor: Colors.white24,
            visualDensity: VisualDensity.compact,
          ),
          Image.asset(
            theme.iconAsset,
            width: 34,
            height: 34,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                LayoutBuilder(
                  builder: (_, constraints) {
                    final showLabel = constraints.maxWidth >= 105;
                    return Row(
                      children: [
                        if (showLabel) ...[
                          Flexible(
                            child: Text(
                              phase < 0
                                  ? 'ROUND $round'
                                  : 'ROUND $round · $phaseLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: accent,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .7,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        if (phase >= 0)
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: _SeasonalPhaseTrail(
                                theme: theme,
                                phase: phase,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          _HudChip(label: 'COMBO', value: '×$combo', color: accent),
          const SizedBox(width: 7),
          _HudChip(label: 'SCORE', value: '$score', color: accent),
          const SizedBox(width: 7),
          _HudChip(
            label: 'TIME',
            value: '$seconds',
            color: seconds <= 5 ? const Color(0xFFFF6464) : accent,
          ),
        ],
      ),
    );
  }
}

class _SeasonalPhaseTrail extends StatelessWidget {
  const _SeasonalPhaseTrail({required this.theme, required this.phase});

  final _SeasonalTheme theme;
  final int phase;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < 2; index++) ...[
            if (index > 0)
              Container(
                width: 4,
                height: 1.5,
                color: index <= phase
                    ? theme.accentColor
                    : Colors.white.withValues(alpha: .22),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: index == phase ? 19 : 15,
              height: index == phase ? 19 : 15,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index <= phase
                    ? theme.glowColor.withValues(alpha: .22)
                    : Colors.black26,
                border: Border.all(
                  color: index == phase
                      ? theme.accentColor
                      : Colors.white.withValues(alpha: .18),
                  width: index == phase ? 1.4 : .7,
                ),
              ),
              child: Opacity(
                opacity: index <= phase ? 1 : .34,
                child: _EventTrialSprite(
                  theme: theme,
                  index: const [0, 2, 4][index],
                ),
              ),
            ),
          ],
        ],
      );
}

class _HudChip extends StatelessWidget {
  const _HudChip(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 8, fontWeight: FontWeight.w900)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ],
      );
}

class _DragonStudentStrip extends StatelessWidget {
  const _DragonStudentStrip({
    required this.dragon,
    required this.success,
    required this.accent,
    required this.status,
  });

  final Pet dragon;
  final bool success;
  final Color accent;
  final String status;

  @override
  Widget build(BuildContext context) => Container(
        height: 108,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xE51B1234),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: .55)),
        ),
        child: Row(
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 220),
              scale: success ? 1.06 : 1,
              child: DragonArt(
                height: 94,
                stageKey: dragon.stageKey,
                lineageId: dragon.lineageId,
                evolutionPath: dragon.activeEvolutionPath,
                prismatic: dragon.prismatic,
                sinister: dragon.sinister,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dragon.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      status.isEmpty ? ' ' : status,
                      key: ValueKey(status),
                      maxLines: 2,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SeasonalAmbientOrnaments extends StatelessWidget {
  const _SeasonalAmbientOrnaments({
    required this.theme,
    required this.animation,
  });

  final _SeasonalTheme theme;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, __) {
            final drift = (animation.value - .5) * 12;
            return Stack(
              children: [
                Positioned(
                  left: -20 + drift,
                  top: MediaQuery.sizeOf(context).height * .23,
                  child: Opacity(
                    opacity: .12,
                    child: Transform.rotate(
                      angle: -.12,
                      child: _EventTrialSprite(
                        theme: theme,
                        index: 1,
                        size: 104,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -25 - drift,
                  bottom: MediaQuery.sizeOf(context).height * .19,
                  child: Opacity(
                    opacity: .10,
                    child: Transform.rotate(
                      angle: .14,
                      child: _EventTrialSprite(
                        theme: theme,
                        index: 3,
                        size: 118,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _IntroOverlay extends StatelessWidget {
  const _IntroOverlay({required this.theme, required this.onStart});

  final _SeasonalTheme theme;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return ColoredBox(
      color: Colors.black.withValues(alpha: .72),
      child: LayoutBuilder(
        builder: (_, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: max(0.0, constraints.maxHeight - 16),
            ),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 390),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.panelColor, theme.deepColor],
                  ),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: theme.accentColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: theme.glowColor,
                      blurRadius: 42,
                      spreadRadius: 3,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width:
                          theme.assetDirectory.endsWith('halloween') ? 166 : 96,
                      height:
                          theme.assetDirectory.endsWith('halloween') ? 166 : 96,
                      child: theme.assetDirectory.endsWith('halloween')
                          ? _EventTrialSprite(theme: theme, index: 0)
                          : Image.asset(theme.iconAsset,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      theme.introTitle(strings),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      theme.instructions(strings),
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white70, height: 1.35),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const Key('start-seasonal-trial'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 15,
                        ),
                      ),
                      onPressed: onStart,
                      icon: _EventTrialSprite(theme: theme, index: 1, size: 27),
                      label: Text(strings.pick('Begin Trial', 'Start Proef')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EndingVeil extends StatelessWidget {
  const _EndingVeil({
    required this.theme,
    required this.score,
    required this.combo,
    required this.accuracy,
    required this.elapsed,
  });

  final _SeasonalTheme theme;
  final int score;
  final int combo;
  final double accuracy;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: theme.deepColor.withValues(alpha: .78),
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 760),
            curve: Curves.easeOutBack,
            tween: Tween(begin: .45, end: 1),
            builder: (_, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 330),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.panelColor, theme.deepColor],
                ),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: theme.accentColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: theme.glowColor.withValues(alpha: .38),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 176,
                    height: 176,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          theme.iconAsset,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 72,
                            height: 72,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.deepColor.withValues(alpha: .88),
                              border: Border.all(
                                color: theme.accentColor,
                                width: 1.5,
                              ),
                            ),
                            child: _EventTrialSprite(
                              theme: theme,
                              index: 5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$score',
                    style: TextStyle(
                      color: theme.accentColor,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 12)
                      ],
                    ),
                  ),
                  Text(
                    'BEST COMBO ×$combo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${(accuracy * 100).round()}% ACCURACY · ${elapsed.inSeconds}s',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _SpriteTapTarget extends StatelessWidget {
  const _SpriteTapTarget({
    super.key,
    required this.theme,
    required this.index,
    required this.onTap,
    this.color,
    this.artwork,
  });

  final Widget? artwork;
  final _SeasonalTheme theme;
  final int index;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 84,
            height: 84,
            padding: EdgeInsets.all(artwork == null ? 8 : 4),
            decoration: BoxDecoration(
              color: (color ?? theme.buttonColor).withValues(alpha: .28),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: (color ?? theme.accentColor).withValues(alpha: .78),
              ),
            ),
            child: artwork ??
                (color == null
                    ? _EventTrialSprite(theme: theme, index: index)
                    : ColorFiltered(
                        colorFilter:
                            ColorFilter.mode(color!, BlendMode.modulate),
                        child: _EventTrialSprite(theme: theme, index: index),
                      )),
          ),
        ),
      );
}

class _EventTrialSprite extends StatelessWidget {
  const _EventTrialSprite({
    super.key,
    required this.theme,
    required this.index,
    this.size = 100,
  });

  final _SeasonalTheme theme;
  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        '${theme.assetDirectory}/trial_sprite_${index.remainder(6)}.webp',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _SeasonalTheme {
  const _SeasonalTheme({
    required this.soundPrefix,
    required this.backgroundAsset,
    required this.assetDirectory,
    required this.deepColor,
    required this.panelColor,
    required this.accentColor,
    required this.glowColor,
    required this.buttonColor,
    required this.palette,
    required this.introEn,
    required this.introNl,
    required this.instructionsEn,
    required this.instructionsNl,
    required this.successEn,
    required this.successNl,
    required this.failureEn,
    required this.failureNl,
  });

  final String soundPrefix;
  final String backgroundAsset;
  final String assetDirectory;
  final Color deepColor;
  final Color panelColor;
  final Color accentColor;
  final Color glowColor;
  final Color buttonColor;
  final List<Color> palette;
  final String introEn;
  final String introNl;
  final String instructionsEn;
  final String instructionsNl;
  final String successEn;
  final String successNl;
  final String failureEn;
  final String failureNl;

  String get iconAsset => '$assetDirectory/trial_icon.webp';

  String introTitle(AppStrings strings) => strings.pick(introEn, introNl);
  String instructions(AppStrings strings) =>
      strings.pick(instructionsEn, instructionsNl);
  String successText(AppStrings strings) => strings.pick(successEn, successNl);
  String failureText(AppStrings strings) => strings.pick(failureEn, failureNl);
}

_SeasonalTheme _themeFor(TrialKind kind) => switch (kind) {
      TrialKind.witchlightWard => const _SeasonalTheme(
          soundPrefix: 'witchlight',
          backgroundAsset:
              'assets/images/events/halloween/trial_background.webp',
          assetDirectory: 'assets/images/events/halloween',
          deepColor: Color(0xFF100D1A),
          panelColor: Color(0xFF2A1734),
          accentColor: Color(0xFFFFA43B),
          glowColor: Color(0xFF79F06B),
          buttonColor: Color(0xFF71376F),
          palette: [Color(0xFFFFA43B), Color(0xFF79F06B), Color(0xFFC873FF)],
          introEn: 'Raise the Witchlight Ward',
          introNl: 'Herstel de Heksenlichtbescherming',
          instructionsEn:
              'Remember the pumpkin face, then guide the Witchlight along the path. Stay within the edges. Three mistakes end the Trial.',
          instructionsNl:
              'Onthoud het pompoengezicht en leid het heksenlicht langs het pad. Blijf binnen de randen. Bij drie fouten eindigt de proef.',
          successEn: 'The ward burns brighter!',
          successNl: 'De bescherming brandt feller!',
          failureEn: 'The gloom stole two seconds.',
          failureNl: 'De duisternis stal twee seconden.'),
      TrialKind.hollyfrostGiftforge => const _SeasonalTheme(
          soundPrefix: 'starlight',
          backgroundAsset:
              'assets/images/events/christmas/trial_background.webp',
          assetDirectory: 'assets/images/events/christmas',
          deepColor: Color(0xFF092A2A),
          panelColor: Color(0xFF17483F),
          accentColor: Color(0xFFFFE09A),
          glowColor: Color(0xFFB9F3FF),
          buttonColor: Color(0xFFB33A4B),
          palette: [Color(0xFFFFE09A), Color(0xFFB9F3FF), Color(0xFFC94758)],
          introEn: 'Light the Hollyfrost Giftforge',
          introNl: 'Ontsteek Hollyfrosts Geschenkensmidse',
          instructionsEn:
              'Drag gifts to the matching symbol. The belt speeds up. Three mistakes end the Trial.',
          instructionsNl:
              'Sleep cadeaus naar hetzelfde symbool. De band versnelt. Bij drie fouten eindigt de proef.',
          successEn: 'Perfectly wrapped!',
          successNl: 'Perfect ingepakt!',
          failureEn: 'Missed delivery · −30 points',
          failureNl: 'Bezorging gemist · −30 punten'),
      TrialKind.midnightChime => const _SeasonalTheme(
          soundPrefix: 'firstlight',
          backgroundAsset:
              'assets/images/events/new_year/trial_background.webp',
          assetDirectory: 'assets/images/events/new_year',
          deepColor: Color(0xFF11153E),
          panelColor: Color(0xFF252864),
          accentColor: Color(0xFFFFD666),
          glowColor: Color(0xFFFF7EAD),
          buttonColor: Color(0xFF4C57A8),
          palette: [Color(0xFFFFD666), Color(0xFFFF7EAD), Color(0xFF75E7FF)],
          introEn: 'Ring in the First Dawn',
          introNl: 'Luid de Eerste Dageraad in',
          instructionsEn:
              'Tap 1–4 as stars reach the gold line. The melody speeds up and later plays two notes together. Three mistakes end the Trial; sound is optional.',
          instructionsNl:
              'Tik op 1–4 als sterren de gouden lijn raken. De melodie versnelt en speelt later twee noten tegelijk. Bij drie fouten stopt de proef; geluid is optioneel.',
          successEn: 'A perfect midnight note!',
          successNl: 'Een perfecte middernachttoon!',
          failureEn: 'Missed chime · −30 points',
          failureNl: 'Klok gemist · −30 punten'),
      TrialKind.rosevowRelay => const _SeasonalTheme(
          soundPrefix: 'twinheart',
          backgroundAsset:
              'assets/images/events/valentine/trial_background.webp',
          assetDirectory: 'assets/images/events/valentine',
          deepColor: Color(0xFF3C1932),
          panelColor: Color(0xFF853C65),
          accentColor: Color(0xFFFFD2DC),
          glowColor: Color(0xFFFF82AB),
          buttonColor: Color(0xFFAE4778),
          palette: [Color(0xFFFFD2DC), Color(0xFFFF82AB), Color(0xFFFFC85F)],
          introEn: 'Carry the Rosevow Relay',
          introNl: 'Draag de Rozenbelofte-estafette',
          instructionsEn:
              'Swipe or use the arrows to guide two hearts to their roses. Horizontal moves are mirrored. A blocked heart waits while its partner moves. Reach both roses together to open a new maze.',
          instructionsNl:
              'Swipe of gebruik de pijlen om twee harten naar hun roos te leiden. Horizontale bewegingen zijn gespiegeld. Een geblokkeerd hart wacht terwijl zijn partner beweegt. Bereik beide rozen om een nieuw doolhof te openen.',
          successEn: 'Both promises shine!',
          successNl: 'Beide beloften stralen!',
          failureEn: 'Both paths blocked · −30 points',
          failureNl: 'Beide paden geblokkeerd · −30 punten'),
      TrialKind.prismaticParade => const _SeasonalTheme(
          soundPrefix: 'radiant',
          backgroundAsset: 'assets/images/events/pride/trial_background.webp',
          assetDirectory: 'assets/images/events/pride',
          deepColor: Color(0xFF21143E),
          panelColor: Color(0xFF452A70),
          accentColor: Color(0xFFFFE878),
          glowColor: Color(0xFF75F2DC),
          buttonColor: Color(0xFF6747A8),
          palette: [
            Color(0xFFFF6078),
            Color(0xFFFFA84A),
            Color(0xFFFFE45D),
            Color(0xFF55D78A),
            Color(0xFF5AA8FF),
            Color(0xFFB574ED),
            Color(0xFFF58FCB),
          ],
          introEn: 'Lead the Prismatic Parade',
          introNl: 'Leid de Prismatische Parade',
          instructionsEn:
              'Rotate the prisms to connect their channels. Guide the rainbow from the white arrow to the gold star. Every newly lit prism scores once; finish the circuit for a bonus and a fresh puzzle.',
          instructionsNl:
              'Draai de prisma’s om hun kanalen te verbinden. Leid de regenboog van de witte pijl naar de gouden ster. Elk nieuw verlicht prisma scoort één keer; voltooi het circuit voor een bonus en een nieuwe puzzel.',
          successEn: 'Another true color joins!',
          successNl: 'Nog een ware kleur sluit aan!',
          failureEn: 'Keep the rainbow flowing!',
          failureNl: 'Laat de regenboog doorstromen!'),
      TrialKind.cavernFlight ||
      TrialKind.ruinBreaker ||
      TrialKind.runeweaver =>
        throw ArgumentError.value(kind, 'kind', 'Not a seasonal Trial'),
    };
