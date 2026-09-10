import 'dart:io';
import 'dart:ui' as ui;

import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/redeem_code.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/trial_game_screen.dart';
import 'package:dragon_haven/screens/seasonal_trial_game.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_trial_run_source.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:dragon_haven/widgets/witchlight_trial_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/canonical_ui_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    const font = String.fromEnvironment('ECONOMY_UI_FONT');
    if (font.isNotEmpty) {
      for (final e in {
        'Roboto': font,
        'MaterialIcons': '${File(font).parent.path}/materialicons-regular.otf'
      }.entries) {
        await (FontLoader(e.key)
              ..addFont(File(e.value).readAsBytes().then(ByteData.sublistView)))
            .load();
      }
    }
  });
  for (final kind
      in TrialKind.values.where((k) => trialDefinitions[k]!.isSeasonal)) {
    testWidgets(
        '${kind.name} shares its sprites and recorded controls with the server model',
        (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.utc(2026, 9, 10, 12);
      late CanonicalGameSession session;
      late CanonicalUiServer server;
      late Directory directory;
      await tester.runAsync(() async {
        final game =
            HouseholdProvider(clock: () => now, persistenceEnabled: false);
        game.pet
          ..stage = DragonStage.hatchling
          ..firstEgg = false
          ..favorite = true
          ..name = 'Moss';
        game.pet.training.addAll({'might': 300, 'arcana': 300, 'spirit': 300});
        final event = trialDefinitions[kind]!.specialEventId;
        final code = redeemCodeCatalog.singleWhere((c) =>
            c.rewardType == RedeemRewardType.seasonalEventPreview &&
            c.rewardId == event);
        await game.redeemCode(code.code, keeperId: CanonicalUiServer.owner);
        game.availableTrials;
        server = CanonicalUiServer(game.exportState())..now = now;
        game.dispose();
        directory = await Directory.systemTemp.createTemp('dh-trial-visual-');
        session = CanonicalGameSession(
            connection: CanonicalUiConnection(server), directory: directory);
        await session.synchronize();
      });
      final offer =
          session.snapshot!.trialOffers.firstWhere((o) => o.kind == kind);
      final source = CanonicalTrialRunSource(
          session, offer, session.snapshot!.activeDragonId!);
      addTearDown(() async {
        session.dispose();
        await directory.delete(recursive: true);
      });
      var elapsed = 0;
      final captureKey = GlobalKey();
      final theme = buildAppTheme();
      await tester.runAsync(() => tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('nl'),
          supportedLocales: const [Locale('nl'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: const String.fromEnvironment('ECONOMY_UI_FONT').isEmpty
              ? theme
              : theme.copyWith(
                  textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
                  filledButtonTheme: FilledButtonThemeData(
                      style: theme.filledButtonTheme.style?.copyWith(
                          textStyle: const WidgetStatePropertyAll(TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w800))))),
          builder: (context, child) =>
              RepaintBoundary(key: captureKey, child: child!),
          home: TrialGameScreen(
              offerId: offer.id,
              dragonId: source.dragonId,
              source: source,
              elapsedMilliseconds: () => elapsed))));
      for (var i = 0;
          i < 300 &&
              find.byKey(const Key('start-seasonal-trial')).evaluate().isEmpty;
          i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      expect(find.byKey(const Key('start-seasonal-trial')), findsOneWidget,
          reason:
              '${session.errorCode} / ${session.snapshot?.trialAttempt?.kind} / ${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList()}');
      await tester.tap(find.byKey(const Key('start-seasonal-trial')));
      final controller = tester
          .widget<SeasonalTrialGame>(find.byType(SeasonalTrialGame))
          .controller!;
      Future<void> advance(int ms) async {
        elapsed += ms;
        server.now = now.add(Duration(milliseconds: elapsed + 2000));
        await tester.runAsync(() async {
          controller.tick();
        });
        await tester.pump(Duration(milliseconds: ms));
      }

      await advance(1000);
      TestGesture? heldFinger;
      if (kind == TrialKind.witchlightWard) {
        await advance(1000);
        await advance(1000);
        await tester.tap(find
            .byKey(Key('witchlight-rune-${controller.model.pumpkinPosition}')));
        await advance(700);
        expect(controller.model.phase, 1);
        final surface = find.byKey(const Key('witchlight-trace-surface'));
        final widget = tester
            .widget<WitchlightTracePath>(find.byType(WitchlightTracePath));
        final points = WitchlightTracePath.points(tester.getSize(surface),
            seed: widget.seed);
        final origin = tester.getTopLeft(surface);
        final finger = await tester.startGesture(origin + points.first);
        for (final point in points.skip(1).take(2)) {
          await finger.moveTo(origin + point);
        }
        await tester.pump(const Duration(milliseconds: 80));
        expect(controller.model.trace!.active, true);
        expect(controller.model.mistakes, 0);
        heldFinger = finger;
      }
      for (var i = 0; i < 15; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 80)));
        await tester.pump(const Duration(milliseconds: 16));
      }
      const output = String.fromEnvironment('ECONOMY_UI_CAPTURE');
      if (output.isNotEmpty) {
        await tester.pump();
        await tester.runAsync(() async {
          final boundary = captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File('$output/${kind.name}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      if (heldFinger != null) {
        await heldFinger.up();
        expect(controller.model.mistakes, 1);
      }
      expect(tester.takeException(), isNull);
      // Save the real UI transcript and compare the server's replay checkpoint.
      await tester.runAsync(controller.flush);
      expect(controller.error, isNull);
      expect(server.state['_activeGameAttempt']['checkpoint']['score'],
          controller.model.score);
      expect(server.state['_activeGameAttempt']['checkpoint']['mistakes'],
          controller.model.mistakes);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(source.cancel);
    });
  }
}
