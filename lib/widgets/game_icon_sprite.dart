import 'package:flutter/material.dart';

import '../models/pet.dart';

enum GameIconKind {
  coin,
  gem,
  experience,
  mysteriousEgg,
  clock,
  might,
  arcana,
  spirit,
  chest,
  myDragons,
  draconomicon,
  adventureMini,
  adventureShort,
  adventureLong,
  adventureGroup,
  adventureSpecial,
  adventureActive,
  adventureStart,
  roomDecorate,
  roomClear,
  towerBuild,
  roomZoomOut,
  navAdventure,
  navInventory,
  navTower,
  navFriends,
  navShop,
  inventoryEggs,
  inventoryChests,
  inventoryFurniture,
  screenAchievements,
  screenAccount,
  audioMusic,
  audioSfx,
  friendsAdd,
  friendsTrade,
  friendsVisit,
  nameDragon,
}

extension GameIconKindAsset on GameIconKind {
  String get assetPath => 'assets/images/ui/ui_${switch (this) {
        GameIconKind.mysteriousEgg => 'mysterious_egg',
        GameIconKind.myDragons => 'my_dragons',
        GameIconKind.adventureMini => 'adventure_short',
        GameIconKind.adventureShort => 'adventure_short',
        GameIconKind.adventureLong => 'adventure_long',
        GameIconKind.adventureGroup => 'adventure_group',
        GameIconKind.adventureSpecial => 'adventure_special',
        GameIconKind.adventureActive => 'adventure_active',
        GameIconKind.adventureStart => 'adventure_start',
        GameIconKind.roomDecorate => 'room_decorate',
        GameIconKind.roomClear => 'room_clear',
        GameIconKind.towerBuild => 'tower_build',
        GameIconKind.roomZoomOut => 'room_zoom_out',
        GameIconKind.navAdventure => 'nav_adventure',
        GameIconKind.navInventory => 'nav_stash',
        GameIconKind.navTower => 'nav_tower',
        GameIconKind.navFriends => 'nav_friends',
        GameIconKind.navShop => 'nav_shop',
        GameIconKind.inventoryEggs => 'stash_eggs',
        GameIconKind.inventoryChests => 'stash_chests',
        GameIconKind.inventoryFurniture => 'stash_furniture',
        GameIconKind.screenAchievements => 'screen_achievements',
        GameIconKind.screenAccount => 'screen_account',
        GameIconKind.audioMusic => 'audio_music',
        GameIconKind.audioSfx => 'audio_sfx',
        GameIconKind.friendsAdd => 'friends_add',
        GameIconKind.friendsTrade => 'friends_trade',
        GameIconKind.friendsVisit => 'friends_visit',
        GameIconKind.nameDragon => 'name_dragon',
        _ => name,
      }}.webp'
          .replaceFirst('ui_adventure_', 'adventure_')
          .replaceFirst('ui_room_', 'room_')
          .replaceFirst('ui_tower_', 'tower_')
          .replaceFirst('ui_nav_', 'nav_')
          .replaceFirst('ui_stash_', 'stash_')
          .replaceFirst('ui_screen_', 'screen_')
          .replaceFirst('ui_audio_', 'audio_')
          .replaceFirst('ui_friends_', 'friends_')
          .replaceFirst('ui_name_dragon', 'name_dragon');
}

class GameIconSprite extends StatelessWidget {
  const GameIconSprite(
    this.kind, {
    super.key,
    this.size = 24,
    this.semanticLabel,
  });

  final GameIconKind kind;
  final double size;
  final String? semanticLabel;

  static GameIconKind forTrainingFocus(TrainingFocus focus) => switch (focus) {
        TrainingFocus.might => GameIconKind.might,
        TrainingFocus.arcana => GameIconKind.arcana,
        TrainingFocus.spirit => GameIconKind.spirit,
      };

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      kind.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
    if (semanticLabel == null) return ExcludeSemantics(child: image);
    return Semantics(image: true, label: semanticLabel, child: image);
  }
}

abstract final class GameVfxAssets {
  static const chestBurst = 'assets/images/ui/vfx_chest_burst.webp';
  static const spectralAura = 'assets/images/ui/vfx_spectral_aura.webp';
}
