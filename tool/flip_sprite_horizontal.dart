import 'dart:io';

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart run tool/flip_sprite_horizontal.dart <image>');
    exitCode = 64;
    return;
  }

  final file = File(arguments.single);
  final decoded = decodeImage(await file.readAsBytes());
  if (decoded == null) {
    throw StateError('Could not decode ${file.path}');
  }

  final mirrored = flipHorizontal(decoded);
  await file.writeAsBytes(encodeWebP(mirrored), flush: true);
  stdout.writeln(
    '${file.path}: horizontally mirrored '
    '(${mirrored.width}x${mirrored.height}, lossless WebP)',
  );
}
