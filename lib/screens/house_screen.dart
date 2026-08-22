import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/house.dart';
import '../models/day_phase.dart';
import '../models/pet.dart';
import '../models/shop_item.dart';
import '../providers/household_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/furniture_art.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/haven_lighting.dart';
import '../widgets/dragon_art.dart';
import '../widgets/ui_bits.dart';

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
  Offset _dragonPosition = const Offset(0.52, 0.72);
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
          0.20 + _random.nextDouble() * 0.60,
          0.62 + _random.nextDouble() * 0.18,
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
    final ownedItems = shopCatalog
        .where((item) => household.ownedItemIds.contains(item.id))
        .toList();

    return ListView(
      key: const PageStorageKey('house-scroll'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
      children: [
        _HouseHeader(
          coins: household.pet.coins,
          largeText: largeText,
        ),
        const SizedBox(height: 13),
        _HouseRoomScene(
          room: room,
          dragons: roomDragons,
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
              leading: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.twilight),
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
        ] else ...[
          const SizedBox(height: 18),
          _HouseSummary(
            room: room,
            placedCount: placements.length,
            unlockedCount: household.unlockedRoomIds.length,
            totalRooms: houseRoomCatalog.length,
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
  const _HouseHeader({required this.coins, required this.largeText});

  final int coins;
  final bool largeText;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final heading = Column(
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
    final coinPill = MetricPill(
      leading: const GameIconSprite(GameIconKind.coin, size: 26),
      value: '$coins',
      label: strings.pick('coins', 'munten'),
      color: const Color(0xFF9A6A00),
    );
    if (largeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading,
          const SizedBox(height: 10),
          coinPill,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: heading),
        const SizedBox(width: 10),
        coinPill,
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
    final editButton = _RoomActionButton(
      onPressed: onToggleEdit,
      kind: GameIconKind.roomDecorate,
      filled: true,
      label: editing
          ? strings.pick('Finish decorating', 'Inrichten afronden')
          : strings.pick('Decorate', 'Inrichten'),
    );
    final clearButton = _RoomActionButton(
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

class _RoomActionButton extends StatelessWidget {
  const _RoomActionButton({
    required this.onPressed,
    required this.kind,
    required this.label,
    this.filled = false,
  });

  final VoidCallback onPressed;
  final GameIconKind kind;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(19),
          child: Ink(
            height: 62,
            padding: const EdgeInsets.fromLTRB(7, 5, 10, 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: filled
                    ? const [Color(0xFFE8DEFF), Color(0xFFD8C9F4)]
                    : const [Colors.white, Color(0xFFFFF8E8)],
              ),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: const Color(0xFFDCD2EC)),
            ),
            child: Row(children: [
              GameIconSprite(kind, size: 48),
              const SizedBox(width: 5),
              Expanded(
                child: Text(label,
                    maxLines: 2,
                    style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
              ),
            ]),
          ),
        ),
      );
}

class _HouseRoomScene extends StatelessWidget {
  const _HouseRoomScene({
    required this.room,
    required this.dragons,
    required this.visitorIds,
    required this.suppressTimeMood,
    required this.activeDragonId,
    required this.placements,
    required this.editMode,
    required this.selectedItemId,
    required this.dragonPosition,
    required this.dragonMoveDuration,
    required this.facingRight,
    required this.wanderStep,
    required this.onSelectItem,
    required this.onRoomTap,
  });

  final HouseRoomDefinition room;
  final List<Pet> dragons;
  final Set<String> visitorIds;
  final bool suppressTimeMood;
  final String activeDragonId;
  final List<HousePlacement> placements;
  final bool editMode;
  final String? selectedItemId;
  final Offset dragonPosition;
  final Duration dragonMoveDuration;
  final bool facingRight;
  final int wanderStep;
  final ValueChanged<String> onSelectItem;
  final ValueChanged<Offset> onRoomTap;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1.25,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              key: const Key('house-room-scene'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => onRoomTap(Offset(
                details.localPosition.dx / size.width,
                details.localPosition.dy / size.height,
              )),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: HavenPhaseImage(
                        assetFor: room.backgroundForPhase,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const Positioned.fill(
                      child: IgnorePointer(child: _RoomPhaseAtmosphere()),
                    ),
                    if (room.tintValue != 0)
                      Positioned.fill(
                        child: ColoredBox(color: Color(room.tintValue)),
                      ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.ink.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                      ),
                    ),
                    for (final placement in placements)
                      _PositionedFurniture(
                        placement: placement,
                        sceneSize: size,
                        selected: selectedItemId == placement.itemId,
                        editable: editMode,
                        onTap: () => onSelectItem(placement.itemId),
                      ),
                    for (var index = 0; index < dragons.length; index++)
                      _RoomDragon(
                        dragon: dragons[index],
                        sceneSize: size,
                        position: dragons[index].id == activeDragonId
                            ? dragonPosition
                            : _idlePosition(dragons[index], index, wanderStep,
                                dragons.length),
                        roomDragonCount: dragons.length,
                        moveDuration: dragons[index].id == activeDragonId
                            ? dragonMoveDuration
                            : _HouseScreenState._wanderMoveDuration,
                        facingRight: dragons[index].id == activeDragonId
                            ? facingRight
                            : (dragons[index].hatchSeed + wanderStep).isEven,
                        animate: !editMode &&
                            !MediaQuery.disableAnimationsOf(context),
                        suppressTimeMood: suppressTimeMood ||
                            visitorIds.contains(dragons[index].id),
                      ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                editMode
                                    ? Icons.edit_rounded
                                    : Icons.pets_rounded,
                                size: 15,
                                color: AppColors.twilight),
                            const SizedBox(width: 5),
                            Text(
                              editMode
                                  ? AppStrings.of(context)
                                      .pick('EDIT MODE', 'INRICHTMODUS')
                                  : AppStrings.of(context).pick(
                                      dragons.any((dragon) =>
                                              dragon.id == activeDragonId)
                                          ? 'TAP TO GUIDE YOUR FAVORITE'
                                          : 'TAP TO CALL YOUR FAVORITE',
                                      dragons.any((dragon) =>
                                              dragon.id == activeDragonId)
                                          ? 'TIK OM JE FAVORIET TE STUREN'
                                          : 'TIK OM JE FAVORIET TE ROEPEN'),
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}

class _RoomPhaseAtmosphere extends StatelessWidget {
  const _RoomPhaseAtmosphere();

  @override
  Widget build(BuildContext context) => HavenClockBuilder(
        builder: (context, now, _) {
          final lighting = havenLightingAt(now);
          return Stack(
            fit: StackFit.expand,
            children: [
              _RoomAtmosphereLayer(phase: lighting.from),
              if (lighting.from != lighting.to)
                Opacity(
                  opacity: lighting.progress,
                  child: _RoomAtmosphereLayer(phase: lighting.to),
                ),
            ],
          );
        },
      );
}

class _RoomAtmosphereLayer extends StatelessWidget {
  const _RoomAtmosphereLayer({required this.phase});

  final HavenDayPhase phase;

  @override
  Widget build(BuildContext context) {
    final gradient = switch (phase) {
      HavenDayPhase.deepNight => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x55211D54), Color(0x1A11122D), Color(0x33211B42)],
          stops: [0, .55, 1],
        ),
      HavenDayPhase.dawn => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x55426A9E), Color(0x18B8D9E8), Color(0x33FFBD8A)],
        ),
      HavenDayPhase.morning => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x2BCEF2FF), Color(0x08FFFFFF), Colors.transparent],
        ),
      HavenDayPhase.day => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x12FFFFFF), Colors.transparent],
        ),
      HavenDayPhase.goldenHour => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x4CFFD36A), Color(0x18FF995F), Colors.transparent],
          stops: [0, .52, 1],
        ),
      HavenDayPhase.dusk => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x55452E79), Color(0x263E3B78), Color(0x26FF9B69)],
        ),
      HavenDayPhase.night => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x66302B70), Color(0x24201F4D), Color(0x3D15182F)],
        ),
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
        CustomPaint(painter: _RoomAtmospherePainter(phase)),
      ],
    );
  }
}

class _RoomAtmospherePainter extends CustomPainter {
  const _RoomAtmospherePainter(this.phase);

  final HavenDayPhase phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (phase == HavenDayPhase.goldenHour || phase == HavenDayPhase.dawn) {
      final beam = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: phase == HavenDayPhase.dawn
              ? const [Color(0x44D9F2FF), Color(0x00D9F2FF)]
              : const [Color(0x55FFE49B), Color(0x00FFE49B)],
        ).createShader(Offset.zero & size);
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * .48, 0)
        ..lineTo(size.width * .72, size.height)
        ..lineTo(size.width * .28, size.height)
        ..close();
      canvas.drawPath(path, beam);
    }
    if (phase == HavenDayPhase.dusk ||
        phase == HavenDayPhase.night ||
        phase == HavenDayPhase.deepNight) {
      final strength = phase == HavenDayPhase.dusk ? .35 : .72;
      final starPaint = Paint()
        ..color = Colors.white.withValues(alpha: strength);
      const points = [
        Offset(.08, .12),
        Offset(.20, .08),
        Offset(.44, .15),
        Offset(.69, .09),
        Offset(.88, .18),
        Offset(.78, .30),
      ];
      for (var index = 0; index < points.length; index++) {
        canvas.drawCircle(
          Offset(points[index].dx * size.width, points[index].dy * size.height),
          index.isEven ? 1.2 : .8,
          starPaint,
        );
      }
    }
    if (phase == HavenDayPhase.dusk || phase == HavenDayPhase.night) {
      for (final point in const [Offset(.18, .42), Offset(.82, .37)]) {
        final center = Offset(point.dx * size.width, point.dy * size.height);
        final glow = Paint()
          ..shader = RadialGradient(
            colors: const [Color(0x55FFD078), Color(0x00FFD078)],
          ).createShader(Rect.fromCircle(center: center, radius: 34));
        canvas.drawCircle(center, 34, glow);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoomAtmospherePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

Offset _idlePosition(Pet dragon, int index, int step, int dragonCount) {
  final columns = min(4, max(1, dragonCount));
  final movingIndex = index + step;
  final column = movingIndex % columns;
  final row = (movingIndex ~/ columns) % 3;
  final seed = dragon.hatchSeed.abs() + step * 173;
  return Offset(
    columns == 1 ? .5 : .20 + column / (columns - 1) * .60,
    .65 + row * .075 + (seed.remainder(5) - 2) * .004,
  );
}

class _RoomDragon extends StatelessWidget {
  const _RoomDragon({
    required this.dragon,
    required this.sceneSize,
    required this.position,
    required this.roomDragonCount,
    required this.moveDuration,
    required this.facingRight,
    required this.animate,
    required this.suppressTimeMood,
  });

  final Pet dragon;
  final Size sceneSize;
  final Offset position;
  final int roomDragonCount;
  final Duration moveDuration;
  final bool facingRight;
  final bool animate;
  final bool suppressTimeMood;

  @override
  Widget build(BuildContext context) {
    final stageScale = switch (dragon.stageKey) {
      'spark' => .23,
      'nestDragon' => .27,
      _ => .30,
    };
    final crowdScale = roomDragonCount <= 3
        ? 1.0
        : (3.2 / roomDragonCount).clamp(.58, .9).toDouble();
    final dragonSize = sceneSize.width *
        stageScale *
        dragon.sizeFactor.clamp(.65, 1.30).toDouble() *
        crowdScale;
    return AnimatedPositioned(
      duration: moveDuration,
      curve: Curves.easeInOutSine,
      left: position.dx * sceneSize.width - dragonSize / 2,
      top: position.dy * sceneSize.height - dragonSize * .72,
      width: dragonSize,
      height: dragonSize,
      child: IgnorePointer(
        child: HavenClockBuilder(
          builder: (context, now, _) {
            final mood = dragonTimeMoodAt(
              now,
              dragon.hatchSeed,
              suppressed: suppressTimeMood,
            );
            return _DragonTimePose(
              key: ValueKey('time-pose-${dragon.id}'),
              mood: mood,
              stage: dragon.stage,
              visualSeed: dragon.hatchSeed,
              animate: animate,
              child: Transform.flip(
                flipX: !facingRight,
                child: DragonArt(
                  height: dragonSize,
                  stageKey: dragon.stageKey,
                  lineageId: dragon.lineageId,
                  evolutionPath: dragon.activeEvolutionPath,
                  prismatic: dragon.prismatic,
                  sinister: dragon.sinister,
                  animate: animate && mood != DragonTimeMood.asleep,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DragonTimePose extends StatefulWidget {
  const _DragonTimePose({
    super.key,
    required this.mood,
    required this.stage,
    required this.visualSeed,
    required this.animate,
    required this.child,
  });

  final DragonTimeMood mood;
  final DragonStage stage;
  final int visualSeed;
  final bool animate;
  final Widget child;

  @override
  State<_DragonTimePose> createState() => _DragonTimePoseState();
}

class _DragonTimePoseState extends State<_DragonTimePose>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 2500 + widget.visualSeed.abs().remainder(1700),
      ),
      value: widget.visualSeed.abs().remainder(100) / 100,
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _DragonTimePose oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate == widget.animate) return;
    widget.animate ? _controller.repeat(reverse: true) : _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = Curves.easeInOut.transform(_controller.value);
          final sleeping = widget.mood == DragonTimeMood.asleep;
          final resting = widget.mood == DragonTimeMood.restful;
          final waking = widget.mood == DragonTimeMood.waking;
          final angle = sleeping
              ? switch (widget.stage) {
                  DragonStage.hatchling => .08,
                  DragonStage.wyrmling => .11,
                  DragonStage.ascended => .055,
                  DragonStage.egg => 0.0,
                }
              : 0.0;
          final scaleX = sleeping
              ? 1 + pulse * .025
              : resting
                  ? .985 + pulse * .015
                  : 1.0;
          final scaleY = sleeping
              ? .86 + pulse * .025
              : resting
                  ? .96 + pulse * .018
                  : waking
                      ? 1 + pulse * .035
                      : 1.0;
          return Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              Transform.rotate(
                angle: angle,
                alignment: Alignment.bottomCenter,
                child: Transform.scale(
                  alignment: Alignment.bottomCenter,
                  scaleX: scaleX,
                  scaleY: scaleY,
                  child: child,
                ),
              ),
              if (sleeping)
                Positioned(
                  right: 2,
                  top: 0,
                  child: Opacity(
                    opacity: .42 + pulse * .35,
                    child: const Text(
                      'Z  z',
                      style: TextStyle(
                        color: Color(0xFFE8E0FF),
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: Color(0xFF29213D), blurRadius: 5)
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        child: widget.child,
      );
}

class _PositionedFurniture extends StatelessWidget {
  const _PositionedFurniture({
    required this.placement,
    required this.sceneSize,
    required this.selected,
    required this.editable,
    required this.onTap,
  });

  final HousePlacement placement;
  final Size sceneSize;
  final bool selected;
  final bool editable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final item = shopCatalog
        .where((candidate) => candidate.id == placement.itemId)
        .firstOrNull;
    if (item == null) return const SizedBox.shrink();
    final baseSize = switch (item.slot) {
      ItemSlot.bed => const Size(92, 58),
      ItemSlot.plant => const Size(54, 78),
      ItemSlot.wall => const Size(52, 58),
      ItemSlot.light => const Size(48, 56),
    };
    final width = baseSize.width * placement.scale;
    final height = baseSize.height * placement.scale;
    return Positioned(
      left: placement.x * sceneSize.width - width / 2,
      top: placement.y * sceneSize.height - height / 2,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: editable ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.all(selected ? 4 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border:
                selected ? Border.all(color: AppColors.gold, width: 3) : null,
            color: selected
                ? Colors.white.withValues(alpha: 0.30)
                : Colors.transparent,
          ),
          child: _TimeAwareFurniture(item: item),
        ),
      ),
    );
  }
}

class _TimeAwareFurniture extends StatefulWidget {
  const _TimeAwareFurniture({required this.item});

  final ShopItem item;

  @override
  State<_TimeAwareFurniture> createState() => _TimeAwareFurnitureState();
}

class _TimeAwareFurnitureState extends State<_TimeAwareFurniture>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 1800 + widget.item.visualSeed.abs().remainder(1100),
      ),
      value: widget.item.visualSeed.abs().remainder(100) / 100,
    );
    if (widget.item.hasAmbientAnimation) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HavenClockBuilder(
        builder: (context, _, phase) => AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final pulse = Curves.easeInOut.transform(_controller.value);
            final glowActive = widget.item.emitsLight &&
                switch (widget.item.nightActivation) {
                  FurnitureNightActivation.always => true,
                  FurnitureNightActivation.duskAndNight => phase.isDark,
                  FurnitureNightActivation.manualVisualOnly ||
                  FurnitureNightActivation.none =>
                    false,
                };
            final glow = glowActive ? .62 + pulse * .25 : 0.0;
            final ambientScale =
                widget.item.hasAmbientAnimation ? .99 + pulse * .018 : 1.0;
            return DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: glowActive
                    ? [
                        BoxShadow(
                          color: _furnitureGlowColor(widget.item.lightType)
                              .withValues(alpha: glow),
                          blurRadius: 8 + widget.item.glowRadius * 46,
                          spreadRadius: widget.item.glowRadius * 10,
                        ),
                      ]
                    : null,
              ),
              child: Transform.scale(scale: ambientScale, child: child),
            );
          },
          child: FurnitureArt(item: widget.item),
        ),
      );
}

Color _furnitureGlowColor(FurnitureLightType type) => switch (type) {
      FurnitureLightType.warm => const Color(0xFFFFC56B),
      FurnitureLightType.cool => const Color(0xFF9DDCFF),
      FurnitureLightType.fire => const Color(0xFFFF8C42),
      FurnitureLightType.arcane => const Color(0xFFC49AFF),
      FurnitureLightType.none => Colors.transparent,
    };

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
        border: Border.all(color: AppColors.mist),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: AppColors.twilight),
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
                  const Icon(Icons.storefront_rounded,
                      color: AppColors.twilightDark),
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
                          color: selected ? AppColors.gold : AppColors.mist,
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

class _HouseSummary extends StatelessWidget {
  const _HouseSummary({
    required this.room,
    required this.placedCount,
    required this.unlockedCount,
    required this.totalRooms,
  });

  final HouseRoomDefinition room;
  final int placedCount;
  final int unlockedCount;
  final int totalRooms;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintLight,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: Icon(_roomIcon(room.id), color: AppColors.twilight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.roomName(room),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  strings.pick(
                    '$placedCount items · $unlockedCount of $totalRooms rooms built',
                    '$placedCount items · $unlockedCount van $totalRooms kamers gebouwd',
                  ),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _roomIcon(String roomId) => switch (roomId) {
      'nest' => Icons.night_shelter_rounded,
      'hearth' => Icons.fireplace_rounded,
      'crystal' => Icons.diamond_rounded,
      'garden' => Icons.local_florist_rounded,
      'tidal_library' => Icons.menu_book_rounded,
      'loft' => Icons.auto_awesome_rounded,
      'cloud' => Icons.cloud_rounded,
      'sunforge' => Icons.wb_sunny_rounded,
      _ => Icons.home_rounded,
    };
