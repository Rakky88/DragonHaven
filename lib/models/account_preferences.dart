import 'audio_settings.dart';
import 'notification_settings.dart';
import 'music_track.dart';

/// Only presentation preferences. Ownership, rewards and device permissions
/// cannot be modified through this allowlist.
abstract final class AccountPreferences {
  static const defaults = <String, dynamic>{
    'languageCode': 'en',
    'musicEnabled': true,
    'musicStyle': 'classic',
    'soundEffectsEnabled': true,
    'enabledMusicTrackIds': ['reverie'],
    'disabledSeasonalMusicTrackIds': <String>[],
    'jukeboxShuffle': false,
    'jukeboxRepeat': true,
    'enabledNotificationCategories': <String>[],
    'achievementsCompact': false,
    'myDragonsViewMode': 'gallery',
    'myDragonsSortMode': 'acquiredAt',
    'myDragonsSortDescending': true,
    'eggInventoryViewMode': 'tiles',
    'eggInventorySortMode': 'acquiredAt',
    'eggInventorySortDescending': true,
  };

  static Map<String, dynamic> validateChanges(Object? raw) {
    if (raw is! Map || raw.isEmpty || raw.length > defaults.length) {
      throw const FormatException('Invalid account preferences');
    }
    final result = <String, dynamic>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || !defaults.containsKey(key)) {
        throw const FormatException('Unknown account preference');
      }
      final allowed = switch (key) {
        'languageCode' => const [
            'en',
            'nl',
            'de',
            'fr',
            'es',
            'pt',
            'it',
            'ja'
          ],
        'musicStyle' => HavenMusicStyle.values.map((s) => s.name),
        'myDragonsViewMode' => const ['gallery', 'compact'],
        'myDragonsSortMode' => const [
            'name',
            'dragonType',
            'acquiredAt',
            'rarity'
          ],
        'eggInventoryViewMode' => const ['tiles', 'list'],
        'eggInventorySortMode' => const ['acquiredAt', 'hatchTime'],
        _ => null,
      };
      if (allowed != null) {
        if (value is! String || !allowed.contains(value)) {
          throw const FormatException('Invalid preference value');
        }
        result[key] = value;
      } else if (defaults[key] is bool) {
        if (value is! bool) throw const FormatException('Expected boolean');
        result[key] = value;
      } else {
        if (value is! List ||
            value.length > 100 ||
            value.any((v) =>
                v is! String ||
                v.isEmpty ||
                v.length > 100 ||
                !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v))) {
          throw const FormatException('Invalid preference collection');
        }
        if (key == 'enabledNotificationCategories' &&
            value.any((v) => !HavenNotificationCategory.values
                .any((category) => category.name == v))) {
          throw const FormatException('Unknown notification category');
        }
        if (key == 'disabledSeasonalMusicTrackIds' &&
            value.any(
                (v) => !seasonalMusicCatalog.any((track) => track.id == v))) {
          throw const FormatException('Unknown seasonal music');
        }
        result[key] = List<String>.unmodifiable(value.cast<String>().toSet());
      }
    }
    return Map.unmodifiable(result);
  }

  static Map<String, dynamic> fromState(Map<String, dynamic> state) =>
      validateChanges({
        for (final entry in defaults.entries)
          entry.key: state[entry.key] ?? entry.value
      });
}
