import 'dart:io';
import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/trial_input.dart';
import 'package:dragon_haven/models/trial_run_model.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/canonical_trial_run_source.dart';
import 'package:dragon_haven/services/trial_gameplay_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/canonical_ui_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late CanonicalUiServer server;
  late CanonicalGameSession session;
  late CanonicalTrialRunSource source;
  late TrialOffer offer;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dh-trial-resume-');
    final now = DateTime.utc(2026, 9, 7, 12);
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => now);
    game.pet
      ..stage = DragonStage.hatchling
      ..firstEgg = false
      ..favorite = true
      ..name = 'Keeper';
    game.eggAltar = EggAltarState(ownerId: CanonicalUiServer.owner);
    offer = TrialOffer(
        id: 'resume-ruin', kind: TrialKind.ruinBreaker, appearedAt: now);
    server = CanonicalUiServer(game.exportState());
    server.state['trialOffers'] = [offer.toJson()];
    server.state['trialRefilledAt'] = now.toIso8601String();
    game.dispose();
    session = CanonicalGameSession(
        connection: CanonicalUiConnection(server), directory: directory);
    await session.synchronize();
    source = CanonicalTrialRunSource(
        session, offer, session.snapshot!.activeDragonId!);
  });
  tearDown(() async {
    session.dispose();
    await directory.delete(recursive: true);
  });

  test(
      'restart resumes the saved model once, fences the old device and excludes away time',
      () async {
    final original = await source.start();
    final model = TrialRunModel(
        kind: offer.kind,
        seed: original.seed,
        training: {
          for (final f in TrainingFocus.values) f: source.dragon!.trainingFor(f)
        });
    const input = TrialInput(0, TrialControl.strikeRuin);
    model.apply(input);
    model.advanceTo(400);
    server.now = server.now.add(const Duration(milliseconds: 400));
    await source.checkpoint(
        TrialInputTranscript.encode([input], startMilliseconds: 0), 400,
        finish: false);
    final checkpoint = model.checkpoint();
    final dragonId = source.dragonId;
    final xp = source.dragon!.xp;
    session.dispose();
    session = CanonicalGameSession(
        connection: CanonicalUiConnection(server), directory: directory);
    server.now = server.now.add(const Duration(hours: 1));
    await session.synchronize();
    source = CanonicalTrialRunSource(session, offer, dragonId,
        resumeAttemptId: original.id);
    var elapsed = 0;
    final controller =
        TrialGameplayController(source, elapsedMilliseconds: () => elapsed);
    addTearDown(controller.dispose);
    server.loseReply = true;
    await controller.prepare();
    expect(controller.error, 'game_command_unavailable');
    expect(controller.ready, false);
    final resumedId = server.state['_activeGameAttempt']['id'];
    final revision = server.revision;
    await controller.prepare();
    expect(controller.error, isNull);
    expect(controller.model.checkpoint(), checkpoint);
    expect(source.acknowledgedMs, 400);
    expect(resumedId, isNot(original.id));
    expect(session.snapshot!.trialAttempt!.id, resumedId);
    expect(server.revision, revision);
    final requests =
        server.sent.where((i) => i.action == 'resume_trial').toList();
    expect(requests.map((i) => i.requestId).toSet(), hasLength(1));
    expect(
        requests.every((i) =>
            i.payload.length == 1 && i.payload['attemptId'] == original.id),
        true);
    final receipt = await session.execute('checkpoint_trial', {
      'attemptId': original.id,
      'elapsedMs': 400,
      'inputs': '',
      'finish': false
    });
    expect(receipt!.failureCode, 'game_attempt_unavailable');
    await session.synchronize();
    // One hour away is not one hour of new playable input after resuming.
    final fast = await session.execute('checkpoint_trial', {
      'attemptId': resumedId,
      'elapsedMs': 1400,
      'inputs': '',
      'finish': false
    });
    expect(fast!.failureCode, 'game_attempt_time_invalid');
    await session.synchronize();
    expect(server.revision, revision);
    expect(source.dragon!.xp, xp);
    controller.start();
    for (var n = 0; n < 3 && !controller.model.ended; n++) {
      elapsed += 400;
      server.now = server.now.add(const Duration(milliseconds: 400));
      controller.tick();
      controller.input(TrialControl.strikeRuin);
    }
    expect(controller.model.ended, true);
    for (var n = 0; n < 100 && controller.saving; n++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await controller.flush();
    expect(controller.error, isNull);
    expect(controller.completion, isNotNull);
    expect(session.snapshot!.trialAttempt, isNull);
    expect(source.dragon!.xp, xp + controller.completion!.reward.xp);
  });

  test('expired reservations can be abandoned but cannot resume for rewards',
      () async {
    final original = await source.start();
    final xp = source.dragon!.xp;
    server.now = server.now.add(const Duration(hours: 7));
    final restored = CanonicalTrialRunSource(session, offer, source.dragonId,
        resumeAttemptId: original.id);
    await expectLater(
        restored.start(),
        throwsA(isA<CanonicalGameException>()
            .having((e) => e.code, 'code', 'game_attempt_time_invalid')));
    await session.synchronize();
    await restored.cancel();
    expect(session.snapshot!.trialAttempt, isNull);
    expect(source.dragon!.xp, xp);
  });

  test('a finished saved checkpoint delivers its reward after reopening once',
      () async {
    final started = await source.start();
    final xp = source.dragon!.xp;
    final model = TrialRunModel(
        kind: offer.kind,
        seed: started.seed,
        training: {
          for (final f in TrainingFocus.values) f: source.dragon!.trainingFor(f)
        });
    final inputs = <TrialInput>[];
    for (var at = 0; at <= 1600 && !model.ended; at += 400) {
      model.advanceTo(at);
      final input = TrialInput(at, TrialControl.strikeRuin);
      model.apply(input);
      inputs.add(input);
    }
    expect(model.ended, true);
    server.now = server.now.add(Duration(milliseconds: model.elapsedMs));
    await source.checkpoint(
        TrialInputTranscript.encode(inputs, startMilliseconds: 0),
        model.elapsedMs,
        finish: false);
    final restored = CanonicalTrialRunSource(session, offer, source.dragonId,
        resumeAttemptId: started.id);
    final controller = TrialGameplayController(restored);
    addTearDown(controller.dispose);
    await controller.prepare();
    expect(controller.error, isNull);
    expect(controller.completion!.score, model.score);
    expect(restored.dragon!.xp, xp + controller.completion!.reward.xp);
    final revision = server.revision;
    await controller.flush();
    expect(server.revision, revision);
    expect(session.snapshot!.trialAttempt, isNull);
  });
}
