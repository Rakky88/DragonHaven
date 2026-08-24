import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/achievement.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/day_phase.dart';
import 'package:dragon_haven/models/house.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/profile_portrait.dart';
import 'package:dragon_haven/models/shop_item.dart';
import 'package:dragon_haven/widgets/dragon_art.dart';
import 'package:dragon_haven/widgets/furniture_art.dart';
import 'package:dragon_haven/widgets/game_icon_sprite.dart';
import 'package:flutter_test/flutter_test.dart';

Future<({int width, int height, Uint8List rgba})> _decode(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final result = (
    width: frame.image.width,
    height: frame.image.height,
    rgba: data!.buffer.asUint8List(),
  );
  frame.image.dispose();
  codec.dispose();
  return result;
}

int _alphaCount(Uint8List rgba, int width, int x0, int y0, int x1, int y1,
    {int step = 1}) {
  var pixels = 0;
  for (var y = y0; y < y1; y += step) {
    for (var x = x0; x < x1; x += step) {
      if (rgba[(y * width + x) * 4 + 3] >= 8) pixels++;
    }
  }
  return pixels;
}

void _expectContained(
    Uint8List rgba, int width, int x0, int y0, int x1, int y1, String label) {
  final horizontalMargin = ((x1 - x0) * .01).ceil().clamp(2, 8);
  final verticalMargin = ((y1 - y0) * .01).ceil().clamp(2, 8);
  expect(_alphaCount(rgba, width, x0, y0, x1, y1, step: 4), greaterThan(100),
      reason: '$label is empty');
  expect(_alphaCount(rgba, width, x0, y0, x0 + horizontalMargin, y1), 0,
      reason: '$label touches its left crop edge');
  expect(_alphaCount(rgba, width, x1 - horizontalMargin, y0, x1, y1), 0,
      reason: '$label touches its right crop edge');
  expect(_alphaCount(rgba, width, x0, y0, x1, y0 + verticalMargin), 0,
      reason: '$label touches its top crop edge');
  expect(_alphaCount(rgba, width, x0, y1 - verticalMargin, x1, y1), 0,
      reason: '$label touches its bottom crop edge');
}

void _expectInsidePortraitCircle(
  Uint8List rgba,
  int width,
  int height,
  String label,
) {
  final centerX = width / 2;
  final centerY = height / 2;
  final maximumRadius = width * .475;
  final maximumSquared = maximumRadius * maximumRadius;
  (int, int)? outsidePixel;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (rgba[(y * width + x) * 4 + 3] < 8) continue;
      final dx = x + .5 - centerX;
      final dy = y + .5 - centerY;
      if (dx * dx + dy * dy > maximumSquared) {
        outsidePixel = (x, y);
        break;
      }
    }
    if (outsidePixel != null) break;
  }
  expect(
    outsidePixel,
    isNull,
    reason: '$label has a visible pixel outside its portrait circle at '
        '$outsidePixel',
  );
}

void _expectSingleSubject(
    Uint8List rgba, int width, int x0, int y0, int x1, int y1, String label) {
  // Inspect every pixel in each four-pixel cell. Sampling only one point per
  // cell can incorrectly split narrow details, while a full-resolution flood
  // fill makes this complete asset audit unnecessarily slow.
  const step = 4;
  final sampleWidth = ((x1 - x0) / step).ceil();
  final sampleHeight = ((y1 - y0) / step).ceil();
  final active = List<bool>.filled(sampleWidth * sampleHeight, false);
  for (var sampleY = 0; sampleY < sampleHeight; sampleY++) {
    for (var sampleX = 0; sampleX < sampleWidth; sampleX++) {
      var hasAlpha = false;
      for (var dy = 0; dy < step && !hasAlpha; dy++) {
        final y = y0 + sampleY * step + dy;
        if (y >= y1) break;
        for (var dx = 0; dx < step; dx++) {
          final x = x0 + sampleX * step + dx;
          if (x >= x1) break;
          if (rgba[(y * width + x) * 4 + 3] >= 32) {
            hasAlpha = true;
            break;
          }
        }
      }
      active[sampleY * sampleWidth + sampleX] = hasAlpha;
    }
  }
  final visited = List<bool>.filled(active.length, false);
  var significantComponents = 0;
  for (var start = 0; start < active.length; start++) {
    if (!active[start] || visited[start]) continue;
    visited[start] = true;
    final queue = <int>[start];
    var cursor = 0;
    var pixels = 0;
    while (cursor < queue.length) {
      final index = queue[cursor++];
      pixels++;
      final sampleX = index % sampleWidth;
      final sampleY = index ~/ sampleWidth;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          final nextX = sampleX + dx;
          final nextY = sampleY + dy;
          if (nextX < 0 ||
              nextX >= sampleWidth ||
              nextY < 0 ||
              nextY >= sampleHeight) {
            continue;
          }
          final next = nextY * sampleWidth + nextX;
          if (active[next] && !visited[next]) {
            visited[next] = true;
            queue.add(next);
          }
        }
      }
    }
    if (pixels >= 4) significantComponents++;
  }
  expect(significantComponents, 1,
      reason: '$label contains a foreign sprite fragment');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all achievement badges are square, non-empty and safely contained',
      () async {
    for (final achievement in achievementCatalog) {
      final image = await _decode(achievement.badgeAsset);
      expect(image.width, 256, reason: achievement.badgeAsset);
      expect(image.height, 256, reason: achievement.badgeAsset);
      _expectContained(image.rgba, image.width, 0, 0, image.width, image.height,
          achievement.badgeAsset);
    }
  });

  test('egg and every Hatchling sprite fit fully inside their image box',
      () async {
    for (final path in <String>[
      DragonArtwork.eggAsset,
      for (final lineage in dragonLineages)
        DragonArtwork.hatchlingAsset(lineage.id),
      DragonArtwork.sinisterHatchlingAsset(),
    ]) {
      final image = await _decode(path);
      expect(image.width / image.height, inInclusiveRange(.5, 2.0),
          reason: '$path must retain a usable natural aspect ratio');
      _expectContained(
          image.rgba, image.width, 0, 0, image.width, image.height, path);
      if (path != DragonArtwork.eggAsset) {
        _expectSingleSubject(
            image.rgba, image.width, 0, 0, image.width, image.height, path);
      }
    }
  });

  test('every Wyrmling and Ascended frame fits its atlas quadrant', () async {
    for (final lineage in dragonLineages) {
      final image = await _decode(DragonArtwork.formsAsset(lineage.id));
      expect(image.width, image.height,
          reason: '${lineage.id} forms atlas must remain square');
      for (var row = 0; row < 2; row++) {
        for (var column = 0; column < 2; column++) {
          final x0 = (column * image.width / 2).round();
          final x1 = ((column + 1) * image.width / 2).round();
          final y0 = (row * image.height / 2).round();
          final y1 = ((row + 1) * image.height / 2).round();
          _expectContained(image.rgba, image.width, x0, y0, x1, y1,
              '${lineage.id} frame ${row * 2 + column}');
          _expectSingleSubject(image.rgba, image.width, x0, y0, x1, y1,
              '${lineage.id} frame ${row * 2 + column}');
        }
      }
    }

    final sinister = await _decode(DragonArtwork.sinisterFormsAsset());
    expect(sinister.width, sinister.height,
        reason: 'sinister forms atlas must remain square');
    for (var row = 0; row < 2; row++) {
      for (var column = 0; column < 2; column++) {
        final x0 = (column * sinister.width / 2).round();
        final x1 = ((column + 1) * sinister.width / 2).round();
        final y0 = (row * sinister.height / 2).round();
        final y1 = ((row + 1) * sinister.height / 2).round();
        _expectContained(
          sinister.rgba,
          sinister.width,
          x0,
          y0,
          x1,
          y1,
          'sinister frame ${row * 2 + column}',
        );
        _expectSingleSubject(sinister.rgba, sinister.width, x0, y0, x1, y1,
            'sinister frame ${row * 2 + column}');
      }
    }
  });

  test('all 42 Mastery Ascended sprites are complete standalone subjects',
      () async {
    for (final lineage in dragonLineages) {
      final path = DragonArtwork.masteryAsset(lineage.id);
      final image = await _decode(path);
      expect(image.width, 1024, reason: path);
      expect(image.height, 1024, reason: path);
      _expectContained(
        image.rgba,
        image.width,
        0,
        0,
        image.width,
        image.height,
        path,
      );
      _expectSingleSubject(
        image.rgba,
        image.width,
        0,
        0,
        image.width,
        image.height,
        path,
      );
      final sampledAlpha = _alphaCount(
        image.rgba,
        image.width,
        0,
        0,
        image.width,
        image.height,
        step: 4,
      );
      expect(
        sampledAlpha,
        lessThan((image.width ~/ 4) * (image.height ~/ 4) * .62),
        reason: '$path appears to contain an opaque generated backdrop',
      );
      expect(
        sampledAlpha,
        greaterThan((image.width ~/ 4) * (image.height ~/ 4) * .08),
        reason: '$path appears to have lost most of its dragon artwork',
      );
    }
  });

  test('all furniture atlases contain eight safely separated sprites',
      () async {
    final files = Directory('assets/images/furniture_atlases')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.webp'))
        .toList();
    expect(files, hasLength(24));
    for (final file in files) {
      final image = await _decode(file.path);
      expect(image.width / image.height, closeTo(2, .01), reason: file.path);
      for (var row = 0; row < 2; row++) {
        for (var column = 0; column < 4; column++) {
          final x0 = (column * image.width / 4).round();
          final x1 = ((column + 1) * image.width / 4).round();
          final y0 = (row * image.height / 2).round();
          final y1 = ((row + 1) * image.height / 2).round();
          _expectContained(image.rgba, image.width, x0, y0, x1, y1,
              '${file.path} frame ${row * 4 + column}');
        }
      }
    }
  });

  test(
      'all standalone furniture and chest sprites have safe transparent bounds',
      () async {
    final paths = <String>{
      for (final item in shopCatalog)
        if (FurnitureArt.assetForItem(item.id) case final path?) path,
      for (final tier in ChestTier.values) ...[
        tier.assetPath,
        tier.openedAssetPath,
      ],
    };
    expect(paths, hasLength(214));
    for (final path in paths) {
      final image = await _decode(path);
      _expectContained(
        image.rgba,
        image.width,
        0,
        0,
        image.width,
        image.height,
        path,
      );
    }
  });

  test('all game UI sprites and visual effects have safe transparent bounds',
      () async {
    final paths = <String>{
      for (final kind in GameIconKind.values) kind.assetPath,
      GameVfxAssets.chestBurst,
      GameVfxAssets.spectralAura,
      GameVfxAssets.evolutionRuneRing,
      GameVfxAssets.evolutionEnergySpiral,
      GameVfxAssets.evolutionRevealBurst,
      GameVfxAssets.evolutionFrameAtlas,
      for (var index = 0; index < 20; index++)
        GameVfxAssets.evolutionFrame(index),
      for (final relic in MysticRelic.values) relic.assetPath,
      'assets/images/relics/egg_crack_magic.png',
    };
    expect(paths, hasLength(69));
    for (final path in paths) {
      final image = await _decode(path);
      expect(image.width / image.height, inInclusiveRange(.5, 2.0),
          reason: '$path must keep a usable natural aspect ratio');
      _expectContained(
        image.rgba,
        image.width,
        0,
        0,
        image.width,
        image.height,
        path,
      );
    }
  });

  test('all portrait and Relic animation sprites are complete and contained',
      () async {
    final encodedPortraits = <String>{};
    for (final portrait in profilePortraitCatalog) {
      encodedPortraits
          .add(base64Encode(await File(portrait.assetPath).readAsBytes()));
      final image = await _decode(portrait.assetPath);
      expect(image.width, 256, reason: portrait.assetPath);
      expect(image.height, 256, reason: portrait.assetPath);
      _expectContained(
        image.rgba,
        image.width,
        0,
        0,
        image.width,
        image.height,
        portrait.assetPath,
      );
      _expectInsidePortraitCircle(
        image.rgba,
        image.width,
        image.height,
        portrait.assetPath,
      );
    }
    expect(encodedPortraits, hasLength(100));
    for (final relic in MysticRelic.values) {
      final encodedFrames = <String>{};
      for (var frame = 0; frame < 20; frame++) {
        final path = relic.animationFrameAsset(frame);
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: path);
        encodedFrames.add(base64Encode(await file.readAsBytes()));
        final image = await _decode(path);
        expect(image.width, 512, reason: path);
        expect(image.height, 512, reason: path);
        _expectContained(
          image.rgba,
          image.width,
          0,
          0,
          image.width,
          image.height,
          path,
        );
      }
      expect(encodedFrames, hasLength(20), reason: relic.name);
    }
  });

  test('Tower banner sprites stay wide and inside their safe canvas', () async {
    for (final path in const [
      GameBannerAssets.draconomicon,
      GameBannerAssets.myDragons,
    ]) {
      final image = await _decode(path);
      expect(image.width / image.height, inInclusiveRange(2.9, 3.1),
          reason: '$path must remain a single wide button');
      for (final x in [60, image.width - 61]) {
        expect(image.rgba[(30 * image.width + x) * 4 + 3], 0,
            reason: '$path must not contain a rectangular background');
      }
      _expectContained(
        image.rgba,
        image.width,
        0,
        0,
        image.width,
        image.height,
        path,
      );
    }
  });

  test('every room and rooftop lighting render is present and visually unique',
      () async {
    final paths = <String>{
      for (final room in houseRoomCatalog) ...{
        room.backgroundAsset,
        room.backgroundForPhase(HavenDayPhase.day),
        room.backgroundForPhase(HavenDayPhase.night),
      },
      for (final phase in HavenDayPhase.values)
        'assets/images/tower_nest_${phase.assetKey}.webp',
    };
    expect(paths, hasLength(31));
    final fingerprints = <int>{};
    for (final path in paths) {
      final bytes = await File(path).readAsBytes();
      final image = await _decode(path);
      expect(image.width, greaterThanOrEqualTo(960), reason: path);
      expect(image.height, greaterThanOrEqualTo(540), reason: path);
      expect(image.width / image.height, greaterThan(1.15), reason: path);
      fingerprints.add(Object.hash(bytes.length, Object.hashAll(bytes)));
    }
    expect(fingerprints, hasLength(paths.length));
  });

  test('Trial card art and dragon-free game backgrounds are release quality',
      () async {
    const paths = [
      'assets/images/ui/trials/trial_cavern_flight.webp',
      'assets/images/ui/trials/trial_ruin_breaker.webp',
      'assets/images/ui/trials/trial_runeweaver.webp',
      'assets/images/ui/trials/trial_cavern_background.webp',
      'assets/images/ui/trials/trial_ruin_background.webp',
      'assets/images/ui/trials/trial_rune_background.webp',
    ];
    final fingerprints = <int>{};
    for (final path in paths) {
      final bytes = await File(path).readAsBytes();
      final image = await _decode(path);
      expect(image.width, 1536, reason: path);
      expect(image.height, 1024, reason: path);
      expect(bytes.length, greaterThan(1000000),
          reason: '$path should retain detailed source art');
      fingerprints.add(Object.hash(bytes.length, Object.hashAll(bytes)));
    }
    expect(fingerprints, hasLength(paths.length));

    const wingsPath = 'assets/images/ui/trials/trial_flight_wings.png';
    final wingImage = await _decode(wingsPath);
    expect(wingImage.width, wingImage.height * 3);
    final bytes = wingImage.rgba;
    expect(
      List.generate(3, (frame) {
        final left = frame * wingImage.height;
        var opaquePixels = 0;
        for (var y = 0; y < wingImage.height; y += 4) {
          for (var x = left; x < left + wingImage.height; x += 4) {
            if (bytes[(y * wingImage.width + x) * 4 + 3] > 32) {
              opaquePixels++;
            }
          }
        }
        return opaquePixels;
      }),
      everyElement(greaterThan(1000)),
      reason: 'every flight frame needs a complete transparent wing pair',
    );
  });
}
