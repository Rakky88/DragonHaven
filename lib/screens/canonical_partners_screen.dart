import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/pet.dart';
import '../models/social.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_partners.dart';
import '../widgets/canonical_game_controls.dart';
import '../widgets/canonical_social_rewards.dart';
import '../widgets/draconomicon_shortcut.dart';
import '../widgets/expertise_score_badge.dart';
import '../widgets/shop_economy_scope.dart';
import 'canonical_adventures_screen.dart'
    show CanonicalCodex, showCanonicalExpertises;
import 'canonical_dragons_screen.dart';

class CanonicalPartnersScreen extends StatelessWidget {
  const CanonicalPartnersScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ShopEconomyBoundary(child: _Partners());
}

class _Partners extends StatefulWidget {
  const _Partners();
  @override
  State<_Partners> createState() => _PartnersState();
}

class _PartnersState extends State<_Partners> {
  final _code = TextEditingController();
  Timer? _poll;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh());
    });
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          context.read<CanonicalGameSession>().canAct) {
        unawaited(_refresh());
      }
    });
  }

  Future<void> _refresh() async {
    final partners = context.read<CanonicalPartners>();
    if (partners.loading) return;
    await partners.refresh();
    if (!mounted) return;
    final session = context.read<CanonicalGameSession>();
    if (!session.busy && session.connection.currentOwner != null) {
      try {
        await session.synchronize();
      } on Object {/* Session displays recovery state. */}
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partners = context.watch<CanonicalPartners>();
    final session = context.watch<CanonicalGameSession>();
    final s = AppStrings.of(context);
    final actions = CanonicalGameActions(session);
    final enabled =
        session.canAct && !partners.loading && partners.error == null;
    final definition = AdventureCatalog.valentineTwoHeartlights;
    final pairs = partners.pairs.toList()
      ..sort((a, b) {
        if (a.isIncomingInvite != b.isIncomingInvite) {
          return a.isIncomingInvite ? -1 : 1;
        }
        return (a.endsAt ?? DateTime.utc(9999))
            .compareTo(b.endsAt ?? DateTime.utc(9999));
      });
    return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
            key: const Key('canonical-partners-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(
                    child: Text(s.adventureTitle(definition),
                        style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                    key: const Key('canonical-refresh-partners'),
                    tooltip: s.pick('Refresh', 'Vernieuwen'),
                    onPressed: partners.loading ? null : _refresh,
                    icon: const Icon(Icons.refresh))
              ]),
              if (partners.loading) const LinearProgressIndicator(),
              if (partners.error case final error?)
                Text(gameConnectionMessage(s, error)),
              if (partners.canInvite)
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(s.adventureDescription(definition)),
                              const SizedBox(height: 12),
                              TextField(
                                  key: const Key('canonical-partner-code'),
                                  controller: _code,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  autocorrect: false,
                                  maxLength: 11,
                                  decoration: InputDecoration(
                                      labelText:
                                          s.pick('Keeper ID', 'Keeper-ID'),
                                      hintText: 'DH-1234ABCD',
                                      counterText: ''),
                                  onChanged: (_) => setState(() {})),
                              OutlinedButton(
                                  key: const Key('canonical-invite-partner'),
                                  onPressed: enabled &&
                                          RegExp(r'^DH-[0-9A-F]{8}$').hasMatch(
                                              _code.text.trim().toUpperCase())
                                      ? () => _choose(null)
                                      : null,
                                  child: Text(s.pick(
                                      'Choose dragon', 'Kies een draak'))),
                            ]))),
              const CanonicalSocialRewards(),
              for (final pair in pairs)
                Card(
                    key: Key('canonical-partner-${pair.id}'),
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                  pair.isCreator
                                      ? pair.partner.displayName
                                      : pair.creator.displayName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text(switch (pair.status) {
                                SeasonalPairAdventureStatus.invited =>
                                  pair.isCreator
                                      ? s.pick('Waiting for acceptance',
                                          'Wachten op acceptatie')
                                      : s.pick('Invites you', 'Nodigt je uit'),
                                SeasonalPairAdventureStatus.accepted => s.pick(
                                    'Waiting for the creator',
                                    'Wachten op de maker'),
                                SeasonalPairAdventureStatus.running => pair
                                            .endsAt
                                            ?.isAfter(
                                                session.snapshot!.serverTime) ==
                                        true
                                    ? s.remainingDuration(pair.endsAt!
                                        .difference(
                                            session.snapshot!.serverTime))
                                    : s.pick('Ready to claim',
                                        'Klaar om op te halen'),
                                _ => s.pick('Completed', 'Voltooid'),
                              }),
                              if (pair.myDragonId.isNotEmpty)
                                if (session.snapshot!.dragon(pair.myDragonId)
                                    case final dragon?)
                                  Text(canonicalDragonName(s, dragon)),
                              if (pair.isIncomingInvite)
                                Wrap(spacing: 8, children: [
                                  OutlinedButton(
                                      key: Key(
                                          'canonical-accept-partner-${pair.id}'),
                                      onPressed: enabled
                                          ? () => _choose(pair.id)
                                          : null,
                                      child:
                                          Text(s.pick('Accept', 'Accepteren'))),
                                  CanonicalActionButton(
                                      key: Key(
                                          'canonical-decline-partner-${pair.id}'),
                                      label: s.pick('Decline', 'Afwijzen'),
                                      action: enabled
                                          ? () async {
                                              await actions
                                                  .declinePairAdventure(
                                                      pair.id);
                                              await _refresh();
                                            }
                                          : null),
                                ]),
                              if (pair.isCreator &&
                                  pair.status ==
                                      SeasonalPairAdventureStatus.accepted)
                                CanonicalActionButton(
                                    key: Key(
                                        'canonical-start-partner-${pair.id}'),
                                    label: s.pick('Start', 'Starten'),
                                    action: enabled
                                        ? () async {
                                            await actions
                                                .startPairAdventure(pair.id);
                                            await _refresh();
                                          }
                                        : null),
                              if ((pair.isCreator &&
                                      pair.status ==
                                          SeasonalPairAdventureStatus
                                              .invited) ||
                                  pair.status ==
                                      SeasonalPairAdventureStatus.accepted)
                                CanonicalActionButton(
                                    key: Key(
                                        'canonical-cancel-partner-${pair.id}'),
                                    label: s.pick('Cancel', 'Annuleren'),
                                    confirmation: s.pick(
                                        'Cancel this invitation before departure?',
                                        'Deze uitnodiging voor vertrek annuleren?'),
                                    action: enabled
                                        ? () async {
                                            await actions
                                                .cancelPairAdventure(pair.id);
                                            await _refresh();
                                          }
                                        : null),
                            ]))),
            ]));
  }

  Future<void> _choose(String? source) async {
    final owner = context.read<CanonicalGameSession>().snapshot!.ownerId;
    final keeperCode = _code.text.trim().toUpperCase();
    String? selected;
    await showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => CanonicalEntityDialog(
                ownerId: owner,
                builder: (context, view, enabled) {
                  final s = AppStrings.of(context);
                  final definition = AdventureCatalog.valentineTwoHeartlights;
                  final dragons = view.dragons.where((d) => d.owned).toList()
                    ..sort((a, b) {
                      final highlighted = (TrainingFocus.values
                                  .every((f) => b.highlighted.contains(f.name))
                              ? 1
                              : 0) -
                          (TrainingFocus.values
                                  .every((f) => a.highlighted.contains(f.name))
                              ? 1
                              : 0);
                      return highlighted != 0
                          ? highlighted
                          : b.training.values
                              .fold(0, (a, b) => a + b)
                              .compareTo(
                                  a.training.values.fold(0, (a, b) => a + b));
                    });
                  final choice = view.dragon(selected ?? '');
                  return AlertDialog(
                    insetPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    title: Row(children: [
                      Expanded(child: Text(s.adventureTitle(definition))),
                      DraconomiconShortcut(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) =>
                                      CanonicalCodex(owner: owner))))
                    ]),
                    content: SizedBox(
                        width: 380,
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              for (final dragon in dragons)
                                Card(
                                    color: selected == dragon.id
                                        ? Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer
                                        : null,
                                    child: InkWell(
                                        key: Key(
                                            'canonical-partner-dragon-${dragon.id}'),
                                        onTap: enabled &&
                                                dragon.adventureId == null
                                            ? () => update(
                                                () => selected = dragon.id)
                                            : null,
                                        child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(children: [
                                              Row(children: [
                                                CanonicalDragonArt(
                                                    dragon: dragon, height: 52),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                    child: Text(
                                                        canonicalDragonName(
                                                            s, dragon))),
                                                IconButton(
                                                    key: Key(
                                                        'canonical-partner-expertise-${dragon.id}'),
                                                    tooltip: s.pick(
                                                        'View all Expertise',
                                                        'Alle Expertises bekijken'),
                                                    onPressed: () =>
                                                        showCanonicalExpertises(
                                                            context,
                                                            dragon.id,
                                                            owner),
                                                    icon: const Icon(
                                                        Icons.info_outline,
                                                        size: 20))
                                              ]),
                                              for (final focus
                                                  in TrainingFocus.values)
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 4),
                                                    child: ExpertiseScoreBadge(
                                                        dragonId: dragon.id,
                                                        focus: focus,
                                                        focusLabel: switch (
                                                            focus) {
                                                          TrainingFocus.might =>
                                                            s.pick('Might',
                                                                'Kracht'),
                                                          TrainingFocus
                                                                .arcana =>
                                                            'Arcana',
                                                          TrainingFocus
                                                                .spirit =>
                                                            s.pick('Spirit',
                                                                'Geest')
                                                        },
                                                        score: dragon.training[
                                                            focus.name]!,
                                                        maximum: dragon
                                                            .maximum(focus),
                                                        highlighted: dragon
                                                            .highlighted
                                                            .contains(
                                                                focus.name),
                                                        expand: true)),
                                              if (dragon.adventureId != null)
                                                Text(s.pick('On adventure',
                                                    'Op avontuur')),
                                            ])))),
                            ]))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(s.pick('Cancel', 'Annuleren'))),
                      CanonicalActionButton(
                          key: const Key('canonical-confirm-partner'),
                          label: source == null
                              ? s.pick('Invite', 'Uitnodigen')
                              : s.pick('Accept', 'Accepteren'),
                          action: enabled &&
                                  choice?.owned == true &&
                                  choice!.adventureId == null
                              ? () async {
                                  final actions = CanonicalGameActions(
                                      context.read<CanonicalGameSession>());
                                  if (source == null) {
                                    await actions.invitePairAdventure(
                                        keeperCode, choice.id);
                                  } else {
                                    await actions.acceptPairAdventure(
                                        source, choice.id);
                                  }
                                  if (context.mounted) Navigator.pop(context);
                                }
                              : null)
                    ],
                  );
                })));
    if (mounted) await _refresh();
  }
}
