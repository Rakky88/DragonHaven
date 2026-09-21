import 'adventure_hub_screen.dart' show TrialRefreshCountdown, trialStatBenefit;
import '../models/social.dart';
import '../widgets/trial_rankings_sheet.dart';
import '../theme/app_theme.dart';
import '../widgets/game_icon_sprite.dart';
import 'dart:async';
import '../widgets/event_point_flight.dart';
import '../widgets/event_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import '../models/trial.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_game_snapshot.dart';
import '../services/canonical_trial_run_source.dart';
import '../widgets/canonical_game_controls.dart';
import '../widgets/draconomicon_shortcut.dart';
import '../widgets/expertise_score_badge.dart';
import '../widgets/shop_economy_scope.dart';
import '../widgets/trial_icon_sprite.dart';
import 'canonical_adventures_screen.dart';
import 'canonical_dragons_screen.dart';
import 'trial_game_screen.dart';

class CanonicalTrialsScreen extends StatelessWidget {
  const CanonicalTrialsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ShopEconomyBoundary(child: _Trials());
}

class _Trials extends StatefulWidget {
  const _Trials();
  @override
  State<_Trials> createState() => _TrialsState();
}

class _TrialsState extends State<_Trials> {
  DateTime? _anchor;
  final _elapsed = Stopwatch();
  late final Timer _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _elapsed.stop();
    super.dispose();
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
    final active = view.trialAttempt;
    final reserved = view.data['trials']['attempt'] != null;
    return ListView(
        key: const PageStorageKey('trials-scroll'),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
        children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2A1E50), Color(0xFF5B3D91)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold, width: 1.2)),
              child: Column(children: [
                Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const GameIconSprite(GameIconKind.adventureSpecial,
                            size: 34),
                        const SizedBox(width: 8),
                        Flexible(
                            child: Text(
                                s.pick('Dragon Trials', 'Drakenproeven'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900))),
                      ]),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        TrialRefreshCountdown(
                            remaining: DateTime.fromMillisecondsSinceEpoch(
                                    (now.millisecondsSinceEpoch ~/ 900000 + 1) *
                                        900000,
                                    isUtc: true)
                                .difference(now)),
                        IconButton(
                            key: const Key('open-trial-rankings'),
                            tooltip: s.pick('View Trial Rankings',
                                'Bekijk Trial-ranglijsten'),
                            color: AppColors.gold,
                            icon:
                                const Icon(Icons.leaderboard_rounded, size: 22),
                            onPressed: () => showTrialRankingsSheet(context,
                                scopes: const [
                                  TrialRankingScope.world,
                                  TrialRankingScope.friends
                                ],
                                initialScope: TrialRankingScope.world)),
                      ]),
                    ]),
                const Divider(height: 10, color: Color(0x33F6DF9A)),
                _TrialStreakCard(
                    count: view.data['trials']['trialStreakCount'] as int,
                    ready:
                        view.data['trials']['trialStreakRewardReady'] == true,
                    onClaim: session.canAct && !reserved
                        ? () => runShopAction(context, () async {
                              await actions.execute('claim_constellation', {});
                            })
                        : null),
              ])),
          for (final progress in view.adventures.eventProgress.where((p) =>
              p.activeAt(now) &&
              view.adventures.activeEvents.any((w) => w.key == p.key)))
            EventProgressBar(
                key: ValueKey(progress.key),
                progress: progress,
                onClaim: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(
                            body: CanonicalAdventuresScreen())))),
          const SizedBox(height: 8),
          if (active != null)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(s.pick('An unfinished Trial is reserved.',
                              'Er staat een onafgemaakte proef klaar.')),
                          Text(trialDefinitions[active.kind]!
                              .title(s.languageCode)),
                          CanonicalActionButton(
                              key: const Key('resume-reserved-trial'),
                              label: s.pick('Continue', 'Doorgaan'),
                              action: session.canAct
                                  ? () async {
                                      final offer = TrialOffer(
                                          id: active.offerId,
                                          kind: active.kind,
                                          appearedAt: active.startedAt,
                                          specialEventKey:
                                              active.specialEventKey);
                                      final source = CanonicalTrialRunSource(
                                          session, offer, active.dragonId,
                                          resumeAttemptId: active.id);
                                      await _withEventPointReturn(
                                          context,
                                          session,
                                          () => Navigator.of(context).push<
                                                  TrialCompletion>(
                                              MaterialPageRoute<
                                                      TrialCompletion>(
                                                  builder: (_) =>
                                                      TrialGameScreen(
                                                          offerId: offer.id,
                                                          dragonId:
                                                              active.dragonId,
                                                          source: source))));
                                    }
                                  : null),
                          CanonicalActionButton(
                              key: const Key('cancel-reserved-trial'),
                              label: s.pick('Leave Trial', 'Proef verlaten'),
                              confirmation: s.pick(
                                  'Leave this Trial without rewards?',
                                  'Deze proef zonder beloning verlaten?'),
                              action: session.canAct
                                  ? () async {
                                      await actions.execute('cancel_trial',
                                          {'attemptId': active.id});
                                    }
                                  : null),
                        ]))),
          if (view.schoolAttempt != null)
            Text(s.pick('Finish your Academy lesson first.',
                'Rond eerst je academieles af.')),
          for (final offer
              in view.trialOffers.where((o) => o.startedAt == null))
            _TrialOfferCard(
                offer: offer,
                best: view.dragons.where((d) => d.owned).fold<int>(
                    0,
                    (best, d) => d.trialBest(offer.kind.name) > best
                        ? d.trialBest(offer.kind.name)
                        : best),
                onStart: session.canAct && !reserved
                    ? () => _choose(context, offer)
                    : null,
                onDismiss: session.canAct && !reserved
                    ? () async {
                        final confirmed = await confirmCanonicalAction(
                            context,
                            s.pick(
                                'Dismiss this Trial?', 'Deze proef wegsturen?'),
                            owner: view.ownerId,
                            epoch: actions.epoch);
                        if (confirmed && context.mounted) {
                          await runShopAction(context, () async {
                            await actions.execute(
                                'dismiss_trial', {'offerId': offer.id});
                          });
                        }
                      }
                    : null),
          if (view.trialOffers.isEmpty)
            Text(s.pick('New Trials will appear here.',
                'Hier verschijnen nieuwe proeven.')),
        ]);
  }

  Future<void> _choose(BuildContext context, TrialOffer offer) async {
    final session = context.read<CanonicalGameSession>();
    final owner = session.snapshot!.ownerId;
    final epoch = session.connection.sessionEpoch;
    final focuses = offer.definition.isSeasonal
        ? TrainingFocus.values
        : [offer.definition.focus];
    bool highlighted(CanonicalDragonView d) =>
        focuses.every((f) => d.highlighted.contains(f.name));
    final id = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => CanonicalEntityDialog(
            ownerId: owner,
            builder: (context, view, enabled) {
              final s = AppStrings.of(context);
              final dragons = view.dragons
                  .where((d) =>
                      d.owned &&
                      d.stage != DragonStage.egg &&
                      d.adventureId == null)
                  .toList()
                ..sort((a, b) => a.displayName.compareTo(b.displayName));
              return SafeArea(
                child: DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: .72,
                  maxChildSize: .92,
                  builder: (_, controller) => ListView(
                    key: const Key('trial-dragon-picker'),
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(
                                s.pick('Choose your Trial dragon',
                                    'Kies je draak voor de proef'),
                                style: Theme.of(context).textTheme.titleLarge)),
                        const SizedBox(width: 8),
                        DraconomiconShortcut(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                    builder: (_) =>
                                        CanonicalCodex(owner: owner)))),
                      ]),
                      const SizedBox(height: 4),
                      Text(trialStatBenefit(s, offer.kind),
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                      for (final group in [true, false]) ...[
                        if (dragons.any((d) => highlighted(d) == group))
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 7),
                            child: Text(
                                (group
                                        ? s.pick('Highlighted for this path',
                                            'Gemarkeerd voor deze route')
                                        : s.pick('Available dragons',
                                            'Beschikbare draken'))
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: AppColors.twilight,
                                    fontSize: 10,
                                    letterSpacing: .7,
                                    fontWeight: FontWeight.w900)),
                          ),
                        for (final dragon
                            in dragons.where((d) => highlighted(d) == group))
                          Card(
                            color:
                                group ? const Color(0xFFFFFAE9) : Colors.white,
                            child: InkWell(
                              key: Key('trial-dragon-${dragon.id}'),
                              borderRadius: BorderRadius.circular(20),
                              onTap: enabled && view.trialAttempt == null
                                  ? () => Navigator.pop(context, dragon.id)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(children: [
                                  SizedBox.square(
                                      dimension: 58,
                                      child: CanonicalDragonArt(
                                          dragon: dragon, height: 58)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(canonicalDragonName(s, dragon),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w900)),
                                        Wrap(
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              for (final focus in offer
                                                  .definition
                                                  .assistingExpertises)
                                                ExpertiseScoreBadge(
                                                    dragonId: dragon.id,
                                                    focus: focus,
                                                    focusLabel:
                                                        _focusName(s, focus),
                                                    score: dragon
                                                        .trainingFor(focus),
                                                    maximum:
                                                        dragon.maximum(focus),
                                                    highlighted: dragon
                                                        .highlighted
                                                        .contains(focus.name)),
                                              IconButton(
                                                  tooltip: s.pick(
                                                      'View all Expertise',
                                                      'Alle Expertises bekijken'),
                                                  onPressed: () =>
                                                      showCanonicalExpertises(
                                                          context,
                                                          dragon.id,
                                                          owner),
                                                  icon: const Icon(
                                                      Icons
                                                          .info_outline_rounded,
                                                      size: 20)),
                                            ]),
                                        Text(
                                            '${s.pick('Best', 'Beste')}: ${dragon.trialBest(offer.kind.name)}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.muted)),
                                      ])),
                                  const Icon(Icons.chevron_right_rounded,
                                      size: 20),
                                ]),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            }));
    if (id == null ||
        !context.mounted ||
        !session.canAct ||
        session.connection.sessionEpoch != epoch ||
        session.snapshot?.ownerId != owner) {
      return;
    }
    final source = CanonicalTrialRunSource(session, offer, id);
    await _withEventPointReturn(
        context,
        session,
        () => Navigator.push<TrialCompletion>(
            context,
            MaterialPageRoute<TrialCompletion>(
                builder: (_) => TrialGameScreen(
                    offerId: offer.id, dragonId: id, source: source))));
  }
}

Future<void> _withEventPointReturn(
    BuildContext context,
    CanonicalGameSession session,
    Future<TrialCompletion?> Function() play) async {
  final trialNavigator = Navigator.of(context);
  final epoch = session.connection.sessionEpoch;
  final owner = session.snapshot?.ownerId;
  final before = {
    for (final p in session.snapshot!.adventures.eventProgress)
      if (!p.complete && !p.claimed) p.key: p.points
  };
  final completion = await play();
  await Future<void>.delayed(const Duration(milliseconds: 350));
  if (!trialNavigator.mounted ||
      completion == null ||
      session.connection.sessionEpoch != epoch ||
      session.snapshot?.ownerId != owner) {
    return;
  }
  EventPointFlight.returnFromTrial(trialNavigator.context, {
    for (final p in session.snapshot!.adventures.eventProgress)
      if (before.containsKey(p.key)) p.key: p.points - before[p.key]!,
  });
}

class _TrialStreakCard extends StatelessWidget {
  const _TrialStreakCard(
      {required this.count, required this.ready, required this.onClaim});
  final int count;
  final bool ready;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final filled = count.clamp(0, 7);
    return Padding(
      key: const Key('trial-streak-card'),
      padding: const EdgeInsets.fromLTRB(2, 2, 10, 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.pick('7-day constellation', '7-daagse constellatie'),
                  style: const TextStyle(
                      color: Color(0xFFF0E8FA),
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
              Text(
                '$filled/7',
                style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w900),
              ),
              if (ready) ...[
                const SizedBox(width: 7),
                SizedBox(
                  height: 34,
                  child: FilledButton(
                    key: const Key('claim-trial-streak'),
                    onPressed: onClaim,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor:
                          AppColors.eventColor(context, AppColors.twilightDark),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(strings.pick('Claim', 'Claim')),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
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
                      color: AppColors.eventColor(
                          context, const Color(0x55D9BCEB)),
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
                              width: 26,
                              height: 26,
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
}

class _TrialOfferCard extends StatelessWidget {
  const _TrialOfferCard(
      {required this.offer, required this.best, this.onStart, this.onDismiss});
  final int best;
  final VoidCallback? onStart, onDismiss;

  final TrialOffer offer;

  String get _asset => switch (offer.kind) {
        TrialKind.cavernFlight =>
          'assets/images/ui/trials/trial_cavern_flight.webp',
        TrialKind.ruinBreaker =>
          'assets/images/ui/trials/trial_ruin_breaker.webp',
        TrialKind.runeweaver => 'assets/images/ui/trials/trial_runeweaver.webp',
        TrialKind.witchlightWard =>
          'assets/images/events/halloween/trial_background.webp',
        TrialKind.hollyfrostGiftforge =>
          'assets/images/events/christmas/trial_background.webp',
        TrialKind.midnightChime =>
          'assets/images/events/new_year/trial_background.webp',
        TrialKind.rosevowRelay =>
          'assets/images/events/valentine/trial_background.webp',
        TrialKind.sunwakeSurf =>
          'assets/images/events/sunwake/trial_background.webp',
        TrialKind.moonlitOrchard =>
          'assets/images/events/harvestmoon/trial_background.webp',
        TrialKind.wishcakeTower =>
          'assets/images/events/golden_wings/trial_background.webp',
        TrialKind.prismaticParade =>
          'assets/images/events/pride/trial_background.webp',
      };

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final definition = offer.definition;
    return Card(
      key: Key('trial-offer-${offer.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('choose-trial-${offer.id}'),
        onTap: onStart,
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
                          definition.assistingExpertises
                              .map((focus) => _focusName(strings, focus))
                              .join(' · '),
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
                    child: Column(
                      children: [
                        IconButton.filledTonal(
                          key: Key('dismiss-trial-${offer.id}'),
                          tooltip:
                              strings.pick('Dismiss Trial', 'Proef negeren'),
                          onPressed: onDismiss,
                          icon: const Icon(Icons.close_rounded),
                        ),
                        if (definition.specialEventId != null)
                          IconButton.filled(
                              key: Key('seasonal-rankings-${offer.id}'),
                              tooltip: strings.pick(
                                  'Event ranking', 'Eventranglijst'),
                              onPressed: () => showTrialRankingsSheet(context,
                                  scopes: const [
                                    TrialRankingScope.world,
                                    TrialRankingScope.friends
                                  ],
                                  initialScope: TrialRankingScope.world,
                                  initialKind: offer.kind),
                              icon: const Icon(Icons.leaderboard_rounded)),
                      ],
                    ),
                  ),
                  if (offer.specialEventKey?.contains(':preview:') == true)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        key: Key('trial-test-label-${offer.id}'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD86E),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'TEST EVENT',
                          style: TextStyle(
                            color: Color(0xFF3B245A),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
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
                          style: TextStyle(
                            color: AppColors.eventColor(
                                context, AppColors.twilight),
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
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.eventColor(context, AppColors.twilight),
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

String _focusName(AppStrings strings, TrainingFocus focus) => switch (focus) {
      TrainingFocus.might => strings.pick('Might', 'Kracht'),
      TrainingFocus.arcana => strings.pick('Arcana', 'Arcana'),
      TrainingFocus.spirit => strings.pick('Spirit', 'Geest'),
    };
