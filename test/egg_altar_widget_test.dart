import 'dart:io';
import 'dart:ui' as ui;
import 'package:dragon_haven/models/dragon_egg.dart';
import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/egg_altar_screen.dart';
import 'package:dragon_haven/screens/inventory_screen.dart';
import 'package:dragon_haven/widgets/weave_beacon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final captureKey = GlobalKey();
  final captureFont = Platform.environment['ALTAR_CAPTURE_FONT'];
  setUpAll(() async {
    if (captureFont == null) return;
    final loader = FontLoader('AltarCapture');
    loader.addFont(Future.value(
        ByteData.sublistView(File(captureFont).readAsBytesSync())));
    await loader.load();
    final icons = Platform.environment['ALTAR_CAPTURE_ICONS'];
    if (icons != null) {
      final iconLoader = FontLoader('MaterialIcons');
      iconLoader.addFont(
          Future.value(ByteData.sublistView(File(icons).readAsBytesSync())));
      await iconLoader.load();
    }
  });
  Future<void> capture(WidgetTester tester, String name) async {
    if (Platform.environment['ALTAR_CAPTURE'] != '1') return;
    await tester.runAsync(() async {
      await Future.wait(tester.widgetList<Image>(find.byType(Image)).map(
          (image) => precacheImage(
              image.image, tester.element(find.byType(MaterialApp)))));
    });
    await tester.pump();
    await tester.runAsync(() async {
      final boundary = captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final snapshot = await boundary.toImage(pixelRatio: 2);
      final bytes = await snapshot.toByteData(format: ui.ImageByteFormat.png);
      final file = File('release/altar-$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      snapshot.dispose();
    });
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));
  HouseholdProvider game() => HouseholdProvider(persistenceEnabled: false)
    ..pet = Pet(
        id: 'dragon',
        name: 'Ember',
        firstEgg: false,
        stage: DragonStage.hatchling)
    ..eggStash = [
      DragonEgg(
          id: 'sinister',
          lineageId: 'sinisterra',
          acquiredAt: DateTime(2026),
          hatchSeed: 8,
          prismatic: false)
    ];
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  Future<void> mount(
      WidgetTester tester, HouseholdProvider g, Widget child) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: g,
        child: RepaintBoundary(
            key: captureKey,
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: captureFont == null
                    ? buildAppTheme()
                    : buildAppTheme().copyWith(
                        filledButtonTheme: FilledButtonThemeData(
                            style: buildAppTheme()
                                .filledButtonTheme
                                .style!
                                .copyWith(
                                    textStyle: const WidgetStatePropertyAll(
                                        TextStyle(
                                            fontFamily: 'AltarCapture',
                                            fontWeight: FontWeight.w800)))),
                        primaryTextTheme: buildAppTheme()
                            .primaryTextTheme
                            .apply(fontFamily: 'AltarCapture'),
                        textTheme: buildAppTheme()
                            .textTheme
                            .apply(fontFamily: 'AltarCapture')),
                home: child))));
    await settle(tester);
  }

  Future<void> hold(WidgetTester tester) async {
    final button = find.byKey(const Key('hold-return-to-weave'));
    await tester.scrollUntilVisible(button, 180,
        scrollable: find.byType(Scrollable).first);
    await settle(tester);
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 1200));
    await gesture.up();
    await settle(tester);
  }

  testWidgets(
      'Sinister return requires a hold and a second confirmation; cancelling spends nothing',
      (tester) async {
    final g = game();
    await mount(tester, g, const EggAltarScreen());
    await capture(tester, 'screen');
    await tester.tap(find.byKey(const Key('altar-select-egg')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('altar-egg-sinister')));
    await settle(tester);
    await capture(tester, 'egg-details');
    await tester.tap(find.byKey(const Key('altar-choose-reviewed-egg')));
    await settle(tester);
    await capture(tester, 'selected');
    await hold(tester);
    expect(find.byKey(const Key('confirm-sinister-return')), findsOneWidget);
    final confirmation = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(Text));
    final confirmationText = tester
        .widgetList<Text>(confirmation)
        .map((text) => text.data ?? '')
        .join(' ');
    expect(confirmationText, contains('This cannot be undone.'));
    expect(confirmationText,
        isNot(matches(r'Fragments|Essence|Weaveheart|25|10%')));
    await capture(tester, 'sinister-confirmation');
    expect(g.eggStash, hasLength(1));
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(g.eggAltar.wallet.fragments, 0);
    await hold(tester);
    await tester.tap(find.byKey(const Key('confirm-sinister-return')));
    await settle(tester);
    if (Platform.environment['ALTAR_CAPTURE'] == '1') {
      for (var frame = 1; frame <= 6; frame++) {
        await capture(tester, 'ritual-$frame');
        await tester.pump(const Duration(milliseconds: 780));
      }
    }
    await tester.pump(const Duration(seconds: 6));
    await settle(tester);
    expect(g.eggStash, isEmpty);
    expect(g.eggAltar.wallet.fragments, 25);
    expect(g.eggAltar.wallet.essence, inInclusiveRange(3, 5));
    expect(g.eggAltar.wallet.hearts, inInclusiveRange(0, 1));
    expect(find.text('Continue'), findsOneWidget);
    await capture(tester, 'result');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    g.dispose();
  });

  testWidgets(
      'tagging a selected egg disables return immediately; untagging restores it',
      (tester) async {
    final g = game();
    await mount(tester, g, const EggAltarScreen());
    await tester.tap(find.byKey(const Key('altar-select-egg')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('altar-egg-sinister')));
    await settle(tester);
    await capture(tester, 'egg-details');
    await tester.tap(find.byKey(const Key('altar-choose-reviewed-egg')));
    await settle(tester);
    await capture(tester, 'selected');
    final tag = find.byKey(const Key('egg-tag-sinister'));
    await tester.ensureVisible(tag);
    await tester.tap(tag);
    await settle(tester);
    expect(g.isEggTagged('sinister'), isTrue);
    expect(tester.widget<HoldToReturn>(find.byType(HoldToReturn)).enabled,
        isFalse);
    await tester.tap(tag);
    await settle(tester);
    expect(
        tester.widget<HoldToReturn>(find.byType(HoldToReturn)).enabled, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    g.dispose();
  });

  testWidgets(
      'inventory altar reviews protected eggs and keeps crafting concise',
      (tester) async {
    final g = game();
    await g.setEggTagged('sinister', true);
    await mount(
        tester, g, const Scaffold(body: InventoryScreen(initialTab: 4)));
    expect(find.byKey(const Key('inventory-tab-altar')), findsOneWidget);
    await capture(tester, 'inventory');
    await tester.tap(find.byKey(const Key('altar-tutorial')));
    await settle(tester);
    final tutorial =
        tester.widget<Text>(find.byKey(const Key('altar-tutorial-text'))).data!;
    expect(tutorial, contains('hold Return to the Weave'));
    expect(tutorial, isNot(matches(r'%|odds|without a Weaveheart')));
    await capture(tester, 'tutorial');
    await tester.tap(find.text('Got it'));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('altar-select-egg')));
    await tester.tap(find.byKey(const Key('altar-select-egg')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('altar-egg-sinister')));
    await settle(tester);
    expect(find.text('Dragon family'), findsOneWidget);
    expect(find.text('Still hidden'), findsNWidgets(3));
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const Key('altar-choose-reviewed-egg')))
            .onPressed,
        isNull);
    // No mutation or accidental selection while inspecting a protected egg.
    expect(g.eggStash, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    await mount(tester, g, const EggAltarScreen());
    await tester.tap(find.text('Craft'));
    await settle(tester);
    expect(
        tester
            .widgetList<AltarRecipeCard>(find.byType(AltarRecipeCard))
            .first
            .relic,
        AltarRelic.nameweaversQuill);
    await capture(tester, 'craft');
    final descriptions = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data ?? '')
        .join(' ');
    expect(descriptions,
        isNot(matches(r'existing drops|Altar exclusive|without a Weaveheart')));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    g.dispose();
  });

  testWidgets(
      'Beacon confirmation submits the selected amount once and refreshes its shared progress',
      (tester) async {
    final g = game()..eggAltar.wallet = const WeaveWallet(40, 0, 0);
    var amount = 490;
    var commands = 0;
    g.altarCurrentUserId = () => 'keeper';
    g.loadWeaveBeacon = (_) async => {'fragments': amount};
    g.altarCommand = (id, action, payload) async {
      expect(action, 'donate');
      expect(payload, {'conclaveId': 'conclave', 'amount': 10});
      commands++;
      amount += 10;
      return {
        'state': {
          ...g.eggAltar.toJson(),
          'ownerId': 'keeper',
          'wallet': const WeaveWallet(30, 0, 0).toJson()
        },
        'receipt': {'donated': 10}
      };
    };
    await mount(
        tester,
        g,
        const Scaffold(
            body: SingleChildScrollView(
                child: WeaveBeaconCard(conclaveId: 'conclave', active: true))));
    await tester.tap(find.text('Weave Beacon'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('donate-weave-fragments')));
    await settle(tester);
    await tester.enterText(
        find.byKey(const Key('beacon-donation-amount')), '10');
    await tester.tap(find.byKey(const Key('confirm-beacon-donation')));
    await settle(tester);
    expect(commands, 1);
    expect(g.eggAltar.wallet.fragments, 30);
    expect(find.text('500 / 5000'), findsOneWidget);
    expect(find.text('Stage 1 / 3'), findsOneWidget);
    await capture(tester, 'beacon');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    g.dispose();
  });
}
