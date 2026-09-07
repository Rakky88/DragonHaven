import 'dart:io';

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    stderr.writeln('Usage: dart run tool/inspect_image_alpha.dart <images...>');
    exitCode = 64;
    return;
  }
  for (final path in arguments) {
    final image = decodeImage(await File(path).readAsBytes());
    if (image == null) {
      stdout.writeln('$path: unreadable');
      continue;
    }
    var transparent = 0;
    var translucent = 0;
    var opaque = 0;
    final buckets = List<int>.filled(5, 0);
    for (final pixel in image) {
      if (pixel.a == 0) {
        transparent++;
      } else if (pixel.a < 255) {
        translucent++;
      } else {
        opaque++;
      }
      buckets[(pixel.a.clamp(0, 254) * 5 ~/ 255).clamp(0, 4)]++;
    }
    stdout.writeln(
      '$path: ${image.width}x${image.height}; '
      'transparent=$transparent translucent=$translucent opaque=$opaque; '
      'cornerAlpha=${image.getPixel(0, 0).a}',
    );
    stdout.writeln(
        '  alpha buckets 0-50/51-101/102-152/153-203/204-255: $buckets');
  }
}
