import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:dragon_haven/widgets/canonical_game_controls.dart';
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
      'pending button blocks duplicate taps but leaves a second action usable',
      (tester) async {
    final hold = Completer<void>();
    var firstTaps = 0;
    var secondTaps = 0;
    await setup(
        tester,
        Column(children: [
          CanonicalActionButton(
              label: 'First',
              action: () async {
                firstTaps++;
                await session
                    .execute('set_account_name', {'name': 'First Name'});
              }),
          CanonicalActionButton(
              label: 'Second',
              action: () async {
                secondTaps++;
                await session
                    .execute('set_account_name', {'name': 'Second Name'});
              }),
        ]));
    server.hold = hold.future;
    await tester.tap(find.text('First'));
    await tester.pump();
    await tester.tap(find.text('First'));
    await tester.tap(find.text('Second'));
    await tester.pump();
    expect(firstTaps, 1);
    expect(secondTaps, 1);
    expect(session.snapshot!.profile.name, 'Second Name');
    hold.complete();
    for (var i = 0; i < 500 && session.busy; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(session.busy, false);
    expect(server.sent, hasLength(2));
    expect(session.confirmedSnapshot!.profile.name, 'Second Name');
    expect(tester.takeException(), isNull);
  });
}
