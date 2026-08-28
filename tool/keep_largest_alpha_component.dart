import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/keep_largest_alpha_component.dart '
      '<input> <output.webp>',
    );
    exitCode = 64;
    return;
  }
  final image = decodeImage(await File(arguments[0]).readAsBytes());
  if (image == null) throw StateError('Could not decode ${arguments[0]}');
  final visited = Uint8List(image.width * image.height);
  var largest = <int>[];
  const neighbors = [
    (-1, -1),
    (0, -1),
    (1, -1),
    (-1, 0),
    (1, 0),
    (-1, 1),
    (0, 1),
    (1, 1),
  ];
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final start = y * image.width + x;
      if (visited[start] != 0 || image.getPixel(x, y).a == 0) continue;
      final component = <int>[];
      final queue = Queue<int>()..add(start);
      visited[start] = 1;
      while (queue.isNotEmpty) {
        final index = queue.removeFirst();
        component.add(index);
        final currentX = index % image.width;
        final currentY = index ~/ image.width;
        for (final (dx, dy) in neighbors) {
          final nextX = currentX + dx;
          final nextY = currentY + dy;
          if (nextX < 0 ||
              nextY < 0 ||
              nextX >= image.width ||
              nextY >= image.height) {
            continue;
          }
          final next = nextY * image.width + nextX;
          if (visited[next] == 0 && image.getPixel(nextX, nextY).a != 0) {
            visited[next] = 1;
            queue.add(next);
          }
        }
      }
      if (component.length > largest.length) largest = component;
    }
  }
  final keep = Uint8List(image.width * image.height);
  for (final index in largest) {
    keep[index] = 1;
  }
  var removed = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final index = y * image.width + x;
      final pixel = image.getPixel(x, y);
      if (pixel.a != 0 && keep[index] == 0) {
        pixel.setRgba(0, 0, 0, 0);
        removed++;
      }
    }
  }
  await File(arguments[1]).writeAsBytes(encodeWebP(image), flush: true);
  stdout.writeln(
    'Kept ${largest.length} connected subject pixels and removed '
    '$removed detached pixels.',
  );
}
