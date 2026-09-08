import 'package:flutter/material.dart';

import '../models/pet.dart';
import 'expertise_icon.dart';

class ExpertiseScoreBadge extends StatelessWidget {
  const ExpertiseScoreBadge({
    super.key,
    required this.dragonId,
    required this.focus,
    required this.focusLabel,
    required this.score,
    required this.maximum,
    this.iconSize = 21,
    this.expand = false,
    this.highlighted = false,
  });

  static const maxAsset = 'assets/images/ui/ui_expertise_max.png';

  final String dragonId;
  final TrainingFocus focus;
  final String focusLabel;
  final int score;
  final int maximum;
  final double iconSize;
  final bool expand;
  final bool highlighted;

  bool get isMaxed => score >= maximum;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            expand ? CrossAxisAlignment.stretch : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExpertiseIcon(
                focus: focus,
                size: iconSize,
                highlighted: highlighted,
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
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (isMaxed) ...[
            const SizedBox(height: 2),
            Align(
                alignment: Alignment.centerRight,
                widthFactor: expand ? null : 1,
                child: Image.asset(
                  maxAsset,
                  key: Key('expertise-max-$dragonId-${focus.name}'),
                  width: 52,
                  height: 17,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  semanticLabel: '$focusLabel maximum',
                )),
          ],
        ],
      );
}
