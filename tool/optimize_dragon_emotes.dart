import 'dart:io';

import 'package:image/image.dart' as img;

const _targetSize = 384;

void main() {
  final root = Directory('assets/images/emotes');
  if (!root.existsSync()) {
    stderr.writeln('Dragon emote directory does not exist.');
    exitCode = 1;
    return;
  }

  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.png'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final decoded = img.decodePng(file.readAsBytesSync());
    if (decoded == null) {
      throw StateError('Could not decode ${file.path}.');
    }
    if (!decoded.hasAlpha) {
      throw StateError('${file.path} does not contain an alpha channel.');
    }

    final resized =
        decoded.width == _targetSize && decoded.height == _targetSize
            ? decoded
            : img.copyResize(
                decoded,
                width: _targetSize,
                height: _targetSize,
                interpolation: img.Interpolation.cubic,
              );
    file.writeAsBytesSync(img.encodePng(resized, level: 9));
  }

  stdout.writeln('Optimized ${files.length} dragon emotes to '
      '${_targetSize}x$_targetSize PNG.');
}
