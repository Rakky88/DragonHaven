import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_egg.dart';
import '../models/egg_altar.dart';
import '../providers/household_provider.dart';
import '../services/audio_service.dart';
import '../widgets/egg_art.dart';

String altarErrorText(AppStrings s, String code) => switch (code) {
      'egg_tagged' => s.pick('Untag this egg before returning it.',
          'Onttag dit ei voordat je het teruggeeft.'),
      'special_egg' => s.pick('Special eggs are always protected.',
          'Special-eieren zijn altijd beschermd.'),
      'egg_in_nest' => s.pick('The egg in the nest is protected.',
          'Het ei in het nest is beschermd.'),
      'egg_reserved' => s.pick('This egg is reserved for a trade.',
          'Dit ei is gereserveerd voor een ruil.'),
      'insufficient_materials' =>
        s.pick('Not enough materials.', 'Niet genoeg materialen.'),
      'already_known' => s.pick('This information is already known.',
          'Deze informatie is al bekend.'),
      'relic_not_owned' =>
        s.pick('Craft this relic first.', 'Maak eerst deze relic.'),
      'invalid_name' => s.pick('Choose a different name of 1–24 characters.',
          'Kies een andere naam van 1–24 tekens.'),
      'altar_sign_in_required' => s.pick('Sign in to use the Egg Altar.',
          'Log in om het Egg Altar te gebruiken.'),
      'altar_pending' => s.pick('Finish the pending action first.',
          'Rond eerst de openstaande actie af.'),
      'beacon_amount_exceeds_goal' => s.pick(
          'The Beacon needs fewer fragments now. Refresh and try again.',
          'De Beacon heeft nu minder fragments nodig. Vernieuw en probeer opnieuw.'),
      'conclave_member_not_found' => s.pick(
          'You are no longer a member of this Conclave.',
          'Je bent geen lid meer van deze Conclave.'),
      'egg_not_found' || 'egg_not_owned' || 'already_returned' => s.pick(
          'This egg is no longer available.',
          'Dit ei is niet meer beschikbaar.'),
      _ => s.pick(
          'The action could not be completed. Reconnect and retry safely.',
          'De actie kon niet worden afgerond. Herstel de verbinding en probeer veilig opnieuw.'),
    };

Future<bool> runAltarAction(
    BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } on Object catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(altarErrorText(AppStrings.of(context),
              error is EggAltarException ? error.code : 'altar_unavailable'))));
    }
    return false;
  }
}

class EggAltarEntry extends StatelessWidget {
  const EggAltarEntry({super.key});
  @override
  Widget build(BuildContext context) => ListTile(
        key: const Key('open-egg-altar'),
        leading: Image.asset('assets/images/egg_altar/altar_empty.png',
            width: 54, height: 54),
        title: const Text('Egg Altar',
            style: TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(AppStrings.of(context).pick(
            'Return to the Weave · craft relics',
            'Return to the Weave · maak relics')),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const EggAltarScreen())),
      );
}

class EggTagButton extends StatelessWidget {
  const EggTagButton({super.key, required this.eggId, this.compact = false});
  final String eggId;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final s = AppStrings.of(context);
    final tagged = game.isEggTagged(eggId);
    final label = tagged
        ? s.pick('Untag egg', 'Ei ontaggen')
        : s.pick('Tag egg', 'Ei taggen');
    final icon = Icon(
        tagged ? Icons.label_rounded : Icons.label_outline_rounded,
        color: tagged ? const Color(0xFF804EB8) : null,
        size: compact ? 20 : 24);
    void change() => unawaited(
        runAltarAction(context, () => game.setEggTagged(eggId, !tagged)));
    return compact
        ? IconButton(
            key: Key('egg-tag-$eggId'),
            tooltip: label,
            visualDensity: VisualDensity.compact,
            icon: icon,
            onPressed: game.altarBusy ? null : change)
        : OutlinedButton.icon(
            key: Key('egg-tag-$eggId'),
            onPressed: game.altarBusy ? null : change,
            icon: icon,
            label: Text(tagged
                ? s.pick('Tagged · untag', 'Getagd · ontaggen')
                : label));
  }
}

class EggKnowledgeSummary extends StatelessWidget {
  const EggKnowledgeSummary({super.key, required this.eggId});
  final String eggId;
  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final s = AppStrings.of(context);
    final egg = game.eggStash.where((e) => e.id == eggId).firstOrNull;
    final nest = game.nestEgg?.id == eggId ? game.nestEgg : null;
    if (egg == null && nest == null) return const SizedBox.shrink();
    final known = game.eggKnowledge(eggId);
    final lineage = egg?.lineage ?? nest!.lineage;
    return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          if (known.lineage) Chip(label: Text(s.lineageName(lineage))),
          if (known.rarity) Chip(label: Text(s.lineageRarity(lineage))),
          if (known.moral)
            Chip(
                label:
                    Text(s.moralAxisName(egg?.moralAxis ?? nest!.moralAxis))),
          if (known.order)
            Chip(label: Text(s.lawAxisName(egg?.lawAxis ?? nest!.lawAxis))),
        ]);
  }
}

class WeaveWalletView extends StatelessWidget {
  const WeaveWalletView(
      {super.key, required this.wallet, this.showLabels = true});
  final WeaveWallet wallet;
  final bool showLabels;
  @override
  Widget build(BuildContext context) => Row(children: [
        for (final material in WeaveMaterial.values)
          Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset(material.asset, width: 40, height: 40),
            Text('${wallet.count(material)}',
                style: const TextStyle(fontWeight: FontWeight.w900)),
            if (showLabels)
              Text(material.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10)),
          ])),
      ]);
}

class EggAltarScreen extends StatefulWidget {
  const EggAltarScreen({super.key});
  @override
  State<EggAltarScreen> createState() => _EggAltarScreenState();
}

class _EggAltarScreenState extends State<EggAltarScreen> {
  String? _selectedId;
  bool _crafting = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final refresh = context.read<HouseholdProvider>().refreshEggAltar;
      if (refresh != null) await runAltarAction(context, refresh);
    });
  }

  Future<void> _selectEgg() async {
    final id = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => const _AltarEggPicker(forReturn: true));
    if (mounted && id != null) setState(() => _selectedId = id);
  }

  Future<void> _returnEgg(DragonEgg egg) async {
    final game = context.read<HouseholdProvider>();
    final s = AppStrings.of(context);
    var sinisterConfirmed = false;
    if (egg.isSinisterEgg) {
      sinisterConfirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                    title: Text(s.pick(
                        'Return a Sinister Egg?', 'Sinister-ei teruggeven?')),
                    content: Text(s.pick(
                        'This permanently returns your Sinister Egg to the Weave. This cannot be undone.',
                        'Dit geeft je Sinister-ei definitief terug aan de Weave. Dit kan niet ongedaan worden gemaakt.')),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(s.pick('Cancel', 'Annuleren'))),
                      FilledButton(
                          key: const Key('confirm-sinister-return'),
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: Text(s.pick('Return Sinister Egg',
                              'Sinister-ei teruggeven'))),
                    ],
                  )) ??
          false;
      if (!mounted || !sinisterConfirmed) return;
    }
    WeaveWallet? reward;
    final success = await runAltarAction(context, () async {
      reward = await game.returnEggToWeave(egg.id,
          sinisterConfirmed: sinisterConfirmed);
    });
    if (!mounted || !success || reward == null) return;
    setState(() => _selectedId = null);
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _WeaveReturnResult(
            egg: egg,
            reward: reward!,
            canSkip: game.eggAltar.totalReturned > 1));
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final s = AppStrings.of(context);
    final egg = game.eggStash.where((e) => e.id == _selectedId).firstOrNull;
    final block = egg == null ? null : game.weaveReturnBlockReason(egg.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Egg Altar'), actions: [
        IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showDialog<void>(
                context: context,
                builder: (c) => AlertDialog(
                        title: Text(s.pick('Return rewards', 'Opbrengst')),
                        content: Text(s.pick(
                            'Every ordinary egg gives 5 Shell Fragments. Independent bonuses: 25% for 1 Draconic Essence and 2% for 1 Weaveheart. After 39 returns without a Weaveheart, the next is guaranteed. Sinister eggs always give 25 Shell Fragments and 3, 4 or 5 Draconic Essence with equal chances, plus an independent 10% chance of 1 Weaveheart. Every returned egg advances the counter once. Materials and crafted relics cannot be traded.',
                            'Elk gewoon ei geeft 5 Shell Fragments. Onafhankelijke bonussen: 25% op 1 Draconic Essence en 2% op 1 Weaveheart. Na 39 teruggaven zonder Weaveheart is de volgende gegarandeerd. Sinister-eieren geven altijd 25 Shell Fragments en 3, 4 of 5 Draconic Essence met gelijke kansen, plus een onafhankelijke kans van 10% op 1 Weaveheart. Elk teruggegeven ei telt eenmaal voor de teller. Materialen en gemaakte relics zijn niet verhandelbaar.')),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text('OK'))
                        ]))),
      ]),
      body: SafeArea(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              children: [
            SizedBox(height: 220, child: EggAltarArt(egg: egg)),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: WeaveWalletView(wallet: game.eggAltar.wallet))),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                    '${s.pick('Returns without a Weaveheart', 'Teruggaven zonder Weaveheart')}: ${game.eggAltar.misses}/40',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12))),
            SegmentedButton<bool>(segments: [
              ButtonSegment(
                  value: false,
                  label: Text(s.pick('Return', 'Teruggeven')),
                  icon: const Icon(Icons.auto_awesome)),
              ButtonSegment(
                  value: true,
                  label: Text(s.pick('Craft', 'Maken')),
                  icon: const Icon(Icons.handyman_outlined)),
            ], selected: {
              _crafting
            }, onSelectionChanged: (v) => setState(() => _crafting = v.single)),
            const SizedBox(height: 16),
            if (game.pendingAltarOperation != null)
              Card(
                  child: ListTile(
                      title:
                          Text(s.pick('Pending action', 'Openstaande actie')),
                      trailing: TextButton(
                          onPressed: game.altarBusy
                              ? null
                              : () => runAltarAction(
                                  context, game.retryPendingAltarOperation),
                          child: Text(s.pick('Retry', 'Opnieuw'))))),
            if (_crafting)
              for (final relic in AltarRelic.values)
                AltarRecipeCard(relic: relic)
            else ...[
              FilledButton.tonalIcon(
                  key: const Key('altar-select-egg'),
                  onPressed: game.altarBusy ? null : _selectEgg,
                  icon: const Icon(Icons.egg_outlined),
                  label: Text(egg == null
                      ? s.pick('Choose an egg', 'Kies een ei')
                      : dragonEggDisplayName(s, egg))),
              if (egg != null) ...[
                EggTagButton(eggId: egg.id),
                EggKnowledgeSummary(eggId: egg.id),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                        block != null
                            ? altarErrorText(s, block)
                            : s.pick(
                                'This egg will leave your inventory permanently. Hold the button to return it to the Weave.',
                                'Dit ei verdwijnt definitief uit je inventaris. Houd de knop ingedrukt om het terug te geven aan de Weave.'),
                        textAlign: TextAlign.center)),
                HoldToReturn(
                    enabled: !game.altarBusy && block == null,
                    onConfirmed: () => _returnEgg(egg)),
              ],
              if (game.altarBusy)
                const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator())),
            ],
          ])),
    );
  }
}

class _AltarEggPicker extends StatefulWidget {
  const _AltarEggPicker({this.forReturn = false, this.relic});
  final bool forReturn;
  final AltarRelic? relic;
  @override
  State<_AltarEggPicker> createState() => _AltarEggPickerState();
}

class _AltarEggPickerState extends State<_AltarEggPicker> {
  int _filter = 0;
  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final s = AppStrings.of(context);
    final ids = [
      if (!widget.forReturn && game.nestEgg != null) game.nestEgg!.id,
      ...game.eggStash.map((e) => e.id)
    ]
        .where((id) => _filter == 0 || game.isEggTagged(id) == (_filter == 1))
        .toList();
    return SafeArea(
        child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .72,
            child: Column(children: [
              Text(s.pick('Choose an egg', 'Kies een ei'),
                  style: Theme.of(context).textTheme.titleLarge),
              Wrap(spacing: 8, children: [
                for (var i = 0; i < 3; i++)
                  ChoiceChip(
                      label: Text([
                        s.pick('All', 'Alle'),
                        s.pick('Tagged', 'Getagd'),
                        s.pick('Untagged', 'Niet getagd')
                      ][i]),
                      selected: _filter == i,
                      onSelected: (_) => setState(() => _filter = i))
              ]),
              Expanded(
                  child: ids.isEmpty
                      ? Center(
                          child: Text(s.pick('No eggs available.',
                              'Geen eieren beschikbaar.')))
                      : ListView.builder(
                          itemCount: ids.length,
                          itemBuilder: (context, i) {
                            final id = ids[i];
                            final egg = game.eggStash
                                .where((e) => e.id == id)
                                .firstOrNull;
                            final nest =
                                game.nestEgg?.id == id ? game.nestEgg : null;
                            final block = widget.forReturn
                                ? game.weaveReturnBlockReason(id)
                                : widget.relic != null &&
                                        game
                                            .eggKnowledge(id)
                                            .knows(widget.relic!)
                                    ? 'already_known'
                                    : null;
                            return ListTile(
                                key: Key('altar-egg-$id'),
                                leading: SizedBox(
                                    width: 48,
                                    child: EggArt(
                                        height: 48,
                                        lineageId:
                                            egg?.lineageId ?? nest!.lineageId,
                                        specialEggId: egg?.specialEggId)),
                                title: Text(egg != null
                                    ? dragonEggDisplayName(s, egg)
                                    : s.pick(
                                        'Egg in the nest', 'Ei in het nest')),
                                subtitle: block == null
                                    ? EggKnowledgeSummary(eggId: id)
                                    : Text(altarErrorText(s, block)),
                                trailing:
                                    EggTagButton(eggId: id, compact: true),
                                onTap: block == null
                                    ? () => Navigator.pop(context, id)
                                    : null);
                          })),
            ])));
  }
}

String altarRelicEffect(AppStrings s, AltarRelic relic) => switch (relic) {
      AltarRelic.moralEcho => s.pick('Reveal an egg’s moral alignment.',
          'Onthul de morele aard van een ei.'),
      AltarRelic.orderSigil => s.pick('Reveal an egg’s order alignment.',
          'Onthul de orde-aard van een ei.'),
      AltarRelic.astralLens => s.pick(
          'Reveal an egg’s rarity. Also found in existing drops.',
          'Onthul de zeldzaamheid van een ei. Ook uit bestaande drops.'),
      AltarRelic.weaveOracle => s.pick(
          'Reveal an egg’s dragon family and rarity. Altar exclusive.',
          'Onthul de drakenfamilie en zeldzaamheid van een ei. Alleen via het altaar.'),
      AltarRelic.nameweaversQuill => s.pick(
          'Rename one dragon. Consumed on use. Altar exclusive.',
          'Hernoem één draak. Eenmalig te gebruiken. Alleen via het altaar.'),
    };

class AltarRecipeCard extends StatelessWidget {
  const AltarRecipeCard(
      {super.key, required this.relic, this.inventoryOnly = false});
  final AltarRelic relic;
  final bool inventoryOnly;
  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final s = AppStrings.of(context);
    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Row(children: [
                Image.asset(relic.asset, width: 66, height: 66),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(relic.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 17)),
                      Text(altarRelicEffect(s, relic)),
                      Text(
                          '${s.pick('Owned', 'In bezit')}: ${game.eggAltar.count(relic)}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]))
              ]),
              if (!inventoryOnly) ...[
                const SizedBox(height: 10),
                WeaveWalletView(wallet: relic.cost, showLabels: false)
              ],
              const SizedBox(height: 10),
              Wrap(spacing: 12, children: [
                if (!inventoryOnly)
                  FilledButton(
                      key: Key('altar-craft-${relic.name}'),
                      onPressed: game.altarBusy ||
                              !game.eggAltar.wallet.covers(relic.cost)
                          ? null
                          : () => runAltarAction(
                              context, () => game.craftAltarRelic(relic)),
                      child: Text(s.pick('Craft', 'Maken'))),
                OutlinedButton(
                    key: Key('altar-use-${relic.name}'),
                    onPressed: game.altarBusy || game.eggAltar.count(relic) == 0
                        ? null
                        : () => showUseAltarRelic(context, relic),
                    child: Text(s.pick('Use', 'Gebruiken'))),
              ]),
            ])));
  }
}

Future<void> showUseAltarRelic(BuildContext context, AltarRelic relic) async {
  final game = context.read<HouseholdProvider>();
  if (relic == AltarRelic.nameweaversQuill) {
    final dragons = game.ownedDragons
        .where((d) => !d.isEgg && d.name.trim().isNotEmpty)
        .toList();
    if (dragons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.of(context).pick(
              'Name your dragon first.', 'Geef je draak eerst een naam.'))));
      return;
    }
    final id = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
                child: ListView(shrinkWrap: true, children: [
              for (final dragon in dragons)
                ListTile(
                    title: Text(dragon.displayName),
                    onTap: () => Navigator.pop(context, dragon.id))
            ])));
    if (!context.mounted || id == null) return;
    await showRenameWithQuill(context, id);
    return;
  }
  final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AltarEggPicker(relic: relic));
  if (!context.mounted || id == null) return;
  final s = AppStrings.of(context);
  final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
              title: Text(relic.label),
              content: Text(s.pick('Use one relic on this egg?',
                  'Eén relic gebruiken op dit ei?')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(s.pick('Cancel', 'Annuleren'))),
                FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(s.pick('Use', 'Gebruiken')))
              ]));
  if (!context.mounted || confirmed != true) return;
  final success =
      await runAltarAction(context, () => game.useAltarRelic(relic, id));
  if (!context.mounted || !success) return;
  unawaited(HavenAudio.play(HavenSound.uiConfirm));
  await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
              title: Text(relic.label),
              content: EggKnowledgeSummary(eggId: id),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c), child: const Text('OK'))
              ]));
}

Future<void> showRenameWithQuill(BuildContext context, String dragonId) async {
  final game = context.read<HouseholdProvider>();
  final dragon = game.dragonById(dragonId);
  if (dragon == null || dragon.isEgg) return;
  if (game.eggAltar.count(AltarRelic.nameweaversQuill) == 0) {
    await runAltarAction(context, () async {
      throw const EggAltarException('relic_not_owned');
    });
    return;
  }
  final s = AppStrings.of(context);
  final controller = TextEditingController(text: dragon.name);
  final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
              scrollable: true,
              title: Text(AltarRelic.nameweaversQuill.label),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(s.pick('Consumes one Quill when the name is changed.',
                    'Verbruikt één Quill wanneer de naam is gewijzigd.')),
                TextField(
                    key: const Key('quill-dragon-name'),
                    controller: controller,
                    maxLength: 24,
                    autofocus: true),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: Text(s.pick('Cancel', 'Annuleren'))),
                FilledButton(
                    onPressed: () => Navigator.pop(c, controller.text.trim()),
                    child: Text(s.pick('Rename', 'Hernoemen')))
              ]));
  await WidgetsBinding.instance.endOfFrame;
  controller.dispose();
  if (!context.mounted || name == null) return;
  await runAltarAction(context, () async {
    if (!await game.renameDragonWithQuill(dragonId, name)) {
      throw const EggAltarException('invalid_name');
    }
  });
}

class HoldToReturn extends StatefulWidget {
  const HoldToReturn(
      {super.key, required this.enabled, required this.onConfirmed});
  final bool enabled;
  final VoidCallback onConfirmed;
  @override
  State<HoldToReturn> createState() => _HoldToReturnState();
}

class _HoldToReturnState extends State<HoldToReturn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.enabled) {
        _hold.reset();
        widget.onConfirmed();
      }
    });
  @override
  void didUpdateWidget(HoldToReturn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _hold.reset();
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      enabled: widget.enabled,
      label: AppStrings.of(context).pick('Hold to Return to the Weave',
          'Houd ingedrukt voor Return to the Weave'),
      child: GestureDetector(
          key: const Key('hold-return-to-weave'),
          onLongPressStart:
              widget.enabled ? (_) => _hold.forward(from: 0) : null,
          onLongPressEnd: (_) => _hold.reset(),
          onLongPressCancel: () => _hold.reset(),
          child: AnimatedBuilder(
              animation: _hold,
              builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(children: [
                    Container(
                        height: 54,
                        color: widget.enabled
                            ? const Color(0xFF66418D)
                            : Colors.grey.shade400),
                    FractionallySizedBox(
                        widthFactor: _hold.value,
                        child: Container(
                            height: 54, color: const Color(0x668CE7D4))),
                    const SizedBox(
                        height: 54,
                        child: Center(
                            child: Text('Return to the Weave',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900)))),
                  ])))));
}

class EggAltarArt extends StatelessWidget {
  const EggAltarArt({super.key, this.egg, this.progress});
  final DragonEgg? egg;
  final double? progress;
  @override
  Widget build(BuildContext context) {
    final p = progress ?? 0;
    final frame = math.min(6, (p * 6).floor() + 1).toString().padLeft(2, '0');
    return AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
            builder: (_, constraints) =>
                Stack(alignment: Alignment.center, children: [
                  Positioned.fill(
                      child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Image.asset(
                              progress == null
                                  ? 'assets/images/egg_altar/altar_empty.png'
                                  : 'assets/images/egg_altar/altar_phase_$frame.png',
                              key: ValueKey(progress == null ? 'empty' : frame),
                              fit: BoxFit.contain))),
                  if (egg != null)
                    Positioned(
                        top: constraints.maxHeight *
                            (.32 - .16 * (p * 3).clamp(0, 1)),
                        child: Opacity(
                            opacity:
                                (1 - ((p - .45) / .26).clamp(0, 1)).toDouble(),
                            child: EggArt(
                                height: constraints.maxHeight * .28,
                                lineageId: egg!.lineageId,
                                specialEggId: egg!.specialEggId))),
                ])));
  }
}

class _WeaveReturnResult extends StatefulWidget {
  const _WeaveReturnResult(
      {required this.egg, required this.reward, required this.canSkip});
  final DragonEgg egg;
  final WeaveWallet reward;
  final bool canSkip;
  @override
  State<_WeaveReturnResult> createState() => _WeaveReturnResultState();
}

class _WeaveReturnResultState extends State<_WeaveReturnResult>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4200));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animation.isAnimating || _animation.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.duration = const Duration(milliseconds: 250);
    }
    _animation.forward();
    unawaited(HavenAudio.play(HavenSound.adventureReturn));
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AnimatedBuilder(
        animation: _animation,
        builder: (_, __) => PopScope(
            canPop: _animation.isCompleted,
            child: AlertDialog(
                title: Text(s.pick(
                    'Returned to the Weave', 'Teruggegeven aan de Weave')),
                content: SizedBox(
                    width: 320,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                          height: 220,
                          child: EggAltarArt(
                              egg: widget.egg,
                              progress: MediaQuery.disableAnimationsOf(context)
                                  ? 1
                                  : _animation.value)),
                      if (_animation.isCompleted)
                        WeaveWalletView(wallet: widget.reward),
                    ])),
                actions: [
                  if (!_animation.isCompleted && widget.canSkip)
                    TextButton(
                        onPressed: () => _animation.value = 1,
                        child: Text(
                            s.pick('Skip animation', 'Animatie overslaan'))),
                  if (_animation.isCompleted)
                    FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(s.pick('Continue', 'Verder'))),
                ])));
  }
}
