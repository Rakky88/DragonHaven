import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

/// Builds the 100 account portraits from four purpose-made avatar atlases.
///
/// The source atlases deliberately contain enchanted objects, familiars,
/// keepers and crests rather than any collectible DragonHaven dragon sprite.
Future<void> main() async {
  final sourceFiles = List.generate(
    4,
    (index) => File(
      'tool/profile_portrait_sources/atlas_${(index + 1).toString().padLeft(2, '0')}.png',
    ),
  );
  final atlases = <Image>[];
  for (final file in sourceFiles) {
    final decoded = decodeImage(await file.readAsBytes());
    if (decoded == null) throw StateError('Could not decode ${file.path}');
    atlases.add(decoded);
  }

  final output = Directory('assets/images/portraits')
    ..createSync(recursive: true);
  for (var index = 0; index < 100; index++) {
    final atlas = atlases[index ~/ 25];
    final cell = index % 25;
    final column = cell % 5;
    final row = cell ~/ 5;
    final left = (column * atlas.width / 5).round();
    final top = (row * atlas.height / 5).round();
    final right = ((column + 1) * atlas.width / 5).round();
    final bottom = ((row + 1) * atlas.height / 5).round();
    final source = copyCrop(
      atlas,
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    );
    final portrait = _buildPortrait(source, index + 1);
    final name = 'portrait_${(index + 1).toString().padLeft(3, '0')}.webp';
    await File('${output.path}/$name').writeAsBytes(
      encodeWebP(portrait),
      flush: true,
    );
  }
  stdout.writeln(
    'Created 100 distinct 256x256 account portraits without collectible dragons.',
  );
}

Image _buildPortrait(Image source, int number) {
  const size = 256;
  const center = 128.0;
  const outerRadius = 119.0;
  final canvas = Image(width: size, height: size, numChannels: 4)
    ..clear(ColorRgba8(0, 0, 0, 0));
  final rendered = copyResize(
    source,
    width: 224,
    height: 224,
    interpolation: Interpolation.cubic,
  );
  compositeImage(canvas, rendered, dstX: 16, dstY: 16);

  // Remove anything outside the portrait circle so neighbouring atlas cells
  // and rectangular source edges can never leak into the final sprite.
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final distance = math.sqrt(
        math.pow(x - center, 2) + math.pow(y - center, 2),
      );
      if (distance > outerRadius) canvas.setPixelRgba(x, y, 0, 0, 0, 0);
    }
  }

  final glow = _rarityGlow(number);
  final ring = glow ?? ColorRgba8(235, 194, 92, 255);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final distance = math.sqrt(
        math.pow(x - center, 2) + math.pow(y - center, 2),
      );
      if (glow != null && distance >= 108 && distance <= 120) {
        final fade = (1 - (distance - 108) / 12).clamp(0.0, 1.0);
        _blend(canvas, x, y, glow, (fade * 185).round());
      }
      if (distance >= 113 && distance <= 119) {
        _blend(canvas, x, y, ring, 255);
      } else if (distance >= 110 && distance < 113) {
        _blend(canvas, x, y, ColorRgba8(255, 248, 218, 255), 235);
      }
    }
  }
  return canvas;
}

ColorRgba8? _rarityGlow(int number) => switch (number) {
      <= 88 => null,
      <= 93 => ColorRgba8(68, 151, 255, 255),
      <= 96 => ColorRgba8(173, 78, 255, 255),
      <= 98 => ColorRgba8(255, 196, 48, 255),
      99 => ColorRgba8(255, 54, 48, 255),
      _ => ColorRgba8(255, 255, 255, 255),
    };

int _mix(num from, num to, double amount) =>
    (from + (to - from) * amount).round().clamp(0, 255).toInt();

void _blend(Image image, int x, int y, ColorRgba8 color, int alpha) {
  final target = image.getPixel(x, y);
  final a = alpha / 255;
  image.setPixelRgba(
    x,
    y,
    _mix(target.r, color.r, a),
    _mix(target.g, color.g, a),
    _mix(target.b, color.b, a),
    math.max(target.a.toInt(), alpha),
  );
}
