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
}

extension GameIconKindAsset on GameIconKind {
  String get assetPath => 'assets/images/ui/ui_${switch (this) {
        GameIconKind.mysteriousEgg => 'mysterious_egg',
        GameIconKind.myDragons => 'my_dragons',
        _ => name,
      }}.webp';
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
