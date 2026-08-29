import '../utils/json_utils.dart';
import 'dragon_lineage.dart';
import 'pet.dart';

class DragonEgg {
  DragonEgg({
    required this.id,
    required this.lineageId,
    required this.acquiredAt,
    required this.hatchSeed,
    required this.prismatic,
    this.lawAxis = LawAxis.neutral,
    this.moralAxis = MoralAxis.neutral,
    this.sizeFactor = 1,
    int incubationMinutes = 1008,
    int? incubationSeconds,
    this.sinister = false,
    this.xp = 0,
  }) : incubationSeconds = (incubationSeconds ?? incubationMinutes * 60)
            .clamp(60, 14 * 24 * 60 * 60);

  final String id;
  final String lineageId;
  final DateTime acquiredAt;
  final int hatchSeed;
  final bool prismatic;
  final LawAxis lawAxis;
  final MoralAxis moralAxis;
  final double sizeFactor;
  final int incubationSeconds;
  int get incubationMinutes => (incubationSeconds + 59) ~/ 60;
  Duration get incubationDuration => Duration(seconds: incubationSeconds);
  final bool sinister;
  final int xp;

  DragonLineage get lineage => dragonLineageById(lineageId);
  bool get isSinisterEgg => lineageId == 'sinisterra';
  bool get isSpecialEgg => lineage.secret && !isSinisterEgg;

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
        incubationSeconds: incubationSeconds,
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
        'incubationSeconds': incubationSeconds,
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
      incubationSeconds: _incubationSecondsFromJson(json),
      sinister: json['sinister'] is bool && json['sinister'] as bool,
      xp: nonNegativeIntFromJson(json['xp'], fallback: 0),
    );
  }

  static int _incubationSecondsFromJson(Map<String, dynamic> json) {
    final savedSeconds = json['incubationSeconds'];
    if (savedSeconds is num) {
      return savedSeconds.toInt().clamp(60, 14 * 24 * 60 * 60);
    }
    final savedMinutes = json['incubationMinutes'];
    if (savedMinutes is num) {
      return (savedMinutes.toInt() * 60).clamp(60, 14 * 24 * 60 * 60);
    }
    final legacyHours =
        nonNegativeIntFromJson(json['incubationHours'], fallback: 168);
    return ((legacyHours * 6).clamp(1, 14 * 24 * 60)) * 60;
  }
}
