import 'dart:io';
import 'dart:ui' as ui;
import 'package:dragon_haven/l10n/app_strings.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/seasonal_conclave_project.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/screens/seasonal_trial_game.dart';
import 'package:dragon_haven/widgets/seasonal_conclave_project_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    const path = String.fromEnvironment('EVENT_CAPTURE_FONT');
    if (path.isNotEmpty) {
      await (FontLoader('SummerCapture')
            ..addFont(File(path).readAsBytes().then(ByteData.sublistView)))
          .load();
    }
  });
  for (final kind in [TrialKind.sunwakeSurf, TrialKind.moonlitOrchard]) {
    for (final large in [false, true]) {
      testWidgets('${kind.name} intro, play, time-out and layout large=$large',
          (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var now = DateTime.utc(2026, 9, 9);
        final completed = <SeasonalTrialRunResult>[];
        final key = GlobalKey();
        Future<void> step(int ms) async {
          now = now.add(Duration(milliseconds: ms));
          await tester.pump(Duration(milliseconds: ms));
        }

        Future<void> capture(String label) async {
          const dir = String.fromEnvironment('EVENT_CAPTURE_DIR');
          if (dir.isEmpty) return;
          await tester.pump();
          await tester.runAsync(() async {
            final boundary = key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(dir).create(recursive: true);
            await File(
                    '$dir/${kind.name}-$label-${large ? 'large' : 'normal'}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        await tester.pumpWidget(RepaintBoundary(
            key: key,
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                    fontFamily:
                        const String.fromEnvironment('EVENT_CAPTURE_FONT')
                                .isEmpty
                            ? null
                            : 'SummerCapture'),
                home: MediaQuery(
                    data: MediaQueryData(
                        size: const Size(320, 640),
                        textScaler: TextScaler.linear(large ? 1.35 : 1),
                        disableAnimations: large),
                    child: SeasonalTrialGame(
                        offer: TrialOffer(
                            id: kind.name, kind: kind, appearedAt: now),
                        dragon: Pet(
                            id: 'summer-test',
                            name: 'Ripple',
                            stage: DragonStage.hatchling,
                            lineageId: kind == TrialKind.sunwakeSurf
                                ? 'solmanta'
                                : 'ciderhorn'),
                        randomSeed: 42,
                        clock: () => now,
                        onFinished: (r) async => completed.add(r))))));
        await step(100);
        await capture('intro');
        expect(tester.takeException(), isNull);
        await tester
            .ensureVisible(find.byKey(const Key('start-seasonal-trial')));
        await tester.tap(find.byKey(const Key('start-seasonal-trial')));
        await step(20);
        expect(
            find.byKey(ValueKey('unique-game-${kind.name}')), findsOneWidget);
        if (kind == TrialKind.sunwakeSurf) {
          final thumb = await tester.startGesture(
              tester.getCenter(find.byKey(const Key('sunwake-dragon'))));
          await thumb.moveBy(const Offset(70, 0));
          await step(200);
          await thumb.up();
          await step(3300);
        } else {
          await tester.tap(find.byKey(const Key('orchard-tray-0')));
          await tester.tap(find.byKey(const Key('orchard-rotate')));
          await tester.tap(find.byKey(const ValueKey('orchard-cell-18')));
          await step(100);
        }
        await capture('playing');
        expect(tester.takeException(), isNull);
        await step(79000);
        await step(1200);
        expect(completed, hasLength(1));
        expect(completed.single.score, inInclusiveRange(0, 20000));
        await step(1500);
        expect(completed, hasLength(1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  test('new gameplay instructions are translated in all supported languages',
      () {
    for (final language in AppStrings.supportedLanguages.keys) {
      // The catalog is a map in the shared localization API.
      final s = AppStrings(language);
      expect(s.pick('Moonlit Orchard', 'Maanverlichte Boomgaard'), isNotEmpty);
      if (language != 'en') {
        expect(s.pick('Fill a row to harvest', 'Vul een rij om te oogsten'),
            isNot('Fill a row to harvest'));
      }
    }
  });
  testWidgets('Conclave project expands within narrow screens with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.35)),
            child: Scaffold(
                body: ListView(children: const [
              SeasonalConclaveProjectCard(
                  project: SeasonalConclaveProject(
                      eventId: 'sunwake_summer_sea',
                      occurrenceKey: 'preview',
                      completedTrials: 15,
                      preview: true,
                      active: true))
            ])))));
    await tester.tap(find.byType(ExpansionTile));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
