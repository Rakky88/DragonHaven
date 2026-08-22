import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/chest.dart';
import '../models/shop_item.dart';
import '../providers/household_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chest_reveal.dart';
import '../widgets/furniture_art.dart';
import '../widgets/dragon_art.dart';
import '../widgets/game_icon_sprite.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        TabBar(tabs: [
          Tab(
            height: 70,
            icon: const GameIconSprite(GameIconKind.inventoryEggs, size: 35),
            iconMargin: const EdgeInsets.only(bottom: 1),
            text: strings.pick('Eggs', 'Eieren'),
          ),
          Tab(
            height: 70,
            icon: const GameIconSprite(GameIconKind.inventoryChests, size: 35),
            iconMargin: const EdgeInsets.only(bottom: 1),
            text: strings.pick('Chests', 'Kisten'),
          ),
          Tab(
            height: 70,
            icon:
                const GameIconSprite(GameIconKind.inventoryFurniture, size: 35),
            iconMargin: const EdgeInsets.only(bottom: 1),
            text: strings.pick('Furniture', 'Meubels'),
          ),
        ]),
        const Expanded(
            child: TabBarView(children: [
          _EggInventoryTab(),
          _ChestInventoryTab(),
          _FurnitureInventoryTab(),
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
    return ListView.builder(
      key: const PageStorageKey('inventory-eggs-scroll'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      itemCount: game.eggStash.length,
      itemBuilder: (context, index) {
        final egg = game.eggStash[index];
        return Card(
          child: ListTile(
            leading: const SizedBox.square(
                dimension: 62,
                child:
                    DragonArt(height: 62, animate: false, stageKey: 'moonEgg')),
            title: Text(strings.pick('Mysterious Egg', 'Mysterieus Ei'),
                style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(strings.pick(
                'Something is moving inside… · Incubates 2–14 days once placed.',
                'Er beweegt iets binnenin… · Broedt 2–14 dagen nadat het geplaatst is.')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: strings.pick('Discard egg', 'Ei wegdoen'),
                  onPressed: () => _discardEgg(context, egg.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
                FilledButton(
                  onPressed: game.hasEggInNest
                      ? null
                      : () async {
                          final ok = await game.activateEgg(egg.id);
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(strings.pick(
                                    'Egg moved to the rooftop nest.',
                                    'Ei naar het daknest verplaatst.'))));
                          }
                        },
                  child: Text(strings.pick('Incubate', 'Broed uit')),
                ),
              ],
            ),
          ),
        );
      },
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
                  onPressed: () => _openChest(context, tier),
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
    final reward = await context.read<HouseholdProvider>().openChest(tier);
    if (reward == null || !navigator.mounted) return;
    unawaited(HavenAudio.play(_soundForChest(tier)));
    await showChestReveal(navigator.context, reward);
  }
}

HavenSound _soundForChest(ChestTier tier) => switch (tier) {
      ChestTier.wooden => HavenSound.chestWooden,
      ChestTier.silver => HavenSound.chestSilver,
      ChestTier.gold => HavenSound.chestGold,
      ChestTier.dragon => HavenSound.chestDragon,
      ChestTier.mythical => HavenSound.chestMythical,
      ChestTier.sinister => HavenSound.chestSinister,
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
