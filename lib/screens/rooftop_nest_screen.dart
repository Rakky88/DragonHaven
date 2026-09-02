import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/day_phase.dart';
import '../models/dragon_egg.dart';
import '../models/egg_collection_preferences.dart';
import '../models/pet.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';
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
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * .78,
            child: _NestEggPicker(
              game: game,
              strings: strings,
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

class _NestEggPicker extends StatefulWidget {
  const _NestEggPicker({required this.game, required this.strings});

  final HouseholdProvider game;
  final AppStrings strings;

  @override
  State<_NestEggPicker> createState() => _NestEggPickerState();
}

class _NestEggPickerState extends State<_NestEggPicker> {
  late EggCollectionView _view;
  late EggCollectionSortMode _sortMode;
  late bool _sortDescending;

  @override
  void initState() {
    super.initState();
    _view = EggCollectionView.values.firstWhere(
      (value) => value.name == widget.game.eggInventoryViewMode,
      orElse: () => EggCollectionView.tiles,
    );
    _sortMode = EggCollectionSortMode.values.firstWhere(
      (value) => value.name == widget.game.eggInventorySortMode,
      orElse: () => EggCollectionSortMode.acquiredAt,
    );
    _sortDescending = widget.game.eggInventorySortDescending;
  }

  void _selectSort(EggCollectionSortMode mode) {
    setState(() {
      if (_sortMode == mode) {
        _sortDescending = !_sortDescending;
      } else {
        _sortMode = mode;
        _sortDescending = mode == EggCollectionSortMode.acquiredAt;
      }
    });
    _savePreferences();
  }

  void _toggleView() {
    setState(() {
      _view = _view == EggCollectionView.tiles
          ? EggCollectionView.list
          : EggCollectionView.tiles;
    });
    _savePreferences();
  }

  void _savePreferences() {
    unawaited(widget.game.setEggInventoryCollectionPreferences(
      viewMode: _view.name,
      sortMode: _sortMode.name,
      descending: _sortDescending,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final eggs = sortedDragonEggs(
      widget.game.eggStash,
      sortMode: _sortMode,
      descending: _sortDescending,
    );
    return Column(
      key: const Key('nest-egg-picker'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 12, 9),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.strings.pick('Choose an Egg', 'Kies een Ei'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${eggs.length} ${widget.strings.pick(eggs.length == 1 ? 'egg' : 'eggs', eggs.length == 1 ? 'ei' : 'eieren')}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<EggCollectionSortMode>(
                key: const Key('nest-egg-sort'),
                initialValue: _sortMode,
                onSelected: _selectSort,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    key: const Key('nest-egg-sort-acquiredAt'),
                    value: EggCollectionSortMode.acquiredAt,
                    child: Text(widget.strings.pick('Received', 'Ontvangen')),
                  ),
                  PopupMenuItem(
                    key: const Key('nest-egg-sort-hatchTime'),
                    value: EggCollectionSortMode.hatchTime,
                    child: Text(widget.strings.pick('Hatch time', 'Broedtijd')),
                  ),
                ],
                child: _NestPickerControl(
                  icon: _sortDescending
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  label: _sortMode == EggCollectionSortMode.acquiredAt
                      ? widget.strings.pick('Received', 'Ontvangen')
                      : widget.strings.pick('Hatch time', 'Broedtijd'),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                key: const Key('nest-egg-view-toggle'),
                tooltip: _view == EggCollectionView.tiles
                    ? widget.strings.pick('Show list', 'Lijst tonen')
                    : widget.strings.pick('Show tiles', 'Tegels tonen'),
                onPressed: _toggleView,
                icon: Icon(_view == EggCollectionView.tiles
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: _view == EggCollectionView.tiles
              ? GridView.builder(
                  key: const PageStorageKey('nest-eggs-grid-scroll'),
                  padding: const EdgeInsets.fromLTRB(12, 3, 12, 24),
                  itemCount: eggs.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 210,
                    childAspectRatio: .72,
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                  ),
                  itemBuilder: (context, index) => _NestEggGridTile(
                    egg: eggs[index],
                    game: widget.game,
                    strings: widget.strings,
                  ),
                )
              : ListView.separated(
                  key: const PageStorageKey('nest-eggs-list-scroll'),
                  padding: const EdgeInsets.fromLTRB(12, 3, 12, 24),
                  itemCount: eggs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 7),
                  itemBuilder: (context, index) => _NestEggListTile(
                    egg: eggs[index],
                    game: widget.game,
                    strings: widget.strings,
                  ),
                ),
        ),
      ],
    );
  }
}

class _NestPickerControl extends StatelessWidget {
  const _NestPickerControl({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF1ECFB),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.twilight),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.twilight,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _NestEggGridTile extends StatelessWidget {
  const _NestEggGridTile({
    required this.egg,
    required this.game,
    required this.strings,
  });

  final DragonEgg egg;
  final HouseholdProvider game;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          key: Key('nest-egg-grid-${egg.id}'),
          onTap: () => Navigator.pop(context, egg),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
            child: Column(
              children: [
                const Expanded(
                  child: DragonArt(
                    height: 88,
                    animate: false,
                    stageKey: 'moonEgg',
                  ),
                ),
                Text(
                  strings.eggName(
                    sinister: egg.isSinisterEgg,
                    special: egg.isSpecialEgg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  strings.pick(
                    'Hatch time: ${strings.remainingDuration(egg.incubationDuration)}',
                    'Broedtijd: ${strings.remainingDuration(egg.incubationDuration)}',
                  ),
                  key: Key('nest-egg-hatch-time-${egg.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.twilight,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  game.eggHintForEgg(egg, locale: strings.languageCode),
                  key: Key('nest-egg-hint-${egg.id}'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                    height: 1.2,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _NestEggListTile extends StatelessWidget {
  const _NestEggListTile({
    required this.egg,
    required this.game,
    required this.strings,
  });

  final DragonEgg egg;
  final HouseholdProvider game;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final received =
        MaterialLocalizations.of(context).formatShortDate(egg.acquiredAt);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        key: Key('nest-egg-list-${egg.id}'),
        onTap: () => Navigator.pop(context, egg),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 62,
                child: DragonArt(
                  height: 58,
                  animate: false,
                  stageKey: 'moonEgg',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.eggName(
                        sinister: egg.isSinisterEgg,
                        special: egg.isSpecialEgg,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.pick(
                        'Hatch time: ${strings.remainingDuration(egg.incubationDuration)} · Received $received',
                        'Broedtijd: ${strings.remainingDuration(egg.incubationDuration)} · Ontvangen $received',
                      ),
                      key: Key('nest-egg-hatch-time-${egg.id}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.twilight,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.eggHintForEgg(egg, locale: strings.languageCode),
                      key: Key('nest-egg-hint-${egg.id}'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        height: 1.2,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
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
