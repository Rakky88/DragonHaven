import 'dart:io';

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length < 3) {
    stderr.writeln(
      'Usage: dart run tool/compare_sprite_alpha.dart '
      '<before-directory> <after-directory> <filename>...',
    );
    exitCode = 64;
    return;
  }
  final beforeDirectory = arguments[0];
  final afterDirectory = arguments[1];
  for (final filename in arguments.skip(2)) {
    final before = decodeImage(
      await File('$beforeDirectory/$filename').readAsBytes(),
    );
    final after = decodeImage(
      await File('$afterDirectory/$filename').readAsBytes(),
    );
    if (before == null || after == null) {
      throw StateError('Could not decode $filename');
    }
    if (before.width != after.width || before.height != after.height) {
      throw StateError('Dimensions changed for $filename');
    }
    var visibleBefore = 0;
    var removed = 0;
    var minX = before.width;
    var minY = before.height;
    var maxX = -1;
    var maxY = -1;
    for (var y = 0; y < before.height; y++) {
      for (var x = 0; x < before.width; x++) {
        final beforeAlpha = before.getPixel(x, y).a.toInt();
        final afterAlpha = after.getPixel(x, y).a.toInt();
        if (beforeAlpha > 8) visibleBefore++;
        if (beforeAlpha > 8 && afterAlpha <= 8) {
          removed++;
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }
    final percent = visibleBefore == 0 ? 0 : removed * 100 / visibleBefore;
    final bounds = maxX < 0 ? 'none' : '$minX,$minY-$maxX,$maxY';
    stdout.writeln(
      '$filename: removed=$removed '
      '(${percent.toStringAsFixed(3)}% of foreground), bounds=$bounds',
    );
  }
}
