import 'dart:io';
import 'dart:ui' as ui;
import 'package:dragon_haven/models/event_progress.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:dragon_haven/screens/adventure_hub_screen.dart';
import 'package:provider/provider.dart';
import 'package:dragon_haven/widgets/event_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    const font = String.fromEnvironment('ECONOMY_UI_FONT');
    if (font.isNotEmpty) {
      for (final entry in {
        'Roboto': font,
        'MaterialIcons': '${File(font).parent.path}/materialicons-regular.otf'
      }.entries) {
        await (FontLoader(entry.key)
              ..addFont(
                  File(entry.value).readAsBytes().then(ByteData.sublistView)))
            .load();
      }
    }
  });
  EventProgress progress({int points = 0, bool claimed = false}) =>
      EventProgress(
          eventId: 'halloween_witchlight',
          key: 'halloween_witchlight:launch:2026',
          startsAt: DateTime.utc(2026, 10, 24, 22),
          endsAt: DateTime.utc(2026, 11, 1, 23),
          chestId: 'witchlight_chest_v1',
          target: 8000,
          points: points,
          claimed: claimed);
  Widget app(EventProgress p, VoidCallback onClaim,
          {bool reduced = false, double scale = 1}) =>
      MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(
                  disableAnimations: reduced,
                  textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                  body: SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: EventProgressBar(
                              progress: p, onClaim: onClaim))))));

  testWidgets('claim seal only navigates when full and unclaimed',
      (tester) async {
    var clicks = 0;
    for (final (points, claimed, enabled) in [
      (3000, false, false),
      (8000, false, true),
      (8000, true, false)
    ]) {
      await tester.pumpWidget(app(
          progress(points: points, claimed: claimed), () => clicks++,
          reduced: true));
      await tester.pump();
      final button =
          find.byKey(const Key('event-claim-halloween_witchlight:launch:2026'));
      expect(tester.widget<FilledButton>(button).onPressed != null, enabled);
      if (enabled) await tester.tap(button);
      expect(find.text('Claim'), findsNothing);
      expect(tester.takeException(), isNull);
    }
    expect(clicks, 1);
  });

  testWidgets(
      'compact enlarged text and reduced motion settle without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
        app(progress(points: 6400), () {}, reduced: true, scale: 2));
    await tester.pumpAndSettle();
    expect(find.text('6400 / 8000 points'), findsNothing);
    expect(tester.getSize(find.byType(EventProgressBar)).height, 58);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'completed event remains claimable after closing in the real Adventures tab',
      (tester) async {
    var now = DateTime.utc(2026, 10, 26);
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => now);
    game.awardEventPoints(8000);
    final online = OnlineAccountProvider(
        repository: DisabledSocialRepository(),
        inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game));
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: game),
          ChangeNotifierProvider.value(value: online),
        ],
        child: MaterialApp(
            home: MediaQuery(
                data: const MediaQueryData(
                    size: Size(320, 640),
                    disableAnimations: true,
                    textScaler: TextScaler.linear(1.6)),
                child: const Scaffold(body: AdventureHubScreen())))));
    await tester.pump(const Duration(milliseconds: 300));
    final seal =
        find.byKey(const Key('event-claim-halloween_witchlight:launch:2026'));
    await tester.ensureVisible(seal);
    expect(game.visibleEventProgress.single.canClaim, true);
    await tester.tap(seal);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 3);
    expect(find.byType(EventRewardCard), findsOneWidget);
    now = DateTime.utc(2026, 11, 3);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(EventProgressBar), findsNothing);
    expect(find.byType(EventRewardCard), findsOneWidget);
    final claim = find.descendant(
        of: find.byType(EventRewardCard), matching: find.byType(FilledButton));
    await tester.ensureVisible(claim);
    await tester.pump();
    await tester.tap(claim);
    await tester.pump(const Duration(milliseconds: 300));
    expect(game.specialChestInventory['witchlight_chest_v1'], 1);
    expect(find.byType(EventRewardCard), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    online.dispose();
    game.dispose();
  });

  testWidgets(
      'only the active meter survives switches, expiry and server end-event sync',
      (tester) async {
    var now = DateTime.utc(2026, 9, 12);
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => now);
    final online = OnlineAccountProvider(
        repository: const DisabledSocialRepository(),
        inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game));
    await tester.runAsync(() => game.synchronizeSeasonalEventPreviews(
        {'halloween_witchlight': now.add(const Duration(days: 2))}));
    game.activeEventProgress.single.points = 80;
    // This pending claim caused expired meters to linger in the previous UI.
    game.adventureRuns.add(AdventureRun(
        id: 'pending',
        adventureId: AdventureCatalog.mini.first.id,
        dragonId: game.pet.id,
        startedAt: now.subtract(const Duration(minutes: 5)),
        endsAt: now,
        status: AdventureRunStatus.rewardReady));
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: game),
      ChangeNotifierProvider.value(value: online),
    ], child: const MaterialApp(home: Scaffold(body: AdventureHubScreen()))));
    await tester.pump();
    expect(find.byType(EventProgressBar), findsOneWidget);
    await tester.runAsync(() => game.synchronizeSeasonalEventPreviews(
        {'valentine_two_heartlights': now.add(const Duration(days: 2))}));
    await tester.pump();
    expect(find.byType(EventProgressBar), findsOneWidget);
    expect(
        tester
            .widget<EventProgressBar>(find.byType(EventProgressBar))
            .progress
            .eventId,
        'valentine_two_heartlights');
    now = now.add(const Duration(hours: 1));
    await tester.runAsync(() => game.synchronizeSeasonalEventPreviews(
        {'valentine_two_heartlights': now.add(const Duration(days: 2))}));
    await tester.pump();
    expect(game.eventProgress.length, 3);
    expect(find.byType(EventProgressBar), findsOneWidget);
    // Authenticated ENDEVENT returns an empty personal-preview snapshot.
    await tester.runAsync(() => game.synchronizeSeasonalEventPreviews({}));
    await tester.pump();
    expect(find.byType(EventProgressBar), findsNothing);
    await tester.runAsync(() => game.synchronizeSeasonalEventPreviews(
        {'halloween_witchlight': now.add(const Duration(days: 2))}));
    await tester.pump();
    now = now.add(const Duration(days: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(EventProgressBar), findsNothing);
    now = DateTime.utc(2026, 10, 26);
    await tester.runAsync(() => game.refreshForCurrentDate());
    await tester.pump();
    expect(find.byType(EventProgressBar), findsOneWidget);
    await tester.runAsync(() => game.synchronizeSeasonalEventDismissals(
        {'halloween_witchlight': DateTime.utc(2026, 11, 2)}));
    await tester.pump();
    expect(find.byType(EventProgressBar), findsNothing);
    await tester.runAsync(() => game.synchronizeSeasonalEventDismissals({}));
    await tester.pump();
    now = DateTime.utc(2026, 11, 2);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(EventProgressBar), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    online.dispose();
    game.dispose();
  });

  testWidgets('animated progress renders its three reward states',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final boundary = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            backgroundColor: const Color(0xFF151328),
            body: RepaintBoundary(
                key: boundary,
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(height: 20),
                      EventProgressBar(
                          progress: progress(points: 3150), onClaim: () {}),
                      EventProgressBar(
                          progress: progress(points: 8000), onClaim: () {}),
                      EventProgressBar(
                          progress: progress(points: 8000, claimed: true),
                          onClaim: () {}),
                    ]))))));
    await tester.pump(const Duration(milliseconds: 1250));
    expect(tester.takeException(), isNull);
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/event-points-review').create(recursive: true);
      await File('build/event-points-review/progress-states.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
  });
}
