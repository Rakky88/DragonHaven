import 'dart:io';

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  for (final path in arguments) {
    final image = decodeImage(await File(path).readAsBytes());
    if (image == null) throw StateError('Cannot decode $path');
    stdout.writeln(
        '$path ${image.width}x${image.height} channels=${image.numChannels}');
    for (final y in [0, 8, 16, 24, 32, 40, 48, 56, 64, 96]) {
      final values = <String>[];
      for (final x in [0, 8, 16, 24, 32, 40, 48, 56, 64, 96]) {
        final p = image.getPixel(x, y);
        values
            .add('${p.r.toInt()},${p.g.toInt()},${p.b.toInt()},${p.a.toInt()}');
      }
      stdout.writeln('y=$y ${values.join(' | ')}');
    }
  }
}
