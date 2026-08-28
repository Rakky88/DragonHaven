import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';

bool _looksLikeCheckerboard(Pixel pixel) {
  if (pixel.a == 0) return false;
  final minimum = [pixel.r, pixel.g, pixel.b].reduce((a, b) => a < b ? a : b);
  final maximum = [pixel.r, pixel.g, pixel.b].reduce((a, b) => a > b ? a : b);
  return minimum >= 232 && maximum - minimum <= 7;
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/remove_generated_checkerboard.dart '
      '<input> <output.webp>',
    );
    exitCode = 64;
    return;
  }
  final image = decodeImage(await File(arguments[0]).readAsBytes());
  if (image == null) throw StateError('Could not decode ${arguments[0]}');
  var opaqueMinX = image.width;
  var opaqueMinY = image.height;
  for (final pixel in image) {
    if (pixel.a == 0) continue;
    if (pixel.x < opaqueMinX) opaqueMinX = pixel.x;
    if (pixel.y < opaqueMinY) opaqueMinY = pixel.y;
  }
  if (opaqueMinX == image.width || opaqueMinY == image.height) {
    throw StateError('${arguments[0]} contains no opaque pixels.');
  }
  final horizontalLightPhases = <bool>[
    for (var x = 0; x < image.width; x++)
      image.getPixel(x, opaqueMinY).r.toInt() >= 248,
  ];
  final verticalLightPhases = <bool>[
    for (var y = 0; y < image.height; y++)
      image.getPixel(opaqueMinX, y).r.toInt() >= 248,
  ];
  bool isCheckerPixel(int x, int y) {
    final pixel = image.getPixel(x, y);
    if (!_looksLikeCheckerboard(pixel)) return false;
    // The source checker was scaled, so its cells alternate between 14 and 15
    // pixels instead of having a stable integer period. The untouched top row
    // and left column provide the exact horizontal/vertical phase at every
    // coordinate. Combining their light/dark phase reconstructs the expected
    // cell without guessing a period.
    final horizontalLight = horizontalLightPhases[x];
    final verticalLight = verticalLightPhases[y];
    final expectedLight = horizontalLight == verticalLight;
    final actualLight = pixel.r.toInt() >= 248;
    return actualLight == expectedLight;
  }

  final visited = Uint8List(image.width * image.height);
  final queue = Queue<int>();

  void seed(int x, int y) {
    final index = y * image.width + x;
    if (visited[index] != 0 || !isCheckerPixel(x, y)) {
      return;
    }
    visited[index] = 1;
    queue.add(index);
  }

  for (var x = 0; x < image.width; x++) {
    seed(x, 0);
    seed(x, image.height - 1);
  }
  for (var y = 0; y < image.height; y++) {
    seed(0, y);
    seed(image.width - 1, y);
  }
  // Normalized assets have transparent padding around the generated square.
  // Seed any checker pixel that directly touches that transparent padding.
  for (var y = 1; y < image.height - 1; y++) {
    for (var x = 1; x < image.width - 1; x++) {
      if (!isCheckerPixel(x, y)) continue;
      if (image.getPixel(x - 1, y).a == 0 ||
          image.getPixel(x + 1, y).a == 0 ||
          image.getPixel(x, y - 1).a == 0 ||
          image.getPixel(x, y + 1).a == 0) {
        seed(x, y);
      }
    }
  }

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
  while (queue.isNotEmpty) {
    final index = queue.removeFirst();
    final x = index % image.width;
    final y = index ~/ image.width;
    image.getPixel(x, y).setRgba(0, 0, 0, 0);
    for (final (dx, dy) in neighbors) {
      final nextX = x + dx;
      final nextY = y + dy;
      if (nextX < 0 ||
          nextY < 0 ||
          nextX >= image.width ||
          nextY >= image.height) {
        continue;
      }
      seed(nextX, nextY);
    }
  }

  // The generated checker can also be fully enclosed by legs, tails or wings,
  // so it cannot be reached by the edge flood-fill. Remove only large compact
  // islands of the same neutral pixels. Tiny neutral highlights inside ivory
  // feathers are intentionally preserved.
  var enclosedRemoved = 0;
  final enclosedComponentSizes = <int>[];
  final enclosedVisited = Uint8List(image.width * image.height);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final start = y * image.width + x;
      if (enclosedVisited[start] != 0 || !isCheckerPixel(x, y)) {
        continue;
      }
      final component = <int>[];
      final componentQueue = Queue<int>()..add(start);
      enclosedVisited[start] = 1;
      while (componentQueue.isNotEmpty) {
        final index = componentQueue.removeFirst();
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
          if (enclosedVisited[next] == 0 && isCheckerPixel(nextX, nextY)) {
            enclosedVisited[next] = 1;
            componentQueue.add(next);
          }
        }
      }
      enclosedComponentSizes.add(component.length);
      if (component.length >= 2048) {
        for (final index in component) {
          image
              .getPixel(index % image.width, index ~/ image.width)
              .setRgba(0, 0, 0, 0);
        }
        enclosedRemoved += component.length;
      }
    }
  }

  await File(arguments[1]).writeAsBytes(encodeWebP(image), flush: true);
  enclosedComponentSizes.sort((a, b) => b.compareTo(a));
  stdout.writeln('Removed ${visited.where((value) => value != 0).length} '
      'connected and $enclosedRemoved enclosed checkerboard pixels from '
      '${arguments[0]}.');
  stdout.writeln('Largest enclosed neutral components: '
      '${enclosedComponentSizes.take(10).join(', ')}');
}
