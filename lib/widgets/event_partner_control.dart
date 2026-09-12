import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_strings.dart';

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
    if (_busy) return;
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
      _error = e is StateError && e.message == 'sign_in' ? 'sign_in' : 'sync';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite() async {
    final s = AppStrings.of(context);
    final controller = TextEditingController();
    final code = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title:
                    Text(s.pick('Invite one friend', 'Nodig één vriend uit')),
                content: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                        labelText: s.pick(
                            'Friend’s Keeper code', 'Hoedercode van je vriend'),
                        hintText: 'DH-…')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.pick('Cancel', 'Annuleren'))),
                  FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, controller.text.trim()),
                      child: Text(s.pick('Invite', 'Uitnodigen')))
                ]));
    // The closing route may still animate with its TextField attached.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (mounted && code != null && code.isNotEmpty) {
      await _sync(action: 'invite', code: code);
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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (pair == null)
        TextButton.icon(
            onPressed: _busy ? null : _invite,
            icon: const Icon(Icons.favorite_outline, color: Colors.white),
            label: Text(
                s.pick('Invite one friend · combine your points',
                    'Nodig één vriend uit · verzamel samen punten'),
                style: const TextStyle(color: Colors.white)))
      else ...[
        Text(
            pair['status'] == 'accepted'
                ? s.pick('Collecting together with ${pair['partnerCode']}',
                    'Samen verzamelen met ${pair['partnerCode']}')
                : s.pick('Invitation · ${pair['partnerCode']}',
                    'Uitnodiging · ${pair['partnerCode']}'),
            style: const TextStyle(color: Colors.white)),
        if (pair['status'] == 'invited')
          Wrap(spacing: 8, children: [
            if (pair['incoming'] == true)
              FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _sync(action: 'accept', id: pair['id'] as String),
                  child: Text(s.pick('Accept', 'Accepteren'))),
            TextButton(
                onPressed: _busy
                    ? null
                    : () => _sync(
                        action: pair['incoming'] == true ? 'decline' : 'cancel',
                        id: pair['id'] as String),
                child: Text(
                    s.pick('Cancel invitation', 'Uitnodiging annuleren'),
                    style: const TextStyle(color: Colors.white))),
          ]),
      ],
      if (_error != null)
        Text(
            _error == 'sign_in'
                ? s.pick('Sign in to collect points with a friend.',
                    'Log in om samen met een vriend punten te verzamelen.')
                : s.pick(
                    'Could not sync the invitation. Check your connection and make sure you are friends.',
                    'De uitnodiging kon niet worden gesynchroniseerd. Controleer je verbinding en of jullie vrienden zijn.'),
            style: const TextStyle(color: Colors.white, fontSize: 12)),
    ]);
  }
}
