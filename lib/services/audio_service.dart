import 'package:flutter/services.dart';

enum HavenSound {
  uiConfirm('ui_confirm'),
  chestWooden('chest_wooden'),
  chestSilver('chest_silver'),
  chestGold('chest_gold'),
  chestDragon('chest_dragon'),
  chestMythical('chest_mythical'),
  chestSinister('chest_sinister'),
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

/// Small, dependency-free bridge around DragonHaven's Android audio layer.
///
/// Android resolves these stable IDs from the bundled `res/raw` CC0 library.
/// Music and effects remain independently gated. Failures stay non-fatal so a
/// device audio problem can never block gameplay or saving preferences.
abstract final class HavenAudio {
  static const _channel = MethodChannel('nl.dragonhaven.app/audio');
  static bool _musicEnabled = true;
  static bool _effectsEnabled = true;
  static HavenMusicScene? _musicScene;

  static Future<void> applyPreferences({
    required bool musicEnabled,
    required bool soundEffectsEnabled,
  }) async {
    _musicEnabled = musicEnabled;
    _effectsEnabled = soundEffectsEnabled;
    try {
      await _channel.invokeMethod<void>('setPreferences', {
        'music': musicEnabled,
        'effects': soundEffectsEnabled,
        'scene': _musicScene?.assetId,
      });
    } on MissingPluginException {
      // Widget tests and unsupported platforms intentionally have no bridge.
    } on PlatformException {
      // Audio must never block saving a player preference.
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
    if (_musicScene == scene) return;
    _musicScene = scene;
    if (!_musicEnabled) return;
    try {
      await _channel.invokeMethod<void>('setMusicScene', {'id': scene.assetId});
    } on MissingPluginException {
      // See applyPreferences.
    } on PlatformException {
      // A device audio failure must not interrupt gameplay.
    }
  }
}
