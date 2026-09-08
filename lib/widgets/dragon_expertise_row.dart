import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import 'expertise_score_badge.dart';

/// The same highlight treatment in the editable collection and picker details.
class DragonExpertiseRow extends StatelessWidget {
  const DragonExpertiseRow({
    super.key,
    required this.dragon,
    required this.focus,
    this.onToggle,
  });

  final Pet dragon;
  final TrainingFocus focus;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final highlighted = dragon.highlightedExpertises.contains(focus);
    final label = switch (focus) {
      TrainingFocus.might => s.pick('Might', 'Kracht'),
      TrainingFocus.arcana => 'Arcana',
      TrainingFocus.spirit => s.pick('Spirit', 'Geest'),
    };
    return Semantics(
      selected: highlighted,
      button: onToggle != null,
      label: highlighted
          ? '$label: ${s.pick('Highlighted for training', 'Gemarkeerd voor training')}'
          : null,
      child: Container(
        key: Key('expertise-highlight-${dragon.id}-${focus.name}'),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .6),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(13),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                child: Row(children: [
                  Expanded(
                      child: ExpertiseScoreBadge(
                    dragonId: dragon.id,
                    focus: focus,
                    focusLabel: label,
                    score: dragon.trainingFor(focus),
                    maximum: dragon.expertiseMaximum(focus),
                    iconSize: 30,
                    expand: true,
                    highlighted: highlighted,
                  )),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
