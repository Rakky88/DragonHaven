import 'package:dragon_haven/services/trial_gameplay_controller.dart';
import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/trial_input.dart';
import 'package:dragon_haven/models/trial_run_model.dart';
import 'package:dragon_haven/screens/trial_game_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/canonical_trial_run_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/game_domain_probe.dart';
import 'support/canonical_ui_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> fixture;
  setUpAll(() async {
    fixture = (await runGameDomainProbe())['state'] as Map<String, dynamic>;
  });
  late Directory directory;
  late CanonicalUiServer server;
  late CanonicalGameSession session;
  late CanonicalTrialRunSource source;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dh-trial-');
    server = CanonicalUiServer(
        jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>);
    final offer = TrialOffer(
        id: 'verified-trial',
        kind: TrialKind.ruinBreaker,
        appearedAt: server.now);
    server.state['trialOffers'] = [offer.toJson()];
    server.state['trialRefilledAt'] = server.now.toIso8601String();
    session = CanonicalGameSession(
        connection: CanonicalUiConnection(server), directory: directory);
    await session.synchronize();
    expect(session.snapshot, isNotNull, reason: session.errorCode);
    source = CanonicalTrialRunSource(
        session, offer, session.snapshot!.activeDragonId!);
  });
  tearDown(() async {
    session.dispose();
    await directory.delete(recursive: true);
  });
  Matcher error(String code) => throwsA(
      isA<CanonicalGameException>().having((e) => e.code, 'code', code));
  test(
      'lost start, checkpoint and finish retain the original attempt and exactly one reward',
      () async {
    server.loseReply = true;
    await expectLater(source.start(), error('game_command_unavailable'));
    final original = server.state['_activeGameAttempt']['id'];
    final attempt = await source.start();
    expect(attempt.id, original);
    expect(session.snapshot!.schoolAttempt, isNull);
    expect(
        session.snapshot!.data['trials']['attempt'].containsKey('checkpoint'),
        false);
    final model = TrialRunModel(
        kind: attempt.kind,
        seed: attempt.seed,
        training: {
          for (final f in TrainingFocus.values) f: source.dragon!.trainingFor(f)
        });
    final initialXp = source.dragon!.xp;
    final inputs = <TrialInput>[];
    for (var at = 0; at <= 5000; at += 10) {
      model.advanceTo(at);
      if (!model.ruin!.locked && (model.ruin!.meter - .5).abs() < .025) {
        final input = TrialInput(at, TrialControl.strikeRuin);
        inputs.add(input);
        model.apply(input);
      }
    }
    server.now = server.now.add(const Duration(seconds: 5));
    final encoded = TrialInputTranscript.encode(inputs, startMilliseconds: 0);
    server.loseReply = true;
    await expectLater(source.checkpoint(encoded, 5000, finish: false),
        error('game_command_unavailable'));
    final revision = server.revision;
    await source.checkpoint(encoded, 5000, finish: false);
    expect(server.revision, revision);
    expect(source.acknowledgedMs, 5000);
    expect(source.dragon!.xp, initialXp);
    inputs.clear();
    for (var at = 5010; at <= 50000 && !model.ended; at += 10) {
      model.advanceTo(at);
      if (!model.ended &&
          !model.ruin!.locked &&
          (model.ruin!.meter - .5).abs() < .025) {
        final input = TrialInput(at, TrialControl.strikeRuin);
        inputs.add(input);
        model.apply(input);
      }
    }
    expect(model.ended, true);
    server.now = server.now.add(const Duration(seconds: 50));
    final finish = TrialInputTranscript.encode(inputs, startMilliseconds: 5000);
    server.loseReply = true;
    await expectLater(source.checkpoint(finish, model.elapsedMs, finish: true),
        error('game_command_unavailable'));
    final completedRevision = server.revision;
    final result =
        await source.checkpoint(finish, model.elapsedMs, finish: true);
    expect(result!.score, model.score);
    expect(result.score, greaterThan(0));
    expect(source.dragon!.xp, initialXp + result.reward.xp);
    expect(session.snapshot!.trialAttempt, isNull);
    expect(server.revision, completedRevision);
  });
  test(
      'abandoning a reserved offer gives no reward; account exit cannot cancel another account',
      () async {
    await source.start();
    final before = source.dragon!.xp;
    await source.cancel();
    expect(session.snapshot!.trialAttempt, isNull);
    expect(source.dragon!.xp, before);
    expect(session.snapshot!.trialOffers.where((o) => o.id == source.offer.id),
        isEmpty);
    (session.connection as CanonicalUiConnection).signOut();
    expect(source.dragon, isNull);
    await expectLater(source.start(), error('game_account_changed'));
    await expectLater(source.cancel(), error('game_account_changed'));
  });
  test(
      'a failed background checkpoint pauses and resumes without counting time away',
      () async {
    var elapsed = 0;
    final controller =
        TrialGameplayController(source, elapsedMilliseconds: () => elapsed);
    addTearDown(controller.dispose);
    await controller.prepare();
    controller.start();
    controller.input(TrialControl.strikeRuin);
    elapsed = 400;
    server.now = server.now.add(const Duration(milliseconds: 400));
    controller.tick();
    controller.input(TrialControl.strikeRuin);
    server.loseReply = true;
    await controller.flush();
    expect(controller.paused, true);
    expect(controller.error, 'game_command_unavailable');
    final revision = server.revision;
    final misses = controller.model.ruin!.misses;
    elapsed = 100400;
    controller.tick();
    expect(controller.model.elapsedMs, 400);
    await controller.resume();
    expect(controller.error, isNull);
    expect(controller.running, true);
    expect(source.acknowledgedMs, 400);
    expect(server.revision, revision);
    expect(controller.model.ruin!.misses, misses);
    elapsed += 100;
    controller.tick();
    expect(controller.model.elapsedMs, 500);
    await controller.cancel();
    expect(session.snapshot!.trialAttempt, isNull);
  });

  testWidgets(
      'the existing Ruin artwork plays canonical input and displays the verified reward',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var elapsed = 0;
    final initialXp = source.dragon!.xp;
    await tester.runAsync(() => tester.pumpWidget(MaterialApp(
        home: TrialGameScreen(
            offerId: source.offer.id,
            dragonId: source.dragonId,
            source: source,
            elapsedMilliseconds: () => elapsed))));
    for (var i = 0;
        i < 100 &&
            find.byKey(const Key('ruin-breaker-game')).evaluate().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(find.byKey(const Key('ruin-breaker-game')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ruin-breaker-game')));
    // Three visible misses end this model; no score payload reaches the server.
    for (var i = 0; i < 3; i++) {
      elapsed += 400;
      server.now = server.now.add(const Duration(milliseconds: 400));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('ruin-breaker-game')));
    }
    for (var i = 0; i < 120 && find.text('Continue').evaluate().isEmpty; i++) {
      elapsed += 50;
      server.now = server.now.add(const Duration(milliseconds: 50));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Continue'), findsOneWidget,
        reason:
            '${server.state['_activeGameAttempt']} / ${session.errorCode} / ${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList()}');
    expect(
        server.sent.where((c) => c.action == 'checkpoint_trial'), isNotEmpty);
    for (final c in server.sent.where((c) => c.action == 'checkpoint_trial')) {
      expect(c.payload.keys,
          unorderedEquals(['attemptId', 'inputs', 'elapsedMs', 'finish']));
    }
    expect(source.dragon!.xp, greaterThan(initialXp));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
