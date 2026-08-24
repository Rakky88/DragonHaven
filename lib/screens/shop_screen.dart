import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/shop_item.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/furniture_art.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/ui_bits.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.currency = ItemCurrency.coins});

  final ItemCurrency currency;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _searchController = TextEditingController();
  ItemSlot? _slot;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final household = context.watch<HouseholdProvider>();
    final largeText = usesLargeText(context);
    final normalizedQuery = _query.trim().toLowerCase();
    final items = shopCatalog.where((item) {
      if (item.currency != widget.currency) return false;
      if (_slot != null && item.slot != _slot) return false;
      if (normalizedQuery.isEmpty) return true;
      return strings.itemName(item).toLowerCase().contains(normalizedQuery) ||
          strings.itemDescription(item).toLowerCase().contains(normalizedQuery);
    }).toList();
    return CustomScrollView(
      key: PageStorageKey('shop-${widget.currency.name}-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShopHeader(
                  balance: widget.currency == ItemCurrency.coins
                      ? household.pet.coins
                      : household.pet.gems,
                  currency: widget.currency,
                  largeText: largeText,
                ),
                const SizedBox(height: 19),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(21),
                    gradient: const LinearGradient(
                        colors: [AppColors.goldLight, Color(0xFFFFE2D8)]),
                  ),
                  child: Row(children: [
                    Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            shape: BoxShape.circle),
                        child: const Padding(
                          padding: EdgeInsets.all(3),
                          child: GameIconSprite(
                            GameIconKind.inventoryFurniture,
                            size: 44,
                          ),
                        )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              strings.pick(
                                  '${household.ownedItemIds.length} of ${shopCatalog.length} collected',
                                  '${household.ownedItemIds.length} van ${shopCatalog.length} verzameld'),
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                              strings.pick('Purchased items are always yours.',
                                  'Gekochte spullen blijven altijd van jullie.'),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.muted))
                        ])),
                  ]),
                ),
                const SizedBox(height: 15),
                TextField(
                  key: const Key('shop-search'),
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: strings.pick(
                      'Search 200 house items',
                      'Zoek in 200 huisspullen',
                    ),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: strings.pick(
                                'Clear search', 'Zoekopdracht wissen'),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 11),
                HorizontalChoiceRail(
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ChoiceChip(
                            label: Text(strings.pick('All', 'Alles')),
                            selected: _slot == null,
                            onSelected: (_) => setState(() => _slot = null))),
                    for (final slot in ItemSlot.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ChoiceChip(
                          avatar: Icon(_slotIcon(slot), size: 17),
                          label: Text(strings.slotLabel(slot)),
                          selected: _slot == slot,
                          onSelected: (_) => setState(() => _slot = slot),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  strings.pick(
                    '${items.length} items shown',
                    '${items.length} spullen getoond',
                  ),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final columns = largeText
                  ? 1
                  : constraints.crossAxisExtent >= 650
                      ? 3
                      : 2;
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 11,
                  mainAxisExtent: largeText
                      ? 360
                      : columns == 2
                          ? 318
                          : 300,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ShopItemCard(item: items[index]),
                  childCount: items.length,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({
    required this.balance,
    required this.currency,
    required this.largeText,
  });

  final int balance;
  final ItemCurrency currency;
  final bool largeText;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.pick('House shop', 'Huiswinkel'),
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 5),
        Text(
          strings.pick('Collect furniture for every dragon room.',
              'Verzamel meubels voor elke drakenkamer.'),
          style: const TextStyle(color: AppColors.muted, fontSize: 16),
        ),
      ],
    );
    final coinPill = MetricPill(
      leading: GameIconSprite(
        currency == ItemCurrency.coins ? GameIconKind.coin : GameIconKind.gem,
        size: 26,
      ),
      value: '$balance',
      label: currency == ItemCurrency.coins
          ? strings.pick('coins', 'munten')
          : strings.tr('gems'),
      color: currency == ItemCurrency.coins
          ? const Color(0xFF9A6A00)
          : const Color(0xFF258BB0),
    );
    if (largeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading,
          const SizedBox(height: 10),
          coinPill,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: heading),
        coinPill,
      ],
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({required this.item});
  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final largeText = usesLargeText(context);
    final household = context.watch<HouseholdProvider>();
    final owned = household.owns(item);
    final equipped = household.isEquipped(item);
    final affordable = (item.currency == ItemCurrency.coins
            ? household.pet.coins
            : household.pet.gems) >=
        item.price;
    final color = Color(furnitureThemeColorValue(item));
    return Container(
      key: Key('shop-item-${item.id}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: equipped ? AppColors.mint : AppColors.mist,
            width: equipped ? 2 : 1),
        boxShadow: [
          BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.045),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: FurnitureArt(item: item),
                ),
              ),
              const Spacer(),
              if (equipped)
                const Icon(Icons.check_circle_rounded, color: AppColors.mint)
              else if (owned)
                const Icon(Icons.inventory_2_rounded,
                    color: AppColors.twilight, size: 21),
            ],
          ),
          const SizedBox(height: 13),
          Text(strings.itemName(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          SizedBox(
            height: largeText ? 48 : 47,
            child: Text(strings.itemDescription(item),
                maxLines: largeText ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 12, height: 1.3)),
          ),
          const Spacer(),
          SizedBox(
            height: 39,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  _Tag(strings.rarityLabel(item.rarity), color),
                  _Tag(strings.slotLabel(item.slot), AppColors.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: Key('shop-action-${item.id}'),
              onPressed: equipped ? null : () => _act(context),
              style: FilledButton.styleFrom(
                backgroundColor: owned
                    ? AppColors.mint
                    : affordable
                        ? AppColors.twilight
                        : AppColors.muted,
                disabledBackgroundColor: AppColors.mintLight,
                disabledForegroundColor: const Color(0xFF29745E),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
              ),
              child: equipped
                  ? Text(strings.pick('Placed', 'Geplaatst'))
                  : owned
                      ? Text(strings.pick('Place', 'Plaatsen'))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (affordable)
                              GameIconSprite(
                                item.currency == ItemCurrency.coins
                                    ? GameIconKind.coin
                                    : GameIconKind.gem,
                                size: 23,
                              )
                            else
                              const Icon(
                                Icons.lock_rounded,
                                size: 17,
                                color: Colors.white,
                              ),
                            const SizedBox(width: 5),
                            Text('${item.price}'),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _act(BuildContext context) async {
    final result =
        await context.read<HouseholdProvider>().purchaseOrEquip(item);
    if (!context.mounted) return;
    final strings = AppStrings.of(context);
    final roomName =
        strings.roomName(context.read<HouseholdProvider>().activeRoom);
    final itemName = strings.itemName(item);
    final message = switch (result) {
      PurchaseResult.purchased => strings.pick(
          '$itemName purchased and stored in Inventory.',
          '$itemName gekocht en in Inventory gezet.'),
      PurchaseResult.equipped => strings.pick(
          '$itemName is now in $roomName.', '$itemName staat nu in $roomName.'),
      PurchaseResult.insufficientCoins => strings.pick(
          '${item.price - context.read<HouseholdProvider>().pet.coins} more coins needed.',
          'Nog ${item.price - context.read<HouseholdProvider>().pet.coins} munten nodig.'),
      PurchaseResult.insufficientGems => strings.pick(
          '${item.price - context.read<HouseholdProvider>().pet.gems} more gems needed.',
          'Nog ${item.price - context.read<HouseholdProvider>().pet.gems} edelstenen nodig.'),
      PurchaseResult.alreadyEquipped => strings.pick(
          '$itemName already has a place in the house.',
          '$itemName heeft al een plek in het huis.'),
    };
    showAppSnackBar(context, message);
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(99)),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w900)),
      );
}

IconData _slotIcon(ItemSlot slot) => switch (slot) {
      ItemSlot.bed => Icons.bed_rounded,
      ItemSlot.plant => Icons.eco_rounded,
      ItemSlot.wall => Icons.wallpaper_rounded,
      ItemSlot.light => Icons.auto_awesome_rounded,
    };
