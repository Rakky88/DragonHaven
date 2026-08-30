import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  var maximumSize = 512;
  var paths = arguments;
  if (paths.isNotEmpty && paths.first.startsWith('--size=')) {
    maximumSize = int.parse(paths.first.substring('--size='.length));
    paths = paths.skip(1).toList(growable: false);
  }
  if (paths.isEmpty || maximumSize < 64) {
    stderr.writeln(
      'Usage: dart run tool/prepare_generated_ui_sprite.dart '
      '[--size=512] <pngs...>',
    );
    exitCode = 64;
    return;
  }
  for (final path in paths) {
    final file = File(path);
    final decoded = decodeImage(await file.readAsBytes());
    if (decoded == null) throw StateError('Could not decode $path');
    final contentSize = maximumSize - 32;
    final scale = contentSize / math.max(decoded.width, decoded.height);
    final resized = copyResize(
      decoded,
      width: (decoded.width * scale).round(),
      height: (decoded.height * scale).round(),
      interpolation: Interpolation.cubic,
    );
    final prepared = Image(
      width: maximumSize,
      height: maximumSize,
      numChannels: 4,
    )..clear(ColorRgba8(0, 0, 0, 0));
    compositeImage(
      prepared,
      resized,
      dstX: (maximumSize - resized.width) ~/ 2,
      dstY: (maximumSize - resized.height) ~/ 2,
    );
    var cleared = 0;
    for (var y = 0; y < prepared.height; y++) {
      for (var x = 0; x < prepared.width; x++) {
        final pixel = prepared.getPixel(x, y);
        if (pixel.a >= 8) continue;
        prepared.setPixelRgba(x, y, 0, 0, 0, 0);
        cleared++;
      }
    }
    await file.writeAsBytes(encodePng(prepared, level: 9), flush: true);
    stdout.writeln(
      '$path ${decoded.width}x${decoded.height} -> '
      '${prepared.width}x${prepared.height}; cleared=$cleared',
    );
  }
}
