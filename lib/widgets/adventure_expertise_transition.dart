import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/pet.dart';
import '../theme/app_theme.dart';
import 'game_icon_sprite.dart';

/// A compact, amount-free summary of the expertise an Adventure trades.
///
/// Adventure details retain the exact values. List cards only need to make the
/// direction and affected expertise clear before the player opens the details.
class AdventureExpertiseTransition extends StatelessWidget {
  const AdventureExpertiseTransition({
    super.key,
    required this.definition,
    required this.keyPrefix,
  });

  final AdventureDefinition definition;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final specialRewards = specialAdventureEventForAdventure(definition.id)
        ?.rewards
        .expertiseRewards;
    final rewards = specialRewards?.isNotEmpty == true
        ? specialRewards!
        : definition.expertiseRewards;
    final orderedRewards = rewards.entries.toList(growable: false)
      ..sort((a, b) =>
          TrainingFocus.values.indexOf(a.key) -
          TrainingFocus.values.indexOf(b.key));
    final losses = orderedRewards
        .where((entry) => entry.value < 0)
        .toList(growable: false);
    final gains = orderedRewards
        .where((entry) => entry.value > 0)
        .toList(growable: false);

    final changes = <({TrainingFocus focus, bool gain})>[
      for (final entry in losses) (focus: entry.key, gain: false),
      for (final entry in gains) (focus: entry.key, gain: true),
    ];
    if (changes.isEmpty) return const SizedBox.shrink();

    final semantics = changes
        .map((change) => strings.pick(
              '${_focusName(strings, change.focus)} ${change.gain ? 'increases' : 'decreases'}',
              '${_focusName(strings, change.focus)} ${change.gain ? 'stijgt' : 'daalt'}',
            ))
        .join('; ');

    return Semantics(
      key: Key('$keyPrefix-summary'),
      container: true,
      label: strings.pick(
        'Expertise change: $semantics',
        'Expertisewijziging: $semantics',
      ),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 5,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final change in changes)
              _ExpertiseDirection(
                key: Key(
                  '$keyPrefix-${change.gain ? 'gain' : 'loss'}-${change.focus.name}',
                ),
                focus: change.focus,
                label: _focusName(strings, change.focus),
                gain: change.gain,
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpertiseDirection extends StatelessWidget {
  const _ExpertiseDirection({
    super.key,
    required this.focus,
    required this.label,
    required this.gain,
  });

  final TrainingFocus focus;
  final String label;
  final bool gain;

  @override
  Widget build(BuildContext context) {
    final foreground = gain ? const Color(0xFF26745F) : const Color(0xFF9B4555);
    final background = gain ? AppColors.mintLight : const Color(0xFFFFE7E6);
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 5, 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withValues(alpha: .22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIconSprite(
            GameIconSprite.forTrainingFocus(focus),
            size: 18,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 1),
          Icon(
            gain ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 13,
            color: foreground,
          ),
        ],
      ),
    );
  }
}

String _focusName(AppStrings strings, TrainingFocus focus) => switch (focus) {
      TrainingFocus.might => strings.pick('Might', 'Kracht'),
      TrainingFocus.arcana => 'Arcana',
      TrainingFocus.spirit => strings.pick('Spirit', 'Geest'),
    };
