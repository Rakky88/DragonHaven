import 'dart:io';

import 'package:image/image.dart';

import 'clean_starforged_arcana_gap.dart';

const selectedForms = <String, List<String>>{
  'auroracrown': ['wyrmling', 'might', 'arcana', 'spirit'],
  'bramblequill': ['wyrmling', 'might', 'arcana', 'spirit'],
  'cinderlynx': ['wyrmling', 'might', 'arcana', 'spirit'],
  'clockskip': ['might', 'spirit'],
  'coraloracle': ['wyrmling', 'might'],
  'crystalwhisk': ['might'],
  'dreammoth': ['arcana'],
  'dustglimmer': ['arcana', 'spirit'],
  'echofern': ['wyrmling', 'might', 'arcana'],
  'eclipseantler': ['wyrmling', 'might'],
  'everwyrm': ['wyrmling', 'might', 'spirit'],
  'frostfable': ['wyrmling', 'might', 'arcana'],
  'harmonytail': ['spirit'],
  'ironwhistle': ['wyrmling', 'might', 'arcana'],
  'leviathanecho': ['wyrmling', 'might', 'spirit'],
  'meteorhide': ['wyrmling', 'might'],
  'mistmantle': ['wyrmling', 'might', 'arcana', 'spirit'],
  'opalchimera': ['wyrmling', 'might', 'spirit'],
  'petaldrift': ['wyrmling', 'might', 'arcana', 'spirit'],
  'quietstar': ['might', 'spirit'],
  'rainbowruff': ['spirit'],
  'runehopper': ['might', 'arcana', 'spirit'],
  'starforged': ['wyrmling', 'might', 'arcana'],
  'sunmuzzle': ['wyrmling', 'might', 'arcana', 'spirit'],
  'temporalark': ['might'],
  'tidescale': ['might', 'spirit'],
  'twinflare': ['spirit'],
  'velvetvolt': ['wyrmling', 'might', 'arcana', 'spirit'],
  'voidbloom': ['wyrmling', 'might', 'arcana', 'spirit'],
  'worldroot': ['wyrmling', 'might'],
};

const _cells = <String, (int, int)>{
  'wyrmling': (0, 0),
  'might': (1, 0),
  'arcana': (0, 1),
  'spirit': (1, 1),
};

Future<void> main(List<String> arguments) async {
  if (arguments.length > 2) {
    throw ArgumentError(
      'Usage: dart run tool/extract_selected_dragon_sprites.dart '
      '[lineage] [form]',
    );
  }
  final lineageFilter = arguments.firstOrNull;
  final formFilter = arguments.length > 1 ? arguments[1] : null;
  var written = 0;
  for (final family in selectedForms.entries) {
    if (lineageFilter != null && family.key != lineageFilter) continue;
    final atlasPath = 'assets/images/dragons/${family.key}_forms.webp';
    final atlas = decodeImage(await File(atlasPath).readAsBytes());
    if (atlas == null) throw StateError('Cannot decode $atlasPath');
    if (atlas.width.isOdd || atlas.height.isOdd) {
      throw StateError('$atlasPath does not contain an exact 2x2 grid.');
    }
    final cellWidth = atlas.width ~/ 2;
    final cellHeight = atlas.height ~/ 2;
    final padding =
        ((cellWidth > cellHeight ? cellWidth : cellHeight) * .125).ceil();
    final canvasSize =
        (cellWidth > cellHeight ? cellWidth : cellHeight) + padding * 2;

    for (final form in family.value) {
      if (formFilter != null && form != formFilter) continue;
      final cell = _cells[form]!;
      final source = copyCrop(
        atlas,
        x: cell.$1 * cellWidth,
        y: cell.$2 * cellHeight,
        width: cellWidth,
        height: cellHeight,
      );
      final canvas = Image(
        width: canvasSize,
        height: canvasSize,
        numChannels: 4,
      )..clear(ColorRgba8(0, 0, 0, 0));
      compositeImage(
        canvas,
        source,
        dstX: (canvasSize - cellWidth) ~/ 2,
        dstY: (canvasSize - cellHeight) ~/ 2,
      );
      if (family.key == 'starforged' && form == 'arcana') {
        cleanStarforgedArcanaGap(canvas);
      }

      final output = File(
        'assets/images/dragons/${family.key}_${form}_safe.webp',
      );
      await output.writeAsBytes(encodeWebP(canvas), flush: true);
      written++;
    }
  }

  stdout.writeln(
    'Wrote $written lossless standalone sprites with 12.5% external padding.',
  );
}
