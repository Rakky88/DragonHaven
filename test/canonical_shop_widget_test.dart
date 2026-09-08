import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/canonical_inventory_screen.dart';
import 'package:dragon_haven/screens/shop_hub_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:dragon_haven/widgets/chest_reveal.dart';
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
    const fontPath = String.fromEnvironment('ECONOMY_UI_FONT');
    if (fontPath.isNotEmpty) {
      final icons =
          File('${File(fontPath).parent.path}/materialicons-regular.otf');
      await (FontLoader('MaterialIcons')
            ..addFont(icons
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes))))
          .load();
      await (FontLoader('Roboto')
            ..addFont(File(fontPath)
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes))))
          .load();
    }
  });
  late CanonicalUiServer server;
  late CanonicalGameSession session;
  late HouseholdProvider legacy;
  late Directory directory;
  final screen = GlobalKey();

  Future<void> prepare(WidgetTester tester) async {
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('dh-shop-widget-');
      server = CanonicalUiServer(
          jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>);
      session = CanonicalGameSession(
          connection: CanonicalUiConnection(server), directory: directory);
      legacy = HouseholdProvider(persistenceEnabled: false)..pet.coins = 77777;
      await session.synchronize();
    });
    addTearDown(() async {
      session.dispose();
      legacy.dispose();
      await directory.delete(recursive: true);
    });
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<void> mount(WidgetTester tester, Widget child,
      {String locale = 'en', double scale = 1}) async {
    final baseTheme = buildAppTheme();
    const visual = String.fromEnvironment('ECONOMY_UI_FONT');
    final theme = visual.isEmpty
        ? baseTheme
        : baseTheme.copyWith(
            textTheme: baseTheme.textTheme.apply(fontFamily: 'Roboto'),
            filledButtonTheme: FilledButtonThemeData(
                style: baseTheme.filledButtonTheme.style!.copyWith(
                    textStyle: const WidgetStatePropertyAll(TextStyle(
                        fontFamily: 'Roboto', fontWeight: FontWeight.w800)))),
          );
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: session),
          ChangeNotifierProvider.value(value: legacy),
        ],
        child: MaterialApp(
          theme: theme,
          locale: Locale(locale),
          supportedLocales: const [Locale('en'), Locale('nl')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true),
              child: child!),
          home: RepaintBoundary(key: screen, child: Scaffold(body: child)),
        )));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> waitForCommand(WidgetTester tester) async {
    for (var n = 0; n < 200 && session.busy; n++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(session.busy, isFalse);
    await tester.pump();
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    const target = String.fromEnvironment('ECONOMY_UI_SCREENSHOTS');
    if (target.isEmpty) return;
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
    await tester.runAsync(() async {
      final boundary =
          screen.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(target).create(recursive: true);
      await File('$target/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
      'ordinary shop waits for server stock, survives lost reply and never spends the local save',
      (tester) async {
    await prepare(tester);
    final localBefore = jsonEncode(legacy.exportState());
    final coins = session.snapshot!.coins;
    await mount(tester, const ShopHubScreen(initialCategoryTab: 1));
    final buy = find.byKey(const Key('buy-title-chest'));
    await tester.ensureVisible(buy);
    await tester.pump(const Duration(milliseconds: 400));
    await screenshot(tester, 'shop-en-320');
    server.loseReply = true;
    final held = Completer<void>();
    server.hold = held.future;
    await tester.tap(buy);
    await tester.pump();
    expect(tester.widget<FilledButton>(buy).onPressed, isNull);
    expect(session.snapshot!.coins, coins);
    held.complete();
    await waitForCommand(tester);
    expect(find.textContaining('We could not confirm'), findsWidgets);
    expect(session.snapshot!.coins, coins);
    expect(server.receipts, hasLength(1));
    await tester.tap(find.byKey(const Key('economy-reconnect')));
    await waitForCommand(tester);
    expect(session.snapshot!.coins, coins - 100);
    expect(find.text('1 unopened chests'), findsOneWidget);
    expect(jsonEncode(legacy.exportState()), localBefore);
    expect(server.receipts, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'offline cache is browsable at large Dutch text; signout removes stock without fallback',
      (tester) async {
    await prepare(tester);
    server.online = false;
    await tester.runAsync(() async {
      await expectLater(
          session.synchronize(), throwsA(isA<CanonicalGameException>()));
    });
    await mount(tester, const ShopHubScreen(initialCategoryTab: 1),
        locale: 'nl', scale: 1.35);
    await screenshot(tester, 'shop-nl-offline-320-large');
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('buy-title-chest')))
            .onPressed,
        isNull);
    expect(find.text('77777'), findsNothing);
    (session.connection as CanonicalUiConnection).signOut();
    await tester.pump();
    expect(find.byKey(const Key('buy-title-chest')), findsNothing);
    expect(find.text('77777'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'inventory reveals a real server chest with no local grant or duplicate open',
      (tester) async {
    await prepare(tester);
    final localBefore = jsonEncode(legacy.exportState());
    await mount(tester, const CanonicalInventoryScreen());
    await screenshot(tester, 'inventory-en-320');
    await tester.tap(find.byKey(const Key('canonical-open-wooden')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(server.sent, isEmpty);
    await tester.tap(find.byKey(const Key('chest-reveal-tap-target')));
    await tester.tap(find.byKey(const Key('chest-reveal-tap-target')));
    await waitForCommand(tester);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('chest-rewards')), findsOneWidget);
    expect(session.snapshot!.shop.chests['wooden'], 1);
    expect(server.receipts, hasLength(1));
    expect(jsonEncode(legacy.exportState()), localBefore);
    await tester.tapAt(const Offset(8, 8));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a failed chest reveal offers an exit and cannot dispatch another opening',
      (tester) async {
    await prepare(tester);
    var calls = 0;
    await mount(
        tester,
        Builder(
            builder: (context) => TextButton(
                onPressed: () {
                  showChestReveal(context, ChestTier.wooden,
                      openChest: () async {
                    calls++;
                    throw const CanonicalGameException(
                        'game_command_unavailable');
                  });
                },
                child: const Text('Open'))));
    await tester.tap(find.text('Open'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('chest-reveal-tap-target')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('chest-open-failed')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chest-reveal-tap-target')));
    expect(calls, 1);
    await tester.ensureVisible(find.byKey(const Key('chest-error-close')));
    await tester.tap(find.byKey(const Key('chest-error-close')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('chest-reveal-tap-target')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
