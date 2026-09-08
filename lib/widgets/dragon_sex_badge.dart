import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import '../theme/app_theme.dart';

class DragonSexBadge extends StatelessWidget {
  const DragonSexBadge({super.key, required this.dragon});

  final Pet dragon;

  @override
  Widget build(BuildContext context) {
    if (dragon.isEgg) return const SizedBox.shrink();
    final s = AppStrings.of(context);
    final male = dragon.sex == DragonSex.male;
    final label =
        male ? s.pick('Male', 'Mannelijk') : s.pick('Female', 'Vrouwelijk');
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Container(
          key: Key('dragon-sex-${dragon.id}'),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.eventColor(context, const Color(0xFFF1ECFB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(male ? Icons.male_rounded : Icons.female_rounded,
              size: 17,
              color: AppColors.eventColor(context, AppColors.twilight)),
        ),
      ),
    );
  }
}
