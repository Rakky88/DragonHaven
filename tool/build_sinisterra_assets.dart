import 'dart:io';

import 'package:image/image.dart';

const _forms = <(String, String)>[
  ('Hatchling', 'assets/images/dragons/sinisterra_hatchling.webp'),
  ('Wyrmling', 'assets/images/dragons/sinisterra_wyrmling_safe.webp'),
  ('Might', 'assets/images/dragons/sinisterra_might_safe.webp'),
  ('Arcana', 'assets/images/dragons/sinisterra_arcana_safe.webp'),
  ('Spirit', 'assets/images/dragons/sinisterra_spirit_safe.webp'),
  ('Mastery', 'assets/images/dragons/sinisterra_mastery.webp'),
];

Future<Image> _read(String path) async {
  final decoded = decodeImage(await File(path).readAsBytes());
  if (decoded == null) throw StateError('Could not decode $path');
  return decoded;
}

Future<void> main() async {
  final atlas = Image(width: 1024, height: 1024, numChannels: 4)
    ..clear(ColorRgba8(0, 0, 0, 0));
  for (var index = 0; index < 4; index++) {
    final source = await _read(_forms[index + 1].$2);
    final cell = copyResize(
      source,
      width: 512,
      height: 512,
      interpolation: Interpolation.cubic,
    );
    compositeImage(
      atlas,
      cell,
      dstX: (index % 2) * 512,
      dstY: (index ~/ 2) * 512,
    );
  }
  const atlasPath = 'assets/images/dragons/sinisterra_forms.webp';
  await File(atlasPath).writeAsBytes(encodeWebP(atlas), flush: true);

  final preview = Image(width: 1260, height: 920, numChannels: 4)
    ..clear(ColorRgba8(24, 112, 205, 255));
  for (var index = 0; index < _forms.length; index++) {
    final source = await _read(_forms[index].$2);
    final sprite = copyResize(
      source,
      width: 390,
      height: 390,
      interpolation: Interpolation.cubic,
    );
    final x = (index % 3) * 420 + 15;
    final y = (index ~/ 3) * 460 + 46;
    compositeImage(preview, sprite, dstX: x, dstY: y);
    drawString(
      preview,
      _forms[index].$1,
      font: arial24,
      x: x + 8,
      y: y - 34,
      color: ColorRgba8(255, 255, 255, 255),
    );
  }
  const previewPath = 'build/sinisterra_visual_audit.png';
  await File(previewPath).writeAsBytes(encodePng(preview), flush: true);
  stdout.writeln('$atlasPath: 1024x1024 lossless WebP atlas');
  stdout.writeln('$previewPath: six forms on blue alpha-review background');
}
