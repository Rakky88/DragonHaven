import 'dart:io';

import 'package:image/image.dart';

const _families = <String, String>{
  'halloween': 'gloamgourd',
  'christmas': 'hollyfrost',
  'new_year': 'dawnchime',
  'valentines': 'rosevow',
  'pridefest': 'spectrumplume',
};

const _forms = <String>[
  'hatchling',
  'wyrmling',
  'might',
  'arcana',
  'spirit',
  'mastery',
];

Future<void> main() async {
  const root = 'future_event_art/dragon_families';
  const outputRoot = 'build/event_dragon_family_reviews';
  for (final entry in _families.entries) {
    final canvas = Image(width: 1536, height: 1024, numChannels: 4)
      ..clear(ColorRgba8(25, 118, 210, 255));
    for (var index = 0; index < _forms.length; index++) {
      final form = _forms[index];
      final path = '$root/${entry.key}/sprites/${entry.value}_$form.webp';
      final decoded = decodeImage(await File(path).readAsBytes());
      if (decoded == null) throw StateError('Could not decode $path');
      final rendered = copyResize(
        decoded,
        width: 480,
        height: 480,
        interpolation: Interpolation.cubic,
      );
      final column = index % 3;
      final row = index ~/ 3;
      compositeImage(
        canvas,
        rendered,
        dstX: column * 512 + 16,
        dstY: row * 512 + 16,
      );
    }
    final output = File('$outputRoot/${entry.key}_review_blue.png')
      ..parent.createSync(recursive: true);
    await output.writeAsBytes(encodePng(canvas, level: 6), flush: true);
    stdout.writeln(output.path);
  }
}
