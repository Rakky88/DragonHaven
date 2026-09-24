import 'dart:math';

import 'trial.dart';
import 'trial_random.dart';

enum SpiritAlignmentPhase { vertical, horizontal, result }

enum SpiritAlignmentShape { circle, square, triangle }

typedef _AlignmentPoint = ({double x, double y});

/// A square logical arena shared verbatim by the model and renderer. Positions
/// are fractions of the available travel after the shape itself is reserved.
abstract final class SpiritAlignmentGeometry {
  static const double shapeExtent = .18;
  static const double travelExtent = 1 - shapeExtent;
  static const double snapTolerance = .004;

  static double arenaPosition(double normalized, double arenaExtent) =>
      normalized * arenaExtent * travelExtent;

  static double shapePixels(double arenaExtent) => arenaExtent * shapeExtent;

  static double offsetInShapeUnits(double from, double to) =>
      (from - to) * travelExtent / shapeExtent;
}

/// Two-tap shape alignment. A round only continues when all three percentages
/// displayed to the player are exactly 100.
class SpiritAlignmentGame {
  SpiritAlignmentGame(
      {required int seed, required int spirit, TrialRandom? random})
      : _random = random ?? TrialRandom(seed),
        _assist = 1 - cavernFlightHitboxScale(spirit);

  final TrialRandom _random;
  final double _assist;
  int milliseconds = 0, round = 1, shapeIndex = 0, score = 0;
  int phaseStartedAt = 0;
  int? resultUntil;
  double lockedY = .5, stoppedX = .14;
  final roundOverlaps = <int>[];
  SpiritAlignmentPhase phase = SpiritAlignmentPhase.vertical;
  bool ended = false;

  SpiritAlignmentShape get shape => SpiritAlignmentShape.values[shapeIndex];
  double get roundSpeed => pow(1.1, round - 1).toDouble();
  double get playerY => phase == SpiritAlignmentPhase.vertical
      ? .18 +
          _triangle(milliseconds - phaseStartedAt,
                  2200 * (1 + _assist * .8) / roundSpeed) *
              .64
      : lockedY;
  double get playerX => phase == SpiritAlignmentPhase.horizontal
      ? .14 +
          _triangle(milliseconds - phaseStartedAt,
                  1900 * (1 + _assist * .8) / roundSpeed) *
              .70
      : stoppedX;
  // The outline stays in the middle while the shape first travels vertically
  // at the left and then crosses it horizontally in both directions.
  double get targetX => .5;
  double get targetY => .5;
  int? get latestOverlap => roundOverlaps.isEmpty ? null : roundOverlaps.last;
  bool get waitingForResult => phase == SpiritAlignmentPhase.result;

  static double _triangle(int elapsedMs, double periodMs) {
    final progress = (elapsedMs / periodMs) % 2;
    return progress <= 1 ? progress : 2 - progress;
  }

  static int overlapPercent(
    SpiritAlignmentShape shape, {
    required double playerX,
    required double playerY,
    double targetX = .5,
    double targetY = .5,
  }) {
    final dx = SpiritAlignmentGeometry.offsetInShapeUnits(playerX, targetX);
    final dy = SpiritAlignmentGeometry.offsetInShapeUnits(playerY, targetY);
    if (dx.abs() <= 1e-10 && dy.abs() <= 1e-10) return 100;
    final fraction = switch (shape) {
      SpiritAlignmentShape.square =>
        max(0.0, 1 - dx.abs()) * max(0.0, 1 - dy.abs()),
      SpiritAlignmentShape.circle => _circleOverlap(dx, dy),
      SpiritAlignmentShape.triangle => _triangleOverlap(dx, dy),
    };
    // Only actual full alignment returns 100. A partial geometric overlap that
    // rounds upward remains visibly partial.
    return (fraction * 100).round().clamp(0, 99);
  }

  static double _circleOverlap(double dx, double dy) {
    final distance = sqrt(dx * dx + dy * dy);
    if (distance >= 1) return 0;
    const radius = .5;
    final area = 2 * radius * radius * acos(distance / (2 * radius)) -
        .5 * distance * sqrt(4 * radius * radius - distance * distance);
    return (area / (pi * radius * radius)).clamp(0, 1);
  }

  static double _triangleOverlap(double dx, double dy) {
    const target = <_AlignmentPoint>[
      (x: .5, y: 0),
      (x: 1, y: 1),
      (x: 0, y: 1),
    ];
    var intersection = <_AlignmentPoint>[
      for (final point in target) (x: point.x + dx, y: point.y + dy),
    ];
    for (var edge = 0;
        edge < target.length && intersection.isNotEmpty;
        edge++) {
      final a = target[edge];
      final b = target[(edge + 1) % target.length];
      final input = intersection;
      intersection = <_AlignmentPoint>[];
      var start = input.last;
      for (final end in input) {
        final startInside = _insideTriangleEdge(start, a, b);
        final endInside = _insideTriangleEdge(end, a, b);
        if (endInside) {
          if (!startInside) {
            intersection.add(_edgeIntersection(start, end, a, b));
          }
          intersection.add(end);
        } else if (startInside) {
          intersection.add(_edgeIntersection(start, end, a, b));
        }
        start = end;
      }
    }
    return (_polygonArea(intersection) / .5).clamp(0, 1);
  }

  static bool _insideTriangleEdge(
          _AlignmentPoint point, _AlignmentPoint a, _AlignmentPoint b) =>
      _cross(b.x - a.x, b.y - a.y, point.x - a.x, point.y - a.y) >= -1e-12;

  static _AlignmentPoint _edgeIntersection(_AlignmentPoint start,
      _AlignmentPoint end, _AlignmentPoint a, _AlignmentPoint b) {
    final edgeX = b.x - a.x;
    final edgeY = b.y - a.y;
    final moveX = end.x - start.x;
    final moveY = end.y - start.y;
    final denominator = _cross(edgeX, edgeY, moveX, moveY);
    if (denominator.abs() <= 1e-14) return end;
    final t = -_cross(edgeX, edgeY, start.x - a.x, start.y - a.y) / denominator;
    return (x: start.x + moveX * t, y: start.y + moveY * t);
  }

  static double _cross(double ax, double ay, double bx, double by) =>
      ax * by - ay * bx;

  static double _polygonArea(List<_AlignmentPoint> points) {
    if (points.length < 3) return 0;
    var twiceArea = 0.0;
    for (var i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      twiceArea += a.x * b.y - a.y * b.x;
    }
    return twiceArea.abs() / 2;
  }

  void advanceTo(int at) {
    if (at < milliseconds) throw const FormatException('input_reversed');
    if (ended) return;
    milliseconds = at;
    if (phase != SpiritAlignmentPhase.result ||
        resultUntil == null ||
        at < resultUntil!) {
      return;
    }
    final nextAt = resultUntil!;
    if (shapeIndex == SpiritAlignmentShape.values.length - 1) {
      if (roundOverlaps.length == 3 &&
          roundOverlaps.every((value) => value == 100)) {
        round++;
        shapeIndex = 0;
        roundOverlaps.clear();
      } else {
        ended = true;
        return;
      }
    } else {
      shapeIndex++;
    }
    phase = SpiritAlignmentPhase.vertical;
    phaseStartedAt = nextAt;
    resultUntil = null;
    stoppedX = .14;
  }

  bool tap(int at) {
    advanceTo(at);
    if (ended || waitingForResult) return false;
    if (phase == SpiritAlignmentPhase.vertical) {
      final currentY = playerY;
      lockedY =
          (currentY - targetY).abs() <= SpiritAlignmentGeometry.snapTolerance
              ? targetY
              : currentY;
      stoppedX = .14;
      phase = SpiritAlignmentPhase.horizontal;
      phaseStartedAt = at;
      return true;
    }
    final currentX = playerX;
    stoppedX =
        (currentX - targetX).abs() <= SpiritAlignmentGeometry.snapTolerance
            ? targetX
            : currentX;
    final overlap = overlapPercent(
      shape,
      playerX: stoppedX,
      playerY: lockedY,
      targetX: targetX,
      targetY: targetY,
    );
    roundOverlaps.add(overlap);
    score += overlap;
    phase = SpiritAlignmentPhase.result;
    resultUntil = at + 700;
    return true;
  }

  Map<String, dynamic> checkpoint() => {
        'version': 1,
        'random': _random.state,
        'milliseconds': milliseconds,
        'round': round,
        'shapeIndex': shapeIndex,
        'score': score,
        'phase': phase.index,
        'phaseStartedAt': phaseStartedAt,
        'resultUntil': resultUntil,
        'lockedY': lockedY,
        'stoppedX': stoppedX,
        'targetY': targetY,
        'roundOverlaps': List.of(roundOverlaps),
        'ended': ended,
      };

  factory SpiritAlignmentGame.fromCheckpoint(Map<String, dynamic> state,
      {required int spirit}) {
    if (state['version'] != 1) {
      throw const FormatException('spirit_alignment_checkpoint_invalid');
    }
    final random = TrialRandom(state['random'] as int);
    final game = SpiritAlignmentGame(seed: 1, spirit: spirit, random: random);
    random.state = state['random'] as int;
    game.milliseconds = state['milliseconds'] as int;
    game.round = state['round'] as int;
    game.shapeIndex = state['shapeIndex'] as int;
    game.score = state['score'] as int;
    game.phase = SpiritAlignmentPhase.values[state['phase'] as int];
    game.phaseStartedAt = state['phaseStartedAt'] as int;
    game.resultUntil = state['resultUntil'] as int?;
    game.lockedY = (state['lockedY'] as num).toDouble();
    game.stoppedX = (state['stoppedX'] as num).toDouble();
    // Version 1 used to persist a random target height. The outline is now
    // fixed at the exact centre; accept that field for checkpoint compatibility
    // but never let an imported value move the authoritative target.
    if (state['targetY'] is! num) {
      throw const FormatException('spirit_alignment_checkpoint_invalid');
    }
    game.roundOverlaps
      ..clear()
      ..addAll(List<int>.from(state['roundOverlaps'] as List));
    game.ended = state['ended'] as bool;
    return game;
  }
}

/// A one-touch, three-lane guard game. Taps cycle the dragon's lane; impacts
/// resolve from the authoritative clock.
class RuinGuardGame {
  RuinGuardGame({required int seed, required this.might, TrialRandom? random})
      : _random = random ?? TrialRandom(seed) {
    targetLane = _random.nextInt(3);
  }

  final TrialRandom _random;
  final int might;
  int milliseconds = 0, roundStartedAt = 0, round = 0, score = 0;
  int combo = 0, misses = 0, playerLane = 1, targetLane = 1;
  int? lockedUntil;
  bool ended = false;
  String feedback = '';

  bool get locked => lockedUntil != null;
  double get speedMultiplier => pow(1.08, round ~/ 3).toDouble();
  int get fallDurationMs =>
      (1850 * (1 + max(0, might) / 10000) / speedMultiplier).round();
  double get boulderProgress => locked
      ? 1
      : ((milliseconds - roundStartedAt) / fallDurationMs).clamp(0, 1);

  void advanceTo(int at) {
    if (at < milliseconds) throw const FormatException('input_reversed');
    if (ended) return;
    while (!ended) {
      if (lockedUntil case final unlockAt?) {
        if (at < unlockAt) {
          milliseconds = at;
          return;
        }
        milliseconds = unlockAt;
        roundStartedAt = unlockAt;
        lockedUntil = null;
        round++;
        if (misses >= 3) {
          ended = true;
          return;
        }
        targetLane = _random.nextInt(3);
        feedback = '';
        continue;
      }
      final impactAt = roundStartedAt + fallDurationMs;
      if (at < impactAt) {
        milliseconds = at;
        return;
      }
      milliseconds = impactAt;
      final guarded = playerLane == targetLane;
      if (guarded) {
        combo++;
        score += 100 + min(combo, 12) * 12;
        feedback = combo >= 4 ? 'GUARD STREAK x$combo!' : 'SHATTERED!';
      } else {
        combo = 0;
        misses++;
        feedback = 'MISSED!';
      }
      lockedUntil = impactAt + 420;
    }
  }

  bool tap(int at) {
    advanceTo(at);
    if (ended || locked) return false;
    playerLane = (playerLane + 1) % 3;
    return true;
  }

  Map<String, dynamic> checkpoint() => {
        'version': 1,
        'random': _random.state,
        'milliseconds': milliseconds,
        'roundStartedAt': roundStartedAt,
        'round': round,
        'score': score,
        'combo': combo,
        'misses': misses,
        'playerLane': playerLane,
        'targetLane': targetLane,
        'lockedUntil': lockedUntil,
        'ended': ended,
        'feedback': feedback,
      };

  factory RuinGuardGame.fromCheckpoint(Map<String, dynamic> state,
      {required int might}) {
    if (state['version'] != 1) {
      throw const FormatException('ruin_guard_checkpoint_invalid');
    }
    final random = TrialRandom(state['random'] as int);
    final game = RuinGuardGame(seed: 1, might: might, random: random);
    random.state = state['random'] as int;
    game.milliseconds = state['milliseconds'] as int;
    game.roundStartedAt = state['roundStartedAt'] as int;
    game.round = state['round'] as int;
    game.score = state['score'] as int;
    game.combo = state['combo'] as int;
    game.misses = state['misses'] as int;
    game.playerLane = state['playerLane'] as int;
    game.targetLane = state['targetLane'] as int;
    game.lockedUntil = state['lockedUntil'] as int?;
    game.ended = state['ended'] as bool;
    game.feedback = state['feedback'] as String;
    return game;
  }
}

/// Five runes orbit a golden gate. Tap anywhere to capture the rune currently
/// in the gate and match it to the target shown in the center.
class RuneOrbitGame {
  RuneOrbitGame({required int seed, required this.arcana, TrialRandom? random})
      : _random = random ?? TrialRandom(seed);

  final TrialRandom _random;
  final int arcana;
  int milliseconds = 0, rounds = 0, misses = 0, targetRune = 0;
  int roundStartedAt = 500;
  int? nextRoundAt = 500;
  bool ended = false;

  int get visibleMs => (720 * (1 + max(0, arcana) / 10000) / pow(1.045, rounds))
      .round()
      .clamp(260, 800);
  bool get accepting => !ended && nextRoundAt == null;
  int get gateRune => ((milliseconds - roundStartedAt) ~/ visibleMs) % 5;

  void advanceTo(int at) {
    if (at < milliseconds) throw const FormatException('input_reversed');
    if (ended) return;
    milliseconds = at;
    if (nextRoundAt != null && at >= nextRoundAt!) {
      roundStartedAt = nextRoundAt!;
      nextRoundAt = null;
      targetRune = _random.nextInt(5);
    }
  }

  bool tap(int rune, int at) {
    advanceTo(at);
    if (!accepting || rune < 0 || rune > 4 || rune != gateRune) return false;
    if (rune == targetRune) {
      rounds++;
    } else {
      misses++;
      if (misses >= 3) ended = true;
    }
    if (!ended) nextRoundAt = at + 420;
    return true;
  }

  Map<String, dynamic> checkpoint() => {
        'version': 1,
        'random': _random.state,
        'milliseconds': milliseconds,
        'rounds': rounds,
        'misses': misses,
        'targetRune': targetRune,
        'roundStartedAt': roundStartedAt,
        'nextRoundAt': nextRoundAt,
        'ended': ended,
      };

  factory RuneOrbitGame.fromCheckpoint(Map<String, dynamic> state,
      {required int arcana}) {
    if (state['version'] != 1) {
      throw const FormatException('rune_orbit_checkpoint_invalid');
    }
    final random = TrialRandom(state['random'] as int);
    final game = RuneOrbitGame(seed: 1, arcana: arcana, random: random);
    random.state = state['random'] as int;
    game.milliseconds = state['milliseconds'] as int;
    game.rounds = state['rounds'] as int;
    game.misses = state['misses'] as int;
    game.targetRune = state['targetRune'] as int;
    game.roundStartedAt = state['roundStartedAt'] as int;
    game.nextRoundAt = state['nextRoundAt'] as int?;
    game.ended = state['ended'] as bool;
    return game;
  }
}
