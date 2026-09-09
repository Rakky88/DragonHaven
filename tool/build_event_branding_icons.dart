import 'dart:io';

import 'package:image/image.dart' as img;

// Deterministic Android size/padding exports from the untouched generated art.
const eventLogoKeys = [
  'halloween',
  'christmas',
  'new_year',
  'valentine',
  'pride',
  'golden_wings',
  'harvestmoon',
  'sunwake',
];

void main() {
  const root = 'android/app/src/main/res';
  const densities = {
    'mdpi': 1.0,
    'hdpi': 1.5,
    'xhdpi': 2.0,
    'xxhdpi': 3.0,
    'xxxhdpi': 4.0
  };
  for (final key in eventLogoKeys) {
    final source = img.decodePng(
        File('assets/images/event_logos/$key.png').readAsBytesSync())!;
    for (final density in densities.entries) {
      final side = (48 * density.value).round();
      final canvas = img.Image(width: side, height: side, numChannels: 4);
      img.fill(canvas, color: img.ColorRgba8(255, 248, 231, 255));
      final art = img.copyResize(source,
          width: (side * .9).round(), interpolation: img.Interpolation.average);
      img.compositeImage(canvas, art,
          dstX: (side - art.width) ~/ 2, dstY: (side - art.height) ~/ 2);
      write('$root/mipmap-${density.key}/ic_event_$key.png',
          img.encodePng(canvas));
      final splash = img.copyResize(source,
          width: (180 * density.value).round(),
          interpolation: img.Interpolation.average);
      write('$root/drawable-${density.key}/launch_logo_$key.png',
          img.encodePng(splash));
    }
    final foreground = img.copyResize(source,
        width: 432, interpolation: img.Interpolation.average);
    write('$root/drawable-nodpi/event_foreground_$key.png',
        img.encodePng(foreground));
    File('$root/mipmap-anydpi-v26/ic_event_$key.xml')
        .writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground><inset android:drawable="@drawable/event_foreground_$key" android:inset="18%" /></foreground>
</adaptive-icon>
''');
    File('$root/drawable/launch_event_$key.xml')
        .writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/dragonhaven_launch_background" />
    <item><bitmap android:gravity="center" android:src="@drawable/launch_logo_$key" /></item>
</layer-list>
''');
  }
}

void write(String path, List<int> bytes) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}
