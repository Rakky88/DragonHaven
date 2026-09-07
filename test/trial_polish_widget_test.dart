import 'dart:io';
import 'dart:ui' as ui;

import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/screens/adventure_hub_screen.dart';
import 'package:dragon_haven/screens/seasonal_trial_game.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:dragon_haven/widgets/witchlight_trial_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final captureKey = GlobalKey();
  final font = Platform.environment['ALTAR_CAPTURE_FONT'];
  setUpAll(() async {
    for (final entry in {
      'PolishCapture': font,
      'MaterialIcons': Platform.environment['ALTAR_CAPTURE_ICONS'],
    }.entries) {
      if (entry.value == null) continue;
      final loader = FontLoader(entry.key);
      loader.addFont(Future.value(
          ByteData.sublistView(File(entry.value!).readAsBytesSync())));
      await loader.load();
    }
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> loadImages(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future.wait(tester.widgetList<Image>(find.byType(Image)).map(
          (image) => precacheImage(
              image.image, tester.element(find.byType(MaterialApp)))));
    });
    await tester.pump();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (Platform.environment['ALTAR_CAPTURE'] != '1') return;
    await loadImages(tester);
    await tester.runAsync(() async {
      final boundary = captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('release/polish-$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> mount(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var theme = buildAppTheme();
    if (font != null) {
      theme = theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'PolishCapture'),
          primaryTextTheme:
              theme.primaryTextTheme.apply(fontFamily: 'PolishCapture'));
    }
    await tester.pumpWidget(RepaintBoundary(
        key: captureKey,
        child: MaterialApp(
            debugShowCheckedModeBanner: false, theme: theme, home: child)));
    await tester.pump();
  }

  testWidgets(
      'six pumpkin sprites match correctly and Might stays inside its ring',
      (tester) async {
    var now = DateTime(2026, 10, 26);
    await mount(
        tester,
        SeasonalTrialGame(
            offer: TrialOffer(
                id: 'polish', kind: TrialKind.witchlightWard, appearedAt: now),
            dragon: Pet(
                id: 'polish-dragon',
                name: 'Moss',
                stage: DragonStage.hatchling),
            randomSeed: 5,
            clock: () => now,
            onFinished: (_) async {}));
    await loadImages(tester);
    await tester.tap(find.byKey(const Key('start-seasonal-trial')));
    await tester.pump();
    await capture(tester, 'arcana');
    final pumpkins = tester
        .widgetList<WitchlightPumpkin>(find.byType(WitchlightPumpkin))
        .toList();
    expect(
        pumpkins
            .skip(1)
            .map((p) => WitchlightPumpkin.assetFor(p.variant))
            .toSet(),
        hasLength(6));
    final target = pumpkins.first.variant;
    final index =
        pumpkins.skip(1).toList().indexWhere((p) => p.variant == target);
    now = now.add(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(Key('witchlight-rune-$index')));
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 700));
    final trace = find.byType(WitchlightTracePath);
    final configuration = tester.widget<WitchlightTracePath>(trace);
    final surface = find.byKey(const Key('witchlight-trace-surface'));
    final origin = tester.getTopLeft(surface);
    final points = WitchlightTracePath.points(tester.getSize(surface),
        seed: configuration.seed);
    final finger = await tester.startGesture(origin + points.first);
    for (final point in points.skip(1)) {
      await finger.moveTo(origin + point);
      await tester.pump(const Duration(milliseconds: 30));
    }
    await finger.up();
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 700));
    final ring = find.byKey(const Key('witchlight-strike'));
    expect(ring, findsOneWidget);
    await capture(tester, 'might');
    for (var i = 0; i < 12; i++) {
      final art = find.descendant(of: ring, matching: find.byType(Image));
      final outer = tester.getRect(ring), inner = tester.getRect(art);
      expect(outer.contains(inner.topLeft), isTrue);
      expect(outer.contains(inner.bottomRight), isTrue);
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'compact Trials header keeps countdown, rankings and constellation available',
      (tester) async {
    final game = HouseholdProvider(persistenceEnabled: false)
      ..pet.stage = DragonStage.hatchling
      ..pet.firstEgg = false;
    final online = OnlineAccountProvider(
        repository: DisabledSocialRepository(),
        inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game));
    await mount(
        tester,
        MultiProvider(providers: [
          ChangeNotifierProvider.value(value: game),
          ChangeNotifierProvider.value(value: online),
        ], child: const Scaffold(body: AdventureHubScreen(initialTab: 1))));
    await tester.pump(const Duration(milliseconds: 500));
    await capture(tester, 'trials');
    expect(
        find.text(
            'Your dragon helps, but your performance decides the rewards'),
        findsNothing);
    expect(find.byKey(const Key('open-trial-rankings')), findsOneWidget);
    expect(find.byKey(const Key('trial-streak-card')), findsOneWidget);
    // Measure the compact block itself; the surrounding Adventure heading can
    // wrap differently with the test font or a player's language/text scale.
    final summaryTop =
        tester.getTopLeft(find.byKey(const Key('trial-summary-card'))).dy;
    final streakBottom =
        tester.getBottomRight(find.byKey(const Key('trial-streak-card'))).dy;
    expect(streakBottom - summaryTop, lessThan(200));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    game.dispose();
    online.dispose();
  });
}
