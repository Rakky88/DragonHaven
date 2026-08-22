import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_lineage.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';
import '../widgets/game_icon_sprite.dart';

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
              Container(
                padding: const EdgeInsets.fromLTRB(15, 13, 16, 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF241747), Color(0xFF5D3D8D)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x332B174D),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(children: [
                  const GameIconSprite(
                    GameIconKind.draconomicon,
                    size: 92,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.pick('The Draconomicon', 'Het Draconomicon'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.pick(
                            'Every form you raise leaves its magic on the page.',
                            'Elke vorm die je grootbrengt laat zijn magie achter op de bladzij.',
                          ),
                          style: const TextStyle(
                            color: Color(0xFFE4DCF5),
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: game.discoveredLineageCount / 42,
                            minHeight: 7,
                            color: const Color(0xFFFFD66E),
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
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
        child: DragonLineageEntry(
            lineage: dragonLineages[index],
            number: index + 1,
            game: game,
            spectral: spectral),
      ),
    );
  }
}

class DragonLineageEntry extends StatelessWidget {
  const DragonLineageEntry(
      {required this.lineage,
      required this.number,
      required this.game,
      required this.spectral,
      super.key});
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
      color: discovered ? Colors.white : const Color(0xFFF0EDF5),
      child: ExpansionTile(
        key: PageStorageKey(
          'draconomicon-lineage-${spectral ? 'spectral' : 'normal'}-${lineage.id}',
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        leading: SizedBox.square(
            dimension: 58,
            child: DragonArt(
                key: Key(
                    'draconomicon-preview-${spectral ? 'spectral' : 'normal'}-${lineage.id}'),
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
        trailing: const Icon(Icons.expand_more_rounded),
        children: [
          GridView.count(
            key: PageStorageKey(
              'draconomicon-forms-${spectral ? 'spectral' : 'normal'}-${lineage.id}',
            ),
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
                  label: strings.pick('Might', 'Kracht'),
                  stageKey: 'homeGuardian',
                  path: 'might',
                  spectral: spectral),
              _FormTile(
                  lineage: lineage,
                  formKey: 'ascended:arcana',
                  label: strings.pick('Arcana', 'Arcana'),
                  stageKey: 'homeGuardian',
                  path: 'arcana',
                  spectral: spectral),
              _FormTile(
                  lineage: lineage,
                  formKey: 'ascended:spirit',
                  label: strings.pick('Spirit', 'Geest'),
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
    final focusKind = switch (path) {
      'arcana' => GameIconKind.arcana,
      'spirit' => GameIconKind.spirit,
      _ => GameIconKind.might,
    };
    return Container(
      key: Key(
          'draconomicon-form-${spectral ? 'spectral' : 'normal'}-${lineage.id}-$formKey'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          gradient: known
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFFFF7E7)],
                )
              : null,
          color: known ? null : const Color(0xFFD8D3E0),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
              color: spectral ? const Color(0xFF78BCD2) : AppColors.mist,
              width: spectral ? 2 : 1)),
      child: Column(children: [
        if (stageKey == 'homeGuardian')
          Align(
            alignment: Alignment.topRight,
            child: GameIconSprite(focusKind, size: 27),
          ),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: DragonArt(
                  key: Key(
                      'draconomicon-art-${spectral ? 'spectral' : 'normal'}-${lineage.id}-$formKey'),
                  height: 112,
                  animate: false,
                  stageKey: stageKey,
                  lineageId: lineage.id,
                  evolutionPath: path,
                  silhouette: !known,
                  prismatic: spectral),
            ),
          ),
        ),
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
