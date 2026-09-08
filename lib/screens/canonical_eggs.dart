import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/dragon_lineage.dart';
import '../models/egg_altar.dart';
import '../models/mystic_relic.dart';
import '../models/pet.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_game_snapshot.dart';
import '../widgets/canonical_game_controls.dart';
import '../widgets/dragon_art.dart';
import '../widgets/shop_economy_scope.dart';

String canonicalEggName(AppStrings strings, CanonicalEggView egg) {
  final special = specialEggById(egg.specialEggId);
  return special == null
      ? strings.eggName(
          sinister: egg.kind == 'sinister', special: egg.kind == 'special')
      : strings.pick(special.titleEn, special.titleNl);
}

String _knownRarity(AppStrings strings, String? value) => switch (value) {
      'common' => strings.pick('Common', 'Gewoon'),
      'uncommon' => strings.pick('Uncommon', 'Ongewoon'),
      'rare' => strings.pick('Rare', 'Zeldzaam'),
      'veryRare' => strings.pick('Very Rare', 'Zeer zeldzaam'),
      'legendary' => strings.pick('Legendary', 'Legendarisch'),
      'mythical' => strings.pick('Mythical', 'Mythisch'),
      'specialEvent' => strings.pick('Special', 'Speciaal'),
      _ => strings.pick('Unknown', 'Onbekend'),
    };

class CanonicalEggArt extends StatelessWidget {
  const CanonicalEggArt({super.key, required this.egg, this.height = 70});
  final CanonicalEggView egg;
  final double height;
  @override
  Widget build(BuildContext context) {
    final special = specialEggById(egg.specialEggId);
    return special == null
        ? DragonArt(stageKey: 'moonEgg', animate: false, height: height)
        : Image.asset(special.assetPath, height: height, fit: BoxFit.contain);
  }
}

class CanonicalEggList extends StatefulWidget {
  const CanonicalEggList({super.key, this.onPlace});
  final void Function(String)? onPlace;
  @override
  State<CanonicalEggList> createState() => _CanonicalEggListState();
}

class _CanonicalEggListState extends State<CanonicalEggList> {
  String _kind = 'all', _order = 'newest';
  bool _tagged = false;
  @override
  Widget build(BuildContext context) {
    final view = context.watch<CanonicalGameSession>().snapshot;
    if (view == null) return const SizedBox.shrink();
    final strings = AppStrings.of(context);
    final eggs = view.eggs
        .where((e) =>
            (_kind == 'all' || e.kind == _kind) && (!_tagged || e.tagged))
        .toList()
      ..sort((a, b) {
        final order = switch (_order) {
          'oldest' => a.acquiredAt.compareTo(b.acquiredAt),
          'shortest' => a.incubation.compareTo(b.incubation),
          _ => b.acquiredAt.compareTo(a.acquiredAt),
        };
        return order != 0 ? order : a.id.compareTo(b.id);
      });
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(
            child: Text(
                widget.onPlace == null
                    ? strings.pick('Eggs', 'Eieren')
                    : strings.pick('Choose an egg', 'Kies een ei'),
                style: Theme.of(context).textTheme.titleLarge)),
        IconButton(
            key: const Key('canonical-egg-filter'),
            tooltip: strings.pick('Filter and sort', 'Filteren en sorteren'),
            onPressed: () => _filter(context),
            icon: const Icon(Icons.tune_rounded))
      ]),
      for (final egg in eggs)
        Card(
            child: ListTile(
          key: Key('canonical-egg-${egg.id}'),
          leading:
              SizedBox(width: 48, child: CanonicalEggArt(egg: egg, height: 48)),
          title: Text(canonicalEggName(strings, egg)),
          subtitle: Text(egg.hint(strings.languageCode)),
          trailing:
              Icon(egg.tagged ? Icons.bookmark_rounded : Icons.info_outline),
          onTap: () =>
              showCanonicalEggDetails(context, egg.id, onPlace: widget.onPlace),
        )),
      if (eggs.isEmpty)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(strings.pick('No eggs match these filters.',
                'Geen eieren met deze filters.'))),
    ]);
  }

  Future<void> _filter(BuildContext context) async {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(builder: (context, update) {
              final strings = AppStrings.of(context);
              void change(VoidCallback action) {
                if (!mounted) {
                  Navigator.pop(context);
                  return;
                }
                setState(action);
                update(() {});
              }

              return SafeArea(
                  child: SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                    strings.pick('Filter and sort',
                                        'Filteren en sorteren'),
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                Wrap(spacing: 8, children: [
                                  for (final entry in {
                                    'all': strings.pick('All', 'Alle'),
                                    'ordinary':
                                        strings.pick('Ordinary', 'Gewoon'),
                                    'sinister': 'Sinister',
                                    'special': 'Special',
                                  }.entries)
                                    ChoiceChip(
                                        label: Text(entry.value),
                                        selected: _kind == entry.key,
                                        onSelected: (_) =>
                                            change(() => _kind = entry.key))
                                ]),
                                SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(strings.pick(
                                        'Tagged only', 'Alleen getagd')),
                                    value: _tagged,
                                    onChanged: (value) =>
                                        change(() => _tagged = value)),
                                for (final entry in {
                                  'newest': strings.pick(
                                      'Newest first', 'Nieuwste eerst'),
                                  'oldest': strings.pick(
                                      'Oldest first', 'Oudste eerst'),
                                  'shortest': strings.pick(
                                      'Shortest incubation',
                                      'Kortste broedtijd')
                                }.entries)
                                  ListTile(
                                      title: Text(entry.value),
                                      trailing: _order == entry.key
                                          ? const Icon(Icons.check)
                                          : null,
                                      onTap: () =>
                                          change(() => _order = entry.key)),
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(strings.pick('Done', 'Klaar'))),
                              ]))));
            }));
  }
}

Future<void> showCanonicalEggDetails(BuildContext context, String id,
    {void Function(String)? onPlace}) async {
  final owner = context.read<CanonicalGameSession>().snapshot?.ownerId;
  if (owner == null) return;
  await showDialog<void>(
      context: context,
      builder: (context) => CanonicalEntityDialog(
          ownerId: owner,
          builder: (context, view, enabled) {
            final strings = AppStrings.of(context);
            final egg = view.egg(id);
            final session = context.read<CanonicalGameSession>();
            final actions = CanonicalGameActions(session);
            final reserved = view.inventory.reservedEggIds.contains(id);
            final unknown = strings.pick('Unknown', 'Onbekend');
            final lineage = dragonLineages
                .where((l) => l.id == egg?.revealedLineageId)
                .firstOrNull;
            return AlertDialog(
              title: Text(egg == null
                  ? strings.pick('Egg', 'Ei')
                  : canonicalEggName(strings, egg)),
              content: SizedBox(
                  width: 380,
                  child: SingleChildScrollView(
                      child: egg == null
                          ? Text(strings.pick(
                              'This egg has left your inventory.',
                              'Dit ei zit niet meer in je inventaris.'))
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                  CanonicalEggArt(egg: egg, height: 120),
                                  Text(egg.hint(strings.languageCode)),
                                  const SizedBox(height: 14),
                                  Text(
                                      '${strings.pick('Dragon', 'Draak')}: ${lineage == null ? unknown : strings.lineageName(lineage)}'),
                                  Text(
                                      '${strings.pick('Rarity', 'Zeldzaamheid')}: ${_knownRarity(strings, egg.revealedRarity)}'),
                                  if (egg.revealedLawAxis != null)
                                    Text(switch (LawAxis.values
                                        .where((v) =>
                                            v.name == egg.revealedLawAxis)
                                        .firstOrNull) {
                                      final value? =>
                                        strings.lawAxisName(value),
                                      null => unknown,
                                    }),
                                  if (egg.revealedMoralAxis != null)
                                    Text(switch (MoralAxis.values
                                        .where((v) =>
                                            v.name == egg.revealedMoralAxis)
                                        .firstOrNull) {
                                      final value? =>
                                        strings.moralAxisName(value),
                                      null => unknown,
                                    }),
                                  if (egg.location == 'nest')
                                    CanonicalNestClock(egg: egg, view: view),
                                  if (reserved)
                                    Text(gameConnectionMessage(
                                        strings, 'egg_reserved')),
                                  const SizedBox(height: 12),
                                  CanonicalActionButton(
                                      key: const Key('canonical-tag-egg'),
                                      label: strings.pick(
                                          egg.tagged ? 'Untag egg' : 'Tag egg',
                                          egg.tagged
                                              ? 'Tag verwijderen'
                                              : 'Ei taggen'),
                                      action: enabled
                                          ? () =>
                                              actions.tagEgg(id, !egg.tagged)
                                          : null),
                                  if (onPlace != null) ...[
                                    if (egg.returnBlockReason != null)
                                      Text(gameConnectionMessage(
                                          strings, egg.returnBlockReason)),
                                    FilledButton(
                                        key: const Key('canonical-place-egg'),
                                        onPressed: enabled &&
                                                egg.returnBlockReason == null
                                            ? () {
                                                Navigator.pop(context);
                                                onPlace(id);
                                              }
                                            : null,
                                        child: Text(strings.pick(
                                            'Place on Altar',
                                            'Op het Altar plaatsen'))),
                                  ] else if (egg.location == 'stash')
                                    CanonicalActionButton(
                                        key:
                                            const Key('canonical-incubate-egg'),
                                        label: strings.pick('Place in nest',
                                            'In het nest plaatsen'),
                                        confirmation: strings.pick(
                                            'Start incubating this egg?',
                                            'Dit ei uitbroeden in het nest?'),
                                        action: enabled &&
                                                !reserved &&
                                                view.nest == null
                                            ? () => actions.activateEgg(id)
                                            : null),
                                  const Divider(height: 24),
                                  for (final relic in AltarRelic.values.where(
                                      (r) => r != AltarRelic.nameweaversQuill))
                                    if (view.inventory.count(relic) > 0)
                                      CanonicalActionButton(
                                          key: Key(
                                              'canonical-reveal-${relic.name}'),
                                          label:
                                              '${relic.label} (${view.inventory.count(relic)})',
                                          confirmation: strings.pick(
                                              'Use one ${relic.label} on this egg?',
                                              'Eén ${relic.label} op dit ei gebruiken?'),
                                          action: enabled &&
                                                  !reserved &&
                                                  !egg.known(relic)
                                              ? () =>
                                                  actions.revealEgg(relic, id)
                                              : null),
                                  if ((view.inventory.usableRelics[
                                              MysticRelic.astralLens] ??
                                          0) >
                                      0)
                                    CanonicalActionButton(
                                        key: const Key(
                                            'canonical-use-drop-lens'),
                                        label: strings
                                            .relicName(MysticRelic.astralLens),
                                        confirmation: strings.pick(
                                            'Use one Astral Lens on this egg?',
                                            'Eén Astral Lens op dit ei gebruiken?'),
                                        action: enabled &&
                                                !reserved &&
                                                egg.revealedRarity == null
                                            ? () => actions.useLens(id)
                                            : null),
                                  if (egg.location == 'nest')
                                    for (final reduction
                                        in view.inventory.chronoshards
                                            .toSet()
                                            .toList()
                                          ..sort())
                                      CanonicalActionButton(
                                          key: Key(
                                              'canonical-chronoshard-$reduction'),
                                          label: 'Chronoshard · $reduction%',
                                          confirmation: strings.pick(
                                              'Use this Chronoshard?',
                                              'Deze Chronoshard gebruiken?'),
                                          action: enabled &&
                                                  view.inventory
                                                      .canUseChronoshard(
                                                          reduction)
                                              ? () => actions
                                                  .useChronoshard(reduction)
                                              : null),
                                ]))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(strings.pick('Close', 'Sluiten')))
              ],
            );
          }));
}

/// Elapsed display time comes from a monotonic clock anchored to the server.
/// The hatch command still uses the database clock, never this estimate.
class CanonicalNestClock extends StatefulWidget {
  const CanonicalNestClock({super.key, required this.egg, required this.view});
  final CanonicalEggView egg;
  final CanonicalGameSnapshot view;
  @override
  State<CanonicalNestClock> createState() => _CanonicalNestClockState();
}

class _CanonicalNestClockState extends State<CanonicalNestClock> {
  final _elapsed = Stopwatch()..start();
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(CanonicalNestClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.view.serverTime != widget.view.serverTime) _elapsed.reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsed.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final remaining = widget.egg.hatchAt!
        .difference(widget.view.serverTime.add(_elapsed.elapsed));
    final ready = remaining <= Duration.zero;
    final actions = CanonicalGameActions(context.read<CanonicalGameSession>());
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(ready
              ? strings.pick('Ready to hatch', 'Klaar om uit te komen')
              : '${strings.pick('In the nest', 'In het nest')} · ${remaining.inHours}h ${remaining.inMinutes % 60}m ${remaining.inSeconds % 60}s')),
      CanonicalActionButton(
          key: const Key('canonical-hatch-egg'),
          label: strings.pick('Hatch', 'Uitbroeden'),
          action: ready ? () => actions.hatchEgg(widget.egg.id) : null),
    ]);
  }
}
