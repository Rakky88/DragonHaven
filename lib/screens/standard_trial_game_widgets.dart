import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import '../models/standard_trial_games.dart';
import '../models/trial.dart';
import '../models/trial_dragon.dart';
import '../models/trial_input.dart';
import '../services/audio_service.dart';
import '../services/trial_gameplay_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/ruin_guard_impact.dart';
import '../widgets/trial_icon_sprite.dart';

typedef FinishStandardTrial = Future<void> Function(int score);

class SpiritAlignmentTrialGame extends StatefulWidget {
  const SpiritAlignmentTrialGame({
    super.key,
    required this.offer,
    required this.dragon,
    required this.onFinished,
    this.controller,
  });

  final TrialOffer offer;
  final TrialDragon dragon;
  final TrialGameplayController? controller;
  final FinishStandardTrial onFinished;

  @override
  State<SpiritAlignmentTrialGame> createState() =>
      _SpiritAlignmentTrialGameState();
}

class _SpiritAlignmentTrialGameState extends State<SpiritAlignmentTrialGame>
    with SingleTickerProviderStateMixin {
  late final SpiritAlignmentGame game;
  late final Ticker ticker;
  Duration? previousTick;
  int elapsedMs = 0;
  bool started = false, finishing = false;

  @override
  void initState() {
    super.initState();
    game = widget.controller?.model.alignment ??
        SpiritAlignmentGame(
          seed: widget.offer.id.hashCode,
          spirit: widget.dragon.trainingFor(TrainingFocus.spirit),
        );
    ticker = createTicker(_tick);
    if (widget.controller == null) ticker.start();
    widget.controller?.addListener(_verifiedFrame);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_verifiedFrame);
    ticker.dispose();
    super.dispose();
  }

  void _verifiedFrame() {
    if (!mounted) return;
    setState(() {});
    if (game.ended) unawaited(_finish());
  }

  void _tick(Duration elapsed) {
    final previous = previousTick;
    previousTick = elapsed;
    if (!started || previous == null || game.ended) return;
    elapsedMs += (elapsed - previous).inMilliseconds;
    game.advanceTo(elapsedMs);
    if (mounted) setState(() {});
    if (game.ended) unawaited(_finish());
  }

  void _tap() {
    if (game.ended || game.waitingForResult) return;
    if (!started) {
      started = true;
      previousTick = null;
      widget.controller?.start();
      unawaited(HavenAudio.play(HavenSound.adventureStart));
      setState(() {});
      return;
    }
    if (widget.controller case final controller?) {
      controller.input(TrialControl.flap);
    } else {
      game.tap(elapsedMs);
    }
    unawaited(HavenAudio.play(HavenSound.uiConfirm));
    setState(() {});
  }

  Future<void> _finish() async {
    if (finishing) return;
    finishing = true;
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (mounted && widget.controller == null) {
      await widget.onFinished(game.score);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final overlap = game.latestOverlap;
    final secondsLeft = (game.remainingMs / 1000).ceil();
    final timeLeft = '${(secondsLeft ~/ 60).toString().padLeft(2, '0')}:'
        '${(secondsLeft % 60).toString().padLeft(2, '0')}';
    return _StandardTrialScaffold(
      offer: widget.offer,
      dragon: widget.dragon,
      score: game.score,
      child: GestureDetector(
        key: const Key('spirit-alignment-game'),
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/ui/trials/trial_cavern_background.webp',
                fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xD9181038), Color(0xE02B1552)],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (game.timed)
                    Semantics(
                      label: strings.pick('Time remaining', 'Resterende tijd'),
                      child: _StatusChip(
                        key: const Key('spirit-time-remaining'),
                        icon: Icons.timer_outlined,
                        label: timeLeft,
                      ),
                    )
                  else ...[
                    _StatusChip(
                      key: const Key('spirit-round'),
                      icon: Icons.auto_awesome_rounded,
                      label: strings.pick(
                          'Round ${game.round}', 'Ronde ${game.round}'),
                    ),
                    _StatusChip(
                      key: const Key('spirit-round-speed'),
                      icon: Icons.speed_rounded,
                      label: '${game.roundSpeed.toStringAsFixed(2)}x',
                    ),
                  ],
                  _StatusChip(
                    key: const Key('spirit-shape-count'),
                    icon: Icons.category_rounded,
                    label: game.timed
                        ? strings.pick(
                            'Shape ${(game.round - 1) * 3 + game.shapeIndex + 1}',
                            'Vorm ${(game.round - 1) * 3 + game.shapeIndex + 1}',
                          )
                        : '${game.shapeIndex + 1}/3',
                  ),
                ]
                    .map((chip) => Flexible(
                          child: FittedBox(fit: BoxFit.scaleDown, child: chip),
                        ))
                    .toList(),
              ),
            ),
            Positioned.fill(
              top: 68,
              bottom: 84,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final arenaExtent = max(
                      1.0, min(constraints.maxWidth, constraints.maxHeight));
                  final size = SpiritAlignmentGeometry.shapePixels(arenaExtent);
                  return Center(
                    child: SizedBox.square(
                      key: const Key('spirit-logical-arena'),
                      dimension: arenaExtent,
                      child: Stack(
                        children: [
                          Positioned(
                            left: SpiritAlignmentGeometry.arenaPosition(
                                game.targetX, arenaExtent),
                            top: SpiritAlignmentGeometry.arenaPosition(
                                game.targetY, arenaExtent),
                            child: _Shape(
                              key: const Key('spirit-target-shape'),
                              shape: game.shape,
                              size: size,
                              filled: false,
                              containedScoring: game.containedScoring,
                              color: AppColors.gold,
                            ),
                          ),
                          Positioned(
                            left: SpiritAlignmentGeometry.arenaPosition(
                                game.playerX, arenaExtent),
                            top: SpiritAlignmentGeometry.arenaPosition(
                                game.playerY, arenaExtent),
                            child: _Shape(
                              key: const Key('spirit-player-shape'),
                              shape: game.shape,
                              size: size,
                              filled: true,
                              containedScoring: game.containedScoring,
                              color: overlap == 100
                                  ? const Color(0xFF82FFE0)
                                  : const Color(0xFFBDA4FF),
                            ),
                          ),
                          if (game.waitingForResult && overlap != null)
                            Center(
                              child: Container(
                                key: const Key('spirit-overlap-percent'),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xEE221648),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: overlap == 100
                                        ? const Color(0xFF82FFE0)
                                        : Colors.white54,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$overlap%',
                                      key: Key(
                                          'spirit-overlap-${game.shapeIndex}'),
                                      style: TextStyle(
                                        color: overlap == 100
                                            ? const Color(0xFF82FFE0)
                                            : Colors.white,
                                        fontSize: 42,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    if (game.timed && overlap == 100)
                                      const Text(
                                        '+5s',
                                        key: Key('spirit-time-bonus'),
                                        style: TextStyle(
                                          color: Color(0xFF82FFE0),
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 20,
              child: Text(
                game.timed && game.ended
                    ? strings.pick("Time's up!", 'De tijd is om!')
                    : game.waitingForResult
                        ? (overlap == 100
                            ? strings.pick(
                                'Perfect overlap!', 'Perfecte overlap!')
                            : strings.pick('Next shape...', 'Volgende vorm...'))
                        : game.phase == SpiritAlignmentPhase.vertical
                            ? strings.pick('Tap to lock the height',
                                'Tik om de hoogte vast te zetten')
                            : game.containedScoring
                                ? strings.pick('Tap to stop inside the outline',
                                    'Tik om binnen de omtrek te stoppen')
                                : strings.pick('Tap to stop on the outline',
                                    'Tik om op de omtrek te stoppen'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(blurRadius: 8)],
                ),
              ),
            ),
            if (!started)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: _StartCard(
                        icon: Icons.center_focus_strong_rounded,
                        title: game.timed
                            ? strings.pick('Align as many shapes as you can',
                                'Lijn zoveel mogelijk vormen uit')
                            : strings.pick('Align all three shapes',
                                'Lijn alle drie vormen uit'),
                        body: game.containedScoring
                            ? strings.pick(
                                'Start with 60 seconds. Tap once to lock the height, then again to stop inside the golden outline. A shape entirely inside earns 100% and 5 extra seconds!',
                                'Je begint met 60 seconden. Tik eenmaal om de hoogte vast te zetten en nogmaals om binnen de gouden omtrek te stoppen. Een vorm die helemaal binnen zit geeft 100% en 5 seconden extra!',
                              )
                            : game.timed
                                ? strings.pick(
                                    'Start with 60 seconds. Tap once to lock the height, then tap again on the golden outline. Every 100% overlap adds 5 seconds. Keep going until time runs out!',
                                    'Je begint met 60 seconden. Tik eenmaal om de hoogte vast te zetten en nogmaals op de gouden omtrek. Elke overlap van 100% geeft 5 seconden extra. Ga door tot de tijd om is!',
                                  )
                                : strings.pick(
                                    'Tap once to lock the height, then tap again on the golden outline. Three displayed 100% scores make the next round 10% faster.',
                                    'Tik eenmaal om de hoogte vast te zetten en nogmaals op de gouden omtrek. Drie zichtbare scores van 100% maken de volgende ronde 10% sneller.',
                                  ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RuinGuardTrialGame extends StatefulWidget {
  const RuinGuardTrialGame({
    super.key,
    required this.offer,
    required this.dragon,
    required this.onFinished,
    this.controller,
  });

  final TrialOffer offer;
  final TrialDragon dragon;
  final TrialGameplayController? controller;
  final FinishStandardTrial onFinished;

  @override
  State<RuinGuardTrialGame> createState() => _RuinGuardTrialGameState();
}

class _RuinGuardTrialGameState extends State<RuinGuardTrialGame>
    with SingleTickerProviderStateMixin {
  late final RuinGuardGame game;
  late final Ticker ticker;
  Duration? previousTick;
  int elapsedMs = 0;
  bool started = false, finishing = false;

  @override
  void initState() {
    super.initState();
    game = widget.controller?.model.guard ??
        RuinGuardGame(
          seed: widget.offer.id.hashCode,
          might: widget.dragon.trainingFor(TrainingFocus.might),
        );
    ticker = createTicker(_tick)..start();
    widget.controller?.addListener(_verifiedFrame);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_verifiedFrame);
    ticker.dispose();
    super.dispose();
  }

  void _verifiedFrame() {
    if (!mounted) return;
    setState(() {});
    if (game.ended) unawaited(_finish());
  }

  void _tick(Duration elapsed) {
    final previous = previousTick;
    previousTick = elapsed;
    if (!started || previous == null || game.ended) return;
    if (widget.controller == null) {
      elapsedMs += (elapsed - previous).inMilliseconds;
      game.advanceTo(elapsedMs);
    }
    if (mounted) setState(() {});
    if (game.ended) unawaited(_finish());
  }

  void _tap() {
    if (game.ended || game.locked) return;
    if (!started) {
      started = true;
      previousTick = null;
      widget.controller?.start();
      unawaited(HavenAudio.play(HavenSound.adventureStart));
      setState(() {});
      return;
    }
    if (widget.controller case final controller?) {
      controller.input(TrialControl.strikeRuin);
    } else {
      game.tap(elapsedMs);
    }
    unawaited(HavenAudio.play(HavenSound.uiConfirm));
    setState(() {});
  }

  Future<void> _finish() async {
    if (finishing) return;
    finishing = true;
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted && widget.controller == null) {
      await widget.onFinished(game.score);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _StandardTrialScaffold(
      offer: widget.offer,
      dragon: widget.dragon,
      score: game.score,
      child: GestureDetector(
        key: const Key('ruin-guard-game'),
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/ui/trials/trial_ruin_background.webp',
                fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x55120C29), Color(0xFA120C29)],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusChip(
                    key: const Key('ruin-guard-lives'),
                    icon: Icons.shield_rounded,
                    label: strings.pick('${max(0, 3 - game.misses)} shields',
                        '${max(0, 3 - game.misses)} schilden'),
                  ),
                  _StatusChip(
                    icon: Icons.local_fire_department_rounded,
                    label: game.combo == 0 ? '-' : 'x${game.combo}',
                  ),
                ],
              ),
            ),
            Positioned.fill(
              top: 64,
              bottom: 98,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final laneWidth = constraints.maxWidth / 3;
                  final travel = max(1.0, constraints.maxHeight - 126);
                  final reducedMotion = MediaQuery.disableAnimationsOf(context);
                  final presentationMs =
                      widget.controller?.presentationElapsedMs ??
                          game.milliseconds;
                  final fallProgress = game.locked
                      ? 1.0
                      : ((presentationMs - game.roundStartedAt) /
                              game.fallDurationMs)
                          .clamp(0.0, 1.0);
                  final impactProgress = game.locked
                      ? ((presentationMs - (game.lockedUntil! - 420)) / 420)
                          .clamp(0.0, 1.0)
                      : 0.0;
                  final guarded =
                      game.locked && game.playerLane == game.targetLane;
                  final readyToGuard = started &&
                      !game.locked &&
                      game.playerLane == game.targetLane;
                  // The dragon meets the stone at the existing collision time.
                  // This anticipation and recoil never advance the game model.
                  final lunge = reducedMotion
                      ? 0.0
                      : guarded
                          ? 1 - Curves.easeOutCubic.transform(impactProgress)
                          : readyToGuard
                              ? Curves.easeInOut.transform(
                                  ((fallProgress - .86) / .14).clamp(0.0, 1.0))
                              : 0.0;
                  final stoneSize = min(76.0, laneWidth * .72);
                  final stoneRotation =
                      reducedMotion ? 0.0 : .18 + fallProgress * 1.1;
                  final stoneLeft =
                      game.targetLane * laneWidth + (laneWidth - stoneSize) / 2;
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      for (var lane = 0; lane < 3; lane++)
                        Positioned(
                          left: lane * laneWidth + 5,
                          top: 0,
                          bottom: 0,
                          width: laneWidth - 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: lane.isEven
                                  ? const Color(0x181A1038)
                                  : const Color(0x2AFFFFFF),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: lane == game.playerLane
                                    ? const Color(0x99FFE08A)
                                    : Colors.white24,
                              ),
                            ),
                          ),
                        ),
                      if (!guarded)
                        Positioned(
                          key: const Key('ruin-guard-boulder'),
                          left: stoneLeft,
                          top: fallProgress * travel +
                              (game.locked && !reducedMotion
                                  ? impactProgress * 40
                                  : 0),
                          child: Opacity(
                            opacity: game.locked ? 1 - impactProgress : 1,
                            child: Transform.rotate(
                              angle: stoneRotation,
                              child: RuinGuardBoulder(size: stoneSize),
                            ),
                          ),
                        ),
                      AnimatedPositioned(
                        key: const Key('ruin-guard-dragon'),
                        duration: reducedMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 150),
                        curve: Curves.easeOutBack,
                        left: game.playerLane * laneWidth,
                        bottom: 2,
                        width: laneWidth,
                        child: Transform.translate(
                          key: const Key('ruin-guard-lunge'),
                          offset: Offset(0, -28 * lunge),
                          child: Transform.rotate(
                            angle: -.08 * lunge,
                            child: DragonArt(
                              height: 90,
                              animate:
                                  started && !game.locked && !reducedMotion,
                              stageKey: widget.dragon.stageKey,
                              lineageId: widget.dragon.lineageId,
                              evolutionPath: widget.dragon.activeEvolutionPath,
                              prismatic: widget.dragon.prismatic,
                              sinister: widget.dragon.sinister,
                            ),
                          ),
                        ),
                      ),
                      if (guarded)
                        Positioned(
                          key: const Key('ruin-guard-shatter'),
                          left: stoneLeft - stoneSize,
                          top: travel - stoneSize,
                          child: RuinGuardImpact(
                            progress: impactProgress,
                            stoneSize: stoneSize,
                            rotation: stoneRotation,
                            reducedMotion: reducedMotion,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 20,
              child: Column(
                children: [
                  Text(
                    game.feedback.isEmpty
                        ? strings.pick('Tap to guard the next lane',
                            'Tik om de volgende baan te bewaken')
                        : game.feedback,
                    style: TextStyle(
                      color: game.feedback.contains('MISS')
                          ? const Color(0xFFFF9BAA)
                          : AppColors.gold,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    strings.pick(
                      'Each tap moves one lane to the right.',
                      'Elke tik verplaatst je een baan naar rechts.',
                    ),
                    style: const TextStyle(
                        color: Color(0xFFE9DDF8), fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (!started)
              _StartCard(
                icon: Icons.shield_rounded,
                title: strings.pick('Guard the ruins', 'Bewaak de ruines'),
                body: strings.pick(
                  'Tap to move between three lanes. Meet each falling boulder before it lands. Three misses end the Trial.',
                  'Tik om tussen drie banen te bewegen. Vang elke vallende rots voordat die landt. Drie missers beeindigen de proef.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RuneOrbitTrialGame extends StatefulWidget {
  const RuneOrbitTrialGame({
    super.key,
    required this.offer,
    required this.dragon,
    required this.onFinished,
    this.controller,
  });

  final TrialOffer offer;
  final TrialDragon dragon;
  final TrialGameplayController? controller;
  final FinishStandardTrial onFinished;

  @override
  State<RuneOrbitTrialGame> createState() => _RuneOrbitTrialGameState();
}

class _RuneOrbitTrialGameState extends State<RuneOrbitTrialGame>
    with SingleTickerProviderStateMixin {
  static const runeKeys = ['fire', 'water', 'moon', 'star', 'wind'];
  late final RuneOrbitGame game;
  late final Ticker ticker;
  Duration frameElapsed = Duration.zero;
  int localStartedAt = 0;
  int observedMatches = 0, observedMisses = 0;
  Duration? resultAt;
  bool matched = false;
  double resultPhase = 0;
  bool started = false, finishing = false;

  @override
  void initState() {
    super.initState();
    game = widget.controller?.model.orbit ??
        RuneOrbitGame(
          seed: widget.offer.id.hashCode,
          arcana: widget.dragon.trainingFor(TrainingFocus.arcana),
        );
    observedMatches = game.rounds;
    observedMisses = game.misses;
    ticker = createTicker(_tick)..start();
    widget.controller?.addListener(_verifiedFrame);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_verifiedFrame);
    ticker.dispose();
    super.dispose();
  }

  void _verifiedFrame() {
    if (!mounted) return;
    _observeResult();
    setState(() {});
    if (game.ended) unawaited(_finish());
  }

  void _tick(Duration elapsed) {
    frameElapsed = elapsed;
    if (!started) return;
    if (widget.controller == null && !game.ended) {
      game.advanceTo(
          max(game.milliseconds, elapsed.inMilliseconds - localStartedAt));
      _observeResult();
    }
    // Canonical games are only advanced by their controller. This ticker reads
    // its monotonic presentation clock to draw between simulation updates.
    if (mounted) setState(() {});
    if (game.ended) unawaited(_finish());
  }

  void _observeResult() {
    if (game.rounds == observedMatches && game.misses == observedMisses) return;
    matched = game.rounds > observedMatches;
    observedMatches = game.rounds;
    observedMisses = game.misses;
    resultAt = frameElapsed;
    if (matched) unawaited(HavenAudio.play(HavenSound.uiConfirm));
  }

  double _phase(bool reducedMotion) {
    if (!started) return 0;
    if (!game.accepting) {
      if (resultAt == null) return 0;
      if (reducedMotion || game.ended) return resultPhase;
      // Each canonical round starts with rune zero. Use its existing 420ms
      // intermission to bring the ring back around without swapping identities.
      final progress =
          ((frameElapsed - resultAt!).inMilliseconds / 420).clamp(0.0, 1.0);
      final nextCycle = (resultPhase / 5).round() * 5;
      return resultPhase +
          (nextCycle - resultPhase) * Curves.easeInOut.transform(progress);
    }
    final at = widget.controller?.presentationElapsedMs ?? game.milliseconds;
    return max(0.0, (at - game.roundStartedAt) / game.visibleMs);
  }

  void _tap() {
    if (!started) {
      started = true;
      localStartedAt = frameElapsed.inMilliseconds;
      widget.controller?.start();
      unawaited(HavenAudio.play(HavenSound.adventureStart));
      setState(() {});
      return;
    }
    if (!game.accepting) return;
    resultPhase = _phase(MediaQuery.disableAnimationsOf(context));
    if (widget.controller case final controller?) {
      controller.inputOrbitRune();
    } else {
      game.tap(game.gateRune, game.milliseconds);
    }
    _observeResult();
    setState(() {});
    if (game.ended) unawaited(_finish());
  }

  Future<void> _finish() async {
    if (finishing) return;
    finishing = true;
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (mounted && widget.controller == null) {
      await widget.onFinished(game.rounds);
    }
  }

  String _asset(int rune) =>
      'assets/images/ui/trials/rune_${runeKeys[rune]}_lit.png';

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final phase = _phase(reducedMotion);
    final resultAge =
        resultAt == null ? 1000 : (frameElapsed - resultAt!).inMilliseconds;
    final showResult = resultAt != null && (resultAge < 700 || game.ended);
    final feedbackColor =
        matched ? const Color(0xFF74F9CF) : const Color(0xFFFF536A);
    final flashOpacity =
        reducedMotion ? .20 : (1 - resultAge / 550).clamp(0.0, 1.0);
    return _StandardTrialScaffold(
      offer: widget.offer,
      dragon: widget.dragon,
      score: game.rounds,
      child: GestureDetector(
        key: const Key('rune-orbit-game'),
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/ui/trials/trial_rune_background.webp',
                fit: BoxFit.cover),
            const ColoredBox(color: Color(0xBB100A25)),
            if (showResult)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    key: const Key('rune-orbit-feedback-flash'),
                    opacity: flashOpacity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: feedbackColor, width: 4),
                        gradient: RadialGradient(
                          radius: .85,
                          colors: [
                            feedbackColor.withValues(alpha: .03),
                            feedbackColor.withValues(alpha: .42),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: _StatusChip(
                        icon: Icons.auto_awesome_rounded,
                        label: strings.pick('${game.rounds} matched',
                            '${game.rounds} gevangen'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    key: const Key('rune-orbit-lives'),
                    icon: Icons.favorite_rounded,
                    label: '${max(0, 3 - game.misses)}/3',
                  ),
                ],
              ),
            ),
            Positioned.fill(
              top: 72,
              bottom: 116,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final center = Offset(
                      constraints.maxWidth / 2, constraints.maxHeight / 2);
                  final radius =
                      min(constraints.maxWidth, constraints.maxHeight) * .34;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          key: const Key('rune-orbit-gate'),
                          painter: _RuneOrbitTrackPainter(
                            center: center,
                            radius: radius,
                          ),
                        ),
                      ),
                      for (var rune = 0; rune < 5; rune++)
                        Positioned(
                          key: Key('rune-orbit-position-$rune'),
                          left: center.dx +
                              cos(-pi / 2 + (rune - phase + .5) * pi * 2 / 5) *
                                  radius -
                              31,
                          top: center.dy +
                              sin(-pi / 2 + (rune - phase + .5) * pi * 2 / 5) *
                                  radius -
                              31,
                          child: Container(
                            width: 62,
                            height: 62,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xB51C103A),
                              border: Border.all(
                                color: game.accepting && rune == game.gateRune
                                    ? AppColors.gold
                                    : const Color(0x665E4A8B),
                                width: game.accepting && rune == game.gateRune
                                    ? 3
                                    : 1,
                              ),
                            ),
                            child: Image.asset(
                              _asset(rune),
                              key: Key('rune-orbit-rune-$rune'),
                            ),
                          ),
                        ),
                      Positioned(
                        left: center.dx - 67,
                        top: center.dy - 67,
                        child: Container(
                          width: 134,
                          height: 134,
                          padding: const EdgeInsets.all(17),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xE02A1A51),
                            border: Border.all(
                                color:
                                    showResult ? feedbackColor : AppColors.gold,
                                width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color: showResult
                                      ? feedbackColor.withValues(alpha: .4)
                                      : const Color(0x88B88AFF),
                                  blurRadius: reducedMotion ? 0 : 24)
                            ],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.asset(
                                  _asset(game.targetRune),
                                  key: const Key('rune-orbit-target'),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                strings.pick('TARGET', 'DOEL'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showResult)
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        key: Key(
                            matched ? 'rune-orbit-success' : 'rune-orbit-miss'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xF51E1239),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: feedbackColor, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                matched
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color: feedbackColor,
                                size: 23),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                matched
                                    ? strings.pick(
                                        'MATCHED! +1', 'GEVANGEN! +1')
                                    : strings.pick(
                                        'MISS! −1 heart', 'MIS! −1 hartje'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: feedbackColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    strings.pick(
                        'Tap when the matching rune enters the golden gate.',
                        'Tik als de juiste rune de gouden poort binnenkomt.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            if (!started)
              _StartCard(
                icon: Icons.blur_circular_rounded,
                title: strings.pick('Catch the rune', 'Vang de rune'),
                body: strings.pick(
                  'Watch the target in the center. Tap anywhere when the same rune reaches the golden gate at the top. Three misses end the Trial.',
                  'Bekijk het doel in het midden. Tik wanneer dezelfde rune de gouden poort bovenaan bereikt. Drie missers beeindigen de proef.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RuneOrbitTrackPainter extends CustomPainter {
  const _RuneOrbitTrackPainter({required this.center, required this.radius});
  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0x665E4A8B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    // Exactly one fifth of the orbit is selectable at a time. Center each
    // rune's canonical interval on the top of this visible gate sector.
    canvas.drawArc(
        ring,
        -pi / 2 - pi / 5,
        pi * 2 / 5,
        false,
        Paint()
          ..color = const Color(0x35FFE08A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 72);
    canvas.drawArc(
        ring.inflate(36),
        -pi / 2 - pi / 5,
        pi * 2 / 5,
        false,
        Paint()
          ..color = AppColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    for (final edge in [-1, 1]) {
      final angle = -pi / 2 + edge * pi / 5;
      final direction = Offset(cos(angle), sin(angle));
      canvas.drawLine(
          center + direction * (radius - 36),
          center + direction * (radius + 36),
          Paint()
            ..color = AppColors.gold
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _RuneOrbitTrackPainter oldDelegate) =>
      oldDelegate.center != center || oldDelegate.radius != radius;
}

class _StandardTrialScaffold extends StatelessWidget {
  const _StandardTrialScaffold({
    required this.offer,
    required this.dragon,
    required this.score,
    required this.child,
  });

  final TrialOffer offer;
  final TrialDragon dragon;
  final int score;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final focus = offer.definition.focus;
    final focusLabel = switch (focus) {
      TrainingFocus.might => strings.pick('Might', 'Kracht'),
      TrainingFocus.arcana => 'Arcana',
      TrainingFocus.spirit => 'Spirit',
    };
    return Scaffold(
      backgroundColor: AppColors.eventColor(context, const Color(0xFF17102E)),
      appBar: AppBar(
        backgroundColor: AppColors.eventColor(context, const Color(0xFF17102E)),
        foregroundColor: Colors.white,
        title: Text(
            strings.pick(offer.definition.titleEn, offer.definition.titleNl)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              color: const Color(0xFF211641),
              child: Row(
                children: [
                  GameIconSprite(GameIconSprite.forTrainingFocus(focus),
                      size: 30),
                  const SizedBox(width: 8),
                  Text(focusLabel,
                      style: const TextStyle(
                          color: AppColors.gold, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TrialIconSprite(kind: offer.kind, size: 30),
                          const SizedBox(width: 8),
                          Text(
                            '$score  /  ${strings.pick('Best', 'Beste')} '
                            '${dragon.trialBest(offer.kind.name)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xD52A1A51),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x88FFE08A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppColors.gold),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _StartCard extends StatelessWidget {
  const _StartCard(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title, body;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.black.withValues(alpha: .58),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 330),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xF02A1E50),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.gold),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.gold, size: 44),
                  const SizedBox(height: 10),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 7),
                  Text(body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFDCD2F4), height: 1.3)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Shape extends StatelessWidget {
  const _Shape({
    super.key,
    required this.shape,
    required this.size,
    required this.filled,
    required this.containedScoring,
    required this.color,
  });
  final SpiritAlignmentShape shape;
  final double size;
  final bool filled;
  final bool containedScoring;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
            painter: _ShapePainter(
                shape: shape,
                filled: filled,
                color: color,
                containedScoring: containedScoring)),
      );
}

class _ShapePainter extends CustomPainter {
  const _ShapePainter(
      {required this.shape,
      required this.filled,
      required this.color,
      required this.containedScoring});
  final SpiritAlignmentShape shape;
  final bool filled;
  final bool containedScoring;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final rect = containedScoring && filled
        ? bounds
            .deflate(size.width * (1 - SpiritAlignmentGeometry.playerScale) / 2)
        : bounds;
    final path = switch (shape) {
      SpiritAlignmentShape.circle => Path()..addOval(rect),
      SpiritAlignmentShape.square => Path()..addRect(rect),
      SpiritAlignmentShape.triangle => Path()
        ..moveTo(rect.center.dx, rect.top)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..close(),
    };
    if (containedScoring) {
      canvas.save();
      if (filled) {
        // Keep the entire white highlight inside the scored player shape.
        canvas.clipPath(path);
      } else {
        // Paint the gold ring outwards only: its inner edge is exactly the
        // target boundary used by the replay model, also for the triangle.
        canvas.clipPath(Path.combine(PathOperation.difference,
            Path()..addRect(bounds.inflate(size.width)), path));
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = containedScoring
            ? 2 * SpiritAlignmentGeometry.outlineWidth * size.width
            : filled
                ? 3
                : 5
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke,
    );
    if (filled) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white70
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
    if (containedScoring) canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.filled != filled ||
      oldDelegate.containedScoring != containedScoring ||
      oldDelegate.color != color;
}
