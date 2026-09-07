import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/shop_item.dart';
import 'package:dragon_haven/services/server_economy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/economy_shop_catalog.dart';

void main() {
  const request = '2198f2e6-1b7a-4bb9-8a6c-c5fd83aa0648';
  const item = '2198f2e6-1b7a-4bb9-8a6c-c5fd83aa0649';
  Map<String, dynamic> response() => {
        'outcome': 'purchased',
        'item_kind': 'relic',
        'catalog_id': 'astralLens',
        'instance_id': item,
        'currency': 'gems',
        'price': 500,
        'coins': 12,
        'gems': 100,
        'wallet_revision': 2,
        'server_revision': 1,
      };

  test('shop snapshot matches every real price and excludes restricted goods',
      () {
    final catalog = economyShopCatalog();
    final sql = File('supabase/migrations/202609070047_dormant_item_shop.sql')
        .readAsStringSync();
    expect(jsonDecode(sql.split(r'$catalog$')[1]), catalog);
    final furniture = catalog['furniture']! as Map;
    for (final item in shopCatalog) {
      expect(furniture[item.id]['price'], item.price);
      expect(furniture[item.id]['currency'], item.currency.name);
    }
    for (final item in supporterFurnitureCatalog) {
      expect(furniture.containsKey(item.id), isFalse);
    }
    final relics = catalog['relic']! as Map;
    expect(
        relics.keys.toSet(),
        MysticRelic.values
            .where((relic) => relic.isShopAvailable)
            .map((relic) => relic.name)
            .toSet());
    expect(relics, hasLength(4));
    expect(relics['astralLens']['tradeable'], isFalse);
  });

  test('item purchase remains disabled in production', () async {
    var calls = 0;
    final repository = ServerEconomyRepository((_, __) async {
      calls++;
      return response();
    });
    await expectLater(
        repository.purchaseItem(
            requestId: request, kind: 'relic', catalogId: 'astralLens'),
        throwsA(isA<ServerEconomyException>()));
    expect(calls, 0);
  });

  test('item purchase sends identity but never a client price or balance',
      () async {
    final repository = ServerEconomyRepository((function, parameters) async {
      expect(function, 'purchase_economy_item');
      expect(parameters.keys.toSet(), {
        'p_request_id',
        'p_item_kind',
        'p_catalog_id',
        'p_protocol_version',
        'p_client_build'
      });
      expect(parameters['p_request_id'], request);
      return response();
    });
    final receipt = await repository.purchaseItemForTesting(
        requestId: request, kind: 'relic', catalogId: 'astralLens');
    expect(receipt.outcome, EconomyItemPurchaseOutcome.purchased);
    expect(receipt.price, 500);
    expect(receipt.instanceId, item);
  });

  test('item receipt validates identity ownership and balance shape', () async {
    for (final alter in <void Function(Map<String, dynamic>)>[
      (data) => data['catalog_id'] = 'moralPrism',
      (data) => data['instance_id'] = null,
      (data) => data['outcome'] = 'already_owned',
      (data) => data['currency'] = 'euro',
      (data) => data['gems'] = -1,
    ]) {
      final data = response();
      alter(data);
      final repository = ServerEconomyRepository((_, __) async => data);
      await expectLater(
          repository.purchaseItemForTesting(
              requestId: request, kind: 'relic', catalogId: 'astralLens'),
          throwsA(isA<ServerEconomyException>()));
    }
  });
}
