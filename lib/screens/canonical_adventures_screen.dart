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
import '../widgets/canonical_game_controls.dart';
import '../widgets/draconomicon_shortcut.dart';
import '../widgets/expertise_score_badge.dart';
import '../widgets/shop_economy_scope.dart';
import 'canonical_dragons_screen.dart';
import 'draconomicon_screen.dart';

class CanonicalAdventuresScreen extends StatelessWidget {
  const CanonicalAdventuresScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ShopEconomyBoundary(child: _Adventures());
}

class _Adventures extends StatefulWidget {
  const _Adventures();
  @override
  State<_Adventures> createState() => _AdventuresState();
}

class _AdventuresState extends State<_Adventures> {
  AdventureKind _kind = AdventureKind.mini;
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
    final sigils = view.inventory.usableRelics[MysticRelic.wayfinderSigil] ?? 0;
    return ListView(
        key: const Key('canonical-adventures-list'),
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(
                child: Text(s.pick('Adventures', 'Avonturen'),
                    style: Theme.of(context).textTheme.titleLarge)),
            CanonicalActionButton(
                key: const Key('canonical-refresh-adventures'),
                label: s.pick('Refresh', 'Vernieuwen'),
                action: session.canAct ? actions.refresh : null),
          ]),
          OutlinedButton.icon(
              key: const Key('canonical-open-trials'),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                          appBar: AppBar(
                              title: Text(
                                  s.pick('Dragon Trials', 'Drakenproeven'))),
                          body: const CanonicalTrialsScreen()))),
              icon: const Icon(Icons.auto_awesome),
              label: Text(s.pick('Dragon Trials', 'Drakenproeven'))),
          if (view.adventures.runs.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(s.pick('Active Adventures', 'Actieve avonturen'),
                style: Theme.of(context).textTheme.titleMedium),
            for (final run in view.adventures.orderedRuns)
              Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                                run.definition == null
                                    ? s.pick('Adventure', 'Avontuur')
                                    : s.adventureTitle(run.definition!),
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(canonicalDragonName(
                                s, view.dragon(run.dragonId)!)),
                            Text(run.endsAt.isAfter(now)
                                ? s.remainingDuration(
                                    run.endsAt.difference(now))
                                : s.pick(
                                    'Ready to claim', 'Klaar om op te halen')),
                            if (run.endsAt.isAfter(now))
                              CanonicalActionButton(
                                  key: Key('canonical-abort-${run.id}'),
                                  label: s.pick(
                                      'Abort adventure', 'Avontuur afbreken'),
                                  confirmation: s.pick(
                                      'Abort this adventure without rewards?',
                                      'Dit avontuur zonder beloning afbreken?'),
                                  action: session.canAct &&
                                          run.definition != null &&
                                          run.definition!.kind !=
                                              AdventureKind.group &&
                                          !run.definition!.requiresOnlinePartner
                                      ? () => actions.abortAdventure(run.id)
                                      : null)
                            else
                              CanonicalActionButton(
                                  key: Key('canonical-claim-${run.id}'),
                                  label: s.pick('Claim', 'Ophalen'),
                                  action: session.canAct
                                      ? () async {
                                          await actions.claimAdventure(run.id);
                                        }
                                      : null),
                          ]))),
          ],
          const SizedBox(height: 20),
          Wrap(spacing: 8, children: [
            for (final kind in [
              AdventureKind.mini,
              AdventureKind.short,
              AdventureKind.long
            ])
              ChoiceChip(
                  label: Text(switch (kind) {
                    AdventureKind.mini => s.pick('Mini', 'Mini'),
                    AdventureKind.short => s.pick('Short', 'Kort'),
                    _ => s.pick('Long', 'Lang'),
                  }),
                  selected: _kind == kind,
                  onSelected: (_) => setState(() => _kind = kind)),
          ]),
          const SizedBox(height: 8),
          for (final id in view.adventures.offers(_kind))
            if (AdventureCatalog.byId[id] case final definition?)
              Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(s.adventureTitle(definition),
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(s.adventureDescription(definition)),
                            const SizedBox(height: 8),
                            Text(
                                '${s.adventureDuration(definition.duration)} · ${definition.xp} XP'),
                            OutlinedButton(
                                key: Key('canonical-select-adventure-$id'),
                                onPressed: session.canAct
                                    ? () => _chooseDragon(context, definition)
                                    : null,
                                child: Text(
                                    s.pick('Choose dragon', 'Kies een draak'))),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              CanonicalActionButton(
                                  key: Key('canonical-dismiss-$id'),
                                  label: s.pick('Dismiss', 'Wegsturen'),
                                  confirmation: s.pick(
                                      'Dismiss this adventure?',
                                      'Dit avontuur wegsturen?'),
                                  action: session.canAct
                                      ? () => actions.dismissAdventure(id)
                                      : null),
                              if (sigils > 0)
                                CanonicalActionButton(
                                    key: Key('canonical-wayfinder-$id'),
                                    label:
                                        s.relicName(MysticRelic.wayfinderSigil),
                                    confirmation: s.pick(
                                        'Use one Wayfinder Sigil to replace this adventure?',
                                        'Eén Wayfinder Sigil gebruiken om dit avontuur te vervangen?'),
                                    action: session.canAct
                                        ? () => actions.useWayfinder(_kind,
                                            replaceAdventureId: id)
                                        : null),
                            ]),
                          ])))
            else
              Text(s.pick('Update the app to use this item.',
                  'Werk de app bij om dit voorwerp te gebruiken.')),
          if (view.adventures.offers(_kind).isEmpty)
            Text(s.pick('Refresh to check for adventures.',
                'Vernieuw om avonturen te controleren.')),
          if (sigils > 0 && view.adventures.offers(_kind).length < 3)
            CanonicalActionButton(
                key: const Key('canonical-wayfinder-add'),
                label: s.relicName(MysticRelic.wayfinderSigil),
                confirmation: s.pick(
                    'Use one Wayfinder Sigil to find an adventure?',
                    'Eén Wayfinder Sigil gebruiken om een avontuur te vinden?'),
                action:
                    session.canAct ? () => actions.useWayfinder(_kind) : null),
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
  final owner = context.read<CanonicalGameSession>().snapshot!.ownerId;
  String? selected;
  await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, update) => CanonicalEntityDialog(
              ownerId: owner,
              builder: (context, view, enabled) {
                final s = AppStrings.of(context);
                final actions =
                    CanonicalGameActions(context.read<CanonicalGameSession>());
                final dragons = view.dragons.where((d) => d.owned).toList()
                  ..sort((a, b) {
                    final highlight = (b.highlighted
                                .contains(definition.focus.name)
                            ? 1
                            : 0) -
                        (a.highlighted.contains(definition.focus.name) ? 1 : 0);
                    return highlight == 0 ? a.id.compareTo(b.id) : highlight;
                  });
                final choice = view.dragon(selected ?? '');
                final available = view.adventures
                    .offers(definition.kind)
                    .contains(definition.id);
                return AlertDialog(
                    insetPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    titlePadding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
                    contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    title: Row(children: [
                      Expanded(
                          child: Text(s.adventureTitle(definition),
                              style: Theme.of(context).textTheme.titleLarge)),
                      DraconomiconShortcut(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) =>
                                      CanonicalCodex(owner: owner)))),
                    ]),
                    content: SizedBox(
                        width: 380,
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              if (dragons.any((d) => d.highlighted
                                  .contains(definition.focus.name)))
                                Text(s.pick('Highlighted for this path',
                                    'Gemarkeerd voor dit pad')),
                              for (final dragon in dragons)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Semantics(
                                        selected: selected == dragon.id,
                                        child: InkWell(
                                            key: Key(
                                                'canonical-adventure-dragon-${dragon.id}'),
                                            onTap: enabled &&
                                                    dragon.adventureId == null
                                                ? () => update(
                                                    () => selected = dragon.id)
                                                : null,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      Row(children: [
                                                        CanonicalDragonArt(
                                                            dragon: dragon,
                                                            height: 48),
                                                        const SizedBox(
                                                            width: 8),
                                                        Expanded(
                                                            child: Text(
                                                                canonicalDragonName(
                                                                    s,
                                                                    dragon))),
                                                        if (selected ==
                                                            dragon.id)
                                                          const Icon(
                                                              Icons
                                                                  .check_circle,
                                                              size: 22),
                                                      ]),
                                                      Row(children: [
                                                        Expanded(
                                                            child: ExpertiseScoreBadge(
                                                                dragonId:
                                                                    dragon.id,
                                                                focus: definition
                                                                    .focus,
                                                                focusLabel:
                                                                    _focusLabel(
                                                                        s,
                                                                        definition
                                                                            .focus),
                                                                score: dragon
                                                                        .training[
                                                                    definition
                                                                        .focus
                                                                        .name]!,
                                                                maximum: dragon.maximum(
                                                                    definition
                                                                        .focus),
                                                                highlighted: dragon
                                                                    .highlighted
                                                                    .contains(definition
                                                                        .focus
                                                                        .name),
                                                                expand: true)),
                                                        IconButton(
                                                            key: Key(
                                                                'canonical-expertise-info-${dragon.id}'),
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
                                                                size: 19)),
                                                      ]),
                                                      Text(dragon.adventureId != null
                                                          ? s.pick(
                                                              'On adventure',
                                                              'Op avontuur')
                                                          : s.adventureDuration(
                                                              expertiseAdjustedAdventureDurationFromScores(
                                                                  definition,
                                                                  [
                                                                    dragon.training[
                                                                        definition
                                                                            .focus
                                                                            .name]!
                                                                  ],
                                                                  combinedExpertise: dragon
                                                                      .training
                                                                      .values
                                                                      .fold(0, (a, b) => a + b)))),
                                                    ]))))),
                            ]))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(s.pick('Cancel', 'Annuleren'))),
                      CanonicalActionButton(
                          key: const Key('canonical-start-adventure'),
                          label: s.pick('Start', 'Starten'),
                          action: enabled &&
                                  available &&
                                  choice?.owned == true &&
                                  choice!.adventureId == null
                              ? () async {
                                  await actions.startAdventure(
                                      definition.id, choice.id);
                                  if (context.mounted) Navigator.pop(context);
                                }
                              : null),
                    ]);
              })));
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
