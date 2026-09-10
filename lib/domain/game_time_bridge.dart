import 'dart:convert';

/// Old saves contain device-local ISO strings without an offset. Only the
/// device that reads that save can resolve their existing meaning. Upload UTC
/// instants before capturing a canonical import; a server must never guess its
/// own timezone. Calendar day labels and unknown metadata are left untouched.
abstract final class GameTimeBridge {
  static const _root = [
    'trialRefilledAt',
    'miniAdventureRefilledAt',
    'shortAdventureRefilledAt',
    'scheduledReturningAt',
    'returningSpecialAvailableUntil'
  ];
  static const _maps = [
    'returningVisitors',
    'rareInteractionAt',
    'seasonalEventPreviewExpiresAt',
    'seasonalEventDismissedUntil'
  ];
  static const _dragon = ['acquiredAt', 'stageStartedAt', 'needsUpdatedAt'];
  static final _iso = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,6}))?(Z|[+-]\d{2}:?\d{2})?$');

  static DateTime _parse(Object value) {
    if (value is! String) throw const FormatException('Invalid game timestamp');
    final match = _iso.firstMatch(value);
    if (match == null) throw const FormatException('Invalid game timestamp');
    final parts = [for (var i = 1; i <= 6; i++) int.parse(match.group(i)!)];
    final nominal = DateTime.utc(
        parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]);
    if (nominal.year != parts[0] ||
        nominal.month != parts[1] ||
        nominal.day != parts[2] ||
        nominal.hour != parts[3] ||
        nominal.minute != parts[4] ||
        nominal.second != parts[5]) {
      throw const FormatException('Invalid game timestamp');
    }
    final zone = match.group(8);
    if (zone != null && zone != 'Z') {
      final digits = zone.substring(1).replaceAll(':', '');
      if (int.parse(digits.substring(0, 2)) > 23 ||
          int.parse(digits.substring(2)) > 59) {
        throw const FormatException('Invalid game timestamp');
      }
    }
    return DateTime.parse(value);
  }

  /// Call in the ordinary app's device timezone before uploading a legacy
  /// backup. No elapsed timer, game rule, inventory or claimed flag is advanced.
  static Map<String, dynamic> forUpload(Map<String, dynamic> source) {
    final result = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
    _visit(result, (value) => _parse(value).toUtc().toIso8601String());
    return result;
  }

  /// The captured database source must already have explicit offsets. This
  /// check performs no conversion and cannot mint a new migration grant.
  static void requireExplicitInstants(Map<String, dynamic> source) {
    _visit(source, (value) {
      final date = _parse(value);
      if (!date.isUtc) {
        throw const FormatException('Device clock bridge required');
      }
      return value;
    }, write: false);
  }

  static void _visit(
      Map<String, dynamic> state, Object Function(Object) transform,
      {bool write = true}) {
    void fields(Object? object, List<String> names) {
      if (object == null) return;
      if (object is! Map<String, dynamic>) {
        throw const FormatException('Invalid timestamp container');
      }
      for (final name in names) {
        if (object[name] != null) {
          final value = transform(object[name] as Object);
          if (write) object[name] = value;
        }
      }
    }

    void entities(String name, List<String> names) {
      final list = state[name];
      if (list == null) return;
      if (list is! List) {
        throw const FormatException('Invalid timestamp container');
      }
      for (final item in list) {
        fields(item, names);
      }
    }

    fields(state, _root);
    for (final name in _maps) {
      final map = state[name];
      if (map == null) continue;
      if (map is! Map<String, dynamic>) {
        throw const FormatException('Invalid timestamp container');
      }
      fields(map, map.keys.toList());
    }
    for (final name in ['pet', 'incubatingEgg']) {
      fields(state[name], _dragon);
    }
    for (final name in ['sanctuaryDragons', 'releasedDragons']) {
      entities(name, _dragon);
    }
    entities('eggStash', ['acquiredAt']);
    entities('adventureRuns', ['startedAt', 'endsAt']);
    entities('trialOffers', ['appearedAt', 'startedAt']);
    entities('activities', ['createdAt']);
    entities('pendingPresentations', ['createdAt', 'sortAt']);
  }
}
