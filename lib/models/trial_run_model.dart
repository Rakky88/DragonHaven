import 'dart:math';

import 'classic_trial_game.dart';
import 'moonlit_orchard.dart';
import 'pet.dart';
import 'seasonal_arcade_game.dart';
import 'sunwake_surf.dart';
import 'trial.dart';
import 'trial_input.dart';
import 'trial_random.dart';
import 'wishcake_tower.dart';
import 'witchlight_trace.dart';

/// A replay receives controls, never a claimed score. Reward selection stays
/// outside this public simulation and uses the server's private entropy.
class TrialRunModel {
  TrialRunModel(
      {required this.kind,
      required this.seed,
      required Map<TrainingFocus, int> training})
      : training = Map.unmodifiable(training),
        _random = Random(seed) {
    durationMs = trialDefinitions[kind]!.duration.inMilliseconds +
        (training.values.fold(0, (sum, value) => sum + value) / 300)
                .clamp(0, 3)
                .round() *
            1000;
    if (kind == TrialKind.cavernFlight) {
      cavern = CavernFlightGame(
          seed: seed,
          spirit: stat(TrainingFocus.spirit),
          random: TrialRandom(seed));
    }
    if (kind == TrialKind.ruinBreaker) {
      ruin = RuinBreakerGame(might: stat(TrainingFocus.might));
    }
    if (kind == TrialKind.runeweaver) {
      runes = RuneweaverGame(
          seed: seed,
          arcana: stat(TrainingFocus.arcana),
          random: TrialRandom(seed));
    }
    if (kind == TrialKind.witchlightWard) {
      _newWitchChallenge(initial: true);
      _newWitchChallenge(initial: true);
    } else if (seasonal) {
      // Keep the established seasonal seed sequence, including the old intro's
      // decorative challenge draws. The actual arcade seed is independent of UI.
      _random.nextInt(6);
      _random.nextInt(2);
      _random.nextInt(kind == TrialKind.prismaticParade ? 7 : 3);
      _random.nextInt(6);
      arcadeSeed = _random.nextInt(1 << 31);
      final might = assistance(TrainingFocus.might),
          arcana = assistance(TrainingFocus.arcana),
          spirit = assistance(TrainingFocus.spirit);
      if (const {
        TrialKind.hollyfrostGiftforge,
        TrialKind.midnightChime,
        TrialKind.rosevowRelay,
        TrialKind.prismaticParade
      }.contains(kind)) {
        arcade = SeasonalArcadeGame(
            kind: kind,
            seed: arcadeSeed,
            might: might,
            arcana: arcana,
            spirit: spirit);
      }
      if (kind == TrialKind.sunwakeSurf) {
        surf = SunwakeSurf(
            seed: arcadeSeed, might: might, arcana: arcana, spirit: spirit);
      }
      if (kind == TrialKind.moonlitOrchard) {
        orchard = MoonlitOrchard(
            seed: arcadeSeed, might: might, arcana: arcana, spirit: spirit);
      }
      if (kind == TrialKind.wishcakeTower) {
        cake = WishcakeTower(
            seed: arcadeSeed, might: might, arcana: arcana, spirit: spirit);
      }
    }
  }
  final TrialKind kind;
  final int seed;
  final Map<TrainingFocus, int> training;
  final Random _random;
  late final int durationMs;
  int elapsedMs = 0, arcadeSeed = 0, correctActions = 0, totalActions = 0;
  int mistakes = 0, combo = 0, bestCombo = 0, round = 1, _score = 0, phase = 0;
  int _witchPenaltyMs = 0, readyAtMs = 0, promptUntilMs = 0;
  int pathSeed = 0, pumpkinTarget = 0, pumpkinPosition = 0;
  double _surfGrabOffset = 0;
  bool _surfHeld = false;
  bool get surfHeld => _surfHeld;
  final surfVisualActions = <SurfAction>[];
  bool _basketResetPending = false;
  final _events = <ArcadeAction>[];
  final _history = <TrialInput>[];
  bool get _directCheckpoint =>
      cavern != null || ruin != null || runes != null || surf != null;
  CavernFlightGame? cavern;
  RuinBreakerGame? ruin;
  RuneweaverGame? runes;
  SeasonalArcadeGame? arcade;
  SunwakeSurf? surf;
  MoonlitOrchard? orchard;
  WishcakeTower? cake;
  WishcakeDrop? lastCakeDrop;
  OrchardPlacement? lastOrchardPlacement;
  WitchlightTrace? trace;
  bool get seasonal => trialDefinitions[kind]!.isSeasonal;
  bool get endless => kind == TrialKind.sunwakeSurf;
  int stat(TrainingFocus focus) => training[focus] ?? 0;
  double assistance(TrainingFocus focus) => stat(focus).clamp(0, 400) / 400;
  int get remainingMs => max(0, durationMs - elapsedMs - _witchPenaltyMs);
  int get score => cavern?.score ?? ruin?.score ?? runes?.rounds ?? _score;
  int? get mistakeLimit => switch (kind) {
        TrialKind.wishcakeTower => 1,
        TrialKind.witchlightWard ||
        TrialKind.hollyfrostGiftforge ||
        TrialKind.midnightChime ||
        TrialKind.sunwakeSurf ||
        TrialKind.moonlitOrchard =>
          3,
        _ => null,
      };
  bool get ended =>
      cavern?.ended ??
      ruin?.ended ??
      runes?.ended ??
      ((!endless && remainingMs == 0) ||
          (mistakeLimit != null && mistakes >= mistakeLimit!));
  bool get witchReady => !ended && elapsedMs >= readyAtMs;
  bool get orchardReady => !ended && elapsedMs >= readyAtMs;
  List<ArcadeAction> takeEvents() {
    final result = List<ArcadeAction>.of(_events);
    _events.clear();
    return result;
  }

  Map<String, dynamic> checkpoint() => {
        'version': 1,
        'kind': kind.name,
        'seed': seed,
        'training': {
          for (final entry in training.entries) entry.key.name: entry.value
        },
        'elapsedMs': elapsedMs,
        'score': _score,
        'correctActions': correctActions,
        'totalActions': totalActions,
        'mistakes': mistakes,
        'combo': combo,
        'bestCombo': bestCombo,
        'round': round,
        'surfHeld': _surfHeld,
        'surfGrabOffset': _surfGrabOffset,
        if (cavern != null) 'cavern': cavern!.checkpoint(),
        if (ruin != null) 'ruin': ruin!.checkpoint(),
        if (runes != null) 'runes': runes!.checkpoint(),
        if (surf != null) 'surf': surf!.checkpoint(),
        if (!_directCheckpoint)
          'history': [
            for (final input in _history)
              [input.milliseconds, input.control.index, input.a, input.b]
          ],
      };

  factory TrialRunModel.fromCheckpoint(Map<String, dynamic> state) {
    if (state['version'] != 1) {
      throw const FormatException('checkpoint_invalid');
    }
    final model = TrialRunModel(
        kind: TrialKind.values.byName(state['kind'] as String),
        seed: state['seed'] as int,
        training: {
          for (final entry in (state['training'] as Map).entries)
            TrainingFocus.values.byName(entry.key as String): entry.value as int
        });
    if (model._directCheckpoint) {
      model.elapsedMs = state['elapsedMs'] as int;
      model._score = state['score'] as int;
      model.correctActions = state['correctActions'] as int;
      model.totalActions = state['totalActions'] as int;
      model.mistakes = state['mistakes'] as int;
      model.combo = state['combo'] as int;
      model.bestCombo = state['bestCombo'] as int;
      model.round = state['round'] as int;
      model._surfHeld = state['surfHeld'] as bool;
      model._surfGrabOffset = (state['surfGrabOffset'] as num).toDouble();
      if (model.cavern != null) {
        model.cavern = CavernFlightGame.fromCheckpoint(
            Map<String, dynamic>.from(state['cavern']),
            spirit: model.stat(TrainingFocus.spirit));
      }
      if (model.ruin != null) {
        model.ruin = RuinBreakerGame.fromCheckpoint(
            Map<String, dynamic>.from(state['ruin']),
            might: model.stat(TrainingFocus.might));
      }
      if (model.runes != null) {
        model.runes = RuneweaverGame.fromCheckpoint(
            Map<String, dynamic>.from(state['runes']),
            arcana: model.stat(TrainingFocus.arcana));
      }
      if (model.surf != null) {
        model.surf = SunwakeSurf.fromCheckpoint(
            Map<String, dynamic>.from(state['surf']));
      }
    } else {
      for (final input in state['history'] as List) {
        model.apply(TrialInput(
            input[0] as int,
            TrialControl.values[input[1] as int],
            input[2] as int,
            input[3] as int));
      }
      model.advanceTo(state['elapsedMs'] as int);
      if (model._score != state['score'] ||
          model.totalActions != state['totalActions'] ||
          model.mistakes != state['mistakes']) {
        throw const FormatException('checkpoint_replay_mismatch');
      }
    }
    model.takeEvents();
    return model;
  }

  void advanceTo(int at) {
    if (at < elapsedMs) throw const FormatException('input_reversed');
    if (ended) return;
    final target =
        seasonal && !endless ? min(at, durationMs - _witchPenaltyMs) : at;
    final delta = target - elapsedMs;
    elapsedMs = target;
    cavern?.advanceTo(target);
    ruin?.advanceTo(target);
    runes?.advanceTo(target);
    if (arcade != null) {
      arcade!.advanceTo(target);
      for (final event in arcade!.takeActions()) {
        _arcadeAction(event);
      }
    }
    if (surf != null) {
      surfVisualActions.clear();
      for (final event in surf!.advance(delta / 1000)) {
        surfVisualActions.add(event);
        _arcadeAction(ArcadeAction(event.correct, points: event.points));
      }
    }
    if (_basketResetPending && target >= readyAtMs) {
      _basketResetPending = false;
      orchard!.freshBasket();
    }
  }

  void _arcadeAction(ArcadeAction event) {
    if (!endless && totalActions >= 200) return;
    totalActions++;
    if (event.correct) {
      correctActions++;
      _score += event.points.clamp(0, 130) + min(90, combo * 6);
      if (!endless) _score = min(20000, _score);
      if (event.complete) {
        combo++;
        bestCombo = max(bestCombo, combo);
        round++;
      }
    } else {
      mistakes++;
      combo = 0;
      _score = max(0, _score - 30);
    }
    _events.add(event);
  }

  void _newWitchChallenge({bool initial = false}) {
    phase = 0;
    trace = null;
    pathSeed = _random.nextInt(4294967296);
    pumpkinTarget = _random.nextInt(6);
    _random.nextInt(2);
    _random.nextInt(3);
    pumpkinPosition = _random.nextInt(6);
    promptUntilMs = elapsedMs +
        1000 +
        (initial ? 1900 : 1150 + stat(TrainingFocus.arcana).clamp(0, 400) * 2);
  }

  void _witchAnswer(bool correct, {bool complete = false}) {
    if (!witchReady) return;
    totalActions++;
    if (correct) {
      correctActions++;
      _score += 70 + min(90, combo * 6);
      if (complete) {
        combo++;
        bestCombo = max(bestCombo, combo);
        round++;
      } else {
        phase++;
      }
    } else {
      mistakes++;
      combo = 0;
      _witchPenaltyMs += 2000;
    }
    readyAtMs = elapsedMs + 650;
    if ((!correct || complete) && mistakes < 3) _newWitchChallenge();
    _events.add(ArcadeAction(correct, points: 70, complete: complete));
  }

  /// Geometry is a visible playfield fact. Configure only before the first
  /// stroke; changing the corridor during an active stroke is never accepted.
  void configureTrace(double width, double height) {
    if (kind != TrialKind.witchlightWard ||
        phase != 1 ||
        !witchReady ||
        !width.isFinite ||
        !height.isFinite ||
        width < 64 ||
        height < 64 ||
        width > 4096 ||
        height > 4096) {
      throw const FormatException('input_arena_invalid');
    }
    if (trace != null) throw const FormatException('input_arena_reserved');
    trace = WitchlightTrace(
        width: width,
        height: height,
        seed: pathSeed,
        tolerance: assistance(TrainingFocus.spirit));
  }

  void apply(TrialInput input) {
    advanceTo(input.milliseconds);
    if (ended) return;
    final a = input.a, b = input.b;
    if (!_directCheckpoint) {
      if (_history.length >= 6000) throw const FormatException('input_limit');
      _history.add(input);
    }
    switch (input.control) {
      case TrialControl.flap when cavern != null:
        if (a != 0 || b != 0) throw const FormatException('input_invalid');
        cavern!.flap(elapsedMs);
      case TrialControl.strikeRuin when ruin != null:
        if (a != 0 || b != 0) throw const FormatException('input_invalid');
        ruin!.strike(elapsedMs);
      case TrialControl.tapRune when runes != null:
        if (a < 0 || a > 4 || b != 0) {
          throw const FormatException('input_invalid');
        }
        runes!.tap(a, elapsedMs);
      case TrialControl.choosePumpkin when kind == TrialKind.witchlightWard:
        if (a < 0 || a > 5 || b != 0) {
          throw const FormatException('input_invalid');
        }
        if (phase == 0 && elapsedMs > promptUntilMs) {
          _witchAnswer(a == pumpkinPosition);
        }
      case TrialControl.configureTrace when kind == TrialKind.witchlightWard:
        configureTrace(a / 4, b / 4);
      case TrialControl.beginPath when kind == TrialKind.witchlightWard:
        if (phase == 1 && witchReady && trace != null) {
          trace!.begin(Point(a / 4, b / 4));
        }
      case TrialControl.followPath when kind == TrialKind.witchlightWard:
        if (phase == 1 && witchReady && trace != null) {
          trace!.move(Point(a / 4, b / 4));
          if (trace!.result != null) {
            _witchAnswer(trace!.result!, complete: true);
          }
        }
      case TrialControl.releasePath when kind == TrialKind.witchlightWard:
        if (a != 0 || b != 0) throw const FormatException('input_invalid');
        if (phase == 1 && witchReady && trace?.active == true) {
          trace!.release();
          _witchAnswer(false, complete: true);
        }
      case TrialControl.dropCake when cake != null:
        if (a != 0 || b != 0) throw const FormatException('input_invalid');
        final result = lastCakeDrop = cake!.drop(elapsedMs / 1000);
        if (result != null) {
          _arcadeAction(ArcadeAction(result.hit, points: result.points));
        }
      case TrialControl.rotateFruit when orchard != null:
        if (a < 0 || a > 2 || b != 0) {
          throw const FormatException('input_invalid');
        }
        if (orchardReady) orchard!.rotate(a);
      case TrialControl.placeFruit when orchard != null:
        if (a < 0 || a > 2 || b < 0 || b >= 42) {
          throw const FormatException('input_invalid');
        }
        if (orchardReady) {
          final result =
              lastOrchardPlacement = orchard!.place(a, b % 6, b ~/ 6);
          if (result != null) {
            _arcadeAction(ArcadeAction(true,
                points: result.rows > 0 ? 130 : 55 + result.fruitCount * 12));
            readyAtMs = elapsedMs + (result.rows > 0 ? 620 : 0);
            if (result.overflow) {
              _arcadeAction(const ArcadeAction(false, points: 0));
              readyAtMs += 850;
              _basketResetPending = !orchard!.finished;
            }
          }
        }
      case TrialControl.grabDragon when surf != null:
        if (!_surfHeld &&
            (a / 4096 - surf!.x).abs() <= .16 &&
            (b / 4096 - SunwakeSurf.playerY).abs() <= .16) {
          _surfHeld = true;
          _surfGrabOffset = a / 4096 - surf!.x;
          surf!.steer(surf!.x);
        }
      case TrialControl.steerDragon when surf != null:
        if (_surfHeld) surf!.steer(a / 4096 - _surfGrabOffset);
      case TrialControl.releaseDragon when surf != null:
        if (a != 0 || b != 0) throw const FormatException('input_invalid');
        _surfHeld = false;
        surf!.releaseSteering();
      case TrialControl.deliverGift ||
              TrialControl.strikeChime ||
              TrialControl.moveHearts ||
              TrialControl.rotatePrism ||
              TrialControl.requestHint
          when arcade != null:
        arcade!.applyInput(input);
        for (final event in arcade!.takeActions()) {
          _arcadeAction(event);
        }
      default:
        throw const FormatException('input_control_invalid');
    }
  }
}
