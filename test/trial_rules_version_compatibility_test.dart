import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/trial_run_model.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/canonical_game_intent.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/canonical_trial_run_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/canonical_ui_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final kind in [TrialKind.spiritAlignment, TrialKind.runeOrbit]) {
    group(kind.name, () {
      late Directory directory;
      late CanonicalUiServer server;
      late CanonicalGameSession session;
      late TrialOffer offer;
      late String dragonId;
      final capability = kind == TrialKind.spiritAlignment
          ? 'spiritAlignmentVersion'
          : 'runeOrbitVersion';
      final version = kind == TrialKind.spiritAlignment ? 4 : 2;

      setUp(() async {
        directory = await Directory.systemTemp.createTemp('dh-trial-rules-');
        final now = DateTime.utc(2026, 9, 7, 12);
        final game =
            HouseholdProvider(persistenceEnabled: false, clock: () => now);
        game.pet
          ..stage = DragonStage.ascended
          ..evolutionPath = ascendedTrialFocus(kind)!.name
          ..firstEgg = false
          ..favorite = true;
        dragonId = game.pet.id;
        game.eggAltar = EggAltarState(ownerId: CanonicalUiServer.owner);
        offer = TrialOffer(id: 'version-offer', kind: kind, appearedAt: now);
        game.trialOffers = [offer];
        game.trialRefilledAt = now;
        server = CanonicalUiServer(game.exportState());
        game.dispose();
        session = CanonicalGameSession(
            connection: CanonicalUiConnection(server), directory: directory);
        await session.synchronize();
      });

      tearDown(() async {
        session.dispose();
        await directory.delete(recursive: true);
      });

      TrialRunModel serverModel() =>
          TrialRunModel.fromCheckpoint(Map<String, dynamic>.from(
              server.state['_activeGameAttempt']['checkpoint'] as Map));
      bool newRules(TrialRunModel model) => kind == TrialKind.spiritAlignment
          ? model.alignment!.streakBonus
          : model.orbit!.uncappedSpeed;

      test('new starts use new rules and recover the same rules after restart',
          () async {
        final source = CanonicalTrialRunSource(session, offer, dragonId);
        server.loseReply = true;
        await expectLater(
            source.start(), throwsA(isA<CanonicalGameException>()));
        expect(newRules(serverModel()), true);
        expect(server.sent.single.payload[capability], version);
        final original = server.sent.single;
        session.dispose();
        session = CanonicalGameSession(
            connection: CanonicalUiConnection(server), directory: directory);
        await session.synchronize();
        final recovered = CanonicalTrialRunSource(session, offer, dragonId);
        await recovered.start();
        expect(newRules(recovered.restoredModel!), true);
        expect(newRules(serverModel()), true);
        final starts =
            server.sent.where((entry) => entry.action == 'start_trial');
        expect(starts, hasLength(2));
        expect(starts.every((entry) => entry.sameIntent(original)), true);
        expect(server.sent.last.action, 'resume_trial');
        expect(server.sent.last.payload[capability], version);
      });

      test('legacy rules stay legacy when the new app recovers a lost start',
          () async {
        server.loseReply = true;
        await expectLater(
            session.execute('start_trial', {
              'offerId': offer.id,
              'dragonId': dragonId,
            }),
            throwsA(isA<CanonicalGameException>()));
        expect(newRules(serverModel()), false);
        final original = server.sent.single;
        session.dispose();
        session = CanonicalGameSession(
            connection: CanonicalUiConnection(server), directory: directory);
        await session.synchronize();
        final source = CanonicalTrialRunSource(session, offer, dragonId);
        await source.start();
        expect(newRules(source.restoredModel!), false);
        expect(newRules(serverModel()), false);
        final starts =
            server.sent.where((entry) => entry.action == 'start_trial');
        expect(starts, hasLength(2));
        expect(starts.every((entry) => entry.sameIntent(original)), true);
      });

      test('a released client cannot fence an attempt using new rules',
          () async {
        final source = CanonicalTrialRunSource(session, offer, dragonId);
        final attempt = await source.start();
        final before = jsonEncode(server.state['_activeGameAttempt']);
        final revision = server.revision;
        for (final payload in [
          <String, dynamic>{'attemptId': attempt.id},
          if (kind == TrialKind.spiritAlignment)
            <String, dynamic>{'attemptId': attempt.id, capability: 2},
        ]) {
          final rejected = await session.execute('resume_trial', payload);
          expect(rejected!.failureCode, 'game_attempt_unavailable');
          expect(jsonEncode(server.state['_activeGameAttempt']), before);
          expect(server.revision, revision);
          await session.synchronize();
          expect(session.canAct, true);
        }
        final capable = CanonicalTrialRunSource(session, offer, dragonId,
            resumeAttemptId: attempt.id);
        final resumed = await capable.start();
        expect(resumed.id, isNot(attempt.id));
        expect(newRules(capable.restoredModel!), true);
      });

      if (kind == TrialKind.spiritAlignment) {
        test('version 2 keeps timed overlap scoring across an upgrade',
            () async {
          final receipt = await session.execute('start_trial', {
            'offerId': offer.id,
            'dragonId': dragonId,
            capability: 2,
          });
          expect(receipt!.succeeded, true);
          expect(serverModel().alignment!.timed, true);
          expect(newRules(serverModel()), false);
          final resumed = CanonicalTrialRunSource(session, offer, dragonId);
          await resumed.start();
          expect(resumed.restoredModel!.alignment!.timed, true);
          expect(newRules(resumed.restoredModel!), false);
          expect(
              server.state['_activeGameAttempt']['checkpoint']['alignment']
                  ['version'],
              2);
        });

        test('version 3 keeps its per-perfect bonus across an upgrade',
            () async {
          final receipt = await session.execute('start_trial', {
            'offerId': offer.id,
            'dragonId': dragonId,
            capability: 3,
          });
          expect(receipt!.succeeded, true);
          expect(serverModel().alignment!.timed, true);
          expect(serverModel().alignment!.containedScoring, true);
          expect(serverModel().alignment!.streakBonus, false);
          final resumed = CanonicalTrialRunSource(session, offer, dragonId);
          await resumed.start();
          expect(resumed.restoredModel!.alignment!.streakBonus, false);
          expect(
              server.state['_activeGameAttempt']['checkpoint']['alignment']
                  ['version'],
              3);
        });
      }
    });
  }

  test('journal strictly allows only supported trial capabilities', () {
    CanonicalGameIntent intent(String action, Map<String, dynamic> payload) =>
        CanonicalGameIntent(
            ownerId: CanonicalUiServer.owner,
            requestId: '33333333-3333-4333-8333-333333333333',
            action: action,
            payload: payload,
            minimumRevision: 1);
    for (final action in ['start_trial', 'resume_trial']) {
      final base = action == 'start_trial'
          ? {'offerId': 'offer', 'dragonId': 'dragon'}
          : {'attemptId': 'attempt'};
      for (final optional in [
        <String, dynamic>{},
        {'spiritAlignmentVersion': 2},
        {'spiritAlignmentVersion': 3},
        {'spiritAlignmentVersion': 4},
        {'runeOrbitVersion': 2},
        {'spiritAlignmentVersion': 4, 'runeOrbitVersion': 2},
      ]) {
        final payload = {...base, ...optional};
        expect(
            CanonicalGameIntent.parse(intent(action, payload).toJson()).payload,
            payload);
      }
      for (final value in [null, 0, 1, 3, '2', true, 2.0]) {
        expect(() => intent(action, {...base, 'runeOrbitVersion': value}),
            throwsA(isA<CanonicalGameException>()));
      }
      expect(
          () => intent(action, {
                ...base,
                'spiritAlignmentVersion': 4,
                'runeOrbitVersion': 2,
                'score': 999,
              }),
          throwsA(isA<CanonicalGameException>()));
    }
    expect(() => intent('refresh', {'runeOrbitVersion': 2}),
        throwsA(isA<CanonicalGameException>()));
  });
}
