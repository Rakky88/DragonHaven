import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/achievement.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(strings.tr('achievements'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          Card(
            color: AppColors.twilightDark,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Color(0xFFFFD568), size: 36),
                const SizedBox(width: 14),
                Text('${game.unlockedAchievementIds.length} / 20 unlocked',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
          for (final category in AchievementCategory.values) ...[
            const SizedBox(height: 22),
            Text(_categoryName(category, strings),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final achievement in achievementCatalog
                .where((item) => item.category == category))
              _AchievementTile(achievement: achievement),
          ],
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final AchievementDefinition achievement;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final unlocked = game.unlockedAchievementIds.contains(achievement.id);
    final progress = game
        .achievementProgress(achievement.id)
        .clamp(0, achievement.target)
        .toInt();
    final hidden = achievement.secret && !unlocked;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: unlocked ? Colors.white : const Color(0xFFF1EFF4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              unlocked ? const Color(0xFFFFE5A6) : const Color(0xFFCCC8D2),
          child: Icon(
            unlocked ? Icons.emoji_events_rounded : Icons.lock_rounded,
            color: unlocked ? const Color(0xFF9A6A00) : AppColors.muted,
          ),
        ),
        title: Text(
            hidden
                ? '???'
                : strings.isDutch
                    ? achievement.titleNl
                    : achievement.titleEn,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(hidden
                ? '???'
                : strings.isDutch
                    ? achievement.descriptionNl
                    : achievement.descriptionEn),
            if (!unlocked) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value:
                    achievement.target == 0 ? 1 : progress / achievement.target,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 3),
              Text('$progress / ${achievement.target}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

String _categoryName(AchievementCategory category, AppStrings strings) =>
    switch (category) {
      AchievementCategory.starter => 'Starter',
      AchievementCategory.easy => strings.pick('Easy', 'Makkelijk'),
      AchievementCategory.challenging =>
        strings.pick('Challenging', 'Uitdagend'),
      AchievementCategory.master => 'Master',
    };
