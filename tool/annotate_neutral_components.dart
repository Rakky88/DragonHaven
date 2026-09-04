import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/annotate_neutral_components.dart '
      '<input> <output.png>',
    );
    exitCode = 64;
    return;
  }
  final source = decodeImage(await File(arguments[0]).readAsBytes());
  if (source == null) throw StateError('Could not decode ${arguments[0]}');
  final canvas = Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  )..clear(ColorRgba8(25, 118, 210, 255));
  compositeImage(canvas, source);

  final candidate = List<bool>.filled(source.width * source.height, false);
  final visited = List<bool>.filled(candidate.length, false);
  for (final pixel in source) {
    final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]
      ..sort();
    candidate[pixel.y * source.width + pixel.x] = pixel.a > 8 &&
        channels.first >= 198 &&
        channels.last - channels.first <= 30;
  }

  final components = <({int size, int minX, int minY, int maxX, int maxY})>[];
  for (var start = 0; start < candidate.length; start++) {
    if (!candidate[start] || visited[start]) continue;
    final queue = <int>[start];
    visited[start] = true;
    var cursor = 0;
    var minX = source.width;
    var minY = source.height;
    var maxX = -1;
    var maxY = -1;
    while (cursor < queue.length) {
      final index = queue[cursor++];
      final x = index % source.width;
      final y = index ~/ source.width;
      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x);
      maxY = math.max(maxY, y);
      for (var yy = math.max(0, y - 1);
          yy <= math.min(source.height - 1, y + 1);
          yy++) {
        for (var xx = math.max(0, x - 1);
            xx <= math.min(source.width - 1, x + 1);
            xx++) {
          final next = yy * source.width + xx;
          if (candidate[next] && !visited[next]) {
            visited[next] = true;
            queue.add(next);
          }
        }
      }
    }
    if (queue.length >= 100) {
      components.add(
          (size: queue.length, minX: minX, minY: minY, maxX: maxX, maxY: maxY));
    }
  }
  components.sort((a, b) => b.size.compareTo(a.size));
  for (final component in components.take(20)) {
    drawRect(
      canvas,
      x1: math.max(0, component.minX - 4),
      y1: math.max(0, component.minY - 4),
      x2: math.min(canvas.width - 1, component.maxX + 4),
      y2: math.min(canvas.height - 1, component.maxY + 4),
      color: ColorRgba8(255, 0, 0, 255),
      thickness: 3,
    );
    drawString(
      canvas,
      component.size.toString(),
      font: arial24,
      x: component.minX,
      y: math.max(0, component.minY - 30),
      color: ColorRgba8(255, 0, 0, 255),
    );
  }
  final output = File(arguments[1])..parent.createSync(recursive: true);
  await output.writeAsBytes(encodePng(canvas, level: 6), flush: true);
  stdout.writeln(output.path);
}
