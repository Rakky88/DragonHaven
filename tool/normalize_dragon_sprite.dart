import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length < 2) {
    stderr.writeln(
      'Usage: dart run tool/normalize_dragon_sprite.dart '
      '<input> <output> [--flip] [--keep-components] '
      '[--preserve-canvas] [--content-size=<pixels>] '
      '[--clear-exposed-neutral] [--clear-neutral-rect=x1,y1,x2,y2] '
      '[--clear-neutral-region=x1,y1,x2,y2] '
      '[--clear-neutral-seed=x,y] [--clear-area=x1,y1,x2,y2] '
      '[--clear-rendered-checkerboard] [--clear-chroma-green] '
      '[--clear-flat-edge-background] [--clear-exact-chroma-green]',
    );
    exitCode = 64;
    return;
  }

  final input = File(arguments[0]);
  final output = File(arguments[1]);
  final flip = arguments.contains('--flip');
  final keepComponents = arguments.contains('--keep-components');
  final preserveCanvas = arguments.contains('--preserve-canvas');
  final clearExposedNeutral = arguments.contains('--clear-exposed-neutral');
  final clearRenderedCheckerboard =
      arguments.contains('--clear-rendered-checkerboard');
  final clearChromaGreen = arguments.contains('--clear-chroma-green');
  final clearFlatEdgeBackground =
      arguments.contains('--clear-flat-edge-background');
  final clearExactChromaGreen =
      arguments.contains('--clear-exact-chroma-green');
  final contentSize = arguments
      .where((argument) => argument.startsWith('--content-size='))
      .map(
          (argument) => int.parse(argument.substring('--content-size='.length)))
      .firstOrNull;
  final clearNeutralRects = arguments
      .where((argument) => argument.startsWith('--clear-neutral-rect='))
      .map(_parseRect)
      .toList(growable: false);
  final clearNeutralRegions = arguments
      .where((argument) => argument.startsWith('--clear-neutral-region='))
      .map(_parseRegion)
      .toList(growable: false);
  final clearNeutralSeeds = arguments
      .where((argument) => argument.startsWith('--clear-neutral-seed='))
      .map(_parseSeed)
      .toList(growable: false);
  final clearAreas = arguments
      .where((argument) => argument.startsWith('--clear-area='))
      .map(_parseArea)
      .toList(growable: false);
  final decoded = decodeImage(await input.readAsBytes());
  if (decoded == null) throw StateError('Could not decode ${input.path}');

  var sprite = decoded.convert(numChannels: 4);
  if (clearChromaGreen) {
    _clearChromaGreen(sprite);
  }
  if (clearFlatEdgeBackground) {
    _clearFlatEdgeBackground(sprite);
  }
  if (clearExactChromaGreen) {
    _clearExactChromaGreen(sprite);
  }
  if (clearRenderedCheckerboard) {
    _clearRenderedCheckerboard(sprite);
  }
  if (_hasOpaqueNeutralBackground(sprite)) {
    _removeGeneratedCheckerboard(sprite);
    _removeNeutralForegroundIslands(sprite);
  }
  if (!keepComponents) _removeSmallForegroundIslands(sprite);
  for (final rect in clearNeutralRects) {
    _clearNeutralRect(sprite, rect);
  }
  for (final region in clearNeutralRegions) {
    _clearNeutralRegion(sprite, region);
  }
  for (final seed in clearNeutralSeeds) {
    _clearNeutralSeed(sprite, seed);
  }
  for (final area in clearAreas) {
    _clearArea(sprite, area);
  }
  if (clearExposedNeutral) {
    _clearExposedNeutral(sprite);
  }
  if (flip) sprite = flipHorizontal(sprite);

  final Image canvas;
  if (preserveCanvas) {
    if (contentSize != null) {
      throw ArgumentError(
          '--content-size cannot be used with --preserve-canvas');
    }
    canvas = sprite;
  } else {
    final bounds = _opaqueBounds(sprite);
    if (bounds == null) throw StateError('No foreground in ${input.path}');
    final (minX, minY, maxX, maxY) = bounds;
    final cropped = copyCrop(
      sprite,
      x: minX,
      y: minY,
      width: maxX - minX + 1,
      height: maxY - minY + 1,
    );
    const canvasSize = 1024;
    final targetContentSize = contentSize ?? 880;
    if (targetContentSize <= 0 || targetContentSize > canvasSize) {
      throw ArgumentError.value(targetContentSize, '--content-size');
    }
    final scale = math.min(
      targetContentSize / cropped.width,
      targetContentSize / cropped.height,
    );
    final rendered = copyResize(
      cropped,
      width: math.max(1, (cropped.width * scale).round()),
      height: math.max(1, (cropped.height * scale).round()),
      interpolation: Interpolation.cubic,
    );
    canvas = Image(width: canvasSize, height: canvasSize, numChannels: 4)
      ..clear(ColorRgba8(0, 0, 0, 0));
    compositeImage(
      canvas,
      rendered,
      dstX: (canvasSize - rendered.width) ~/ 2,
      dstY: (canvasSize - rendered.height) ~/ 2,
    );
  }

  output.parent.createSync(recursive: true);
  final extension = output.path.toLowerCase();
  final bytes = extension.endsWith('.png')
      ? encodePng(canvas, level: 6)
      : encodeWebP(canvas);
  await output.writeAsBytes(bytes, flush: true);

  final finalBounds = _opaqueBounds(canvas)!;
  stdout.writeln(
    '${output.path}: ${canvas.width}x${canvas.height}; '
    'bounds=${finalBounds.$1},${finalBounds.$2}-'
    '${finalBounds.$3},${finalBounds.$4}; '
    'edgeAlpha=${_edgeOpaqueCount(canvas)}',
  );
}

void _clearExactChromaGreen(Image image) {
  for (final pixel in image) {
    if (pixel.a > 8 &&
        pixel.g.toInt() >= 225 &&
        pixel.r.toInt() <= 45 &&
        pixel.b.toInt() <= 45) {
      pixel.a = 0;
    }
  }
}

void _clearFlatEdgeBackground(Image image) {
  final width = image.width;
  final height = image.height;
  final reference = image.getPixel(0, 0);
  final red = reference.r.toInt();
  final green = reference.g.toInt();
  final blue = reference.b.toInt();
  final remove = List<bool>.filled(width * height, false);
  final queue = <int>[];

  bool matches(Pixel pixel) =>
      pixel.a > 8 &&
      (pixel.r.toInt() - red).abs() <= 12 &&
      (pixel.g.toInt() - green).abs() <= 12 &&
      (pixel.b.toInt() - blue).abs() <= 12;

  void enqueue(int x, int y) {
    final index = y * width + x;
    if (remove[index] || !matches(image.getPixel(x, y))) return;
    remove[index] = true;
    queue.add(index);
  }

  for (var x = 0; x < width; x++) {
    enqueue(x, 0);
    enqueue(x, height - 1);
  }
  for (var y = 1; y < height - 1; y++) {
    enqueue(0, y);
    enqueue(width - 1, y);
  }

  var cursor = 0;
  while (cursor < queue.length) {
    final index = queue[cursor++];
    final x = index % width;
    final y = index ~/ width;
    if (x > 0) enqueue(x - 1, y);
    if (x + 1 < width) enqueue(x + 1, y);
    if (y > 0) enqueue(x, y - 1);
    if (y + 1 < height) enqueue(x, y + 1);
  }

  for (var index = 0; index < remove.length; index++) {
    if (remove[index]) image.getPixel(index % width, index ~/ width).a = 0;
  }
}

void _clearExposedNeutral(Image image) {
  final width = image.width;
  final height = image.height;
  final candidate = List<bool>.filled(width * height, false);
  final remove = List<bool>.filled(width * height, false);
  final queue = <int>[];

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
      final index = y * width + x;
      candidate[index] = isNeutral(image.getPixel(x, y));
      if (candidate[index] && touchesTransparent(x, y)) {
        remove[index] = true;
        queue.add(index);
      }
    }
  }

  var cursor = 0;
  while (cursor < queue.length) {
    final index = queue[cursor++];
    final x = index % width;
    final y = index ~/ width;
    for (var yy = math.max(0, y - 1); yy <= math.min(height - 1, y + 1); yy++) {
      for (var xx = math.max(0, x - 1);
          xx <= math.min(width - 1, x + 1);
          xx++) {
        final next = yy * width + xx;
        if (!candidate[next] || remove[next]) continue;
        remove[next] = true;
        queue.add(next);
      }
    }
  }

  for (var index = 0; index < remove.length; index++) {
    if (remove[index]) {
      image.getPixel(index % width, index ~/ width).a = 0;
    }
  }
}

void _clearRenderedCheckerboard(Image image) {
  for (final pixel in image) {
    final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]
      ..sort();
    if (pixel.a > 8 &&
        channels.first >= 240 &&
        channels.last - channels.first <= 3) {
      pixel.a = 0;
    }
  }
  for (var pass = 0; pass < 4; pass++) {
    final remove = <int>[];
    for (var y = 1; y < image.height - 1; y++) {
      for (var x = 1; x < image.width - 1; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.a <= 8) continue;
        final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]
          ..sort();
        if (channels.first < 205 || channels.last - channels.first > 24) {
          continue;
        }
        if (image.getPixel(x - 1, y).a <= 8 ||
            image.getPixel(x + 1, y).a <= 8 ||
            image.getPixel(x, y - 1).a <= 8 ||
            image.getPixel(x, y + 1).a <= 8) {
          remove.add(y * image.width + x);
        }
      }
    }
    for (final index in remove) {
      image.getPixel(index % image.width, index ~/ image.width).a = 0;
    }
  }
}

void _clearChromaGreen(Image image) {
  bool isGreen(Pixel pixel, {required bool fringe}) {
    if (pixel.a <= 8) return false;
    final red = pixel.r.toInt();
    final green = pixel.g.toInt();
    final blue = pixel.b.toInt();
    final strongestOther = math.max(red, blue);
    return fringe
        ? green >= 95 && green >= strongestOther * 1.18 + 18
        : green >= 110 && green >= strongestOther * 1.35 + 24;
  }

  for (final pixel in image) {
    if (isGreen(pixel, fringe: false)) pixel.a = 0;
  }
  for (var pass = 0; pass < 3; pass++) {
    final remove = <int>[];
    for (var y = 1; y < image.height - 1; y++) {
      for (var x = 1; x < image.width - 1; x++) {
        final pixel = image.getPixel(x, y);
        if (!isGreen(pixel, fringe: true)) continue;
        if (image.getPixel(x - 1, y).a <= 8 ||
            image.getPixel(x + 1, y).a <= 8 ||
            image.getPixel(x, y - 1).a <= 8 ||
            image.getPixel(x, y + 1).a <= 8) {
          remove.add(y * image.width + x);
        }
      }
    }
    for (final index in remove) {
      image.getPixel(index % image.width, index ~/ image.width).a = 0;
    }
  }
}

(int, int, int, int) _parseRect(String argument) {
  final values = argument
      .substring('--clear-neutral-rect='.length)
      .split(',')
      .map(int.parse)
      .toList(growable: false);
  if (values.length != 4) {
    throw ArgumentError.value(argument, '--clear-neutral-rect');
  }
  return (values[0], values[1], values[2], values[3]);
}

(int, int, int, int) _parseRegion(String argument) {
  final values = argument
      .substring('--clear-neutral-region='.length)
      .split(',')
      .map(int.parse)
      .toList(growable: false);
  if (values.length != 4) {
    throw ArgumentError.value(argument, '--clear-neutral-region');
  }
  return (values[0], values[1], values[2], values[3]);
}

void _clearNeutralRegion(Image image, (int, int, int, int) rect) {
  final (left, top, right, bottom) = rect;
  for (var y = math.max(0, top); y <= math.min(image.height - 1, bottom); y++) {
    for (var x = math.max(0, left);
        x <= math.min(image.width - 1, right);
        x++) {
      final pixel = image.getPixel(x, y);
      final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]
        ..sort();
      if (pixel.a > 8 &&
          channels.first >= 190 &&
          channels.last - channels.first <= 34) {
        pixel.a = 0;
      }
    }
  }
}

(int, int) _parseSeed(String argument) {
  final values = argument
      .substring('--clear-neutral-seed='.length)
      .split(',')
      .map(int.parse)
      .toList(growable: false);
  if (values.length != 2) {
    throw ArgumentError.value(argument, '--clear-neutral-seed');
  }
  return (values[0], values[1]);
}

void _clearNeutralSeed(Image image, (int, int) requestedSeed) {
  bool isNeutral(int x, int y) {
    final pixel = image.getPixel(x, y);
    final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]
      ..sort();
    return pixel.a > 8 &&
        channels.first >= 185 &&
        channels.last - channels.first <= 40;
  }

  (int, int)? seed;
  for (var radius = 0; radius <= 24 && seed == null; radius++) {
    for (var y = math.max(0, requestedSeed.$2 - radius);
        y <= math.min(image.height - 1, requestedSeed.$2 + radius);
        y++) {
      for (var x = math.max(0, requestedSeed.$1 - radius);
          x <= math.min(image.width - 1, requestedSeed.$1 + radius);
          x++) {
        if (isNeutral(x, y)) {
          seed = (x, y);
          break;
        }
      }
      if (seed != null) break;
    }
  }
  if (seed == null) {
    stderr.writeln(
        'No neutral pixel near ${requestedSeed.$1},${requestedSeed.$2}');
    return;
  }

  final remove = List<bool>.filled(image.width * image.height, false);
  final queue = <int>[seed.$2 * image.width + seed.$1];
  remove[queue.single] = true;
  var cursor = 0;
  while (cursor < queue.length) {
    final index = queue[cursor++];
    final x = index % image.width;
    final y = index ~/ image.width;
    for (var yy = math.max(0, y - 1);
        yy <= math.min(image.height - 1, y + 1);
        yy++) {
      for (var xx = math.max(0, x - 1);
          xx <= math.min(image.width - 1, x + 1);
          xx++) {
        final next = yy * image.width + xx;
        if (!remove[next] && isNeutral(xx, yy)) {
          remove[next] = true;
          queue.add(next);
        }
      }
    }
  }
  for (final index in queue) {
    image.getPixel(index % image.width, index ~/ image.width).a = 0;
  }
  stdout.writeln(
    'cleared neutral seed ${requestedSeed.$1},${requestedSeed.$2} '
    'from ${seed.$1},${seed.$2}: ${queue.length} pixels',
  );
}

(int, int, int, int) _parseArea(String argument) {
  final values = argument
      .substring('--clear-area='.length)
      .split(',')
      .map(int.parse)
      .toList(growable: false);
  if (values.length != 4) {
    throw ArgumentError.value(argument, '--clear-area');
  }
  return (values[0], values[1], values[2], values[3]);
}

void _clearArea(Image image, (int, int, int, int) rect) {
  final (left, top, right, bottom) = rect;
  for (var y = math.max(0, top); y <= math.min(image.height - 1, bottom); y++) {
    for (var x = math.max(0, left);
        x <= math.min(image.width - 1, right);
        x++) {
      image.getPixel(x, y).a = 0;
    }
  }
}

void _clearNeutralRect(Image image, (int, int, int, int) rect) {
  final (left, top, right, bottom) = rect;
  final remove = List<bool>.filled(image.width * image.height, false);
  for (var y = math.max(0, top); y <= math.min(image.height - 1, bottom); y++) {
    for (var x = math.max(0, left);
        x <= math.min(image.width - 1, right);
        x++) {
      final pixel = image.getPixel(x, y);
      final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]
        ..sort();
      if (pixel.a > 8 &&
          channels.first >= 215 &&
          channels.last - channels.first <= 14) {
        remove[y * image.width + x] = true;
      }
    }
  }
  for (var pass = 0; pass < 3; pass++) {
    final grown = List<bool>.from(remove);
    for (var y = math.max(1, top);
        y < math.min(image.height - 1, bottom);
        y++) {
      for (var x = math.max(1, left);
          x < math.min(image.width - 1, right);
          x++) {
        final index = y * image.width + x;
        if (remove[index]) continue;
        final pixel = image.getPixel(x, y);
        final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]
          ..sort();
        if (channels.first < 190 || channels.last - channels.first > 34) {
          continue;
        }
        if (remove[index - 1] ||
            remove[index + 1] ||
            remove[index - image.width] ||
            remove[index + image.width]) {
          grown[index] = true;
        }
      }
    }
    remove.setAll(0, grown);
  }
  for (var index = 0; index < remove.length; index++) {
    if (remove[index]) {
      image.getPixel(index % image.width, index ~/ image.width).a = 0;
    }
  }
}

bool _hasOpaqueNeutralBackground(Image image) {
  final samples = <Pixel>[
    image.getPixel(0, 0),
    image.getPixel(image.width - 1, 0),
    image.getPixel(0, image.height - 1),
    image.getPixel(image.width - 1, image.height - 1),
  ];
  return samples.where((pixel) {
        final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]
          ..sort();
        return pixel.a > 240 &&
            channels.first >= 205 &&
            channels.last - channels.first <= 18;
      }).length >=
      3;
}

void _removeSmallForegroundIslands(Image image) {
  final width = image.width;
  final height = image.height;
  final foreground = List<bool>.generate(
    width * height,
    (index) => image.getPixel(index % width, index ~/ width).a > 8,
  );
  final visited = List<bool>.filled(foreground.length, false);
  final components = <List<int>>[];
  final stack = <int>[];
  for (var start = 0; start < foreground.length; start++) {
    if (!foreground[start] || visited[start]) continue;
    final component = <int>[];
    visited[start] = true;
    stack.add(start);
    while (stack.isNotEmpty) {
      final index = stack.removeLast();
      component.add(index);
      final x = index % width;
      final y = index ~/ width;
      if (x > 0) _visit(index - 1, foreground, visited, stack);
      if (x + 1 < width) _visit(index + 1, foreground, visited, stack);
      if (y > 0) _visit(index - width, foreground, visited, stack);
      if (y + 1 < height) _visit(index + width, foreground, visited, stack);
    }
    components.add(component);
  }
  if (components.isEmpty) return;
  components.sort((a, b) => b.length.compareTo(a.length));
  final largest = components.first.length;
  for (final component in components.skip(1)) {
    if (component.length >= largest ~/ 45 || component.length >= 5000) {
      continue;
    }
    for (final index in component) {
      image.getPixel(index % width, index ~/ width).a = 0;
    }
  }
}

void _removeGeneratedCheckerboard(Image image) {
  final width = image.width;
  final height = image.height;
  final candidate = List<bool>.filled(width * height, false);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = image.getPixel(x, y);
      final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]
        ..sort();
      candidate[y * width + x] =
          channels.first >= 205 && channels.last - channels.first <= 18;
    }
  }

  final visited = List<bool>.filled(candidate.length, false);
  final stack = <int>[];
  for (var start = 0; start < candidate.length; start++) {
    if (!candidate[start] || visited[start]) continue;
    final component = <int>[];
    var touchesEdge = false;
    visited[start] = true;
    stack.add(start);
    while (stack.isNotEmpty) {
      final index = stack.removeLast();
      component.add(index);
      final x = index % width;
      final y = index ~/ width;
      touchesEdge |= x == 0 || y == 0 || x == width - 1 || y == height - 1;
      if (x > 0) _visit(index - 1, candidate, visited, stack);
      if (x + 1 < width) _visit(index + 1, candidate, visited, stack);
      if (y > 0) _visit(index - width, candidate, visited, stack);
      if (y + 1 < height) _visit(index + width, candidate, visited, stack);
    }
    if (touchesEdge) {
      for (final index in component) {
        image.getPixel(index % width, index ~/ width).a = 0;
      }
    }
  }

  for (var pass = 0; pass < 3; pass++) {
    final remove = <int>[];
    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.a == 0) continue;
        final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]
          ..sort();
        if (channels.first < 190 || channels.last - channels.first > 30) {
          continue;
        }
        if (image.getPixel(x - 1, y).a == 0 ||
            image.getPixel(x + 1, y).a == 0 ||
            image.getPixel(x, y - 1).a == 0 ||
            image.getPixel(x, y + 1).a == 0) {
          remove.add(y * width + x);
        }
      }
    }
    for (final index in remove) {
      image.getPixel(index % width, index ~/ width).a = 0;
    }
  }
}

void _removeNeutralForegroundIslands(Image image) {
  final width = image.width;
  final height = image.height;
  final foreground = List<bool>.generate(
    width * height,
    (index) => image.getPixel(index % width, index ~/ width).a > 8,
  );
  final visited = List<bool>.filled(foreground.length, false);
  final stack = <int>[];
  for (var start = 0; start < foreground.length; start++) {
    if (!foreground[start] || visited[start]) continue;
    final component = <int>[];
    var neutral = 0;
    visited[start] = true;
    stack.add(start);
    while (stack.isNotEmpty) {
      final index = stack.removeLast();
      component.add(index);
      final pixel = image.getPixel(index % width, index ~/ width);
      final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]
        ..sort();
      if (channels.first >= 198 && channels.last - channels.first <= 24) {
        neutral++;
      }
      final x = index % width;
      final y = index ~/ width;
      if (x > 0) _visit(index - 1, foreground, visited, stack);
      if (x + 1 < width) _visit(index + 1, foreground, visited, stack);
      if (y > 0) _visit(index - width, foreground, visited, stack);
      if (y + 1 < height) _visit(index + width, foreground, visited, stack);
    }
    if (component.length >= 40 && neutral / component.length >= 0.9) {
      for (final index in component) {
        image.getPixel(index % width, index ~/ width).a = 0;
      }
    }
  }
}

void _visit(
  int index,
  List<bool> candidate,
  List<bool> visited,
  List<int> stack,
) {
  if (!candidate[index] || visited[index]) return;
  visited[index] = true;
  stack.add(index);
}

(int, int, int, int)? _opaqueBounds(Image image) {
  var minX = image.width;
  var minY = image.height;
  var maxX = -1;
  var maxY = -1;
  for (final pixel in image) {
    if (pixel.a <= 8) continue;
    minX = math.min(minX, pixel.x);
    minY = math.min(minY, pixel.y);
    maxX = math.max(maxX, pixel.x);
    maxY = math.max(maxY, pixel.y);
  }
  return maxX < 0 ? null : (minX, minY, maxX, maxY);
}

int _edgeOpaqueCount(Image image) {
  var count = 0;
  for (var x = 0; x < image.width; x++) {
    if (image.getPixel(x, 0).a > 8) count++;
    if (image.getPixel(x, image.height - 1).a > 8) count++;
  }
  for (var y = 1; y < image.height - 1; y++) {
    if (image.getPixel(0, y).a > 8) count++;
    if (image.getPixel(image.width - 1, y).a > 8) count++;
  }
  return count;
}
