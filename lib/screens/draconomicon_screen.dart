import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dragon_lineage.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';
import '../widgets/game_icon_sprite.dart';

class DraconomiconScreen extends StatelessWidget {
  const DraconomiconScreen({
    super.key,
    this.discoveredForms,
    this.prismaticForms,
    this.keeperName,
  });

  final Set<String>? discoveredForms;
  final Set<String>? prismaticForms;
  final String? keeperName;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final normalCollection = discoveredForms ?? game.discoveredForms;
    final spectralCollection = prismaticForms ?? game.prismaticForms;
    final discoveredLineageCount = {
      ...normalCollection,
      ...spectralCollection,
    }.map((key) => key.split(':').first).toSet().length;
    final discoveredDragonFormCount = normalCollection.length;
    final hasSpectralCollection = spectralCollection.isNotEmpty;
    final allKnownLineageIds = {
      ...normalCollection,
      ...spectralCollection,
    }.map((key) => key.split(':').first).toSet();
    final visibleLineages = dragonLineages
        .where((lineage) =>
            !lineage.secret || allKnownLineageIds.contains(lineage.id))
        .toList(growable: false);
    final completion = visibleLineages.isEmpty
        ? 0.0
        : discoveredLineageCount / visibleLineages.length;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFBF3), Color(0xFFF4EEFF)],
        ),
      ),
      child: DefaultTabController(
        length: hasSpectralCollection ? 2 : 1,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    key: const Key('draconomicon-hero'),
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF17112F),
                          Color(0xFF37205F),
                          Color(0xFF65449A),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0x99FFD66E)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x552B174D),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _CodexConstellationPainter(),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 82,
                                  height: 82,
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFFFFF7D5),
                                        Color(0xFFFFD66E),
                                        Color(0xFF8A5FB5),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x99FFD66E),
                                        blurRadius: 18,
                                      ),
                                    ],
                                  ),
                                  child: const GameIconSprite(
                                    GameIconKind.draconomicon,
                                    size: 68,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        keeperName == null
                                            ? strings.pick(
                                                'The Draconomicon',
                                                'Het Draconomicon',
                                              )
                                            : strings.pick(
                                                "$keeperName's Draconomicon",
                                                'Draconomicon van $keeperName',
                                              ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          letterSpacing: -.25,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        strings.pick(
                                          keeperName == null
                                              ? 'Every form you raise leaves its magic on the page.'
                                              : 'Every form this keeper discovered left its magic on the page.',
                                          keeperName == null
                                              ? 'Elke vorm die je grootbrengt laat zijn magie achter op de bladzij.'
                                              : 'Elke vorm die deze hoeder ontdekte liet magie achter op de bladzij.',
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFFE9E0F8),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          height: 1.23,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _CodexStatPill(
                                    icon: Icons.auto_awesome_rounded,
                                    label: strings.pick(
                                      'Dragons $discoveredDragonFormCount',
                                      'Draken $discoveredDragonFormCount',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _CodexStatPill(
                                    icon: Icons.menu_book_rounded,
                                    label: strings.pick(
                                      'Dragon families $discoveredLineageCount/${visibleLineages.length}',
                                      'Drakenfamilies $discoveredLineageCount/${visibleLineages.length}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      key: const Key(
                                          'draconomicon-family-progress'),
                                      value: completion,
                                      minHeight: 8,
                                      color: const Color(0xFFFFD66E),
                                      backgroundColor: Colors.white24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Text(
                                  '${(completion * 100).round()}%',
                                  style: const TextStyle(
                                    color: Color(0xFFFFE7A1),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7DFF3),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white),
                    ),
                    child: TabBar(
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: AppColors.twilight,
                      unselectedLabelColor: AppColors.muted,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFFFF7DE)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x225B3E91),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      tabs: [
                        Tab(
                          height: 48,
                          icon: const Icon(Icons.menu_book_rounded, size: 18),
                          iconMargin: const EdgeInsets.only(bottom: 1),
                          text: strings.pick('Dragons', 'Draken'),
                        ),
                        if (hasSpectralCollection)
                          Tab(
                            height: 48,
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            iconMargin: const EdgeInsets.only(bottom: 1),
                            text: strings.pick('Spectral', 'Spectral'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _DragonCollection(
                    spectral: false,
                    collection: normalCollection,
                    lineages: visibleLineages,
                  ),
                  if (hasSpectralCollection)
                    _DragonCollection(
                      spectral: true,
                      collection: spectralCollection,
                      lineages: visibleLineages,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodexStatPill extends StatelessWidget {
  const _CodexStatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: const Color(0xFFFFD66E)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                  height: 1.08,
                ),
              ),
            ),
          ],
        ),
      );
}

class _CodexConstellationPainter extends CustomPainter {
  const _CodexConstellationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const stars = [
      Offset(.08, .16),
      Offset(.24, .08),
      Offset(.42, .18),
      Offset(.62, .07),
      Offset(.83, .19),
      Offset(.93, .09),
      Offset(.72, .39),
      Offset(.91, .54),
      Offset(.56, .48),
      Offset(.15, .48),
      Offset(.33, .65),
      Offset(.79, .76),
      Offset(.96, .88),
    ];
    final line = Paint()
      ..color = const Color(0x33FFE6A1)
      ..strokeWidth = 1.1;
    for (var index = 1; index < stars.length; index++) {
      if (index % 3 != 0) {
        canvas.drawLine(
          Offset(stars[index - 1].dx * size.width,
              stars[index - 1].dy * size.height),
          Offset(stars[index].dx * size.width, stars[index].dy * size.height),
          line,
        );
      }
    }
    for (var index = 0; index < stars.length; index++) {
      final point = Offset(
        stars[index].dx * size.width,
        stars[index].dy * size.height,
      );
      canvas.drawCircle(
        point,
        index.isEven ? 1.7 : 1,
        Paint()..color = const Color(0xAAFFF2BD),
      );
    }
    canvas.drawCircle(
      Offset(size.width * .9, size.height * .2),
      size.shortestSide * .25,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x18FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DragonCollection extends StatelessWidget {
  const _DragonCollection({
    required this.spectral,
    required this.collection,
    required this.lineages,
  });
  final bool spectral;
  final Set<String> collection;
  final List<DragonLineage> lineages;
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: PageStorageKey(
          spectral ? 'draconomicon-spectral' : 'draconomicon-dragons'),
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 30),
      itemCount: lineages.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DragonLineageEntry(
            lineage: lineages[index],
            number: index + 1,
            collection: collection,
            spectral: spectral),
      ),
    );
  }
}

class DragonLineageEntry extends StatelessWidget {
  const DragonLineageEntry(
      {required this.lineage,
      required this.number,
      required this.collection,
      required this.spectral,
      super.key});
  final DragonLineage lineage;
  final int number;
  final Set<String> collection;
  final bool spectral;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final discovered =
        collection.any((key) => key.startsWith('${lineage.id}:'));
    final count =
        collection.where((key) => key.startsWith('${lineage.id}:')).length;
    final masteryKnown = collection.contains('${lineage.id}:ascended:mastery');
    final visibleFormCount = masteryKnown ? 6 : 5;
    final firstKnown = collection.contains('${lineage.id}:hatchling');
    final primary = Color(lineage.primaryColorValue);
    final secondary = Color(lineage.secondaryColorValue);
    final rarityColor = _codexRarityColor(lineage.rarity);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      color: discovered
          ? Color.alphaBlend(primary.withValues(alpha: .06), Colors.white)
          : const Color(0xFFE9E5EE),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(23),
        side: BorderSide(
          color: discovered ? rarityColor.withValues(alpha: .62) : Colors.white,
          width: discovered ? 1.5 : 1,
        ),
      ),
      child: ExpansionTile(
        key: PageStorageKey(
          'draconomicon-lineage-${spectral ? 'spectral' : 'normal'}-${lineage.id}',
        ),
        tilePadding: const EdgeInsets.fromLTRB(11, 7, 11, 7),
        childrenPadding: const EdgeInsets.fromLTRB(11, 0, 11, 13),
        leading: Container(
          width: 62,
          height: 62,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: discovered
                ? LinearGradient(colors: [secondary, primary])
                : const LinearGradient(
                    colors: [Color(0xFFDCD7E3), Color(0xFFB9B2C3)],
                  ),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: discovered
                ? [
                    BoxShadow(
                      color: rarityColor.withValues(alpha: .28),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: DragonArt(
            key: Key(
                'draconomicon-preview-${spectral ? 'spectral' : 'normal'}-${lineage.id}'),
            height: 56,
            animate: false,
            stageKey: 'spark',
            lineageId: lineage.id,
            silhouette: !firstKnown,
            prismatic: spectral && firstKnown,
          ),
        ),
        title: Text(
          discovered
              ? strings.lineageName(lineage)
              : strings.pick('Unknown lineage', 'Onbekende drakenlijn'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
            '#${number.toString().padLeft(3, '0')} · ${strings.lineageRarity(lineage)} · $count/$visibleFormCount ${strings.pick('forms', 'vormen')}'),
        trailing: Container(
          width: 47,
          height: 47,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: discovered
                ? rarityColor.withValues(alpha: .11)
                : Colors.white54,
            border: Border.all(
              color:
                  discovered ? rarityColor.withValues(alpha: .5) : Colors.white,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count/$visibleFormCount',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: discovered ? rarityColor : AppColors.muted,
              ),
            ],
          ),
        ),
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 11),
            color: rarityColor.withValues(alpha: .16),
          ),
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
                  collection: collection,
                  formKey: 'hatchling',
                  label: strings.petStageNameByKey('spark'),
                  stageKey: 'spark',
                  spectral: spectral),
              _FormTile(
                  lineage: lineage,
                  collection: collection,
                  formKey: 'wyrmling',
                  label: strings.petStageNameByKey('nestDragon'),
                  stageKey: 'nestDragon',
                  spectral: spectral),
              _FormTile(
                  lineage: lineage,
                  collection: collection,
                  formKey: 'ascended:might',
                  label: strings.pick('Might', 'Kracht'),
                  stageKey: 'homeGuardian',
                  path: 'might',
                  spectral: spectral),
              _FormTile(
                  lineage: lineage,
                  collection: collection,
                  formKey: 'ascended:arcana',
                  label: strings.pick('Arcana', 'Arcana'),
                  stageKey: 'homeGuardian',
                  path: 'arcana',
                  spectral: spectral),
              _FormTile(
                  lineage: lineage,
                  collection: collection,
                  formKey: 'ascended:spirit',
                  label: strings.pick('Spirit', 'Geest'),
                  stageKey: 'homeGuardian',
                  path: 'spirit',
                  spectral: spectral),
              if (masteryKnown)
                _FormTile(
                    lineage: lineage,
                    collection: collection,
                    formKey: 'ascended:mastery',
                    label: 'Mastery',
                    stageKey: 'homeGuardian',
                    path: 'mastery',
                    spectral: spectral),
            ],
          ),
        ],
      ),
    );
  }
}

Color _codexRarityColor(DragonRarity rarity) => switch (rarity) {
      DragonRarity.common => const Color(0xFF527064),
      DragonRarity.uncommon => const Color(0xFF2E8A68),
      DragonRarity.rare => const Color(0xFF3477C7),
      DragonRarity.veryRare => const Color(0xFF7951C9),
      DragonRarity.legendary => const Color(0xFFD39424),
      DragonRarity.mythical => const Color(0xFFC13D89),
    };

class _FormTile extends StatelessWidget {
  const _FormTile(
      {required this.lineage,
      required this.collection,
      required this.formKey,
      required this.label,
      required this.stageKey,
      required this.spectral,
      this.path = 'might'});
  final DragonLineage lineage;
  final Set<String> collection;
  final String formKey;
  final String label;
  final String stageKey;
  final String path;
  final bool spectral;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final known = collection.contains('${lineage.id}:$formKey');
    final title = !known
        ? '???'
        : stageKey == 'homeGuardian'
            ? strings.lineageFormName(lineage, path)
            : label;
    final focusKind = switch (path) {
      'arcana' => GameIconKind.arcana,
      'spirit' => GameIconKind.spirit,
      'mastery' => GameIconKind.dragonFavorite,
      _ => GameIconKind.might,
    };
    final primary = Color(lineage.primaryColorValue);
    final secondary = Color(lineage.secondaryColorValue);
    final rarityColor = _codexRarityColor(lineage.rarity);
    return Container(
      key: Key(
          'draconomicon-form-${spectral ? 'spectral' : 'normal'}-${lineage.id}-$formKey'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          gradient: known
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color.alphaBlend(
                      secondary.withValues(alpha: .2),
                      const Color(0xFFFFFAEF),
                    ),
                  ],
                )
              : null,
          color: known ? null : const Color(0xFFD9D4E0),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
              color: spectral ? const Color(0xFF69C9E7) : rarityColor,
              width: spectral ? 2 : 1.25),
          boxShadow: known
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: .12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null),
      child: Column(children: [
        if (stageKey == 'homeGuardian')
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 30,
              height: 30,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .88),
                shape: BoxShape.circle,
                border: Border.all(color: rarityColor.withValues(alpha: .35)),
              ),
              child: GameIconSprite(focusKind, size: 24),
            ),
          ),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(13),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: Key(
                      'draconomicon-zoom-${spectral ? 'spectral' : 'normal'}-${lineage.id}-$formKey'),
                  onTap: known
                      ? () => _showDragonPreview(
                            context,
                            lineage: lineage,
                            title: title,
                            stageKey: stageKey,
                            path: path,
                            formKey: formKey,
                            spectral: spectral,
                          )
                      : null,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: known
                                ? [
                                    secondary.withValues(alpha: .24),
                                    Colors.transparent,
                                  ]
                                : const [
                                    Color(0x22FFFFFF),
                                    Colors.transparent,
                                  ],
                          ),
                        ),
                      ),
                      DragonArt(
                          key: Key(
                              'draconomicon-art-${spectral ? 'spectral' : 'normal'}-${lineage.id}-$formKey'),
                          height: 112,
                          animate: false,
                          stageKey: stageKey,
                          lineageId: lineage.id,
                          evolutionPath: path,
                          silhouette: !known,
                          prismatic: spectral),
                      if (known)
                        const Positioned(
                          right: 2,
                          bottom: 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xD9FFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.zoom_in_rounded,
                                  size: 16, color: AppColors.twilight),
                            ),
                          ),
                        ),
                      if (!known)
                        const Positioned(
                          right: 3,
                          bottom: 3,
                          child: Icon(
                            Icons.lock_rounded,
                            size: 17,
                            color: Color(0xFF777080),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
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

Future<void> _showDragonPreview(
  BuildContext context, {
  required DragonLineage lineage,
  required String title,
  required String stageKey,
  required String path,
  required String formKey,
  required bool spectral,
}) {
  final strings = AppStrings.of(context);
  final rarityColor = _codexRarityColor(lineage.rarity);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      key: Key(
          'draconomicon-modal-${spectral ? 'spectral' : 'normal'}-${lineage.id}-$formKey'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      backgroundColor: const Color(0xFFFFFCF5),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: rarityColor, width: 2),
      ),
      shadowColor: rarityColor.withValues(alpha: .5),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(dialogContext)
                      .closeButtonTooltip,
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(lineage.secondaryColorValue)
                            .withValues(alpha: .38),
                        Color(lineage.primaryColorValue).withValues(alpha: .1),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: rarityColor.withValues(alpha: .28),
                    ),
                  ),
                  child: DragonArt(
                    key: Key(
                        'draconomicon-modal-art-${spectral ? 'spectral' : 'normal'}-${lineage.id}-$formKey'),
                    height: 360,
                    animate: true,
                    stageKey: stageKey,
                    lineageId: lineage.id,
                    evolutionPath: path,
                    prismatic: spectral,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (spectral) ...[
                const SizedBox(height: 4),
                Text(
                  '✦ ${strings.pick('Spectral', 'Spectral')}',
                  style: const TextStyle(
                    color: AppColors.twilight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
