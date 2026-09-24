import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dragon_haven/models/game_presentation.dart';
import 'package:dragon_haven/models/profile_portrait.dart';
import 'package:dragon_haven/models/shop_item.dart';
import 'package:dragon_haven/models/supporter_pack.dart';
import 'package:dragon_haven/screens/canonical_house_screen.dart';
import 'package:dragon_haven/screens/canonical_profile_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:dragon_haven/widgets/canonical_milestones.dart';
import 'package:dragon_haven/widgets/haven_lighting.dart';
import 'package:dragon_haven/widgets/house_room_scene.dart';
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
              ..addFont(
                  File(entry.value).readAsBytes().then(ByteData.sublistView)))
            .load();
      }
    }
  });
  late Directory directory;
  late CanonicalUiServer server;
  late CanonicalGameSession session;
  final captureKey = GlobalKey();
  Future<void> setup(WidgetTester tester, Widget child,
      {GamePresentationType? milestone,
      void Function(CanonicalUiServer)? prepare,
      String Function()? requestIdGenerator,
      bool disableAnimations = true}) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('dh-care-widget-');
      server = CanonicalUiServer(
          jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>);
      server.state['ownedPortraitIds'] = [
        profilePortraitCatalog[0].id,
        profilePortraitCatalog[1].id
      ];
      server.state['selectedPortraitId'] = profilePortraitCatalog[0].id;
      server.state['ownedBadgeIds'] = [heartboundPairBadge.id];
      server.state['selectedBadgeId'] = heartboundPairBadge.id;
      server.state['towerFloorRoomIds'] = ['hearth', 'garden'];
      server.state['unlockedRoomIds'] = ['nest', 'hearth', 'garden'];
      server.state['damagedTowerFloors'] = <int>[];
      server.state['damagedTowerRepairFactors'] = <String, dynamic>{};
      if (milestone == GamePresentationType.evolution) {
        server.state['pet']['stage'] = 'wyrmling';
      }
      server.state['pet']['currentFloorIndex'] = 0;
      server.state['pet']['currentRoomId'] = 'hearth';
      server.state['pet']['roamsTower'] = true;
      server.state['pet']['favorite'] = true;
      server.state['pendingPresentations'] = milestone == null
          ? []
          : [
              GamePresentation(
                      id: 'shown-event',
                      type: milestone,
                      createdAt: server.now,
                      sortAt: server.now,
                      dragonId: server.state['pet']['id'] as String,
                      previousStageKey:
                          milestone == GamePresentationType.evolution
                              ? 'spark'
                              : null)
                  .toJson()
            ];
      prepare?.call(server);
      session = CanonicalGameSession(
          connection: CanonicalUiConnection(server),
          directory: directory,
          requestIdGenerator: requestIdGenerator);
      await session.synchronize();
    });
    addTearDown(() async {
      session.dispose();
      await directory.delete(recursive: true);
    });
    final base = buildAppTheme();
    final theme = const String.fromEnvironment('ECONOMY_UI_FONT').isEmpty
        ? base
        : base.copyWith(
            textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
            filledButtonTheme: FilledButtonThemeData(
                style: base.filledButtonTheme.style?.copyWith(
                    textStyle: const WidgetStatePropertyAll(TextStyle(
                        fontFamily: 'Roboto', fontWeight: FontWeight.w700)))));
    await tester.runAsync(() => tester.pumpWidget(ChangeNotifierProvider.value(
        value: session,
        child: MaterialApp(
            locale: const Locale('nl'),
            supportedLocales: const [Locale('nl'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            debugShowCheckedModeBanner: false,
            theme: theme,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.35),
                    disableAnimations: disableAnimations),
                child: RepaintBoundary(key: captureKey, child: child!)),
            home: Scaffold(body: child)))));
    await tester.pump();
  }

  Future<void> settled(WidgetTester tester) async {
    for (var i = 0; i < 300 && session.busy; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(session.canAct, isTrue, reason: session.errorCode);
    await tester.pump();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    const dir = String.fromEnvironment('ECONOMY_UI_CAPTURE');
    if (dir.isEmpty) return;
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.runAsync(() async {
      final boundary = captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(dir).create(recursive: true);
      await File('$dir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
      'compact profile selects owned art and clears it immediately on account exit',
      (tester) async {
    await setup(tester, const CanonicalProfileScreen());
    final second = profilePortraitCatalog[1].id;
    final button = find.byKey(Key('canonical-profile-portrait-$second'));
    await tester.ensureVisible(button);
    await tester.runAsync(() => tester.tap(button));
    await settled(tester);
    expect(session.snapshot!.profile.selected('portrait'), second);
    await capture(tester, 'profile-320-dutch');
    expect(tester.takeException(), isNull);
    (session.connection as CanonicalUiConnection).signOut();
    await tester.pump();
    expect(button, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'restored room scene guides and calls the favorite through the server',
      (tester) async {
    await setup(tester, const CanonicalHouseScreen(), disableAnimations: false);
    final visit = find.byKey(const Key('canonical-visit-floor-1'));
    await tester.scrollUntilVisible(visit, 200,
        scrollable: find
            .descendant(
                of: find.byKey(const Key('canonical-tower-list')),
                matching: find.byType(Scrollable))
            .first);
    await tester.runAsync(() => tester.tap(visit));
    await tester.pump();
    await settled(tester);
    expect(
        find.byKey(const Key('canonical-floor-room-screen-1')), findsOneWidget);
    final scene = find.byKey(const Key('house-room-scene'));
    expect(scene, findsOneWidget);
    expect(find.byType(HavenPhaseImage), findsOneWidget);
    expect(find.byType(RoomActionButton), findsNWidgets(3));
    expect(find.text('Drakenreservaat'), findsOneWidget);
    expect(find.byKey(const Key('canonical-change-floor-1')), findsOneWidget);
    final background = tester.widget<AnimatedSwitcher>(
        find.byKey(const Key('room-background-transition')));
    expect(background.duration, const Duration(milliseconds: 780));
    expect(background.reverseDuration, const Duration(milliseconds: 520));
    final atmosphere = tester.widget<AnimatedSwitcher>(
        find.byKey(const Key('room-atmosphere-transition')));
    expect(atmosphere.duration, const Duration(milliseconds: 620));
    expect(atmosphere.reverseDuration, const Duration(milliseconds: 440));
    final hold = Completer<void>();
    addTearDown(() {
      if (!hold.isCompleted) hold.complete();
    });
    server.hold = hold.future;
    await tester.runAsync(() => tester.tap(scene));
    await tester.pump();
    expect(find.byKey(const Key('room-tap-effect')), findsOneWidget);
    final id = server.state['pet']['id'] as String;
    expect(session.snapshot!.dragon(id)!.floorIndex, 1);
    expect(find.byKey(Key('room-dragon-$id')), findsOneWidget);
    expect(find.byKey(Key('room-dragon-shadow-$id')), findsOneWidget);
    final arrival = tester
        .widget<AnimatedOpacity>(find.byKey(Key('room-dragon-arrival-$id')));
    expect(arrival.duration, const Duration(milliseconds: 520));
    final arrivalScale = tester.widget<AnimatedScale>(find.descendant(
        of: find.byKey(Key('room-dragon-arrival-$id')),
        matching: find.byType(AnimatedScale)));
    expect(arrivalScale.duration, const Duration(milliseconds: 650));
    final appeared =
        tester.widget<AnimatedPositioned>(find.byKey(Key('room-dragon-$id')));
    expect(appeared.duration, Duration.zero);
    final appearedLeft = appeared.left!;
    final appearedTop = appeared.top!;
    await tester.pump();
    final walking =
        tester.widget<AnimatedPositioned>(find.byKey(Key('room-dragon-$id')));
    expect(walking.duration, const Duration(milliseconds: 5200));
    expect(walking.left, isNot(appearedLeft));
    expect(walking.top, isNot(appearedTop));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byKey(const Key('room-tap-effect')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.byKey(const Key('room-tap-effect')), findsNothing);
    hold.complete();
    await settled(tester);
    expect(session.snapshot!.dragon(id)!.floorIndex, 1);
    expect(server.sent.where((i) => i.action == 'visit_tower_floor'),
        hasLength(1));
    expect(server.sent.where((i) => i.action == 'call_dragon_to_floor'),
        hasLength(1));
    await capture(tester, 'room-resident-320-dutch');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('room effects honor reduced motion and leave no active ticker',
      (tester) async {
    await setup(tester, const CanonicalHouseScreen(), prepare: (server) {
      final placements = List<Map<String, dynamic>>.from(
          (server.state['housePlacements'] as List)
              .map((item) => Map<String, dynamic>.from(item as Map)))
        ..removeWhere((item) => item['itemId'] == 'firefly_lamp')
        ..add(
          {
            'itemId': 'firefly_lamp',
            'roomId': 'garden',
            'x': .72,
            'y': .62,
            'scale': 1.0,
          },
        );
      server.state['housePlacements'] = placements;
      server.state['ownedItemIds'] = {
        ...(server.state['ownedItemIds'] as List).cast<String>(),
        'firefly_lamp',
      }.toList();
      server.state['equippedItemIds'] = {
        for (final placement in placements)
          if (shopItemById(placement['itemId'] as String) case final item?)
            item.slot.name: item.id,
      };
    });
    final visit = find.byKey(const Key('canonical-visit-floor-1'));
    await tester.scrollUntilVisible(visit, 200,
        scrollable: find
            .descendant(
                of: find.byKey(const Key('canonical-tower-list')),
                matching: find.byType(Scrollable))
            .first);
    await tester.runAsync(() => tester.tap(visit));
    await tester.pump();
    await settled(tester);

    final background = tester.widget<AnimatedSwitcher>(
        find.byKey(const Key('room-background-transition')));
    expect(background.duration, Duration.zero);
    expect(background.reverseDuration, Duration.zero);
    final atmosphere = tester.widget<AnimatedSwitcher>(
        find.byKey(const Key('room-atmosphere-transition')));
    expect(atmosphere.duration, Duration.zero);
    expect(atmosphere.reverseDuration, Duration.zero);
    expect(
        find.byKey(const Key('placed-furniture-firefly_lamp')), findsOneWidget);

    final scene = find.byKey(const Key('house-room-scene'));
    await tester.runAsync(() => tester.tap(scene));
    await tester.pump();
    await settled(tester);

    final id = server.state['pet']['id'] as String;
    final dragon =
        tester.widget<AnimatedPositioned>(find.byKey(Key('room-dragon-$id')));
    expect(dragon.duration, Duration.zero);
    expect(find.byKey(Key('room-dragon-shadow-$id')), findsOneWidget);
    final arrival = tester
        .widget<AnimatedOpacity>(find.byKey(Key('room-dragon-arrival-$id')));
    expect(arrival.duration, Duration.zero);
    final arrivalScale = tester.widget<AnimatedScale>(find.descendant(
        of: find.byKey(Key('room-dragon-arrival-$id')),
        matching: find.byType(AnimatedScale)));
    expect(arrivalScale.duration, Duration.zero);
    expect(find.byKey(const Key('room-tap-effect')), findsNothing);

    await tester.pumpAndSettle(const Duration(milliseconds: 20),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('active returning visitors appear in their former tower room',
      (tester) async {
    const visitorId = 'returning-visitor';
    await setup(tester, const CanonicalHouseScreen(), prepare: (server) {
      final visitor =
          jsonDecode(jsonEncode(server.state['pet'])) as Map<String, dynamic>;
      visitor
        ..['id'] = visitorId
        ..['favorite'] = false
        ..['currentFloorIndex'] = 1
        ..['currentRoomId'] = 'garden'
        ..['activeAdventureId'] = null;
      server.state['releasedDragons'] = [visitor];
      server.state['returningVisitors'] = {
        visitorId: server.now.add(const Duration(hours: 1)).toIso8601String(),
      };
    });
    final visit = find.byKey(const Key('canonical-visit-floor-1'));
    await tester.scrollUntilVisible(visit, 200,
        scrollable: find
            .descendant(
                of: find.byKey(const Key('canonical-tower-list')),
                matching: find.byType(Scrollable))
            .first);
    await tester.runAsync(() => tester.tap(visit));
    await tester.pump();
    await settled(tester);

    expect(find.byKey(const Key('room-dragon-$visitorId')), findsOneWidget);
    final scene = tester.widget<HouseRoomScene>(find.byType(HouseRoomScene));
    expect(scene.visitorIds, contains(visitorId));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('changing room type clears the previous rare room moment',
      (tester) async {
    final ids = <String>[
      '00000000-0000-4000-8000-000000000007',
      '00000000-0000-4000-8000-000000000008',
    ];
    await setup(tester, const CanonicalHouseScreen(),
        requestIdGenerator: () => ids.removeAt(0),
        prepare: (server) {
          server.state['pet']
            ..['lineageId'] = 'bramblequill'
            ..['currentFloorIndex'] = 0
            ..['currentRoomId'] = 'garden'
            ..['activeAdventureId'] = null;
          server.state['towerFloorRoomIds'][0] = 'garden';
          server.state['rareInteractionAt'] = <String, dynamic>{};
        });
    final visit = find.byKey(const Key('canonical-visit-floor-0'));
    await tester.scrollUntilVisible(visit, 200,
        scrollable: find
            .descendant(
                of: find.byKey(const Key('canonical-tower-list')),
                matching: find.byType(Scrollable))
            .first);
    await tester.runAsync(() => tester.tap(visit));
    await tester.pump();
    await settled(tester);
    expect(find.text('Een zeldzaam torenmoment'), findsOneWidget);
    expect(
        tester
            .widget<HouseRoomScene>(find.byType(HouseRoomScene))
            .suppressTimeMood,
        isTrue);

    final change = find.byKey(const Key('canonical-change-floor-0'));
    await tester.scrollUntilVisible(change, 180,
        scrollable: find
            .descendant(
                of: find
                    .byKey(const PageStorageKey('canonical-floor-room-scroll')),
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(change);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('canonical-convert-hearth')));
    await tester.pump();
    await settled(tester);
    await tester.pump();
    final scene = tester.widget<HouseRoomScene>(find.byType(HouseRoomScene));
    expect(scene.room.id, 'hearth');
    expect(scene.suppressTimeMood, isFalse);
    expect(find.text('Een zeldzaam torenmoment'), findsNothing);
    expect(server.sent.where((i) => i.action == 'visit_tower_floor'),
        hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final kind in [
    GamePresentationType.hatch,
    GamePresentationType.evolution
  ]) {
    testWidgets(
        '${kind.name} uses the existing animation and acknowledges only its presentation',
        (tester) async {
      await setup(
          tester,
          Builder(
              builder: (context) => TextButton(
                  onPressed: () => showCanonicalMilestone(
                      context, session.snapshot!.presentations.single),
                  child: const Text('Reveal'))),
          milestone: kind);
      final before = session.snapshot!;
      await tester.tap(find.text('Reveal'));
      await tester.pump();
      for (var i = 0; i < 22; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      await capture(tester, '${kind.name}-320-dutch');
      expect(tester.takeException(), isNull);
      final close = kind == GamePresentationType.hatch
          ? find.text('Doorgaan')
          : find.byKey(const Key('close-evolution-presentation'));
      await tester.runAsync(() => tester.tap(close));
      await tester.runAsync(() => tester.pump());
      await settled(tester);
      expect(session.snapshot!.presentations, isEmpty);
      expect(session.snapshot!.coins, before.coins);
      expect(session.snapshot!.dragons.map((d) => d.xp).toList(),
          before.dragons.map((d) => d.xp).toList());
      expect(server.sent.where((i) => i.action == 'complete_presentation'),
          hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
