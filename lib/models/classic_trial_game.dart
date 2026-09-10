import 'dart:math';

import 'trial.dart';
import 'trial_random.dart';

class FlightObstacle {
  FlightObstacle(
      {required this.x,
      required this.gap,
      required this.halfGap,
      required this.crystal,
      required this.moving,
      required this.phase});
  double x;
  final double gap, halfGap, phase;
  final bool crystal, moving;
  bool passed = false;
  double gapAt(double elapsed) =>
      (gap + (moving ? sin(elapsed * 1.4 + phase) * .045 : 0)).clamp(.23, .77);
}

/// One fixed simulation step on every device and in the server evaluator.
/// Collision geometry uses a reference arena, independent of physical pixels.
class CavernFlightGame {
  CavernFlightGame({required int seed, required int spirit, Random? random})
      : _random = random ?? Random(seed),
        hitboxScale = cavernFlightHitboxScale(spirit) {
    obstacles.addAll(List.generate(3, (i) => _newObstacle(1.15 + i * .58)));
  }
  final Random _random;
  final double hitboxScale;
  final obstacles = <FlightObstacle>[];
  int milliseconds = 0, passed = 0;
  double dragonY = .5, velocity = -.58;
  bool ended = false;
  double get elapsed => milliseconds / 1000;
  int get score => (elapsed * 10).floor() + passed * 25;

  Map<String, dynamic> checkpoint() => {
        'random': (_random as TrialRandom).state,
        'milliseconds': milliseconds,
        'passed': passed,
        'dragonY': dragonY,
        'velocity': velocity,
        'ended': ended,
        'obstacles': [
          for (final obstacle in obstacles)
            {
              'x': obstacle.x,
              'gap': obstacle.gap,
              'halfGap': obstacle.halfGap,
              'crystal': obstacle.crystal,
              'moving': obstacle.moving,
              'phase': obstacle.phase,
              'passed': obstacle.passed,
            }
        ],
      };

  factory CavernFlightGame.fromCheckpoint(Map<String, dynamic> state,
      {required int spirit}) {
    final random = TrialRandom(state['random'] as int);
    final game = CavernFlightGame(seed: 1, spirit: spirit, random: random);
    random.state = state['random'] as int;
    game.milliseconds = state['milliseconds'] as int;
    game.passed = state['passed'] as int;
    game.dragonY = (state['dragonY'] as num).toDouble();
    game.velocity = (state['velocity'] as num).toDouble();
    game.ended = state['ended'] as bool;
    game.obstacles.clear();
    for (final entry in state['obstacles'] as List) {
      final obstacle = FlightObstacle(
          x: (entry['x'] as num).toDouble(),
          gap: (entry['gap'] as num).toDouble(),
          halfGap: (entry['halfGap'] as num).toDouble(),
          crystal: entry['crystal'] as bool,
          moving: entry['moving'] as bool,
          phase: (entry['phase'] as num).toDouble());
      obstacle.passed = entry['passed'] as bool;
      game.obstacles.add(obstacle);
    }
    return game;
  }

  FlightObstacle _newObstacle(double x) => FlightObstacle(
      x: x,
      gap: .30 + _random.nextDouble() * .40,
      halfGap: .19 - min(passed, 10) * .0035,
      crystal: _random.nextBool(),
      moving: passed >= 4 && _random.nextInt(4) == 0,
      phase: _random.nextDouble() * pi * 2);

  void advanceTo(int at) {
    final target = at ~/ 10 * 10;
    while (milliseconds < target && !ended) {
      milliseconds += 10;
      velocity += 1.55 * .01;
      dragonY += velocity * .01;
      final speed = .27 + min(elapsed / 120, .12);
      for (final obstacle in obstacles) {
        obstacle.x -= speed * .01;
        if (!obstacle.passed && obstacle.x < .20) {
          obstacle.passed = true;
          passed++;
        }
      }
      if (obstacles.first.x < -.20) obstacles.removeAt(0);
      if (obstacles.last.x < .82) {
        obstacles.add(_newObstacle(obstacles.last.x + .58));
      }
      final halfWidth = 43 * hitboxScale / 720;
      final halfHeight = 31 * hitboxScale / 1200;
      if (dragonY - halfHeight <= 0 || dragonY + halfHeight >= 1) {
        ended = true;
      } else {
        for (final obstacle in obstacles) {
          if (.24 + halfWidth < obstacle.x ||
              .24 - halfWidth > obstacle.x + .13) {
            continue;
          }
          final gap = obstacle.gapAt(elapsed);
          if (dragonY - halfHeight < gap - obstacle.halfGap ||
              dragonY + halfHeight > gap + obstacle.halfGap) {
            ended = true;
            break;
          }
        }
      }
    }
  }

  void flap(int at) {
    advanceTo(at);
    if (!ended) velocity = -.58;
  }
}

class RuinBreakerGame {
  RuinBreakerGame({required this.might});
  final int might;
  static const basePoints = [100, 140, 190, 250, 340];
  int milliseconds = 0,
      roundStartedAt = 0,
      round = 0,
      score = 0,
      combo = 0,
      misses = 0;
  int? lockedUntil;
  bool ended = false;
  String feedback = '';
  bool get locked => lockedUntil != null;
  bool get isGap => round > 0 && (round + 1) % 6 == 0;
  double get meter => locked
      ? _struckMeter
      : (sin((milliseconds - roundStartedAt) /
                      1000 *
                      (1.8 + min(round * .10, 2.2)) -
                  pi / 2) +
              1) /
          2;
  double _struckMeter = 0;

  Map<String, dynamic> checkpoint() => {
        'milliseconds': milliseconds,
        'roundStartedAt': roundStartedAt,
        'round': round,
        'score': score,
        'combo': combo,
        'misses': misses,
        'lockedUntil': lockedUntil,
        'ended': ended,
        'feedback': feedback,
        'struckMeter': _struckMeter,
      };

  factory RuinBreakerGame.fromCheckpoint(Map<String, dynamic> state,
      {required int might}) {
    final game = RuinBreakerGame(might: might);
    game.milliseconds = state['milliseconds'] as int;
    game.roundStartedAt = state['roundStartedAt'] as int;
    game.round = state['round'] as int;
    game.score = state['score'] as int;
    game.combo = state['combo'] as int;
    game.misses = state['misses'] as int;
    game.lockedUntil = state['lockedUntil'] as int?;
    game.ended = state['ended'] as bool;
    game.feedback = state['feedback'] as String;
    game._struckMeter = (state['struckMeter'] as num).toDouble();
    return game;
  }

  void advanceTo(int at) {
    if (at < milliseconds || ended) return;
    milliseconds = at;
    if (lockedUntil != null && at >= lockedUntil!) {
      roundStartedAt = lockedUntil!;
      lockedUntil = null;
      round++;
      if (misses >= 3 || round >= 30) ended = true;
    }
  }

  bool strike(int at) {
    advanceTo(at);
    if (ended || locked) return false;
    final distance = (meter - .5).abs();
    _struckMeter = meter;
    lockedUntil = at + 330;
    final base = isGap ? 210 : basePoints[round % basePoints.length];
    if (distance <= .045 * ruinBreakerPerfectZoneScale(might)) {
      combo++;
      score += (base * (1 + min(combo, 8) * .15)).round();
      feedback = combo >= 4 ? 'SMASH STREAK x$combo!' : 'PERFECT x$combo!';
    } else if (distance <= .18 * ruinBreakerSuccessZoneScale(might)) {
      combo = 0;
      score += (base * .60).round();
      feedback = isGap ? 'CLEAR!' : 'SMASH!';
    } else {
      combo = 0;
      misses++;
      feedback = isGap ? 'MISSED JUMP!' : 'GLANCING HIT!';
    }
    return true;
  }
}

class RuneweaverGame {
  RuneweaverGame({required int seed, required this.arcana, Random? random})
      : _random = random ?? Random(seed);
  final Random _random;
  final int arcana;
  final sequence = <int>[];
  List<int> positions = [0, 1, 2, 3, 4];
  int milliseconds = 0, rounds = 0, inputIndex = 0;
  int? wrongRune, echoRune;
  bool ended = false, echoUsed = false;
  int? _nextRoundAt = 500;
  int _roundAt = 500, _acceptAt = 0, _litUntil = 0;
  int? _pressedRune;
  int get visibleMs => runeweaverRuneDuration(arcana).inMilliseconds;
  bool get showing =>
      !ended && _nextRoundAt == null && milliseconds < _acceptAt;
  bool get accepting =>
      !ended && _nextRoundAt == null && milliseconds >= _acceptAt;
  int? get litRune {
    if (wrongRune != null) return wrongRune;
    if (showing) {
      final offset = milliseconds - _roundAt;
      final index = offset ~/ (visibleMs + 150);
      return index < sequence.length && offset % (visibleMs + 150) < visibleMs
          ? sequence[index]
          : null;
    }
    return milliseconds < _litUntil ? _pressedRune : null;
  }

  Map<String, dynamic> checkpoint() => {
        'random': (_random as TrialRandom).state,
        'sequence': List.of(sequence),
        'positions': List.of(positions),
        'milliseconds': milliseconds,
        'rounds': rounds,
        'inputIndex': inputIndex,
        'wrongRune': wrongRune,
        'echoRune': echoRune,
        'ended': ended,
        'echoUsed': echoUsed,
        'nextRoundAt': _nextRoundAt,
        'roundAt': _roundAt,
        'acceptAt': _acceptAt,
        'litUntil': _litUntil,
        'pressedRune': _pressedRune,
      };

  factory RuneweaverGame.fromCheckpoint(Map<String, dynamic> state,
      {required int arcana}) {
    final game = RuneweaverGame(
        seed: 1, arcana: arcana, random: TrialRandom(state['random'] as int));
    game.sequence.addAll(List<int>.from(state['sequence'] as List));
    game.positions = List<int>.from(state['positions'] as List);
    game.milliseconds = state['milliseconds'] as int;
    game.rounds = state['rounds'] as int;
    game.inputIndex = state['inputIndex'] as int;
    game.wrongRune = state['wrongRune'] as int?;
    game.echoRune = state['echoRune'] as int?;
    game.ended = state['ended'] as bool;
    game.echoUsed = state['echoUsed'] as bool;
    game._nextRoundAt = state['nextRoundAt'] as int?;
    game._roundAt = state['roundAt'] as int;
    game._acceptAt = state['acceptAt'] as int;
    game._litUntil = state['litUntil'] as int;
    game._pressedRune = state['pressedRune'] as int?;
    return game;
  }

  void advanceTo(int at) {
    if (at < milliseconds || ended) return;
    milliseconds = at;
    if (_nextRoundAt != null && at >= _nextRoundAt!) {
      _roundAt = _nextRoundAt!;
      _nextRoundAt = null;
      sequence.add(_random.nextInt(5));
      inputIndex = 0;
      echoRune = null;
      _acceptAt = _roundAt + sequence.length * (visibleMs + 150);
      if (rounds >= 6) positions = [...positions]..shuffle(_random);
      if (!echoUsed && rounds >= 3 && arcana >= 240) {
        echoRune = sequence.last;
        echoUsed = true;
      }
    }
  }

  bool tap(int rune, int at) {
    advanceTo(at);
    if (!accepting || rune < 0 || rune > 4) return false;
    echoRune = null;
    _pressedRune = rune;
    _litUntil = at + 150;
    if (rune != sequence[inputIndex]) {
      wrongRune = rune;
      ended = true;
    } else {
      inputIndex++;
      if (inputIndex == sequence.length) {
        rounds++;
        _nextRoundAt = at + 800;
      }
    }
    return true;
  }
}
