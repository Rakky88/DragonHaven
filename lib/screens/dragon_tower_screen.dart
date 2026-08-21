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
import '../widgets/haven_lighting.dart';
import 'draconomicon_screen.dart';
import 'house_screen.dart';
import 'pet_screen.dart';
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
        Row(children: [
          Expanded(
            child: Text(
              strings.tr('tower'),
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          _Currency(icon: Icons.monetization_on_rounded, value: game.coins),
          const SizedBox(width: 7),
          _Currency(icon: Icons.diamond_rounded, value: game.gems),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.schedule_rounded, size: 15, color: AppColors.muted),
          const SizedBox(width: 5),
          Expanded(
            child: HavenClockBuilder(
              builder: (_, __, livePhase) => Text(
                livePhase.label(strings.isDutch),
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
        const SizedBox(height: 14),
        const _TowerRoof(),
        const SizedBox(height: 9),
        for (var index = game.towerFloorRoomIds.length - 1; index >= 0; index--)
          _TowerFloor(index: index, roomId: game.towerFloorRoomIds[index]),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('add-tower-floor'),
          onPressed:
              game.towerFloorCount >= 20 ? null : () => _addFloor(context),
          icon: const Icon(Icons.add_home_work_rounded),
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
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () => _showOwnedDragons(context),
              icon: const Icon(Icons.pets_rounded),
              label: Text(strings.pick('My dragons', 'Mijn draken')),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: FilledButton.tonalIcon(
              key: const Key('open-draconomicon'),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                          appBar: _CodexBar(), body: DraconomiconScreen()))),
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Draconomicon'),
            ),
          ),
        ]),
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
                appBar: _DragonBar(),
                body: PetScreen(),
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
            Align(
              alignment: const Alignment(.1, .58),
              child: Transform.scale(
                scale: game.pet.sizeFactor,
                child: DragonArt(
                  height: 135,
                  stageKey: game.pet.stageKey,
                  lineageId: game.pet.lineageId,
                  evolutionPath: game.pet.activeEvolutionPath,
                  prismatic: game.pet.spectral,
                  sinister: game.pet.sinister,
                ),
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
                      Text(game.pet.displayName,
                          style: const TextStyle(
                              color: Color(0xFFF1EDFF),
                              fontWeight: FontWeight.w700)),
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
                appBar: AppBar(title: Text(strings.roomName(room))),
                body: HouseScreen(
                  active: true,
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

class _Currency extends StatelessWidget {
  const _Currency({required this.icon, required this.value});
  final IconData icon;
  final int value;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(99)),
        child: Row(children: [
          Icon(icon, size: 17, color: AppColors.twilight),
          const SizedBox(width: 4),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w900))
        ]),
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
        builder: (_, controller) => ListView(
          key: const Key('owned-dragons-scroll'),
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(strings.pick('My dragons', 'Mijn draken'),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 9),
            for (final dragon in game.ownedDragons)
              Card(
                child: ListTile(
                  leading: SizedBox.square(
                    dimension: 58,
                    child: Transform.scale(
                      scale: dragon.sizeFactor,
                      child: DragonArt(
                        height: 58,
                        animate: false,
                        stageKey: dragon.stageKey,
                        lineageId: dragon.lineageId,
                        evolutionPath: dragon.activeEvolutionPath,
                        prismatic: dragon.spectral,
                        sinister: dragon.sinister,
                      ),
                    ),
                  ),
                  title: Row(children: [
                    Expanded(
                        child: Text(dragon.displayName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900))),
                    if (dragon.favorite)
                      const Icon(Icons.favorite_rounded,
                          color: Color(0xFFE05A78), size: 18),
                  ]),
                  subtitle: Text(
                      '${dragon.lineage.name(strings.isDutch)} · ${strings.petStage(dragon)} · Lv. ${dragon.level}${game.dragonSizeLabel(dragon).isEmpty ? '' : ' · ${game.dragonSizeLabel(dragon)}'}\n${dragon.xp} XP · ${dragon.activeAdventureId == null ? strings.pick('In Tower', 'In Toren') : strings.pick('Adventuring', 'Op avontuur')}'),
                  isThreeLine: true,
                  onTap: () => _dragonActions(context, dragon),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _dragonActions(BuildContext context, Pet dragon) async {
    final strings = AppStrings.of(context);
    final game = context.read<HouseholdProvider>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: Icon(dragon.favorite
                ? Icons.heart_broken_rounded
                : Icons.favorite_rounded),
            title: Text(dragon.favorite
                ? strings.pick('Remove favorite', 'Favoriet verwijderen')
                : strings.pick('Set as favorite', 'Instellen als favoriet')),
            onTap: () async {
              Navigator.pop(sheetContext);
              await game.toggleFavorite(dragon.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.flight_takeoff_rounded),
            title: Text(strings.pick('Release dragon…', 'Draak vrijlaten…')),
            subtitle: Text(strings.pick(
                'Archived permanently; it may return for weekly visits.',
                'Blijvend gearchiveerd; kan wekelijks op bezoek komen.')),
            onTap: () async {
              Navigator.pop(sheetContext);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  scrollable: true,
                  title: Text(strings.pick('Release ${dragon.displayName}?',
                      '${dragon.displayName} vrijlaten?')),
                  content: Text(strings.pick(
                      'This dragon leaves your collection and cannot be trained. Its identity, form, alignment and hidden personality are preserved.',
                      'Deze draak verlaat je collectie en kan niet meer worden getraind. Identiteit, vorm, alignment en verborgen persoonlijkheid blijven bewaard.')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(strings.tr('cancel'))),
                    FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(strings.pick('Release', 'Vrijlaten'))),
                  ],
                ),
              );
              if (confirmed == true) await game.releaseDragon(dragon.id);
            },
          ),
        ]),
      ),
    );
  }
}

class _CodexBar extends StatelessWidget implements PreferredSizeWidget {
  const _CodexBar();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) =>
      AppBar(title: const Text('The Draconomicon'));
}

class _DragonBar extends StatelessWidget implements PreferredSizeWidget {
  const _DragonBar();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
      title:
          Text(AppStrings.of(context).pick('Dragon care', 'Drakenverzorging')));
}

class _ShopBar extends StatelessWidget implements PreferredSizeWidget {
  const _ShopBar();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) =>
      AppBar(title: Text(AppStrings.of(context).tr('shop')));
}
