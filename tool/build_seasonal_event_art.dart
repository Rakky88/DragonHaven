import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

const _eventIds = <String>[
  'halloween',
  'christmas',
  'new_year',
  'valentine',
  'pride',
];

const _coreNames = <String, List<String>>{
  'halloween': [
    'witchlight_chest.webp',
    'witchlight_chest_open.webp',
    'witchlight_egg.webp',
    '../../achievements/warden_witchlight.webp',
  ],
  'christmas': [
    'starlight_chest.webp',
    'starlight_chest_open.webp',
    'starlit_evergreen_egg.webp',
    '../../achievements/star_every_hearth.webp',
  ],
  'new_year': [
    'firstlight_chest.webp',
    'firstlight_chest_open.webp',
    'turning_year_egg.webp',
    '../../achievements/first_light_first_flight.webp',
  ],
  'valentine': [
    'twinheart_chest.webp',
    'twinheart_chest_open.webp',
    'rosebound_egg.webp',
    '../../achievements/two_hearts_one_flight.webp',
  ],
  'pride': [
    'radiant_chest.webp',
    'radiant_chest_open.webp',
    'truecolor_egg.webp',
    '../../achievements/every_color_takes_flight.webp',
  ],
};

Future<void> main() async {
  for (final eventId in _eventIds) {
    final directory = Directory('assets/images/events/$eventId');
    final sourceDirectory =
        Directory('artwork_sources/seasonal_events/$eventId');
    final background =
        await _decode('${sourceDirectory.path}/trial_background.png');
    final sheet = await _decode('${sourceDirectory.path}/trial_sprites.png');
    final core = await _decode('${sourceDirectory.path}/core_sheet.png');

    await _writeWebp(
      '${directory.path}/trial_background.webp',
      background,
    );

    final coreWidth = core.width ~/ 2;
    final coreHeight = core.height ~/ 2;
    for (var index = 0; index < 4; index++) {
      final cell = copyCrop(
        core,
        x: (index % 2) * coreWidth,
        y: (index ~/ 2) * coreHeight,
        width: coreWidth,
        height: coreHeight,
      );
      await _writeWebp(
        '${directory.path}/${_coreNames[eventId]![index]}',
        _squareCanvas(
          cell,
          index == 3 ? 256 : 640,
          padding: index == 3 ? 20 : 0,
        ),
      );
    }
    if (eventId == 'valentine') {
      await _writeWebp(
        '${directory.path}/heartbound_pair_badge.webp',
        _squareCanvas(
          copyCrop(
            core,
            x: coreWidth,
            y: coreHeight,
            width: coreWidth,
            height: coreHeight,
          ),
          320,
        ),
      );
    }
    final cellWidth = sheet.width ~/ 3;
    final cellHeight = sheet.height ~/ 2;
    for (var index = 0; index < 6; index++) {
      final cell = copyCrop(
        sheet,
        x: (index % 3) * cellWidth,
        y: (index ~/ 3) * cellHeight,
        width: cellWidth,
        height: cellHeight,
      );
      _cleanCutoutAlpha(cell);
      await _writeWebp(
        '${directory.path}/trial_sprite_$index.webp',
        cell,
      );
    }
    await _writeWebp(
      '${directory.path}/trial_icon.webp',
      copyResize(
        _cleanCutoutAlpha(copyCrop(
          sheet,
          x: 0,
          y: 0,
          width: cellWidth,
          height: cellHeight,
        )),
        width: 256,
        height: 256,
        interpolation: Interpolation.cubic,
      ),
    );
  }

  final podium =
      await _decode('artwork_sources/seasonal_events/podium_emotes_sheet.png');
  final podiumWidth = podium.width ~/ 5;
  final podiumHeight = podium.height ~/ 3;
  const ranks = ['gold', 'silver', 'bronze'];
  for (var row = 0; row < 3; row++) {
    for (var column = 0; column < _eventIds.length; column++) {
      final cell = copyCrop(
        podium,
        x: column * podiumWidth,
        y: row * podiumHeight,
        width: podiumWidth,
        height: podiumHeight,
      );
      await _writeWebp(
        'assets/images/events/${_eventIds[column]}/podium_${ranks[row]}.webp',
        _squareCanvas(cell, 384, padding: 24),
      );
    }
  }
}

Image _cleanCutoutAlpha(Image image) {
  // Image-generation exports can leave an almost invisible low-alpha
  // alpha veil across an otherwise transparent cell. Removing only that veil
  // keeps soft magical glows and anti-aliased edges intact while guaranteeing
  // clean corners when the sprite is placed over bright rooms.
  for (final pixel in image) {
    final alpha = pixel.a.toInt();
    if (alpha <= 40) {
      pixel.setRgba(0, 0, 0, 0);
      continue;
    }
    final normalized = (alpha - 40) / 215;
    final cleaned = (math.pow(normalized, .82) * 255).round().clamp(0, 255);
    pixel.a = cleaned;
  }
  // Keep a small guaranteed-transparent perimeter. WebP encoding can otherwise
  // spread a neighboring magical glow into an outer corner by a few alpha
  // values even when the decoded source corner was fully transparent.
  const perimeter = 4;
  for (var offset = 0; offset < perimeter; offset++) {
    for (var x = 0; x < image.width; x++) {
      image.getPixel(x, offset).setRgba(0, 0, 0, 0);
      image.getPixel(x, image.height - 1 - offset).setRgba(0, 0, 0, 0);
    }
    for (var y = 0; y < image.height; y++) {
      image.getPixel(offset, y).setRgba(0, 0, 0, 0);
      image.getPixel(image.width - 1 - offset, y).setRgba(0, 0, 0, 0);
    }
  }
  return image;
}

Image _squareCanvas(Image source, int size, {int padding = 0}) {
  final available = math.max(1, size - padding * 2);
  final scale = math.min(
    available / source.width,
    available / source.height,
  );
  final resized = copyResize(
    source,
    width: math.max(1, (source.width * scale).round()),
    height: math.max(1, (source.height * scale).round()),
    interpolation: Interpolation.cubic,
  );
  final canvas = Image(width: size, height: size, numChannels: 4)
    ..clear(ColorRgba8(0, 0, 0, 0));
  compositeImage(
    canvas,
    resized,
    dstX: (size - resized.width) ~/ 2,
    dstY: (size - resized.height) ~/ 2,
  );
  return canvas;
}

Future<Image> _decode(String path) async {
  final decoded = decodeImage(await File(path).readAsBytes());
  if (decoded == null) throw StateError('Unable to decode $path');
  return decoded;
}

Future<void> _writeWebp(
  String path,
  Image image,
) async {
  await File(path).writeAsBytes(
    encodeWebP(image),
    flush: true,
  );
  stdout.writeln('$path (${image.width}x${image.height})');
}
