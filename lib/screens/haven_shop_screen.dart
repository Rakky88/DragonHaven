import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/shop_item.dart';
import '../theme/app_theme.dart';
import '../widgets/game_icon_sprite.dart';
import 'shop_screen.dart';

class HavenShopScreen extends StatelessWidget {
  const HavenShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        TabBar(tabs: [
          Tab(text: strings.pick('Coin furniture', 'Muntenmeubels')),
          Tab(text: strings.pick('Gem furniture', 'Edelsteenmeubels')),
          Tab(text: strings.pick('Buy gems', 'Edelstenen kopen')),
        ]),
        const Expanded(
          child: TabBarView(children: [
            ShopScreen(),
            ShopScreen(currency: ItemCurrency.gems),
            _GemPacks(),
          ]),
        ),
      ]),
    );
  }
}

class _GemPacks extends StatelessWidget {
  const _GemPacks();
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    const packs = [50, 120, 280, 650, 1500, 3500];
    return ListView(
      key: const PageStorageKey('gem-packs-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF2D8),
              borderRadius: BorderRadius.circular(16)),
          child: Text(
              strings.pick(
                  'Purchases are disabled until Google Play product IDs and server-side receipt validation are configured.',
                  'Aankopen staan uit totdat Google Play-product-ID’s en servercontrole van betaalbewijzen zijn ingesteld.'),
              style: const TextStyle(fontSize: 12)),
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < packs.length; index++)
          Card(
            child: ListTile(
              leading: const GameIconSprite(GameIconKind.gem, size: 42),
              title: Text('${packs[index]} ${strings.tr('gems')}',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(strings.pick(
                  'Pack ${index + 1} of 6', 'Pakket ${index + 1} van 6')),
              trailing: const Icon(Icons.lock_rounded, color: AppColors.muted),
            ),
          ),
      ],
    );
  }
}
