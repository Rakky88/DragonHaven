import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/day_phase.dart';
import '../models/dragon_egg.dart';
import '../models/pet.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/haven_lighting.dart';
import '../widgets/rooftop_egg_nest.dart';
import 'pet_screen.dart';

class RooftopNestScreen extends StatefulWidget {
  const RooftopNestScreen({super.key});

  @override
  State<RooftopNestScreen> createState() => _RooftopNestScreenState();
}

class _RooftopNestScreenState extends State<RooftopNestScreen> {
  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final egg = game.nestEgg;
    return ListView(
      key: const PageStorageKey('rooftop-nest-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 34),
      children: [
        Text(
          strings.pick('Rooftop Nest', 'Daknest'),
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 5),
        Text(
          egg == null
              ? strings.pick(
                  'A quiet cradle for the next life in your collection.',
                  'Een rustige wieg voor het volgende leven in je collectie.',
                )
              : strings.pick(
                  'One hidden dragon is growing beneath the shell.',
                  'Onder de schaal groeit één verborgen draak.',
                ),
          style: const TextStyle(color: AppColors.muted, fontSize: 15),
        ),
        const SizedBox(height: 15),
        _NestScene(egg: egg, onTap: () => _handleNestTap(context, game)),
        const SizedBox(height: 16),
        if (egg == null)
          _EmptyNestCard(
            hasEggs: game.eggStash.isNotEmpty,
            onChoose: () => _chooseEgg(context, game),
          )
        else ...[
          EggHatchCountdown(
            key: const Key('nest-egg-hatch-countdown'),
            pet: egg,
            onElapsed: () => _hatch(context, game),
          ),
          const SizedBox(height: 14),
          _EggClueCard(egg: egg),
          if (egg.canHatch(DateTime.now())) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('hatch-nest-egg'),
                onPressed: () => _hatch(context, game),
                icon: const GameIconSprite(
                  GameIconKind.mysteriousEgg,
                  size: 28,
                ),
                label: Text(strings.pick(
                  'Reveal the dragon',
                  'Onthul de draak',
                )),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _handleNestTap(
    BuildContext context,
    HouseholdProvider game,
  ) async {
    final egg = game.nestEgg;
    if (egg == null) {
      await _chooseEgg(context, game);
    } else if (egg.firstEgg) {
      game.accelerateStarterEgg();
    }
  }

  Future<void> _chooseEgg(
    BuildContext context,
    HouseholdProvider game,
  ) async {
    final strings = AppStrings.of(context);
    if (game.hasEggInNest) return;
    if (game.eggStash.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(strings.pick(
          'No Eggs are waiting in your inventory.',
          'Er wachten geen Eieren in je inventaris.',
        )),
      ));
      return;
    }
    final selected = await showModalBottomSheet<DragonEgg>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final height = (game.eggStash.length * 112.0 + 92)
            .clamp(230.0, MediaQuery.sizeOf(sheetContext).height * .72)
            .toDouble();
        return SafeArea(
          child: SizedBox(
            height: height,
            child: ListView(
              key: const Key('nest-egg-picker'),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              children: [
                Text(
                  strings.pick(
                    'Choose an Egg',
                    'Kies een Ei',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final egg in game.eggStash)
                  Card(
                    child: ListTile(
                      leading: const GameIconSprite(
                        GameIconKind.mysteriousEgg,
                        size: 54,
                      ),
                      title: Text(
                        strings.eggName(
                          sinister: egg.isSinisterEgg,
                          special: egg.isSpecialEgg,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        strings.pick(
                          'Hatch time: ${strings.remainingDuration(egg.incubationDuration)}\nIts identity is already safely hidden inside.',
                          'Broedtijd: ${strings.remainingDuration(egg.incubationDuration)}\nZijn identiteit zit al veilig binnenin verborgen.',
                        ),
                        key: Key('nest-egg-hatch-time-${egg.id}'),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(sheetContext, egg),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || !context.mounted) return;
    // Let the picker finish its reverse transition before notifying the nest
    // route. This keeps the newly incubating egg visible immediately on both
    // Android and slower accessibility animation settings.
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!context.mounted) return;
    final activated = await game.activateEgg(selected.id);
    if (!context.mounted) return;
    if (activated) {
      setState(() {});
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(strings.pick(
        'The nest is already occupied.',
        'Het nest is al bezet.',
      )),
    ));
  }

  Future<void> _hatch(
    BuildContext context,
    HouseholdProvider game,
  ) async {
    final hatched = await game.hatchActiveDragon();
    if (hatched && context.mounted) Navigator.pop(context);
  }
}

class _NestScene extends StatelessWidget {
  const _NestScene({required this.egg, required this.onTap});

  final Pet? egg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: egg == null || egg?.firstEgg == true,
        child: InkWell(
          key: const Key('rooftop-nest-scene'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            height: 270,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (egg == null)
                    const Positioned.fill(
                      child: HavenPhaseImage(
                        assetFor: _nestAssetForPhase,
                      ),
                    )
                  else
                    const Positioned(
                      left: 0,
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: RooftopEggNest(),
                    ),
                  if (egg == null)
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xD91D1639),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .18),
                          ),
                        ),
                        child: Text(
                          AppStrings.of(context).pick(
                            'Tap the nest to choose an egg',
                            'Tik op het nest om een ei te kiezen',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
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

String _nestAssetForPhase(HavenDayPhase value) =>
    'assets/images/tower_nest_${value.assetKey}.webp';

class _EmptyNestCard extends StatelessWidget {
  const _EmptyNestCard({required this.hasEggs, required this.onChoose});

  final bool hasEggs;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF2ECFF), Color(0xFFFFF4D9)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.mist),
      ),
      child: Row(children: [
        const GameIconSprite(GameIconKind.mysteriousEgg, size: 58),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.pick('The nest is empty', 'Het nest is leeg'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                hasEggs
                    ? strings.pick(
                        'Choose one egg from your inventory.',
                        'Kies één ei uit je inventaris.',
                      )
                    : strings.pick(
                        'Rare eggs can be found in chests earned on Adventures.',
                        'Zeldzame eieren kun je vinden in kisten die je met Adventures verdient.',
                      ),
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        if (hasEggs)
          IconButton.filledTonal(
            key: const Key('choose-nest-egg'),
            tooltip: strings.pick('Choose an egg', 'Kies een ei'),
            onPressed: onChoose,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
      ]),
    );
  }
}

class _EggClueCard extends StatelessWidget {
  const _EggClueCard({required this.egg});

  final Pet egg;

  @override
  Widget build(BuildContext context) {
    final game = context.read<HouseholdProvider>();
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.mist),
      ),
      child: Row(children: [
        const GameIconSprite(GameIconKind.mysteriousEgg, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            game.eggHint(locale: strings.languageCode),
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ]),
    );
  }
}
