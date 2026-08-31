import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/social.dart';
import '../providers/household_provider.dart';
import '../providers/online_account_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/online_account_access.dart';

String conclaveEmblemAsset(String key) => 'assets/images/ui/conclave/$key.png';

String aerieStageAsset(int stage) =>
    'assets/images/ui/conclave/aerie_stage_${stage.toString().padLeft(2, '0')}.png';

class ConclaveScreen extends StatefulWidget {
  const ConclaveScreen({super.key});

  @override
  State<ConclaveScreen> createState() => _ConclaveScreenState();
}

class _ConclaveScreenState extends State<ConclaveScreen> {
  List<ConclaveSummary>? _directory;
  Timer? _pollTimer;
  bool _pollInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDirectory());
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && context.read<OnlineAccountProvider>().conclave != null) {
        unawaited(_refreshConclave());
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshConclave() async {
    if (_pollInFlight) return;
    _pollInFlight = true;
    final refreshed = await context
        .read<OnlineAccountProvider>()
        .refreshConclave(background: true);
    _pollInFlight = false;
    if (mounted && refreshed) setState(() {});
  }

  Future<void> _loadDirectory() async {
    if (context.read<OnlineAccountProvider>().conclave != null) return;
    final result =
        await context.read<OnlineAccountProvider>().loadConclaveDirectory();
    if (mounted && result != null) setState(() => _directory = result);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final online = context.watch<OnlineAccountProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(strings.pick('Conclave', 'Conclave'))),
      body: RefreshIndicator(
        onRefresh: () async {
          await online.refresh();
          await _loadDirectory();
        },
        child: online.conclave != null
            ? _ConclaveHome(snapshot: online.conclave!)
            : _ConclaveDirectory(
                directory: _directory,
                invites: online.conclaveInvites,
                onReload: _loadDirectory,
              ),
      ),
    );
  }
}

class _ConclaveDirectory extends StatelessWidget {
  const _ConclaveDirectory({
    required this.directory,
    required this.invites,
    required this.onReload,
  });

  final List<ConclaveSummary>? directory;
  final List<ConclaveInvite> invites;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final online = context.watch<OnlineAccountProvider>();
    return ListView(
      key: const PageStorageKey('conclave-directory'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF21143F), Color(0xFF7952A7)],
            ),
            borderRadius: BorderRadius.circular(27),
          ),
          child: Row(
            children: [
              Image.asset(
                aerieStageAsset(1),
                width: 106,
                height: 92,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.castle_rounded,
                  color: Color(0xFFFFDF7D),
                  size: 66,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.pick('Find your Conclave', 'Vind je Conclave'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.pick(
                        'Build an Aerie together, chat and keep a shared Chronicle.',
                        'Bouw samen een Aerie, chat en bewaar een gedeelde Chronicle.',
                      ),
                      style: const TextStyle(
                        color: Color(0xFFE9DFF7),
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
        if (online.errorCode != null || online.noticeCode != null) ...[
          const SizedBox(height: 10),
          _ConclaveFeedback(online: online),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('create-conclave-button'),
          onPressed: online.busy
              ? null
              : () async {
                  final created = await _showCreateConclave(context);
                  if (created) await onReload();
                },
          icon: const Icon(Icons.add_home_work_rounded),
          label: Text(strings.pick('Create a Conclave', 'Maak een Conclave')),
        ),
        if (invites.isNotEmpty) ...[
          _Title(strings.pick('Invitations', 'Uitnodigingen')),
          for (final invite in invites)
            Card(
              child: ListTile(
                leading: _Emblem(keyName: invite.conclave.emblemKey, size: 50),
                title: Text(invite.conclave.name,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(strings.pick(
                  'Level ${invite.conclave.level} · expires in 7 days',
                  'Level ${invite.conclave.level} · verloopt binnen 7 dagen',
                )),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: strings.pick('Decline', 'Weigeren'),
                      onPressed: online.busy
                          ? null
                          : () => online.respondConclaveInvite(
                                invite.id,
                                false,
                              ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    IconButton.filled(
                      tooltip: strings.pick('Accept', 'Accepteren'),
                      onPressed: online.busy
                          ? null
                          : () => online.respondConclaveInvite(
                                invite.id,
                                true,
                              ),
                      icon: const Icon(Icons.check_rounded),
                    ),
                  ],
                ),
              ),
            ),
        ],
        _Title(strings.pick('Open Conclaves', 'Open Conclaves')),
        if (directory == null)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (directory!.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Text(
                strings.pick(
                  'No public Conclaves yet. You can found the first one.',
                  'Er zijn nog geen openbare Conclaves. Jij kunt de eerste stichten.',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          for (final conclave in directory!)
            _DirectoryCard(conclave: conclave, onReload: onReload),
      ],
    );
  }
}

class _DirectoryCard extends StatelessWidget {
  const _DirectoryCard({required this.conclave, required this.onReload});

  final ConclaveSummary conclave;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final online = context.watch<OnlineAccountProvider>();
    final full = conclave.memberCount >= conclave.memberLimit;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          children: [
            Row(
              children: [
                _Emblem(keyName: conclave.emblemKey, size: 60),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(conclave.name,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900)),
                      Text(
                        '${conclave.language.toUpperCase()} · ${conclave.memberCount}/${conclave.memberLimit} · ${strings.pick('Level', 'Level')} ${conclave.level}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: online.busy || full || conclave.requested
                      ? null
                      : () async {
                          await online.requestOrJoinConclave(conclave.id);
                          await onReload();
                        },
                  child: Text(conclave.requested
                      ? strings.pick('Requested', 'Aangevraagd')
                      : conclave.visibility == ConclaveVisibility.request
                          ? strings.pick('Request', 'Aanvragen')
                          : strings.pick('Join', 'Meedoen')),
                ),
              ],
            ),
            if (conclave.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(conclave.description),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConclaveHome extends StatelessWidget {
  const _ConclaveHome({required this.snapshot});

  final ConclaveSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final online = context.watch<OnlineAccountProvider>();
    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          if (online.errorCode != null || online.noticeCode != null)
            SliverToBoxAdapter(
              child: _ConclaveFeedback(online: online),
            ),
          SliverToBoxAdapter(child: _AerieHeader(snapshot: snapshot)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabHeaderDelegate(
              TabBar(
                tabs: [
                  Tab(text: strings.pick('Chat', 'Chat')),
                  Tab(text: strings.pick('Keepers', 'Hoeders')),
                  Tab(text: strings.pick('Chronicle', 'Chronicle')),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _ConclaveChat(snapshot: snapshot),
            _ConclaveMembers(snapshot: snapshot),
            _ConclaveChronicle(entries: snapshot.chronicle),
          ],
        ),
      ),
    );
  }
}

class _ConclaveFeedback extends StatelessWidget {
  const _ConclaveFeedback({required this.online});

  final OnlineAccountProvider online;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final error = online.errorCode;
    final code = error ?? online.noticeCode;
    if (code == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        color:
            error == null ? const Color(0xFFE9F7E8) : const Color(0xFFFFE8EB),
        child: ListTile(
          leading: Icon(
            error == null ? Icons.check_circle_rounded : Icons.error_rounded,
            color: error == null ? const Color(0xFF3D8A52) : Colors.redAccent,
          ),
          title: Text(
            socialMessage(strings, code, supportCode: online.supportCode),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          trailing: IconButton(
            tooltip: strings.pick('Dismiss', 'Sluiten'),
            onPressed: online.clearMessages,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ),
    );
  }
}

class _AerieHeader extends StatelessWidget {
  const _AerieHeader({required this.snapshot});
  final ConclaveSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final online = context.watch<OnlineAccountProvider>();
    final conclave = snapshot.conclave;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1238), Color(0xFF7652A5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 230,
                  child: Image.asset(
                    aerieStageAsset(conclave.aerieStage),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.castle_rounded,
                      color: Color(0xFFFFD978),
                      size: 130,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 30, 16, 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xDD1D1138)],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Emblem(keyName: conclave.emblemKey, size: 62),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conclave.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${strings.pick('Aerie stage', 'Aerie-fase')} ${conclave.aerieStage}/10 · ${conclave.memberCount}/${conclave.memberLimit}',
                              style: const TextStyle(
                                color: Color(0xFFE7DDFC),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${strings.pick('Level', 'Level')} ${conclave.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        conclave.level >= 50
                            ? 'MAX'
                            : '${conclave.xpIntoLevel}/${ConclaveSummary.xpPerLevel} XP',
                        style: const TextStyle(color: Color(0xFFE8DEF8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: conclave.level >= 50
                        ? 1
                        : conclave.xpIntoLevel / ConclaveSummary.xpPerLevel,
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(99),
                    color: const Color(0xFFFFD76A),
                    backgroundColor: Colors.white24,
                  ),
                  if (conclave.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(conclave.description,
                        style: const TextStyle(color: Color(0xFFE9E0F5))),
                  ],
                  const SizedBox(height: 11),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('tend-aerie-button'),
                      onPressed: online.busy || snapshot.contributedToday
                          ? null
                          : online.contributeToConclave,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD76A),
                        foregroundColor: AppColors.twilight,
                      ),
                      icon: Icon(snapshot.contributedToday
                          ? Icons.check_circle_rounded
                          : Icons.auto_awesome_rounded),
                      label: Text(snapshot.contributedToday
                          ? strings.pick(
                              'Aerie tended today',
                              'Aerie vandaag verzorgd',
                            )
                          : strings.pick(
                              'Tend the Aerie · +10 XP',
                              'Verzorg de Aerie · +10 XP',
                            )),
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

class _ConclaveChat extends StatefulWidget {
  const _ConclaveChat({required this.snapshot});
  final ConclaveSnapshot snapshot;

  @override
  State<_ConclaveChat> createState() => _ConclaveChatState();
}

class _ConclaveChatState extends State<_ConclaveChat> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    final sent =
        await context.read<OnlineAccountProvider>().sendConclaveMessage(
              kind: 'text',
              body: body,
            );
    if (sent) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final online = context.watch<OnlineAccountProvider>();
    final latest = online.conclave ?? widget.snapshot;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Text(
            strings.pick(
              'Messages remain available for 24 hours.',
              'Berichten blijven 24 uur beschikbaar.',
            ),
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: latest.messages.isEmpty
              ? Center(
                  child: Text(strings.pick(
                    'The Aerie is quiet. Start the conversation!',
                    'Het is stil in de Aerie. Begin het gesprek!',
                  )),
                )
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: latest.messages.length,
                  itemBuilder: (context, index) {
                    final message = latest.messages.reversed.elementAt(index);
                    return _ConclaveMessageTile(message: message);
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  key: const Key('share-to-conclave-button'),
                  tooltip: strings.pick('Share', 'Delen'),
                  onPressed: online.busy ? null : () => _share(context),
                  icon: const Icon(Icons.add_circle_rounded),
                ),
                Expanded(
                  child: TextField(
                    key: const Key('conclave-message-field'),
                    controller: _controller,
                    maxLength: 500,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: strings.pick(
                        'Message the Conclave…',
                        'Bericht aan de Conclave…',
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF2EDF7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 7),
                IconButton.filled(
                  key: const Key('send-conclave-message'),
                  onPressed: online.busy ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _share(BuildContext context) async {
    final strings = AppStrings.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.emoji_events_rounded),
              title: Text(
                  strings.pick('Latest achievement', 'Laatste achievement')),
              onTap: () => Navigator.pop(context, 'achievement'),
            ),
            ListTile(
              leading: const Icon(Icons.pets_rounded),
              title: Text(strings.pick('Favorite dragon', 'Favoriete draak')),
              onTap: () => Navigator.pop(context, 'dragon'),
            ),
            ListTile(
              leading: const Icon(Icons.sports_score_rounded),
              title: Text(strings.pick('Trial records', 'Trialrecords')),
              onTap: () => Navigator.pop(context, 'trial'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    final game = context.read<HouseholdProvider>();
    switch (choice) {
      case 'achievement':
        final ids = game.unlockedAchievementIds.toList();
        if (ids.isEmpty) return;
        await context.read<OnlineAccountProvider>().sendConclaveMessage(
          kind: 'achievement',
          body: strings.pick(
              'Achievement unlocked!', 'Achievement vrijgespeeld!'),
          payload: {'achievement_id': ids.last},
        );
      case 'dragon':
        final dragon = [game.pet, ...game.sanctuaryDragons]
            .where((candidate) => !candidate.isEgg)
            .cast<dynamic>()
            .firstWhere((candidate) => candidate.favorite, orElse: () => null);
        if (dragon == null) return;
        await context.read<OnlineAccountProvider>().sendConclaveMessage(
          kind: 'dragon',
          body: strings.pick(
            'Meet ${dragon.displayName}, my favorite dragon!',
            'Dit is ${dragon.displayName}, mijn favoriete draak!',
          ),
          payload: {'name': dragon.displayName, 'lineage_id': dragon.lineageId},
        );
      case 'trial':
        final dragons = [game.pet, ...game.sanctuaryDragons]
            .where((dragon) => !dragon.isEgg);
        int best(String key) => dragons.fold(
              0,
              (score, dragon) => score > (dragon.trialHighScores[key] ?? 0)
                  ? score
                  : dragon.trialHighScores[key] ?? 0,
            );
        await context.read<OnlineAccountProvider>().sendConclaveMessage(
          kind: 'trial',
          body: strings.pick(
              'My Keeper trial records', 'Mijn Keeper-trialrecords'),
          payload: {
            'might': best('ruinBreaker'),
            'arcana': best('runeweaver'),
            'spirit': best('cavernFlight'),
          },
        );
    }
  }
}

class _ConclaveMessageTile extends StatelessWidget {
  const _ConclaveMessageTile({required this.message});
  final ConclaveMessage message;

  @override
  Widget build(BuildContext context) {
    final mine =
        message.senderId == context.read<OnlineAccountProvider>().currentUserId;
    final icon = switch (message.kind) {
      'achievement' => Icons.emoji_events_rounded,
      'dragon' => Icons.pets_rounded,
      'trial' => Icons.sports_score_rounded,
      _ => null,
    };
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFE8DFFF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE1D8EA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon == null)
              KeeperPortrait(
                portraitKey: message.senderPortraitKey,
                displayName: message.senderName,
                radius: 18,
              )
            else
              CircleAvatar(
                backgroundColor: const Color(0xFFFFE39A),
                child: Icon(icon, color: AppColors.twilight),
              ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.senderName,
                      style: const TextStyle(
                          color: AppColors.twilight,
                          fontWeight: FontWeight.w900,
                          fontSize: 12)),
                  Text(message.body, style: const TextStyle(height: 1.28)),
                  if (message.kind == 'trial')
                    Text(
                      'M ${message.payload['might'] ?? 0} · A ${message.payload['arcana'] ?? 0} · S ${message.payload['spirit'] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
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

class _ConclaveMembers extends StatelessWidget {
  const _ConclaveMembers({required this.snapshot});
  final ConclaveSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final online = context.watch<OnlineAccountProvider>();
    final canModerate = snapshot.myRole != ConclaveRole.keeper;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
      children: [
        if (canModerate)
          FilledButton.icon(
            onPressed: online.busy ? null : () => _inviteKeeper(context),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(strings.pick(
                'Invite by Keeper ID', 'Uitnodigen via Keeper-ID')),
          ),
        if (snapshot.joinRequests.isNotEmpty) ...[
          _Title(strings.pick('Join requests', 'Deelnameverzoeken')),
          for (final request in snapshot.joinRequests)
            Card(
              child: ListTile(
                leading: KeeperPortrait(
                  portraitKey: request.portraitKey,
                  displayName: request.displayName,
                ),
                title: Text(request.displayName),
                subtitle: Text(request.keeperCode),
                trailing: Wrap(
                  children: [
                    IconButton(
                      onPressed: online.busy
                          ? null
                          : () => online.respondConclaveJoinRequest(
                              request.id, false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    IconButton.filled(
                      onPressed: online.busy
                          ? null
                          : () => online.respondConclaveJoinRequest(
                              request.id, true),
                      icon: const Icon(Icons.check_rounded),
                    ),
                  ],
                ),
              ),
            ),
        ],
        _Title(
            '${strings.pick('Keepers', 'Hoeders')} (${snapshot.members.length})'),
        for (final member in snapshot.members)
          Card(
            child: ListTile(
              leading: KeeperPortrait(
                portraitKey: member.portraitKey,
                displayName: member.displayName,
                frameKey: member.frameKey,
                badgeKey: member.badgeKey,
              ),
              title: Text(member.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(
                '${_roleLabel(strings, member.role)} · ${strings.pick('care streak', 'verzorgreeks')} ${member.contributionStreak}',
              ),
              trailing: canModerate && member.userId != online.currentUserId
                  ? IconButton(
                      onPressed: () => _memberActions(context, member),
                      icon: const Icon(Icons.more_vert_rounded),
                    )
                  : null,
            ),
          ),
        const SizedBox(height: 12),
        if (snapshot.myRole == ConclaveRole.flightmaster)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: online.busy ? null : () => _dissolve(context),
            icon: const Icon(Icons.delete_forever_rounded),
            label: Text(strings.pick('Dissolve Conclave', 'Conclave opheffen')),
          )
        else
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: online.busy ? null : online.leaveConclave,
            icon: const Icon(Icons.logout_rounded),
            label: Text(strings.pick('Leave Conclave', 'Conclave verlaten')),
          ),
      ],
    );
  }

  Future<void> _inviteKeeper(BuildContext context) async {
    final strings = AppStrings.of(context);
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.pick('Invite Keeper', 'Hoeder uitnodigen')),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Keeper ID'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(strings.pick('Invite', 'Uitnodigen'))),
        ],
      ),
    );
    controller.dispose();
    if (context.mounted && code != null && code.trim().isNotEmpty) {
      await context.read<OnlineAccountProvider>().inviteToConclave(code);
    }
  }

  Future<void> _memberActions(
      BuildContext context, ConclaveMember member) async {
    final strings = AppStrings.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (snapshot.myRole == ConclaveRole.flightmaster) ...[
              ListTile(
                leading: const Icon(Icons.shield_rounded),
                title: Text(member.role == ConclaveRole.warden
                    ? strings.pick('Make Keeper', 'Maak Hoeder')
                    : strings.pick('Make Warden', 'Maak Warden')),
                onTap: () => Navigator.pop(context, 'role'),
              ),
              ListTile(
                leading: const Icon(Icons.workspace_premium_rounded),
                title: Text(strings.pick(
                    'Transfer Flightmaster', 'Flightmaster overdragen')),
                onTap: () => Navigator.pop(context, 'transfer'),
              ),
            ],
            ListTile(
              leading: const Icon(Icons.person_remove_rounded,
                  color: Colors.redAccent),
              title: Text(strings.pick(
                  'Remove from Conclave', 'Uit Conclave verwijderen')),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    final online = context.read<OnlineAccountProvider>();
    switch (choice) {
      case 'role':
        await online.setConclaveMemberRole(
          member.userId,
          member.role == ConclaveRole.warden
              ? ConclaveRole.keeper
              : ConclaveRole.warden,
        );
      case 'transfer':
        await online.transferConclave(member.userId);
      case 'remove':
        await online.removeConclaveMember(member.userId);
    }
  }

  Future<void> _dissolve(BuildContext context) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title:
                Text(strings.pick('Dissolve Conclave?', 'Conclave opheffen?')),
            content: Text(strings.pick(
              'The Aerie, chat and Chronicle will be permanently removed.',
              'De Aerie, chat en Chronicle worden permanent verwijderd.',
            )),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(strings.tr('cancel'))),
              FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(context, true),
                child: Text(strings.pick('Dissolve', 'Opheffen')),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && context.mounted) {
      await context.read<OnlineAccountProvider>().dissolveConclave();
    }
  }
}

class _ConclaveChronicle extends StatelessWidget {
  const _ConclaveChronicle({required this.entries});
  final List<ConclaveChronicleEntry> entries;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (entries.isEmpty) {
      return Center(
          child: Text(strings.pick(
              'The Chronicle is still empty.', 'De Chronicle is nog leeg.')));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 34),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final icon = switch (entry.kind) {
          'level' => Icons.upgrade_rounded,
          'achievement' => Icons.emoji_events_rounded,
          'joined' => Icons.person_add_rounded,
          'left' => Icons.person_remove_rounded,
          'role' => Icons.shield_rounded,
          _ => Icons.auto_stories_rounded,
        };
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFE39A),
              child: Icon(icon, color: AppColors.twilight),
            ),
            title: Text(entry.body,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(
                entry.actorName ?? strings.pick('The Conclave', 'De Conclave')),
          ),
        );
      },
    );
  }
}

Future<bool> _showCreateConclave(BuildContext context) async {
  final strings = AppStrings.of(context);
  final name = TextEditingController();
  final description = TextEditingController();
  var emblem = 'conclave_emblem_01';
  var language = context.read<HouseholdProvider>().languageCode;
  var visibility = ConclaveVisibility.public;
  var limit = 20.0;
  final created = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title:
                Text(strings.pick('Found a Conclave', 'Sticht een Conclave')),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: const Key('conclave-name-field'),
                      controller: name,
                      maxLength: 30,
                      decoration: InputDecoration(
                        labelText: strings.pick('Name', 'Naam'),
                        helperText: strings.pick(
                          'Choose carefully: this unique Conclave name cannot be changed later.',
                          'Kies zorgvuldig: deze unieke Conclave-naam kan later niet worden gewijzigd.',
                        ),
                        helperMaxLines: 2,
                      ),
                    ),
                    TextField(
                      controller: description,
                      maxLength: 280,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                          labelText:
                              strings.pick('Description', 'Beschrijving')),
                    ),
                    Text(strings.pick('Emblem', 'Embleem'),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5),
                      itemCount: 20,
                      itemBuilder: (context, index) {
                        final key =
                            'conclave_emblem_${(index + 1).toString().padLeft(2, '0')}';
                        return InkWell(
                          onTap: () => setState(() => emblem = key),
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: emblem == key
                                  ? const Color(0xFFE8DFFF)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                  color: emblem == key
                                      ? AppColors.twilight
                                      : const Color(0xFFE0D8E8),
                                  width: 2),
                            ),
                            child: _Emblem(keyName: key, size: 48),
                          ),
                        );
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: language,
                      decoration: InputDecoration(
                          labelText: strings.pick('Language', 'Taal')),
                      items: [
                        for (final entry
                            in AppStrings.supportedLanguages.entries)
                          DropdownMenuItem(
                              value: entry.key, child: Text(entry.value)),
                      ],
                      onChanged: (value) =>
                          setState(() => language = value ?? 'en'),
                    ),
                    DropdownButtonFormField<ConclaveVisibility>(
                      initialValue: visibility,
                      decoration: InputDecoration(
                          labelText: strings.pick('Joining', 'Deelname')),
                      items: [
                        DropdownMenuItem(
                            value: ConclaveVisibility.public,
                            child: Text(strings.pick('Public', 'Openbaar'))),
                        DropdownMenuItem(
                            value: ConclaveVisibility.request,
                            child: Text(strings.pick(
                                'Request to Join', 'Deelname aanvragen'))),
                        DropdownMenuItem(
                            value: ConclaveVisibility.invite,
                            child: Text(strings.pick(
                                'Invite Only', 'Alleen op uitnodiging'))),
                      ],
                      onChanged: (value) => setState(() =>
                          visibility = value ?? ConclaveVisibility.public),
                    ),
                    const SizedBox(height: 10),
                    Text(
                        '${strings.pick('Maximum Keepers', 'Maximaal aantal Hoeders')}: ${limit.round()}'),
                    Slider(
                      value: limit,
                      min: 4,
                      max: 20,
                      divisions: 16,
                      label: '${limit.round()}',
                      onChanged: (value) => setState(() => limit = value),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(strings.tr('cancel'))),
              FilledButton(
                key: const Key('confirm-create-conclave'),
                onPressed: () async {
                  if (name.text.trim().length < 3) return;
                  final success = await context
                      .read<OnlineAccountProvider>()
                      .createConclave(
                        name: name.text,
                        emblemKey: emblem,
                        description: description.text,
                        language: language,
                        visibility: visibility,
                        memberLimit: limit.round(),
                      );
                  if (success && dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                },
                child: Text(strings.pick('Create', 'Maken')),
              ),
            ],
          ),
        ),
      ) ??
      false;
  name.dispose();
  description.dispose();
  return created;
}

class _Emblem extends StatelessWidget {
  const _Emblem({required this.keyName, required this.size});
  final String keyName;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        conclaveEmblemAsset(keyName),
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.shield_rounded,
          color: AppColors.gold,
          size: size * .78,
        ),
      );
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(3, 20, 3, 7),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      );
}

String _roleLabel(AppStrings strings, ConclaveRole role) => switch (role) {
      ConclaveRole.flightmaster => 'Flightmaster',
      ConclaveRole.warden => 'Warden',
      ConclaveRole.keeper => strings.pick('Keeper', 'Hoeder'),
    };

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TabHeaderDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Material(color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);
  @override
  bool shouldRebuild(_TabHeaderDelegate oldDelegate) => false;
}
