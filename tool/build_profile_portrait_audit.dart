import 'dart:io';

import 'package:image/image.dart';

const _columns = 10;
const _tileSize = 176;
const _portraitSize = 136;

Future<void> main() async {
  final sheet = Image(
    width: _columns * _tileSize,
    height: 10 * _tileSize,
    numChannels: 4,
  )..clear(ColorRgba8(252, 247, 239, 255));

  for (var index = 0; index < 100; index++) {
    final number = index + 1;
    final id = number.toString().padLeft(3, '0');
    final path = 'assets/images/portraits/portrait_$id.webp';
    final source = decodeImage(await File(path).readAsBytes());
    if (source == null) throw StateError('Could not decode $path');

    final column = index % _columns;
    final row = index ~/ _columns;
    final tileX = column * _tileSize;
    final tileY = row * _tileSize;
    fillCircle(
      sheet,
      x: tileX + _tileSize ~/ 2,
      y: tileY + 76,
      radius: 70,
      color: ColorRgba8(230, 220, 239, 255),
    );
    final rendered = copyResize(
      source,
      width: _portraitSize,
      height: _portraitSize,
      interpolation: Interpolation.cubic,
    );
    compositeImage(
      sheet,
      rendered,
      dstX: tileX + (_tileSize - _portraitSize) ~/ 2,
      dstY: tileY + 8,
    );
    drawString(
      sheet,
      id,
      font: arial24,
      x: tileX + 66,
      y: tileY + 148,
      color: ColorRgba8(42, 31, 66, 255),
    );
  }

  final output = File('build/profile_portrait_audit.png');
  output.parent.createSync(recursive: true);
  await output.writeAsBytes(encodePng(sheet), flush: true);
  stdout.writeln(output.path);
}
