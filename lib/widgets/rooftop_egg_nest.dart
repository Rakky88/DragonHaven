import 'package:flutter/material.dart';

import '../models/day_phase.dart';
import 'dragon_art.dart';
import 'haven_lighting.dart';

class RooftopEggNest extends StatelessWidget {
  const RooftopEggNest({super.key, this.animate = true});

  static const birdNestAsset =
      'assets/images/ui/ui_rooftop_nest_foreground.png';

  final bool animate;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final sceneWidth = constraints.maxWidth;
          final sceneHeight = constraints.maxHeight;
          final scale = sceneHeight / 215;
          final nestWidth = (128 * scale).clamp(0, sceneWidth * .62).toDouble();
          final nestHeight = 68 * scale;
          final eggWidth = 62 * scale;
          final eggHeight = 72 * scale;
          final eggArtHeight = 66 * scale;

          return Stack(
            fit: StackFit.expand,
            children: [
              HavenPhaseImage(
                assetFor: (phase) =>
                    'assets/images/tower_nest_${phase.assetKey}.webp',
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 39 * scale,
                child: Center(
                  child: SizedBox(
                    width: eggWidth,
                    height: eggHeight,
                    child: Center(
                      child: DragonArt(
                        key: const Key('rooftop-nest-egg'),
                        height: eggArtHeight,
                        stageKey: 'moonEgg',
                        animate: animate,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (sceneWidth - nestWidth) / 2,
                bottom: 25 * scale,
                width: nestWidth,
                height: nestHeight,
                child: Image.asset(
                  birdNestAsset,
                  key: const Key('rooftop-bird-nest-front'),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          );
        },
      );
}
