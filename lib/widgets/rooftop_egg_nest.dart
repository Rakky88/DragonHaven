import 'package:flutter/material.dart';

import '../models/day_phase.dart';
import 'haven_lighting.dart';

class RooftopEggNest extends StatelessWidget {
  const RooftopEggNest({super.key, this.animate = true});

  static const combinedEggNestAsset =
      'assets/images/ui/ui_rooftop_egg_nest_combined.png';

  final bool animate;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final sceneWidth = constraints.maxWidth;
          final sceneHeight = constraints.maxHeight;
          final scale = sceneHeight / 215;
          final artWidth = (148 * scale).clamp(0, sceneWidth * .66).toDouble();
          final artHeight = artWidth / (960 / 700);

          return Stack(
            fit: StackFit.expand,
            children: [
              HavenPhaseImage(
                assetFor: (phase) =>
                    'assets/images/tower_nest_${phase.assetKey}.webp',
              ),
              Positioned(
                left: (sceneWidth - artWidth) / 2,
                bottom: 18 * scale,
                width: artWidth,
                height: artHeight,
                child: Image.asset(
                  combinedEggNestAsset,
                  key: const Key('rooftop-egg-nest-combined'),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          );
        },
      );
}
