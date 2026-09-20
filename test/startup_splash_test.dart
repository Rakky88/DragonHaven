import 'dart:io';
import 'dart:ui' as ui;
import 'package:dragon_haven/widgets/startup_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final logo in ['default', 'pride']) {
    testWidgets('server check uses the $logo launch art on a compact screen',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('nl.dragonhaven.app/event_branding'),
              (call) async => logo);
      await tester.pumpWidget(MaterialApp(
          home: RepaintBoundary(
              key: const Key('splash-review'),
              child: MediaQuery(
                  data: const MediaQueryData(
                      textScaler: TextScaler.linear(1.5),
                      disableAnimations: true),
                  child: const StartupSplash()))));
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(find.byKey(const Key('startup-logo')));
      await tester.runAsync(() => precacheImage(
          image.image, tester.element(find.byKey(const Key('startup-logo')))));
      await tester.pumpAndSettle();
      expect(
          (image.image as AssetImage).assetName,
          logo == 'default'
              ? 'assets/images/dragonhaven_logo.png'
              : 'assets/images/event_logos/pride.png');
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Checking your progress'), findsNothing);
      expect(tester.getCenter(find.byKey(const Key('startup-logo'))),
          const Offset(160, 320));
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('STARTUP_UI_REVIEW')) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('splash-review')));
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('.tools/startup-$logo.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
