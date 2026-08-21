import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/day_phase.dart';
import '../models/dragon_egg.dart';
import '../models/dragon_dialogue.dart';
import '../models/pet.dart';
import '../providers/household_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';
import '../widgets/haven_lighting.dart';
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
              : '${strings.petStage(pet)} · ${pet.lineage.name(strings.isDutch)}${pet.spectral ? ' · Spectral' : ''}',
          style: const TextStyle(color: AppColors.muted, fontSize: 15),
        ),
        const SizedBox(height: 18),
        _DragonStageCard(pet: pet),
        if (!pet.isEgg) ...[
          const SizedBox(height: 18),
          _DragonNeedsPanel(pet: pet),
        ],
        const SizedBox(height: 18),
        _CarePanel(pet: pet),
        if (!pet.isEgg) ...[
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
          SectionHeading(title: strings.pick('Egg stash', 'Eiervoorraad')),
          const SizedBox(height: 11),
          _EggStash(eggs: game.eggStash, activeIsEgg: pet.isEgg),
        ],
      ],
    );
  }
}

Future<void> _talk(BuildContext context, Pet pet) async {
  final strings = AppStrings.of(context);
  final line = dialogueFor(pet, DateTime.now());
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.twilight),
      title: Text(pet.displayName, textAlign: TextAlign.center),
      content: Text(line.text(strings.isDutch),
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
    return Container(
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
                child: HavenPhaseImage(
                  assetFor: (phase) =>
                      'assets/images/tower_nest_${phase.assetKey}.webp',
                ),
              ),
            ),
          const Positioned(
              left: 25,
              top: 25,
              child: Icon(Icons.star_rounded, color: AppColors.gold, size: 18)),
          const Positioned(
              right: 42,
              top: 50,
              child: Icon(Icons.auto_awesome_rounded,
                  color: Colors.white54, size: 14)),
          Align(
              alignment:
                  pet.isEgg ? const Alignment(.02, .43) : Alignment.center,
              child: Transform.scale(
                  scale: pet.isEgg ? 1 : pet.sizeFactor,
                  child: DragonArt(
                      height: 248,
                      stageKey: pet.stageKey,
                      lineageId: pet.lineageId,
                      evolutionPath: pet.activeEvolutionPath,
                      prismatic: pet.spectral,
                      sinister: pet.sinister))),
          Positioned(
              left: 16,
              bottom: 15,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(99)),
                  child: Text(
                      pet.isEgg
                          ? '🥚 Mysterious Egg'
                          : pet.stage.name[0].toUpperCase() +
                              pet.stage.name.substring(1),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.twilightDark)))),
        ],
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
                  icon: const Icon(Icons.diamond_rounded),
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

class _CarePanel extends StatelessWidget {
  const _CarePanel({required this.pet});
  final Pet pet;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final now = DateTime.now();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!pet.isEgg) ...[
            Text(strings.pick('Spend time together', 'Breng tijd samen door'),
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 5),
            Text(
                strings.pick('Each action rests for four hours after use.',
                    'Elke actie rust vier uur na gebruik.'),
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 12),
          ],
          Row(children: [
            for (final action in DragonCareAction.values) ...[
              Expanded(
                  child: _CareButton(
                      action: action,
                      enabled: pet.canCare(action, now),
                      remaining: pet.careRemaining(action, now))),
              if (action != DragonCareAction.values.last)
                const SizedBox(width: 8),
            ],
          ]),
        ]),
      ),
    );
  }
}

class _CareButton extends StatelessWidget {
  const _CareButton(
      {required this.action, required this.enabled, required this.remaining});
  final DragonCareAction action;
  final bool enabled;
  final Duration remaining;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final (icon, en, nl) = switch (action) {
      DragonCareAction.play => (Icons.toys_rounded, 'Play', 'Spelen'),
      DragonCareAction.rest => (Icons.bedtime_rounded, 'Rest', 'Rusten'),
      DragonCareAction.care => (Icons.favorite_rounded, 'Care', 'Zorgen'),
    };
    return OutlinedButton(
      onPressed: enabled ? () => _care(context) : null,
      style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(strings.pick(en, nl), maxLines: 1),
        if (!enabled)
          Text('${remaining.inHours + 1}h', style: const TextStyle(fontSize: 9))
      ]),
    );
  }

  Future<void> _care(BuildContext context) async {
    final ok = await context.read<HouseholdProvider>().careForPet(action);
    if (!context.mounted) return;
    showAppSnackBar(
        context,
        ok
            ? AppStrings.of(context).pick('A gentle moment, safely saved.',
                'Een zacht moment, veilig opgeslagen.')
            : AppStrings.of(context).pick(
                'This care action needs a little more rest.',
                'Deze verzorgingsactie moet nog even rusten.'));
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
    final icon = switch (focus) {
      TrainingFocus.might => Icons.fitness_center_rounded,
      TrainingFocus.arcana => Icons.auto_awesome_rounded,
      TrainingFocus.spirit => Icons.favorite_rounded
    };
    final name = focus.name[0].toUpperCase() + focus.name.substring(1);
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(children: [
          Row(children: [
            Icon(icon, size: 18, color: color),
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
    final ready = pet.isEgg ? pet.canHatch(now) : pet.canEvolve(now);
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
    final remaining = pet.remainingForNextStage(now);
    final target = switch (pet.stage) {
      DragonStage.egg => 1,
      DragonStage.hatchling => Pet.wyrmlingXp,
      DragonStage.wyrmling => Pet.ascendedXp,
      DragonStage.ascended => Pet.ascendedXp
    };
    final next = switch (pet.stage) {
      DragonStage.egg => 'Hatchling',
      DragonStage.hatchling => 'Wyrmling',
      DragonStage.wyrmling => 'Ascended',
      DragonStage.ascended => 'Ascended'
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
          Text(
              '${pet.xp}/$target XP · ${remaining == Duration.zero ? strings.pick('minimum time complete', 'minimumtijd voltooid') : strings.pick('${_time(remaining)} remaining', 'nog ${_time(remaining)}')}',
              style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          if (pet.stage == DragonStage.wyrmling)
            Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                    '${pet.totalTraining}/300 training · ${pet.leadingPath == 'unknown' ? strings.pick('path undecided', 'pad onbeslist') : pet.leadingPath}',
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12))),
          if (pet.stage != DragonStage.ascended) ...[
            const SizedBox(height: 13),
            SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                    onPressed: ready ? () => _evolve(context) : null,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(ready
                        ? strings.pick('Evolve now', 'Evolueer nu')
                        : strings.pick('Not ready yet', 'Nog niet klaar'))))
          ],
        ]),
      ),
    );
  }

  Future<void> _hatch(BuildContext context) async {
    final game = context.read<HouseholdProvider>();
    if (!await game.hatchActiveDragon() || !context.mounted) return;
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ChangeNotifierProvider.value(
            value: game, child: const _HatchDialog()));
  }

  Future<void> _evolve(BuildContext context) async {
    final game = context.read<HouseholdProvider>();
    final wasHatchling = game.pet.stage == DragonStage.hatchling;
    if (!await game.evolveActiveDragon() || !context.mounted) return;
    await HavenAudio.setMusicScene(HavenMusicScene.reveal);
    await HavenAudio.play(wasHatchling
        ? HavenSound.evolutionYoung
        : HavenSound.evolutionAscended);
    if (!context.mounted) return;
    final pet = game.pet;
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _EvolutionDialog(
              pet: pet,
              previousStageKey: wasHatchling ? 'spark' : 'nestDragon',
            ));
  }
}

class _EvolutionDialog extends StatefulWidget {
  const _EvolutionDialog({required this.pet, required this.previousStageKey});
  final Pet pet;
  final String previousStageKey;

  @override
  State<_EvolutionDialog> createState() => _EvolutionDialogState();
}

class _EvolutionDialogState extends State<_EvolutionDialog> {
  int _phase = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1050), () async {
      if (!mounted) return;
      setState(() => _phase = 1);
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (mounted) setState(() => _phase = 2);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      backgroundColor: _phase == 1 ? Colors.white : const Color(0xFF1D183B),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          image: _phase == 1
              ? null
              : const DecorationImage(
                  image: AssetImage(
                      'assets/images/evolution_reveal_background.webp'),
                  fit: BoxFit.cover,
                ),
        ),
        child: SafeArea(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Spacer(),
            if (_phase != 1)
              AnimatedScale(
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutBack,
                scale: _phase >= 2 ? 1.08 : .92,
                child: DragonArt(
                  height: 285,
                  stageKey:
                      _phase >= 2 ? pet.stageKey : widget.previousStageKey,
                  lineageId: pet.lineageId,
                  evolutionPath: pet.activeEvolutionPath,
                  prismatic: pet.spectral,
                  sinister: pet.sinister,
                ),
              ),
            const SizedBox(height: 22),
            if (_phase == 0)
              Text(
                  strings.pick(
                      'A new form is awakening…', 'Een nieuwe vorm ontwaakt…'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900)),
            if (_phase >= 2) ...[
              Text(
                  strings.pick(
                      'A new form awakens!', 'Een nieuwe vorm is ontwaakt!'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                pet.stage == DragonStage.ascended
                    ? pet.lineage
                        .formName(pet.activeEvolutionPath, strings.isDutch)
                    : 'Wyrmling',
                style: const TextStyle(
                    color: Color(0xFFFFD878),
                    fontSize: 19,
                    fontWeight: FontWeight.w900),
              ),
            ],
            const Spacer(),
            if (_phase >= 2)
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(strings.pick('Welcome', 'Welkom')),
              ),
            const SizedBox(height: 22),
          ]),
        ),
      ),
    );
  }
}

class _HatchDialog extends StatefulWidget {
  const _HatchDialog();
  @override
  State<_HatchDialog> createState() => _HatchDialogState();
}

class _HatchDialogState extends State<_HatchDialog> {
  var phase = 0;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    HavenAudio.setMusicScene(HavenMusicScene.reveal);
    HavenAudio.play(HavenSound.hatchBuild);
    timer = Timer.periodic(const Duration(milliseconds: 620), (timer) {
      if (!mounted) return;
      if (phase >= 6) {
        timer.cancel();
        return;
      }
      setState(() => phase++);
      switch (phase) {
        case 1:
          HavenAudio.play(HavenSound.hatchCrackOne);
        case 2:
          HavenAudio.play(HavenSound.hatchCrackTwo);
        case 3:
          HavenAudio.play(HavenSound.hatchCrackThree);
        case 5:
          HavenAudio.play(HavenSound.hatchReveal);
          final pet = context.read<HouseholdProvider>().pet;
          if (pet.spectral) HavenAudio.play(HavenSound.spectralReveal);
        default:
          break;
      }
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
    final pet = context.watch<HouseholdProvider>().pet;
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
                                : AnimatedScale(
                                    duration: const Duration(milliseconds: 220),
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
                                                child: CustomPaint(
                                                    painter:
                                                        _CrackPainter(phase)))
                                        ]))),
                    const SizedBox(height: 20),
                    if (phase == 0)
                      Text(
                          strings.pick('The shell is trembling...',
                              'De schaal trilt...'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 22)),
                    if (phase >= 1 && phase <= 3)
                      Text(strings.pick('CRACK $phase/3', 'KRAK $phase/3'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 30)),
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
                          child: FilledButton.icon(
                              onPressed: () async {
                                await _askForName(context, closeAfter: true);
                              },
                              icon: const Icon(Icons.edit_rounded),
                              label: Text(strings.pick(
                                  'Choose a name', 'Kies een naam')))),
                  ]))),
    );
  }
}

class _CrackPainter extends CustomPainter {
  const _CrackPainter(this.intensity);
  final int intensity;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF352B63)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * .52, size.height * .2)
      ..lineTo(size.width * .43, size.height * .4)
      ..lineTo(size.width * .55, size.height * .52)
      ..lineTo(size.width * .41, size.height * .73);
    canvas.drawPath(path, paint);
    canvas.drawLine(Offset(size.width * .44, size.height * .39),
        Offset(size.width * .3, size.height * .44), paint);
    canvas.drawLine(Offset(size.width * .55, size.height * .52),
        Offset(size.width * .7, size.height * .46), paint);
    if (intensity >= 2) {
      canvas.drawLine(Offset(size.width * .43, size.height * .40),
          Offset(size.width * .29, size.height * .30), paint);
      canvas.drawLine(Offset(size.width * .41, size.height * .73),
          Offset(size.width * .57, size.height * .84), paint);
    }
    if (intensity >= 3) {
      canvas.drawLine(Offset(size.width * .55, size.height * .52),
          Offset(size.width * .76, size.height * .64), paint);
      canvas.drawLine(Offset(size.width * .52, size.height * .20),
          Offset(size.width * .65, size.height * .10), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CrackPainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}

class _EggStash extends StatelessWidget {
  const _EggStash({required this.eggs, required this.activeIsEgg});
  final List<DragonEgg> eggs;
  final bool activeIsEgg;
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
                        activeIsEgg ? null : () => _activate(context, egg),
                    child: Text(strings.pick('Raise', 'Activeren')))))
    ]);
  }

  Future<void> _activate(BuildContext context, DragonEgg egg) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(
                    strings.pick('Raise this egg?', 'Dit ei grootbrengen?')),
                content: Text(strings.pick(
                    'Your current dragon moves safely into the sanctuary collection. Coins, gems and discoveries stay yours.',
                    'Je huidige draak verhuist veilig naar de reservaatcollectie. Munten, gems en ontdekkingen blijven van jou.')),
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

Future<void> _askForName(BuildContext context,
    {bool closeAfter = false}) async {
  final controller = TextEditingController();
  final strings = AppStrings.of(context);
  final name = await showDialog<String>(
      context: context,
      barrierDismissible: !closeAfter,
      builder: (dialogContext) => AlertDialog(
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
  controller.dispose();
  if (name == null || !context.mounted) return;
  await context.read<HouseholdProvider>().nameActiveDragon(name);
  if (closeAfter && context.mounted) {
    Navigator.pop(context);
  }
}

String _time(Duration duration) {
  if (duration >= const Duration(hours: 1)) {
    final totalHours = (duration.inSeconds + 3599) ~/ 3600;
    final days = totalHours ~/ 24;
    final hours = totalHours.remainder(24);
    if (days > 0) return hours == 0 ? '${days}d' : '${days}d ${hours}h';
    return '${totalHours}h';
  }
  return '${((duration.inSeconds + 59) ~/ 60).clamp(1, 59)}m';
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
