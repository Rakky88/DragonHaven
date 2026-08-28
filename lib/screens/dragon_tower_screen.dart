import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/day_phase.dart';
import '../models/dragon_lineage.dart';
import '../models/house.dart';
import '../models/mystic_relic.dart';
import '../models/pet.dart';
import '../providers/household_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';
import '../widgets/dragon_trial_records.dart';
import '../widgets/expertise_score_badge.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/haven_lighting.dart';
import '../widgets/rooftop_egg_nest.dart';
import 'draconomicon_screen.dart';
import 'house_screen.dart';
import 'pet_screen.dart';
import 'rooftop_nest_screen.dart';
import 'shop_screen.dart';

class DragonTowerScreen extends StatelessWidget {
  const DragonTowerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    if (game.pet.isEgg) return const PetScreen();
    final strings = AppStrings.of(context);
    final phase = havenDayPhaseAt(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HavenAudio.setMusicScene(
        phase.isDark ? HavenMusicScene.towerNight : HavenMusicScene.towerDay,
      );
    });
    return ListView(
      key: const PageStorageKey('dragon-tower-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 34),
      children: [
        Row(
          children: [
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  strings.tr('tower'),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _TowerTopIconButton(
              key: const Key('open-my-dragons'),
              icon: GameIconKind.myDragons,
              tooltip: strings.pick('My dragons', 'Mijn draken'),
              onPressed: () => _showOwnedDragons(context),
            ),
            const SizedBox(width: 7),
            _TowerTopIconButton(
              key: const Key('open-draconomicon'),
              icon: GameIconKind.draconomicon,
              tooltip: 'Draconomicon',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(
                    appBar: _CodexBar(),
                    body: DraconomiconScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(children: [
          const GameIconSprite(GameIconKind.clock, size: 21),
          const SizedBox(width: 5),
          Expanded(
            child: HavenClockBuilder(
              builder: (_, __, livePhase) => Text(
                strings.dayPhase(livePhase),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.muted, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
              '${game.towerFloorCount}/20 ${strings.pick('floors', 'verdiepingen')}',
              style: const TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        const _TowerRoof(),
        const SizedBox(height: 9),
        for (var index = game.towerFloorRoomIds.length - 1; index >= 0; index--)
          _TowerFloor(index: index, roomId: game.towerFloorRoomIds[index]),
        const SizedBox(height: 12),
        _BuildFloorButton(
          key: const Key('add-tower-floor'),
          onPressed:
              game.towerFloorCount >= 20 ? null : () => _addFloor(context),
          label: Text(game.towerFloorCount >= 20
              ? strings.pick(
                  'Maximum height reached', 'Maximale hoogte bereikt')
              : strings.pick('Add a floor · ${game.nextTowerFloorPrice} coins',
                  'Verdieping toevoegen · ${game.nextTowerFloorPrice} munten')),
        ),
        if (game.latestReturningEvent case final event?) ...[
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFFFF2D8),
            child: ListTile(
              leading: const Icon(Icons.history_toggle_off_rounded,
                  color: Color(0xFF9A6A00)),
              title: Text(strings.pick('A familiar shadow returned',
                  'Een bekende schaduw keerde terug')),
              subtitle: Text(event),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _addFloor(BuildContext context) async {
    final strings = AppStrings.of(context);
    final room = await showModalBottomSheet<HouseRoomDefinition>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          key: const Key('tower-room-picker-scroll'),
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
          children: [
            Text(strings.pick('Choose a room type', 'Kies een kamertype'),
                style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final definition
                in houseRoomCatalog.where((room) => room.id != 'nest'))
              Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(definition.backgroundAsset,
                        width: 58, height: 48, fit: BoxFit.cover),
                  ),
                  title: Text(strings.roomName(definition),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(strings.pick('Unique atmosphere and layout',
                      'Eigen sfeer en indeling')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(sheetContext, definition),
                ),
              ),
          ],
        ),
      ),
    );
    if (room == null || !context.mounted) return;
    final result =
        await context.read<HouseholdProvider>().buildTowerFloor(room.id);
    if (!context.mounted || result == TowerBuildResult.built) return;
    final message = switch (result) {
      TowerBuildResult.maximumReached => strings.pick(
          'The tower already has 20 floors.',
          'De toren heeft al 20 verdiepingen.'),
      TowerBuildResult.insufficientCoins => strings.pick(
          'Not enough coins for this floor.',
          'Niet genoeg munten voor deze verdieping.'),
      TowerBuildResult.invalidRoom => strings.pick(
          'That room cannot be built here.',
          'Die kamer kan hier niet worden gebouwd.'),
      TowerBuildResult.built => '',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showOwnedDragons(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => const _OwnedDragonsSheet(),
      );
}

class _TowerRoof extends StatelessWidget {
  const _TowerRoof();

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
    return InkWell(
      key: const Key('tower-roof'),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
                appBar: _NestBar(),
                body: RooftopNestScreen(),
              ))),
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        height: 215,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(children: [
            if (game.nestEgg == null)
              Positioned.fill(
                child: HavenPhaseImage(
                  assetFor: (value) =>
                      'assets/images/tower_nest_${value.assetKey}.webp',
                ),
              )
            else
              const Positioned.fill(
                child: IgnorePointer(child: RooftopEggNest()),
              ),
            Positioned(
              left: 14,
              right: 14,
              top: 13,
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strings.pick('Rooftop Nest', 'Daknest'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18)),
                    ],
                  ),
                ),
                if (game.nestEgg != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xD91B1436),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const GameIconSprite(GameIconKind.clock, size: 22),
                  ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _TowerFloor extends StatelessWidget {
  const _TowerFloor({required this.index, required this.roomId});
  final int index;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final room = houseRoomById(roomId) ?? houseRoomCatalog[1];
    final damaged = game.damagedTowerFloors.contains(index);
    final floorDragons = game.towerDragons
        .where((dragon) =>
            dragon.activeAdventureId == null &&
            dragon.currentFloorIndex == index)
        .take(3)
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        key: Key('tower-floor-$index'),
        onTap: () async {
          await game.selectRoom(room.id);
          if (context.mounted) {
            await Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: _RoomBar(room: room),
                body: HouseScreen(
                  active: true,
                  floorIndex: index,
                  onOpenShop: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(
                            appBar: _ShopBar(), body: ShopScreen())),
                  ),
                ),
              ),
            ));
          }
        },
        borderRadius: BorderRadius.circular(19),
        child: Ink(
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            image: DecorationImage(
                image: AssetImage(room.backgroundAsset), fit: BoxFit.cover),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              gradient: const LinearGradient(
                colors: [Color(0xB5201C3F), Color(0x18201C3F)],
              ),
            ),
            padding: const EdgeInsets.all(13),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: .9),
                child: Text('${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(strings.roomName(room),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
              ),
              if (!damaged && floorDragons.isNotEmpty) ...[
                _TowerFloorDragons(dragons: floorDragons),
                const SizedBox(width: 6),
              ],
              if (damaged)
                FilledButton.tonalIcon(
                  onPressed: () => game.repairTowerFloor(index),
                  icon: const Icon(Icons.construction_rounded, size: 17),
                  label: Text(
                      '${strings.pick('Repair', 'Repareer')} · ${game.repairTowerFloorPrice(index)}'),
                )
              else
                const Icon(Icons.zoom_in_rounded, color: Colors.white),
            ]),
          ),
        ),
      ),
    );
  }
}

class _TowerFloorDragons extends StatelessWidget {
  const _TowerFloorDragons({required this.dragons});

  final List<Pet> dragons;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 36 + (dragons.length - 1) * 18,
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = 0; index < dragons.length; index++)
              Positioned(
                key: Key('tower-floor-dragon-${dragons[index].id}'),
                left: index * 18,
                top: index.isOdd ? 3 : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xD9FFF9ED),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFD86B)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x660D0820),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: DragonArt(
                      height: 34,
                      animate: false,
                      stageKey: dragons[index].stageKey,
                      lineageId: dragons[index].lineageId,
                      evolutionPath: dragons[index].activeEvolutionPath,
                      prismatic: dragons[index].prismatic,
                      sinister: dragons[index].sinister,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _BuildFloorButton extends StatelessWidget {
  const _BuildFloorButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  final VoidCallback? onPressed;
  final Widget label;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            height: 92,
            padding: const EdgeInsets.fromLTRB(10, 7, 16, 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: onPressed == null
                    ? const [Color(0xFFE9E7ED), Color(0xFFF4F2F6)]
                    : const [Color(0xFFECE5FF), Color(0xFFFFF3D4)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDED4ED)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x185B4B8A),
                    blurRadius: 12,
                    offset: Offset(0, 5)),
              ],
            ),
            child: Row(children: [
              Opacity(
                opacity: onPressed == null ? .45 : 1,
                child: const GameIconSprite(GameIconKind.towerBuild, size: 76),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DefaultTextStyle(
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900),
                  child: label,
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.twilight),
            ]),
          ),
        ),
      );
}

class _TowerTopIconButton extends StatelessWidget {
  const _TowerTopIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final GameIconKind icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: tooltip,
        child: Tooltip(
          message: tooltip,
          child: Material(
            color: Colors.transparent,
            child: InkResponse(
              onTap: onPressed,
              radius: 32,
              child: SizedBox(
                width: 64,
                height: 64,
                child: Center(child: GameIconSprite(icon, size: 60)),
              ),
            ),
          ),
        ),
      );
}

enum _DragonCollectionView { gallery, compact }

enum _DragonSortMode { name, acquiredAt, rarity }

class _OwnedDragonsSheet extends StatefulWidget {
  const _OwnedDragonsSheet();

  @override
  State<_OwnedDragonsSheet> createState() => _OwnedDragonsSheetState();
}

class _OwnedDragonsSheetState extends State<_OwnedDragonsSheet> {
  _DragonCollectionView _view = _DragonCollectionView.gallery;
  _DragonSortMode _sortMode = _DragonSortMode.acquiredAt;
  bool _sortDescending = true;
  final Set<String> _formFilters = {};
  final Set<String> _rarityFilters = {};
  bool _spectralOnly = false;

  String _formKey(Pet dragon) => switch (dragon.stage) {
        DragonStage.hatchling => 'hatchling',
        DragonStage.wyrmling => 'wyrmling',
        DragonStage.ascended => dragon.activeEvolutionPath,
        DragonStage.egg => 'egg',
      };

  String _rarityKey(Pet dragon) =>
      dragon.sinister ? 'infernal' : dragon.lineage.rarity.name;

  List<Pet> _filteredDragons(Iterable<Pet> source) => source
      .where(
        (dragon) =>
            (_formFilters.isEmpty || _formFilters.contains(_formKey(dragon))) &&
            (_rarityFilters.isEmpty ||
                _rarityFilters.contains(_rarityKey(dragon))) &&
            (!_spectralOnly || dragon.spectral),
      )
      .toList(growable: false);

  List<Pet> _sortedDragons(Iterable<Pet> source) {
    final dragons = source.toList(growable: false);
    dragons.sort((a, b) {
      final comparison = switch (_sortMode) {
        _DragonSortMode.name =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
        _DragonSortMode.acquiredAt => a.acquiredAt.compareTo(b.acquiredAt),
        _DragonSortMode.rarity => _rarityRank(a).compareTo(_rarityRank(b)),
      };
      final stable = comparison != 0
          ? comparison
          : a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      return _sortDescending ? -stable : stable;
    });
    return dragons;
  }

  int _rarityRank(Pet dragon) => dragon.sinister
      ? DragonRarity.values.length
      : dragon.lineage.rarity.index;

  String _sortLabel(AppStrings strings) => switch (_sortMode) {
        _DragonSortMode.name => strings.pick('Name', 'Naam'),
        _DragonSortMode.acquiredAt => strings.pick('Received', 'Ontvangen'),
        _DragonSortMode.rarity => strings.pick('Rarity', 'Zeldzaamheid'),
      };

  void _selectSort(_DragonSortMode value) {
    setState(() {
      if (_sortMode == value) {
        _sortDescending = !_sortDescending;
      } else {
        _sortMode = value;
        _sortDescending = value != _DragonSortMode.name;
      }
    });
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
    final game = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final dragons = _sortedDragons(_filteredDragons(game.ownedDragons));
    final activeFilterCount =
        _formFilters.length + _rarityFilters.length + (_spectralOnly ? 1 : 0);
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .7,
        maxChildSize: .92,
        builder: (_, controller) => Column(
          key: const Key('owned-dragons-scroll'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.pick('My dragons', 'Mijn draken'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
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
                                    _DragonSortMode.acquiredAt =>
                                      Icons.event_rounded,
                                    _DragonSortMode.rarity =>
                                      Icons.auto_awesome_rounded,
                                  }),
                                  const SizedBox(width: 9),
                                  Text(switch (mode) {
                                    _DragonSortMode.name =>
                                      strings.pick('Name', 'Naam'),
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
                            color: const Color(0xFFF1ECFB),
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
                                color: AppColors.twilight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _sortLabel(strings),
                                style: const TextStyle(
                                  color: AppColors.twilight,
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
                            game.ownedDragons,
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
                        onPressed: () => setState(() {
                          _view = _view == _DragonCollectionView.gallery
                              ? _DragonCollectionView.compact
                              : _DragonCollectionView.gallery;
                        }),
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
                      color: const Color(0xFFF1ECFB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      const GameIconSprite(GameIconKind.roomClear, size: 34),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.pick(
                            '${game.selectedRoamingDragonCount} / ${game.towerRoamingCapacity} roaming · maximum 3 per room',
                            '${game.selectedRoamingDragonCount} / ${game.towerRoamingCapacity} actief · maximaal 3 per kamer',
                          ),
                          style: const TextStyle(
                            color: AppColors.twilight,
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
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                          itemCount: dragons.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
                            childAspectRatio: .88,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemBuilder: (context, index) {
                            final dragon = dragons[index];
                            return _OwnedDragonGridCard(
                              dragon: dragon,
                              twinstarEquipped:
                                  game.isTwinstarEquippedOn(dragon.id),
                              onTap: () => _showDragonDetails(context, dragon),
                            );
                          },
                        )
                      : ListView.separated(
                          key: const Key('owned-dragons-list'),
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                          itemCount: dragons.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 7),
                          itemBuilder: (context, index) {
                            final dragon = dragons[index];
                            return _OwnedDragonListCard(
                              dragon: dragon,
                              twinstarEquipped:
                                  game.isTwinstarEquippedOn(dragon.id),
                              onTap: () => _showDragonDetails(context, dragon),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilters(
    BuildContext context,
    Iterable<Pet> ownedDragons,
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

  Future<void> _showDragonDetails(BuildContext context, Pet dragon) async {
    final strings = AppStrings.of(context);
    final game = context.read<HouseholdProvider>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox.square(
              dimension: 190,
              child: DragonArt(
                height: 190,
                animate: true,
                stageKey: dragon.stageKey,
                lineageId: dragon.lineageId,
                evolutionPath: dragon.activeEvolutionPath,
                prismatic: dragon.spectral,
                sinister: dragon.sinister,
              ),
            ),
            Text(dragon.displayName,
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F0FB),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(children: [
                _DragonDetailRow(
                    label: strings.pick('Dragon type', 'Draaktype'),
                    value: strings.lineageName(dragon.lineage)),
                _DragonDetailRow(
                    label: strings.pick('Maturity', 'Volwassenheid'),
                    value: strings.petStage(dragon)),
                const Divider(height: 13),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    strings.pick('Expertises', 'Expertises'),
                    style: const TextStyle(
                      color: AppColors.twilight,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .35,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                for (final focus in TrainingFocus.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: ExpertiseScoreBadge(
                      dragonId: dragon.id,
                      focus: focus,
                      focusLabel: switch (focus) {
                        TrainingFocus.might => strings.pick('Might', 'Kracht'),
                        TrainingFocus.arcana =>
                          strings.pick('Arcana', 'Arcana'),
                        TrainingFocus.spirit => strings.pick('Spirit', 'Geest'),
                      },
                      score: dragon.trainingFor(focus),
                      maximum: dragon.expertiseMaximum(focus),
                      iconSize: 27,
                      expand: true,
                    ),
                  ),
                const Divider(height: 13),
                _DragonDetailRow(
                  label: strings.pick('Moral nature', 'Morele aard'),
                  value: dragon.moralAxisKnown
                      ? strings.moralAxisName(dragon.moralAxis)
                      : strings.pick('Undiscovered', 'Onontdekt'),
                ),
                _DragonDetailRow(
                  label: strings.pick('Order nature', 'Orde-aard'),
                  value: dragon.lawAxisKnown
                      ? strings.lawAxisName(dragon.lawAxis)
                      : strings.pick('Undiscovered', 'Onontdekt'),
                ),
                _DragonDetailRow(
                  label: strings.pick('Personality', 'Karakter'),
                  value: dragon.personalityKnown
                      ? dragon.personalityTraitIds
                          .map(strings.personality)
                          .join(' · ')
                      : strings.pick('Undiscovered', 'Onontdekt'),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            _DragonProgressCard(dragon: dragon),
            const SizedBox(height: 10),
            DragonTrialRecords(
              cavernFlightBest: dragon.trialBest('cavernFlight'),
              ruinBreakerBest: dragon.trialBest('ruinBreaker'),
              runeweaverBest: dragon.trialBest('runeweaver'),
            ),
            const SizedBox(height: 10),
            Card(
              margin: EdgeInsets.zero,
              child: Column(children: [
                ListTile(
                  key: Key('dragon-roaming-${dragon.id}'),
                  leading:
                      const GameIconSprite(GameIconKind.roomClear, size: 38),
                  title: Text(dragon.roamsTower
                      ? strings.pick('Remove from Tower', 'Uit de Toren halen')
                      : strings.pick(
                          'Invite to Tower', 'Uitnodigen in de Toren')),
                  trailing: dragon.roamsTower
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.twilight)
                      : null,
                  onTap: () async {
                    final result = await game.setDragonRoaming(
                        dragon.id, !dragon.roamsTower);
                    if (!sheetContext.mounted) return;
                    if (result == DragonRoamingResult.towerFull) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(strings.pick(
                          'The Tower is full. Build another floor or disable another roaming dragon.',
                          'De Toren is vol. Bouw een verdieping of zet een andere rondlopende draak uit.',
                        )),
                      ));
                      return;
                    }
                    Navigator.pop(sheetContext);
                  },
                ),
                const Divider(height: 1),
                if (game.hasTwinstarBrooch) ...[
                  ListTile(
                    key: Key('dragon-twinstar-${dragon.id}'),
                    leading: SizedBox.square(
                      dimension: 40,
                      child: Image.asset(
                        MysticRelic.twinstarBrooch.assetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                    title: Text(
                      game.isTwinstarEquippedOn(dragon.id)
                          ? strings.pick(
                              'Unequip Twinstar Brooch',
                              'Tweesterbroche afdoen',
                            )
                          : game.twinstarBroochDragonId == null
                              ? strings.pick(
                                  'Equip Twinstar Brooch',
                                  'Tweesterbroche omdoen',
                                )
                              : strings.pick(
                                  'Move Twinstar Brooch here',
                                  'Tweesterbroche hierheen verplaatsen',
                                ),
                    ),
                    subtitle: Text(strings.pick(
                      'Doubles all XP while equipped',
                      'Verdubbelt alle XP zolang hij gedragen wordt',
                    )),
                    trailing: game.isTwinstarEquippedOn(dragon.id)
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.twilight,
                          )
                        : null,
                    onTap: () async {
                      final equipped = game.isTwinstarEquippedOn(dragon.id);
                      await game.equipTwinstarBrooch(
                        equipped ? null : dragon.id,
                      );
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: const GameIconSprite(
                    GameIconKind.dragonFavorite,
                    key: Key('dragon-favorite-action-sprite'),
                    size: 40,
                  ),
                  title: Text(strings.pick(
                      'Set as favorite', 'Instellen als favoriet')),
                  enabled: !dragon.favorite,
                  trailing: dragon.favorite
                      ? const Icon(Icons.check_circle_rounded,
                          color: Color(0xFFE05A78))
                      : null,
                  onTap: dragon.favorite
                      ? null
                      : () async {
                          Navigator.pop(sheetContext);
                          await game.toggleFavorite(dragon.id);
                        },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Opacity(
                    opacity: dragon.favorite || dragon.activeAdventureId != null
                        ? .38
                        : 1,
                    child: const GameIconSprite(
                      GameIconKind.dragonRelease,
                      key: Key('dragon-release-action-sprite'),
                      size: 40,
                    ),
                  ),
                  title:
                      Text(strings.pick('Release dragon…', 'Draak vrijlaten…')),
                  subtitle: dragon.activeAdventureId == null
                      ? null
                      : Text(strings.pick(
                          'This dragon is currently away on an Adventure.',
                          'Deze draak is momenteel op avontuur.')),
                  enabled: !dragon.favorite && dragon.activeAdventureId == null,
                  onTap: dragon.favorite || dragon.activeAdventureId != null
                      ? null
                      : () async {
                          Navigator.pop(sheetContext);
                          final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  scrollable: true,
                                  title: Text(strings.pick(
                                      'Release ${dragon.displayName}?',
                                      '${dragon.displayName} vrijlaten?')),
                                  content: Text(strings.pick(
                                      'This dragon leaves your collection and cannot be trained. Its identity, form, alignment and hidden personality are preserved. Each day it has a 10% chance to return at a random time.',
                                      'Deze draak verlaat je collectie en kan niet meer worden getraind. Identiteit, vorm, alignment en verborgen persoonlijkheid blijven bewaard. Elke dag heeft hij 10% kans om op een willekeurig tijdstip terug te keren.')),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: Text(strings.tr('cancel'))),
                                    FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: Text(strings.pick(
                                            'Release', 'Vrijlaten'))),
                                  ],
                                ),
                              ) ??
                              false;
                          if (confirmed) {
                            await game.releaseDragon(dragon.id);
                          }
                        },
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DragonProgressCard extends StatelessWidget {
  const _DragonProgressCard({required this.dragon});

  final Pet dragon;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final atMaximumLevel = dragon.level >= Pet.levelThresholds.length;
    final nextStage = dragon.nextEvolutionStage;
    final nextStageName = switch (nextStage) {
      DragonStage.wyrmling => strings.petStageNameByKey('nestDragon'),
      DragonStage.ascended => strings.petStageNameByKey('homeGuardian'),
      _ => '',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B1D55), Color(0xFF654A9B)],
        ),
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
              '${strings.pick('Level', 'Niveau')} ${dragon.level}',
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
            value: dragon.levelProgress,
            minHeight: 12,
            color: const Color(0xFFFFD86E),
            backgroundColor: Colors.white.withValues(alpha: .16),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          atMaximumLevel
              ? strings.pick('Highest level reached', 'Hoogste niveau bereikt')
              : '${dragon.xp - dragon.currentLevelFloor} / '
                  '${dragon.nextLevelTarget - dragon.currentLevelFloor} XP '
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
            '${dragon.nextEvolutionLevel} · ${dragon.nextEvolutionXp} XP',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (dragon.stage == DragonStage.wyrmling) ...[
            const SizedBox(height: 5),
            Text(
              '${strings.pick('Expertises required', 'Expertises vereist')}: '
              '${dragon.totalTraining}/300',
              style: const TextStyle(
                color: Color(0xFFD8CFF1),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ]),
    );
  }
}

class _OwnedDragonGridCard extends StatelessWidget {
  const _OwnedDragonGridCard({
    required this.dragon,
    required this.twinstarEquipped,
    required this.onTap,
  });

  final Pet dragon;
  final bool twinstarEquipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        key: Key('owned-dragon-${dragon.id}'),
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
                      stageKey: dragon.stageKey,
                      lineageId: dragon.lineageId,
                      evolutionPath: dragon.activeEvolutionPath,
                      prismatic: dragon.spectral,
                      sinister: dragon.sinister,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dragon.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
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
            if (twinstarEquipped)
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
                      MysticRelic.twinstarBrooch.assetPath,
                      key: Key('dragon-twinstar-badge-${dragon.id}'),
                      width: 24,
                      height: 24,
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

class _OwnedDragonListCard extends StatelessWidget {
  const _OwnedDragonListCard({
    required this.dragon,
    required this.twinstarEquipped,
    required this.onTap,
  });

  final Pet dragon;
  final bool twinstarEquipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final received = MaterialLocalizations.of(context).formatShortDate(
      dragon.acquiredAt,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        key: Key('owned-dragon-list-${dragon.id}'),
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
                  stageKey: dragon.stageKey,
                  lineageId: dragon.lineageId,
                  evolutionPath: dragon.activeEvolutionPath,
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
                            dragon.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (dragon.favorite) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFE05A78),
                            size: 15,
                          ),
                        ],
                        if (twinstarEquipped) ...[
                          const SizedBox(width: 4),
                          Image.asset(
                            MysticRelic.twinstarBrooch.assetPath,
                            key: Key('dragon-twinstar-list-${dragon.id}'),
                            width: 19,
                            height: 19,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${strings.lineageName(dragon.lineage)} · '
                      '${strings.lineageRarity(dragon.lineage)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.twilight,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${strings.petStage(dragon)} · '
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

class _DragonDetailRow extends StatelessWidget {
  const _DragonDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ),
          Text(value,
              style: const TextStyle(
                  color: AppColors.ink, fontWeight: FontWeight.w900)),
        ]),
      );
}

class _CodexBar extends StatelessWidget implements PreferredSizeWidget {
  const _CodexBar();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
      title: Text(
          AppStrings.of(context).pick('The Draconomicon', 'Het Draconomicon')));
}

class _NestBar extends StatelessWidget implements PreferredSizeWidget {
  const _NestBar();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
      title: Text(AppStrings.of(context).pick('Rooftop Nest', 'Daknest')));
}

class _RoomBar extends StatelessWidget implements PreferredSizeWidget {
  const _RoomBar({required this.room});

  final HouseRoomDefinition room;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        leadingWidth: 66,
        leading: IconButton(
          key: const Key('zoom-out-room'),
          tooltip: AppStrings.of(context).pick('Zoom out', 'Uitzoomen'),
          onPressed: () => Navigator.maybePop(context),
          icon: const GameIconSprite(GameIconKind.roomZoomOut, size: 48),
        ),
        title: Text(AppStrings.of(context).roomName(room)),
      );
}

class _ShopBar extends StatelessWidget implements PreferredSizeWidget {
  const _ShopBar();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) =>
      AppBar(title: Text(AppStrings.of(context).tr('shop')));
}
