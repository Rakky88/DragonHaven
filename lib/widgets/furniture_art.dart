import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/shop_item.dart';

class FurnitureArt extends StatelessWidget {
  const FurnitureArt({
    super.key,
    required this.item,
    this.fit = BoxFit.contain,
  });

  final ShopItem item;
  final BoxFit fit;

  static String? assetForItem(String itemId) {
    final original = switch (itemId) {
      'moss_cushion' => 'assets/images/furniture_moss_cushion.webp',
      'cloud_basket' => 'assets/images/furniture_cloud_basket.webp',
      'moon_fern' => 'assets/images/furniture_moon_fern.webp',
      'star_bonsai' => 'assets/images/furniture_star_bonsai.webp',
      'spire_map' => 'assets/images/furniture_spire_map.webp',
      'moon_banner' => 'assets/images/furniture_moon_banner.webp',
      'firefly_lamp' => 'assets/images/furniture_firefly_lamp.webp',
      'crystal_lantern' => 'assets/images/furniture_crystal_lantern.webp',
      _ => null,
    };
    if (original != null) return original;
    final parts = itemId.split('_');
    if (parts.length == 3 && parts.first == 'decor') {
      return 'assets/images/furniture/$itemId.webp';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final standalone = assetForItem(item.id);
    return Semantics(
      image: true,
      label: AppStrings.of(context).itemName(item),
      child: standalone == null
          ? _errorBuilder(context, StateError('Unknown furniture'), null)
          : Image.asset(
              standalone,
              fit: fit,
              filterQuality: FilterQuality.high,
              cacheWidth: 512,
              errorBuilder: _errorBuilder,
            ),
    );
  }

  static Widget _errorBuilder(
          BuildContext context, Object error, StackTrace? stackTrace) =>
      const Center(child: Icon(Icons.chair_alt_rounded));
}
