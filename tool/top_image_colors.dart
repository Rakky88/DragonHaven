import 'dart:io';

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart run tool/top_image_colors.dart <image>');
    exitCode = 64;
    return;
  }
  final image = decodeImage(await File(arguments.single).readAsBytes());
  if (image == null) throw StateError('Could not decode ${arguments.single}');
  final counts = <int, int>{};
  for (final pixel in image) {
    final key = (pixel.r.toInt() << 24) |
        (pixel.g.toInt() << 16) |
        (pixel.b.toInt() << 8) |
        pixel.a.toInt();
    counts[key] = (counts[key] ?? 0) + 1;
  }
  final colors = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in colors.take(30)) {
    final key = entry.key;
    stdout.writeln(
      '${entry.value}: '
      '${(key >> 24) & 255},${(key >> 16) & 255},${(key >> 8) & 255},${key & 255}',
    );
  }
}
