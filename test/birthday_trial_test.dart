import 'dart:io';
import 'dart:ui' as ui;

import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/wishcake_tower.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/seasonal_trial_game.dart';
import 'package:dragon_haven/widgets/wishcake_trial.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    const font = String.fromEnvironment('EVENT_CAPTURE_FONT');
    if (font.isNotEmpty) {
      final loader = FontLoader('BirthdayCapture')
        ..addFont(File(font).readAsBytes().then(ByteData.sublistView));
      await loader.load();
    }
  });

  double align(WishcakeTower game, {double offset = 0}) {
    for (double t = game.readyAt;
        t < game.readyAt + game.crossingSeconds(game.readyAt);
        t += .0005) {
      if ((game.movingLeft(t) - game.top.left - offset).abs() < .001) return t;
    }
    throw StateError('No crossing of requested alignment');
  }

  test(
      'cake overlap trims only overhang; perfect streak restores bounded width',
      () {
    final game = WishcakeTower(seed: 4);
    final base = game.top;
    final time = align(game, offset: .08);
    final drop = game.drop(time)!;
    expect(drop.hit, true);
    expect(drop.perfect, false);
    expect(drop.points, 85);
    expect(game.top.width, closeTo(base.width - .08, .001));
    expect(drop.offcuts.single.width, closeTo(.08, .001));
    expect(game.drop(time), isNull,
        reason: 'Drop animation cannot be tapped twice');
    final cutWidth = game.top.width;
    for (var i = 0; i < 3; i++) {
      expect(game.drop(align(game))!.perfect, true);
    }
    expect(game.top.width, closeTo(cutWidth + .025, .001));
    for (var i = 0; i < 30; i++) {
      game.drop(align(game));
    }
    expect(game.top.width, lessThanOrEqualTo(base.width));
    expect(game.top.left, greaterThanOrEqualTo(0));
    expect(game.top.right, lessThanOrEqualTo(1));
  });

  test('the first missed layer stops input and preserves the earned tower', () {
    final game = WishcakeTower(seed: 8);
    var drops = 0;
    while (!game.finished && drops++ < 30) {
      game.drop(game.readyAt); // Alternate far edges; overhang narrows first.
    }
    expect(game.mistakes, 1);
    expect(game.finished, true);
    expect(game.drop(game.readyAt + 100), isNull);
  });

  test('birthday speed, help and input bounds remain playable', () {
    final plain = WishcakeTower(seed: 2);
    final helped = WishcakeTower(seed: 2, might: 100, arcana: 100, spirit: 100);
    expect(helped.baseWidth, closeTo(.48, .0001));
    expect(helped.perfectTolerance, closeTo(.025, .00001));
    expect(helped.crossingSeconds(0),
        closeTo(plain.crossingSeconds(0) * 1.08, .0001));
    expect(plain.crossingSeconds(60), lessThan(plain.crossingSeconds(0)));
    expect(plain.crossingSeconds(10000), .48);
    for (var ms = 0; ms < 10000; ms += 13) {
      expect(plain.movingLeft(ms / 1000),
          inInclusiveRange(0, 1 - plain.top.width));
    }
  });

  test(
      'birthday preview fills slots, grants ordinary rewards once and preserves high score',
      () async {
    final now = DateTime.utc(2026, 9, 9, 12);
    final game = HouseholdProvider(clock: () => now, persistenceEnabled: false)
      ..pet = Pet(
          id: 'birthday-dragon', stage: DragonStage.hatchling, firstEgg: false);
    addTearDown(game.dispose);
    await game.redeemCode('BDAYEVENT', keeperId: 'DH-AAAA0001');
    expect(game.activeSpecialAdventureWindows.single.event.id,
        'golden_wings_birthday');
    expect(game.availableTrials.map((o) => o.kind),
        everyElement(TrialKind.wishcakeTower));
    final offer = game.availableTrials.first;
    final xp = game.pet.xp;
    final completion = await game.completeTrial(
        offerId: offer.id, dragonId: game.pet.id, score: 10000);
    expect(completion!.reward.grade, TrialGrade.sPlus);
    expect(completion.simulated, false);
    expect(completion.testEvent, true);
    expect(game.pet.xp, greaterThan(xp));
    expect(
        completion.reward.expertiseRewards.values.reduce((a, b) => a + b), 7);
    expect(
        await game.completeTrial(
            offerId: offer.id, dragonId: game.pet.id, score: 10000),
        isNull);
    final restored = Pet.fromJson(game.pet.toJson());
    expect(restored.trialHighScores['wishcakeTower'], 10000);
    expect(game.specialChestCount('golden_wings_chest_v1'), 0);
  });

  test('birthday recurrence moves from September 2026 to May 13 from 2027', () {
    for (final year in [2027, 2028, 2030]) {
      final start = DateTime.utc(year, 5, 12, 22);
      final end = DateTime.utc(year, 5, 13, 22);
      bool active(DateTime t) => specialAdventureWindowsAt(t)
          .any((w) => w.event.id == 'golden_wings_birthday');
      expect(active(start.subtract(const Duration(milliseconds: 1))), false);
      expect(active(start), true);
      expect(active(end.subtract(const Duration(milliseconds: 1))), true);
      expect(active(end), false);
      expect(active(DateTime.utc(year, 9, 1, 12)), false);
    }
  });

  for (final large in [false, true]) {
    testWidgets(
        'birthday intro, stacking, animation and game over at 320dp large=$large',
        (tester) async {
      var now = DateTime.utc(2026, 9, 9);
      final result = <SeasonalTrialRunResult>[];
      final captureKey = GlobalKey();
      const directory = String.fromEnvironment('EVENT_CAPTURE_DIR');
      const font = String.fromEnvironment('EVENT_CAPTURE_FONT');
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> capture(String name) async {
        if (directory.isEmpty) return;
        await tester.pump();
        await tester.runAsync(() async {
          final boundary = captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(directory).create(recursive: true);
          await File(
                  '$directory/birthday-$name-${large ? 'large' : 'normal'}.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      Future<void> step(int ms) async {
        now = now.add(Duration(milliseconds: ms));
        await tester.pump(Duration(milliseconds: ms));
      }

      await tester.pumpWidget(RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme:
                ThemeData(fontFamily: font.isEmpty ? null : 'BirthdayCapture'),
            home: MediaQuery(
                data: MediaQueryData(
                    size: const Size(320, 640),
                    disableAnimations: large,
                    textScaler: TextScaler.linear(large ? 1.35 : 1)),
                child: SeasonalTrialGame(
                    offer: TrialOffer(
                        id: 'birthday',
                        kind: TrialKind.wishcakeTower,
                        appearedAt: now),
                    dragon: Pet(
                        id: 'b', name: 'Wishes', stage: DragonStage.hatchling),
                    randomSeed: 8,
                    clock: () => now,
                    onFinished: (r) async => result.add(r))),
          )));
      await step(100);
      await capture('intro');
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const Key('start-seasonal-trial')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('start-seasonal-trial')));
      await step(20);
      for (var layer = 0; layer < 7; layer++) {
        // Read the visible geometry, as a player would, and aim for its centre.
        for (var tick = 0; tick < 200; tick++) {
          final painter = tester
              .widget<CustomPaint>(find.byKey(const Key('wishcake-canvas')))
              .painter! as WishcakePainter;
          if (painter.showMoving &&
              (painter.movingLeft - painter.layers.last.left).abs() < .012) {
            break;
          }
          await step(16);
        }
        await tester.tap(find.byKey(const Key('wishcake-drop-button')));
        await step(150);
        if (layer == 6) await capture('stack');
        await step(282);
      }
      expect(find.text('Mistakes: 0 / 1'), findsOneWidget);
      // Deliberately drop at far edges until the first real miss, then try again.
      for (var taps = 0; taps < 20 && result.isEmpty; taps++) {
        final button = tester.widget<FilledButton>(
            find.byKey(const Key('wishcake-drop-button')));
        button.onPressed?.call();
        await step(430);
      }
      await step(1200);
      expect(result, hasLength(1));
      expect(result.single.totalActions - result.single.correctActions, 1);
      expect(result.single.score, greaterThan(0));
      await capture('finished');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
