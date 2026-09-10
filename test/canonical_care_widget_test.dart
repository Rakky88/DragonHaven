import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dragon_haven/models/game_presentation.dart';
import 'package:dragon_haven/models/profile_portrait.dart';
import 'package:dragon_haven/models/supporter_pack.dart';
import 'package:dragon_haven/screens/canonical_house_screen.dart';
import 'package:dragon_haven/screens/canonical_profile_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:dragon_haven/widgets/canonical_milestones.dart';
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
      {GamePresentationType? milestone}) async {
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
      session = CanonicalGameSession(
          connection: CanonicalUiConnection(server), directory: directory);
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
                    disableAnimations: true),
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
      'room dialog calls the favorite and shows its new server position',
      (tester) async {
    await setup(tester, const CanonicalHouseScreen());
    final visit = find.byKey(const Key('canonical-visit-floor-1'));
    await tester.ensureVisible(visit);
    await tester.runAsync(() => tester.tap(visit));
    await tester.pump();
    await settled(tester);
    final call = find.byKey(const Key('canonical-call-dragon'));
    await tester.runAsync(() => tester.tap(call));
    await settled(tester);
    expect(
        session.snapshot!
            .dragon(server.state['pet']['id'] as String)!
            .floorIndex,
        1);
    expect(server.sent.where((i) => i.action == 'visit_tower_floor'),
        hasLength(1));
    await capture(tester, 'room-resident-320-dutch');
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
