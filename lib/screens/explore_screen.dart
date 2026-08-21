import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/chest.dart';
import '../models/pet.dart';
import '../models/sanctuary_activity.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_bits.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    return ListView(
      key: const PageStorageKey('explore-scroll'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
      children: [
        Text(strings.pick('Explore the Spire', 'Verken de Spire'),
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 6),
        Text(
            strings.pick(
                'Short daily adventures grow your dragon and uncover treasure.',
                'Korte dagelijkse avonturen laten je draak groeien en onthullen schatten.'),
            style: const TextStyle(color: AppColors.muted, fontSize: 15)),
        const SizedBox(height: 18),
        _TrainingSummary(pet: game.pet),
        const SizedBox(height: 24),
        SectionHeading(
            title: strings.pick(
                'Sanctuary activities', 'Activiteiten in het reservaat'),
            subtitle: strings.pick('Uses refresh each new day.',
                'Pogingen worden elke nieuwe dag vernieuwd.')),
        const SizedBox(height: 12),
        for (final activity in sanctuaryActivities)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ActivityCard(activity: activity),
          ),
        const SizedBox(height: 16),
        SectionHeading(
            title: strings.pick('Treasure chamber', 'Schatkamer'),
            subtitle: strings.pick('Chest rewards are saved before the reveal.',
                'Kistbeloningen worden vóór de onthulling opgeslagen.')),
        const SizedBox(height: 12),
        for (final tier in ChestTier.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _ChestCard(tier: tier, count: game.chestCount(tier)),
          ),
      ],
    );
  }
}

class _TrainingSummary extends StatelessWidget {
  const _TrainingSummary({required this.pet});
  final Pet pet;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF443876), Color(0xFF685495)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.route_rounded, color: AppColors.gold),
            const SizedBox(width: 9),
            Expanded(
                child: Text(
                    strings.pick('Ascension training', 'Ascension-training'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17))),
            Text(strings.petStage(pet),
                style: const TextStyle(
                    color: Color(0xFFE9E3FA), fontWeight: FontWeight.w800))
          ]),
          const SizedBox(height: 14),
          if (pet.isEgg)
            Text(
                strings.pick(
                    'Training points begin after hatching. Experience still counts now.',
                    'Trainingspunten beginnen na het uitkomen. Experience telt nu al mee.'),
                style: const TextStyle(color: Color(0xFFE9E3FA), height: 1.35))
          else
            for (final focus in TrainingFocus.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(children: [
                  SizedBox(
                      width: 74,
                      child: Text(_focusName(focus),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800))),
                  Expanded(
                      child: LinearProgressIndicator(
                          value: (pet.trainingFor(focus) / 300).clamp(0, 1),
                          minHeight: 8,
                          backgroundColor: Colors.white12,
                          color: _focusColor(focus),
                          borderRadius: BorderRadius.circular(99))),
                  const SizedBox(width: 9),
                  SizedBox(
                      width: 34,
                      child: Text('${pet.trainingFor(focus)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800)))
                ]),
              ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});
  final SanctuaryActivity activity;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final remaining = game.activityUsesRemaining(activity);
    final focus = activity.trainingFocus;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        color: (focus == null
                                ? AppColors.gold
                                : _focusColor(focus))
                            .withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(15)),
                    child: Icon(_activityIcon(activity.id),
                        color: focus == null
                            ? const Color(0xFF9A6A00)
                            : _focusColor(focus))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(strings.isDutch ? activity.nameNl : activity.nameEn,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(
                          strings.isDutch
                              ? activity.descriptionNl
                              : activity.descriptionEn,
                          style: const TextStyle(
                              color: AppColors.muted, height: 1.35))
                    ])),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 7, runSpacing: 7, children: [
              _RewardChip(Icons.auto_awesome_rounded, '+${activity.xp} XP'),
              _RewardChip(Icons.monetization_on_rounded, '+${activity.coins}'),
              if (focus != null)
                _RewardChip(_focusIcon(focus),
                    '+${activity.trainingPoints} ${_focusName(focus)}'),
              if (activity.chestChance > 0)
                _RewardChip(
                    Icons.inventory_2_rounded,
                    activity.chestChance >= 1
                        ? strings.pick('chest', 'kist')
                        : strings.pick('chest chance', 'kistkans')),
              if (activity.gemChance > 0)
                _RewardChip(Icons.diamond_rounded,
                    strings.pick('gem chance', 'gemkans')),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: Key('activity-${activity.id}'),
                onPressed: remaining <= 0 ? null : () => _perform(context),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(remaining <= 0
                    ? strings.pick('Back tomorrow', 'Morgen weer')
                    : strings.pick(
                        'Begin · $remaining left', 'Begin · nog $remaining')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _perform(BuildContext context) async {
    final result =
        await context.read<HouseholdProvider>().performActivity(activity);
    if (!context.mounted || result == null) return;
    final strings = AppStrings.of(context);
    final extras = [
      if (result.gems > 0) '+${result.gems} gem',
      if (result.chestFound != null) strings.pick('a chest!', 'een kist!')
    ];
    showAppSnackBar(context,
        '${strings.pick('Adventure complete', 'Avontuur voltooid')}: +${result.xp} XP, +${result.coins} ${strings.pick('coins', 'munten')}${extras.isEmpty ? '' : ' · ${extras.join(' · ')}'}');
  }
}

class _ChestCard extends StatelessWidget {
  const _ChestCard({required this.tier, required this.count});
  final ChestTier tier;
  final int count;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final color = _chestColor(tier);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(15)),
            child: Icon(Icons.inventory_2_rounded, color: color, size: 29)),
        title: Text(_chestName(strings, tier),
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
            strings.pick(_chestDescriptionEn(tier), _chestDescriptionNl(tier)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        trailing: FilledButton.tonal(
            onPressed: count == 0 ? null : () => _open(context),
            child: Text(strings.pick('Open ($count)', 'Open ($count)'))),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final reward = await context.read<HouseholdProvider>().openChest(tier);
    if (!context.mounted || reward == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _ChestRevealDialog(reward: reward),
    );
  }
}

class _ChestRevealDialog extends StatefulWidget {
  const _ChestRevealDialog({required this.reward});
  final ChestReward reward;
  @override
  State<_ChestRevealDialog> createState() => _ChestRevealDialogState();
}

class _ChestRevealDialogState extends State<_ChestRevealDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 850))
    ..forward();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AlertDialog(
      title: Text(strings.pick('Treasure revealed!', 'Schat onthuld!'),
          textAlign: TextAlign.center),
      content: ScaleTransition(
        scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inventory_2_rounded,
              size: 92, color: _chestColor(widget.reward.tier)),
          const SizedBox(height: 15),
          Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _RewardChip(
                    Icons.monetization_on_rounded, '+${widget.reward.coins}'),
                if (widget.reward.gems > 0)
                  _RewardChip(Icons.diamond_rounded, '+${widget.reward.gems}'),
                _RewardChip(
                    Icons.auto_awesome_rounded, '+${widget.reward.xp} XP')
              ]),
          if (widget.reward.eggFound) ...[
            const SizedBox(height: 18),
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  const Text('🥚', style: TextStyle(fontSize: 30)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          strings.pick(
                              'A Mysterious Egg was sent to your stash!',
                              'Een Mysterieus Ei is naar je voorraad gestuurd!'),
                          style: const TextStyle(fontWeight: FontWeight.w900)))
                ]))
          ]
        ]),
      ),
      actions: [
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.pick('Wonderful', 'Geweldig')))
      ],
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
          color: AppColors.mist, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: AppColors.twilight),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))
      ]));
}

String _focusName(TrainingFocus focus) => switch (focus) {
      TrainingFocus.might => 'Might',
      TrainingFocus.arcana => 'Arcana',
      TrainingFocus.spirit => 'Spirit'
    };
Color _focusColor(TrainingFocus focus) => switch (focus) {
      TrainingFocus.might => const Color(0xFFD96852),
      TrainingFocus.arcana => const Color(0xFF7A63D1),
      TrainingFocus.spirit => const Color(0xFF3FA37C)
    };
IconData _focusIcon(TrainingFocus focus) => switch (focus) {
      TrainingFocus.might => Icons.fitness_center_rounded,
      TrainingFocus.arcana => Icons.auto_awesome_rounded,
      TrainingFocus.spirit => Icons.favorite_rounded
    };
IconData _activityIcon(String id) => switch (id) {
      'nest_tending' => Icons.egg_alt_rounded,
      'cliff_course' => Icons.landscape_rounded,
      'rune_observatory' => Icons.nights_stay_rounded,
      'cloud_walk' => Icons.cloud_rounded,
      'spire_expedition' => Icons.explore_rounded,
      _ => Icons.star_rounded
    };
Color _chestColor(ChestTier tier) => switch (tier) {
      ChestTier.wooden => const Color(0xFF7B5A3A),
      ChestTier.silver => const Color(0xFF59738F),
      ChestTier.gold => const Color(0xFF8B61C2),
      ChestTier.dragon => const Color(0xFF8D52C7),
      ChestTier.mythical => const Color(0xFF2A9CB8),
      ChestTier.sinister => const Color(0xFF6D204E),
    };
String _chestName(AppStrings s, ChestTier tier) => switch (tier) {
      ChestTier.wooden => s.pick('Wooden Chest', 'Houten Kist'),
      ChestTier.silver => s.pick('Silver Chest', 'Zilveren Kist'),
      ChestTier.gold => s.pick('Gold Chest', 'Gouden Kist'),
      ChestTier.dragon => s.pick('Dragon Chest', 'Drakenkist'),
      ChestTier.mythical => s.pick('Mythical Chest', 'Mythische Kist'),
      ChestTier.sinister => s.pick('Sinister Chest', 'Sinistere Kist'),
    };
String _chestDescriptionEn(ChestTier tier) => switch (tier) {
      ChestTier.wooden => 'Coins, a little XP and a tiny egg chance.',
      ChestTier.silver => 'More gems and a better egg chance.',
      ChestTier.gold => 'Rich rewards and a good egg chance.',
      ChestTier.dragon => 'Exceptional rewards and a guaranteed egg.',
      ChestTier.mythical => 'Mythical rewards and a guaranteed egg.',
      ChestTier.sinister => 'Mythical value with a sinister possibility.',
    };
String _chestDescriptionNl(ChestTier tier) => switch (tier) {
      ChestTier.wooden => 'Munten, wat XP en een heel kleine eikans.',
      ChestTier.silver => 'Meer gems en een betere eikans.',
      ChestTier.gold => 'Rijke beloningen en een goede eikans.',
      ChestTier.dragon => 'Uitzonderlijke beloningen en zeker een ei.',
      ChestTier.mythical => 'Mythische beloningen en zeker een ei.',
      ChestTier.sinister => 'Mythische waarde met een sinistere mogelijkheid.',
    };
