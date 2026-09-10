import 'dart:math';
import 'dart:convert';
import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/domain/game_public_projection.dart';
import 'package:dragon_haven/domain/social_trade_assets.dart';
import 'package:dragon_haven/models/dragon_egg.dart';
import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

const alice = '11111111-1111-4111-8111-111111111111';
const bob = '22222222-2222-4222-8222-222222222222';
const trade = '33333333-3333-4333-8333-333333333333';
final at = DateTime.utc(2026, 9, 10, 13);
Map<String, dynamic> clone(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> first;
  late Map<String, dynamic> second;
  Map<String, dynamic> fixture(String owner) {
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => at);
    game.pet
      ..stage = DragonStage.hatchling
      ..firstEgg = false
      ..favorite = true
      ..name = 'Keeper';
    game.eggAltar = EggAltarState(ownerId: owner);
    game.eggStash.add(DragonEgg(
        id: 'egg-$owner',
        lineageId: 'solmanta',
        specialEggId: 'sunwake_egg_v1',
        incubationMinutes: 1200,
        acquiredAt: at,
        hatchSeed: 734891,
        prismatic: true,
        sex: DragonSex.female,
        altarKnowledge: const AltarEggKnowledge(
            tagged: true,
            tagRevision: 3,
            rarity: true,
            order: true,
            moral: true)));
    game.relicInventory[MysticRelic.chronoshard] = 3;
    game.chronoshardReductions = [25, 60, 60];
    game.chestInventory[ChestTier.gold] = 2;
    game.eggRarityRevealedIds.add('egg-$owner');
    final state = game.exportState();
    game.dispose();
    state['eggStash'][0]['futureMetadata'] = {'fixedRoll': 'keep-me'};
    state['eggStash'][0]['altarKnowledge']['futureClue'] = 'keep-this-too';
    return state;
  }

  setUp(() {
    first = fixture(alice);
    second = fixture(bob);
  });
  Map<String, dynamic> item(Map<String, dynamic> state, String kind, String key,
      {int variant = 0}) {
    final game = HouseholdProvider.forServerState(state,
        now: at, random: Random(4), idGenerator: () => trade);
    try {
      return SocialTradeAssets.select(
          game: game,
          state: state,
          kind: kind,
          key: key,
          variant: variant,
          includeReserved: true);
    } finally {
      game.dispose();
    }
  }

  Map<String, dynamic> context(
          String owner,
          String action,
          String before,
          String after,
          Map<String, dynamic>? sent,
          Map<String, dynamic>? received) =>
      {
        'version': 1,
        'ownerId': owner,
        'action': action,
        'sourceId': trade,
        'fingerprint': 'ab' * 32,
        'facts': {
          'initiatorId': alice,
          'recipientId': bob,
          'otherOwnerId': owner == alice ? bob : alice,
          'beforeStatus': before,
          'afterStatus': after,
          'sent': sent,
          'received': received
        }
      };
  Future<Map<String, dynamic>> run(
          Map<String, dynamic> state,
          String owner,
          String action,
          Map<String, dynamic> payload,
          Map<String, dynamic>? sealed,
          {Map<String, dynamic>? reservations}) =>
      GameCommandEngine.execute(
          state: state,
          action: action,
          payload: payload,
          secretSeed: 'ab' * 32,
          now: at,
          keeperId: owner,
          verifiedSocialContext: sealed,
          verifiedTradeReservations: reservations);
  test(
      'two-owner exchange conserves the exact egg and Chronoshard variant without leaking genetics',
      () async {
    final egg = item(first, 'egg', 'egg-$alice');
    final shard = item(second, 'relic', 'chronoshard', variant: 60);
    final offer = await run(
        first,
        alice,
        'offer_trade',
        {
          'keeperCode': 'DH-22222222',
          'kind': 'egg',
          'key': 'egg-$alice',
          'variant': 0
        },
        context(alice, 'offer_trade', 'new', 'awaiting_recipient', egg, null));
    first = offer['state'];
    expect(first['reservedOnlineTradeEggIds'], ['egg-$alice']);
    final reply = await run(
        second,
        bob,
        'reply_trade',
        {
          'tradeId': trade,
          'kind': 'relic',
          'key': 'chronoshard',
          'variant': 60
        },
        context(bob, 'reply_trade', 'awaiting_recipient', 'awaiting_initiator',
            shard, egg));
    second = reply['state'];
    final results = await Future.wait([
      run(
          first,
          alice,
          'confirm_trade',
          {'tradeId': trade},
          context(alice, 'confirm_trade', 'awaiting_initiator', 'completed',
              egg, shard)),
      run(
          second,
          bob,
          'confirm_trade',
          {'tradeId': trade},
          context(bob, 'confirm_trade', 'awaiting_initiator', 'completed',
              shard, egg))
    ]);
    final a = results[0]['state'] as Map<String, dynamic>;
    final b = results[1]['state'] as Map<String, dynamic>;
    expect(a['eggStash'], isEmpty);
    expect(b['eggRarityRevealedIds'], contains('egg-$alice'));
    final transferred =
        (b['eggStash'] as List).singleWhere((e) => e['id'] == 'egg-$alice');
    expect(transferred, egg['data']);
    final reloaded = await run(b, bob, 'refresh', {}, null);
    expect(
        (reloaded['state']['eggStash'] as List)
                .singleWhere((e) => e['id'] == 'egg-$alice')['altarKnowledge']
            ['futureClue'],
        'keep-this-too');
    expect(a['chronoshardReductions'], [25, 60, 60, 60]);
    expect(b['chronoshardReductions'], [25, 60]);
    expect(a['relicInventory']['chronoshard'], 4);
    expect(b['relicInventory']['chronoshard'], 2);
    expect(a['reservedOnlineTradeEggIds'], isEmpty);
    expect(b['reservedOnlineTradeRelics'], isEmpty);
    expect(a['pet'], first['pet']);
    expect(b['pet'], second['pet']);
    expect(a['pendingPresentations'].last['createdAt'], at.toIso8601String());
    expect(results[0]['result'], {'tradeId': trade, 'status': 'completed'});
    final projected =
        GamePublicProjection.project(state: b, ownerId: bob, now: at);
    final wire = jsonEncode(projected);
    expect(wire, isNot(contains('734891')));
    expect(wire, isNot(contains('fixedRoll')));
    final transferredView =
        (projected['eggs'] as List).singleWhere((e) => e['id'] == 'egg-$alice');
    expect(transferredView['tagged'], true);
    expect(transferredView['lineageId'], isNull);
    await expectLater(
        run(
            a,
            alice,
            'confirm_trade',
            {'tradeId': trade},
            context(alice, 'confirm_trade', 'awaiting_initiator', 'completed',
                egg, shard)),
        throwsA(isA<GameCommandException>()));
  });
  test(
      'cancellation and expired server overlays release assets without minting or consuming them',
      () async {
    final egg = item(first, 'egg', 'egg-$alice');
    first['reservedOnlineTradeEggIds'] = ['egg-$alice'];
    final result = await run(
        first,
        alice,
        'cancel_trade',
        {'tradeId': trade},
        context(alice, 'cancel_trade', 'awaiting_recipient', 'cancelled', egg,
            null));
    expect(result['state']['eggStash'], first['eggStash']);
    expect(result['state']['reservedOnlineTradeEggIds'], isEmpty);
    final projected = GamePublicProjection.project(
        state: first,
        ownerId: alice,
        now: at,
        verifiedTradeReservations: {
          'version': 1,
          'ownerId': alice,
          'items': []
        });
    expect(projected['inventory']['reservedOnlineTradeEggIds'], isEmpty);
    expect(first['reservedOnlineTradeEggIds'], ['egg-$alice']);
  });
  test(
      'reservations prevent duplicate selection, while cosmetic and equipped relics stay untradeable',
      () async {
    final egg = item(first, 'egg', 'egg-$alice');
    for (final choice in [
      {'kind': 'egg', 'key': 'egg-$alice', 'variant': 0},
      {'kind': 'chest', 'key': 'portrait', 'variant': 0},
      {'kind': 'chest', 'key': 'special', 'variant': 0},
      {'kind': 'relic', 'key': 'twinstarBrooch', 'variant': 0},
      {'kind': 'relic', 'key': 'chronoshard', 'variant': 59},
      {'kind': 'relic', 'key': 'chronoshard', 'variant': 60},
    ]) {
      final state = clone(first);
      state['reservedOnlineTradeEggIds'] = ['egg-$alice'];
      state['reservedOnlineTradeRelics'] = {'chronoshard:60': 2};
      await expectLater(
          run(
              state,
              alice,
              'offer_trade',
              {'keeperCode': 'DH-22222222', ...choice},
              context(alice, 'offer_trade', 'new', 'awaiting_recipient', egg,
                  null)),
          throwsA(isA<GameCommandException>()));
    }
  });
  test(
      'rejects cross-owner, altered item and arbitrary grant facts without mutating input',
      () async {
    final egg = item(first, 'egg', 'egg-$alice');
    final valid =
        context(alice, 'offer_trade', 'new', 'awaiting_recipient', egg, null);
    final altered = clone(valid);
    altered['facts']['sent']['data']['hatchSeed'] = 123;
    final before = jsonEncode(first);
    for (final invalid in [
      null,
      {...valid, 'ownerId': bob},
      {...valid, 'xp': 10000},
      altered
    ]) {
      await expectLater(
          run(
              first,
              alice,
              'offer_trade',
              {
                'keeperCode': 'DH-22222222',
                'kind': 'egg',
                'key': 'egg-$alice',
                'variant': 0
              },
              invalid),
          throwsA(isA<GameCommandException>()));
    }
    expect(jsonEncode(first), before);
  });
}
