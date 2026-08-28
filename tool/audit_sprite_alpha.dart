import 'dart:io';

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    stderr.writeln('Usage: dart run tool/audit_sprite_alpha.dart <images...>');
    exitCode = 64;
    return;
  }
  for (final path in arguments) {
    final decoded = decodeImage(await File(path).readAsBytes());
    if (decoded == null) throw StateError('Could not decode $path');
    var transparent = 0;
    var translucent = 0;
    var opaque = 0;
    final colors = <int, int>{};
    for (final pixel in decoded) {
      if (pixel.a == 0) {
        transparent++;
      } else if (pixel.a < 255) {
        translucent++;
      } else {
        opaque++;
        final key =
            (pixel.r.toInt() << 16) | (pixel.g.toInt() << 8) | pixel.b.toInt();
        colors.update(key, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    stdout.writeln(
      '$path ${decoded.width}x${decoded.height}: '
      'transparent=$transparent translucent=$translucent opaque=$opaque',
    );
    final common = colors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    stdout.writeln(common.take(8).map((entry) {
      final hex = entry.key.toRadixString(16).padLeft(6, '0');
      return '#$hex=${entry.value}';
    }).join(' '));
  }
}
