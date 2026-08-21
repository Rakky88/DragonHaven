import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/widgets/dragon_art.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('egg and every Hatchling sprite fit fully inside their image box',
      () async {
    for (final path in [
      DragonArtwork.eggAsset,
      for (final lineage in dragonLineages)
        DragonArtwork.hatchlingAsset(lineage.id),
    ]) {
      final image = await _decode(path);
      _expectContained(
          image.rgba, image.width, 0, 0, image.width, image.height, path);
    }
  });

  test('every Wyrmling and Ascended frame fits its atlas quadrant', () async {
    for (final lineage in dragonLineages) {
      final image = await _decode(DragonArtwork.formsAsset(lineage.id));
      for (var row = 0; row < 2; row++) {
        for (var column = 0; column < 2; column++) {
          final x0 = (column * image.width / 2).round();
          final x1 = ((column + 1) * image.width / 2).round();
          final y0 = (row * image.height / 2).round();
          final y1 = ((row + 1) * image.height / 2).round();
          _expectContained(image.rgba, image.width, x0, y0, x1, y1,
              '${lineage.id} frame ${row * 2 + column}');
        }
      }
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
}
