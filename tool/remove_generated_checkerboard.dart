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
  if (arguments.length < 2 || arguments.length > 3) {
    stderr.writeln(
      'Usage: dart run tool/remove_generated_checkerboard.dart '
      '<input> <output.webp> [minimum-enclosed-component-pixels]',
    );
    exitCode = 64;
    return;
  }
  final decoded = decodeImage(await File(arguments[0]).readAsBytes());
  if (decoded == null) throw StateError('Could not decode ${arguments[0]}');
  final minimumEnclosedComponentPixels =
      arguments.length == 3 ? int.parse(arguments[2]) : 2048;
  if (minimumEnclosedComponentPixels < 1) {
    throw ArgumentError.value(
      minimumEnclosedComponentPixels,
      'minimum-enclosed-component-pixels',
    );
  }
  // Opaque generated PNGs commonly decode as RGB. Editing their alpha in
  // place would then be silently discarded by the encoder, so normalize every
  // source onto an RGBA canvas before extracting the checkerboard.
  final image = Image(
    width: decoded.width,
    height: decoded.height,
    numChannels: 4,
  )..clear(ColorRgba8(0, 0, 0, 0));
  compositeImage(image, decoded);
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
  bool isCheckerPixel(int x, int y) {
    final pixel = image.getPixel(x, y);
    // Generated checker cells use several slightly different neutral values
    // after image scaling and compression. Treat the whole connected neutral
    // field as background rather than trying to reconstruct an exact phase;
    // subject-colored edges stop the flood-fill naturally.
    return _looksLikeCheckerboard(pixel);
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
  // islands of the same neutral pixels. The optional threshold lets a
  // hand-audited asset remove smaller remnants while the conservative default
  // continues to preserve neutral highlights in other generated artwork.
  var enclosedRemoved = 0;
  final enclosedComponents =
      <({int size, int minX, int minY, int maxX, int maxY})>[];
  final enclosedVisited = Uint8List(image.width * image.height);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final start = y * image.width + x;
      if (enclosedVisited[start] != 0 || !isCheckerPixel(x, y)) {
        continue;
      }
      final component = <int>[];
      var minX = image.width;
      var minY = image.height;
      var maxX = 0;
      var maxY = 0;
      final componentQueue = Queue<int>()..add(start);
      enclosedVisited[start] = 1;
      while (componentQueue.isNotEmpty) {
        final index = componentQueue.removeFirst();
        component.add(index);
        final currentX = index % image.width;
        final currentY = index ~/ image.width;
        if (currentX < minX) minX = currentX;
        if (currentY < minY) minY = currentY;
        if (currentX > maxX) maxX = currentX;
        if (currentY > maxY) maxY = currentY;
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
      enclosedComponents.add((
        size: component.length,
        minX: minX,
        minY: minY,
        maxX: maxX,
        maxY: maxY,
      ));
      if (component.length >= minimumEnclosedComponentPixels) {
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
  enclosedComponents.sort((a, b) => b.size.compareTo(a.size));
  stdout.writeln('Removed ${visited.where((value) => value != 0).length} '
      'connected and $enclosedRemoved enclosed checkerboard pixels from '
      '${arguments[0]}.');
  stdout.writeln('Largest enclosed neutral components:');
  for (final component in enclosedComponents.take(20)) {
    stdout.writeln(
      '  ${component.size} px @ '
      '(${component.minX},${component.minY})-'
      '(${component.maxX},${component.maxY})',
    );
  }
}
