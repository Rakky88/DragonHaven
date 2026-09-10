import '../models/dragon_school.dart';
import '../models/game_input_transcript.dart';
import '../models/school_lesson_game.dart';
import '../providers/household_provider.dart';

/// Private server attempts bind a lesson and pupils before any input is sent.
/// The command lease atomically commits both the consumed attempt and rewards.
abstract final class SchoolAttempts {
  static Map<String, dynamic> start({
    required HouseholdProvider game,
    required String id,
    required int seed,
    required String gameId,
    required List<String> dragonIds,
    required String? mentorId,
    required DateTime now,
  }) {
    if (game.dragonSchoolEnrollment(
            gameId: gameId, dragonIds: dragonIds, mentorDragonId: mentorId) ==
        null) {
      throw const SchoolAttemptException('game_action_unavailable');
    }
    return {
      'version': 1,
      'type': 'school',
      'id': id,
      'seed': seed,
      'gameId': gameId,
      'dragonIds': List<String>.from(dragonIds),
      'mentorId': mentorId,
      'startedAt': now.toUtc().toIso8601String(),
      'expiresAt':
          now.toUtc().add(const Duration(minutes: 10)).toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> finish({
    required HouseholdProvider game,
    required Map<String, dynamic>? attempt,
    required String id,
    required DateTime now,
    required String inputs,
    bool cancel = false,
  }) async {
    if (attempt == null || attempt['id'] != id || attempt['type'] != 'school') {
      throw const SchoolAttemptException('game_attempt_unavailable');
    }
    final started = DateTime.parse(attempt['startedAt'] as String);
    final expires = DateTime.parse(attempt['expiresAt'] as String);
    if (!cancel &&
        (!now.isBefore(expires) ||
            now.difference(started) < const Duration(seconds: 20))) {
      throw const SchoolAttemptException('game_attempt_time_invalid');
    }
    final definition = dragonSchoolGameById(attempt['gameId'] as String)!;
    final model = SchoolLessonGame(
        kind: definition.kind,
        seed: attempt['seed'] as int,
        mentor: attempt['mentorId'] != null);
    if (!cancel) {
      for (final input in SchoolInputTranscript.decode(inputs)) {
        model.tap(input.target, input.milliseconds);
      }
    }
    final result = await game.completeDragonSchoolLesson(
      gameId: definition.id,
      score: model.score,
      dragonIds: List<String>.from(attempt['dragonIds'] as List),
      mentorDragonId: cancel ? null : attempt['mentorId'] as String?,
    );
    if (!result.accepted) {
      throw const SchoolAttemptException('game_attempt_state_changed');
    }
    return {
      'score': model.score,
      'cancelled': cancel,
      'accepted': result.accepted,
      'keeperBestImproved': result.keeperBestImproved,
      'newStarsByDragon': result.newStarsByDragon,
      'xpByDragon': result.xpByDragon,
      'graduatedDragonIds': result.graduatedDragonIds.toList(),
      'finalizedDragonIds': result.finalizedDragonIds.toList(),
      'attemptsByDragon': result.attemptsByDragon,
    };
  }
}

class SchoolAttemptException implements Exception {
  const SchoolAttemptException(this.code);
  final String code;
}
