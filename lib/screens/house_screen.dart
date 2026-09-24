import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/house.dart';
import '../models/day_phase.dart';
import '../models/shop_item.dart';
import '../providers/household_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/furniture_art.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/house_room_scene.dart';
import '../widgets/ui_bits.dart';

export '../widgets/house_room_scene.dart' show roomDragonDepthOrder;

class HouseScreen extends StatefulWidget {
  const HouseScreen({
    super.key,
    required this.active,
    required this.floorIndex,
    required this.onOpenShop,
  });

  final bool active;
  final int floorIndex;
  final VoidCallback onOpenShop;

  @override
  State<HouseScreen> createState() => _HouseScreenState();
}

class _HouseScreenState extends State<HouseScreen> {
  static const _wanderMoveDuration = Duration(milliseconds: 3600);
  static const _calledMoveDuration = Duration(milliseconds: 5200);

  final _random = Random();
  Timer? _wanderTimer;
  Offset _dragonPosition = const Offset(0.24, 0.76);
  Duration _dragonMoveDuration = _wanderMoveDuration;
  bool _facingRight = true;
  int _wanderStep = 0;
  bool _editMode = false;
  String? _selectedItemId;
  String? _interactionRoomId;
  String? _interactionMessage;

  @override
  void initState() {
    super.initState();
    HavenAudio.setMusicScene(HavenMusicScene.room);
    if (widget.active) _startWandering();
  }

  @override
  void didUpdateWidget(covariant HouseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;
    widget.active ? _startWandering() : _stopWandering();
  }

  @override
  void dispose() {
    _stopWandering();
    super.dispose();
  }

  void _startWandering() {
    _wanderTimer?.cancel();
    _wanderTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !widget.active || _editMode) return;
      if (_interactionMessage != null) return;
      final phase = havenDayPhaseAt(DateTime.now());
      final moveChance = switch (phase) {
        HavenDayPhase.deepNight => .12,
        HavenDayPhase.night => .20,
        HavenDayPhase.dusk => .45,
        HavenDayPhase.dawn => .60,
        HavenDayPhase.morning => .82,
        HavenDayPhase.day || HavenDayPhase.goldenHour => .95,
      };
      if (_random.nextDouble() > moveChance) return;
      final household = context.read<HouseholdProvider>();
      final controllable = household.towerControllableDragon;
      setState(() => _wanderStep++);
      if (controllable.isEgg ||
          controllable.activeAdventureId != null ||
          controllable.currentFloorIndex != widget.floorIndex) {
        return;
      }
      _moveDragonTo(
        Offset(
          0.14 + _random.nextDouble() * 0.72,
          0.60 + _random.nextDouble() * 0.23,
        ),
        duration: _wanderMoveDuration,
      );
    });
  }

  void _stopWandering() {
    _wanderTimer?.cancel();
    _wanderTimer = null;
  }

  void _moveDragonTo(
    Offset target, {
    Duration duration = _wanderMoveDuration,
  }) {
    setState(() {
      _facingRight = target.dx >= _dragonPosition.dx;
      _dragonMoveDuration = duration;
      _dragonPosition = Offset(
        target.dx.clamp(0.14, 0.86).toDouble(),
        target.dy.clamp(0.56, 0.84).toDouble(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final household = context.watch<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final largeText = usesLargeText(context);
    final room = household.activeRoom;
    final placements = household.placementsForRoom(room.id);
    final roomDragons = household.towerDragons
        .where((dragon) =>
            dragon.activeAdventureId == null &&
            dragon.currentFloorIndex == widget.floorIndex)
        .toList(growable: false);
    final controllableDragon = household.towerControllableDragon;
    if (_interactionRoomId != room.id) {
      _interactionRoomId = room.id;
      _interactionMessage = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkRareInteraction(room.id, widget.floorIndex);
      });
    }
    final ownedItems = allFurnitureCatalog
        .where((item) => household.ownedItemIds.contains(item.id))
        .toList();

    return ListView(
      key: const PageStorageKey('house-scroll'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
      children: [
        const _HouseHeader(),
        const SizedBox(height: 13),
        HouseRoomScene(
          room: room,
          dragons: [
            for (final dragon in roomDragons)
              RoomDragonVisual(
                id: dragon.id,
                stage: dragon.stage,
                stageKey: dragon.stageKey,
                lineageId: dragon.lineageId,
                evolutionPath: dragon.activeEvolutionPath,
                prismatic: dragon.prismatic,
                sinister: dragon.sinister,
                sizeFactor: dragon.sizeFactor,
                visualSeed: dragon.hatchSeed,
              ),
          ],
          visitorIds:
              household.visitingDragons.map((dragon) => dragon.id).toSet(),
          suppressTimeMood: _interactionMessage != null,
          activeDragonId: controllableDragon.id,
          placements: placements,
          editMode: _editMode,
          selectedItemId: _selectedItemId,
          dragonPosition: _dragonPosition,
          dragonMoveDuration: _dragonMoveDuration,
          facingRight: _facingRight,
          wanderStep: _wanderStep,
          onSelectItem: (itemId) => setState(() => _selectedItemId = itemId),
          onRoomTap: (position) => _handleRoomTap(room, position),
        ),
        if (_interactionMessage case final message?) ...[
          const SizedBox(height: 10),
          Card(
            color: AppColors.goldLight,
            child: ListTile(
              leading: Icon(Icons.auto_awesome_rounded,
                  color: AppColors.eventColor(context, AppColors.twilight)),
              title: Text(strings.pick(
                  'A rare Tower moment', 'Een zeldzaam torenmoment')),
              subtitle: Text(message),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _HouseActions(
          editing: _editMode,
          largeText: largeText,
          onToggleEdit: () {
            setState(() {
              _editMode = !_editMode;
              if (!_editMode) _selectedItemId = null;
            });
            _editMode ? _stopWandering() : _startWandering();
          },
          onClear: () async {
            final cleared =
                await household.clearDragonsFromRoom(widget.floorIndex);
            if (!mounted) return;
            _message(cleared
                ? strings.pick('The dragons found cozy places on other floors.',
                    'De draken hebben knusse plekken op andere verdiepingen gevonden.')
                : strings.pick('Build another floor before clearing this room.',
                    'Bouw nog een verdieping voordat je deze kamer leegmaakt.'));
          },
        ),
        if (_editMode) ...[
          const SizedBox(height: 18),
          _InventoryPanel(
            items: ownedItems,
            placements: household.housePlacements,
            activeRoomId: room.id,
            selectedItemId: _selectedItemId,
            onSelect: (itemId) => setState(() => _selectedItemId = itemId),
            onRemove: _selectedItemId == null
                ? null
                : () async {
                    await household.removeHouseItem(_selectedItemId!);
                    if (mounted) setState(() => _selectedItemId = null);
                  },
            onOpenShop: widget.onOpenShop,
          ),
        ],
      ],
    );
  }

  Future<void> _handleRoomTap(HouseRoomDefinition room, Offset position) async {
    final household = context.read<HouseholdProvider>();
    final selectedId = _selectedItemId;
    if (!_editMode || selectedId == null) {
      if (household.pet.stageKey == 'moonEgg') {
        _moveDragonTo(
          Offset(0.5 + (_random.nextDouble() - 0.5) * 0.05, 0.74),
          duration: _calledMoveDuration,
        );
      } else {
        await household.callControllableDragonToRoom(
            room.id, widget.floorIndex);
        if (!mounted) return;
        _moveDragonTo(position, duration: _calledMoveDuration);
      }
      if (widget.active) _startWandering();
      return;
    }

    final item = shopItemById(selectedId);
    if (item == null) return;
    final safeY = switch (item.slot) {
      ItemSlot.wall ||
      ItemSlot.light =>
        position.dy.clamp(room.wallMinY, room.wallMaxY).toDouble(),
      ItemSlot.bed ||
      ItemSlot.plant =>
        position.dy.clamp(room.floorMinY, room.floorMaxY).toDouble(),
    };
    await household.placeHouseItem(
      item.id,
      roomId: room.id,
      x: position.dx.clamp(0.08, 0.92).toDouble(),
      y: safeY,
    );
    if (!mounted) return;
    showAppSnackBar(
      context,
      AppStrings.of(context).pick(
        '${AppStrings.of(context).itemName(item)} placed. Tap elsewhere to move it.',
        '${AppStrings.of(context).itemName(item)} geplaatst. Tik ergens anders om het te verplaatsen.',
      ),
    );
  }

  Future<void> _checkRareInteraction(String roomId, int floorIndex) async {
    final message = await context
        .read<HouseholdProvider>()
        .maybeTriggerRoomInteraction(roomId, floorIndex);
    if (!mounted || _interactionRoomId != roomId || message == null) return;
    setState(() => _interactionMessage = message);
  }

  void _message(String message) => showAppSnackBar(context, message);
}

class _HouseHeader extends StatelessWidget {
  const _HouseHeader();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.pick('Dragon sanctuary', 'Drakenreservaat'),
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 5),
        Text(
          strings.pick('Build a home that grows with your dragon.',
              'Bouw een thuis dat met jullie draak meegroeit.'),
          style: const TextStyle(color: AppColors.muted, fontSize: 15),
        ),
      ],
    );
  }
}

class _HouseActions extends StatelessWidget {
  const _HouseActions({
    required this.editing,
    required this.largeText,
    required this.onToggleEdit,
    required this.onClear,
  });

  final bool editing;
  final bool largeText;
  final VoidCallback onToggleEdit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final editButton = RoomActionButton(
      key: const Key('tower-decorate-button'),
      onPressed: onToggleEdit,
      kind: GameIconKind.roomDecorate,
      filled: true,
      label: editing
          ? strings.pick('Finish decorating', 'Inrichten afronden')
          : strings.pick('Decorate', 'Inrichten'),
    );
    final clearButton = RoomActionButton(
      onPressed: onClear,
      kind: GameIconKind.roomClear,
      label: strings.pick('Clear dragons', 'Draken verplaatsen'),
    );
    if (largeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          editButton,
          const SizedBox(height: 9),
          clearButton,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: editButton),
        const SizedBox(width: 9),
        Expanded(child: clearButton),
      ],
    );
  }
}

class _InventoryPanel extends StatelessWidget {
  const _InventoryPanel({
    required this.items,
    required this.placements,
    required this.activeRoomId,
    required this.selectedItemId,
    required this.onSelect,
    required this.onRemove,
    required this.onOpenShop,
  });

  final List<ShopItem> items;
  final List<HousePlacement> placements;
  final String activeRoomId;
  final String? selectedItemId;
  final ValueChanged<String> onSelect;
  final VoidCallback? onRemove;
  final VoidCallback onOpenShop;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final largeText = usesLargeText(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: AppColors.eventColor(context, AppColors.mist)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_rounded,
                  color: AppColors.eventColor(context, AppColors.twilight)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(strings.pick('House inventory', 'Huisinventaris'),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (!largeText)
                TextButton(
                  onPressed: onOpenShop,
                  child: Text(strings.pick('Shop', 'Winkel')),
                ),
            ],
          ),
          if (largeText)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onOpenShop,
                icon: const Icon(Icons.storefront_rounded),
                label: Text(strings.pick('Shop', 'Winkel')),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            selectedItemId == null
                ? strings.pick(
                    'Select an item, then tap its new place in the room.',
                    'Kies een item en tik daarna op zijn nieuwe plek in de kamer.')
                : strings.pick(
                    'Selected: ${strings.itemNameById(selectedItemId)}. Tap the room to place it.',
                    'Geselecteerd: ${strings.itemNameById(selectedItemId)}. Tik in de kamer om het te plaatsen.'),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.storefront_rounded,
                      color: AppColors.eventColor(
                          context, AppColors.twilightDark)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(strings.pick(
                      'The inventory is empty. Explore the Spire or visit the furniture market.',
                      'De inventaris is leeg. Verken de Spire of bezoek de meubelmarkt.',
                    )),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: largeText ? 110 : 88,
              child: ListView.separated(
                key: const PageStorageKey('room-inventory-scroll'),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final placement = placements
                      .where((candidate) => candidate.itemId == item.id)
                      .firstOrNull;
                  final selected = selectedItemId == item.id;
                  return InkWell(
                    key: Key('tower-furniture-${item.id}'),
                    onTap: () => onSelect(item.id),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: largeText ? 110 : 92,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.goldLight : AppColors.cream,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? AppColors.gold
                              : AppColors.eventColor(context, AppColors.mist),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 34,
                            height: 30,
                            child: FurnitureArt(item: item),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            strings.itemName(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 10),
                          ),
                          const Spacer(),
                          Text(
                            placement == null
                                ? strings.pick('INVENTORY', 'INVENTARIS')
                                : placement.roomId == activeRoomId
                                    ? strings.pick('HERE', 'HIER')
                                    : strings.pick(
                                        'OTHER ROOM', 'ANDERE KAMER'),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (selectedItemId != null &&
              placements.any((item) => item.itemId == selectedItemId)) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.inventory_2_outlined, size: 18),
                label: Text(strings.pick(
                    'Return to inventory', 'Terug naar inventaris')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
