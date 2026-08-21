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
        key: const PageStorageKey('achievements-scroll'),
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
                Expanded(
                  child: Text(
                    '${game.unlockedAchievementIds.length} / 20 unlocked',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
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
            hidden ? Icons.question_mark_rounded : _badgeIcon(achievement.id),
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

IconData _badgeIcon(String id) => switch (id) {
      'hello_little_one' => Icons.egg_alt_rounded,
      'first_flight' => Icons.flight_takeoff_rounded,
      'chest_expectations' => Icons.inventory_2_rounded,
      'room_to_roost' => Icons.add_home_work_rounded,
      'feed_furniture' => Icons.chair_alt_rounded,
      'book_wyrm' => Icons.menu_book_rounded,
      'growing_pains' => Icons.trending_up_rounded,
      'not_picking_favorites' => Icons.favorite_rounded,
      'halfway_clouds' => Icons.cloud_rounded,
      'ascension_day' => Icons.auto_awesome_rounded,
      'something_spectral' => Icons.blur_on_rounded,
      'well_read_scaled' => Icons.auto_stories_rounded,
      'frequent_flyer' => Icons.airplanemode_active_rounded,
      'full_party' => Icons.groups_rounded,
      'came_crawling_back' => Icons.u_turn_left_rounded,
      'sky_ceiling' => Icons.vertical_align_top_rounded,
      'scale_every_tale' => Icons.library_books_rounded,
      'ghost_writer' => Icons.history_edu_rounded,
      'myth_made_real' => Icons.workspace_premium_rounded,
      'probably_fine' => Icons.local_fire_department_rounded,
      _ => Icons.emoji_events_rounded,
    };

String _categoryName(AchievementCategory category, AppStrings strings) =>
    switch (category) {
      AchievementCategory.starter => 'Starter',
      AchievementCategory.easy => strings.pick('Easy', 'Makkelijk'),
      AchievementCategory.challenging =>
        strings.pick('Challenging', 'Uitdagend'),
      AchievementCategory.master => 'Master',
    };
