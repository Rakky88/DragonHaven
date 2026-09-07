import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
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
    if (oldWidget.conclaveId != widget.conclaveId) _fragments = null;
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
    final load = context.read<HouseholdProvider>().loadWeaveBeacon;
    if (load == null) return;
    _loading = true;
    final id = widget.conclaveId;
    try {
      final data = await load(id);
      if (mounted && id == widget.conclaveId) {
        setState(() {
          _fragments = (data['fragments'] as num).toInt();
          _failed = false;
        });
      }
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      _loading = false;
    }
  }

  Future<void> _donate() async {
    final game = context.read<HouseholdProvider>();
    final s = AppStrings.of(context);
    final maxAmount =
        min(game.eggAltar.wallet.fragments, 5000 - (_fragments ?? 0));
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
    if (!mounted || amount == null) return;
    await runAltarAction(
        context, () => game.donateWeaveFragments(widget.conclaveId, amount));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    if (game.loadWeaveBeacon == null) return const SizedBox.shrink();
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
                  onPressed: game.altarBusy ||
                          _fragments == null ||
                          game.eggAltar.wallet.fragments < 1
                      ? null
                      : _donate,
                  icon: const Icon(Icons.volunteer_activism_outlined),
                  label:
                      Text(s.pick('Donate fragments', 'Fragments schenken'))),
          ],
        ));
  }
}
