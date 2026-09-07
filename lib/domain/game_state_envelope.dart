/// Preserve forward-compatible metadata while replacing every field owned by
/// the current rules. Counts, claims and whole inventories are authoritative:
/// this never unions deleted inventory entries back into an exported state.
abstract final class GameStateEnvelope {
  static Map<String, dynamic> preserveUnknownMetadata(
      Map<String, dynamic> source, Map<String, dynamic> exported) {
    final entities = <String, Map<String, dynamic>>{};
    void collect(Object? value) {
      if (value is Map && value['id'] is String) {
        entities[value['id'] as String] = Map<String, dynamic>.from(value);
      }
    }

    for (final key in const ['pet', 'incubatingEgg']) {
      collect(source[key]);
    }
    for (final key in const [
      'eggStash',
      'sanctuaryDragons',
      'releasedDragons',
    ]) {
      for (final value in source[key] as List? ?? const []) {
        collect(value);
      }
    }
    Map<String, dynamic> merge(Object? value) {
      final next = Map<String, dynamic>.from(value as Map);
      return {...?entities[next['id']], ...next};
    }

    return {
      ...source,
      ...exported,
      'pet': merge(exported['pet']),
      'incubatingEgg': exported['incubatingEgg'] == null
          ? null
          : merge(exported['incubatingEgg']),
      for (final key in const [
        'eggStash',
        'sanctuaryDragons',
        'releasedDragons'
      ])
        key: [for (final value in exported[key] as List) merge(value)],
    };
  }
}
