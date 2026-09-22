import 'dart:async';
import '../models/pet.dart';
import '../widgets/dragon_art.dart';
import '../theme/app_theme.dart';
import '../services/canonical_game_snapshot.dart';
import '../models/egg_altar.dart';
import '../widgets/restored_collection_cards.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/chest.dart';
import '../models/mystic_relic.dart';
import '../models/shop_item.dart';
import '../widgets/furniture_art.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/egg_altar_scene.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../services/audio_service.dart';
import '../widgets/chest_reveal.dart';
import '../widgets/shop_economy_scope.dart';
import 'canonical_eggs.dart';
import 'canonical_altar_screen.dart';
import 'canonical_dragons_screen.dart';
import 'canonical_adventures_screen.dart';

/// Server inventory uses nullable public egg facts. It never constructs a
/// legacy egg with a made-up lineage, seed, alignment or eventual dragon.
class CanonicalInventoryScreen extends StatelessWidget {
  const CanonicalInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      ShopEconomyBoundary(child: const _InventoryContents());
}

class _InventoryContents extends StatelessWidget {
  const _InventoryContents();
  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final view = session.snapshot!;
    final strings = AppStrings.of(context);
    return DefaultTabController(
        length: 5,
        child: Column(children: [
          TabBar(
              key: const Key('tutorial-inventory-tabs'),
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              tabs: [
                Tab(
                    key: const Key('inventory-tab-chests'),
                    height: 70,
                    iconMargin: const EdgeInsets.only(bottom: 1),
                    icon: const GameIconSprite(GameIconKind.inventoryChests,
                        size: 35),
                    text: strings.pick('Chests', 'Kisten')),
                Tab(
                    key: const Key('inventory-tab-eggs'),
                    height: 70,
                    iconMargin: const EdgeInsets.only(bottom: 1),
                    icon: const GameIconSprite(GameIconKind.inventoryEggs,
                        size: 35),
                    text: strings.pick('Eggs', 'Eieren')),
                Tab(
                    key: const Key('inventory-tab-altar'),
                    height: 70,
                    iconMargin: const EdgeInsets.only(bottom: 1),
                    icon:
                        Image.asset(EggAltarScene.altar, width: 35, height: 35),
                    text: 'Altar'),
                Tab(
                    key: const Key('inventory-tab-relics'),
                    height: 70,
                    iconMargin: const EdgeInsets.only(bottom: 1),
                    icon: Image.asset(MysticRelic.soulMirror.assetPath,
                        width: 35, height: 35),
                    text: strings.pick('Relics', 'Relieken')),
                Tab(
                    key: const Key('inventory-tab-furniture'),
                    height: 70,
                    iconMargin: const EdgeInsets.only(bottom: 1),
                    icon: const GameIconSprite(GameIconKind.inventoryFurniture,
                        size: 35),
                    text: strings.pick('Furniture', 'Meubels')),
              ]),
          Expanded(
              child: TabBarView(children: [
            ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
                children: [
                  for (final tier
                      in ChestTier.values.where((t) => t != ChestTier.special))
                    if ((view.shop.chests[tier.name] ?? 0) > 0)
                      _ChestRow(
                          tier: tier, count: view.shop.chests[tier.name]!),
                  for (final entry in view.shop.specialChests.entries)
                    if (entry.value > 0)
                      _ChestRow(
                          tier: ChestTier.special,
                          count: entry.value,
                          specialId: entry.key),
                  for (final entry in view.shop.chests.entries)
                    if (entry.value > 0 &&
                        !ChestTier.values.any((tier) =>
                            tier != ChestTier.special &&
                            tier.name == entry.key))
                      _UnrecognizedStock(
                          count: entry.value,
                          label: strings.pick('Chest', 'Kist')),
                  if (view.shop.chests.values.every((n) => n == 0) &&
                      view.shop.specialChests.values.every((n) => n == 0))
                    RestoredCollectionEmpty(
                        icon: GameIconKind.inventoryChests,
                        text: strings.pick('Your chests will appear here.',
                            'Je kisten komen hier te staan.')),
                ]),
            const CanonicalEggList(),
            const CanonicalAltarScreen(),
            ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
                children: [
                  for (final relic in AltarRelic.values)
                    if (view.inventory.count(relic) > 0)
                      RestoredAltarRecipeCard(
                          relic: relic,
                          owned: view.inventory.count(relic),
                          inventoryOnly: true,
                          onUse: () => relic == AltarRelic.nameweaversQuill
                              ? Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                      builder: (_) => Scaffold(
                                          appBar:
                                              AppBar(title: Text(relic.label)),
                                          body:
                                              const CanonicalDragonsScreen())))
                              : showCanonicalAltarRelicPicker(context, relic)),
                  for (final relic in MysticRelic.values)
                    if ((view.shop.relics[relic.name] ?? 0) > 0)
                      RestoredRelicCard(
                        relic: relic,
                        count: view.shop.relics[relic.name]!,
                        detail: relic == MysticRelic.chronoshard
                            ? view.inventory.chronoshards
                                .map((n) => '$n%')
                                .join(' · ')
                            : relic.isEquipable
                                ? strings.pick(
                                    view.inventory.equipment.containsKey(relic)
                                        ? 'Equipped to a dragon'
                                        : 'Not equipped',
                                    view.inventory.equipment.containsKey(relic)
                                        ? 'Aan een draak gekoppeld'
                                        : 'Niet gekoppeld')
                                : null,
                        canUse: session.canAct &&
                            (view.inventory.usableRelics[relic] ?? 0) > 0,
                        onUse: () => _useCanonicalRelic(context, relic),
                      ),
                  for (final entry in view.shop.relics.entries)
                    if (entry.value > 0 &&
                        !MysticRelic.values.any((r) => r.name == entry.key))
                      _UnrecognizedStock(
                          count: entry.value,
                          label: strings.pick('Relic', 'Reliek')),
                  if (view.shop.relics.values.every((n) => n == 0) &&
                      AltarRelic.values
                          .every((r) => view.inventory.count(r) == 0))
                    RestoredRelicEmptyState(strings: strings),
                ]),
            const _FurnitureInventoryTab(),
          ])),
        ]));
  }
}

class _UnrecognizedStock extends StatelessWidget {
  const _UnrecognizedStock({required this.count, required this.label});
  final int count;
  final String label;
  @override
  Widget build(BuildContext context) => Card(
          child: ListTile(
        title: Text(label),
        trailing: Text('$count'),
        subtitle: Text(AppStrings.of(context).pick(
            'Update the app to use this item.',
            'Werk de app bij om dit voorwerp te gebruiken.')),
      ));
}

class _ChestRow extends StatelessWidget {
  const _ChestRow({required this.tier, required this.count, this.specialId});
  final ChestTier tier;
  final int count;
  final String? specialId;
  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final view = session.snapshot!;
    final strings = AppStrings.of(context);
    final special = specialChestById(specialId);
    final reserved = view.shop.reservedChests[specialId ?? tier.name] ?? 0;
    final available = max(0, count - reserved);
    final known = specialId == null || special != null;
    final label = special == null
        ? strings.chestLabel(tier)
        : strings.pick(special.titleEn, special.titleNl);
    final actions = CanonicalGameActions(session);
    void open(int quantity) => showChestReveal(context, tier,
        quantity: quantity,
        displayName: label,
        closedAssetPath: special?.closedAssetPath,
        openedAssetPath: special?.openedAssetPath,
        onOpen: special == null
            ? null
            : () => HavenAudio.playAsset(
                  special.id == 'golden_wings_chest_v1'
                      ? HavenSound.chestSpecial.assetId
                      : 'event_${special.openSoundId}_chest',
                ),
        openChest: () => actions.openChests(tier,
            count: quantity, specialChestId: specialId));
    return RestoredChestCard(
        assetPath: special?.closedAssetPath ?? tier.assetPath,
        color: Color(tier.colorValue),
        title: label,
        count: count,
        openKey: Key('canonical-open-${specialId ?? tier.name}'),
        openTenKey: Key('canonical-open-ten-${specialId ?? tier.name}'),
        canOpen: session.canAct && known && available > 0,
        canOpenTen: session.canAct && known && available >= 10,
        onOpen: () => open(1),
        onOpenTen: () => open(10));
  }
}

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
    final game = context.watch<CanonicalGameSession>().snapshot!;
    final strings = AppStrings.of(context);
    final ownedItems = game.shop.ownedItems
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
            (!_placedOnly || game.shop.placedItems.contains(item.id)))
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
                              if (game.shop.placedItems.contains(item.id))
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
                            trailing: game.shop.placedItems.contains(item.id)
                                ? Icon(Icons.check_circle_rounded,
                                    color: AppColors.eventColor(
                                        context, AppColors.twilight))
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
    CanonicalGameSnapshot game,
  ) async {
    final strings = AppStrings.of(context);
    final ownedItems =
        game.shop.ownedItems.map(shopItemById).whereType<ShopItem>();
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
                  border: Border.all(
                      color: AppColors.eventColor(context, AppColors.mist)),
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

class _InventoryControlChip extends StatelessWidget {
  const _InventoryControlChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.eventColor(context, const Color(0xFFF1ECFB)),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 17,
                color: AppColors.eventColor(context, AppColors.twilight)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.eventColor(context, AppColors.twilight),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

Future<void> _useCanonicalRelic(BuildContext context, MysticRelic relic) async {
  final session = context.read<CanonicalGameSession>();
  final view = session.snapshot;
  if (view == null || !session.canAct) return;
  final actions = CanonicalGameActions(session);
  final strings = AppStrings.of(context);
  bool current() =>
      context.mounted &&
      session.connection.sessionEpoch == actions.epoch &&
      session.snapshot?.ownerId == view.ownerId;
  if (relic == MysticRelic.astralLens) {
    final eggs = view.eggs
        .where((egg) =>
            egg.revealedRarity == null &&
            !view.inventory.reservedEggIds.contains(egg.id))
        .toList();
    if (eggs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(strings.pick('There is no egg with an unknown rarity.',
              'Er is geen ei waarvan de zeldzaamheid nog onbekend is.'))));
      return;
    }
    final selected = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (c) => SafeArea(
                child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
                    children: [
                  Text(strings.pick('Reveal which egg?', 'Welk ei onthullen?'),
                      style: Theme.of(c).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  for (final egg in eggs)
                    Card(
                        child: ListTile(
                            key: Key('astral-lens-egg-${egg.id}'),
                            leading: const GameIconSprite(
                                GameIconKind.mysteriousEgg,
                                size: 42),
                            title: Text(egg.location == 'nest'
                                ? strings.pick(
                                    'Egg in the nest', 'Ei in het nest')
                                : strings.pick(
                                    'Inventory egg', 'Ei in inventaris')),
                            subtitle: Text(strings.pick(
                                'Rarity is still hidden',
                                'Zeldzaamheid is nog verborgen')),
                            onTap: () => Navigator.pop(c, egg.id))),
                ])));
    if (!context.mounted || !current() || selected == null) return;
    await runShopAction(context, () async {
      await actions.useLens(selected);
      if (!context.mounted || !current()) return;
      final rarity = session.snapshot?.egg(selected)?.revealedRarity;
      if (rarity == null) return;
      await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
                  icon: Image.asset(relic.assetPath, width: 92, height: 92),
                  title: Text(
                      strings.pick('Rarity revealed', 'Zeldzaamheid onthuld')),
                  content: Text(canonicalKnownRarity(strings, rarity),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 20)),
                  actions: [
                    FilledButton(
                        onPressed: () => Navigator.pop(c),
                        child: Text(strings.pick('Done', 'Klaar')))
                  ]));
    });
    return;
  }
  if (relic == MysticRelic.chronoshard) {
    if (view.nest == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(strings.pick('Place an egg in the rooftop nest first.',
              'Plaats eerst een ei in het daknest.'))));
      return;
    }
    final values = view.inventory.chronoshards;
    final selected = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        builder: (c) => SafeArea(
                child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
                    children: [
                  Text(
                      strings.pick(
                          'Choose a Chronoshard', 'Kies een Chronoscherf'),
                      style: Theme.of(c).textTheme.titleLarge),
                  Text(strings.pick(
                      'Its percentage was fixed when this relic was found.',
                      'Het percentage werd vastgelegd toen dit reliek werd gevonden.')),
                  const SizedBox(height: 8),
                  for (var index = 0; index < values.length; index++)
                    Card(
                        child: ListTile(
                            key: Key('chronoshard-${values[index]}-$index'),
                            leading: Image.asset(relic.assetPath,
                                width: 48, height: 48),
                            title: Text('${values[index]}%',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900)),
                            subtitle: Text(strings.pick(
                                'Shorten remaining incubation',
                                'Verkort de resterende broedtijd')),
                            onTap: () => Navigator.pop(c, values[index]))),
                ])));
    if (!context.mounted || !current() || selected == null) return;
    await runShopAction(context, () async {
      await actions.useChronoshard(selected);
      if (!context.mounted || !current()) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(strings.pick(
              'Remaining incubation shortened by $selected%.',
              'Resterende broedtijd met $selected% verkort.'))));
    });
    return;
  }
  if (relic.isEquipable) {
    const unequip = '__unequip__';
    final selected = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (c) => FractionallySizedBox(
            heightFactor: .72,
            child: SafeArea(
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
                    children: [
                  Text(strings.relicName(relic),
                      style: Theme.of(c).textTheme.titleLarge),
                  Text(strings.relicDescription(relic)),
                  Text(strings.pick(
                      'Equipping replaces the dragon’s current brooch.',
                      'Uitrusten vervangt de huidige broche van de draak.')),
                  if (view.inventory.equipment.containsKey(relic))
                    Card(
                        child: ListTile(
                            key: Key('${relic.name}-unequip'),
                            leading: const Icon(Icons.link_off_rounded),
                            title: Text(strings.pick('Unequip', 'Ontkoppelen')),
                            onTap: () => Navigator.pop(c, unequip))),
                  for (final dragon in view.dragons.where((d) => d.owned))
                    Card(
                        child: ListTile(
                            key: Key('${relic.name}-equip-${dragon.id}'),
                            leading: SizedBox.square(
                                dimension: 52,
                                child: DragonArt(
                                    height: 52,
                                    animate: false,
                                    stageKey: dragon.stageKey,
                                    lineageId: dragon.lineageId,
                                    evolutionPath: dragon.activeEvolutionPath,
                                    prismatic: dragon.prismatic,
                                    sinister: dragon.sinister)),
                            title: Text(dragon.displayName),
                            trailing:
                                view.inventory.equippedOn(dragon.id) == relic
                                    ? Icon(Icons.check_circle_rounded,
                                        color: AppColors.eventColor(
                                            context, AppColors.twilight))
                                    : const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.pop(c, dragon.id))),
                ]))));
    if (!context.mounted || !current() || selected == null) return;
    await runShopAction(context,
        () => actions.equip(relic, selected == unequip ? null : selected));
    return;
  }
  if (relic.hasUseAnimation) {
    await showCanonicalDragonRelic(context, relic);
    return;
  }
  await Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (_) => Scaffold(
              appBar: AppBar(title: Text(strings.relicName(relic))),
              body: relic == MysticRelic.wayfinderSigil
                  ? const CanonicalAdventuresScreen()
                  : const CanonicalDragonsScreen())));
}

Future<void> showCanonicalDragonRelic(
  BuildContext context,
  MysticRelic relic,
) async {
  final session = context.read<CanonicalGameSession>();
  final view = session.snapshot;
  if (view == null || !session.canAct) return;
  final actions = CanonicalGameActions(session);
  final strings = AppStrings.of(context);
  final eligibleDragons = view.dragons
      .where((d) => d.owned)
      .where((dragon) => !dragon.knows(relic))
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
  final selected = await showModalBottomSheet<CanonicalDragonView>(
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
            for (final dragon in view.dragons.where((d) => d.owned))
              Card(
                child: ListTile(
                  key: Key('relic-dragon-choice-${dragon.id}'),
                  enabled: !dragon.knows(relic),
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
                    dragon.knows(relic)
                        ? strings.pick('Already revealed', 'Al onthuld')
                        : strings.pick(
                            'Secret still hidden', 'Geheim nog verborgen'),
                  ),
                  trailing: dragon.knows(relic)
                      ? Icon(Icons.check_circle_rounded,
                          color:
                              AppColors.eventColor(context, AppColors.twilight))
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: dragon.knows(relic)
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
  await runShopAction(context, () async {
    await actions.useRelic(relic, selected.id);
    if (!context.mounted ||
        session.connection.sessionEpoch != actions.epoch ||
        session.snapshot?.ownerId != view.ownerId) {
      return;
    }
    final dragon = session.snapshot?.dragon(selected.id);
    if (dragon == null || !dragon.knows(relic)) return;
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            _AnimatedRelicRevealDialog(relic: relic, dragon: dragon));
  });
}

class _AnimatedRelicRevealDialog extends StatefulWidget {
  const _AnimatedRelicRevealDialog({
    required this.relic,
    required this.dragon,
  });

  final MysticRelic relic;
  final CanonicalDragonView dragon;

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
    if (MediaQuery.disableAnimationsOf(context)) {
      _frame = 19;
      _revealed = true;
      return;
    }
    for (var frame = 0;
        frame < (widget.relic.usesFrameSequence ? 20 : 1);
        frame++) {
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
      MysticRelic.sparkAstrolabe =>
        "${strings.pick('Dragon Spark', 'Drakenvonk')}: +${widget.dragon.dragonSpark}",
      MysticRelic.moralPrism => strings
          .moralAxisName(MoralAxis.values.byName(widget.dragon.moralAxis!)),
      MysticRelic.orderCompass =>
        strings.lawAxisName(LawAxis.values.byName(widget.dragon.lawAxis!)),
      MysticRelic.soulMirror =>
        widget.dragon.personality!.map(strings.personality).join(' · '),
      MysticRelic.astralLens ||
      MysticRelic.chronoshard ||
      MysticRelic.wayfinderSigil ||
      MysticRelic.twinstarBrooch ||
      MysticRelic.emberheartBrooch ||
      MysticRelic.moonweaveBrooch ||
      MysticRelic.soulbloomBrooch =>
        '',
    };
    return Dialog.fullscreen(
      backgroundColor: AppColors.eventColor(context, const Color(0xFF170E32)),
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
                    child: widget.relic == MysticRelic.sparkAstrolabe
                        ? AnimatedScale(
                            scale: _revealed ? 1 : .84 + _frame / 19 * .16,
                            duration: const Duration(milliseconds: 120),
                            child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: const Color(0xFFDAA7FF)
                                              .withValues(
                                                  alpha:
                                                      .08 + _frame / 19 * .20),
                                          blurRadius: 35 + _frame * 2,
                                          spreadRadius: 4)
                                    ]),
                                child: Image.asset(widget.relic.assetPath,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high)))
                        : AnimatedSwitcher(
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
