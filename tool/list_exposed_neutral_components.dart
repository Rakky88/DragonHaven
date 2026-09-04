import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty || arguments.length > 2) {
    stderr.writeln(
      'Usage: dart run tool/list_exposed_neutral_components.dart '
      '<image> [--all]',
    );
    exitCode = 64;
    return;
  }
  final includeEnclosed = arguments.contains('--all');
  final imagePath = arguments.firstWhere((argument) => argument != '--all');
  final image = decodeImage(await File(imagePath).readAsBytes());
  if (image == null) throw StateError('Could not decode $imagePath');
  final width = image.width;
  final height = image.height;
  final candidate = List<bool>.filled(width * height, false);
  final visited = List<bool>.filled(width * height, false);

  bool isNeutral(Pixel pixel) {
    if (pixel.a <= 8) return false;
    final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]
      ..sort();
    return channels.first >= 198 && channels.last - channels.first <= 30;
  }

  bool touchesTransparent(int x, int y) {
    for (var yy = math.max(0, y - 1); yy <= math.min(height - 1, y + 1); yy++) {
      for (var xx = math.max(0, x - 1);
          xx <= math.min(width - 1, x + 1);
          xx++) {
        if (xx == x && yy == y) continue;
        if (image.getPixel(xx, yy).a <= 8) return true;
      }
    }
    return false;
  }

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      candidate[y * width + x] = isNeutral(image.getPixel(x, y));
    }
  }

  final components = <({int size, int minX, int minY, int maxX, int maxY})>[];
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final start = y * width + x;
      if (!candidate[start] || visited[start]) continue;
      final queue = <int>[start];
      visited[start] = true;
      var cursor = 0;
      var size = 0;
      var minX = x;
      var minY = y;
      var maxX = x;
      var maxY = y;
      var exposed = false;
      while (cursor < queue.length) {
        final index = queue[cursor++];
        final px = index % width;
        final py = index ~/ width;
        size++;
        minX = math.min(minX, px);
        minY = math.min(minY, py);
        maxX = math.max(maxX, px);
        maxY = math.max(maxY, py);
        exposed = exposed || touchesTransparent(px, py);
        for (var yy = math.max(0, py - 1);
            yy <= math.min(height - 1, py + 1);
            yy++) {
          for (var xx = math.max(0, px - 1);
              xx <= math.min(width - 1, px + 1);
              xx++) {
            final next = yy * width + xx;
            if (!visited[next] && candidate[next]) {
              visited[next] = true;
              queue.add(next);
            }
          }
        }
      }
      if (exposed || includeEnclosed) {
        components.add(
          (size: size, minX: minX, minY: minY, maxX: maxX, maxY: maxY),
        );
      }
    }
  }
  components.sort((a, b) => b.size.compareTo(a.size));
  for (final component in components.take(30)) {
    stdout.writeln(
      '${component.size}: ${component.minX},${component.minY}-'
      '${component.maxX},${component.maxY}',
    );
  }
}
