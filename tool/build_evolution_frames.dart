import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

const _frameCount = 20;
const _canvasSize = 512;

Future<void> main() async {
  final ring = await _read('assets/images/ui/evolution_rune_ring.webp');
  final energy = await _read('assets/images/ui/evolution_energy_spiral.webp');
  final burst = await _read('assets/images/ui/evolution_reveal_burst.webp');
  final output = Directory('assets/images/ui/evolution_frames');
  await output.create(recursive: true);
  final frames = <Image>[];

  for (var index = 0; index < _frameCount; index++) {
    final progress = index / _frameCount;
    final pulse = (1 - math.cos(progress * math.pi * 2)) / 2;
    final frame = Image(
      width: _canvasSize,
      height: _canvasSize,
      numChannels: 4,
    )..clear(ColorRgba8(0, 0, 0, 0));

    final ringLayer = copyRotate(
      copyResize(ring, width: 430, height: 430),
      angle: progress * 360,
      interpolation: Interpolation.cubic,
    );
    _multiplyAlpha(ringLayer, .82 + pulse * .16);
    _center(frame, ringLayer);

    final energyLayer = copyRotate(
      copyResize(energy, width: 390, height: 390),
      angle: -progress * 360,
      interpolation: Interpolation.cubic,
    );
    _multiplyAlpha(energyLayer, .66 + pulse * .22);
    _center(frame, energyLayer);

    final burstSize = (292 + pulse * 42).round();
    final burstLayer = copyResize(
      burst,
      width: burstSize,
      height: burstSize,
      interpolation: Interpolation.cubic,
    );
    _multiplyAlpha(burstLayer, .10 + pulse * .14);
    _center(frame, burstLayer);
    frames.add(frame);

    final suffix = index.toString().padLeft(2, '0');
    final path = '${output.path}/evolution_frame_$suffix.webp';
    await File(path).writeAsBytes(encodeWebP(frame), flush: true);
    stdout.writeln(path);
  }

  final atlas = Image(
    width: _canvasSize * 5,
    height: _canvasSize * 4,
    numChannels: 4,
  )..clear(ColorRgba8(0, 0, 0, 0));
  for (var index = 0; index < frames.length; index++) {
    compositeImage(
      atlas,
      frames[index],
      dstX: (index % 5) * _canvasSize,
      dstY: (index ~/ 5) * _canvasSize,
    );
  }
  const atlasPath = 'assets/images/ui/evolution_frame_atlas.webp';
  await File(atlasPath).writeAsBytes(encodeWebP(atlas), flush: true);
  stdout.writeln(atlasPath);
}

Future<Image> _read(String path) async {
  final image = decodeImage(await File(path).readAsBytes());
  if (image == null) throw StateError('Could not decode $path');
  return image;
}

void _multiplyAlpha(Image image, double factor) {
  for (final pixel in image) {
    pixel.a = (pixel.a * factor).round().clamp(0, 255);
  }
}

void _center(Image canvas, Image layer) {
  compositeImage(
    canvas,
    layer,
    dstX: (canvas.width - layer.width) ~/ 2,
    dstY: (canvas.height - layer.height) ~/ 2,
  );
}
