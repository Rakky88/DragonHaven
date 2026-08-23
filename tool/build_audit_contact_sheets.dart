import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    throw ArgumentError('Usage: <input-directory> <output-directory>');
  }
  final input = Directory(arguments[0]);
  final output = Directory(arguments[1])..createSync(recursive: true);
  final files = input
      .listSync()
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.png'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  const pagesPerSheet = 8;
  for (var start = 0; start < files.length; start += pagesPerSheet) {
    final pageFiles = files.sublist(
      start,
      math.min(start + pagesPerSheet, files.length),
    );
    final canvas = Image(width: 1080, height: 2240, numChannels: 4)
      ..clear(ColorRgba8(255, 249, 241, 255));
    for (var index = 0; index < pageFiles.length; index++) {
      final decoded = decodeImage(await pageFiles[index].readAsBytes());
      if (decoded == null) {
        throw StateError('Cannot decode ${pageFiles[index]}');
      }
      final crop = copyCrop(decoded, x: 0, y: 150, width: 1080, height: 1120);
      final tile = copyResize(
        crop,
        width: 540,
        height: 560,
        interpolation: Interpolation.cubic,
      );
      compositeImage(
        canvas,
        tile,
        dstX: (index % 2) * 540,
        dstY: (index ~/ 2) * 560,
      );
    }
    final sheetNumber = start ~/ pagesPerSheet + 1;
    await File('${output.path}/audit_sheet_$sheetNumber.png')
        .writeAsBytes(encodePng(canvas), flush: true);
  }
}
