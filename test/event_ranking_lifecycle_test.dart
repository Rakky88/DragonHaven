import 'dart:math';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preview ranking expires exactly three days after its natural end',
      () async {
    var now = DateTime.utc(2026, 9, 12);
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => now);
    addTearDown(game.dispose);
    final end = now.add(const Duration(days: 2));
    await game.synchronizeSeasonalEventPreviews({'halloween_witchlight': end});
    final key = game.trialRankingEventWindow!.key;
    now = end;
    await game.synchronizeSeasonalEventPreviews({});
    expect(game.trialRankingEventWindow?.key, key);
    now = end
        .add(const Duration(days: 3))
        .subtract(const Duration(microseconds: 1));
    expect(game.trialRankingEventWindow?.key, key);
    now = now.add(const Duration(microseconds: 1));
    expect(game.trialRankingEventWindow, isNull);
  });

  test(
      'switch and explicit end retire rankings across save reload without losing points',
      () async {
    var now = DateTime.utc(2026, 9, 12);
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => now);
    addTearDown(game.dispose);
    await game.synchronizeSeasonalEventPreviews(
        {'valentine_two_heartlights': now.add(const Duration(days: 2))});
    final first = game.activeEventProgress.single;
    first.points = 55;
    now = now.add(const Duration(minutes: 1));
    await game.synchronizeSeasonalEventPreviews(
        {'halloween_witchlight': now.add(const Duration(days: 2))});
    expect(game.trialRankingEventWindow?.event.id, 'halloween_witchlight');
    expect(first.rankingHidden, isTrue);
    await game.synchronizeSeasonalEventPreviews({});
    expect(game.trialRankingEventWindow, isNull);
    now = now.add(const Duration(days: 2));
    final restored = HouseholdProvider.forServerState(game.exportState(),
        random: Random(1), now: now, idGenerator: () => 'test');
    addTearDown(restored.dispose);
    expect(restored.trialRankingEventWindow, isNull);
    expect(restored.eventProgress[first.key]?.points, 55);
    expect(restored.eventProgress[first.key]?.rankingHidden, isTrue);
  });

  test('calendar dismissal survives dismissal expiry during ranking grace',
      () async {
    var now = DateTime.utc(2026, 10, 26);
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => now);
    addTearDown(game.dispose);
    final window = game.trialRankingEventWindow!;
    await game
        .synchronizeSeasonalEventDismissals({window.event.id: window.endsAt});
    expect(game.trialRankingEventWindow, isNull);
    now = window.endsAt;
    await game.synchronizeSeasonalEventDismissals({});
    expect(game.trialRankingEventWindow, isNull);
  });
}
