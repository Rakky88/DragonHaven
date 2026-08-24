import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_lineage.dart';
import '../models/social.dart';
import '../providers/online_account_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';
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
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const Key('add-friend-button'),
          onPressed: online.busy ? null : () => _showAddFriend(context),
          icon: const Icon(Icons.person_add_alt_1_rounded),
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
          'Friends (${online.friends.length})',
          'Vrienden (${online.friends.length})',
        )),
        if (online.friends.isEmpty)
          _StatusCard(
            icon: Icons.people_outline_rounded,
            text: strings.pick(
              'No friends yet. Share your Keeper ID or add someone else.',
              'Nog geen vrienden. Deel je Keeper-ID of voeg iemand toe.',
            ),
          )
        else
          for (final friend in online.friends) _FriendTile(friend: friend),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(strings.tr('friends'),
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 7),
          Text(
            strings.pick(
              'Find trusted keepers, compare collections and visit their profiles.',
              'Vind vertrouwde hoeders, vergelijk collecties en bezoek hun profiel.',
            ),
            style: const TextStyle(color: AppColors.muted, fontSize: 15),
          ),
        ]),
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
      color: const Color(0xFFEDE8FF),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
    return Card(
      child: ListTile(
        key: Key('friend-${friend.userId}'),
        onTap: () => _showFriendProfile(context, friend),
        leading: KeeperPortrait(
          portraitKey: friend.portraitKey,
          displayName: friend.displayName,
          radius: 27,
        ),
        title: Text(friend.displayName,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
            '${keeperTitleLabel(strings, friend.title)}\n${strings.pick('Discovered', 'Ontdekt')}: '
            '${friend.discoveredDragonCount}'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
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
            const SizedBox(height: 18),
            _ProfileFact(
              icon: Icons.auto_stories_rounded,
              label: strings.pick('Discovered dragons', 'Ontdekte draken'),
              value: '${friend.discoveredDragonCount}',
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
      {required this.icon, required this.text, this.error = false});
  final IconData icon;
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) => Card(
        color: error ? const Color(0xFFFFECEC) : null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Icon(icon,
                color: error ? Colors.redAccent : AppColors.twilight, size: 38),
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
