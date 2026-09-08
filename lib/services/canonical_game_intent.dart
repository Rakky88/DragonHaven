import 'dart:convert';

import '../models/game_command_schema.dart';
import 'canonical_game_snapshot.dart';

/// One durable player intent. The UUID and exact payload survive retries;
/// neither a save, reward amount, clock nor entropy seed can be submitted.
class CanonicalGameIntent {
  CanonicalGameIntent(
      {required this.ownerId,
      required this.requestId,
      required this.action,
      required Map<String, dynamic> payload,
      required this.minimumRevision})
      : payload = Map.unmodifiable({
          for (final key in payload.keys.toList()..sort()) key: payload[key],
        }) {
    final keys = GameCommandSchema.keys[action];
    if (!validOwner(ownerId) ||
        !validOwner(requestId) ||
        keys == null ||
        keys.length != payload.length ||
        !keys.every(payload.containsKey) ||
        minimumRevision < 1 ||
        minimumRevision > 9007199254740991 ||
        payload.entries
            .any((entry) => !_argument(action, entry.key, entry.value)) ||
        utf8.encode(jsonEncode(payload)).length > 4096) {
      throw const CanonicalGameException('game_intent_invalid');
    }
  }

  final String ownerId;
  final String requestId;
  final String action;
  final Map<String, dynamic> payload;
  final int minimumRevision;

  Map<String, dynamic> toRequest(int clientBuild) => {
        'protocol': 2,
        'clientBuild': clientBuild,
        'requestId': requestId,
        'expectedRevision': minimumRevision,
        'action': action,
        'payload': payload,
      };
  Map<String, dynamic> toJson() => {
        'version': 1,
        'owner': ownerId,
        'request': requestId,
        'action': action,
        'payload': payload,
        'minimumRevision': minimumRevision
      };
  factory CanonicalGameIntent.parse(Object? value) {
    if (value is! Map<String, dynamic> ||
        value.length != 6 ||
        value['version'] != 1 ||
        value['owner'] is! String ||
        value['request'] is! String ||
        value['action'] is! String ||
        value['payload'] is! Map<String, dynamic> ||
        value['minimumRevision'] is! int) {
      throw const CanonicalGameException('game_intent_invalid');
    }
    return CanonicalGameIntent(
        ownerId: value['owner'] as String,
        requestId: value['request'] as String,
        action: value['action'] as String,
        payload: value['payload'] as Map<String, dynamic>,
        minimumRevision: value['minimumRevision'] as int);
  }
  bool sameIntent(CanonicalGameIntent other) =>
      jsonEncode(toJson()) == jsonEncode(other.toJson());

  static bool validOwner(String value) =>
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
          .hasMatch(value);
  static bool _argument(String action, String key, Object? value) {
    if (const ['tagged', 'sinisterConfirmed', 'fullyViewed'].contains(key)) {
      return value is bool;
    }
    if (const ['count', 'reductionPercent', 'index'].contains(key)) {
      final (min, max) = switch (key) {
        'count' => (1, 10),
        'index' => (0, 19),
        _ => (1, 100)
      };
      return value is int && value >= min && value <= max;
    }
    if (value == null) {
      return key == 'replaceAdventureId' ||
          (action == 'equip_twinstar' || action == 'equip_relic') &&
              key == 'dragonId';
    }
    final maxLength = key == 'name'
        ? 24
        : key == 'code'
            ? 100
            : 200;
    return value is String &&
        value.trim().isNotEmpty &&
        value.runes.length <= maxLength &&
        !RegExp(r'[\x00-\x1f\x7f]').hasMatch(value);
  }
}
