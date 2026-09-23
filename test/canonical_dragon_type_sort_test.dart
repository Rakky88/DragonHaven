import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/screens/canonical_dragons_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../tool/game_domain_probe.dart';
import 'support/canonical_ui_server.dart';

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
    late CanonicalGameSession session;
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
    await tester.binding.setSurfaceSize(const Size(420, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
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
      for (var attempt = 0; attempt < 300 && session.busy; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(session.busy, isFalse, reason: session.errorCode);
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.tap(find.byKey(const Key('owned-dragons-sort')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Dragon type'), findsOneWidget);
    await tester.tap(find.text('Dragon type'));
    await tester.pump();
    await finishPreferenceSave();

    double top(String id) =>
        tester.getTopLeft(find.byKey(Key('canonical-dragon-$id'))).dy;
    expect(top(auroracrownId), lessThan(top(mossproutId)));
    expect(top(mossproutId), lessThan(top(worldrootId)));
    expect(find.text('Dragon type'), findsOneWidget);
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
    await tester.tap(find.text('Dragon type').last);
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
}
