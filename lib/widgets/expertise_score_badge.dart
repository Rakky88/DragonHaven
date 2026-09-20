import '../l10n/app_strings.dart';
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
        ],
      );
}

/// Whole-dragon budget state; unrevealed capacity is never printed.
class DragonExpertiseStatus extends StatelessWidget {
  const DragonExpertiseStatus(
      {super.key, required this.dragonId, required this.maxed, this.spark});
  final String dragonId;
  final bool maxed;
  final int? spark;
  @override
  Widget build(BuildContext context) {
    if (!maxed && spark == null) return const SizedBox.shrink();
    final s = AppStrings.of(context);
    return Row(children: [
      if (spark != null)
        Expanded(
            child: Text('${s.pick('Dragon Spark', 'Drakenvonk')}: +$spark',
                key: Key('dragon-spark-$dragonId'),
                style: const TextStyle(fontWeight: FontWeight.w700))),
      if (maxed)
        Image.asset(ExpertiseScoreBadge.maxAsset,
            key: Key('expertise-max-$dragonId'),
            width: 62,
            height: 22,
            semanticLabel: s.pick('Fully trained', 'Volledig getraind')),
    ]);
  }
}
