import 'dart:io';

import 'package:image/image.dart';

const _forms = <String>['might', 'arcana', 'spirit', 'mastery'];

Future<void> main(List<String> arguments) async {
  final sourceDirectory = arguments.isEmpty ? 'build' : arguments.first;
  final suffix = arguments.length < 2 ? '_reclean.webp' : arguments[1];
  final output = arguments.length < 3
      ? 'build/sinisterra_ascended_alpha_review.png'
      : arguments[2];
  final preview = Image(width: 2048, height: 2048, numChannels: 4)
    ..clear(ColorRgba8(25, 118, 210, 255));
  for (var index = 0; index < _forms.length; index++) {
    final path = '$sourceDirectory/sinisterra_${_forms[index]}$suffix';
    final decoded = decodeImage(await File(path).readAsBytes());
    if (decoded == null) throw StateError('Could not decode $path');
    final sprite = copyResize(
      decoded,
      width: 1024,
      height: 1024,
      interpolation: Interpolation.cubic,
    );
    compositeImage(
      preview,
      sprite,
      dstX: (index % 2) * 1024,
      dstY: (index ~/ 2) * 1024,
    );
  }
  await File(output).writeAsBytes(encodePng(preview), flush: true);
  stdout.writeln(output);
}
