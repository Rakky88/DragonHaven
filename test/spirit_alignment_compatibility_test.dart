import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/trial_input.dart';
import 'package:dragon_haven/models/trial_run_model.dart';
import 'package:dragon_haven/services/canonical_game_intent.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/canonical_trial_run_source.dart';
import 'package:dragon_haven/providers/household_provider.dart';
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
    directory = await Directory.systemTemp.createTemp('dh-alignment-compat-');
    final now = DateTime.utc(2026, 9, 7, 12);
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => now);
    game.pet
      ..stage = DragonStage.ascended
      ..evolutionPath = TrainingFocus.spirit.name
      ..firstEgg = false
      ..favorite = true;
    game.eggAltar = EggAltarState(ownerId: CanonicalUiServer.owner);
    offer = TrialOffer(
        id: 'alignment-compat',
        kind: TrialKind.spiritAlignment,
        appearedAt: now);
    game.trialOffers = [offer];
    game.trialRefilledAt = now;
    server = CanonicalUiServer(game.exportState());
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

  int checkpointVersion() => server.state['_activeGameAttempt']['checkpoint']
      ['alignment']['version'] as int;

  test('a fresh capable start uses timed rules and the unchanged public shape',
      () async {
    final attempt = await source.start();
    expect(checkpointVersion(), 3);
    expect(server.sent.single.payload, {
      'offerId': offer.id,
      'dragonId': source.dragonId,
      'spiritAlignmentVersion': 3,
    });
    expect(source.restoredModel, isNull);
    expect(session.snapshot!.trialAttempt!.id, attempt.id);
    expect(
        session.snapshot!.data['trials']['attempt'].keys,
        unorderedEquals([
          'version',
          'type',
          'id',
          'seed',
          'gameId',
          'dragonIds',
          'offerId',
          'specialEventKey',
          'startedAt',
          'expiresAt',
          'elapsedMs',
        ]));
    server.now = server.now.add(const Duration(seconds: 60));
    final completed = await source.checkpoint(
        TrialInputTranscript.encode([], startMilliseconds: 0), 60000,
        finish: true);
    expect(completed!.score, 0);
    expect(session.snapshot!.trialAttempt, isNull);
  });

  test('upgrading restores a legacy start without converting its rules',
      () async {
    final started = await session.execute('start_trial', {
      'offerId': offer.id,
      'dragonId': source.dragonId,
    });
    expect(started!.succeeded, true);
    expect(checkpointVersion(), 1);
    final oldId = session.snapshot!.trialAttempt!.id;
    final resumed = await source.start();
    expect(resumed.id, isNot(oldId));
    expect(source.restoredModel!.alignment!.timed, false);
    expect(checkpointVersion(), 1);
    expect(server.sent.last.payload['spiritAlignmentVersion'], 3);
  });

  test('a released client can still finish its original three-shape game',
      () async {
    final started = await session.execute('start_trial', {
      'offerId': offer.id,
      'dragonId': source.dragonId,
    });
    final attempt = CanonicalTrialAttempt.parse(started!.result);
    final legacy = TrialRunModel(
      kind: attempt.kind,
      seed: attempt.seed,
      timedSpiritAlignment: false,
      containedSpiritAlignment: false,
      training: {
        for (final focus in TrainingFocus.values)
          focus: source.dragon!.trainingFor(focus),
      },
    );
    final inputs = <TrialInput>[];
    for (var at = 0; at < 2100; at += 700) {
      for (var tap = 0; tap < 2; tap++) {
        final input = TrialInput(at, TrialControl.flap);
        legacy.apply(input);
        inputs.add(input);
      }
    }
    legacy.advanceTo(2100);
    expect(legacy.ended, true);
    server.now = server.now.add(const Duration(milliseconds: 2100));
    final completed = await session.execute('checkpoint_trial', {
      'attemptId': attempt.id,
      'inputs': TrialInputTranscript.encode(inputs, startMilliseconds: 0),
      'elapsedMs': 2100,
      'finish': true,
    });
    expect(completed!.succeeded, true);
    expect((completed.result as Map)['score'], legacy.score);
    expect(session.snapshot!.trialAttempt, isNull);
  });

  test('an old app cannot fence or alter a timed attempt while resuming',
      () async {
    final started = await source.start();
    final before = jsonEncode(server.state['_activeGameAttempt']);
    final revision = server.revision;
    final rejected = await session.execute('resume_trial', {
      'attemptId': started.id,
    });
    expect(rejected!.failureCode, 'game_attempt_unavailable');
    expect(jsonEncode(server.state['_activeGameAttempt']), before);
    expect(server.revision, revision);
    await session.synchronize();
    final capable = CanonicalTrialRunSource(session, offer, source.dragonId,
        resumeAttemptId: started.id);
    final resumed = await capable.start();
    expect(resumed.id, isNot(started.id));
    expect(capable.restoredModel!.alignment!.timed, true);
    expect(checkpointVersion(), 3);
  });

  test('lost legacy start retries its exact durable payload after upgrading',
      () async {
    server.loseReply = true;
    await expectLater(
      session.execute('start_trial', {
        'offerId': offer.id,
        'dragonId': source.dragonId,
      }),
      throwsA(isA<CanonicalGameException>()),
    );
    final original = server.sent.single;
    final dragonId = source.dragonId;
    expect(checkpointVersion(), 1);
    session.dispose();
    session = CanonicalGameSession(
        connection: CanonicalUiConnection(server), directory: directory);
    await session.synchronize();
    source = CanonicalTrialRunSource(session, offer, dragonId);
    await source.start();
    final starts = server.sent.where((entry) => entry.action == 'start_trial');
    expect(starts.length, 2);
    expect(starts.every((entry) => entry.sameIntent(original)), true);
    expect(
        starts.every(
            (entry) => !entry.payload.containsKey('spiritAlignmentVersion')),
        true);
    expect(source.restoredModel!.alignment!.timed, false);
    expect(checkpointVersion(), 1);
  });

  test('lost capable start recovers its saved timed model', () async {
    server.loseReply = true;
    await expectLater(source.start(), throwsA(isA<CanonicalGameException>()));
    await source.start();
    expect(source.restoredModel!.alignment!.timed, true);
    expect(checkpointVersion(), 3);
    final starts = server.sent.where((entry) => entry.action == 'start_trial');
    expect(starts.map((entry) => entry.requestId).toSet(), hasLength(1));
    expect(server.sent.last.action, 'resume_trial');
  });

  test('the durable schema accepts only absent or supported capability', () {
    CanonicalGameIntent intent(String action, Map<String, dynamic> payload) =>
        CanonicalGameIntent(
          ownerId: CanonicalUiServer.owner,
          requestId: '33333333-3333-4333-8333-333333333333',
          action: action,
          payload: payload,
          minimumRevision: 1,
        );
    for (final action in ['start_trial', 'resume_trial']) {
      final payload = action == 'start_trial'
          ? {'offerId': offer.id, 'dragonId': source.dragonId}
          : {'attemptId': 'attempt'};
      expect(intent(action, payload).payload, payload);
      final capable = {...payload, 'spiritAlignmentVersion': 3};
      expect(
          CanonicalGameIntent.parse(intent(action, capable).toJson()).payload,
          capable);
      for (final invalid in [null, 0, 1, 4, '2', true, 2.5]) {
        expect(
          () => intent(action, {...payload, 'spiritAlignmentVersion': invalid}),
          throwsA(isA<CanonicalGameException>()),
        );
      }
      expect(() => intent(action, {...capable, 'score': 999}),
          throwsA(isA<CanonicalGameException>()));
    }
    expect(() => intent('refresh', {'spiritAlignmentVersion': 3}),
        throwsA(isA<CanonicalGameException>()));
  });
}
