import 'package:flutter/services.dart';

enum HavenSound {
  uiConfirm('ui_confirm'),
  chestWooden('chest_wooden'),
  chestSilver('chest_silver'),
  chestGold('chest_gold'),
  chestDragon('chest_dragon'),
  chestMythical('chest_mythical'),
  chestSinister('chest_sinister'),
  chestSpecial('chest_special'),
  hatchBuild('hatch_build'),
  hatchCrackOne('hatch_crack_1'),
  hatchCrackTwo('hatch_crack_2'),
  hatchCrackThree('hatch_crack_3'),
  hatchReveal('hatch_reveal'),
  spectralReveal('spectral_reveal'),
  evolutionYoung('evolution_young'),
  evolutionAscended('evolution_ascended'),
  achievement('achievement'),
  adventureStart('adventure_start'),
  adventureReturn('adventure_return'),
  floorBuilt('floor_built');

  const HavenSound(this.assetId);
  final String assetId;
}

enum HavenMusicScene {
  towerDay('tower_day'),
  towerNight('tower_night'),
  room('room'),
  reveal('reveal');

  const HavenMusicScene(this.assetId);
  final String assetId;
}

enum HavenMusicStyle {
  classic('classic');

  const HavenMusicStyle(this.assetId);
  final String assetId;
}

/// Small, dependency-free bridge around DragonHaven's Android audio layer.
///
/// Android resolves these stable IDs from the bundled `res/raw` audio library.
/// Music and effects remain independently gated. Failures stay non-fatal so a
/// device audio problem can never block gameplay or saving preferences.
abstract final class HavenAudio {
  static const _channel = MethodChannel('nl.dragonhaven.app/audio');
  static bool _musicEnabled = true;
  static bool _effectsEnabled = true;
  static HavenMusicStyle _musicStyle = HavenMusicStyle.classic;
  static HavenMusicScene? _musicScene;
  static List<String> _jukeboxTrackIds = const ['music_reverie'];
  static bool _jukeboxShuffle = false;
  static bool _jukeboxRepeat = true;
  static bool _appInForeground = false;

  static Future<void> applyPreferences({
    required bool musicEnabled,
    required bool soundEffectsEnabled,
    required HavenMusicStyle musicStyle,
  }) async {
    _musicEnabled = musicEnabled;
    _effectsEnabled = soundEffectsEnabled;
    _musicStyle = musicStyle;
    try {
      await _channel.invokeMethod<void>('setPreferences', {
        'music': musicEnabled,
        'effects': soundEffectsEnabled,
        'style': _musicStyle.assetId,
        'scene': _musicScene?.assetId,
        'tracks': _jukeboxTrackIds,
        'shuffle': _jukeboxShuffle,
        'repeat': _jukeboxRepeat,
      });
    } on MissingPluginException {
      // Widget tests and unsupported platforms intentionally have no bridge.
    } on PlatformException {
      // Audio must never block saving a player preference.
    }
  }

  static Future<void> configureJukebox({
    required Iterable<String> trackIds,
    required bool shuffle,
    required bool repeat,
  }) async {
    _jukeboxTrackIds = List.unmodifiable(trackIds);
    _jukeboxShuffle = shuffle;
    _jukeboxRepeat = repeat;
    try {
      await _channel.invokeMethod<void>('setJukebox', {
        'tracks': _jukeboxTrackIds,
        'shuffle': shuffle,
        'repeat': repeat,
      });
    } on MissingPluginException {
      // Widget tests and unsupported platforms intentionally have no bridge.
    } on PlatformException {
      // Audio must never block saving a jukebox preference.
    }
  }

  static Future<void> play(HavenSound sound) async {
    if (!_effectsEnabled) return;
    try {
      await _channel.invokeMethod<void>('playSound', {'id': sound.assetId});
    } on MissingPluginException {
      // See applyPreferences.
    } on PlatformException {
      // A device audio failure must not interrupt gameplay.
    }
  }

  static Future<void> setMusicScene(HavenMusicScene scene) async {
    _musicScene = scene;
    if (!_musicEnabled || !_appInForeground) return;
    try {
      await _channel.invokeMethod<void>('setMusicScene', {'id': scene.assetId});
    } on MissingPluginException {
      // See applyPreferences.
    } on PlatformException {
      // A device audio failure must not interrupt gameplay.
    }
  }

  static Future<void> setAppInForeground(bool foreground) async {
    _appInForeground = foreground;
    try {
      await _channel.invokeMethod<void>('setAppForeground', {
        'foreground': foreground,
      });
    } on MissingPluginException {
      // Widget tests and unsupported platforms intentionally have no bridge.
    } on PlatformException {
      // Lifecycle audio failures must never interrupt the app.
    }
  }
}
