import 'dart:io';

import 'package:dragon_haven/models/achievement.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/house.dart';
import 'package:dragon_haven/models/shop_item.dart';
import 'package:dragon_haven/widgets/furniture_art.dart';
import 'package:dragon_haven/widgets/house_room_scene.dart';
import 'package:dragon_haven/widgets/dragon_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('42 standard and nine secret lineages provide distinct forms', () {
    expect(standardDragonLineages, hasLength(42));
    expect(dragonLineages, hasLength(51));
    expect(dragonLineages.map((lineage) => lineage.id).toSet(), hasLength(51));
    final adultNames = <String>{};
    for (final lineage in dragonLineages) {
      for (final path in ['might', 'arcana', 'spirit', 'mastery']) {
        adultNames.add(lineage.formName(path, false));
      }
    }
    expect(adultNames, hasLength(204));
    expect(DragonArtwork.logicalFormCount, 307);
    expect(DragonArtwork.allAssetPaths, hasLength(287));
    final emberbun = dragonLineageById('emberbun');
    expect(emberbun.formName('spirit', false), 'Everwarm Hearthkeeper');
    expect(emberbun.formName('spirit', true), 'Eeuwarm Haardhoeder');
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
    expect(shopCatalog.every((item) => item.price % shopPriceMultiplier == 0),
        isTrue);
    expect(
      shopCatalog.firstWhere((item) => item.id == 'moss_cushion').price,
      120,
    );
    expect(
      shopCatalog.firstWhere((item) => item.id == 'decor_aurora_daybed').price,
      110,
    );
    expect(shopCatalog.where((item) => item.id.startsWith('decor_')),
        hasLength(192));
    final runtimeAssets = shopCatalog
        .map((item) => FurnitureArt.assetForItem(item.id))
        .whereType<String>()
        .toSet();
    expect(runtimeAssets, hasLength(200));
    for (final path in runtimeAssets) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
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

  testWidgets('generated furniture renders from proportional runtime sprites',
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

  testWidgets(
      'every bed asset uses safe contain padding and stays inside room bounds',
      (tester) async {
    const themes = <String>[
      'aurora',
      'ember',
      'moon',
      'forest',
      'ocean',
      'crystal',
      'cloud',
      'sun',
      'lavender',
      'copper',
      'starlight',
      'meadow',
      'storm',
      'cherry',
      'frost',
      'honey',
      'mushroom',
      'velvet',
      'rainbow',
      'twilight',
      'coral',
      'sapphire',
      'rose',
      'dragon',
    ];
    final expectedIds = <String>{
      'moss_cushion',
      'cloud_basket',
      'supporter_dragon_throne',
      for (final theme in themes) 'decor_${theme}_cushion',
      for (final theme in themes) 'decor_${theme}_daybed',
    };
    final beds = allFurnitureCatalog
        .where((item) => item.slot == ItemSlot.bed)
        .toList(growable: false);
    expect(beds.map((item) => item.id).toSet(), expectedIds);
    expect(beds, hasLength(51));

    const sceneSize = Size(320, 256);
    for (final item in beds) {
      final asset = FurnitureArt.assetForItem(item.id);
      expect(asset, isNotNull, reason: item.id);
      expect(File(asset!).existsSync(), isTrue, reason: item.id);
      for (final point in const [
        Offset(.04, .04),
        Offset(.96, .04),
        Offset(.04, .96),
        Offset(.96, .96),
      ]) {
        final rect = furnitureRoomPlacementRect(
          item: item,
          placement: HousePlacement(
            itemId: item.id,
            roomId: 'hearth',
            x: point.dx,
            y: point.dy,
            scale: 1.35,
          ),
          sceneSize: sceneSize,
        );
        expect(rect.left, greaterThanOrEqualTo(0), reason: item.id);
        expect(rect.top, greaterThanOrEqualTo(0), reason: item.id);
        expect(rect.right, lessThanOrEqualTo(sceneSize.width), reason: item.id);
        expect(rect.bottom, lessThanOrEqualTo(sceneSize.height),
            reason: item.id);
      }
    }

    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Wrap(
        children: [
          for (final item in beds)
            SizedBox(
              width: 100,
              height: 85,
              child: FurnitureArt(item: item),
            ),
        ],
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(FractionallySizedBox), findsNWidgets(51));
    for (final box in tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))) {
      expect(box.widthFactor, .94);
      expect(box.heightFactor, .94);
    }
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      expect(image.fit, BoxFit.contain);
    }
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

  test('all achievements are bilingual and uniquely identified', () {
    expect(achievementCatalog, hasLength(40));
    expect(achievementCatalog.map((entry) => entry.id).toSet(), hasLength(40));
    expect(
        achievementCatalog.every((entry) =>
            entry.titleEn.isNotEmpty &&
            entry.titleNl.isNotEmpty &&
            entry.descriptionEn.isNotEmpty &&
            entry.descriptionNl.isNotEmpty),
        isTrue);
    for (final achievement in achievementCatalog) {
      expect(File(achievement.badgeAsset).existsSync(), isTrue,
          reason: achievement.badgeAsset);
    }
  });
}
