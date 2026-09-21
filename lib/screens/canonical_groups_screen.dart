import '../widgets/game_icon_sprite.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/social.dart';
import '../theme/app_theme.dart';
import '../widgets/online_account_access.dart'
    show KeeperPortrait, keeperTitleLabel;
import 'adventure_hub_screen.dart'
    show
        showRestoredAdventureDetails,
        restoredGroupRequirements,
        restoredGroupRewards;
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
        padding: widget.embedded && widget.section != 0
            ? EdgeInsets.zero
            : const EdgeInsets.all(16),
        children: [
          if (!widget.embedded || widget.section == 0)
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
            _offerCard(context, definition, enabled)
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
            _lobbyCard(context, lobby),
        ]);
  }

  Widget _offerCard(
      BuildContext context, AdventureDefinition definition, bool enabled) {
    final s = AppStrings.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white.withValues(alpha: .96),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('group-offer-${definition.id}'),
        onTap: () => showRestoredAdventureDetails(context, definition,
            onChooseDragon:
                enabled ? () => _choose(context, definition, null) : null),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.fromLTRB(11, 8, 7, 8),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text(s.adventureTitle(definition),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 13.5)),
                  const SizedBox(height: 5),
                  Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const GameIconSprite(GameIconKind.clock, size: 19),
                          const SizedBox(width: 3),
                          Text(s.adventureDuration(definition.duration),
                              style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800)),
                        ]),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.group_rounded,
                              size: 18,
                              color: AppColors.eventColor(
                                  context, AppColors.twilight)),
                          const SizedBox(width: 3),
                          Text(
                              '${definition.requirements.players} ${s.pick('dragons', 'draken')}',
                              style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800)),
                        ]),
                        GameIconSprite(
                            GameIconSprite.forTrainingFocus(definition.focus),
                            size: 19),
                      ]),
                ])),
            const SizedBox(width: 6),
            Semantics(
                button: true,
                label: s.pick('Create', 'Maken'),
                child: InkWell(
                    key: const Key('canonical-create-group'),
                    onTap: enabled
                        ? () => _choose(context, definition, null)
                        : null,
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                        width: 56,
                        height: 58,
                        decoration: BoxDecoration(
                            gradient: AppColors.panelGradient(context,
                                fallback: const LinearGradient(colors: [
                                  Color(0xFF7256B5),
                                  Color(0xFF4C358D)
                                ])),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x334C358D),
                                  blurRadius: 9,
                                  offset: Offset(0, 4))
                            ]),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const GameIconSprite(GameIconKind.adventureStart,
                                  size: 33),
                              Text(s.pick('Create', 'Maken'),
                                  maxLines: 1,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      height: 1,
                                      fontWeight: FontWeight.w900)),
                            ])))),
          ]),
        ),
      ),
    );
  }

  Widget _lobbyCard(BuildContext context, GroupAdventureLobby lobby) {
    final s = AppStrings.of(context);
    final session = context.watch<CanonicalGameSession>();
    final definition = AdventureCatalog.byId[lobby.adventureId];
    final ready = lobby.rewardReadyAt(session.snapshot!.serverTime);
    final owner = lobby.owner;
    final member = lobby.participants
        .where((p) => p.dragonId == lobby.myDragonId)
        .firstOrNull;
    return Card(
      key: Key('canonical-group-${lobby.id}'),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(top: 7),
      elevation: lobby.isParticipant ? null : 0,
      color: lobby.isParticipant ? null : Colors.white.withValues(alpha: .96),
      child: InkWell(
        onTap: () => _showLobby(lobby),
        child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 13, 10),
            child: Row(children: [
              if (lobby.isParticipant)
                Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFE9FBF4), Color(0xFFD6F1E8)]),
                        borderRadius: BorderRadius.circular(20)),
                    child: const GameIconSprite(GameIconKind.adventureGroup,
                        size: 74))
              else
                KeeperPortrait(
                    portraitKey: owner?.keeper.portraitKey ?? 'portrait_001',
                    displayName: owner?.keeper.displayName ?? 'Keeper',
                    frameKey: owner?.keeper.frameKey,
                    badgeKey: owner?.keeper.badgeKey,
                    radius: 24),
              const SizedBox(width: 11),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        lobby.isParticipant
                            ? definition == null
                                ? s.pick('Group Adventure', 'Groepsavontuur')
                                : s.adventureTitle(definition)
                            : owner?.keeper.displayName ?? 'Keeper',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(
                        lobby.isParticipant
                            ? '${member?.dragonName ?? s.pick('Your dragon', 'Jouw draak')} \u00b7 ${lobby.participants.length}/${lobby.requiredPlayers}'
                            : definition == null
                                ? lobby.adventureId
                                : s.adventureTitle(definition),
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 7),
                    if (lobby.isParticipant)
                      Text(
                          lobby.isWaiting
                              ? s.pick(
                                  'Waiting for ${lobby.requiredPlayers - lobby.participants.length} dragon(s)',
                                  'Wacht op ${lobby.requiredPlayers - lobby.participants.length} draak/draken')
                              : ready
                                  ? s.pick('Rewards are ready',
                                      'Beloningen staan klaar')
                                  : s.remainingDuration(lobby.endsAt!
                                      .difference(
                                          session.snapshot!.serverTime)),
                          style: TextStyle(
                              color: ready
                                  ? const Color(0xFF24735B)
                                  : AppColors.eventColor(
                                      context, AppColors.twilight),
                              fontWeight: FontWeight.w900))
                    else
                      ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                              minHeight: 6,
                              value: (lobby.participants.length /
                                      lobby.requiredPlayers.clamp(1, 4))
                                  .clamp(0, 1),
                              color: const Color(0xFF5F9F86),
                              backgroundColor: const Color(0xFFDDF1E8))),
                  ])),
              const SizedBox(width: 8),
              if (!lobby.isParticipant)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  const GameIconSprite(GameIconKind.adventureGroup, size: 39),
                  Text('${lobby.participants.length}/${lobby.requiredPlayers}',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w900)),
                ])
              else
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.eventColor(context, AppColors.twilight)),
            ])),
      ),
    );
  }

  Future<void> _showLobby(GroupAdventureLobby original) async {
    final owner = context.read<CanonicalGameSession>().connection.currentOwner;
    final epoch = context.read<CanonicalGameSession>().connection.sessionEpoch;
    await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) =>
            Consumer2<CanonicalGroups, CanonicalGameSession>(
                builder: (context, groups, session, _) {
              // The modal never retains interactive data across an account switch.
              if (session.connection.currentOwner != owner ||
                  session.connection.sessionEpoch != epoch ||
                  session.snapshot == null) {
                return const SizedBox.shrink();
              }
              final lobby =
                  groups.lobbies.where((l) => l.id == original.id).firstOrNull;
              if (lobby == null) return const SizedBox.shrink();
              final s = AppStrings.of(context);
              final definition = AdventureCatalog.byId[lobby.adventureId];
              final ready = lobby.rewardReadyAt(session.snapshot!.serverTime);
              final enabled =
                  session.canAct && !groups.loading && groups.error == null;
              final actions = CanonicalGameActions(session);
              final canJoin = enabled &&
                  lobby.isWaiting &&
                  !lobby.isParticipant &&
                  lobby.isCurrentOffer &&
                  groups.status?.alreadyCompleted == false &&
                  !groups.lobbies
                      .any((l) => l.isCurrentOffer && l.isParticipant) &&
                  lobby.participants.length < lobby.requiredPlayers &&
                  definition != null;
              return SafeArea(
                  child: DraggableScrollableSheet(
                      expand: false,
                      initialChildSize: .78,
                      maxChildSize: .94,
                      builder: (_, controller) => ListView(
                              controller: controller,
                              key: Key('canonical-group-details-${lobby.id}'),
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                              children: [
                                const Center(
                                    child: GameIconSprite(
                                        GameIconKind.adventureGroup,
                                        size: 108)),
                                Text(
                                    definition == null
                                        ? s.pick(
                                            'Group Adventure', 'Groepsavontuur')
                                        : s.adventureTitle(definition),
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 6),
                                Text(
                                    lobby.isWaiting
                                        ? s.pick(
                                            'The journey starts automatically when all requirements are met.',
                                            'De reis start automatisch zodra aan alle vereisten is voldaan.')
                                        : ready
                                            ? s.pick('The group has returned.',
                                                'De groep is teruggekeerd.')
                                            : s.remainingDuration(lobby.endsAt!
                                                .difference(session
                                                    .snapshot!.serverTime)),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: AppColors.muted)),
                                if (definition != null) ...[
                                  const SizedBox(height: 12),
                                  restoredGroupRequirements(definition),
                                  const SizedBox(height: 12),
                                  restoredGroupRewards(definition,
                                      approximate: !ready),
                                ],
                                const SizedBox(height: 14),
                                Text(
                                    '${s.pick('Participants', 'Deelnemers')} ${lobby.participants.length}/${lobby.requiredPlayers}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 6),
                                for (final member in lobby.participants)
                                  Card(
                                      child: ListTile(
                                          leading: KeeperPortrait(
                                              portraitKey:
                                                  member.keeper.portraitKey,
                                              displayName:
                                                  member.keeper.displayName,
                                              frameKey: member.keeper.frameKey,
                                              badgeKey: member.keeper.badgeKey,
                                              radius: 23),
                                          title: Text(member.keeper.displayName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w900)),
                                          subtitle: Text(
                                              '${keeperTitleLabel(s, member.keeper.title)}\n${member.dragonName} \u00b7 ${s.pick('Level', 'Niveau')} ${member.level} \u00b7 M ${member.might} / A ${member.arcana} / S ${member.spirit}'),
                                          isThreeLine: true,
                                          trailing: lobby.isWaiting &&
                                                  lobby.isOwner &&
                                                  !member.isOwner
                                              ? CanonicalActionButton(
                                                  key: Key(
                                                      'canonical-remove-group-${member.keeper.userId}'),
                                                  label: s.pick(
                                                      'Remove', 'Verwijderen'),
                                                  confirmation: s.pick(
                                                      'Remove this friend from the lobby?',
                                                      'Deze vriend uit de lobby verwijderen?'),
                                                  action: enabled
                                                      ? () async {
                                                          await actions
                                                              .removeGroupAdventureMember(
                                                                  lobby.id,
                                                                  member.keeper
                                                                      .userId);
                                                          await _refresh();
                                                        }
                                                      : null)
                                              : null)),
                                const SizedBox(height: 12),
                                if (lobby.isWaiting && lobby.isParticipant)
                                  CanonicalActionButton(
                                      key: Key(
                                          'canonical-leave-group-${lobby.id}'),
                                      label: lobby.isOwner
                                          ? s.pick(
                                              'Cancel group', 'Groep annuleren')
                                          : s.pick('Withdraw', 'Uitschrijven'),
                                      confirmation: lobby.isOwner
                                          ? s.pick(
                                              'Close this lobby for everyone?',
                                              'Deze lobby voor iedereen sluiten?')
                                          : s.pick('Leave this lobby?',
                                              'Deze lobby verlaten?'),
                                      action: enabled
                                          ? () async {
                                              await actions.leaveGroupAdventure(
                                                  lobby.id);
                                              if (sheetContext.mounted) {
                                                Navigator.pop(sheetContext);
                                              }
                                              if (mounted) await _refresh();
                                            }
                                          : null),
                                if (canJoin)
                                  FilledButton.icon(
                                      key: Key(
                                          'canonical-join-group-${lobby.id}'),
                                      onPressed: () {
                                        Navigator.pop(sheetContext);
                                        _choose(
                                            this.context, definition, lobby.id);
                                      },
                                      icon: const Icon(Icons.group_add_rounded),
                                      label: Text(s.pick('Join with a dragon',
                                          'Aanmelden met een draak'))),
                                if (ready &&
                                    lobby.isParticipant &&
                                    !lobby.rewardAcknowledged)
                                  CanonicalActionButton(
                                      key: Key(
                                          'canonical-claim-group-${lobby.id}'),
                                      primary: true,
                                      label: s.pick('Claim rewards',
                                          'Beloningen ophalen'),
                                      action: enabled &&
                                              session.snapshot!.trialAttempt ==
                                                  null &&
                                              session.snapshot!.schoolAttempt ==
                                                  null
                                          ? () async {
                                              await actions
                                                  .claimGroupReward(lobby.id);
                                              if (sheetContext.mounted) {
                                                Navigator.pop(sheetContext);
                                              }
                                              if (mounted) await _refresh();
                                            }
                                          : null),
                              ])));
            }));
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
