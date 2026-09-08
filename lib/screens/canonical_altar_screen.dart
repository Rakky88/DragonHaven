import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/egg_altar.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_game_snapshot.dart';
import '../widgets/canonical_game_controls.dart';
import '../widgets/egg_altar_scene.dart';
import 'canonical_eggs.dart';

class CanonicalAltarScreen extends StatefulWidget {
  const CanonicalAltarScreen({super.key});
  @override
  State<CanonicalAltarScreen> createState() => _CanonicalAltarScreenState();
}

class _CanonicalAltarScreenState extends State<CanonicalAltarScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedId, _owner;
  int? _epoch;
  CanonicalEggView? _returning;
  WeaveWallet? _reward;
  late final _animation = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2800));
  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    final session = context.read<CanonicalGameSession>();
    final view = session.snapshot;
    final epoch = session.connection.sessionEpoch;
    if (view == null) return;
    final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SizedBox(
            height: MediaQuery.sizeOf(context).height * .84,
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
        _reward = null;
      });
    }
  }

  Future<void> _return(
      CanonicalEggView egg, CanonicalGameActions actions, String owner) async {
    setState(() {
      _returning = egg;
      _owner = owner;
      _epoch = actions.epoch;
      _reward = null;
    });
    _animation.reset();
    try {
      final reward = await actions.returnEgg(egg.id,
          sinisterConfirmed: egg.kind == 'sinister');
      if (!mounted ||
          context.read<CanonicalGameSession>().connection.sessionEpoch !=
              actions.epoch ||
          context.read<CanonicalGameSession>().snapshot?.ownerId != owner) {
        return;
      }
      if (!MediaQuery.disableAnimationsOf(context)) {
        try {
          await _animation.forward().orCancel;
        } on TickerCanceled {
          return;
        }
      }
      if (!mounted ||
          context.read<CanonicalGameSession>().connection.sessionEpoch !=
              actions.epoch ||
          context.read<CanonicalGameSession>().snapshot?.ownerId != owner) {
        return;
      }
      setState(() {
        _reward = reward;
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
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(
                child: Text('Egg Altar',
                    style: Theme.of(context).textTheme.titleLarge)),
            IconButton(
                tooltip: strings.pick('How it works', 'Hoe het werkt'),
                onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                            title: const Text('Egg Altar'),
                            content: SingleChildScrollView(
                                child: Text(strings.pick(
                                    'Choose an egg and read its details before placing it on the Altar. Return it to the Weave to receive crafting materials. Tagged eggs, Special eggs and eggs in the nest are protected. Sinister eggs need an extra confirmation. Use materials to craft relics, then select an egg to reveal information or use a Quill to rename a dragon.',
                                    'Kies een ei en lees de details voordat je het op het Altar plaatst. Geef het terug aan de Weave voor materialen om relieken te maken. Getagde eieren, Special-eieren en eieren in het nest zijn beschermd. Sinister-eieren vragen een extra bevestiging. Maak relieken met je materialen en kies daarna een ei om informatie te onthullen, of gebruik een Quill om een draak te hernoemen.'))),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(strings.pick('Close', 'Sluiten')))
                            ])),
                icon: const Icon(Icons.info_outline))
          ]),
          const SizedBox(height: 12),
          SizedBox(
              height: 240,
              child: AnimatedBuilder(
                  animation: _animation,
                  builder: (_, child) => EggAltarScene(
                      eggArtwork: visibleEgg == null
                          ? null
                          : CanonicalEggArt(egg: visibleEgg, height: 100),
                      progress: _returning == null ? null : _animation.value))),
          if (egg != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(canonicalEggName(strings, egg),
                    textAlign: TextAlign.center)),
          const SizedBox(height: 8),
          OutlinedButton(
              key: const Key('canonical-altar-choose'),
              onPressed: session.canAct && _returning == null ? _choose : null,
              child: Text(strings.pick('Choose an egg', 'Kies een ei'))),
          CanonicalActionButton(
              key: const Key('canonical-altar-return'),
              label: strings.pick('Return to the Weave', 'Terug naar de Weave'),
              confirmation: strings.pick(
                  'Return this egg to the Weave? It will leave your inventory.',
                  'Dit ei teruggeven aan de Weave? Het verdwijnt uit je inventaris.'),
              secondaryConfirmation: egg?.kind == 'sinister'
                  ? strings.pick(
                      'This is a Sinister egg. Confirm that you want to return it.',
                      'Dit is een Sinister-ei. Bevestig dat je het wilt teruggeven.')
                  : null,
              action:
                  canReturn ? () => _return(egg, actions, view.ownerId) : null),
          const SizedBox(height: 16),
          if (sameOwner && _reward != null) ...[
            Text(
                strings.pick(
                    'Returned to the Weave', 'Teruggegeven aan de Weave'),
                style: Theme.of(context).textTheme.titleMedium),
            _Materials(wallet: _reward!, reward: true),
            const Divider(height: 24)
          ],
          _Materials(wallet: view.inventory.materials),
          const SizedBox(height: 20),
          Text(strings.pick('Craft relics', 'Relieken maken'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final relic in [
            AltarRelic.nameweaversQuill,
            ...AltarRelic.values.where((r) => r != AltarRelic.nameweaversQuill)
          ])
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Image.asset(relic.asset, width: 50, height: 50),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(relic.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium)),
                            const SizedBox(width: 8),
                            Text('${view.inventory.count(relic)}')
                          ]),
                          Text(switch (relic) {
                            AltarRelic.nameweaversQuill => strings.pick(
                                'Rename one dragon.', 'Hernoem één draak.'),
                            AltarRelic.moralEcho => strings.pick(
                                'Reveal an egg’s moral nature.',
                                'Onthul de morele aard van een ei.'),
                            AltarRelic.orderSigil => strings.pick(
                                'Reveal an egg’s order nature.',
                                'Onthul de orde-aard van een ei.'),
                            AltarRelic.astralLens => strings.pick(
                                'Reveal the rarity inside an egg.',
                                'Onthul de zeldzaamheid in een ei.'),
                            AltarRelic.weaveOracle => strings.pick(
                                'Reveal the dragon inside an egg.',
                                'Onthul de draak in een ei.'),
                          }),
                          _Materials(wallet: relic.cost, compact: true),
                          CanonicalActionButton(
                              key: Key('canonical-craft-${relic.name}'),
                              label: strings.pick('Craft', 'Maken'),
                              action: session.canAct &&
                                      view.inventory.materials
                                          .covers(relic.cost)
                                  ? () => actions.craft(relic)
                                  : null),
                        ]))),
        ]);
  }
}

class _Materials extends StatelessWidget {
  const _Materials(
      {required this.wallet, this.reward = false, this.compact = false});
  final WeaveWallet wallet;
  final bool reward, compact;
  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 14, runSpacing: 8, children: [
        for (final material in WeaveMaterial.values)
          if (!compact || wallet.count(material) > 0)
            Tooltip(
                message: material.label,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset(material.asset,
                      width: compact ? 28 : 38,
                      height: compact ? 28 : 38,
                      semanticLabel: material.label),
                  const SizedBox(width: 4),
                  Text('${reward ? '+' : ''}${wallet.count(material)}',
                      style: Theme.of(context).textTheme.titleMedium)
                ])),
      ]);
}
