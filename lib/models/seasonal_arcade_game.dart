import 'dart:math';

import 'seasonal_minigame.dart';
import 'trial.dart';
import 'trial_input.dart';

class ArcadeAction {
  const ArcadeAction(this.correct, {this.points = 100, this.complete = true});
  final bool correct, complete;
  final int points;
}

class ChimeNote {
  const ChimeNote(this.id, this.lane, this.strikeAt, this.travel);
  final int id, lane;
  final double strikeAt, travel;
}

class GiftParcel {
  const GiftParcel(this.id, this.type, this.born, this.duration);
  final int id, type;
  final double born, duration;
}

/// The four puzzle/rhythm games share deterministic rules with server replay.
/// Input timestamps advance a fixed 10 ms clock; rendering cannot change notes,
/// deadlines, collision order, cooldowns or puzzle rewards.
class SeasonalArcadeGame {
  SeasonalArcadeGame({
    required this.kind,
    required int seed,
    double might = 0,
    double arcana = 0,
    double spirit = 0,
  })  : _random = Random(seed),
        might = might.clamp(0, 1),
        spirit = spirit.clamp(0, 1),
        hints = 1 + (arcana.clamp(0, 1) * 2).floor() {
    if (!const {
      TrialKind.hollyfrostGiftforge,
      TrialKind.midnightChime,
      TrialKind.rosevowRelay,
      TrialKind.prismaticParade,
    }.contains(kind)) {
      throw ArgumentError.value(kind, 'kind');
    }
    _melodyPhrase = kind == TrialKind.midnightChime ? _random.nextInt(4) : 0;
    _newPuzzle();
  }

  final TrialKind kind;
  final Random _random;
  final double might, spirit;
  final parcels = <GiftParcel>[];
  final notes = <ChimeNote>[];
  final laneReadyAt = <int, double>{};
  final flares = <int, double>{};
  final _actions = <ArcadeAction>[];
  late HeartMaze maze;
  late PrismCircuit prisms;
  late final int _melodyPhrase;
  int _milliseconds = 0, _parcelId = 0, _noteId = 0, _beat = 0;
  int mistakes = 0, hints;
  int? errorCell, prismHint;
  HeartDirection? hint;
  double readyAt = 0, _nextParcel = 0, _nextNote = 0;
  double get time => _milliseconds / 1000;
  double get chimeWindow => .18 + might * .07;
  bool get lost => mistakes >= 3;
  bool get canInput => !lost && time >= readyAt;

  List<ArcadeAction> takeActions() {
    final result = List<ArcadeAction>.of(_actions);
    _actions.clear();
    return result;
  }

  void _report(bool correct, {int points = 100, bool complete = true}) {
    if (lost) return;
    if (!correct &&
        (kind == TrialKind.hollyfrostGiftforge ||
            kind == TrialKind.midnightChime)) {
      mistakes++;
    }
    _actions.add(ArcadeAction(correct, points: points, complete: complete));
  }

  void _spawnParcel(double born, {int? type}) {
    parcels.add(GiftParcel(_parcelId++, type ?? _random.nextInt(3), born,
        SeasonalArcadePacing.parcelLifetime(born, might)));
    _nextParcel = born + SeasonalArcadePacing.parcelInterval(born);
  }

  void _newPuzzle() {
    hint = null;
    prismHint = null;
    errorCell = null;
    final symbol = _random.nextInt(3);
    if (kind == TrialKind.hollyfrostGiftforge) _spawnParcel(time, type: symbol);
    if (kind == TrialKind.rosevowRelay) maze = HeartMaze.generate(_random);
    if (kind == TrialKind.prismaticParade) {
      prisms = PrismCircuit.generate(_random);
    }
  }

  void advanceTo(int milliseconds) {
    // These four games end by 78 s, including maximum expertise assistance.
    final target = min(milliseconds, 78000) ~/ 10 * 10;
    while (_milliseconds < target && !lost) {
      _milliseconds += 10;
      flares.removeWhere((_, until) => until <= time);
      if (time >= readyAt) errorCell = null;
      if (kind == TrialKind.hollyfrostGiftforge) {
        while (_nextParcel <= time && parcels.length < 8) {
          _spawnParcel(_nextParcel);
        }
        final expired =
            parcels.where((p) => time > p.born + p.duration).toList();
        for (final parcel in expired) {
          parcels.remove(parcel);
          _report(false);
          if (lost) break;
        }
      }
      if (kind == TrialKind.midnightChime) {
        final expired =
            notes.where((n) => time > n.strikeAt + chimeWindow).toList();
        for (final note in expired) {
          notes.remove(note);
          _report(false);
          if (lost) break;
        }
        if (!lost && time >= _nextNote) {
          final travel = SeasonalArcadePacing.chimeTravel(time, spirit);
          for (final lane
              in SeasonalArcadePacing.chimeLanes(_beat, time, _melodyPhrase)) {
            notes.add(ChimeNote(_noteId++, lane, time + travel, travel));
          }
          _nextNote = time +
              SeasonalArcadePacing.chimeBeat(time) *
                  (_beat % 16 == 15 ? 1.5 : 1);
          _beat++;
        }
      }
    }
  }

  void applyInput(TrialInput input) {
    if (input.milliseconds < _milliseconds) {
      throw const FormatException('input_reversed');
    }
    advanceTo(input.milliseconds);
    switch (input.control) {
      case TrialControl.deliverGift when kind == TrialKind.hollyfrostGiftforge:
        if (input.a < 0 || input.b < 0 || input.b > 2) {
          throw const FormatException('input_invalid');
        }
        deliver(input.a, input.b);
      case TrialControl.strikeChime when kind == TrialKind.midnightChime:
        if (input.a < 0 || input.a > 3 || input.b != 0) {
          throw const FormatException('input_invalid');
        }
        strike(input.a);
      case TrialControl.moveHearts when kind == TrialKind.rosevowRelay:
        if (input.a < 0 || input.a > 3 || input.b != 0) {
          throw const FormatException('input_invalid');
        }
        move(HeartDirection.values[input.a]);
      case TrialControl.rotatePrism when kind == TrialKind.prismaticParade:
        if (input.a < 0 || input.a > 15 || input.b != 0) {
          throw const FormatException('input_invalid');
        }
        rotatePrism(input.a);
      case TrialControl.requestHint
          when kind == TrialKind.rosevowRelay ||
              kind == TrialKind.prismaticParade:
        if (input.a != 0 || input.b != 0) {
          throw const FormatException('input_invalid');
        }
        requestHint();
      default:
        throw const FormatException('input_control_invalid');
    }
  }

  void deliver(int parcelId, int bay) {
    if (!canInput ||
        kind != TrialKind.hollyfrostGiftforge ||
        bay < 0 ||
        bay > 2) {
      return;
    }
    final parcel = parcels.where((p) => p.id == parcelId).firstOrNull;
    if (parcel == null) return;
    parcels.remove(parcel);
    _report(bay == parcel.type, points: 120);
  }

  /// Returns the hit status for the optional lane sound; null means no input.
  bool? strike(int lane) {
    if (!canInput ||
        kind != TrialKind.midnightChime ||
        lane < 0 ||
        lane > 3 ||
        time < (laneReadyAt[lane] ?? 0)) {
      return null;
    }
    final candidates = notes.where((n) => n.lane == lane).toList()
      ..sort((a, b) =>
          (time - a.strikeAt).abs().compareTo((time - b.strikeAt).abs()));
    final target = candidates.firstOrNull;
    final correct =
        target != null && (time - target.strikeAt).abs() <= chimeWindow;
    if (target != null) notes.remove(target);
    _report(correct,
        points: correct && (time - target.strikeAt).abs() < .09 ? 130 : 100);
    flares[lane] = time + .35;
    errorCell = correct ? null : lane;
    laneReadyAt[lane] = time + .12;
    return correct;
  }

  void move(HeartDirection direction) {
    if (!canInput || kind != TrialKind.rosevowRelay) return;
    hint = null;
    final fresh = maze.move(direction);
    if (fresh == null) {
      _report(false, complete: false);
      errorCell = 0;
    } else if (maze.solved) {
      _report(true, points: 120);
      _newPuzzle();
    } else if (fresh) {
      _report(true, points: 55, complete: false);
    }
    readyAt = time + .13;
  }

  void rotatePrism(int cell) {
    if (!canInput || kind != TrialKind.prismaticParade || cell < 0 || cell > 15) {
      return;
    }
    prismHint = null;
    prisms.rotate(cell);
    for (final lit in prisms.litCells) {
      if (prisms.credited.add(lit)) _report(true, points: 70, complete: false);
    }
    if (prisms.solved) {
      _report(true, points: 120);
      _newPuzzle();
      readyAt = time + .35;
    } else {
      readyAt = time + .1;
    }
  }

  void requestHint() {
    if (!canInput || hints <= 0) return;
    if (kind == TrialKind.rosevowRelay) {
      hints--;
      hint = maze.solution()?.firstOrNull;
    } else if (kind == TrialKind.prismaticParade) {
      hints--;
      prismHint = prisms.solutionMasks.keys
          .where((i) => prisms.connectors[i] != prisms.solutionMasks[i])
          .firstOrNull;
    }
  }
}
