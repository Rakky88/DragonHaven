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
import 'canonical_house_screen.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
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
          TabBar(isScrollable: true, tabAlignment: TabAlignment.center, tabs: [
            Tab(
                height: 70,
                icon: const GameIconSprite(GameIconKind.inventoryChests,
                    size: 35),
                text: strings.pick('Chests', 'Kisten')),
            Tab(
                height: 70,
                icon:
                    const GameIconSprite(GameIconKind.inventoryEggs, size: 35),
                text: strings.pick('Eggs', 'Eieren')),
            Tab(
                height: 70,
                icon: Image.asset(EggAltarScene.altar, width: 35, height: 35),
                text: 'Altar'),
            Tab(
                height: 70,
                icon: Image.asset(MysticRelic.soulMirror.assetPath,
                    width: 35, height: 35),
                text: strings.pick('Relics', 'Relieken')),
            Tab(
                height: 70,
                icon: const GameIconSprite(GameIconKind.inventoryFurniture,
                    size: 35),
                text: strings.pick('Furniture', 'Meubels')),
          ]),
          Expanded(
              child: TabBarView(children: [
            _InventoryGallery(children: [
              for (final tier
                  in ChestTier.values.where((t) => t != ChestTier.special))
                if ((view.shop.chests[tier.name] ?? 0) > 0)
                  _ChestRow(tier: tier, count: view.shop.chests[tier.name]!),
              for (final entry in view.shop.specialChests.entries)
                if (entry.value > 0)
                  _ChestRow(
                      tier: ChestTier.special,
                      count: entry.value,
                      specialId: entry.key),
              for (final entry in view.shop.chests.entries)
                if (entry.value > 0 &&
                    !ChestTier.values.any((tier) =>
                        tier != ChestTier.special && tier.name == entry.key))
                  _UnrecognizedStock(
                      count: entry.value, label: strings.pick('Chest', 'Kist')),
              if (view.shop.chests.values.every((n) => n == 0) &&
                  view.shop.specialChests.values.every((n) => n == 0))
                Text(strings.pick('Your chests will appear here.',
                    'Je kisten komen hier te staan.')),
            ]),
            const CanonicalEggList(),
            const CanonicalAltarScreen(),
            _InventoryGallery(children: [
              for (final relic in MysticRelic.values)
                if ((view.shop.relics[relic.name] ?? 0) > 0)
                  _InventoryTile(
                    art: Image.asset(relic.assetPath, width: 100, height: 100),
                    title: strings.relicName(relic),
                    subtitle: '${view.shop.relics[relic.name]}',
                    description: strings.relicDescription(relic),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => Scaffold(
                                appBar: AppBar(
                                    title: Text(strings.relicName(relic))),
                                body: relic == MysticRelic.wayfinderSigil
                                    ? const CanonicalAdventuresScreen()
                                    : relic.isEquipable || relic.hasUseAnimation
                                        ? const CanonicalDragonsScreen()
                                        : const ShopEconomyBoundary(
                                            child: CanonicalEggList())))),
                  ),
              for (final entry in view.shop.relics.entries)
                if (entry.value > 0 &&
                    !MysticRelic.values.any((r) => r.name == entry.key))
                  _UnrecognizedStock(
                      count: entry.value,
                      label: strings.pick('Relic', 'Reliek')),
              if (view.shop.relics.values.every((n) => n == 0))
                Text(strings.pick('Your relics will appear here.',
                    'Je relieken komen hier te staan.')),
            ]),
            _InventoryGallery(children: [
              for (final id in view.shop.ownedItems)
                if (shopItemById(id) case final item?)
                  _InventoryTile(
                    art: SizedBox.square(
                        dimension: 100, child: FurnitureArt(item: item)),
                    title: strings.pick(item.name, item.nameNl),
                    subtitle: view.shop.placedItems.contains(id)
                        ? strings.pick(
                            'Placed in your tower', 'In je toren geplaatst')
                        : strings.pick(
                            'Ready to place', 'Klaar om te plaatsen'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => Scaffold(
                                appBar: AppBar(
                                    title:
                                        Text(strings.pick('Tower', 'Toren'))),
                                body: const CanonicalHouseScreen()))),
                  ),
            ]),
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
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Image.asset(special?.closedAssetPath ?? tier.assetPath,
                  width: 120, height: 120),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                Text('$count'),
                FilledButton(
                  key: Key('canonical-open-${specialId ?? tier.name}'),
                  onPressed: session.canAct && known && available > 0
                      ? () {
                          final actions = CanonicalGameActions(session);
                          showChestReveal(
                            context,
                            tier,
                            displayName: label,
                            closedAssetPath: special?.closedAssetPath,
                            openedAssetPath: special?.openedAssetPath,
                            openChest: () => actions.openChests(tier,
                                specialChestId: specialId),
                          );
                        }
                      : null,
                  child: Text(strings.pick('Open', 'Openen')),
                ),
              ]),
            ])));
  }
}

class _InventoryGallery extends StatelessWidget {
  const _InventoryGallery({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: LayoutBuilder(builder: (context, box) {
        final columns = box.maxWidth >= 540 ? 3 : 2;
        return Wrap(spacing: 10, runSpacing: 10, children: [
          for (final child in children)
            SizedBox(
                width: (box.maxWidth - 10 * (columns - 1)) / columns,
                child: child),
        ]);
      }));
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile(
      {required this.art,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.description});
  final Widget art;
  final String title, subtitle;
  final String? description;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: description == null
              ? onTap
              : () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (context) => SafeArea(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            art,
                            Text(title,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 12),
                            Text(description!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onTap();
                                },
                                child: Text(AppStrings.of(context)
                                    .pick('Use', 'Gebruiken'))),
                          ])))),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                art,
                const SizedBox(height: 8),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, textAlign: TextAlign.center),
              ]))));
}
