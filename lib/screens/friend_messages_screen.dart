import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/social.dart';
import '../models/dragon_emote.dart';
import '../providers/household_provider.dart';
import '../providers/online_account_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/online_account_access.dart';
import '../widgets/dragon_emote_picker.dart';

class FriendMessagesScreen extends StatefulWidget {
  const FriendMessagesScreen({super.key, required this.friend});

  final KeeperProfile friend;

  @override
  State<FriendMessagesScreen> createState() => _FriendMessagesScreenState();
}

class _FriendMessagesScreenState extends State<FriendMessagesScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<FriendMessage> _messages = const [];
  bool _loading = true;
  bool _loadInFlight = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) unawaited(_load(background: true));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool background = false}) async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    final messages = await context
        .read<OnlineAccountProvider>()
        .openFriendMessages(widget.friend.userId, background: background);
    _loadInFlight = false;
    if (!mounted) return;
    setState(() {
      if (messages != null) _messages = messages;
      _loading = false;
    });
    _scrollToEnd();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    FocusScope.of(context).unfocus();
    final sent = await context
        .read<OnlineAccountProvider>()
        .sendFriendMessage(widget.friend.userId, body);
    if (!mounted || !sent) return;
    _controller.clear();
    await _load();
  }

  Future<void> _sendEmote() async {
    final game = context.read<HouseholdProvider>();
    final emote = await showDragonEmotePicker(context, game.ownedDragonEmotes);
    if (!mounted || emote == null || !game.ownsDragonEmote(emote.id)) return;
    final sent = await context.read<OnlineAccountProvider>().sendFriendMessage(
      widget.friend.userId,
      emote.label(game.languageCode),
      kind: 'emote',
      payload: {'emote_id': emote.id},
    );
    if (!mounted || !sent) return;
    await _load();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final online = context.watch<OnlineAccountProvider>();
    final conversation = online.conversationWith(widget.friend.userId);
    final available =
        online.friendMessagesAllowed && (conversation?.messagesAllowed ?? true);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            KeeperPortrait(
              portraitKey: widget.friend.portraitKey,
              displayName: widget.friend.displayName,
              frameKey: widget.friend.frameKey,
              badgeKey: widget.friend.badgeKey,
              radius: 19,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.friend.displayName)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFFFF2CC),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              strings.pick(
                'Private messages disappear after 24 hours.',
                'Privéberichten verdwijnen na 24 uur.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.twilight,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Text(
                            strings.pick(
                              'No messages yet. Say hello!',
                              'Nog geen berichten. Zeg hallo!',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final mine = message.senderId == online.currentUserId;
                          return _MessageBubble(message: message, mine: mine);
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE7E0EE))),
              ),
              child: available
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          key: const Key('friend-message-emote-picker'),
                          tooltip: strings.pick(
                            'Dragon emotes',
                            'Drakenemotes',
                          ),
                          onPressed: online.busy ? null : _sendEmote,
                          icon: const Icon(Icons.emoji_emotions_rounded),
                        ),
                        Expanded(
                          child: TextField(
                            key: const Key('friend-message-field'),
                            controller: _controller,
                            enabled: !online.busy,
                            maxLength: 500,
                            minLines: 1,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: strings.pick(
                                'Write a message…',
                                'Schrijf een bericht…',
                              ),
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFFF5F1FA),
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
                          key: const Key('send-friend-message'),
                          onPressed: online.busy ? null : _send,
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ],
                    )
                  : Text(
                      online.friendMessagesAllowed
                          ? strings.pick(
                              '${widget.friend.displayName} is not accepting messages.',
                              '${widget.friend.displayName} accepteert geen berichten.',
                            )
                          : strings.pick(
                              'Enable friend messages in Account Info to chat.',
                              'Sta berichten toe bij Account Info om te chatten.',
                            ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final FriendMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final emote = message.kind == 'emote'
        ? dragonEmoteById(message.payload['emote_id']?.toString())
        : null;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 7),
        padding: EdgeInsets.fromLTRB(
          emote == null ? 14 : 8,
          emote == null ? 10 : 6,
          emote == null ? 14 : 8,
          8,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.twilight : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(19),
            topRight: const Radius.circular(19),
            bottomLeft: Radius.circular(mine ? 19 : 5),
            bottomRight: Radius.circular(mine ? 5 : 19),
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x18000000), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: emote == null
                  ? Text(
                      message.body,
                      style: TextStyle(
                        color: mine ? Colors.white : AppColors.ink,
                        height: 1.3,
                      ),
                    )
                  : DragonEmoteSprite(emote: emote, size: 116),
            ),
            const SizedBox(height: 4),
            Text(
              TimeOfDay.fromDateTime(message.createdAt.toLocal())
                  .format(context),
              style: TextStyle(
                color: mine ? Colors.white70 : AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
