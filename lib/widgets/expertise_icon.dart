import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/pet.dart';
import 'game_icon_sprite.dart';

/// A soft bloom follows the actual sprite silhouette, keeping its original art.
class ExpertiseIcon extends StatelessWidget {
  const ExpertiseIcon({
    super.key,
    required this.focus,
    required this.size,
    this.highlighted = false,
  });

  final TrainingFocus focus;
  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = switch (focus) {
      TrainingFocus.might => const Color(0xFFFFB62E),
      TrainingFocus.arcana => const Color(0xFFC681FF),
      TrainingFocus.spirit => const Color(0xFF57E3B0),
    };
    final kind = GameIconSprite.forTrainingFocus(focus);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: highlighted ? 1 : 0),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      child: GameIconSprite(kind, size: size),
      builder: (context, glow, child) => SizedBox.square(
        dimension: size,
        child: Stack(clipBehavior: Clip.none, children: [
          if (glow > 0)
            Positioned.fill(
              child: ExcludeSemantics(
                child: Opacity(
                  opacity: glow,
                  child: Transform.scale(
                    scale: 1.16,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                        child: GameIconSprite(kind, size: size),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(child: child!),
          if (glow > 0)
            Positioned.fill(
              child: ExcludeSemantics(
                child: Opacity(
                  opacity: glow * .16,
                  child: ColorFiltered(
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    child: GameIconSprite(kind, size: size),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
