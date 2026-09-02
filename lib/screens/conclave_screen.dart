import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/achievement.dart';
import '../models/dragon_emote.dart';
import '../models/social.dart';
import '../providers/household_provider.dart';
import '../providers/online_account_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/online_account_access.dart';
import '../widgets/dragon_emote_picker.dart';

String conclaveEmblemAsset(String key) => 'assets/images/ui/conclave/$key.png';

String aerieStageAsset(int stage) =>
    'assets/images/ui/conclave/aerie_stage_${stage.toString().padLeft(2, '0')}.png';

AchievementDefinition? _achievementById(Object? rawId) {
  final id = rawId?.toString();
  if (id == null || id.isEmpty) return null;
  for (final achievement in achievementCatalog) {
    if (achievement.id == id) return achievement;
  }
  return null;
}

class _ConclaveMessageGroup {
  const _ConclaveMessageGroup(this.messages);

  final List<ConclaveMessage> messages;
}

List<_ConclaveMessageGroup> _groupConclaveMessages(
  List<ConclaveMessage> messages,
) {
  final ordered = List<ConclaveMessage>.of(messages)
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final groups = <_ConclaveMessageGroup>[];
  for (final message in ordered) {
    final previous = groups.isEmpty ? null : groups.last;
    final previousMessage = previous?.messages.last;
    final belongsToAchievementBatch = message.kind == 'achievement' &&
        previousMessage?.kind == 'achievement' &&
        previousMessage?.senderId == message.senderId &&
        message.createdAt.difference(previousMessage!.createdAt) <=
            const Duration(minutes: 2);
    if (belongsToAchievementBatch) {
      groups[groups.length - 1] = _ConclaveMessageGroup([
        ...previous!.messages,
        message,
      ]);
    } else {
      groups.add(_ConclaveMessageGroup([message]));
    }
  }
  return groups;
}

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
    final current = online.conclave?.conclave;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 2,
        title: Row(
          children: [
            if (current != null) ...[
              _Emblem(keyName: current.emblemKey, size: 38),
              const SizedBox(width: 9),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current?.name ?? strings.pick('Conclaves', 'Conclaves'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    current == null
                        ? strings.pick(
                            'Find your shared Aerie',
                            'Vind jullie gedeelde Aerie',
                          )
                        : '${strings.pick('Level', 'Level')} ${current.level}  •  ${current.memberCount}/${current.memberLimit}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: strings.pick('Refresh', 'Vernieuwen'),
            onPressed: online.busy
                ? null
                : () async {
                    await online.refresh();
                    await _loadDirectory();
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBF4), Color(0xFFF3ECFC)],
          ),
        ),
        child: RefreshIndicator(
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
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _ConclaveHeroPill(
                          icon: Icons.groups_rounded,
                          label: strings.pick(
                            'Up to 20 Keepers',
                            'Tot 20 Hoeders',
                          ),
                        ),
                        _ConclaveHeroPill(
                          icon: Icons.castle_rounded,
                          label: strings.pick(
                            '10 Aerie stages',
                            '10 Aerie-fases',
                          ),
                        ),
                      ],
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

class _ConclaveHeroPill extends StatelessWidget {
  const _ConclaveHeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFFFD978), size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

class _ConclaveStatusChip extends StatelessWidget {
  const _ConclaveStatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0E9FA),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.twilight, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.twilight,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
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
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white.withValues(alpha: .9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFDCD1E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF2ECFF), Color(0xFFFFF1C3)],
                    ),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: _Emblem(keyName: conclave.emblemKey, size: 54),
                ),
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
                _ConclaveStatusChip(
                  icon: conclave.visibility == ConclaveVisibility.public
                      ? Icons.public_rounded
                      : Icons.lock_outline_rounded,
                  label: conclave.visibility == ConclaveVisibility.public
                      ? strings.pick('Public', 'Openbaar')
                      : strings.pick('Request', 'Aanvraag'),
                ),
              ],
            ),
            if (conclave.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                conclave.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, height: 1.3),
              ),
            ],
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: online.busy || full || conclave.requested
                    ? null
                    : () async {
                        await online.requestOrJoinConclave(conclave.id);
                        await onReload();
                      },
                icon: Icon(full
                    ? Icons.group_off_rounded
                    : conclave.requested
                        ? Icons.schedule_rounded
                        : Icons.flight_takeoff_rounded),
                label: Text(full
                    ? strings.pick('Conclave is full', 'Conclave is vol')
                    : conclave.requested
                        ? strings.pick('Request pending', 'Aanvraag loopt')
                        : conclave.visibility == ConclaveVisibility.request
                            ? strings.pick(
                                'Request to join',
                                'Deelname aanvragen',
                              )
                            : strings.pick(
                                'Join this Conclave',
                                'Word lid van deze Conclave',
                              )),
              ),
            ),
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
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F2F1B54),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.twilightDark,
                unselectedLabelColor: AppColors.muted,
                labelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
                tabs: [
                  _ConclaveTab(
                    icon: Icons.forum_rounded,
                    label: strings.pick('Chat', 'Chat'),
                  ),
                  _ConclaveTab(
                    icon: Icons.groups_rounded,
                    label: strings.pick('Keepers', 'Hoeders'),
                    badgeCount: snapshot.joinRequests.length,
                  ),
                  _ConclaveTab(
                    icon: Icons.auto_stories_rounded,
                    label: strings.pick('Chronicle', 'Chronicle'),
                  ),
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
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1238), Color(0xFF7652A5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0x55FFD978)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3D2B174E),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 176,
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
                const Positioned(
                  top: 15,
                  right: 22,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xB3FFD978),
                    size: 24,
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
                      _Emblem(keyName: conclave.emblemKey, size: 56),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conclave.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
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
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFFFD76A),
                        size: 18,
                      ),
                      const SizedBox(width: 5),
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
  final _scrollController = ScrollController();
  String? _latestMessageId;
  bool _nearBottom = true;
  bool _scrollScheduled = false;
  bool _automaticScroll = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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
    if (sent) {
      _controller.clear();
      _nearBottom = true;
      _scrollToBottom();
    }
  }

  Future<void> _sendEmote() async {
    final game = context.read<HouseholdProvider>();
    final emote = await showDragonEmotePicker(context, game.ownedDragonEmotes);
    if (!mounted || emote == null || !game.ownsDragonEmote(emote.id)) return;
    final sent =
        await context.read<OnlineAccountProvider>().sendConclaveMessage(
      kind: 'emote',
      body: emote.label(game.languageCode),
      payload: {'emote_id': emote.id},
    );
    if (!mounted || !sent) return;
    _nearBottom = true;
    _scrollToBottom();
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (!animate) {
        _scrollController.jumpTo(target);
        return;
      }
      _automaticScroll = true;
      unawaited(
        _scrollController
            .animateTo(
              target,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
            )
            .whenComplete(() => _automaticScroll = false),
      );
    });
  }

  bool _trackScroll(ScrollNotification notification) {
    if (_automaticScroll || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final nextNearBottom =
        notification.metrics.maxScrollExtent - notification.metrics.pixels < 72;
    if (nextNearBottom != _nearBottom && mounted) {
      setState(() => _nearBottom = nextNearBottom);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final online = context.watch<OnlineAccountProvider>();
    final latest = online.conclave ?? widget.snapshot;
    final messageGroups = _groupConclaveMessages(latest.messages);
    final latestMessageId =
        messageGroups.isEmpty ? null : messageGroups.last.messages.last.id;
    if (latestMessageId != _latestMessageId) {
      final followNewest = _latestMessageId == null || _nearBottom;
      _latestMessageId = latestMessageId;
      if (followNewest) {
        _scrollToBottom(animate: messageGroups.length > 1);
      }
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 3),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEAE2F4),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.twilight,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    strings.pick(
                      'Messages stay for 24 hours',
                      'Berichten blijven 24 uur',
                    ),
                    style: const TextStyle(
                      color: AppColors.twilight,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: messageGroups.isEmpty
              ? _ConclaveEmptyState(
                  icon: Icons.forum_rounded,
                  title: strings.pick('The Aerie is quiet', 'De Aerie is stil'),
                  body: strings.pick(
                    'Start the first conversation with your fellow Keepers.',
                    'Begin het eerste gesprek met je mede-Hoeders.',
                  ),
                )
              : Stack(
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: _trackScroll,
                      child: Scrollbar(
                        controller: _scrollController,
                        child: ListView.builder(
                          key: const Key('conclave-chat-list'),
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          itemCount: messageGroups.length,
                          itemBuilder: (context, index) {
                            final group = messageGroups[index];
                            return _ConclaveMessageTile(
                              key: ValueKey(group.messages.first.id),
                              messages: group.messages,
                            );
                          },
                        ),
                      ),
                    ),
                    if (!_nearBottom)
                      Positioned(
                        right: 14,
                        bottom: 10,
                        child: IconButton.filledTonal(
                          key: const Key('conclave-scroll-to-newest'),
                          tooltip: strings.pick(
                            'Newest messages',
                            'Nieuwste berichten',
                          ),
                          onPressed: () {
                            setState(() => _nearBottom = true);
                            _scrollToBottom();
                          },
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                      ),
                  ],
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFDCCFE9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A2E1B50),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    key: const Key('share-to-conclave-button'),
                    tooltip: strings.pick('Share', 'Delen'),
                    onPressed: online.busy ? null : () => _share(context),
                    icon: const Icon(Icons.add_circle_rounded),
                  ),
                  IconButton(
                    key: const Key('conclave-emote-picker'),
                    tooltip: strings.pick('Dragon emotes', 'Drakenemotes'),
                    onPressed: online.busy ? null : _sendEmote,
                    icon: const Icon(Icons.emoji_emotions_rounded),
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
  const _ConclaveMessageTile({
    super.key,
    required this.messages,
  });

  final List<ConclaveMessage> messages;

  @override
  Widget build(BuildContext context) {
    final message = messages.first;
    if (messages.every((candidate) => candidate.kind == 'achievement')) {
      return _ConclaveAchievementMessageTile(messages: messages);
    }
    final emote = message.kind == 'emote'
        ? dragonEmoteById(message.payload['emote_id']?.toString())
        : null;
    if (emote != null) {
      return _ConclaveEmoteMessageTile(message: message, emote: emote);
    }
    final mine =
        message.senderId == context.read<OnlineAccountProvider>().currentUserId;
    final icon = switch (message.kind) {
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.senderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.twilight,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ConclaveMessageTime(message: message),
                    ],
                  ),
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

class _ConclaveEmoteMessageTile extends StatelessWidget {
  const _ConclaveEmoteMessageTile({
    required this.message,
    required this.emote,
  });

  final ConclaveMessage message;
  final DragonEmoteDefinition emote;

  @override
  Widget build(BuildContext context) {
    final mine =
        message.senderId == context.read<OnlineAccountProvider>().currentUserId;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: Key('conclave-emote-${message.id}'),
        constraints: const BoxConstraints(maxWidth: 210),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 7),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFE8DFFF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE1D8EA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            KeeperPortrait(
              portraitKey: message.senderPortraitKey,
              displayName: message.senderName,
              radius: 16,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.senderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.twilight,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _ConclaveMessageTime(message: message),
                    ],
                  ),
                  DragonEmoteSprite(emote: emote, size: 112),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConclaveAchievementMessageTile extends StatefulWidget {
  const _ConclaveAchievementMessageTile({required this.messages});

  final List<ConclaveMessage> messages;

  @override
  State<_ConclaveAchievementMessageTile> createState() =>
      _ConclaveAchievementMessageTileState();
}

class _ConclaveAchievementMessageTileState
    extends State<_ConclaveAchievementMessageTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final firstMessage = widget.messages.first;
    final mine = firstMessage.senderId ==
        context.read<OnlineAccountProvider>().currentUserId;
    final isBatch = widget.messages.length > 1;
    final visibleCount = _expanded || !isBatch
        ? widget.messages.length
        : widget.messages.length < 3
            ? widget.messages.length
            : 3;
    final hiddenCount = widget.messages.length - visibleCount;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: Key('conclave-achievement-group-${firstMessage.id}'),
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: mine
                ? const [Color(0xFFF0E8FF), Color(0xFFFFF5D6)]
                : const [Colors.white, Color(0xFFFFF4D1)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2C66C), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F513675),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                KeeperPortrait(
                  portraitKey: firstMessage.senderPortraitKey,
                  displayName: firstMessage.senderName,
                  radius: 16,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstMessage.senderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.twilight,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        isBatch
                            ? strings.pick(
                                '${widget.messages.length} achievements shared',
                                '${widget.messages.length} achievements gedeeld',
                              )
                            : strings.pick(
                                'Achievement unlocked',
                                'Achievement vrijgespeeld',
                              ),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFD09A18),
                  size: 21,
                ),
              ],
            ),
            const SizedBox(height: 9),
            for (var index = 0; index < visibleCount; index++) ...[
              _ConclaveAchievementRow(
                message: widget.messages[index],
                showDescription: !isBatch,
              ),
              if (index + 1 < visibleCount) const SizedBox(height: 7),
            ],
            if (isBatch) ...[
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('toggle-conclave-achievement-batch'),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _expanded
                        ? strings.pick('Show less', 'Minder tonen')
                        : strings.pick(
                            'Show $hiddenCount more',
                            'Toon er nog $hiddenCount',
                          ),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConclaveAchievementRow extends StatelessWidget {
  const _ConclaveAchievementRow({
    required this.message,
    required this.showDescription,
  });

  final ConclaveMessage message;
  final bool showDescription;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final achievement = _achievementById(message.payload['achievement_id']);
    final title = achievement == null
        ? message.body
        : strings.achievementTitle(achievement);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0x40D09A18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ConclaveAchievementBadge(achievement: achievement),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.twilight,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      height: 1.15,
                    ),
                  ),
                  if (showDescription && achievement != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      strings.achievementDescription(achievement),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 7),
            _ConclaveMessageTime(message: message),
          ],
        ),
      ),
    );
  }
}

class _ConclaveMessageTime extends StatelessWidget {
  const _ConclaveMessageTime({required this.message});

  final ConclaveMessage message;

  @override
  Widget build(BuildContext context) => Text(
        TimeOfDay.fromDateTime(message.createdAt.toLocal()).format(context),
        key: Key('conclave-message-time-${message.id}'),
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _ConclaveAchievementBadge extends StatelessWidget {
  const _ConclaveAchievementBadge({required this.achievement});

  final AchievementDefinition? achievement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 43,
      height: 43,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7A3),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD09A18), width: 1.3),
      ),
      child: achievement == null
          ? const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.twilight,
              size: 25,
            )
          : Image.asset(
              achievement!.badgeAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.twilight,
                size: 25,
              ),
            ),
    );
  }
}

class _ConclaveMembers extends StatelessWidget {
  const _ConclaveMembers({required this.snapshot});
  final ConclaveSnapshot snapshot;

  bool _canInviteFriend(
    OnlineAccountProvider online,
    ConclaveMember member,
  ) =>
      member.userId != online.currentUserId &&
      member.keeperCode.trim().isNotEmpty &&
      !online.friends.any((friend) => friend.userId == member.userId) &&
      !online.requests.any((request) => request.keeper.userId == member.userId);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final online = context.watch<OnlineAccountProvider>();
    final canModerate = snapshot.myRole != ConclaveRole.keeper;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF302050), Color(0xFF7652A5)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFFFFE39A),
                child: Icon(
                  Icons.groups_rounded,
                  color: AppColors.twilightDark,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.pick('Conclave Keepers', 'Conclave-Hoeders'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${snapshot.members.length}/${snapshot.conclave.memberLimit}  •  ${strings.pick('Your rank', 'Jouw rang')}: ${_roleLabel(strings, snapshot.myRole)}',
                      style: const TextStyle(
                        color: Color(0xFFE9DFF6),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (canModerate)
          OutlinedButton.icon(
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
          _buildMemberCard(context, strings, online, member, canModerate),
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

  Widget _buildMemberCard(
    BuildContext context,
    AppStrings strings,
    OnlineAccountProvider online,
    ConclaveMember member,
    bool canModerate,
  ) {
    final canManageMember =
        canModerate && member.userId != online.currentUserId;
    final canInviteFriend = _canInviteFriend(online, member);
    return _ConclaveMemberCard(
      member: member,
      isCurrentKeeper: member.userId == online.currentUserId,
      roleLabel: _roleLabel(strings, member.role),
      streakLabel: strings.pick('care streak', 'verzorgreeks'),
      actionsTooltip: strings.pick('Keeper actions', 'Hoederacties'),
      onActions: canManageMember || canInviteFriend
          ? () => _memberActions(
                context,
                member,
                canManageMember: canManageMember,
                canInviteFriend: canInviteFriend,
              )
          : null,
      actionsEnabled: !online.busy,
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
    BuildContext context,
    ConclaveMember member, {
    required bool canManageMember,
    required bool canInviteFriend,
  }) async {
    final strings = AppStrings.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canInviteFriend)
              ListTile(
                key: Key('invite-conclave-member-${member.userId}'),
                leading: const Icon(Icons.person_add_alt_1_rounded),
                title: Text(
                    strings.pick('Invite as friend', 'Uitnodigen als vriend')),
                onTap: () => Navigator.pop(context, 'friend'),
              ),
            if (canManageMember &&
                snapshot.myRole == ConclaveRole.flightmaster) ...[
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
            if (canManageMember)
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
      case 'friend':
        await online.sendFriendRequest(member.keeperCode);
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

class _ConclaveMemberCard extends StatelessWidget {
  const _ConclaveMemberCard({
    required this.member,
    required this.isCurrentKeeper,
    required this.roleLabel,
    required this.streakLabel,
    required this.actionsTooltip,
    required this.onActions,
    required this.actionsEnabled,
  });

  static const double avatarSlotSize = 86;
  static const double portraitRadius = 27;

  final ConclaveMember member;
  final bool isCurrentKeeper;
  final String roleLabel;
  final String streakLabel;
  final String actionsTooltip;
  final VoidCallback? onActions;
  final bool actionsEnabled;

  @override
  Widget build(BuildContext context) => Card.outlined(
        key: Key('conclave-member-${member.userId}'),
        margin: const EdgeInsets.only(bottom: 8),
        color: Colors.white.withValues(alpha: .92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isCurrentKeeper
                ? const Color(0xFFBFA5E7)
                : const Color(0xFFE0D8E8),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 6, 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox.square(
                key: Key('conclave-member-avatar-slot-${member.userId}'),
                dimension: avatarSlotSize,
                child: Center(
                  child: KeeperPortrait(
                    portraitKey: member.portraitKey,
                    displayName: member.displayName,
                    radius: portraitRadius,
                    frameKey: member.frameKey,
                    badgeKey: member.badgeKey,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayName,
                      key: Key('conclave-member-name-${member.userId}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MemberRoleChip(
                          role: member.role,
                          label: roleLabel,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2D8),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: Color(0xFFE4913B),
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$streakLabel ${member.contributionStreak}',
                                style: const TextStyle(
                                  color: Color(0xFF78552D),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onActions != null) ...[
                const SizedBox(width: 3),
                SizedBox.square(
                  dimension: 40,
                  child: IconButton(
                    key: Key('conclave-member-actions-${member.userId}'),
                    tooltip: actionsTooltip,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: actionsEnabled ? onActions : null,
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                ),
              ] else
                const SizedBox(width: 4),
            ],
          ),
        ),
      );
}

class _ConclaveEmptyState extends StatelessWidget {
  const _ConclaveEmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 330),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFFFF4D3)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFE2D6B4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFFFE39A),
                  child: Icon(icon, color: AppColors.twilight, size: 32),
                ),
                const SizedBox(height: 13),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ConclaveChronicle extends StatelessWidget {
  const _ConclaveChronicle({required this.entries});
  final List<ConclaveChronicleEntry> entries;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (entries.isEmpty) {
      return _ConclaveEmptyState(
        icon: Icons.auto_stories_rounded,
        title: strings.pick(
          'A new Chronicle',
          'Een nieuwe Chronicle',
        ),
        body: strings.pick(
          'Milestones, new Keepers and shared achievements will be recorded here.',
          'Mijlpalen, nieuwe Hoeders en gedeelde achievements worden hier bewaard.',
        ),
      );
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
        final isLast = index == entries.length - 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                height: 88,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (!isLast)
                      Positioned(
                        top: 40,
                        bottom: -12,
                        child: Container(
                          width: 2,
                          color: const Color(0xFFD8CBE8),
                        ),
                      ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFFFE39A),
                      child: Icon(
                        icon,
                        color: AppColors.twilight,
                        size: 21,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Card.outlined(
                  color: Colors.white.withValues(alpha: .92),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0xFFE0D8E8)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.body,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          entry.actorName ??
                              strings.pick('The Conclave', 'De Conclave'),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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

class _MemberRoleChip extends StatelessWidget {
  const _MemberRoleChip({required this.role, required this.label});

  final ConclaveRole role;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      ConclaveRole.flightmaster => const Color(0xFFD59A17),
      ConclaveRole.warden => AppColors.twilight,
      ConclaveRole.keeper => const Color(0xFF4E8C78),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ConclaveTab extends StatelessWidget {
  const _ConclaveTab({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final int badgeCount;

  @override
  Widget build(BuildContext context) => Tab(
        height: 42,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge.count(
              count: badgeCount,
              isLabelVisible: badgeCount > 0,
              backgroundColor: Colors.redAccent,
              child: Icon(icon, size: 18),
            ),
            const SizedBox(height: 1),
            FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
          ],
        ),
      );
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TabHeaderDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => 62;
  @override
  double get maxExtent => 62;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 4, 14, 6),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFE9E1F4),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: const Color(0xFFD8CBE8)),
          ),
          child: tabBar,
        ),
      );
  @override
  bool shouldRebuild(_TabHeaderDelegate oldDelegate) => false;
}
