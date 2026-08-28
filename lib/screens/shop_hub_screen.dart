import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/account_title.dart';
import '../models/chest.dart';
import '../models/mystic_relic.dart';
import '../models/music_track.dart';
import '../models/profile_portrait.dart';
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
    final sellsRelics = currency == ItemCurrency.gems;
    final categoryCount = sellsRelics ? 4 : 3;
    return DefaultTabController(
      length: categoryCount,
      initialIndex: initialCategoryTab.clamp(0, categoryCount - 1),
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
                if (sellsRelics)
                  Tab(
                    key: const Key('shop-gems-tab-relics'),
                    text: strings.pick('Relics', 'Relieken'),
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
                if (sellsRelics) const _RelicShop(),
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

class _RelicShop extends StatelessWidget {
  const _RelicShop();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    return ListView(
      key: const PageStorageKey('shop-gems-relics-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2D8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4C46B)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.twilight),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.pick(
                    'Relics bought here are untradeable. Relics found through gameplay remain tradeable. You may buy as many as you like.',
                    'Relieken die je hier koopt zijn niet ruilbaar. Relieken die je via gameplay vindt blijven wel ruilbaar. Je mag er onbeperkt kopen.',
                  ),
                  style: const TextStyle(
                    color: AppColors.ink,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final relic in MysticRelic.values.where(
          (candidate) => candidate.isShopAvailable,
        ))
          _RelicShopCard(
            relic: relic,
            owned: game.relicCount(relic),
            untradeable: game.untradeableRelicCount(relic),
          ),
      ],
    );
  }
}

class _RelicShopCard extends StatelessWidget {
  const _RelicShopCard({
    required this.relic,
    required this.owned,
    required this.untradeable,
  });

  final MysticRelic relic;
  final int owned;
  final int untradeable;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    return Card(
      key: Key('shop-relic-${relic.name}'),
      margin: const EdgeInsets.only(bottom: 11),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 92,
              height: 92,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF4EEFF), Color(0xFFFFF2D8)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(relic.assetPath, fit: BoxFit.contain),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.relicName(relic),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    strings.relicDescription(relic),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    strings.pick(
                      'Owned: $owned · shop-bought: $untradeable (untradeable)',
                      'In bezit: $owned · uit shop: $untradeable (niet ruilbaar)',
                    ),
                    style: const TextStyle(
                      color: AppColors.twilight,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: Key('buy-relic-${relic.name}'),
                      onPressed: game.pet.gems < relicShopGemPrice
                          ? null
                          : () => _buy(context),
                      icon: const GameIconSprite(GameIconKind.gem, size: 25),
                      label: const Text('$relicShopGemPrice'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buy(BuildContext context) async {
    final result = await context.read<HouseholdProvider>().purchaseRelic(relic);
    if (!context.mounted) return;
    final strings = AppStrings.of(context);
    final name = strings.relicName(relic);
    showAppSnackBar(
      context,
      switch (result) {
        MysticRelicPurchaseResult.purchased => strings.pick(
            '$name added to your Inventory. This copy is untradeable.',
            '$name is aan je Inventory toegevoegd. Dit exemplaar is niet ruilbaar.',
          ),
        MysticRelicPurchaseResult.insufficientGems => strings.pick(
            '${relicShopGemPrice - context.read<HouseholdProvider>().pet.gems} more gems needed.',
            'Je hebt nog ${relicShopGemPrice - context.read<HouseholdProvider>().pet.gems} edelstenen nodig.',
          ),
        MysticRelicPurchaseResult.notAvailable => strings.pick(
            'This Relic is not available in the shop.',
            'Dit Reliek is niet verkrijgbaar in de shop.',
          ),
      },
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
    final collectionComplete =
        portraitChest ? game.hasEveryPortrait : game.hasEveryTitle;
    final capacityReached = portraitChest
        ? game.portraitChestCapacityReached
        : game.titleChestCapacityReached;
    final owned = portraitChest ? game.portraitCount : game.titleCount;
    final total = portraitChest
        ? profilePortraitCatalog.length
        : accountTitleCatalog.length;
    final unopened = game.chestCount(tier);
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
              _ChestCollectionStatus(
                portraitChest: portraitChest,
                owned: owned,
                total: total,
                unopened: unopened,
                remainingPortraitsByRarity:
                    portraitChest ? game.remainingPortraitsByRarity : null,
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: Key('buy-${tier.name}-chest'),
                  onPressed: capacityReached
                      ? null
                      : () => _buy(context, portraitChest: portraitChest),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE39A),
                    foregroundColor: const Color(0xFF29184C),
                    disabledBackgroundColor: const Color(0xFF7F7394),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: capacityReached
                      ? Text(collectionComplete
                          ? strings.pick(
                              'Collection complete',
                              'Collectie compleet',
                            )
                          : strings.pick(
                              'All remaining rewards covered',
                              'Alle resterende beloningen gedekt',
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
        if (portraitChest) ...[
          const SizedBox(height: 18),
          const _MusicChestShopCard(),
        ],
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

class _MusicChestShopCard extends StatelessWidget {
  const _MusicChestShopCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    const tier = ChestTier.music;
    return Container(
      key: const Key('shop-music-chest-card'),
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
              'Contains one random song you do not own. Its contents are decided only when opened.',
              'Bevat één willekeurig liedje dat je nog niet bezit. De inhoud wordt pas bij het openen bepaald.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE2D8F5),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            key: const Key('music-chest-collection-status'),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.library_music_rounded,
                      color: Color(0xFFFFD66E), size: 20),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      strings.pick('Collection progress', 'Collectievoortgang'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${game.musicTrackCount} / ${musicCatalog.length}',
                    key: const Key('music-chest-progress'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: game.musicTrackCount / musicCatalog.length,
                    minHeight: 7,
                    color: const Color(0xFFFFD66E),
                    backgroundColor: Colors.white24,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${game.chestCount(tier)} ${strings.pick('unopened chests', 'ongeopende kisten')}',
                  style: const TextStyle(
                    color: Color(0xFFE2D8F5),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('buy-music-chest'),
              onPressed: game.musicChestCapacityReached
                  ? null
                  : () => _buyMusic(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFE39A),
                foregroundColor: const Color(0xFF29184C),
                disabledBackgroundColor: const Color(0xFF7F7394),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: game.musicChestCapacityReached
                  ? Text(game.hasEveryMusicTrack
                      ? strings.pick(
                          'Collection complete', 'Collectie compleet')
                      : strings.pick('All remaining rewards covered',
                          'Alle resterende beloningen gedekt'))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GameIconSprite(GameIconKind.gem, size: 29),
                        SizedBox(width: 7),
                        Text(
                          '$musicChestGemPrice',
                          style: TextStyle(
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
    );
  }

  Future<void> _buyMusic(BuildContext context) async {
    final game = context.read<HouseholdProvider>();
    final result = await game.purchaseMusicChest();
    if (!context.mounted) return;
    final strings = AppStrings.of(context);
    switch (result) {
      case MusicChestPurchaseResult.purchased:
        showAppSnackBar(
          context,
          strings.pick(
            'Music Chest added to your Inventory.',
            'Muziekkist toegevoegd aan je Inventory.',
          ),
        );
      case MusicChestPurchaseResult.insufficientGems:
        showAppSnackBar(
          context,
          strings.pick(
            '${musicChestGemPrice - game.pet.gems} more gems needed.',
            'Nog ${musicChestGemPrice - game.pet.gems} edelstenen nodig.',
          ),
        );
      case MusicChestPurchaseResult.collectionComplete:
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: Image.asset(
              ChestTier.music.assetPath,
              width: 92,
              height: 92,
            ),
            title: Text(strings.pick(
              'Collection complete',
              'Collectie compleet',
            )),
            content: Text(strings.pick(
              'Every song is already owned or covered by an unopened Music Chest.',
              'Elk liedje is al in bezit of wordt gedekt door een ongeopende Muziekkist.',
            )),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(strings.pick('Understood', 'Begrepen')),
              ),
            ],
          ),
        );
    }
  }
}

class _ChestCollectionStatus extends StatelessWidget {
  const _ChestCollectionStatus({
    required this.portraitChest,
    required this.owned,
    required this.total,
    required this.unopened,
    required this.remainingPortraitsByRarity,
  });

  final bool portraitChest;
  final int owned;
  final int total;
  final int unopened;
  final Map<PortraitRarity, int>? remainingPortraitsByRarity;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final remaining = total - owned;
    final rarityCounts = remainingPortraitsByRarity;
    return Container(
      key: Key(portraitChest
          ? 'portrait-chest-collection-status'
          : 'title-chest-collection-status'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.collections_bookmark_rounded,
                  color: Color(0xFFFFD66E), size: 20),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  strings.pick('Collection progress', 'Collectievoortgang'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$owned / $total',
                key: Key(portraitChest
                    ? 'portrait-chest-progress'
                    : 'title-chest-progress'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total == 0 ? 1 : owned / total,
              minHeight: 7,
              color: const Color(0xFFFFD66E),
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '$unopened ${strings.pick('unopened chests', 'ongeopende kisten')}',
            style: const TextStyle(
              color: Color(0xFFE2D8F5),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          if (portraitChest && remaining > 0 && rarityCounts != null) ...[
            const SizedBox(height: 13),
            Text(
              strings.pick('Current portrait odds', 'Actuele portretkansen'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final rarity in PortraitRarity.values)
                  if ((rarityCounts[rarity] ?? 0) > 0)
                    _PortraitOddsChip(
                      rarity: rarity,
                      remaining: rarityCounts[rarity]!,
                      totalRemaining: remaining,
                    ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PortraitOddsChip extends StatelessWidget {
  const _PortraitOddsChip({
    required this.rarity,
    required this.remaining,
    required this.totalRemaining,
  });

  final PortraitRarity rarity;
  final int remaining;
  final int totalRemaining;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final odds = remaining / totalRemaining * 100;
    final oddsText = odds == odds.roundToDouble()
        ? odds.toStringAsFixed(0)
        : odds.toStringAsFixed(1);
    final color = Color(rarity.colorValue);
    return Container(
      key: Key('portrait-odds-${rarity.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .8)),
      ),
      child: Text(
        '${strings.portraitRarity(rarity)}  $remaining · $oddsText%',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
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
        const SizedBox(height: 12),
        GridView.builder(
          key: Key('shop-${currency.name}-pack-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: packs.length,
          itemBuilder: (context, index) => _CurrencyPackTile(
            key: Key('shop-${currency.name}-pack-$index'),
            currency: currency,
            amount: packs[index],
            stage: index,
          ),
        ),
      ],
    );
  }
}

class _CurrencyPackTile extends StatelessWidget {
  const _CurrencyPackTile({
    super.key,
    required this.currency,
    required this.amount,
    required this.stage,
  });

  final ItemCurrency currency;
  final int amount;
  final int stage;

  @override
  Widget build(BuildContext context) {
    final coin = currency == ItemCurrency.coins;
    final label = coin
        ? AppStrings.of(context).pick('coins', 'munten')
        : AppStrings.of(context).tr('gems');
    return Semantics(
      label: '$amount $label',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: coin
                ? const [Color(0xFFFFFBEB), Color(0xFFFFE8A9)]
                : const [Color(0xFFFBF6FF), Color(0xFFE5D5FF)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: coin ? const Color(0xFFE2B84E) : const Color(0xFF9B72D0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F3C236F),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 24),
                child: _CurrencyPackArt(currency: currency, stage: stage),
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Icon(
                Icons.lock_rounded,
                size: 14,
                color: AppColors.twilight.withValues(alpha: .62),
              ),
            ),
            Positioned(
              left: 4,
              right: 4,
              bottom: 7,
              child: Text(
                '$amount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyPackArt extends StatelessWidget {
  const _CurrencyPackArt({required this.currency, required this.stage});

  final ItemCurrency currency;
  final int stage;

  @override
  Widget build(BuildContext context) {
    final currencyName = currency == ItemCurrency.coins ? 'coins' : 'gems';
    final packNumber = (stage + 1).toString().padLeft(2, '0');
    return Image.asset(
      'assets/images/shop/currency_pack_${currencyName}_$packNumber.webp',
      key: Key('currency-pack-art-$currencyName-$packNumber'),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
