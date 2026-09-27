import 'dart:math';
import 'dart:io';

import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/keeper_level.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _SequenceRandom implements Random {
  _SequenceRandom({required this.doubles});

  final List<double> doubles;
  var _doubleIndex = 0;
  var _integer = 0;

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() => doubles[_doubleIndex++ % doubles.length];

  @override
  int nextInt(int max) {
    final value = _integer % max;
    _integer++;
    return value;
  }
}

HouseholdProvider _game({Random? random}) {
  final game = HouseholdProvider(
    random: random ?? Random(40),
    persistenceEnabled: false,
  );
  game.pet
    ..stage = DragonStage.ascended
    ..firstEgg = false
    ..gems = 100;
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dragon and Keeper level curves preserve evolution and reach new caps',
      () {
    expect(Pet.levelThresholds, hasLength(50));
    expect(Pet.levelThresholds.take(9),
        [0, 150, 350, 650, 1000, 1450, 1950, 2600, 3400]);
    expect(Pet.levelAtXp(Pet.levelThresholds.last), 50);
    expect(Pet.levelAtXp(Pet.levelThresholds.last + 1000000), 50);

    expect(keeperLevelThresholds, hasLength(40));
    expect(keeperLevelThresholds[1], 50000);
    expect(keeperLevelThresholds[2], 125000);
    expect(keeperLevelThresholds.last, 737156841577);
    expect(keeperLevelAtXp(49999), 1);
    expect(keeperLevelAtXp(50000), 2);
    expect(keeperLevelAtXp(keeperLevelThresholds.last), 40);
  });

  test('server social level function has the exact 50 app XP floors', () {
    final sql = File('supabase/migrations/202609270104_dragon_level_50.sql')
        .readAsStringSync();
    final body =
        RegExp(r'array\[([\s\S]*?)\]::integer\[\]').firstMatch(sql)!.group(1)!;
    final sqlThresholds = RegExp(r'\d+')
        .allMatches(body)
        .map((match) => int.parse(match.group(0)!))
        .toList();
    expect(sqlThresholds, Pet.levelThresholds);
    expect(sql, contains('greatest(value, 0)'));
    expect(sql, contains('revoke all on function private.dragon_level'));
    expect(
      sql,
      contains("badge_key ~ '^keeper_level_badge_([2-9]|[1-3][0-9]|40)\$'"),
    );
    expect(sql, contains("'keeper_level_frame_40'"));
    expect(
      sql,
      contains(
        'public.update_my_profile(text, text, text, text, text)',
      ),
    );
  });

  test('XP crossing level 50 fills the dragon and immediately flows to Keeper',
      () async {
    final game = _game();
    game.pet.xp = Pet.levelThresholds.last - 10;

    expect(await game.buyStarlightTreat(), isTrue);
    expect(game.pet.xp, Pet.levelThresholds.last);
    expect(game.pet.level, 50);
    expect(game.keeperXp, 15);

    expect(await game.buyStarlightTreat(), isTrue);
    expect(game.pet.xp, Pet.levelThresholds.last);
    expect(game.keeperXp, 40);
    game.dispose();
  });

  test(
      'each reached Keeper level chest grants its fixed and random contents once',
      () async {
    final game = _game(
      random: _SequenceRandom(doubles: [.1]),
    )..keeperXp = keeperLevelThresholds[1];
    final eggsBefore = game.eggStash.length;
    final relicsBefore = game.totalRelicCount;

    final reward = await game.openKeeperLevelChest(2);

    expect(reward, isNotNull);
    expect(reward!.specialChestId, 'keeper_level_2');
    expect(reward.emoteFound?.id, keeperLevelEmoteId(2));
    expect(reward.badgeFound?.id, keeperLevelBadgeId(2));
    expect(reward.frameFound, isNull);
    expect(reward.relicFound, isNotNull);
    expect(game.totalRelicCount, relicsBefore + 1);
    expect(game.eggStash, hasLength(eggsBefore + 1));
    expect(game.eggStash.last.lineage.rarity, DragonRarity.mythical);
    expect(game.ownedDragonEmoteIds, contains(keeperLevelEmoteId(2)));
    expect(game.ownedBadgeIds, {keeperLevelBadgeId(2)});
    expect(game.claimedKeeperLevelRewardLevels, {2});
    expect(await game.openKeeperLevelChest(2), isNull);
    expect(game.eggStash, hasLength(eggsBefore + 1));
    expect(game.totalRelicCount, relicsBefore + 1);
    game.dispose();
  });

  test(
      'level 40 chest replaces the lower badge and grants frame and achievement',
      () async {
    final game = _game()
      ..keeperXp = keeperLevelThresholds.last
      ..ownedBadgeIds.add(keeperLevelBadgeId(12))
      ..selectedBadgeId = keeperLevelBadgeId(12);

    final reward = await game.openKeeperLevelChest(40);

    expect(reward?.badgeFound?.id, keeperLevelBadgeId(40));
    expect(reward?.frameFound?.id, keeperLevel40FrameId);
    expect(game.ownedBadgeIds, {keeperLevelBadgeId(40)});
    expect(game.selectedBadgeId, keeperLevelBadgeId(40));
    expect(game.ownedFrameIds, contains(keeperLevel40FrameId));
    expect(game.unlockedAchievementIds, contains('keeper_level_40'));
    expect(await game.openKeeperLevelChest(2), isNotNull,
        reason: 'older pending chests remain claimable');
    expect(game.ownedBadgeIds, {keeperLevelBadgeId(40)},
        reason: 'opening an older chest cannot downgrade the current badge');
    expect(game.selectedBadgeId, keeperLevelBadgeId(40));
    game.dispose();
  });

  test('canonical level chest result carries all revealable rewards', () async {
    final source = HouseholdProvider(
      random: Random(41),
      persistenceEnabled: false,
    );
    final state = source.exportState()..['keeperXp'] = keeperLevelThresholds[1];
    source.dispose();

    final executed = await GameCommandEngine.execute(
      state: state,
      action: 'open_keeper_level_chest',
      payload: const {'level': 2},
      secretSeed: 'a5' * 32,
      now: DateTime.utc(2026, 9, 27),
      keeperId: '11111111-1111-4111-8111-111111111111',
    );
    final reward =
        ((executed['result'] as Map)['rewards'] as List).single as Map;
    expect(reward['specialChestId'], 'keeper_level_2');
    expect(reward['relicFound'], isNotNull);
    expect(reward['emoteFound'], keeperLevelEmoteId(2));
    expect(reward['badgeFound'], keeperLevelBadgeId(2));
    expect(reward['frameFound'], isNull);
    expect(executed['state']['claimedKeeperLevelRewardLevels'], [2]);
  });
}
