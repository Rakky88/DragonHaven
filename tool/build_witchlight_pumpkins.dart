import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

/// Package the six image-generated faces using their magenta extraction matte.
/// Keep their common canvas registration: only the carved face should stand out.
Future<void> main() async {
  for (var variant = 0; variant < 6; variant++) {
    final input =
        File('artwork_sources/witchlight_pumpkins/pumpkin_$variant.png');
    final sprite =
        decodePng(await input.readAsBytes())!.convert(numChannels: 4);
    for (final pixel in sprite) {
      final r = pixel.r.toDouble(),
          g = pixel.g.toDouble(),
          b = pixel.b.toDouble();
      // Magenta has both red and blue above green. Warm pumpkin highlights,
      // brown shadows and green leaves stay opaque, including dark face edges.
      final key = ((math.min(r, b) - g - 24) / 150).clamp(0.0, 1.0);
      if (key <= 0) continue;
      final alpha = 1 - key;
      if (alpha < .025) {
        pixel.setRgba(0, 0, 0, 0);
      } else {
        pixel.setRgba(
            ((r - 255 * key) / alpha).clamp(0, 255).round(),
            (g / alpha).clamp(0, 255).round(),
            ((b - 255 * key) / alpha).clamp(0, 255).round(),
            (alpha * 255).round());
      }
    }
    final output = copyResize(sprite,
        width: 384, height: 384, interpolation: Interpolation.average);
    final path = 'assets/images/events/halloween/arcana_pumpkin_$variant.webp';
    await File(path).writeAsBytes(encodeWebP(output), flush: true);
    stdout.writeln(path);
  }
}
