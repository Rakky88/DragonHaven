import 'package:flutter/material.dart';

import '../models/pet.dart';
import 'game_icon_sprite.dart';

class ExpertiseScoreBadge extends StatelessWidget {
  const ExpertiseScoreBadge({
    super.key,
    required this.dragonId,
    required this.focus,
    required this.focusLabel,
    required this.score,
    this.iconSize = 21,
    this.expand = false,
  });

  static const maxAsset = 'assets/images/ui/ui_expertise_max.png';

  final String dragonId;
  final TrainingFocus focus;
  final String focusLabel;
  final int score;
  final double iconSize;
  final bool expand;

  bool get isMaxed => score >= maxDragonExpertise;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameIconSprite(
            GameIconSprite.forTrainingFocus(focus),
            size: iconSize,
          ),
          const SizedBox(width: 4),
          Text(
            focusLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 3),
          if (expand) const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (isMaxed) ...[
                const SizedBox(height: 2),
                Image.asset(
                  maxAsset,
                  key: Key('expertise-max-$dragonId-${focus.name}'),
                  width: 52,
                  height: 17,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  semanticLabel: '$focusLabel maximum',
                ),
              ],
            ],
          ),
        ],
      );
}
