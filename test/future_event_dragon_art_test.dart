import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart';

void main() {
  const families = <String, String>{
    'halloween': 'gloamgourd',
    'christmas': 'hollyfrost',
    'new_year': 'dawnchime',
    'valentines': 'rosevow',
    'pridefest': 'spectrumplume',
  };
  const forms = <String>[
    'hatchling',
    'wyrmling',
    'might',
    'arcana',
    'spirit',
    'mastery',
  ];

  test('future event families contain six safe transparent sprites each', () {
    for (final family in families.entries) {
      for (final form in forms) {
        final path = 'future_event_art/dragon_families/'
            '${family.key}/sprites/${family.value}_$form.webp';
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: path);
        final image = decodeImage(file.readAsBytesSync());
        expect(image, isNotNull, reason: path);
        expect(image!.width, 1024, reason: path);
        expect(image.height, 1024, reason: path);

        var transparent = 0;
        var visible = 0;
        var edgeAlpha = 0;
        var minX = image.width;
        var minY = image.height;
        var maxX = -1;
        var maxY = -1;
        for (final pixel in image) {
          final alpha = pixel.a.toInt();
          if (alpha <= 8) {
            transparent++;
            continue;
          }
          visible++;
          minX = math.min(minX, pixel.x);
          minY = math.min(minY, pixel.y);
          maxX = math.max(maxX, pixel.x);
          maxY = math.max(maxY, pixel.y);
          if (pixel.x == 0 ||
              pixel.y == 0 ||
              pixel.x == image.width - 1 ||
              pixel.y == image.height - 1) {
            edgeAlpha = math.max(edgeAlpha, alpha);
          }
        }
        final pixels = image.width * image.height;
        expect(transparent, greaterThan(pixels ~/ 5), reason: path);
        expect(visible, greaterThan(pixels ~/ 100), reason: path);
        expect(edgeAlpha, 0, reason: path);
        final margin = math.min(
          math.min(minX, image.width - 1 - maxX),
          math.min(minY, image.height - 1 - maxY),
        );
        expect(margin, greaterThanOrEqualTo(64), reason: path);
      }
    }
  });
}
