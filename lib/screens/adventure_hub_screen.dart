import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/chest.dart';
import '../models/mystic_relic.dart';
import '../models/pet.dart';
import '../models/social.dart';
import '../models/trial.dart';
import '../providers/household_provider.dart';
import '../providers/online_account_provider.dart';
import 'trial_game_screen.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';
import '../widgets/expertise_score_badge.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/trial_icon_sprite.dart';
import '../widgets/online_account_access.dart';
import '../widgets/ui_bits.dart';

class AdventureHubScreen extends StatefulWidget {
  const AdventureHubScreen({
    super.key,
    this.initialTab = 0,
    this.navigationRevision = 0,
  });

  final int initialTab;
  final int navigationRevision;

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
    _tabs = TabController(
      length: 4,
      initialIndex: widget.initialTab.clamp(0, 3),
      vsync: this,
    );
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant AdventureHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationRevision != oldWidget.navigationRevision) {
      _tabs.animateTo(widget.initialTab.clamp(0, 3));
    }
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
    final online = context.watch<OnlineAccountProvider>();
    final localRuns = game.activeAdventureRuns;
    final groupRuns = online.isSignedIn
        ? online.myGroupAdventures
        : const <GroupAdventureLobby>[];
    final activeCount = localRuns
            .where((run) => run.status == AdventureRunStatus.running)
            .length +
        groupRuns
            .where((lobby) => !_groupAdventureReady(lobby, game.currentTime))
            .length;
    final completedCount = localRuns
            .where((run) => run.status == AdventureRunStatus.rewardReady)
            .length +
        groupRuns
            .where((lobby) => _groupAdventureReady(lobby, game.currentTime))
            .length;
    final trialCount = game.availableTrials.length;
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
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelPadding: const EdgeInsets.symmetric(horizontal: 10),
            tabs: [
              Tab(
                child: Text(
                  strings.pick('Available', 'Beschikbaar'),
                  key: const Key('adventure-tab-available'),
                ),
              ),
              Tab(
                child: Row(
                  key: const Key('adventure-tab-trials'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(strings.pick('Trials', 'Proeven')),
                    if (trialCount > 0) ...[
                      const SizedBox(width: 6),
                      _TabCount(value: trialCount, gold: true),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  key: const Key('adventure-tab-active'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(strings.pick('Active', 'Actief')),
                    if (activeCount > 0) ...[
                      const SizedBox(width: 7),
                      _TabCount(value: activeCount),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  key: const Key('adventure-tab-completed'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(strings.pick('Completed', 'Voltooid')),
                    if (completedCount > 0) ...[
                      const SizedBox(width: 7),
                      _TabCount(value: completedCount, gold: true),
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
              _TrialsTab(now: game.currentTime),
              _ActiveAdventures(now: game.currentTime),
              _CompletedAdventures(now: game.currentTime),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabCount extends StatelessWidget {
  const _TabCount({required this.value, this.gold = false});

  final int value;
  final bool gold;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: gold ? AppColors.gold : AppColors.twilight,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          '$value',
          style: TextStyle(
            color: gold ? const Color(0xFF2A1E50) : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class _TrialsTab extends StatelessWidget {
  const _TrialsTab({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final offers = game.availableTrials;
    return ListView(
      key: const PageStorageKey('trials-scroll'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A1E50), Color(0xFF5B3D91)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x302A1E50),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              const GameIconSprite(GameIconKind.adventureSpecial, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.pick('Dragon Trials', 'Drakenproeven'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      strings.pick(
                        'Your dragon helps, but your performance decides the reward.',
                        'Je draak helpt, maar jouw prestatie bepaalt de beloning.',
                      ),
                      style: const TextStyle(
                        color: Color(0xFFDCD2F4),
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TrialRefreshCountdown(
                remaining: game.trialRefreshRemaining(from: now),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _TrialStreakCard(),
        const SizedBox(height: 14),
        if (offers.isEmpty)
          const _EmptyTrials()
        else
          for (final offer in offers) ...[
            _TrialOfferCard(offer: offer),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _TrialStreakCard extends StatelessWidget {
  const _TrialStreakCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final filled = game.trialStreakCount.clamp(0, 7);
    return Container(
      key: const Key('trial-streak-card'),
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8DD), Color(0xFFF2E9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0x66D6A72E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.pick('Seven-day Trial constellation',
                      'Zevendaagse Trial-constellatie'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 14.5),
                ),
              ),
              Text(
                '$filled/7',
                style: const TextStyle(
                    color: AppColors.twilight, fontWeight: FontWeight.w900),
              ),
              if (game.trialStreakRewardReady) ...[
                const SizedBox(width: 7),
                SizedBox(
                  height: 34,
                  child: FilledButton(
                    key: const Key('claim-trial-streak'),
                    onPressed: () => _claim(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(strings.pick('Claim', 'Claim')),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 7),
          LayoutBuilder(
            builder: (context, constraints) => Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 14,
                  right: 14,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8CAE8),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var day = 1; day <= 7; day++)
                      Semantics(
                        label: strings.pick(
                          'Day $day ${day <= filled ? 'complete' : 'empty'}',
                          'Dag $day ${day <= filled ? 'voltooid' : 'leeg'}',
                        ),
                        child: AnimatedScale(
                          key: Key('trial-streak-day-$day'),
                          duration: const Duration(milliseconds: 280),
                          scale: day <= filled ? 1 : .84,
                          child: Opacity(
                            opacity: day <= filled ? 1 : .3,
                            child: Image.asset(
                              'assets/images/ui/trials/trial_constellation_node.png',
                              width: 29,
                              height: 29,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _claim(BuildContext context) async {
    final strings = AppStrings.of(context);
    final reward =
        await context.read<HouseholdProvider>().claimTrialStreakReward();
    if (!context.mounted || reward == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(strings.pick(
        'Constellation claimed: ${strings.chestLabel(reward)}!',
        'Constellatie geclaimd: ${strings.chestLabel(reward)}!',
      )),
    ));
  }
}

class _TrialRefreshCountdown extends StatelessWidget {
  const _TrialRefreshCountdown({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('trial-refresh-countdown'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .24),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GameIconSprite(GameIconKind.clock, size: 18),
            const SizedBox(width: 4),
            Text(
              _formatRefreshCountdown(remaining, includeDays: false),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
}

class _EmptyTrials extends StatelessWidget {
  const _EmptyTrials();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const GameIconSprite(GameIconKind.adventureActive, size: 96),
            const SizedBox(height: 12),
            Text(
              strings.pick('The Trial gates are resting',
                  'De poorten van de proeven rusten'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            const SizedBox(height: 5),
            Text(
              strings.pick(
                'A new Trial appears at the next quarter-hour.',
                'Op het volgende kwartier verschijnt een nieuwe proef.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrialOfferCard extends StatelessWidget {
  const _TrialOfferCard({required this.offer});

  final TrialOffer offer;

  String get _asset => switch (offer.kind) {
        TrialKind.cavernFlight =>
          'assets/images/ui/trials/trial_cavern_flight.webp',
        TrialKind.ruinBreaker =>
          'assets/images/ui/trials/trial_ruin_breaker.webp',
        TrialKind.runeweaver => 'assets/images/ui/trials/trial_runeweaver.webp',
      };

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final definition = offer.definition;
    final best = game.accountTrialBest(offer.kind);
    return Card(
      key: Key('trial-offer-${offer.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _startTrial(context, offer),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 148,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(_asset, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xD9231746)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 15,
                    right: 54,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.pick(
                            definition.titleEn,
                            definition.titleNl,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            shadows: [Shadow(blurRadius: 7)],
                          ),
                        ),
                        Text(
                          _focusName(strings, definition.focus),
                          style: const TextStyle(
                            color: Color(0xFFFFE08A),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton.filledTonal(
                      key: Key('dismiss-trial-${offer.id}'),
                      tooltip: strings.pick('Dismiss Trial', 'Proef negeren'),
                      onPressed: () => game.dismissTrial(offer.id),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 12, 12, 13),
              child: Row(
                children: [
                  TrialIconSprite(kind: offer.kind, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.pick(
                            definition.subtitleEn,
                            definition.subtitleNl,
                          ),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11.5,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          best == 0
                              ? strings.pick('No account record yet',
                                  'Nog geen accountrecord')
                              : '${strings.pick('Account best', 'Accountrecord')}: $best',
                          style: const TextStyle(
                            color: AppColors.twilight,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: const BoxDecoration(
                      color: AppColors.goldLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.twilight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _startTrial(BuildContext context, TrialOffer offer) async {
  final game = context.read<HouseholdProvider>();
  final strings = AppStrings.of(context);
  final dragons = game.ownedDragons
      .where((dragon) => dragon.activeAdventureId == null)
      .toList()
    ..sort((a, b) => b
        .trainingFor(offer.definition.focus)
        .compareTo(a.trainingFor(offer.definition.focus)));
  if (dragons.isEmpty) {
    showAppSnackBar(
      context,
      strings.pick(
        'No dragon is currently available for this Trial.',
        'Er is nu geen draak beschikbaar voor deze proef.',
      ),
    );
    return;
  }
  final dragon = await showModalBottomSheet<Pet>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TrialDragonPicker(
      offer: offer,
      dragons: dragons,
    ),
  );
  if (dragon == null || !context.mounted) return;
  game.beginPresentationDeferral();
  try {
    await Navigator.of(context).push<TrialCompletion>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TrialGameScreen(
          offerId: offer.id,
          dragonId: dragon.id,
        ),
      ),
    );
  } finally {
    // Navigator.push completes at the start of the pop transition. Keep the
    // cinematic queue deferred until the Trial route is fully off screen, so
    // the result/reward flow cannot remain visible underneath a reveal.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    game.endPresentationDeferral();
  }
}

class _TrialDragonPicker extends StatelessWidget {
  const _TrialDragonPicker({required this.offer, required this.dragons});

  final TrialOffer offer;
  final List<Pet> dragons;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final focus = offer.definition.focus;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: Column(
                children: [
                  Text(
                    strings.pick('Choose your Trial dragon',
                        'Kies je draak voor de proef'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _trialStatBenefit(strings, offer.kind),
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                key: const Key('trial-dragon-picker'),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                itemCount: dragons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 7),
                itemBuilder: (context, index) {
                  final dragon = dragons[index];
                  return Card(
                    color: index == 0 ? const Color(0xFFFFFAE9) : Colors.white,
                    child: ListTile(
                      key: Key('trial-dragon-${dragon.id}'),
                      onTap: () => Navigator.pop(context, dragon),
                      leading: SizedBox.square(
                        dimension: 58,
                        child: DragonArt(
                          height: 58,
                          animate: false,
                          stageKey: dragon.stageKey,
                          lineageId: dragon.lineageId,
                          evolutionPath: dragon.activeEvolutionPath,
                          prismatic: dragon.prismatic,
                          sinister: dragon.sinister,
                        ),
                      ),
                      title: Text(
                        dragon.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Row(
                        children: [
                          ExpertiseScoreBadge(
                            dragonId: dragon.id,
                            focus: focus,
                            focusLabel: _focusName(strings, focus),
                            score: dragon.trainingFor(focus),
                            maximum: dragon.expertiseMaximum(focus),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${strings.pick('Best', 'Beste')}: '
                              '${dragon.trialBest(offer.kind.name)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TrialIconSprite(kind: offer.kind, size: 34),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _trialStatBenefit(AppStrings strings, TrialKind kind) => switch (kind) {
      TrialKind.cavernFlight => strings.pick(
          'Higher Spirit makes the real collision box up to 10% smaller.',
          'Hogere Spirit maakt de echte hitbox tot 10% kleiner.'),
      TrialKind.ruinBreaker => strings.pick(
          'Higher Might widens successful timing up to 15% and Perfect up to 5%.',
          'Hogere Kracht vergroot succesvolle timing tot 15% en Perfect tot 5%.'),
      TrialKind.runeweaver => strings.pick(
          'Higher Arcana keeps every demonstrated rune visible longer.',
          'Hogere Arcana houdt iedere getoonde rune langer zichtbaar.'),
    };

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
          if (kind == AdventureKind.group)
            _GroupAdventureSection(
              adventure: game.adventuresFor(kind).firstOrNull,
              now: now,
            )
          else
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _kindTitle(strings, kind),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _AdventureInfoButton(kind: kind),
                      ],
                    ),
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

class _GroupAdventureSection extends StatelessWidget {
  const _GroupAdventureSection({required this.adventure, required this.now});

  final AdventureDefinition? adventure;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final online = context.watch<OnlineAccountProvider>();
    final colors = _kindColors(AdventureKind.group);
    final serverAdventureId = online.groupAdventureStatus?.adventureId;
    final effectiveAdventure = serverAdventureId == null
        ? adventure
        : AdventureCatalog.byId[serverAdventureId] ?? adventure;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.last.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const GameIconSprite(GameIconKind.adventureGroup, size: 46),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _kindTitle(strings, AdventureKind.group),
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const _AdventureInfoButton(kind: AdventureKind.group),
                    ],
                  ),
                  Text(_kindDescription(strings, AdventureKind.group),
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 10)),
                ],
              ),
            ),
            _AdventureRefreshCountdown(
              kind: AdventureKind.group,
              remaining: game.adventureRefreshRemaining(
                AdventureKind.group,
                from: now,
              )!,
            ),
          ]),
          const SizedBox(height: 7),
          if (!online.isConfigured || !online.isSignedIn)
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading:
                    const Icon(Icons.lock_rounded, color: AppColors.twilight),
                title: Text(strings.pick('Sign in for Group Adventures',
                    'Log in voor groepsavonturen')),
                subtitle: Text(strings.pick(
                  'Group Adventures are only available to verified online accounts.',
                  'Groepsavonturen zijn alleen beschikbaar voor geverifieerde online accounts.',
                )),
              ),
            )
          else ...[
            if (effectiveAdventure case final definition?)
              if (!online.currentGroupOfferConsumed)
                _GroupOfferCard(adventure: definition)
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                  child: Text(
                    strings.pick(
                      'Your current weekly Group Adventure is reserved. Its lobby or journey stays under Active, then moves to Completed when rewards are ready.',
                      'Je huidige wekelijkse groepsavontuur is gereserveerd. De lobby of reis staat onder Actief en verhuist naar Voltooid zodra de beloningen klaarstaan.',
                    ),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
            if (online.joinableGroupAdventures.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 10, 6, 5),
                child: Text(
                  strings.pick('Friends looking for dragons',
                      'Vrienden zoeken nog draken'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              for (final lobby in online.joinableGroupAdventures)
                _JoinableGroupLobbyCard(lobby: lobby),
            ],
          ],
        ],
      ),
    );
  }
}

class _GroupOfferCard extends StatelessWidget {
  const _GroupOfferCard({required this.adventure});

  final AdventureDefinition adventure;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SizedBox(
      height: 88,
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.white.withValues(alpha: .96),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('group-offer-${adventure.id}'),
          onTap: () => _showAdventureDetailsForGroup(context, adventure),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 8, 7, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.adventureTitle(adventure),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
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
                          const SizedBox(width: 8),
                          const Icon(Icons.group_rounded,
                              size: 18, color: AppColors.twilight),
                          const SizedBox(width: 3),
                          Text(
                            '${adventure.requirements.players} ${strings.pick('dragons', 'draken')}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GameIconSprite(
                            GameIconSprite.forTrainingFocus(adventure.focus),
                            size: 19,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _GroupActionButton(
                  key: const Key('create-group-lobby'),
                  label: strings.pick('Create', 'Maken'),
                  icon: GameIconKind.adventureStart,
                  onPressed: () => _createGroupLobby(context, adventure),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JoinableGroupLobbyCard extends StatelessWidget {
  const _JoinableGroupLobbyCard({required this.lobby});

  final GroupAdventureLobby lobby;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final owner = lobby.owner;
    final definition = AdventureCatalog.byId[lobby.adventureId];
    return Card(
      margin: const EdgeInsets.only(top: 7),
      color: Colors.white.withValues(alpha: .96),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('joinable-group-${lobby.id}'),
        onTap: () => _showGroupLobbyDetails(context, lobby),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
          child: Row(
            children: [
              KeeperPortrait(
                portraitKey: owner?.keeper.portraitKey ?? 'portrait_001',
                displayName: owner?.keeper.displayName ?? 'Keeper',
                frameKey: owner?.keeper.frameKey,
                badgeKey: owner?.keeper.badgeKey,
                radius: 24,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(owner?.keeper.displayName ?? 'Keeper',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(
                      definition == null
                          ? lobby.adventureId
                          : strings.adventureTitle(definition),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: lobby.participants.length /
                            lobby.requiredPlayers.clamp(1, 4),
                        color: const Color(0xFF5F9F86),
                        backgroundColor: const Color(0xFFDDF1E8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GameIconSprite(GameIconKind.adventureGroup, size: 39),
                  Text(
                    '${lobby.participants.length}/${lobby.requiredPlayers}',
                    style: const TextStyle(
                      color: AppColors.twilight,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupActionButton extends StatelessWidget {
  const _GroupActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final GameIconKind icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              width: 56,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7256B5), Color(0xFF4C358D)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x334C358D),
                    blurRadius: 9,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GameIconSprite(icon, size: 33),
                  Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

Future<Pet?> _pickGroupDragon(
  BuildContext context,
  AdventureDefinition adventure,
) async {
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
    return null;
  }
  if (!context.mounted) return null;
  return showModalBottomSheet<Pet>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _DragonPicker(adventure: adventure, dragons: available),
  );
}

Future<void> _createGroupLobby(
  BuildContext context,
  AdventureDefinition adventure,
) async {
  final dragon = await _pickGroupDragon(context, adventure);
  if (dragon == null || !context.mounted) return;
  final online = context.read<OnlineAccountProvider>();
  final success = await online.createGroupLobby(
    adventure.id,
    GroupDragonSubmission.fromPet(dragon),
  );
  if (!context.mounted) return;
  if (success) unawaited(HavenAudio.play(HavenSound.adventureStart));
  _showOnlineAdventureMessage(context, online);
}

Future<void> _joinGroupLobby(
  BuildContext context,
  GroupAdventureLobby lobby,
) async {
  final adventure = AdventureCatalog.byId[lobby.adventureId];
  if (adventure == null) return;
  final dragon = await _pickGroupDragon(context, adventure);
  if (dragon == null || !context.mounted) return;
  final online = context.read<OnlineAccountProvider>();
  final success = await online.joinGroupLobby(
    lobby.id,
    GroupDragonSubmission.fromPet(dragon),
  );
  if (!context.mounted) return;
  if (success) unawaited(HavenAudio.play(HavenSound.adventureStart));
  _showOnlineAdventureMessage(context, online);
}

void _showAdventureDetailsForGroup(
  BuildContext context,
  AdventureDefinition adventure,
) {
  final strings = AppStrings.of(context);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const GameIconSprite(GameIconKind.adventureGroup, size: 110),
          Text(strings.adventureTitle(adventure),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(strings.adventureDescription(adventure),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          _GroupRequirementsCard(adventure: adventure),
          const SizedBox(height: 10),
          _CompletedAdventureRewards(
            key: const Key('group-offer-expected-rewards'),
            definition: adventure,
            groupChestRange: true,
            approximate: true,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) _createGroupLobby(context, adventure);
                });
              },
              icon: const Icon(Icons.group_add_rounded),
              label: Text(strings.pick('Create group', 'Groep maken')),
            ),
          ),
        ]),
      ),
    ),
  );
}

class _GroupRequirementSummary extends StatelessWidget {
  const _GroupRequirementSummary({
    required this.adventure,
    this.decorated = true,
  });

  final AdventureDefinition adventure;
  final bool decorated;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final requirements = adventure.requirements;
    final details = <({Widget icon, String label})>[
      (
        icon: const Icon(Icons.group_rounded,
            color: AppColors.twilight, size: 21),
        label:
            '${requirements.players} ${strings.pick('participants', 'deelnemers')}'
      ),
      if (requirements.combinedLevel > 0)
        (
          icon: const GameIconSprite(GameIconKind.experience, size: 23),
          label:
              '${strings.pick('combined level', 'gecombineerd niveau')} ${requirements.combinedLevel}'
        ),
      if (requirements.combinedStat > 0)
        (
          icon: GameIconSprite(
            GameIconSprite.forTrainingFocus(
              requirements.focus ?? adventure.focus,
            ),
            size: 23,
          ),
          label:
              '${strings.pick('combined', 'gecombineerde')} ${_focusName(strings, requirements.focus ?? adventure.focus)} ${requirements.combinedStat}'
        ),
    ];
    final content = Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 7,
      children: [
        for (final detail in details)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              detail.icon,
              const SizedBox(width: 4),
              Text(
                detail.label,
                style: const TextStyle(
                  color: AppColors.twilight,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
      ],
    );
    if (!decorated) return content;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9FBF4),
        borderRadius: BorderRadius.circular(17),
      ),
      child: content,
    );
  }
}

class _GroupRequirementsCard extends StatelessWidget {
  const _GroupRequirementsCard({required this.adventure});

  final AdventureDefinition adventure;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      key: const Key('group-adventure-requirements'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9FBF4),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0x335F9F86)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_rounded,
                  color: Color(0xFF24735B), size: 20),
              const SizedBox(width: 6),
              Text(
                strings.pick(
                    'Requirements to start', 'Vereisten om te starten'),
                style: const TextStyle(
                  color: Color(0xFF24735B),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            strings.pick(
              'The group can only depart when every requirement below is met.',
              'De groep kan pas vertrekken als aan alle onderstaande vereisten is voldaan.',
            ),
            style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
          ),
          const SizedBox(height: 8),
          _GroupRequirementSummary(adventure: adventure, decorated: false),
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
                          adventure.combinedExpertise
                              ? strings.pick(
                                  'All Expertises', 'Alle Expertises')
                              : _focusName(strings, adventure.focus),
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
    final game = context.read<HouseholdProvider>();
    final specialEvent = specialAdventureEventForAdventure(definition.id);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
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
            if (specialEvent != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5DE),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  strings.pick(specialEvent.storyEn, specialEvent.storyNl),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF795225),
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
            if (!definition.combinedExpertise)
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
            if (definition.combinedExpertise)
              _DetailRow(
                icon: const GameIconSprite(GameIconKind.adventureSpecial,
                    size: 34),
                title: strings.pick('Journey shortening', 'Reisverkorting'),
                value: strings.pick(
                  'Might + Arcana + Spirit: every combined point removes 1 hour (minimum 1 day).',
                  'Might + Arcana + Spirit: elk gecombineerd punt haalt 1 uur van de reis af (minimum 1 dag).',
                ),
              ),
            if (specialEvent == null)
              _DetailRow(
                icon: const GameIconSprite(GameIconKind.chest, size: 34),
                title: strings.pick('Possible chests', 'Mogelijke kisten'),
                value: _chestPossibilities(strings, definition),
              ),
            if (specialEvent != null) ...[
              _DetailRow(
                icon: Image.asset(
                  ChestTier.special.assetPath,
                  width: 38,
                  height: 38,
                ),
                title: strings.pick(
                    'Guaranteed Special Chest', 'Gegarandeerde Speciale Kist'),
                value: strings.pick(
                  '269 coins, 10 gems and a Special Egg with an event dragon.',
                  '269 coins, 10 gems en een Speciaal Ei met een eventdraak.',
                ),
              ),
              _DetailRow(
                icon: Image.asset(
                  MysticRelic.moralPrism.assetPath,
                  width: 36,
                  height: 36,
                ),
                title: strings.pick('Guaranteed relic', 'Gegarandeerde relic'),
                value: strings.pick(
                  '1 random relic; which one remains a surprise until you claim it.',
                  '1 willekeurige relic; welke het is blijft een verrassing tot je hem ophaalt.',
                ),
              ),
              if (specialEvent.rewards.musicChest &&
                  !game.musicChestCapacityReached)
                _DetailRow(
                  icon: Image.asset(
                    ChestTier.music.assetPath,
                    width: 38,
                    height: 38,
                  ),
                  title: strings.pick(
                      'Guaranteed Music Chest', 'Gegarandeerde Muziekkist'),
                  value: strings.pick(
                    '1 Music Chest, rolled only when you open it.',
                    '1 Muziekkist, pas gerolld wanneer je hem opent.',
                  ),
                ),
            ],
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
                key: const Key('adventure-details-choose-dragon'),
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
                    ExpertiseScoreBadge(
                      dragonId: dragon.id,
                      focus: focus,
                      focusLabel: _focusName(strings, focus),
                      score: dragon.trainingFor(focus),
                      maximum: dragon.expertiseMaximum(focus),
                    ),
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
    final online = context.watch<OnlineAccountProvider>();
    final runs = game.activeAdventureRuns
        .where((run) => run.status == AdventureRunStatus.running)
        .toList(growable: false);
    final groupRuns = online.isSignedIn
        ? online.myGroupAdventures
            .where((lobby) => !_groupAdventureReady(lobby, now))
            .toList(growable: false)
        : const <GroupAdventureLobby>[];
    if (runs.isEmpty && groupRuns.isEmpty) {
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
    final itemCount = groupRuns.length + runs.length;
    return ListView.separated(
      key: const PageStorageKey('active-adventures-scroll'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => index < groupRuns.length
          ? _ActiveGroupAdventureCard(lobby: groupRuns[index], now: now)
          : _ActiveAdventureCard(
              run: runs[index - groupRuns.length],
              now: now,
            ),
    );
  }
}

class _CompletedAdventures extends StatelessWidget {
  const _CompletedAdventures({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final online = context.watch<OnlineAccountProvider>();
    final runs = game.activeAdventureRuns
        .where((run) => run.status == AdventureRunStatus.rewardReady)
        .toList(growable: false);
    final groupRuns = online.isSignedIn
        ? online.myGroupAdventures
            .where((lobby) => _groupAdventureReady(lobby, now))
            .toList(growable: false)
        : const <GroupAdventureLobby>[];
    if (runs.isEmpty && groupRuns.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GameIconSprite(GameIconKind.chest, size: 142),
              Text(
                strings.pick(
                  'No completed adventures',
                  'Geen voltooide avonturen',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                strings.pick(
                  'Finished journeys wait here until you collect their rewards.',
                  'Afgeronde reizen wachten hier tot je hun beloningen ophaalt.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }
    final itemCount = groupRuns.length + runs.length;
    return ListView.separated(
      key: const PageStorageKey('completed-adventures-scroll'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => index < groupRuns.length
          ? _ActiveGroupAdventureCard(lobby: groupRuns[index], now: now)
          : _ActiveAdventureCard(
              run: runs[index - groupRuns.length],
              now: now,
            ),
    );
  }
}

bool _groupAdventureReady(GroupAdventureLobby lobby, DateTime now) =>
    lobby.isRewardReady ||
    (lobby.endsAt?.isAfter(now) == false && !lobby.isWaiting);

class _ActiveGroupAdventureCard extends StatelessWidget {
  const _ActiveGroupAdventureCard({required this.lobby, required this.now});

  final GroupAdventureLobby lobby;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final definition = AdventureCatalog.byId[lobby.adventureId];
    if (definition == null) return const SizedBox.shrink();
    final timedReady = lobby.endsAt?.isAfter(now) == false && !lobby.isWaiting;
    final ready = lobby.isRewardReady || timedReady;
    final myDragon =
        lobby.participants.cast<GroupAdventureParticipant?>().firstWhere(
              (participant) => participant?.dragonId == lobby.myDragonId,
              orElse: () => null,
            );
    final status = lobby.isWaiting
        ? strings.pick(
            'Waiting for ${lobby.requiredPlayers - lobby.participants.length} dragon(s)',
            'Wacht op ${lobby.requiredPlayers - lobby.participants.length} draak/draken')
        : ready
            ? strings.pick('Rewards are ready', 'Beloningen staan klaar')
            : adventureRemainingLabel(lobby.endsAt!, strings, now: now);
    return Card(
      key: Key('active-group-${lobby.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showGroupLobbyDetails(context, lobby),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 13, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: _kindColors(AdventureKind.group)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const GameIconSprite(GameIconKind.adventureGroup,
                      size: 74),
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
                      const SizedBox(height: 3),
                      Text(
                        '${myDragon?.dragonName ?? strings.pick('Your dragon', 'Jouw draak')} · '
                        '${lobby.participants.length}/${lobby.requiredPlayers}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 7),
                      Text(status,
                          style: TextStyle(
                            color: ready
                                ? const Color(0xFF24735B)
                                : AppColors.twilight,
                            fontWeight: FontWeight.w900,
                          )),
                    ],
                  ),
                ),
                if (ready)
                  FilledButton.tonal(
                    key: Key('claim-group-${lobby.id}'),
                    onPressed: () => _claimGroupReward(context, lobby.id),
                    child: Text(strings.pick('Claim', 'Ophalen')),
                  )
                else
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.twilight),
              ]),
              if (ready) ...[
                const SizedBox(height: 10),
                _CompletedAdventureRewards(
                  key: Key('completed-group-rewards-${lobby.id}'),
                  definition: definition,
                  groupChestRange: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showGroupLobbyDetails(
  BuildContext context,
  GroupAdventureLobby originalLobby,
) async {
  final rootContext = context;
  final strings = AppStrings.of(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Consumer<OnlineAccountProvider>(
      builder: (context, online, _) {
        final lobby =
            online.groupLobbies.cast<GroupAdventureLobby?>().firstWhere(
                      (candidate) => candidate?.id == originalLobby.id,
                      orElse: () => originalLobby,
                    ) ??
                originalLobby;
        final definition = AdventureCatalog.byId[lobby.adventureId];
        if (definition == null) return const SizedBox.shrink();
        final now = rootContext.read<HouseholdProvider>().currentTime;
        final ready = lobby.isRewardReady ||
            (lobby.endsAt?.isAfter(now) == false && !lobby.isWaiting);
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: .78,
            maxChildSize: .94,
            builder: (_, controller) => ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              children: [
                const Center(
                  child: GameIconSprite(GameIconKind.adventureGroup, size: 108),
                ),
                Text(strings.adventureTitle(definition),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  lobby.isWaiting
                      ? strings.pick(
                          'The journey starts automatically when all requirements are met.',
                          'De reis start automatisch zodra aan alle vereisten is voldaan.')
                      : ready
                          ? strings.pick('The group has returned.',
                              'De groep is teruggekeerd.')
                          : adventureRemainingLabel(
                              lobby.endsAt!,
                              strings,
                              now: now,
                            ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                _GroupRequirementsCard(adventure: definition),
                const SizedBox(height: 12),
                _CompletedAdventureRewards(
                  key: const Key('completed-group-detail-rewards'),
                  definition: definition,
                  groupChestRange: true,
                  approximate: !ready,
                ),
                const SizedBox(height: 14),
                Text(
                  '${strings.pick('Participants', 'Deelnemers')} '
                  '${lobby.participants.length}/${lobby.requiredPlayers}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                for (final participant in lobby.participants)
                  Card(
                    child: ListTile(
                      leading: KeeperPortrait(
                        portraitKey: participant.keeper.portraitKey,
                        displayName: participant.keeper.displayName,
                        frameKey: participant.keeper.frameKey,
                        badgeKey: participant.keeper.badgeKey,
                        radius: 23,
                      ),
                      title: Text(participant.keeper.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: Text(
                        '${keeperTitleLabel(strings, participant.keeper.title)}\n'
                        '${participant.dragonName} · ${strings.pick('Level', 'Niveau')} ${participant.level} · '
                        'M ${participant.might} / A ${participant.arcana} / S ${participant.spirit}',
                      ),
                      isThreeLine: true,
                      trailing: lobby.isWaiting &&
                              lobby.isOwner &&
                              !participant.isOwner
                          ? IconButton(
                              key: Key(
                                  'remove-group-participant-${participant.keeper.userId}'),
                              tooltip: strings.pick(
                                  'Remove dragon', 'Draak verwijderen'),
                              onPressed: online.busy
                                  ? null
                                  : () => _confirmRemoveGroupParticipant(
                                        sheetContext,
                                        lobby,
                                        participant,
                                      ),
                              icon: const Icon(Icons.person_remove_rounded,
                                  color: Colors.redAccent),
                            )
                          : null,
                    ),
                  ),
                const SizedBox(height: 12),
                if (lobby.isWaiting && !lobby.isParticipant)
                  FilledButton.icon(
                    key: const Key('join-group-lobby'),
                    onPressed: online.busy
                        ? null
                        : () async {
                            Navigator.pop(sheetContext);
                            if (rootContext.mounted) {
                              await _joinGroupLobby(rootContext, lobby);
                            }
                          },
                    icon: const Icon(Icons.group_add_rounded),
                    label: Text(strings.pick(
                        'Join with a dragon', 'Aanmelden met een draak')),
                  ),
                if (lobby.isWaiting && lobby.isParticipant)
                  OutlinedButton.icon(
                    key: const Key('leave-group-lobby'),
                    onPressed: online.busy
                        ? null
                        : () => _confirmLeaveGroupLobby(
                              sheetContext,
                              lobby,
                            ),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(lobby.isOwner
                        ? strings.pick('Cancel group', 'Groep annuleren')
                        : strings.pick('Withdraw', 'Uitschrijven')),
                  ),
                if (ready && lobby.isParticipant)
                  FilledButton.icon(
                    key: const Key('claim-group-reward'),
                    onPressed: online.busy
                        ? null
                        : () async {
                            final reward =
                                await online.claimGroupReward(lobby.id);
                            if (!sheetContext.mounted || reward == null) {
                              if (sheetContext.mounted) {
                                _showOnlineAdventureMessage(
                                    sheetContext, online);
                              }
                              return;
                            }
                            Navigator.pop(sheetContext);
                            if (rootContext.mounted) {
                              _showGroupRewardMessage(rootContext, reward);
                            }
                          },
                    icon: const GameIconSprite(GameIconKind.chest, size: 32),
                    label: Text(
                        strings.pick('Claim rewards', 'Beloningen ophalen')),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<void> _confirmLeaveGroupLobby(
  BuildContext context,
  GroupAdventureLobby lobby,
) async {
  final strings = AppStrings.of(context);
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(lobby.isOwner
              ? strings.pick('Cancel this group?', 'Deze groep annuleren?')
              : strings.pick('Withdraw from this group?',
                  'Uitschrijven voor deze groep?')),
          content: Text(strings.pick(
            'This is only possible before the adventure starts.',
            'Dit kan alleen voordat het avontuur begint.',
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.tr('cancel')),
            ),
            FilledButton(
              key: const Key('confirm-leave-group'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.pick('Confirm', 'Bevestigen')),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed || !context.mounted) return;
  final online = context.read<OnlineAccountProvider>();
  final success = await online.leaveGroupLobby(lobby.id);
  if (!context.mounted) return;
  if (success) Navigator.pop(context);
  _showOnlineAdventureMessage(context, online);
}

Future<void> _confirmRemoveGroupParticipant(
  BuildContext context,
  GroupAdventureLobby lobby,
  GroupAdventureParticipant participant,
) async {
  final strings = AppStrings.of(context);
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(strings.pick(
              'Remove this dragon?', 'Deze draak uit de groep verwijderen?')),
          content: Text(
              '${participant.keeper.displayName} · ${participant.dragonName}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.tr('cancel')),
            ),
            FilledButton(
              key: const Key('confirm-remove-group-participant'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.pick('Remove', 'Verwijderen')),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed || !context.mounted) return;
  final online = context.read<OnlineAccountProvider>();
  await online.removeGroupParticipant(lobby.id, participant.keeper.userId);
  if (context.mounted) _showOnlineAdventureMessage(context, online);
}

Future<void> _claimGroupReward(BuildContext context, String lobbyId) async {
  final online = context.read<OnlineAccountProvider>();
  final reward = await online.claimGroupReward(lobbyId);
  if (!context.mounted) return;
  if (reward == null) {
    _showOnlineAdventureMessage(context, online);
    return;
  }
  _showGroupRewardMessage(context, reward);
}

void _showGroupRewardMessage(
  BuildContext context,
  GroupAdventureReward reward,
) {
  final strings = AppStrings.of(context);
  final tier = ChestTier.values.firstWhere(
    (candidate) => candidate.name == reward.chestTier,
    orElse: () => ChestTier.gold,
  );
  unawaited(HavenAudio.play(HavenSound.adventureReturn));
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(strings.pick(
      '${strings.chestLabel(tier)} and Group Adventure rewards added.',
      '${strings.chestLabel(tier)} en groepsbeloningen toegevoegd.',
    )),
  ));
}

void _showOnlineAdventureMessage(
  BuildContext context,
  OnlineAccountProvider online,
) {
  final code = online.errorCode ?? online.noticeCode;
  if (code == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(socialMessage(
      AppStrings.of(context),
      code,
      supportCode: online.errorCode == null ? null : online.supportCode,
    )),
  ));
  online.clearMessages();
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
    final abortable = !ready && definition.kind != AdventureKind.group;
    final specialEvent = specialAdventureEventById(run.specialEventId);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showRunDetails(context, run, definition, dragon),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 13, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                            dragon?.displayName ??
                                strings.pick(
                                    'Unknown dragon', 'Onbekende draak'),
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12)),
                        const SizedBox(height: 7),
                        Row(children: [
                          const GameIconSprite(GameIconKind.clock, size: 22),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ready
                                  ? strings.pick('Ready to return',
                                      'Klaar om terug te keren')
                                  : adventureRemainingLabel(
                                      run.endsAt,
                                      strings,
                                      now: now,
                                    ),
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
                  else if (abortable)
                    IconButton(
                      key: Key('abort-adventure-${run.id}'),
                      tooltip:
                          strings.pick('Abort adventure', 'Avontuur afbreken'),
                      onPressed: () => _confirmAbortAdventure(
                        context,
                        run,
                        dragon?.displayName,
                      ),
                      icon: const Icon(Icons.cancel_outlined,
                          color: AppColors.twilight),
                    )
                  else
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.twilight),
                ],
              ),
              if (ready) ...[
                const SizedBox(height: 10),
                _CompletedAdventureRewards(
                  key: Key('completed-adventure-rewards-${run.id}'),
                  definition: definition,
                  chestTier: run.rewardTier ?? definition.knownChest,
                  specialEvent: specialEvent,
                  includeMusicChest: specialEvent?.rewards.musicChest == true &&
                      !game.musicChestCapacityReached,
                ),
              ],
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
  final specialEvent = specialAdventureEventById(run.specialEventId);
  final ready = run.status == AdventureRunStatus.rewardReady;
  final abortable = !ready && definition.kind != AdventureKind.group;
  final chestTier = run.rewardTier ?? definition.knownChest;
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
                    : adventureRemainingLabel(
                        run.endsAt,
                        strings,
                        now: game.currentTime,
                      )),
            _DetailRow(
                icon: const GameIconSprite(GameIconKind.experience, size: 34),
                title: strings.pick('Dragon experience', 'Drakenervaring'),
                value: '${definition.xp} XP'),
            if (!definition.combinedExpertise)
              _DetailRow(
                  icon: GameIconSprite(
                      GameIconSprite.forTrainingFocus(definition.focus),
                      size: 34),
                  title: strings.pick('Training reward', 'Trainingsbeloning'),
                  value:
                      '+${definition.statPoints} ${_focusName(strings, definition.focus)}'),
            if (specialEvent == null)
              _DetailRow(
                  icon: const GameIconSprite(GameIconKind.chest, size: 34),
                  title: strings.pick('Treasure', 'Schat'),
                  value: ready && chestTier != null
                      ? strings.chestLabel(chestTier)
                      : strings.pick(
                          'One sealed chest', 'Eén verzegelde kist')),
            if (specialEvent != null) ...[
              _DetailRow(
                icon: Image.asset(ChestTier.special.assetPath,
                    width: 38, height: 38),
                title: strings.pick(
                    'Guaranteed Special Chest', 'Gegarandeerde Speciale Kist'),
                value: strings.pick(
                  '269 coins, 10 gems and a Special Egg with an event dragon.',
                  '269 coins, 10 gems en een Speciaal Ei met een eventdraak.',
                ),
              ),
              _DetailRow(
                icon: Image.asset(MysticRelic.moralPrism.assetPath,
                    width: 36, height: 36),
                title: strings.pick('Guaranteed relic', 'Gegarandeerde relic'),
                value: strings.pick(
                  '1 random relic; the exact relic is still a surprise.',
                  '1 willekeurige relic; de exacte relic blijft nog een verrassing.',
                ),
              ),
              if (specialEvent.rewards.musicChest &&
                  !game.musicChestCapacityReached)
                _DetailRow(
                  icon: Image.asset(ChestTier.music.assetPath,
                      width: 38, height: 38),
                  title: strings.pick(
                      'Guaranteed Music Chest', 'Gegarandeerde Muziekkist'),
                  value: strings.pick(
                    '1 Music Chest, rolled when it is opened.',
                    '1 Muziekkist, gerolld wanneer hij wordt geopend.',
                  ),
                ),
            ],
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
              )
            else if (abortable)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: Key('abort-adventure-details-${run.id}'),
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await _confirmAbortAdventure(
                      context,
                      run,
                      dragon?.displayName,
                    );
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(
                    strings.pick('Abort adventure', 'Avontuur afbreken'),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _confirmAbortAdventure(
  BuildContext context,
  AdventureRun run,
  String? dragonName,
) async {
  final strings = AppStrings.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(strings.pick('Abort adventure?', 'Avontuur afbreken?')),
          content: Text(strings.pick(
            '${dragonName ?? 'Your dragon'} returns immediately, but you receive no rewards.',
            '${dragonName ?? 'Je draak'} keert direct terug, maar je ontvangt geen beloningen.',
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.pick('Keep going', 'Doorgaan')),
            ),
            FilledButton(
              key: Key('confirm-abort-adventure-${run.id}'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.pick('Abort', 'Afbreken')),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed || !context.mounted) return;
  final aborted =
      await context.read<HouseholdProvider>().abortAdventure(run.id);
  if (!aborted || messenger?.mounted != true) return;
  messenger!.showSnackBar(SnackBar(
    content: Text(strings.pick(
      'Adventure aborted. Your dragon is available again.',
      'Avontuur afgebroken. Je draak is weer beschikbaar.',
    )),
  ));
}

class _CompletedAdventureRewards extends StatelessWidget {
  const _CompletedAdventureRewards({
    super.key,
    required this.definition,
    this.chestTier,
    this.specialEvent,
    this.includeMusicChest = false,
    this.groupChestRange = false,
    this.approximate = false,
  });

  final AdventureDefinition definition;
  final ChestTier? chestTier;
  final SpecialAdventureEventDefinition? specialEvent;
  final bool includeMusicChest;
  final bool groupChestRange;
  final bool approximate;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final resolvedChest = chestTier ?? definition.knownChest;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0x225B4B8A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            approximate
                ? strings.pick('Expected rewards', 'Verwachte beloningen')
                : strings.pick('Rewards', 'Beloningen'),
            style: const TextStyle(
              color: AppColors.twilight,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _AdventureRewardPill(
                icon: const GameIconSprite(GameIconKind.experience, size: 24),
                label: '+${definition.xp} XP',
              ),
              if (!definition.combinedExpertise && definition.statPoints > 0)
                _AdventureRewardPill(
                  icon: GameIconSprite(
                    GameIconSprite.forTrainingFocus(definition.focus),
                    size: 24,
                  ),
                  label:
                      '+${definition.statPoints} ${_focusName(strings, definition.focus)}',
                ),
              if (resolvedChest != null)
                _AdventureRewardPill(
                  icon: Image.asset(
                    resolvedChest.assetPath,
                    width: 26,
                    height: 26,
                    cacheWidth: 96,
                  ),
                  label: strings.chestLabel(resolvedChest),
                )
              else if (groupChestRange)
                _AdventureRewardPill(
                  icon: const GameIconSprite(GameIconKind.chest, size: 24),
                  label: strings.pick(
                    '1 Gold, Dragon or Mythical Chest',
                    '1 Gouden, Draken- of Mythische Kist',
                  ),
                ),
              if (specialEvent?.rewards.randomRelicPool.isNotEmpty == true)
                _AdventureRewardPill(
                  icon: Image.asset(
                    MysticRelic.moralPrism.assetPath,
                    width: 25,
                    height: 25,
                    cacheWidth: 80,
                  ),
                  label: strings.pick('1 random relic', '1 willekeurige relic'),
                ),
              if (includeMusicChest)
                _AdventureRewardPill(
                  icon: Image.asset(
                    ChestTier.music.assetPath,
                    width: 26,
                    height: 26,
                    cacheWidth: 96,
                  ),
                  label: strings.chestLabel(ChestTier.music),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdventureRewardPill extends StatelessWidget {
  const _AdventureRewardPill({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          boxShadow: const [
            BoxShadow(
              color: Color(0x125B4B8A),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ],
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
      AdventureKind.mini => strings.pick('Tiny outings', 'Kleine uitstapjes'),
      AdventureKind.short => strings.pick('Quick routes', 'Snelle routes'),
      AdventureKind.long =>
        strings.pick('Patient journeys', 'Geduldige reizen'),
      AdventureKind.group =>
        strings.pick('Shared discoveries', 'Gedeelde ontdekkingen'),
      AdventureKind.special => strings.pick('Rare trails', 'Zeldzame routes'),
    };

class _AdventureInfoButton extends StatelessWidget {
  const _AdventureInfoButton({required this.kind});

  final AdventureKind kind;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Semantics(
      button: true,
      label: strings.pick('Refresh rules', 'Verversregels'),
      child: Material(
        color: Colors.white.withValues(alpha: .72),
        shape: const CircleBorder(
          side: BorderSide(color: Color(0x665D438D)),
        ),
        child: InkWell(
          key: Key('adventure-info-${kind.name}'),
          customBorder: const CircleBorder(),
          onTap: () => _showAdventureRefreshInfo(context, kind),
          child: const SizedBox.square(
            dimension: 24,
            child: Icon(
              Icons.info_outline_rounded,
              size: 17,
              color: AppColors.twilight,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showAdventureRefreshInfo(
  BuildContext context,
  AdventureKind kind,
) async {
  final strings = AppStrings.of(context);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: GameIconSprite(_kindIcon(kind), size: 78),
      title: Text(
        '${_kindTitle(strings, kind)} · ${strings.pick('Refresh rules', 'Verversregels')}',
        textAlign: TextAlign.center,
      ),
      content: Text(
        _adventureRefreshExplanation(strings, kind),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(strings.pick('Close', 'Sluiten')),
        ),
      ],
    ),
  );
}

String _adventureRefreshExplanation(
  AppStrings strings,
  AdventureKind kind,
) =>
    switch (kind) {
      AdventureKind.mini => strings.pick(
          'Up to three routes wait. One free slot refills every 15 minutes. Visible routes stay until you start or dismiss them; they are not automatically replaced.',
          'Er staan maximaal drie routes klaar. Elke 15 minuten wordt één vrije plek aangevuld. Zichtbare routes blijven staan tot je ze start of wegklikt; ze worden niet automatisch vervangen.',
        ),
      AdventureKind.short => strings.pick(
          'Up to three routes wait. One free slot refills every hour. Visible routes stay until you start or dismiss them; they are not automatically replaced.',
          'Er staan maximaal drie routes klaar. Elk uur wordt één vrije plek aangevuld. Zichtbare routes blijven staan tot je ze start of wegklikt; ze worden niet automatisch vervangen.',
        ),
      AdventureKind.long => strings.pick(
          'Up to three routes wait. Free slots refill at local midnight. Visible routes stay until you start or dismiss them; they are not automatically replaced.',
          'Er staan maximaal drie routes klaar. Vrije plekken worden om lokale middernacht aangevuld. Zichtbare routes blijven staan tot je ze start of wegklikt; ze worden niet automatisch vervangen.',
        ),
      AdventureKind.group => strings.pick(
          'Every keeper sees the same weekly route. It changes automatically every Sunday at 12:00 in Europe/Amsterdam. A group that already started always finishes and keeps its reward.',
          'Elke hoeder ziet dezelfde wekelijkse route. Deze verandert automatisch op zondag om 12:00 uur in Europe/Amsterdam. Een gestarte groep maakt de reis altijd af en behoudt de beloning.',
        ),
      AdventureKind.special => strings.pick(
          'Special routes appear only during certain events. They can expire or change automatically; their card shows them only while they are available.',
          'Speciale routes verschijnen alleen tijdens bepaalde gebeurtenissen. Ze kunnen automatisch verlopen of veranderen; hun kaart is alleen zichtbaar zolang ze beschikbaar zijn.',
        ),
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

String adventureRemainingLabel(
  DateTime end,
  AppStrings strings, {
  DateTime? now,
}) {
  final remaining = end.difference(now ?? DateTime.now());
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
