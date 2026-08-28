import 'dart:math';

import '../utils/json_utils.dart';
import 'dragon_lineage.dart';

enum DragonStage { egg, hatchling, wyrmling, ascended }

enum TrainingFocus { might, arcana, spirit }

const int maxDragonExpertise = 300;
const int ascendedDragonExpertise = 350;
const int infernalSpecialistExpertise = 400;

int dragonExpertiseMaximum({
  required DragonStage stage,
  required bool sinister,
  required String? evolutionPath,
  required TrainingFocus focus,
}) {
  if (sinister) {
    if (stage == DragonStage.ascended &&
        (evolutionPath == 'mastery' || evolutionPath == focus.name)) {
      return infernalSpecialistExpertise;
    }
    return ascendedDragonExpertise;
  }
  if (stage != DragonStage.ascended) return maxDragonExpertise;
  if (evolutionPath == 'mastery' || evolutionPath == focus.name) {
    return ascendedDragonExpertise;
  }
  return maxDragonExpertise;
}

Map<String, int> _normalizedTraining(
  Map<String, int>? values, {
  required DragonStage stage,
  required bool sinister,
  required String? evolutionPath,
}) =>
    {
      for (final focus in TrainingFocus.values)
        focus.name: (values?[focus.name] ?? 0)
            .clamp(
              0,
              dragonExpertiseMaximum(
                stage: stage,
                sinister: sinister,
                evolutionPath: evolutionPath,
                focus: focus,
              ),
            )
            .toInt(),
    };

const _trialKeys = {'cavernFlight', 'ruinBreaker', 'runeweaver'};

Map<String, int> _normalizedTrialHighScores(Map<String, int>? values) => {
      for (final key in _trialKeys)
        key: (values?[key] ?? 0).clamp(0, 1000000000).toInt(),
    };

enum LawAxis { lawful, neutral, chaotic }

enum MoralAxis { good, neutral, evil }

const dragonPersonalityTraits = <String>[
  'Sleepy',
  'Nosy',
  'Hoarder',
  'Drama Queen',
  'Bookworm',
  'Food Thief',
  'Afraid of Heights',
  'Restless',
  'Shy',
  'Show-Off',
  'Clumsy',
  'Neat Freak',
  'Messy',
  'Curious',
  'Stubborn',
  'Cuddly',
  'Grumpy',
  'Easily Distracted',
  'Night Owl',
  'Early Bird',
  'Splash Lover',
  'Firebug',
  'Attention Seeker',
  'Startles Easily',
];

const dragonPersonalityIncompatibilities = <String, String>{
  'Sleepy': 'Restless',
  'Restless': 'Sleepy',
  'Shy': 'Show-Off',
  'Show-Off': 'Shy',
  'Neat Freak': 'Messy',
  'Messy': 'Neat Freak',
  'Night Owl': 'Early Bird',
  'Early Bird': 'Night Owl',
};

class Pet {
  Pet({
    String? id,
    this.name = '',
    this.xp = 0,
    this.coins = 25,
    this.gems = 3,
    this.stage = DragonStage.egg,
    this.firstEgg = true,
    this.prismatic = false,
    this.sinister = false,
    this.lawAxis = LawAxis.neutral,
    this.moralAxis = MoralAxis.neutral,
    this.lawAxisKnown = false,
    this.moralAxisKnown = false,
    this.personalityKnown = false,
    this.sizeFactor = 1,
    this.incubationMinutes = 60,
    List<String>? personalityTraitIds,
    this.favorite = false,
    this.roamsTower = true,
    this.currentRoomId = 'hearth',
    this.currentFloorIndex = 0,
    this.activeAdventureId,
    this.joy = 78,
    this.energy = 78,
    this.comfort = 78,
    DateTime? acquiredAt,
    DateTime? stageStartedAt,
    DateTime? needsUpdatedAt,
    Map<String, int>? training,
    Map<String, int>? trialHighScores,
    int? hatchSeed,
    String? lineageId,
    this.evolutionPath,
  })  : id = id ?? 'dragon-${DateTime.now().microsecondsSinceEpoch}',
        acquiredAt = acquiredAt ?? DateTime.now(),
        stageStartedAt = stageStartedAt ?? acquiredAt ?? DateTime.now(),
        needsUpdatedAt = needsUpdatedAt ?? DateTime.now(),
        training = _normalizedTraining(
          training,
          stage: stage,
          sinister: sinister,
          evolutionPath: evolutionPath,
        ),
        trialHighScores = _normalizedTrialHighScores(trialHighScores),
        personalityTraitIds = personalityTraitIds ?? <String>[],
        hatchSeed = hatchSeed ??
            DateTime.now().microsecondsSinceEpoch.remainder(0x7fffffff),
        lineageId = lineageId ??
            standardDragonLineages[(hatchSeed ??
                        DateTime.now()
                            .microsecondsSinceEpoch
                            .remainder(0x7fffffff))
                    .abs()
                    .remainder(standardDragonLineages.length)]
                .id;

  final String id;
  String name;
  int xp;
  int coins;
  int gems;
  DragonStage stage;
  bool firstEgg;
  final bool prismatic;
  final bool sinister;
  final LawAxis lawAxis;
  final MoralAxis moralAxis;
  bool lawAxisKnown;
  bool moralAxisKnown;
  bool personalityKnown;
  final double sizeFactor;
  final int incubationMinutes;
  final List<String> personalityTraitIds;
  bool favorite;
  bool roamsTower;
  String currentRoomId;
  int currentFloorIndex;
  String? activeAdventureId;
  int joy;
  int energy;
  int comfort;
  final DateTime acquiredAt;
  DateTime stageStartedAt;
  DateTime needsUpdatedAt;
  final Map<String, int> training;
  final Map<String, int> trialHighScores;
  final int hatchSeed;
  final String lineageId;
  String? evolutionPath;

  static const hatchXpFirst = 100;
  static const hatchXpLater = 200;
  // Evolution milestones line up with the first XP of their advertised level.
  static const wyrmlingXp = 350; // Level 3.
  static const ascendedXp = 1950; // Level 7.

  DragonLineage get lineage => dragonLineageById(lineageId);
  bool get spectral => prismatic;
  bool get isEgg => stage == DragonStage.egg;
  bool get isSpecialEgg => isEgg && lineage.secret;
  String get displayName => isEgg
      ? (isSpecialEgg ? 'Special Egg' : 'Mysterious Egg')
      : name.trim().isEmpty
          ? lineage.nameEn
          : name.trim();

  String get stageKey => switch (stage) {
        DragonStage.egg => 'moonEgg',
        DragonStage.hatchling => 'spark',
        DragonStage.wyrmling => 'nestDragon',
        DragonStage.ascended => 'homeGuardian',
      };

  static const levelThresholds = [
    0,
    150,
    350,
    650,
    1000,
    1450,
    1950,
    2600,
    3400
  ];
  int get level {
    return levelAtXp(xp);
  }

  static int levelAtXp(int xp) {
    for (var index = levelThresholds.length - 1; index >= 0; index--) {
      if (xp >= levelThresholds[index]) return index + 1;
    }
    return 1;
  }

  int get currentLevelFloor =>
      levelThresholds[(level - 1).clamp(0, levelThresholds.length - 1)];
  int get nextLevelTarget =>
      level >= levelThresholds.length ? xp : levelThresholds[level];
  double get levelProgress {
    if (level >= levelThresholds.length) return 1;
    final span = max(1, nextLevelTarget - currentLevelFloor);
    return ((xp - currentLevelFloor) / span).clamp(0, 1);
  }

  int? get nextEvolutionXp => switch (stage) {
        DragonStage.hatchling => wyrmlingXp,
        DragonStage.wyrmling => ascendedXp,
        DragonStage.egg || DragonStage.ascended => null,
      };

  int? get nextEvolutionLevel {
    final target = nextEvolutionXp;
    return target == null ? null : levelAtXp(target);
  }

  DragonStage? get nextEvolutionStage => switch (stage) {
        DragonStage.hatchling => DragonStage.wyrmling,
        DragonStage.wyrmling => DragonStage.ascended,
        DragonStage.egg || DragonStage.ascended => null,
      };

  double get wellbeing => (joy + energy + comfort) / 300;
  int trainingFor(TrainingFocus focus) => training[focus.name] ?? 0;
  int expertiseMaximum(TrainingFocus focus) => dragonExpertiseMaximum(
        stage: stage,
        sinister: sinister,
        evolutionPath: evolutionPath,
        focus: focus,
      );
  int get maximumTotalExpertise => TrainingFocus.values
      .fold(0, (total, focus) => total + expertiseMaximum(focus));
  int trialBest(String trialKey) => trialHighScores[trialKey] ?? 0;

  bool recordTrialScore(String trialKey, int score) {
    if (!_trialKeys.contains(trialKey) || score <= trialBest(trialKey)) {
      return false;
    }
    trialHighScores[trialKey] = score.clamp(0, 1000000000).toInt();
    return true;
  }

  int get totalTraining => TrainingFocus.values
      .fold(0, (total, focus) => total + trainingFor(focus));

  bool get hasMasteryBalance {
    if (stage != DragonStage.wyrmling) return false;
    final scores = TrainingFocus.values.map(trainingFor).toList();
    return scores.toSet().length == 1;
  }

  bool get isMastery =>
      stage == DragonStage.ascended && activeEvolutionPath == 'mastery';

  String get leadingPath {
    if (totalTraining == 0) return 'unknown';
    final ranked = TrainingFocus.values.toList()
      ..sort((a, b) {
        final value = trainingFor(b).compareTo(trainingFor(a));
        if (value != 0) return value;
        final stableA = (hatchSeed + a.index * 97).remainder(997);
        final stableB = (hatchSeed + b.index * 97).remainder(997);
        return stableA.compareTo(stableB);
      });
    return ranked.first.name;
  }

  String get activeEvolutionPath => evolutionPath ?? leadingPath;
  Duration ageAt(DateTime now) => now.isAfter(stageStartedAt)
      ? now.difference(stageStartedAt)
      : Duration.zero;
  Duration get incubationDuration => Duration(minutes: incubationMinutes);

  bool canHatch(DateTime now) => isEgg && ageAt(now) >= incubationDuration;
  bool canEvolve(DateTime now) => switch (stage) {
        DragonStage.hatchling => xp >= wyrmlingXp,
        DragonStage.wyrmling => xp >= ascendedXp && totalTraining >= 300,
        _ => false,
      };

  Duration remainingForNextStage(DateTime now) {
    final minimum = switch (stage) {
      DragonStage.egg => incubationDuration,
      DragonStage.hatchling || DragonStage.wyrmling => Duration.zero,
      DragonStage.ascended => Duration.zero,
    };
    final elapsed = ageAt(now);
    return elapsed >= minimum ? Duration.zero : minimum - elapsed;
  }

  bool applyTimeDecay(DateTime now) {
    if (isEgg || !now.isAfter(needsUpdatedAt)) return false;
    final periods = now.difference(needsUpdatedAt).inHours ~/ 8;
    if (periods <= 0) return false;
    joy = max(25, joy - periods * 2);
    energy = max(20, energy - periods * 2);
    comfort = max(30, comfort - periods);
    needsUpdatedAt = needsUpdatedAt.add(Duration(hours: periods * 8));
    return true;
  }

  void addTraining(TrainingFocus focus, int amount) {
    if (amount <= 0) return;
    final maximum = expertiseMaximum(focus);
    training.update(
      focus.name,
      (value) => (value + amount).clamp(0, maximum).toInt(),
      ifAbsent: () => amount.clamp(0, maximum).toInt(),
    );
  }

  void hatch(DateTime now) {
    if (!canHatch(now)) throw StateError('This egg is not ready to hatch.');
    stage = DragonStage.hatchling;
    stageStartedAt = now;
    name = '';
    joy = 90;
    energy = 88;
    comfort = 90;
    needsUpdatedAt = now;
    _rollPersonalityIfNeeded();
  }

  void _rollPersonalityIfNeeded() {
    if (personalityTraitIds.isNotEmpty) return;
    final random = Random(hatchSeed ^ 0x5a17c9);
    final count = random.nextDouble() < .25 ? 2 : 1;
    while (personalityTraitIds.length < count) {
      final candidate = dragonPersonalityTraits[
          random.nextInt(dragonPersonalityTraits.length)];
      if (personalityTraitIds.contains(candidate)) continue;
      final incompatible = dragonPersonalityIncompatibilities[candidate];
      if (incompatible != null && personalityTraitIds.contains(incompatible)) {
        continue;
      }
      personalityTraitIds.add(candidate);
    }
  }

  void revealPersonality() {
    _rollPersonalityIfNeeded();
    personalityKnown = true;
  }

  void evolve(DateTime now) {
    if (!canEvolve(now)) {
      throw StateError('This dragon is not ready to evolve.');
    }
    if (stage == DragonStage.hatchling) {
      stage = DragonStage.wyrmling;
    } else if (stage == DragonStage.wyrmling) {
      evolutionPath = hasMasteryBalance
          ? 'mastery'
          : leadingPath == 'unknown'
              ? 'spirit'
              : leadingPath;
      stage = DragonStage.ascended;
    }
    stageStartedAt = now;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'xp': xp,
        'coins': coins,
        'gems': gems,
        'stage': stage.name,
        'firstEgg': firstEgg,
        'prismatic': prismatic,
        'spectral': prismatic,
        'sinister': sinister,
        'lawAxis': lawAxis.name,
        'moralAxis': moralAxis.name,
        'lawAxisKnown': lawAxisKnown,
        'moralAxisKnown': moralAxisKnown,
        'personalityKnown': personalityKnown,
        'sizeFactor': sizeFactor,
        'incubationMinutes': incubationMinutes,
        'personalityTraitIds': personalityTraitIds,
        'favorite': favorite,
        'roamsTower': roamsTower,
        'currentRoomId': currentRoomId,
        'currentFloorIndex': currentFloorIndex,
        'activeAdventureId': activeAdventureId,
        'joy': joy,
        'energy': energy,
        'comfort': comfort,
        'acquiredAt': acquiredAt.toIso8601String(),
        'stageStartedAt': stageStartedAt.toIso8601String(),
        'needsUpdatedAt': needsUpdatedAt.toIso8601String(),
        'training': training,
        'trialHighScores': trialHighScores,
        'hatchSeed': hatchSeed,
        'lineageId': lineageId,
        'evolutionPath': evolutionPath,
      };

  factory Pet.fromJson(Map<String, dynamic> json) {
    final seed = json['hatchSeed'] is num
        ? (json['hatchSeed'] as num).toInt().abs()
        : DateTime.now().microsecondsSinceEpoch.remainder(0x7fffffff);
    final oldXp = nonNegativeIntFromJson(json['xp'], fallback: 0);
    final storedStage = enumByName(DragonStage.values, json['stage']);
    final legacyStage = oldXp < 60
        ? DragonStage.egg
        : oldXp < 280
            ? DragonStage.hatchling
            : oldXp < 700
                ? DragonStage.wyrmling
                : DragonStage.ascended;
    final rawTraining = mapFromJson(json['training']);
    final oldTraining = mapFromJson(json['pathEnergy']);
    final acquired = DateTime.tryParse(
          stringFromJson(json['acquiredAt']) ??
              stringFromJson(json['needsUpdatedAt']) ??
              '',
        ) ??
        DateTime.now();
    final stageStart =
        DateTime.tryParse(stringFromJson(json['stageStartedAt']) ?? '') ??
            acquired;
    final lineage = stringFromJson(json['lineageId']);
    final isFirstEgg =
        json['firstEgg'] is bool ? json['firstEgg'] as bool : true;
    final storedPath = stringFromJson(json['evolutionPath']);
    final migratedPath = switch (storedPath) {
      'earth' => 'might',
      'storm' => 'arcana',
      'bond' => 'spirit',
      'might' || 'arcana' || 'spirit' || 'mastery' => storedPath,
      _ => null,
    };
    return Pet(
      id: nonEmptyStringFromJson(json['id']) ?? 'legacy-$seed',
      name: stringFromJson(json['name'])?.trim() ?? '',
      xp: oldXp,
      coins: nonNegativeIntFromJson(json['coins'], fallback: 25),
      gems: nonNegativeIntFromJson(json['gems'], fallback: 3),
      stage: storedStage ?? legacyStage,
      firstEgg: isFirstEgg,
      prismatic: (json['spectral'] is bool && json['spectral'] as bool) ||
          (json['prismatic'] is bool && json['prismatic'] as bool),
      sinister: json['sinister'] is bool && json['sinister'] as bool,
      lawAxis: enumByName(LawAxis.values, json['lawAxis']) ??
          LawAxis.values[seed.remainder(LawAxis.values.length)],
      moralAxis: enumByName(MoralAxis.values, json['moralAxis']) ??
          MoralAxis.values[(seed ~/ 3).remainder(MoralAxis.values.length)],
      lawAxisKnown:
          json['lawAxisKnown'] is bool && json['lawAxisKnown'] as bool,
      moralAxisKnown:
          json['moralAxisKnown'] is bool && json['moralAxisKnown'] as bool,
      personalityKnown:
          json['personalityKnown'] is bool && json['personalityKnown'] as bool,
      sizeFactor: ((json['sizeFactor'] as num?)?.toDouble() ?? 1)
          .clamp(.5, 1.5)
          .toDouble(),
      incubationMinutes: _incubationMinutesFromJson(json, firstEgg: isFirstEgg),
      personalityTraitIds: (json['personalityTraitIds'] as List?)
              ?.whereType<String>()
              .where(dragonPersonalityTraits.contains)
              .toSet()
              .take(2)
              .toList() ??
          <String>[],
      favorite: json['favorite'] is bool && json['favorite'] as bool,
      roamsTower: json['roamsTower'] is! bool || json['roamsTower'] as bool,
      currentRoomId: nonEmptyStringFromJson(json['currentRoomId']) ?? 'hearth',
      currentFloorIndex:
          nonNegativeIntFromJson(json['currentFloorIndex'], fallback: 0),
      activeAdventureId: nonEmptyStringFromJson(json['activeAdventureId']),
      joy: percentageFromJson(json['joy'], fallback: 78),
      energy: percentageFromJson(json['energy'], fallback: 78),
      comfort: percentageFromJson(json['comfort'], fallback: 78),
      acquiredAt: acquired,
      stageStartedAt: stageStart,
      needsUpdatedAt:
          DateTime.tryParse(stringFromJson(json['needsUpdatedAt']) ?? '') ??
              DateTime.now(),
      hatchSeed: seed,
      lineageId: dragonLineages.any((candidate) => candidate.id == lineage)
          ? lineage
          : standardDragonLineages[
                  seed.remainder(standardDragonLineages.length)]
              .id,
      evolutionPath: migratedPath,
      training: {
        'might': nonNegativeIntFromJson(
          rawTraining['might'] ?? oldTraining['earth'],
          fallback: 0,
        ),
        'arcana': nonNegativeIntFromJson(
          rawTraining['arcana'] ?? oldTraining['storm'],
          fallback: 0,
        ),
        'spirit': nonNegativeIntFromJson(
          rawTraining['spirit'] ?? oldTraining['bond'],
          fallback: 0,
        ),
      },
      trialHighScores: {
        for (final entry in mapFromJson(json['trialHighScores']).entries)
          entry.key: nonNegativeIntFromJson(entry.value, fallback: 0),
      },
    );
  }

  static int _incubationMinutesFromJson(
    Map<String, dynamic> json, {
    required bool firstEgg,
  }) {
    if (firstEgg) return 60;
    final savedMinutes = json['incubationMinutes'];
    if (savedMinutes is num) {
      return savedMinutes.toInt().clamp(1, 14 * 24 * 60);
    }

    // Versions through v0.01.02 stored whole hours. Starter Eggs now take one
    // hour, while every already-incubating later egg immediately adopts one
    // tenth of its original duration without resetting its start time.
    final legacyHours = nonNegativeIntFromJson(
      json['incubationHours'],
      fallback: 24 * 7,
    );
    return (legacyHours * 6).clamp(1, 14 * 24 * 60);
  }
}
