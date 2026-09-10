import '../models/chest.dart';
import '../models/dragon_emote.dart';
import '../models/mystic_relic.dart';
import '../models/pet.dart';
import '../models/trial.dart';
import '../models/trial_run_model.dart';
import 'canonical_game_actions.dart';
import 'canonical_game_session.dart';
import 'canonical_game_snapshot.dart';

/// The journal retries the original command, including a lost reply. No score,
/// reward, seed or replay checkpoint is accepted from the player's screen.
class CanonicalTrialRunSource {
  CanonicalTrialRunSource(this.session, this.offer, this.dragonId,
      {this.resumeAttemptId})
      : owner = session.connection.currentOwner,
        epoch = session.connection.sessionEpoch;
  final CanonicalGameSession session;
  final TrialOffer offer;
  final String dragonId;
  final String? owner;
  final int epoch;
  final String? resumeAttemptId;
  TrialRunModel? _restoredModel;
  TrialRunModel? get restoredModel => _restoredModel;
  String? _attemptId;
  bool _startPending = false;
  int _acknowledgedMs = 0;
  int get acknowledgedMs => _acknowledgedMs;
  bool get accountCurrent =>
      owner != null &&
      owner == session.connection.currentOwner &&
      epoch == session.connection.sessionEpoch;
  CanonicalDragonView? get dragon =>
      accountCurrent ? session.snapshot?.dragon(dragonId) : null;
  void _requireAccount() {
    if (!accountCurrent) {
      throw const CanonicalGameException('game_account_changed');
    }
  }

  Future<CanonicalTrialAttempt> start() async {
    _requireAccount();
    if (resumeAttemptId != null) return _resumeSaved();
    Object? raw;
    if (_startPending) {
      await session.synchronize();
      _requireAccount();
      raw = session.snapshot?.data['trials']['attempt'];
    }
    if (raw == null) {
      _startPending = true;
      raw = await CanonicalGameActions(session)
          .execute('start_trial', {'offerId': offer.id, 'dragonId': dragonId});
    }
    _requireAccount();
    final attempt = CanonicalTrialAttempt.parse(raw);
    if (attempt.offerId != offer.id ||
        attempt.dragonId != dragonId ||
        attempt.kind != offer.kind ||
        attempt.elapsedMs != 0) {
      throw const CanonicalGameException('game_attempt_unavailable');
    }
    _attemptId = attempt.id;
    _startPending = false;
    return attempt;
  }

  Future<CanonicalTrialAttempt> _resumeSaved() async {
    Object? raw;
    final recovering = _startPending;
    if (recovering || !session.canAct) {
      final receipt = await session.synchronize();
      _requireAccount();
      final result = receipt?.result;
      if (recovering && result is Map && result.containsKey('checkpoint')) {
        raw = result;
      }
    }
    final current = session.snapshot?.trialAttempt;
    if (current == null ||
        current.offerId != offer.id ||
        current.dragonId != dragonId ||
        current.kind != offer.kind) {
      throw const CanonicalGameException('game_attempt_unavailable');
    }
    if (raw == null) {
      _startPending = true;
      raw = await CanonicalGameActions(session).execute('resume_trial',
          {'attemptId': recovering ? current.id : resumeAttemptId!});
    }
    _requireAccount();
    if (raw is! Map ||
        raw.length != 2 ||
        raw['checkpoint'] is! Map ||
        raw['attempt'] is! Map) {
      throw const CanonicalGameException('game_result_invalid');
    }
    final attempt = CanonicalTrialAttempt.parse(raw['attempt']);
    final TrialRunModel model;
    try {
      model = TrialRunModel.fromCheckpoint(
          Map<String, dynamic>.from(raw['checkpoint'] as Map));
    } on Object {
      throw const CanonicalGameException('game_result_invalid');
    }
    if (attempt.id != session.snapshot?.trialAttempt?.id ||
        attempt.offerId != offer.id ||
        attempt.dragonId != dragonId ||
        attempt.kind != offer.kind ||
        model.kind != attempt.kind ||
        model.seed != attempt.seed ||
        model.elapsedMs != attempt.elapsedMs) {
      throw const CanonicalGameException('game_attempt_unavailable');
    }
    _attemptId = attempt.id;
    _acknowledgedMs = attempt.elapsedMs;
    _restoredModel = model;
    _startPending = false;
    return attempt;
  }

  Future<TrialCompletion?> checkpoint(String inputs, int elapsedMs,
      {required bool finish}) async {
    _requireAccount();
    final id = _attemptId;
    if (id == null || elapsedMs < _acknowledgedMs) {
      throw const CanonicalGameException('game_attempt_unavailable');
    }
    if (!session.canAct) await session.synchronize();
    _requireAccount();
    final last = session.snapshot?.data['trials']['lastResult'];
    if (finish &&
        last is Map &&
        last['type'] == 'trial' &&
        last['attemptId'] == id) {
      return decodeTrialCompletion(last['result']);
    }
    final current = session.snapshot?.trialAttempt;
    if (current?.id != id) {
      throw const CanonicalGameException('game_attempt_unavailable');
    }
    // Synchronization may have recovered this exact chunk's lost reply.
    if (!finish &&
        current!.elapsedMs >= elapsedMs &&
        elapsedMs > _acknowledgedMs) {
      _acknowledgedMs = elapsedMs;
      return null;
    }
    final raw = await CanonicalGameActions(session).execute(
        'checkpoint_trial', {
      'attemptId': id,
      'inputs': inputs,
      'elapsedMs': elapsedMs,
      'finish': finish
    });
    _requireAccount();
    if (raw is! Map || raw['accepted'] != true) {
      throw const CanonicalGameException('game_result_invalid');
    }
    if (finish) return decodeTrialCompletion(raw);
    if (raw['elapsedMs'] != elapsedMs || raw['finished'] is! bool) {
      throw const CanonicalGameException('game_result_invalid');
    }
    _acknowledgedMs = elapsedMs;
    return null;
  }

  Future<void> cancel() async {
    _requireAccount();
    if (!session.canAct) await session.synchronize();
    _requireAccount();
    final attempt = session.snapshot?.trialAttempt;
    if (attempt == null) return;
    if (attempt.offerId != offer.id ||
        attempt.dragonId != dragonId ||
        (_attemptId != null && attempt.id != _attemptId)) {
      throw const CanonicalGameException('game_attempt_unavailable');
    }
    await CanonicalGameActions(session)
        .execute('cancel_trial', {'attemptId': attempt.id});
    _attemptId = null;
  }
}

TrialCompletion decodeTrialCompletion(Object? raw) {
  Never invalid() => throw const CanonicalGameException('game_result_invalid');
  if (raw is! Map ||
      raw['accepted'] != true ||
      raw['cancelled'] != false ||
      !TrialKind.values.any((k) => k.name == raw['kind']) ||
      !TrialGrade.values.any((g) => g.name == raw['grade']) ||
      raw['newDragonBest'] is! bool ||
      raw['testEvent'] is! bool ||
      raw['simulated'] is! bool) {
    invalid();
  }
  int count(String key) {
    final value = raw[key];
    if (value is! int || value < 0 || value > 9007199254740991) invalid();
    return value;
  }

  T? optional<T>(String key, List<T> values, String Function(T) name) {
    if (raw[key] == null) return null;
    return values.where((v) => name(v) == raw[key]).firstOrNull ?? invalid();
  }

  final expertise = raw['expertiseRewards'];
  if (expertise is! Map ||
      expertise.entries.any((e) =>
          !TrainingFocus.values.any((f) => f.name == e.key) ||
          e.value is! int ||
          (e.value as int) < 0 ||
          (e.value as int) > 400)) {
    invalid();
  }
  final kind = TrialKind.values.byName(raw['kind'] as String);
  final score = count('score');
  final grade = TrialGrade.values.byName(raw['grade'] as String);
  if (trialGradeForScore(kind, score) != grade) invalid();
  return TrialCompletion(
      kind: kind,
      score: score,
      newDragonBest: raw['newDragonBest'] as bool,
      testEvent: raw['testEvent'] as bool,
      simulated: raw['simulated'] as bool,
      reward: TrialReward(
          grade: grade,
          coins: count('coins'),
          xp: count('xp'),
          statPoints: count('statPoints'),
          chestTier: optional('chestTier', ChestTier.values, (v) => v.name),
          relic: optional('relic', MysticRelic.values, (v) => v.name),
          emote: optional('emote', allDragonEmotes, (v) => v.id),
          expertiseRewards: {
            for (final e in expertise.entries)
              TrainingFocus.values.byName(e.key as String): e.value as int
          }));
}
