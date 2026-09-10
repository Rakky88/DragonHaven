import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/canonical_beacon.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import 'shop_economy_scope.dart';
import '../providers/household_provider.dart';
import '../screens/egg_altar_screen.dart';

class WeaveBeaconCard extends StatefulWidget {
  const WeaveBeaconCard(
      {super.key, required this.conclaveId, required this.active});
  final String conclaveId;
  final bool active;
  @override
  State<WeaveBeaconCard> createState() => _WeaveBeaconCardState();
}

class _WeaveBeaconCardState extends State<WeaveBeaconCard> {
  int? _fragments;
  bool _loading = false;
  bool _failed = false;
  Timer? _timer;
  int _readGeneration = 0;
  String? _owner;
  int _epoch = 0;

  (String?, int) get _account {
    final server = context.read<CanonicalGameSession?>();
    return server != null
        ? (server.connection.currentOwner, server.connection.sessionEpoch)
        : (context.read<HouseholdProvider>().altarCurrentUserId?.call(), 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final account = _account;
    if (_owner != account.$1 || _epoch != account.$2) {
      _owner = account.$1;
      _epoch = account.$2;
      _readGeneration++;
      _loading = false;
      _failed = false;
      _fragments = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (widget.active) _refresh();
    });
  }

  @override
  void didUpdateWidget(WeaveBeaconCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conclaveId != widget.conclaveId) {
      _fragments = null;
      _failed = false;
      _readGeneration++;
      _loading = false;
    }
    if (widget.active &&
        (!oldWidget.active || oldWidget.conclaveId != widget.conclaveId)) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted || _loading) return;
    final server = context.read<CanonicalGameSession?>();
    final canonicalSource = context.read<CanonicalBeaconSource?>();
    final legacyLoad = server == null
        ? context.read<HouseholdProvider>().loadWeaveBeacon
        : null;
    final account = _account;
    if (server != null && (canonicalSource == null || account.$1 == null) ||
        server == null && legacyLoad == null) {
      return;
    }
    _loading = true;
    final generation = ++_readGeneration;
    final id = widget.conclaveId;
    bool current() =>
        mounted &&
        generation == _readGeneration &&
        id == widget.conclaveId &&
        account == _account;
    try {
      final amount = server != null
          ? await canonicalSource!.load(account.$1!, id)
          : ((await legacyLoad!(id))['fragments'] as num).toInt();
      if (current()) {
        setState(() {
          _fragments = amount;
          _failed = false;
        });
      }
    } on Object {
      if (current()) {
        setState(() {
          _failed = true;
          _fragments = null;
        });
      }
    } finally {
      if (mounted && generation == _readGeneration) _loading = false;
    }
  }

  Future<void> _donate() async {
    final server = context.read<CanonicalGameSession?>();
    final game = server == null ? context.read<HouseholdProvider>() : null;
    final actions = server == null ? null : CanonicalGameActions(server);
    final account = _account;
    final conclave = widget.conclaveId;
    final s = AppStrings.of(context);
    final available = server?.snapshot?.inventory.materials.fragments ??
        game?.eggAltar.wallet.fragments ??
        0;
    final maxAmount = min(available, 5000 - (_fragments ?? 0));
    if (maxAmount < 1 ||
        _fragments == null ||
        (server != null && !server.canAct)) {
      return;
    }
    final controller =
        TextEditingController(text: min(25, maxAmount).toString());
    final amount = await showDialog<int>(
        context: context,
        builder: (c) => AlertDialog(
                scrollable: true,
                title: Text(s.pick(
                    'Donate Shell Fragments', 'Shell Fragments schenken')),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(s.pick(
                      'A voluntary gift to your Conclave’s cosmetic Beacon. Donations cannot be taken back.',
                      'Een vrijwillige gift voor de cosmetische Beacon van je Conclave. Giften kunnen niet worden teruggenomen.')),
                  TextField(
                      key: const Key('beacon-donation-amount'),
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(helperText: '1–$maxAmount')),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text(s.pick('Cancel', 'Annuleren'))),
                  FilledButton(
                      key: const Key('confirm-beacon-donation'),
                      onPressed: () {
                        final value = int.tryParse(controller.text);
                        if (value != null && value > 0 && value <= maxAmount) {
                          Navigator.pop(c, value);
                        }
                      },
                      child: Text(s.pick('Donate', 'Schenken')))
                ]));
    await WidgetsBinding.instance.endOfFrame;
    controller.dispose();
    if (!mounted ||
        amount == null ||
        account != _account ||
        conclave != widget.conclaveId) {
      return;
    }
    if (actions != null) {
      await runShopAction(context, () async {
        await actions.donateBeacon(conclave, amount);
      });
    } else {
      await runAltarAction(
          context, () => game!.donateWeaveFragments(conclave, amount));
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final server = context.watch<CanonicalGameSession?>();
    final game = server == null ? context.watch<HouseholdProvider>() : null;
    if (server == null && game!.loadWeaveBeacon == null ||
        server != null && context.read<CanonicalBeaconSource?>() == null) {
      return const SizedBox.shrink();
    }
    final available = server?.snapshot?.inventory.materials.fragments ??
        game?.eggAltar.wallet.fragments ??
        0;
    final busy = server != null ? !server.canAct : game!.altarBusy;
    final s = AppStrings.of(context);
    final amount = _fragments ?? 0;
    final stage = amount >= 5000
        ? 3
        : amount >= 2000
            ? 2
            : amount >= 500
                ? 1
                : 0;
    final next = stage == 0
        ? 500
        : stage == 1
            ? 2000
            : 5000;
    return Card(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: ExpansionTile(
          key: const Key('weave-beacon-project'),
          leading: Image.asset('assets/images/egg_altar/weave_beacon.png',
              width: 38, height: 46),
          title: const Text('Weave Beacon',
              style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(_failed
              ? s.pick('Tap to reconnect', 'Tik om opnieuw te verbinden')
              : _fragments == null
                  ? '… / 5000'
                  : '$amount / 5000'),
          onExpansionChanged: (open) {
            if (open) _refresh();
          },
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: RadialGradient(colors: [
                      const Color(0xFFBA7DF0)
                          .withValues(alpha: .1 + stage * .18),
                      Colors.transparent
                    ])),
                child: Opacity(
                    opacity: .35 + stage * .65 / 3,
                    child: Image.asset(
                        'assets/images/egg_altar/weave_beacon.png',
                        height: 145))),
            Text('${s.pick('Stage', 'Fase')} $stage / 3',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            LinearProgressIndicator(value: (amount / next).clamp(0, 1)),
            const SizedBox(height: 8),
            Text(
                stage == 3
                    ? s.pick('The Weave shines in your Aerie!',
                        'De Weave schittert in jullie Aerie!')
                    : s.pick(
                        'Build a shared decoration with Shell Fragments. Milestones: 500, 2000 and 5000.',
                        'Bouw samen een versiering met Shell Fragments. Mijlpalen: 500, 2000 en 5000.'),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            if (stage < 3)
              FilledButton.icon(
                  key: const Key('donate-weave-fragments'),
                  onPressed: busy || _fragments == null || available < 1
                      ? null
                      : _donate,
                  icon: const Icon(Icons.volunteer_activism_outlined),
                  label:
                      Text(s.pick('Donate fragments', 'Fragments schenken'))),
          ],
        ));
  }
}
