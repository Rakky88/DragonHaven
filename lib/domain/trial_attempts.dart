import '../models/pet.dart';
import '../models/trial.dart';
import '../models/trial_input.dart';
import '../models/trial_run_model.dart';
import '../providers/household_provider.dart';

/// Server-owned reservations and replay checkpoints. Neither the seed, private
/// simulation state nor reward values can be supplied in a player command.
abstract final class TrialAttempts {
  static Future<Map<String, dynamic>> start(
      {required HouseholdProvider game,
      required String id,
      required int seed,
      required String offerId,
      required String dragonId,
      required DateTime now}) async {
    final dragon = game.ownedDragons.where((d) => d.id == dragonId).firstOrNull;
    final offer =
        game.availableTrials.where((o) => o.id == offerId).firstOrNull;
    if (dragon == null ||
        dragon.stage == DragonStage.egg ||
        dragon.activeAdventureId != null ||
        offer == null ||
        !dragonMeetsTrialFormRequirement(
          kind: offer.kind,
          stage: dragon.stage,
          activeEvolutionPath: dragon.activeEvolutionPath,
        ) ||
        !await game.beginTrial(offerId)) {
      throw const TrialAttemptException('game_action_unavailable');
    }
    final model = TrialRunModel(kind: offer.kind, seed: seed, training: {
      for (final focus in TrainingFocus.values) focus: dragon.trainingFor(focus)
    });
    return {
      'version': 1,
      'type': 'trial',
      'id': id,
      'seed': seed,
      'gameId': offer.kind.name,
      'offerId': offerId,
      'dragonIds': [dragonId],
      'specialEventKey': offer.specialEventKey,
      'startedAt': now.toUtc().toIso8601String(),
      'expiresAt': now.toUtc().add(const Duration(hours: 6)).toIso8601String(),
      'elapsedMs': 0,
      'inputCount': 0,
      'activeClockAt': now.toUtc().toIso8601String(),
      'activeClockElapsedMs': 0,
      'checkpoint': model.checkpoint(),
    };
  }

  static Map<String, dynamic> resume(
      {required HouseholdProvider game,
      required Map<String, dynamic>? attempt,
      required String id,
      required String replacementId,
      required DateTime now}) {
    if (attempt == null || attempt['type'] != 'trial' || attempt['id'] != id) {
      throw const TrialAttemptException('game_attempt_unavailable');
    }
    if (!now.isBefore(DateTime.parse(attempt['expiresAt'] as String))) {
      throw const TrialAttemptException('game_attempt_time_invalid');
    }
    _requireEligibleAttemptDragon(game, attempt);
    final model = TrialRunModel.fromCheckpoint(
        Map<String, dynamic>.from(attempt['checkpoint'] as Map));
    if (model.kind.name != attempt['gameId']) {
      throw const TrialAttemptException('game_attempt_unavailable');
    }
    final release = !model.ended && model.surfHeld
        ? TrialControl.releaseDragon
        : !model.ended && model.trace?.active == true
            ? TrialControl.releasePath
            : null;
    if (release != null) model.apply(TrialInput(model.elapsedMs, release));
    return {
      ...attempt,
      // A previous device cannot append inputs after this device resumes.
      'id': replacementId,
      'inputCount': (attempt['inputCount'] as int) + (release == null ? 0 : 1),
      'checkpoint': model.checkpoint(),
      'activeClockAt': now.toUtc().toIso8601String(),
      'activeClockElapsedMs': model.elapsedMs,
      'expiresAt': now.toUtc().add(const Duration(hours: 6)).toIso8601String(),
    };
  }

  static Map<String, dynamic> display(Map<String, dynamic> attempt) => {
        for (final key in const [
          'version',
          'type',
          'elapsedMs',
          'id',
          'seed',
          'gameId',
          'offerId',
          'dragonIds',
          'specialEventKey',
          'startedAt',
          'expiresAt'
        ])
          key: attempt[key]
      };

  static Future<({Map<String, dynamic>? attempt, Map<String, dynamic> result})>
      update(
          {required HouseholdProvider game,
          required Map<String, dynamic>? attempt,
          required String id,
          required DateTime now,
          required String inputs,
          required int elapsedMs,
          required bool finish,
          bool cancel = false}) async {
    if (attempt == null || attempt['type'] != 'trial' || attempt['id'] != id) {
      throw const TrialAttemptException('game_attempt_unavailable');
    }
    if (cancel) {
      final offerId = attempt['offerId'];
      if (offerId is! String) {
        throw const TrialAttemptException('game_attempt_unavailable');
      }
      await game.dismissTrial(offerId);
      return (attempt: null, result: {'cancelled': true, 'accepted': true});
    }
    final dragon = _requireEligibleAttemptDragon(game, attempt);
    final offerId = attempt['offerId'] as String;
    final dragonId = dragon.id;
    final started = DateTime.parse(attempt['startedAt'] as String);
    final expires = DateTime.parse(attempt['expiresAt'] as String);
    final previous = attempt['elapsedMs'] as int;
    final clockAt = DateTime.parse(
        (attempt['activeClockAt'] ?? attempt['startedAt']) as String);
    final clockElapsed = (attempt['activeClockElapsedMs'] ?? 0) as int;
    if (!now.isBefore(expires) ||
        elapsedMs < previous ||
        elapsedMs - previous > 60000 ||
        elapsedMs > now.difference(started).inMilliseconds ||
        elapsedMs > clockElapsed + now.difference(clockAt).inMilliseconds) {
      throw const TrialAttemptException('game_attempt_time_invalid');
    }
    final decoded =
        TrialInputTranscript.decode(inputs, startMilliseconds: previous);
    if (decoded.isNotEmpty && decoded.last.milliseconds > elapsedMs) {
      throw const TrialAttemptException('game_attempt_time_invalid');
    }
    final count = (attempt['inputCount'] as int) + decoded.length;
    if (count > 180 + elapsedMs * 180 ~/ 1000) {
      throw const TrialAttemptException('game_attempt_input_limit');
    }
    final model = TrialRunModel.fromCheckpoint(
        Map<String, dynamic>.from(attempt['checkpoint'] as Map));
    if (model.kind.name != attempt['gameId']) {
      throw const TrialAttemptException('game_attempt_unavailable');
    }
    for (final input in decoded) {
      model.apply(input);
    }
    model.advanceTo(elapsedMs);
    if (!finish) {
      final updated = {
        ...attempt,
        'checkpoint': model.checkpoint(),
        'elapsedMs': elapsedMs,
        'inputCount': count,
        'expiresAt': now.toUtc().add(const Duration(hours: 6)).toIso8601String()
      };
      return (
        attempt: updated,
        result: {
          'accepted': true,
          'elapsedMs': elapsedMs,
          'finished': model.ended
        }
      );
    }
    if (!model.ended) {
      throw const TrialAttemptException('game_attempt_incomplete');
    }
    final completion = await game.completeTrial(
        offerId: offerId, dragonId: dragonId, score: model.score);
    if (completion == null) {
      throw const TrialAttemptException('game_attempt_state_changed');
    }
    final reward = completion.reward;
    return (
      attempt: null,
      result: {
        'accepted': true,
        'cancelled': false,
        'kind': model.kind.name,
        'score': model.score,
        'newDragonBest': completion.newDragonBest,
        'testEvent': completion.testEvent,
        'simulated': completion.simulated,
        'durationMs': elapsedMs,
        'correctActions': model.correctActions,
        'totalActions': model.totalActions,
        'specialEventKey': attempt['specialEventKey'],
        'grade': reward.grade.name,
        'coins': reward.coins,
        'xp': reward.xp,
        'statPoints': reward.statPoints,
        'chestTier': reward.chestTier?.name,
        'relic': reward.relic?.name,
        'emote': reward.emote?.id,
        'expertiseRewards': {
          for (final entry in reward.expertiseRewards.entries)
            entry.key.name: entry.value
        },
      }
    );
  }

  static Pet _requireEligibleAttemptDragon(
      HouseholdProvider game, Map<String, dynamic> attempt) {
    final rawGameId = attempt['gameId'];
    final kind = rawGameId is String ? trialKindByName(rawGameId) : null;
    final ids = attempt['dragonIds'];
    final offerId = attempt['offerId'];
    if (kind == null ||
        ids is! List ||
        ids.length != 1 ||
        ids.single is! String ||
        offerId is! String) {
      throw const TrialAttemptException('game_attempt_unavailable');
    }
    final dragon = game.ownedDragons
        .where((candidate) => candidate.id == ids.single)
        .firstOrNull;
    final offer = game.trialOffers
        .where((candidate) => candidate.id == offerId)
        .firstOrNull;
    if (dragon == null ||
        dragon.stage == DragonStage.egg ||
        dragon.activeAdventureId != null ||
        offer == null ||
        offer.kind != kind ||
        offer.startedAt == null ||
        !dragonMeetsTrialFormRequirement(
          kind: kind,
          stage: dragon.stage,
          activeEvolutionPath: dragon.activeEvolutionPath,
        )) {
      throw const TrialAttemptException('game_attempt_unavailable');
    }
    return dragon;
  }
}

class TrialAttemptException implements Exception {
  const TrialAttemptException(this.code);
  final String code;
}
