import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/decontaminate_light_background_edges.dart '
      '<input> <output.webp>',
    );
    exitCode = 64;
    return;
  }
  final decoded = decodeImage(await File(arguments[0]).readAsBytes());
  if (decoded == null) throw StateError('Could not decode ${arguments[0]}');
  final image = Image(
    width: decoded.width,
    height: decoded.height,
    numChannels: 4,
  )..clear(ColorRgba8(0, 0, 0, 0));
  compositeImage(image, decoded);

  const radius = 36;
  const background = 250.0;
  final distance = Int16List(image.width * image.height)
    ..fillRange(0, image.width * image.height, -1);
  final queue = Queue<int>();
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final index = y * image.width + x;
      if (image.getPixel(x, y).a == 0) {
        distance[index] = 0;
        queue.add(index);
      }
    }
  }
  const neighbors = [(-1, 0), (1, 0), (0, -1), (0, 1)];
  while (queue.isNotEmpty) {
    final index = queue.removeFirst();
    final current = distance[index];
    if (current >= radius) continue;
    final x = index % image.width;
    final y = index ~/ image.width;
    for (final (dx, dy) in neighbors) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= image.width || ny >= image.height) {
        continue;
      }
      final next = ny * image.width + nx;
      if (distance[next] == -1) {
        distance[next] = current + 1;
        queue.add(next);
      }
    }
  }

  var changed = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final index = y * image.width + x;
      final d = distance[index];
      final pixel = image.getPixel(x, y);
      if (pixel.a == 0 || d <= 0 || d > radius) continue;
      final red = pixel.r.toDouble();
      final green = pixel.g.toDouble();
      final blue = pixel.b.toDouble();
      final fromBackground = math
          .max(
            0.0,
            math.max(
              (background - red) / background,
              math.max(
                (background - green) / background,
                (background - blue) / background,
              ),
            ),
          )
          .clamp(0.0, 1.0);
      final depth = d / radius;
      final edgeWeight = 1 - depth * depth;
      final finalAlpha =
          (pixel.a / 255) * (1 - edgeWeight * (1 - fromBackground));
      if (finalAlpha <= .004) {
        pixel.setRgba(0, 0, 0, 0);
        changed++;
        continue;
      }
      final unblendAlpha = math.max(.06, fromBackground);
      double recover(double channel) =>
          ((channel - (1 - unblendAlpha) * background) / unblendAlpha)
              .clamp(0.0, 255.0);
      final recoveredRed = recover(red);
      final recoveredGreen = recover(green);
      final recoveredBlue = recover(blue);
      pixel.setRgba(
        (red + (recoveredRed - red) * edgeWeight).round(),
        (green + (recoveredGreen - green) * edgeWeight).round(),
        (blue + (recoveredBlue - blue) * edgeWeight).round(),
        (finalAlpha * 255).round(),
      );
      changed++;
    }
  }
  await File(arguments[1]).writeAsBytes(encodeWebP(image), flush: true);
  stdout.writeln('Decontaminated $changed edge pixels in ${arguments[0]}.');
}
