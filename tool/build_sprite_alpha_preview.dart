import 'dart:io';

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2 && arguments.length != 6) {
    stderr.writeln(
      'Usage: dart run tool/build_sprite_alpha_preview.dart '
      '<input image> <output png> [x y width height]',
    );
    exitCode = 64;
    return;
  }

  final sprite = decodeImage(await File(arguments[0]).readAsBytes());
  if (sprite == null) throw StateError('Could not decode ${arguments[0]}.');
  var preview = Image(
    width: sprite.width,
    height: sprite.height,
    numChannels: 4,
  )..clear(ColorRgba8(25, 118, 210, 255));
  compositeImage(preview, sprite);
  if (arguments.length == 6) {
    preview = copyResize(
      copyCrop(
        preview,
        x: int.parse(arguments[2]),
        y: int.parse(arguments[3]),
        width: int.parse(arguments[4]),
        height: int.parse(arguments[5]),
      ),
      width: int.parse(arguments[4]) * 5,
      height: int.parse(arguments[5]) * 5,
      interpolation: Interpolation.nearest,
    );
  }
  await File(arguments[1]).writeAsBytes(encodePng(preview), flush: true);
  stdout.writeln('${arguments[1]}: ${sprite.width}x${sprite.height} on blue.');
}
