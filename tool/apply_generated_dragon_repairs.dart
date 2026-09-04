import 'dart:io';

import 'package:image/image.dart';

const _generatedDirectory =
    r'C:\Users\groot\.codex\generated_images\01a01a86-71f3-74a3-8773-6677fd748832';

const _atlases = <String, String>{
  'auroracrown': 'exec-66a38e75-4e15-4445-bd3c-c5a5cd69c18b.png',
  'bramblequill': 'exec-41406c80-eb6e-4212-b420-f2d3ff038743.png',
  'cinderlynx': 'exec-c6214a4c-73b3-4086-a713-fdbdb07fcccd.png',
  'clockskip': 'exec-cddc388d-8aa3-4d0f-bdb7-ce5266ea8de9.png',
  'coraloracle': 'exec-6e80d229-1ca0-492a-bc64-d14d71ba8bd1.png',
  'crystalwhisk': 'exec-e989541c-825c-44f9-80b7-4db0f9b012e7.png',
  'dreammoth': 'exec-ad7cb589-f793-402e-8c4b-0ac96fe5cd3f.png',
  'dustglimmer': 'exec-03313427-6f46-4d32-9bbd-8dc6632b5d86.png',
  'echofern': 'exec-d3a8884a-b211-4e7c-9c31-e23fb4194306.png',
  'eclipseantler': 'exec-d8ce312d-6b36-44a9-a24a-fb3b7b8346ee.png',
  'everwyrm': 'exec-c6fd0ced-30f5-48ce-bf53-eb52d4f24723.png',
  'frostfable': 'exec-233f11e6-e159-40c5-a570-e9d69b0f82cb.png',
  'harmonytail': 'exec-92f3d78e-54b7-485e-8bed-cbe5eed9735d.png',
  'ironwhistle': 'exec-1b5b793a-c9e8-4ea1-b092-eb0af1e454b8.png',
  'leviathanecho': 'exec-a45ec0b4-63e0-461b-81ae-bcf0c8452e1f.png',
  'meteorhide': 'exec-8222fb99-ee38-40fb-9149-41abfb32fb07.png',
  'mistmantle': 'exec-a75dd345-c0ae-4078-a5ae-c9c3bf3fac21.png',
  'opalchimera': 'exec-885409da-485d-4cdb-a36b-c760ef664e10.png',
  'petaldrift': 'exec-8460ee82-acd9-466b-ac98-4e89d8e3ae97.png',
  'quietstar': 'exec-93e7c9d8-cbb7-40fb-b0c2-85a50fbe5e2d.png',
  'rainbowruff': 'exec-76d23111-e81a-4175-98f2-4a9305557ab8.png',
  'runehopper': 'exec-d9010887-a788-40c4-96ab-f444a59ea181.png',
  'starforged': 'exec-b42456dd-85e8-43c8-b32d-e54fb9a7ed44.png',
  'sunmuzzle': 'exec-c38c1ee5-42a3-4658-a9eb-f69f7bf901b4.png',
  'temporalark': 'exec-6311d2b7-da88-4d47-b170-fb801ea462ad.png',
  'tidescale': 'exec-08ee7881-9e8b-4311-a2d1-a4e729727ff7.png',
  'twinflare': 'exec-7efc3606-6416-42a0-becb-12445e60a784.png',
  'velvetvolt': 'exec-d058189e-c653-4dbc-858e-b7418f6196f6.png',
  'voidbloom': 'exec-2fef9cea-2d80-4e79-ad38-f75d916edb41.png',
  'worldroot': 'exec-cdf26589-c2b5-4353-8918-3596907cf241.png',
};

const _selectedForms = <String, List<String>>{
  'auroracrown': ['wyrmling', 'might', 'arcana', 'spirit'],
  'bramblequill': ['wyrmling', 'might', 'arcana', 'spirit'],
  'cinderlynx': ['wyrmling', 'might', 'arcana', 'spirit'],
  'clockskip': ['might', 'spirit'],
  'coraloracle': ['wyrmling', 'might', 'arcana'],
  'crystalwhisk': ['might'],
  'dreammoth': ['arcana', 'spirit'],
  'dustglimmer': ['arcana', 'spirit'],
  'echofern': ['wyrmling', 'might', 'arcana'],
  'eclipseantler': ['wyrmling', 'might', 'arcana'],
  'everwyrm': ['wyrmling', 'might', 'arcana', 'spirit'],
  'frostfable': ['wyrmling', 'might', 'arcana'],
  'harmonytail': ['spirit'],
  'ironwhistle': ['wyrmling', 'might', 'arcana'],
  'leviathanecho': ['wyrmling', 'might', 'arcana', 'spirit'],
  'meteorhide': ['wyrmling', 'might', 'arcana', 'spirit'],
  'mistmantle': ['wyrmling', 'might', 'arcana', 'spirit'],
  'opalchimera': ['wyrmling', 'might', 'arcana', 'spirit'],
  'petaldrift': ['wyrmling', 'might', 'arcana', 'spirit'],
  'quietstar': ['might', 'spirit'],
  'rainbowruff': ['spirit'],
  'runehopper': ['might', 'arcana', 'spirit'],
  'starforged': ['wyrmling', 'might', 'arcana', 'spirit'],
  'sunmuzzle': ['wyrmling', 'might', 'arcana', 'spirit'],
  'temporalark': ['wyrmling', 'might', 'arcana', 'spirit'],
  'tidescale': ['might', 'spirit'],
  'twinflare': ['might', 'spirit'],
  'velvetvolt': ['wyrmling', 'might', 'arcana', 'spirit'],
  'voidbloom': ['wyrmling', 'might', 'arcana', 'spirit'],
  'worldroot': ['wyrmling', 'might', 'arcana'],
};

const _cells = <String, (int, int)>{
  'wyrmling': (0, 0),
  'might': (1, 0),
  'arcana': (0, 1),
  'spirit': (1, 1),
};

Future<void> main(List<String> arguments) async {
  if (arguments.length > 1) {
    throw ArgumentError(
      'Usage: dart run tool/apply_generated_dragon_repairs.dart '
      '[output-directory]',
    );
  }
  final outputDirectory = arguments.firstOrNull ?? 'assets/images/dragons';
  Directory(outputDirectory).createSync(recursive: true);
  var written = 0;
  for (final family in _selectedForms.entries) {
    final sourcePath = '$_generatedDirectory\\${_atlases[family.key]}';
    final atlas = decodeImage(await File(sourcePath).readAsBytes());
    if (atlas == null) throw StateError('Cannot decode $sourcePath');
    final cellWidth = atlas.width ~/ 2;
    final cellHeight = atlas.height ~/ 2;

    for (final form in family.value) {
      final position = _cells[form]!;
      final rgbCell = copyCrop(
        atlas,
        x: position.$1 * cellWidth,
        y: position.$2 * cellHeight,
        width: cellWidth,
        height: cellHeight,
      );
      final cell = Image(
        width: cellWidth,
        height: cellHeight,
        numChannels: 4,
      )..clear(ColorRgba8(0, 0, 0, 0));
      compositeImage(cell, rgbCell);
      _removeGeneratedCheckerboard(cell);
      _removeSmallForegroundIslands(cell);
      final bounds = _opaqueBounds(cell);
      if (bounds == null) {
        throw StateError('${family.key} $form became empty');
      }
      final trimmed = copyCrop(
        cell,
        x: bounds.$1,
        y: bounds.$2,
        width: bounds.$3 - bounds.$1 + 1,
        height: bounds.$4 - bounds.$2 + 1,
      );
      const canvasSize = 1024;
      const maximumContentSize = 790;
      final scale = maximumContentSize /
          (trimmed.width > trimmed.height ? trimmed.width : trimmed.height);
      final rendered = copyResize(
        trimmed,
        width: (trimmed.width * scale).round(),
        height: (trimmed.height * scale).round(),
        interpolation: Interpolation.cubic,
      );
      final canvas = Image(
        width: canvasSize,
        height: canvasSize,
        numChannels: 4,
      )..clear(ColorRgba8(0, 0, 0, 0));
      compositeImage(
        canvas,
        rendered,
        dstX: (canvasSize - rendered.width) ~/ 2,
        dstY: (canvasSize - rendered.height) ~/ 2,
      );
      final output = File(
        '$outputDirectory/${family.key}_${form}_safe.webp',
      );
      await output.writeAsBytes(encodeWebP(canvas), flush: true);
      written++;
    }
  }
  stdout.writeln(
    'Wrote $written repaired full-body sprites on 1024px transparent canvases.',
  );
}

void _removeSmallForegroundIslands(Image image) {
  final width = image.width;
  final height = image.height;
  final foreground = List<bool>.filled(width * height, false);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      foreground[y * width + x] = image.getPixel(x, y).a > 8;
    }
  }

  final visited = List<bool>.filled(foreground.length, false);
  final stack = <int>[];
  final components = <List<int>>[];
  for (var start = 0; start < foreground.length; start++) {
    if (!foreground[start] || visited[start]) continue;
    final component = <int>[];
    visited[start] = true;
    stack.add(start);
    while (stack.isNotEmpty) {
      final index = stack.removeLast();
      component.add(index);
      final x = index % width;
      final y = index ~/ width;
      if (x > 0) _visit(index - 1, foreground, visited, stack);
      if (x + 1 < width) _visit(index + 1, foreground, visited, stack);
      if (y > 0) _visit(index - width, foreground, visited, stack);
      if (y + 1 < height) _visit(index + width, foreground, visited, stack);
    }
    components.add(component);
  }
  if (components.isEmpty) return;
  components.sort((a, b) => b.length.compareTo(a.length));
  for (final component in components.skip(1)) {
    for (final index in component) {
      image.getPixel(index % width, index ~/ width).a = 0;
    }
  }
}

void _removeGeneratedCheckerboard(Image image) {
  final width = image.width;
  final height = image.height;
  final broadCandidate = List<bool>.filled(width * height, false);
  final definiteBackground = List<bool>.filled(width * height, false);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = image.getPixel(x, y);
      final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]
        ..sort();
      final minimum = channels.first;
      final chroma = channels.last - minimum;
      final index = y * width + x;
      broadCandidate[index] = minimum >= 208 && chroma <= 15;
    }
  }

  final visited = List<bool>.filled(width * height, false);
  final stack = <int>[];
  for (var start = 0; start < broadCandidate.length; start++) {
    if (!broadCandidate[start] || visited[start]) continue;
    final component = <int>[];
    var touchesEdge = false;
    visited[start] = true;
    stack.add(start);
    while (stack.isNotEmpty) {
      final index = stack.removeLast();
      component.add(index);
      final x = index % width;
      final y = index ~/ width;
      touchesEdge |= x == 0 || y == 0 || x == width - 1 || y == height - 1;
      if (x > 0) _visit(index - 1, broadCandidate, visited, stack);
      if (x + 1 < width) _visit(index + 1, broadCandidate, visited, stack);
      if (y > 0) _visit(index - width, broadCandidate, visited, stack);
      if (y + 1 < height) _visit(index + width, broadCandidate, visited, stack);
    }
    if (touchesEdge || component.length >= 420) {
      for (final index in component) {
        definiteBackground[index] = true;
      }
    }
  }

  for (var index = 0; index < definiteBackground.length; index++) {
    if (!definiteBackground[index]) continue;
    image.getPixel(index % width, index ~/ width).a = 0;
  }

  for (var pass = 0; pass < 2; pass++) {
    final remove = <int>[];
    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.a == 0) continue;
        final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]
          ..sort();
        if (channels.first < 195 || channels.last - channels.first > 28) {
          continue;
        }
        if (image.getPixel(x - 1, y).a == 0 ||
            image.getPixel(x + 1, y).a == 0 ||
            image.getPixel(x, y - 1).a == 0 ||
            image.getPixel(x, y + 1).a == 0) {
          remove.add(y * width + x);
        }
      }
    }
    for (final index in remove) {
      image.getPixel(index % width, index ~/ width).a = 0;
    }
  }
}

void _visit(
  int index,
  List<bool> candidate,
  List<bool> visited,
  List<int> stack,
) {
  if (!candidate[index] || visited[index]) return;
  visited[index] = true;
  stack.add(index);
}

(int, int, int, int)? _opaqueBounds(Image image) {
  var minX = image.width;
  var minY = image.height;
  var maxX = -1;
  var maxY = -1;
  for (final pixel in image) {
    if (pixel.a <= 8) continue;
    if (pixel.x < minX) minX = pixel.x;
    if (pixel.y < minY) minY = pixel.y;
    if (pixel.x > maxX) maxX = pixel.x;
    if (pixel.y > maxY) maxY = pixel.y;
  }
  return maxX < 0 ? null : (minX, minY, maxX, maxY);
}
