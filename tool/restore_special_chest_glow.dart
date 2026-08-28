import 'dart:io';

import 'package:image/image.dart';

bool _insideGlow(int x, int y) {
  const points = <(int, int)>[
    (216, 529),
    (386, 480),
    (742, 489),
    (760, 536),
    (633, 606),
    (315, 584),
  ];
  var inside = false;
  for (var index = 0, previous = points.length - 1;
      index < points.length;
      previous = index++) {
    final (x1, y1) = points[index];
    final (x2, y2) = points[previous];
    final crosses =
        (y1 > y) != (y2 > y) && x < (x2 - x1) * (y - y1) / (y2 - y1) + x1;
    if (crosses) inside = !inside;
  }
  return inside;
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/restore_special_chest_glow.dart '
      '<original> <transparent-base> <output.webp>',
    );
    exitCode = 64;
    return;
  }
  final original = decodeImage(await File(arguments[0]).readAsBytes());
  final cleaned = decodeImage(await File(arguments[1]).readAsBytes());
  if (original == null || cleaned == null) {
    throw StateError('Could not decode source images.');
  }
  if (original.width != 1024 ||
      original.height != 1024 ||
      cleaned.width != 1024 ||
      cleaned.height != 1024) {
    throw StateError('Special Chest source assets must remain 1024x1024.');
  }
  for (var y = 0; y < cleaned.height; y++) {
    for (var x = 0; x < cleaned.width; x++) {
      if (!_insideGlow(x, y)) continue;
      final source = original.getPixel(x, y);
      cleaned.getPixel(x, y).setRgba(
            source.r,
            source.g,
            source.b,
            source.a,
          );
    }
  }
  await File(arguments[2]).writeAsBytes(encodeWebP(cleaned), flush: true);
  stdout.writeln('Restored the protected Special Chest glow polygon.');
}
