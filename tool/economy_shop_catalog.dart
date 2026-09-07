import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/shop_item.dart';

Map<String, Object> economyShopCatalog() => {
      'version': 1,
      'furniture': {
        for (final item in shopCatalog)
          item.id: {
            'currency': item.currency.name,
            'price': item.price,
            'tradeable': true,
            'unique_while_owned': true
          },
      },
      'relic': {
        for (final relic
            in MysticRelic.values.where((item) => item.isShopAvailable))
          relic.name: {
            'currency': 'gems',
            'price': relicShopGemPrice,
            'tradeable': false,
            'unique_while_owned': false
          },
      },
    };

void main(List<String> arguments) {
  final snapshot = jsonEncode(economyShopCatalog());
  if (arguments.length == 1 && arguments.single == '--verify') {
    final sql = File('supabase/migrations/202609070047_dormant_item_shop.sql')
        .readAsStringSync();
    if (!sql.contains('\$catalog\$$snapshot\$catalog\$::jsonb')) {
      stderr.writeln(
          'Server shop catalog drift: add a forward catalog migration.');
      exitCode = 1;
    } else {
      stdout.writeln('Server shop prices and availability match the app.');
    }
  } else {
    stdout.writeln(snapshot);
  }
}
