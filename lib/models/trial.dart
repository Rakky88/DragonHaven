import 'chest.dart';
import 'pet.dart';
import 'mystic_relic.dart';
import 'dragon_emote.dart';

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
    this.relic,
    this.emote,
  });

  final TrialGrade grade;
  final int coins;
  final int xp;
  final int statPoints;
  final ChestTier? chestTier;
  final MysticRelic? relic;
  final DragonEmoteDefinition? emote;
}

class TrialCompletion {
  const TrialCompletion({
    required this.kind,
    required this.baseScore,
    required this.score,
    required this.expertise,
    required this.newDragonBest,
    required this.reward,
  });

  final TrialKind kind;
  final int baseScore;
  final int score;
  final int expertise;
  final bool newDragonBest;
  final TrialReward reward;

  double get expertiseMultiplier => trialExpertiseMultiplier(expertise);
}

double trialExpertiseMultiplier(int expertise) =>
    (1000 + (expertise < 0 ? 0 : expertise)) / 1000;

int trialScoreWithExpertise(int score, int expertise) {
  if (score <= 0) return score < 0 ? 0 : score;
  final safeExpertise = expertise < 0 ? 0 : expertise;
  return (score * (1000 + safeExpertise) + 500) ~/ 1000;
}

TrialGrade trialGradeForScore(TrialKind kind, int score) {
  final thresholds = switch (kind) {
    TrialKind.cavernFlight => const [250, 600, 1100, 1700, 2500],
    TrialKind.ruinBreaker => const [900, 2250, 4000, 6750, 9000],
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

TrialReward trialRewardForGrade(
  TrialGrade grade,
  double chestRoll, {
  double relicRoll = 1,
  int relicChoice = 0,
}) {
  final chest = switch (grade) {
    TrialGrade.d => null,
    TrialGrade.c => ChestTier.wooden,
    TrialGrade.b => chestRoll < .85
        ? ChestTier.wooden
        : chestRoll < .95
            ? ChestTier.silver
            : ChestTier.gold,
    TrialGrade.a => chestRoll < .30
        ? ChestTier.wooden
        : chestRoll < .80
            ? ChestTier.silver
            : ChestTier.gold,
    TrialGrade.s => chestRoll < .30
        ? ChestTier.silver
        : chestRoll < .99
            ? ChestTier.gold
            : ChestTier.dragon,
    TrialGrade.sPlus => chestRoll < .90
        ? ChestTier.gold
        : chestRoll < .99
            ? ChestTier.dragon
            : ChestTier.mythical,
  };
  final (coins, xp, statPoints) = switch (grade) {
    TrialGrade.d => (0, 10, 1),
    TrialGrade.c => (0, 20, 2),
    TrialGrade.b => (0, 30, 3),
    TrialGrade.a => (0, 40, 4),
    TrialGrade.s => (0, 50, 5),
    TrialGrade.sPlus => (0, 69, 7),
  };
  final relic = grade == TrialGrade.sPlus && relicRoll < .01
      ? MysticRelic.values[relicChoice.abs() % MysticRelic.values.length]
      : null;
  return TrialReward(
    grade: grade,
    coins: coins,
    xp: xp,
    statPoints: statPoints,
    chestTier: chest,
    relic: relic,
  );
}
