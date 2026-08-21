import 'shop_item.dart';
import 'day_phase.dart';
import '../utils/json_utils.dart';

class HouseRoomDefinition {
  const HouseRoomDefinition({
    required this.id,
    required this.unlockLevel,
    required this.price,
    required this.tintValue,
    this.backgroundAsset = 'assets/images/house_room_nest.webp',
    this.floorMinY = 0.57,
    this.floorMaxY = 0.84,
    this.wallMinY = 0.20,
    this.wallMaxY = 0.46,
  });

  final String id;
  final int unlockLevel;
  final int price;
  final int tintValue;
  final String backgroundAsset;
  final double floorMinY;
  final double floorMaxY;
  final double wallMinY;
  final double wallMaxY;

  String backgroundForPhase(HavenDayPhase phase) {
    final suffix = switch (phase) {
      HavenDayPhase.morning || HavenDayPhase.day => 'day',
      HavenDayPhase.deepNight || HavenDayPhase.night => 'night',
      HavenDayPhase.dawn ||
      HavenDayPhase.goldenHour ||
      HavenDayPhase.dusk =>
        null,
    };
    if (suffix == null) return backgroundAsset;
    return 'assets/images/house_room_${id}_$suffix.webp';
  }
}

const houseRoomCatalog = <HouseRoomDefinition>[
  HouseRoomDefinition(
    id: 'nest',
    unlockLevel: 1,
    price: 0,
    tintValue: 0x00000000,
  ),
  HouseRoomDefinition(
    id: 'hearth',
    unlockLevel: 2,
    price: 45,
    tintValue: 0x00000000,
    backgroundAsset: 'assets/images/house_room_hearth.webp',
    floorMinY: 0.60,
    wallMaxY: 0.49,
  ),
  HouseRoomDefinition(
    id: 'crystal',
    unlockLevel: 3,
    price: 65,
    tintValue: 0x00000000,
    backgroundAsset: 'assets/images/house_room_crystal.webp',
    floorMinY: 0.51,
    floorMaxY: 0.88,
    wallMinY: 0.16,
    wallMaxY: 0.43,
  ),
  HouseRoomDefinition(
    id: 'garden',
    unlockLevel: 4,
    price: 80,
    tintValue: 0x00000000,
    backgroundAsset: 'assets/images/house_room_garden.webp',
    floorMinY: 0.55,
    floorMaxY: 0.88,
    wallMinY: 0.18,
    wallMaxY: 0.43,
  ),
  HouseRoomDefinition(
    id: 'tidal_library',
    unlockLevel: 5,
    price: 105,
    tintValue: 0x00000000,
    backgroundAsset: 'assets/images/house_room_tidal_library.webp',
    floorMinY: 0.54,
    floorMaxY: 0.89,
    wallMinY: 0.18,
    wallMaxY: 0.45,
  ),
  HouseRoomDefinition(
    id: 'loft',
    unlockLevel: 6,
    price: 130,
    tintValue: 0x00000000,
    backgroundAsset: 'assets/images/house_room_loft.webp',
    floorMinY: 0.59,
    floorMaxY: 0.86,
    wallMinY: 0.19,
    wallMaxY: 0.48,
  ),
  HouseRoomDefinition(
    id: 'cloud',
    unlockLevel: 7,
    price: 165,
    tintValue: 0x00000000,
    backgroundAsset: 'assets/images/house_room_cloud.webp',
    floorMinY: 0.55,
    floorMaxY: 0.89,
    wallMinY: 0.17,
    wallMaxY: 0.46,
  ),
  HouseRoomDefinition(
    id: 'sunforge',
    unlockLevel: 9,
    price: 240,
    tintValue: 0x00000000,
    backgroundAsset: 'assets/images/house_room_sunforge.webp',
    floorMinY: 0.57,
    floorMaxY: 0.89,
    wallMinY: 0.18,
    wallMaxY: 0.47,
  ),
];

class HousePlacement {
  const HousePlacement({
    required this.itemId,
    required this.roomId,
    required this.x,
    required this.y,
    this.scale = 1,
  });

  final String itemId;
  final String roomId;
  final double x;
  final double y;
  final double scale;

  HousePlacement copyWith({
    String? itemId,
    String? roomId,
    double? x,
    double? y,
    double? scale,
  }) =>
      HousePlacement(
        itemId: itemId ?? this.itemId,
        roomId: roomId ?? this.roomId,
        x: _normalized(x ?? this.x),
        y: _normalized(y ?? this.y),
        scale: (scale ?? this.scale).clamp(0.65, 1.35).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'roomId': roomId,
        'x': x,
        'y': y,
        'scale': scale,
      };

  factory HousePlacement.fromJson(Map<String, dynamic> json) => HousePlacement(
        itemId: stringFromJson(json['itemId']) ?? '',
        roomId: stringFromJson(json['roomId']) ?? 'nest',
        x: _normalized(_finiteDouble(json['x'], 0.5)),
        y: _normalized(_finiteDouble(json['y'], 0.7)),
        scale: _finiteDouble(json['scale'], 1).clamp(0.65, 1.35).toDouble(),
      );

  static double _normalized(double value) => value.clamp(0.04, 0.96).toDouble();

  static double _finiteDouble(Object? value, double fallback) {
    final number = value is num ? value.toDouble() : fallback;
    return number.isFinite ? number : fallback;
  }
}

HousePlacement defaultPlacementFor(
  ShopItem item,
  String roomId,
  int slotIndex,
) {
  final room = houseRoomById(roomId) ?? houseRoomCatalog.first;
  final targetRoomId = room.id;
  final points = _defaultPoints(targetRoomId, item.slot, room);
  final point = points[slotIndex % points.length];
  return HousePlacement(
    itemId: item.id,
    roomId: targetRoomId,
    x: point.x,
    y: point.y,
  );
}

List<({double x, double y})> _defaultPoints(
  String roomId,
  ItemSlot slot,
  HouseRoomDefinition room,
) =>
    switch ((roomId, slot)) {
      ('hearth', ItemSlot.bed) => [
          (x: 0.23, y: 0.78),
          (x: 0.77, y: 0.78),
          (x: 0.50, y: 0.82)
        ],
      ('hearth', ItemSlot.plant) => [
          (x: 0.12, y: 0.70),
          (x: 0.88, y: 0.70),
          (x: 0.50, y: 0.66)
        ],
      ('hearth', ItemSlot.wall) => [
          (x: 0.19, y: 0.36),
          (x: 0.81, y: 0.36),
          (x: 0.50, y: 0.27)
        ],
      ('hearth', ItemSlot.light) => [
          (x: 0.34, y: 0.34),
          (x: 0.66, y: 0.34),
          (x: 0.50, y: 0.42)
        ],
      ('garden', ItemSlot.bed) => [
          (x: 0.50, y: 0.80),
          (x: 0.29, y: 0.77),
          (x: 0.71, y: 0.77)
        ],
      ('garden', ItemSlot.plant) => [
          (x: 0.17, y: 0.67),
          (x: 0.83, y: 0.67),
          (x: 0.50, y: 0.63)
        ],
      ('garden', ItemSlot.wall) => [
          (x: 0.23, y: 0.32),
          (x: 0.77, y: 0.32),
          (x: 0.50, y: 0.24)
        ],
      ('garden', ItemSlot.light) => [
          (x: 0.14, y: 0.38),
          (x: 0.86, y: 0.38),
          (x: 0.50, y: 0.34)
        ],
      ('loft', ItemSlot.bed) => [
          (x: 0.27, y: 0.80),
          (x: 0.73, y: 0.80),
          (x: 0.50, y: 0.74)
        ],
      ('loft', ItemSlot.plant) => [
          (x: 0.16, y: 0.73),
          (x: 0.84, y: 0.73),
          (x: 0.50, y: 0.67)
        ],
      ('loft', ItemSlot.wall) => [
          (x: 0.20, y: 0.35),
          (x: 0.80, y: 0.35),
          (x: 0.50, y: 0.28)
        ],
      ('loft', ItemSlot.light) => [
          (x: 0.32, y: 0.39),
          (x: 0.68, y: 0.39),
          (x: 0.50, y: 0.22)
        ],
      (_, ItemSlot.bed) => [
          (x: 0.22, y: room.floorMaxY - 0.06),
          (x: 0.50, y: room.floorMaxY - 0.04),
          (x: 0.78, y: room.floorMaxY - 0.06),
        ],
      (_, ItemSlot.plant) => [
          (x: 0.78, y: room.floorMinY + 0.13),
          (x: 0.22, y: room.floorMinY + 0.13),
          (x: 0.50, y: room.floorMinY + 0.10),
        ],
      (_, ItemSlot.wall) => [
          (x: 0.20, y: 0.34),
          (x: 0.50, y: 0.30),
          (x: 0.80, y: 0.34),
        ],
      (_, ItemSlot.light) => [
          (x: 0.72, y: 0.34),
          (x: 0.28, y: 0.34),
          (x: 0.50, y: 0.40),
        ],
    };

final Map<String, HouseRoomDefinition> _roomsById =
    Map<String, HouseRoomDefinition>.unmodifiable({
  for (final room in houseRoomCatalog) room.id: room,
});

HouseRoomDefinition? houseRoomById(String id) => _roomsById[id];
