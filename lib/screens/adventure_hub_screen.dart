import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/pet.dart';
import '../providers/household_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';
import '../widgets/game_icon_sprite.dart';

class AdventureHubScreen extends StatefulWidget {
  const AdventureHubScreen({super.key});

  @override
  State<AdventureHubScreen> createState() => _AdventureHubScreenState();
}

class _AdventureHubScreenState extends State<AdventureHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final activeCount = game.activeAdventureRuns.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              const GameIconSprite(GameIconKind.adventureShort, size: 52),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.tr('adventure'),
                        style: Theme.of(context).textTheme.displaySmall),
                    Text(
                      strings.pick(
                        'Choose a path. Bring back stories, training and treasure.',
                        'Kies een route. Breng verhalen, training en schatten mee terug.',
                      ),
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: strings.pick('Available', 'Beschikbaar')),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(strings.pick('Active', 'Actief')),
                    if (activeCount > 0) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.twilight,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text('$activeCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _AvailableAdventures(now: game.currentTime),
              _ActiveAdventures(now: game.currentTime),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvailableAdventures extends StatelessWidget {
  const _AvailableAdventures({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    return ListView(
      key: const PageStorageKey('available-adventures-scroll'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
      children: [
        for (final kind in AdventureKind.values)
          _AdventureSection(
            kind: kind,
            adventures: game.adventuresFor(kind),
            now: now,
          ),
      ],
    );
  }
}

class _AdventureSection extends StatelessWidget {
  const _AdventureSection({
    required this.kind,
    required this.adventures,
    required this.now,
  });

  final AdventureKind kind;
  final List<AdventureDefinition> adventures;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.read<HouseholdProvider>();
    final colors = _kindColors(kind);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.last.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GameIconSprite(_kindIcon(kind), size: 46),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_kindTitle(strings, kind),
                        style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                    Text(_kindDescription(strings, kind),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 10)),
                  ],
                ),
              ),
              if (kind != AdventureKind.special) ...[
                const SizedBox(width: 7),
                _AdventureRefreshCountdown(
                  kind: kind,
                  remaining: game.adventureRefreshRemaining(kind, from: now)!,
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          if (adventures.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
              child: Text(
                strings.pick('No trail is available here right now.',
                    'Hier is nu geen route beschikbaar.'),
                style: const TextStyle(color: AppColors.muted),
              ),
            )
          else
            for (final adventure in adventures)
              _AdventureCard(adventure: adventure),
        ],
      ),
    );
  }
}

class _AdventureRefreshCountdown extends StatelessWidget {
  const _AdventureRefreshCountdown({
    required this.kind,
    required this.remaining,
  });

  final AdventureKind kind;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final includeDays =
        kind == AdventureKind.long || kind == AdventureKind.group;
    return Container(
      key: Key('adventure-refresh-${kind.name}'),
      padding: const EdgeInsets.fromLTRB(7, 5, 9, 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1E50).withValues(alpha: .94),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(
            color: Color(0x282A1E50),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GameIconSprite(GameIconKind.clock, size: 20),
          const SizedBox(width: 4),
          Text(
            _formatRefreshCountdown(remaining, includeDays: includeDays),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatRefreshCountdown(
  Duration remaining, {
  required bool includeDays,
}) {
  final totalSeconds = remaining.inSeconds.clamp(0, 999999999);
  final seconds = totalSeconds % 60;
  final totalMinutes = totalSeconds ~/ 60;
  final minutes = totalMinutes % 60;
  if (!includeDays) {
    return '${totalMinutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  final hours = (totalSeconds ~/ Duration.secondsPerHour) % 24;
  final days = totalSeconds ~/ Duration.secondsPerDay;
  return '${days}d ${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

class _AdventureCard extends StatelessWidget {
  const _AdventureCard({required this.adventure});

  final AdventureDefinition adventure;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    return SizedBox(
      key: Key('adventure-card-${adventure.id}'),
      height: 82,
      child: Card(
        color: Colors.white.withValues(alpha: .96),
        margin: const EdgeInsets.only(bottom: 7),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('adventure-details-${adventure.id}'),
          onTap: () => _showAdventureDetails(context, adventure),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 7, 7, 7),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          strings.adventureTitle(adventure),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      if (adventure.sinister)
                        const Icon(Icons.visibility_rounded,
                            size: 16, color: Color(0xFF8A285E)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      const GameIconSprite(GameIconKind.clock, size: 19),
                      const SizedBox(width: 3),
                      Text(
                        strings.adventureDuration(adventure.duration),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 9),
                      GameIconSprite(
                        GameIconSprite.forTrainingFocus(adventure.focus),
                        size: 19,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _focusName(strings, adventure.focus),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              if (adventure.kind == AdventureKind.mini ||
                  adventure.kind == AdventureKind.short ||
                  adventure.kind == AdventureKind.long)
                IconButton(
                  key: Key('dismiss-adventure-${adventure.id}'),
                  tooltip: strings.pick('Dismiss', 'Wegsturen'),
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints.tightFor(width: 30, height: 42),
                  padding: EdgeInsets.zero,
                  onPressed: () => game.dismissAdventure(adventure),
                  icon: const Icon(Icons.close_rounded,
                      size: 19, color: AppColors.muted),
                ),
              const SizedBox(width: 2),
              _AdventureStartButton(onPressed: () => _start(context)),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context) async {
    final game = context.read<HouseholdProvider>();
    final available = game.ownedDragons
        .where((dragon) => dragon.activeAdventureId == null)
        .toList()
      ..sort((a, b) {
        final score = _recommendationScore(b, adventure)
            .compareTo(_recommendationScore(a, adventure));
        return score != 0 ? score : a.acquiredAt.compareTo(b.acquiredAt);
      });
    if (available.isEmpty) {
      await _showStartResult(context, AdventureStartResult.eggCannotAdventure);
      return;
    }
    final selected = await showModalBottomSheet<Pet>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _DragonPicker(adventure: adventure, dragons: available),
    );
    if (selected == null || !context.mounted) return;
    final result = await game.startAdventure(adventure, dragonId: selected.id);
    if (!context.mounted) return;
    await _showStartResult(context, result);
    if (result == AdventureStartResult.started) {
      HavenAudio.play(HavenSound.adventureStart);
    }
  }

  void _showAdventureDetails(
    BuildContext context,
    AdventureDefinition definition,
  ) {
    final strings = AppStrings.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          key: const Key('available-adventure-details-scroll'),
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            GameIconSprite(_kindIcon(definition.kind), size: 122),
            Text(
              strings.adventureTitle(definition),
              textAlign: TextAlign.center,
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              strings.adventureDescription(definition),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
            const SizedBox(height: 15),
            _DetailRow(
              icon: const GameIconSprite(GameIconKind.clock, size: 34),
              title: strings.pick('Duration', 'Duur'),
              value: strings.adventureDuration(definition.duration),
            ),
            _DetailRow(
              icon: const GameIconSprite(GameIconKind.experience, size: 34),
              title: strings.pick('Dragon experience', 'Drakenervaring'),
              value: '${definition.xp} XP',
            ),
            _DetailRow(
              icon: GameIconSprite(
                GameIconSprite.forTrainingFocus(definition.focus),
                size: 34,
              ),
              title: strings.pick('Expertise training', 'Expertisetraining'),
              value:
                  '+${definition.statPoints} ${_focusName(strings, definition.focus)} · '
                  '${_focusExplanation(strings, definition.focus)}',
            ),
            _DetailRow(
              icon: const GameIconSprite(GameIconKind.chest, size: 34),
              title: strings.pick('Possible chests', 'Mogelijke kisten'),
              value: _chestPossibilities(strings, definition),
            ),
            if (definition.kind == AdventureKind.group)
              _DetailRow(
                icon: const Icon(Icons.group_rounded,
                    color: AppColors.twilight, size: 30),
                title: strings.pick('Keeper requirement', 'Hoedervereiste'),
                value:
                    '${definition.requirements.players} ${strings.pick('connected keepers', 'gekoppelde hoeders')}',
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) _start(context);
                  });
                },
                icon: const GameIconSprite(
                  GameIconKind.adventureStart,
                  size: 38,
                ),
                label: Text(strings.pick('Choose a dragon', 'Kies een draak')),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _AdventureStartButton extends StatelessWidget {
  const _AdventureStartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: AppStrings.of(context).pick('Start adventure', 'Start avontuur'),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('start-adventure-button'),
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              width: 52,
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7256B5), Color(0xFF4C358D)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x334C358D),
                      blurRadius: 9,
                      offset: Offset(0, 4)),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const GameIconSprite(GameIconKind.adventureStart, size: 31),
                    Text(AppStrings.of(context).pick('Start', 'Start'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            height: 1,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _DragonPicker extends StatelessWidget {
  const _DragonPicker({required this.adventure, required this.dragons});

  final AdventureDefinition adventure;
  final List<Pet> dragons;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final recommendationCount = dragons.length.clamp(1, 3);
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        maxChildSize: .92,
        builder: (_, controller) => ListView(
          key: const Key('adventure-dragon-picker-scroll'),
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            Row(
              children: [
                const GameIconSprite(GameIconKind.adventureStart, size: 70),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strings.pick('Choose a dragon', 'Kies een draak'),
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(strings.adventureTitle(adventure),
                          style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _PickerSectionLabel(
                label: strings.pick(
                    'Recommended for this path', 'Aanbevolen voor deze route')),
            for (var index = 0; index < recommendationCount; index++)
              _DragonPickerTile(
                  dragon: dragons[index],
                  adventure: adventure,
                  recommended: true),
            if (dragons.length > recommendationCount) ...[
              const SizedBox(height: 8),
              _PickerSectionLabel(
                  label: strings.pick(
                      'Other available dragons', 'Andere beschikbare draken')),
              for (var index = recommendationCount;
                  index < dragons.length;
                  index++)
                _DragonPickerTile(
                    dragon: dragons[index],
                    adventure: adventure,
                    recommended: false),
            ],
          ],
        ),
      ),
    );
  }
}

class _PickerSectionLabel extends StatelessWidget {
  const _PickerSectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 7),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
                color: AppColors.twilight,
                fontSize: 10,
                letterSpacing: .7,
                fontWeight: FontWeight.w900)),
      );
}

class _DragonPickerTile extends StatelessWidget {
  const _DragonPickerTile({
    required this.dragon,
    required this.adventure,
    required this.recommended,
  });

  final Pet dragon;
  final AdventureDefinition adventure;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final focus = adventure.focus;
    return Card(
      color: recommended ? const Color(0xFFFFFAE9) : Colors.white,
      child: InkWell(
        onTap: () => Navigator.pop(context, dragon),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 64,
                child: DragonArt(
                  height: 64,
                  animate: false,
                  stageKey: dragon.stageKey,
                  lineageId: dragon.lineageId,
                  evolutionPath: dragon.activeEvolutionPath,
                  prismatic: dragon.prismatic,
                  sinister: dragon.sinister,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(dragon.displayName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      if (recommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(strings.pick('Recommended', 'Aanbevolen'),
                              style: const TextStyle(
                                  fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                    ]),
                    const SizedBox(height: 3),
                    Text(
                      '${strings.lineageName(dragon.lineage)} · ${strings.levelShort(dragon.level)}',
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    const SizedBox(height: 5),
                    Row(children: [
                      GameIconSprite(GameIconSprite.forTrainingFocus(focus),
                          size: 21),
                      const SizedBox(width: 4),
                      Text(
                          '${_focusName(strings, focus)} ${dragon.trainingFor(focus)}',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800)),
                    ]),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.twilight),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveAdventures extends StatelessWidget {
  const _ActiveAdventures({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final runs = game.activeAdventureRuns;
    if (runs.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GameIconSprite(GameIconKind.adventureActive, size: 150),
              Text(
                  strings.pick('No adventures are active',
                      'Er zijn geen actieve avonturen'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                strings.pick(
                  'Send a dragon out and its journey will appear here.',
                  'Stuur een draak op pad en zijn reis verschijnt hier.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      key: const PageStorageKey('active-adventures-scroll'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
      itemCount: runs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _ActiveAdventureCard(run: runs[index], now: now),
    );
  }
}

class _ActiveAdventureCard extends StatelessWidget {
  const _ActiveAdventureCard({required this.run, required this.now});

  final AdventureRun run;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final definition = AdventureCatalog.byId[run.adventureId]!;
    final dragon = game.ownedDragons.cast<Pet?>().firstWhere(
          (candidate) => candidate?.id == run.dragonId,
          orElse: () => null,
        );
    final ready = run.status == AdventureRunStatus.rewardReady;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showRunDetails(context, run, definition, dragon),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 13, 10),
          child: Row(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  gradient:
                      LinearGradient(colors: _kindColors(definition.kind)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: GameIconSprite(_kindIcon(definition.kind), size: 74),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.adventureTitle(definition),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                        dragon?.displayName ??
                            strings.pick('Unknown dragon', 'Onbekende draak'),
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 7),
                    Row(children: [
                      const GameIconSprite(GameIconKind.clock, size: 22),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ready
                              ? strings.pick(
                                  'Ready to return', 'Klaar om terug te keren')
                              : _remaining(run.endsAt, strings, now),
                          style: TextStyle(
                            color: ready
                                ? const Color(0xFF24735B)
                                : AppColors.twilight,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              if (ready)
                FilledButton.tonal(
                  key: Key('claim-adventure-${run.id}'),
                  onPressed: () => _claimAdventure(context, run.id),
                  child: Text(strings.pick('Claim', 'Ophalen')),
                )
              else
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.twilight),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showRunDetails(
  BuildContext context,
  AdventureRun run,
  AdventureDefinition definition,
  Pet? dragon,
) async {
  final strings = AppStrings.of(context);
  final game = context.read<HouseholdProvider>();
  final ready = run.status == AdventureRunStatus.rewardReady;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        key: const Key('active-adventure-details-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameIconSprite(_kindIcon(definition.kind), size: 128),
            Text(strings.adventureTitle(definition),
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text(strings.adventureDescription(definition),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            _DetailRow(
                icon: dragon == null
                    ? const GameIconSprite(GameIconKind.myDragons, size: 34)
                    : SizedBox.square(
                        dimension: 42,
                        child: DragonArt(
                          height: 42,
                          animate: false,
                          stageKey: dragon.stageKey,
                          lineageId: dragon.lineageId,
                          evolutionPath: dragon.activeEvolutionPath,
                          prismatic: dragon.prismatic,
                          sinister: dragon.sinister,
                        ),
                      ),
                title: strings.pick('Dragon', 'Draak'),
                value: dragon?.displayName ??
                    strings.pick('Unknown dragon', 'Onbekende draak')),
            _DetailRow(
                icon: const GameIconSprite(GameIconKind.clock, size: 34),
                title: ready
                    ? strings.pick('Status', 'Status')
                    : strings.pick('Return in', 'Terug over'),
                value: ready
                    ? strings.pick('Ready to return', 'Klaar om terug te keren')
                    : _remaining(run.endsAt, strings, game.currentTime)),
            _DetailRow(
                icon: const GameIconSprite(GameIconKind.experience, size: 34),
                title: strings.pick('Dragon experience', 'Drakenervaring'),
                value: '${definition.xp} XP'),
            _DetailRow(
                icon: GameIconSprite(
                    GameIconSprite.forTrainingFocus(definition.focus),
                    size: 34),
                title: strings.pick('Training reward', 'Trainingsbeloning'),
                value:
                    '+${definition.statPoints} ${_focusName(strings, definition.focus)}'),
            _DetailRow(
                icon: const GameIconSprite(GameIconKind.chest, size: 34),
                title: strings.pick('Treasure', 'Schat'),
                value: strings.pick('One sealed chest', 'Eén verzegelde kist')),
            const SizedBox(height: 14),
            if (ready)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final tier = await game.claimAdventure(run.id);
                    if (!sheetContext.mounted || tier == null) return;
                    HavenAudio.play(HavenSound.adventureReturn);
                    Navigator.pop(sheetContext);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(strings.pick(
                        '${strings.chestLabel(tier)} added to your rewards.',
                        '${strings.chestLabel(tier)} toegevoegd aan je beloningen.',
                      )),
                    ));
                  },
                  icon: const GameIconSprite(GameIconKind.chest, size: 34),
                  label:
                      Text(strings.pick('Claim rewards', 'Beloningen ophalen')),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.title, required this.value});
  final Widget icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F2FF),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(children: [
          SizedBox.square(dimension: 42, child: Center(child: icon)),
          const SizedBox(width: 9),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            ]),
          ),
        ]),
      );
}

int _recommendationScore(Pet dragon, AdventureDefinition adventure) =>
    dragon.trainingFor(adventure.focus) * 100 +
    dragon.level * 10 +
    (dragon.lineage.primaryRoomId == dragon.currentRoomId ? 3 : 0);

GameIconKind _kindIcon(AdventureKind kind) => switch (kind) {
      AdventureKind.mini => GameIconKind.adventureMini,
      AdventureKind.short => GameIconKind.adventureShort,
      AdventureKind.long => GameIconKind.adventureLong,
      AdventureKind.group => GameIconKind.adventureGroup,
      AdventureKind.special => GameIconKind.adventureSpecial,
    };

List<Color> _kindColors(AdventureKind kind) => switch (kind) {
      AdventureKind.mini => const [Color(0xFFFFF4E8), Color(0xFFFFDFC4)],
      AdventureKind.short => const [Color(0xFFFFF8DC), Color(0xFFFFEDB7)],
      AdventureKind.long => const [Color(0xFFE9F2FF), Color(0xFFD9E6FF)],
      AdventureKind.group => const [Color(0xFFE9FBF4), Color(0xFFD6F1E8)],
      AdventureKind.special => const [Color(0xFFF2E9FF), Color(0xFFE5D7FA)],
    };

String _kindTitle(AppStrings strings, AdventureKind kind) => switch (kind) {
      AdventureKind.mini => strings.pick('Mini', 'Mini'),
      AdventureKind.short => strings.pick('Short', 'Kort'),
      AdventureKind.long => strings.pick('Long', 'Lang'),
      AdventureKind.group => strings.pick('Group', 'Groep'),
      AdventureKind.special => strings.pick('Special', 'Speciaal'),
    };

String _kindDescription(AppStrings strings, AdventureKind kind) =>
    switch (kind) {
      AdventureKind.mini => strings.pick(
          'Tiny outings, quick training and wooden chests.',
          'Kleine uitstapjes, snelle training en houten kisten.'),
      AdventureKind.short => strings.pick(
          'Quick routes that refresh throughout the day.',
          'Snelle routes die door de dag heen verversen.'),
      AdventureKind.long => strings.pick(
          'Patient journeys with richer returns.',
          'Geduldige reizen met rijkere opbrengsten.'),
      AdventureKind.group => strings.pick(
          'Shared discoveries for connected keepers.',
          'Gedeelde ontdekkingen voor gekoppelde hoeders.'),
      AdventureKind.special => strings.pick(
          'Rare trails that only appear at special moments.',
          'Zeldzame routes die alleen op bijzondere momenten verschijnen.'),
    };

String _focusName(AppStrings strings, TrainingFocus focus) => switch (focus) {
      TrainingFocus.might => strings.pick('Might', 'Kracht'),
      TrainingFocus.arcana => strings.pick('Arcana', 'Arcana'),
      TrainingFocus.spirit => strings.pick('Spirit', 'Geest'),
    };

String _focusExplanation(AppStrings strings, TrainingFocus focus) =>
    switch (focus) {
      TrainingFocus.might =>
        strings.pick('shapes a Might Ascension', 'vormt een Might-Ascension'),
      TrainingFocus.arcana => strings.pick(
          'shapes an Arcana Ascension', 'vormt een Arcana-Ascension'),
      TrainingFocus.spirit =>
        strings.pick('shapes a Spirit Ascension', 'vormt een Spirit-Ascension'),
    };

String _chestPossibilities(
  AppStrings strings,
  AdventureDefinition adventure,
) {
  final known = adventure.knownChest;
  if (known != null) return '${strings.chestLabel(known)} · 100%';
  return adventureChestChances[adventure.kind]!
      .map((chance) =>
          '${strings.chestLabel(chance.tier)} ${_chancePercent(strings, chance.probability)}')
      .join(' · ');
}

String _chancePercent(AppStrings strings, double probability) {
  final percent = probability * 100;
  final text = percent == percent.roundToDouble()
      ? '${percent.toInt()}'
      : percent.toStringAsFixed(1);
  final usesDecimalComma =
      const {'de', 'es', 'fr', 'it', 'nl', 'pt'}.contains(strings.languageCode);
  return '${usesDecimalComma ? text.replaceAll('.', ',') : text}%';
}

String _remaining(DateTime end, AppStrings strings, DateTime now) {
  final remaining = end.difference(now);
  if (remaining <= Duration.zero) return strings.pick('Ready', 'Klaar');
  return strings.remainingDuration(remaining);
}

Future<void> _claimAdventure(BuildContext context, String runId) async {
  final game = context.read<HouseholdProvider>();
  final strings = AppStrings.of(context);
  final tier = await game.claimAdventure(runId);
  if (!context.mounted || tier == null) return;
  unawaited(HavenAudio.play(HavenSound.adventureReturn));
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(strings.pick(
      '${strings.chestLabel(tier)} added to your Inventory.',
      '${strings.chestLabel(tier)} toegevoegd aan je Inventory.',
    )),
  ));
}

Future<void> _showStartResult(
    BuildContext context, AdventureStartResult result) async {
  if (!context.mounted) return;
  final strings = AppStrings.of(context);
  final message = switch (result) {
    AdventureStartResult.started =>
      strings.pick('Adventure started.', 'Avontuur gestart.'),
    AdventureStartResult.eggCannotAdventure => strings.pick(
        'No dragon is available for this adventure.',
        'Er is geen draak beschikbaar voor dit avontuur.'),
    AdventureStartResult.dragonBusy =>
      strings.pick('That dragon is already away.', 'Die draak is al onderweg.'),
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
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
