import '../widgets/compact_egg_hatch_time.dart';
import '../widgets/restored_collection_cards.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../theme/app_theme.dart';
import '../widgets/game_icon_sprite.dart';
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

String canonicalKnownRarity(AppStrings strings, String? value) =>
    switch (value) {
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
  const CanonicalEggList({super.key, this.onPlace, this.forAltar = false});
  final bool forAltar;
  final void Function(String)? onPlace;
  @override
  State<CanonicalEggList> createState() => _CanonicalEggListState();
}

class _CanonicalEggListState extends State<CanonicalEggList> {
  String _kind = 'all';
  int _tagFilter = 0;
  @override
  Widget build(BuildContext context) {
    final view = context.watch<CanonicalGameSession>().snapshot;
    if (view == null) return const SizedBox.shrink();
    final strings = AppStrings.of(context);
    final session = context.read<CanonicalGameSession>();
    final prefs = view.profile.preferences;
    final sort = prefs['eggInventorySortMode'] == 'hatchTime'
        ? 'hatchTime'
        : 'acquiredAt';
    final descending = prefs['eggInventorySortDescending'] == true;
    void preference(Map<String, dynamic> changes) => runShopAction(
        context, () => CanonicalGameActions(session).setPreferences(changes));
    final compact = prefs['eggInventoryViewMode'] == 'list';
    if (_kind != 'all' && !view.eggs.any((e) => e.kind == _kind)) _kind = 'all';
    final eggs = view.eggs
        .where((e) =>
            (_kind == 'all' || e.kind == _kind) &&
            (_tagFilter == 0 || e.tagged == (_tagFilter == 1)))
        .toList()
      ..sort((a, b) {
        final order = prefs['eggInventorySortMode'] == 'hatchTime'
            ? a.incubation.compareTo(b.incubation)
            : a.acquiredAt.compareTo(b.acquiredAt);
        return order == 0
            ? a.id.compareTo(b.id)
            : prefs['eggInventorySortDescending'] == true
                ? -order
                : order;
      });
    if (widget.onPlace != null || widget.forAltar) {
      final available = eggs
          .where((e) => widget.onPlace == null || e.location == 'stash')
          .toList();
      return Column(children: [
        Text(strings.pick('Choose an egg', 'Kies een ei'),
            style: Theme.of(context).textTheme.titleLarge),
        Wrap(spacing: 8, children: [
          for (var i = 0; i < 3; i++)
            ChoiceChip(
                label: Text([
                  strings.pick('All', 'Alle'),
                  strings.pick('Tagged', 'Getagd'),
                  strings.pick('Untagged', 'Niet getagd')
                ][i]),
                selected: _tagFilter == i,
                onSelected: (_) => setState(() => _tagFilter = i)),
        ]),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                  child: Text(strings.pick('${available.length} eggs',
                      '${available.length} eieren'))),
              PopupMenuButton<String>(
                  key: const Key('altar-egg-sort'),
                  onSelected: (value) => preference({
                        'eggInventorySortMode': value,
                        'eggInventorySortDescending':
                            value == sort ? !descending : value == 'acquiredAt'
                      }),
                  itemBuilder: (_) => [
                        PopupMenuItem(
                            value: 'acquiredAt',
                            child: Text(strings.pick('Received', 'Ontvangen'))),
                        PopupMenuItem(
                            value: 'hatchTime',
                            child:
                                Text(strings.pick('Hatch time', 'Broedtijd')))
                      ],
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(sort == 'acquiredAt'
                          ? strings.pick('Received', 'Ontvangen')
                          : strings.pick('Hatch time', 'Broedtijd')))),
            ])),
        Expanded(
            child: ListView(children: [
          for (final egg in available)
            ListTile(
                key: Key('canonical-egg-${egg.id}'),
                leading: SizedBox(
                    width: 48, child: CanonicalEggArt(egg: egg, height: 48)),
                title: Text(canonicalEggName(strings, egg)),
                subtitle: widget.onPlace != null &&
                        egg.returnBlockReason != null
                    ? Text(
                        gameConnectionMessage(strings, egg.returnBlockReason))
                    : egg.revealedRarity == null
                        ? null
                        : Text(
                            canonicalKnownRarity(strings, egg.revealedRarity)),
                trailing: IconButton(
                    icon: Icon(egg.tagged
                        ? Icons.label_rounded
                        : Icons.label_outline_rounded),
                    tooltip: strings.pick(egg.tagged ? 'Untag egg' : 'Tag egg',
                        egg.tagged ? 'Ei ontaggen' : 'Ei taggen'),
                    onPressed: session.canAct
                        ? () => runShopAction(
                            context,
                            () => CanonicalGameActions(session)
                                .tagEgg(egg.id, !egg.tagged))
                        : null),
                onTap: () => showCanonicalEggDetails(context, egg.id,
                    onPlace: widget.onPlace, forAltar: true)),
        ])),
      ]);
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (widget.onPlace != null)
        Text(strings.pick('Choose an egg', 'Kies een ei'),
            style: Theme.of(context).textTheme.titleLarge),
      Wrap(alignment: WrapAlignment.center, spacing: 6, children: [
        for (var i = 0; i < 3; i++)
          ChoiceChip(
              label: Text([
                strings.pick('All', 'Alle'),
                strings.pick('Tagged', 'Getagd'),
                strings.pick('Untagged', 'Niet getagd')
              ][i]),
              selected: _tagFilter == i,
              onSelected: (_) => setState(() => _tagFilter = i)),
      ]),
      const SizedBox(height: 8),
      Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 7,
          children: [
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                    color: const Color(0xFFF1ECFB),
                    borderRadius: BorderRadius.circular(99)),
                child: Text(
                    '${eggs.length} ${strings.pick(eggs.length == 1 ? 'egg' : 'eggs', eggs.length == 1 ? 'ei' : 'eieren')}',
                    key: const Key('egg-inventory-count'),
                    style: const TextStyle(
                        color: AppColors.twilight,
                        fontWeight: FontWeight.w900))),
            Row(mainAxisSize: MainAxisSize.min, children: [
              PopupMenuButton<String>(
                  key: const Key('egg-inventory-sort'),
                  enabled: session.canAct,
                  initialValue: sort,
                  onSelected: (value) => preference({
                        'eggInventorySortMode': value,
                        'eggInventorySortDescending':
                            value == sort ? !descending : value == 'acquiredAt',
                      }),
                  itemBuilder: (_) => [
                        PopupMenuItem(
                            value: 'acquiredAt',
                            child: Text(strings.pick('Received', 'Ontvangen'))),
                        PopupMenuItem(
                            value: 'hatchTime',
                            child:
                                Text(strings.pick('Hatch time', 'Broedtijd'))),
                      ],
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF1ECFB),
                          borderRadius: BorderRadius.circular(99)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                            descending
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 16,
                            color: AppColors.twilight),
                        const SizedBox(width: 4),
                        Text(
                            sort == 'acquiredAt'
                                ? strings.pick('Received', 'Ontvangen')
                                : strings.pick('Hatch time', 'Broedtijd'),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.twilight)),
                      ]))),
              IconButton.filledTonal(
                  key: const Key('egg-inventory-view-toggle'),
                  tooltip: compact
                      ? strings.pick('Show tiles', 'Tegels tonen')
                      : strings.pick('Show list', 'Lijst tonen'),
                  onPressed: session.canAct
                      ? () => preference(
                          {'eggInventoryViewMode': compact ? 'tiles' : 'list'})
                      : null,
                  icon: Icon(compact
                      ? Icons.grid_view_rounded
                      : Icons.view_list_rounded)),
              IconButton(
                  key: const Key('canonical-egg-filter'),
                  tooltip:
                      strings.pick('Filter and sort', 'Filteren en sorteren'),
                  onPressed: () => _filter(context),
                  icon: const Icon(Icons.tune_rounded)),
            ]),
          ]),
      const SizedBox(height: 8),
      if (!compact)
        LayoutBuilder(
            builder: (context, constraints) =>
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final egg in eggs)
                    SizedBox(
                        width: constraints.maxWidth < 240
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 8) / 2,
                        child: Card(
                            child: InkWell(
                                key: Key('canonical-egg-${egg.id}'),
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => showCanonicalEggDetails(
                                    context, egg.id,
                                    onPlace: widget.onPlace,
                                    forAltar: widget.forAltar),
                                child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(children: [
                                      Stack(children: [
                                        Center(
                                            child: CanonicalEggArt(
                                                egg: egg, height: 125)),
                                        if (egg.tagged)
                                          const Positioned(
                                              top: 0,
                                              right: 0,
                                              child: Icon(
                                                  Icons.bookmark_rounded,
                                                  size: 20,
                                                  color: AppColors.twilight)),
                                      ]),
                                      Text(canonicalEggName(strings, egg),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 3),
                                      Text(
                                          strings.remainingDuration(
                                              egg.incubation),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 5),
                                      Text(egg.hint(strings.languageCode),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 10.5,
                                              fontStyle: FontStyle.italic)),
                                      if (view.inventory.reservedEggIds
                                          .contains(egg.id)) ...[
                                        const SizedBox(height: 5),
                                        Text(
                                            strings.pick('Reserved for trade',
                                                'Gereserveerd voor ruil'),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.twilight,
                                                fontWeight: FontWeight.w800)),
                                      ],
                                    ]))))),
                ])),
      if (compact)
        for (final egg in eggs)
          Card(
              child: ListTile(
            key: Key('canonical-egg-${egg.id}'),
            leading: SizedBox(
                width: 48, child: CanonicalEggArt(egg: egg, height: 48)),
            title: Text(canonicalEggName(strings, egg)),
            subtitle: Text('${strings.remainingDuration(egg.incubation)} · '
                '${strings.pick('Received', 'Ontvangen')} ${MaterialLocalizations.of(context).formatShortDate(egg.acquiredAt.toLocal())}'
                '${view.inventory.reservedEggIds.contains(egg.id) ? strings.pick(' · Reserved', ' · Gereserveerd') : ''}'),
            trailing:
                Icon(egg.tagged ? Icons.bookmark_rounded : Icons.info_outline),
            onTap: () => showCanonicalEggDetails(context, egg.id,
                onPlace: widget.onPlace, forAltar: widget.forAltar),
          )),
      if (eggs.isEmpty)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(children: [
              const GameIconSprite(GameIconKind.inventoryEggs, size: 88),
              const SizedBox(height: 10),
              Text(
                  view.eggs.isEmpty
                      ? strings.pick('No Eggs in your inventory yet.',
                          'Nog geen Eieren in je inventaris.')
                      : strings.pick('No eggs match these filters.',
                          'Geen eieren met deze filters.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted)),
            ])),
    ]);
  }

  Future<void> _filter(BuildContext context) async {
    final original = context.read<CanonicalGameSession>().snapshot;
    if (original == null) return;
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(builder: (context, update) {
              final strings = AppStrings.of(context);
              final session = context.watch<CanonicalGameSession>();
              final current = session.snapshot?.ownerId == original.ownerId;
              final prefs = current
                  ? session.snapshot!.profile.preferences
                  : original.profile.preferences;
              final order = prefs['eggInventorySortMode'] == 'hatchTime'
                  ? 'shortest'
                  : prefs['eggInventorySortDescending'] == true
                      ? 'newest'
                      : 'oldest';
              void preference(Map<String, dynamic> changes) {
                if (!mounted || !current) {
                  Navigator.pop(context);
                  return;
                }
                runShopAction(
                    context,
                    () =>
                        CanonicalGameActions(session).setPreferences(changes));
              }

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
                                    if ((session.snapshot ?? original)
                                        .eggs
                                        .any((e) => e.kind == 'ordinary'))
                                      'ordinary':
                                          strings.pick('Ordinary', 'Gewoon'),
                                    if ((session.snapshot ?? original)
                                        .eggs
                                        .any((e) => e.kind == 'sinister'))
                                      'sinister': 'Sinister',
                                    if ((session.snapshot ?? original)
                                        .eggs
                                        .any((e) => e.kind == 'special'))
                                      'special': 'Special',
                                  }.entries)
                                    ChoiceChip(
                                        label: Text(entry.value),
                                        selected: _kind == entry.key,
                                        onSelected: (_) =>
                                            change(() => _kind = entry.key))
                                ]),
                                IconButton(
                                    tooltip: strings.pick(
                                        'Change view', 'Weergave wijzigen'),
                                    icon: Icon(
                                        prefs['eggInventoryViewMode'] == 'list'
                                            ? Icons.grid_view
                                            : Icons.view_list),
                                    onPressed: session.canAct
                                        ? () => preference({
                                              'eggInventoryViewMode':
                                                  prefs['eggInventoryViewMode'] ==
                                                          'list'
                                                      ? 'tiles'
                                                      : 'list'
                                            })
                                        : null),
                                SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(strings.pick(
                                        'Tagged only', 'Alleen getagd')),
                                    value: _tagFilter == 1,
                                    onChanged: (value) => change(
                                        () => _tagFilter = value ? 1 : 0)),
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
                                      trailing: order == entry.key
                                          ? const Icon(Icons.check)
                                          : null,
                                      onTap: session.canAct
                                          ? () => preference({
                                                'eggInventorySortMode':
                                                    entry.key == 'shortest'
                                                        ? 'hatchTime'
                                                        : 'acquiredAt',
                                                'eggInventorySortDescending':
                                                    entry.key == 'newest',
                                              })
                                          : null),
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(strings.pick('Done', 'Klaar'))),
                              ]))));
            }));
  }
}

class _InventoryEggDetails extends StatelessWidget {
  const _InventoryEggDetails(
      {required this.egg, required this.view, required this.enabled});
  final CanonicalEggView egg;
  final CanonicalGameSnapshot view;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final actions = CanonicalGameActions(context.read<CanonicalGameSession>());
    final reserved = view.inventory.reservedEggIds.contains(egg.id);
    final lineage =
        dragonLineages.where((l) => l.id == egg.revealedLineageId).firstOrNull;
    final moral = MoralAxis.values
        .where((v) => v.name == egg.revealedMoralAxis)
        .firstOrNull;
    final law =
        LawAxis.values.where((v) => v.name == egg.revealedLawAxis).firstOrNull;
    return SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CanonicalEggArt(egg: egg, height: 126),
              Text(canonicalEggName(s, egg),
                  style: Theme.of(context).textTheme.titleLarge),
              OutlinedButton.icon(
                  key: const Key('canonical-tag-egg'),
                  onPressed: enabled
                      ? () => runShopAction(
                          context, () => actions.tagEgg(egg.id, !egg.tagged))
                      : null,
                  icon: Icon(egg.tagged
                      ? Icons.label_rounded
                      : Icons.label_outline_rounded),
                  label: Text(egg.tagged
                      ? s.pick('Untag egg', 'Ei ontaggen')
                      : s.pick('Tag egg', 'Ei taggen'))),
              Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (lineage != null)
                      Chip(label: Text(s.lineageName(lineage))),
                    if (egg.revealedRarity != null)
                      Chip(
                          label: Text(
                              canonicalKnownRarity(s, egg.revealedRarity))),
                    if (moral != null)
                      Chip(label: Text(s.moralAxisName(moral))),
                    if (law != null) Chip(label: Text(s.lawAxisName(law))),
                  ]),
              const SizedBox(height: 10),
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: AppColors.eventColor(
                          context, const Color(0xFFF5F0FC)),
                      borderRadius: BorderRadius.circular(18)),
                  child: Text(egg.hint(s.languageCode),
                      key: Key('inventory-egg-clue-${egg.id}'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.35,
                          fontStyle: FontStyle.italic))),
              const SizedBox(height: 12),
              if (egg.revealedRarity != null)
                ListTile(
                    dense: true,
                    leading: const Icon(Icons.auto_awesome_rounded),
                    title: Text(s.pick('Rarity', 'Zeldzaamheid')),
                    trailing: Text(canonicalKnownRarity(s, egg.revealedRarity),
                        style: const TextStyle(fontWeight: FontWeight.w900)))
              else if ((view.inventory.usableRelics[MysticRelic.astralLens] ??
                      0) >
                  0)
                ListTile(
                    key: const Key('canonical-use-drop-lens'),
                    leading: Image.asset(MysticRelic.astralLens.assetPath,
                        width: 38, height: 38),
                    title: Text(s.pick('Reveal rarity with Astral Lens',
                        'Onthul zeldzaamheid met Astrale Lens')),
                    onTap: enabled && !reserved
                        ? () => runShopAction(
                            context, () => actions.useLens(egg.id))
                        : null),
              ListTile(
                  dense: true,
                  leading: const Icon(Icons.schedule_rounded),
                  title: Text(s.pick(
                      'Incubation after nesting', 'Broedtijd na plaatsing')),
                  trailing: Text(s.remainingDuration(egg.incubation),
                      style: const TextStyle(fontWeight: FontWeight.w900))),
              if (reserved)
                ListTile(
                    dense: true,
                    leading: const Icon(Icons.swap_horiz_rounded),
                    title: Text(s.pick(
                        'Reserved for trade', 'Gereserveerd voor ruil'))),
              if (egg.location == 'stash')
                SizedBox(
                    width: double.infinity,
                    child: CanonicalActionButton(
                        key: const Key('canonical-incubate-egg'),
                        primary: true,
                        icon: Icons.egg_alt_rounded,
                        label: s.pick('Incubate', 'Broed uit'),
                        confirmation: s.pick('Start incubating this egg?',
                            'Dit ei uitbroeden in het nest?'),
                        action: enabled && !reserved && view.nest == null
                            ? () => actions.activateEgg(egg.id)
                            : null)),
              if (egg.location == 'nest') ...[
                CanonicalNestClock(egg: egg, view: view),
                for (final reduction
                    in view.inventory.chronoshards.toSet().toList()..sort())
                  CanonicalActionButton(
                      key: Key('canonical-chronoshard-$reduction'),
                      label: 'Chronoshard \u00b7 $reduction%',
                      confirmation: s.pick('Use this Chronoshard?',
                          'Deze Chronoshard gebruiken?'),
                      action:
                          enabled && view.inventory.canUseChronoshard(reduction)
                              ? () => actions.useChronoshard(reduction)
                              : null),
              ],
            ])));
  }
}

Future<void> showCanonicalEggDetails(BuildContext context, String id,
    {void Function(String)? onPlace, bool forAltar = false}) async {
  final owner = context.read<CanonicalGameSession>().snapshot?.ownerId;
  if (owner == null) return;
  await showModalBottomSheet<void>(
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      builder: (context) => CanonicalEntityDialog(
          ownerId: owner,
          builder: (context, view, enabled) {
            final strings = AppStrings.of(context);
            final egg = view.egg(id);
            final session = context.read<CanonicalGameSession>();
            final actions = CanonicalGameActions(session);
            final reserved = view.inventory.reservedEggIds.contains(id);
            final unknown = strings.pick('Still hidden', 'Nog verborgen');
            final lineage = dragonLineages
                .where((l) => l.id == egg?.revealedLineageId)
                .firstOrNull;
            if (egg != null && !forAltar && onPlace == null) {
              return _InventoryEggDetails(
                  egg: egg, view: view, enabled: enabled);
            }
            return RestoredDetailSheet(
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
                                  Row(children: [
                                    Container(
                                        width: 88,
                                        height: 96,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            gradient: AppColors.panelGradient(
                                                context,
                                                fallback: const LinearGradient(
                                                    colors: [
                                                      Color(0xFFF3EDF9),
                                                      Color(0xFFE9DEF6)
                                                    ]))),
                                        child: CanonicalEggArt(
                                            egg: egg, height: 80)),
                                    const SizedBox(width: 14),
                                    Expanded(
                                        child: Text(
                                            canonicalEggName(strings, egg),
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800))),
                                  ]),
                                  const SizedBox(height: 18),
                                  _EggDetailLine(
                                      label: strings.pick(
                                          'Dragon family', 'Drakenfamilie'),
                                      value: lineage == null
                                          ? unknown
                                          : strings.lineageName(lineage)),
                                  _EggDetailLine(
                                      label: strings.pick(
                                          'Rarity', 'Zeldzaamheid'),
                                      value: egg.revealedRarity == null
                                          ? unknown
                                          : canonicalKnownRarity(
                                              strings, egg.revealedRarity)),
                                  _EggDetailLine(
                                      label: strings.pick(
                                          'Moral alignment', 'Morele aard'),
                                      value: switch (MoralAxis.values
                                          .where((v) =>
                                              v.name == egg.revealedMoralAxis)
                                          .firstOrNull) {
                                        final value? =>
                                          strings.moralAxisName(value),
                                        null => unknown
                                      }),
                                  _EggDetailLine(
                                      label: strings.pick(
                                          'Order alignment', 'Orde-aard'),
                                      value: switch (LawAxis.values
                                          .where((v) =>
                                              v.name == egg.revealedLawAxis)
                                          .firstOrNull) {
                                        final value? =>
                                          strings.lawAxisName(value),
                                        null => unknown
                                      }),
                                  _EggDetailLine(
                                      label: strings.pick(
                                          'Incubation', 'Broedtijd'),
                                      value: strings
                                          .remainingDuration(egg.incubation)),
                                  _EggDetailLine(
                                      label:
                                          strings.pick('Acquired', 'Verkregen'),
                                      value: MaterialLocalizations.of(context)
                                          .formatMediumDate(
                                              egg.acquiredAt.toLocal())),
                                  const SizedBox(height: 12),
                                  Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFFAF6EE),
                                          borderRadius:
                                              BorderRadius.circular(18)),
                                      child: Text(
                                          egg.hint(strings.languageCode),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              height: 1.35,
                                              fontStyle: FontStyle.italic,
                                              color: Color(0xFF756447)))),
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
  const CanonicalNestClock(
      {super.key,
      required this.egg,
      required this.view,
      this.showHatchButton = true,
      this.compact = false});
  final bool compact;
  final bool showHatchButton;
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
    if (widget.compact) {
      return Text(formatCompactEggHatchTime(remaining),
          key: const Key('tower-nest-hatch-remaining'),
          maxLines: 1,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()]));
    }
    final actions = CanonicalGameActions(context.read<CanonicalGameSession>());
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(ready
              ? strings.pick('Ready to hatch', 'Klaar om uit te komen')
              : '${strings.pick('In the nest', 'In het nest')} · ${remaining.inHours}h ${remaining.inMinutes % 60}m ${remaining.inSeconds % 60}s')),
      if (widget.showHatchButton)
        CanonicalActionButton(
            key: const Key('canonical-hatch-egg'),
            label: strings.pick('Hatch', 'Uitbroeden'),
            action: ready ? () => actions.hatchEgg(widget.egg.id) : null),
    ]);
  }
}

class _EggDetailLine extends StatelessWidget {
  const _EggDetailLine({required this.label, required this.value});
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
