import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/domain/game_public_projection.dart';
import 'package:dragon_haven/domain/server_entropy.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/redeem_code.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/trial_input.dart';
import 'package:dragon_haven/models/trial_run_model.dart';
import 'package:dragon_haven/providers/household_provider.dart';

import 'trial_input_pilot.dart';

/// Full commands and private checkpoints must agree on the phone VM and Deno,
/// including a Sunwake run above 20,000 points and its one final reward.
Future<List<Object?>> trialCommandProbe() async {
  final results = <Object?>[];
  final now = DateTime.utc(2026, 9, 10, 12);
  const owner = '11111111-1111-4111-8111-111111111111';
  final seed = List.filled(32, 'a1').join();
  for (final kind in TrialKind.values) {
    final ids = ServerEntropy(seed, stream: 'identities');
    final game = HouseholdProvider(
        clock: () => now,
        persistenceEnabled: false,
        idGenerator: ids.uuid,
        random: ServerEntropy(seed, stream: 'rewards'));
    game.pet
      ..stage = DragonStage.hatchling
      ..firstEgg = false
      ..favorite = true;
    game.pet.training.addAll({'might': 300, 'arcana': 300, 'spirit': 300});
    final event = trialDefinitions[kind]!.specialEventId;
    if (event != null) {
      final code = redeemCodeCatalog.singleWhere((c) =>
          c.rewardType == RedeemRewardType.seasonalEventPreview &&
          c.rewardId == event);
      await game.redeemCode(code.code, keeperId: owner);
      game.availableTrials;
    } else {
      game.trialOffers = [
        TrialOffer(id: 'parity-offer', kind: kind, appearedAt: now)
      ];
      game.trialRefilledAt = now;
    }
    var state = game.exportState();
    final offer = game.trialOffers.firstWhere((o) => o.kind == kind);
    game.dispose();
    var awayMs = 0;
    Future<Map<String, dynamic>> command(
        String action, Map<String, dynamic> payload, int at) async {
      final result = await GameCommandEngine.execute(
          state: state,
          action: action,
          payload: payload,
          secretSeed:
              action == 'resume_trial' ? List.filled(32, 'b2').join() : seed,
          now: now.add(Duration(milliseconds: at + awayMs)),
          keeperId: owner);
      state = result['state'];
      return result;
    }

    final started = await command('start_trial',
        {'offerId': offer.id, 'dragonId': state['pet']['id']}, 0);
    var attempt = started['result'] as Map;
    var model = TrialRunModel(
        kind: kind,
        seed: attempt['seed'] as int,
        training: {for (final focus in TrainingFocus.values) focus: 300});
    final queued = <TrialInput>[];
    void press(int at, TrialControl control, [int a = 0, int b = 0]) {
      final input = TrialInput(at, control, a, b);
      model.apply(input);
      queued.add(input);
    }

    var previous = 0;
    Object? finalResult;
    Object? resumedResult;
    final checkpoints = <Object?>[];
    for (var at = 0; at <= 145000; at += 20) {
      model.advanceTo(at);
      if (!model.ended) pilotTrial(model, at, press);
      model.takeEvents();
      if (model.ended || at - previous >= 5000) {
        final updated = await command(
            'checkpoint_trial',
            {
              'attemptId': attempt['id'],
              'inputs': TrialInputTranscript.encode(queued,
                  startMilliseconds: previous),
              'elapsedMs': at,
              'finish': model.ended
            },
            at + 1000);
        queued.clear();
        previous = at;
        if (model.ended) {
          finalResult = updated['result'];
          break;
        }
        checkpoints.add(state['_activeGameAttempt']['checkpoint']);
        if (resumedResult == null) {
          final oldId = attempt['id'];
          awayMs = const Duration(hours: 1).inMilliseconds;
          final resumed =
              await command('resume_trial', {'attemptId': oldId}, at + 1000);
          resumedResult = resumed['result'];
          attempt = (resumedResult as Map)['attempt'] as Map;
          model = TrialRunModel.fromCheckpoint(
              Map<String, dynamic>.from(resumedResult['checkpoint'] as Map));
          if (attempt['id'] == oldId || model.elapsedMs != at) {
            throw StateError('trial_resume_parity_invalid');
          }
        }
      }
    }
    if (finalResult is! Map ||
        finalResult['score'] != model.score ||
        model.score <= 0 ||
        kind == TrialKind.sunwakeSurf && model.score <= 20000) {
      throw StateError('trial_command_parity_incomplete_${kind.name}');
    }
    results.add({
      'kind': kind.name,
      'start': started['result'],
      'checkpoints': checkpoints,
      'resume': resumedResult,
      'result': finalResult,
      'state': state,
      'public': GamePublicProjection.project(
          state: state,
          now: now.add(Duration(milliseconds: awayMs + 180000)),
          ownerId: owner)
    });
  }
  return results;
}
