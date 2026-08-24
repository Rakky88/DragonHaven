import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/chest.dart';
import '../models/shop_item.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/ui_bits.dart';
import 'shop_screen.dart';

class ShopHubScreen extends StatelessWidget {
  const ShopHubScreen({
    super.key,
    this.initialCurrencyTab = 0,
    this.initialCategoryTab = 0,
  });

  final int initialCurrencyTab;
  final int initialCategoryTab;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return DefaultTabController(
      length: 2,
      initialIndex: initialCurrencyTab,
      child: Column(
        children: [
          TabBar(
            key: const Key('shop-currency-tabs'),
            tabs: [
              Tab(
                key: const Key('shop-tab-coins'),
                icon: const GameIconSprite(GameIconKind.coin, size: 35),
                text: strings.pick('Coins', 'Munten'),
              ),
              Tab(
                key: const Key('shop-tab-gems'),
                icon: const GameIconSprite(GameIconKind.gem, size: 35),
                text: strings.pick('Gems', 'Edelstenen'),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _CurrencyShop(
                  currency: ItemCurrency.coins,
                  initialCategoryTab: initialCategoryTab,
                ),
                _CurrencyShop(
                  currency: ItemCurrency.gems,
                  initialCategoryTab: initialCategoryTab,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyShop extends StatelessWidget {
  const _CurrencyShop({
    required this.currency,
    required this.initialCategoryTab,
  });

  final ItemCurrency currency;
  final int initialCategoryTab;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return DefaultTabController(
      length: 3,
      initialIndex: initialCategoryTab,
      child: Column(
        children: [
          Material(
            color: const Color(0xFFF3EEFA),
            child: TabBar(
              key: Key('shop-${currency.name}-category-tabs'),
              labelStyle: const TextStyle(fontWeight: FontWeight.w900),
              tabs: [
                Tab(
                  key: Key('shop-${currency.name}-tab-furniture'),
                  text: strings.pick('Furniture', 'Meubels'),
                ),
                Tab(
                  key: Key('shop-${currency.name}-tab-chests'),
                  text: strings.pick('Chests', 'Kisten'),
                ),
                Tab(
                  key: Key('shop-${currency.name}-tab-buy'),
                  text: strings.pick('Buy', 'Kopen'),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ShopScreen(currency: currency),
                _ChestShop(currency: currency),
                _CurrencyPacks(currency: currency),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ChestPurchaseOutcome { purchased, insufficientFunds, collectionComplete }

class _ChestShop extends StatelessWidget {
  const _ChestShop({required this.currency});

  final ItemCurrency currency;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final portraitChest = currency == ItemCurrency.gems;
    final tier = portraitChest ? ChestTier.portrait : ChestTier.title;
    final complete = portraitChest ? game.hasEveryPortrait : game.hasEveryTitle;
    final price = portraitChest ? portraitChestGemPrice : titleChestCoinPrice;
    final currencyKind = portraitChest ? GameIconKind.gem : GameIconKind.coin;
    return ListView(
      key: PageStorageKey('shop-${currency.name}-chests-scroll'),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2B185B), Color(0xFF6B3FA0)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x443C236F),
                blurRadius: 26,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Image.asset(
                tier.assetPath,
                width: 238,
                height: 190,
                fit: BoxFit.contain,
              ),
              Text(
                strings.chestLabel(tier),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                strings.pick(
                  portraitChest
                      ? 'Contains one random portrait you do not own. Its contents are decided only when opened.'
                      : 'Contains one random account title you do not own. Its contents are decided only when opened.',
                  portraitChest
                      ? 'Bevat één willekeurig portret dat je nog niet bezit. De inhoud wordt pas bij het openen bepaald.'
                      : 'Bevat één willekeurige accounttitel die je nog niet bezit. De inhoud wordt pas bij het openen bepaald.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE2D8F5),
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: Key('buy-${tier.name}-chest'),
                  onPressed: () => _buy(context, portraitChest: portraitChest),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE39A),
                    foregroundColor: const Color(0xFF29184C),
                    disabledBackgroundColor: const Color(0xFF7F7394),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: complete
                      ? Text(strings.pick(
                          'Collection complete',
                          'Collectie compleet',
                        ))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GameIconSprite(currencyKind, size: 29),
                            const SizedBox(width: 7),
                            Text(
                              '$price',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _buy(
    BuildContext context, {
    required bool portraitChest,
  }) async {
    final game = context.read<HouseholdProvider>();
    final _ChestPurchaseOutcome result;
    if (portraitChest) {
      result = switch (await game.purchasePortraitChest()) {
        PortraitChestPurchaseResult.purchased =>
          _ChestPurchaseOutcome.purchased,
        PortraitChestPurchaseResult.insufficientGems =>
          _ChestPurchaseOutcome.insufficientFunds,
        PortraitChestPurchaseResult.collectionComplete =>
          _ChestPurchaseOutcome.collectionComplete,
      };
    } else {
      result = switch (await game.purchaseTitleChest()) {
        TitleChestPurchaseResult.purchased => _ChestPurchaseOutcome.purchased,
        TitleChestPurchaseResult.insufficientCoins =>
          _ChestPurchaseOutcome.insufficientFunds,
        TitleChestPurchaseResult.collectionComplete =>
          _ChestPurchaseOutcome.collectionComplete,
      };
    }
    if (!context.mounted) return;
    final strings = AppStrings.of(context);
    final tier = portraitChest ? ChestTier.portrait : ChestTier.title;
    if (result == _ChestPurchaseOutcome.collectionComplete) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Image.asset(
            tier.assetPath,
            width: 92,
            height: 92,
          ),
          title: Text(strings.pick(
            'Collection complete',
            'Collectie compleet',
          )),
          content: Text(strings.pick(
            portraitChest
                ? 'You already own all 100 portraits, so another Portrait Chest cannot be purchased.'
                : 'You already own all 500 account titles, so another Title Chest cannot be purchased.',
            portraitChest
                ? 'Je bezit alle 100 portretten al, dus je kunt geen nieuwe Portretkist kopen.'
                : 'Je bezit alle 500 accounttitels al, dus je kunt geen nieuwe Titelkist kopen.',
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
    final message = switch (result) {
      _ChestPurchaseOutcome.purchased => strings.pick(
          portraitChest
              ? 'Portrait Chest added to your Inventory.'
              : 'Title Chest added to your Inventory.',
          portraitChest
              ? 'Portretkist toegevoegd aan je Inventory.'
              : 'Titelkist toegevoegd aan je Inventory.',
        ),
      _ChestPurchaseOutcome.insufficientFunds => strings.pick(
          portraitChest
              ? '${portraitChestGemPrice - game.pet.gems} more gems needed.'
              : '${titleChestCoinPrice - game.pet.coins} more coins needed.',
          portraitChest
              ? 'Nog ${portraitChestGemPrice - game.pet.gems} edelstenen nodig.'
              : 'Nog ${titleChestCoinPrice - game.pet.coins} munten nodig.',
        ),
      _ChestPurchaseOutcome.collectionComplete => '',
    };
    showAppSnackBar(context, message);
  }
}

class _CurrencyPacks extends StatelessWidget {
  const _CurrencyPacks({required this.currency});

  final ItemCurrency currency;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final packs = currency == ItemCurrency.coins
        ? const [500, 1200, 2800, 6500, 15000, 35000]
        : const [50, 120, 280, 650, 1500, 3500];
    final label = currency == ItemCurrency.coins
        ? strings.pick('coins', 'munten')
        : strings.tr('gems');
    final kind =
        currency == ItemCurrency.coins ? GameIconKind.coin : GameIconKind.gem;
    return ListView(
      key: PageStorageKey('${currency.name}-packs-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2D8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            strings.pick(
              'Purchases are disabled until Google Play product IDs and server-side receipt validation are configured.',
              'Aankopen staan uit totdat Google Play-product-ID’s en servercontrole van betaalbewijzen zijn ingesteld.',
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < packs.length; index++)
          Card(
            child: ListTile(
              leading: GameIconSprite(kind, size: 42),
              title: Text(
                '${packs[index]} $label',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(strings.pick(
                'Pack ${index + 1} of ${packs.length}',
                'Pakket ${index + 1} van ${packs.length}',
              )),
              trailing: const Icon(Icons.lock_rounded, color: AppColors.muted),
            ),
          ),
      ],
    );
  }
}
