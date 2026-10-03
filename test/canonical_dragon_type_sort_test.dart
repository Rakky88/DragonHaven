import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/screens/canonical_dragons_screen.dart';
import 'package:dragon_haven/services/canonical_game_reconciler.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../tool/game_domain_probe.dart';
import 'support/canonical_ui_server.dart';

class _PreferenceTrackingSession extends CanonicalGameSession {
  _PreferenceTrackingSession(
      {required super.connection, required super.directory});

  // Constructed in runAsync so journal I/O can complete outside fake time.
  final _ioZone = Zone.current;
  Future<CanonicalGameReceipt?>? preferenceSave;

  @override
  Future<CanonicalGameReceipt?> execute(
      String action, Map<String, dynamic> payload,
      {bool optimistic = true}) {
    final result = _ioZone
        .run(() => super.execute(action, payload, optimistic: optimistic));
    if (action == 'set_preferences') preferenceSave = result;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> fixture;
  setUpAll(() async {
    fixture = (await runGameDomainProbe())['state'] as Map<String, dynamic>;
  });

  testWidgets(
      'My Dragons sorts dragon types alphabetically in both directions and saves the choice',
      (tester) async {
    late Directory directory;
    late _PreferenceTrackingSession session;
    late CanonicalUiServer server;
    late String auroracrownId;
    const mossproutId = 'sort-mossprout';
    const worldrootId = 'sort-worldroot';

    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('dh-dragon-sort-');
      final state = jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
      final pet = state['pet'] as Map<String, dynamic>;
      auroracrownId = pet['id'] as String;
      pet
        ..['lineageId'] = dragonLineages
            .firstWhere((lineage) => lineage.nameEn == 'Auroracrown')
            .id
        ..['name'] = 'Zulu';

      Map<String, dynamic> additionalDragon(
          String id, String lineageName, String name) {
        final dragon = jsonDecode(jsonEncode(pet)) as Map<String, dynamic>;
        return dragon
          ..['id'] = id
          ..['lineageId'] = dragonLineages
              .firstWhere((lineage) => lineage.nameEn == lineageName)
              .id
          ..['name'] = name
          ..['favorite'] = false;
      }

      state
        ..['sanctuaryDragons'] = [
          additionalDragon(mossproutId, 'Mossprout', 'Middle'),
          additionalDragon(worldrootId, 'Worldroot', 'Alpha'),
        ]
        ..['myDragonsViewMode'] = 'compact'
        ..['myDragonsSortMode'] = 'acquiredAt'
        ..['myDragonsSortDescending'] = true;
      server = CanonicalUiServer(state);
      session = _PreferenceTrackingSession(
        connection: CanonicalUiConnection(server),
        directory: directory,
      );
      await session.synchronize();
    });
    addTearDown(() async {
      session.dispose();
      await directory.delete(recursive: true);
    });
    await tester.binding.setSurfaceSize(const Size(420, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider<CanonicalGameSession>.value(
        value: session,
        child: MaterialApp(
          theme: buildAppTheme(),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const Scaffold(body: CanonicalDragonsScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    Future<void> finishPreferenceSave() async {
      final preferenceSave = session.preferenceSave;
      expect(preferenceSave, isNotNull);
      session.preferenceSave = null;
      await tester.runAsync(() async {
        final receipt = await preferenceSave;
        expect(receipt?.succeeded, isTrue);
      });
      expect(session.busy, isFalse, reason: session.errorCode);
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.tap(find.byKey(const Key('owned-dragons-sort')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Type'), findsOneWidget);
    await tester.tap(find.text('Type'));
    await tester.pump();
    await finishPreferenceSave();

    double top(String id) =>
        tester.getTopLeft(find.byKey(Key('canonical-dragon-$id'))).dy;
    expect(top(auroracrownId), lessThan(top(mossproutId)));
    expect(top(mossproutId), lessThan(top(worldrootId)));
    expect(find.text('Type'), findsOneWidget);
    expect(server.sent, hasLength(1));
    expect(server.sent.single.action, 'set_preferences');
    expect(
      jsonDecode(server.sent.single.payload['changes'] as String),
      containsPair('myDragonsSortMode', 'dragonType'),
    );
    expect(
      jsonDecode(server.sent.single.payload['changes'] as String),
      containsPair('myDragonsSortDescending', false),
    );

    await tester.tap(find.byKey(const Key('owned-dragons-sort')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Type').last);
    await tester.pump();
    await finishPreferenceSave();

    expect(top(worldrootId), lessThan(top(mossproutId)));
    expect(top(mossproutId), lessThan(top(auroracrownId)));
    expect(server.sent, hasLength(2));
    expect(
      jsonDecode(server.sent.last.payload['changes'] as String),
      containsPair('myDragonsSortDescending', true),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('My Dragons controls stay on one row on a compact phone',
      (tester) async {
    late Directory directory;
    late CanonicalGameSession session;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('dh-dragon-row-');
      final state = jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>
        ..['myDragonsSortMode'] = 'dragonType'
        ..['myDragonsViewMode'] = 'compact';
      final server = CanonicalUiServer(state);
      session = CanonicalGameSession(
        connection: CanonicalUiConnection(server),
        directory: directory,
      );
      await session.synchronize();
    });
    addTearDown(() async {
      session.dispose();
      await directory.delete(recursive: true);
    });
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider<CanonicalGameSession>.value(
        value: session,
        child: MaterialApp(
          theme: buildAppTheme(),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const Scaffold(body: CanonicalDragonsScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final controls = [
      find.byKey(const Key('owned-dragons-title')),
      find.byKey(const Key('owned-dragons-sort')),
      find.byKey(const Key('owned-dragons-filter')),
      find.byKey(const Key('owned-dragons-view-toggle')),
    ];
    final centers = controls.map(tester.getCenter).map((p) => p.dy).toList();
    expect(centers.every((dy) => (dy - centers.first).abs() < 1), isTrue);
    expect(find.text('Type'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
