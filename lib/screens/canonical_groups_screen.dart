import '../widgets/game_icon_sprite.dart';
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
import '../widgets/shop_economy_scope.dart';
import 'canonical_adventures_screen.dart' show pickCanonicalAdventureDragon;

class CanonicalGroupsScreen extends StatelessWidget {
  const CanonicalGroupsScreen(
      {super.key, this.embedded = false, this.section, this.active = true});
  final bool embedded;
  final int? section;
  final bool active;
  @override
  Widget build(BuildContext context) => embedded
      ? Container(
          margin: section == 0
              ? const EdgeInsets.only(bottom: 12)
              : EdgeInsets.zero,
          decoration: section == 0
              ? BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFE9FBF4), Color(0xFFD6F1E8)]),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0x88D6F1E8)))
              : null,
          child: _Groups(embedded: true, section: section, active: active))
      : const ShopEconomyBoundary(child: _Groups());
}

class _Groups extends StatefulWidget {
  const _Groups({this.embedded = false, this.section, this.active = true});
  final bool embedded;
  final int? section;
  final bool active;
  @override
  State<_Groups> createState() => _GroupsState();
}

class _GroupsState extends State<_Groups> {
  Timer? _poll;
  String? _membership;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.active) unawaited(_refresh());
    });
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted &&
          widget.active &&
          ModalRoute.of(context)?.isCurrent == true &&
          context.read<CanonicalGameSession>().canAct) {
        unawaited(_refresh());
      }
    });
  }

  @override
  void didUpdateWidget(covariant _Groups oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final groups = context.read<CanonicalGroups>();
    if (groups.loading) return;
    await groups.refresh();
    if (!mounted) return;
    final session = context.read<CanonicalGameSession>();
    // Membership can change on another keeper's device. A new canonical read
    // releases removed members' dragons without importing a social snapshot.
    final membership = (groups.lobbies
            .where((l) => l.isParticipant)
            .map((l) =>
                '${l.id}:${l.status}:${l.myDragonId}:${l.startedAt}:${l.endsAt}:${l.rewardAcknowledged}')
            .toList()
          ..sort())
        .join('|');
    if (groups.error == null &&
        membership != _membership &&
        !session.busy &&
        session.connection.currentOwner != null) {
      try {
        await session.synchronize();
        _membership = membership;
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
    if (widget.embedded &&
        widget.section != 0 &&
        !lobbies.any((l) =>
            l.isParticipant &&
            !l.rewardAcknowledged &&
            l.rewardReadyAt(session.snapshot!.serverTime) ==
                (widget.section == 3))) {
      return const SizedBox.shrink();
    }
    return ListView(
        key: Key(widget.embedded
            ? 'adventure-groups-${widget.section}'
            : 'canonical-groups-list'),
        shrinkWrap: widget.embedded,
        primary: !widget.embedded,
        physics: widget.embedded
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            if (widget.embedded && widget.section == 0)
              const GameIconSprite(GameIconKind.adventureGroup, size: 46),
            Expanded(
                child: Text(
                    widget.embedded && widget.section == 0
                        ? s.pick('Group', 'Groep')
                        : s.pick('Group Adventures', 'Groepsavonturen'),
                    style: Theme.of(context).textTheme.titleLarge)),
            IconButton(
                key: const Key('canonical-refresh-groups'),
                tooltip: s.pick('Refresh', 'Vernieuwen'),
                onPressed: groups.loading ? null : _refresh,
                icon: const Icon(Icons.refresh)),
          ]),
          if (groups.loading && !widget.embedded)
            const LinearProgressIndicator(),
          if (groups.error case final error?)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(gameConnectionMessage(s, error))),
          if ((widget.section == null || widget.section == 0) &&
              offer != null &&
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
                              style: Theme.of(context).textTheme.titleMedium),
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
                              child: Text(
                                  s.pick('Choose dragon', 'Kies een draak'))),
                        ])))
          else if (offer != null &&
              (widget.section == null || widget.section == 0))
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(s.pick('No trail is available here right now',
                    'Er is hier nu geen pad beschikbaar'))),
          if (widget.section == null) const CanonicalSocialRewards(),
          for (final lobby in lobbies.where((l) =>
              widget.section == null ||
              (widget.section == 0
                  ? !l.isParticipant && l.isWaiting
                  : l.isParticipant &&
                      !l.rewardAcknowledged &&
                      l.rewardReadyAt(session.snapshot!.serverTime) ==
                          (widget.section == 3))))
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
                                  ? s.adventureTitle(
                                      AdventureCatalog.byId[lobby.adventureId]!)
                                  : s.pick('Group Adventure', 'Groepsavontuur'),
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(lobby.isWaiting
                              ? '${lobby.participants.length}/${lobby.requiredPlayers} · ${s.pick('Waiting for friends', 'Wachten op vrienden')}'
                              : lobby.rewardReadyAt(
                                      session.snapshot!.serverTime)
                                  ? s.pick(
                                      'Ready to claim', 'Klaar om op te halen')
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
                                        label: s.pick('Remove', 'Verwijderen'),
                                        confirmation: s.pick(
                                            'Remove this friend from the lobby?',
                                            'Deze vriend uit de lobby verwijderen?'),
                                        action: enabled
                                            ? () async {
                                                await actions
                                                    .removeGroupAdventureMember(
                                                        lobby.id,
                                                        member.keeper.userId);
                                                await _refresh();
                                              }
                                            : null),
                                ])),
                          if (lobby.isWaiting && lobby.isParticipant)
                            CanonicalActionButton(
                                key: Key('canonical-leave-group-${lobby.id}'),
                                label: s.pick('Leave lobby', 'Lobby verlaten'),
                                confirmation: lobby.isOwner
                                    ? s.pick('Close this lobby for everyone?',
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
                                key: Key('canonical-join-group-${lobby.id}'),
                                onPressed: enabled
                                    ? () => _choose(
                                        context,
                                        AdventureCatalog
                                            .byId[lobby.adventureId]!,
                                        lobby.id)
                                    : null,
                                child: Text(s.pick('Join', 'Meedoen'))),
                        ]))),
        ]);
  }

  Future<void> _choose(BuildContext context, AdventureDefinition definition,
      String? lobbyId) async {
    final actions = CanonicalGameActions(context.read<CanonicalGameSession>());
    final id = await pickCanonicalAdventureDragon(context, definition,
        keyPrefix: 'canonical-group-dragon',
        expertiseKeyPrefix: 'canonical-group-expertise');
    if (id == null || !context.mounted) return;
    await runShopAction(
        context,
        () => lobbyId == null
            ? actions.createGroupAdventure(definition.id, id)
            : actions.joinGroupAdventure(lobbyId, id));
    if (mounted) await _refresh();
  }
}
