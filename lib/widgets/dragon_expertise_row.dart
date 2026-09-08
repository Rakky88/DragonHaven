import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import '../theme/app_theme.dart';
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
      child: AnimatedContainer(
        key: Key('expertise-highlight-${dragon.id}-${focus.name}'),
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: highlighted
              ? const Color(0xFFFFF4CD)
              : Colors.white.withValues(alpha: .6),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
              color: highlighted ? AppColors.gold : Colors.transparent),
          boxShadow: highlighted
              ? const [BoxShadow(color: Color(0x33F4C95D), blurRadius: 12)]
              : const [],
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
                    iconSize: 24,
                    expand: true,
                  )),
                  const SizedBox(width: 10),
                  Icon(
                      highlighted
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 21,
                      color: highlighted
                          ? const Color(0xFF916408)
                          : AppColors.muted),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
