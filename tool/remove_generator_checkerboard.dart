import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/remove_generator_checkerboard.dart '
      '<input.png> <output.webp>',
    );
    exitCode = 64;
    return;
  }
  final source = decodeImage(await File(arguments[0]).readAsBytes());
  if (source == null) throw StateError('Could not decode ${arguments[0]}');
  final image = source.convert(numChannels: 4);
  final width = image.width;
  final height = image.height;
  final cleared = Uint8List(width * height);
  final queue = Queue<int>();

  bool isNeutralBackground(int x, int y, {bool fringe = false}) {
    final pixel = image.getPixel(x, y);
    final red = pixel.r.toInt();
    final green = pixel.g.toInt();
    final blue = pixel.b.toInt();
    final minimum = math.min(red, math.min(green, blue));
    final maximum = math.max(red, math.max(green, blue));
    return minimum >= (fringe ? 175 : 205) &&
        maximum - minimum <= (fringe ? 42 : 30);
  }

  void enqueue(int x, int y) {
    final index = y * width + x;
    if (cleared[index] != 0 || !isNeutralBackground(x, y)) return;
    cleared[index] = 1;
    queue.add(index);
  }

  for (var x = 0; x < width; x++) {
    enqueue(x, 0);
    enqueue(x, height - 1);
  }
  for (var y = 0; y < height; y++) {
    enqueue(0, y);
    enqueue(width - 1, y);
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
    final x = index % width;
    final y = index ~/ width;
    for (final (dx, dy) in neighbors) {
      final nextX = x + dx;
      final nextY = y + dy;
      if (nextX < 0 || nextY < 0 || nextX >= width || nextY >= height) {
        continue;
      }
      enqueue(nextX, nextY);
    }
  }

  var backgroundPixels = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (cleared[y * width + x] == 0) continue;
      image.setPixelRgba(x, y, 0, 0, 0, 0);
      backgroundPixels++;
    }
  }

  // Remove only pale neutral fringe that directly touches the cleared matte.
  // Saturated dragon highlights are deliberately excluded by the neutrality
  // check, while enclosed whites such as the eyes remain protected.
  for (var pass = 0; pass < 4; pass++) {
    final fringe = <int>[];
    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.a == 0 || !isNeutralBackground(x, y, fringe: true)) continue;
        if (neighbors.any(
            (offset) => image.getPixel(x + offset.$1, y + offset.$2).a == 0)) {
          fringe.add(y * width + x);
        }
      }
    }
    if (fringe.isEmpty) break;
    for (final index in fringe) {
      image.setPixelRgba(index % width, index ~/ width, 0, 0, 0, 0);
    }
    backgroundPixels += fringe.length;
  }

  var minX = width;
  var minY = height;
  var maxX = -1;
  var maxY = -1;
  for (final pixel in image) {
    if (pixel.a <= 8) continue;
    minX = math.min(minX, pixel.x);
    minY = math.min(minY, pixel.y);
    maxX = math.max(maxX, pixel.x);
    maxY = math.max(maxY, pixel.y);
  }
  if (maxX < 0) throw StateError('Background removal erased the full image.');
  final subject = copyCrop(
    image,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
  const canvasSize = 1024;
  const contentSize = 880;
  final scale = math.min(
    contentSize / subject.width,
    contentSize / subject.height,
  );
  final resized = copyResize(
    subject,
    width: math.max(1, (subject.width * scale).round()),
    height: math.max(1, (subject.height * scale).round()),
    interpolation: Interpolation.cubic,
  );
  final canvas = Image(width: canvasSize, height: canvasSize, numChannels: 4)
    ..clear(ColorRgba8(0, 0, 0, 0));
  compositeImage(
    canvas,
    resized,
    dstX: (canvasSize - resized.width) ~/ 2,
    dstY: (canvasSize - resized.height) ~/ 2,
  );
  await File(arguments[1]).writeAsBytes(encodeWebP(canvas), flush: true);
  stdout.writeln(
    '${arguments[1]}: ${source.width}x${source.height} -> '
    '${canvas.width}x${canvas.height}; cleared=$backgroundPixels',
  );
}
