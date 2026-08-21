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
    this.incubationHours = 168,
    this.sinister = false,
    this.careScore = 0,
    this.careActions = 0,
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
  final int incubationHours;
  final bool sinister;
  final int careScore;
  final int careActions;
  final int xp;

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
        incubationHours: incubationHours,
        firstEgg: false,
        careScore: careScore,
        careActions: careActions,
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
        'incubationHours': incubationHours,
        'sinister': sinister,
        'careScore': careScore,
        'careActions': careActions,
        'xp': xp,
      };

  factory DragonEgg.fromJson(Map<String, dynamic> json) {
    final seed = nonNegativeIntFromJson(json['hatchSeed'], fallback: 0);
    final lineageId = stringFromJson(json['lineageId']);
    return DragonEgg(
      id: nonEmptyStringFromJson(json['id']) ?? 'egg-$seed',
      lineageId: dragonLineages.any((lineage) => lineage.id == lineageId)
          ? lineageId!
          : dragonLineages[seed.remainder(dragonLineages.length)].id,
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
      incubationHours:
          nonNegativeIntFromJson(json['incubationHours'], fallback: 168)
              .clamp(48, 336)
              .toInt(),
      sinister: json['sinister'] is bool && json['sinister'] as bool,
      careScore: nonNegativeIntFromJson(json['careScore'], fallback: 0),
      careActions: nonNegativeIntFromJson(json['careActions'], fallback: 0),
      xp: nonNegativeIntFromJson(json['xp'], fallback: 0),
    );
  }
}
