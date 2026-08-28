import '../utils/json_utils.dart';
import 'dragon_lineage.dart';
import 'pet.dart';

class DragonEgg {
  const DragonEgg({
    required this.id,
    required this.lineageId,
    required this.acquiredAt,
    required this.hatchSeed,
    required this.prismatic,
    this.lawAxis = LawAxis.neutral,
    this.moralAxis = MoralAxis.neutral,
    this.sizeFactor = 1,
    this.incubationMinutes = 1008,
    this.sinister = false,
    this.xp = 0,
  });

  final String id;
  final String lineageId;
  final DateTime acquiredAt;
  final int hatchSeed;
  final bool prismatic;
  final LawAxis lawAxis;
  final MoralAxis moralAxis;
  final double sizeFactor;
  final int incubationMinutes;
  Duration get incubationDuration => Duration(minutes: incubationMinutes);
  final bool sinister;
  final int xp;

  DragonLineage get lineage => dragonLineageById(lineageId);
  bool get isSpecialEgg => lineage.secret;

  Pet activate(
          {required int coins, required int gems, DateTime? activatedAt}) =>
      Pet(
        id: id,
        lineageId: lineageId,
        acquiredAt: acquiredAt,
        stageStartedAt: activatedAt ?? DateTime.now(),
        hatchSeed: hatchSeed,
        prismatic: prismatic,
        sinister: sinister,
        lawAxis: lawAxis,
        moralAxis: moralAxis,
        sizeFactor: sizeFactor,
        incubationMinutes: incubationMinutes,
        firstEgg: false,
        xp: xp,
        coins: coins,
        gems: gems,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lineageId': lineageId,
        'acquiredAt': acquiredAt.toIso8601String(),
        'hatchSeed': hatchSeed,
        'prismatic': prismatic,
        'spectral': prismatic,
        'lawAxis': lawAxis.name,
        'moralAxis': moralAxis.name,
        'sizeFactor': sizeFactor,
        'incubationMinutes': incubationMinutes,
        'sinister': sinister,
        'xp': xp,
      };

  factory DragonEgg.fromJson(Map<String, dynamic> json) {
    final seed = nonNegativeIntFromJson(json['hatchSeed'], fallback: 0);
    final lineageId = stringFromJson(json['lineageId']);
    return DragonEgg(
      id: nonEmptyStringFromJson(json['id']) ?? 'egg-$seed',
      lineageId: dragonLineages.any((lineage) => lineage.id == lineageId)
          ? lineageId!
          : standardDragonLineages[
                  seed.remainder(standardDragonLineages.length)]
              .id,
      acquiredAt: DateTime.tryParse(stringFromJson(json['acquiredAt']) ?? '') ??
          DateTime.now(),
      hatchSeed: seed,
      prismatic: (json['spectral'] is bool && json['spectral'] as bool) ||
          (json['prismatic'] is bool && json['prismatic'] as bool),
      lawAxis: enumByName(LawAxis.values, json['lawAxis']) ??
          LawAxis.values[seed.remainder(3)],
      moralAxis: enumByName(MoralAxis.values, json['moralAxis']) ??
          MoralAxis.values[(seed ~/ 3).remainder(3)],
      sizeFactor: ((json['sizeFactor'] as num?)?.toDouble() ?? 1)
          .clamp(.5, 1.5)
          .toDouble(),
      incubationMinutes: _incubationMinutesFromJson(json),
      sinister: json['sinister'] is bool && json['sinister'] as bool,
      xp: nonNegativeIntFromJson(json['xp'], fallback: 0),
    );
  }

  static int _incubationMinutesFromJson(Map<String, dynamic> json) {
    final savedMinutes = json['incubationMinutes'];
    if (savedMinutes is num) {
      return savedMinutes.toInt().clamp(1, 14 * 24 * 60);
    }
    final legacyHours =
        nonNegativeIntFromJson(json['incubationHours'], fallback: 168);
    return (legacyHours * 6).clamp(1, 14 * 24 * 60);
  }
}
