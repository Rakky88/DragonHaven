import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dragon_haven/dragonhaven_app.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/screens/adventure_hub_screen.dart';
import 'package:dragon_haven/screens/draconomicon_screen.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:dragon_haven/widgets/dragon_expertise_row.dart';
import 'package:dragon_haven/widgets/seasonal_app_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final captureKey = GlobalKey();
  setUpAll(() async {
    for (final entry in {
      'Roboto': Platform.environment['ALTAR_CAPTURE_FONT'],
      'Ahem': Platform.environment['ALTAR_CAPTURE_FONT'],
      'MaterialIcons': Platform.environment['ALTAR_CAPTURE_ICONS'],
    }.entries) {
      if (entry.value == null) continue;
      final loader = FontLoader(entry.key)
        ..addFont(Future.value(
            ByteData.sublistView(File(entry.value!).readAsBytesSync())));
      await loader.load();
    }
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> reveal(WidgetTester tester, Finder finder,
      {bool towardTop = false}) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(finder, towardTop ? -200 : 200,
          scrollable: find.byType(Scrollable).last);
    }
    await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
    await tester.pump();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (Platform.environment['ALTAR_CAPTURE'] != '1') return;
    await tester.runAsync(() async {
      final context = tester.element(find.byType(MaterialApp));
      await Future.wait([
        for (final image in tester.widgetList<Image>(find.byType(Image)))
          precacheImage(image.image, context),
        for (final box
            in tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)))
          if (box.decoration is BoxDecoration &&
              (box.decoration as BoxDecoration).image != null)
            precacheImage(
                (box.decoration as BoxDecoration).image!.image, context),
      ]);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.runAsync(() async {
      final boundary = captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('release/event-training-$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<HouseholdProvider> mount(WidgetTester tester,
      {DateTime Function()? clock,
      bool event = false,
      bool shell = true,
      double scale = 1}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final now = clock ?? () => DateTime.utc(2026, 9, 8, 12);
    final game = HouseholdProvider(
        persistenceEnabled: false, random: Random(31), clock: now)
      ..onboardingComplete = true
      ..tutorialCompleted = true
      ..tutorialFullyViewed = true;
    game.pet = Pet(
        id: 'marked',
        name: 'Nova',
        stage: DragonStage.hatchling,
        firstEgg: false,
        lineageId: 'clockskip',
        hatchSeed: 831,
        acquiredAt: now(),
        stageStartedAt: now(),
        needsUpdatedAt: now(),
        training: {'might': 25, 'arcana': 40, 'spirit': 60});
    game.sanctuaryDragons = [
      Pet(
          id: 'unmarked',
          name: 'Luna',
          stage: DragonStage.hatchling,
          lineageId: 'clockskip',
          firstEgg: false,
          hatchSeed: 832,
          acquiredAt: now(),
          stageStartedAt: now(),
          needsUpdatedAt: now(),
          training: {'might': 120, 'arcana': 130, 'spirit': 140})
    ];
    game.beginPresentationDeferral();
    if (event) {
      game.seasonalEventPreviewExpiresAt['halloween_witchlight'] =
          now().add(const Duration(days: 2));
    }
    final online = OnlineAccountProvider(
        repository: const DisabledSocialRepository(),
        inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game));
    addTearDown(game.dispose);
    addTearDown(online.dispose);
    await tester.pumpWidget(RepaintBoundary(
        key: captureKey,
        child: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: game),
              ChangeNotifierProvider.value(value: online),
            ],
            child: shell
                ? const DragonHavenApp()
                : MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: buildAppTheme(),
                    home: const Scaffold(body: AdventureHubScreen())))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    return game;
  }

  test('live event wins over previews and expired windows are excluded', () {
    final event = specialAdventureEventById('halloween_witchlight')!;
    final now = DateTime.utc(2026, 9, 8);
    SpecialAdventureWindow window(String key, DateTime end) =>
        SpecialAdventureWindow(
            event: event,
            key: key,
            startsAt: now.subtract(const Duration(days: 1)),
            endsAt: end);
    final preview =
        window('halloween:preview:test', now.add(const Duration(hours: 1)));
    final live = window('halloween:2026', now.add(const Duration(days: 1)));
    expect(appEventWindow([preview, live], now)?.key, live.key);
    expect(appEventWindow([preview], preview.endsAt), isNull);
  });

  testWidgets(
      'event artwork, logo and countdown reach every main tab and expire',
      (tester) async {
    var now = DateTime.utc(2026, 9, 8, 12);
    final game = await mount(tester, clock: () => now, event: true);
    expect(find.byKey(const Key('app-event-background')), findsOneWidget);
    expect(find.byKey(const Key('app-event-logo-emblem')), findsOneWidget);
    expect(find.textContaining('Ends in 2d'), findsOneWidget);
    await capture(tester, 'tower');
    for (final destination in ['friends', 'adventure', 'inventory', 'shop']) {
      await tester.tap(find.byKey(Key('tutorial-nav-$destination')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byKey(const Key('app-event-countdown')), findsOneWidget);
    }
    await capture(tester, 'shop');
    now = now.add(const Duration(days: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('app-event-countdown')), findsNothing);
    expect(find.byKey(const Key('app-event-background')), findsNothing);
    expect(game.seasonalEventPreviewExpiresAt, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('My Dragons highlights independent Expertise rows and shows sex',
      (tester) async {
    final game = await mount(tester, event: true);
    await tester.tap(find.byKey(const Key('open-my-dragons')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byKey(const Key('dragon-sex-marked')), findsOneWidget);
    await tester.tap(find.byKey(const Key('owned-dragon-marked')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    for (final focus in [TrainingFocus.arcana, TrainingFocus.spirit]) {
      final row = find.byKey(Key('expertise-highlight-marked-${focus.name}'));
      await reveal(tester, row);
      await tester.tap(row);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(game.pet.highlightedExpertises,
        {TrainingFocus.arcana, TrainingFocus.spirit});
    await capture(tester, 'dragon-details');
    await reveal(
        tester, find.byKey(const Key('expertise-highlight-marked-arcana')));
    await tester
        .tap(find.byKey(const Key('expertise-highlight-marked-arcana')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(game.pet.highlightedExpertises, {TrainingFocus.spirit});
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'Trial picker prioritizes highlights and returns intact from the codex',
      (tester) async {
    final game = await mount(tester, shell: false, scale: 1.6);
    game.pet.highlightedExpertises.addAll(TrainingFocus.values);
    await tester.tap(find.byKey(const Key('adventure-tab-trials')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final offer = game.availableTrials.first;
    await reveal(tester, find.byKey(Key('trial-offer-${offer.id}')));
    await tester.tap(find.byKey(Key('trial-offer-${offer.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('HIGHLIGHTED FOR THIS PATH'), findsOneWidget);
    final info = find.byKey(const Key('dragon-expertise-info-marked'));
    await reveal(tester, info);
    await tester.tap(info);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DragonExpertiseRow), findsNWidgets(3));
    expect(game.trialOffers.any((o) => o.id == offer.id && o.startedAt != null),
        isFalse);
    await capture(tester, 'trial-expertise');
    await tester.tap(find.text('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final shortcut = find.byKey(const Key('dragon-picker-draconomicon'));
    await reveal(tester, shortcut, towardTop: true);
    await tester.pump();
    await capture(tester, 'trial-picker');
    await tester.tap(shortcut);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(DraconomiconScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('trial-dragon-picker')), findsOneWidget);
    expect(game.trialOffers.any((o) => o.id == offer.id && o.startedAt != null),
        isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'Adventure picker shows the marked dragon first and preserves selection through the codex',
      (tester) async {
    final game = await mount(tester, shell: false, scale: 1.6);
    final adventure = game.adventuresFor(AdventureKind.mini).first;
    game.pet.highlightedExpertises.add(adventure.focus);
    final details = find.byKey(Key('adventure-details-${adventure.id}'));
    await reveal(tester, details);
    await tester.tap(details);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    final choose = find.byKey(const Key('adventure-details-choose-dragon'));
    await reveal(tester, choose);
    await tester.tap(choose);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('HIGHLIGHTED FOR THIS PATH'), findsOneWidget);
    final marked = find.byKey(const Key('adventure-dragon-marked'));
    final other = find.byKey(const Key('adventure-dragon-unmarked'));
    expect(tester.getTopLeft(marked).dy, lessThan(tester.getTopLeft(other).dy));
    final info = find.byKey(const Key('dragon-expertise-info-marked'));
    await reveal(tester, info);
    await tester.tap(info);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DragonExpertiseRow), findsNWidgets(3));
    await tester.tap(find.text('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final shortcut = find.byKey(const Key('dragon-picker-draconomicon'));
    await reveal(tester, shortcut, towardTop: true);
    await capture(tester, 'adventure-picker');
    await tester.tap(shortcut);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byType(DraconomiconScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byKey(const Key('adventure-dragon-picker-scroll')),
        findsOneWidget);
    expect(game.activeAdventureRuns, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
