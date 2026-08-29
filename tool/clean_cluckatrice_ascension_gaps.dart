import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';

class _Gap {
  const _Gap({
    required this.seedX,
    required this.seedY,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  final int seedX;
  final int seedY;
  final int minX;
  final int minY;
  final int maxX;
  final int maxY;
}

const _arcanaGaps = [
  _Gap(
    seedX: 338,
    seedY: 730,
    minX: 315,
    minY: 675,
    maxX: 363,
    maxY: 780,
  ),
  _Gap(
    seedX: 520,
    seedY: 740,
    minX: 485,
    minY: 700,
    maxX: 552,
    maxY: 782,
  ),
];

const _spiritGaps = [
  _Gap(
    seedX: 340,
    seedY: 730,
    minX: 313,
    minY: 688,
    maxX: 375,
    maxY: 775,
  ),
];

bool _isStrictBackground(Pixel pixel) {
  if (pixel.a == 0) return false;
  final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
  final minimum = channels.reduce((a, b) => a < b ? a : b);
  final maximum = channels.reduce((a, b) => a > b ? a : b);
  return minimum >= 220 && maximum - minimum <= 24;
}

bool _isNeutralFringe(Pixel pixel) {
  if (pixel.a == 0) return false;
  final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
  final minimum = channels.reduce((a, b) => a < b ? a : b);
  final maximum = channels.reduce((a, b) => a > b ? a : b);
  return minimum >= 185 && maximum - minimum <= 38;
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/clean_cluckatrice_ascension_gaps.dart '
      '<input.webp> <output.webp> <blue-preview.png>',
    );
    exitCode = 64;
    return;
  }

  final input = arguments[0];
  final gaps = input.contains('_arcana_')
      ? _arcanaGaps
      : input.contains('_spirit_')
          ? _spiritGaps
          : throw ArgumentError('Expected an Arcana or Spirit Cluckatrice.');
  final image = decodeImage(await File(input).readAsBytes());
  if (image == null || image.width != 1024 || image.height != 1024) {
    throw StateError('The Cluckatrice source must be 1024x1024.');
  }

  final remove = Uint8List(image.width * image.height);
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
  var removed = 0;

  for (final gap in gaps) {
    final seed = gap.seedY * image.width + gap.seedX;
    if (!_isStrictBackground(image.getPixel(gap.seedX, gap.seedY))) {
      throw StateError('Configured gap seed is no longer neutral: $input.');
    }
    final queue = Queue<int>()..add(seed);
    remove[seed] = 1;
    while (queue.isNotEmpty) {
      final index = queue.removeFirst();
      removed++;
      final x = index % image.width;
      final y = index ~/ image.width;
      for (final (dx, dy) in neighbors) {
        final nextX = x + dx;
        final nextY = y + dy;
        if (nextX < gap.minX ||
            nextX > gap.maxX ||
            nextY < gap.minY ||
            nextY > gap.maxY) {
          continue;
        }
        final next = nextY * image.width + nextX;
        if (remove[next] == 0 &&
            _isStrictBackground(image.getPixel(nextX, nextY))) {
          remove[next] = 1;
          queue.add(next);
        }
      }
    }

    // Clear the immediately adjoining neutral matte fringe, while remaining
    // inside the hand-audited negative-space rectangle.
    for (var pass = 0; pass < 3; pass++) {
      final grow = Uint8List.fromList(remove);
      for (var y = gap.minY; y <= gap.maxY; y++) {
        for (var x = gap.minX; x <= gap.maxX; x++) {
          final index = y * image.width + x;
          if (remove[index] != 0 || !_isNeutralFringe(image.getPixel(x, y))) {
            continue;
          }
          for (final (dx, dy) in neighbors) {
            final nextX = x + dx;
            final nextY = y + dy;
            if (nextX < 0 ||
                nextY < 0 ||
                nextX >= image.width ||
                nextY >= image.height) {
              continue;
            }
            if (remove[nextY * image.width + nextX] != 0) {
              grow[index] = 1;
              removed++;
              break;
            }
          }
        }
      }
      remove.setAll(0, grow);
    }
  }

  if (removed < 900) {
    throw StateError('Too few background pixels selected in $input: $removed');
  }
  for (var index = 0; index < remove.length; index++) {
    if (remove[index] == 0) continue;
    image
        .getPixel(index % image.width, index ~/ image.width)
        .setRgba(0, 0, 0, 0);
  }

  await File(arguments[1]).writeAsBytes(encodeWebP(image), flush: true);
  final preview = Image(width: 1024, height: 1024, numChannels: 4)
    ..clear(ColorRgba8(25, 118, 210, 255));
  compositeImage(preview, image);
  await File(arguments[2]).writeAsBytes(encodePng(preview), flush: true);
  stdout.writeln('Removed $removed white background pixels from $input.');
}
