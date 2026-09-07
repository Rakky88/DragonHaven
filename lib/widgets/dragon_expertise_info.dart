import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import 'expertise_score_badge.dart';

/// A separate tap target: inspecting a dragon never selects it for an adventure.
class DragonExpertiseInfo extends StatelessWidget {
  const DragonExpertiseInfo({super.key, required this.dragon});

  final Pet dragon;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return IconButton(
      key: Key('dragon-expertise-info-${dragon.id}'),
      tooltip: s.pick('View all Expertise', 'Alle Expertises bekijken'),
      iconSize: 19,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.info_outline_rounded),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(dragon.displayName),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.pick('Expertise', 'Expertise')),
                const SizedBox(height: 12),
                for (final focus in TrainingFocus.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ExpertiseScoreBadge(
                      dragonId: dragon.id,
                      focus: focus,
                      focusLabel: switch (focus) {
                        TrainingFocus.might => 'Might',
                        TrainingFocus.arcana => 'Arcana',
                        TrainingFocus.spirit => 'Spirit',
                      },
                      score: dragon.trainingFor(focus),
                      maximum: dragon.expertiseMaximum(focus),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.pick('Close', 'Sluiten')))
          ],
        ),
      ),
    );
  }
}
