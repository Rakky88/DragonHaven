import 'dart:io';
import 'dart:ui' as ui;

import 'package:dragon_haven/widgets/haven_header_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    const font = String.fromEnvironment('EVENT_CAPTURE_FONT');
    if (font.isNotEmpty) {
      await (FontLoader('HeaderCapture')
            ..addFont(File(font).readAsBytes().then(ByteData.sublistView)))
          .load();
    }
  });
  test('abbreviations preserve thresholds and never round balances up', () {
    for (final (amount, label) in [
      (0, '0'),
      (999, '999'),
      (1000, '1K'),
      (1099, '1K'),
      (12993, '12.9K'),
      (999999, '999K'),
      (1000000, '1M'),
      (1259999999, '1.2B'),
      (9223372036854775807, '9.2Qi'),
    ]) {
      expect(compactBalance(amount), label);
    }
  });

  for (final width in [280.0, 320.0, 390.0, 800.0]) {
    for (final scale in [1.0, 1.35, 2.0]) {
      testWidgets('full header at $width dp and text $scale', (tester) async {
        tester.view.physicalSize = Size(width, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final captureKey = GlobalKey();
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
              fontFamily:
                  const String.fromEnvironment('EVENT_CAPTURE_FONT').isEmpty
                      ? null
                      : 'HeaderCapture'),
          home: MediaQuery(
            data: MediaQueryData(
                size: Size(width, 640), textScaler: TextScaler.linear(scale)),
            child: Builder(
                builder: (context) => Scaffold(
                      appBar: AppBar(
                        leadingWidth: 66,
                        leading: const Icon(Icons.auto_awesome),
                        titleSpacing: 2,
                        toolbarHeight: HavenHeaderTitle.toolbarHeight(context),
                        title: RepaintBoundary(
                          key: captureKey,
                          child: const HavenHeaderTitle(
                              subtitle: 'Dragon Tower',
                              coins: 12993,
                              gems: 1284),
                        ),
                        actions: [
                          IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.more_vert))
                        ],
                      ),
                    )),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
        final brand = find.byKey(const Key('haven-full-brand'));
        expect(
            tester.widget<Text>(brand).textSpan!.toPlainText(), 'DragonHaven');
        final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: brand, matching: find.byType(RichText)));
        expect(paragraph.didExceedMaxLines, false);
        expect(paragraph.overflow, isNot(TextOverflow.ellipsis));
        final brandRect = tester.getRect(brand);
        final walletRect =
            tester.getRect(find.byKey(const Key('haven-balances')));
        expect(brandRect.overlaps(walletRect), false);
        expect(brandRect.left, greaterThanOrEqualTo(0));
        expect(brandRect.right, lessThanOrEqualTo(width));
        const directory = String.fromEnvironment('EVENT_CAPTURE_DIR');
        if (directory.isNotEmpty) {
          await tester.runAsync(() async {
            final boundary = captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(directory).create(recursive: true);
            await File('$directory/header-$width-$scale.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.tap(find.byKey(const Key('haven-balances')));
        await tester.pumpAndSettle();
        expect(find.text('12993'), findsOneWidget);
        expect(find.text('1284'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
