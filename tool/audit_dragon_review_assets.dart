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

Future<void> main(List<String> arguments) async {
  final assetRootArgument = arguments.firstWhere(
    (argument) => argument.startsWith('--asset-root='),
    orElse: () => '--asset-root=assets/images/dragons',
  );
  final assetRoot = assetRootArgument.substring('--asset-root='.length);
  final entries = arguments.where((argument) {
    return !argument.startsWith('--asset-root=');
  }).map((argument) {
    final parts = argument.split(':');
    if (parts.length != 2 || !_validForm(parts.last)) {
      throw ArgumentError.value(argument, 'family:form');
    }
    return (family: parts.first, form: parts.last);
  }).toList(growable: false);
  if (entries.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/audit_dragon_review_assets.dart '
      '[--asset-root=<directory>] <family:form>...',
    );
    exitCode = 64;
    return;
  }

  final failures = <String>[];
  final resolvedPaths = <String>{};
  for (final entry in entries) {
    final label = '${entry.family}:${entry.form}';
    try {
      final resolved = await _resolve(entry.family, entry.form, assetRoot);
      resolvedPaths.add(resolved.path);
      final decoded = decodeImage(await resolved.readAsBytes());
      if (decoded == null) {
        failures.add('$label: decoder returned null (${resolved.path})');
        continue;
      }
      final issues = _audit(decoded);
      if (issues.isNotEmpty) {
        failures.add('$label: ${issues.join(', ')} (${resolved.path})');
      }
    } catch (error) {
      failures.add('$label: $error');
    }
  }

  stdout.writeln(
    'Audited ${entries.length} forms across ${resolvedPaths.length} runtime assets.',
  );
  if (failures.isEmpty) {
    stdout.writeln(
        'PASS: decode, alpha edges, margins and flat-background scan.');
    return;
  }
  for (final failure in failures) {
    stderr.writeln('FAIL: $failure');
  }
  exitCode = 1;
}

bool _validForm(String form) =>
    form == 'hatchling' || form == 'mastery' || _formCells.containsKey(form);

Future<File> _resolve(String family, String form, String assetRoot) async {
  if (form == 'hatchling') {
    return File(
      family == 'seraphscale'
          ? '$assetRoot/seraphscale_hatchling_v2.webp'
          : '$assetRoot/${family}_hatchling.webp',
    );
  }
  if (form == 'mastery') {
    return File('$assetRoot/${family}_mastery.webp');
  }
  if (family == 'seraphscale' && form == 'might') {
    final special = File('$assetRoot/seraphscale_ascended_might_v2.png');
    if (special.existsSync()) return special;
  }
  final suffix = _secondPass[family]?.contains(form) == true
      ? '${form}_safe_v2.webp'
      : '${form}_safe.webp';
  final standalone = File('$assetRoot/${family}_$suffix');
  if (standalone.existsSync()) return standalone;
  final firstPass = File('$assetRoot/${family}_${form}_safe.webp');
  if (firstPass.existsSync()) return firstPass;
  throw StateError('reviewed form does not resolve to a standalone asset');
}

List<String> _audit(Image image) {
  final issues = <String>[];
  if (image.width < 256 || image.height < 256) {
    issues.add('unexpectedly small ${image.width}x${image.height}');
  }

  var minX = image.width;
  var minY = image.height;
  var maxX = -1;
  var maxY = -1;
  var visible = 0;
  var transparent = 0;
  var edgeAlpha = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final alpha = image.getPixel(x, y).a.toInt();
      if (alpha <= 8) {
        transparent++;
      } else {
        visible++;
        minX = math.min(minX, x);
        minY = math.min(minY, y);
        maxX = math.max(maxX, x);
        maxY = math.max(maxY, y);
      }
      if (x == 0 || y == 0 || x == image.width - 1 || y == image.height - 1) {
        edgeAlpha = math.max(edgeAlpha, alpha);
      }
    }
  }
  final pixels = image.width * image.height;
  if (visible < pixels ~/ 100) issues.add('less than 1% visible content');
  if (transparent < pixels ~/ 5) issues.add('less than 20% transparent canvas');
  if (edgeAlpha != 0) {
    issues.add('non-transparent outer edge (alpha $edgeAlpha)');
  }
  if (maxX >= 0) {
    final margin = math.min(
      math.min(minX, image.width - 1 - maxX),
      math.min(minY, image.height - 1 - maxY),
    );
    if (margin < 12) issues.add('content margin only $margin px');
  }
  if (_hasFlatNeutralBlock(image)) {
    issues.add('suspicious flat neutral background block');
  }
  return issues;
}

bool _hasFlatNeutralBlock(Image image) {
  const blockSize = 48;
  for (var y = blockSize; y + blockSize < image.height; y += 24) {
    for (var x = blockSize; x + blockSize < image.width; x += 24) {
      var opaque = 0;
      var minChannel = 255;
      var maxChannel = 0;
      var minLuma = 255;
      var maxLuma = 0;
      for (var yy = y; yy < y + blockSize; yy++) {
        for (var xx = x; xx < x + blockSize; xx++) {
          final pixel = image.getPixel(xx, yy);
          if (pixel.a.toInt() < 245) continue;
          opaque++;
          final red = pixel.r.toInt();
          final green = pixel.g.toInt();
          final blue = pixel.b.toInt();
          minChannel =
              math.min(minChannel, math.min(red, math.min(green, blue)));
          maxChannel =
              math.max(maxChannel, math.max(red, math.max(green, blue)));
          final luma = ((red + green + blue) / 3).round();
          minLuma = math.min(minLuma, luma);
          maxLuma = math.max(maxLuma, luma);
        }
      }
      if (opaque < blockSize * blockSize * 0.98) continue;
      final neutral = maxChannel - minChannel <= 18;
      final flat = maxLuma - minLuma <= 8;
      if (neutral && flat) return true;
    }
  }
  return false;
}
