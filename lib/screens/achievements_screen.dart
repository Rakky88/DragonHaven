import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/achievement.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/achievement_badge_sprite.dart';
import '../widgets/game_icon_sprite.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tr('achievements')),
        actions: [
          IconButton(
            key: const Key('achievements-view-toggle'),
            tooltip: game.achievementsCompact
                ? strings.pick('List view', 'Lijstweergave')
                : strings.pick('Compact view', 'Compacte weergave'),
            onPressed: readOnly
                ? null
                : () => game.setAchievementsCompact(!game.achievementsCompact),
            icon: Icon(game.achievementsCompact
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        key: const PageStorageKey('achievements-scroll'),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          Card(
            color: AppColors.twilightDark,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                const GameIconSprite(
                  GameIconKind.screenAchievements,
                  size: 68,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.pick(
                      '${game.unlockedAchievementIds.length} / 20 unlocked',
                      '${game.unlockedAchievementIds.length} / 20 behaald',
                    ),
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
          const SizedBox(height: 16),
          if (game.achievementsCompact)
            _CompactAchievementGrid(strings: strings)
          else
            for (final achievement in achievementCatalog)
              _AchievementTile(achievement: achievement),
        ],
      ),
    );
  }
}

class _CompactAchievementGrid extends StatelessWidget {
  const _CompactAchievementGrid({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 360 ? 4 : 3;
        return GridView.builder(
          key: const Key('achievements-compact-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: achievementCatalog.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final achievement = achievementCatalog[index];
            final unlocked =
                game.unlockedAchievementIds.contains(achievement.id);
            final name = achievement.secret && !unlocked
                ? strings.pick('Secret achievement', 'Geheime achievement')
                : strings.achievementTitle(achievement);
            final badge = DecoratedBox(
              decoration: BoxDecoration(
                color: unlocked ? Colors.white : const Color(0xFFE4E1E8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: unlocked ? AppColors.gold : AppColors.mist,
                  width: unlocked ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: AchievementBadgeSprite(
                  achievement: achievement,
                  unlocked: unlocked,
                ),
              ),
            );
            return Semantics(
              button: unlocked,
              label:
                  '$name, ${unlocked ? strings.pick('unlocked', 'behaald') : strings.pick('locked', 'vergrendeld')}',
              child: Tooltip(
                message: name,
                child: unlocked
                    ? Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: Key('achievement-zoom-${achievement.id}'),
                          borderRadius: BorderRadius.circular(22),
                          onTap: () =>
                              _showAchievementZoom(context, achievement),
                          child: badge,
                        ),
                      )
                    : badge,
              ),
            );
          },
        );
      },
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
        contentPadding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        leading: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            key: unlocked ? Key('achievement-zoom-${achievement.id}') : null,
            customBorder: const CircleBorder(),
            onTap: unlocked
                ? () => _showAchievementZoom(context, achievement)
                : null,
            child: Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: unlocked ? Colors.white : const Color(0xFFE1DEE5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: unlocked ? AppColors.gold : const Color(0xFFBBB7C1),
                  width: unlocked ? 1.6 : 1,
                ),
              ),
              child: AchievementBadgeSprite(
                achievement: achievement,
                unlocked: unlocked,
              ),
            ),
          ),
        ),
        title: Text(hidden ? '???' : strings.achievementTitle(achievement),
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(hidden ? '???' : strings.achievementDescription(achievement)),
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

Future<void> _showAchievementZoom(
  BuildContext context,
  AchievementDefinition achievement,
) {
  final strings = AppStrings.of(context);
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0xCC17112A),
    builder: (dialogContext) => Dialog(
      key: const Key('achievement-zoom-dialog'),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(dialogContext),
          borderRadius: BorderRadius.circular(34),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                center: Alignment.topCenter,
                radius: 1.25,
                colors: [Color(0xFFFFF8DC), Color(0xFFF1E9FF)],
              ),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: AppColors.gold, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x805D45A0),
                  blurRadius: 34,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                SizedBox.square(
                  key: const Key('achievement-zoom-image'),
                  dimension: 230,
                  child: AchievementBadgeSprite(
                    achievement: achievement,
                    unlocked: true,
                    size: 230,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.achievementTitle(achievement),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.achievementDescription(achievement),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
