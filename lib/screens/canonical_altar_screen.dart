import 'egg_altar_screen.dart'
    show HoldToReturn, WeaveReturnResult, WeaveWalletView;
import '../widgets/restored_collection_cards.dart';
import 'canonical_dragons_screen.dart';
import '../widgets/shop_economy_scope.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/egg_altar.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_game_snapshot.dart';
import '../widgets/egg_altar_scene.dart';
import 'canonical_eggs.dart';

class CanonicalAltarScreen extends StatefulWidget {
  const CanonicalAltarScreen({super.key});
  @override
  State<CanonicalAltarScreen> createState() => _CanonicalAltarScreenState();
}

class _CanonicalAltarScreenState extends State<CanonicalAltarScreen> {
  bool _crafting = false;
  String? _selectedId, _owner;
  int? _epoch;
  CanonicalEggView? _returning;
  Future<void> _choose() async {
    final session = context.read<CanonicalGameSession>();
    final view = session.snapshot;
    final epoch = session.connection.sessionEpoch;
    if (view == null) return;
    final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SizedBox(
            height: MediaQuery.sizeOf(context).height * .72,
            child: SafeArea(
                child: CanonicalEggList(
                    onPlace: (id) => Navigator.pop(context, id)))));
    if (mounted &&
        selected != null &&
        session.connection.sessionEpoch == epoch &&
        context.read<CanonicalGameSession>().snapshot?.ownerId ==
            view.ownerId) {
      setState(() {
        _selectedId = selected;
        _owner = view.ownerId;
        _epoch = epoch;
      });
    }
  }

  Future<void> _return(
      CanonicalEggView egg, CanonicalGameActions actions, String owner) async {
    setState(() {
      _returning = egg;
      _owner = owner;
      _epoch = actions.epoch;
    });
    try {
      final reward = await actions.returnEgg(egg.id,
          sinisterConfirmed: egg.kind == 'sinister');
      if (!mounted ||
          context.read<CanonicalGameSession>().connection.sessionEpoch !=
              actions.epoch ||
          context.read<CanonicalGameSession>().snapshot?.ownerId != owner) {
        return;
      }
      await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => WeaveReturnResult(
              eggArtwork: CanonicalEggArt(egg: egg, height: 100),
              reward: reward,
              canSkip: true));
      if (!mounted) return;
      setState(() {
        _selectedId = null;
      });
    } finally {
      if (mounted) setState(() => _returning = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final view = session.snapshot;
    if (view == null) return const SizedBox.shrink();
    final strings = AppStrings.of(context);
    final sameOwner =
        _owner == view.ownerId && _epoch == session.connection.sessionEpoch;
    final egg = sameOwner ? view.egg(_selectedId ?? '') : null;
    final visibleEgg = sameOwner ? (_returning ?? egg) : null;
    final actions = CanonicalGameActions(session);
    final canReturn = session.canAct &&
        _returning == null &&
        egg != null &&
        egg.returnBlockReason == null;
    return ListView(
        key: const Key('canonical-altar-list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Row(children: [
            Expanded(
                child: Text(
                    strings.pick('Return to the Weave', 'Terug naar de Weave'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800))),
            IconButton(
                tooltip: strings.pick('How it works', 'Hoe het werkt'),
                onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                            title: const Text('Egg Altar'),
                            content: SingleChildScrollView(
                                child: Text(strings.pick(
                                    'Choose an egg and read its details before placing it on the altar. If you want to keep an egg, tag it to protect it. When you are ready, hold Return to the Weave: the egg leaves your inventory permanently and becomes materials you can use to craft relics. Special eggs, tagged eggs, eggs in the nest and eggs reserved for a trade are protected. Returning a Sinister egg asks for one extra confirmation. Open Craft to choose a relic, check its materials and make it. Use your crafted relics to learn more about an egg or give a dragon a new name.',
                                    'Kies een ei en bekijk eerst de informatie voordat je het op het altaar plaatst. Wil je een ei bewaren, tag het dan om het te beschermen. Houd Return to the Weave ingedrukt wanneer je klaar bent: het ei verdwijnt definitief uit je inventaris en wordt omgezet in materialen waarmee je relics kunt maken. Special-eieren, getagde eieren, eieren in het nest en eieren die voor een ruil zijn gereserveerd zijn beschermd. Een Sinister-ei teruggeven vraagt om een extra bevestiging. Open Maken, kies een relic, bekijk de benodigde materialen en maak hem. Gebruik je gemaakte relics om meer over een ei te ontdekken of een draak een nieuwe naam te geven.'))),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(strings.pick('Close', 'Sluiten')))
                            ])),
                icon: const Icon(Icons.info_outline))
          ]),
          AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  child: SizedBox(
                      key: ValueKey(visibleEgg?.id),
                      height: _crafting ? 154 : 238,
                      width: double.infinity,
                      child: EggAltarScene(
                          eggArtwork: visibleEgg == null
                              ? null
                              : CanonicalEggArt(
                                  egg: visibleEgg, height: 100))))),
          const SizedBox(height: 14),
          Card(
              margin: EdgeInsets.zero,
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  child: WeaveWalletView(wallet: view.inventory.materials))),
          const SizedBox(height: 18),
          SegmentedButton<bool>(segments: [
            ButtonSegment(
                value: false,
                label: Text(strings.pick('Return', 'Teruggeven')),
                icon: const Icon(Icons.auto_awesome)),
            ButtonSegment(
                value: true,
                label: Text(strings.pick('Craft', 'Maken')),
                icon: const Icon(Icons.handyman_outlined)),
          ], selected: {
            _crafting
          }, onSelectionChanged: (v) => setState(() => _crafting = v.single)),
          const SizedBox(height: 18),
          if (!_crafting) ...[
            FilledButton.tonalIcon(
                key: const Key('canonical-altar-choose'),
                onPressed:
                    session.canAct && _returning == null ? _choose : null,
                icon: Icon(egg == null
                    ? Icons.egg_outlined
                    : Icons.swap_horiz_rounded),
                label: Text(egg == null
                    ? strings.pick('Choose an egg', 'Kies een ei')
                    : strings.pick('Choose another egg', 'Kies een ander ei'))),
            if (egg == null)
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Text(
                      strings.pick(
                          'Give an egg back to the Weave and let its magic take a new form.',
                          'Geef een ei terug aan de Weave en laat zijn magie een nieuwe vorm aannemen.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          height: 1.45, color: Color(0xFF796A8B))))
            else ...[
              const SizedBox(height: 10),
              Text(canonicalEggName(strings, egg),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800)),
              TextButton.icon(
                  onPressed: () =>
                      showCanonicalEggDetails(context, egg.id, forAltar: true),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(strings.pick('Details', 'Informatie'))),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Text(
                      strings.pick(
                          'This egg will leave your inventory permanently. Hold the button to return it to the Weave.',
                          'Dit ei verdwijnt definitief uit je inventaris. Houd de knop ingedrukt om het terug te geven aan de Weave.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(height: 1.45))),
              HoldToReturn(
                  key: const Key('canonical-altar-return'),
                  enabled: canReturn,
                  onConfirmed: () async {
                    if (!canReturn) return;
                    if (egg.kind == 'sinister') {
                      final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                                  title: Text(strings.pick(
                                      'Return a Sinister Egg?',
                                      'Sinister-ei teruggeven?')),
                                  content: Text(strings.pick(
                                      'This permanently returns your Sinister Egg to the Weave. This cannot be undone.',
                                      'Dit geeft je Sinister-ei definitief terug aan de Weave. Dit kan niet ongedaan worden gemaakt.')),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(strings.pick(
                                            'Cancel', 'Annuleren'))),
                                    FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(strings.pick(
                                            'Return Sinister Egg',
                                            'Sinister-ei teruggeven')))
                                  ]));
                      if (confirmed != true || !mounted) return;
                    }
                    if (context.mounted) {
                      await runShopAction(
                          context, () => _return(egg, actions, view.ownerId));
                    }
                  }),
            ],
          ] else
            for (final relic in [
              AltarRelic.nameweaversQuill,
              ...AltarRelic.values
                  .where((r) => r != AltarRelic.nameweaversQuill)
            ])
              RestoredAltarRecipeCard(
                  relic: relic,
                  owned: view.inventory.count(relic),
                  onCraft: session.canAct &&
                          view.inventory.materials.covers(relic.cost)
                      ? () => runShopAction(context, () => actions.craft(relic))
                      : null,
                  onUse: session.canAct && view.inventory.count(relic) > 0
                      ? () => relic == AltarRelic.nameweaversQuill
                          ? Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => Scaffold(
                                      appBar: AppBar(title: Text(relic.label)),
                                      body: const CanonicalDragonsScreen())))
                          : showCanonicalAltarRelicPicker(context, relic)
                      : null),
        ]);
  }
}
