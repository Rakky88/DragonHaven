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
}

extension GameIconKindAsset on GameIconKind {
  String get assetPath => 'assets/images/ui/ui_${switch (this) {
        GameIconKind.mysteriousEgg => 'mysterious_egg',
        GameIconKind.myDragons => 'my_dragons',
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
        _ => name,
      }}.webp'
          .replaceFirst('ui_adventure_', 'adventure_')
          .replaceFirst('ui_room_', 'room_')
          .replaceFirst('ui_tower_', 'tower_');
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
