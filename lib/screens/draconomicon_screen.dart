import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_lineage.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';

class DraconomiconScreen extends StatelessWidget {
  const DraconomiconScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    return DefaultTabController(
      length: game.hasSpectralCollection ? 2 : 1,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(strings.pick('The Draconomicon', 'Het Draconomicon'),
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 5),
              Text(
                  strings.pick(
                      'Your living record of every dragon form you have raised.',
                      'Je levende register van elke drakenvorm die je hebt grootgebracht.'),
                  style: const TextStyle(color: AppColors.muted, fontSize: 15)),
              const SizedBox(height: 15),
              Container(
                  decoration: BoxDecoration(
                      color: AppColors.mist,
                      borderRadius: BorderRadius.circular(16)),
                  child: TabBar(
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13)),
                      tabs: [
                        Tab(
                            text: strings.pick(
                                'Dragons ${game.discoveredLineageCount}/42',
                                'Draken ${game.discoveredLineageCount}/42')),
                        if (game.hasSpectralCollection)
                          Tab(text: strings.pick('Spectral', 'Spectral')),
                      ]))
            ]),
          ),
          Expanded(
              child: TabBarView(children: [
            const _DragonCollection(spectral: false),
            if (game.hasSpectralCollection)
              const _DragonCollection(spectral: true),
          ])),
        ],
      ),
    );
  }
}

class _DragonCollection extends StatelessWidget {
  const _DragonCollection({required this.spectral});
  final bool spectral;
  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    return ListView.builder(
      key: PageStorageKey(
          spectral ? 'draconomicon-spectral' : 'draconomicon-dragons'),
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 30),
      itemCount: dragonLineages.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _LineageEntry(
            lineage: dragonLineages[index],
            number: index + 1,
            game: game,
            spectral: spectral),
      ),
    );
  }
}

class _LineageEntry extends StatelessWidget {
  const _LineageEntry(
      {required this.lineage,
      required this.number,
      required this.game,
      required this.spectral});
  final DragonLineage lineage;
  final int number;
  final HouseholdProvider game;
  final bool spectral;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final collection = spectral ? game.prismaticForms : game.discoveredForms;
    final discovered =
        collection.any((key) => key.startsWith('${lineage.id}:'));
    final count =
        collection.where((key) => key.startsWith('${lineage.id}:')).length;
    final firstKnown =
        game.hasDiscovered(lineage.id, 'hatchling', prismatic: spectral);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey('draconomicon-lineage-${lineage.id}'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        leading: SizedBox.square(
            dimension: 58,
            child: DragonArt(
                height: 58,
                animate: false,
                stageKey: 'spark',
                lineageId: lineage.id,
                silhouette: !firstKnown,
                prismatic: spectral && firstKnown)),
        title: Text(
            discovered
                ? strings.lineageName(lineage)
                : strings.pick('Unknown lineage', 'Onbekende drakenlijn'),
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
            '#${number.toString().padLeft(3, '0')} · ${strings.lineageRarity(lineage)} · $count/5 ${strings.pick('forms', 'vormen')}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (spectral && discovered)
            const Padding(padding: EdgeInsets.only(right: 7), child: Text('✦')),
          const Icon(Icons.expand_more_rounded)
        ]),
        children: [
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 520 ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: .85,
            children: [
              _FormTile(
                  lineage: lineage,
                  formKey: 'hatchling',
                  label: strings.petStageNameByKey('spark'),
                  stageKey: 'spark',
                  spectral: spectral),
              _FormTile(
                  lineage: lineage,
                  formKey: 'wyrmling',
                  label: strings.petStageNameByKey('nestDragon'),
                  stageKey: 'nestDragon',
                  spectral: spectral),
              _FormTile(
                  lineage: lineage,
                  formKey: 'ascended:might',
                  label: 'Might',
                  stageKey: 'homeGuardian',
                  path: 'might',
                  spectral: spectral),
              _FormTile(
                  lineage: lineage,
                  formKey: 'ascended:arcana',
                  label: 'Arcana',
                  stageKey: 'homeGuardian',
                  path: 'arcana',
                  spectral: spectral),
              _FormTile(
                  lineage: lineage,
                  formKey: 'ascended:spirit',
                  label: 'Spirit',
                  stageKey: 'homeGuardian',
                  path: 'spirit',
                  spectral: spectral),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormTile extends StatelessWidget {
  const _FormTile(
      {required this.lineage,
      required this.formKey,
      required this.label,
      required this.stageKey,
      required this.spectral,
      this.path = 'might'});
  final DragonLineage lineage;
  final String formKey;
  final String label;
  final String stageKey;
  final String path;
  final bool spectral;
  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final known = game.hasDiscovered(lineage.id, formKey, prismatic: spectral);
    final title = !known
        ? '???'
        : stageKey == 'homeGuardian'
            ? strings.lineageFormName(lineage, path)
            : label;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: known ? Colors.white : const Color(0xFFE1DDE9),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
              color: spectral ? const Color(0xFF78BCD2) : AppColors.mist,
              width: spectral ? 2 : 1)),
      child: Column(children: [
        Expanded(
            child: DragonArt(
                height: 112,
                animate: false,
                stageKey: stageKey,
                lineageId: lineage.id,
                evolutionPath: path,
                silhouette: !known,
                prismatic: spectral)),
        const SizedBox(height: 5),
        Text(title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
        Text(
            spectral
                ? '✦ ${strings.pick('Spectral', 'Spectral')} $label'
                : label,
            style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 10))
      ]),
    );
  }
}
