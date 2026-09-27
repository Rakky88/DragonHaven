import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/trial_input.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/standard_trial_game_widgets.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_trial_run_source.dart';
import 'package:dragon_haven/services/trial_gameplay_controller.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/canonical_ui_server.dart';

// Keep the real canonical controller, model, transcript and server validation,
// but explicitly drive simulation updates independently of Flutter frames.
class _ManualController extends TrialGameplayController {
  _ManualController(super.source, {super.elapsedMilliseconds});
  Future<void>? pendingCheckpoint;
  @override
  void tick() {}
  void advanceFrame() => super.tick();

  @override
  Future<void> flush() => pendingCheckpoint = super.flush();
}

class _OrbitHarness {
  late _ManualController controller;
  late CanonicalTrialRunSource source;
  late CanonicalGameSession session;
  late CanonicalUiServer server;
  late Directory directory;
  int elapsed = 0;
  final captureKey = GlobalKey();

  Future<void> advanceTo(WidgetTester tester, int at) async {
    // A tick can start a durable background checkpoint. Start it in the real
    // async zone and await that exact write before advancing the server clock.
    await tester.runAsync(() async {
      while (elapsed < at) {
        final step = min(1000, at - elapsed);
        elapsed += step;
        server.now = server.now.add(Duration(milliseconds: step));
        controller.advanceFrame();
        await controller.pendingCheckpoint;
      }
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sounds = <String>[];
  setUp(() {
    sounds.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('nl.dragonhaven.app/audio'), (call) async {
      if (call.method == 'playSound') {
        sounds.add(call.arguments['id'] as String);
      }
      return null;
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('nl.dragonhaven.app/audio'), null);
  });
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

  Future<_OrbitHarness> setup(WidgetTester tester,
      {bool reducedMotion = false,
      Size size = const Size(390, 800),
      double textScale = 1}) async {
    final harness = _OrbitHarness();
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      final now = DateTime.utc(2026, 9, 7, 12);
      final household =
          HouseholdProvider(persistenceEnabled: false, clock: () => now);
      household.pet
        ..stage = DragonStage.ascended
        ..evolutionPath = 'arcana'
        ..firstEgg = false
        ..favorite = true;
      final offer = TrialOffer(
          id: 'orbit-feedback', kind: TrialKind.runeOrbit, appearedAt: now);
      harness.server = CanonicalUiServer(household.exportState())..now = now;
      harness.server.state['trialOffers'] = [offer.toJson()];
      harness.server.state['trialRefilledAt'] = now.toIso8601String();
      household.dispose();
      harness.directory = await Directory.systemTemp.createTemp('dh-orbit-');
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
        data: MediaQuery.of(context).copyWith(
            disableAnimations: reducedMotion,
            textScaler: TextScaler.linear(textScale)),
        child: RepaintBoundary(key: harness.captureKey, child: child!),
      ),
      home: RuneOrbitTrialGame(
        offer: harness.source.offer,
        dragon: harness.source.dragon!,
        controller: harness.controller,
        onFinished: (_) async =>
            fail('Canonical completion uses its controller'),
      ),
    ));
    await tester.tap(find.byKey(const Key('rune-orbit-game')));
    await tester.pump();
    await harness.advanceTo(tester, 500);
    await tester.pump(const Duration(milliseconds: 500));
    return harness;
  }

  Future<void> capture(
      WidgetTester tester, _OrbitHarness harness, String name) async {
    const output = String.fromEnvironment('TRIAL_FEEDBACK_SCREENSHOTS');
    if (output.isEmpty) return;
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

  testWidgets(
      'orbit draws between canonical updates without changing its model',
      (tester) async {
    final harness = await setup(tester);
    final controller = harness.controller;
    final before = controller.model.checkpoint();
    final rune = find.byKey(const Key('rune-orbit-rune-0'));
    final first = tester.getCenter(rune);
    harness.elapsed += 8;
    await tester.pump(const Duration(milliseconds: 8));
    final second = tester.getCenter(rune);
    harness.elapsed += 8;
    await tester.pump(const Duration(milliseconds: 8));
    final third = tester.getCenter(rune);
    expect((second - first).distance, greaterThan(.5));
    expect((third - second).distance, greaterThan(.5));
    expect((third - second).distance, lessThan(5));
    expect(controller.model.checkpoint(), before);
    for (var rune = 0; rune < 5; rune++) {
      expect(find.byKey(Key('rune-orbit-rune-$rune')), findsOneWidget);
    }
    harness.elapsed += 100;
    expect(controller.presentationElapsedMs, controller.model.elapsedMs + 32);
    expect(controller.model.checkpoint(), before);
    controller.pause();
    await tester.pump();
    final paused = tester.getCenter(rune);
    harness.elapsed += 100;
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getCenter(rune), paused);
    expect(controller.presentationElapsedMs, controller.model.elapsedMs);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('miss and match show distinct feedback and record canonical taps',
      (tester) async {
    final harness = await setup(tester);
    final game = harness.controller.model.orbit!;
    final board = find.byKey(const Key('rune-orbit-game'));
    final wrong = (game.targetRune + 1) % 5;
    // Cross the background-save threshold on every run, independent of the
    // server-generated target, before selecting the same wrong rune two laps on.
    await harness.advanceTo(tester,
        (game.roundStartedAt + (wrong + 10) * game.visibleMs + 100).ceil());
    expect(
        harness.server.sent
            .where((intent) => intent.action == 'checkpoint_trial'),
        isNotEmpty);
    await tester.pump(const Duration(milliseconds: 16));
    final missAt = harness.elapsed;
    await tester.tap(board);
    await tester.pump();
    expect(game.misses, 1);
    expect(find.text('MISS! −1 heart'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    expect(find.byKey(const Key('rune-orbit-miss')), findsOneWidget);
    final flash = find.byKey(const Key('rune-orbit-feedback-flash'));
    expect(tester.widget<Opacity>(flash).opacity, 1);
    await tester.tap(board);
    expect(game.misses, 1, reason: 'Intermission ignores repeated input');
    await tester.pump(const Duration(milliseconds: 100));
    final fading = tester.widget<Opacity>(flash).opacity;
    expect(fading, lessThan(1));
    expect(fading, greaterThan(0));
    await capture(tester, harness, 'rune-orbit-miss');

    await harness.advanceTo(tester, game.nextRoundAt!);
    final target = game.targetRune;
    await harness.advanceTo(
        tester, (game.roundStartedAt + target * game.visibleMs + 100).ceil());
    await tester.pump(const Duration(milliseconds: 420));
    final matchAt = harness.elapsed;
    await tester.tap(board);
    await tester.pump();
    expect(game.rounds, 1);
    expect(game.misses, 1);
    expect(find.text('MATCHED! +1'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byKey(const Key('rune-orbit-success')), findsOneWidget);
    expect(sounds.where((sound) => sound == 'ui_confirm'), hasLength(1));
    await capture(tester, harness, 'rune-orbit-success');

    expect(harness.controller.saving, isFalse);
    await tester.runAsync(() => harness.controller.flush());
    expect(harness.controller.error, isNull);
    final chunks = harness.server.sent
        .where((intent) => intent.action == 'checkpoint_trial')
        .toList();
    var origin = 0;
    final recorded = <TrialInput>[];
    for (final chunk in chunks) {
      recorded.addAll(TrialInputTranscript.decode(
          chunk.payload['inputs'] as String,
          startMilliseconds: origin));
      origin = chunk.payload['elapsedMs'] as int;
    }
    expect(recorded, hasLength(2));
    expect(recorded.map((input) => input.control),
        everyElement(TrialControl.tapRune));
    expect(recorded.map((input) => input.a), [wrong, target]);
    expect(recorded.map((input) => input.milliseconds), [missAt, matchAt]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'a tap across a gate boundary resolves the current canonical rune',
      (tester) async {
    final harness = await setup(tester);
    final game = harness.controller.model.orbit!;
    await harness.advanceTo(
        tester, (game.roundStartedAt + game.visibleMs).ceil() - 1);
    expect(game.gateRune, 0);
    // The previous rendered/controller sample still names rune zero. The input
    // clock has crossed into rune one; one atomic advance must pick rune one.
    harness.elapsed += 2;
    harness.server.now =
        harness.server.now.add(const Duration(milliseconds: 2));
    await tester.tap(find.byKey(const Key('rune-orbit-game')));
    await tester.pump();
    expect(game.rounds + game.misses, 1);
    await tester.runAsync(() => harness.controller.flush());
    expect(harness.controller.error, isNull);
    final chunk = harness.server.sent
        .lastWhere((intent) => intent.action == 'checkpoint_trial');
    final input = TrialInputTranscript.decode(chunk.payload['inputs'] as String,
            startMilliseconds: 0)
        .single;
    expect(input.control, TrialControl.tapRune);
    expect(input.a, 1);
    expect(input.milliseconds, harness.elapsed);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'reduced motion keeps static feedback and readable compact layout',
      (tester) async {
    final harness = await setup(tester,
        reducedMotion: true, size: const Size(320, 640), textScale: 1.3);
    final game = harness.controller.model.orbit!;
    final wrong = (game.targetRune + 1) % 5;
    await harness.advanceTo(
        tester, (game.roundStartedAt + wrong * game.visibleMs + 100).ceil());
    await tester.tap(find.byKey(const Key('rune-orbit-game')));
    await tester.pump();
    final flash = find.byKey(const Key('rune-orbit-feedback-flash'));
    expect(tester.widget<Opacity>(flash).opacity, .20);
    final rune = find.byKey(const Key('rune-orbit-rune-0'));
    final position = tester.getCenter(rune);
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.widget<Opacity>(flash).opacity, .20);
    expect(tester.getCenter(rune), position);
    expect(find.text('MISS! −1 heart'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, harness, 'rune-orbit-reduced-motion');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
