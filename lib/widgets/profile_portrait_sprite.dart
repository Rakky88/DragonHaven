import 'package:flutter/material.dart';

import '../models/profile_portrait.dart';
import 'game_icon_sprite.dart';

class ProfilePortraitSprite extends StatelessWidget {
  const ProfilePortraitSprite({
    super.key,
    required this.portrait,
    this.size = 88,
  });

  final ProfilePortrait? portrait;
  final double size;

  /// Every portrait has a deliberately transparent outer safety margin.
  /// Overscan it just beyond the oval clip so even compact friend portraits
  /// remain completely filled at device-pixel rounding boundaries.
  static const portraitFillScale = 1.68;

  @override
  Widget build(BuildContext context) {
    final selected = portrait;
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: selected == null
            ? GameIconSprite(GameIconKind.screenAccount, size: size)
            : Transform.scale(
                // The Supporter portrait is delivered as a complete circular
                // medallion and therefore must not use the overscan needed by
                // the regular transparent portrait cut-outs.
                scale: selected.supporterExclusive ? 1 : portraitFillScale,
                child: Image.asset(
                  selected.assetPath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  semanticLabel: 'Dragonkeeper portrait',
                ),
              ),
      ),
    );
  }
}
