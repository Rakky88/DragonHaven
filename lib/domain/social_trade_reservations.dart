import '../providers/household_provider.dart';
import 'social_trade_assets.dart';

/// Current database reservations override stale saved reservations after a
/// cancellation or expiry, including when another keeper closed the trade.
abstract final class SocialTradeReservations {
  static void apply(
      {required HouseholdProvider game,
      required String ownerId,
      required Map<String, dynamic> state,
      required Map<String, dynamic>? verified}) {
    if (verified == null) return;
    if (verified.length != 3 ||
        verified['version'] != 1 ||
        verified['ownerId'] != ownerId ||
        verified['items'] is! List ||
        (verified['items'] as List).length > 1) {
      SocialTradeAssets.unavailable();
    }
    // Validate before replacing the stale local overlay. Normalized server
    // tables enforce one active trade per keeper and exactly one item per side.
    final items = <Map<String, dynamic>>[];
    for (final raw in verified['items'] as List) {
      if (raw is! Map<String, dynamic> ||
          raw.length != 3 ||
          raw['kind'] is! String ||
          raw['key'] is! String ||
          raw['variant'] is! int) {
        SocialTradeAssets.unavailable();
      }
      items.add(SocialTradeAssets.select(
          game: game,
          state: state,
          kind: raw['kind'],
          key: raw['key'],
          variant: raw['variant'],
          includeReserved: true));
    }
    game.reservedOnlineTradeEggIds = {};
    game.reservedOnlineTradeChests = {};
    game.reservedOnlineTradeRelics = {};
    for (final item in items) {
      SocialTradeAssets.reserve(game, item);
    }
  }
}
