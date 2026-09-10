import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dragon_haven/models/dragon_school.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/screens/dragon_school_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_school_run_source.dart';
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
  setUpAll(() async {
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
  for (final id in ['runeRush', 'cloudWeave', 'breathBalance']) {
    testWidgets('$id retains its art on a compact Dutch canonical screen',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late Directory directory;
      late CanonicalGameSession session;
      late CanonicalUiServer server;
      await tester.runAsync(() async {
        final fixture = (await runGameDomainProbe())['state'];
        server = CanonicalUiServer(
            jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>);
        server.state['towerFloorRoomIds'] = List.filled(5, 'hearth');
        (server.state['sanctuaryDragons'] as List).add(Pet(
                id: 'second-pupil',
                name: 'Mica',
                stage: DragonStage.hatchling,
                lineageId: 'copperflame',
                acquiredAt: server.now,
                stageStartedAt: server.now,
                needsUpdatedAt: server.now)
            .toJson());
        directory = await Directory.systemTemp.createTemp('dh-school-visual-');
        session = CanonicalGameSession(
            connection: CanonicalUiConnection(server), directory: directory);
        await session.synchronize();
      });
      final definition = dragonSchoolGameById(id)!;
      final source = CanonicalSchoolRunSource(
          session,
          definition,
          [
            session.snapshot!.activeDragonId!,
            if (definition.minimumDragons > 1) 'second-pupil'
          ],
          null);
      addTearDown(() async {
        source.dispose();
        session.dispose();
        await directory.delete(recursive: true);
      });
      final captureKey = GlobalKey();
      var elapsed = 0;
      final theme = buildAppTheme();
      await tester.pumpWidget(ChangeNotifierProvider.value(
          value: session,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('nl'),
            supportedLocales: const [Locale('nl'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: const String.fromEnvironment('ECONOMY_UI_FONT').isEmpty
                ? theme
                : theme.copyWith(
                    textTheme: theme.textTheme.apply(fontFamily: 'Roboto')),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.35),
                    disableAnimations: true),
                child: RepaintBoundary(key: captureKey, child: child!)),
            home: DragonSchoolGameScreen(
                definition: definition,
                dragonIds: source.dragonIds,
                source: source,
                elapsedMilliseconds: () => elapsed),
          )));
      Future<void> capture(String label) async {
        const dir = String.fromEnvironment('ECONOMY_UI_CAPTURE');
        if (dir.isEmpty) return;
        await tester.pump();
        await tester.runAsync(() async {
          final boundary = captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(dir).create(recursive: true);
          await File('$dir/$id-$label.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tester.pump(const Duration(milliseconds: 100));
      await capture('intro');
      await tester.ensureVisible(find.byKey(const Key('start-school-game')));
      await tester.runAsync(
          () => tester.tap(find.byKey(const Key('start-school-game'))));
      for (var i = 0;
          i < 150 && (session.busy || session.snapshot!.schoolAttempt == null);
          i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump();
      }
      elapsed = 1250;
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
      await tester.pump();
      await capture('playing');
      expect(session.snapshot!.schoolAttempt?.gameId, id);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(source.cancel);
    });
  }
}
