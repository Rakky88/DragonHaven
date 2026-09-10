import '../providers/household_provider.dart';
import 'social_trade_assets.dart';

/// One owner's part of an exchange. The worker evaluates both owners from
/// private leases; SQL commits both resulting inventories in one transaction.
abstract final class SocialTradeLifecycle {
  static Future<Map<String, dynamic>> apply({
    required HouseholdProvider game,
    required Map<String, dynamic> state,
    required String ownerId,
    required String action,
    required Map<String, dynamic> payload,
    required Map<String, dynamic>? context,
  }) async {
    final uuid = RegExp(r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$');
    if (context == null ||
        context.length != 6 ||
        context['version'] != 1 ||
        context['ownerId'] != ownerId ||
        context['action'] != action ||
        context['sourceId'] is! String ||
        !uuid.hasMatch(context['sourceId']) ||
        context['fingerprint'] is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(context['fingerprint']) ||
        context['facts'] is! Map<String, dynamic>) {
      SocialTradeAssets.unavailable();
    }
    final facts = context['facts'] as Map<String, dynamic>;
    final id = context['sourceId'] as String;
    if (facts.length != 7 ||
        facts['initiatorId'] is! String ||
        !uuid.hasMatch(facts['initiatorId']) ||
        facts['recipientId'] is! String ||
        !uuid.hasMatch(facts['recipientId']) ||
        facts['initiatorId'] == facts['recipientId'] ||
        ![facts['initiatorId'], facts['recipientId']].contains(ownerId) ||
        facts['otherOwnerId'] !=
            (facts['initiatorId'] == ownerId
                ? facts['recipientId']
                : facts['initiatorId']) ||
        (action != 'offer_trade' && payload['tradeId'] != id)) {
      SocialTradeAssets.unavailable();
    }
    final sent = facts['sent'] == null ? null : _item(facts['sent']);
    final received =
        facts['received'] == null ? null : _item(facts['received']);
    final before = facts['beforeStatus'];
    final after = facts['afterStatus'];
    if (action == 'offer_trade' || action == 'reply_trade') {
      final offer = action == 'offer_trade';
      if (ownerId != facts[offer ? 'initiatorId' : 'recipientId'] ||
          before != (offer ? 'new' : 'awaiting_recipient') ||
          after != (offer ? 'awaiting_recipient' : 'awaiting_initiator') ||
          sent == null ||
          (offer ? received != null : received == null)) {
        SocialTradeAssets.unavailable();
      }
      final selected = SocialTradeAssets.select(
          game: game,
          state: state,
          kind: payload['kind'] as String,
          key: payload['key'] as String,
          variant: payload['variant'] as int);
      if (!SocialTradeAssets.same(selected, sent)) {
        SocialTradeAssets.unavailable();
      }
      SocialTradeAssets.reserve(game, sent);
    } else if (action == 'confirm_trade') {
      if (before != 'awaiting_initiator' ||
          after != 'completed' ||
          sent == null ||
          received == null ||
          game.appliedOnlineTradeIds.contains(id)) {
        SocialTradeAssets.unavailable();
      }
      final selected = SocialTradeAssets.select(
          game: game,
          state: state,
          kind: sent['kind'],
          key: sent['key'],
          variant: sent['variant'],
          includeReserved: true);
      if (!SocialTradeAssets.same(selected, sent)) {
        SocialTradeAssets.unavailable();
      }
      if (received['kind'] == 'egg' &&
          game.eggAltar.returnedIds.contains(received['key'])) {
        SocialTradeAssets.unavailable();
      }
      SocialTradeAssets.release(game, sent);
      final applied = await game.applyOnlineTradeSettlement(
          tradeId: id,
          sentKind: sent['kind'],
          sentKey: sent['key'],
          sentData: sent['data'],
          receivedKind: received['kind'],
          receivedKey: received['key'],
          receivedData: received['data']);
      if (!applied) {
        SocialTradeAssets.unavailable();
      }
    } else if (action == 'cancel_trade' || action == 'reject_trade') {
      if (!const ['awaiting_recipient', 'awaiting_initiator']
              .contains(before) ||
          after != (action == 'cancel_trade' ? 'cancelled' : 'rejected') ||
          (action == 'reject_trade' && ownerId == facts['initiatorId'])) {
        SocialTradeAssets.unavailable();
      }
      if (sent != null) SocialTradeAssets.release(game, sent);
    } else {
      SocialTradeAssets.unavailable();
    }
    return {'tradeId': id, 'status': after};
  }

  /// Add the received raw entity only to the metadata source. The exported
  /// inventory still decides which entities exist; deleted eggs stay deleted.
  static Map<String, dynamic> metadataSource(Map<String, dynamic> state,
      String action, Map<String, dynamic>? context) {
    if (action != 'confirm_trade') return state;
    final received = context?['facts']?['received'];
    if (received is! Map || received['kind'] != 'egg') return state;
    return {
      ...state,
      'eggStash': [...state['eggStash'] as List, received['data']]
    };
  }

  static Map<String, dynamic> _item(Object? raw) {
    if (raw is! Map<String, dynamic> ||
        raw.length != 4 ||
        !const ['egg', 'chest', 'relic'].contains(raw['kind']) ||
        raw['key'] is! String ||
        (raw['key'] as String).isEmpty ||
        (raw['key'] as String).length > 100 ||
        raw['variant'] is! int ||
        raw['data'] is! Map<String, dynamic>) {
      SocialTradeAssets.unavailable();
    }
    final data = raw['data'] as Map<String, dynamic>;
    if (raw['kind'] == 'egg') {
      if (raw['variant'] != 0 ||
          data['id'] != raw['key'] ||
          data['hatchSeed'] is! int ||
          !const ['male', 'female'].contains(data['sex'])) {
        SocialTradeAssets.unavailable();
      }
    } else if (raw['key'] == 'chronoshard' && raw['kind'] == 'relic') {
      if (raw['variant'] < 10 ||
          raw['variant'] > 90 ||
          data.length != 1 ||
          data['reductionPercent'] != raw['variant']) {
        SocialTradeAssets.unavailable();
      }
    } else if (raw['variant'] != 0 || data.isNotEmpty) {
      SocialTradeAssets.unavailable();
    }
    return raw;
  }
}
