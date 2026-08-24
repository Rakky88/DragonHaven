import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_lineage.dart';
import '../models/chest.dart';
import '../models/mystic_relic.dart';
import '../models/social.dart';
import '../providers/household_provider.dart';
import '../providers/online_account_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';
import '../widgets/dragon_trial_records.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/online_account_access.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final online = context.watch<OnlineAccountProvider>();
    if (!online.isConfigured) {
      return _FriendsList(children: [
        _Header(strings: strings),
        _SetupRequired(strings: strings),
      ]);
    }
    if (!online.isSignedIn) {
      return _FriendsList(children: [
        _Header(strings: strings),
        const OnlineAccountAccessCard(),
      ]);
    }
    if (online.profile == null && online.busy) {
      return const Center(child: CircularProgressIndicator());
    }
    final sortedFriends = online.friends.toList(growable: false)
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ));
    return RefreshIndicator(
      onRefresh: online.refresh,
      child: _FriendsList(children: [
        _Header(strings: strings),
        if (online.errorCode case final error?)
          _StatusCard(
            icon: Icons.cloud_off_rounded,
            text: socialMessage(strings, error),
            error: true,
          ),
        if (online.profile case final profile?) _MyKeeperCard(profile: profile),
        _FriendsOverview(online: online),
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const Key('add-friend-button'),
          onPressed: online.busy ? null : () => _showAddFriend(context),
          icon: const GameIconSprite(GameIconKind.friendsAdd, size: 39),
          label:
              Text(strings.pick('Add by Keeper ID', 'Toevoegen via Keeper-ID')),
        ),
        if (online.incomingRequests.isNotEmpty) ...[
          _SectionTitle(
              strings.pick('Friend requests', 'Vriendschapsverzoeken')),
          for (final request in online.incomingRequests)
            _IncomingRequestCard(request: request),
        ],
        if (online.outgoingRequests.isNotEmpty) ...[
          _SectionTitle(strings.pick('Sent requests', 'Verstuurde verzoeken')),
          for (final request in online.outgoingRequests)
            _OutgoingRequestCard(request: request),
        ],
        _SectionTitle(strings.pick(
          'Friends (${sortedFriends.length})',
          'Vrienden (${sortedFriends.length})',
        )),
        if (sortedFriends.isEmpty)
          _StatusCard(
            sprite: GameIconKind.navFriends,
            text: strings.pick(
              'No friends yet. Share your Keeper ID or add someone else.',
              'Nog geen vrienden. Deel je Keeper-ID of voeg iemand toe.',
            ),
          )
        else
          for (final friend in sortedFriends) _FriendTile(friend: friend),
        if (online.blockedKeepers.isNotEmpty) ...[
          _SectionTitle(strings.pick('Blocked', 'Geblokkeerd')),
          for (final keeper in online.blockedKeepers)
            Card(
              child: ListTile(
                leading: KeeperPortrait(
                  portraitKey: keeper.portraitKey,
                  displayName: keeper.displayName,
                ),
                title: Text(keeper.displayName),
                subtitle: Text(keeper.keeperCode),
                trailing: TextButton(
                  onPressed: online.busy
                      ? null
                      : () => online.unblockKeeper(keeper.userId),
                  child: Text(strings.pick('Unblock', 'Deblokkeren')),
                ),
              ),
            ),
        ],
      ]),
    );
  }

  Future<void> _showAddFriend(BuildContext context) async {
    final controller = TextEditingController();
    final strings = AppStrings.of(context);
    final online = context.read<OnlineAccountProvider>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(strings.pick('Add a keeper', 'Hoeder toevoegen')),
        content: TextField(
          key: const Key('friend-code-field'),
          controller: controller,
          autofocus: true,
          maxLength: 11,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Keeper ID',
            hintText: 'DH-12AB34CD',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.tr('cancel'))),
          FilledButton(
            key: const Key('send-friend-request'),
            onPressed: () async {
              final sent = await online.sendFriendRequest(controller.text);
              if (sent && dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(strings.pick('Send request', 'Verzoek sturen')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!context.mounted) return;
    _showProviderMessage(context, online);
  }
}

class _FriendsList extends StatelessWidget {
  const _FriendsList({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
        key: const PageStorageKey('friends-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: children,
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.strings});
  final AppStrings strings;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 16, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF241747), Color(0xFF6548A0)],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332B174D),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const GameIconSprite(GameIconKind.navFriends, size: 92),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.tr('friends'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.pick(
                        'Trusted keepers, shared adventures and safe trades.',
                        'Vertrouwde hoeders, gedeelde avonturen en veilige ruilen.',
                      ),
                      style: const TextStyle(
                        color: Color(0xFFE7DFFA),
                        height: 1.25,
                        fontWeight: FontWeight.w600,
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

class _SetupRequired extends StatelessWidget {
  const _SetupRequired({required this.strings});
  final AppStrings strings;
  @override
  Widget build(BuildContext context) => _StatusCard(
        icon: Icons.dns_outlined,
        text: strings.pick(
          'Online accounts are ready in this build, but this installation still needs its server URL and publishable key.',
          'Online accounts zijn in deze build voorbereid, maar deze installatie heeft nog een server-URL en publieke sleutel nodig.',
        ),
      );
}

class _MyKeeperCard extends StatelessWidget {
  const _MyKeeperCard({required this.profile});
  final KeeperProfile profile;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFEDE8FF)],
          ),
        ),
        child: Row(children: [
          KeeperPortrait(
            portraitKey: profile.portraitKey,
            displayName: profile.displayName,
            radius: 29,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 17)),
                Text(keeperTitleLabel(strings, profile.title),
                    style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 4),
                Text(profile.keeperCode,
                    style: const TextStyle(
                        color: AppColors.twilight,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8)),
              ],
            ),
          ),
          IconButton(
            key: const Key('copy-keeper-code'),
            tooltip: strings.pick('Copy Keeper ID', 'Keeper-ID kopiëren'),
            onPressed: () => copyKeeperCode(context, profile.keeperCode),
            icon: const Icon(Icons.copy_rounded),
          ),
        ]),
      ),
    );
  }
}

class _FriendsOverview extends StatelessWidget {
  const _FriendsOverview({required this.online});

  final OnlineAccountProvider online;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final activeTrades = online.trades.where((trade) => trade.isActive).length;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: _OverviewPill(
              sprite: GameIconKind.navFriends,
              value: '${online.friends.length}',
              label: strings.pick('friends', 'vrienden'),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _OverviewPill(
              sprite: GameIconKind.friendsAdd,
              value: '${online.incomingRequests.length}',
              label: strings.pick('requests', 'verzoeken'),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _OverviewPill(
              sprite: GameIconKind.friendsTrade,
              value: '$activeTrades',
              label: strings.pick('trades', 'ruilen'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPill extends StatelessWidget {
  const _OverviewPill({
    required this.sprite,
    required this.value,
    required this.label,
  });

  final GameIconKind sprite;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F0FF),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFD8CCF2)),
        ),
        child: Row(
          children: [
            GameIconSprite(sprite, size: 31),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          color: AppColors.twilight,
                          fontWeight: FontWeight.w900)),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 9.5)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _IncomingRequestCard extends StatelessWidget {
  const _IncomingRequestCard({required this.request});
  final FriendshipRequest request;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final online = context.read<OnlineAccountProvider>();
    return Card(
      key: Key('incoming-request-${request.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: KeeperPortrait(
              portraitKey: request.keeper.portraitKey,
              displayName: request.keeper.displayName,
            ),
            title: Text(request.keeper.displayName,
                style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(
                '${keeperTitleLabel(strings, request.keeper.title)}\n${request.keeper.keeperCode}'),
            isThreeLine: true,
          ),
          Wrap(
            spacing: 7,
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  await online.respondToRequest(request.id, 'rejected');
                  if (context.mounted) _showProviderMessage(context, online);
                },
                child: Text(strings.pick('Reject', 'Afwijzen')),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                onPressed: () async {
                  await online.respondToRequest(request.id, 'blocked');
                  if (context.mounted) _showProviderMessage(context, online);
                },
                child: Text(strings.pick('Block', 'Blokkeren')),
              ),
              FilledButton(
                key: Key('accept-request-${request.id}'),
                onPressed: () async {
                  await online.respondToRequest(request.id, 'accepted');
                  if (context.mounted) _showProviderMessage(context, online);
                },
                child: Text(strings.pick('Accept', 'Accepteren')),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

class _OutgoingRequestCard extends StatelessWidget {
  const _OutgoingRequestCard({required this.request});
  final FriendshipRequest request;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      child: ListTile(
        leading: KeeperPortrait(
          portraitKey: request.keeper.portraitKey,
          displayName: request.keeper.displayName,
        ),
        title: Text(request.keeper.displayName,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(keeperTitleLabel(strings, request.keeper.title)),
        trailing: Chip(label: Text(strings.pick('Pending', 'In afwachting'))),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend});
  final KeeperProfile friend;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final activeTrades =
        context.watch<OnlineAccountProvider>().tradesWith(friend.userId);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('friend-${friend.userId}'),
        onTap: () => _showFriendProfile(context, friend),
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 11, 8, 11),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFFFF8E8)],
            ),
          ),
          child: Row(
            children: [
              KeeperPortrait(
                portraitKey: friend.portraitKey,
                displayName: friend.displayName,
                radius: 29,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(friend.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(keeperTitleLabel(strings, friend.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE8FF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${friend.discoveredDragonCount} ${strings.pick('dragons discovered', 'draken ontdekt')}',
                        style: const TextStyle(
                          color: AppColors.twilight,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              if (activeTrades.isNotEmpty)
                IconButton(
                  key: Key('friend-trade-${friend.userId}'),
                  tooltip: strings.pick('Open trade', 'Ruil openen'),
                  onPressed: () => _showTrade(context, activeTrades.first),
                  icon: Badge(
                    label: Text('${activeTrades.length}'),
                    child: const GameIconSprite(
                      GameIconKind.friendsTrade,
                      size: 40,
                    ),
                  ),
                )
              else
                const GameIconSprite(GameIconKind.friendsVisit, size: 44),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showFriendProfile(
    BuildContext context, KeeperProfile friend) async {
  final strings = AppStrings.of(context);
  final online = context.read<OnlineAccountProvider>();
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: FractionallySizedBox(
        heightFactor: .88,
        child: ListView(
          key: Key('friend-profile-${friend.userId}'),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Center(
              child: KeeperPortrait(
                portraitKey: friend.portraitKey,
                displayName: friend.displayName,
                radius: 48,
              ),
            ),
            const SizedBox(height: 10),
            Text(friend.displayName,
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.headlineSmall),
            Text(keeperTitleLabel(strings, friend.title),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 16)),
            const SizedBox(height: 6),
            Text(friend.keeperCode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.twilight,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8)),
            const SizedBox(height: 13),
            Center(
              child: Tooltip(
                message: strings.pick(
                    'Trade with this friend', 'Ruilen met deze vriend'),
                child: InkWell(
                  key: const Key('start-trade-button'),
                  borderRadius: BorderRadius.circular(22),
                  onTap: online.busy
                      ? null
                      : () => _startTrade(sheetContext, friend),
                  child: Ink(
                    width: 78,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFFFF1A8),
                        Color(0xFFE8CB69),
                      ]),
                      borderRadius: BorderRadius.circular(22),
                      border:
                          Border.all(color: const Color(0xFF9A6A21), width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x332D195F),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: GameIconSprite(
                        GameIconKind.friendsTrade,
                        size: 58,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (online.tradesWith(friend.userId).isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final trade in online.tradesWith(friend.userId))
                Card(
                  color: trade.needsMyResponse
                      ? const Color(0xFFFFF5CC)
                      : const Color(0xFFF2ECFF),
                  child: ListTile(
                    key: Key('trade-${trade.id}'),
                    leading: const GameIconSprite(
                      GameIconKind.friendsTrade,
                      size: 42,
                    ),
                    title: Text(_tradeStatusLabel(strings, trade),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text(_tradeItemLabel(
                        strings,
                        context.read<HouseholdProvider>(),
                        trade.initiatorItem)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showTrade(sheetContext, trade),
                  ),
                ),
            ],
            const SizedBox(height: 18),
            _ProfileFact(
              icon: Icons.auto_stories_rounded,
              label: strings.pick('Discovered dragons', 'Ontdekte draken'),
              value: '${friend.discoveredDragonCount}',
            ),
            const SizedBox(height: 10),
            DragonTrialRecords(
              account: true,
              cavernFlightBest: friend.cavernFlightBest,
              ruinBreakerBest: friend.ruinBreakerBest,
              runeweaverBest: friend.runeweaverBest,
            ),
            const SizedBox(height: 14),
            if (friend.favoriteDragon case final dragon?)
              _FavoriteDragonCard(dragon: dragon)
            else
              _StatusCard(
                icon: Icons.favorite_border_rounded,
                text: strings.pick('No favorite dragon selected.',
                    'Geen favoriete draak gekozen.'),
              ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              key: const Key('remove-friend-button'),
              style:
                  OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                      context: sheetContext,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(strings.pick(
                            'Remove friend?', 'Vriend verwijderen?')),
                        content: Text(strings.pick(
                          '${friend.displayName} will disappear from both friend lists.',
                          '${friend.displayName} verdwijnt uit beide vriendenlijsten.',
                        )),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: Text(strings.tr('cancel')),
                          ),
                          FilledButton(
                            key: const Key('confirm-remove-friend'),
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.redAccent),
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: Text(strings.pick('Remove', 'Verwijderen')),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (!confirmed) return;
                final removed = await online.removeFriend(friend.userId);
                if (removed && sheetContext.mounted) {
                  Navigator.pop(sheetContext);
                }
              },
              icon: const Icon(Icons.person_remove_rounded),
              label: Text(strings.pick('Remove friend', 'Vriend verwijderen')),
            ),
            TextButton.icon(
              onPressed: () async {
                final blocked = await online.blockKeeper(friend.userId);
                if (blocked && sheetContext.mounted) {
                  Navigator.pop(sheetContext);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              icon: const Icon(Icons.block_rounded),
              label: Text(strings.pick('Block keeper', 'Hoeder blokkeren')),
            ),
          ],
        ),
      ),
    ),
  );
  if (context.mounted) _showProviderMessage(context, online);
}

class _FavoriteDragonCard extends StatelessWidget {
  const _FavoriteDragonCard({required this.dragon});
  final FavoriteDragonSummary dragon;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final lineage = dragonLineageById(dragon.lineageId);
    return Card(
      color: const Color(0xFFF7F2FF),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Text(strings.pick('Favorite dragon', 'Favoriete draak'),
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          DragonArt(
            height: 170,
            animate: false,
            stageKey: dragon.stageKey,
            lineageId: dragon.lineageId,
            evolutionPath: dragon.evolutionPath,
            prismatic: dragon.prismatic,
            sinister: dragon.sinister,
          ),
          Text(dragon.name,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
          Text('${lineage.name(strings.isDutch)} • '
              '${strings.pick('Level', 'Niveau')} ${dragon.level}'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Expertise(label: 'Might', value: dragon.might)),
            Expanded(child: _Expertise(label: 'Arcana', value: dragon.arcana)),
            Expanded(child: _Expertise(label: 'Spirit', value: dragon.spirit)),
          ]),
          const SizedBox(height: 13),
          DragonTrialRecords(
            compact: true,
            cavernFlightBest: dragon.cavernFlightBest,
            ruinBreakerBest: dragon.ruinBreakerBest,
            runeweaverBest: dragon.runeweaverBest,
          ),
        ]),
      ),
    );
  }
}

class _Expertise extends StatelessWidget {
  const _Expertise({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text('$value',
            style: const TextStyle(
                color: AppColors.twilight,
                fontWeight: FontWeight.w900,
                fontSize: 17)),
        Text(label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ]);
}

class _ProfileFact extends StatelessWidget {
  const _ProfileFact(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: AppColors.twilight),
          title: Text(label),
          trailing: Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        ),
      );
}

Future<void> _startTrade(BuildContext context, KeeperProfile friend) async {
  final online = context.read<OnlineAccountProvider>();
  final item = await _pickTradeItem(context);
  if (item == null || !context.mounted) return;
  final strings = AppStrings.of(context);
  final game = context.read<HouseholdProvider>();
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
              strings.pick('Send trade proposal?', 'Ruilvoorstel versturen?')),
          content: Text(strings.pick(
            '${_tradeItemLabel(strings, game, item)} will be reserved for ten minutes while ${friend.displayName} responds.',
            '${_tradeItemLabel(strings, game, item)} wordt tien minuten gereserveerd terwijl ${friend.displayName} reageert.',
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.tr('cancel')),
            ),
            FilledButton(
              key: const Key('confirm-create-trade'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.pick('Send', 'Versturen')),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed) return;
  await online.createTrade(friend.userId, item);
  if (context.mounted) _showProviderMessage(context, online);
}

Future<TradeItem?> _pickTradeItem(BuildContext context) async {
  final online = context.read<OnlineAccountProvider>();
  if (!await online.prepareTradeInventory() || !context.mounted) {
    if (context.mounted) _showProviderMessage(context, online);
    return null;
  }
  final strings = AppStrings.of(context);
  final items = online.tradeInventory;
  return showModalBottomSheet<TradeItem>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: FractionallySizedBox(
        heightFactor: .82,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
            child: Column(children: [
              Text(strings.pick('Choose one item', 'Kies één item'),
                  style: Theme.of(sheetContext).textTheme.headlineSmall),
              const SizedBox(height: 5),
              Text(
                strings.pick(
                  'The item is kept safe and cannot be used in another trade. The proposal expires ten minutes after it is created.',
                  'Het item wordt veilig apart gezet en kan niet in een andere ruil worden gebruikt. Het voorstel vervalt tien minuten nadat het is aangemaakt.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ]),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        strings.pick(
                          'You have no unreserved eggs, chests or relics to trade.',
                          'Je hebt geen vrije eieren, kisten of relieken om te ruilen.',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    key: const Key('trade-inventory-list'),
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final inventoryItem = items[index];
                      return Card(
                        child: ListTile(
                          key: Key(
                              'trade-item-${inventoryItem.item.kind.name}-${inventoryItem.item.key}'),
                          leading: _TradeItemArt(item: inventoryItem.item),
                          title: Text(
                            _tradeItemLabel(
                              strings,
                              context.read<HouseholdProvider>(),
                              inventoryItem.item,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: inventoryItem.item.kind == TradeItemKind.egg
                              ? Text(strings.pick(
                                  'Mysterious Egg', 'Mysterieus Ei'))
                              : null,
                          trailing: inventoryItem.available > 1
                              ? Chip(label: Text('×${inventoryItem.available}'))
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              Navigator.pop(sheetContext, inventoryItem.item),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    ),
  );
}

Future<void> _showTrade(BuildContext context, TradeOffer trade) async {
  final strings = AppStrings.of(context);
  final online = context.read<OnlineAccountProvider>();
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: FractionallySizedBox(
        heightFactor: .82,
        child: ListView(
          key: Key('trade-detail-${trade.id}'),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            const Center(
              child: GameIconSprite(GameIconKind.friendsTrade, size: 76),
            ),
            Text(
              strings.pick('Trade with ${trade.otherKeeper.displayName}',
                  'Ruil met ${trade.otherKeeper.displayName}'),
              textAlign: TextAlign.center,
              style: Theme.of(sheetContext).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              _tradeStatusLabel(strings, trade),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.twilight, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            _TradeOfferItemCard(
              title: trade.amInitiator
                  ? strings.pick('You offer', 'Jij biedt aan')
                  : strings.pick('${trade.otherKeeper.displayName} offers',
                      '${trade.otherKeeper.displayName} biedt aan'),
              item: trade.initiatorItem,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Icon(Icons.swap_vert_rounded,
                  size: 34, color: AppColors.twilight),
            ),
            if (trade.recipientItem case final item?)
              _TradeOfferItemCard(
                title: trade.amInitiator
                    ? strings.pick('${trade.otherKeeper.displayName} offers',
                        '${trade.otherKeeper.displayName} biedt aan')
                    : strings.pick('You offer', 'Jij biedt aan'),
                item: item,
              )
            else
              Card(
                color: const Color(0xFFF4F0FA),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Text(
                    strings.pick('Waiting for a return item.',
                        'Wachten op een tegenaanbod.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (!trade.amInitiator && trade.status == 'awaiting_recipient')
              FilledButton.icon(
                key: const Key('answer-trade-button'),
                onPressed: () async {
                  final item = await _pickTradeItem(sheetContext);
                  if (item == null || !sheetContext.mounted) return;
                  final accepted = await online.respondToTrade(trade.id, item);
                  if (accepted && sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                },
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: Text(strings.pick('Choose my item', 'Kies mijn item')),
              ),
            if (trade.amInitiator && trade.status == 'awaiting_initiator')
              FilledButton.icon(
                key: const Key('complete-trade-button'),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                        context: sheetContext,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(strings.pick(
                              'Complete this trade?', 'Deze ruil afronden?')),
                          content: Text(strings.pick(
                            'This is the final confirmation. Both items will change owner immediately.',
                            'Dit is de laatste bevestiging. Beide items wisselen direct van eigenaar.',
                          )),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: Text(strings.tr('cancel')),
                            ),
                            FilledButton(
                              key: const Key('confirm-complete-trade'),
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: Text(strings.pick('Trade', 'Ruilen')),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (!confirmed) return;
                  final completed = await online.completeTrade(trade.id);
                  if (completed && sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                },
                icon: const Icon(Icons.handshake_rounded),
                label: Text(strings.pick(
                    'Final confirmation', 'Definitief bevestigen')),
              ),
            if (trade.isActive) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('stop-trade-button'),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                onPressed: () async {
                  final stopped = trade.amInitiator
                      ? await online.cancelTrade(trade.id)
                      : await online.rejectTrade(trade.id);
                  if (stopped && sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                },
                icon: Icon(trade.amInitiator
                    ? Icons.cancel_outlined
                    : Icons.thumb_down_alt_outlined),
                label: Text(trade.amInitiator
                    ? strings.pick('Cancel trade', 'Ruil annuleren')
                    : strings.pick('Reject trade', 'Ruil weigeren')),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  if (context.mounted) _showProviderMessage(context, online);
}

class _TradeOfferItemCard extends StatelessWidget {
  const _TradeOfferItemCard({required this.title, required this.item});
  final String title;
  final TradeItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      color: const Color(0xFFF7F2FF),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          _TradeItemArt(item: item, size: 58),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.muted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  _tradeItemLabel(
                    strings,
                    context.read<HouseholdProvider>(),
                    item,
                  ),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _TradeItemArt extends StatelessWidget {
  const _TradeItemArt({required this.item, this.size = 46});
  final TradeItem item;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: switch (item.kind) {
          TradeItemKind.egg =>
            GameIconSprite(GameIconKind.mysteriousEgg, size: size),
          TradeItemKind.chest => Image.asset(
              item.chestTier?.assetPath ?? ChestTier.wooden.assetPath,
              fit: BoxFit.contain,
            ),
          TradeItemKind.relic => Image.asset(
              item.relic?.assetPath ?? MysticRelic.moralPrism.assetPath,
              fit: BoxFit.contain,
            ),
        },
      );
}

String _tradeItemLabel(
  AppStrings strings,
  HouseholdProvider game,
  TradeItem item,
) {
  switch (item.kind) {
    case TradeItemKind.egg:
      final egg = item.egg;
      return egg == null
          ? strings.pick('Mysterious Egg', 'Mysterieus Ei')
          : game.eggHintForEgg(egg, locale: strings.languageCode);
    case TradeItemKind.chest:
      return item.chestTier?.label(strings.isDutch) ??
          strings.pick('Chest', 'Kist');
    case TradeItemKind.relic:
      final relic = item.relic;
      return relic == null
          ? strings.pick('Relic', 'Reliek')
          : strings.relicName(relic);
  }
}

String _tradeStatusLabel(AppStrings strings, TradeOffer trade) =>
    switch (trade.status) {
      'awaiting_recipient' => trade.amInitiator
          ? strings.pick('Waiting for your friend', 'Wacht op je vriend')
          : strings.pick('New trade proposal', 'Nieuw ruilvoorstel'),
      'awaiting_initiator' => trade.amInitiator
          ? strings.pick('Your final confirmation is needed',
              'Jouw definitieve bevestiging is nodig')
          : strings.pick('Waiting for final confirmation',
              'Wacht op definitieve bevestiging'),
      'completed' => strings.pick('Trade completed', 'Ruil afgerond'),
      'cancelled' => strings.pick('Trade cancelled', 'Ruil geannuleerd'),
      'rejected' => strings.pick('Trade rejected', 'Ruil geweigerd'),
      'expired' => strings.pick('Trade expired', 'Ruil verlopen'),
      _ => strings.pick('Trade', 'Ruil'),
    };

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 22, 2, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard(
      {this.icon, this.sprite, required this.text, this.error = false})
      : assert(icon != null || sprite != null);
  final IconData? icon;
  final GameIconKind? sprite;
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) => Card(
        color: error ? const Color(0xFFFFECEC) : null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            if (sprite case final kind?)
              GameIconSprite(kind, size: 64)
            else
              Icon(icon,
                  color: error ? Colors.redAccent : AppColors.twilight,
                  size: 38),
            const SizedBox(height: 8),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted)),
          ]),
        ),
      );
}

void _showProviderMessage(BuildContext context, OnlineAccountProvider online) {
  final code = online.errorCode ?? online.noticeCode;
  if (code == null) return;
  final strings = AppStrings.of(context);
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(socialMessage(strings, code))));
  online.clearMessages();
}
