import 'dart:convert';

import '../models/chest.dart';
import '../models/mystic_relic.dart';
import '../providers/household_provider.dart';

/// Private, database-sealed assets. Egg data must never be included in a
/// command response or social offer; the public projection reveals only known
/// information. Selection cannot supply genetics or a reward quantity.
abstract final class SocialTradeAssets {
  static Map<String, dynamic> select({
    required HouseholdProvider game,
    required Map<String, dynamic> state,
    required String kind,
    required String key,
    required int variant,
    bool includeReserved = false,
  }) {
    if (key.isEmpty || key.length > 100) {
      unavailable();
    }
    if (kind == 'egg') {
      if (variant != 0 ||
          (!includeReserved && game.isEggReservedForTrade(key))) {
        unavailable();
      }
      final egg = game.eggStash.where((e) => e.id == key).firstOrNull;
      if (egg == null) {
        unavailable();
      }
      final raw = (state['eggStash'] as List)
          .whereType<Map>()
          .where((e) => e['id'] == key)
          .firstOrNull;
      if (raw == null) {
        unavailable();
      }
      return {
        'kind': kind,
        'key': key,
        'variant': 0,
        'data': {
          ...Map<String, dynamic>.from(raw),
          ...egg.toJson(),
          'altarKnowledge': {
            ...Map<String, dynamic>.from(raw['altarKnowledge'] as Map? ?? {}),
            ...game.eggKnowledge(key).toJson(),
          },
        }
      };
    }
    if (kind == 'chest') {
      final tier = ChestTier.values.where((t) => t.name == key).firstOrNull;
      if (variant != 0 ||
          tier == null ||
          !tier.isTradeable ||
          (includeReserved
                  ? game.chestCount(tier)
                  : game.tradeableChestCount(tier)) <
              1) {
        unavailable();
      }
      return {
        'kind': kind,
        'key': key,
        'variant': 0,
        'data': <String, dynamic>{}
      };
    }
    if (kind == 'relic') {
      final relic = MysticRelic.values.where((r) => r.name == key).firstOrNull;
      if (relic == null ||
          relic.isAlwaysUntradeable ||
          (includeReserved
                  ? game.gameplayRelicCount(relic)
                  : game.tradeableRelicCount(relic)) <
              1) {
        unavailable();
      }
      if (relic == MysticRelic.chronoshard) {
        if (variant < 10 ||
            variant > 90 ||
            !game.chronoshardReductions.contains(variant) ||
            (!includeReserved && game.isChronoshardReserved(variant))) {
          unavailable();
        }
      } else if (variant != 0) {
        unavailable();
      }
      return {
        'kind': kind,
        'key': key,
        'variant': variant,
        'data': {
          if (relic == MysticRelic.chronoshard) 'reductionPercent': variant,
        }
      };
    }
    unavailable();
  }

  static String reservationKey(Map<String, dynamic> item) =>
      item['kind'] == 'relic' && item['key'] == 'chronoshard'
          ? 'chronoshard:${item['variant']}'
          : item['key'] as String;

  static void reserve(HouseholdProvider game, Map<String, dynamic> item) {
    final key = reservationKey(item);
    switch (item['kind']) {
      case 'egg':
        game.reservedOnlineTradeEggIds.add(key);
      case 'chest':
        game.reservedOnlineTradeChests
            .update(key, (n) => n + 1, ifAbsent: () => 1);
      case 'relic':
        game.reservedOnlineTradeRelics
            .update(key, (n) => n + 1, ifAbsent: () => 1);
      default:
        unavailable();
    }
  }

  static void release(HouseholdProvider game, Map<String, dynamic> item) {
    final key = reservationKey(item);
    if (item['kind'] == 'egg') {
      game.reservedOnlineTradeEggIds.remove(key);
      return;
    }
    final counts = item['kind'] == 'chest'
        ? game.reservedOnlineTradeChests
        : game.reservedOnlineTradeRelics;
    final count = counts[key] ?? 0;
    if (count <= 1) {
      counts.remove(key);
    } else {
      counts[key] = count - 1;
    }
  }

  /// JSON object order is irrelevant; counts, arrays, identity, unknown
  /// metadata and every fixed egg property must remain exactly equal.
  static bool same(Object? first, Object? second) =>
      jsonEncode(_ordered(first)) == jsonEncode(_ordered(second));
  static Object? _ordered(Object? value) => switch (value) {
        Map() => {
            for (final key in value.keys.cast<String>().toList()..sort())
              key: _ordered(value[key])
          },
        List() => value.map(_ordered).toList(),
        _ => value,
      };
  static Never unavailable() => throw const SocialTradeException();
}

class SocialTradeException implements Exception {
  const SocialTradeException();
}
