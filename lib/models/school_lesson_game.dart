import 'dart:math';

import 'dragon_school.dart';
import 'game_input_transcript.dart';

/// The Academy's rules, shared by the screen and the server input evaluator.
/// Time means elapsed milliseconds since a server-issued lesson began. Rendering
/// a frame never changes the score, challenge, or timing window.
class SchoolLessonGame {
  SchoolLessonGame({
    required this.kind,
    required int seed,
    this.mentor = false,
    this.durationMs = 20000,
  }) : _random = Random(seed) {
    target = _random.nextInt(switch (kind) {
      DragonSchoolGameKind.crystalChase => 9,
      DragonSchoolGameKind.cloudWeave => 3,
      _ => 6,
    });
    shadowDifference = _random.nextInt(4);
    expected = kind == DragonSchoolGameKind.constellationTrace ? 0 : 1;
    order.shuffle(_random);
    constellationOrder.shuffle(_random);
    runePoint = _random.nextInt(9);
    if (kind == DragonSchoolGameKind.emberReflex) _scheduleReflex();
    if (kind == DragonSchoolGameKind.sigilMemory) _scheduleMemory();
  }

  final DragonSchoolGameKind kind;
  final bool mentor;
  final int durationMs;
  final Random _random;
  int elapsedMs = 0, score = 0, target = 0, shadowDifference = 0, expected = 1;
  int runePoint = 0, reaction = 0, _reactionUntil = 0, _cueAt = 0, _hideAt = 0;
  final inputs = <SchoolTap>[];
  int _lastInputAt = -25;
  final order = [1, 2, 3, 4, 5, 6];
  final constellationOrder = [0, 1, 2, 3, 4, 5];
  bool mentorShieldUsed = false;
  bool get finished => elapsedMs >= durationMs;
  bool get cueReady => elapsedMs >= _cueAt;
  bool get memoryVisible => elapsedMs < _hideAt;
  int get remainingMs => max(0, durationMs - elapsedMs);
  double get phase => (elapsedMs * .0004) % 1;

  void advanceTo(int milliseconds) {
    if (milliseconds < elapsedMs) {
      throw const FormatException('input_time_reversed');
    }
    elapsedMs = milliseconds;
    if (elapsedMs >= _reactionUntil) reaction = 0;
  }

  /// A real button identity, never a claimed success/score. Rune Rush records
  /// the visible rune position, so an old queued tap cannot hit the next rune.
  void tap(int index, int milliseconds) {
    advanceTo(milliseconds);
    if (finished || milliseconds - _lastInputAt < 25) return;
    final count = switch (kind) {
      DragonSchoolGameKind.runeRush || DragonSchoolGameKind.crystalChase => 9,
      DragonSchoolGameKind.cloudWeave => 3,
      DragonSchoolGameKind.emberReflex ||
      DragonSchoolGameKind.breathBalance =>
        1,
      _ => 6,
    };
    if (index < 0 || index >= count) {
      throw const FormatException('input_target_invalid');
    }
    _lastInputAt = milliseconds;
    inputs.add(SchoolTap(milliseconds, index));
    switch (kind) {
      case DragonSchoolGameKind.runeRush:
        if (index != runePoint) {
          _mistake();
          break;
        }
        _correct();
        runePoint = _random.nextInt(9);
      case DragonSchoolGameKind.crystalChase:
        index == target ? _correct() : _mistake();
        target = _random.nextInt(9);
      case DragonSchoolGameKind.emberReflex:
        if (cueReady) {
          _correct();
          _scheduleReflex();
        } else {
          _mistake();
        }
      case DragonSchoolGameKind.sigilMemory:
        if (memoryVisible) return;
        index == target ? _correct(2) : _mistake();
        _scheduleMemory();
      case DragonSchoolGameKind.scaleOrder:
        if (order[index] == expected) {
          _correct();
          expected++;
          if (expected > 6) {
            expected = 1;
            order.shuffle(_random);
          }
        } else {
          _mistake();
          expected = 1;
        }
      case DragonSchoolGameKind.shadowMatch:
        index == target ? _correct(2) : _mistake();
        target = _differentTarget(target, 6);
        shadowDifference = _random.nextInt(4);
      case DragonSchoolGameKind.breathBalance:
        (phase - .5).abs() < .12 ? _correct(2) : _mistake();
      case DragonSchoolGameKind.cloudWeave:
        index == target ? _correct() : _mistake();
        target = _differentTarget(target, 3);
      case DragonSchoolGameKind.safeHoard:
        index == target ? _mistake(penalty: 2) : _correct();
        target = _differentTarget(target, 6);
      case DragonSchoolGameKind.constellationTrace:
        if (index == constellationOrder[expected]) {
          _correct();
          expected++;
          if (expected >= constellationOrder.length) {
            expected = 0;
            constellationOrder.shuffle(_random);
          }
        } else {
          _mistake();
          expected = 0;
        }
    }
  }

  void _scheduleReflex() => _cueAt = elapsedMs + 600 + _random.nextInt(900);
  void _scheduleMemory() {
    target = _random.nextInt(6);
    _hideAt = elapsedMs + 820;
  }

  void _correct([int points = 1]) {
    score += points;
    reaction = 1;
    _reactionUntil = elapsedMs + 430;
  }

  void _mistake({int penalty = 1}) {
    if (mentor && !mentorShieldUsed) {
      mentorShieldUsed = true;
      reaction = 2;
    } else {
      score = max(0, score - penalty);
      reaction = -1;
    }
    _reactionUntil = elapsedMs + 430;
  }

  int _differentTarget(int current, int count) {
    var next = _random.nextInt(count);
    while (next == current) {
      next = _random.nextInt(count);
    }
    return next;
  }
}
