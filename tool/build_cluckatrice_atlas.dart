import 'dart:io';

import 'package:image/image.dart';

Future<void> main() async {
  const paths = [
    'assets/images/dragons/cluckatrice_wyrmling_safe.webp',
    'assets/images/dragons/cluckatrice_might_safe.webp',
    'assets/images/dragons/cluckatrice_arcana_safe.webp',
    'assets/images/dragons/cluckatrice_spirit_safe.webp',
  ];
  final atlas = Image(width: 1024, height: 1024, numChannels: 4)
    ..clear(ColorRgba8(0, 0, 0, 0));
  for (var index = 0; index < paths.length; index++) {
    final decoded = decodeImage(await File(paths[index]).readAsBytes());
    if (decoded == null) throw StateError('Could not decode ${paths[index]}');
    final cell = copyResize(
      decoded,
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
  const output = 'assets/images/dragons/cluckatrice_forms.webp';
  await File(output).writeAsBytes(encodeWebP(atlas), flush: true);
  stdout.writeln('$output: 1024x1024 lossless WebP atlas');
}
