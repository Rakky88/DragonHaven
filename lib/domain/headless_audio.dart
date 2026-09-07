import '../models/audio_settings.dart';
export '../models/audio_settings.dart';

/// Audio belongs to the device displaying the committed result. These methods
/// intentionally perform no platform calls or shared preference mutations.
abstract final class HavenAudio {
  static Future<void> applyPreferences({
    required bool musicEnabled,
    required bool soundEffectsEnabled,
    required HavenMusicStyle musicStyle,
  }) async {}

  static Future<void> configureJukebox({
    required Iterable<String> trackIds,
    required bool shuffle,
    required bool repeat,
  }) async {}
}
