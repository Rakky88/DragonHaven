import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

const _formCells = <String, (int, int)>{
  'wyrmling': (0, 0),
  'might': (1, 0),
  'arcana': (0, 1),
  'spirit': (1, 1),
};

const _secondPass = <String, Set<String>>{
  'clockskip': {'might'},
  'dreammoth': {'arcana'},
  'echofern': {'might'},
  'harmonytail': {'spirit'},
  'ironwhistle': {'might'},
  'meteorhide': {'might'},
  'petaldrift': {'might'},
  'runehopper': {'arcana'},
  'starforged': {'might'},
  'tidescale': {'might', 'spirit'},
  'worldroot': {'might'},
};

const _pageSize = 1536;
const _tileSize = 512;
const _imageSize = 438;
const _formsPerPage = 9;

Future<void> main(List<String> arguments) async {
  if (arguments.length < 2) {
    stderr.writeln(
      'Usage: dart run tool/build_dragon_review_contact_sheets.dart '
      '<output-directory> <family:form>...',
    );
    exitCode = 64;
    return;
  }
  final output = Directory(arguments.first)..createSync(recursive: true);
  final exportIndividual = arguments.contains('--export-individual');
  final backgroundArgument = arguments.skip(1).firstWhere(
        (argument) => argument.startsWith('--background='),
        orElse: () => '--background=blue',
      );
  final background = backgroundArgument.substring('--background='.length);
  if (background != 'blue' && background != 'contrast') {
    throw ArgumentError.value(background, '--background');
  }
  final assetRootArgument = arguments.skip(1).firstWhere(
        (argument) => argument.startsWith('--asset-root='),
        orElse: () => '--asset-root=assets/images/dragons',
      );
  final assetRoot = assetRootArgument.substring('--asset-root='.length);
  final entries = arguments
      .skip(1)
      .where(
        (argument) =>
            !argument.startsWith('--asset-root=') &&
            !argument.startsWith('--background=') &&
            argument != '--export-individual',
      )
      .map((argument) {
    final parts = argument.split(':');
    if (parts.length != 2 || !_validForm(parts.last)) {
      throw ArgumentError.value(argument, 'family:form');
    }
    return (family: parts.first, form: parts.last);
  }).toList(growable: false);

  if (exportIndividual) {
    for (final entry in entries) {
      final sprite = await _loadRuntimeSprite(
        entry.family,
        entry.form,
        assetRoot,
      );
      final destination = File(
        '${output.path}/${entry.family}_${entry.form}.png',
      );
      await destination.writeAsBytes(encodePng(sprite, level: 6), flush: true);
      stdout.writeln(destination.path);
    }
    return;
  }

  for (var pageStart = 0;
      pageStart < entries.length;
      pageStart += _formsPerPage) {
    final page = Image(width: _pageSize, height: _pageSize, numChannels: 4)
      ..clear(ColorRgba8(247, 242, 252, 255));
    final pageEntries = entries.sublist(
      pageStart,
      math.min(pageStart + _formsPerPage, entries.length),
    );
    for (var index = 0; index < pageEntries.length; index++) {
      final entry = pageEntries[index];
      final sprite = await _loadRuntimeSprite(
        entry.family,
        entry.form,
        assetRoot,
      );
      _drawTile(
        page,
        sprite,
        (index % 3) * _tileSize,
        (index ~/ 3) * _tileSize,
        '${entry.family}:${entry.form}',
        background,
      );
    }
    final number = (pageStart ~/ _formsPerPage + 1).toString().padLeft(2, '0');
    final destination = File('${output.path}/review_$number.png');
    await destination.writeAsBytes(encodePng(page, level: 6), flush: true);
    stdout.writeln(destination.path);
  }
}

bool _validForm(String form) =>
    form == 'hatchling' || form == 'mastery' || _formCells.containsKey(form);

Future<Image> _loadRuntimeSprite(
  String family,
  String form,
  String assetRoot,
) async {
  if (form == 'hatchling') {
    return _decode(
      family == 'seraphscale'
          ? '$assetRoot/seraphscale_hatchling_v2.webp'
          : '$assetRoot/${family}_hatchling.webp',
    );
  }
  if (form == 'mastery') {
    return _decode('$assetRoot/${family}_mastery.webp');
  }
  if (family == 'seraphscale' && form == 'might') {
    final special = File('$assetRoot/seraphscale_ascended_might_v2.png');
    if (special.existsSync()) return _decode(special.path);
  }

  final suffix = _secondPass[family]?.contains(form) == true
      ? '${form}_safe_v2.webp'
      : '${form}_safe.webp';
  final standalone = File('$assetRoot/${family}_$suffix');
  if (standalone.existsSync()) return _decode(standalone.path);
  final firstPass = File('$assetRoot/${family}_${form}_safe.webp');
  if (firstPass.existsSync()) return _decode(firstPass.path);

  final atlas = await _decode('$assetRoot/${family}_forms.webp');
  final cell = _formCells[form]!;
  final width = atlas.width ~/ 2;
  final height = atlas.height ~/ 2;
  return copyCrop(
    atlas,
    x: cell.$1 * width,
    y: cell.$2 * height,
    width: width,
    height: height,
  );
}

Future<Image> _decode(String path) async {
  final decoded = decodeImage(await File(path).readAsBytes());
  if (decoded == null) throw StateError('Could not decode $path');
  return decoded;
}

void _drawTile(
  Image page,
  Image sprite,
  int left,
  int top,
  String label,
  String background,
) {
  const inset = 22;
  if (background == 'contrast') {
    fillRect(
      page,
      x1: left + inset,
      y1: top + inset,
      x2: left + inset + _imageSize - 1,
      y2: top + inset + _imageSize - 1,
      color: ColorRgba8(232, 232, 232, 255),
      radius: 20,
    );
    fillRect(
      page,
      x1: left + inset,
      y1: top + inset + _imageSize ~/ 2,
      x2: left + inset + _imageSize - 1,
      y2: top + inset + _imageSize - 1,
      color: ColorRgba8(22, 18, 31, 255),
    );
  } else {
    fillRect(
      page,
      x1: left + inset,
      y1: top + inset,
      x2: left + inset + _imageSize - 1,
      y2: top + inset + _imageSize - 1,
      color: ColorRgba8(25, 118, 210, 255),
      radius: 20,
    );
  }
  final fitted = copyResize(
    sprite,
    width: _imageSize,
    height: _imageSize,
    maintainAspect: true,
    interpolation: Interpolation.cubic,
  );
  compositeImage(
    page,
    fitted,
    dstX: left + inset + (_imageSize - fitted.width) ~/ 2,
    dstY: top + inset + (_imageSize - fitted.height) ~/ 2,
  );
  drawString(
    page,
    label,
    font: arial24,
    x: left + inset,
    y: top + 469,
    color: ColorRgba8(42, 30, 70, 255),
  );
}
