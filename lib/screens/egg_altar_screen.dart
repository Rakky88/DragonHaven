import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_egg.dart';
import '../models/egg_altar.dart';
import '../models/egg_collection_preferences.dart';
import '../providers/household_provider.dart';
import '../services/audio_service.dart';
import '../widgets/egg_art.dart';
import '../widgets/egg_altar_scene.dart';

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
  const EggAltarScreen({super.key, this.embedded = false});
  final bool embedded;
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

  void _showTutorial() {
    final s = AppStrings.of(context);
    showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
              title: Text(s.pick('The Egg Altar', 'Het Egg Altar')),
              content: SingleChildScrollView(
                  child: Text(
                      s.pick(
                          'Choose an egg and read its details before placing it on the altar. If you want to keep an egg, tag it to protect it. When you are ready, hold Return to the Weave: the egg leaves your inventory permanently and becomes materials you can use to craft relics. Special eggs, tagged eggs, eggs in the nest and eggs reserved for a trade are protected. Returning a Sinister egg asks for one extra confirmation. Open Craft to choose a relic, check its materials and make it. Use your crafted relics to learn more about an egg or give a dragon a new name.',
                          'Kies een ei en bekijk eerst de informatie voordat je het op het altaar plaatst. Wil je een ei bewaren, tag het dan om het te beschermen. Houd Return to the Weave ingedrukt wanneer je klaar bent: het ei verdwijnt definitief uit je inventaris en wordt omgezet in materialen waarmee je relics kunt maken. Special-eieren, getagde eieren, eieren in het nest en eieren die voor een ruil zijn gereserveerd zijn beschermd. Een Sinister-ei teruggeven vraagt om een extra bevestiging. Open Maken, kies een relic, bekijk de benodigde materialen en maak hem. Gebruik je gemaakte relics om meer over een ei te ontdekken of een draak een nieuwe naam te geven.'),
                      key: const Key('altar-tutorial-text'),
                      style: const TextStyle(height: 1.55))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: Text(s.pick('Got it', 'Begrepen')))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final s = AppStrings.of(context);
    final egg = game.eggStash.where((e) => e.id == _selectedId).firstOrNull;
    final block = egg == null ? null : game.weaveReturnBlockReason(egg.id);
    final info = IconButton(
        key: const Key('altar-tutorial'),
        tooltip: s.pick('How the Altar works', 'Hoe het Altar werkt'),
        icon: const Icon(Icons.info_outline_rounded),
        onPressed: _showTutorial);
    final content = ListView(
      key: const PageStorageKey('altar-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (widget.embedded)
          Row(children: [
            Expanded(
                child: Text(
                    s.pick('Return to the Weave', 'Terug naar de Weave'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800))),
            info
          ]),
        AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                child: SizedBox(
                    key: ValueKey(egg?.id),
                    height: _crafting ? 154 : 238,
                    width: double.infinity,
                    child: EggAltarArt(egg: egg)))),
        const SizedBox(height: 14),
        Card(
            margin: EdgeInsets.zero,
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: WeaveWalletView(wallet: game.eggAltar.wallet))),
        const SizedBox(height: 18),
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
        const SizedBox(height: 18),
        if (game.pendingAltarOperation != null)
          Card(
              child: ListTile(
                  title: Text(s.pick('Pending action', 'Openstaande actie')),
                  trailing: TextButton(
                      onPressed: game.altarBusy
                          ? null
                          : () => runAltarAction(
                              context, game.retryPendingAltarOperation),
                      child: Text(s.pick('Retry', 'Opnieuw'))))),
        if (_crafting)
          for (final relic in [
            AltarRelic.nameweaversQuill,
            ...AltarRelic.values.where((r) => r != AltarRelic.nameweaversQuill)
          ])
            AltarRecipeCard(relic: relic)
        else ...[
          FilledButton.tonalIcon(
              key: const Key('altar-select-egg'),
              onPressed: game.altarBusy ? null : _selectEgg,
              icon: Icon(
                  egg == null ? Icons.egg_outlined : Icons.swap_horiz_rounded),
              label: Text(egg == null
                  ? s.pick('Choose an egg', 'Kies een ei')
                  : s.pick('Choose another egg', 'Kies een ander ei'))),
          if (egg == null)
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Text(
                    s.pick(
                        'Give an egg back to the Weave and let its magic take a new form.',
                        'Geef een ei terug aan de Weave en laat zijn magie een nieuwe vorm aannemen.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        height: 1.45, color: Color(0xFF796A8B))))
          else ...[
            const SizedBox(height: 10),
            Text(dragonEggDisplayName(s, egg),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            Wrap(alignment: WrapAlignment.center, children: [
              EggTagButton(eggId: egg.id),
              TextButton.icon(
                  onPressed: () => showAltarEggDetails(context, egg.id),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(s.pick('Details', 'Informatie'))),
            ]),
            Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Text(
                    block != null
                        ? altarErrorText(s, block)
                        : s.pick(
                            'This egg will leave your inventory permanently. Hold the button to return it to the Weave.',
                            'Dit ei verdwijnt definitief uit je inventaris. Houd de knop ingedrukt om het terug te geven aan de Weave.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.45))),
            HoldToReturn(
                enabled: !game.altarBusy && block == null,
                onConfirmed: () => _returnEgg(egg)),
          ],
          if (game.altarBusy)
            const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator())),
        ],
      ],
    );
    if (widget.embedded) return content;
    return Scaffold(
        appBar: AppBar(title: const Text('Egg Altar'), actions: [info]),
        body: SafeArea(child: content));
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
  EggCollectionSortMode _sort = EggCollectionSortMode.acquiredAt;
  bool _descending = true;
  bool _loadedPreferences = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedPreferences) return;
    final game = context.read<HouseholdProvider>();
    _sort = EggCollectionSortMode.values.firstWhere(
      (mode) => mode.name == game.eggInventorySortMode,
      orElse: () => EggCollectionSortMode.acquiredAt,
    );
    _descending = game.eggInventorySortDescending;
    _loadedPreferences = true;
  }

  void _selectSort(EggCollectionSortMode mode) {
    setState(() {
      _descending = _sort == mode
          ? !_descending
          : mode == EggCollectionSortMode.acquiredAt;
      _sort = mode;
    });
    final game = context.read<HouseholdProvider>();
    unawaited(game.setEggInventoryCollectionPreferences(
      viewMode: game.eggInventoryViewMode,
      sortMode: _sort.name,
      descending: _descending,
    ));
  }

  Future<void> _inspect(String id) async {
    final chosen = await showAltarEggDetails(context, id,
        selectable: true, forReturn: widget.forReturn, relic: widget.relic);
    if (mounted && chosen == true) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final s = AppStrings.of(context);
    final ids = [
      if (!widget.forReturn && game.nestEgg != null) game.nestEgg!.id,
      ...sortedDragonEggs(game.eggStash,
              sortMode: _sort, descending: _descending)
          .map((e) => e.id)
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(
                      child: Text(s.pick(
                          '${ids.length} eggs', '${ids.length} eieren'))),
                  PopupMenuButton<EggCollectionSortMode>(
                    key: const Key('altar-egg-sort'),
                    tooltip: s.pick('Sort eggs', 'Eieren sorteren'),
                    initialValue: _sort,
                    onSelected: _selectSort,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        key: const Key('altar-egg-sort-acquiredAt'),
                        value: EggCollectionSortMode.acquiredAt,
                        child: Text(s.pick('Received', 'Ontvangen')),
                      ),
                      PopupMenuItem(
                        key: const Key('altar-egg-sort-hatchTime'),
                        value: EggCollectionSortMode.hatchTime,
                        child: Text(s.pick('Hatch time', 'Broedtijd')),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 14),
                      child: Text(_sort == EggCollectionSortMode.acquiredAt
                          ? s.pick('Received', 'Ontvangen')
                          : s.pick('Hatch time', 'Broedtijd')),
                    ),
                  ),
                  IconButton(
                    key: const Key('altar-egg-sort-direction'),
                    tooltip: _descending
                        ? s.pick('Descending; tap to reverse',
                            'Aflopend; tik om te keren')
                        : s.pick('Ascending; tap to reverse',
                            'Oplopend; tik om te keren'),
                    onPressed: () => _selectSort(_sort),
                    icon: Icon(_descending
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded),
                  ),
                ]),
              ),
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
                                onTap: () => _inspect(id));
                          })),
            ])));
  }
}

Future<bool?> showAltarEggDetails(
  BuildContext context,
  String eggId, {
  bool selectable = false,
  bool forReturn = false,
  AltarRelic? relic,
}) =>
    showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _AltarEggDetails(
            eggId: eggId,
            selectable: selectable,
            forReturn: forReturn,
            relic: relic));

class _AltarEggDetails extends StatelessWidget {
  const _AltarEggDetails(
      {required this.eggId,
      required this.selectable,
      required this.forReturn,
      this.relic});
  final String eggId;
  final bool selectable;
  final bool forReturn;
  final AltarRelic? relic;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final s = AppStrings.of(context);
    final nest = game.nestEgg?.id == eggId ? game.nestEgg : null;
    final egg = game.eggStash.where((e) => e.id == eggId).firstOrNull ??
        (nest == null
            ? null
            : DragonEgg(
                id: nest.id,
                lineageId: nest.lineageId,
                acquiredAt: nest.acquiredAt,
                hatchSeed: nest.hatchSeed,
                prismatic: nest.prismatic,
                lawAxis: nest.lawAxis,
                moralAxis: nest.moralAxis,
                sizeFactor: nest.sizeFactor,
                incubationSeconds: nest.incubationSeconds,
                sinister: nest.sinister,
                moralAxisKnown: nest.moralAxisKnown));
    if (egg == null) {
      return SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(altarErrorText(s, 'egg_not_found'))));
    }
    final known = game.eggKnowledge(eggId);
    final unknown = s.pick('Still hidden', 'Nog verborgen');
    final block = forReturn
        ? game.weaveReturnBlockReason(eggId)
        : relic != null && known.knows(relic!)
            ? 'already_known'
            : null;
    return FractionallySizedBox(
        heightFactor: .90,
        child: SafeArea(
            top: false,
            child: Column(children: [
              Expanded(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Column(children: [
                        Row(children: [
                          Container(
                              width: 88,
                              height: 96,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFFF3EDF9),
                                    Color(0xFFE9DEF6)
                                  ])),
                              child: EggArt(
                                  height: 80,
                                  lineageId: egg.lineageId,
                                  specialEggId: egg.specialEggId)),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(dragonEggDisplayName(s, egg),
                                    key: const Key('altar-egg-detail-title'),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                EggTagButton(eggId: eggId),
                              ])),
                        ]),
                        const SizedBox(height: 18),
                        _AltarDetailLine(
                            label: s.pick('Dragon family', 'Drakenfamilie'),
                            value: known.lineage
                                ? s.lineageName(egg.lineage)
                                : unknown),
                        _AltarDetailLine(
                            label: s.pick('Rarity', 'Zeldzaamheid'),
                            value: known.rarity || game.isEggRarityKnown(eggId)
                                ? s.lineageRarity(egg.lineage)
                                : unknown),
                        _AltarDetailLine(
                            label: s.pick('Moral alignment', 'Morele aard'),
                            value: known.moral ||
                                    egg.isSinisterEgg ||
                                    egg.moralAxisKnown
                                ? s.moralAxisName(egg.moralAxis)
                                : unknown),
                        _AltarDetailLine(
                            label: s.pick('Order alignment', 'Orde-aard'),
                            value: known.order
                                ? s.lawAxisName(egg.lawAxis)
                                : unknown),
                        _AltarDetailLine(
                            label: s.pick('Incubation', 'Broedtijd'),
                            value: s.remainingDuration(egg.incubationDuration)),
                        _AltarDetailLine(
                            label: s.pick('Acquired', 'Verkregen'),
                            value: MaterialLocalizations.of(context)
                                .formatMediumDate(egg.acquiredAt.toLocal())),
                        const SizedBox(height: 12),
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFAF6EE),
                                borderRadius: BorderRadius.circular(18)),
                            child: Text(
                                game.eggHintForEgg(egg, locale: s.languageCode),
                                key: Key('altar-egg-clue-$eggId'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    height: 1.35,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF756447)))),
                        const SizedBox(height: 16),
                        if (block != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(altarErrorText(s, block),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Color(0xFF8D5368), height: 1.4))),
                      ]))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
                  child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          key: const Key('altar-choose-reviewed-egg'),
                          onPressed:
                              selectable && (block != null || game.altarBusy)
                                  ? null
                                  : () => Navigator.pop(context, selectable),
                          child: Text(!selectable
                              ? s.pick('Close', 'Sluiten')
                              : forReturn
                                  ? s.pick(
                                      'Place on altar', 'Plaats op het altaar')
                                  : s.pick(
                                      'Choose this egg', 'Kies dit ei'))))),
            ])));
  }
}

class _AltarDetailLine extends StatelessWidget {
  const _AltarDetailLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child:
                Text(label, style: const TextStyle(color: Color(0xFF84758F)))),
        const SizedBox(width: 12),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w700))),
      ]));
}

String altarRelicEffect(AppStrings s, AltarRelic relic) => switch (relic) {
      AltarRelic.moralEcho => s.pick('Reveal an egg’s moral alignment.',
          'Onthul de morele aard van een ei.'),
      AltarRelic.orderSigil => s.pick('Reveal an egg’s order alignment.',
          'Onthul de orde-aard van een ei.'),
      AltarRelic.astralLens =>
        s.pick('Reveal an egg’s rarity.', 'Onthul de zeldzaamheid van een ei.'),
      AltarRelic.weaveOracle => s.pick(
          'Reveal an egg’s dragon family and rarity.',
          'Onthul de drakenfamilie en zeldzaamheid van een ei.'),
      AltarRelic.nameweaversQuill => s.pick(
          'Rename one dragon. Consumed on use.',
          'Hernoem één draak. Eenmalig te gebruiken.'),
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
    final owned = game.eggAltar.count(relic);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFE8DFEE))),
      child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 58,
                  height: 64,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5EFFA),
                      borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.all(3),
                  child: Image.asset(relic.asset, fit: BoxFit.contain)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(relic.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(altarRelicEffect(s, relic),
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF80708D))),
                    if (owned > 0)
                      Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('${s.pick('Owned', 'In bezit')}: $owned',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700))),
                  ])),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              if (!inventoryOnly)
                Expanded(
                    child: Wrap(spacing: 10, runSpacing: 5, children: [
                  for (final material in WeaveMaterial.values
                      .where((m) => relic.cost.count(m) > 0))
                    Tooltip(
                        message: material.label,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Image.asset(material.asset, width: 26, height: 26),
                          const SizedBox(width: 3),
                          Text('${relic.cost.count(material)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 12)),
                        ])),
                ]))
              else
                const Spacer(),
              if (!inventoryOnly)
                FilledButton(
                    key: Key('altar-craft-${relic.name}'),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18)),
                    onPressed: game.altarBusy ||
                            !game.eggAltar.wallet.covers(relic.cost)
                        ? null
                        : () => runAltarAction(
                            context, () => game.craftAltarRelic(relic)),
                    child: Text(s.pick('Craft', 'Maken'))),
              if (inventoryOnly)
                OutlinedButton(
                    key: Key('altar-use-${relic.name}'),
                    onPressed: game.altarBusy || owned == 0
                        ? null
                        : () => showUseAltarRelic(context, relic),
                    child: Text(s.pick('Use', 'Gebruiken'))),
            ]),
            if (!inventoryOnly && owned > 0)
              Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      key: Key('altar-use-${relic.name}'),
                      onPressed: game.altarBusy
                          ? null
                          : () => showUseAltarRelic(context, relic),
                      child: Text(s.pick('Use relic', 'Gebruik relic')))),
          ])),
    );
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
  Widget build(BuildContext context) =>
      EggAltarScene(egg: egg, progress: progress);
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
      vsync: this, duration: const Duration(milliseconds: 5200));
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
            child: Dialog(
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                          _animation.isCompleted
                              ? s.pick('Returned to the Weave',
                                  'Teruggegeven aan de Weave')
                              : s.pick('Returning to the Weave',
                                  'Terug naar de Weave'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 21, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 18),
                      SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: EggAltarArt(
                              egg: widget.egg,
                              progress: MediaQuery.disableAnimationsOf(context)
                                  ? 1
                                  : _animation.value)),
                      const SizedBox(height: 18),
                      AnimatedOpacity(
                          opacity: _animation.isCompleted ? 1 : 0,
                          duration: const Duration(milliseconds: 450),
                          child: ExcludeSemantics(
                              excluding: !_animation.isCompleted,
                              child: WeaveWalletView(wallet: widget.reward))),
                      const SizedBox(height: 20),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: _animation.isCompleted
                                  ? () => Navigator.pop(context)
                                  : widget.canSkip
                                      ? () => _animation.value = 1
                                      : null,
                              child: Text(_animation.isCompleted
                                  ? s.pick('Continue', 'Verder')
                                  : widget.canSkip
                                      ? s.pick('Skip animation',
                                          'Animatie overslaan')
                                      : s.pick(
                                          'Returning...', 'Teruggeven...')))),
                    ]),
                  ),
                ))));
  }
}
