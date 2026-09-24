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
import '../widgets/dragon_trial_records.dart';
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
  const CanonicalDragonArt(
      {super.key,
      required this.dragon,
      this.height = 80,
      this.animate = false});
  final CanonicalDragonView dragon;
  final double height;
  final bool animate;
  @override
  Widget build(BuildContext context) =>
      !dragonLineages.any((l) => l.id == dragon.lineageId)
          ? SizedBox(height: height, child: const Icon(Icons.help_outline))
          : DragonArt(
              height: height,
              animate: animate,
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
  const CanonicalDragonsScreen({super.key}) : _bottomSheet = false;
  const CanonicalDragonsScreen.sheet({super.key}) : _bottomSheet = true;

  final bool _bottomSheet;

  @override
  Widget build(BuildContext context) {
    if (!_bottomSheet) {
      return const ShopEconomyBoundary(child: SafeArea(child: _DragonList()));
    }
    return SafeArea(
        child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: .7,
            maxChildSize: .92,
            builder: (_, controller) => ShopEconomyBoundary(
                child: _DragonList(scrollController: controller))));
  }
}

class _DragonList extends StatefulWidget {
  const _DragonList({this.scrollController});
  final ScrollController? scrollController;
  @override
  State<_DragonList> createState() => _DragonListState();
}

enum _DragonCollectionView { gallery, compact }

enum _DragonSortMode { name, dragonType, acquiredAt, rarity }

class _DragonListState extends State<_DragonList> {
  _DragonCollectionView _view = _DragonCollectionView.gallery;
  _DragonSortMode _sortMode = _DragonSortMode.acquiredAt;
  bool _sortDescending = true;
  final Set<String> _formFilters = {};
  final Set<String> _rarityFilters = {};
  bool _spectralOnly = false;
  bool _preferencesLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preferencesLoaded) return;
    final game = context.read<CanonicalGameSession>().snapshot!;
    _view = _DragonCollectionView.values.firstWhere(
      (value) => value.name == game.profile.preferences['myDragonsViewMode'],
      orElse: () => _DragonCollectionView.gallery,
    );
    _sortMode = _DragonSortMode.values.firstWhere(
      (value) => value.name == game.profile.preferences['myDragonsSortMode'],
      orElse: () => _DragonSortMode.acquiredAt,
    );
    _sortDescending =
        game.profile.preferences['myDragonsSortDescending'] == true;
    _preferencesLoaded = true;
  }

  String _formKey(CanonicalDragonView dragon) => switch (dragon.stage) {
        DragonStage.hatchling => 'hatchling',
        DragonStage.wyrmling => 'wyrmling',
        DragonStage.ascended => dragon.path,
        DragonStage.egg => 'egg',
      };

  String _rarityKey(CanonicalDragonView dragon) => dragon.sinister
      ? 'infernal'
      : dragonLineages.firstWhere((l) => l.id == dragon.lineageId).rarity.name;

  List<CanonicalDragonView> _filteredDragons(
          Iterable<CanonicalDragonView> source) =>
      source
          .where(
            (dragon) =>
                (_formFilters.isEmpty ||
                    _formFilters.contains(_formKey(dragon))) &&
                (_rarityFilters.isEmpty ||
                    _rarityFilters.contains(_rarityKey(dragon))) &&
                (!_spectralOnly || dragon.spectral),
          )
          .toList(growable: false);

  List<CanonicalDragonView> _sortedDragons(
      Iterable<CanonicalDragonView> source) {
    final dragons = source.toList(growable: false);
    dragons.sort((a, b) {
      final comparison = switch (_sortMode) {
        _DragonSortMode.name => canonicalDragonName(AppStrings.of(context), a)
            .toLowerCase()
            .compareTo(
                canonicalDragonName(AppStrings.of(context), b).toLowerCase()),
        _DragonSortMode.dragonType => _dragonTypeName(a).compareTo(
            _dragonTypeName(b),
          ),
        _DragonSortMode.acquiredAt => a.acquiredAt.compareTo(b.acquiredAt),
        _DragonSortMode.rarity => _rarityRank(a).compareTo(_rarityRank(b)),
      };
      final stable = comparison != 0
          ? comparison
          : canonicalDragonName(AppStrings.of(context), a)
              .toLowerCase()
              .compareTo(
                  canonicalDragonName(AppStrings.of(context), b).toLowerCase());
      return _sortDescending ? -stable : stable;
    });
    return dragons;
  }

  int _rarityRank(CanonicalDragonView dragon) => dragon.sinister
      ? DragonRarity.values.length
      : dragonLineages.firstWhere((l) => l.id == dragon.lineageId).rarity.index;

  String _dragonTypeName(CanonicalDragonView dragon) => AppStrings.of(context)
      .lineageName(dragonLineages
          .firstWhere((lineage) => lineage.id == dragon.lineageId))
      .toLowerCase();

  String _sortLabel(AppStrings strings) => switch (_sortMode) {
        _DragonSortMode.name => strings.pick('Name', 'Naam'),
        _DragonSortMode.dragonType => strings.pick('Dragon type', 'Draaktype'),
        _DragonSortMode.acquiredAt => strings.pick('Received', 'Ontvangen'),
        _DragonSortMode.rarity => strings.pick('Rarity', 'Zeldzaamheid'),
      };

  void _selectSort(_DragonSortMode value) {
    setState(() {
      if (_sortMode == value) {
        _sortDescending = !_sortDescending;
      } else {
        _sortMode = value;
        _sortDescending = value != _DragonSortMode.name &&
            value != _DragonSortMode.dragonType;
      }
    });
    _saveCollectionPreferences();
  }

  void _saveCollectionPreferences() {
    final session = context.read<CanonicalGameSession>();
    runShopAction(
        context,
        () => CanonicalGameActions(session).setPreferences({
              'myDragonsViewMode': _view.name,
              'myDragonsSortMode': _sortMode.name,
              'myDragonsSortDescending': _sortDescending,
            }));
  }

  String _formLabel(AppStrings strings, String key) => switch (key) {
        'hatchling' => strings.pick('Hatchling', 'Jong'),
        'wyrmling' => 'Wyrmling',
        'might' => strings.pick('Might', 'Kracht'),
        'arcana' => 'Arcana',
        'spirit' => strings.pick('Spirit', 'Geest'),
        'mastery' => strings.pick('Mastery', 'Meesterschap'),
        _ => key,
      };

  String _rarityLabel(AppStrings strings, String key) {
    if (key == 'infernal') return strings.pick('Infernal', 'Infernaal');
    final rarity = DragonRarity.values.firstWhere((value) => value.name == key);
    return strings.lineageRarity(
      dragonLineages.firstWhere((lineage) => lineage.rarity == rarity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<CanonicalGameSession>().snapshot!;
    final strings = AppStrings.of(context);
    final dragons =
        _sortedDragons(_filteredDragons(game.dragons.where((d) => d.owned)));
    final activeFilterCount =
        _formFilters.length + _rarityFilters.length + (_spectralOnly ? 1 : 0);
    return Column(
      key: const Key('owned-dragons-scroll'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    strings.pick('My dragons', 'Mijn draken'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  PopupMenuButton<_DragonSortMode>(
                    key: const Key('owned-dragons-sort'),
                    tooltip: strings.pick(
                      'Change dragon order',
                      'Volgorde van draken wijzigen',
                    ),
                    initialValue: _sortMode,
                    onSelected: _selectSort,
                    itemBuilder: (_) => [
                      for (final mode in _DragonSortMode.values)
                        PopupMenuItem(
                          key: Key('owned-dragons-sort-${mode.name}'),
                          value: mode,
                          child: Row(
                            children: [
                              Icon(switch (mode) {
                                _DragonSortMode.name =>
                                  Icons.sort_by_alpha_rounded,
                                _DragonSortMode.dragonType =>
                                  Icons.pets_rounded,
                                _DragonSortMode.acquiredAt =>
                                  Icons.event_rounded,
                                _DragonSortMode.rarity =>
                                  Icons.auto_awesome_rounded,
                              }),
                              const SizedBox(width: 9),
                              Text(switch (mode) {
                                _DragonSortMode.name =>
                                  strings.pick('Name', 'Naam'),
                                _DragonSortMode.dragonType =>
                                  strings.pick('Dragon type', 'Draaktype'),
                                _DragonSortMode.acquiredAt =>
                                  strings.pick('Received', 'Ontvangen'),
                                _DragonSortMode.rarity =>
                                  strings.pick('Rarity', 'Zeldzaamheid'),
                              }),
                            ],
                          ),
                        ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.eventColor(
                            context, const Color(0xFFF1ECFB)),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sortDescending
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 18,
                            color: AppColors.eventColor(
                                context, AppColors.twilight),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _sortLabel(strings),
                            style: TextStyle(
                              color: AppColors.eventColor(
                                  context, AppColors.twilight),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Badge(
                    isLabelVisible: activeFilterCount > 0,
                    label: Text('$activeFilterCount'),
                    child: IconButton.filledTonal(
                      key: const Key('owned-dragons-filter'),
                      tooltip: strings.pick(
                        'Filter dragons',
                        'Draken filteren',
                      ),
                      onPressed: () => _showFilters(
                        context,
                        game.dragons.where((d) => d.owned),
                      ),
                      icon: const Icon(Icons.filter_alt_rounded),
                    ),
                  ),
                  const SizedBox(width: 7),
                  IconButton.filledTonal(
                    key: const Key('owned-dragons-view-toggle'),
                    tooltip: _view == _DragonCollectionView.gallery
                        ? strings.pick(
                            'Show compact list',
                            'Compacte lijst tonen',
                          )
                        : strings.pick(
                            'Show gallery',
                            'Galerij tonen',
                          ),
                    onPressed: () {
                      setState(() {
                        _view = _view == _DragonCollectionView.gallery
                            ? _DragonCollectionView.compact
                            : _DragonCollectionView.gallery;
                      });
                      _saveCollectionPreferences();
                    },
                    icon: Icon(
                      _view == _DragonCollectionView.gallery
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Container(
                key: const Key('tower-roaming-capacity'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.eventColor(context, const Color(0xFFF1ECFB)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const GameIconSprite(GameIconKind.roomClear, size: 34),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strings.pick(
                        '${game.dragons.where((d) => d.owned && d.roamsTower).length} / ${game.house.floorRoomIds.length * 3} roaming · maximum 3 per room',
                        '${game.dragons.where((d) => d.owned && d.roamsTower).length} / ${game.house.floorRoomIds.length * 3} actief · maximaal 3 per kamer',
                      ),
                      style: TextStyle(
                        color:
                            AppColors.eventColor(context, AppColors.twilight),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
        Expanded(
          child: dragons.isEmpty
              ? Center(
                  child: Text(
                    strings.pick(
                      'No dragons match these filters.',
                      'Geen draken voldoen aan deze filters.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                )
              : _view == _DragonCollectionView.gallery
                  ? GridView.builder(
                      key: const Key('owned-dragons-grid'),
                      controller: widget.scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                      itemCount: dragons.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
                        childAspectRatio: .88,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final dragon = dragons[index];
                        return _DragonGalleryCard(
                          dragon: dragon,
                          equippedRelic: game.inventory.equippedOn(dragon.id),
                          onTap: () =>
                              showCanonicalDragonDetails(context, dragon.id),
                        );
                      },
                    )
                  : ListView.separated(
                      key: const Key('owned-dragons-list'),
                      controller: widget.scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                      itemCount: dragons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 7),
                      itemBuilder: (context, index) {
                        final dragon = dragons[index];
                        return _DragonCompactCard(
                          dragon: dragon,
                          equippedRelic: game.inventory.equippedOn(dragon.id),
                          onTap: () =>
                              showCanonicalDragonDetails(context, dragon.id),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Future<void> _showFilters(
    BuildContext context,
    Iterable<CanonicalDragonView> ownedDragons,
  ) async {
    final strings = AppStrings.of(context);
    final availableForms = ownedDragons.map(_formKey).toSet().toList()..sort();
    final availableRarities = ownedDragons.map(_rarityKey).toSet().toList()
      ..sort((a, b) {
        const order = [
          'common',
          'uncommon',
          'rare',
          'veryRare',
          'legendary',
          'mythical',
          'infernal',
        ];
        return order.indexOf(a).compareTo(order.indexOf(b));
      });
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, modalSetState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.pick('Filter dragons', 'Draken filteren'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      key: const Key('owned-dragons-filter-clear'),
                      onPressed: () => modalSetState(() {
                        _formFilters.clear();
                        _rarityFilters.clear();
                        _spectralOnly = false;
                      }),
                      child: Text(strings.pick('Clear', 'Wissen')),
                    ),
                  ],
                ),
                Text(strings.pick('Form', 'Vorm'),
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  children: [
                    for (final form in availableForms)
                      FilterChip(
                        key: Key('dragon-filter-form-$form'),
                        label: Text(_formLabel(strings, form)),
                        selected: _formFilters.contains(form),
                        onSelected: (selected) => modalSetState(() => selected
                            ? _formFilters.add(form)
                            : _formFilters.remove(form)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(strings.pick('Rarity', 'Zeldzaamheid'),
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  children: [
                    for (final rarity in availableRarities)
                      FilterChip(
                        key: Key('dragon-filter-rarity-$rarity'),
                        label: Text(_rarityLabel(strings, rarity)),
                        selected: _rarityFilters.contains(rarity),
                        onSelected: (selected) => modalSetState(() => selected
                            ? _rarityFilters.add(rarity)
                            : _rarityFilters.remove(rarity)),
                      ),
                  ],
                ),
                if (ownedDragons.any((dragon) => dragon.spectral)) ...[
                  const SizedBox(height: 14),
                  FilterChip(
                    key: const Key('dragon-filter-spectral'),
                    avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(strings.pick(
                      'Spectral only',
                      'Alleen spectraal',
                    )),
                    selected: _spectralOnly,
                    onSelected: (selected) =>
                        modalSetState(() => _spectralOnly = selected),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('owned-dragons-filter-done'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text(strings.pick('Show dragons', 'Draken tonen')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
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
            return SafeArea(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                    child: dragon == null || !dragon.owned
                        ? Text(strings.pick(
                            'This dragon is no longer in your Haven.',
                            'Deze draak woont niet meer in je Haven.'))
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                Center(
                                    child: SizedBox.square(
                                        key: const Key(
                                            'canonical-dragon-detail-art'),
                                        dimension: 190,
                                        child: CanonicalDragonArt(
                                            dragon: dragon,
                                            height: 190,
                                            animate: true))),
                                Text(canonicalDragonName(strings, dragon),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall),
                                const SizedBox(height: 12),
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 13, vertical: 7),
                                    decoration: BoxDecoration(
                                        color: AppColors.eventColor(
                                            context, const Color(0xFFF4F0FB)),
                                        borderRadius:
                                            BorderRadius.circular(22)),
                                    child: Column(children: [
                                      _Fact(
                                          strings.pick(
                                              'Dragon type', 'Drakentype'),
                                          lineage == null
                                              ? unknown
                                              : strings.lineageName(lineage)),
                                      _Fact(
                                          strings.pick(
                                              'Maturity', 'Levensfase'),
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
                                              .where((v) =>
                                                  v.name == dragon.lawAxis)
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
                                    ])),
                                const SizedBox(height: 10),
                                _DragonProgressCard(dragon: dragon),
                                const SizedBox(height: 12),
                                if (dragon.schoolAttempts.values
                                    .any((attempts) => attempts > 0))
                                  _DragonSchoolDiplomaCard(dragon: dragon),
                                DragonTrialRecords(
                                  cavernFlightBest:
                                      dragon.trialBest('cavernFlight'),
                                  ruinBreakerBest:
                                      dragon.trialBest('ruinBreaker'),
                                  runeweaverBest:
                                      dragon.trialBest('runeweaver'),
                                  spiritAlignmentBest:
                                      dragon.trialBest('spiritAlignment'),
                                  ruinGuardBest: dragon.trialBest('ruinGuard'),
                                  runeOrbitBest: dragon.trialBest('runeOrbit'),
                                  showNewTrials: true,
                                ),
                                const Divider(height: 24),
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
                                          ? () => actions.buyStarlightTreat(id)
                                          : null),
                                if (view.activeDragonId == id)
                                  const SizedBox(height: 12),
                                if (dragon.evolutionReady)
                                  CanonicalActionButton(
                                      key: const Key('canonical-evolve-dragon'),
                                      label:
                                          strings.pick('Evolve', 'Evolueren'),
                                      action: enabled
                                          ? () => actions.evolveDragon(id)
                                          : null),
                                for (final relic in MysticRelic.values)
                                  if ((view.inventory.usableRelics[relic] ??
                                              0) >
                                          0 &&
                                      !relic.isEquipable &&
                                      relic.hasUseAnimation) ...[
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Image.asset(relic.assetPath,
                                          width: 40, height: 40),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(strings.relicName(relic)))
                                    ]),
                                    Text(strings.relicDescription(relic)),
                                    CanonicalActionButton(
                                        key: Key('canonical-use-${relic.name}'),
                                        label: strings.pick('Use', 'Gebruiken'),
                                        confirmation: strings.pick(
                                            'Use one ${strings.relicName(relic)} on this dragon?',
                                            'Eén ${strings.relicName(relic)} op deze draak gebruiken?'),
                                        action: enabled && !dragon.knows(relic)
                                            ? () => actions.useRelic(relic, id)
                                            : null),
                                  ],
                                const SizedBox(height: 16),
                                _CanonicalDragonActionsCard(
                                    dragon: dragon,
                                    view: view,
                                    owner: owner,
                                    actions: actions),
                              ])));
          }));
}

class _CanonicalDragonActionsCard extends StatelessWidget {
  const _CanonicalDragonActionsCard({
    required this.dragon,
    required this.view,
    required this.owner,
    required this.actions,
  });

  final CanonicalDragonView dragon;
  final CanonicalGameSnapshot view;
  final String owner;
  final CanonicalGameActions actions;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final quills = view.inventory.count(AltarRelic.nameweaversQuill);
    final canName = dragon.name.trim().isEmpty || quills > 0;
    final canRelease = !dragon.favorite &&
        dragon.adventureId == null &&
        view.dragons.where((candidate) => candidate.owned).length > 1;
    final tiles = <Widget>[
      _CanonicalDragonActionTile(
        key: const ValueKey('canonical-roam-dragon-state'),
        tileKey: const Key('canonical-roam-dragon'),
        leading: const GameIconSprite(
          GameIconKind.roomClear,
          key: Key('canonical-roam-action-sprite'),
          size: 38,
        ),
        title: dragon.roamsTower
            ? strings.pick('Remove from Tower', 'Uit de Toren halen')
            : strings.pick('Invite to Tower', 'Uitnodigen in de Toren'),
        trailing: dragon.roamsTower
            ? Icon(
                Icons.check_circle_rounded,
                color: AppColors.eventColor(context, AppColors.twilight),
              )
            : null,
        action: () => actions.setDragonRoaming(dragon.id, !dragon.roamsTower),
      ),
      for (final relic in MysticRelic.values)
        if (relic.isEquipable && (view.inventory.usableRelics[relic] ?? 0) > 0)
          _CanonicalDragonActionTile(
            key: ValueKey('canonical-equip-${relic.name}-state'),
            tileKey: Key('canonical-equip-${relic.name}'),
            leading: Image.asset(relic.assetPath, width: 40, height: 40),
            title: strings.relicName(relic),
            subtitle: strings.relicDescription(relic),
            trailing: view.inventory.equipment[relic] == dragon.id
                ? Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.eventColor(context, AppColors.twilight),
                  )
                : const Icon(Icons.add_circle_outline_rounded),
            action: () => actions.equip(
              relic,
              view.inventory.equipment[relic] == dragon.id ? null : dragon.id,
            ),
          ),
      _CanonicalDragonActionTile(
        key: const ValueKey('canonical-favorite-dragon-state'),
        tileKey: const Key('canonical-favorite-dragon'),
        leading: const GameIconSprite(
          GameIconKind.dragonFavorite,
          key: Key('canonical-favorite-action-sprite'),
          size: 40,
        ),
        title: strings.pick('Set as favorite', 'Instellen als favoriet'),
        trailing: dragon.favorite
            ? const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFE05A78),
              )
            : null,
        action:
            dragon.favorite ? null : () => actions.setFavoriteDragon(dragon.id),
      ),
      if (canName)
        _CanonicalDragonActionTile(
          key: const ValueKey('canonical-name-dragon-state'),
          tileKey: const Key('canonical-name-dragon'),
          leading: const GameIconSprite(
            GameIconKind.nameDragon,
            key: Key('canonical-name-action-sprite'),
            size: 40,
          ),
          title: dragon.name.trim().isEmpty
              ? strings.pick('Name dragon', 'Geef een naam')
              : strings.pick('Rename · 1 Quill', 'Hernoemen · 1 Quill'),
          action: () => nameCanonicalDragon(context, dragon, owner, actions),
        ),
      _CanonicalDragonActionTile(
        key: const ValueKey('canonical-release-dragon-state'),
        tileKey: const Key('canonical-release-dragon'),
        leading: Opacity(
          opacity: canRelease ? 1 : .38,
          child: const GameIconSprite(
            GameIconKind.dragonRelease,
            key: Key('canonical-release-action-sprite'),
            size: 40,
          ),
        ),
        title: strings.pick('Release dragon…', 'Draak vrijlaten…'),
        subtitle: dragon.adventureId == null
            ? null
            : strings.pick('This dragon is currently away on an Adventure.',
                'Deze draak is momenteel op avontuur.'),
        confirmation: strings.pick(
          'Release this dragon from your Haven?',
          'Deze draak vrijlaten uit je Haven?',
        ),
        action: canRelease ? () => actions.releaseDragon(dragon.id) : null,
      ),
    ];

    return Card(
      key: const Key('canonical-dragon-actions-card'),
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < tiles.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            tiles[index],
          ],
        ],
      ),
    );
  }
}

class _CanonicalDragonActionTile extends StatefulWidget {
  const _CanonicalDragonActionTile({
    super.key,
    required this.tileKey,
    required this.leading,
    required this.title,
    required this.action,
    this.subtitle,
    this.trailing,
    this.confirmation,
  });

  final Key tileKey;
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? confirmation;
  final Future<void> Function()? action;

  @override
  State<_CanonicalDragonActionTile> createState() =>
      _CanonicalDragonActionTileState();
}

class _CanonicalDragonActionTileState
    extends State<_CanonicalDragonActionTile> {
  bool _busy = false;

  Future<void> _run() async {
    final action = widget.action;
    if (_busy || action == null) return;
    final session = context.read<CanonicalGameSession>();
    final owner = session.snapshot?.ownerId;
    final epoch = session.connection.sessionEpoch;
    setState(() => _busy = true);
    try {
      final confirmation = widget.confirmation;
      if (confirmation != null &&
          (!mounted ||
              !await confirmCanonicalAction(
                context,
                confirmation,
                owner: owner,
                epoch: epoch,
              ))) {
        return;
      }
      if (mounted &&
          session.connection.sessionEpoch == epoch &&
          session.snapshot?.ownerId == owner &&
          session.canAct) {
        await runShopAction(context, action);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAct = context.watch<CanonicalGameSession>().canAct;
    final enabled = !_busy && widget.action != null && canAct;
    return ListTile(
      key: widget.tileKey,
      leading: widget.leading,
      title: Text(widget.title),
      subtitle: widget.subtitle == null ? null : Text(widget.subtitle!),
      trailing: widget.trailing,
      enabled: enabled,
      onTap: enabled ? _run : null,
    );
  }
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

class _DragonProgressCard extends StatelessWidget {
  const _DragonProgressCard({required this.dragon});

  final CanonicalDragonView dragon;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final level = Pet.levelAtXp(dragon.xp);
    final currentLevelFloor = Pet
        .levelThresholds[(level - 1).clamp(0, Pet.levelThresholds.length - 1)];
    final nextLevelTarget = level >= Pet.levelThresholds.length
        ? dragon.xp
        : Pet.levelThresholds[level];
    final progress = level >= Pet.levelThresholds.length
        ? 1.0
        : ((dragon.xp - currentLevelFloor) /
                (nextLevelTarget - currentLevelFloor))
            .clamp(0.0, 1.0);
    final nextEvolutionXp = switch (dragon.stage) {
      DragonStage.hatchling => Pet.wyrmlingXp,
      DragonStage.wyrmling => Pet.ascendedXp,
      _ => null,
    };
    final nextEvolutionLevel =
        nextEvolutionXp == null ? null : Pet.levelAtXp(nextEvolutionXp);
    final atMaximumLevel = level >= Pet.levelThresholds.length;
    final nextStage = switch (dragon.stage) {
      DragonStage.hatchling => DragonStage.wyrmling,
      DragonStage.wyrmling => DragonStage.ascended,
      _ => null
    };
    final nextStageName = switch (nextStage) {
      DragonStage.wyrmling => strings.petStageNameByKey('nestDragon'),
      DragonStage.ascended => strings.petStageNameByKey('homeGuardian'),
      _ => '',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
      decoration: BoxDecoration(
        gradient: AppColors.panelGradient(context,
            fallback: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2B1D55), Color(0xFF654A9B)])),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332B1D55),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const GameIconSprite(GameIconKind.experience, size: 38),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${strings.pick('Level', 'Niveau')} $level',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '${dragon.xp} XP',
            style: const TextStyle(
              color: Color(0xFFFFE39A),
              fontWeight: FontWeight.w900,
            ),
          ),
        ]),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            key: const Key('dragon-level-progress'),
            value: progress,
            minHeight: 12,
            color: const Color(0xFFFFD86E),
            backgroundColor: Colors.white.withValues(alpha: .16),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          atMaximumLevel
              ? strings.pick('Highest level reached', 'Hoogste niveau bereikt')
              : '${dragon.xp - currentLevelFloor} / '
                  '${nextLevelTarget - currentLevelFloor} XP '
                  '${strings.pick('to next level', 'tot het volgende niveau')}',
          style: const TextStyle(
            color: Color(0xFFD8CFF1),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Divider(height: 22, color: Color(0x33FFFFFF)),
        if (nextStage == null)
          Text(
            strings.pick('Final evolution reached', 'Laatste evolutie bereikt'),
            style: const TextStyle(
              color: Color(0xFFFFE39A),
              fontWeight: FontWeight.w900,
            ),
          )
        else ...[
          Text(
            '${strings.pick('Next evolution', 'Volgende evolutie')}: '
            '$nextStageName · ${strings.pick('Level', 'Niveau')} '
            '$nextEvolutionLevel'
            '${dragon.stage == DragonStage.wyrmling ? '' : ' · $nextEvolutionXp XP'}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (dragon.stage == DragonStage.wyrmling) ...[
            const SizedBox(height: 9),
            _CanonicalAscensionRequirements(
              dragon: dragon,
              onDark: true,
              compact: true,
              includeLevelRequirement: false,
            ),
          ],
        ],
      ]),
    );
  }
}

class _CanonicalAscensionRequirements extends StatelessWidget {
  const _CanonicalAscensionRequirements({
    required this.dragon,
    this.onDark = false,
    this.compact = false,
    this.includeLevelRequirement = true,
  });

  final CanonicalDragonView dragon;
  final bool onDark;
  final bool compact;
  final bool includeLevelRequirement;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final targetLevel = Pet.levelAtXp(Pet.ascendedXp);
    final levelReady = dragon.xp >= Pet.ascendedXp;
    final expertiseReady =
        dragon.training.values.fold<int>(0, (a, b) => a + b) >=
            Pet.ascensionExpertiseRequirement;
    final foreground = onDark ? Colors.white : AppColors.ink;
    final muted = onDark
        ? AppColors.eventColor(context, const Color(0xFFD8CFF1))
        : AppColors.muted;
    final track = onDark
        ? Colors.white.withValues(alpha: .14)
        : AppColors.eventColor(context, AppColors.mist).withValues(alpha: .8);

    return Container(
      key: const Key('ascension-requirements'),
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 13),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: .08)
            : AppColors.eventColor(context, AppColors.mist)
                .withValues(alpha: .48),
        borderRadius: BorderRadius.circular(compact ? 14 : 17),
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: .14)
              : AppColors.eventColor(context, AppColors.twilight)
                  .withValues(alpha: .12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: compact ? 17 : 19,
                color: onDark ? const Color(0xFFFFE39A) : AppColors.gold,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  strings.pick(
                    'Ascension requirements',
                    'Ascension-vereisten',
                  ),
                  style: TextStyle(
                    color: foreground,
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (levelReady && expertiseReady) _ReadyPill(onDark: onDark),
            ],
          ),
          if (includeLevelRequirement) ...[
            SizedBox(height: compact ? 3 : 5),
            Text(
              strings.pick(
                'Complete both requirements before Ascension.',
                'Voltooi beide vereisten voor Ascension.',
              ),
              style: TextStyle(
                color: muted,
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: compact ? 9 : 12),
            _RequirementProgress(
              key: const Key('ascension-level-requirement'),
              statusKey: const Key('ascension-level-status'),
              title: strings.pick('Level & XP', 'Niveau & XP'),
              value:
                  '${strings.pick('Level', 'Niveau')} ${Pet.levelAtXp(dragon.xp)}/$targetLevel'
                  ' · ${dragon.xp}/${Pet.ascendedXp} XP',
              progress: dragon.xp / Pet.ascendedXp,
              complete: levelReady,
              foreground: foreground,
              muted: muted,
              track: track,
              compact: compact,
            ),
            SizedBox(height: compact ? 9 : 12),
          ] else
            SizedBox(height: compact ? 7 : 10),
          _RequirementProgress(
            key: const Key('ascension-expertise-requirement'),
            statusKey: const Key('ascension-expertise-status'),
            title: strings.pick(
              'Minimum total Expertise',
              'Minimale totale Expertise',
            ),
            value:
                '${dragon.training.values.fold<int>(0, (a, b) => a + b)}/${Pet.ascensionExpertiseRequirement}',
            progress: dragon.training.values.fold<int>(0, (a, b) => a + b) /
                Pet.ascensionExpertiseRequirement,
            complete: expertiseReady,
            foreground: foreground,
            muted: muted,
            track: track,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _ReadyPill extends StatelessWidget {
  const _ReadyPill({required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      key: const Key('ascension-ready'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: onDark ? .24 : .18),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 13, color: AppColors.mint),
          const SizedBox(width: 3),
          Text(
            strings.pick('Ready', 'Klaar'),
            style: TextStyle(
              color: onDark
                  ? Colors.white
                  : AppColors.eventColor(context, AppColors.twilightDark),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementProgress extends StatelessWidget {
  const _RequirementProgress({
    super.key,
    required this.statusKey,
    required this.title,
    required this.value,
    required this.progress,
    required this.complete,
    required this.foreground,
    required this.muted,
    required this.track,
    required this.compact,
  });

  final Key statusKey;
  final String title;
  final String value;
  final double progress;
  final bool complete;
  final Color foreground;
  final Color muted;
  final Color track;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              key: statusKey,
              width: compact ? 20 : 23,
              height: compact ? 20 : 23,
              decoration: BoxDecoration(
                color: complete
                    ? AppColors.mint.withValues(alpha: .18)
                    : AppColors.gold.withValues(alpha: .16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                complete ? Icons.check_rounded : Icons.lock_clock_rounded,
                size: compact ? 13 : 15,
                color: complete ? AppColors.mint : AppColors.gold,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: foreground,
                  fontSize: compact ? 11 : 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: complete ? AppColors.mint : muted,
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: compact ? 5 : 6,
            color: complete ? AppColors.mint : AppColors.gold,
            backgroundColor: track,
          ),
        ),
      ],
    );
  }
}
