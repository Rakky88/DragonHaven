import 'chest.dart';
import 'pet.dart';

enum TrialKind { cavernFlight, ruinBreaker, runeweaver }

enum TrialGrade { d, c, b, a, s, sPlus }

class TrialDefinition {
  const TrialDefinition({
    required this.kind,
    required this.focus,
    required this.titleEn,
    required this.titleNl,
    required this.subtitleEn,
    required this.subtitleNl,
  });

  final TrialKind kind;
  final TrainingFocus focus;
  final String titleEn;
  final String titleNl;
  final String subtitleEn;
  final String subtitleNl;

  String title(String languageCode) => languageCode == 'nl' ? titleNl : titleEn;
  String subtitle(String languageCode) =>
      languageCode == 'nl' ? subtitleNl : subtitleEn;
}

const trialDefinitions = <TrialKind, TrialDefinition>{
  TrialKind.cavernFlight: TrialDefinition(
    kind: TrialKind.cavernFlight,
    focus: TrainingFocus.spirit,
    titleEn: 'Cavern Flight',
    titleNl: 'Grotvlucht',
    subtitleEn: 'Thread the crystal cavern with instinct and control.',
    subtitleNl: 'Vlieg met instinct en beheersing door de kristalgrot.',
  ),
  TrialKind.ruinBreaker: TrialDefinition(
    kind: TrialKind.ruinBreaker,
    focus: TrainingFocus.might,
    titleEn: 'Ruin Breaker',
    titleNl: 'Ruinebreker',
    subtitleEn: 'Time every strike and shatter the ancient road.',
    subtitleNl: 'Time iedere slag en breek door de eeuwenoude route.',
  ),
  TrialKind.runeweaver: TrialDefinition(
    kind: TrialKind.runeweaver,
    focus: TrainingFocus.arcana,
    titleEn: 'Runeweaver',
    titleNl: 'Runenwever',
    subtitleEn: 'Remember the runes and awaken the sealed gate.',
    subtitleNl: 'Onthoud de runen en wek de verzegelde poort.',
  ),
};

class TrialOffer {
  const TrialOffer({
    required this.id,
    required this.kind,
    required this.appearedAt,
  });

  final String id;
  final TrialKind kind;
  final DateTime appearedAt;

  TrialDefinition get definition => trialDefinitions[kind]!;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'appearedAt': appearedAt.toIso8601String(),
      };

  factory TrialOffer.fromJson(Map<String, dynamic> json) => TrialOffer(
        id: json['id']?.toString() ?? '',
        kind: TrialKind.values.firstWhere(
          (value) => value.name == json['kind'],
          orElse: () => TrialKind.cavernFlight,
        ),
        appearedAt: DateTime.tryParse(json['appearedAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class TrialReward {
  const TrialReward({
    required this.grade,
    required this.coins,
    required this.xp,
    required this.statPoints,
    this.chestTier,
  });

  final TrialGrade grade;
  final int coins;
  final int xp;
  final int statPoints;
  final ChestTier? chestTier;
}

class TrialCompletion {
  const TrialCompletion({
    required this.kind,
    required this.score,
    required this.newDragonBest,
    required this.reward,
  });

  final TrialKind kind;
  final int score;
  final bool newDragonBest;
  final TrialReward reward;
}

TrialGrade trialGradeForScore(TrialKind kind, int score) {
  final thresholds = switch (kind) {
    TrialKind.cavernFlight => const [25, 60, 100, 150, 220],
    TrialKind.ruinBreaker => const [300, 700, 1200, 1800, 2600],
    TrialKind.runeweaver => const [3, 6, 9, 12, 15],
  };
  if (score >= thresholds[4]) return TrialGrade.sPlus;
  if (score >= thresholds[3]) return TrialGrade.s;
  if (score >= thresholds[2]) return TrialGrade.a;
  if (score >= thresholds[1]) return TrialGrade.b;
  if (score >= thresholds[0]) return TrialGrade.c;
  return TrialGrade.d;
}

String trialGradeLabel(TrialGrade grade) =>
    grade == TrialGrade.sPlus ? 'S+' : grade.name.toUpperCase();

double cavernFlightHitboxScale(int spirit) =>
    1 - .10 * (spirit.clamp(0, 300) / 300);

double ruinBreakerSuccessZoneScale(int might) =>
    1 + .15 * (might.clamp(0, 300) / 300);

double ruinBreakerPerfectZoneScale(int might) =>
    1 + .05 * (might.clamp(0, 300) / 300);

Duration runeweaverRuneDuration(int arcana) => Duration(
      milliseconds: 500 + (100 * (arcana.clamp(0, 300) / 300)).round(),
    );

TrialReward trialRewardForGrade(TrialGrade grade, double chestRoll) {
  final chest = switch (grade) {
    TrialGrade.d => null,
    TrialGrade.c => ChestTier.wooden,
    TrialGrade.b => chestRoll < .85 ? ChestTier.silver : ChestTier.gold,
    TrialGrade.a => chestRoll < .10
        ? ChestTier.silver
        : chestRoll < .98
            ? ChestTier.gold
            : ChestTier.dragon,
    TrialGrade.s => chestRoll < .92 ? ChestTier.gold : ChestTier.dragon,
    TrialGrade.sPlus => chestRoll < .04
        ? ChestTier.gold
        : chestRoll < .99
            ? ChestTier.dragon
            : ChestTier.mythical,
  };
  final (coins, xp, statPoints) = switch (grade) {
    TrialGrade.d => (20, 10, 1),
    TrialGrade.c => (35, 20, 2),
    TrialGrade.b => (60, 40, 3),
    TrialGrade.a => (100, 70, 5),
    TrialGrade.s => (160, 100, 7),
    TrialGrade.sPlus => (250, 150, 10),
  };
  return TrialReward(
    grade: grade,
    coins: coins,
    xp: xp,
    statPoints: statPoints,
    chestTier: chest,
  );
}
