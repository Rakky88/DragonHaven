import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';

const _seedX = 360;
const _seedY = 420;
const _minX = 338;
const _minY = 394;
const _maxX = 383;
const _maxY = 448;

bool _isWhiteMatte(Pixel pixel, {bool fringe = false}) {
  if (pixel.a == 0) return false;
  final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
  final minimum = channels.reduce((a, b) => a < b ? a : b);
  final maximum = channels.reduce((a, b) => a > b ? a : b);
  return minimum >= (fringe ? 132 : 184) &&
      maximum - minimum <= (fringe ? 62 : 48);
}

int cleanStarforgedArcanaGap(Image image) {
  if (image.width != 640 || image.height != 640) {
    throw StateError('Expected the 640x640 standalone Starforged Arcana.');
  }
  if (!_isWhiteMatte(image.getPixel(_seedX, _seedY))) {
    throw StateError('The audited white-matte seed has changed.');
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
  final remove = Uint8List(image.width * image.height);
  final seed = _seedY * image.width + _seedX;
  final queue = Queue<int>()..add(seed);
  remove[seed] = 1;
  while (queue.isNotEmpty) {
    final index = queue.removeFirst();
    final x = index % image.width;
    final y = index ~/ image.width;
    for (final (dx, dy) in neighbors) {
      final nextX = x + dx;
      final nextY = y + dy;
      if (nextX < _minX || nextX > _maxX || nextY < _minY || nextY > _maxY) {
        continue;
      }
      final next = nextY * image.width + nextX;
      if (remove[next] == 0 && _isWhiteMatte(image.getPixel(nextX, nextY))) {
        remove[next] = 1;
        queue.add(next);
      }
    }
  }

  for (var pass = 0; pass < 4; pass++) {
    final grown = Uint8List.fromList(remove);
    for (var y = _minY; y <= _maxY; y++) {
      for (var x = _minX; x <= _maxX; x++) {
        final index = y * image.width + x;
        if (remove[index] != 0 ||
            !_isWhiteMatte(image.getPixel(x, y), fringe: true)) {
          continue;
        }
        if (neighbors.any((offset) {
          final nextX = x + offset.$1;
          final nextY = y + offset.$2;
          return nextX >= 0 &&
              nextY >= 0 &&
              nextX < image.width &&
              nextY < image.height &&
              remove[nextY * image.width + nextX] != 0;
        })) {
          grown[index] = 1;
        }
      }
    }
    remove.setAll(0, grown);
  }

  var removed = 0;
  for (var index = 0; index < remove.length; index++) {
    if (remove[index] == 0) continue;
    image
        .getPixel(index % image.width, index ~/ image.width)
        .setRgba(0, 0, 0, 0);
    removed++;
  }
  if (removed < 220 || removed > 1800) {
    throw StateError('Unexpected white-matte area: $removed pixels.');
  }
  return removed;
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/clean_starforged_arcana_gap.dart '
      '<input.webp> <output.webp> <blue-preview.png>',
    );
    exitCode = 64;
    return;
  }

  final image = decodeImage(await File(arguments[0]).readAsBytes());
  if (image == null) {
    throw StateError('Could not decode ${arguments[0]}.');
  }
  final removed = cleanStarforgedArcanaGap(image);

  await File(arguments[1]).writeAsBytes(encodeWebP(image), flush: true);
  final preview =
      Image(width: image.width, height: image.height, numChannels: 4)
        ..clear(ColorRgba8(25, 118, 210, 255));
  compositeImage(preview, image);
  await File(arguments[2]).writeAsBytes(encodePng(preview), flush: true);
  stdout.writeln('Removed $removed audited white background pixels.');
}
