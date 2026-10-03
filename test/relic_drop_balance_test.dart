import 'dart:convert';
import 'dart:math';

import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/domain/social_trade_assets.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/canonical_game_actions.dart';
import 'package:flutter_test/flutter_test.dart';

class _Rolls implements Random {
  _Rolls(this.rolls, {this.fallback = .99});
  final List<double> rolls;
  final double fallback;
  @override
  double nextDouble() => rolls.isEmpty ? fallback : rolls.removeAt(0);
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 27, 12);
  const owner = '11111111-1111-4111-8111-111111111111';
  const quill = MysticRelic.nameweaversQuill;

  HouseholdProvider game(Random random) {
    final game = HouseholdProvider(
        initialize: false,
        persistenceEnabled: false,
        clock: () => now,
        random: random)
      ..pet = Pet(stage: DragonStage.hatchling, firstEgg: false);
    addTearDown(game.dispose);
    return game;
  }

  test('fivefold standard gates preserve guarantees, exclusions and pool', () {
    final g = game(_Rolls([]));
    final expected = {
      ChestTier.wooden: 0.0,
      ChestTier.silver: 0.0,
      ChestTier.gold: .05,
      ChestTier.dragon: .10,
      ChestTier.mythical: .20,
      ChestTier.sinister: 1.0,
    };
    for (final tier in ChestTier.values) {
      expect(g.relicDropChance(tier), expected[tier] ?? 0, reason: tier.name);
    }
    expect(mysticRelicDropPool(), hasLength(65));
    expect(mysticRelicDropPool(), isNot(contains(quill)));
    expect(trialRewardForGrade(TrialGrade.sPlus, 0, relicRoll: .049).relic,
        isNotNull);
    expect(
        trialRewardForGrade(TrialGrade.sPlus, 0, relicRoll: .05).relic, isNull);
    for (final grade in TrialGrade.values.where((g) => g != TrialGrade.sPlus)) {
      expect(trialRewardForGrade(grade, 0, relicRoll: 0).relic, isNull);
    }
  });

  test('Quill chances are independent and guaranteed beside Sinister relics',
      () async {
    final expected = {
      ChestTier.wooden: .02,
      ChestTier.silver: .04,
      ChestTier.gold: .08,
      ChestTier.dragon: .16,
      ChestTier.mythical: .32,
      ChestTier.sinister: 1.0,
    };
    for (final tier in ChestTier.values) {
      final g = game(_Rolls([], fallback: 0));
      expect(g.nameweaversQuillDropChance(tier), expected[tier] ?? 0,
          reason: tier.name);
      g.chestInventory[tier] = 1;
      final reward = await g.openChest(tier);
      expect(reward?.additionalRelics.contains(quill) ?? false,
          expected.containsKey(tier),
          reason: tier.name);
      expect(g.tradeableRelicCount(quill), expected.containsKey(tier) ? 1 : 0);
    }
  });

  test(
      'one chest can grant both relics and Quill does not depend on the other roll',
      () async {
    // Mythical: egg roll, regular relic roll, Quill roll, emote roll.
    for (final (regular, extra, expected) in [
      (0.0, 0.0, [MysticRelic.moralPrism, quill]),
      (.99, 0.0, [quill]),
      (0.0, .32, [MysticRelic.moralPrism]),
      (.99, .32, <MysticRelic>[]),
    ]) {
      final g = game(_Rolls([.99, regular, extra]));
      g.chestInventory[ChestTier.mythical] = 1;
      final reward = (await g.openChest(ChestTier.mythical))!;
      expect(ChestRewardBundle.single(reward).relics, expected);
      expect(g.relicCount(quill), expected.contains(quill) ? 1 : 0);
      expect(g.relicCount(MysticRelic.moralPrism),
          expected.contains(MysticRelic.moralPrism) ? 1 : 0);
    }
  });

  test('Sinister chest always grants a pool relic and a separate Quill',
      () async {
    final g = game(_Rolls([], fallback: .999));
    g.chestInventory[ChestTier.sinister] = 1;
    final reward = (await g.openChest(ChestTier.sinister))!;
    expect(reward.relicFound, isNotNull);
    expect(reward.additionalRelics, [quill]);
    expect(ChestRewardBundle.single(reward).relics, hasLength(2));
    expect(g.relicCount(quill), 1);
    expect(g.relicCount(reward.relicFound!), 1);
  });

  test('server buys one bound Quill for 100 gems and refuses below that price',
      () async {
    final g = HouseholdProvider(
        persistenceEnabled: false, clock: () => now, random: Random(37));
    addTearDown(g.dispose);
    g.pet
      ..stage = DragonStage.hatchling
      ..favorite = true
      ..firstEgg = false
      ..gems = 100;
    Future<Map<String, dynamic>> buy(Map<String, dynamic> state) =>
        GameCommandEngine.execute(
            state: state,
            action: 'purchase_relic',
            payload: {'relic': quill.name},
            now: now,
            keeperId: owner,
            secretSeed: 'a5' * 32);
    final bought = await buy(g.exportState());
    expect(bought['result'], 'purchased');
    final state = bought['state'] as Map<String, dynamic>;
    expect(state['pet']['gems'], 0);
    expect(state['relicInventory'][quill.name], 1);
    expect(state['untradeableRelicInventory'][quill.name], 1);
    final refused = await buy(state);
    expect(refused['result'], 'insufficientGems');
    expect(refused['state']['relicInventory'][quill.name], 1);
    expect(refused['state']['pet']['gems'], 0);
  });

  test(
      'trade selectors permit dropped Quills but exclude bound and reserved copies',
      () async {
    final g = game(_Rolls([]))..pet.gems = 100;
    g.relicInventory[quill] = 1;
    await g.purchaseRelic(quill);
    Map<String, dynamic> select() => SocialTradeAssets.select(
        game: g,
        state: g.exportState(),
        kind: 'relic',
        key: quill.name,
        variant: 0);
    expect(select()['key'], quill.name);
    g.reservedOnlineTradeRelics[quill.name] = 1;
    expect(select, throwsA(isA<SocialTradeException>()));
    g.reservedOnlineTradeRelics.clear();
    g.relicInventory[quill] = 1;
    expect(select, throwsA(isA<SocialTradeException>()));
    expect(g.tradeableRelicCount(quill), 0);
  });

  test('canonical chest receipt displays both relics and accepts old receipts',
      () {
    final receipt = {
      'tier': 'gold',
      'rewards': [
        {
          'tier': 'gold',
          'coins': 100,
          'gems': 2,
          'eggFound': false,
          'sinisterEgg': false,
          'specialEgg': false,
          'relicFound': 'moralPrism',
          'additionalRelics': ['nameweaversQuill'],
        }
      ],
    };
    final rewards = decodeChestRewards(receipt, tier: ChestTier.gold, count: 1);
    expect(rewards.relics, [MysticRelic.moralPrism, quill]);
    final old = jsonDecode(jsonEncode(receipt)) as Map<String, dynamic>;
    (old['rewards'][0] as Map).remove('additionalRelics');
    expect(decodeChestRewards(old, tier: ChestTier.gold, count: 1).relics,
        [MysticRelic.moralPrism]);
  });
}
