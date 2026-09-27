import 'dart:io';
import 'dart:ui' as ui;
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:dragon_haven/widgets/trial_rankings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _RankingsOnline extends OnlineAccountProvider {
  _RankingsOnline(HouseholdProvider game)
      : super(
            repository: const DisabledSocialRepository(),
            inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game));
  final rankingRequests = <(String, TrialRankingScope)>[];
  @override
  bool get isSignedIn => true;
  @override
  Future<List<TrialRankingEntry>?> loadTrialRankings(
      {required String trialKey, required TrialRankingScope scope}) async {
    rankingRequests.add((trialKey, scope));
    return [
      TrialRankingEntry(
          position: 1,
          entryKey: trialKey,
          displayName: 'Luna',
          title: 'title_001',
          portraitKey: 'portrait_001',
          score: 8138,
          isCurrentUser: true),
    ];
  }
}

void _expectAllStandardChoicesVisible(WidgetTester tester) {
  final viewport =
      tester.getRect(find.byKey(const Key('trial-rankings-sheet')));
  for (final kind in standardTrialKinds) {
    final choice = find.byKey(Key('trial-ranking-kind-${kind.name}'));
    expect(choice.hitTestable(), findsOneWidget, reason: kind.name);
    final bounds = tester.getRect(choice);
    expect(bounds.left, greaterThanOrEqualTo(viewport.left), reason: kind.name);
    expect(bounds.right, lessThanOrEqualTo(viewport.right), reason: kind.name);
    expect(bounds.top, greaterThanOrEqualTo(viewport.top), reason: kind.name);
    expect(bounds.bottom, lessThanOrEqualTo(viewport.bottom),
        reason: kind.name);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    const font = String.fromEnvironment('ECONOMY_UI_FONT');
    if (font.isNotEmpty) {
      await (FontLoader('Roboto')
            ..addFont(File(font).readAsBytes().then(ByteData.sublistView)))
          .load();
    }
    const icons = String.fromEnvironment('MATERIAL_ICONS_FONT');
    if (icons.isNotEmpty) {
      await (FontLoader('MaterialIcons')
            ..addFont(File(icons).readAsBytes().then(ByteData.sublistView)))
          .load();
    }
  });

  for (final (width, height, scale) in [
    (390.0, 844.0, 1.0),
    (320.0, 568.0, 1.0),
    (286.0, 630.0, 1.0),
    (320.0, 568.0, 1.6)
  ]) {
    testWidgets(
        'one illustrated event ranking at $width with text scale $scale',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, height));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, height);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var now = DateTime.utc(2026, 9, 12);
      final game =
          HouseholdProvider(persistenceEnabled: false, clock: () => now);
      final online = _RankingsOnline(game);
      final end = now.add(const Duration(days: 2));
      await tester.runAsync(() => game.synchronizeSeasonalEventPreviews(
          {'valentine_two_heartlights': end}));
      final boundary = GlobalKey();
      await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: game),
            ChangeNotifierProvider<OnlineAccountProvider>.value(value: online),
          ],
          child: RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(scale),
                        disableAnimations: true),
                    child: child!),
                home: Builder(
                    builder: (context) => Scaffold(
                        body: Center(
                            child: FilledButton(
                                onPressed: () => showTrialRankingsSheet(context,
                                    scopes: const [
                                      TrialRankingScope.world,
                                      TrialRankingScope.friends
                                    ],
                                    initialScope: TrialRankingScope.world,
                                    initialKind: TrialKind.rosevowRelay),
                                child: const Text('Open rankings'))))),
              ))));
      await tester.tap(find.text('Open rankings'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('trial-ranking-kind-rosevowRelay')),
          findsOneWidget);
      for (final kind in standardTrialKinds) {
        expect(
            find.byKey(Key('trial-ranking-kind-${kind.name}')), findsOneWidget);
      }
      expect(find.text('Basic trials'), findsOneWidget);
      expect(find.text('Ascended trials'), findsOneWidget);
      if (scale == 1) _expectAllStandardChoicesVisible(tester);
      expect(
          find.descendant(
              of: find.byKey(const Key('trial-ranking-kind-selector')),
              matching: find.byWidgetPredicate((widget) =>
                  widget is Scrollable &&
                  (widget.axisDirection == AxisDirection.left ||
                      widget.axisDirection == AxisDirection.right))),
          findsNothing);
      // All six are visible together at normal text size. Enlarged system
      // text may use vertical scrolling without hiding choices sideways.
      final lastStandard =
          find.byKey(const Key('trial-ranking-kind-runeOrbit'));
      await tester.ensureVisible(lastStandard);
      await tester.pumpAndSettle();
      await tester.tap(lastStandard);
      await tester.pumpAndSettle();
      if (scale > 1) {
        await tester.dragUntilVisible(
            find.byKey(const Key('trial-ranking-entry-runeOrbit')),
            find.byType(NestedScrollView),
            const Offset(0, -100));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('trial-ranking-entry-runeOrbit')),
          findsOneWidget);
      final seasonalChoice =
          find.byKey(const Key('trial-ranking-kind-rosevowRelay'));
      // After reading a result the scrollable header may be outside the
      // sliver viewport. Scroll back to build it before selecting the event.
      await tester.dragUntilVisible(
          seasonalChoice, find.byType(NestedScrollView), const Offset(0, 100));
      await tester.pumpAndSettle();
      await tester.tap(seasonalChoice);
      await tester.pumpAndSettle();
      if (scale > 1) {
        await tester.dragUntilVisible(
            find.byKey(const Key('trial-ranking-entry-rosevowRelay')),
            find.byType(NestedScrollView),
            const Offset(0, -100));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('trial-ranking-entry-rosevowRelay')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      const review = bool.fromEnvironment('EVENT_RANKING_REVIEW');
      if (review) {
        tester
            .state<NestedScrollViewState>(find.byType(NestedScrollView))
            .outerController
            .jumpTo(0);
        await tester.pumpAndSettle();
        final imageContext =
            tester.element(find.byKey(const Key('trial-rankings-sheet')));
        await tester.runAsync(() async {
          await Future.wait([
            for (final widget in tester.widgetList<Image>(find.byType(Image)))
              precacheImage(widget.image, imageContext),
            precacheImage(
                const AssetImage(
                    'assets/images/events/valentine/trial_background.webp'),
                imageContext),
          ]);
        });
        await tester.pumpAndSettle();
        final render = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/event-points-review').create(recursive: true);
          await File('build/event-points-review/rankings-$width-$scale.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      now =
          end.add(const Duration(days: 3)).subtract(const Duration(seconds: 1));
      expect(
          game.trialRankingEventWindow?.event.id, 'valentine_two_heartlights');
      await tester.pump(const Duration(seconds: 1));
      expect(
          find.byKey(const Key('trial-ranking-kind-rosevowRelay'),
              skipOffstage: false),
          findsOneWidget);
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('trial-ranking-kind-rosevowRelay')),
          findsNothing);
      expect(find.byKey(const Key('trial-ranking-entry-rosevowRelay')),
          findsNothing);
      if (scale > 1) {
        await tester.dragUntilVisible(
            find.byKey(const Key('trial-ranking-entry-cavernFlight')),
            find.byType(NestedScrollView),
            const Offset(0, -100));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('trial-ranking-entry-cavernFlight')),
          findsOneWidget);
      await tester.runAsync(() => game.synchronizeSeasonalEventPreviews(
          {'halloween_witchlight': now.add(const Duration(days: 2))}));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('trial-ranking-kind-witchlightWard'),
              skipOffstage: false),
          findsOneWidget);
      expect(find.byKey(const Key('trial-ranking-kind-rosevowRelay')),
          findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      online.dispose();
      game.dispose();
    });
  }

  testWidgets(
      'Conclave ranks each of the six visible Basic and Ascended trials',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = HouseholdProvider(
        persistenceEnabled: false, clock: () => DateTime.utc(2026, 9, 12));
    final online = _RankingsOnline(game);
    expect(game.trialRankingEventWindow, isNull);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider<OnlineAccountProvider>.value(value: online),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
                onPressed: () => showTrialRankingsSheet(context,
                    scopes: const [TrialRankingScope.conclave],
                    initialScope: TrialRankingScope.conclave),
                child: const Text('Conclave rankings')),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Conclave rankings'));
    await tester.pumpAndSettle();
    expect(find.text('Basic trials'), findsOneWidget);
    expect(find.text('Ascended trials'), findsOneWidget);
    expect(find.byKey(const Key('trial-ranking-scope-selector')), findsNothing);
    _expectAllStandardChoicesVisible(tester);
    for (final kind in standardTrialKinds) {
      await tester.tap(find.byKey(Key('trial-ranking-kind-${kind.name}')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(Key('trial-ranking-entry-${kind.name}')), findsOneWidget);
      expect(online.rankingRequests,
          contains((kind.name, TrialRankingScope.conclave)));
      _expectAllStandardChoicesVisible(tester);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    online.dispose();
    game.dispose();
  });
}
