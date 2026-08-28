import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/chest.dart';
import '../models/dragon_egg.dart';
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

class _EggInventoryTab extends StatelessWidget {
  const _EggInventoryTab();

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
    if (game.eggStash.isEmpty) {
      return _EmptyState(
        kind: GameIconKind.inventoryEggs,
        text: strings.pick('No Mysterious Eggs in your inventory yet.',
            'Nog geen Mysterious Eggs in je inventaris.'),
      );
    }
    final eggs = [...game.eggStash]
      ..sort((a, b) => b.acquiredAt.compareTo(a.acquiredAt));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 8),
          child: Row(
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
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.pick(
                    'Tap an egg for its clue and actions.',
                    'Tik op een ei voor de hint en acties.',
                  ),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
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
                          strings.pick('Mysterious Egg', 'Mysterieus Ei'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          strings.remainingDuration(egg.incubationDuration),
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
                strings.pick('Mysterious Egg', 'Mysterieus Ei'),
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
                            await _discardEgg(context, egg.id);
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

  Future<void> _discardEgg(BuildContext context, String eggId) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: Text(strings.pick(
                'Discard this Mysterious Egg?', 'Dit Mysterious Egg wegdoen?')),
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
      await context.read<HouseholdProvider>().discardEgg(eggId);
    }
  }
}

class _ChestInventoryTab extends StatelessWidget {
  const _ChestInventoryTab();
  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final tiers =
        ChestTier.values.where((tier) => game.chestCount(tier) > 0).toList();
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
                FilledButton(
                  key: Key('inventory-open-chest-${tier.name}'),
                  onPressed: game.tradeableChestCount(tier) > 0
                      ? () => _openChest(context, tier)
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 12,
                    ),
                  ),
                  child: Text(strings.pick('Open', 'Openen')),
                ),
              ]),
            ),
          ),
      ],
    );
  }

  Future<void> _openChest(BuildContext context, ChestTier tier) async {
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
    await showChestReveal(
      navigator.context,
      tier,
      openChest: () => game.openChest(tier),
      onOpen: () => HavenAudio.play(_soundForChest(tier)),
    );
  }
}

HavenSound _soundForChest(ChestTier tier) => switch (tier) {
      ChestTier.wooden => HavenSound.chestWooden,
      ChestTier.silver => HavenSound.chestSilver,
      ChestTier.gold => HavenSound.chestGold,
      ChestTier.dragon => HavenSound.chestDragon,
      ChestTier.mythical => HavenSound.chestMythical,
      ChestTier.sinister => HavenSound.chestSinister,
      ChestTier.portrait || ChestTier.title => HavenSound.chestMythical,
    };

class _FurnitureInventoryTab extends StatelessWidget {
  const _FurnitureInventoryTab();
  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final items = game.ownedItemIds
        .map(shopItemById)
        .whereType<ShopItem>()
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    if (items.isEmpty) {
      return _EmptyState(
          kind: GameIconKind.inventoryFurniture,
          text: strings.pick('Your purchased furniture is stored here.',
              'Je gekochte meubels worden hier bewaard.'));
    }
    return GridView.builder(
      key: const PageStorageKey('inventory-furniture-scroll'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: .92,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              Expanded(child: FurnitureArt(item: item)),
              Text(strings.itemName(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              if (game.isEquipped(item))
                Text(strings.pick('Placed', 'Geplaatst'),
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 11)),
            ]),
          ),
        );
      },
    );
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
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
      );
}
