import 'dart:convert';
import 'dart:io';
import 'package:dragon_haven/screens/canonical_school_screen.dart';
import 'package:dragon_haven/models/dragon_school.dart';
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
  late CanonicalUiServer server;
  late CanonicalGameSession session;
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
    addTearDown(() async {
      session.dispose();
      await directory.delete(recursive: true);
    });
    await tester.binding.setSurfaceSize(const Size(360, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: session),
        ],
        child: MaterialApp(
            theme: buildAppTheme(),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(body: child))));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets(
      'Academy restores hero, standings and original pupil cards from server facts',
      (tester) async {
    await setup(tester, const CanonicalSchoolScreen(), prepare: (state) {
      state['towerFloorRoomIds'] = [
        'hearth',
        'hearth',
        'hearth',
        'hearth',
        'hearth'
      ];
      state['pet']['dragonSchoolAttempts'] = {dragonSchoolGames.first.id: 1};
      state['pet']['dragonSchoolRecords'] = {
        dragonSchoolGames.first.id: dragonSchoolGames.first.goldScore
      };
      state['pet']['dragonSchoolStars'] = {dragonSchoolGames.first.id: 3};
    });
    expect(find.text('Practice makes legends'), findsOneWidget);
    expect(find.text('0 final reports'), findsOneWidget);
    expect(find.byKey(const Key('dragon-school-standings')), findsOneWidget);
    expect(find.text('100/1200'), findsOneWidget);
    final lesson =
        find.byKey(Key('canonical-school-${dragonSchoolGames.first.id}'));
    await tester.ensureVisible(lesson);
    await tester.tap(lesson);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Enter classroom'), findsOneWidget);
    expect(
        find.byKey(Key('school-pupil-${session.snapshot!.dragons.first.id}')),
        findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(server.sent, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
