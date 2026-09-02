import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/chest.dart';
import '../models/dragon_egg.dart';
import '../models/egg_collection_preferences.dart';
import '../models/mystic_relic.dart';
import '../models/pet.dart';
import '../models/shop_item.dart';
import '../providers/household_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chest_reveal.dart';
import '../widgets/furniture_art.dart';
import '../widgets/dragon_art.dart';
import '../widgets/game_icon_sprite.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab,
      child: Column(children: [
        TabBar(
          key: const Key('tutorial-inventory-tabs'),
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: [
            Tab(
              key: const Key('inventory-tab-eggs'),
              height: 70,
              icon: const GameIconSprite(GameIconKind.inventoryEggs, size: 35),
              iconMargin: const EdgeInsets.only(bottom: 1),
              text: strings.pick('Eggs', 'Eieren'),
            ),
            Tab(
              key: const Key('inventory-tab-chests'),
              height: 70,
              icon:
                  const GameIconSprite(GameIconKind.inventoryChests, size: 35),
              iconMargin: const EdgeInsets.only(bottom: 1),
              text: strings.pick('Chests', 'Kisten'),
            ),
            Tab(
              key: const Key('inventory-tab-furniture'),
              height: 70,
              icon: const GameIconSprite(GameIconKind.inventoryFurniture,
                  size: 35),
              iconMargin: const EdgeInsets.only(bottom: 1),
              text: strings.pick('Furniture', 'Meubels'),
            ),
            Tab(
              key: const Key('inventory-tab-relics'),
              height: 70,
              icon: Image.asset(
                MysticRelic.soulMirror.assetPath,
                width: 35,
                height: 35,
                fit: BoxFit.contain,
              ),
              iconMargin: const EdgeInsets.only(bottom: 1),
              text: strings.pick('Relics', 'Relieken'),
            ),
          ],
        ),
        const Expanded(
            child: TabBarView(children: [
          _EggInventoryTab(),
          _ChestInventoryTab(),
          _FurnitureInventoryTab(),
          _RelicInventoryTab(),
        ])),
      ]),
    );
  }
}

class _InventoryControlChip extends StatelessWidget {
  const _InventoryControlChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1ECFB),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppColors.twilight),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.twilight,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _EggInventoryTab extends StatefulWidget {
  const _EggInventoryTab();

  @override
  State<_EggInventoryTab> createState() => _EggInventoryTabState();
}

class _EggInventoryTabState extends State<_EggInventoryTab> {
  EggCollectionView _view = EggCollectionView.tiles;
  EggCollectionSortMode _sortMode = EggCollectionSortMode.acquiredAt;
  bool _sortDescending = true;
  bool _preferencesLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preferencesLoaded) return;
    final game = context.read<HouseholdProvider>();
    _view = EggCollectionView.values.firstWhere(
      (value) => value.name == game.eggInventoryViewMode,
      orElse: () => EggCollectionView.tiles,
    );
    _sortMode = EggCollectionSortMode.values.firstWhere(
      (value) => value.name == game.eggInventorySortMode,
      orElse: () => EggCollectionSortMode.acquiredAt,
    );
    _sortDescending = game.eggInventorySortDescending;
    _preferencesLoaded = true;
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
    _saveCollectionPreferences();
  }

  void _saveCollectionPreferences() {
    unawaited(
        context.read<HouseholdProvider>().setEggInventoryCollectionPreferences(
              viewMode: _view.name,
              sortMode: _sortMode.name,
              descending: _sortDescending,
            ));
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
    if (game.eggStash.isEmpty) {
      return _EmptyState(
        kind: GameIconKind.inventoryEggs,
        text: strings.pick('No Eggs in your inventory yet.',
            'Nog geen Eieren in je inventaris.'),
      );
    }
    final eggs = sortedDragonEggs(
      game.eggStash,
      sortMode: _sortMode,
      descending: _sortDescending,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 8),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 7,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECFB),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${eggs.length} ${strings.pick(eggs.length == 1 ? 'egg' : 'eggs', eggs.length == 1 ? 'ei' : 'eieren')}',
                  key: const Key('egg-inventory-count'),
                  style: const TextStyle(
                    color: AppColors.twilight,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<EggCollectionSortMode>(
                    key: const Key('egg-inventory-sort'),
                    initialValue: _sortMode,
                    onSelected: _selectSort,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        key: const Key('egg-sort-acquiredAt'),
                        value: EggCollectionSortMode.acquiredAt,
                        child: Text(strings.pick('Received', 'Ontvangen')),
                      ),
                      PopupMenuItem(
                        key: const Key('egg-sort-hatchTime'),
                        value: EggCollectionSortMode.hatchTime,
                        child: Text(strings.pick('Hatch time', 'Broedtijd')),
                      ),
                    ],
                    child: _InventoryControlChip(
                      icon: _sortDescending
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      label: _sortMode == EggCollectionSortMode.acquiredAt
                          ? strings.pick('Received', 'Ontvangen')
                          : strings.pick('Hatch time', 'Broedtijd'),
                    ),
                  ),
                  const SizedBox(width: 7),
                  IconButton.filledTonal(
                    key: const Key('egg-inventory-view-toggle'),
                    tooltip: _view == EggCollectionView.tiles
                        ? strings.pick('Show list', 'Lijst tonen')
                        : strings.pick('Show tiles', 'Tegels tonen'),
                    onPressed: () {
                      setState(() {
                        _view = _view == EggCollectionView.tiles
                            ? EggCollectionView.list
                            : EggCollectionView.tiles;
                      });
                      _saveCollectionPreferences();
                    },
                    icon: Icon(_view == EggCollectionView.tiles
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _view == EggCollectionView.tiles
              ? GridView.builder(
                  key: const PageStorageKey('inventory-eggs-scroll'),
                  padding: const EdgeInsets.fromLTRB(12, 3, 12, 32),
                  itemCount: eggs.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 210,
                    childAspectRatio: .82,
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                  ),
                  itemBuilder: (context, index) {
                    final egg = eggs[index];
                    final reserved = game.isEggReservedForTrade(egg.id);
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        key: Key('inventory-egg-${egg.id}'),
                        onTap: () => _showEggDetails(context, egg),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
                          child: Column(
                            children: [
                              const Expanded(
                                child: DragonArt(
                                  height: 86,
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                strings
                                    .remainingDuration(egg.incubationDuration),
                                style: const TextStyle(
                                  color: AppColors.twilight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                game.eggHintForEgg(
                                  egg,
                                  locale: strings.languageCode,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10.5,
                                  height: 1.2,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              if (reserved) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.swap_horiz_rounded,
                                        size: 14, color: AppColors.twilight),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        strings.pick(
                                          'Reserved for trade',
                                          'Gereserveerd voor ruil',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.twilight,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              : ListView.separated(
                  key: const PageStorageKey('inventory-eggs-list-scroll'),
                  padding: const EdgeInsets.fromLTRB(12, 3, 12, 32),
                  itemCount: eggs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    final egg = eggs[index];
                    final reserved = game.isEggReservedForTrade(egg.id);
                    final received = MaterialLocalizations.of(context)
                        .formatShortDate(egg.acquiredAt);
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        key: Key('inventory-egg-list-${egg.id}'),
                        onTap: () => _showEggDetails(context, egg),
                        leading: const SizedBox.square(
                          dimension: 54,
                          child: DragonArt(
                            height: 52,
                            animate: false,
                            stageKey: 'moonEgg',
                          ),
                        ),
                        title: Text(
                          strings.eggName(
                            sinister: egg.isSinisterEgg,
                            special: egg.isSpecialEgg,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          '${strings.remainingDuration(egg.incubationDuration)} · '
                          '${strings.pick('Received', 'Ontvangen')} $received'
                          '${reserved ? strings.pick(' · Reserved', ' · Gereserveerd') : ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showEggDetails(BuildContext context, DragonEgg egg) async {
    final game = context.read<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final reserved = game.isEggReservedForTrade(egg.id);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DragonArt(
                height: 126,
                animate: false,
                stageKey: 'moonEgg',
              ),
              Text(
                strings.eggName(
                  sinister: egg.isSinisterEgg,
                  special: egg.isSpecialEgg,
                ),
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0FC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  game.eggHintForEgg(egg, locale: strings.languageCode),
                  key: Key('inventory-egg-clue-${egg.id}'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.35,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (game.isEggRarityKnown(egg.id))
                ListTile(
                  key: Key('inventory-egg-rarity-${egg.id}'),
                  dense: true,
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: Text(strings.pick('Rarity', 'Zeldzaamheid')),
                  trailing: Text(
                    strings.lineageRarity(egg.lineage),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                )
              else if (game.usableRelicCount(MysticRelic.astralLens) > 0)
                ListTile(
                  key: Key('inventory-egg-use-astral-${egg.id}'),
                  leading: Image.asset(
                    MysticRelic.astralLens.assetPath,
                    width: 38,
                    height: 38,
                  ),
                  title: Text(strings.pick(
                    'Reveal rarity with Astral Lens',
                    'Onthul zeldzaamheid met Astrale Lens',
                  )),
                  onTap: () async {
                    final result = await game.useAstralLens(egg.id);
                    if (!sheetContext.mounted ||
                        result != AstralLensUseResult.revealed) {
                      return;
                    }
                    Navigator.pop(sheetContext);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(strings.pick(
                        'Rarity: ${strings.lineageRarity(egg.lineage)}',
                        'Zeldzaamheid: ${strings.lineageRarity(egg.lineage)}',
                      )),
                    ));
                  },
                ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.schedule_rounded),
                title: Text(strings.pick(
                  'Incubation after nesting',
                  'Broedtijd na plaatsing',
                )),
                trailing: Text(
                  strings.remainingDuration(egg.incubationDuration),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (reserved)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.swap_horiz_rounded),
                  title: Text(strings.pick(
                    'Reserved for trade',
                    'Gereserveerd voor ruil',
                  )),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.outlined(
                    key: Key('inventory-discard-egg-${egg.id}'),
                    tooltip: strings.pick('Discard egg', 'Ei wegdoen'),
                    onPressed: reserved
                        ? null
                        : () async {
                            Navigator.pop(sheetContext);
                            await _discardEgg(context, egg);
                          },
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      key: Key('inventory-incubate-egg-${egg.id}'),
                      onPressed: game.hasEggInNest || reserved
                          ? null
                          : () async {
                              Navigator.pop(sheetContext);
                              final ok = await game.activateEgg(egg.id);
                              if (context.mounted && ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(strings.pick(
                                      'Egg moved to the rooftop nest.',
                                      'Ei naar het daknest verplaatst.',
                                    )),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.egg_alt_rounded),
                      label: Text(strings.pick('Incubate', 'Broed uit')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _discardEgg(BuildContext context, DragonEgg egg) async {
    final strings = AppStrings.of(context);
    final eggName = strings.eggName(
      sinister: egg.isSinisterEgg,
      special: egg.isSpecialEgg,
    );
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: Text(strings.pick(
              'Discard this $eggName?',
              'Dit $eggName wegdoen?',
            )),
            content: Text(strings.pick(
                'The hidden dragon inside will be lost permanently.',
                'De verborgen draak binnenin gaat definitief verloren.')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(strings.tr('cancel'))),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(strings.pick('Discard', 'Wegdoen'))),
            ],
          ),
        ) ??
        false;
    if (confirmed && context.mounted) {
      await context.read<HouseholdProvider>().discardEgg(egg.id);
    }
  }
}

class _ChestInventoryTab extends StatelessWidget {
  const _ChestInventoryTab();
  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
    const chestOrder = [
      ChestTier.wooden,
      ChestTier.silver,
      ChestTier.gold,
      ChestTier.dragon,
      ChestTier.mythical,
      ChestTier.sinister,
      ChestTier.special,
      ChestTier.portrait,
      ChestTier.title,
      ChestTier.music,
    ];
    final tiers =
        chestOrder.where((tier) => game.chestCount(tier) > 0).toList();
    if (tiers.isEmpty) {
      return _EmptyState(
          kind: GameIconKind.inventoryChests,
          text: strings.pick('Adventure rewards are stored here.',
              'Avontuurbeloningen worden hier bewaard.'));
    }
    return ListView(
      key: const PageStorageKey('inventory-chests-scroll'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      children: [
        for (final tier in tiers)
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 9, 8),
              child: Row(children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Color(tier.colorValue).withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Image.asset(tier.assetPath, fit: BoxFit.contain),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.chestLabel(tier),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '×${game.chestCount(tier)}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      key: Key('inventory-open-chest-${tier.name}'),
                      onPressed: game.tradeableChestCount(tier) > 0
                          ? () => _openChest(context, tier)
                          : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                      ),
                      child: Text(strings.pick('Open', 'Openen')),
                    ),
                    if (game.chestCount(tier) >= 10) ...[
                      const SizedBox(height: 5),
                      OutlinedButton(
                        key: Key('inventory-open-ten-chests-${tier.name}'),
                        onPressed: game.openableChestCount(tier) >= 10
                            ? () => _openChest(
                                  context,
                                  tier,
                                  quantity: 10,
                                )
                            : null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                        ),
                        child: Text(strings.pick('Open 10', 'Open er 10')),
                      ),
                    ],
                  ],
                ),
              ]),
            ),
          ),
      ],
    );
  }

  Future<void> _openChest(
    BuildContext context,
    ChestTier tier, {
    int quantity = 1,
  }) async {
    final navigator = Navigator.of(context);
    final game = context.read<HouseholdProvider>();
    if (!navigator.mounted) return;
    if (tier == ChestTier.portrait && game.hasEveryPortrait) {
      final strings = AppStrings.of(context);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Image.asset(tier.assetPath, width: 92, height: 92),
          title: Text(strings.pick(
            'Portrait collection complete',
            'Portretcollectie compleet',
          )),
          content: Text(strings.pick(
            'You already own all 100 portraits. This Portrait Chest stays safely in your Inventory and cannot be opened.',
            'Je bezit alle 100 portretten al. Deze Portretkist blijft veilig in je Inventory en kan niet worden geopend.',
          )),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.pick('Understood', 'Begrepen')),
            ),
          ],
        ),
      );
      return;
    }
    if (tier == ChestTier.title && game.hasEveryTitle) {
      final strings = AppStrings.of(context);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Image.asset(tier.assetPath, width: 92, height: 92),
          title: Text(strings.pick(
            'Title collection complete',
            'Titelcollectie compleet',
          )),
          content: Text(strings.pick(
            'You already own all 500 account titles. This Title Chest stays safely in your Inventory and cannot be opened.',
            'Je bezit alle 500 accounttitels al. Deze Titelkist blijft veilig in je Inventory en kan niet worden geopend.',
          )),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.pick('Understood', 'Begrepen')),
            ),
          ],
        ),
      );
      return;
    }
    if (tier == ChestTier.music && game.hasEveryMusicTrack) {
      final strings = AppStrings.of(context);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Image.asset(tier.assetPath, width: 92, height: 92),
          title: Text(strings.pick(
            'Music collection complete',
            'Muziekcollectie compleet',
          )),
          content: Text(strings.pick(
            'You already own every song. This Music Chest stays safely in your Inventory and cannot be opened.',
            'Je bezit alle liedjes al. Deze Muziekkist blijft veilig in je Inventory en kan niet worden geopend.',
          )),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.pick('Understood', 'Begrepen')),
            ),
          ],
        ),
      );
      return;
    }
    game.beginPresentationDeferral();
    try {
      await showChestReveal(
        navigator.context,
        tier,
        quantity: quantity,
        openChest: () async {
          if (quantity > 1) {
            return game.openChests(tier, count: quantity);
          }
          final reward = await game.openChest(tier);
          return reward == null ? null : ChestRewardBundle.single(reward);
        },
        onOpen: () => HavenAudio.play(_soundForChest(tier)),
      );
    } finally {
      // Let the chest route finish leaving before milestone cinematics start.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      game.endPresentationDeferral();
    }
  }
}

HavenSound _soundForChest(ChestTier tier) => switch (tier) {
      ChestTier.wooden => HavenSound.chestWooden,
      ChestTier.silver => HavenSound.chestSilver,
      ChestTier.gold => HavenSound.chestGold,
      ChestTier.dragon => HavenSound.chestDragon,
      ChestTier.mythical => HavenSound.chestMythical,
      ChestTier.sinister => HavenSound.chestSinister,
      ChestTier.special => HavenSound.chestSpecial,
      ChestTier.portrait ||
      ChestTier.title ||
      ChestTier.music =>
        HavenSound.chestMythical,
    };

enum _FurnitureInventoryView { tiles, list }

enum _FurnitureSortMode { name, type, rarity }

class _FurnitureInventoryTab extends StatefulWidget {
  const _FurnitureInventoryTab();

  @override
  State<_FurnitureInventoryTab> createState() => _FurnitureInventoryTabState();
}

class _FurnitureInventoryTabState extends State<_FurnitureInventoryTab> {
  _FurnitureInventoryView _view = _FurnitureInventoryView.tiles;
  _FurnitureSortMode _sortMode = _FurnitureSortMode.name;
  bool _sortDescending = false;
  final Set<ItemSlot> _slotFilters = {};
  final Set<ItemRarity> _rarityFilters = {};
  bool _placedOnly = false;

  void _selectSort(_FurnitureSortMode mode) {
    setState(() {
      if (_sortMode == mode) {
        _sortDescending = !_sortDescending;
      } else {
        _sortMode = mode;
        _sortDescending = mode == _FurnitureSortMode.rarity;
      }
    });
  }

  String _sortLabel(AppStrings strings) => switch (_sortMode) {
        _FurnitureSortMode.name => strings.pick('Name', 'Naam'),
        _FurnitureSortMode.type => strings.pick('Type', 'Type'),
        _FurnitureSortMode.rarity => strings.pick('Rarity', 'Zeldzaamheid'),
      };

  String _slotLabel(AppStrings strings, ItemSlot slot) => switch (slot) {
        ItemSlot.bed => strings.pick('Beds', 'Bedden'),
        ItemSlot.plant => strings.pick('Plants', 'Planten'),
        ItemSlot.wall => strings.pick('Wall', 'Muur'),
        ItemSlot.light => strings.pick('Lights', 'Lampen'),
      };

  String _rarityLabel(AppStrings strings, ItemRarity rarity) =>
      switch (rarity) {
        ItemRarity.common => strings.pick('Common', 'Gewoon'),
        ItemRarity.special => strings.pick('Special', 'Speciaal'),
        ItemRarity.rare => strings.pick('Rare', 'Zeldzaam'),
      };

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final ownedItems = game.ownedItemIds
        .map(shopItemById)
        .whereType<ShopItem>()
        .toList(growable: false);
    if (ownedItems.isEmpty) {
      return _EmptyState(
          kind: GameIconKind.inventoryFurniture,
          text: strings.pick('Your purchased furniture is stored here.',
              'Je gekochte meubels worden hier bewaard.'));
    }
    final items = ownedItems
        .where((item) =>
            (_slotFilters.isEmpty || _slotFilters.contains(item.slot)) &&
            (_rarityFilters.isEmpty || _rarityFilters.contains(item.rarity)) &&
            (!_placedOnly || game.isEquipped(item)))
        .toList()
      ..sort((a, b) {
        final comparison = switch (_sortMode) {
          _FurnitureSortMode.name =>
            strings.itemName(a).compareTo(strings.itemName(b)),
          _FurnitureSortMode.type => a.slot.index.compareTo(b.slot.index),
          _FurnitureSortMode.rarity => a.rarity.index.compareTo(b.rarity.index),
        };
        final stable = comparison != 0 ? comparison : a.id.compareTo(b.id);
        return _sortDescending ? -stable : stable;
      });
    final activeFilterCount =
        _slotFilters.length + _rarityFilters.length + (_placedOnly ? 1 : 0);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
          child: Row(
            children: [
              PopupMenuButton<_FurnitureSortMode>(
                key: const Key('furniture-inventory-sort'),
                initialValue: _sortMode,
                onSelected: _selectSort,
                itemBuilder: (_) => [
                  for (final mode in _FurnitureSortMode.values)
                    PopupMenuItem(
                      key: Key('furniture-sort-${mode.name}'),
                      value: mode,
                      child: Text(switch (mode) {
                        _FurnitureSortMode.name => strings.pick('Name', 'Naam'),
                        _FurnitureSortMode.type => strings.pick('Type', 'Type'),
                        _FurnitureSortMode.rarity =>
                          strings.pick('Rarity', 'Zeldzaamheid'),
                      }),
                    ),
                ],
                child: _InventoryControlChip(
                  icon: _sortDescending
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  label: _sortLabel(strings),
                ),
              ),
              const Spacer(),
              Badge(
                isLabelVisible: activeFilterCount > 0,
                label: Text('$activeFilterCount'),
                child: IconButton.filledTonal(
                  key: const Key('furniture-inventory-filter'),
                  onPressed: () => _showFilters(context, game),
                  icon: const Icon(Icons.filter_alt_rounded),
                ),
              ),
              const SizedBox(width: 7),
              IconButton.filledTonal(
                key: const Key('furniture-inventory-view-toggle'),
                onPressed: () => setState(() {
                  _view = _view == _FurnitureInventoryView.tiles
                      ? _FurnitureInventoryView.list
                      : _FurnitureInventoryView.tiles;
                }),
                icon: Icon(_view == _FurnitureInventoryView.tiles
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(strings.pick(
                    'No furniture matches these filters.',
                    'Geen meubels voldoen aan deze filters.',
                  )),
                )
              : _view == _FurnitureInventoryView.tiles
                  ? GridView.builder(
                      key: const PageStorageKey('inventory-furniture-scroll'),
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 32),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: .92,
                        crossAxisSpacing: 9,
                        mainAxisSpacing: 9,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(children: [
                              Expanded(child: FurnitureArt(item: item)),
                              Text(
                                strings.itemName(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900),
                              ),
                              if (game.isEquipped(item))
                                Text(strings.pick('Placed', 'Geplaatst'),
                                    style: const TextStyle(
                                        color: AppColors.muted, fontSize: 11)),
                            ]),
                          ),
                        );
                      },
                    )
                  : ListView.separated(
                      key: const PageStorageKey(
                          'inventory-furniture-list-scroll'),
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 32),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 7),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: SizedBox.square(
                              dimension: 58,
                              child: FurnitureArt(item: item),
                            ),
                            title: Text(strings.itemName(item),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900)),
                            subtitle: Text(
                              '${_slotLabel(strings, item.slot)} · '
                              '${_rarityLabel(strings, item.rarity)}',
                            ),
                            trailing: game.isEquipped(item)
                                ? const Icon(Icons.check_circle_rounded,
                                    color: AppColors.twilight)
                                : null,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Future<void> _showFilters(
    BuildContext context,
    HouseholdProvider game,
  ) async {
    final strings = AppStrings.of(context);
    final ownedItems =
        game.ownedItemIds.map(shopItemById).whereType<ShopItem>();
    final slots = ownedItems.map((item) => item.slot).toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final rarities = ownedItems.map((item) => item.rarity).toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, modalSetState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      strings.pick('Filter furniture', 'Meubels filteren'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    key: const Key('furniture-filter-clear'),
                    onPressed: () => modalSetState(() {
                      _slotFilters.clear();
                      _rarityFilters.clear();
                      _placedOnly = false;
                    }),
                    child: Text(strings.pick('Clear', 'Wissen')),
                  ),
                ]),
                Text(strings.pick('Type', 'Type'),
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Wrap(
                  spacing: 7,
                  children: [
                    for (final slot in slots)
                      FilterChip(
                        key: Key('furniture-filter-slot-${slot.name}'),
                        label: Text(_slotLabel(strings, slot)),
                        selected: _slotFilters.contains(slot),
                        onSelected: (selected) => modalSetState(() => selected
                            ? _slotFilters.add(slot)
                            : _slotFilters.remove(slot)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(strings.pick('Rarity', 'Zeldzaamheid'),
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Wrap(
                  spacing: 7,
                  children: [
                    for (final rarity in rarities)
                      FilterChip(
                        key: Key('furniture-filter-rarity-${rarity.name}'),
                        label: Text(_rarityLabel(strings, rarity)),
                        selected: _rarityFilters.contains(rarity),
                        onSelected: (selected) => modalSetState(() => selected
                            ? _rarityFilters.add(rarity)
                            : _rarityFilters.remove(rarity)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                FilterChip(
                  key: const Key('furniture-filter-placed'),
                  label: Text(strings.pick('Placed only', 'Alleen geplaatst')),
                  selected: _placedOnly,
                  onSelected: (selected) =>
                      modalSetState(() => _placedOnly = selected),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child:
                        Text(strings.pick('Show furniture', 'Meubels tonen')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }
}

class _RelicInventoryTab extends StatelessWidget {
  const _RelicInventoryTab();

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final owned = MysticRelic.values
        .where((relic) => game.relicCount(relic) > 0)
        .toList(growable: false);
    if (owned.isEmpty) {
      return _RelicEmptyState(strings: strings);
    }
    return ListView(
      key: const PageStorageKey('inventory-relics-scroll'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      children: [
        for (final relic in owned)
          _RelicCard(
            relic: relic,
            count: game.relicCount(relic),
            canUse: game.usableRelicCount(relic) > 0,
          ),
      ],
    );
  }
}

class _RelicEmptyState extends StatelessWidget {
  const _RelicEmptyState({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF25194C), Color(0xFF624899)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44342469),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Image.asset(
                MysticRelic.soulMirror.assetPath,
                width: 148,
                height: 148,
                fit: BoxFit.contain,
              ),
              Text(
                strings.pick('No Relics yet', 'Nog geen Relieken'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                strings.pick(
                  'These exceptionally rare treasures can appear in Gold Chests and rarer chests.',
                  'Deze uitzonderlijk zeldzame schatten kunnen verschijnen in Gouden Kisten en zeldzamere kisten.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFD8CFF1),
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
          ),
        ),
      );
}

class _RelicCard extends StatelessWidget {
  const _RelicCard({
    required this.relic,
    required this.count,
    required this.canUse,
  });

  final MysticRelic relic;
  final int count;
  final bool canUse;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final detail = switch (relic) {
      MysticRelic.chronoshard =>
        game.chronoshardReductions.map((value) => '$value%').join(' · '),
      MysticRelic.twinstarBrooch => game.twinstarBroochDragonId == null
          ? strings.pick('Not equipped', 'Niet gekoppeld')
          : strings.pick('Equipped to a dragon', 'Aan een draak gekoppeld'),
      _ => null,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 9, 11, 9),
        child: Row(children: [
          Container(
            width: 84,
            height: 84,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [Color(0xFFFFF3BF), Color(0xFFE9DEFF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(relic.assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      strings.relicName(relic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    '×$count',
                    style: const TextStyle(
                      color: AppColors.twilight,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(
                  strings.relicDescription(relic),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                if (detail != null && detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: AppColors.twilight,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    key: Key('use-relic-${relic.name}'),
                    onPressed: canUse ? () => _useRelic(context, relic) : null,
                    child: Text(strings.pick('Use', 'Gebruiken')),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

Future<void> _useRelic(BuildContext context, MysticRelic relic) async {
  switch (relic) {
    case MysticRelic.astralLens:
      return _useAstralLens(context);
    case MysticRelic.chronoshard:
      return _useChronoshard(context);
    case MysticRelic.wayfinderSigil:
      return _useWayfinderSigil(context);
    case MysticRelic.twinstarBrooch:
      return _equipTwinstarBrooch(context);
    case MysticRelic.moralPrism:
    case MysticRelic.orderCompass:
    case MysticRelic.soulMirror:
      break;
  }
  return _useDragonRevealRelic(context, relic);
}

Future<void> _useDragonRevealRelic(
  BuildContext context,
  MysticRelic relic,
) async {
  final game = context.read<HouseholdProvider>();
  final strings = AppStrings.of(context);
  final eligibleDragons = game.ownedDragons
      .where((dragon) => !game.isRelicKnownFor(relic, dragon))
      .toList(growable: false);
  if (eligibleDragons.isEmpty) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        icon: Image.asset(relic.assetPath, width: 82, height: 82),
        title: Text(
            strings.pick('Nothing left to reveal', 'Niets meer te onthullen')),
        content: Text(strings.pick(
          'This Relic has already revealed its secret for every dragon you own. Hatch or collect another dragon to use it.',
          'Dit Reliek heeft zijn geheim al onthuld voor elke draak die je bezit. Laat een ander ei uitkomen of verzamel een nieuwe draak om het te gebruiken.',
        )),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.pick('Understood', 'Begrepen')),
          ),
        ],
      ),
    );
    return;
  }
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          icon: Image.asset(relic.assetPath, width: 82, height: 82),
          title: Text(strings.pick(
            'Use this Relic?',
            'Dit Reliek gebruiken?',
          )),
          content: Text(strings.pick(
            'This is a consumable item. It disappears after revealing one dragon. Continue?',
            'Dit is een verbruiksitem. Het verdwijnt nadat het één draak heeft onthuld. Doorgaan?',
          )),
          actions: [
            TextButton(
              key: const Key('cancel-relic-use'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.tr('cancel')),
            ),
            FilledButton(
              key: const Key('confirm-relic-use'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.pick('Continue', 'Doorgaan')),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed || !context.mounted) return;
  final selected = await showModalBottomSheet<Pet>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: .78,
      child: SafeArea(
        child: ListView(
          key: const Key('relic-dragon-picker-scroll'),
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
          children: [
            Row(children: [
              Image.asset(relic.assetPath, width: 72, height: 72),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.pick('Choose a dragon', 'Kies een draak'),
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    Text(
                      strings.relicName(relic),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 8),
            for (final dragon in game.ownedDragons)
              Card(
                child: ListTile(
                  key: Key('relic-dragon-choice-${dragon.id}'),
                  enabled: !game.isRelicKnownFor(relic, dragon),
                  leading: SizedBox.square(
                    dimension: 58,
                    child: DragonArt(
                      height: 58,
                      animate: false,
                      stageKey: dragon.stageKey,
                      lineageId: dragon.lineageId,
                      evolutionPath: dragon.activeEvolutionPath,
                      prismatic: dragon.prismatic,
                      sinister: dragon.sinister,
                    ),
                  ),
                  title: Text(
                    dragon.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    game.isRelicKnownFor(relic, dragon)
                        ? strings.pick('Already revealed', 'Al onthuld')
                        : strings.pick(
                            'Secret still hidden', 'Geheim nog verborgen'),
                  ),
                  trailing: game.isRelicKnownFor(relic, dragon)
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.twilight)
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: game.isRelicKnownFor(relic, dragon)
                      ? null
                      : () => Navigator.pop(sheetContext, dragon),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  if (selected == null || !context.mounted) return;
  final result = await game.useRelic(relic, selected.id);
  if (!context.mounted || result != MysticRelicUseResult.revealed) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AnimatedRelicRevealDialog(
      relic: relic,
      dragon: selected,
    ),
  );
}

Future<void> _useAstralLens(BuildContext context) async {
  final game = context.read<HouseholdProvider>();
  final strings = AppStrings.of(context);
  final targets = <({String id, String name, String rarity})>[
    if (game.nestEgg case final egg?)
      if (!game.isEggRarityKnown(egg.id))
        (
          id: egg.id,
          name: strings.pick('Egg in rooftop nest', 'Ei in het daknest'),
          rarity: strings.lineageRarity(egg.lineage),
        ),
    for (final egg in game.eggStash)
      if (!game.isEggRarityKnown(egg.id))
        (
          id: egg.id,
          name: strings.pick('Inventory egg', 'Ei in inventaris'),
          rarity: strings.lineageRarity(egg.lineage),
        ),
  ];
  if (targets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(strings.pick(
        'There is no egg with an unknown rarity.',
        'Er is geen ei waarvan de zeldzaamheid nog onbekend is.',
      )),
    ));
    return;
  }
  final selected =
      await showModalBottomSheet<({String id, String name, String rarity})>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
        children: [
          Text(strings.pick('Reveal which egg?', 'Welk ei onthullen?'),
              style: Theme.of(sheetContext).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (var index = 0; index < targets.length; index++)
            Card(
              child: ListTile(
                key: Key('astral-lens-egg-${targets[index].id}'),
                leading: const GameIconSprite(
                  GameIconKind.mysteriousEgg,
                  size: 42,
                ),
                title: Text(targets[index].name),
                subtitle: Text(strings.pick(
                  'Rarity is still hidden',
                  'Zeldzaamheid is nog verborgen',
                )),
                onTap: () => Navigator.pop(sheetContext, targets[index]),
              ),
            ),
        ],
      ),
    ),
  );
  if (selected == null || !context.mounted) return;
  final result = await game.useAstralLens(selected.id);
  if (!context.mounted || result != AstralLensUseResult.revealed) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon:
          Image.asset(MysticRelic.astralLens.assetPath, width: 92, height: 92),
      title: Text(strings.pick('Rarity revealed', 'Zeldzaamheid onthuld')),
      content: Text(selected.rarity,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(strings.pick('Done', 'Klaar')),
        ),
      ],
    ),
  );
}

Future<void> _useChronoshard(BuildContext context) async {
  final game = context.read<HouseholdProvider>();
  final strings = AppStrings.of(context);
  if (!game.hasEggInNest) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(strings.pick(
        'Place an egg in the rooftop nest first.',
        'Plaats eerst een ei in het daknest.',
      )),
    ));
    return;
  }
  final values = [...game.chronoshardReductions];
  final selected = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
        children: [
          Text(strings.pick('Choose a Chronoshard', 'Kies een Chronoscherf'),
              style: Theme.of(sheetContext).textTheme.titleLarge),
          Text(strings.pick(
            'Its percentage was fixed when this relic was found.',
            'Het percentage werd vastgelegd toen dit reliek werd gevonden.',
          )),
          const SizedBox(height: 8),
          for (var index = 0; index < values.length; index++)
            Card(
              child: ListTile(
                key: Key('chronoshard-${values[index]}-$index'),
                leading: Image.asset(
                  MysticRelic.chronoshard.assetPath,
                  width: 48,
                  height: 48,
                ),
                title: Text(
                  '${values[index]}%',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(strings.pick(
                  'Shorten remaining incubation',
                  'Verkort de resterende broedtijd',
                )),
                onTap: () => Navigator.pop(sheetContext, values[index]),
              ),
            ),
        ],
      ),
    ),
  );
  if (selected == null || !context.mounted) return;
  final result = await game.useChronoshard(selected);
  if (!context.mounted || result != ChronoshardUseResult.accelerated) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(strings.pick(
      'Remaining incubation shortened by $selected%.',
      'Resterende broedtijd met $selected% verkort.',
    )),
  ));
}

Future<void> _useWayfinderSigil(BuildContext context) async {
  final game = context.read<HouseholdProvider>();
  final strings = AppStrings.of(context);
  final kind = await showDialog<AdventureKind>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(strings.pick('Choose Adventure type', 'Kies avontuurtype')),
      children: [
        for (final value in const [
          AdventureKind.mini,
          AdventureKind.short,
          AdventureKind.long,
        ])
          SimpleDialogOption(
            key: Key('wayfinder-kind-${value.name}'),
            onPressed: () => Navigator.pop(dialogContext, value),
            child: Text(switch (value) {
              AdventureKind.mini => strings.pick('Mini', 'Mini'),
              AdventureKind.short => strings.pick('Short', 'Kort'),
              AdventureKind.long => strings.pick('Long', 'Lang'),
              AdventureKind.group || AdventureKind.special => value.name,
            }),
          ),
      ],
    ),
  );
  if (kind == null || !context.mounted) return;
  final adventures = game.adventuresFor(kind);
  const createKey = '__create__';
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
        children: [
          Text(strings.pick('Use Wayfinder Sigil', 'Padvinderszegel gebruiken'),
              style: Theme.of(sheetContext).textTheme.titleLarge),
          if (adventures.length < 3)
            Card(
              child: ListTile(
                key: const Key('wayfinder-create'),
                leading: const Icon(Icons.add_circle_rounded),
                title: Text(strings.pick(
                  'Create an extra Adventure',
                  'Maak een extra avontuur',
                )),
                onTap: () => Navigator.pop(sheetContext, createKey),
              ),
            ),
          for (final adventure in adventures)
            Card(
              child: ListTile(
                key: Key('wayfinder-reroll-${adventure.id}'),
                leading: const Icon(Icons.casino_rounded),
                title: Text(strings.pick(adventure.titleEn, adventure.titleNl)),
                subtitle: Text(strings.pick(
                    'Reroll this Adventure', 'Dit avontuur opnieuw rollen')),
                onTap: () => Navigator.pop(sheetContext, adventure.id),
              ),
            ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  final result = await game.useWayfinderSigil(
    kind,
    replaceAdventureId: choice == createKey ? null : choice,
  );
  if (!context.mounted || result != WayfinderSigilUseResult.changed) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(strings.pick(
      'The Adventure choices have changed.',
      'De avontuurkeuzes zijn gewijzigd.',
    )),
  ));
}

Future<void> _equipTwinstarBrooch(BuildContext context) async {
  final game = context.read<HouseholdProvider>();
  final strings = AppStrings.of(context);
  const unequipKey = '__unequip__';
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: .72,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
          children: [
            Text(strings.pick('Twinstar Brooch', 'Tweesterbroche'),
                style: Theme.of(sheetContext).textTheme.titleLarge),
            Text(strings.pick(
              'Only its current wearer receives double XP.',
              'Alleen de huidige drager ontvangt dubbele XP.',
            )),
            if (game.twinstarBroochDragonId != null)
              Card(
                child: ListTile(
                  key: const Key('twinstar-unequip'),
                  leading: const Icon(Icons.link_off_rounded),
                  title: Text(strings.pick('Unequip', 'Ontkoppelen')),
                  onTap: () => Navigator.pop(sheetContext, unequipKey),
                ),
              ),
            for (final dragon in game.ownedDragons)
              Card(
                child: ListTile(
                  key: Key('twinstar-equip-${dragon.id}'),
                  leading: SizedBox.square(
                    dimension: 52,
                    child: DragonArt(
                      height: 52,
                      animate: false,
                      stageKey: dragon.stageKey,
                      lineageId: dragon.lineageId,
                      evolutionPath: dragon.activeEvolutionPath,
                      prismatic: dragon.prismatic,
                      sinister: dragon.sinister,
                    ),
                  ),
                  title: Text(dragon.displayName),
                  trailing: game.isTwinstarEquippedOn(dragon.id)
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.twilight)
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(sheetContext, dragon.id),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  await game.equipTwinstarBrooch(choice == unequipKey ? null : choice);
}

class _AnimatedRelicRevealDialog extends StatefulWidget {
  const _AnimatedRelicRevealDialog({
    required this.relic,
    required this.dragon,
  });

  final MysticRelic relic;
  final Pet dragon;

  @override
  State<_AnimatedRelicRevealDialog> createState() =>
      _AnimatedRelicRevealDialogState();
}

class _AnimatedRelicRevealDialogState
    extends State<_AnimatedRelicRevealDialog> {
  Timer? _timer;
  var _frame = 0;
  var _revealed = false;
  var _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    for (var frame = 0; frame < 20; frame++) {
      precacheImage(
          AssetImage(widget.relic.animationFrameAsset(frame)), context);
    }
    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) return;
      if (_frame >= 19) {
        timer.cancel();
        Future<void>.delayed(const Duration(milliseconds: 260), () {
          if (mounted) setState(() => _revealed = true);
        });
        return;
      }
      setState(() => _frame++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finishAnimation() {
    if (_revealed) return;
    _timer?.cancel();
    setState(() {
      _frame = 19;
      _revealed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final value = switch (widget.relic) {
      MysticRelic.moralPrism => strings.moralAxisName(widget.dragon.moralAxis),
      MysticRelic.orderCompass => strings.lawAxisName(widget.dragon.lawAxis),
      MysticRelic.soulMirror =>
        widget.dragon.personalityTraitIds.map(strings.personality).join(' · '),
      MysticRelic.astralLens ||
      MysticRelic.chronoshard ||
      MysticRelic.wayfinderSigil ||
      MysticRelic.twinstarBrooch =>
        '',
    };
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF170E32),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finishAnimation,
        child: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -.25),
                radius: 1.2,
                colors: [Color(0xFF6343A0), Color(0xFF170E32)],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              child: Column(
                children: [
                  SizedBox.square(
                    dimension: 284,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 115),
                      child: Image.asset(
                        widget.relic.animationFrameAsset(_frame),
                        key: ValueKey(_frame),
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _revealed ? 1 : 0,
                    duration: const Duration(milliseconds: 520),
                    child: IgnorePointer(
                      ignoring: !_revealed,
                      child: Column(
                        children: [
                          Text(
                            strings.relicName(widget.relic),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFFE39A),
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox.square(
                            dimension: 112,
                            child: DragonArt(
                              height: 112,
                              animate: true,
                              stageKey: widget.dragon.stageKey,
                              lineageId: widget.dragon.lineageId,
                              evolutionPath: widget.dragon.activeEvolutionPath,
                              prismatic: widget.dragon.prismatic,
                              sinister: widget.dragon.sinister,
                            ),
                          ),
                          Text(
                            widget.dragon.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0x66FFE39A),
                              ),
                            ),
                            child: Text(
                              value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              key: const Key('close-relic-reveal'),
                              onPressed: () => Navigator.pop(context),
                              child: Text(strings.pick(
                                'Remember this',
                                'Onthoud dit',
                              )),
                            ),
                          ),
                        ],
                      ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.kind, required this.text});
  final GameIconKind kind;
  final String text;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity),
            ),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 390),
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF0EAFF)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.mist),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x145B4B8A),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  GameIconSprite(kind, size: 116),
                  const SizedBox(height: 12),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}
