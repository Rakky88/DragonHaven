import '../widgets/restored_collection_cards.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_lineage.dart';
import '../models/egg_altar.dart';
import '../models/dragon_school.dart';
import '../models/mystic_relic.dart';
import '../models/pet.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_game_snapshot.dart';
import '../widgets/canonical_game_controls.dart';
import '../widgets/dragon_art.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/expertise_score_badge.dart';
import '../widgets/shop_economy_scope.dart';

String canonicalDragonName(AppStrings strings, CanonicalDragonView dragon) {
  if (dragon.name.trim().isNotEmpty) return dragon.name;
  final lineage =
      dragonLineages.where((l) => l.id == dragon.lineageId).firstOrNull;
  return lineage == null
      ? strings.pick('Dragon', 'Draak')
      : strings.lineageName(lineage);
}

String _stageName(AppStrings strings, DragonStage stage) =>
    strings.petStageNameByKey(switch (stage) {
      DragonStage.egg => 'moonEgg',
      DragonStage.hatchling => 'spark',
      DragonStage.wyrmling => 'nestDragon',
      DragonStage.ascended => 'homeGuardian',
    });

class CanonicalDragonArt extends StatelessWidget {
  const CanonicalDragonArt({super.key, required this.dragon, this.height = 80});
  final CanonicalDragonView dragon;
  final double height;
  @override
  Widget build(BuildContext context) =>
      !dragonLineages.any((l) => l.id == dragon.lineageId)
          ? SizedBox(height: height, child: const Icon(Icons.help_outline))
          : DragonArt(
              height: height,
              animate: false,
              lineageId: dragon.lineageId,
              stageKey: switch (dragon.stage) {
                DragonStage.hatchling => 'spark',
                DragonStage.wyrmling => 'nestDragon',
                _ => 'homeGuardian',
              },
              evolutionPath: dragon.path,
              prismatic: dragon.spectral,
              sinister: dragon.sinister);
}

class CanonicalDragonsScreen extends StatelessWidget {
  const CanonicalDragonsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ShopEconomyBoundary(child: _DragonList());
}

class _DragonList extends StatefulWidget {
  const _DragonList();
  @override
  State<_DragonList> createState() => _DragonListState();
}

class _DragonListState extends State<_DragonList> {
  final _stages = <DragonStage>{};
  final _rarities = <String>{};
  bool _spectral = false;

  @override
  Widget build(BuildContext context) {
    final view = context.watch<CanonicalGameSession>().snapshot!;
    final strings = AppStrings.of(context);
    final session = context.read<CanonicalGameSession>();
    final prefs = view.profile.preferences;
    final compact = prefs['myDragonsViewMode'] == 'compact';
    final descending = prefs['myDragonsSortDescending'] == true;
    final sort = prefs['myDragonsSortMode'] as String;
    final dragons = view.dragons
        .where((d) =>
            d.owned &&
            (_stages.isEmpty || _stages.contains(d.stage)) &&
            (_rarities.isEmpty ||
                _rarities.contains(dragonLineages
                    .firstWhere((l) => l.id == d.lineageId)
                    .rarity
                    .name)) &&
            (!_spectral || d.spectral))
        .toList()
      ..sort((a, b) {
        final compared = switch (sort) {
          'name' => canonicalDragonName(strings, a)
              .toLowerCase()
              .compareTo(canonicalDragonName(strings, b).toLowerCase()),
          'rarity' => dragonLineages
              .firstWhere((l) => l.id == a.lineageId)
              .rarity
              .index
              .compareTo(dragonLineages
                  .firstWhere((l) => l.id == b.lineageId)
                  .rarity
                  .index),
          _ => a.acquiredAt.compareTo(b.acquiredAt),
        };
        return compared == 0
            ? a.id.compareTo(b.id)
            : descending
                ? -compared
                : compared;
      });
    void change(Map<String, dynamic> values) => runShopAction(
        context, () => CanonicalGameActions(session).setPreferences(values));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(strings.pick('My dragons', 'Mijn draken'),
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: PopupMenuButton<String>(
                tooltip: strings.pick(
                    'Change dragon order', 'Volgorde van draken wijzigen'),
                onSelected: session.canAct
                    ? (value) => change({'myDragonsSortMode': value})
                    : null,
                itemBuilder: (_) => [
                      for (final entry in {
                        'acquiredAt': strings.pick('Received', 'Ontvangen'),
                        'name': strings.pick('Name', 'Naam'),
                        'rarity': strings.pick('Rarity', 'Zeldzaamheid')
                      }.entries)
                        PopupMenuItem(
                            value: entry.key, child: Text(entry.value)),
                    ],
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF1ECFB),
                        borderRadius: BorderRadius.circular(99)),
                    child: Text(
                        switch (sort) {
                          'name' => strings.pick('Name', 'Naam'),
                          'rarity' => strings.pick('Rarity', 'Zeldzaamheid'),
                          _ => strings.pick('Received', 'Ontvangen')
                        },
                        style: const TextStyle(
                            color: AppColors.twilight,
                            fontSize: 11,
                            fontWeight: FontWeight.w900))))),
        IconButton.filledTonal(
            key: const Key('canonical-dragon-filter'),
            tooltip: strings.pick('Filter dragons', 'Draken filteren'),
            icon: const Icon(Icons.filter_alt_rounded),
            onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) =>
                    StatefulBuilder(builder: (context, update) {
                      void filter(VoidCallback change) {
                        if (mounted) {
                          setState(change);
                          update(() {});
                        }
                      }

                      return SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                    strings.pick(
                                        'Filter dragons', 'Draken filteren'),
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 12),
                                Wrap(spacing: 8, children: [
                                  for (final stage in DragonStage.values
                                      .where((s) => s != DragonStage.egg))
                                    FilterChip(
                                        label: Text(_stageName(strings, stage)),
                                        selected: _stages.contains(stage),
                                        onSelected: (v) => filter(() => v
                                            ? _stages.add(stage)
                                            : _stages.remove(stage)))
                                ]),
                                Wrap(spacing: 8, children: [
                                  for (final rarity in dragonLineages
                                      .map((l) => l.rarity)
                                      .toSet())
                                    FilterChip(
                                        label: Text(strings.lineageRarity(
                                            dragonLineages.firstWhere(
                                                (l) => l.rarity == rarity))),
                                        selected:
                                            _rarities.contains(rarity.name),
                                        onSelected: (v) => filter(() => v
                                            ? _rarities.add(rarity.name)
                                            : _rarities.remove(rarity.name)))
                                ]),
                                SwitchListTile(
                                    title: Text(strings.pick(
                                        'Spectral only', 'Alleen Spectral')),
                                    value: _spectral,
                                    onChanged: (v) =>
                                        filter(() => _spectral = v)),
                              ]));
                    }))),
        IconButton(
            tooltip: strings.pick('Reverse order', 'Volgorde omkeren'),
            icon: Icon(descending ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: session.canAct
                ? () => change({'myDragonsSortDescending': !descending})
                : null),
        IconButton(
            tooltip: strings.pick('Change view', 'Weergave wijzigen'),
            icon: Icon(compact ? Icons.grid_view : Icons.view_list),
            onPressed: session.canAct
                ? () => change(
                    {'myDragonsViewMode': compact ? 'gallery' : 'compact'})
                : null),
      ]),
      if (!compact)
        LayoutBuilder(
            builder: (context, box) =>
                Wrap(spacing: 9, runSpacing: 9, children: [
                  for (final dragon in dragons)
                    SizedBox(
                        width: (box.maxWidth - 9) / 2,
                        height: (box.maxWidth - 9) / 2 + 42,
                        child: _DragonGalleryCard(
                            dragon: dragon,
                            equippedRelic: view.inventory.equippedOn(dragon.id),
                            onTap: () => showCanonicalDragonDetails(
                                context, dragon.id))),
                ])),
      if (compact)
        for (final dragon in dragons)
          Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _DragonCompactCard(
                  dragon: dragon,
                  equippedRelic: view.inventory.equippedOn(dragon.id),
                  onTap: () => showCanonicalDragonDetails(context, dragon.id))),
      if (!view.dragons.any((d) => d.owned))
        RestoredCollectionEmpty(
            icon: GameIconKind.myDragons,
            text: strings.pick('Your dragons will appear here after hatching.',
                'Je draken komen hier na het uitbroeden.')),
    ]);
  }
}

Future<void> showCanonicalDragonDetails(BuildContext context, String id) async {
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
            final dragon = view.dragon(id);
            final actions =
                CanonicalGameActions(context.read<CanonicalGameSession>());
            final lineage = dragonLineages
                .where((l) => l.id == dragon?.lineageId)
                .firstOrNull;
            final unknown = strings.pick('Undiscovered', 'Niet ontdekt');
            return RestoredDetailSheet(
                title: Text(dragon == null
                    ? strings.pick('Dragon', 'Draak')
                    : canonicalDragonName(strings, dragon)),
                content: SizedBox(
                    width: 390,
                    child: SingleChildScrollView(
                        child: dragon == null || !dragon.owned
                            ? Text(strings.pick(
                                'This dragon is no longer in your Haven.',
                                'Deze draak woont niet meer in je Haven.'))
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                    CanonicalDragonArt(
                                        dragon: dragon, height: 190),
                                    _Fact(
                                        strings.pick(
                                            'Dragon type', 'Drakentype'),
                                        lineage == null
                                            ? unknown
                                            : strings.lineageName(lineage)),
                                    _Fact(
                                        strings.pick('Maturity', 'Levensfase'),
                                        _stageName(strings, dragon.stage)),
                                    _Fact(
                                        strings.pick('Gender', 'Geslacht'),
                                        strings.pick(
                                            dragon.sex == DragonSex.male
                                                ? 'Male'
                                                : 'Female',
                                            dragon.sex == DragonSex.male
                                                ? 'Mannelijk'
                                                : 'Vrouwelijk'),
                                        icon: dragon.sex == DragonSex.male
                                            ? Icons.male
                                            : Icons.female),
                                    const SizedBox(height: 12),
                                    _DragonSchoolDiplomaCard(dragon: dragon),
                                    const Divider(height: 24),
                                    RestoredNeedBar(
                                        icon: Icons
                                            .sentiment_very_satisfied_rounded,
                                        label: strings.pick('Joy', 'Plezier'),
                                        value: dragon.joy,
                                        color: AppColors.coral),
                                    RestoredNeedBar(
                                        icon: Icons.bolt_rounded,
                                        label:
                                            strings.pick('Energy', 'Energie'),
                                        value: dragon.energy,
                                        color: AppColors.gold),
                                    RestoredNeedBar(
                                        icon: Icons.shield_moon_rounded,
                                        label:
                                            strings.pick('Comfort', 'Comfort'),
                                        value: dragon.comfort,
                                        color: AppColors.mint),
                                    if (view.activeDragonId == id)
                                      CanonicalActionButton(
                                          key: const Key(
                                              'canonical-starlight-treat'),
                                          label: strings.pick(
                                              'Starlight Treat · 3 gems',
                                              'Sterlichtsnack · 3 gems'),
                                          confirmation: strings.pick(
                                              'Spend 3 gems on a Starlight Treat for this dragon?',
                                              '3 gems uitgeven aan een Sterlichtsnack voor deze draak?'),
                                          action: enabled && view.gems >= 3
                                              ? () =>
                                                  actions.buyStarlightTreat(id)
                                              : null),
                                    const SizedBox(height: 12),
                                    Text(strings.pick(
                                        'Tap an expertise to highlight it for training.',
                                        'Tik op een expertise om deze voor training te markeren.')),
                                    DragonExpertiseStatus(
                                        dragonId: dragon.id,
                                        maxed: dragon.expertiseMaxed,
                                        spark: dragon.dragonSpark),
                                    for (final focus in TrainingFocus.values)
                                      _HighlightControl(
                                          dragon: dragon, focus: focus),
                                    const Divider(height: 24),
                                    _Fact(
                                        strings.pick(
                                            'Moral nature', 'Morele aard'),
                                        switch (MoralAxis.values
                                            .where((v) =>
                                                v.name == dragon.moralAxis)
                                            .firstOrNull) {
                                          final axis? =>
                                            strings.moralAxisName(axis),
                                          null => unknown,
                                        }),
                                    _Fact(
                                        strings.pick(
                                            'Order nature', 'Orde-aard'),
                                        switch (LawAxis.values
                                            .where(
                                                (v) => v.name == dragon.lawAxis)
                                            .firstOrNull) {
                                          final axis? =>
                                            strings.lawAxisName(axis),
                                          null => unknown,
                                        }),
                                    _Fact(
                                        strings.pick(
                                            'Personality', 'Persoonlijkheid'),
                                        dragon.personality
                                                ?.map(strings.personality)
                                                .join(', ') ??
                                            unknown),
                                    Text(
                                        '${dragon.xp} XP · ${strings.pick('Level', 'Level')} ${Pet.levelAtXp(dragon.xp)}'),
                                    const SizedBox(height: 12),
                                    CanonicalActionButton(
                                        key: const Key(
                                            'canonical-favorite-dragon'),
                                        label: dragon.favorite
                                            ? strings.pick('Favorite dragon',
                                                'Favoriete draak')
                                            : strings.pick('Set as favorite',
                                                'Als favoriet instellen'),
                                        action: enabled && !dragon.favorite
                                            ? () =>
                                                actions.setFavoriteDragon(id)
                                            : null),
                                    CanonicalActionButton(
                                        key: const Key('canonical-roam-dragon'),
                                        label: dragon.roamsTower
                                            ? strings.pick('Rest in sanctuary',
                                                'Rust in het reservaat')
                                            : strings.pick('Roam the Tower',
                                                'Door de Toren lopen'),
                                        action: enabled
                                            ? () => actions.setDragonRoaming(
                                                id, !dragon.roamsTower)
                                            : null),
                                    OutlinedButton(
                                        key: const Key('canonical-name-dragon'),
                                        onPressed: enabled &&
                                                (dragon.name.trim().isEmpty ||
                                                    view.inventory.count(AltarRelic
                                                            .nameweaversQuill) >
                                                        0)
                                            ? () => nameCanonicalDragon(
                                                context, dragon, owner, actions)
                                            : null,
                                        child: Text(dragon.name.trim().isEmpty
                                            ? strings.pick(
                                                'Name dragon', 'Geef een naam')
                                            : strings.pick('Rename · 1 Quill',
                                                'Hernoemen · 1 Quill'))),
                                    if (dragon.evolutionReady)
                                      CanonicalActionButton(
                                          key: const Key(
                                              'canonical-evolve-dragon'),
                                          label: strings.pick(
                                              'Evolve', 'Evolueren'),
                                          action: enabled
                                              ? () => actions.evolveDragon(id)
                                              : null),
                                    for (final relic in MysticRelic.values)
                                      if ((view.inventory.usableRelics[relic] ??
                                                  0) >
                                              0 &&
                                          (relic.isEquipable ||
                                              relic.hasUseAnimation)) ...[
                                        const SizedBox(height: 8),
                                        Row(children: [
                                          Image.asset(relic.assetPath,
                                              width: 40, height: 40),
                                          const SizedBox(width: 8),
                                          Expanded(
                                              child: Text(
                                                  strings.relicName(relic)))
                                        ]),
                                        Text(strings.relicDescription(relic)),
                                        if (relic.isEquipable)
                                          CanonicalActionButton(
                                              key: Key(
                                                  'canonical-equip-${relic.name}'),
                                              label: view.inventory.equipment[relic] == id
                                                  ? strings.pick(
                                                      'Unequip', 'Afdoen')
                                                  : strings.pick(
                                                      'Equip', 'Uitrusten'),
                                              action: enabled
                                                  ? () => actions.equip(
                                                      relic,
                                                      view.inventory.equipment[relic] == id
                                                          ? null
                                                          : id)
                                                  : null)
                                        else
                                          CanonicalActionButton(
                                              key: Key(
                                                  'canonical-use-${relic.name}'),
                                              label: strings.pick(
                                                  'Use', 'Gebruiken'),
                                              confirmation: strings.pick(
                                                  'Use one ${strings.relicName(relic)} on this dragon?',
                                                  'Eén ${strings.relicName(relic)} op deze draak gebruiken?'),
                                              action: enabled && !dragon.knows(relic)
                                                  ? () => actions.useRelic(relic, id)
                                                  : null),
                                      ],
                                    const SizedBox(height: 16),
                                    CanonicalActionButton(
                                        key: const Key(
                                            'canonical-release-dragon'),
                                        label: strings.pick('Release dragon',
                                            'Draak vrijlaten'),
                                        confirmation: strings.pick(
                                            'Release this dragon from your Haven?',
                                            'Deze draak vrijlaten uit je Haven?'),
                                        action: enabled &&
                                                !dragon.favorite &&
                                                dragon.adventureId == null &&
                                                view.dragons
                                                        .where((d) => d.owned)
                                                        .length >
                                                    1
                                            ? () => actions.releaseDragon(id)
                                            : null),
                                  ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(strings.pick('Close', 'Sluiten')))
                ]);
          }));
}

class _HighlightControl extends StatelessWidget {
  const _HighlightControl({required this.dragon, required this.focus});
  final CanonicalDragonView dragon;
  final TrainingFocus focus;
  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final actions = CanonicalGameActions(session);
    final s = AppStrings.of(context);
    final highlighted = dragon.highlighted.contains(focus.name);
    final label = switch (focus) {
      TrainingFocus.might => s.pick('Might', 'Kracht'),
      TrainingFocus.arcana => 'Arcana',
      TrainingFocus.spirit => s.pick('Spirit', 'Geest'),
    };
    return Semantics(
        button: true,
        toggled: highlighted,
        enabled: session.canAct,
        child: InkWell(
            key: Key('canonical-highlight-${dragon.id}-${focus.name}'),
            borderRadius: BorderRadius.circular(12),
            onTap: session.canAct
                ? () => runShopAction(
                    context,
                    () => actions.setDragonHighlight(
                        dragon.id, focus, !highlighted))
                : null,
            child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ExpertiseScoreBadge(
                        dragonId: dragon.id,
                        focus: focus,
                        focusLabel: label,
                        score: dragon.training[focus.name]!,
                        maximum: dragon.maximum(focus),
                        highlighted: highlighted,
                        expand: true,
                        iconSize: 30)))));
  }
}

Future<void> nameCanonicalDragon(
    BuildContext context,
    CanonicalDragonView dragon,
    String owner,
    CanonicalGameActions actions) async {
  await showDialog<void>(
      context: context,
      builder: (_) =>
          _DragonNameDialog(dragon: dragon, owner: owner, actions: actions));
}

class _DragonNameDialog extends StatefulWidget {
  const _DragonNameDialog(
      {required this.dragon, required this.owner, required this.actions});
  final CanonicalDragonView dragon;
  final String owner;
  final CanonicalGameActions actions;
  @override
  State<_DragonNameDialog> createState() => _DragonNameDialogState();
}

class _DragonNameDialogState extends State<_DragonNameDialog> {
  late final controller = TextEditingController(text: widget.dragon.name);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CanonicalEntityDialog(
      ownerId: widget.owner,
      builder: (context, view, enabled) {
        final strings = AppStrings.of(context);
        return AlertDialog(
            title: Text(strings.pick('Dragon name', 'Drakennaam')),
            content: TextField(
                key: const Key('canonical-dragon-name-input'),
                controller: controller,
                maxLength: 24,
                enabled: enabled,
                decoration:
                    InputDecoration(labelText: strings.pick('Name', 'Naam'))),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(strings.pick('Cancel', 'Annuleren'))),
              CanonicalActionButton(
                  key: const Key('canonical-save-name'),
                  label: strings.pick('Save', 'Opslaan'),
                  action: enabled
                      ? () async {
                          await widget.actions
                              .nameDragon(widget.dragon.id, controller.text);
                          if (context.mounted) Navigator.pop(context);
                        }
                      : null)
            ]);
      });
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {this.icon});
  final String label, value;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(builder: (context, constraints) {
        final detail = Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 5)],
          Flexible(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ]);
        if (constraints.maxWidth <
            MediaQuery.textScalerOf(context).scale(260)) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                const SizedBox(height: 2),
                detail,
              ]);
        }
        return Row(children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 10),
          Flexible(child: detail),
        ]);
      }));
}

class _DragonGalleryCard extends StatelessWidget {
  const _DragonGalleryCard({
    required this.dragon,
    required this.equippedRelic,
    required this.onTap,
  });

  final CanonicalDragonView dragon;
  final MysticRelic? equippedRelic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: dragon.highlighted.isEmpty ? null : const Color(0xFFFFFAE9),
      shape: dragon.highlighted.isEmpty
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.gold),
            ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        key: Key('canonical-dragon-${dragon.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Stack(children: [
            Column(children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DragonArt(
                      height: 150,
                      animate: false,
                      stageKey: switch (dragon.stage) {
                        DragonStage.hatchling => 'spark',
                        DragonStage.wyrmling => 'nestDragon',
                        _ => 'homeGuardian'
                      },
                      lineageId: dragon.lineageId,
                      evolutionPath: dragon.path,
                      prismatic: dragon.spectral,
                      sinister: dragon.sinister,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(
                    child: Text(
                  canonicalDragonName(AppStrings.of(context), dragon),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                )),
                const SizedBox(width: 4),
              ]),
            ]),
            if (dragon.favorite)
              const Positioned(
                top: 3,
                right: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x22000000), blurRadius: 5),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(Icons.favorite_rounded,
                        color: Color(0xFFE05A78), size: 20),
                  ),
                ),
              ),
            if (equippedRelic != null)
              Positioned(
                top: 3,
                left: 3,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x22000000), blurRadius: 5),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Image.asset(
                      equippedRelic!.assetPath,
                      key: Key('dragon-brooch-badge-${dragon.id}'),
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              ),
            if (dragon.schoolComplete)
              Positioned(
                left: 3,
                bottom: 3,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x22000000), blurRadius: 5),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Image.asset(
                      dragon.schoolOutcome.badgeAsset,
                      key: Key('dragon-school-status-${dragon.id}'),
                      width: 25,
                      height: 25,
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _DragonCompactCard extends StatelessWidget {
  const _DragonCompactCard({
    required this.dragon,
    required this.equippedRelic,
    required this.onTap,
  });

  final CanonicalDragonView dragon;
  final MysticRelic? equippedRelic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final received = MaterialLocalizations.of(context).formatShortDate(
      dragon.acquiredAt.toLocal(),
    );
    return Card(
      color: dragon.highlighted.isEmpty ? null : const Color(0xFFFFFAE9),
      shape: dragon.highlighted.isEmpty
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.gold),
            ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        key: Key('canonical-dragon-${dragon.id}'),
        onTap: onTap,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              SizedBox.square(
                dimension: 72,
                child: DragonArt(
                  height: 66,
                  animate: false,
                  stageKey: switch (dragon.stage) {
                    DragonStage.hatchling => 'spark',
                    DragonStage.wyrmling => 'nestDragon',
                    _ => 'homeGuardian'
                  },
                  lineageId: dragon.lineageId,
                  evolutionPath: dragon.path,
                  prismatic: dragon.spectral,
                  sinister: dragon.sinister,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            canonicalDragonName(AppStrings.of(context), dragon),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (dragon.favorite) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFE05A78),
                            size: 15,
                          ),
                        ],
                        if (equippedRelic != null) ...[
                          const SizedBox(width: 4),
                          Image.asset(
                            equippedRelic!.assetPath,
                            key: Key('dragon-brooch-list-${dragon.id}'),
                            width: 19,
                            height: 19,
                          ),
                        ],
                        if (dragon.schoolComplete) ...[
                          const SizedBox(width: 4),
                          Image.asset(
                            dragon.schoolOutcome.badgeAsset,
                            key: Key('dragon-school-status-list-${dragon.id}'),
                            width: 20,
                            height: 20,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${strings.lineageName(dragonLineages.firstWhere((l) => l.id == dragon.lineageId))} · '
                      '${strings.lineageRarity(dragonLineages.firstWhere((l) => l.id == dragon.lineageId))}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            AppColors.eventColor(context, AppColors.twilight),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_stageName(strings, dragon.stage)} · '
                      '${strings.pick('Received', 'Ontvangen')} $received',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragonSchoolDiplomaCard extends StatelessWidget {
  const _DragonSchoolDiplomaCard({required this.dragon});

  final CanonicalDragonView dragon;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final outcome = dragon.schoolOutcome;
    final complete = dragon.schoolComplete;
    final graduated = outcome.isPassing;
    return Container(
      key: Key('dragon-school-diploma-${dragon.id}'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: graduated
              ? const [Color(0xFFFFF4C7), Color(0xFFF0E4FF)]
              : complete
                  ? const [Color(0xFFFFEEE7), Color(0xFFF8F1F4)]
                  : const [Color(0xFFF6F2FA), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: graduated
              ? AppColors.gold
              : complete
                  ? const Color(0xFFB25434)
                  : AppColors.eventColor(context, const Color(0xFFDCD2E8)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                outcome.badgeAsset,
                width: 54,
                height: 54,
                opacity: AlwaysStoppedAnimation(complete ? 1 : .42),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete
                          ? strings.pick(outcome.titleEn, outcome.titleNl)
                          : strings.pick('Dragon Academy report card',
                              'Drakenacademierapport'),
                      style: TextStyle(
                          color:
                              AppColors.eventColor(context, AppColors.twilight),
                          fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${dragon.schoolStarTotal}/30 ${strings.pick('stars', 'sterren')} · '
                      '${dragon.schoolAttempts.values.fold(0, (a, b) => a + b)}/$dragonSchoolMaximumAttempts ${strings.pick('attempts', 'pogingen')}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (complete)
                Icon(
                  graduated
                      ? Icons.verified_rounded
                      : Icons.history_edu_rounded,
                  color: graduated
                      ? const Color(0xFFD39A16)
                      : const Color(0xFFB25434),
                  size: 28,
                ),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final lesson in dragonSchoolGames)
                Tooltip(
                  message: '${strings.pick(lesson.titleEn, lesson.titleNl)} · '
                      '${(dragon.schoolAttempts[lesson.id] ?? 0)}/$dragonSchoolAttemptsPerLesson',
                  child: Container(
                    width: 27,
                    height: 27,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .72),
                      shape: BoxShape.circle,
                    ),
                    child: Opacity(
                      opacity:
                          (dragon.schoolStars[lesson.id] ?? 0) > 0 ? 1 : .22,
                      child: Image.asset(lesson.iconAsset),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
