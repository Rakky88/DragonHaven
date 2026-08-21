import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/chest.dart';
import '../models/shop_item.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/furniture_art.dart';
import '../widgets/dragon_art.dart';

class StashScreen extends StatelessWidget {
  const StashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        TabBar(tabs: [
          Tab(text: strings.pick('Eggs', 'Eieren')),
          Tab(text: strings.pick('Chests', 'Kisten')),
          Tab(text: strings.pick('Furniture', 'Meubels')),
        ]),
        const Expanded(
            child: TabBarView(children: [
          _EggStashTab(),
          _ChestStashTab(),
          _FurnitureStashTab(),
        ])),
      ]),
    );
  }
}

class _EggStashTab extends StatelessWidget {
  const _EggStashTab();
  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
    if (game.eggStash.isEmpty) {
      return _EmptyState(
        icon: Icons.egg_alt_outlined,
        text: strings.pick('No Mysterious Eggs in your stash yet.',
            'Nog geen Mysterious Eggs in je voorraad.'),
      );
    }
    return ListView.builder(
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
                  onPressed: game.pet.isEgg
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

class _ChestStashTab extends StatelessWidget {
  const _ChestStashTab();
  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final tiers =
        ChestTier.values.where((tier) => game.chestCount(tier) > 0).toList();
    if (tiers.isEmpty) {
      return _EmptyState(
          icon: Icons.inventory_2_outlined,
          text: strings.pick(
              'Adventure rewards will appear here and on Adventure.',
              'Avontuurbeloningen verschijnen hier en bij Avontuur.'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      children: [
        for (final tier in tiers)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                  backgroundColor:
                      Color(tier.colorValue).withValues(alpha: .15),
                  child: Icon(Icons.inventory_2_rounded,
                      color: Color(tier.colorValue))),
              title: Text(tier.label(strings.isDutch),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text('×${game.chestCount(tier)}'),
              trailing: IconButton(
                tooltip: strings.pick('Discard one chest', 'Eén kist wegdoen'),
                onPressed: () => _discardChest(context, tier),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _discardChest(BuildContext context, ChestTier tier) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.pick('Discard one ${tier.label(false)}?',
                'Eén ${tier.label(true)} wegdoen?')),
            content: Text(strings.pick('Its unopened contents will be lost.',
                'De ongeopende inhoud gaat verloren.')),
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
      await context.read<HouseholdProvider>().discardChest(tier);
    }
  }
}

class _FurnitureStashTab extends StatelessWidget {
  const _FurnitureStashTab();
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
          icon: Icons.chair_outlined,
          text: strings.pick('Your purchased furniture is stored here.',
              'Je gekochte meubels worden hier bewaard.'));
    }
    return GridView.builder(
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
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (game.isEquipped(item))
                  Text(strings.pick('Placed', 'Geplaatst'),
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: strings.pick(
                      'Remove permanently', 'Definitief verwijderen'),
                  onPressed: () => _discard(context, item),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _discard(BuildContext context, ShopItem item) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.pick('Remove ${strings.itemName(item)}?',
            '${strings.itemName(item)} verwijderen?')),
        content: Text(strings.pick(
            'This cannot be undone and gives no coins back.',
            'Dit kan niet ongedaan worden gemaakt en geeft geen munten terug.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.pick('Remove', 'Verwijderen'))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<HouseholdProvider>().discardOwnedItem(item.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted)),
          ]),
        ),
      );
}
