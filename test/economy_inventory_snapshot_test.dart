import 'dart:convert';

import 'package:dragon_haven/services/economy_inventory_snapshot.dart';
import 'package:dragon_haven/services/server_economy_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const owner = '11111111-1111-4111-8111-111111111111';
String instanceId(int index) =>
    '22222222-2222-4222-8222-${index.toString().padLeft(12, '0')}';
Map<String, dynamic> chest(int index) => {
      'kind': 'chest',
      'id': instanceId(index),
      'catalog_id': 'wooden',
      'state': 'owned',
      'tradeable': true,
      'special_chest_id': null,
    };
Map<String, dynamic> shard(int index) => {
      'kind': 'item',
      'id': instanceId(index),
      'item_kind': 'relic',
      'catalog_id': 'chronoshard',
      'state': 'reserved',
      'tradeable': false,
      'reduction_percent': 47,
    };
Map<String, dynamic> page(List<Map<String, dynamic>> rows,
        {bool more = false, int revision = 7}) =>
    {
      'snapshot_version': 1,
      'owner_id': owner,
      'server_revision': revision,
      'wallet_revision': 4,
      'coins': 321,
      'gems': 17,
      'instances': rows,
      'next_cursor':
          more ? {'kind': rows.last['kind'], 'id': rows.last['id']} : null,
    };
Matcher code(String value) =>
    throwsA(isA<ServerEconomyException>().having((e) => e.code, 'code', value));

void main() {
  test(
      'all pages form one immutable snapshot with absolute balances and fixed relic values',
      () async {
    var calls = 0;
    final reader = EconomyInventoryReader((name, parameters) async {
      expect(name, 'get_my_economy_inventory_page');
      expect(parameters['p_page_size'], 100);
      expect(parameters['p_expected_revision'], calls == 0 ? null : 7);
      expect(parameters['p_after_id'],
          calls == 0 ? null : instanceId(calls * 100 - 1));
      final offset = calls++ * 100;
      return offset < 200
          ? page(List.generate(100, (i) => chest(offset + i)), more: true)
          : page([shard(200)]);
    });
    final snapshot = await reader.fetch(
        ownerId: owner, minimumServerRevision: 7, minimumWalletRevision: 4);
    expect(calls, 3);
    expect(snapshot.instances.length, 201);
    expect(snapshot.coins, 321);
    expect(snapshot.gems, 17);
    expect(snapshot.instances.last.reductionPercent, 47);
    expect(snapshot.instances.last.tradeable, isFalse);
    expect(snapshot.instances.last.state, 'reserved');
    expect(() => snapshot.instances.clear(), throwsUnsupportedError);
  });

  test(
      'real PostgREST revision conflict discards pages and retries once from the start',
      () async {
    var calls = 0;
    final reader = EconomyInventoryReader((_, parameters) async {
      calls++;
      if (calls == 1) return page(List.generate(100, chest), more: true);
      if (calls == 2) {
        throw const PostgrestException(
            message: 'economy_snapshot_changed', code: 'P0001');
      }
      expect(parameters['p_after_id'], isNull);
      expect(parameters['p_expected_revision'], isNull);
      return page([shard(200)], revision: 8);
    });
    final snapshot = await reader.fetch(ownerId: owner);
    expect(snapshot.serverRevision, 8);
    expect(snapshot.instances.single.catalogId, 'chronoshard');
    expect(calls, 3);
  });

  test(
      'continued revision conflicts terminate instead of mixing inventory generations',
      () async {
    var calls = 0;
    final reader = EconomyInventoryReader((_, __) async {
      calls++;
      if (calls.isOdd) return page(List.generate(100, chest), more: true);
      return page([shard(200)], revision: 8);
    });
    await expectLater(
        reader.fetch(ownerId: owner), code('economy_snapshot_changed'));
    expect(calls, 4);
  });

  test(
      'timeout does not expose partial inventory or silently retry other failures',
      () async {
    var calls = 0;
    final reader = EconomyInventoryReader((_, __) async {
      if (calls++ == 0) return page(List.generate(100, chest), more: true);
      throw const PostgrestException(message: 'offline');
    });
    await expectLater(
        reader.fetch(ownerId: owner), throwsA(isA<PostgrestException>()));
    expect(calls, 2);
  });

  test('a snapshot older than a receipt or local revision cannot be applied',
      () async {
    final reader = EconomyInventoryReader((_, __) async => page([]));
    await expectLater(reader.fetch(ownerId: owner, minimumServerRevision: 8),
        code('economy_snapshot_stale'));
    await expectLater(reader.fetch(ownerId: owner, minimumWalletRevision: 5),
        code('economy_snapshot_stale'));
  });

  test(
      'foreign, malformed, consumed, duplicate and out-of-order responses fail closed',
      () async {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (p) => p['owner_id'] = instanceId(900),
      (p) => p['snapshot_version'] = 1.0,
      (p) => p['coins'] = 3.5,
      (p) => p['wallet_revision'] = 0,
      (p) => p.remove('next_cursor'),
      (p) => p['instances'][0]['state'] = 'consumed',
      (p) => p['instances'][0]['tradeable'] = 'false',
      (p) => p['instances'][0].remove('reduction_percent'),
      (p) => p['instances'][0]['reduction_percent'] = 91,
      (p) => p['instances'] = [chest(1), chest(1)],
      (p) => p['instances'] = [chest(2), chest(1)],
      (p) => p['next_cursor'] = {'kind': 'item', 'id': instanceId(200)},
      (p) => p['instances'] = [
            {...chest(1), 'catalog_id': 'special'}
          ],
    ]) {
      final raw = page([shard(200)]);
      mutate(raw);
      await expectLater(
          EconomyInventoryReader((_, __) async => raw).fetch(ownerId: owner),
          code('economy_snapshot_invalid'));
    }
  });

  test('currency drift at the same server revision is rejected', () async {
    var calls = 0;
    final reader = EconomyInventoryReader((_, __) async => calls++ == 0
        ? page(List.generate(100, chest), more: true)
        : {
            ...page([shard(200)]),
            'coins': 999
          });
    await expectLater(
        reader.fetch(ownerId: owner), code('economy_snapshot_invalid'));
  });

  test(
      'page cursor must identify its last row and may not repeat rows across pages',
      () async {
    final raw = page(List.generate(100, chest), more: true);
    final invalid = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
    invalid['next_cursor']['id'] = instanceId(98);
    await expectLater(
        EconomyInventoryReader((_, __) async => invalid).fetch(ownerId: owner),
        code('economy_snapshot_invalid'));
    var calls = 0;
    await expectLater(
        EconomyInventoryReader(
                (_, __) async => calls++ == 0 ? raw : page([chest(99)]))
            .fetch(ownerId: owner),
        code('economy_snapshot_invalid'));
  });

  test('invalid request is rejected before contacting the server', () async {
    var calls = 0;
    final reader = EconomyInventoryReader((_, __) async {
      calls++;
      return page([]);
    });
    await expectLater(
        reader.fetch(ownerId: '../foreign'), code('economy_request_invalid'));
    await expectLater(reader.fetch(ownerId: owner, minimumServerRevision: -1),
        code('economy_request_invalid'));
    expect(calls, 0);
  });
}
