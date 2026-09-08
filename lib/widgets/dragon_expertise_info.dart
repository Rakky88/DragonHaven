import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import 'dragon_expertise_row.dart';

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
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.pick('Expertise', 'Expertise')),
                  const SizedBox(height: 12),
                  for (final focus in TrainingFocus.values)
                    DragonExpertiseRow(dragon: dragon, focus: focus),
                ],
              ),
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
