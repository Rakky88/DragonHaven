import 'dart:convert';
import 'dart:io';
import 'package:dragon_haven/screens/canonical_dragons_screen.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/widgets/restored_collection_cards.dart';
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
      'collection restores original toolbar, owned-only filters and direct form filtering',
      (tester) async {
    await setup(tester, const CanonicalDragonsScreen());
    expect(find.byKey(const Key('owned-dragons-sort')), findsOneWidget);
    expect(find.byKey(const Key('tower-roaming-capacity')), findsOneWidget);
    await tester.tap(find.byKey(const Key('owned-dragons-filter')));
    await tester.pump(const Duration(milliseconds: 400));
    final owned = session.snapshot!.dragons.where((d) => d.owned).toList();
    final forms = owned
        .map((d) => switch (d.stage) {
              DragonStage.hatchling => 'hatchling',
              DragonStage.wyrmling => 'wyrmling',
              _ => d.path
            })
        .toSet();
    for (final form in [
      'hatchling',
      'wyrmling',
      'might',
      'arcana',
      'spirit',
      'mastery'
    ]) {
      expect(find.byKey(Key('dragon-filter-form-$form')),
          forms.contains(form) ? findsOneWidget : findsNothing);
    }
    expect(find.byKey(const Key('owned-dragons-filter-clear')), findsOneWidget);
    expect(find.byKey(const Key('owned-dragons-filter-done')), findsOneWidget);
    expect(server.sent, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'dragon details restore progress and personal trial records without local inventory',
      (tester) async {
    await setup(
        tester,
        Builder(
            builder: (context) => TextButton(
                onPressed: () => showCanonicalDragonDetails(
                    context,
                    context
                        .read<CanonicalGameSession>()
                        .snapshot!
                        .dragons
                        .firstWhere((d) => d.owned)
                        .id),
                child: const Text('Details'))));
    await tester.tap(find.text('Details'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('dragon-level-progress')), findsOneWidget);
    expect(find.byKey(const Key('dragon-trial-records')), findsOneWidget);
    expect(find.byType(RestoredNeedBar), findsNothing);
    expect(server.sent, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
