import 'dart:math';

import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/redeem_code.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const owner = '11111111-1111-4111-8111-111111111111';
  test('verified end command clears a preview and dismisses only this edition',
      () async {
    final now = DateTime.utc(2027, 7, 21, 12);
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => now);
    game.pet
      ..stage = DragonStage.hatchling
      ..firstEgg = false
      ..favorite = true
      ..name = 'Moss';
    game.eggAltar = EggAltarState(ownerId: owner);
    await game.refreshForCurrentDate();
    game.seasonalEventPreviewExpiresAt = {
      'valentine_two_heartlights': now.add(const Duration(hours: 48))
    };
    final state = game.exportState();
    final coins = game.pet.coins;
    final gems = game.pet.gems;
    final stock = {...game.chestInventory};
    game.dispose();
    final code = redeemCodeCatalog
        .singleWhere((c) => c.rewardType == RedeemRewardType.endSeasonalEvent)
        .code;
    final result = await GameCommandEngine.execute(
        state: state,
        action: 'redeem_code',
        payload: {'code': code},
        secretSeed: 'a1' * 32,
        now: now,
        keeperId: owner);
    expect(result['result'], 'event_ended');
    final after = result['state'] as Map<String, dynamic>;
    expect(after['seasonalEventPreviewExpiresAt'], isEmpty);
    final ended = after['seasonalEventDismissedUntil'] as Map;
    final window = specialAdventureWindowsAt(now)
        .singleWhere((w) => w.event.id == 'sunwake_summer_sea');
    expect(DateTime.parse(ended[window.event.id]), window.endsAt);
    expect(after['pet']['coins'], coins);
    expect(after['pet']['gems'], gems);
    expect(after['chestInventory'],
        {for (final e in stock.entries) e.key.name: e.value});
    final repeated = await GameCommandEngine.execute(
        state: after,
        action: 'redeem_code',
        payload: {'code': code},
        secretSeed: 'b2' * 32,
        now: now.add(const Duration(minutes: 1)),
        keeperId: owner);
    expect(repeated['state']['seasonalEventDismissedUntil'], ended);
    final nextYear = HouseholdProvider.forServerState(
        repeated['state'] as Map<String, dynamic>,
        random: Random(1),
        now: DateTime.utc(2028, 7, 21, 12),
        idGenerator: () => 'next-year-fixture');
    expect(nextYear.activeSpecialAdventureWindows.single.event.id,
        'sunwake_summer_sea');
    nextYear.dispose();
  });
}
