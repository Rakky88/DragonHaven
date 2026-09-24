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

/// Display footprint used by every Tower room view.
///
/// Beds are wider than the other furniture categories and get enough vertical
/// room for high-backed daybeds. Keeping this in one helper lets the room and
/// editor use the same proportional, edge-safe layout for the full catalog.
Size furnitureRoomDisplaySize(ShopItem item) => switch (item.slot) {
      ItemSlot.bed => const Size(96, 72),
      ItemSlot.plant => const Size(54, 78),
      ItemSlot.wall => const Size(52, 58),
      ItemSlot.light => const Size(48, 56),
    };

Rect furnitureRoomPlacementRect({
  required ShopItem item,
  required HousePlacement placement,
  required Size sceneSize,
}) {
  final base = furnitureRoomDisplaySize(item);
  final width = min(sceneSize.width, base.width * placement.scale);
  final height = min(sceneSize.height, base.height * placement.scale);
  final maxLeft = max(0.0, sceneSize.width - width);
  final maxTop = max(0.0, sceneSize.height - height);
  final left = (placement.x * sceneSize.width - width / 2).clamp(0.0, maxLeft);
  final top = (placement.y * sceneSize.height - height / 2).clamp(0.0, maxTop);
  return Rect.fromLTWH(left.toDouble(), top.toDouble(), width, height);
}

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
            final reducedMotion = MediaQuery.disableAnimationsOf(context);
            return _RoomInteractionSurface(
              sceneSize: size,
              animationsEnabled: !editMode && !reducedMotion,
              onRoomTap: onRoomTap,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      key: const Key('room-background-transition'),
                      duration: reducedMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 780),
                      reverseDuration: reducedMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 520),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        fit: StackFit.expand,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      ),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 1.035, end: 1).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      child: SizedBox.expand(
                        key: ValueKey('room-background-${room.id}'),
                        child: HavenPhaseImage(
                          assetFor: room.backgroundForPhase,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: AnimatedSwitcher(
                          key: const Key('room-atmosphere-transition'),
                          duration: reducedMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 620),
                          reverseDuration: reducedMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 440),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          layoutBuilder: (currentChild, previousChildren) =>
                              Stack(
                            fit: StackFit.expand,
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          ),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: _RoomPhaseAtmosphere(
                            key: ValueKey('room-atmosphere-${room.id}'),
                            roomId: room.id,
                            animationsEnabled: !editMode &&
                                !reducedMotion &&
                                dragons.isNotEmpty,
                          ),
                        ),
                      ),
                    ),
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
                      key: ValueKey('room-dragon-motion-${dragons[index].id}'),
                      dragon: dragons[index],
                      sceneSize: size,
                      position: dragonPositions[index],
                      roomDragonCount: dragons.length,
                      moveDuration: dragons[index].id == activeDragonId
                          ? dragonMoveDuration
                          : houseRoomWanderMoveDuration,
                      facingRight: dragons[index].id == activeDragonId
                          ? facingRight
                          : _idleFacingRight(
                              dragons[index],
                              index,
                              wanderStep,
                              dragons.length,
                            ),
                      animate: !editMode && !reducedMotion,
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

class _RoomInteractionSurface extends StatefulWidget {
  const _RoomInteractionSurface({
    required this.sceneSize,
    required this.animationsEnabled,
    required this.onRoomTap,
    required this.child,
  });

  final Size sceneSize;
  final bool animationsEnabled;
  final ValueChanged<Offset> onRoomTap;
  final Widget child;

  @override
  State<_RoomInteractionSurface> createState() =>
      _RoomInteractionSurfaceState();
}

class _RoomInteractionSurfaceState extends State<_RoomInteractionSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapEffect;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _tapEffect = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
      value: 1,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _tapPosition = null);
        }
      });
  }

  @override
  void didUpdateWidget(covariant _RoomInteractionSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animationsEnabled && oldWidget.animationsEnabled) {
      _tapEffect
        ..stop()
        ..value = 1;
      _tapPosition = null;
    }
  }

  @override
  void dispose() {
    _tapEffect.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details) {
    final position = Offset(
      (details.localPosition.dx / widget.sceneSize.width)
          .clamp(0, 1)
          .toDouble(),
      (details.localPosition.dy / widget.sceneSize.height)
          .clamp(0, 1)
          .toDouble(),
    );
    if (widget.animationsEnabled) {
      setState(() => _tapPosition = position);
      _tapEffect.forward(from: 0);
    }
    widget.onRoomTap(position);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        key: const Key('house-room-scene'),
        behavior: HitTestBehavior.opaque,
        onTapUp: _handleTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              if (_tapPosition case final position?)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _tapEffect,
                          builder: (context, _) => CustomPaint(
                            key: const Key('room-tap-effect'),
                            painter: _RoomTapEffectPainter(
                              position: position,
                              progress: _tapEffect.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _RoomTapEffectPainter extends CustomPainter {
  const _RoomTapEffectPainter({
    required this.position,
    required this.progress,
  });

  final Offset position;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(position.dx * size.width, position.dy * size.height);
    final eased = Curves.easeOutCubic.transform(progress);
    final fade = (1 - progress).clamp(0.0, 1.0);
    final outer = Paint()
      ..color = const Color(0xFFFFDB72).withValues(alpha: fade * .82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 - progress * 1.2;
    final inner = Paint()
      ..color = const Color(0xFFC9ADFF).withValues(alpha: fade * .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas
      ..drawCircle(center, 7 + eased * 31, outer)
      ..drawCircle(center, 3 + eased * 18, inner);
    final sparkle = Paint()..color = Colors.white.withValues(alpha: fade * .9);
    for (var index = 0; index < 6; index++) {
      final angle = index * pi / 3 + progress * .7;
      final distance = 8 + eased * (18 + (index.isEven ? 6 : 0));
      final point = center + Offset(cos(angle), sin(angle)) * distance;
      canvas.drawCircle(point, 1.8 - progress * .9, sparkle);
    }
  }

  @override
  bool shouldRepaint(covariant _RoomTapEffectPainter oldDelegate) =>
      oldDelegate.position != position || oldDelegate.progress != progress;
}

class _RoomPhaseAtmosphere extends StatefulWidget {
  const _RoomPhaseAtmosphere({
    super.key,
    required this.roomId,
    required this.animationsEnabled,
  });

  final String roomId;
  final bool animationsEnabled;

  @override
  State<_RoomPhaseAtmosphere> createState() => _RoomPhaseAtmosphereState();
}

class _RoomPhaseAtmosphereState extends State<_RoomPhaseAtmosphere>
    with SingleTickerProviderStateMixin {
  late final int _roomSeed = widget.roomId.codeUnits.fold<int>(
      0x45d9f3b, (value, unit) => ((value ^ unit) * 0x119de1f3) & 0x7fffffff);
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 14000 + _roomSeed.remainder(5000)),
    value: _roomSeed.remainder(1000) / 1000,
  );
  bool? _motionEnabled;
  bool _deviceAllowsMotion = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _deviceAllowsMotion = !MediaQuery.disableAnimationsOf(context);
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant _RoomPhaseAtmosphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationsEnabled != widget.animationsEnabled) _syncMotion();
  }

  void _syncMotion() {
    final enabled = widget.animationsEnabled && _deviceAllowsMotion;
    if (_motionEnabled == enabled) return;
    _motionEnabled = enabled;
    if (enabled) {
      _drift.repeat();
    } else {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

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
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _drift,
                  builder: (context, _) => CustomPaint(
                    key: const Key('room-ambient-motion'),
                    painter: _RoomAmbientMotionPainter(
                      phase:
                          lighting.progress < .5 ? lighting.from : lighting.to,
                      progress: _drift.value,
                      seed: _roomSeed,
                      roomId: widget.roomId,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class _RoomAmbientMotionPainter extends CustomPainter {
  const _RoomAmbientMotionPainter({
    required this.phase,
    required this.progress,
    required this.seed,
    required this.roomId,
  });

  final HavenDayPhase phase;
  final double progress;
  final int seed;
  final String roomId;

  double _unit(int salt) {
    final value = ((seed ^ (salt * 0x45d9f3b)) * 0x119de1f3) & 0x7fffffff;
    return value / 0x7fffffff;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final dark = phase == HavenDayPhase.dusk ||
        phase == HavenDayPhase.night ||
        phase == HavenDayPhase.deepNight;
    final warm =
        phase == HavenDayPhase.dawn || phase == HavenDayPhase.goldenHour;
    final roomColor = switch (roomId) {
      'hearth' || 'sunforge' => const Color(0xFFFFB35F),
      'crystal' => const Color(0xFFDDB6FF),
      'garden' => const Color(0xFFC9F58B),
      'tidal_library' => const Color(0xFF9DEBFF),
      'loft' || 'cloud' => const Color(0xFFEAF9FF),
      _ => const Color(0xFFFFE49B),
    };
    final color = dark
        ? Color.lerp(roomColor, const Color(0xFFD8C7FF), .48)!
        : warm
            ? Color.lerp(roomColor, const Color(0xFFFFE49B), .38)!
            : roomColor;
    final count = dark ? 10 : 7;
    for (var index = 0; index < count; index++) {
      final baseX = _unit(index * 5 + 1);
      final baseY = .10 + _unit(index * 5 + 2) * .66;
      final speed = .035 + _unit(index * 5 + 3) * .085;
      final cycle = (progress + _unit(index * 5 + 4)) % 1;
      final horizontalDirection = switch (roomId) {
        'tidal_library' => index.isEven ? 1.0 : -1.0,
        _ => 1.0,
      };
      final x =
          (baseX + cycle * speed * horizontalDirection + 1).remainder(1.0);
      final verticalDrift = switch (roomId) {
        'hearth' || 'sunforge' => -.13,
        'tidal_library' => -.04,
        'loft' || 'cloud' => -.025,
        _ => -.075,
      };
      final y = (baseY +
              cycle * verticalDrift +
              sin((progress * 2 * pi) + index * .9) * .018)
          .clamp(.05, .80)
          .toDouble();
      final cycleFade = pow(sin(pi * cycle).abs(), .45).toDouble();
      final twinkle = (.35 +
              ((sin(progress * 2 * pi * (1.2 + speed * 4) + index) + 1) / 2) *
                  .65) *
          cycleFade;
      final radius = .7 + _unit(index * 5 + 5) * (dark ? 1.25 : .85);
      final center = Offset(x * size.width, y * size.height);
      canvas.drawCircle(
        center,
        radius * 3.2,
        Paint()..color = color.withValues(alpha: .055 * twinkle),
      );
      final motePaint = Paint()
        ..color = color.withValues(alpha: .28 * twinkle)
        ..strokeWidth = max(1, radius * .65)
        ..strokeCap = StrokeCap.round;
      switch (roomId) {
        case 'tidal_library':
          motePaint.style = PaintingStyle.stroke;
          canvas.drawCircle(center, radius * 1.45, motePaint);
        case 'crystal':
          final crystal = Path()
            ..moveTo(center.dx, center.dy - radius * 1.7)
            ..lineTo(center.dx + radius, center.dy)
            ..lineTo(center.dx, center.dy + radius * 1.7)
            ..lineTo(center.dx - radius, center.dy)
            ..close();
          canvas.drawPath(crystal, motePaint);
        case 'garden':
          canvas
            ..save()
            ..translate(center.dx, center.dy)
            ..rotate(index * .7 + progress * pi)
            ..drawOval(
              Rect.fromCenter(
                center: Offset.zero,
                width: radius * 2.6,
                height: radius,
              ),
              motePaint,
            )
            ..restore();
        case 'loft' || 'cloud':
          motePaint
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1, radius * .55);
          canvas.drawArc(
            Rect.fromCenter(
              center: center,
              width: radius * 5.2,
              height: radius * 2.2,
            ),
            .15,
            pi * .7,
            false,
            motePaint,
          );
        case 'hearth' || 'sunforge':
          final ember = Path()
            ..moveTo(center.dx, center.dy - radius * 1.8)
            ..quadraticBezierTo(
              center.dx + radius * 1.2,
              center.dy,
              center.dx,
              center.dy + radius,
            )
            ..quadraticBezierTo(
              center.dx - radius,
              center.dy,
              center.dx,
              center.dy - radius * 1.8,
            );
          canvas.drawPath(ember, motePaint);
        default:
          canvas.drawCircle(center, radius, motePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoomAmbientMotionPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.progress != progress ||
      oldDelegate.seed != seed ||
      oldDelegate.roomId != roomId;
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

const _roomWaypoints = <Offset>[
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

Offset _idlePosition(
        RoomDragonVisual dragon, int index, int step, int dragonCount) =>
    _idlePositionForRouteStep(
      dragon,
      index,
      _idleRouteStep(dragon, step),
      dragonCount,
    );

Offset _idlePositionForRouteStep(
    RoomDragonVisual dragon, int index, int routeStep, int dragonCount) {
  final routeOffset = dragon.visualSeed.abs().remainder(_roomWaypoints.length);
  final separation = max(1, _roomWaypoints.length ~/ max(1, dragonCount));
  return _roomWaypoints[
      (routeOffset + routeStep + index * separation) % _roomWaypoints.length];
}

bool _idleFacingRight(
    RoomDragonVisual dragon, int index, int step, int dragonCount) {
  final routeStep = _idleRouteStep(dragon, step);
  if (routeStep == 0) return dragon.visualSeed.isEven;
  final previous =
      _idlePositionForRouteStep(dragon, index, routeStep - 1, dragonCount);
  final current =
      _idlePositionForRouteStep(dragon, index, routeStep, dragonCount);
  return current.dx >= previous.dx;
}

/// Gives each resident its own unhurried walking rhythm. The room still uses
/// one inexpensive timer, while only a subset of the dragons changes waypoint
/// on any tick instead of the whole group marching at once.
int _idleRouteStep(RoomDragonVisual dragon, int sharedStep) {
  final cadence = 2 + dragon.visualSeed.abs().remainder(3);
  final phase = dragon.visualSeed.abs().remainder(cadence);
  return (sharedStep + phase) ~/ cadence;
}

class _RoomDragon extends StatefulWidget {
  const _RoomDragon({
    super.key,
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
  State<_RoomDragon> createState() => _RoomDragonState();
}

class _RoomDragonState extends State<_RoomDragon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gait;
  bool _arriving = true;

  @override
  void initState() {
    super.initState();
    _gait = AnimationController(
      vsync: this,
      duration: widget.moveDuration,
      value: 1,
    );
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.animate) return;
        setState(() => _arriving = false);
      });
    } else {
      _arriving = false;
    }
  }

  @override
  void didUpdateWidget(covariant _RoomDragon oldWidget) {
    super.didUpdateWidget(oldWidget);
    final moved = oldWidget.position != widget.position;
    if (!widget.animate) {
      _gait
        ..stop()
        ..value = 1;
      _arriving = false;
      return;
    }
    if (moved) {
      _gait
        ..duration = widget.moveDuration
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _gait.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stageScale = switch (widget.dragon.stageKey) {
      'spark' => .23,
      'nestDragon' => .27,
      _ => .30,
    };
    final crowdScale = widget.roomDragonCount <= 3
        ? 1.0
        : (3.2 / widget.roomDragonCount).clamp(.58, .9).toDouble();
    final perspectiveScale =
        (.88 + ((widget.position.dy - .56) / .28).clamp(0, 1).toDouble() * .16)
            .clamp(.88, 1.04)
            .toDouble();
    final dragonSize = widget.sceneSize.width *
        stageScale *
        widget.dragon.sizeFactor.clamp(.65, 1.30).toDouble() *
        crowdScale *
        perspectiveScale;
    return AnimatedPositioned(
      key: Key('room-dragon-${widget.dragon.id}'),
      duration: widget.animate ? widget.moveDuration : Duration.zero,
      curve: Curves.easeInOutSine,
      left: widget.position.dx * widget.sceneSize.width - dragonSize / 2,
      top: widget.position.dy * widget.sceneSize.height - dragonSize * .72,
      width: dragonSize,
      height: dragonSize,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _gait,
          builder: (context, child) {
            final moving = _gait.isAnimating && widget.animate;
            final gaitEnvelope = moving ? sin(pi * _gait.value) : 0.0;
            final gaitCycles = 3 + widget.dragon.visualSeed.abs().remainder(2);
            final stride = moving
                ? sin(_gait.value * pi * 2 * gaitCycles) * gaitEnvelope
                : 0.0;
            final stepLift = moving ? stride.abs() * dragonSize * .026 : 0.0;
            final lean = moving ? stride * .018 : 0.0;
            final squash = moving ? stride.abs() * .018 : 0.0;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  key: Key('room-dragon-shadow-${widget.dragon.id}'),
                  left: dragonSize * (.19 + stepLift / dragonSize * .5),
                  right: dragonSize * (.19 + stepLift / dragonSize * .5),
                  bottom: dragonSize * .105,
                  height: dragonSize * .105,
                  child: AnimatedOpacity(
                    key: Key('room-dragon-shadow-arrival-${widget.dragon.id}'),
                    opacity: _arriving ? 0 : 1,
                    duration: widget.animate
                        ? const Duration(milliseconds: 520)
                        : Duration.zero,
                    curve: Curves.easeOutCubic,
                    child: Transform.scale(
                      scaleX: 1 - (stepLift / dragonSize) * 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF1B1730).withValues(alpha: .28),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  key: Key('room-dragon-arrival-${widget.dragon.id}'),
                  opacity: _arriving ? 0 : 1,
                  duration: widget.animate
                      ? const Duration(milliseconds: 520)
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  child: AnimatedScale(
                    scale: _arriving ? .76 : 1,
                    duration: widget.animate
                        ? const Duration(milliseconds: 650)
                        : Duration.zero,
                    curve: Curves.easeOutBack,
                    alignment: Alignment.bottomCenter,
                    child: Transform.translate(
                      offset: Offset(0, -stepLift),
                      child: Transform.rotate(
                        angle: lean,
                        alignment: Alignment.bottomCenter,
                        child: Transform.scale(
                          scaleX: 1 + squash,
                          scaleY: 1 - squash * .55,
                          alignment: Alignment.bottomCenter,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          child: HavenClockBuilder(
            builder: (context, now, _) {
              final mood = dragonTimeMoodAt(
                now,
                widget.dragon.visualSeed,
                suppressed: widget.suppressTimeMood,
              );
              return _DragonTimePose(
                key: ValueKey('time-pose-${widget.dragon.id}'),
                mood: mood,
                stage: widget.dragon.stage,
                visualSeed: widget.dragon.visualSeed,
                animate: widget.animate,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: widget.facingRight ? 1 : -1),
                  duration: widget.animate
                      ? const Duration(milliseconds: 210)
                      : Duration.zero,
                  curve: Curves.easeInOutCubic,
                  builder: (context, scaleX, child) => Transform(
                    transform: Matrix4.diagonal3Values(scaleX, 1, 1),
                    alignment: Alignment.center,
                    child: child,
                  ),
                  child: DragonArt(
                    height: dragonSize,
                    stageKey: widget.dragon.stageKey,
                    lineageId: widget.dragon.lineageId,
                    evolutionPath: widget.dragon.evolutionPath,
                    prismatic: widget.dragon.prismatic,
                    sinister: widget.dragon.sinister,
                    // The room gait and time pose own the movement so the
                    // artwork does not also float out of phase with its feet.
                    animate: false,
                  ),
                ),
              );
            },
          ),
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
    final rect = furnitureRoomPlacementRect(
      item: item,
      placement: placement,
      sceneSize: sceneSize,
    );
    return Positioned(
      key: Key('placed-furniture-${item.id}'),
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        onTap: editable ? onTap : null,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 160),
          padding: EdgeInsets.all(selected ? 4 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border:
                selected ? Border.all(color: AppColors.gold, width: 3) : null,
            color: selected
                ? Colors.white.withValues(alpha: 0.30)
                : Colors.transparent,
          ),
          child: item.hasAmbientAnimation || item.emitsLight
              ? _TimeAwareFurniture(
                  item: item,
                  animationsEnabled: !editable,
                )
              : FurnitureArt(item: item),
        ),
      ),
    );
  }
}

class _TimeAwareFurniture extends StatefulWidget {
  const _TimeAwareFurniture({
    required this.item,
    required this.animationsEnabled,
  });

  final ShopItem item;
  final bool animationsEnabled;

  @override
  State<_TimeAwareFurniture> createState() => _TimeAwareFurnitureState();
}

class _TimeAwareFurnitureState extends State<_TimeAwareFurniture>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _animationsAllowed;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final allowed = !MediaQuery.disableAnimationsOf(context);
    if (_animationsAllowed == allowed) return;
    _animationsAllowed = allowed;
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant _TimeAwareFurniture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _controller.duration = Duration(
        milliseconds: 1800 + widget.item.visualSeed.abs().remainder(1100),
      );
    }
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.animationsEnabled != widget.animationsEnabled) {
      _syncMotion();
    }
  }

  void _syncMotion() {
    if (_animationsAllowed == true &&
        widget.animationsEnabled &&
        widget.item.hasAmbientAnimation) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = .5;
    }
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
            final motion = widget.item.hasAmbientAnimation ? pulse : .5;
            final ambientScale = switch (widget.item.slot) {
              ItemSlot.light => .985 + motion * .025,
              ItemSlot.wall => .997 + motion * .006,
              ItemSlot.plant => .995 + motion * .01,
              ItemSlot.bed => 1.0,
            };
            final ambientAngle =
                widget.item.slot == ItemSlot.plant ? (motion - .5) * .026 : 0.0;
            final ambientLift = widget.item.slot == ItemSlot.light
                ? -motion * 1.8
                : widget.item.slot == ItemSlot.plant
                    ? -motion * .7
                    : 0.0;
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
              child: Transform.translate(
                offset: Offset(0, ambientLift),
                child: Transform.rotate(
                  angle: ambientAngle,
                  alignment: Alignment.bottomCenter,
                  child: Transform.scale(
                    key: Key('room-furniture-motion-${widget.item.id}'),
                    scale: ambientScale,
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                ),
              ),
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
