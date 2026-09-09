import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/services/economy_chest_intent_store.dart';
import 'package:dragon_haven/services/server_economy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/economy_chest_catalog.dart';

const owner = '2198f2e6-1b7a-4bb9-8a6c-c5fd83aa0647';
const request = '2198f2e6-1b7a-4bb9-8a6c-c5fd83aa0648';
const chest = '2198f2e6-1b7a-4bb9-8a6c-c5fd83aa0649';
const second = '2198f2e6-1b7a-4bb9-8a6c-c5fd83aa0650';

Map<String, dynamic> receipt() => {
      'coins': 123,
      'gems': 8,
      'wallet_revision': 10,
      'server_revision': 4,
      'chests': [
        {
          'outcome': 'opened',
          'chest_instance_id': chest,
          'tier': 'sinister',
          'coins': 400,
          'gems': 8,
          'catalog_version': 1,
          'items': [
            {
              'kind': 'relic',
              'instance_id': second,
              'catalog_id': 'chronoshard',
              'reduction_percent': 45
            }
          ],
          'egg': {
            'instance_id': owner,
            'sinister': true,
            'special_egg_id': null,
            'incubation_seconds': 21966
          },
        }
      ],
    };

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('economy-intent-test-');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
      'catalog snapshot matches real client collections and Special definitions',
      () {
    final catalog = economyChestCatalog();
    final sql = File('supabase/migrations/202609090064_sunwake_harvestmoon.sql')
        .readAsStringSync();
    final embedded = sql.split(r'$catalog$')[1];
    expect(jsonDecode(embedded), catalog);
    expect(catalog['portrait'], hasLength(100));
    expect(catalog['title'], hasLength(500));
    expect(catalog['music'], hasLength(80));
    expect(catalog['relic'], contains('astralLens'));
    expect(catalog['relic'], isNot(contains('weaveOracle')));
    expect(catalog['relic'], isNot(contains('nameweaversQuill')));
    for (final tier in (catalog['tiers']! as Map).values) {
      expect(tier['coins_max'], greaterThanOrEqualTo(tier['coins_min']));
      expect(tier['rarity'], hasLength(5));
    }
  });

  test('app gate keeps chest mutations dormant', () async {
    var calls = 0;
    final repository = ServerEconomyRepository((_, __) async {
      calls++;
      return receipt();
    });
    await expectLater(
        repository.openChests(requestId: request, chestIds: [chest]),
        throwsA(isA<ServerEconomyException>()));
    expect(calls, 0);
  });

  test('timeout after commit and process restart preserve one opening intent',
      () async {
    final firstStore = EconomyChestIntentStore(directory);
    await firstStore.prepare(EconomyChestIntent(
        ownerId: owner, requestId: request, chestIds: [chest]));
    final committed = <String, Map<String, dynamic>>{};
    var calls = 0;
    final repository = ServerEconomyRepository((function, parameters) async {
      expect(function, 'open_chest_instances');
      expect(parameters['p_chest_ids'], [chest]);
      final key = parameters['p_request_id']! as String;
      final response = committed.putIfAbsent(key, receipt);
      if (++calls == 1) throw TimeoutException('response lost after commit');
      return response;
    });
    await expectLater(
        repository.openChestsForTesting(requestId: request, chestIds: [chest]),
        throwsA(isA<TimeoutException>()));
    final restarted = EconomyChestIntentStore(Directory(directory.path));
    final recovered = (await restarted.pending(owner))!;
    final response = await repository.openChestsForTesting(
        requestId: recovered.requestId, chestIds: recovered.chestIds);
    expect(committed, hasLength(1));
    expect(response.chests.single.items.single.reductionPercent, 45);
    expect(response.chests.single.egg!.incubationSeconds, 21966);
    // Receiving a response alone must not clear pending work before a save.
    expect(await restarted.pending(owner), isNotNull);
    expect(
        acceptsEconomyWalletRevision(
            currentRevision: 11, incomingRevision: response.walletRevision),
        isFalse);
    await restarted.acknowledge(ownerId: owner, requestId: request);
    expect(await restarted.pending(owner), isNull);
  });

  test(
      'two stores cannot replace a pending intent or acknowledge the wrong request',
      () async {
    final a = EconomyChestIntentStore(directory);
    final b = EconomyChestIntentStore(directory);
    final intent = EconomyChestIntent(
        ownerId: owner, requestId: request, chestIds: [chest]);
    await Future.wait([a.prepare(intent), b.prepare(intent)]);
    await expectLater(
        b.prepare(EconomyChestIntent(
            ownerId: owner, requestId: second, chestIds: [chest])),
        throwsA(isA<ServerEconomyException>()));
    await expectLater(b.acknowledge(ownerId: owner, requestId: second),
        throwsA(isA<ServerEconomyException>()));
    expect((await a.pending(owner))!.requestId, request);
    expect(await b.pending(second), isNull);
    expect(() => intent.chestIds.add(second), throwsUnsupportedError);
  });

  test('corrupt persisted intent fails closed and is retained for recovery',
      () async {
    final file = File('${directory.path}/chest-$owner.json');
    await file.writeAsString('{broken');
    final store = EconomyChestIntentStore(directory);
    await expectLater(
        store.pending(owner), throwsA(isA<ServerEconomyException>()));
    await expectLater(
        store.prepare(EconomyChestIntent(
            ownerId: owner, requestId: request, chestIds: [chest])),
        throwsA(isA<ServerEconomyException>()));
    expect(await file.readAsString(), '{broken');
  });

  test('invalid requests never reach the server', () async {
    var calls = 0;
    final repository = ServerEconomyRepository((_, __) async {
      calls++;
      return receipt();
    });
    for (final ids in <List<String>>[
      [],
      [chest, chest],
      ['invalid'],
      List.filled(11, chest)
    ]) {
      await expectLater(
          repository.openChestsForTesting(requestId: request, chestIds: ids),
          throwsA(isA<ServerEconomyException>()));
    }
    expect(calls, 0);
  });

  test('wrong chest and malformed Chronoshard or wallet responses fail closed',
      () async {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (json) => json['chests'][0]['chest_instance_id'] = second,
      (json) => json['chests'][0]['items'][0]['reduction_percent'] = 91,
      (json) => json['chests'][0]['items'][0].remove('reduction_percent'),
      (json) => json['chests'][0]['egg']['sinister'] = 'true',
      (json) => json['chests'][0]['outcome'] = 'collection_complete',
      (json) => json['wallet_revision'] = -1,
      (json) => json['chests'] = [],
    ]) {
      final json = receipt();
      mutate(json);
      final repository = ServerEconomyRepository((_, __) async => json);
      await expectLater(
          repository
              .openChestsForTesting(requestId: request, chestIds: [chest]),
          throwsA(isA<ServerEconomyException>()));
    }
  });
}
