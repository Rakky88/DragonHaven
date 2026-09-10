import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/pet.dart';
import '../models/trial.dart';
import '../models/trial_input.dart';
import '../models/trial_run_model.dart';
import 'canonical_game_snapshot.dart';
import 'canonical_trial_run_source.dart';

/// One clock and one simulation for both rendering and recorded inputs.
/// Ordinary saves run in the background. A failed save pauses play and retains
/// its exact chunk until the durable command journal has recovered it.
class TrialGameplayController extends ChangeNotifier {
  TrialGameplayController(this.source, {this.elapsedMilliseconds}) {
    source.session.addListener(_accountChanged);
  }
  final CanonicalTrialRunSource source;
  final int Function()? elapsedMilliseconds;
  final Stopwatch _clock = Stopwatch();
  TrialRunModel? _model;
  TrialRunModel get model => _model!;
  final _inputs = <TrialInput>[];
  Timer? _timer;
  bool _disposed = false, started = false, paused = false, saving = false;
  bool _starting = false;
  String? error;
  TrialCompletion? completion;
  int _offsetMs = 0, _testOrigin = 0;
  ({String inputs, int at, int count, bool finish})? _pending;
  bool get ready => _model != null;
  bool get running =>
      ready &&
      started &&
      !paused &&
      !model.ended &&
      source.accountCurrent &&
      !_disposed;
  int get _nowMs =>
      _offsetMs +
      (elapsedMilliseconds == null
          ? _clock.elapsedMilliseconds
          : elapsedMilliseconds!() - _testOrigin);

  Future<void> prepare() async {
    if (_starting || ready) return;
    _starting = true;
    error = null;
    _notify();
    try {
      final attempt = await source.start();
      final dragon = source.dragon;
      if (_disposed) return;
      if (dragon == null) {
        throw const CanonicalGameException('game_account_changed');
      }
      _model = source.restoredModel ??
          TrialRunModel(kind: attempt.kind, seed: attempt.seed, training: {
            for (final f in TrainingFocus.values) f: dragon.trainingFor(f)
          });
      _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => tick());
      if (model.ended) {
        started = true;
        await flush();
      }
    } on CanonicalGameException catch (e) {
      error = e.code;
    } finally {
      _starting = false;
      _notify();
    }
  }

  void start() {
    if (!ready || started || !source.accountCurrent) return;
    started = true;
    _resetClock();
    _notify();
  }

  void _resetClock() {
    _offsetMs = model.elapsedMs;
    _testOrigin = elapsedMilliseconds?.call() ?? 0;
    _clock
      ..reset()
      ..start();
  }

  void _advance() {
    final target = _nowMs;
    // A suspended app must not fast-forward thousands of simulation steps.
    if (target - model.elapsedMs > 2000) {
      pause();
      return;
    }
    if (target >= model.elapsedMs) model.advanceTo(target);
  }

  void tick() {
    if (!running) return;
    _advance();
    if (!paused &&
        (model.ended ||
            _inputs.length >= 140 ||
            model.elapsedMs - source.acknowledgedMs >= 5000)) {
      unawaited(flush());
    }
    // Bounded memory while a slow request is in flight. The current pointer is
    // retained; no input or corridor segment is silently discarded.
    if (_inputs.length >= 280 ||
        model.elapsedMs - source.acknowledgedMs >= 45000) {
      pause();
    }
    _notify();
  }

  void input(TrialControl control, [int a = 0, int b = 0]) {
    if (!running) return;
    _advance();
    if (paused || model.ended) {
      if (model.ended) unawaited(flush());
      _notify();
      return;
    }
    final input = TrialInput(model.elapsedMs, control, a, b);
    model.apply(input);
    _inputs.add(input);
    if (model.ended || _inputs.length >= 140) unawaited(flush());
    _notify();
  }

  void pause() {
    if (!ready || !started || paused) return;
    _clock.stop();
    paused = true;
    if (!model.ended) {
      final control = model.surfHeld
          ? TrialControl.releaseDragon
          : model.trace?.active == true
              ? TrialControl.releasePath
              : null;
      if (control != null) {
        final input = TrialInput(model.elapsedMs, control);
        model.apply(input);
        _inputs.add(input);
      }
    }
    _notify();
  }

  Future<void> resume() async {
    if (!ready) {
      await prepare();
      return;
    }
    await flush();
    if (_disposed || error != null || !source.accountCurrent) return;
    paused = false;
    _resetClock();
    _notify();
  }

  Future<void> flush() async {
    if (_disposed || !ready || !started || saving || completion != null) return;
    saving = true;
    error = null;
    final selected = _inputs.take(140).toList();
    final partial = selected.length < _inputs.length;
    final chunk = _pending ??= (
      inputs: TrialInputTranscript.encode(selected,
          startMilliseconds: source.acknowledgedMs),
      at: partial ? selected.last.milliseconds : model.elapsedMs,
      count: selected.length,
      finish: model.ended && !partial
    );
    try {
      final result =
          await source.checkpoint(chunk.inputs, chunk.at, finish: chunk.finish);
      if (_disposed) return;
      _inputs.removeRange(0, chunk.count);
      _pending = null;
      completion = result;
    } on CanonicalGameException catch (e) {
      error = e.code;
      pause();
    } finally {
      saving = false;
      _notify();
    }
    if (!_disposed && error == null && completion == null && model.ended) {
      await flush();
    }
  }

  Future<void> cancel() async {
    pause();
    if (saving) throw const CanonicalGameException('game_refresh_required');
    await source.cancel();
  }

  void _accountChanged() {
    if (source.accountCurrent) return;
    pause();
    error = 'game_account_changed';
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _clock.stop();
    source.session.removeListener(_accountChanged);
    super.dispose();
  }
}
