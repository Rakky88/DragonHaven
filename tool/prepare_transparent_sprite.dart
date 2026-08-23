import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length < 4 || arguments.length > 5) {
    stderr.writeln(
      'Usage: dart run tool/prepare_transparent_sprite.dart '
      '<input> <output.webp> <canvas-size> <content-size> '
      '[normal|silhouette|spectral]',
    );
    exitCode = 64;
    return;
  }

  final input = arguments[0];
  final output = arguments[1];
  final canvasSize = int.parse(arguments[2]);
  final contentSize = int.parse(arguments[3]);
  final variant = arguments.length == 5 ? arguments[4] : 'normal';
  if (!{'normal', 'silhouette', 'spectral'}.contains(variant)) {
    throw ArgumentError.value(variant, 'variant', 'Unsupported variant.');
  }
  if (canvasSize <= 0 || contentSize <= 0 || contentSize > canvasSize) {
    throw ArgumentError('Invalid canvas/content dimensions.');
  }

  final source = decodeImage(await File(input).readAsBytes());
  if (source == null) throw StateError('Could not decode $input');

  final scale = math.min(
    contentSize / source.width,
    contentSize / source.height,
  );
  final width = math.max(1, (source.width * scale).round());
  final height = math.max(1, (source.height * scale).round());
  final resized = copyResize(
    source,
    width: width,
    height: height,
    interpolation: Interpolation.cubic,
  );
  final canvas = Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  )..clear(ColorRgba8(0, 0, 0, 0));
  compositeImage(
    canvas,
    resized,
    dstX: (canvasSize - width) ~/ 2,
    dstY: (canvasSize - height) ~/ 2,
  );
  if (variant == 'silhouette') {
    for (final pixel in canvas) {
      pixel.setRgba(45, 41, 65, pixel.a);
    }
  } else if (variant == 'spectral') {
    for (final pixel in canvas) {
      final red = pixel.r;
      final green = pixel.g;
      final blue = pixel.b;
      pixel.setRgba(
        (.25 * red + .75 * green + .25 * blue + 18).clamp(0, 255),
        (.65 * red + .15 * green + .55 * blue + 4).clamp(0, 255),
        (.35 * red + .55 * green + .15 * blue + 26).clamp(0, 255),
        pixel.a,
      );
    }
  }
  await File(output).writeAsBytes(encodeWebP(canvas), flush: true);
  stdout.writeln(
    '$output: ${canvas.width}x${canvas.height} $variant lossless WebP',
  );
}
