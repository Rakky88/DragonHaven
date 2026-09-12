import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dragon_haven/screens/canonical_inventory_screen.dart';
import 'package:dragon_haven/screens/canonical_dragons_screen.dart';
import 'package:dragon_haven/screens/canonical_adventures_screen.dart';
import 'package:dragon_haven/screens/canonical_house_screen.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/widgets/expertise_score_badge.dart';
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
      {String language = 'en',
      double scale = 1,
      void Function(CanonicalUiServer)? prepare}) async {
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('dh-lifecycle-ui-');
      server = CanonicalUiServer(
          jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>);
      server.state['eggAltar']
          ['wallet'] = {'fragments': 200, 'essence': 30, 'hearts': 4};
      server.state['eggAltar']['crafted']['nameweaversQuill'] = 1;
      prepare?.call(server);
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
    // A newly prepended run may be above the retained offer-list scroll offset.
    // Scroll it into the lazy list before asking ensureVisible for its element.
    final list = find.byWidgetPredicate((widget) => const [
          Key('canonical-adventures-list'),
          Key('canonical-tower-list'),
          Key('canonical-rooms-list'),
          Key('canonical-room-editor-list'),
          Key('canonical-tower-list'),
          Key('canonical-rooms-list')
        ].contains(widget.key));
    if (finder.evaluate().isEmpty && list.evaluate().isNotEmpty) {
      final scrollable =
          find.descendant(of: list, matching: find.byType(Scrollable)).first;
      tester.state<ScrollableState>(scrollable).position.jumpTo(0);
      await tester.pump();
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
      }
    }
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
    for (var n = 0; n < 1000 && server.sent.isEmpty; n++) {
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

  testWidgets(
      'Adventure picker inspections preserve selection and lost start/claim recover once',
      (tester) async {
    await setup(tester, const CanonicalAdventuresScreen());
    await tap(tester, key('canonical-refresh-adventures'));
    await command(tester);
    final id = session.snapshot!.adventures.offers(AdventureKind.mini).first;
    final dragon = session.snapshot!.dragons.first;
    final stock = session.snapshot!.shop.chests['wooden'] ?? 0;
    await tap(tester, key('canonical-select-adventure-$id'));
    final before = server.sent.length;
    await tap(tester, key('canonical-expertise-info-${dragon.id}'));
    expect(find.text('Might'), findsWidgets);
    expect(find.text('Arcana'), findsWidgets);
    expect(find.text('Spirit'), findsWidgets);
    await tap(tester, find.widgetWithText(TextButton, 'Close'));
    final start = find.descendant(
        of: key('canonical-start-adventure'),
        matching: find.byType(FilledButton));
    expect(tester.widget<FilledButton>(start).onPressed, isNull);
    await tap(tester, key('canonical-adventure-dragon-${dragon.id}'));
    await tap(tester, key('dragon-picker-draconomicon'));
    await tap(tester, find.byType(BackButton));
    expect(tester.widget<FilledButton>(start).onPressed, isNotNull);
    expect(server.sent, hasLength(before));
    await shot(tester, 'adventure-picker');
    server.loseReply = true;
    await tap(tester, key('canonical-start-adventure'));
    await command(tester);
    await tap(tester, find.widgetWithText(TextButton, 'Cancel'));
    await tap(tester, key('economy-reconnect'));
    await command(tester);
    final run = session.snapshot!.adventures.runs.single;
    expect(run.revealedRewardId, isNull);
    server.now = run.endsAt.add(const Duration(seconds: 1));
    await tester.runAsync(() => session.synchronize());
    await tester.pump();
    server.loseReply = true;
    await tap(tester, key('canonical-tab-completed'));
    await tap(tester, key('canonical-claim-${run.id}'));
    await command(tester);
    await tap(tester, key('economy-reconnect'));
    await command(tester);
    expect(session.snapshot!.adventures.runs, isEmpty);
    expect(session.snapshot!.shop.chests['wooden'], stock + 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'Dutch large-text Adventure controls and Wayfinder confirmation fit and spend once',
      (tester) async {
    await setup(tester, const CanonicalAdventuresScreen(),
        language: 'nl', scale: 1.35, prepare: (server) {
      server.state['relicInventory']['wayfinderSigil'] = 1;
    });
    await tap(tester, key('canonical-refresh-adventures'));
    await command(tester);
    final id = session.snapshot!.adventures.offers(AdventureKind.mini).first;
    await tap(tester, key('canonical-select-adventure-$id'));
    await shot(tester, 'adventure-picker-nl-large');
    await tap(tester, find.widgetWithText(TextButton, 'Annuleren'));
    await tap(tester, key('canonical-wayfinder-$id'));
    expect(session.snapshot!.shop.relics['wayfinderSigil'], 1);
    await tap(tester, find.widgetWithText(FilledButton, 'Bevestigen'));
    await command(tester);
    expect(session.snapshot!.shop.relics['wayfinderSigil'], 0);
    expect(session.snapshot!.adventures.offers(AdventureKind.mini),
        isNot(contains(id)));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  void prepareHouse(CanonicalUiServer server) {
    server.state['pet']['coins'] = 10000;
    server.state['towerFloorRoomIds'] = ['hearth'];
    server.state['damagedTowerFloors'] = [0];
    // A damaged only floor has no roaming residents in a valid saved game.
    server.state['pet']['roamsTower'] = false;
    server.state['damagedTowerRepairFactors'] = {'0': .60};
    server.state['dragonWardLevel'] = 0;
  }

  testWidgets(
      'dragon highlights remain visible in adventure expertise without changing scores',
      (tester) async {
    await setup(tester, const CanonicalDragonsScreen(), prepare: (server) {
      server.state['pet']['highlightedExpertises'] = [];
    });
    final dragon = session.snapshot!.dragons.first;
    await tap(tester, key('canonical-dragon-${dragon.id}'));
    await tap(tester, key('canonical-highlight-${dragon.id}-might'));
    await command(tester);
    await tap(tester, key('canonical-highlight-${dragon.id}-spirit'));
    await command(tester);
    await shot(tester, 'dragon-highlight-controls');
    expect(
        session.snapshot!.dragon(dragon.id)!.highlighted, {'might', 'spirit'});
    await tap(tester, key('canonical-highlight-${dragon.id}-spirit'));
    await command(tester);
    expect(session.snapshot!.dragon(dragon.id)!.highlighted, {'might'});
    expect(session.snapshot!.dragon(dragon.id)!.training, dragon.training);
    expect(session.snapshot!.dragon(dragon.id)!.xp, dragon.xp);
    await tap(tester, find.widgetWithText(TextButton, 'Close'));
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: session,
        child: const MaterialApp(
            home: Scaffold(body: CanonicalAdventuresScreen()))));
    await tester.pump(const Duration(milliseconds: 400));
    await tap(tester, key('canonical-refresh-adventures'));
    await command(tester);
    final id = session.snapshot!.adventures.offers(AdventureKind.mini).first;
    await tap(tester, key('canonical-select-adventure-$id'));
    await tap(tester, key('canonical-expertise-info-${dragon.id}'));
    final info = find.byWidgetPredicate((w) =>
        w is ExpertiseScoreBadge &&
        w.dragonId == dragon.id &&
        w.focus == TrainingFocus.might &&
        w.iconSize == 30);
    expect(tester.widget<ExpertiseScoreBadge>(info).highlighted, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Dutch large-text house confirms exact prices before spending',
      (tester) async {
    await setup(tester, const CanonicalHouseScreen(),
        language: 'nl', scale: 1.35, prepare: prepareHouse);
    await shot(tester, 'house-nl-large');
    await tap(tester, key('canonical-upgrade-ward'));
    await tap(tester, find.widgetWithText(TextButton, 'Annuleren'));
    expect(session.snapshot!.coins, 10000);
    await tap(tester, key('canonical-upgrade-ward'));
    await tap(tester, find.widgetWithText(FilledButton, 'Bevestigen'));
    await command(tester);
    expect(session.snapshot!.house.wardLevel, 1);
    expect(session.snapshot!.coins, 9850);
    await tap(tester, key('canonical-repair-0'));
    expect(find.textContaining('270 munten?'), findsOneWidget);
    await tap(tester, find.widgetWithText(FilledButton, 'Bevestigen'));
    await command(tester);
    expect(session.snapshot!.house.damagedFloors, isEmpty);
    expect(session.snapshot!.coins, 9580);
    await tap(tester, key('canonical-add-floor'));
    await shot(tester, 'house-floor-picker-nl-large');
    await tap(tester, key('canonical-build-hearth'));
    expect(find.textContaining('2050 munten?'), findsOneWidget);
    await tap(tester, find.widgetWithText(FilledButton, 'Bevestigen'));
    await command(tester);
    expect(session.snapshot!.house.floorRoomIds, ['hearth', 'hearth']);
    expect(session.snapshot!.coins, 7530);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('house purchase confirmation cannot cross an account change',
      (tester) async {
    await setup(tester, const CanonicalHouseScreen(), prepare: prepareHouse);
    await tap(tester, key('canonical-add-floor'));
    await tap(tester, key('canonical-build-hearth'));
    final before = server.sent.length;
    (session.connection as CanonicalUiConnection).signOut();
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm'))
            .onPressed,
        isNull);
    expect(server.sent, hasLength(before));
    expect(server.state['pet']['coins'], 10000);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  void prepareEditor(CanonicalUiServer server) {
    prepareHouse(server);
    server.state['ownedItemIds'] = ['moss_cushion', 'moon_fern'];
    server.state['housePlacements'] = <dynamic>[];
    server.state['equippedItemIds'] = <String, dynamic>{};
    server.state['unlockedRoomIds'] = ['nest', 'hearth', 'crystal'];
    server.state['towerFloorRoomIds'] = ['hearth', 'crystal'];
  }

  testWidgets(
      'Dutch room editor places from public stock, recovers lost reply and keeps stock on removal',
      (tester) async {
    await setup(tester, const CanonicalHouseScreen(),
        language: 'nl', scale: 1.35, prepare: prepareEditor);
    await tap(tester, find.widgetWithText(Tab, 'Kamers'));
    await tap(tester, key('canonical-edit-room-hearth'));
    await tap(tester, key('canonical-select-furniture-moss_cushion'));
    final canvas = key('canonical-room-canvas');
    await tester.ensureVisible(canvas);
    await tester.pump();
    final rect = tester.getRect(canvas);
    server.loseReply = true;
    await tester.runAsync(() => tester.tapAt(
        Offset(rect.left + rect.width * .3, rect.top + rect.height * .8)));
    await command(tester);
    await tester.runAsync(session.synchronize);
    await tester.pump();
    expect(session.snapshot!.house.placements.single.x, closeTo(.3, .001));
    expect(session.snapshot!.house.placements.single.roomId, 'hearth');
    expect(session.snapshot!.shop.ownedItems, contains('moss_cushion'));
    expect(session.snapshot!.coins, 10000);
    // Let the transient lost-reply message expire before reviewing the
    // restored editor. The assertions above still verify actual reconciliation.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, 'house-editor-nl-large');
    await tap(tester, key('canonical-remove-furniture'));
    await command(tester);
    expect(session.snapshot!.house.placements, isEmpty);
    expect(session.snapshot!.shop.ownedItems, contains('moss_cushion'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'floor arrows persist order and an old room editor cannot act after account reentry',
      (tester) async {
    await setup(tester, const CanonicalHouseScreen(), prepare: prepareEditor);
    await tap(tester, key('canonical-floor-up-0'));
    await command(tester);
    expect(session.snapshot!.house.floorRoomIds, ['crystal', 'hearth']);
    expect(session.snapshot!.house.damagedFloors, {1});
    await shot(tester, 'house-reordered');
    await tap(tester, find.widgetWithText(Tab, 'Rooms'));
    await tap(tester, key('canonical-edit-room-hearth'));
    await tap(tester, key('canonical-select-furniture-moss_cushion'));
    final sent = server.sent.length;
    final connection = session.connection as CanonicalUiConnection;
    connection.signOut();
    await tester.pump();
    connection.currentOwner = CanonicalUiServer.owner;
    await tester.runAsync(session.synchronize);
    await tester.pump();
    expect(key('canonical-room-canvas'), findsNothing);
    expect(key('canonical-select-furniture-moss_cushion'), findsNothing);
    expect(server.sent, hasLength(sent));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'dragon detail roaming sends desired state without changing expertise',
      (tester) async {
    await setup(tester, const CanonicalDragonsScreen());
    final dragon = session.snapshot!.dragons.firstWhere((d) => d.owned);
    final before = dragon.training;
    await tap(tester, key('canonical-dragon-${dragon.id}'));
    await tap(tester, key('canonical-roam-dragon'));
    await command(tester);
    expect(session.snapshot!.dragon(dragon.id)!.roamsTower, !dragon.roamsTower);
    expect(session.snapshot!.dragon(dragon.id)!.training, before);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Dutch care confirms one treat and recovers its lost reply',
      (tester) async {
    await setup(tester, const CanonicalDragonsScreen(),
        language: 'nl', scale: 1.35);
    final before = session.snapshot!;
    final id = before.activeDragonId!;
    await tap(tester, key('canonical-dragon-$id'));
    await tap(tester, key('canonical-starlight-treat'));
    await shot(tester, 'care-confirm-nl-large');
    await tap(tester, find.text('Annuleren'));
    await shot(tester, 'care-details-nl-large');
    expect(session.snapshot!.gems, before.gems);
    server.loseReply = true;
    await tap(tester, key('canonical-starlight-treat'));
    await tap(tester, find.text('Bevestigen').last);
    await command(tester);
    await tester.runAsync(() => session.synchronize());
    await tester.pump(const Duration(milliseconds: 400));
    expect(session.snapshot!.gems, before.gems - 3);
    expect(session.snapshot!.dragon(id)!.xp, before.dragon(id)!.xp + 25);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
