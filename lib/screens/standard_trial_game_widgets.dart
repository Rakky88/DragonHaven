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
                  _StatusChip(
                    icon: Icons.category_rounded,
                    label: '${game.shapeIndex + 1}/3',
                  ),
                ],
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
                                child: Text(
                                  '$overlap%',
                                  key: Key('spirit-overlap-${game.shapeIndex}'),
                                  style: TextStyle(
                                    color: overlap == 100
                                        ? const Color(0xFF82FFE0)
                                        : Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                  ),
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
                game.waitingForResult
                    ? (overlap == 100
                        ? strings.pick('Perfect overlap!', 'Perfecte overlap!')
                        : strings.pick('Next shape...', 'Volgende vorm...'))
                    : game.phase == SpiritAlignmentPhase.vertical
                        ? strings.pick('Tap to lock the height',
                            'Tik om de hoogte vast te zetten')
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
              _StartCard(
                icon: Icons.center_focus_strong_rounded,
                title: strings.pick(
                    'Align all three shapes', 'Lijn alle drie vormen uit'),
                body: strings.pick(
                  'Tap once to lock the height, then tap again on the golden outline. Three displayed 100% scores make the next round 10% faster.',
                  'Tik eenmaal om de hoogte vast te zetten en nogmaals op de gouden omtrek. Drie zichtbare scores van 100% maken de volgende ronde 10% sneller.',
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
                  return Stack(
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
                      Positioned(
                        key: const Key('ruin-guard-boulder'),
                        left:
                            game.targetLane * laneWidth + (laneWidth - 58) / 2,
                        top: game.boulderProgress * travel,
                        child: const Icon(
                          Icons.hexagon_rounded,
                          size: 58,
                          color: Color(0xFF706177),
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 10)
                          ],
                        ),
                      ),
                      AnimatedPositioned(
                        key: const Key('ruin-guard-dragon'),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 150),
                        curve: Curves.easeOutBack,
                        left: game.playerLane * laneWidth,
                        bottom: 2,
                        width: laneWidth,
                        child: DragonArt(
                          height: 90,
                          animate: !game.locked,
                          stageKey: widget.dragon.stageKey,
                          lineageId: widget.dragon.lineageId,
                          evolutionPath: widget.dragon.activeEvolutionPath,
                          prismatic: widget.dragon.prismatic,
                          sinister: widget.dragon.sinister,
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

class _RuneOrbitTrialGameState extends State<RuneOrbitTrialGame> {
  static const runeKeys = ['fire', 'water', 'moon', 'star', 'wind'];
  late final RuneOrbitGame game;
  Timer? timer;
  bool started = false, finishing = false;

  @override
  void initState() {
    super.initState();
    game = widget.controller?.model.orbit ??
        RuneOrbitGame(
          seed: widget.offer.id.hashCode,
          arcana: widget.dragon.trainingFor(TrainingFocus.arcana),
        );
    widget.controller?.addListener(_verifiedFrame);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_verifiedFrame);
    timer?.cancel();
    super.dispose();
  }

  void _verifiedFrame() {
    if (!mounted) return;
    setState(() {});
    if (game.ended) unawaited(_finish());
  }

  void _tap() {
    if (!started) {
      started = true;
      widget.controller?.start();
      unawaited(HavenAudio.play(HavenSound.adventureStart));
      if (widget.controller == null) {
        timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
          if (!mounted || game.ended) return;
          game.advanceTo(timer.tick * 16);
          setState(() {});
          if (game.ended) unawaited(_finish());
        });
      }
      setState(() {});
      return;
    }
    if (!game.accepting) return;
    final rune = game.gateRune;
    if (widget.controller case final controller?) {
      controller.input(TrialControl.tapRune, rune);
    } else {
      game.tap(rune, game.milliseconds);
    }
    unawaited(HavenAudio.play(HavenSound.uiConfirm));
    setState(() {});
  }

  Future<void> _finish() async {
    if (finishing) return;
    finishing = true;
    timer?.cancel();
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
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusChip(
                    icon: Icons.auto_awesome_rounded,
                    label: strings.pick(
                        '${game.rounds} matched', '${game.rounds} gevangen'),
                  ),
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
              bottom: 72,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final center = Offset(
                      constraints.maxWidth / 2, constraints.maxHeight / 2);
                  final radius =
                      min(constraints.maxWidth, constraints.maxHeight) * .34;
                  return Stack(
                    children: [
                      for (var slot = 0; slot < 5; slot++)
                        Positioned(
                          left: center.dx +
                              cos(-pi / 2 + slot * pi * 2 / 5) * radius -
                              31,
                          top: center.dy +
                              sin(-pi / 2 + slot * pi * 2 / 5) * radius -
                              31,
                          child: Opacity(
                            opacity: slot == 0 ? 1 : .58,
                            child: Image.asset(
                              _asset((game.gateRune + slot) % 5),
                              key: slot == 0
                                  ? const Key('rune-orbit-gate')
                                  : null,
                              width: 62,
                              height: 62,
                            ),
                          ),
                        ),
                      Positioned(
                        left: center.dx - 67,
                        top: center.dy - 67,
                        child: Container(
                          width: 134,
                          height: 134,
                          padding: const EdgeInsets.all(23),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xE02A1A51),
                            border: Border.all(color: AppColors.gold, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x88B88AFF), blurRadius: 24)
                            ],
                          ),
                          child: Image.asset(
                            _asset(game.targetRune),
                            key: const Key('rune-orbit-target'),
                          ),
                        ),
                      ),
                      Positioned(
                        left: center.dx - 60,
                        top: center.dy + 74,
                        width: 120,
                        child: Text(
                          strings.pick('MATCH', 'VANG'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
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
              bottom: 22,
              child: Text(
                strings.pick('Tap when the matching rune reaches the top gate.',
                    'Tik wanneer de juiste rune de bovenste poort bereikt.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800),
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
                  const Spacer(),
                  TrialIconSprite(kind: offer.kind, size: 30),
                  const SizedBox(width: 8),
                  Text(
                    '$score  /  ${strings.pick('Best', 'Beste')} '
                    '${dragon.trialBest(offer.kind.name)}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900),
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
                    style:
                        const TextStyle(color: Color(0xFFDCD2F4), height: 1.3)),
              ],
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
    required this.color,
  });
  final SpiritAlignmentShape shape;
  final double size;
  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
            painter: _ShapePainter(shape: shape, filled: filled, color: color)),
      );
}

class _ShapePainter extends CustomPainter {
  const _ShapePainter(
      {required this.shape, required this.filled, required this.color});
  final SpiritAlignmentShape shape;
  final bool filled;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = switch (shape) {
      SpiritAlignmentShape.circle => Path()..addOval(rect),
      SpiritAlignmentShape.square => Path()..addRect(rect),
      SpiritAlignmentShape.triangle => Path()
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
    };
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = filled ? 3 : 5
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
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.filled != filled ||
      oldDelegate.color != color;
}
