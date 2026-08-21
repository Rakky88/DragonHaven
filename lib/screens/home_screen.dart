import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/activity_entry.dart';
import '../models/pet.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';
import '../widgets/ui_bits.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenExplore,
    required this.onOpenPet,
    required this.onOpenHouse,
  });

  final VoidCallback onOpenExplore;
  final VoidCallback onOpenPet;
  final VoidCallback onOpenHouse;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final pet = game.pet;
    return ListView(
      key: const PageStorageKey('spire-scroll'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
      children: [
        Text(strings.greeting, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 5),
        Text(
          strings.pick('Welcome back to your dragon sanctuary.',
              'Welkom terug in je drakenreservaat.'),
          style: const TextStyle(color: AppColors.muted, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MetricPill(
                icon: Icons.auto_awesome_rounded,
                value: '${pet.xp}',
                label: 'XP',
                color: AppColors.twilight),
            MetricPill(
                icon: Icons.monetization_on_rounded,
                value: '${pet.coins}',
                label: strings.pick('coins', 'munten'),
                color: const Color(0xFF9A6A00)),
            MetricPill(
                icon: Icons.diamond_rounded,
                value: '${pet.gems}',
                label: 'gems',
                color: const Color(0xFF258BB0)),
            MetricPill(
                icon: Icons.inventory_2_rounded,
                value: '${game.totalChestCount}',
                label: strings.pick('chests', 'kisten'),
                color: const Color(0xFF8B5A3C)),
          ],
        ),
        const SizedBox(height: 18),
        _TowerHero(pet: pet, onTap: onOpenPet),
        const SizedBox(height: 18),
        _NextStageCard(pet: pet, onOpenPet: onOpenPet),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _ShortcutCard(
                icon: Icons.explore_rounded,
                title: strings.pick('Explore', 'Verkennen'),
                subtitle: strings.pick(
                    'Activities & chests', 'Activiteiten & kisten'),
                color: AppColors.mint,
                onTap: onOpenExplore,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ShortcutCard(
                icon: Icons.cottage_rounded,
                title: strings.pick('Sanctuary', 'Reservaat'),
                subtitle: strings.pick('Rooms & furniture', 'Kamers & meubels'),
                color: AppColors.coral,
                onTap: onOpenHouse,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionHeading(
          title: strings.pick('Collection progress', 'Collectievoortgang'),
          subtitle: strings.pick(
              'Every discovered form stays in the Draconomicon.',
              'Elke ontdekte vorm blijft in het Draconomicon.'),
        ),
        const SizedBox(height: 11),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _CollectionMetric(
                    value: '${game.discoveredLineageCount}/20',
                    label: strings.pick('lineages', 'lijnen')),
                const SizedBox(height: 42, child: VerticalDivider()),
                _CollectionMetric(
                    value: '${game.discoveredForms.length}/100',
                    label: strings.pick('forms', 'vormen')),
                const SizedBox(height: 42, child: VerticalDivider()),
                _CollectionMetric(
                    value: '${game.unlockedAchievementIds.length}/20',
                    label: 'achievements'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SectionHeading(
          title: strings.pick(
              'Whispers from the Spire', 'Fluisteringen uit de Spire'),
          subtitle: strings.pick('Your latest discoveries and milestones.',
              'Je nieuwste ontdekkingen en mijlpalen.'),
        ),
        const SizedBox(height: 11),
        if (game.activities.isEmpty)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(strings.pick('The Spire is quiet—for now.',
                      'De Spire is stil—voor nu.'))))
        else
          Card(
            child: Column(
              children: [
                for (final entry in game.activities.take(5))
                  ListTile(
                    leading: Icon(_activityIcon(entry.code),
                        color: AppColors.twilight),
                    title: Text(
                        strings.isDutch
                            ? strings.activityMessage(entry)
                            : entry.message,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle:
                        entry.xp == 0 && entry.coins == 0 && entry.gems == 0
                            ? null
                            : Text([
                                if (entry.xp != 0) '+${entry.xp} XP',
                                if (entry.coins != 0)
                                  '${entry.coins > 0 ? '+' : ''}${entry.coins} coins',
                                if (entry.gems != 0) '+${entry.gems} gems'
                              ].join(' · ')),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TowerHero extends StatelessWidget {
  const _TowerHero({required this.pet, required this.onTap});
  final Pet pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final name = pet.isEgg
        ? strings.pick('Mysterious Egg', 'Mysterieus Ei')
        : pet.displayName;
    final subtitle = pet.isEgg
        ? strings.pick(
            'Something is moving inside...', 'Er beweegt iets binnenin...')
        : '${strings.petStage(pet)} · ${pet.lineage.name(strings.isDutch)}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('tower-hero'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          height: 330,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: const Color(0xFF2E285D),
            boxShadow: [
              BoxShadow(
                  color: AppColors.twilight.withValues(alpha: 0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 13))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/tower_nest.webp',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, .1),
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 105,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: .55),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 0.42),
                  child: DragonArt(
                      height: pet.isEgg ? 176 : 212,
                      stageKey: pet.stageKey,
                      lineageId: pet.lineageId,
                      evolutionPath: pet.activeEvolutionPath,
                      prismatic: pet.prismatic,
                      sinister: pet.sinister),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  top: 18,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(subtitle,
                                style: const TextStyle(
                                    color: Color(0xFFECE8FA),
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white),
                    ],
                  ),
                ),
                if (pet.prismatic && !pet.isEgg)
                  Positioned(
                      right: 18,
                      bottom: 16,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.86),
                              borderRadius: BorderRadius.circular(99)),
                          child: const Text('🌈 Prismatic',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.twilightDark)))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextStageCard extends StatelessWidget {
  const _NextStageCard({required this.pet, required this.onOpenPet});
  final Pet pet;
  final VoidCallback onOpenPet;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final now = DateTime.now();
    final remaining = pet.remainingForNextStage(now);
    final target = pet.stage == DragonStage.ascended
        ? pet.xp
        : switch (pet.stage) {
            DragonStage.egg =>
              pet.firstEgg ? Pet.hatchXpFirst : Pet.hatchXpLater,
            DragonStage.hatchling => Pet.wyrmlingXp,
            DragonStage.wyrmling => Pet.ascendedXp,
            DragonStage.ascended => pet.xp,
          };
    final progress = target == 0 ? 1.0 : (pet.xp / target).clamp(0.0, 1.0);
    final label = pet.stage == DragonStage.ascended
        ? strings.pick(
            'Ascended and thriving', 'Ascended en helemaal opgebloeid')
        : remaining > Duration.zero
            ? strings.pick(
                '${_durationLabel(remaining)} minimum time remaining',
                'Nog minimaal ${_durationLabel(remaining)}')
            : strings.pick('Time gate complete · ${pet.xp}/$target XP',
                'Tijd voltooid · ${pet.xp}/$target XP');
    return Card(
      child: InkWell(
        onTap: onOpenPet,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.hourglass_top_rounded,
                    color: AppColors.twilight),
                const SizedBox(width: 9),
                Expanded(
                    child: Text(
                        strings.pick('Path to the next form',
                            'Pad naar de volgende vorm'),
                        style: const TextStyle(fontWeight: FontWeight.w900))),
                Text('${pet.xp}/$target XP',
                    style: const TextStyle(
                        color: AppColors.muted, fontWeight: FontWeight.w800))
              ]),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  borderRadius: BorderRadius.circular(99),
                  backgroundColor: AppColors.mist),
              const SizedBox(height: 9),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(13)),
                  child: Icon(icon, color: color)),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12))
            ]),
          ),
        ),
      );
}

class _CollectionMetric extends StatelessWidget {
  const _CollectionMetric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
          child: Column(children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.twilightDark)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700))
      ]));
}

String _durationLabel(Duration duration) {
  if (duration >= const Duration(hours: 1)) {
    final totalHours = (duration.inSeconds + 3599) ~/ 3600;
    final days = totalHours ~/ 24;
    final hours = totalHours.remainder(24);
    if (days > 0) return hours == 0 ? '${days}d' : '${days}d ${hours}h';
    return '${totalHours}h';
  }
  final minutes = ((duration.inSeconds + 59) ~/ 60).clamp(1, 59);
  return '${minutes}m';
}

IconData _activityIcon(ActivityCode code) => switch (code) {
      ActivityCode.chestOpened => Icons.inventory_2_rounded,
      ActivityCode.hatched => Icons.egg_alt_rounded,
      ActivityCode.achievement => Icons.emoji_events_rounded,
      ActivityCode.evolved => Icons.auto_awesome_rounded,
      ActivityCode.itemPlaced => Icons.chair_rounded,
      _ => Icons.brightness_5_rounded,
    };
