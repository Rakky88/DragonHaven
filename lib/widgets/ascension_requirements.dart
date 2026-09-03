import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import '../theme/app_theme.dart';

/// Displays the two independent gates that must both be complete before a
/// Wyrmling can Ascend.
class AscensionRequirements extends StatelessWidget {
  const AscensionRequirements({
    super.key,
    required this.dragon,
    this.onDark = false,
    this.compact = false,
    this.includeLevelRequirement = true,
  });

  final Pet dragon;
  final bool onDark;
  final bool compact;
  final bool includeLevelRequirement;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final targetLevel = Pet.levelAtXp(Pet.ascendedXp);
    final levelReady = dragon.xp >= Pet.ascendedXp;
    final expertiseReady =
        dragon.totalTraining >= Pet.ascensionExpertiseRequirement;
    final foreground = onDark ? Colors.white : AppColors.ink;
    final muted = onDark ? const Color(0xFFD8CFF1) : AppColors.muted;
    final track = onDark
        ? Colors.white.withValues(alpha: .14)
        : AppColors.mist.withValues(alpha: .8);

    return Container(
      key: const Key('ascension-requirements'),
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 13),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: .08)
            : AppColors.mist.withValues(alpha: .48),
        borderRadius: BorderRadius.circular(compact ? 14 : 17),
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: .14)
              : AppColors.twilight.withValues(alpha: .12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: compact ? 17 : 19,
                color: onDark ? const Color(0xFFFFE39A) : AppColors.gold,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  strings.pick(
                    'Ascension requirements',
                    'Ascension-vereisten',
                  ),
                  style: TextStyle(
                    color: foreground,
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (levelReady && expertiseReady) _ReadyPill(onDark: onDark),
            ],
          ),
          if (includeLevelRequirement) ...[
            SizedBox(height: compact ? 3 : 5),
            Text(
              strings.pick(
                'Complete both requirements before Ascension.',
                'Voltooi beide vereisten voor Ascension.',
              ),
              style: TextStyle(
                color: muted,
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: compact ? 9 : 12),
            _RequirementProgress(
              key: const Key('ascension-level-requirement'),
              statusKey: const Key('ascension-level-status'),
              title: strings.pick('Level & XP', 'Niveau & XP'),
              value:
                  '${strings.pick('Level', 'Niveau')} ${dragon.level}/$targetLevel'
                  ' · ${dragon.xp}/${Pet.ascendedXp} XP',
              progress: dragon.xp / Pet.ascendedXp,
              complete: levelReady,
              foreground: foreground,
              muted: muted,
              track: track,
              compact: compact,
            ),
            SizedBox(height: compact ? 9 : 12),
          ] else
            SizedBox(height: compact ? 7 : 10),
          _RequirementProgress(
            key: const Key('ascension-expertise-requirement'),
            statusKey: const Key('ascension-expertise-status'),
            title: strings.pick(
              'Minimum total Expertise',
              'Minimale totale Expertise',
            ),
            value:
                '${dragon.totalTraining}/${Pet.ascensionExpertiseRequirement}',
            progress: dragon.totalTraining / Pet.ascensionExpertiseRequirement,
            complete: expertiseReady,
            foreground: foreground,
            muted: muted,
            track: track,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _ReadyPill extends StatelessWidget {
  const _ReadyPill({required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      key: const Key('ascension-ready'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: onDark ? .24 : .18),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 13, color: AppColors.mint),
          const SizedBox(width: 3),
          Text(
            strings.pick('Ready', 'Klaar'),
            style: TextStyle(
              color: onDark ? Colors.white : AppColors.twilightDark,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementProgress extends StatelessWidget {
  const _RequirementProgress({
    super.key,
    required this.statusKey,
    required this.title,
    required this.value,
    required this.progress,
    required this.complete,
    required this.foreground,
    required this.muted,
    required this.track,
    required this.compact,
  });

  final Key statusKey;
  final String title;
  final String value;
  final double progress;
  final bool complete;
  final Color foreground;
  final Color muted;
  final Color track;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              key: statusKey,
              width: compact ? 20 : 23,
              height: compact ? 20 : 23,
              decoration: BoxDecoration(
                color: complete
                    ? AppColors.mint.withValues(alpha: .18)
                    : AppColors.gold.withValues(alpha: .16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                complete ? Icons.check_rounded : Icons.lock_clock_rounded,
                size: compact ? 13 : 15,
                color: complete ? AppColors.mint : AppColors.gold,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: foreground,
                  fontSize: compact ? 11 : 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: complete ? AppColors.mint : muted,
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: compact ? 5 : 6,
            color: complete ? AppColors.mint : AppColors.gold,
            backgroundColor: track,
          ),
        ),
      ],
    );
  }
}
