import 'dart:io';

import 'package:image/image.dart';

bool _isBrightNeutral(Pixel pixel) {
  if (pixel.a < 8) return false;
  final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]..sort();
  return channels.first >= 215 && channels.last - channels.first <= 20;
}

int _removeDetachedFragments(Image image) {
  const componentAlphaThreshold = 32;
  final visited = List<bool>.filled(image.width * image.height, false);
  final components = <List<int>>[];
  for (var start = 0; start < visited.length; start++) {
    if (visited[start]) continue;
    final startX = start % image.width;
    final startY = start ~/ image.width;
    if (image.getPixel(startX, startY).a < componentAlphaThreshold) {
      visited[start] = true;
      continue;
    }

    visited[start] = true;
    final queue = <int>[start];
    var cursor = 0;
    while (cursor < queue.length) {
      final index = queue[cursor++];
      final x = index % image.width;
      final y = index ~/ image.width;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          final nextX = x + dx;
          final nextY = y + dy;
          if (nextX < 0 ||
              nextX >= image.width ||
              nextY < 0 ||
              nextY >= image.height) {
            continue;
          }
          final next = nextY * image.width + nextX;
          if (visited[next]) continue;
          if (image.getPixel(nextX, nextY).a < componentAlphaThreshold) {
            visited[next] = true;
            continue;
          }
          visited[next] = true;
          queue.add(next);
        }
      }
    }
    components.add(queue);
  }

  if (components.length <= 1) return 0;
  components.sort((left, right) => right.length.compareTo(left.length));
  var removed = 0;
  for (final component in components.skip(1)) {
    removed += component.length;
    for (final index in component) {
      image
          .getPixel(index % image.width, index ~/ image.width)
          .setRgba(0, 0, 0, 0);
    }
  }
  return removed;
}

int _visiblePixelCount(Image image) {
  var count = 0;
  for (final pixel in image) {
    if (pixel.a >= 8) count++;
  }
  return count;
}

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    throw ArgumentError(
      'Usage: [--report] <sprite.webp> [<sprite.webp> ...]',
    );
  }

  final reportOnly = arguments.first == '--report';
  final paths = reportOnly ? arguments.skip(1) : arguments;

  for (final path in paths) {
    final file = File(path);
    final image = decodeImage(await file.readAsBytes());
    if (image == null) throw StateError('Cannot decode $path');

    var minX = image.width;
    var minY = image.height;
    var maxX = -1;
    var maxY = -1;
    for (final pixel in image) {
      if (pixel.a < 8) continue;
      if (pixel.x < minX) minX = pixel.x;
      if (pixel.y < minY) minY = pixel.y;
      if (pixel.x > maxX) maxX = pixel.x;
      if (pixel.y > maxY) maxY = pixel.y;
    }
    if (maxX < minX || maxY < minY) {
      throw StateError('$path contains no visible sprite.');
    }

    final visited = List<bool>.filled(image.width * image.height, false);
    final remove = <int>[];
    var componentNumber = 0;
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final start = y * image.width + x;
        if (visited[start] || !_isBrightNeutral(image.getPixel(x, y))) {
          continue;
        }

        componentNumber++;
        visited[start] = true;
        final queue = <int>[start];
        final colors = <int, int>{};
        var cursor = 0;
        var componentMinX = x;
        var componentMinY = y;
        var componentMaxX = x;
        var componentMaxY = y;
        var touchesEdge = false;
        while (cursor < queue.length) {
          final index = queue[cursor++];
          final pixelX = index % image.width;
          final pixelY = index ~/ image.width;
          final pixel = image.getPixel(pixelX, pixelY);
          final color = (pixel.r.toInt() >> 3) << 10 |
              (pixel.g.toInt() >> 3) << 5 |
              (pixel.b.toInt() >> 3);
          colors[color] = (colors[color] ?? 0) + 1;
          if (pixelX < componentMinX) componentMinX = pixelX;
          if (pixelX > componentMaxX) componentMaxX = pixelX;
          if (pixelY < componentMinY) componentMinY = pixelY;
          if (pixelY > componentMaxY) componentMaxY = pixelY;
          touchesEdge |= pixelX == minX ||
              pixelX == maxX ||
              pixelY == minY ||
              pixelY == maxY;

          for (final offset in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
            final nextX = pixelX + offset.$1;
            final nextY = pixelY + offset.$2;
            if (nextX < minX || nextX > maxX || nextY < minY || nextY > maxY) {
              continue;
            }
            final next = nextY * image.width + nextX;
            if (visited[next] ||
                !_isBrightNeutral(image.getPixel(nextX, nextY))) {
              continue;
            }
            visited[next] = true;
            queue.add(next);
          }
        }

        final componentArea = (componentMaxX - componentMinX + 1) *
            (componentMaxY - componentMinY + 1);
        final fillRatio = queue.length / componentArea;
        final colorCounts = colors.values.toList()..sort();
        final dominantCount = colorCounts.reversed.take(2).fold<int>(
              0,
              (total, count) => total + count,
            );
        final dominantColors = colors.entries.toList()
          ..sort((left, right) => right.value.compareTo(left.value));
        final dominantRatio = dominantCount / queue.length;
        bool isAchromatic(int color) {
          final red = color >> 10;
          final green = (color >> 5) & 31;
          final blue = color & 31;
          return red == green && green == blue;
        }

        final hasCheckerboardPair = dominantColors.length >= 2 &&
            isAchromatic(dominantColors[0].key) &&
            isAchromatic(dominantColors[1].key) &&
            dominantColors[0].key != dominantColors[1].key &&
            dominantColors[1].value / queue.length >= .10;
        var horizontalPairs = 0;
        var horizontalTransitions = 0;
        var verticalPairs = 0;
        var verticalTransitions = 0;
        if (queue.length >= 1000 && hasCheckerboardPair) {
          final componentPixels = queue.toSet();
          final firstColor = dominantColors[0].key;
          final secondColor = dominantColors[1].key;
          int quantizedColor(int index) {
            final pixel = image.getPixel(
              index % image.width,
              index ~/ image.width,
            );
            return (pixel.r.toInt() >> 3) << 10 |
                (pixel.g.toInt() >> 3) << 5 |
                (pixel.b.toInt() >> 3);
          }

          bool isDominantColor(int color) =>
              color == firstColor || color == secondColor;
          for (final index in queue) {
            final color = quantizedColor(index);
            if (!isDominantColor(color)) continue;
            final x = index % image.width;
            final y = index ~/ image.width;
            if (x < maxX && componentPixels.contains(index + 1)) {
              final nextColor = quantizedColor(index + 1);
              if (isDominantColor(nextColor)) {
                horizontalPairs++;
                if (color != nextColor) horizontalTransitions++;
              }
            }
            if (y < maxY && componentPixels.contains(index + image.width)) {
              final nextColor = quantizedColor(index + image.width);
              if (isDominantColor(nextColor)) {
                verticalPairs++;
                if (color != nextColor) verticalTransitions++;
              }
            }
          }
        }
        final horizontalTransitionRatio = horizontalPairs == 0
            ? 0.0
            : horizontalTransitions / horizontalPairs;
        final verticalTransitionRatio =
            verticalPairs == 0 ? 0.0 : verticalTransitions / verticalPairs;
        final isEnclosedCheckerboard =
            queue.length >= 1000 && dominantRatio >= .80 && hasCheckerboardPair;
        final shouldRemove = touchesEdge || isEnclosedCheckerboard;
        if (reportOnly && shouldRemove) {
          stdout.writeln(
            '$path component $componentNumber: ${queue.length}px, '
            'box $componentMinX,$componentMinY '
            '${componentMaxX - componentMinX + 1}x'
            '${componentMaxY - componentMinY + 1}, '
            'fill ${fillRatio.toStringAsFixed(2)}, '
            'dominant ${dominantRatio.toStringAsFixed(2)}, '
            'colors ${dominantColors.take(2).map((entry) {
              final color = entry.key;
              return '${(color >> 10) * 8}/'
                  '${((color >> 5) & 31) * 8}/'
                  '${(color & 31) * 8}:${entry.value}';
            }).join(',')}, '
            'transitions '
            '${horizontalTransitionRatio.toStringAsFixed(3)}/'
            '${verticalTransitionRatio.toStringAsFixed(3)}, '
            'edge $touchesEdge, remove $shouldRemove',
          );
        }
        if (shouldRemove) remove.addAll(queue);
      }
    }

    if (reportOnly) continue;
    for (final index in remove) {
      final x = index % image.width;
      final y = index ~/ image.width;
      image.getPixel(x, y).setRgba(0, 0, 0, 0);
    }
    final beforeFragmentPixels = _visiblePixelCount(image);
    final fragmentPixels = _removeDetachedFragments(image);
    final afterFragmentPixels = _visiblePixelCount(image);
    if (afterFragmentPixels < beforeFragmentPixels * .90) {
      throw StateError(
        '$path fragment cleanup removed most of the intended sprite.',
      );
    }
    final encoded = encodeWebP(image);
    final verificationImage = decodeWebP(encoded);
    if (verificationImage == null ||
        _visiblePixelCount(verificationImage) < afterFragmentPixels * .90) {
      throw StateError('$path lost its sprite during WebP encoding.');
    }
    await file.writeAsBytes(encoded, flush: true);
    stdout.writeln(
      '$path: removed ${remove.length} checkerboard and '
      '$fragmentPixels detached-fragment pixels.',
    );
  }
}
