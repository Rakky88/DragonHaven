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

  static String? assetForItem(String itemId) => switch (itemId) {
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

  @override
  Widget build(BuildContext context) {
    final standalone = assetForItem(item.id);
    return Semantics(
      image: true,
      label: AppStrings.of(context).itemName(item),
      child: standalone == null
          ? _AtlasFurnitureSprite(item: item)
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

class _AtlasFurnitureSprite extends StatelessWidget {
  const _AtlasFurnitureSprite({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final parts = item.id.split('_');
    if (parts.length != 3 || parts.first != 'decor') {
      return const Center(child: Icon(Icons.chair_alt_rounded));
    }
    final atlas = 'assets/images/furniture_atlases/${parts[1]}.webp';
    final frame = (item.visualSeed - 8).clamp(0, 191).remainder(8);
    final column = frame.remainder(4);
    final row = frame ~/ 4;
    final x = -1 + column * (2 / 3);
    final y = row == 0 ? -1.0 : 1.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final logicalWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : 256.0;
        final sourceWidth =
            (logicalWidth * MediaQuery.devicePixelRatioOf(context) * 4)
                .ceil()
                .clamp(256, 1774);
        return ClipRect(
          child: Transform.scale(
            scaleX: 4,
            scaleY: 2,
            alignment: Alignment(x, y),
            child: Image.asset(
              atlas,
              fit: BoxFit.fill,
              cacheWidth: sourceWidth,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              errorBuilder: FurnitureArt._errorBuilder,
            ),
          ),
        );
      },
    );
  }
}
