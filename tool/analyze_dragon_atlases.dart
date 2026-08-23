import 'dart:io';

import 'package:image/image.dart';

const _frames = <String, (int, int)>{
  'wyrmling': (0, 0),
  'might': (1, 0),
  'arcana': (0, 1),
  'spirit': (1, 1),
};

Future<void> main() async {
  final directory = Directory('assets/images/dragons');
  final atlases = directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('_forms.webp'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in atlases) {
    final atlas = decodeImage(await file.readAsBytes());
    if (atlas == null) throw StateError('Cannot decode ${file.path}');
    final cellWidth = atlas.width ~/ 2;
    final cellHeight = atlas.height ~/ 2;
    final family = file.uri.pathSegments.last.replaceFirst('_forms.webp', '');
    for (final frame in _frames.entries) {
      final originX = frame.value.$1 * cellWidth;
      final originY = frame.value.$2 * cellHeight;
      var minX = cellWidth;
      var minY = cellHeight;
      var maxX = -1;
      var maxY = -1;
      for (var y = 0; y < cellHeight; y++) {
        for (var x = 0; x < cellWidth; x++) {
          if (atlas.getPixel(originX + x, originY + y).a <= 8) continue;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
      if (maxX < 0) {
        stdout.writeln('$family:${frame.key} EMPTY');
        continue;
      }
      final margins = (
        left: minX,
        top: minY,
        right: cellWidth - 1 - maxX,
        bottom: cellHeight - 1 - maxY,
      );
      final minimum = [
        margins.left,
        margins.top,
        margins.right,
        margins.bottom,
      ].reduce((a, b) => a < b ? a : b);
      if (minimum <= 12) {
        stdout.writeln(
          '$family:${frame.key} '
          'L${margins.left} T${margins.top} '
          'R${margins.right} B${margins.bottom}',
        );
      }
    }
  }
}
