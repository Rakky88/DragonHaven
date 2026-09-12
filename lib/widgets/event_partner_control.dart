import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_strings.dart';
import 'package:provider/provider.dart';
import '../models/social.dart';
import '../providers/online_account_provider.dart';
import 'online_account_access.dart';

/// The server owns invitations and the accepted two-keeper membership.
class EventPartnerControl extends StatefulWidget {
  const EventPartnerControl(
      {super.key,
      required this.eventKey,
      required this.beforeSync,
      required this.applyShared,
      this.showControls = true});
  final String eventKey;
  final bool showControls;
  final Future<bool> Function() beforeSync;
  final Future<void> Function(Map<String, dynamic>, String) applyShared;
  @override
  State<EventPartnerControl> createState() => _EventPartnerControlState();
}

class _EventPartnerControlState extends State<EventPartnerControl> {
  Timer? _timer;
  List<Map<String, dynamic>> _pairs = [];
  bool _busy = false;
  String? _pairsOwner;
  String? _error;
  Completer<void>? _idle;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_sync());
    });
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent != false) {
        unawaited(_sync());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sync({String action = 'list', String? code, String? id}) async {
    while (_busy) {
      if (action == 'list') return;
      await _idle?.future;
      if (!mounted) return;
    }
    _idle = Completer<void>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      final owner = client.auth.currentUser?.id;
      if (_pairsOwner != owner) {
        _pairs = [];
        _pairsOwner = owner;
      }
      if (owner == null) {
        throw StateError('sign_in');
      }
      if (action != 'cancel' &&
          action != 'decline' &&
          !await widget.beforeSync()) {
        if (action == 'list') return;
        throw StateError('sync');
      }
      if (!mounted || client.auth.currentUser?.id != owner) return;
      final raw = await client.rpc('event_point_partner', params: {
        'p_action': action,
        'p_event_key': widget.eventKey,
        'p_keeper_code': code,
        'p_pair_id': id,
      });
      if (!mounted || client.auth.currentUser?.id != owner) return;
      final value = Map<String, dynamic>.from(raw as Map);
      await widget.applyShared(
          Map<String, dynamic>.from(value['shared'] as Map), owner);
      if (!mounted || client.auth.currentUser?.id != owner) return;
      _pairs = [
        for (final p in value['pairs'] as List)
          if (p['eventKey'] == widget.eventKey)
            Map<String, dynamic>.from(p as Map)
      ];
    } on Object catch (e) {
      if (!mounted) return;
      if (action != 'list') {
        _error = e is StateError && e.message == 'sign_in' ? 'sign_in' : 'sync';
        final s = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_error == 'sign_in'
                ? s.pick('Sign in to invite a friend.',
                    'Log in om een vriend uit te nodigen.')
                : s.pick(
                    'Invitation could not be saved. Let syncing finish and try again.',
                    'De uitnodiging kon niet worden opgeslagen. Laat synchroniseren afronden en probeer opnieuw.'))));
      }
    } finally {
      _idle?.complete();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite() async {
    final online = context.read<OnlineAccountProvider?>();
    final refresh = online?.refreshIfStale();
    final friend = await showModalBottomSheet<KeeperProfile>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => EventFriendPicker(online: online));
    if (mounted && friend != null) {
      if (refresh != null) await refresh;
      if (!mounted) return;
      await _sync(action: 'invite', code: friend.keeperCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showControls) return const SizedBox.shrink();
    final s = AppStrings.of(context);
    String? currentOwner;
    try {
      currentOwner = Supabase.instance.client.auth.currentUser?.id;
    } on Object {/* Offline installation. */}
    final pair = currentOwner == _pairsOwner ? _pairs.firstOrNull : null;
    final friends = context.watch<OnlineAccountProvider?>()?.friends ??
        const <KeeperProfile>[];
    final friend =
        friends.where((f) => f.keeperCode == pair?['partnerCode']).firstOrNull;
    final name = friend?.displayName ?? s.pick('your friend', 'je vriend');
    return Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          TextButton.icon(
              key: const Key('event-invite-friend'),
              style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(48, 48),
                  textStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
              onPressed: pair == null ? _invite : null,
              icon: Icon(
                  pair?['status'] == 'accepted'
                      ? Icons.favorite
                      : Icons.person_add_alt_1,
                  size: 16,
                  color: Colors.white70),
              label: Text(
                  pair == null
                      ? s.pick('Invite a friend', 'Nodig een vriend uit')
                      : pair['status'] == 'accepted'
                          ? s.pick('Together with $name', 'Samen met $name')
                          : s.pick('Invitation ? $name', 'Uitnodiging ? $name'),
                  style: const TextStyle(color: Colors.white))),
          if (pair?['status'] == 'invited') ...[
            if (pair?['incoming'] == true)
              TextButton(
                  onPressed: _busy
                      ? null
                      : () =>
                          _sync(action: 'accept', id: pair!['id'] as String),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: Text(s.pick('Accept', 'Accepteren'))),
            IconButton(
                tooltip: s.pick('Cancel invitation', 'Uitnodiging annuleren'),
                onPressed: _busy
                    ? null
                    : () => _sync(
                        action:
                            pair?['incoming'] == true ? 'decline' : 'cancel',
                        id: pair!['id'] as String),
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: Colors.white70)),
          ],
        ]);
  }
}

/// Opens directly on existing friends; Keeper codes stay an RPC detail.
class EventFriendPicker extends StatelessWidget {
  const EventFriendPicker({super.key, this.online, this.friends = const []});
  final OnlineAccountProvider? online;
  final List<KeeperProfile> friends;
  @override
  Widget build(BuildContext context) => online == null
      ? _content(context, friends)
      : ListenableBuilder(
          listenable: online!,
          builder: (context, _) => _content(context, online!.friends));
  Widget _content(BuildContext context, List<KeeperProfile> source) {
    final s = AppStrings.of(context);
    final sorted = [...source]..sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return SizedBox(
        height: MediaQuery.sizeOf(context).height * .6,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.pick('Choose a friend', 'Kies een vriend'),
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(s.pick(
                        'Combine your event points and each earn a chest.',
                        'Verzamel samen eventpunten en verdien allebei een kist.'))
                  ])),
          if (sorted.isEmpty)
            Padding(
                padding: const EdgeInsets.all(20),
                child: Text(s.pick(
                    'Your friends will appear here. Add a friend in Friends first.',
                    'Je vrienden verschijnen hier. Voeg eerst een vriend toe via Friends.'))),
          Expanded(
              child: ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final f = sorted[index];
                    return ListTile(
                        key: Key('event-friend-${f.userId}'),
                        leading: KeeperPortrait(
                            portraitKey: f.portraitKey,
                            displayName: f.displayName,
                            frameKey: f.frameKey,
                            badgeKey: f.badgeKey,
                            radius: 20),
                        title: Text(f.displayName),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => Navigator.pop(context, f));
                  })),
        ]));
  }
}
