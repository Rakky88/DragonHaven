import 'package:dragon_haven/server_dragonhaven_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Tower room breaks refresh at their exact future deadline', () {
    final now = DateTime.utc(2026, 9, 24, 12);

    expect(
      canonicalRefreshDelay(
        now: now,
        adventureRefreshAt: now.add(const Duration(minutes: 15)),
        towerAwayUntil: [now.add(const Duration(minutes: 4))],
      ),
      const Duration(minutes: 4),
    );
  });

  test('an expired room break retries quickly with a bounded backoff', () {
    final now = DateTime.utc(2026, 9, 24, 12);
    final expired = [now.subtract(const Duration(seconds: 1))];

    expect(
      canonicalRefreshDelay(
        now: now,
        adventureRefreshAt: now.add(const Duration(minutes: 15)),
        towerAwayUntil: expired,
      ),
      const Duration(seconds: 2),
    );
    expect(
      canonicalRefreshDelay(
        now: now,
        adventureRefreshAt: now.add(const Duration(minutes: 15)),
        towerAwayUntil: expired,
        expiredRetryAttempt: 99,
      ),
      const Duration(seconds: 60),
    );
  });
}
