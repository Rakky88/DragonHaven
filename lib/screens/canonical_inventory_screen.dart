import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/chest.dart';
import '../models/mystic_relic.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../widgets/chest_reveal.dart';
import '../widgets/shop_economy_scope.dart';
import 'canonical_eggs.dart';
import 'canonical_altar_screen.dart';
import 'canonical_dragons_screen.dart';

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
        length: 4,
        child: Column(children: [
          TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [
            Tab(text: strings.pick('Chests', 'Kisten')),
            Tab(text: strings.pick('Eggs', 'Eieren')),
            Tab(text: strings.pick('Relics', 'Relieken')),
            const Tab(text: 'Altar'),
          ]),
          Expanded(
              child: TabBarView(children: [
            ListView(padding: const EdgeInsets.all(16), children: [
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
            ListView(padding: const EdgeInsets.all(16), children: [
              for (final relic in MysticRelic.values)
                if ((view.shop.relics[relic.name] ?? 0) > 0)
                  Card(
                      child: ListTile(
                    leading:
                        Image.asset(relic.assetPath, width: 44, height: 44),
                    title: Text(strings.relicName(relic)),
                    subtitle: Text(strings.relicDescription(relic)),
                    trailing: Text('${view.shop.relics[relic.name]}'),
                    onTap: relic == MysticRelic.wayfinderSigil
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => Scaffold(
                                    appBar: AppBar(
                                        title: Text(strings.relicName(relic))),
                                    body: relic.isEquipable ||
                                            relic.hasUseAnimation
                                        ? const CanonicalDragonsScreen()
                                        : const ShopEconomyBoundary(
                                            child: CanonicalEggList())))),
                  )),
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
            const CanonicalAltarScreen(),
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
            child: Row(children: [
              Image.asset(special?.closedAssetPath ?? tier.assetPath,
                  width: 64, height: 64),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                  ])),
            ])));
  }
}
