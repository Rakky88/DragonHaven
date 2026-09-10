import '../providers/household_provider.dart';

/// A database-owned reservation view shared by command evaluation and display.
/// A null view means that the social cutover is disabled. An empty, verified
/// view releases obsolete social bindings after a lobby closes or a keeper
/// leaves; it never clears an ordinary solo adventure.
abstract final class SocialDragonReservations {
  static void apply({
    required HouseholdProvider game,
    required String ownerId,
    required Map<String, dynamic>? verified,
    Map<String, dynamic>? activeAttempt,
  }) {
    if (verified == null) return;
    Never invalid() => throw const FormatException(
        'Invalid authoritative social reservations');
    if (verified.length != 3 ||
        verified['version'] != 1 ||
        verified['ownerId'] != ownerId ||
        verified['reservations'] is! List) {
      invalid();
    }
    final values = verified['reservations'] as List;
    if (values.length > 1000) invalid();
    final bindings = <String, String>{};
    final dragons = {for (final dragon in game.ownedDragons) dragon.id: dragon};
    final reservedByAttempt =
        (activeAttempt?['dragonIds'] as List? ?? const []).toSet();
    if (activeAttempt?['mentorId'] case final String mentorId) {
      reservedByAttempt.add(mentorId);
    }
    for (final value in values) {
      if (value is! Map || value.length != 3) invalid();
      final id = value['dragonId'];
      final source = value['sourceId'];
      final kind = value['kind'];
      if (id is! String ||
          id.isEmpty ||
          id.length > 100 ||
          !dragons.containsKey(id) ||
          bindings.containsKey(id) ||
          reservedByAttempt.contains(id) ||
          !const {'group', 'pair'}.contains(kind) ||
          source is! String ||
          !RegExp(r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$')
              .hasMatch(source)) {
        invalid();
      }
      bindings[id] =
          '${kind == 'group' ? 'online-group' : 'online-seasonal'}:$source';
    }
    // Validate all conflicts before touching the ephemeral game instance.
    for (final entry in bindings.entries) {
      final current = dragons[entry.key]!.activeAdventureId;
      if (current != null && !_social(current)) invalid();
    }
    for (final dragon in dragons.values) {
      final next = bindings[dragon.id];
      if (next != null || _social(dragon.activeAdventureId)) {
        dragon.activeAdventureId = next;
      }
    }
  }

  static bool _social(String? id) =>
      id?.startsWith('online-group:') == true ||
      id?.startsWith('online-seasonal:') == true;
}
