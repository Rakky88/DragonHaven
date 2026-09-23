import 'adventure_hub_screen.dart'
    show
        showRestoredAdventureDetails,
        showRestoredRunDetails,
        adventureKindColors,
        restoredAdventureRewards,
        RestoredAdventureCountdown,
        AdventureRefreshCountdown;
import '../providers/household_provider.dart'
    show SpecialAdventureWindow, adventureOfferRefreshRemaining;
import '../models/dragon_lineage.dart';
import '../models/music_track.dart';
import '../models/trial.dart';
import '../widgets/trial_icon_sprite.dart';
import '../services/canonical_game_snapshot.dart';
import '../theme/app_theme.dart';
import '../widgets/event_point_flight.dart';
import '../widgets/event_progress_bar.dart';
import '../widgets/event_partner_control.dart';
import '../services/canonical_groups.dart';
import 'canonical_groups_screen.dart';
import '../widgets/canonical_social_rewards.dart';
import 'canonical_trials_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/mystic_relic.dart';
import '../models/pet.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../widgets/adventure_expertise_transition.dart';
import '../widgets/canonical_game_controls.dart';
import '../widgets/draconomicon_shortcut.dart';
import '../widgets/expertise_score_badge.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/shop_economy_scope.dart';
import 'canonical_dragons_screen.dart';
import 'draconomicon_screen.dart';

class CanonicalAdventuresScreen extends StatelessWidget {
  const CanonicalAdventuresScreen(
      {super.key, this.showCompleted = false, this.active = true});
  final bool active;
  final bool showCompleted;
  @override
  Widget build(BuildContext context) => ShopEconomyBoundary(
      child: _Adventures(showCompleted: showCompleted, active: active));
}

class _Adventures extends StatefulWidget {
  const _Adventures({required this.showCompleted, required this.active});
  final bool active;
  final bool showCompleted;
  @override
  State<_Adventures> createState() => _AdventuresState();
}

class _AdventuresState extends State<_Adventures>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  int _tab = 0;
  DateTime? _anchor;
  final _elapsed = Stopwatch();
  late final Timer _timer;
  @override
  void initState() {
    super.initState();
    _tab = widget.showCompleted ? 3 : 0;
    _controller = TabController(length: 4, vsync: this, initialIndex: _tab)
      ..addListener(() {
        if (mounted && _tab != _controller.index) {
          setState(() => _tab = _controller.index);
        }
      });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _Adventures oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showCompleted != widget.showCompleted) {
      _controller.animateTo(widget.showCompleted ? 3 : 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    _elapsed.stop();
    super.dispose();
  }

  Future<void> _refreshFromServer() async {
    final session = context.read<CanonicalGameSession>();
    final groups = context.read<CanonicalGroups?>();
    if (groups != null && !groups.loading) {
      await groups.refresh();
    }
    if (!mounted || session.busy) return;
    await runShopAction(context, () async {
      if (!session.canAct) await session.synchronize();
      if (!session.canAct) {
        throw const CanonicalGameException('game_refresh_required');
      }
      await CanonicalGameActions(session).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final view = session.snapshot!;
    if (_anchor != view.serverTime) {
      _anchor = view.serverTime;
      _elapsed
        ..reset()
        ..start();
    }
    final now = _anchor!.add(_elapsed.elapsed);
    final s = AppStrings.of(context);
    final actions = CanonicalGameActions(session);
    final groups = context.watch<CanonicalGroups?>();
    int groupCount(bool completed) =>
        groups?.lobbies
            .where((l) =>
                l.isParticipant &&
                !l.rewardAcknowledged &&
                l.rewardReadyAt(now) == completed)
            .length ??
        0;
    final sigils = view.inventory.usableRelics[MysticRelic.wayfinderSigil] ?? 0;
    Widget content(int tab) => RefreshIndicator(
        key: Key('canonical-adventures-pull-$tab'),
        onRefresh: _refreshFromServer,
        child: ListView(
            key: PageStorageKey('canonical-adventures-list-$tab'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
            children: [
              for (final progress in view.adventures.eventProgress.where((p) =>
                  view.adventures.activeEvents.any((w) => w.key == p.key) &&
                  p.activeAt(now)))
                EventProgressBar(
                    progress: progress,
                    onClaim: () => _controller.animateTo(3),
                    partnerAction: progress.eventId ==
                            'valentine_two_heartlights'
                        ? EventPartnerControl(
                            eventKey: progress.key,
                            active: widget.active && tab == _tab,
                            firstAutomaticSyncAfter:
                                adventureOfferRefreshRemaining(
                                    AdventureKind.mini, now),
                            beforeSync: () async {
                              for (var attempt = 0;
                                  attempt < 50 && session.busy;
                                  attempt++) {
                                await Future<void>.delayed(
                                    const Duration(milliseconds: 100));
                              }
                              return session.canAct;
                            },
                            applyShared: (_, owner) async {
                              if (session.connection.currentOwner == owner) {
                                await session.synchronize();
                              }
                            })
                        : null),
              if ((tab == 3)) ...[
                for (final progress
                    in view.adventures.eventProgress.where((p) => p.canClaim))
                  EventRewardCard(
                      progress: progress,
                      claim: session.canAct
                          ? () => actions.claimEventReward(progress.key)
                          : null),
                const CanonicalSocialRewards(),
              ],
              if ((tab == 2 || tab == 3) &&
                  !(context.watch<CanonicalGroups?>()?.lobbies.any((l) =>
                          l.isParticipant &&
                          !l.rewardAcknowledged &&
                          l.rewardReadyAt(now) == (tab == 3)) ??
                      false) &&
                  !view.adventures.runs
                      .any((r) => (tab == 3) == !r.endsAt.isAfter(now)) &&
                  (!(tab == 3) ||
                      (!view.adventures.eventProgress.any((p) => p.canClaim) &&
                          (view.data['adventures']['socialClaims'] as List)
                              .isEmpty)))
                Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      GameIconSprite(
                          (tab == 3)
                              ? GameIconKind.chest
                              : GameIconKind.adventureActive,
                          size: 142),
                      Text(
                          (tab == 3)
                              ? s.pick('No completed adventures',
                                  'Geen voltooide avonturen')
                              : s.pick('No adventures are active',
                                  'Er zijn geen actieve avonturen'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                          (tab == 3)
                              ? s.pick(
                                  'Finished journeys wait here until you collect their rewards.',
                                  'Afgeronde reizen wachten hier tot je hun beloningen ophaalt.')
                              : s.pick(
                                  'Send a dragon out and its journey will appear here.',
                                  'Stuur een draak op pad en zijn reis verschijnt hier.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted)),
                    ])),
              if ((tab == 2 || tab == 3) &&
                  view.adventures.runs
                      .any((r) => (tab == 3) == !r.endsAt.isAfter(now))) ...[
                for (final run in view.adventures.orderedRuns
                    .where((r) => (tab == 3) == !r.endsAt.isAfter(now)))
                  _CanonicalRunCard(run: run, now: now),
              ],
              if (tab == 0)
                for (final kind in AdventureKind.values)
                  if (kind == AdventureKind.group) ...[
                    if (context.watch<CanonicalGroups?>() != null)
                      CanonicalGroupsScreen(
                          embedded: true,
                          section: 0,
                          active: widget.active && tab == _tab,
                          refreshRemaining: adventureOfferRefreshRemaining(
                              AdventureKind.group, now)),
                  ] else
                    _AdventureSection(kind: kind, now: now, children: [
                      for (final id in tab != 0
                          ? <String>[]
                          : view.adventures.offers(kind))
                        if (AdventureCatalog.byId[id] case final definition?)
                          _AdventureOffer(
                              definition: definition,
                              onStart: session.canAct
                                  ? () => _chooseDragon(context, definition)
                                  : null,
                              details: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (kind != AdventureKind.special) ...[
                                      CanonicalActionButton(
                                          key: Key('canonical-dismiss-$id'),
                                          label: s.pick('Dismiss', 'Wegsturen'),
                                          outlined: true,
                                          icon: Icons.close_rounded,
                                          confirmation: s.pick(
                                              'Dismiss this adventure?',
                                              'Dit avontuur wegsturen?'),
                                          action: session.canAct
                                              ? () =>
                                                  actions.dismissAdventure(id)
                                              : null),
                                      if (sigils > 0) ...[
                                        const SizedBox(height: 8),
                                        CanonicalActionButton(
                                            key: Key('canonical-wayfinder-$id'),
                                            label: s.relicName(
                                                MysticRelic.wayfinderSigil),
                                            icon: Icons.explore_rounded,
                                            confirmation: s.pick(
                                                'Use one Wayfinder Sigil to replace this adventure?',
                                                'Eén Wayfinder Sigil gebruiken om dit avontuur te vervangen?'),
                                            action: session.canAct
                                                ? () => actions.useWayfinder(
                                                    kind,
                                                    replaceAdventureId: id)
                                                : null),
                                      ],
                                    ],
                                  ]))
                        else
                          Text(s.pick('Update the app to use this item.',
                              'Werk de app bij om dit voorwerp te gebruiken.')),
                      if (tab == 0 && view.adventures.offers(kind).isEmpty)
                        Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 26),
                            child: Text(
                                s.pick('No trail is available here right now.',
                                    'Hier is nu geen route beschikbaar.'),
                                style:
                                    const TextStyle(color: AppColors.muted))),
                      if (tab == 0 &&
                          kind != AdventureKind.special &&
                          sigils > 0 &&
                          view.adventures.offers(kind).length < 3)
                        CanonicalActionButton(
                            key: const Key('canonical-wayfinder-add'),
                            label: s.relicName(MysticRelic.wayfinderSigil),
                            confirmation: s.pick(
                                'Use one Wayfinder Sigil to find an adventure?',
                                'Eén Wayfinder Sigil gebruiken om een avontuur te vinden?'),
                            action: session.canAct
                                ? () => actions.useWayfinder(kind)
                                : null),
                    ]),
              if (context.watch<CanonicalGroups?>() != null && tab >= 2)
                CanonicalGroupsScreen(
                    embedded: true,
                    section: tab,
                    active: widget.active && tab == _tab),
            ]));
    return Column(children: [
      Padding(
          key: const Key('tutorial-adventure-header'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(children: [
            const GameIconSprite(GameIconKind.adventureShort, size: 52),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(s.tr('adventure'),
                      style: Theme.of(context).textTheme.displaySmall),
                  Text(
                      s.pick(
                          'Choose a path. Bring back stories, training and treasure.',
                          'Kies een route. Breng verhalen, training en schatten mee terug.'),
                      style: Theme.of(context).textTheme.bodySmall),
                ])),
          ])),
      TabBar(
          key: const Key('tutorial-adventure-tabs'),
          controller: _controller,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: [
            Tab(
                key: const Key('canonical-tab-available'),
                text: s.pick('Available', 'Beschikbaar')),
            Tab(
                key: const Key('canonical-open-trials'),
                text: s.pick('Trials', 'Proeven')),
            Tab(
                key: const Key('canonical-tab-active'),
                child: _AdventureTabCount(
                    label: s.pick('Active', 'Actief'),
                    count: view.adventures.runs
                            .where((r) => r.endsAt.isAfter(now))
                            .length +
                        groupCount(false))),
            Tab(
                key: const Key('canonical-tab-completed'),
                child: _AdventureTabCount(
                    label: s.pick('Completed', 'Voltooid'),
                    count: view.adventures.runs
                            .where((r) => !r.endsAt.isAfter(now))
                            .length +
                        groupCount(true))),
          ]),
      Expanded(
          child: TabBarView(controller: _controller, children: [
        content(0),
        const CanonicalTrialsScreen(),
        content(2),
        content(3),
      ])),
    ]);
  }
}

String _focusLabel(AppStrings s, TrainingFocus focus) => switch (focus) {
      TrainingFocus.might => s.pick('Might', 'Kracht'),
      TrainingFocus.arcana => 'Arcana',
      TrainingFocus.spirit => s.pick('Spirit', 'Geest'),
    };

Future<void> _chooseDragon(
    BuildContext context, AdventureDefinition definition) async {
  final actions = CanonicalGameActions(context.read<CanonicalGameSession>());
  final id = await pickCanonicalAdventureDragon(context, definition);
  if (id != null && context.mounted) {
    await runShopAction(
        context, () => actions.startAdventure(definition.id, id));
  }
}

Future<String?> pickCanonicalAdventureDragon(
    BuildContext context, AdventureDefinition definition,
    {String keyPrefix = 'canonical-adventure-dragon',
    String expertiseKeyPrefix = 'canonical-expertise-info'}) async {
  final session = context.read<CanonicalGameSession>();
  final owner = session.snapshot!.ownerId;
  final epoch = session.connection.sessionEpoch;
  final focuses =
      definition.combinedExpertise ? TrainingFocus.values : [definition.focus];
  bool highlighted(CanonicalDragonView d) =>
      focuses.every((f) => d.highlighted.contains(f.name));
  final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => CanonicalEntityDialog(
          ownerId: owner,
          builder: (context, view, enabled) {
            final s = AppStrings.of(context);
            final dragons = view.dragons
                .where((d) => d.owned && d.adventureId == null)
                .toList()
              ..sort((a, b) {
                final h = (highlighted(b) ? 1 : 0) - (highlighted(a) ? 1 : 0);
                if (h != 0) return h;
                int score(CanonicalDragonView d) =>
                    focuses.fold(0, (sum, f) => sum + d.trainingFor(f));
                return score(b).compareTo(score(a));
              });
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(
                                              s.pick('Choose a dragon',
                                                  'Kies een draak'),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge),
                                          Text(s.adventureTitle(definition),
                                              style: const TextStyle(
                                                  color: AppColors.muted)),
                                        ])),
                                    DraconomiconShortcut(
                                        onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute<void>(
                                                builder: (_) => CanonicalCodex(
                                                    owner: owner)))),
                                  ]),
                              const SizedBox(height: 10),
                              for (final recommended in [true, false]) ...[
                                if (dragons
                                    .any((d) => highlighted(d) == recommended))
                                  Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(4, 8, 4, 7),
                                      child: Text(
                                          (recommended
                                                  ? s.pick(
                                                      'Highlighted for this path',
                                                      'Gemarkeerd voor deze route')
                                                  : s.pick('Available dragons',
                                                      'Beschikbare draken'))
                                              .toUpperCase(),
                                          style: const TextStyle(
                                              color: AppColors.twilight,
                                              fontSize: 10,
                                              letterSpacing: .7,
                                              fontWeight: FontWeight.w900))),
                                for (final d in dragons.where(
                                    (d) => highlighted(d) == recommended))
                                  Card(
                                      color: recommended
                                          ? const Color(0xFFFFF6D9)
                                          : Colors.white,
                                      child: InkWell(
                                          key: Key('$keyPrefix-${d.id}'),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          onTap: enabled
                                              ? () =>
                                                  Navigator.pop(context, d.id)
                                              : null,
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      8, 8, 12, 8),
                                              child: Row(children: [
                                                CanonicalDragonArt(
                                                    dragon: d, height: 64),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                    child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                      Text(
                                                          canonicalDragonName(
                                                              s, d),
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900)),
                                                      Text(
                                                          '${s.lineageName(dragonLineageById(d.lineageId))} \u00b7 ${s.levelShort(Pet.levelAtXp(d.xp))}',
                                                          style: const TextStyle(
                                                              color: AppColors
                                                                  .muted,
                                                              fontSize: 11)),
                                                      const SizedBox(height: 5),
                                                      Wrap(
                                                          spacing: 8,
                                                          runSpacing: 4,
                                                          crossAxisAlignment:
                                                              WrapCrossAlignment
                                                                  .center,
                                                          children: [
                                                            for (final f
                                                                in focuses)
                                                              ExpertiseScoreBadge(
                                                                  dragonId:
                                                                      d.id,
                                                                  focus: f,
                                                                  focusLabel:
                                                                      _focusLabel(
                                                                          s, f),
                                                                  score: d
                                                                      .trainingFor(
                                                                          f),
                                                                  maximum:
                                                                      d.maximum(
                                                                          f),
                                                                  highlighted: d
                                                                      .highlighted
                                                                      .contains(
                                                                          f.name)),
                                                            IconButton(
                                                                key: Key(
                                                                    '$expertiseKeyPrefix-${d.id}'),
                                                                tooltip: s.pick(
                                                                    'View all Expertise',
                                                                    'Alle Expertises bekijken'),
                                                                onPressed: () =>
                                                                    showCanonicalExpertises(
                                                                        context,
                                                                        d.id,
                                                                        owner),
                                                                icon: const Icon(
                                                                    Icons
                                                                        .info_outline_rounded,
                                                                    size: 19)),
                                                          ]),
                                                    ])),
                                                const Icon(
                                                    Icons.chevron_right_rounded,
                                                    color: AppColors.twilight),
                                              ])))),
                              ],
                            ])));
          }));
  if (id == null ||
      !context.mounted ||
      session.connection.sessionEpoch != epoch ||
      session.snapshot?.ownerId != owner) {
    return null;
  }
  return id;
}

Future<void> showCanonicalExpertises(
        BuildContext context, String id, String owner) =>
    showDialog<void>(
        context: context,
        builder: (context) => CanonicalEntityDialog(
            ownerId: owner,
            builder: (context, view, enabled) {
              final s = AppStrings.of(context);
              final dragon = view.dragon(id);
              return AlertDialog(
                  title: Text(s.pick('Expertise', 'Expertise')),
                  content: dragon == null || !dragon.owned
                      ? const SizedBox.shrink()
                      : SizedBox(
                          width: 320,
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(canonicalDragonName(s, dragon)),
                            DragonExpertiseStatus(
                                dragonId: id,
                                maxed: dragon.expertiseMaxed,
                                spark: dragon.dragonSpark),
                            for (final focus in TrainingFocus.values)
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: ExpertiseScoreBadge(
                                      dragonId: id,
                                      focus: focus,
                                      focusLabel: _focusLabel(s, focus),
                                      score: dragon.training[focus.name]!,
                                      maximum: dragon.maximum(focus),
                                      highlighted: dragon.highlighted
                                          .contains(focus.name),
                                      expand: true,
                                      iconSize: 30)),
                          ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(s.pick('Close', 'Sluiten')))
                  ]);
            }));

class CanonicalCodex extends StatelessWidget {
  const CanonicalCodex({super.key, required this.owner});
  final String owner;
  @override
  Widget build(BuildContext context) {
    final view = context.watch<CanonicalGameSession>().snapshot;
    return Scaffold(
        appBar: AppBar(title: const Text('Draconomicon')),
        body: ShopEconomyBoundary(
            child: view?.ownerId != owner
                ? const SizedBox.shrink()
                : DraconomiconScreen(
                    discoveredForms: view!.shop.discoveredForms,
                    prismaticForms: view.shop.prismaticForms)));
  }
}

class _AdventureOffer extends StatelessWidget {
  const _AdventureOffer(
      {required this.definition, required this.details, this.onStart});
  final AdventureDefinition definition;
  final Widget details;
  final VoidCallback? onStart;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final event = specialAdventureEventForAdventure(definition.id);
    final view = context.watch<CanonicalGameSession>().snapshot!;
    final window = view.adventures.activeEvents
        .where((w) => w.eventId == event?.id)
        .firstOrNull;
    final trialKind = trialKindByName(event?.trialKindName);
    return Card(
        color: Colors.white.withValues(alpha: .96),
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 7),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: () => showRestoredAdventureDetails(context, definition,
                onChooseDragon: onStart,
                extraActions: details,
                specialWindow: window == null || event == null
                    ? null
                    : SpecialAdventureWindow(
                        event: event,
                        key: window.key,
                        startsAt: window.startsAt,
                        endsAt: window.endsAt)),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(children: [
                  if (trialKind != null) ...[
                    Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF3EAFD),
                            border: Border.all(color: const Color(0xFFD9C5F0))),
                        child: TrialIconSprite(kind: trialKind, size: 44)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Expanded(
                              child: Text(s.adventureTitle(definition),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5))),
                          if (definition.sinister)
                            const Icon(Icons.visibility_rounded,
                                size: 16, color: Color(0xFF8A285E)),
                        ]),
                        const SizedBox(height: 5),
                        Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const GameIconSprite(GameIconKind.clock,
                                    size: 19),
                                const SizedBox(width: 3),
                                Text(s.adventureDuration(definition.duration),
                                    style: const TextStyle(fontSize: 11)),
                              ]),
                              AdventureExpertiseTransition(
                                definition: definition,
                                keyPrefix:
                                    'canonical-adventure-${definition.id}-expertise',
                              ),
                            ]),
                      ])),
                  IconButton(
                      key: Key('canonical-select-adventure-${definition.id}'),
                      tooltip: s.pick('Choose dragon', 'Kies een draak'),
                      onPressed: onStart,
                      icon: const GameIconSprite(GameIconKind.adventureStart,
                          size: 36)),
                ]))));
  }
}

class _AdventureSection extends StatelessWidget {
  const _AdventureSection(
      {required this.kind, required this.now, required this.children});
  final AdventureKind kind;
  final DateTime now;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = switch (kind) {
      AdventureKind.mini => const [Color(0xFFFFF4E8), Color(0xFFFFDFC4)],
      AdventureKind.short => const [Color(0xFFFFF8DC), Color(0xFFFFEDB7)],
      AdventureKind.long => const [Color(0xFFE9F2FF), Color(0xFFD9E6FF)],
      _ => const [Color(0xFFF2E9FF), Color(0xFFE5D7FA)],
    };
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 2),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.last.withValues(alpha: .55))),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            GameIconSprite(
                switch (kind) {
                  AdventureKind.mini => GameIconKind.adventureMini,
                  AdventureKind.short => GameIconKind.adventureShort,
                  AdventureKind.long => GameIconKind.adventureLong,
                  _ => GameIconKind.adventureSpecial,
                },
                size: 46),
            const SizedBox(width: 7),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      switch (kind) {
                        AdventureKind.mini => s.pick('Mini', 'Mini'),
                        AdventureKind.short => s.pick('Short', 'Kort'),
                        AdventureKind.long => s.pick('Long', 'Lang'),
                        _ => s.pick('Special', 'Speciaal'),
                      },
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900)),
                  Text(
                      switch (kind) {
                        AdventureKind.mini =>
                          s.pick('Tiny outings', 'Kleine uitstapjes'),
                        AdventureKind.short =>
                          s.pick('Quick routes', 'Snelle routes'),
                        AdventureKind.long =>
                          s.pick('Patient journeys', 'Geduldige reizen'),
                        _ => s.pick('Rare trails', 'Zeldzame routes'),
                      },
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 10)),
                ])),
            if (adventureOfferRefreshRemaining(kind, now)
                case final remaining?) ...[
              const SizedBox(width: 7),
              AdventureRefreshCountdown(kind: kind, remaining: remaining),
            ],
          ]),
          const SizedBox(height: 5),
          ...children,
        ]));
  }
}

GameIconKind _adventureIcon(AdventureKind kind) => switch (kind) {
      AdventureKind.mini => GameIconKind.adventureMini,
      AdventureKind.short => GameIconKind.adventureShort,
      AdventureKind.long => GameIconKind.adventureLong,
      AdventureKind.group => GameIconKind.adventureGroup,
      AdventureKind.special => GameIconKind.adventureSpecial,
    };

class _AdventureTabCount extends StatelessWidget {
  const _AdventureTabCount({required this.label, required this.count});
  final String label;
  final int count;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 5),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.twilight,
                  borderRadius: BorderRadius.circular(99)),
              child: Text('$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900)))
        ],
      ]);
}

class _CanonicalRunCard extends StatelessWidget {
  const _CanonicalRunCard({required this.run, required this.now});
  final CanonicalAdventureRun run;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final session = context.watch<CanonicalGameSession>();
    final actions = CanonicalGameActions(session);
    final definition = run.definition;
    final dragon = session.snapshot!.dragon(run.dragonId);
    final shop = session.snapshot!.shop;
    final musicChestCapacityReached =
        shop.music.length + (shop.chests['music'] ?? 0) >= musicCatalog.length;
    final ready = !run.endsAt.isAfter(now);
    final awaitingConfirmation =
        session.confirmedSnapshot?.adventures.run(run.id) == null;
    final abortable = definition != null &&
        !ready &&
        definition.kind != AdventureKind.group &&
        !definition.requiresOnlinePartner;
    Future<void> claim() => runShopAction(context, () async {
          await EventPointFlight.claim(
              context, () => actions.claimAdventure(run.id));
        });
    Future<void> abort() async {
      final confirmed = await confirmCanonicalAction(
          context,
          s.pick('Abort this adventure without rewards?',
              'Dit avontuur zonder beloning afbreken?'),
          owner: session.snapshot!.ownerId,
          epoch: actions.epoch);
      if (confirmed && context.mounted) {
        await runShopAction(context, () => actions.abortAdventure(run.id));
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('canonical-run-details-${run.id}'),
        onTap: definition == null
            ? null
            : () => showRestoredRunDetails(context,
                definition: definition,
                runId: run.id,
                endsAt: run.endsAt,
                now: now,
                ready: ready,
                retraining: run.retraining,
                musicChestCapacityReached: musicChestCapacityReached,
                dragonName:
                    dragon == null ? null : canonicalDragonName(s, dragon),
                dragonArtwork: dragon == null
                    ? null
                    : SizedBox.square(
                        dimension: 42,
                        child: CanonicalDragonArt(dragon: dragon, height: 42)),
                chestTier: run.revealedReward ?? definition.knownChest,
                onClaim: session.canAct && ready && !awaitingConfirmation
                    ? claim
                    : null,
                onAbort: session.canAct && abortable && !awaitingConfirmation
                    ? abort
                    : null),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 13, 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: adventureKindColors(
                              definition?.kind ?? AdventureKind.short)),
                      borderRadius: BorderRadius.circular(20)),
                  child: GameIconSprite(
                      _adventureIcon(definition?.kind ?? AdventureKind.short),
                      size: 74)),
              const SizedBox(width: 11),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        definition == null
                            ? s.pick('Adventure', 'Avontuur')
                            : s.adventureTitle(definition),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                        dragon == null
                            ? s.pick('Unknown dragon', 'Onbekende draak')
                            : canonicalDragonName(s, dragon),
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 7),
                    Row(children: [
                      const GameIconSprite(GameIconKind.clock, size: 22),
                      const SizedBox(width: 4),
                      Expanded(
                          child: RestoredAdventureCountdown(
                              key: ValueKey(
                                  'adventure-card-countdown-${run.id}'),
                              endsAt: run.endsAt,
                              confirmedNow: now,
                              ready: ready,
                              style: TextStyle(
                                  color: ready
                                      ? const Color(0xFF24735B)
                                      : AppColors.eventColor(
                                          context, AppColors.twilight),
                                  fontWeight: FontWeight.w900))),
                    ]),
                  ])),
              if (ready)
                FilledButton.tonal(
                    key: Key('canonical-claim-${run.id}'),
                    onPressed:
                        session.canAct && !awaitingConfirmation ? claim : null,
                    child: Text(s.pick('Claim', 'Ophalen')))
              else if (abortable)
                IconButton(
                    key: Key('canonical-abort-${run.id}'),
                    tooltip: s.pick('Abort adventure', 'Avontuur afbreken'),
                    onPressed:
                        session.canAct && !awaitingConfirmation ? abort : null,
                    icon: Icon(Icons.cancel_outlined,
                        color:
                            AppColors.eventColor(context, AppColors.twilight)))
              else
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.eventColor(context, AppColors.twilight)),
            ]),
            if (ready && definition != null) ...[
              const SizedBox(height: 10),
              restoredAdventureRewards(
                  definition: definition,
                  retraining: run.retraining,
                  musicChestCapacityReached: musicChestCapacityReached,
                  chestTier: run.revealedReward ?? definition.knownChest),
            ],
          ]),
        ),
      ),
    );
  }
}
