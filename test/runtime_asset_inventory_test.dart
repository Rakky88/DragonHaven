import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dragon_haven/models/achievement.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/dragon_emote.dart';
import 'package:dragon_haven/models/dragon_school.dart';
import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/runtime_image_assets.dart';
import 'package:dragon_haven/screens/conclave_screen.dart';
import 'package:dragon_haven/theme/event_appearance.dart';
import 'package:dragon_haven/widgets/dragon_art.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dynamic artwork catalogs resolve to bundled runtime images', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundled = manifest.listAssets().toSet();
    final paths = <String>{
      ...DragonArtwork.allAssetPaths,
      for (final item in achievementCatalog) item.badgeAsset,
      for (final item in ChestTier.values) ...[
        item.assetPath,
        item.openedAssetPath,
      ],
      for (final item in allDragonEmotes) item.assetPath,
      for (final item in dragonSchoolGames) ...[
        item.iconAsset,
        item.backgroundAsset,
      ],
      for (final item in MysticRelic.values) item.assetPath,
      for (final item in WeaveMaterial.values) item.asset,
      for (final item in AltarRelic.values) item.asset,
      for (final id in EventAppearance.logoKeys.keys) ...[
        EventAppearance.logoForEvent(id),
        if (EventAppearance.forEvent(id).background case final asset?) asset,
        if (EventAppearance.forEvent(id).emblem case final asset?) asset,
      ],
      for (var stage = 1; stage <= 10; stage++) aerieStageAsset(stage),
      for (var index = 1; index <= 20; index++)
        conclaveEmblemAsset(
            'conclave_emblem_${index.toString().padLeft(2, '0')}'),
      ...losslessPngAssets.map(runtimeImageAsset),
    };
    for (final path in paths) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(bundled, contains(path));
    }
  });

  test('reviewed runtime bytes match the lossless manifest', () async {
    final review = jsonDecode(
      File('tool/asset_manifests/lossless_v35.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final bundle = (await AssetManifest.loadFromAssetBundle(rootBundle))
        .listAssets()
        .toSet();
    final rows = (review['imageRows'] as List).cast<Map<String, dynamic>>();
    for (final row in rows) {
      final source = row['source'] as String;
      expect(bundle, isNot(contains(row['archive'])));
      if (row['retired'] == true) {
        expect(bundle, isNot(contains(source)));
        expect(DragonArtwork.allAssetPaths, isNot(contains(source)));
        continue;
      }
      final runtime = row['runtime'] as String;
      final bytes = File(runtime).readAsBytesSync();
      expect(bytes.length, row['candidateBytes'], reason: runtime);
      expect(sha256.convert(bytes).toString(), row['candidateSha256'],
          reason: runtime);
      expect(row['rgbaExact'], isTrue);
      expect(row['flutterRgbaExact'], isTrue);
      expect(bundle, contains(runtime));
      if (source != runtime) {
        expect(bundle, isNot(contains(source)));
        expect(runtimeImageAsset(source), runtime);
      }
    }
    expect(bundle.where((path) => path.contains('ART_PROMPTS')), isEmpty);
  });
}
