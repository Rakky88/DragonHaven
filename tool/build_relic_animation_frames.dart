import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

const _relics = <String, String>{
  'moralPrism': 'moral_prism.png',
  'orderCompass': 'order_compass.png',
  'soulMirror': 'soul_mirror.png',
};

Future<void> main() async {
  for (final entry in _relics.entries) {
    final bytes =
        await File('assets/images/relics/${entry.value}').readAsBytes();
    final source = decodeImage(bytes);
    if (source == null) throw StateError('Could not decode ${entry.value}');
    final output = Directory('assets/images/relics/animations/${entry.key}')
      ..createSync(recursive: true);
    for (var frame = 0; frame < 20; frame++) {
      final image = _makeFrame(source, frame, entry.key.hashCode);
      final name = 'frame_${frame.toString().padLeft(2, '0')}.webp';
      await File('${output.path}/$name')
          .writeAsBytes(encodeWebP(image), flush: true);
    }
  }
  stdout.writeln('Created 60 relic animation sprites (20 per Relic).');
}

Image _makeFrame(Image source, int frame, int seed) {
  const size = 512;
  const center = 256.0;
  final t = frame / 19;
  final eased = .5 - math.cos(t * math.pi) / 2;
  final pulse = math.sin(t * math.pi);
  final canvas = Image(width: size, height: size, numChannels: 4)
    ..clear(ColorRgba8(0, 0, 0, 0));

  final hue = switch (seed.abs() % 3) {
    0 => ColorRgba8(125, 84, 255, 255),
    1 => ColorRgba8(70, 191, 255, 255),
    _ => ColorRgba8(255, 191, 72, 255),
  };

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = x - center;
      final dy = y - center;
      final distance = math.sqrt(dx * dx + dy * dy);
      final ringRadius = 176 - 54 * pulse + 8 * math.sin(t * math.pi * 4);
      final ringDistance = (distance - ringRadius).abs();
      if (ringDistance < 7) {
        final alpha = ((1 - ringDistance / 7) * (90 + 135 * pulse)).round();
        canvas.setPixelRgba(x, y, hue.r, hue.g, hue.b, alpha);
      }
      final innerGlow = (1 - distance / 206).clamp(0.0, 1.0) * pulse;
      if (innerGlow > 0) {
        canvas.setPixelRgba(
          x,
          y,
          hue.r,
          hue.g,
          hue.b,
          (innerGlow * 54).round(),
        );
      }
    }
  }

  final random = math.Random(seed + frame * 977);
  for (var particle = 0; particle < 34; particle++) {
    final angle = particle * math.pi * 2 / 34 + t * math.pi * 1.65;
    final radius =
        58 + ((particle * 29 + frame * 17) % 145) * (1 - .28 * eased);
    final x = (center + math.cos(angle) * radius).round();
    final y = (center + math.sin(angle) * radius * .78).round();
    final sparkle = 2 + random.nextInt(4) + (pulse * 3).round();
    fillCircle(
      canvas,
      x: x,
      y: y,
      radius: sparkle,
      color: ColorRgba8(255, 244, 194, (120 + 125 * pulse).round()),
    );
  }

  final bounds = _alphaBounds(source);
  final trimmed = copyCrop(
    source,
    x: bounds.$1,
    y: bounds.$2,
    width: bounds.$3,
    height: bounds.$4,
  );
  final target = (248 + 52 * eased + 18 * pulse).round();
  final scale = math.min(target / trimmed.width, target / trimmed.height);
  var relic = copyResize(
    trimmed,
    width: math.max(1, (trimmed.width * scale).round()),
    height: math.max(1, (trimmed.height * scale).round()),
    interpolation: Interpolation.cubic,
  );
  relic = copyRotate(
    relic,
    angle: math.sin(t * math.pi * 2) * 3.2,
    interpolation: Interpolation.cubic,
  );
  compositeImage(
    canvas,
    relic,
    dstX: (size - relic.width) ~/ 2,
    dstY: (size - relic.height) ~/ 2,
  );

  if (frame >= 16) {
    final flash = ((frame - 15) / 4 * 92).round();
    fillCircle(
      canvas,
      x: 256,
      y: 256,
      radius: 42 + (frame - 16) * 9,
      color: ColorRgba8(255, 255, 255, flash.clamp(0, 92)),
    );
  }
  return canvas;
}

(int, int, int, int) _alphaBounds(Image image) {
  var minX = image.width;
  var minY = image.height;
  var maxX = -1;
  var maxY = -1;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a < 12) continue;
      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x);
      maxY = math.max(maxY, y);
    }
  }
  if (maxX < minX || maxY < minY) return (0, 0, image.width, image.height);
  return (minX, minY, maxX - minX + 1, maxY - minY + 1);
}
