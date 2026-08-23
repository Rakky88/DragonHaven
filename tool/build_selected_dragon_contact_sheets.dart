import 'dart:io';

import 'package:image/image.dart';

const _selectedForms = <String, List<String>>{
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
  'starforged': ['wyrmling', 'might'],
  'sunmuzzle': ['wyrmling', 'might', 'arcana', 'spirit'],
  'temporalark': ['might'],
  'tidescale': ['might', 'spirit'],
  'twinflare': ['spirit'],
  'velvetvolt': ['wyrmling', 'might', 'arcana', 'spirit'],
  'voidbloom': ['wyrmling', 'might', 'arcana', 'spirit'],
  'worldroot': ['wyrmling', 'might'],
};

const _panelSize = 142;
const _tileWidth = 780;
const _tileHeight = 286;
const _sheetColumns = 2;
const _sheetRows = 4;

Future<void> main() async {
  final output = Directory('build/selected_dragon_visual_audit');
  output.createSync(recursive: true);

  final forms = [
    for (final family in _selectedForms.entries)
      for (final form in family.value) (family: family.key, form: form),
  ];

  for (var sheetIndex = 0;
      sheetIndex * _sheetColumns * _sheetRows < forms.length;
      sheetIndex++) {
    final sheet = Image(
      width: _sheetColumns * _tileWidth,
      height: _sheetRows * _tileHeight,
      numChannels: 4,
    )..clear(ColorRgba8(245, 240, 250, 255));

    final sheetStart = sheetIndex * _sheetColumns * _sheetRows;
    for (var localIndex = 0;
        localIndex < _sheetColumns * _sheetRows &&
            sheetStart + localIndex < forms.length;
        localIndex++) {
      final entry = forms[sheetStart + localIndex];
      final source = decodeImage(File(
        'assets/images/dragons/${entry.family}_${entry.form}_safe.webp',
      ).readAsBytesSync())!;

      final tileX = (localIndex % _sheetColumns) * _tileWidth;
      final tileY = (localIndex ~/ _sheetColumns) * _tileHeight;
      _renderTile(sheet, source, tileX, tileY, entry.family, entry.form);
    }

    final number = (sheetIndex + 1).toString().padLeft(2, '0');
    File('${output.path}/selected_$number.png')
        .writeAsBytesSync(encodePng(sheet, level: 6));
  }

  stdout.writeln(
    'Wrote ${((forms.length - 1) ~/ (_sheetColumns * _sheetRows)) + 1} '
    'sheets for ${forms.length} source forms. Every tile contains five visual passes.',
  );
}

void _renderTile(
  Image sheet,
  Image source,
  int tileX,
  int tileY,
  String family,
  String form,
) {
  drawRect(
    sheet,
    x1: tileX + 4,
    y1: tileY + 4,
    x2: tileX + _tileWidth - 5,
    y2: tileY + _tileHeight - 5,
    color: ColorRgba8(180, 164, 207, 255),
    thickness: 2,
    radius: 18,
  );
  drawString(
    sheet,
    '${family.toUpperCase()} / ${form.toUpperCase()}',
    font: arial24,
    x: tileX + 18,
    y: tileY + 14,
    color: ColorRgba8(38, 27, 64, 255),
  );

  final color = copyResize(
    source,
    width: _panelSize,
    height: _panelSize,
    interpolation: Interpolation.cubic,
  );
  final silhouette = Image.from(color);
  final spectral = Image.from(color);
  final alpha = Image.from(color);
  for (final pixel in silhouette) {
    final a = pixel.a;
    pixel
      ..r = 7
      ..g = 5
      ..b = 12
      ..a = a;
  }
  for (final pixel in spectral) {
    final a = pixel.a;
    final luminance = (pixel.r + pixel.g + pixel.b) / 3;
    pixel
      ..r = 80 + luminance * .25
      ..g = 180 + luminance * .18
      ..b = 245
      ..a = a;
  }
  for (final pixel in alpha) {
    final a = pixel.a;
    pixel
      ..r = 210
      ..g = 40
      ..b = 60
      ..a = a;
  }

  final views = [color, Image.from(color), silhouette, spectral, alpha];
  final backgrounds = [
    ColorRgba8(255, 251, 244, 255),
    ColorRgba8(26, 19, 48, 255),
    ColorRgba8(255, 251, 244, 255),
    ColorRgba8(229, 243, 255, 255),
    ColorRgba8(255, 255, 255, 255),
  ];
  const labels = ['LIGHT', 'DARK', 'SILHOUETTE', 'SPECTRAL', 'ALPHA'];
  for (var index = 0; index < views.length; index++) {
    final x = tileX + 18 + index * 151;
    final y = tileY + 72;
    final panel = Image(
      width: _panelSize,
      height: _panelSize,
      numChannels: 4,
    )..clear(backgrounds[index]);
    compositeImage(panel, views[index]);
    compositeImage(sheet, panel, dstX: x, dstY: y);
    drawRect(
      sheet,
      x1: x,
      y1: y,
      x2: x + _panelSize - 1,
      y2: y + _panelSize - 1,
      color: ColorRgba8(118, 94, 160, 255),
      thickness: 2,
    );
    drawString(
      sheet,
      labels[index],
      font: arial14,
      x: x,
      y: y + _panelSize + 10,
      color: ColorRgba8(73, 61, 96, 255),
    );
  }
}
