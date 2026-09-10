import '../tool/trial_input_pilot.dart';

import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/redeem_code.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/trial_input.dart';
import 'package:dragon_haven/models/trial_run_model.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 10, 12);
  const owner = '11111111-1111-4111-8111-111111111111';
  final entropy = List.filled(32, 'a1').join();
  Future<Map<String, dynamic>> command(Map<String, dynamic> state,
          String action, Map<String, dynamic> payload, {int at = 0}) =>
      GameCommandEngine.execute(
          state: state,
          action: action,
          payload: payload,
          secretSeed: entropy,
          now: now.add(Duration(milliseconds: at)),
          keeperId: owner);
  Matcher error(String code) =>
      throwsA(isA<GameCommandException>().having((e) => e.code, 'code', code));

  Future<Map<String, dynamic>> fixture(TrialKind kind) async {
    final game = HouseholdProvider(clock: () => now, persistenceEnabled: false);
    game.pet
      ..stage = DragonStage.hatchling
      ..firstEgg = false
      ..favorite = true;
    game.pet.training.addAll({'might': 300, 'arcana': 300, 'spirit': 300});
    final eventId = trialDefinitions[kind]!.specialEventId;
    if (eventId != null) {
      final code = redeemCodeCatalog
          .singleWhere((c) =>
              c.rewardType == RedeemRewardType.seasonalEventPreview &&
              c.rewardId == eventId)
          .code;
      await game.redeemCode(code, keeperId: owner);
      game.availableTrials;
    } else {
      game.trialOffers = [
        TrialOffer(id: 'authority-offer', kind: kind, appearedAt: now)
      ];
      game.trialRefilledAt = now;
    }
    final state = game.exportState();
    game.dispose();
    return state;
  }

  test(
      'expiry, reversed/ahead time, oversized chunk and wrong controls cannot settle',
      () async {
    final initial = await fixture(TrialKind.ruinBreaker);
    final started = await command(initial, 'start_trial',
        {'offerId': 'authority-offer', 'dragonId': initial['pet']['id']});
    final state = started['state'] as Map<String, dynamic>;
    final id = started['result']['id'];
    final empty = TrialInputTranscript.encode([], startMilliseconds: 0);
    Map<String, dynamic> payload(int at, {String? input, String? attempt}) => {
          'attemptId': attempt ?? id,
          'inputs': input ?? empty,
          'elapsedMs': at,
          'finish': false
        };
    await expectLater(
        command(state, 'checkpoint_trial', payload(1001), at: 1000),
        error('game_attempt_time_invalid'));
    await expectLater(
        command(state, 'checkpoint_trial', payload(60001), at: 65000),
        error('game_attempt_time_invalid'));
    await expectLater(
        command(state, 'checkpoint_trial', payload(1), at: 21600001),
        error('game_attempt_time_invalid'));
    await expectLater(
        command(
            state, 'checkpoint_trial', payload(100, attempt: 'another-attempt'),
            at: 1000),
        error('game_attempt_unavailable'));
    final invalid = TrialInputTranscript.encode(
        [const TrialInput(100, TrialControl.dropCake)],
        startMilliseconds: 0);
    await expectLater(
        command(state, 'checkpoint_trial', payload(100, input: invalid),
            at: 1000),
        error('invalid_argument'));
    final checkpoint =
        await command(state, 'checkpoint_trial', payload(1000), at: 1000);
    await expectLater(
        command(checkpoint['state'], 'checkpoint_trial', payload(900),
            at: 2000),
        error('game_attempt_time_invalid'));
    final cancelled =
        await command(state, 'cancel_trial', {'attemptId': id}, at: 21600001);
    expect(cancelled['state']['pet']['xp'], initial['pet']['xp']);
    expect(cancelled['state']['_activeGameAttempt'], isNull);
  });

  test(
      'Sunwake personal best survives above the previous one-billion storage clamp',
      () {
    final dragon = Pet(id: 'endless-best', stage: DragonStage.hatchling);
    dragon.recordTrialScore('sunwakeSurf', 1000000007);
    expect(Pet.fromJson(dragon.toJson()).trialBest('sunwakeSurf'), 1000000007);
  });

  for (final kind in TrialKind.values) {
    test('${kind.name}: bounded server input replay grants one exact result',
        () async {
      var state = await fixture(kind);
      final dragonId = state['pet']['id'] as String;
      final offerId = (state['trialOffers'] as List)
          .firstWhere((o) => o['kind'] == kind.name)['id'] as String;
      final initialXp = state['pet']['xp'] as int;
      final start = await command(
          state, 'start_trial', {'offerId': offerId, 'dragonId': dragonId});
      state = start['state'];
      final attempt = start['result'] as Map<String, dynamic>;
      expect(attempt.containsKey('checkpoint'), isFalse);
      expect(state['pet']['xp'], initialXp);
      final model = TrialRunModel(
          kind: kind,
          seed: attempt['seed'] as int,
          training: {for (final f in TrainingFocus.values) f: 300});
      final queued = <TrialInput>[];
      var previous = 0;
      final empty = TrialInputTranscript.encode([], startMilliseconds: 0);
      await expectLater(
          command(
              state,
              'checkpoint_trial',
              {
                'attemptId': attempt['id'],
                'inputs': empty,
                'elapsedMs': 0,
                'finish': true
              },
              at: 1000),
          error('game_attempt_incomplete'));
      await expectLater(
          command(
              state,
              'checkpoint_trial',
              {
                'attemptId': attempt['id'],
                'inputs': empty,
                'elapsedMs': 0,
                'finish': true,
                'score': 999999
              },
              at: 1000),
          error('invalid_command'));
      await expectLater(
          command(state, 'buy_starlight_treat', {'dragonId': dragonId}),
          error('game_attempt_in_progress'));
      void press(int at, TrialControl control, [int a = 0, int b = 0]) {
        final input = TrialInput(at, control, a, b);
        queued.add(input);
        model.apply(input);
      }

      Map<String, dynamic>? finalResult, finalPayload;
      for (var at = 0; at <= 145000; at += 20) {
        model.advanceTo(at);
        if (!model.ended) {
          pilotTrial(model, at, press);
        }
        model.takeEvents();
        if (model.ended || at - previous >= 5000) {
          final payload = {
            'attemptId': attempt['id'],
            'inputs': TrialInputTranscript.encode(queued,
                startMilliseconds: previous),
            'elapsedMs': at,
            'finish': model.ended
          };
          final updated =
              await command(state, 'checkpoint_trial', payload, at: at + 1000);
          state = updated['state'];
          queued.clear();
          previous = at;
          if (model.ended) {
            finalResult = updated['result'];
            finalPayload = payload;
            break;
          }
          expect(state['pet']['xp'], initialXp);
          final restored = TrialRunModel.fromCheckpoint(
              state['_activeGameAttempt']['checkpoint']);
          expect(restored.score, model.score);
        }
      }
      expect(finalResult, isNotNull);
      expect(finalResult!['score'], model.score);
      expect(model.score, greaterThan(0));
      if (kind == TrialKind.sunwakeSurf) {
        expect(model.score, greaterThan(20000));
      }
      expect(state['_activeGameAttempt'], isNull);
      expect(state['_lastGameResult']['type'], 'trial');
      expect(state['pet']['xp'], initialXp + (finalResult['xp'] as int));
      expect((state['trialOffers'] as List).where((o) => o['id'] == offerId),
          isEmpty);
      await expectLater(
          command(state, 'checkpoint_trial', finalPayload!,
              at: previous + 2000),
          error('game_attempt_unavailable'));
    });
  }
}
