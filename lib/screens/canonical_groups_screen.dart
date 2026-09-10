import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_groups.dart';
import '../widgets/canonical_game_controls.dart';
import '../widgets/canonical_social_rewards.dart';
import '../widgets/draconomicon_shortcut.dart';
import '../widgets/expertise_score_badge.dart';
import '../widgets/shop_economy_scope.dart';
import 'canonical_dragons_screen.dart';
import 'canonical_adventures_screen.dart'
    show CanonicalCodex, showCanonicalExpertises;

class CanonicalGroupsScreen extends StatelessWidget {
  const CanonicalGroupsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ShopEconomyBoundary(child: _Groups());
}

class _Groups extends StatefulWidget {
  const _Groups();
  @override
  State<_Groups> createState() => _GroupsState();
}

class _GroupsState extends State<_Groups> {
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
    final groups = context.read<CanonicalGroups>();
    if (groups.loading) return;
    await groups.refresh();
    if (!mounted) return;
    final session = context.read<CanonicalGameSession>();
    // Membership can change on another keeper's device. A new canonical read
    // releases removed members' dragons without importing a social snapshot.
    if (!session.busy && session.fresh) {
      try {
        await session.synchronize();
      } on Object {/* Session owns status. */}
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<CanonicalGroups>();
    final session = context.watch<CanonicalGameSession>();
    final s = AppStrings.of(context);
    final actions = CanonicalGameActions(session);
    final offer = groups.status;
    final definition = AdventureCatalog.byId[offer?.adventureId];
    final enabled = session.canAct && !groups.loading && groups.error == null;
    final currentMember =
        groups.lobbies.any((l) => l.isCurrentOffer && l.isParticipant);
    final lobbies = groups.lobbies.toList()
      ..sort((a, b) {
        if (a.isParticipant != b.isParticipant) return a.isParticipant ? -1 : 1;
        if (a.isWaiting != b.isWaiting) return a.isWaiting ? -1 : 1;
        return (a.endsAt ?? DateTime.utc(9999))
            .compareTo(b.endsAt ?? DateTime.utc(9999));
      });
    return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
            key: const Key('canonical-groups-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(
                    child: Text(s.pick('Group Adventures', 'Groepsavonturen'),
                        style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                    key: const Key('canonical-refresh-groups'),
                    tooltip: s.pick('Refresh', 'Vernieuwen'),
                    onPressed: groups.loading ? null : _refresh,
                    icon: const Icon(Icons.refresh)),
              ]),
              if (groups.loading) const LinearProgressIndicator(),
              if (groups.error case final error?)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(gameConnectionMessage(s, error))),
              if (offer != null &&
                  definition != null &&
                  !offer.alreadyCompleted &&
                  !currentMember)
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(s.adventureTitle(definition),
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text(s.adventureDescription(definition)),
                              const SizedBox(height: 6),
                              Text(
                                  '${definition.xp} XP · ${s.adventureDuration(definition.duration)}'),
                              OutlinedButton(
                                  key: const Key('canonical-create-group'),
                                  onPressed: enabled
                                      ? () => _choose(context, definition, null)
                                      : null,
                                  child: Text(s.pick(
                                      'Choose dragon', 'Kies een draak'))),
                            ])))
              else if (offer != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(s.pick('No trail is available here right now',
                        'Er is hier nu geen pad beschikbaar'))),
              const CanonicalSocialRewards(),
              for (final lobby in lobbies)
                Card(
                    key: Key('canonical-group-${lobby.id}'),
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                  AdventureCatalog.byId
                                          .containsKey(lobby.adventureId)
                                      ? s.adventureTitle(AdventureCatalog
                                          .byId[lobby.adventureId]!)
                                      : s.pick(
                                          'Group Adventure', 'Groepsavontuur'),
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text(lobby.isWaiting
                                  ? '${lobby.participants.length}/${lobby.requiredPlayers} · ${s.pick('Waiting for friends', 'Wachten op vrienden')}'
                                  : lobby.rewardReadyAt(
                                          session.snapshot!.serverTime)
                                      ? s.pick('Ready to claim',
                                          'Klaar om op te halen')
                                      : s.remainingDuration(lobby.endsAt!
                                          .difference(
                                              session.snapshot!.serverTime))),
                              for (final member in lobby.participants)
                                Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Row(children: [
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(member.keeper.displayName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall),
                                            Text(
                                                '${member.dragonName} · Lv. ${member.level}'),
                                          ])),
                                      if (lobby.isWaiting &&
                                          lobby.isOwner &&
                                          !member.isOwner)
                                        CanonicalActionButton(
                                            key: Key(
                                                'canonical-remove-group-${member.keeper.userId}'),
                                            label:
                                                s.pick('Remove', 'Verwijderen'),
                                            confirmation: s.pick(
                                                'Remove this friend from the lobby?',
                                                'Deze vriend uit de lobby verwijderen?'),
                                            action: enabled
                                                ? () async {
                                                    await actions
                                                        .removeGroupAdventureMember(
                                                            lobby.id,
                                                            member
                                                                .keeper.userId);
                                                    await _refresh();
                                                  }
                                                : null),
                                    ])),
                              if (lobby.isWaiting && lobby.isParticipant)
                                CanonicalActionButton(
                                    key: Key(
                                        'canonical-leave-group-${lobby.id}'),
                                    label:
                                        s.pick('Leave lobby', 'Lobby verlaten'),
                                    confirmation: lobby.isOwner
                                        ? s.pick(
                                            'Close this lobby for everyone?',
                                            'Deze lobby voor iedereen sluiten?')
                                        : s.pick('Leave this lobby?',
                                            'Deze lobby verlaten?'),
                                    action: enabled
                                        ? () async {
                                            await actions
                                                .leaveGroupAdventure(lobby.id);
                                            await _refresh();
                                          }
                                        : null),
                              if (lobby.isWaiting &&
                                  !lobby.isParticipant &&
                                  lobby.isCurrentOffer &&
                                  !currentMember &&
                                  offer?.alreadyCompleted == false &&
                                  lobby.participants.length <
                                      lobby.requiredPlayers &&
                                  AdventureCatalog.byId
                                      .containsKey(lobby.adventureId))
                                OutlinedButton(
                                    key:
                                        Key('canonical-join-group-${lobby.id}'),
                                    onPressed: enabled
                                        ? () => _choose(
                                            context,
                                            AdventureCatalog
                                                .byId[lobby.adventureId]!,
                                            lobby.id)
                                        : null,
                                    child: Text(s.pick('Join', 'Meedoen'))),
                            ]))),
            ]));
  }

  Future<void> _choose(BuildContext context, AdventureDefinition definition,
      String? lobbyId) async {
    final owner = context.read<CanonicalGameSession>().snapshot!.ownerId;
    String? selected;
    await showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => CanonicalEntityDialog(
                ownerId: owner,
                builder: (context, view, enabled) {
                  final s = AppStrings.of(context);
                  final groups = context.watch<CanonicalGroups>();
                  final dragons = view.dragons.where((d) => d.owned).toList()
                    ..sort((a, b) {
                      final glow =
                          (b.highlighted.contains(definition.focus.name)
                                  ? 1
                                  : 0) -
                              (a.highlighted.contains(definition.focus.name)
                                  ? 1
                                  : 0);
                      return glow != 0
                          ? glow
                          : b.training[definition.focus.name]!
                              .compareTo(a.training[definition.focus.name]!);
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
                                            'canonical-group-dragon-${dragon.id}'),
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
                                                        'canonical-group-expertise-${dragon.id}'),
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
                                              ExpertiseScoreBadge(
                                                  dragonId: dragon.id,
                                                  focus: definition.focus,
                                                  focusLabel: switch (
                                                      definition.focus.name) {
                                                    'might' =>
                                                      s.pick('Might', 'Kracht'),
                                                    'spirit' =>
                                                      s.pick('Spirit', 'Geest'),
                                                    _ => 'Arcana'
                                                  },
                                                  score: dragon.training[
                                                      definition.focus.name]!,
                                                  maximum: dragon.maximum(
                                                      definition.focus),
                                                  highlighted: dragon
                                                      .highlighted
                                                      .contains(definition
                                                          .focus.name),
                                                  expand: true),
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
                          key: const Key('canonical-confirm-group'),
                          label: s.pick('Join', 'Meedoen'),
                          action: enabled &&
                                  !groups.loading &&
                                  groups.error == null &&
                                  choice?.owned == true &&
                                  choice!.adventureId == null
                              ? () async {
                                  final actions = CanonicalGameActions(
                                      context.read<CanonicalGameSession>());
                                  if (lobbyId == null) {
                                    await actions.createGroupAdventure(
                                        definition.id, choice.id);
                                  } else {
                                    await actions.joinGroupAdventure(
                                        lobbyId, choice.id);
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
