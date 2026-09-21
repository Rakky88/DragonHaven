import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/screens/canonical_adventures_screen.dart';
import 'package:dragon_haven/screens/canonical_trials_screen.dart';
import 'package:dragon_haven/screens/conclave_screen.dart';
import 'package:dragon_haven/screens/canonical_inventory_screen.dart';
import 'package:dragon_haven/screens/canonical_house_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:dragon_haven/widgets/trial_rankings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../tool/game_domain_probe.dart';
import 'support/canonical_ui_server.dart';

class _Rankings extends OnlineAccountProvider {
  _Rankings()
      : super(
            repository: DisabledSocialRepository(),
            serverOwned: true,
            inventorySnapshot: () =>
                throw StateError('No local inventory in canonical rankings'));
  final scopes = <TrialRankingScope>[];
  void joinConclave() {
    conclave = ConclaveSnapshot(
        conclave: const ConclaveSummary(
            id: 'ranked-conclave',
            name: 'Ranked Aerie',
            emblemKey: 'conclave_emblem_01',
            description: '',
            language: 'en',
            visibility: ConclaveVisibility.public,
            memberLimit: 20,
            memberCount: 2,
            level: 1,
            xp: 0,
            aerieStage: 1),
        myRole: ConclaveRole.keeper,
        contributedToday: false,
        members: const [],
        messages: const [],
        chronicle: const [],
        joinRequests: const []);
  }

  @override
  bool get isSignedIn => true;
  @override
  Future<List<TrialRankingEntry>?> loadTrialRankings(
      {required String trialKey, required TrialRankingScope scope}) async {
    scopes.add(scope);
    return [
      TrialRankingEntry(
          position: 1,
          entryKey: trialKey,
          displayName: 'Luna',
          title: 'title_001',
          portraitKey: 'portrait_001',
          score: 8138,
          isCurrentUser: true)
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> fixture;
  setUpAll(() async {
    fixture = (await runGameDomainProbe())['state'] as Map<String, dynamic>;
  });
  late CanonicalUiServer server;
  late CanonicalGameSession session;
  late _Rankings rankings;
  Future<void> setup(WidgetTester tester, Widget child,
      {void Function(Map<String, dynamic>)? prepare}) async {
    late Directory directory;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('dh-ui-parity-');
      final state = jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
      prepare?.call(state);
      server = CanonicalUiServer(state);
      session = CanonicalGameSession(
          connection: CanonicalUiConnection(server), directory: directory);
      await session.synchronize();
    });
    rankings = _Rankings();
    addTearDown(() async {
      session.dispose();
      rankings.dispose();
      await directory.delete(recursive: true);
    });
    await tester.binding.setSurfaceSize(const Size(360, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: session),
          ChangeNotifierProvider<OnlineAccountProvider>.value(value: rankings),
        ],
        child: MaterialApp(
            theme: buildAppTheme(),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(body: child))));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> finish(WidgetTester tester) async {
    for (var i = 0; i < 300 && session.busy; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(session.busy, false);
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets(
      'slow swipe tracks the finger and settles on Trials without a fling',
      (tester) async {
    await setup(tester, const CanonicalAdventuresScreen());
    final pages = find.byType(TabBarView);
    final gesture = await tester.startGesture(tester.getCenter(pages));
    await gesture.moveBy(const Offset(-70, 0));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveBy(const Offset(-90, 0));
    await tester.pump(const Duration(milliseconds: 600));
    final page = find.descendant(of: pages, matching: find.byType(PageView));
    expect(tester.widget<PageView>(page).controller!.page, greaterThan(.1));
    await gesture.moveBy(const Offset(-90, 0));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
    expect(find.byKey(const Key('open-trial-rankings')), findsOneWidget);
    expect(server.sent, isEmpty);
  });
  testWidgets(
      'Trial picker restores draggable sheet, assist text and personal best',
      (tester) async {
    await setup(tester, const CanonicalTrialsScreen(), prepare: (state) {
      state['trialOffers'] = [
        TrialOffer(
                id: 'parity-trial',
                kind: TrialKind.cavernFlight,
                appearedAt: DateTime.utc(2026, 8, 28))
            .toJson()
      ];
    });
    final offer =
        session.snapshot!.trialOffers.firstWhere((o) => o.startedAt == null);
    await tester.tap(find.byKey(Key('choose-trial-${offer.id}')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Choose your Trial dragon'), findsOneWidget);
    final sheet = tester.widget<DraggableScrollableSheet>(
        find.byType(DraggableScrollableSheet));
    expect(sheet.initialChildSize, .72);
    expect(sheet.maxChildSize, .92);
    expect(find.byKey(const Key('trial-dragon-picker')), findsOneWidget);
    expect(find.textContaining('Best:'), findsWidgets);
    expect(server.sent, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final scope in TrialRankingScope.values) {
    testWidgets(
        'original rankings load $scope from canonical UI without HouseholdProvider',
        (tester) async {
      await setup(
          tester,
          Builder(
              builder: (context) => TextButton(
                  onPressed: () => showTrialRankingsSheet(context,
                      scopes: [scope], initialScope: scope),
                  child: const Text('Rankings'))));
      await tester.tap(find.text('Rankings'));
      await tester.pumpAndSettle();
      expect(rankings.scopes, [scope]);
      expect(find.text('Luna'), findsOneWidget);
      expect(find.textContaining('8'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'Conclave Keepers opens actual rankings with server-only providers',
      (tester) async {
    await setup(
        tester,
        Builder(
            builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => const ConclaveScreen())),
                child: const Text('Conclave'))));
    rankings.joinConclave();
    await tester.tap(find.text('Conclave'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keepers'));
    await tester.pumpAndSettle();
    final entry = find.byKey(const Key('open-conclave-trial-rankings'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(rankings.scopes, [TrialRankingScope.conclave]);
    expect(find.text('Luna'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'ordinary server refresh keeps confirmed content steady without inventory spinner',
      (tester) async {
    await setup(tester, const CanonicalAdventuresScreen());
    // Lifecycle invalidation happens before the resumed read is admitted.
    // Keep the existing page quiet even during that intermediate frame.
    session.setForeground(false);
    session.setForeground(true);
    await tester.pump();
    expect(find.byKey(const Key('economy-reconnect')), findsNothing);
    expect(find.byType(TabBarView), findsOneWidget);
    expect(session.canAct, false);
    await tester.runAsync(session.synchronize);
    await tester.pump();
    final held = Completer<void>();
    server.hold = held.future;
    final start = tester
        .widget<IconButton>(
            find.byKey(const Key('canonical-refresh-adventures')))
        .onPressed!;
    start();
    await tester.pump();
    expect(find.textContaining('Checking your inventory'), findsNothing);
    expect(find.byType(TabBarView), findsOneWidget);
    expect(session.canAct, false);
    held.complete();
    await finish(tester);
    expect(tester.takeException(), isNull);
  });
  testWidgets('egg filters contain only currently owned kinds', (tester) async {
    await setup(tester, const CanonicalInventoryScreen(), prepare: (state) {
      final stash = state['eggStash'] as List;
      stash.removeWhere(
          (e) => e['sinister'] == true || e['specialEggId'] != null);
    });
    await tester.tap(find.text('Eggs'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final filters = find.byTooltip('Filter and sort');
    await tester.tap(filters);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.widgetWithText(ChoiceChip, 'Sinister'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Special'), findsNothing);
    expect(server.sent, isEmpty);
  });
  testWidgets('historical tower order drag persists one canonical reorder',
      (tester) async {
    await setup(
        tester,
        Builder(
            builder: (context) => TextButton(
                onPressed: () => showCanonicalRoomOrder(context),
                child: const Text('Arrange'))), prepare: (state) {
      state['towerFloorRoomIds'] = ['hearth', 'crystal'];
      state['unlockedRoomIds'] = ['nest', 'hearth', 'crystal'];
    });
    await tester.tap(find.text('Arrange'));
    await tester.pumpAndSettle();
    final list = tester.widget<ReorderableListView>(
        find.byKey(const Key('tower-room-order-list')));
    list.onReorderItem!(0, 1);
    await tester.pump();
    await finish(tester);
    expect(server.sent.where((i) => i.action == 'reorder_tower_floor'),
        hasLength(1));
    expect(session.snapshot!.house.floorRoomIds, ['crystal', 'hearth']);
    expect(tester.takeException(), isNull);
  });
}
