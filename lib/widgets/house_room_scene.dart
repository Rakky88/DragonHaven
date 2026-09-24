import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/day_phase.dart';
import '../models/house.dart';
import '../models/pet.dart';
import '../models/shop_item.dart';
import '../theme/app_theme.dart';
import 'dragon_art.dart';
import 'furniture_art.dart';
import 'game_icon_sprite.dart';
import 'haven_lighting.dart';

const houseRoomWanderMoveDuration = Duration(milliseconds: 3600);

@immutable
class RoomDragonVisual {
  const RoomDragonVisual({
    required this.id,
    required this.stage,
    required this.stageKey,
    required this.lineageId,
    required this.evolutionPath,
    required this.prismatic,
    required this.sinister,
    required this.sizeFactor,
    required this.visualSeed,
  });

  final String id;
  final DragonStage stage;
  final String stageKey;
  final String lineageId;
  final String evolutionPath;
  final bool prismatic;
  final bool sinister;
  final double sizeFactor;

  /// Stable cosmetic input for room routes and idle poses.
  ///
  /// It never participates in gameplay and need not be the dragon's private
  /// hatch seed. Legacy callers pass that existing value; canonical callers
  /// can derive a stable value from public identity.
  final int visualSeed;
}

class RoomActionButton extends StatelessWidget {
  const RoomActionButton({
    super.key,
    required this.onPressed,
    required this.kind,
    required this.label,
    this.filled = false,
  });

  final VoidCallback? onPressed;
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
              border: Border.all(
                  color:
                      AppColors.eventColor(context, const Color(0xFFDCD2EC))),
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

class HouseRoomScene extends StatelessWidget {
  const HouseRoomScene({
    super.key,
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
  final List<RoomDragonVisual> dragons;
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
            final dragonPositions = <Offset>[
              for (var index = 0; index < dragons.length; index++)
                dragons[index].id == activeDragonId
                    ? dragonPosition
                    : _idlePosition(
                        dragons[index], index, wanderStep, dragons.length),
            ];
            final dragonPaintOrder = roomDragonDepthOrder(
              dragonPositions,
              stableIds: [for (final dragon in dragons) dragon.id],
            );
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
                    // A Stack paints later children in front. Sorting by each
                    // dragon's ground anchor keeps walkers at the top of the
                    // room behind dragons standing lower in the scene.
                    for (final index in dragonPaintOrder)
                      _RoomDragon(
                        dragon: dragons[index],
                        sceneSize: size,
                        position: dragonPositions[index],
                        roomDragonCount: dragons.length,
                        moveDuration: dragons[index].id == activeDragonId
                            ? dragonMoveDuration
                            : houseRoomWanderMoveDuration,
                        facingRight: dragons[index].id == activeDragonId
                            ? facingRight
                            : (dragons[index].visualSeed + wanderStep).isEven,
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
                                color: AppColors.eventColor(
                                    context, AppColors.twilight)),
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

/// Returns back-to-front paint indices for room actors.
///
/// [Offset.dy] is the virtual ground contact point, so a smaller value is
/// farther into the room. Horizontal position and id only stabilize ties and
/// prevent overlapping dragons from flickering between frames.
List<int> roomDragonDepthOrder(
  List<Offset> positions, {
  List<String>? stableIds,
}) {
  assert(stableIds == null || stableIds.length == positions.length);
  final indices = List<int>.generate(positions.length, (index) => index);
  indices.sort((left, right) {
    final depth = positions[left].dy.compareTo(positions[right].dy);
    if (depth != 0) return depth;
    final horizontal = positions[left].dx.compareTo(positions[right].dx);
    if (horizontal != 0) return horizontal;
    if (stableIds != null) return stableIds[left].compareTo(stableIds[right]);
    return left.compareTo(right);
  });
  return indices;
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

Offset _idlePosition(
    RoomDragonVisual dragon, int index, int step, int dragonCount) {
  const waypoints = <Offset>[
    Offset(.15, .76),
    Offset(.82, .68),
    Offset(.31, .62),
    Offset(.72, .81),
    Offset(.48, .70),
    Offset(.12, .64),
    Offset(.88, .79),
    Offset(.37, .82),
    Offset(.65, .62),
    Offset(.22, .69),
    Offset(.78, .74),
    Offset(.53, .83),
  ];
  final routeOffset = dragon.visualSeed.abs().remainder(waypoints.length);
  final separation = max(1, waypoints.length ~/ max(1, dragonCount));
  return waypoints[
      (routeOffset + step + index * separation) % waypoints.length];
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

  final RoomDragonVisual dragon;
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
      key: Key('room-dragon-${dragon.id}'),
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
              dragon.visualSeed,
              suppressed: suppressTimeMood,
            );
            return _DragonTimePose(
              key: ValueKey('time-pose-${dragon.id}'),
              mood: mood,
              stage: dragon.stage,
              visualSeed: dragon.visualSeed,
              animate: animate,
              child: Transform.flip(
                flipX: !facingRight,
                child: DragonArt(
                  height: dragonSize,
                  stageKey: dragon.stageKey,
                  lineageId: dragon.lineageId,
                  evolutionPath: dragon.evolutionPath,
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
    final item = shopItemById(placement.itemId);
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
      key: Key('placed-furniture-${item.id}'),
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
