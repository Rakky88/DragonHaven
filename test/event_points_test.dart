import 'dart:math';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/domain/game_public_projection.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/event_progress.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const owner = '11111111-1111-4111-8111-111111111111';
  HouseholdProvider restore(Map<String, dynamic> state, DateTime at) =>
      HouseholdProvider.forServerState(state,
          random: Random(1), now: at, idGenerator: () => 'event-test');

  test('exact adventure and trial point tables', () {
    expect(AdventureKind.values.map(eventAdventurePoints), [5, 20, 50, 50, 0]);
    for (final entry in {
      TrialGrade.d: 0,
      TrialGrade.c: 5,
      TrialGrade.b: 10,
      TrialGrade.a: 15,
      TrialGrade.s: 20,
      TrialGrade.sPlus: 25
    }.entries) {
      expect(eventTrialPoints(entry.key), entry.value);
    }
  });

  test('New Year runs six Amsterdam calendar days and recurs', () {
    for (final year in [2027, 2028, 2029]) {
      final start = DateTime.utc(year - 1, 12, 31, 23);
      final end = DateTime.utc(year, 1, 6, 23);
      bool active(DateTime at) => specialAdventureWindowsAt(at)
          .any((w) => w.event.id == 'new_year_first_dawn');
      expect(active(start.subtract(const Duration(microseconds: 1))), false);
      expect(active(start), true);
      expect(active(end.subtract(const Duration(microseconds: 1))), true);
      expect(active(end), false);
      final game =
          HouseholdProvider(persistenceEnabled: false, clock: () => start);
      expect(game.visibleEventProgress.single.target, 6000);
      game.dispose();
    }
  });

  test('Christmas and Valentine use extended annual point-event windows', () {
    for (final spec in [
      (
        id: 'christmas_winter_hearth',
        year: 2026,
        month: 12,
        day: 20,
        days: 7,
        target: 7000
      ),
      (
        id: 'valentine_two_heartlights',
        year: 2027,
        month: 2,
        day: 12,
        days: 5,
        target: 10000
      ),
    ]) {
      for (final year in [spec.year, spec.year + 1, spec.year + 2]) {
        // Both events occur during Amsterdam winter time (UTC+1).
        final start = DateTime.utc(year, spec.month, spec.day - 1, 23);
        final end = start.add(Duration(days: spec.days));
        bool active(DateTime at) => specialAdventureWindowsAt(at)
            .any((window) => window.event.id == spec.id);
        expect(active(start.subtract(const Duration(microseconds: 1))), false);
        expect(active(start), true);
        expect(active(end.subtract(const Duration(microseconds: 1))), true);
        expect(active(end), false);
        final game =
            HouseholdProvider(persistenceEnabled: false, clock: () => start);
        final progress = game.visibleEventProgress.single;
        expect(progress.target, spec.target);
        expect(progress.startsAt, start);
        expect(progress.endsAt, end);
        game.awardEventPoints(spec.target - 1);
        expect(progress.canClaim, false);
        game.awardEventPoints(1);
        expect(progress.canClaim, true);
        game.dispose();
      }
    }
  });

  test('full target can be earned on day one and claimed once after closing',
      () async {
    final now = DateTime.utc(2027, 1, 1, 12);
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => now);
    game.awardEventPoints(6000);
    final p = game.visibleEventProgress.single;
    expect(p.complete, true);
    final key = p.key;
    final saved = game.exportState();
    game.dispose();
    final after = restore(saved, DateTime.utc(2027, 3, 1));
    expect(after.visibleEventProgress.single.canClaim, true);
    expect(await after.claimEventReward(key), true);
    expect(await after.claimEventReward(key), false);
    expect(after.specialChestInventory['firstlight_celebration_chest_v1'], 1);
    final claimed = restore(after.exportState(), DateTime.utc(2028, 1, 1));
    expect(claimed.eventProgress[key]!.fraction, 1);
    expect(claimed.eventProgress[key]!.canClaim, false);
    expect(claimed.visibleEventProgress.first.target, 6000);
    expect(claimed.visibleEventProgress.first.points, 0);
    after.dispose();
    claimed.dispose();
  });

  test('adventure finishing before close earns points only on late claim once',
      () async {
    var now = DateTime.utc(2027, 1, 6, 22, 59);
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => now);
    final p = game.visibleEventProgress.single;
    p.points = 5995;
    game.pet
      ..stage = DragonStage.hatchling
      ..firstEgg = false
      ..favorite = true;
    game.adventureRuns.add(AdventureRun(
        id: 'mini-before-close',
        adventureId: AdventureCatalog.mini.first.id,
        dragonId: game.pet.id,
        startedAt: now.subtract(const Duration(minutes: 5)),
        endsAt: now,
        status: AdventureRunStatus.running));
    now = DateTime.utc(2027, 1, 8);
    final restored = restore(game.exportState(), now);
    await restored.refreshForCurrentDate();
    expect(restored.eventProgress[p.key]!.points, 5995);
    await restored.refreshForCurrentDate();
    expect(restored.eventProgress[p.key]!.points, 5995);
    expect(await restored.claimAdventure('mini-before-close'), isNotNull);
    expect(await restored.claimAdventure('mini-before-close'), isNull);
    expect(restored.eventProgress[p.key]!.points, 6000);
    expect(restored.eventProgress[p.key]!.canClaim, true);
    game.dispose();
    restored.dispose();
  });

  test(
      'ready save round trip defers points, while old ready saves do not double credit',
      () async {
    final at = DateTime.utc(2027, 1, 2);
    for (final legacy in [false, true]) {
      final game =
          HouseholdProvider(persistenceEnabled: false, clock: () => at);
      game.pet
        ..stage = DragonStage.hatchling
        ..firstEgg = false
        ..favorite = true;
      final p = game.visibleEventProgress.single;
      p.points = legacy ? 5 : 0;
      game.adventureRuns.add(AdventureRun(
          id: 'claim-once',
          adventureId: AdventureCatalog.mini.first.id,
          dragonId: game.pet.id,
          startedAt: at.subtract(const Duration(minutes: 5)),
          endsAt: at,
          status: AdventureRunStatus.running));
      await game.refreshForCurrentDate();
      expect(p.points, legacy ? 5 : 0);
      final state = game.exportState();
      if (legacy) {
        (state['adventureRuns'] as List).single.remove('eventPointsAwarded');
      }
      final loaded = restore(state, at);
      expect(await loaded.claimAdventure('claim-once'), isNotNull);
      expect(loaded.eventProgress[p.key]!.points, 5);
      expect(await loaded.claimAdventure('claim-once'), isNull);
      expect(loaded.eventProgress[p.key]!.points, 5);
      loaded.dispose();
      game.dispose();
    }
  });

  test('closing boundary excludes new points and group completions deduplicate',
      () {
    final game = HouseholdProvider(
        persistenceEnabled: false, clock: () => DateTime.utc(2027, 1, 8));
    expect(
        game.recordGroupEventCompletion('group', DateTime.utc(2027, 1, 6, 22)),
        true);
    expect(
        game.recordGroupEventCompletion('group', DateTime.utc(2027, 1, 6, 22)),
        false);
    final p = game.eventProgress.values.single;
    expect(p.points, 50);
    game.awardEventPoints(25, completedAt: DateTime.utc(2027, 1, 6, 23));
    expect(p.points, 50);
    game.dispose();
  });

  test(
      'Valentine combines existing contributions and each keeper claims own chest',
      () async {
    final at = DateTime.utc(2027, 2, 14, 12);
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => at);
    game.awardEventPoints(750);
    final p = game.visibleEventProgress.single;
    expect(p.target, 10000);
    expect(p.canClaim, false);
    final shared = {
      'version': 1,
      'ownerId': owner,
      'progress': [
        {...p.toJson(), 'partnerPoints': 9250}
      ]
    };
    game.applyEventPartnerPoints(shared, owner);
    expect(p.canClaim, true);
    expect(p.points, 750);
    final result = await GameCommandEngine.execute(
        state: game.exportState(),
        action: 'claim_event_reward',
        payload: {'eventKey': p.key},
        secretSeed: 'a1' * 32,
        now: at.add(const Duration(days: 10)),
        keeperId: owner,
        verifiedEventProgress: shared);
    expect(result['result'], true);
    expect(
        result['state']['specialChestInventory']['twinheart_keepsake_chest_v1'],
        1);
    final projected = GamePublicProjection.project(
        state: result['state'],
        ownerId: owner,
        now: at.add(const Duration(days: 10)));
    expect(projected['adventures']['eventProgress'].single['claimed'], true);
    expect(() => game.applyEventPartnerPoints(shared, 'wrong-owner'),
        throwsFormatException);
    game.dispose();
  });

  test(
      'seasonal adventures removed, returning specials and stored chests retained',
      () async {
    final game = HouseholdProvider(
        persistenceEnabled: false, clock: () => DateTime.utc(2027, 1, 1));
    expect(
        game
            .adventuresFor(AdventureKind.special)
            .where((a) => a.seasonalSpecial),
        isEmpty);
    expect(await game.startAdventure(AdventureCatalog.newYearFirstDawn),
        isNot(AdventureStartResult.started));
    game.dispose();
  });

  test('preview progress never grants a permanent production chest', () async {
    final at = DateTime.utc(2026, 9, 12);
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => at);
    game.persistentSeasonalPreviewRewards = false;
    game.seasonalEventPreviewExpiresAt['valentine_two_heartlights'] =
        at.add(const Duration(days: 2));
    final p = game.visibleEventProgress.single;
    expect(p.target, 4000);
    game.awardEventPoints(4000);
    expect(await game.claimEventReward(p.key), true);
    expect(game.specialChestInventory, isEmpty);
    game.dispose();
  });
}
