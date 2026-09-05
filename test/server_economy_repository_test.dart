import 'dart:async';

import 'package:dragon_haven/services/server_economy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const requestId = '2198f2e6-1b7a-4bb9-8a6c-c5fd83aa0647';

  test('production client gate keeps the dormant mutation unreachable',
      () async {
    expect(ServerEconomyRepository.mutationsEnabled, isFalse);
    final repository = ServerEconomyRepository((_, __) async => null);
    await expectLater(
      repository.purchaseVanityChest(
        requestId: requestId,
        tier: 'title',
      ),
      throwsA(
        isA<ServerEconomyException>().having(
          (error) => error.code,
          'code',
          'economy_client_disabled',
        ),
      ),
    );
  });

  test('timeout then reconnect reuses one request and one server receipt',
      () async {
    final server = _TimeoutAfterCommitServer();
    final repository = ServerEconomyRepository(server.call);

    await expectLater(
      repository.purchaseVanityChestForTesting(
        requestId: requestId,
        tier: 'title',
      ),
      throwsA(isA<TimeoutException>()),
    );
    final replay = await repository.purchaseVanityChestForTesting(
      requestId: requestId,
      tier: 'title',
    );

    expect(replay.outcome, VanityChestPurchaseOutcome.purchased);
    expect(replay.chestInstanceId, 'server-chest-1');
    expect(replay.coins, 900);
    expect(server.requests, hasLength(2));
    expect(
      server.requests.map((request) => request['p_request_id']).toSet(),
      {requestId},
    );
    expect(server.committedPurchases, 1);
  });

  test('rapid duplicate submits resolve to the same idempotent grant',
      () async {
    final server = _IdempotentServer();
    final repository = ServerEconomyRepository(server.call);

    final receipts = await Future.wait([
      repository.purchaseVanityChestForTesting(
        requestId: requestId,
        tier: 'portrait',
      ),
      repository.purchaseVanityChestForTesting(
        requestId: requestId,
        tier: 'portrait',
      ),
    ]);

    expect(receipts.map((receipt) => receipt.chestInstanceId).toSet(),
        {'server-chest-1'});
    expect(server.committedPurchases, 1);
  });

  test('request and response validation fail closed', () async {
    final repository = ServerEconomyRepository((_, __) async => {
          'outcome': 'purchased',
          'tier': 'music',
          'coins': 25,
          'gems': -1,
          'wallet_revision': 2,
          'server_revision': 1,
          'chest_instance_id': 'chest',
        });
    await expectLater(
      repository.purchaseVanityChestForTesting(
        requestId: requestId,
        tier: 'music',
      ),
      throwsA(isA<ServerEconomyException>()),
    );
    final incompleteRepository = ServerEconomyRepository((_, __) async => {
          'outcome': 'collection_complete',
          'tier': 'portrait',
        });
    await expectLater(
      incompleteRepository.purchaseVanityChestForTesting(
        requestId: requestId,
        tier: 'portrait',
      ),
      throwsA(isA<ServerEconomyException>()),
    );
    await expectLater(
      repository.purchaseVanityChestForTesting(
        requestId: 'not-a-uuid',
        tier: 'music',
      ),
      throwsA(isA<ServerEconomyException>()),
    );
  });
}

class _IdempotentServer {
  final Map<String, Map<String, dynamic>> _receipts = {};
  int committedPurchases = 0;

  Future<Object?> call(
    String function,
    Map<String, dynamic> parameters,
  ) async {
    expect(function, 'purchase_vanity_chest');
    final id = parameters['p_request_id']! as String;
    return _receipts.putIfAbsent(id, () {
      committedPurchases++;
      final tier = parameters['p_tier']! as String;
      return {
        'outcome': 'purchased',
        'tier': tier,
        'coins': tier == 'title' ? 900 : 25,
        'gems': tier == 'title' ? 3 : 900,
        'wallet_revision': 2,
        'server_revision': 1,
        'chest_instance_id': 'server-chest-$committedPurchases',
      };
    });
  }
}

class _TimeoutAfterCommitServer extends _IdempotentServer {
  final List<Map<String, dynamic>> requests = [];
  bool _first = true;

  @override
  Future<Object?> call(
    String function,
    Map<String, dynamic> parameters,
  ) async {
    requests.add(Map<String, dynamic>.from(parameters));
    final receipt = await super.call(function, parameters);
    if (_first) {
      _first = false;
      throw TimeoutException('response lost after commit');
    }
    return receipt;
  }
}
