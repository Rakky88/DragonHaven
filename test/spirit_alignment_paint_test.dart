import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/standard_trial_games.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/screens/standard_trial_game_widgets.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _shapeSize = 240.0;
const _padding = 40.0;
const _imageSize = 320;

Future<ui.Image> _paint(List<CustomPainter> painters) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..translate(_padding, _padding);
  for (final painter in painters) {
    painter.paint(canvas, const Size.square(_shapeSize));
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(_imageSize, _imageSize);
  picture.dispose();
  return image;
}

Future<Uint8List> _pixels(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();

Path _interior(SpiritAlignmentShape shape, {double inset = 0}) {
  final bounds =
      const Rect.fromLTWH(0, 0, _shapeSize, _shapeSize).deflate(inset);
  return switch (shape) {
    SpiritAlignmentShape.circle => Path()..addOval(bounds),
    SpiritAlignmentShape.square => Path()..addRect(bounds),
    SpiritAlignmentShape.triangle => Path()
      ..moveTo(bounds.center.dx, bounds.top)
      ..lineTo(bounds.right, bounds.bottom)
      ..lineTo(bounds.left, bounds.bottom)
      ..close(),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('all three filled shapes fit inside an empty gold outline',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: SpiritAlignmentTrialGame(
        offer: TrialOffer(
          id: 'alignment-contained-paint',
          kind: TrialKind.spiritAlignment,
          appearedAt: DateTime.utc(2026, 9, 27),
        ),
        dragon: Pet(id: 'spirit-dragon', name: 'Moss', firstEgg: false),
        onFinished: (_) async {},
      ),
    ));
    final board = find.byKey(const Key('spirit-alignment-game'));
    await tester.tap(board);
    await tester.pump();

    for (final shape in SpiritAlignmentShape.values) {
      CustomPainter painter(String key) => tester
          .widget<CustomPaint>(find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(CustomPaint),
          ))
          .painter!;

      final target = painter('spirit-target-shape');
      final player = painter('spirit-player-shape');
      expect(
        tester.getSize(find.byKey(const Key('spirit-target-shape'))),
        tester.getSize(find.byKey(const Key('spirit-player-shape'))),
      );
      expect(
        SpiritAlignmentGame.overlapPercent(shape, playerX: .5, playerY: .5),
        100,
      );

      await tester.runAsync(() async {
        final targetImage = await _paint([target]);
        final playerImage = await _paint([player]);
        try {
          final targetPixels = await _pixels(targetImage);
          final playerPixels = await _pixels(playerImage);
          final interior = _interior(shape, inset: 3);
          final targetBoundary = _interior(shape);
          var ringPixels = 0, shapePixels = 0, highlightedPixels = 0;
          var overlapPixels = 0, interiorPaintPixels = 0;
          var playerOutsidePixels = 0;
          var left = _imageSize, top = _imageSize, right = 0, bottom = 0;
          for (var y = 0; y < _imageSize; y++) {
            for (var x = 0; x < _imageSize; x++) {
              final offset = (y * _imageSize + x) * 4;
              final targetAlpha = targetPixels[offset + 3];
              final playerAlpha = playerPixels[offset + 3];
              final point = Offset(x + .5 - _padding, y + .5 - _padding);
              if (targetAlpha > 8) ringPixels++;
              if (playerAlpha > 8) {
                shapePixels++;
                left = min(left, x);
                top = min(top, y);
                right = max(right, x);
                bottom = max(bottom, y);
              }
              if (targetAlpha > 8 && playerAlpha > 8) overlapPixels++;
              if (interior.contains(point) && targetAlpha > 8) {
                interiorPaintPixels++;
              }
              if (playerAlpha > 8 && !targetBoundary.contains(point)) {
                playerOutsidePixels++;
              }
              if (playerAlpha > 200 &&
                  playerPixels[offset] > 205 &&
                  playerPixels[offset + 1] > 185) {
                highlightedPixels++;
              }
            }
          }
          expect(ringPixels, greaterThan(1000), reason: shape.name);
          expect(shapePixels, greaterThan(10000), reason: shape.name);
          expect(highlightedPixels, greaterThan(100),
              reason: '${shape.name} still has its white inner highlight');
          expect(overlapPixels, 0,
              reason: '${shape.name} fill/highlight cannot cover the gold');
          expect(interiorPaintPixels, 0,
              reason: '${shape.name} outline paints outside its scoring area');
          expect(playerOutsidePixels, 0,
              reason: '${shape.name} fits entirely inside its target');
          const paintedSize = _shapeSize * SpiritAlignmentGeometry.playerScale;
          const inset = (_shapeSize - paintedSize) / 2;
          for (final minimum in [left, top]) {
            expect(minimum - _padding + .5, closeTo(inset, 2),
                reason: '${shape.name} follows the scored inset bounds');
          }
          for (final maximum in [right, bottom]) {
            expect(maximum - _padding + .5, closeTo(_shapeSize - inset, 2),
                reason: '${shape.name} highlight stays inside those bounds');
          }
          final areaFraction = switch (shape) {
            SpiritAlignmentShape.circle => pi / 4,
            SpiritAlignmentShape.square => 1.0,
            SpiritAlignmentShape.triangle => .5,
          };
          final area = paintedSize * paintedSize * areaFraction;
          expect(shapePixels, closeTo(area, area * .03),
              reason: '${shape.name} uses the same geometry as the score');

          const output = String.fromEnvironment('SPIRIT_PAINT_SCREENSHOTS');
          if (output.isNotEmpty) {
            final composite = await _paint([target, player]);
            try {
              final bytes =
                  await composite.toByteData(format: ui.ImageByteFormat.png);
              final directory = await Directory(output).create(recursive: true);
              await File('${directory.path}/spirit-${shape.name}.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
            } finally {
              composite.dispose();
            }
          }
        } finally {
          targetImage.dispose();
          playerImage.dispose();
        }
      });

      // Two immediate taps miss deliberately, advancing to the next shape
      // without needing to couple this paint test to movement timing.
      await tester.tap(board);
      await tester.tap(board);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
