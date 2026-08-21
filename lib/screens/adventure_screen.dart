import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/chest.dart';
import '../models/pet.dart';
import '../providers/household_provider.dart';
import '../services/audio_service.dart';
import '../widgets/chest_reveal.dart';
import '../theme/app_theme.dart';

class AdventureScreen extends StatefulWidget {
  const AdventureScreen({super.key});

  @override
  State<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends State<AdventureScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final runs = game.activeAdventureRuns;
    return Column(
      children: [
        if (runs.isNotEmpty) _RunningAdventures(runs: runs),
        if (game.totalChestCount > 0) _UnopenedChests(game: game),
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: strings.pick('Short', 'Kort')),
              Tab(text: strings.pick('Long', 'Lang')),
              Tab(text: strings.pick('Group', 'Groep')),
              const Tab(text: 'Special'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              for (final kind in AdventureKind.values)
                _AdventureList(kind: kind),
            ],
          ),
        ),
      ],
    );
  }
}

class _RunningAdventures extends StatelessWidget {
  const _RunningAdventures({required this.runs});

  final List<AdventureRun> runs;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    return Container(
      width: double.infinity,
      color: const Color(0xFFEDE8FF),
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.pick('Active expeditions', 'Actieve expedities'),
              style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          SizedBox(
            height: 52,
            child: ListView.separated(
              key: const PageStorageKey('active-adventures-scroll'),
              scrollDirection: Axis.horizontal,
              itemCount: runs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final run = runs[index];
                final definition = AdventureCatalog.byId[run.adventureId]!;
                final ready = run.status == AdventureRunStatus.rewardReady;
                return ActionChip(
                  avatar: Icon(
                    ready ? Icons.redeem_rounded : Icons.hourglass_top_rounded,
                    size: 18,
                  ),
                  label: Text(ready
                      ? strings.pick('Claim ${definition.titleEn}',
                          'Claim ${definition.titleNl}')
                      : _remaining(run.endsAt, strings)),
                  onPressed: ready
                      ? () async {
                          final tier = await game.claimAdventure(run.id);
                          if (tier != null && context.mounted) {
                            HavenAudio.play(HavenSound.adventureReturn);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(strings.pick(
                                    '${tier.label(false)} added to your rewards.',
                                    '${tier.label(true)} toegevoegd aan je beloningen.'))));
                          }
                        }
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UnopenedChests extends StatelessWidget {
  const _UnopenedChests({required this.game});

  final HouseholdProvider game;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tiers = ChestTier.values.where((tier) => game.chestCount(tier) > 0);
    return SizedBox(
      height: 66,
      child: ListView(
        key: const PageStorageKey('unopened-chests-scroll'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
        children: [
          for (final tier in tiers)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: Icon(Icons.inventory_2_rounded,
                    color: Color(tier.colorValue), size: 18),
                label: Text(
                    '${tier.label(strings.isDutch)} ×${game.chestCount(tier)}'),
                onPressed: () => _openChest(context, tier),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openChest(BuildContext context, ChestTier tier) async {
    final reward = await game.openChest(tier);
    if (reward == null || !context.mounted) return;
    await HavenAudio.play(_soundForChest(tier));
    if (!context.mounted) return;
    await showChestReveal(context, reward);
  }
}

class _AdventureList extends StatelessWidget {
  const _AdventureList({required this.kind});

  final AdventureKind kind;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final adventures = game.adventuresFor(kind);
    return ListView(
      key: PageStorageKey('adventures-${kind.name}'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      children: [
        if (kind == AdventureKind.short)
          _InfoBanner(
              text: strings.pick(
                  'Up to 3 offers. Open slots refresh every hour; you may dismiss one.',
                  'Maximaal 3 opties. Open plekken verversen elk uur; je mag er één wegsturen.')),
        if (kind == AdventureKind.long)
          _InfoBanner(
              text: strings.pick('Up to 3 offers, refreshed at local midnight.',
                  'Maximaal 3 opties, vernieuwd om lokale middernacht.')),
        if (kind == AdventureKind.group)
          _InfoBanner(
              text: strings.pick(
                  'A global weekly expedition refreshes on Sunday at 12:00 Europe/Amsterdam. Online friends are required.',
                  'Een wereldwijde expeditie ververst zondag om 12:00 Europe/Amsterdam. Online vrienden zijn vereist.')),
        if (kind == AdventureKind.special)
          _InfoBanner(
              text: strings.pick(
                  'Event, code and returning-dragon adventures stay available for 48 hours.',
                  'Avonturen uit events, codes en terugkerende draken blijven 48 uur beschikbaar.')),
        const SizedBox(height: 8),
        for (final adventure in adventures)
          _AdventureCard(adventure: adventure),
      ],
    );
  }
}

class _AdventureCard extends StatelessWidget {
  const _AdventureCard({required this.adventure});

  final AdventureDefinition adventure;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final group = adventure.kind == AdventureKind.group;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  strings.isDutch ? adventure.titleNl : adventure.titleEn,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              if (adventure.sinister)
                const Icon(Icons.visibility_rounded, color: Color(0xFF8A285E)),
            ]),
            const SizedBox(height: 5),
            Text(
                strings.isDutch
                    ? adventure.descriptionNl
                    : adventure.descriptionEn,
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            Wrap(spacing: 7, runSpacing: 7, children: [
              _Meta(
                  icon: Icons.schedule_rounded,
                  text: _duration(adventure.duration)),
              _Meta(
                  icon: Icons.auto_awesome_rounded, text: '${adventure.xp} XP'),
              _Meta(
                  icon: _focusIcon(adventure.focus),
                  text:
                      '+${adventure.statPoints} ${_focusName(adventure.focus)}'),
              _Meta(
                  icon: Icons.inventory_2_rounded,
                  text: adventure.knownChest?.label(strings.isDutch) ??
                      strings.pick('Hidden chest', 'Verborgen kist')),
              if (group)
                _Meta(
                    icon: Icons.group_rounded,
                    text: '${adventure.requirements.players} players'),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              if (adventure.kind == AdventureKind.short)
                TextButton(
                  onPressed: () => game.dismissAdventure(adventure),
                  child: Text(strings.pick('Dismiss', 'Wegsturen')),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _start(context),
                icon: Icon(group
                    ? Icons.group_add_rounded
                    : Icons.flight_takeoff_rounded),
                label: Text(strings.pick('Start', 'Start')),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context) async {
    final game = context.read<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final available = game.ownedDragons
        .where((dragon) => dragon.activeAdventureId == null)
        .toList();
    if (available.length > 1) {
      final selected = await showModalBottomSheet<Pet>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            key: const Key('adventure-dragon-picker-scroll'),
            shrinkWrap: true,
            children: [
              for (final dragon in available)
                ListTile(
                  leading: const Icon(Icons.pets_rounded),
                  title: Text(dragon.displayName),
                  subtitle: Text(
                      '${dragon.lineage.name(strings.isDutch)} · Lv. ${dragon.level}'),
                  onTap: () => Navigator.pop(sheetContext, dragon),
                ),
            ],
          ),
        ),
      );
      if (selected == null || !context.mounted) return;
      final result =
          await game.startAdventure(adventure, dragonId: selected.id);
      if (!context.mounted) return;
      await _showStartResult(context, result);
      if (result == AdventureStartResult.started) {
        HavenAudio.play(HavenSound.adventureStart);
      }
      return;
    }
    final result = await game.startAdventure(adventure);
    if (!context.mounted) return;
    await _showStartResult(context, result);
    if (result == AdventureStartResult.started) {
      HavenAudio.play(HavenSound.adventureStart);
    }
  }

  Future<void> _showStartResult(
      BuildContext context, AdventureStartResult result) async {
    if (!context.mounted) return;
    final strings = AppStrings.of(context);
    final message = switch (result) {
      AdventureStartResult.started =>
        strings.pick('Adventure started.', 'Avontuur gestart.'),
      AdventureStartResult.eggCannotAdventure => strings.pick(
          'An egg cannot go adventuring.', 'Een ei kan niet op avontuur.'),
      AdventureStartResult.dragonBusy => strings.pick(
          'That dragon is already away.', 'Die draak is al onderweg.'),
      AdventureStartResult.groupNeedsFriends => strings.pick(
          'Connect online friends before joining a Group Adventure.',
          'Koppel online vrienden voordat je aan een Group Adventure meedoet.'),
      AdventureStartResult.requirementsNotMet => strings.pick(
          'The group does not meet the requirements.',
          'De groep voldoet niet aan de eisen.'),
      AdventureStartResult.unavailable => strings.pick(
          'This offer is no longer available.',
          'Deze optie is niet meer beschikbaar.'),
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded,
              size: 19, color: AppColors.twilight),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ]),
      );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F1F7),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: AppColors.twilight),
          const SizedBox(width: 5),
          Text(text,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ]),
      );
}

String _focusName(TrainingFocus focus) => switch (focus) {
      TrainingFocus.might => 'Might',
      TrainingFocus.arcana => 'Arcana',
      TrainingFocus.spirit => 'Spirit',
    };

IconData _focusIcon(TrainingFocus focus) => switch (focus) {
      TrainingFocus.might => Icons.fitness_center_rounded,
      TrainingFocus.arcana => Icons.auto_fix_high_rounded,
      TrainingFocus.spirit => Icons.favorite_rounded,
    };

String _duration(Duration duration) =>
    duration.inDays >= 1 ? '${duration.inDays}d' : '${duration.inHours}h';

String _remaining(DateTime end, AppStrings strings) {
  final remaining = end.difference(DateTime.now());
  if (remaining.isNegative) return strings.pick('Ready', 'Klaar');
  if (remaining.inDays > 0) {
    return '${remaining.inDays}d ${remaining.inHours % 24}h';
  }
  if (remaining.inHours > 0) {
    return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
  }
  return '${remaining.inMinutes.clamp(1, 59)}m';
}

HavenSound _soundForChest(ChestTier tier) => switch (tier) {
      ChestTier.wooden => HavenSound.chestWooden,
      ChestTier.silver => HavenSound.chestSilver,
      ChestTier.gold => HavenSound.chestGold,
      ChestTier.dragon => HavenSound.chestDragon,
      ChestTier.mythical => HavenSound.chestMythical,
      ChestTier.sinister => HavenSound.chestSinister,
    };
