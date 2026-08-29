import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';

bool _insideHalo(int x, int y) {
  const centerX = 512.0;
  const centerY = 282.0;
  final dx = (x - centerX) / 162.0;
  final dy = (y - centerY) / 166.0;
  return dx * dx + dy * dy <= 1;
}

bool _isNeutralGlow(Pixel pixel) {
  if (pixel.a == 0) return false;
  final red = pixel.r.toInt();
  final green = pixel.g.toInt();
  final blue = pixel.b.toInt();
  final minimum = [red, green, blue].reduce((a, b) => a < b ? a : b);
  final maximum = [red, green, blue].reduce((a, b) => a > b ? a : b);
  return minimum >= 208 && maximum - minimum <= 34;
}

bool _insideNeckFeathers(int x, int y) {
  final dx = (x - 535) / 61;
  final dy = (y - 414) / 112;
  return dx * dx + dy * dy <= 1;
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/clean_cluckatrice_mastery_halo.dart '
      '<input> <output.webp> <blue-preview.png>',
    );
    exitCode = 64;
    return;
  }

  final image = decodeImage(await File(arguments[0]).readAsBytes());
  if (image == null || image.width != 1024 || image.height != 1024) {
    throw StateError('The Cluckatrice Mastery source must be 1024x1024.');
  }

  final candidate = Uint8List(image.width * image.height);
  for (var y = 116; y <= 448; y++) {
    for (var x = 350; x <= 674; x++) {
      if (!_insideHalo(x, y) || !_isNeutralGlow(image.getPixel(x, y))) {
        continue;
      }
      var neutralNeighbors = 0;
      var sampledNeighbors = 0;
      for (var offsetY = -3; offsetY <= 3; offsetY++) {
        for (var offsetX = -3; offsetX <= 3; offsetX++) {
          final sampleX = x + offsetX;
          final sampleY = y + offsetY;
          if (sampleX < 0 ||
              sampleY < 0 ||
              sampleX >= image.width ||
              sampleY >= image.height) {
            continue;
          }
          sampledNeighbors++;
          if (_isNeutralGlow(image.getPixel(sampleX, sampleY))) {
            neutralNeighbors++;
          }
        }
      }
      if (neutralNeighbors / sampledNeighbors >= .58) {
        candidate[y * image.width + x] = 1;
      }
    }
  }

  // Keep only sizeable neutral areas. Fine ivory feather highlights are small
  // and textured, while the unwanted generated halo fill forms broad islands.
  final remove = Uint8List(image.width * image.height);
  final visited = Uint8List(image.width * image.height);
  const neighbors = [(-1, 0), (1, 0), (0, -1), (0, 1)];
  var removed = 0;
  for (var y = 116; y <= 448; y++) {
    for (var x = 350; x <= 674; x++) {
      final start = y * image.width + x;
      if (candidate[start] == 0 || visited[start] != 0) continue;
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
          if (nextX < 350 || nextX > 674 || nextY < 116 || nextY > 448) {
            continue;
          }
          final next = nextY * image.width + nextX;
          if (candidate[next] != 0 && visited[next] == 0) {
            visited[next] = 1;
            queue.add(next);
          }
        }
      }
      if (component.length < 36) continue;
      for (final index in component) {
        remove[index] = 1;
        removed++;
      }
    }
  }

  // Include the immediately adjoining light fringe so it cannot leave a white
  // outline on saturated review backgrounds.
  for (var pass = 0; pass < 3; pass++) {
    final grow = Uint8List.fromList(remove);
    for (var y = 117; y < 448; y++) {
      for (var x = 351; x < 674; x++) {
        final index = y * image.width + x;
        if (remove[index] != 0 || !_isNeutralGlow(image.getPixel(x, y))) {
          continue;
        }
        if (remove[index - 1] != 0 ||
            remove[index + 1] != 0 ||
            remove[index - image.width] != 0 ||
            remove[index + image.width] != 0) {
          grow[index] = 1;
          removed++;
        }
      }
    }
    remove.setAll(0, grow);
  }

  for (var y = 116; y <= 448; y++) {
    for (var x = 350; x <= 674; x++) {
      if (remove[y * image.width + x] != 0 && !_insideNeckFeathers(x, y)) {
        image.getPixel(x, y).setRgba(0, 0, 0, 0);
      }
    }
  }

  await File(arguments[1]).writeAsBytes(encodeWebP(image), flush: true);
  final preview = Image(width: 1024, height: 1024, numChannels: 4)
    ..clear(ColorRgba8(25, 118, 210, 255));
  compositeImage(preview, image);
  await File(arguments[2]).writeAsBytes(encodePng(preview), flush: true);
  stdout.writeln('Removed $removed neutral halo-background pixels.');
}
