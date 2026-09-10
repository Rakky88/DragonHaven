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

class _Trials extends StatelessWidget {
  const _Trials();
  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final view = session.snapshot!;
    final s = AppStrings.of(context);
    final actions = CanonicalGameActions(session);
    final active = view.trialAttempt;
    final reserved = view.data['trials']['attempt'] != null;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(
            child: Text(s.pick('Dragon Trials', 'Drakenproeven'),
                style: Theme.of(context).textTheme.titleLarge)),
        CanonicalActionButton(
            label: s.pick('Refresh', 'Vernieuwen'),
            action: session.canAct && !reserved ? actions.refresh : null)
      ]),
      const SizedBox(height: 8),
      Text(
          '${s.pick('7-day constellation', '7-daagse constellatie')} · ${view.data['trials']['trialStreakCount']}/7'),
      if (view.data['trials']['trialStreakRewardReady'] == true)
        CanonicalActionButton(
            label: s.pick('Claim chest', 'Kist ophalen'),
            action: session.canAct && !reserved
                ? () async {
                    await actions.execute('claim_constellation', {});
                  }
                : null),
      if (active != null)
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(s.pick('An unfinished Trial is reserved.',
                          'Er staat een onafgemaakte proef klaar.')),
                      Text(
                          trialDefinitions[active.kind]!.title(s.languageCode)),
                      CanonicalActionButton(
                          key: const Key('resume-reserved-trial'),
                          label: s.pick('Continue', 'Doorgaan'),
                          action: session.canAct
                              ? () async {
                                  final offer = TrialOffer(
                                      id: active.offerId,
                                      kind: active.kind,
                                      appearedAt: active.startedAt,
                                      specialEventKey: active.specialEventKey);
                                  final source = CanonicalTrialRunSource(
                                      session, offer, active.dragonId,
                                      resumeAttemptId: active.id);
                                  await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                          builder: (_) => TrialGameScreen(
                                              offerId: offer.id,
                                              dragonId: active.dragonId,
                                              source: source)));
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
                                  await actions.execute(
                                      'cancel_trial', {'attemptId': active.id});
                                }
                              : null),
                    ]))),
      if (view.schoolAttempt != null)
        Text(s.pick('Finish your Academy lesson first.',
            'Rond eerst je academieles af.')),
      for (final offer in view.trialOffers.where((o) => o.startedAt == null))
        Card(
            margin: const EdgeInsets.only(top: 12),
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        TrialIconSprite(kind: offer.kind, size: 42),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(offer.definition.title(s.languageCode),
                                style: Theme.of(context).textTheme.titleMedium))
                      ]),
                      const SizedBox(height: 8),
                      FilledButton(
                          key: Key('choose-trial-${offer.id}'),
                          onPressed: session.canAct && !reserved
                              ? () => _choose(context, offer)
                              : null,
                          child: Text(
                              s.pick('Choose a dragon', 'Kies een draak'))),
                      CanonicalActionButton(
                          label: s.pick('Dismiss', 'Wegsturen'),
                          confirmation: s.pick(
                              'Dismiss this Trial?', 'Deze proef wegsturen?'),
                          action: session.canAct && !reserved
                              ? () async {
                                  await actions.execute(
                                      'dismiss_trial', {'offerId': offer.id});
                                }
                              : null),
                    ]))),
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
        useSafeArea: true,
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
              return FractionallySizedBox(
                  heightFactor: .88,
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Row(children: [
                          Expanded(
                              child: Text(
                                  offer.definition.title(s.languageCode),
                                  style:
                                      Theme.of(context).textTheme.titleLarge)),
                          DraconomiconShortcut(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                      builder: (_) =>
                                          CanonicalCodex(owner: owner))))
                        ]),
                        const SizedBox(height: 12),
                        Expanded(
                            child: ListView(children: [
                          for (final group in [true, false]) ...[
                            if (dragons.any((d) => highlighted(d) == group))
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                      group
                                          ? s.pick('Highlighted for this path',
                                              'Gemarkeerd voor dit pad')
                                          : s.pick('Available dragons',
                                              'Beschikbare draken'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge)),
                            for (final dragon in dragons
                                .where((d) => highlighted(d) == group))
                              Card(
                                  child: InkWell(
                                      key: Key('trial-dragon-${dragon.id}'),
                                      onTap: enabled &&
                                              view.data['trials']['attempt'] ==
                                                  null
                                          ? () =>
                                              Navigator.pop(context, dragon.id)
                                          : null,
                                      child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(children: [
                                            CanonicalDragonArt(
                                                dragon: dragon, height: 64),
                                            const SizedBox(width: 10),
                                            Expanded(
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                  Text(
                                                      canonicalDragonName(
                                                          s, dragon),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium),
                                                  const SizedBox(height: 6),
                                                  Wrap(
                                                      spacing: 10,
                                                      runSpacing: 8,
                                                      children: [
                                                        for (final focus
                                                            in focuses)
                                                          ExpertiseScoreBadge(
                                                              dragonId:
                                                                  dragon.id,
                                                              focus: focus,
                                                              focusLabel: focus
                                                                          .name ==
                                                                      'might'
                                                                  ? s.pick(
                                                                      'Might',
                                                                      'Kracht')
                                                                  : focus.name ==
                                                                          'spirit'
                                                                      ? s.pick(
                                                                          'Spirit',
                                                                          'Geest')
                                                                      : 'Arcana',
                                                              score: dragon
                                                                  .trainingFor(
                                                                      focus),
                                                              maximum: dragon
                                                                  .maximum(
                                                                      focus),
                                                              highlighted: dragon
                                                                  .highlighted
                                                                  .contains(
                                                                      focus.name))
                                                      ]),
                                                ])),
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
                                                    Icons.info_outline_rounded,
                                                    size: 20)),
                                          ])))),
                          ],
                        ])),
                      ])));
            }));
    if (id == null ||
        !context.mounted ||
        !session.canAct ||
        session.connection.sessionEpoch != epoch ||
        session.snapshot?.ownerId != owner) {
      return;
    }
    final source = CanonicalTrialRunSource(session, offer, id);
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => TrialGameScreen(
                offerId: offer.id, dragonId: id, source: source)));
  }
}
