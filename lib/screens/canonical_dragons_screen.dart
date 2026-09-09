import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_lineage.dart';
import '../models/egg_altar.dart';
import '../models/mystic_relic.dart';
import '../models/pet.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_game_snapshot.dart';
import '../widgets/canonical_game_controls.dart';
import '../widgets/dragon_art.dart';
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

class _DragonList extends StatelessWidget {
  const _DragonList();
  @override
  Widget build(BuildContext context) {
    final view = context.watch<CanonicalGameSession>().snapshot!;
    final strings = AppStrings.of(context);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(strings.pick('My dragons', 'Mijn draken'),
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      for (final dragon in view.dragons.where((d) => d.owned))
        Card(
            child: ListTile(
                key: Key('canonical-dragon-${dragon.id}'),
                leading: SizedBox(
                    width: 64,
                    child: CanonicalDragonArt(dragon: dragon, height: 64)),
                title: Text(canonicalDragonName(strings, dragon)),
                subtitle: Text(
                    '${_stageName(strings, dragon.stage)} · ${dragon.xp} XP'),
                trailing: switch (view.inventory.equippedOn(dragon.id)) {
                  final relic? =>
                    Image.asset(relic.assetPath, width: 32, height: 32),
                  null => const Icon(Icons.info_outline),
                },
                onTap: () => showCanonicalDragonDetails(context, dragon.id))),
      if (!view.dragons.any((d) => d.owned))
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(strings.pick(
                'Your dragons will appear here after hatching.',
                'Je draken komen hier na het uitbroeden.'))),
    ]);
  }
}

Future<void> showCanonicalDragonDetails(BuildContext context, String id) async {
  final owner = context.read<CanonicalGameSession>().snapshot?.ownerId;
  if (owner == null) return;
  await showDialog<void>(
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
            return AlertDialog(
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
                                        dragon: dragon, height: 165),
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
                                    const Divider(height: 24),
                                    Wrap(spacing: 12, runSpacing: 4, children: [
                                      Text(
                                          '${strings.pick('Joy', 'Vreugde')}: ${dragon.joy}%'),
                                      Text(
                                          '${strings.pick('Energy', 'Energie')}: ${dragon.energy}%'),
                                      Text(
                                          '${strings.pick('Comfort', 'Comfort')}: ${dragon.comfort}%'),
                                    ]),
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
                                            ? () => _name(
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

Future<void> _name(BuildContext context, CanonicalDragonView dragon,
    String owner, CanonicalGameActions actions) async {
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
