import 'dart:io';

import 'package:dragon_haven/models/achievement.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/house.dart';
import 'package:dragon_haven/models/shop_item.dart';
import 'package:dragon_haven/widgets/furniture_art.dart';
import 'package:dragon_haven/widgets/dragon_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forty-two lineages provide 126 distinct Ascended forms', () {
    expect(dragonLineages, hasLength(42));
    expect(dragonLineages.map((lineage) => lineage.id).toSet(), hasLength(42));
    final adultNames = <String>{};
    for (final lineage in dragonLineages) {
      for (final path in ['might', 'arcana', 'spirit']) {
        adultNames.add(lineage.formName(path, false));
      }
    }
    expect(adultNames, hasLength(126));
    expect(DragonArtwork.logicalFormCount, 211);
    expect(DragonArtwork.allAssetPaths, hasLength(87));
  });

  test('all dragon artwork files exist', () {
    for (final path in DragonArtwork.allAssetPaths) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('the furniture catalog contains 200 unique purchasable items', () {
    expect(shopCatalog, hasLength(200));
    expect(shopCatalog.map((item) => item.id).toSet(), hasLength(200));
    expect(shopCatalog.every((item) => item.price > 0), isTrue);
    expect(shopCatalog.where((item) => item.id.startsWith('decor_')),
        hasLength(192));
  });

  test('all twenty-four generated furniture atlases exist', () {
    final themeIds = shopCatalog
        .where((item) => item.id.startsWith('decor_'))
        .map((item) => item.id.split('_')[1])
        .toSet();
    expect(themeIds, hasLength(24));
    for (final theme in themeIds) {
      expect(File('assets/images/furniture_atlases/$theme.webp').existsSync(),
          isTrue,
          reason: theme);
    }
  });

  testWidgets('generated furniture renders from real sprite atlases',
      (tester) async {
    final samples = <ShopItem>[];
    final seenThemes = <String>{};
    for (final item
        in shopCatalog.where((item) => item.id.startsWith('decor_'))) {
      if (seenThemes.add(item.id.split('_')[1])) samples.add(item);
    }
    await tester.pumpWidget(MaterialApp(
      home: Wrap(
        children: [
          for (final item in samples)
            SizedBox.square(dimension: 64, child: FurnitureArt(item: item)),
        ],
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(Image), findsNWidgets(24));
    expect(tester.takeException(), isNull);
  });

  test('eight rooms have distinct handcrafted backgrounds', () {
    expect(houseRoomCatalog, hasLength(8));
    expect(houseRoomCatalog.map((room) => room.id).toSet(), hasLength(8));
    expect(houseRoomCatalog.map((room) => room.backgroundAsset).toSet(),
        hasLength(8));
    for (final room in houseRoomCatalog) {
      expect(File(room.backgroundAsset).existsSync(), isTrue,
          reason: room.backgroundAsset);
    }
  });

  test('all twenty achievements are bilingual and uniquely identified', () {
    expect(achievementCatalog, hasLength(20));
    expect(achievementCatalog.map((entry) => entry.id).toSet(), hasLength(20));
    expect(
        achievementCatalog.every((entry) =>
            entry.titleEn.isNotEmpty &&
            entry.titleNl.isNotEmpty &&
            entry.descriptionEn.isNotEmpty &&
            entry.descriptionNl.isNotEmpty),
        isTrue);
  });
}
