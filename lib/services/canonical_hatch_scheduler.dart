import 'dart:async';

import 'canonical_game_actions.dart';
import 'canonical_game_session.dart';
import 'canonical_game_snapshot.dart';

/// Schedules the existing durable hatch command from confirmed server time.
/// The server still decides readiness and owns the outcome and reveal queue.
class CanonicalHatchScheduler {
  CanonicalHatchScheduler(this.session) {
    session.addListener(_schedule);
    _schedule();
  }
  final CanonicalGameSession session;
  final _elapsed = Stopwatch()..start();
  CanonicalGameSnapshot? _observed;
  Timer? _timer;
  String? _attempted;
  bool _disposed = false;

  void _schedule() {
    _timer?.cancel();
    final view = session.confirmedSnapshot;
    if (!identical(view, _observed)) {
      _observed = view;
      _elapsed.reset();
    }
    if (_disposed ||
        !session.canAct ||
        view == null ||
        !view.profile.onboardingComplete ||
        view.trialAttempt != null ||
        view.schoolAttempt != null) {
      return;
    }
    final egg = view.nest;
    if (egg?.hatchAt == null) return;
    final epoch = session.connection.sessionEpoch;
    final key =
        '$epoch:${view.ownerId}:${egg!.id}:${egg.hatchAt}:${view.serverTime}';
    if (_attempted == key) return;
    final remaining =
        egg.hatchAt!.difference(view.serverTime.add(_elapsed.elapsed));
    _timer = Timer(remaining.isNegative ? Duration.zero : remaining, () async {
      if (_disposed ||
          !session.canAct ||
          session.connection.sessionEpoch != epoch ||
          session.confirmedSnapshot?.ownerId != view.ownerId ||
          session.confirmedSnapshot?.nest?.id != egg.id) {
        return;
      }
      _attempted = key;
      try {
        await CanonicalGameActions(session).hatchEgg(egg.id);
      } on CanonicalGameException {
        // Recovery replays the durable intent. Do not create another request
        // every timer tick or acknowledge an unconfirmed hatch locally.
      }
    });
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    session.removeListener(_schedule);
    _elapsed.stop();
  }
}
