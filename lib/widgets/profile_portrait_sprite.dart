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

  @override
  Widget build(BuildContext context) {
    final selected = portrait;
    return SizedBox.square(
      dimension: size,
      child: selected == null
          ? GameIconSprite(GameIconKind.screenAccount, size: size)
          : Image.asset(
              selected.assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: 'Dragonkeeper portrait',
            ),
    );
  }
}
