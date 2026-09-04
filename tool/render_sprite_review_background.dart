import 'dart:io';

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3 && arguments.length != 4) {
    stderr.writeln(
      'Usage: dart run tool/render_sprite_review_background.dart '
      '<input> <output.png> <blue|contrast> [x1,y1,x2,y2]',
    );
    exitCode = 64;
    return;
  }

  var source = decodeImage(await File(arguments[0]).readAsBytes());
  if (source == null) throw StateError('Could not decode ${arguments[0]}');
  final mode = arguments[2];
  if (mode != 'blue' && mode != 'contrast') {
    throw ArgumentError.value(mode, 'background');
  }
  if (arguments.length == 4) {
    final values = arguments[3].split(',').map(int.parse).toList();
    if (values.length != 4) throw ArgumentError.value(arguments[3], 'crop');
    source = copyCrop(
      source,
      x: values[0],
      y: values[1],
      width: values[2] - values[0] + 1,
      height: values[3] - values[1] + 1,
    );
    source = copyResize(
      source,
      width: 1024,
      height: 1024,
      interpolation: Interpolation.nearest,
    );
  }

  final canvas = Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );
  if (mode == 'blue') {
    canvas.clear(ColorRgba8(25, 118, 210, 255));
  } else {
    canvas.clear(ColorRgba8(232, 232, 232, 255));
    fillRect(
      canvas,
      x1: 0,
      y1: source.height ~/ 2,
      x2: source.width - 1,
      y2: source.height - 1,
      color: ColorRgba8(22, 18, 31, 255),
    );
  }
  compositeImage(canvas, source);
  final output = File(arguments[1])..parent.createSync(recursive: true);
  await output.writeAsBytes(encodePng(canvas, level: 6), flush: true);
  stdout.writeln(output.path);
}
