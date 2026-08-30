import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  var width = 512;
  var height = 512;
  var padding = 16;
  int? jpegQuality;
  final paths = <String>[];

  for (final argument in arguments) {
    if (argument.startsWith('--width=')) {
      width = int.parse(argument.substring('--width='.length));
    } else if (argument.startsWith('--height=')) {
      height = int.parse(argument.substring('--height='.length));
    } else if (argument.startsWith('--padding=')) {
      padding = int.parse(argument.substring('--padding='.length));
    } else if (argument.startsWith('--jpeg-quality=')) {
      jpegQuality = int.parse(argument.substring('--jpeg-quality='.length));
    } else {
      paths.add(argument);
    }
  }

  if (paths.isEmpty ||
      width < 64 ||
      height < 64 ||
      padding < 0 ||
      padding * 2 >= width ||
      padding * 2 >= height) {
    stderr.writeln(
      'Usage: dart run tool/prepare_generated_game_asset.dart '
      '--width=512 --height=512 [--padding=16] '
      '[--jpeg-quality=88] <images...>',
    );
    exitCode = 64;
    return;
  }

  for (final path in paths) {
    final file = File(path);
    final decoded = decodeImage(await file.readAsBytes());
    if (decoded == null) throw StateError('Could not decode $path');

    final availableWidth = width - padding * 2;
    final availableHeight = height - padding * 2;
    final scale = math.min(
      availableWidth / decoded.width,
      availableHeight / decoded.height,
    );
    final resized = copyResize(
      decoded,
      width: math.max(1, (decoded.width * scale).round()),
      height: math.max(1, (decoded.height * scale).round()),
      interpolation: Interpolation.cubic,
    );
    final prepared = Image(width: width, height: height, numChannels: 4)
      ..clear(ColorRgba8(0, 0, 0, 0));
    compositeImage(
      prepared,
      resized,
      dstX: (width - resized.width) ~/ 2,
      dstY: (height - resized.height) ~/ 2,
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

    var outputPath = path;
    if (jpegQuality case final quality?) {
      if (quality < 1 || quality > 100) {
        throw ArgumentError.value(quality, 'jpegQuality', 'must be 1..100');
      }
      outputPath = path.replaceFirst(RegExp(r'\.[^.]+$'), '.jpg');
      await File(outputPath).writeAsBytes(
        encodeJpg(prepared, quality: quality),
        flush: true,
      );
      if (outputPath != path) await file.delete();
    } else {
      await file.writeAsBytes(encodePng(prepared, level: 9), flush: true);
    }
    stdout.writeln(
      '$path ${decoded.width}x${decoded.height} -> $outputPath '
      '${prepared.width}x${prepared.height}; cleared=$cleared',
    );
  }
}
