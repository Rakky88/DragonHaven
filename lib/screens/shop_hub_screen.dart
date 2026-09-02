import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/account_title.dart';
import '../models/chest.dart';
import '../models/dragon_emote.dart';
import '../models/mystic_relic.dart';
import '../models/music_track.dart';
import '../models/profile_portrait.dart';
import '../models/shop_item.dart';
import '../models/supporter_pack.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/dragon_emote_picker.dart';
import '../widgets/furniture_art.dart';
import '../widgets/profile_portrait_sprite.dart';
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
      length: 3,
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
              Tab(
                key: const Key('shop-tab-packs'),
                icon: Image.asset(
                  'assets/images/ui/packs_icon.png',
                  width: 38,
                  height: 38,
                ),
                text: strings.pick('Packs', 'Pakketten'),
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
                const _PacksShop(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PacksShop extends StatefulWidget {
  const _PacksShop();

  @override
  State<_PacksShop> createState() => _PacksShopState();
}

class _PacksShopState extends State<_PacksShop> {
  bool _contentsExpanded = false;
  String? _expandedEmotePackId;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    return ListView(
      key: const Key('packs-shop-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/ui/packs_icon.png',
              width: 42,
              height: 42,
            ),
            const SizedBox(width: 9),
            Text(
              strings.pick('Packs', 'Pakketten'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          strings.pick(
            'Special cosmetic collections. More packs can join this shop later.',
            'Speciale cosmetische collecties. Later kunnen hier meer pakketten bijkomen.',
          ),
          style: const TextStyle(color: AppColors.muted, height: 1.3),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF211638), Color(0xFF694A97), Color(0xFFB1784B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.gold),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332A1E50),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Image.asset(
                supporterBadge.assetPath,
                width: 104,
                height: 104,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.gold,
                  size: 88,
                ),
              ),
              Text(
                strings.pick(
                    'Founding Supporter Pack', 'Oprichterssupporter-pakket'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                strings.pick(
                  'A permanent collection of cosmetics made to thank the Keepers who help DragonHaven grow.',
                  'Een permanente collectie cosmetica als dank aan de Keepers die DragonHaven helpen groeien.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFE9DFF9), height: 1.3),
              ),
              const SizedBox(height: 13),
              FilledButton.icon(
                key: const Key('buy-supporter-pack'),
                onPressed: game.supporterPackOwned
                    ? null
                    : () => showAppSnackBar(
                          context,
                          strings.pick(
                            'The pack is ready for €2.99. Purchasing becomes available after the Google Play product and secure server verification are connected.',
                            'Het pakket staat klaar voor €2,99. Kopen wordt beschikbaar zodra het Google Play-product en veilige servercontrole zijn aangesloten.',
                          ),
                        ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .14),
                  disabledBackgroundColor: Colors.white.withValues(alpha: .10),
                  foregroundColor: AppColors.gold,
                  disabledForegroundColor: AppColors.gold,
                  side: const BorderSide(color: Colors.white24),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                ),
                icon: Icon(game.supporterPackOwned
                    ? Icons.check_circle_rounded
                    : Icons.shopping_bag_rounded),
                label: Text(
                  game.supporterPackOwned
                      ? strings.pick('OWNED', 'IN BEZIT')
                      : '€2,99',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('supporter-pack-everything-included'),
                  onTap: () => setState(
                    () => _contentsExpanded = !_contentsExpanded,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.pick(
                                'Everything included', 'Alles inbegrepen'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _contentsExpanded ? .5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(
                            Icons.expand_more_rounded,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_contentsExpanded) const _SupporterPackContents(),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.pick(
            'Cosmetic only: no gems, coins, power or gameplay advantage.',
            'Alleen cosmetisch: geen gems, munten, kracht of spelvoordeel.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 18),
        Text(
          strings.pick('Dragon emote packs', 'Drakenemotepakketten'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          strings.pick(
            'Each pack contains ten exclusive chat emotes that cannot drop from chests or Trials.',
            'Elk pakket bevat tien exclusieve chatemotes die niet uit kisten of Trials kunnen komen.',
          ),
          style: const TextStyle(color: AppColors.muted, height: 1.3),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < dragonEmotePacks.length; index++) ...[
              if (index > 0) const SizedBox(width: 7),
              Expanded(
                child: _DragonEmotePackCard(
                  pack: dragonEmotePacks[index],
                  expanded: _expandedEmotePackId == dragonEmotePacks[index].id,
                  onExpand: () => setState(() {
                    final id = dragonEmotePacks[index].id;
                    _expandedEmotePackId =
                        _expandedEmotePackId == id ? null : id;
                  }),
                ),
              ),
            ],
          ],
        ),
        if (_expandedEmotePackId != null) ...[
          const SizedBox(height: 8),
          _DragonEmotePackGrid(
            pack: dragonEmotePacks.firstWhere(
              (pack) => pack.id == _expandedEmotePackId,
            ),
          ),
        ],
      ],
    );
  }
}

class _DragonEmotePackCard extends StatelessWidget {
  const _DragonEmotePackCard({
    required this.pack,
    required this.expanded,
    required this.onExpand,
  });

  final DragonEmotePackDefinition pack;
  final bool expanded;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final owned = game.ownsDragonEmotePack(pack.id);
    final colors = switch (pack.source) {
      DragonEmoteSource.cozyPack => const [
          Color(0xFFF8B8C8),
          Color(0xFF8A5CB5)
        ],
      DragonEmoteSource.infernalPack => const [
          Color(0xFF421127),
          Color(0xFFC44734)
        ],
      DragonEmoteSource.celestialPack => const [
          Color(0xFF182F66),
          Color(0xFF7752B8)
        ],
      _ => const [Color(0xFF392465), Color(0xFF694A97)],
    };
    return Container(
      key: Key('dragon-emote-pack-${pack.id}'),
      height: 190,
      padding: const EdgeInsets.fromLTRB(7, 9, 7, 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x222A1E50),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          DragonEmoteSprite(emote: pack.emotes.first, size: 58),
          const SizedBox(height: 2),
          SizedBox(
            height: 34,
            child: Center(
              child: Text(
                pack.name(strings.languageCode),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 35,
            child: FilledButton(
              key: Key('buy-dragon-emote-pack-${pack.id}'),
              onPressed: owned
                  ? null
                  : () => showAppSnackBar(
                        context,
                        strings.pick(
                          'This pack is ready for €1.99. Purchasing becomes available after its Google Play product and secure server verification are connected.',
                          'Dit pakket staat klaar voor €1,99. Kopen wordt beschikbaar zodra het Google Play-product en veilige servercontrole zijn aangesloten.',
                        ),
                      ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: .15),
                disabledBackgroundColor: Colors.white.withValues(alpha: .10),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFFE9DFF9),
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  owned ? strings.pick('OWNED', 'IN BEZIT') : '€1,99',
                  key: Key('dragon-emote-pack-price-${pack.id}'),
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          InkWell(
            key: Key('expand-dragon-emote-pack-${pack.id}'),
            onTap: onExpand,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        strings.pick('10 emotes', '10 emotes'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? .5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: Colors.white,
                      size: 18,
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
}

class _DragonEmotePackGrid extends StatelessWidget {
  const _DragonEmotePackGrid({required this.pack});

  final DragonEmotePackDefinition pack;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0E8F8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: GridView.builder(
          key: Key('dragon-emote-pack-grid-${pack.id}'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
          itemCount: pack.emotes.length,
          itemBuilder: (context, index) => DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: DragonEmoteSprite(
                emote: pack.emotes[index],
                size: 58,
              ),
            ),
          ),
        ),
      );
}

class _SupporterPackContents extends StatelessWidget {
  const _SupporterPackContents();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
      key: const Key('supporter-pack-contents'),
      children: [
        _SupporterContentTile(
          art: ProfilePortraitSprite(
              portrait: supporterProfilePortrait, size: 64),
          title: strings.pick(
              'Exclusive supporter portrait', 'Exclusief supporterportret'),
          body: strings.pick(
            'Separate from Portrait Chests and never changes their odds.',
            'Staat los van Portretkisten en verandert hun kansen nooit.',
          ),
        ),
        _SupporterContentTile(
          art: const Icon(Icons.workspace_premium_rounded,
              color: AppColors.twilight, size: 46),
          title: strings.pick(
              '“Founding Supporter” title', 'Titel “Oprichterssupporter”'),
          body: strings.pick(
            'Separate from Title Chests and never changes their odds.',
            'Staat los van Titelkisten en verandert hun kansen nooit.',
          ),
        ),
        _SupporterContentTile(
          art: Image.asset(supporterBadge.assetPath,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.shield_rounded, size: 46)),
          title: strings.pick('Supporter badge', 'Supporterbadge'),
          body: strings.pick(
            'A new identity cosmetic that clearly marks your support.',
            'Een nieuw identiteitsitem dat jouw steun duidelijk laat zien.',
          ),
        ),
        _SupporterContentTile(
          art: Image.asset(supporterFrame.assetPath,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.crop_square_rounded, size: 46)),
          title: strings.pick(
              'Supporter portrait frame', 'Supporter-portretlijst'),
          body: strings.pick(
            'An equipable profile frame created exclusively for this pack.',
            'Een instelbare profiellijst, exclusief gemaakt voor dit pakket.',
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F2FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.pick('Complete supporter furniture set',
                    'Volledige supporter-meubelset'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in supporterFurnitureCatalog)
                        SizedBox(
                          width: itemWidth,
                          height: itemWidth / 1.05,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0x33A87836),
                              ),
                            ),
                            child: Column(
                              children: [
                                Expanded(child: FurnitureArt(item: item)),
                                Text(
                                  strings.itemName(item),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupporterContentTile extends StatelessWidget {
  const _SupporterContentTile({
    required this.art,
    required this.title,
    required this.body,
  });

  final Widget art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox.square(dimension: 64, child: Center(child: art)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(body,
                        style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            height: 1.25)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
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
    final owned =
        portraitChest ? game.chestPortraitCount : game.chestTitleCount;
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
        ? const [500, 1200, 3200, 6500, 15000, 35000]
        : const [50, 120, 320, 650, 1500, 3500];
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
