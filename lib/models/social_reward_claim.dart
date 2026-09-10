import 'adventure.dart';

enum SocialRewardKind { group, pair, podium }

/// Public claim identity only. The reward itself is resolved again from its
/// private database source when the authenticated command acquires its lease.
class SocialRewardClaim {
  SocialRewardClaim._(this.id, this.kind, this.catalogId, this.dragonId,
      this.position, this.readyAt);
  final String id, catalogId;
  final SocialRewardKind kind;
  final String? dragonId;
  final int? position;
  final DateTime readyAt;

  factory SocialRewardClaim.parse(Object? raw) {
    Never invalid() => throw const FormatException('Invalid social claim');
    if (raw is! Map ||
        raw.length != 6 ||
        !const ['id', 'kind', 'catalogId', 'dragonId', 'position', 'readyAt']
            .every(raw.containsKey)) {
      invalid();
    }
    final id = raw['id'],
        catalog = raw['catalogId'],
        dragon = raw['dragonId'],
        place = raw['position'];
    if (id is! String ||
        !RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
            .hasMatch(id) ||
        catalog is! String ||
        catalog.isEmpty ||
        raw['readyAt'] is! String) {
      invalid();
    }
    final kind =
        SocialRewardKind.values.where((k) => k.name == raw['kind']).firstOrNull;
    final ready = DateTime.tryParse(raw['readyAt'] as String);
    if (kind == null || ready == null || !ready.isUtc) {
      invalid();
    }
    if (kind == SocialRewardKind.podium) {
      if (dragon != null ||
          place is! int ||
          place < 1 ||
          place > 3 ||
          specialAdventureEventById(catalog) == null) {
        invalid();
      }
    } else {
      if (place != null ||
          dragon is! String ||
          dragon.isEmpty ||
          dragon.length > 200) {
        invalid();
      }
      if (kind == SocialRewardKind.group &&
          AdventureCatalog.byId[catalog]?.kind != AdventureKind.group) {
        invalid();
      }
      if (kind == SocialRewardKind.pair) {
        final event = specialAdventureEventById(catalog);
        if (event == null ||
            AdventureCatalog.byId[event.adventureId]?.requiresOnlinePartner !=
                true) {
          invalid();
        }
      }
    }
    return SocialRewardClaim._(
        id, kind, catalog, dragon as String?, place as int?, ready);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'catalogId': catalogId,
        'dragonId': dragonId,
        'position': position,
        'readyAt': readyAt.toIso8601String()
      };

  static List<SocialRewardClaim> parseList(Object? raw) {
    if (raw is! List || raw.length > 300) {
      throw const FormatException('Invalid social claims');
    }
    final claims = raw.map(SocialRewardClaim.parse).toList();
    if (claims.map((c) => '${c.kind.name}:${c.id}').toSet().length !=
        claims.length) {
      throw const FormatException('Duplicate social claim');
    }
    claims.sort((a, b) {
      final byTime = a.readyAt.compareTo(b.readyAt);
      return byTime == 0 ? a.id.compareTo(b.id) : byTime;
    });
    return List.unmodifiable(claims);
  }
}
