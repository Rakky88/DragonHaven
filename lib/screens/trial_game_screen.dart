import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import '../models/trial.dart';
import '../providers/household_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/trial_icon_sprite.dart';

class TrialGameScreen extends StatefulWidget {
  const TrialGameScreen({
    super.key,
    required this.offerId,
    required this.dragonId,
  });

  final String offerId;
  final String dragonId;

  @override
  State<TrialGameScreen> createState() => _TrialGameScreenState();
}

class _TrialGameScreenState extends State<TrialGameScreen> {
  TrialOffer? _offer;
  Pet? _dragon;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_offer != null && _dragon != null) return;
    final game = context.read<HouseholdProvider>();
    _offer = game.availableTrials.cast<TrialOffer?>().firstWhere(
          (candidate) => candidate?.id == widget.offerId,
          orElse: () => null,
        );
    _dragon = game.ownedDragons.cast<Pet?>().firstWhere(
          (candidate) => candidate?.id == widget.dragonId,
          orElse: () => null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offer;
    final dragon = _dragon;
    if (offer == null || dragon == null) {
      return _UnavailableTrial(onClose: () => Navigator.pop(context));
    }
    return switch (offer.kind) {
      TrialKind.cavernFlight => _CavernFlightGame(offer: offer, dragon: dragon),
      TrialKind.ruinBreaker => _RuinBreakerGame(offer: offer, dragon: dragon),
      TrialKind.runeweaver => _RuneweaverGame(offer: offer, dragon: dragon),
    };
  }
}

class _UnavailableTrial extends StatelessWidget {
  const _UnavailableTrial({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF17102E),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GameIconSprite(
                    GameIconKind.adventureActive,
                    size: 110,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.of(context).pick(
                      'This Trial is no longer available.',
                      'Deze proef is niet meer beschikbaar.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onClose, child: const Text('OK')),
                ],
              ),
            ),
          ),
        ),
      );
}

class _TrialScaffold extends StatelessWidget {
  const _TrialScaffold({
    required this.title,
    required this.focus,
    required this.score,
    required this.best,
    required this.child,
  });

  final String title;
  final TrainingFocus focus;
  final int score;
  final int best;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF17102E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17102E),
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              decoration: const BoxDecoration(
                color: Color(0xFF211641),
                border: Border(bottom: BorderSide(color: Color(0x355B4B8A))),
              ),
              child: Row(
                children: [
                  GameIconSprite(
                    GameIconSprite.forTrainingFocus(focus),
                    size: 30,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _focusLabel(strings, focus),
                    style: const TextStyle(
                      color: Color(0xFFFFE08A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  TrialIconSprite(
                    kind: switch (focus) {
                      TrainingFocus.spirit => TrialKind.cavernFlight,
                      TrainingFocus.might => TrialKind.ruinBreaker,
                      TrainingFocus.arcana => TrialKind.runeweaver,
                    },
                    size: 30,
                  ),
                  const SizedBox(width: 7),
                  _HudValue(
                    label: strings.pick('SCORE', 'SCORE'),
                    value: '$score',
                  ),
                  const SizedBox(width: 16),
                  _HudValue(
                    label: strings.pick('BEST', 'BESTE'),
                    value: '$best',
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

class _HudValue extends StatelessWidget {
  const _HudValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 8,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
}

Future<void> _finishTrial(
  BuildContext context, {
  required TrialOffer offer,
  required Pet dragon,
  required int score,
}) async {
  // Keep the route navigator itself. Completing the Trial removes its offer and
  // rebuilds this screen, so the individual game's BuildContext can be disposed
  // while the result dialog is still visible.
  final routeNavigator = Navigator.of(context);
  final game = context.read<HouseholdProvider>();
  final completion = await game.completeTrial(
    offerId: offer.id,
    dragonId: dragon.id,
    score: score,
  );
  if (!routeNavigator.mounted) return;
  if (completion == null) {
    routeNavigator.pop();
    return;
  }
  unawaited(HavenAudio.play(HavenSound.adventureReturn));
  await showGeneralDialog<void>(
    context: routeNavigator.context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 500),
    transitionBuilder: (_, animation, __, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
        child: child,
      ),
    ),
    pageBuilder: (dialogContext, _, __) => _TrialResultCard(
      completion: completion,
      dragonName: dragon.displayName,
      onContinue: () => Navigator.pop(dialogContext),
    ),
  );
  if (routeNavigator.mounted) routeNavigator.pop(completion);
}

class _TrialResultCard extends StatelessWidget {
  const _TrialResultCard({
    required this.completion,
    required this.dragonName,
    required this.onContinue,
  });

  final TrialCompletion completion;
  final String dragonName;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final reward = completion.reward;
    final grade = trialGradeLabel(reward.grade);
    final chest = reward.chestTier;
    final color = switch (reward.grade) {
      TrialGrade.d => const Color(0xFFB6B0C4),
      TrialGrade.c => const Color(0xFF8BD8B9),
      TrialGrade.b => const Color(0xFF78B7FF),
      TrialGrade.a => const Color(0xFFF4C95D),
      TrialGrade.s => const Color(0xFFE987FF),
      TrialGrade.sPlus => Colors.white,
    };
    return PopScope(
      canPop: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 390),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF392465), Color(0xFF1C1237)],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.gold, width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: .35), blurRadius: 38),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings.pick('TRIAL COMPLETE', 'PROEF VOLTOOID'),
                    style: const TextStyle(
                      color: Color(0xFFFFE08A),
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 158,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 1350),
                          curve: Curves.easeOutCubic,
                          builder: (_, turn, child) => Transform.rotate(
                            angle: turn * pi * 1.5,
                            child: Transform.scale(
                              scale: .75 + turn * .42,
                              child: child,
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 142,
                            color: color.withValues(alpha: .28),
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: .06, end: 1),
                          duration: const Duration(milliseconds: 1050),
                          curve: Curves.elasticOut,
                          builder: (_, scale, child) => Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                          child: Image.asset(
                            _trialGradeAsset(reward.grade),
                            key: const Key('trial-result-grade'),
                            width: 154,
                            height: 154,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            semanticLabel: 'Trial grade $grade',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${completion.score} ${strings.pick('points', 'punten')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (completion.newDragonBest) ...[
                    const SizedBox(height: 6),
                    Text(
                      strings.pick('NEW $dragonName RECORD!',
                          'NIEUW RECORD VOOR $dragonName!'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFE08A),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        _RewardLine(
                          icon: GameIconKind.coin,
                          label:
                              '+${reward.coins} ${strings.pick('coins', 'munten')}',
                        ),
                        _RewardLine(
                          icon: GameIconKind.experience,
                          label: '+${reward.xp} XP',
                        ),
                        _RewardLine(
                          icon: GameIconSprite.forTrainingFocus(
                            trialDefinitions[completion.kind]!.focus,
                          ),
                          label:
                              '+${reward.statPoints} ${_focusLabel(strings, trialDefinitions[completion.kind]!.focus)}',
                        ),
                        if (chest != null)
                          _RewardLine(
                            icon: GameIconKind.chest,
                            label: strings.chestLabel(chest),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('trial-result-continue'),
                      onPressed: onContinue,
                      child: Text(strings.pick('Continue', 'Verder')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _trialGradeAsset(TrialGrade grade) => switch (grade) {
      TrialGrade.d => 'assets/images/ui/trials/grade_d.png',
      TrialGrade.c => 'assets/images/ui/trials/grade_c.png',
      TrialGrade.b => 'assets/images/ui/trials/grade_b.png',
      TrialGrade.a => 'assets/images/ui/trials/grade_a.png',
      TrialGrade.s => 'assets/images/ui/trials/grade_s.png',
      TrialGrade.sPlus => 'assets/images/ui/trials/grade_s_plus.png',
    };

class _RewardLine extends StatelessWidget {
  const _RewardLine({required this.icon, required this.label});

  final GameIconKind icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            GameIconSprite(icon, size: 27),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

class _CavernFlightGame extends StatefulWidget {
  const _CavernFlightGame({required this.offer, required this.dragon});

  final TrialOffer offer;
  final Pet dragon;

  @override
  State<_CavernFlightGame> createState() => _CavernFlightGameState();
}

class _CavernFlightGameState extends State<_CavernFlightGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final Random _random;
  Duration? _lastTick;
  Size _gameSize = Size.zero;
  final List<_FlightObstacle> _obstacles = [];
  bool _started = false;
  bool _ended = false;
  bool _finishing = false;
  double _dragonY = .5;
  double _velocity = 0;
  double _elapsed = 0;
  int _score = 0;
  int _passed = 0;

  @override
  void initState() {
    super.initState();
    _random = Random(widget.offer.id.hashCode);
    _obstacles.addAll(List.generate(
      3,
      (index) => _newObstacle(1.15 + index * .58),
    ));
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  _FlightObstacle _newObstacle(double x) => _FlightObstacle(
        x: x,
        gap: .30 + _random.nextDouble() * .40,
        halfGap: .19 - min(_passed, 10) * .0035,
        crystal: _random.nextBool(),
        moving: _passed >= 4 && _random.nextInt(4) == 0,
        phase: _random.nextDouble() * pi * 2,
      );

  void _tick(Duration elapsed) {
    final previous = _lastTick;
    _lastTick = elapsed;
    if (!_started || _ended || previous == null || _gameSize.isEmpty) return;
    final dt = min((elapsed - previous).inMicroseconds / 1000000, .035);
    _elapsed += dt;
    _velocity += 1.55 * dt;
    _dragonY += _velocity * dt;
    final speed = .27 + min(_elapsed / 120, .12);
    for (final obstacle in _obstacles) {
      obstacle.x -= speed * dt;
      if (!obstacle.passed && obstacle.x < .20) {
        obstacle.passed = true;
        _passed++;
        unawaited(HavenAudio.play(HavenSound.uiConfirm));
      }
    }
    if (_obstacles.first.x < -.20) _obstacles.removeAt(0);
    if (_obstacles.last.x < .82) {
      _obstacles.add(_newObstacle(_obstacles.last.x + .58));
    }
    _score = (_elapsed * 10).floor() + _passed * 25;
    if (_collides()) {
      _ended = true;
      unawaited(HavenAudio.play(HavenSound.uiConfirm));
      setState(() {});
      _finishAfterCrash();
      return;
    }
    setState(() {});
  }

  bool _collides() {
    final hitboxScale = cavernFlightHitboxScale(
      widget.dragon.trainingFor(TrainingFocus.spirit),
    );
    final center = Offset(_gameSize.width * .24, _gameSize.height * _dragonY);
    final dragonBox = Rect.fromCenter(
      center: center,
      width: 43 * hitboxScale,
      height: 31 * hitboxScale,
    );
    if (dragonBox.top <= 0 || dragonBox.bottom >= _gameSize.height) return true;
    for (final obstacle in _obstacles) {
      final left = obstacle.x * _gameSize.width;
      final right = left + _gameSize.width * .13;
      if (dragonBox.right < left || dragonBox.left > right) continue;
      final gap = obstacle.gapAt(_elapsed);
      final topBottom = (gap - obstacle.halfGap) * _gameSize.height;
      final bottomTop = (gap + obstacle.halfGap) * _gameSize.height;
      if (dragonBox.top < topBottom || dragonBox.bottom > bottomTop) {
        return true;
      }
    }
    return false;
  }

  Future<void> _finishAfterCrash() async {
    if (_finishing) return;
    _finishing = true;
    await Future<void>.delayed(const Duration(milliseconds: 760));
    if (!mounted) return;
    await _finishTrial(
      context,
      offer: widget.offer,
      dragon: widget.dragon,
      score: _score,
    );
  }

  void _flap() {
    if (_ended) return;
    if (!_started) {
      _started = true;
      _lastTick = null;
      unawaited(HavenAudio.play(HavenSound.adventureStart));
    }
    _velocity = -.58;
    unawaited(HavenAudio.play(HavenSound.uiConfirm));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _TrialScaffold(
      title: strings.pick(
        widget.offer.definition.titleEn,
        widget.offer.definition.titleNl,
      ),
      focus: TrainingFocus.spirit,
      score: _score,
      best: widget.dragon.trialBest(widget.offer.kind.name),
      child: LayoutBuilder(
        builder: (context, constraints) {
          _gameSize = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            key: const Key('cavern-flight-game'),
            behavior: HitTestBehavior.opaque,
            onTap: _flap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/ui/trials/trial_cavern_background.webp',
                  fit: BoxFit.cover,
                ),
                _CavernObstacleSprites(
                  obstacles: _obstacles,
                  elapsed: _elapsed,
                ),
                CustomPaint(
                  painter: _CavernPainter(
                    elapsed: _elapsed,
                    spirit: widget.dragon.trainingFor(TrainingFocus.spirit),
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * .24 - 48,
                  top: constraints.maxHeight * _dragonY - 48,
                  child: _FlightDragonSprite(
                    dragon: widget.dragon,
                    elapsed: _elapsed,
                    velocity: _velocity,
                    flying: _started,
                    crashed: _ended,
                  ),
                ),
                if (!_started)
                  _StartOverlay(
                    title: strings.pick('Tap to flap', 'Tik om te vliegen'),
                    body: strings.pick(
                      'Fly through every opening. Spirit subtly reduces your real hitbox.',
                      'Vlieg door iedere opening. Spirit verkleint subtiel je echte hitbox.',
                    ),
                    icon: Icons.touch_app_rounded,
                  ),
                if (_ended)
                  Center(
                    child: Text(
                      strings.pick('RECOVERING...', 'HERSTELLEN...'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(blurRadius: 12)],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FlightDragonSprite extends StatelessWidget {
  const _FlightDragonSprite({
    required this.dragon,
    required this.elapsed,
    required this.velocity,
    required this.flying,
    required this.crashed,
  });

  final Pet dragon;
  final double elapsed;
  final double velocity;
  final bool flying;
  final bool crashed;

  @override
  Widget build(BuildContext context) {
    // Four beats use three purpose-built wing sprites: up, middle, down,
    // middle. The selected dragon remains visible at the common wing hinge.
    final beat = flying ? (elapsed * 8).floor() % 4 : 1;
    final frame = crashed ? 2 : const [0, 1, 2, 1][beat];
    final lift = switch (frame) { 0 => -3.0, 2 => 3.0, _ => 0.0 };
    final bodyOffset = switch (frame) { 0 => 18.0, 2 => -14.0, _ => 1.0 };
    final bodySize = switch (dragon.stage) {
      DragonStage.hatchling => 46.0,
      DragonStage.wyrmling => 52.0,
      DragonStage.ascended => 58.0,
      DragonStage.egg => 44.0,
    };
    final bank = crashed ? .34 : velocity.clamp(-.6, .7) * .32;
    return Semantics(
      label: 'Animated flight sprite for ${dragon.displayName}',
      child: Transform.translate(
        offset: Offset(crashed ? 10 : 0, lift),
        child: Transform.rotate(
          angle: bank,
          child: Transform.scale(
            scale: crashed ? .94 : 1,
            child: SizedBox.square(
              dimension: 96,
              child: ColorFiltered(
                colorFilter: crashed
                    ? const ColorFilter.mode(
                        Color(0xFFB8A5CB), BlendMode.modulate)
                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _FlightWingFrame(frame: frame),
                    Transform.translate(
                      offset: Offset(0, bodyOffset),
                      child: DragonArt(
                        height: bodySize,
                        animate: false,
                        stageKey: dragon.stageKey,
                        lineageId: dragon.lineageId,
                        evolutionPath: dragon.activeEvolutionPath,
                        prismatic: dragon.prismatic,
                        sinister: dragon.sinister,
                      ),
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

class _FlightWingFrame extends StatelessWidget {
  const _FlightWingFrame({required this.frame});

  final int frame;

  @override
  Widget build(BuildContext context) => ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 288,
          maxWidth: 288,
          minHeight: 96,
          maxHeight: 96,
          child: Transform.translate(
            offset: Offset(-96.0 * frame, 0),
            child: Image.asset(
              'assets/images/ui/trials/trial_flight_wings.png',
              width: 288,
              height: 96,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      );
}

class _FlightObstacle {
  _FlightObstacle({
    required this.x,
    required this.gap,
    required this.halfGap,
    required this.crystal,
    required this.moving,
    required this.phase,
  });

  double x;
  final double gap;
  final double halfGap;
  final bool crystal;
  final bool moving;
  final double phase;
  bool passed = false;

  double gapAt(double elapsed) =>
      (gap + (moving ? sin(elapsed * 1.4 + phase) * .045 : 0)).clamp(.23, .77);
}

class _CavernPainter extends CustomPainter {
  const _CavernPainter({
    required this.elapsed,
    required this.spirit,
  });

  final double elapsed;
  final int spirit;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x44120C29), Color(0x552C1746), Color(0x660C1026)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);
    final particlePaint = Paint()
      ..color =
          spirit >= 200 ? const Color(0xA8A7FFF0) : const Color(0x6552C9DD)
      ..strokeWidth = spirit >= 200 ? 2 : 1;
    for (var index = 0; index < 13; index++) {
      final x = ((index * 83 + elapsed * 62) % size.width);
      final y = (index * 47.0) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x + 12, y - 2), particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CavernPainter oldDelegate) => true;
}

class _CavernObstacleSprites extends StatelessWidget {
  const _CavernObstacleSprites({
    required this.obstacles,
    required this.elapsed,
  });

  final List<_FlightObstacle> obstacles;
  final double elapsed;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          // The artwork deliberately fans out beyond the real .13-wide
          // collision column. Keep that gameplay column unchanged, while
          // centring a broader silhouette over it so the crystal formations
          // read as substantial cave obstacles instead of thin needles.
          final width = size.width * .22;
          return ClipRect(
            child: Stack(
              children: [
                for (final obstacle in obstacles) ...[
                  Positioned(
                    left: (obstacle.x - .045) * size.width,
                    top: 0,
                    width: width,
                    height: max(
                      1.0,
                      (obstacle.gapAt(elapsed) - obstacle.halfGap) *
                          size.height,
                    ),
                    child: Image.asset(
                      'assets/images/ui/trials/trial_stalactite.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Positioned(
                    left: (obstacle.x - .045) * size.width,
                    top: (obstacle.gapAt(elapsed) + obstacle.halfGap) *
                        size.height,
                    bottom: 0,
                    width: width,
                    child: Image.asset(
                      'assets/images/ui/trials/trial_stalagmite.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
}

class _StartOverlay extends StatelessWidget {
  const _StartOverlay({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.black.withValues(alpha: .58),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 310),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xEE2A1E50),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.gold),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.gold, size: 44),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFDCD2F4), height: 1.3),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RuinBreakerGame extends StatefulWidget {
  const _RuinBreakerGame({required this.offer, required this.dragon});

  final TrialOffer offer;
  final Pet dragon;

  @override
  State<_RuinBreakerGame> createState() => _RuinBreakerGameState();
}

class _RuinBreakerGameState extends State<_RuinBreakerGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration? _lastTick;
  double _time = 0;
  double _meter = 0;
  bool _started = false;
  bool _locked = false;
  bool _ended = false;
  bool _impact = false;
  int _round = 0;
  int _score = 0;
  int _combo = 0;
  int _misses = 0;
  String _feedback = '';

  static const _obstacles = [
    ('Rock', 'Rots', 100),
    ('Reinforced Rock', 'Versterkte rots', 140),
    ('Ancient Wall', 'Oude muur', 190),
    ('Crystal Formation', 'Kristalformatie', 250),
    ('Giant Boulder', 'Reuzenkei', 340),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool get _isGap => _round > 0 && (_round + 1) % 6 == 0;

  void _tick(Duration elapsed) {
    final previous = _lastTick;
    _lastTick = elapsed;
    if (!_started || _ended || _locked || previous == null) return;
    final dt = min((elapsed - previous).inMicroseconds / 1000000, .04);
    _time += dt;
    final speed = 1.8 + min(_round * .10, 2.2);
    _meter = (sin(_time * speed - pi / 2) + 1) / 2;
    setState(() {});
  }

  void _start() {
    if (_started) return;
    _started = true;
    _lastTick = null;
    unawaited(HavenAudio.play(HavenSound.adventureStart));
    setState(() {});
  }

  Future<void> _strike() async {
    if (!_started) {
      _start();
      return;
    }
    if (_locked || _ended) return;
    _locked = true;
    final distance = (_meter - .5).abs();
    final might = widget.dragon.trainingFor(TrainingFocus.might);
    final perfectHalf = .045 * ruinBreakerPerfectZoneScale(might);
    final successHalf = .18 * ruinBreakerSuccessZoneScale(might);
    final base = _isGap ? 210 : _obstacles[_round % _obstacles.length].$3;
    if (distance <= perfectHalf) {
      _combo++;
      _score += (base * (1 + min(_combo, 8) * .15)).round();
      _feedback = _combo >= 4 ? 'SMASH STREAK x$_combo!' : 'PERFECT x$_combo!';
      unawaited(HavenAudio.play(HavenSound.uiConfirm));
    } else if (distance <= successHalf) {
      _combo = 0;
      _score += (base * .60).round();
      _feedback = _isGap ? 'CLEAR!' : 'SMASH!';
      unawaited(HavenAudio.play(HavenSound.uiConfirm));
    } else {
      _combo = 0;
      _misses++;
      _feedback = _isGap ? 'MISSED JUMP!' : 'GLANCING HIT!';
      unawaited(HavenAudio.play(HavenSound.uiConfirm));
    }
    _impact = true;
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 330));
    if (!mounted) return;
    _impact = false;
    _round++;
    _time = 0;
    _meter = 0;
    if (_misses >= 3 || _round >= 30) {
      _ended = true;
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      await _finishTrial(
        context,
        offer: widget.offer,
        dragon: widget.dragon,
        score: _score,
      );
      return;
    }
    _locked = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final might = widget.dragon.trainingFor(TrainingFocus.might);
    final successHalf = .18 * ruinBreakerSuccessZoneScale(might);
    final perfectHalf = .045 * ruinBreakerPerfectZoneScale(might);
    final obstacle = _obstacles[_round % _obstacles.length];
    return _TrialScaffold(
      title: strings.pick(
        widget.offer.definition.titleEn,
        widget.offer.definition.titleNl,
      ),
      focus: TrainingFocus.might,
      score: _score,
      best: widget.dragon.trialBest(widget.offer.kind.name),
      child: GestureDetector(
        key: const Key('ruin-breaker-game'),
        behavior: HitTestBehavior.opaque,
        onTap: _strike,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/ui/trials/trial_ruin_background.webp',
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFA120C29)],
                  stops: [.25, .72],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 22,
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      _feedback.isEmpty
                          ? (_isGap
                              ? strings.pick('CHASM — JUMP!', 'KLOOF — SPRING!')
                              : strings.pick(obstacle.$1, obstacle.$2))
                          : _feedback,
                      key: ValueKey('$_round-$_feedback'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _feedback.contains('PERFECT') ||
                                _feedback.contains('STREAK')
                            ? AppColors.gold
                            : Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        shadows: const [Shadow(blurRadius: 10)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedScale(
                    scale: _impact ? 1.12 : 1,
                    duration: const Duration(milliseconds: 120),
                    child: _RuinDragonSprite(
                      dragon: widget.dragon,
                      impact: _impact,
                      success: _feedback.contains('PERFECT') ||
                          _feedback.contains('SMASH') ||
                          _feedback.contains('CLEAR'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PowerMeter(
                    value: _meter,
                    successHalf: successHalf,
                    perfectHalf: perfectHalf,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${strings.pick('Mistakes', 'Missers')}: $_misses/3',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const Spacer(),
                      Text(
                        _combo == 0
                            ? ''
                            : '${strings.pick('Combo', 'Combo')} x$_combo',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!_started)
              _StartOverlay(
                title: strings.pick(
                    'Tap for the perfect hit', 'Tik voor de perfecte slag'),
                body: strings.pick(
                  'Stop the moving marker in the center. Watch out for chasms.',
                  'Stop de bewegende marker in het midden. Let op kloven.',
                ),
                icon: Icons.flash_on_rounded,
              ),
          ],
        ),
      ),
    );
  }
}

class _RuinDragonSprite extends StatelessWidget {
  const _RuinDragonSprite({
    required this.dragon,
    required this.impact,
    required this.success,
  });

  final Pet dragon;
  final bool impact;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final hatchling = dragon.stage == DragonStage.hatchling;
    final ascended = dragon.stage == DragonStage.ascended;
    final lunge = impact ? (ascended ? 26.0 : 14.0) : 0.0;
    return SizedBox(
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (impact && success)
            Transform.scale(
              scale: ascended ? 1.35 : .82,
              child: const Icon(
                Icons.brightness_7_rounded,
                size: 82,
                color: Color(0x77FFE28A),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 115),
            curve: Curves.easeOutBack,
            transform: Matrix4.identity()
              ..translateByDouble(lunge, impact ? 3 : 0, 0, 1)
              ..rotateZ(impact && hatchling ? .12 : 0),
            child: DragonArt(
              height: ascended ? 100 : 88,
              animate: !impact,
              stageKey: dragon.stageKey,
              lineageId: dragon.lineageId,
              evolutionPath: dragon.activeEvolutionPath,
              prismatic: dragon.prismatic,
              sinister: dragon.sinister,
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerMeter extends StatelessWidget {
  const _PowerMeter({
    required this.value,
    required this.successHalf,
    required this.perfectHalf,
  });

  final double value;
  final double successHalf;
  final double perfectHalf;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 62,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/ui/trials/trial_reaction_bar.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned(
                  top: 20,
                  child: Container(
                    width: width * successHalf * 2,
                    height: 25,
                    decoration: BoxDecoration(
                      color: const Color(0x2255C6A9),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: const Color(0xFF6FF0B4),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  child: Container(
                    width: width * perfectHalf * 2,
                    height: 29,
                    decoration: BoxDecoration(
                      color: const Color(0x33FFF0A0),
                      borderRadius: BorderRadius.circular(99),
                      border:
                          Border.all(color: const Color(0xFFFFE08A), width: 2),
                    ),
                  ),
                ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'GOOD',
                        style: TextStyle(
                          color: Color(0xFF8FF4C4),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(width: 13),
                      Text(
                        'PERFECT',
                        style: TextStyle(
                          color: Color(0xFFFFE08A),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: (width - 13) * value,
                  top: 13,
                  child: Container(
                    width: 13,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFFFD96A)],
                      ),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: const Color(0xFF6B3F14)),
                      boxShadow: const [
                        BoxShadow(color: Color(0xAAFFE08A), blurRadius: 9),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _RuneweaverGame extends StatefulWidget {
  const _RuneweaverGame({required this.offer, required this.dragon});

  final TrialOffer offer;
  final Pet dragon;

  @override
  State<_RuneweaverGame> createState() => _RuneweaverGameState();
}

class _RuneweaverGameState extends State<_RuneweaverGame> {
  late final Random _random;
  final List<int> _sequence = [];
  List<int> _positions = [0, 1, 2, 3, 4];
  bool _started = false;
  bool _showing = false;
  bool _accepting = false;
  bool _ended = false;
  bool _echoUsed = false;
  int? _litRune;
  int? _echoRune;
  int _inputIndex = 0;
  int _rounds = 0;

  static const _runeKeys = ['fire', 'water', 'moon', 'star', 'wind'];

  @override
  void initState() {
    super.initState();
    _random = Random(widget.offer.id.hashCode ^ widget.dragon.hatchSeed);
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    unawaited(HavenAudio.play(HavenSound.adventureStart));
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) await _nextRound();
  }

  Future<void> _nextRound() async {
    if (_ended) return;
    _sequence.add(_random.nextInt(_runeKeys.length));
    _inputIndex = 0;
    _showing = true;
    _accepting = false;
    _echoRune = null;
    setState(() {});
    final visible = runeweaverRuneDuration(
      widget.dragon.trainingFor(TrainingFocus.arcana),
    );
    for (final rune in _sequence) {
      if (!mounted || _ended) return;
      setState(() => _litRune = rune);
      unawaited(HavenAudio.play(HavenSound.uiConfirm));
      await Future<void>.delayed(visible);
      if (!mounted || _ended) return;
      setState(() => _litRune = null);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    if (_rounds >= 6) {
      _positions = [..._positions]..shuffle(_random);
    }
    if (!_echoUsed &&
        _rounds >= 3 &&
        widget.dragon.trainingFor(TrainingFocus.arcana) >= 240) {
      _echoRune = _sequence.last;
      _echoUsed = true;
    }
    _showing = false;
    _accepting = true;
    setState(() {});
  }

  Future<void> _tapRune(int rune) async {
    if (!_accepting || _ended) return;
    _echoRune = null;
    if (rune != _sequence[_inputIndex]) {
      _accepting = false;
      _ended = true;
      _litRune = rune;
      unawaited(HavenAudio.play(HavenSound.uiConfirm));
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      await _finishTrial(
        context,
        offer: widget.offer,
        dragon: widget.dragon,
        score: _rounds,
      );
      return;
    }
    _litRune = rune;
    _inputIndex++;
    unawaited(HavenAudio.play(HavenSound.uiConfirm));
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _litRune = null;
    if (_inputIndex == _sequence.length) {
      _accepting = false;
      _rounds++;
      setState(() {});
      if (_rounds >= 15) {
        _ended = true;
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        await _finishTrial(
          context,
          offer: widget.offer,
          dragon: widget.dragon,
          score: _rounds,
        );
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 650));
        if (mounted) await _nextRound();
      }
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _TrialScaffold(
      title: strings.pick(
        widget.offer.definition.titleEn,
        widget.offer.definition.titleNl,
      ),
      focus: TrainingFocus.arcana,
      score: _rounds,
      best: widget.dragon.trialBest(widget.offer.kind.name),
      child: GestureDetector(
        key: const Key('runeweaver-game'),
        behavior: HitTestBehavior.opaque,
        onTap: _started ? null : _start,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/ui/trials/trial_rune_background.webp',
              fit: BoxFit.cover,
            ),
            ColoredBox(color: const Color(0xAA100A25)),
            Column(
              children: [
                const SizedBox(height: 14),
                Text(
                  _showing
                      ? strings.pick('WATCH THE RUNES', 'KIJK NAAR DE RUNEN')
                      : _accepting
                          ? strings.pick('WEAVE THE SEQUENCE', 'WEEF DE REEKS')
                          : strings.pick('ARCANE SURGE', 'ARCANE SURGE'),
                  style: const TextStyle(
                    color: Color(0xFFFFE08A),
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${strings.pick('Sequence', 'Reeks')} ${_sequence.length} · '
                  '${strings.pick('Completed', 'Voltooid')} $_rounds',
                  style: const TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 13,
                    runSpacing: 13,
                    children: [
                      for (final rune in _positions)
                        _RuneButton(
                          key: Key('rune-$rune'),
                          runeKey: _runeKeys[rune],
                          lit: _litRune == rune,
                          echo: _echoRune == rune,
                          enabled: _accepting,
                          onTap: () => _tapRune(rune),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 104,
                  child: DragonArt(
                    height: 104,
                    stageKey: widget.dragon.stageKey,
                    lineageId: widget.dragon.lineageId,
                    evolutionPath: widget.dragon.activeEvolutionPath,
                    prismatic: widget.dragon.prismatic,
                    sinister: widget.dragon.sinister,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            if (!_started)
              _StartOverlay(
                title: strings.pick(
                    'Tap to awaken the gate', 'Tik om de poort te wekken'),
                body: strings.pick(
                  'Watch each rune, then reproduce the complete sequence.',
                  'Bekijk iedere rune en herhaal daarna de volledige reeks.',
                ),
                icon: Icons.auto_awesome_rounded,
              ),
          ],
        ),
      ),
    );
  }
}

class _RuneButton extends StatelessWidget {
  const _RuneButton({
    super.key,
    required this.runeKey,
    required this.lit,
    required this.echo,
    required this.enabled,
    required this.onTap,
  });

  final String runeKey;
  final bool lit;
  final bool echo;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: lit ? 1.13 : 1,
        duration: const Duration(milliseconds: 130),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            width: 82,
            height: 82,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 145),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Opacity(
                key: ValueKey('$runeKey-$lit-$echo'),
                opacity: echo && !lit ? .78 : 1,
                child: Image.asset(
                  'assets/images/ui/trials/rune_$runeKey${lit || echo ? '_lit' : ''}.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  semanticLabel: '$runeKey rune',
                ),
              ),
            ),
          ),
        ),
      );
}

String _focusLabel(AppStrings strings, TrainingFocus focus) => switch (focus) {
      TrainingFocus.might => strings.pick('Might', 'Kracht'),
      TrainingFocus.arcana => 'Arcana',
      TrainingFocus.spirit => strings.pick('Spirit', 'Geest'),
    };
