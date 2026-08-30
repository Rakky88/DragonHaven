import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/activity_entry.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/game_icon_sprite.dart';

enum _JournalFilter { all, adventures, discoveries, milestones }

class KeeperJournalScreen extends StatefulWidget {
  const KeeperJournalScreen({super.key});

  @override
  State<KeeperJournalScreen> createState() => _KeeperJournalScreenState();
}

class _KeeperJournalScreenState extends State<KeeperJournalScreen> {
  _JournalFilter _filter = _JournalFilter.all;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final entries = game.activities
        .where((entry) => _matches(entry, _filter))
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final oldestDragon = game.ownedDragons.isEmpty
        ? game.currentTime
        : game.ownedDragons
            .map((dragon) => dragon.acquiredAt)
            .reduce((a, b) => a.isBefore(b) ? a : b);
    final keeperDays = game.currentTime.difference(oldestDragon).inDays + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.pick('Keeper Journal', 'Keeperdagboek')),
      ),
      body: CustomScrollView(
        key: const Key('keeper-journal-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _JournalHeader(
                keeperDays: keeperDays,
                moments: game.activities.length,
                discoveredForms: game.discoveredForms.length,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in _JournalFilter.values) ...[
                      FilterChip(
                        key: Key('journal-filter-${filter.name}'),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                        avatar: Icon(_filterIcon(filter), size: 17),
                        label: Text(_filterLabel(strings, filter)),
                      ),
                      const SizedBox(width: 7),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyJournal(filter: _filter),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final previous = index == 0 ? null : entries[index - 1];
                  final showDate = previous == null ||
                      !_sameDay(previous.createdAt, entry.createdAt);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDate) ...[
                        if (index > 0) const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(left: 49, bottom: 5),
                          child: Text(
                            _dateLabel(context, entry.createdAt,
                                game.currentTime, strings),
                            style: const TextStyle(
                              color: AppColors.twilight,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      _JournalEntryTile(
                        entry: entry,
                        isLast: index == entries.length - 1,
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _JournalHeader extends StatelessWidget {
  const _JournalHeader({
    required this.keeperDays,
    required this.moments,
    required this.discoveredForms,
  });

  final int keeperDays;
  final int moments;
  final int discoveredForms;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      key: const Key('keeper-journal-header'),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF211638), Color(0xFF5B3D91), Color(0xFFA8685B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.gold),
        boxShadow: const [
          BoxShadow(
              color: Color(0x332A1E50), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x22FFFFFF),
                ),
                child: const Center(
                  child: GameIconSprite(GameIconKind.draconomicon, size: 58),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.pick('Your story, kept in ink and starlight',
                          'Jouw verhaal, bewaard in inkt en sterrenlicht'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.pick(
                        'Adventures, discoveries and milestones from your life as a Keeper.',
                        'Avonturen, ontdekkingen en mijlpalen uit jouw leven als Keeper.',
                      ),
                      style: const TextStyle(
                          color: Color(0xFFE9DFF9), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _JournalStat(
                  value: '$keeperDays', label: strings.pick('days', 'dagen')),
              _JournalStat(
                  value: '$moments',
                  label: strings.pick('moments', 'momenten')),
              _JournalStat(
                  value: '$discoveredForms',
                  label: strings.pick('forms', 'vormen')),
            ],
          ),
        ],
      ),
    );
  }
}

class _JournalStat extends StatelessWidget {
  const _JournalStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
              Text(label,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 10.5)),
            ],
          ),
        ),
      );
}

class _JournalEntryTile extends StatelessWidget {
  const _JournalEntryTile({required this.entry, required this.isLast});

  final ActivityEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final accent = _activityColor(entry.type);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: accent.withValues(alpha: .3), blurRadius: 7)
                    ],
                  ),
                  child:
                      Icon(_activityIcon(entry), color: Colors.white, size: 19),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: const Color(0xFFDCD2E8)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 9),
              elevation: 0,
              color: Colors.white.withValues(alpha: .96),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
                side: BorderSide(color: accent.withValues(alpha: .18)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.message,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          TimeOfDay.fromDateTime(entry.createdAt)
                              .format(context),
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 10.5),
                        ),
                        const Spacer(),
                        if (entry.xp != 0) _RewardText('+${entry.xp} XP'),
                        if (entry.coins != 0)
                          _RewardText('${entry.coins} coins'),
                        if (entry.gems != 0) _RewardText('${entry.gems} gems'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardText extends StatelessWidget {
  const _RewardText(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 7),
        child: Text(label,
            style: const TextStyle(
                color: AppColors.twilight,
                fontSize: 10.5,
                fontWeight: FontWeight.w900)),
      );
}

class _EmptyJournal extends StatelessWidget {
  const _EmptyJournal({required this.filter});
  final _JournalFilter filter;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GameIconSprite(GameIconKind.draconomicon, size: 94),
            Text(
              strings.pick('These pages are still waiting for a story.',
                  'Deze pagina\'s wachten nog op een verhaal.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

bool _matches(ActivityEntry entry, _JournalFilter filter) => switch (filter) {
      _JournalFilter.all => true,
      _JournalFilter.adventures => entry.type == ActivityType.explore,
      _JournalFilter.discoveries => entry.type == ActivityType.discovery,
      _JournalFilter.milestones => entry.type == ActivityType.milestone,
    };

String _filterLabel(AppStrings strings, _JournalFilter filter) =>
    switch (filter) {
      _JournalFilter.all => strings.pick('All', 'Alles'),
      _JournalFilter.adventures => strings.pick('Adventures', 'Avonturen'),
      _JournalFilter.discoveries => strings.pick('Discoveries', 'Ontdekkingen'),
      _JournalFilter.milestones => strings.pick('Milestones', 'Mijlpalen'),
    };

IconData _filterIcon(_JournalFilter filter) => switch (filter) {
      _JournalFilter.all => Icons.auto_stories_rounded,
      _JournalFilter.adventures => Icons.explore_rounded,
      _JournalFilter.discoveries => Icons.auto_awesome_rounded,
      _JournalFilter.milestones => Icons.emoji_events_rounded,
    };

IconData _activityIcon(ActivityEntry entry) => switch (entry.code) {
      ActivityCode.hatched => Icons.egg_alt_rounded,
      ActivityCode.evolved => Icons.change_circle_rounded,
      ActivityCode.achievement => Icons.emoji_events_rounded,
      ActivityCode.chestOpened => Icons.inventory_2_rounded,
      ActivityCode.activityCompleted => Icons.explore_rounded,
      ActivityCode.itemPurchased ||
      ActivityCode.portraitChestPurchased ||
      ActivityCode.titleChestPurchased =>
        Icons.shopping_bag_rounded,
      ActivityCode.portraitRevealed ||
      ActivityCode.titleRevealed ||
      ActivityCode.bonusFound =>
        Icons.auto_awesome_rounded,
      ActivityCode.itemPlaced => Icons.chair_alt_rounded,
      ActivityCode.welcome || ActivityCode.legacy => Icons.menu_book_rounded,
    };

Color _activityColor(ActivityType type) => switch (type) {
      ActivityType.explore => const Color(0xFF427D8C),
      ActivityType.discovery => const Color(0xFF8C5BA7),
      ActivityType.purchase => const Color(0xFFA46A38),
      ActivityType.milestone => const Color(0xFF5B4B8A),
    };

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dateLabel(
  BuildContext context,
  DateTime date,
  DateTime now,
  AppStrings strings,
) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return strings.pick('Today', 'Vandaag');
  if (difference == 1) return strings.pick('Yesterday', 'Gisteren');
  return MaterialLocalizations.of(context).formatMediumDate(date);
}
