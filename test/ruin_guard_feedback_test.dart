import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/standard_trial_game_widgets.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_trial_run_source.dart';
import 'package:dragon_haven/services/trial_gameplay_controller.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:dragon_haven/widgets/ruin_guard_impact.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/canonical_ui_server.dart';

class _ManualController extends TrialGameplayController {
  _ManualController(super.source, {super.elapsedMilliseconds});
  @override
  void tick() {}
  void advanceFrame() => super.tick();
}

class _GuardHarness {
  late _ManualController controller;
  late CanonicalTrialRunSource source;
  late CanonicalGameSession session;
  late CanonicalUiServer server;
  late Directory directory;
  int elapsed = 0;
  final captureKey = GlobalKey();

  void advanceTo(int at) {
    while (elapsed < at) {
      final step = min(1000, at - elapsed);
      elapsed += step;
      server.now = server.now.add(Duration(milliseconds: step));
      controller.advanceFrame();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    const font = String.fromEnvironment('ECONOMY_UI_FONT');
    if (font.isNotEmpty) {
      for (final entry in {
        'Roboto': font,
        'MaterialIcons': '${File(font).parent.path}/materialicons-regular.otf',
      }.entries) {
        await (FontLoader(entry.key)
              ..addFont(
                  File(entry.value).readAsBytes().then(ByteData.sublistView)))
            .load();
      }
    }
  });

  Future<_GuardHarness> setup(WidgetTester tester,
      {bool reducedMotion = false, Size size = const Size(390, 800)}) async {
    final harness = _GuardHarness();
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      final now = DateTime.utc(2026, 9, 7, 12);
      final household =
          HouseholdProvider(persistenceEnabled: false, clock: () => now);
      household.pet
        ..stage = DragonStage.ascended
        ..evolutionPath = 'might'
        ..firstEgg = false
        ..favorite = true;
      final offer = TrialOffer(
          id: 'guard-feedback', kind: TrialKind.ruinGuard, appearedAt: now);
      harness.server = CanonicalUiServer(household.exportState())..now = now;
      harness.server.state['trialOffers'] = [offer.toJson()];
      harness.server.state['trialRefilledAt'] = now.toIso8601String();
      household.dispose();
      harness.directory = await Directory.systemTemp.createTemp('dh-guard-');
      harness.session = CanonicalGameSession(
          connection: CanonicalUiConnection(harness.server),
          directory: harness.directory);
      await harness.session.synchronize();
      harness.source = CanonicalTrialRunSource(
          harness.session, offer, harness.session.snapshot!.activeDragonId!);
      harness.controller = _ManualController(harness.source,
          elapsedMilliseconds: () => harness.elapsed);
      await harness.controller.prepare();
    });
    expect(harness.controller.ready, isTrue, reason: harness.controller.error);
    addTearDown(() async {
      harness.controller.dispose();
      harness.session.dispose();
      await harness.directory.delete(recursive: true);
    });
    final theme = buildAppTheme();
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: const String.fromEnvironment('ECONOMY_UI_FONT').isEmpty
          ? theme
          : theme.copyWith(
              textTheme: theme.textTheme.apply(fontFamily: 'Roboto')),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: RepaintBoundary(key: harness.captureKey, child: child!),
      ),
      home: RuinGuardTrialGame(
        offer: harness.source.offer,
        dragon: harness.source.dragon!,
        controller: harness.controller,
        onFinished: (_) async =>
            fail('Canonical completion uses its controller'),
      ),
    ));
    await tester.tap(find.byKey(const Key('ruin-guard-game')));
    await tester.pump();
    return harness;
  }

  Future<void> capture(
      WidgetTester tester, _GuardHarness harness, String name) async {
    const output = String.fromEnvironment('TRIAL_FEEDBACK_SCREENSHOTS');
    if (output.isEmpty) return;
    // Let asset manifests and image decodes complete without advancing the
    // manually driven canonical clock used for the captured collision frame.
    for (var frame = 0; frame < 3; frame++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
      await tester.pump();
    }
    await tester.runAsync(() async {
      final boundary = harness.captureKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = await Directory(output).create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> guardLane(WidgetTester tester, _GuardHarness harness) async {
    final game = harness.controller.model.guard!;
    while (game.playerLane != game.targetLane) {
      await tester.tap(find.byKey(const Key('ruin-guard-game')));
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
  }

  testWidgets(
      'successful guard lunges and shatters the stone at canonical impact',
      (tester) async {
    final harness = await setup(tester);
    final game = harness.controller.model.guard!;
    final stone = find.byKey(const Key('ruin-guard-boulder'));
    final lunge = find.byKey(const Key('ruin-guard-lunge'));
    await guardLane(tester, harness);
    harness.advanceTo((game.fallDurationMs * .95).floor());
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byType(RuinGuardBoulder), findsOneWidget);
    expect(stone, findsOneWidget);
    expect(tester.widget<Transform>(lunge).transform.getTranslation().y,
        lessThan(-10));
    expect(game.score, 0);
    expect(find.byType(RuinGuardImpact), findsNothing);
    await capture(tester, harness, 'ruin-guard-contact');

    harness.advanceTo(game.fallDurationMs);
    await tester.pump(const Duration(milliseconds: 16));
    expect(game.score, 112);
    expect(game.misses, 0);
    expect(stone, findsNothing);
    expect(find.byType(RuinGuardImpact), findsOneWidget);
    expect(find.byType(RuinGuardBoulder), findsNWidgets(7));
    final first = tester
        .widget<Transform>(find.byKey(const Key('ruin-guard-fragment-0')))
        .transform;
    harness.advanceTo(harness.elapsed + 100);
    await tester.pump(const Duration(milliseconds: 100));
    final separated = tester
        .widget<Transform>(find.byKey(const Key('ruin-guard-fragment-0')))
        .transform;
    expect(separated, isNot(first));
    expect(separated.getTranslation().x, lessThan(-20));
    await capture(tester, harness, 'ruin-guard-shatter');
    harness.advanceTo(game.lockedUntil!);
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byType(RuinGuardImpact), findsNothing);
    expect(stone, findsOneWidget);
    expect(game.score, 112);
    await tester.runAsync(() => harness.controller.flush());
    expect(harness.controller.error, isNull);
    expect(harness.server.sent.where((i) => i.action == 'checkpoint_trial'),
        isNotEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('miss leaves the stone intact and never shows successful debris',
      (tester) async {
    final harness = await setup(tester);
    final game = harness.controller.model.guard!;
    if (game.playerLane == game.targetLane) {
      await tester.tap(find.byKey(const Key('ruin-guard-game')));
    }
    harness.advanceTo(game.fallDurationMs + 100);
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.misses, 1);
    expect(game.score, 0);
    expect(find.text('MISSED!'), findsOneWidget);
    expect(find.byType(RuinGuardImpact), findsNothing);
    expect(find.byType(RuinGuardBoulder), findsOneWidget);
    expect(
        tester
            .widget<Transform>(find.byKey(const Key('ruin-guard-lunge')))
            .transform
            .getTranslation()
            .y,
        0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('extra display frames do not advance or score the server game',
      (tester) async {
    final harness = await setup(tester);
    harness.advanceTo(500);
    await tester.pump(const Duration(milliseconds: 500));
    final checkpoint = harness.controller.model.checkpoint();
    final stone = find.byKey(const Key('ruin-guard-boulder'));
    final before = tester.getTopLeft(stone);
    harness.elapsed += 16;
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.getTopLeft(stone).dy, greaterThan(before.dy));
    expect(harness.controller.model.checkpoint(), checkpoint);
    harness.controller.pause();
    await tester.pump();
    final paused = tester.getTopLeft(stone);
    harness.elapsed += 100;
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(stone), paused);
    expect(harness.controller.model.checkpoint(), checkpoint);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'reduced motion preserves static shatter feedback on small screens',
      (tester) async {
    final harness =
        await setup(tester, reducedMotion: true, size: const Size(320, 640));
    final game = harness.controller.model.guard!;
    await guardLane(tester, harness);
    harness.advanceTo(game.fallDurationMs);
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    final fragment = find.byKey(const Key('ruin-guard-fragment-0'));
    final before = tester.widget<Transform>(fragment).transform;
    harness.advanceTo(harness.elapsed + 180);
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.widget<Transform>(fragment).transform, before);
    expect(
        tester
            .widget<Transform>(find.byKey(const Key('ruin-guard-lunge')))
            .transform
            .getTranslation()
            .y,
        0);
    expect(game.score, 112);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
