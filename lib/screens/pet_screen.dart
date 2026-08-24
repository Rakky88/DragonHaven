import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_egg.dart';
import '../models/dragon_dialogue.dart';
import '../models/game_presentation.dart';
import '../models/pet.dart';
import '../providers/household_provider.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/rooftop_egg_nest.dart';
import '../widgets/ui_bits.dart';

class PetScreen extends StatelessWidget {
  const PetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final pet = game.pet;
    return ListView(
      key: const PageStorageKey('dragon-scroll'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      children: [
        Text(
            pet.isEgg
                ? strings.pick('The tower nest', 'Het torennest')
                : pet.displayName,
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 5),
        Text(
          pet.isEgg
              ? strings.pick(
                  'A secret life is waiting inside one familiar shell.',
                  'In deze vertrouwde schaal wacht een geheim leven.')
              : '${strings.petStage(pet)} · ${strings.lineageName(pet.lineage)}${pet.spectral ? ' · ${strings.pick('Spectral', 'Spectral')}' : ''}',
          style: const TextStyle(color: AppColors.muted, fontSize: 15),
        ),
        const SizedBox(height: 18),
        _DragonStageCard(pet: pet),
        if (pet.isEgg) ...[
          const SizedBox(height: 10),
          EggHatchCountdown(
            pet: pet,
            onElapsed: game.hatchActiveDragon,
          ),
        ],
        if (!pet.isEgg) ...[
          const SizedBox(height: 18),
          _DragonNeedsPanel(pet: pet),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const Key('talk-to-dragon'),
            onPressed: () => _talk(context, pet),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: Text(strings.pick(
                'Talk to ${pet.displayName}', 'Praat met ${pet.displayName}')),
          ),
        ],
        const SizedBox(height: 18),
        if (pet.stage == DragonStage.wyrmling ||
            pet.stage == DragonStage.ascended) ...[
          _TrainingPanel(pet: pet),
          const SizedBox(height: 18),
        ],
        _EvolutionPanel(pet: pet),
        if (!pet.isEgg && pet.name.trim().isEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: () => _askForName(context),
              icon: const Icon(Icons.edit_rounded),
              label: Text(
                  strings.pick('Name your dragon', 'Geef je draak een naam'))),
        ],
        if (game.eggStash.isNotEmpty) ...[
          const SizedBox(height: 26),
          SectionHeading(
              title: strings.pick('Egg inventory', 'Eierinventaris')),
          const SizedBox(height: 11),
          _EggInventory(eggs: game.eggStash, nestOccupied: game.hasEggInNest),
        ],
      ],
    );
  }
}

class EggHatchCountdown extends StatefulWidget {
  const EggHatchCountdown({
    super.key,
    required this.pet,
    this.onElapsed,
  });

  final Pet pet;
  final FutureOr<void> Function()? onElapsed;

  @override
  State<EggHatchCountdown> createState() => _EggCountdownState();
}

class _EggCountdownState extends State<EggHatchCountdown>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _glowController;
  DateTime _now = DateTime.now();
  bool _elapsedNotified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _glowController.stop();
      _glowController.value = 0;
    } else if (!_glowController.isAnimating) {
      _glowController.repeat();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void didUpdateWidget(covariant EggHatchCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pet.id != widget.pet.id) _elapsedNotified = false;
  }

  void _refresh() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() => _now = now);
    if (_elapsedNotified ||
        widget.onElapsed == null ||
        !widget.pet.canHatch(now)) {
      return;
    }
    _elapsedNotified = true;
    final strings = AppStrings.of(context);
    unawaited(HavenNotifications.showEggReadyNow(
      id: 'egg-${widget.pet.id}',
      title: strings.pick(
          'Your Mysterious Egg is ready', 'Je Mysterieus Ei is klaar'),
      body: strings.pick(
        'Something inside wants to hatch in the Rooftop Nest.',
        'Iets binnenin wil uitkomen in het Daknest.',
      ),
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onElapsed?.call();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final hatchAt =
        widget.pet.stageStartedAt.add(widget.pet.incubationDuration);
    final remaining =
        hatchAt.isAfter(_now) ? hatchAt.difference(_now) : Duration.zero;
    final ready = remaining == Duration.zero;
    final countdown = _countdownParts(remaining);
    return Semantics(
      liveRegion: true,
      label: ready
          ? strings.pick('Ready to hatch', 'Klaar om uit te komen')
          : strings.pick('Hatches in ${_countdown(remaining)}',
              'Komt uit over ${_countdown(remaining)}'),
      child: Center(
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            final wave =
                (math.sin(_glowController.value * math.pi * 2) + 1) / 2;
            return Container(
              key: const Key('egg-hatch-countdown'),
              width: 330,
              height: 94,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: ready
                      ? const [Color(0xFF4A276A), Color(0xFF8E5E28)]
                      : const [Color(0xFF251A4D), Color(0xFF5B3E91)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (ready ? AppColors.gold : AppColors.twilight)
                        .withValues(alpha: .22 + wave * .14),
                    blurRadius: 18 + wave * 8,
                    spreadRadius: wave * 1.5,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: CustomPaint(
                  painter: _CountdownFramePainter(
                    progress: _glowController.value,
                    ready: ready,
                  ),
                  child: Center(child: child),
                ),
              ),
            );
          },
          child: Row(
            key: const Key('egg-hatch-countdown-value'),
            mainAxisSize: MainAxisSize.min,
            children: [
              _CountdownUnit(value: countdown.$1),
              const _CountdownColon(),
              _CountdownUnit(value: countdown.$2),
              const _CountdownColon(),
              _CountdownUnit(value: countdown.$3),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  const _CountdownUnit({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Container(
      width: 67,
      height: 57,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: Colors.white.withValues(alpha: .09),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 360),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, .22),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        ),
        child: ShaderMask(
          key: ValueKey(value),
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFFE39A)],
          ).createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 29,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownColon extends StatelessWidget {
  const _CountdownColon();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 22,
        child: Text(
          ':',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.goldLight,
            fontSize: 26,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class _CountdownFramePainter extends CustomPainter {
  const _CountdownFramePainter({required this.progress, required this.ready});

  final double progress;
  final bool ready;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final frame = RRect.fromRectAndRadius(
      rect.deflate(1.5),
      const Radius.circular(27),
    );
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = SweepGradient(
        transform: GradientRotation(progress * math.pi * 2),
        colors: ready
            ? const [Color(0x55F4C95D), Color(0xFFFFE39A), Color(0x55F4C95D)]
            : const [Color(0x337B61C9), Color(0xFFFFE39A), Color(0x337B61C9)],
      ).createShader(rect, textDirection: TextDirection.ltr);
    canvas.drawRRect(frame, borderPaint);

    final glowCenter = Offset(
      size.width * (.18 + .64 * ((math.sin(progress * math.pi * 2) + 1) / 2)),
      size.height * .12,
    );
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (ready ? AppColors.gold : const Color(0xFFBCA8FF))
              .withValues(alpha: .22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: 86));
    canvas.drawRect(rect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _CountdownFramePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.ready != ready;
}

(String, String, String) _countdownParts(Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(0, 14 * 24 * 60 * 60).toInt();
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  String two(int value) => value.toString().padLeft(2, '0');
  return (two(hours), two(minutes), two(seconds));
}

String _countdown(Duration duration) {
  final parts = _countdownParts(duration);
  return '${parts.$1}:${parts.$2}:${parts.$3}';
}

Future<void> _talk(BuildContext context, Pet pet) async {
  final strings = AppStrings.of(context);
  final line = dialogueFor(pet, DateTime.now());
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.twilight),
      title: Text(pet.displayName, textAlign: TextAlign.center),
      content: Text(line.text(strings.languageCode),
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 17, height: 1.45, fontWeight: FontWeight.w700)),
      actions: [
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
                strings.pick('That was insightful', 'Dat was verhelderend')))
      ],
    ),
  );
}

class _DragonStageCard extends StatelessWidget {
  const _DragonStageCard({required this.pet});
  final Pet pet;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Semantics(
      button: pet.isEgg,
      label: pet.isEgg
          ? strings.pick(
              'Listen to the mysterious egg', 'Luister naar het mysterieuze ei')
          : pet.displayName,
      child: GestureDetector(
        key: pet.isEgg ? const Key('mysterious-egg-hint') : null,
        behavior: HitTestBehavior.opaque,
        onTap: pet.isEgg
            ? () {
                HavenAudio.play(HavenSound.uiConfirm);
                final game = context.read<HouseholdProvider>();
                showAppSnackBar(
                  context,
                  game.eggHint(locale: strings.languageCode),
                );
              }
            : null,
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: pet.isEgg
                ? null
                : const RadialGradient(
                    center: Alignment(.1, -.2),
                    radius: 1.2,
                    colors: [Color(0xFF75629E), Color(0xFF352B63)]),
          ),
          child: Stack(
            children: [
              if (pet.isEgg)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: const RooftopEggNest(),
                  ),
                ),
              if (!pet.isEgg)
                const Positioned(
                    left: 25,
                    top: 25,
                    child: Icon(Icons.star_rounded,
                        color: AppColors.gold, size: 18)),
              if (!pet.isEgg)
                const Positioned(
                    right: 42,
                    top: 50,
                    child: Icon(Icons.auto_awesome_rounded,
                        color: Colors.white54, size: 14)),
              if (!pet.isEgg)
                Align(
                  alignment: Alignment.center,
                  child: SizedBox.square(
                    dimension: 280,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox.square(
                        dimension: 248 * pet.sizeFactor,
                        child: DragonArt(
                          height: 248 * pet.sizeFactor,
                          stageKey: pet.stageKey,
                          lineageId: pet.lineageId,
                          evolutionPath: pet.activeEvolutionPath,
                          prismatic: pet.spectral,
                          sinister: pet.sinister,
                        ),
                      ),
                    ),
                  ),
                ),
              if (!pet.isEgg)
                Positioned(
                    left: 16,
                    bottom: 15,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .9),
                            borderRadius: BorderRadius.circular(99)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(strings.petStage(pet),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.twilightDark)),
                        ]))),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragonNeedsPanel extends StatelessWidget {
  const _DragonNeedsPanel({required this.pet});
  final Pet pet;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(strings.pick('Wellbeing', 'Welzijn'),
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 13),
          _NeedBar(
              icon: Icons.sentiment_very_satisfied_rounded,
              label: strings.pick('Joy', 'Plezier'),
              value: pet.joy,
              color: AppColors.coral),
          _NeedBar(
              icon: Icons.bolt_rounded,
              label: strings.pick('Energy', 'Energie'),
              value: pet.energy,
              color: AppColors.gold),
          _NeedBar(
              icon: Icons.shield_moon_rounded,
              label: strings.pick('Comfort', 'Comfort'),
              value: pet.comfort,
              color: AppColors.mint),
          const SizedBox(height: 4),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                  onPressed: pet.gems < 3 ? null : () => _buyTreat(context),
                  icon: const GameIconSprite(GameIconKind.gem, size: 25),
                  label: Text(strings.pick(
                      'Starlight Treat · 3 gems', 'Sterlichtsnack · 3 gems')))),
        ]),
      ),
    );
  }

  Future<void> _buyTreat(BuildContext context) async {
    final ok = await context.read<HouseholdProvider>().buyStarlightTreat();
    if (context.mounted && ok) {
      showAppSnackBar(
          context,
          AppStrings.of(context).pick('A soft glow fills every wellbeing bar.',
              'Een zachte gloed vult elke welzijnsbalk.'));
    }
  }
}

class _TrainingPanel extends StatelessWidget {
  const _TrainingPanel({required this.pet});
  final Pet pet;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(strings.pick('Ascension paths', 'Ascension-paden'),
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 5),
          Text(
              strings.pick(
                  'The highest trained path fixes the final form. Activities in Explore raise these values.',
                  'Het hoogst getrainde pad legt de eindvorm vast. Activiteiten in Verkennen verhogen deze waarden.'),
              style: const TextStyle(color: AppColors.muted, height: 1.35)),
          const SizedBox(height: 14),
          for (final focus in TrainingFocus.values)
            _TrainingBar(
                focus: focus,
                value: pet.trainingFor(focus),
                leading: pet.leadingPath == focus.name),
        ]),
      ),
    );
  }
}

class _TrainingBar extends StatelessWidget {
  const _TrainingBar(
      {required this.focus, required this.value, required this.leading});
  final TrainingFocus focus;
  final int value;
  final bool leading;
  @override
  Widget build(BuildContext context) {
    final color = switch (focus) {
      TrainingFocus.might => const Color(0xFFD96852),
      TrainingFocus.arcana => const Color(0xFF7A63D1),
      TrainingFocus.spirit => const Color(0xFF3FA37C)
    };
    final name = focus.name[0].toUpperCase() + focus.name.substring(1);
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(children: [
          Row(children: [
            GameIconSprite(GameIconSprite.forTrainingFocus(focus), size: 28),
            const SizedBox(width: 7),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
            if (leading) ...[
              const SizedBox(width: 6),
              const Icon(Icons.arrow_upward_rounded,
                  size: 14, color: AppColors.gold)
            ],
            const Spacer(),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.w900))
          ]),
          const SizedBox(height: 6),
          LinearProgressIndicator(
              value: (value / 300).clamp(0, 1),
              minHeight: 8,
              color: color,
              backgroundColor: AppColors.mist,
              borderRadius: BorderRadius.circular(99))
        ]));
  }
}

class _EvolutionPanel extends StatelessWidget {
  const _EvolutionPanel({required this.pet});
  final Pet pet;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final now = DateTime.now();
    final ready = pet.isEgg && pet.canHatch(now);
    if (pet.isEgg) {
      if (!ready) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _hatch(context),
            icon: const Icon(Icons.egg_alt_rounded),
            label: Text(strings.pick('Begin hatching', 'Laat het ei uitkomen')),
          ),
        ),
      );
    }
    final target = switch (pet.stage) {
      DragonStage.egg => 1,
      DragonStage.hatchling => Pet.wyrmlingXp,
      DragonStage.wyrmling => Pet.ascendedXp,
      DragonStage.ascended => Pet.ascendedXp
    };
    final next = switch (pet.stage) {
      DragonStage.egg => strings.petStageNameByKey('spark'),
      DragonStage.hatchling => strings.petStageNameByKey('nestDragon'),
      DragonStage.wyrmling => strings.petStageNameByKey('homeGuardian'),
      DragonStage.ascended => strings.petStageNameByKey('homeGuardian')
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.twilight),
            const SizedBox(width: 9),
            Expanded(
                child: Text(
                    pet.stage == DragonStage.ascended
                        ? strings.pick(
                            'Ascension complete', 'Ascension voltooid')
                        : strings.pick(
                            'Next form: $next', 'Volgende vorm: $next'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 17)))
          ]),
          const SizedBox(height: 11),
          LinearProgressIndicator(
              value: (pet.xp / target).clamp(0, 1),
              minHeight: 9,
              borderRadius: BorderRadius.circular(99),
              backgroundColor: AppColors.mist),
          const SizedBox(height: 8),
          Text('${pet.xp}/$target XP',
              style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          if (pet.stage == DragonStage.wyrmling)
            Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                    '${strings.pick('Expertises', 'Expertises')}: ${pet.totalTraining}/${maxDragonExpertise * TrainingFocus.values.length} · ${pet.leadingPath == 'unknown' ? strings.pick('path undecided', 'pad onbeslist') : pet.leadingPath}',
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12))),
        ]),
      ),
    );
  }

  Future<void> _hatch(BuildContext context) async {
    final game = context.read<HouseholdProvider>();
    await game.hatchActiveDragon();
  }
}

Future<void> showHatchMilestonePresentation(
  BuildContext context,
  HouseholdProvider game,
  GamePresentation presentation,
) async {
  final dragon = game.dragonById(presentation.dragonId);
  if (dragon == null || dragon.isEgg) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ChangeNotifierProvider.value(
      value: game,
      child: _HatchDialog(dragonId: dragon.id),
    ),
  );
}

Future<void> showEvolutionMilestonePresentation(
  BuildContext context,
  HouseholdProvider game,
  GamePresentation presentation,
) async {
  final dragon = game.dragonById(presentation.dragonId);
  if (dragon == null || dragon.isEgg) return;
  final wasHatchling = presentation.previousStageKey == 'spark';
  final previousStageKey =
      presentation.previousStageKey ?? (wasHatchling ? 'spark' : 'nestDragon');
  final previousArtwork = DragonArtwork.forStage(
    stageKey: previousStageKey,
    lineageId: dragon.lineageId,
    evolutionPath: dragon.activeEvolutionPath,
  );
  final evolvedArtwork = DragonArtwork.forStage(
    stageKey: dragon.stageKey,
    lineageId: dragon.lineageId,
    evolutionPath: dragon.activeEvolutionPath,
  );
  unawaited(Future.wait([
    precacheImage(
      const AssetImage('assets/images/evolution_reveal_background.webp'),
      context,
    ),
    precacheImage(
      const AssetImage(GameVfxAssets.evolutionRuneRing),
      context,
    ),
    precacheImage(
      const AssetImage(GameVfxAssets.evolutionEnergySpiral),
      context,
    ),
    precacheImage(
      const AssetImage(GameVfxAssets.evolutionRevealBurst),
      context,
    ),
    precacheImage(
      const AssetImage(GameVfxAssets.evolutionFrameAtlas),
      context,
    ),
    precacheImage(AssetImage(previousArtwork.asset), context),
    precacheImage(AssetImage(evolvedArtwork.asset), context),
  ]));
  unawaited(HavenAudio.setMusicScene(HavenMusicScene.reveal));
  unawaited(HavenAudio.play(
      wasHatchling ? HavenSound.evolutionYoung : HavenSound.evolutionAscended));
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _EvolutionDialog(
      pet: dragon,
      previousStageKey: previousStageKey,
    ),
  );
}

class _EvolutionDialog extends StatefulWidget {
  const _EvolutionDialog({required this.pet, required this.previousStageKey});
  final Pet pet;
  final String previousStageKey;

  @override
  State<_EvolutionDialog> createState() => _EvolutionDialogState();
}

class _EvolutionDialogState extends State<_EvolutionDialog>
    with TickerProviderStateMixin {
  int _phase = 0;
  Timer? _convergenceTimer;
  Timer? _flashTimer;
  Timer? _revealTimer;
  late final AnimationController _magic = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 10400),
  )..repeat();
  late final AnimationController _frames = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _convergenceTimer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() => _phase = 1);
    });
    _flashTimer = Timer(const Duration(milliseconds: 6500), () {
      if (mounted) setState(() => _phase = 2);
    });
    _revealTimer = Timer(const Duration(milliseconds: 7800), () {
      if (mounted) setState(() => _phase = 3);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _magic
        ..stop()
        ..value = 1;
      _frames
        ..stop()
        ..value = 0;
    } else {
      if (!_magic.isAnimating) _magic.repeat();
      if (!_frames.isAnimating) _frames.repeat();
    }
  }

  void _skipToReveal() {
    if (_phase >= 3) return;
    _convergenceTimer?.cancel();
    _flashTimer?.cancel();
    _revealTimer?.cancel();
    setState(() => _phase = 3);
  }

  @override
  void dispose() {
    _convergenceTimer?.cancel();
    _flashTimer?.cancel();
    _revealTimer?.cancel();
    _magic.dispose();
    _frames.dispose();
    HavenAudio.setMusicScene(
      DateTime.now().hour >= 21 || DateTime.now().hour < 7
          ? HavenMusicScene.towerNight
          : HavenMusicScene.towerDay,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final pet = widget.pet;
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF1D183B),
      child: GestureDetector(
        key: const Key('close-evolution-presentation'),
        behavior: HitTestBehavior.opaque,
        onTap: _phase >= 3 ? () => Navigator.pop(context) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 900),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                'assets/images/evolution_reveal_background.webp',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: Align(
                    alignment: const Alignment(0, -.08),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_magic, _frames]),
                      builder: (_, __) {
                        final pulse =
                            (1 - math.cos(_magic.value * math.pi * 4)) / 2;
                        final frameIndex =
                            math.min(19, (_frames.value * 20).floor());
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            RepaintBoundary(
                              key: const Key('evolution-frame-sequence'),
                              child: Opacity(
                                opacity: _phase >= 3
                                    ? .58
                                    : _phase == 1
                                        ? 1
                                        : .90,
                                child: Transform.scale(
                                  scale: _phase == 1
                                      ? .96 + pulse * .055
                                      : .94 + pulse * .025,
                                  child: _EvolutionFrameAtlas(
                                    frameIndex: frameIndex,
                                    size: 430,
                                  ),
                                ),
                              ),
                            ),
                            if (_phase == 1)
                              Transform.scale(
                                scale: .58 + pulse * .34,
                                child: Opacity(
                                  opacity: .20 + pulse * .52,
                                  child: const Image(
                                    key: Key('evolution-reveal-burst'),
                                    image: AssetImage(
                                      GameVfxAssets.evolutionRevealBurst,
                                    ),
                                    width: 390,
                                    height: 390,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _magic,
                    builder: (_, child) {
                      final pulse =
                          (1 - math.cos(_magic.value * math.pi * 4)) / 2;
                      return Transform.translate(
                        offset: Offset(
                          0,
                          math.sin(_magic.value * math.pi * 4) * 4,
                        ),
                        child: Transform.scale(
                          scale: _phase >= 3
                              ? 1.08
                              : _phase == 1
                                  ? .96 + pulse * .09
                                  : .91 + pulse * .045,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFB992FF).withValues(
                                    alpha:
                                        _phase >= 3 ? .42 : .18 + pulse * .31,
                                  ),
                                  blurRadius: 42 + pulse * 34,
                                  spreadRadius: 8 + pulse * 13,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: SizedBox(
                      key: const Key('centered-evolution-dragon'),
                      height: 300,
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(_phase >= 3
                            ? 'evolved-dragon-entrance'
                            : 'previous-dragon-entrance'),
                        tween: Tween(begin: .72, end: 1),
                        duration: const Duration(milliseconds: 1450),
                        curve: Curves.easeOutBack,
                        builder: (_, entrance, child) => Opacity(
                          opacity: entrance.clamp(0, 1),
                          child: Transform.scale(scale: entrance, child: child),
                        ),
                        child: DragonArt(
                          height: 300,
                          stageKey: _phase >= 3
                              ? pet.stageKey
                              : widget.previousStageKey,
                          lineageId: pet.lineageId,
                          evolutionPath: pet.activeEvolutionPath,
                          prismatic: pet.spectral,
                          sinister: pet.sinister,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_phase >= 3) ...[
                    Text(
                      strings.pick('A new form awakens!',
                          'Een nieuwe vorm is ontwaakt!'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pet.stage == DragonStage.ascended
                          ? strings.lineageFormName(
                              pet.lineage, pet.activeEvolutionPath)
                          : strings.petStageNameByKey('nestDragon'),
                      style: const TextStyle(
                        color: Color(0xFFFFD878),
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                  const Spacer(),
                  const SizedBox(height: 22),
                ]),
                IgnorePointer(
                  child: AnimatedOpacity(
                    key: const Key('evolution-white-flash'),
                    opacity: _phase == 2 ? 1 : 0,
                    duration: const Duration(milliseconds: 900),
                    curve:
                        _phase == 2 ? Curves.easeInExpo : Curves.easeOutCubic,
                    child: const ColoredBox(color: Colors.white),
                  ),
                ),
                if (_phase < 3)
                  Align(
                    alignment: const Alignment(0, .4),
                    child: Semantics(
                      button: true,
                      label: strings.pick(
                        'Skip evolution animation',
                        'Evolutieanimatie overslaan',
                      ),
                      child: GestureDetector(
                        key: const Key('skip-evolution-animation'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _skipToReveal,
                        child: const SizedBox(width: 180, height: 110),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EvolutionFrameAtlas extends StatelessWidget {
  const _EvolutionFrameAtlas({
    required this.frameIndex,
    required this.size,
  });

  final int frameIndex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final column = frameIndex % 5;
    final row = frameIndex ~/ 5;
    return SizedBox.square(
      key: const Key('evolution-frame-atlas'),
      dimension: size,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: size * 5,
          maxWidth: size * 5,
          minHeight: size * 4,
          maxHeight: size * 4,
          child: Transform.translate(
            offset: Offset(-column * size, -row * size),
            child: Image.asset(
              GameVfxAssets.evolutionFrameAtlas,
              width: size * 5,
              height: size * 4,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _HatchDialog extends StatefulWidget {
  const _HatchDialog({required this.dragonId});

  final String dragonId;
  @override
  State<_HatchDialog> createState() => _HatchDialogState();
}

class _HatchDialogState extends State<_HatchDialog> {
  var phase = 0;
  var _crackingStarted = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    HavenAudio.setMusicScene(HavenMusicScene.reveal);
    HavenAudio.play(HavenSound.hatchBuild);
  }

  void _beginCracking() {
    if (_crackingStarted || !mounted) return;
    _crackingStarted = true;
    setState(() => phase = 1);
    HavenAudio.play(HavenSound.hatchCrackOne);
    _scheduleNextPhase();
  }

  Duration get _delayUntilNextPhase => switch (phase) {
        1 => const Duration(milliseconds: 900),
        2 => const Duration(milliseconds: 1050),
        3 => const Duration(milliseconds: 1150),
        4 => const Duration(milliseconds: 440),
        5 => const Duration(milliseconds: 1500),
        _ => Duration.zero,
      };

  void _scheduleNextPhase() {
    if (!mounted || phase >= 6) return;
    timer = Timer(_delayUntilNextPhase, () {
      if (!mounted) return;
      setState(() => phase++);
      switch (phase) {
        case 2:
          HavenAudio.play(HavenSound.hatchCrackTwo);
        case 3:
          HavenAudio.play(HavenSound.hatchCrackThree);
        case 5:
          HavenAudio.play(HavenSound.hatchReveal);
          final game = context.read<HouseholdProvider>();
          final pet = game.dragonById(widget.dragonId) ?? game.pet;
          if (pet.spectral) HavenAudio.play(HavenSound.spectralReveal);
        default:
          break;
      }
      _scheduleNextPhase();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    final hour = DateTime.now().hour;
    HavenAudio.setMusicScene(hour >= 21 || hour < 7
        ? HavenMusicScene.towerNight
        : HavenMusicScene.towerDay);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<HouseholdProvider>();
    final pet = game.dragonById(widget.dragonId) ?? game.pet;
    final strings = AppStrings.of(context);
    final reveal = phase >= 5;
    return Dialog.fullscreen(
      backgroundColor: phase == 4 ? Colors.white : const Color(0xFF30265E),
      child: SafeArea(
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              decoration: BoxDecoration(
                  image: phase == 4
                      ? null
                      : const DecorationImage(
                          image: AssetImage(
                              'assets/images/hatch_reveal_background.webp'),
                          fit: BoxFit.cover,
                        )),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        child: reveal
                            ? DragonArt(
                                key: const Key('hatchling-reveal'),
                                height: 270,
                                stageKey: pet.stageKey,
                                lineageId: pet.lineageId,
                                prismatic: pet.spectral,
                                sinister: pet.sinister)
                            : phase == 4
                                ? const SizedBox.square(
                                    key: Key('hatch-flash'), dimension: 270)
                                : Semantics(
                                    button: phase == 0,
                                    label: phase == 0
                                        ? strings.pick(
                                            'Tap the egg once to begin hatching',
                                            'Tik één keer op het ei om het uitkomen te starten')
                                        : null,
                                    child: GestureDetector(
                                      key: const Key('hatch-egg-tap'),
                                      behavior: HitTestBehavior.opaque,
                                      onTap: phase == 0 ? _beginCracking : null,
                                      child: AnimatedScale(
                                          duration:
                                              const Duration(milliseconds: 220),
                                          scale: 1 + phase * .025,
                                          child: Stack(
                                              key: const Key('cracking-egg'),
                                              alignment: Alignment.center,
                                              children: [
                                                DragonArt(
                                                    height: 260,
                                                    stageKey: 'moonEgg',
                                                    animate: phase == 0),
                                                if (phase >= 1)
                                                  SizedBox(
                                                      width: 170,
                                                      height: 190,
                                                      child: ClipPath(
                                                        clipper:
                                                            _CrackStageClipper(
                                                                phase),
                                                        child: Opacity(
                                                          opacity: switch (
                                                              phase) {
                                                            1 => .68,
                                                            2 => .84,
                                                            _ => 1,
                                                          },
                                                          child: Image.asset(
                                                            'assets/images/relics/egg_crack_magic.png',
                                                            key: const Key(
                                                                'egg-crack-sprite'),
                                                            fit: BoxFit.contain,
                                                            filterQuality:
                                                                FilterQuality
                                                                    .high,
                                                          ),
                                                        ),
                                                      ))
                                              ])),
                                    ),
                                  )),
                    const SizedBox(height: 20),
                    if (phase == 5 && pet.spectral)
                      Text(
                          strings.pick('✦ SOMETHING IS DIFFERENT...',
                              '✦ ER IS IETS ANDERS...'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 22)),
                    if (phase >= 5 && !pet.spectral)
                      Text(
                          strings.pick('A ${pet.lineage.nameEn} has hatched!',
                              'Er is een ${pet.lineage.nameNl} uitgekomen!'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 22)),
                    if (phase >= 6)
                      Padding(
                          padding: const EdgeInsets.only(top: 22),
                          child: _HatchNameButton(
                              onPressed: () async {
                                await _askForName(
                                  context,
                                  dragonId: widget.dragonId,
                                  closeAfter: true,
                                );
                              },
                              label: strings.pick(
                                  'Choose a name', 'Kies een naam'))),
                  ]))),
    );
  }
}

class _HatchNameButton extends StatelessWidget {
  const _HatchNameButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF7557B8), Color(0xFF49307F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFFFFD66B), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66402775),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: Color(0x55FFE08A),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('choose-dragon-name'),
                onTap: onPressed,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GameIconSprite(GameIconKind.nameDragon, size: 54),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .2,
                          ),
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

class _CrackStageClipper extends CustomClipper<Path> {
  const _CrackStageClipper(this.stage);

  final int stage;

  @override
  Path getClip(Size size) => Path()
    ..addRect(Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height *
          switch (stage) {
            1 => .42,
            2 => .72,
            _ => 1,
          },
    ));

  @override
  bool shouldReclip(covariant _CrackStageClipper oldClipper) =>
      oldClipper.stage != stage;
}

class _EggInventory extends StatelessWidget {
  const _EggInventory({required this.eggs, required this.nestOccupied});
  final List<DragonEgg> eggs;
  final bool nestOccupied;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (eggs.isEmpty) {
      return Card(
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                const Icon(Icons.inventory_2_outlined, color: AppColors.muted),
                const SizedBox(width: 11),
                Expanded(
                    child: Text(
                        strings.pick(
                            'No waiting eggs. Rare chest drops will appear here.',
                            'Geen wachtende eieren. Zeldzame vondsten uit kisten verschijnen hier.'),
                        style: const TextStyle(color: AppColors.muted)))
              ])));
    }
    return Column(children: [
      for (final egg in eggs)
        Card(
            child: ListTile(
                leading: const Text('🥚', style: TextStyle(fontSize: 34)),
                title: Text(strings.pick('Mysterious Egg', 'Mysterieus Ei'),
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(strings.pick(
                    'Acquired ${_date(egg.acquiredAt)} · identity fixed',
                    'Verkregen ${_date(egg.acquiredAt)} · identiteit ligt vast')),
                trailing: FilledButton.tonal(
                    onPressed:
                        nestOccupied ? null : () => _activate(context, egg),
                    child: Text(strings.pick('Raise', 'Activeren')))))
    ]);
  }

  Future<void> _activate(BuildContext context, DragonEgg egg) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                scrollable: true,
                title: Text(
                    strings.pick('Raise this egg?', 'Dit ei grootbrengen?')),
                content: Text(strings.pick(
                    'The egg moves to the Rooftop Nest. Your active dragon and the rest of the app stay available.',
                    'Het ei verhuist naar het Daknest. Je actieve draak en de rest van de app blijven beschikbaar.')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(strings.pick('Cancel', 'Annuleren'))),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(strings.pick('Activate egg', 'Ei activeren')))
                ]));
    if (confirmed == true && context.mounted) {
      await context.read<HouseholdProvider>().activateEgg(egg.id);
    }
  }
}

class _NeedBar extends StatelessWidget {
  const _NeedBar(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 8),
        SizedBox(
            width: 64,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w800))),
        Expanded(
            child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 8,
                color: color,
                backgroundColor: AppColors.mist,
                borderRadius: BorderRadius.circular(99))),
        const SizedBox(width: 8),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w900))
      ]));
}

Future<void> _askForName(
  BuildContext context, {
  String? dragonId,
  bool closeAfter = false,
}) async {
  final controller = TextEditingController();
  final strings = AppStrings.of(context);
  final name = await showDialog<String>(
      context: context,
      barrierDismissible: !closeAfter,
      builder: (dialogContext) => AlertDialog(
              scrollable: true,
              title: Text(
                  strings.pick('Name your dragon', 'Geef je draak een naam')),
              content: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 24,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                      labelText: strings.pick('Dragon name', 'Drakennaam'),
                      hintText: strings.pick(
                          'For example: Ember', 'Bijvoorbeeld: Ember')),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.pop(dialogContext, value.trim());
                    }
                  }),
              actions: [
                FilledButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        Navigator.pop(dialogContext, controller.text.trim());
                      }
                    },
                    child: Text(strings.pick('Keep this name', 'Naam bewaren')))
              ]));
  await WidgetsBinding.instance.endOfFrame;
  controller.dispose();
  if (name == null || !context.mounted) return;
  final game = context.read<HouseholdProvider>();
  await game.nameDragon(dragonId ?? game.pet.id, name);
  if (closeAfter && context.mounted) {
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return;
    Navigator.pop(context);
  }
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
