import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dragon_haven/screens/canonical_inventory_screen.dart';
import 'package:dragon_haven/screens/canonical_dragons_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
    const font = String.fromEnvironment('ECONOMY_UI_FONT');
    if (font.isNotEmpty) {
      for (final entry in {
        'Roboto': font,
        'MaterialIcons': '${File(font).parent.path}/materialicons-regular.otf'
      }.entries) {
        await (FontLoader(entry.key)
              ..addFont(File(entry.value)
                  .readAsBytes()
                  .then((b) => ByteData.sublistView(b))))
            .load();
      }
    }
  });
  late CanonicalUiServer server;
  late CanonicalGameSession session;
  late Directory directory;
  final capture = GlobalKey();
  Future<void> setup(WidgetTester tester, Widget screen,
      {String language = 'en', double scale = 1}) async {
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('dh-lifecycle-ui-');
      server = CanonicalUiServer(
          jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>);
      server.state['eggAltar']
          ['wallet'] = {'fragments': 200, 'essence': 30, 'hearts': 4};
      server.state['eggAltar']['crafted']['nameweaversQuill'] = 1;
      session = CanonicalGameSession(
          connection: CanonicalUiConnection(server), directory: directory);
      await session.synchronize();
    });
    addTearDown(() async {
      session.dispose();
      await directory.delete(recursive: true);
    });
    await tester.binding.setSurfaceSize(const Size(320, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final base = buildAppTheme();
    const font = String.fromEnvironment('ECONOMY_UI_FONT');
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: session,
        child: MaterialApp(
            locale: Locale(language),
            supportedLocales: const [Locale('en'), Locale('nl')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: font.isEmpty
                ? base
                : base.copyWith(
                    textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
                    filledButtonTheme: FilledButtonThemeData(
                        style: base.filledButtonTheme.style!.copyWith(
                            textStyle: const WidgetStatePropertyAll(TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w800))))),
            builder: (context, child) => RepaintBoundary(
                key: capture,
                child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(scale),
                        disableAnimations: true),
                    child: child!)),
            home: Scaffold(body: screen))));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() => tester.tap(finder));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> command(WidgetTester tester) async {
    for (var n = 0; n < 300 && session.busy; n++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(session.busy, isFalse);
    await tester.pump(const Duration(milliseconds: 400));
  }

  Finder key(String value) => find.byKey(Key(value));
  Future<void> shot(WidgetTester tester, String name) async {
    const path = String.fromEnvironment('ECONOMY_UI_SCREENSHOTS');
    if (path.isEmpty) return;
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 450)));
    await tester.pump();
    await tester.runAsync(() async {
      // Capture the root overlay too, including details and confirmation dialogs.
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(path).create(recursive: true);
      await File('$path/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
      'egg details reveal no hidden identity; tag and incubation use the durable session',
      (tester) async {
    await setup(tester, const CanonicalInventoryScreen());
    final egg = session.snapshot!.eggs.first;
    await tap(tester, find.text('Eggs'));
    await tap(tester, key('canonical-egg-${egg.id}'));
    expect(find.text('Dragon: Unknown'), findsOneWidget);
    await tap(tester, key('canonical-tag-egg'));
    await command(tester);
    expect(session.snapshot!.egg(egg.id)!.tagged, isTrue);
    expect(find.text('Untag egg'), findsOneWidget);
    await tap(tester, key('canonical-incubate-egg'));
    await tap(tester, find.widgetWithText(FilledButton, 'Confirm'));
    await command(tester);
    expect(session.snapshot!.nest?.id, egg.id);
    expect(
        tester
            .widget<FilledButton>(find.descendant(
                of: key('canonical-hatch-egg'),
                matching: find.byType(FilledButton)))
            .onPressed,
        isNull);
    server.now =
        session.snapshot!.nest!.hatchAt!.add(const Duration(seconds: 1));
    await tester.runAsync(() => session.synchronize());
    await tester.pump();
    await tap(tester, key('canonical-hatch-egg'));
    await command(tester);
    expect(session.snapshot!.egg(egg.id), isNull);
    expect(session.snapshot!.dragon(egg.id)?.owned, isTrue);
    expect(find.text('This egg has left your inventory.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Sinister return needs two confirmations and reconciles a lost receipt once',
      (tester) async {
    await setup(tester, const CanonicalInventoryScreen());
    final egg = session.snapshot!.eggs.firstWhere((e) => e.kind == 'sinister');
    await tap(tester, find.text('Altar'));
    await tap(tester, key('canonical-altar-choose'));
    await tap(tester, key('canonical-egg-${egg.id}'));
    await tap(tester, key('canonical-place-egg'));
    tester
        .state<ScrollableState>(find
            .descendant(
                of: key('canonical-altar-list'),
                matching: find.byType(Scrollable))
            .first)
        .position
        .jumpTo(0);
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, 'altar-selected');
    await tap(tester, key('canonical-altar-return'));
    await tap(tester, find.widgetWithText(FilledButton, 'Confirm'));
    expect(find.textContaining('This is a Sinister egg'), findsOneWidget);
    await tap(tester, find.widgetWithText(TextButton, 'Cancel'));
    expect(server.sent, isEmpty);
    server.loseReply = true;
    await tap(tester, key('canonical-altar-return'));
    await tap(tester, find.widgetWithText(FilledButton, 'Confirm'));
    await tap(tester, find.widgetWithText(FilledButton, 'Confirm'));
    await command(tester);
    expect(session.snapshot!.egg(egg.id), isNotNull);
    await tap(tester, key('economy-reconnect'));
    await command(tester);
    expect(session.snapshot!.egg(egg.id), isNull);
    expect(session.snapshot!.inventory.materials.fragments, 225);
    expect(server.receipts, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Dutch compact Altar puts Quill first and double craft taps spend once',
      (tester) async {
    await setup(tester, const CanonicalInventoryScreen(),
        language: 'nl', scale: 1.35);
    await tap(tester, find.text('Altar'));
    final craft = key('canonical-craft-nameweaversQuill');
    await tester
        .ensureVisible(find.ancestor(of: craft, matching: find.byType(Card)));
    await tester.pump();
    await shot(tester, 'altar-crafting-nl-large');
    final held = Completer<void>();
    server.hold = held.future;
    await tap(tester, craft);
    await tap(tester, craft);
    for (var n = 0; n < 100 && server.sent.isEmpty; n++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
    }
    held.complete();
    expect(server.sent, hasLength(1));
    await command(tester);
    expect(session.snapshot!.inventory.crafted['nameweaversQuill'], 2);
    expect(session.snapshot!.inventory.materials.fragments, 190);
    expect(session.snapshot!.inventory.materials.essence, 29);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a confirmation cannot survive sign-out and reauthentication of the same owner',
      (tester) async {
    await setup(tester, const CanonicalInventoryScreen());
    final egg = session.snapshot!.eggs.first;
    await tap(tester, find.text('Eggs'));
    await tap(tester, key('canonical-egg-${egg.id}'));
    await tap(tester, key('canonical-incubate-egg'));
    final connection = session.connection as CanonicalUiConnection;
    connection.signOut();
    await tester.pump();
    connection.currentOwner = CanonicalUiServer.owner;
    await tester.runAsync(() => session.synchronize());
    await tester.pump();
    final confirm = find.widgetWithText(FilledButton, 'Confirm');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(find.text('Start incubating this egg?'), findsNothing);
    expect(server.sent, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an open filter closes safely when its account screen is removed',
      (tester) async {
    await setup(tester, const CanonicalInventoryScreen());
    await tap(tester, find.text('Eggs'));
    await tap(tester, key('canonical-egg-filter'));
    (session.connection as CanonicalUiConnection).signOut();
    await tester.pump();
    await tap(tester, find.widgetWithText(ChoiceChip, 'Sinister'));
    expect(find.widgetWithText(ChoiceChip, 'Sinister'), findsNothing);
    expect(server.sent, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a successful rename spends one Quill and closes without a disposed controller',
      (tester) async {
    await setup(tester, const CanonicalDragonsScreen());
    final dragon = session.snapshot!.dragons.first;
    await tap(tester, key('canonical-dragon-${dragon.id}'));
    await tap(tester, key('canonical-name-dragon'));
    await tester.enterText(key('canonical-dragon-name-input'), 'Fresh name');
    await tap(tester, key('canonical-save-name'));
    await command(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(session.snapshot!.dragon(dragon.id)!.name, 'Fresh name');
    expect(session.snapshot!.inventory.crafted['nameweaversQuill'], 0);
    expect(key('canonical-dragon-name-input'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'dragon details show Gender after Maturity and clear a rename dialog at sign-out',
      (tester) async {
    await setup(tester, const CanonicalDragonsScreen());
    final dragon = session.snapshot!.dragons.first;
    await tap(tester, key('canonical-dragon-${dragon.id}'));
    expect(tester.getTopLeft(find.text('Gender')).dy,
        greaterThan(tester.getTopLeft(find.text('Maturity')).dy));
    await shot(tester, 'dragon-details');
    await tap(tester, key('canonical-name-dragon'));
    await tester.enterText(key('canonical-dragon-name-input'), 'Fresh name');
    (session.connection as CanonicalUiConnection).signOut();
    await tester.pump();
    expect(key('canonical-dragon-name-input'), findsNothing);
    expect(find.text('Fresh name'), findsNothing);
    expect(server.sent, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
