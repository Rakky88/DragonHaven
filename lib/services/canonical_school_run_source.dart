import 'dart:convert';

import '../models/dragon_school.dart';
import 'canonical_game_actions.dart';
import 'canonical_game_session.dart';
import 'canonical_game_snapshot.dart';
import 'school_run_source.dart';

SchoolStudent canonicalSchoolStudent(CanonicalDragonView dragon) =>
    SchoolStudent(
        id: dragon.id,
        displayName: dragon.name,
        lineageId: dragon.lineageId,
        stage: dragon.stage,
        path: dragon.path,
        spectral: dragon.spectral,
        sinister: dragon.sinister,
        attempts: dragon.schoolAttempts,
        stars: dragon.schoolStars,
        complete: dragon.schoolComplete,
        outcome: dragon.schoolOutcome);

class CanonicalSchoolRunSource extends SchoolRunSource {
  CanonicalSchoolRunSource(
      this.session, this.definition, List<String> ids, this.mentorId)
      : dragonIds = List.unmodifiable(ids),
        owner = session.connection.currentOwner,
        epoch = session.connection.sessionEpoch {
    session.addListener(notifyListeners);
  }
  final CanonicalGameSession session;
  final DragonSchoolGameDefinition definition;
  final List<String> dragonIds;
  final String? mentorId, owner;
  final int epoch;
  String? _attemptId;
  bool _startPending = false;
  @override
  bool get accountCurrent =>
      owner != null &&
      session.connection.currentOwner == owner &&
      session.connection.sessionEpoch == epoch;
  @override
  List<SchoolStudent> get participants => !accountCurrent
      ? []
      : [
          for (final id in dragonIds)
            if (session.snapshot?.dragon(id) case final dragon?)
              canonicalSchoolStudent(dragon),
        ];
  @override
  SchoolStudent? get mentor {
    final dragon =
        accountCurrent ? session.snapshot?.dragon(mentorId ?? '') : null;
    return dragon == null ? null : canonicalSchoolStudent(dragon);
  }

  @override
  int get keeperBest => !accountCurrent
      ? 0
      : (session.snapshot?.data['progress']['dragonSchoolRecords']
              [definition.id] as int? ??
          0);
  CanonicalGameActions _actions() {
    if (!accountCurrent) {
      throw const CanonicalGameException('game_account_changed');
    }
    return CanonicalGameActions(session);
  }

  @override
  Future<int> start() async {
    _actions();
    Object? result;
    if (_startPending) {
      await session.synchronize();
      result = session.snapshot?.data['trials']['attempt'];
    }
    if (result == null) {
      _startPending = true;
      result = await _actions().execute('start_school', {
        'gameId': definition.id,
        'dragonIds': jsonEncode(dragonIds),
        'mentorId': mentorId,
      });
    }
    if (!accountCurrent) {
      throw const CanonicalGameException('game_account_changed');
    }
    final attempt = CanonicalSchoolAttempt.parse(result);
    if (attempt.gameId != definition.id ||
        jsonEncode(attempt.dragonIds) != jsonEncode(dragonIds) ||
        attempt.mentorId != mentorId) {
      throw const CanonicalGameException('game_result_invalid');
    }
    _startPending = false;
    _attemptId = attempt.id;
    return attempt.seed;
  }

  @override
  Future<DragonSchoolLessonResult> finish(String inputs) async {
    final id = _attemptId;
    if (id == null) {
      throw const CanonicalGameException('game_attempt_unavailable');
    }
    _actions();
    if (!session.canAct) await session.synchronize();
    final completed = session.snapshot?.data['trials']['lastResult'];
    final Object? result;
    if (completed is Map &&
        completed['attemptId'] == id &&
        completed['type'] == 'school') {
      result = completed['result'];
    } else {
      result = await _actions()
          .execute('finish_school', {'attemptId': id, 'inputs': inputs});
    }
    if (!accountCurrent) {
      throw const CanonicalGameException('game_account_changed');
    }
    final decoded = decodeSchoolResult(result);
    _attemptId = null;
    return decoded;
  }

  @override
  Future<void> cancel() async {
    _actions();
    if (!session.canAct) await session.synchronize();
    final attempt = accountCurrent ? session.snapshot?.schoolAttempt : null;
    final id = _attemptId ?? attempt?.id;
    if (id == null) return;
    final completed = session.snapshot?.data['trials']['lastResult'];
    if (completed is! Map || completed['attemptId'] != id) {
      await _actions().execute('cancel_school', {'attemptId': id});
    }
    _attemptId = null;
  }

  @override
  void dispose() {
    session.removeListener(notifyListeners);
    super.dispose();
  }
}

DragonSchoolLessonResult decodeSchoolResult(Object? raw) {
  if (raw is! Map ||
      raw['accepted'] != true ||
      raw['keeperBestImproved'] is! bool) {
    throw const CanonicalGameException('game_result_invalid');
  }
  Map<String, int> counts(String key) {
    final values = raw[key];
    if (values is! Map ||
        values.entries.any((e) =>
            e.key is! String || e.value is! int || (e.value as int) < 0)) {
      throw const CanonicalGameException('game_result_invalid');
    }
    return Map<String, int>.from(values);
  }

  Set<String> ids(String key) {
    final values = raw[key];
    if (values is! List || values.any((id) => id is! String)) {
      throw const CanonicalGameException('game_result_invalid');
    }
    return values.cast<String>().toSet();
  }

  return DragonSchoolLessonResult(
      accepted: true,
      keeperBestImproved: raw['keeperBestImproved'] as bool,
      newStarsByDragon: counts('newStarsByDragon'),
      xpByDragon: counts('xpByDragon'),
      graduatedDragonIds: ids('graduatedDragonIds'),
      finalizedDragonIds: ids('finalizedDragonIds'),
      attemptsByDragon: counts('attemptsByDragon'));
}
