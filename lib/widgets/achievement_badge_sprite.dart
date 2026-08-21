import 'package:flutter/material.dart';

import '../models/achievement.dart';

class AchievementBadgeSprite extends StatelessWidget {
  const AchievementBadgeSprite({
    required this.achievement,
    required this.unlocked,
    this.size = 64,
    super.key,
  });

  final AchievementDefinition achievement;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sprite = Image.asset(
      achievement.badgeAsset,
      key: Key('achievement-sprite-${achievement.id}'),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
    if (unlocked) return sprite;
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
      child: sprite,
    );
  }
}
