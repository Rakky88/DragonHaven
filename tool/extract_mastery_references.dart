import 'dart:io';

import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:image/image.dart';

Future<void> main(List<String> arguments) async {
  final outputDirectory = Directory(
    arguments.isEmpty ? 'build/mastery_references' : arguments.single,
  )..createSync(recursive: true);

  for (final lineage in dragonLineages) {
    final atlasPath = 'assets/images/dragons/${lineage.spriteId}_forms.webp';
    final atlas = decodeImage(await File(atlasPath).readAsBytes());
    if (atlas == null || atlas.width.isOdd || atlas.height.isOdd) {
      throw StateError('$atlasPath is not a decodable 2x2 form atlas.');
    }
    final wyrmling = copyCrop(
      atlas,
      x: 0,
      y: 0,
      width: atlas.width ~/ 2,
      height: atlas.height ~/ 2,
    );
    await File('${outputDirectory.path}/${lineage.id}_wyrmling.png')
        .writeAsBytes(encodePng(wyrmling), flush: true);
  }

  stdout.writeln(
    'Wrote ${dragonLineages.length} Mastery reference sprites to '
    '${outputDirectory.path}.',
  );
}
