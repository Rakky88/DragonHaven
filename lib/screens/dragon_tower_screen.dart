import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/day_phase.dart';
import '../models/house.dart';
import '../models/pet.dart';
import '../providers/household_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dragon_art.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/haven_lighting.dart';
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
        Text(
          strings.tr('tower'),
          style: Theme.of(context).textTheme.displaySmall,
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
        Row(children: [
          Expanded(
            child: _TowerShortcut(
              onPressed: () => _showOwnedDragons(context),
              kind: GameIconKind.myDragons,
              label: strings.pick('My dragons', 'Mijn draken'),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _TowerShortcut(
              key: const Key('open-draconomicon'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(
                    appBar: _CodexBar(),
                    body: DraconomiconScreen(),
                  ),
                ),
              ),
              kind: GameIconKind.draconomicon,
              label: 'Draconomicon',
            ),
          ),
        ]),
        const SizedBox(height: 14),
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
            Positioned.fill(
              child: HavenPhaseImage(
                assetFor: (value) =>
                    'assets/images/tower_nest_${value.assetKey}.webp',
              ),
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GameIconSprite(GameIconKind.mysteriousEgg, size: 25),
                        SizedBox(width: 4),
                        GameIconSprite(GameIconKind.clock, size: 20),
                      ],
                    ),
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

class _TowerShortcut extends StatelessWidget {
  const _TowerShortcut({
    super.key,
    required this.onPressed,
    required this.kind,
    required this.label,
  });

  final VoidCallback onPressed;
  final GameIconKind kind;
  final String label;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: 86,
            padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF1EBFF), Color(0xFFFFF5DF)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE1D7F2)),
            ),
            child: Row(children: [
              GameIconSprite(kind, size: 58),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
}

class _OwnedDragonsSheet extends StatelessWidget {
  const _OwnedDragonsSheet();
  @override
  Widget build(BuildContext context) {
    final game = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
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
                  Text(strings.pick('My dragons', 'Mijn draken'),
                      style: Theme.of(context).textTheme.titleLarge),
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
              child: GridView.builder(
                key: const Key('owned-dragons-grid'),
                controller: controller,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                itemCount: game.ownedDragons.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
                  childAspectRatio: .88,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final dragon = game.ownedDragons[index];
                  return _OwnedDragonGridCard(
                    dragon: dragon,
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
                _DragonDetailRow(
                    icon: const GameIconSprite(GameIconKind.might, size: 27),
                    label: strings.pick('Might', 'Kracht'),
                    value: '${dragon.trainingFor(TrainingFocus.might)}'),
                _DragonDetailRow(
                    icon: const GameIconSprite(GameIconKind.arcana, size: 27),
                    label: strings.pick('Arcana', 'Arcana'),
                    value: '${dragon.trainingFor(TrainingFocus.arcana)}'),
                _DragonDetailRow(
                    icon: const GameIconSprite(GameIconKind.spirit, size: 27),
                    label: strings.pick('Spirit', 'Geest'),
                    value: '${dragon.trainingFor(TrainingFocus.spirit)}'),
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
            Card(
              margin: EdgeInsets.zero,
              child: Column(children: [
                ListTile(
                  key: Key('dragon-roaming-${dragon.id}'),
                  leading:
                      const GameIconSprite(GameIconKind.roomClear, size: 38),
                  title: Text(strings.pick(
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
                ListTile(
                  leading: const Icon(Icons.favorite_rounded),
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
                  leading: const Icon(Icons.flight_takeoff_rounded),
                  title:
                      Text(strings.pick('Release dragon…', 'Draak vrijlaten…')),
                  enabled: !dragon.favorite,
                  onTap: dragon.favorite
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
                                      'This dragon leaves your collection and cannot be trained. Its identity, form, alignment and hidden personality are preserved.',
                                      'Deze draak verlaat je collectie en kan niet meer worden getraind. Identiteit, vorm, alignment en verborgen persoonlijkheid blijven bewaard.')),
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
    final remainingAge = dragon.remainingForNextStage(DateTime.now());
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
          const SizedBox(height: 5),
          Text(
            remainingAge == Duration.zero
                ? strings.pick('Minimum age reached', 'Minimumleeftijd bereikt')
                : '${strings.pick('Minimum age remaining', 'Resterende minimumleeftijd')}: '
                    '${strings.evolutionRemaining(remainingAge)}',
            style: const TextStyle(
              color: Color(0xFFD8CFF1),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (dragon.stage == DragonStage.wyrmling) ...[
            const SizedBox(height: 3),
            Text(
              '${strings.pick('Training required', 'Training vereist')}: '
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
  const _OwnedDragonGridCard({required this.dragon, required this.onTap});

  final Pet dragon;
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
          ]),
        ),
      ),
    );
  }
}

class _DragonDetailRow extends StatelessWidget {
  const _DragonDetailRow({
    required this.label,
    required this.value,
    this.icon,
  });

  final Widget? icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          if (icon != null) ...[
            SizedBox.square(dimension: 30, child: Center(child: icon)),
            const SizedBox(width: 7),
          ],
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
