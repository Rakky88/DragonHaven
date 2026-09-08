import 'chest.dart';
import 'pet.dart';
import 'mystic_relic.dart';
import 'dragon_emote.dart';

enum TrialKind {
  cavernFlight,
  ruinBreaker,
  runeweaver,
  witchlightWard,
  hollyfrostGiftforge,
  midnightChime,
  rosevowRelay,
  prismaticParade,
}

enum TrialGrade { d, c, b, a, s, sPlus }

class TrialDefinition {
  const TrialDefinition({
    required this.kind,
    required this.focus,
    required this.titleEn,
    required this.titleNl,
    required this.subtitleEn,
    required this.subtitleNl,
    this.specialEventId,
    this.duration = const Duration(seconds: 75),
  });

  final TrialKind kind;
  final TrainingFocus focus;
  final String titleEn;
  final String titleNl;
  final String subtitleEn;
  final String subtitleNl;
  final String? specialEventId;
  final Duration duration;

  bool get isSeasonal => specialEventId != null;

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
  TrialKind.witchlightWard: TrialDefinition(
    kind: TrialKind.witchlightWard,
    focus: TrainingFocus.arcana,
    titleEn: 'Witchlight Ward',
    titleNl: 'Heksenlichtbescherming',
    subtitleEn:
        'Balance lantern wards, catch brave wisps and drive the creeping gloom from the grove.',
    subtitleNl:
        'Breng lantaarntekens in balans, vang dappere dwaallichtjes en verjaag de sluipende duisternis.',
    specialEventId: 'halloween_witchlight',
  ),
  TrialKind.hollyfrostGiftforge: TrialDefinition(
    kind: TrialKind.hollyfrostGiftforge,
    focus: TrainingFocus.might,
    titleEn: 'Hollyfrost Giftforge',
    titleNl: 'Hollyfrosts Geschenkensmidse',
    subtitleEn:
        'Remember each gift, stamp it at the glowing forge and send it safely to the starlight sleigh.',
    subtitleNl:
        'Onthoud elk cadeau, stempel het bij de gloeiende smidse en stuur het veilig naar de sterrenlichtslee.',
    specialEventId: 'christmas_winter_hearth',
  ),
  TrialKind.midnightChime: TrialDefinition(
    kind: TrialKind.midnightChime,
    focus: TrainingFocus.spirit,
    titleEn: 'Midnight Chime',
    titleNl: 'Middernachtklank',
    subtitleEn:
        'Read the turning sky, strike the chimes in rhythm and launch a perfect first-dawn firework.',
    subtitleNl:
        'Lees de draaiende hemel, sla de klokken in ritme en lanceer perfect eerstedagvuurwerk.',
    specialEventId: 'new_year_first_dawn',
  ),
  TrialKind.rosevowRelay: TrialDefinition(
    kind: TrialKind.rosevowRelay,
    focus: TrainingFocus.spirit,
    titleEn: 'Rosevow Relay',
    titleNl: 'Rozenbelofte-estafette',
    subtitleEn:
        'Carry paired heartlights across thorn gates and keep both promises glowing together.',
    subtitleNl:
        'Draag twee hartlichten langs doornpoorten en laat beide beloften samen gloeien.',
    specialEventId: 'valentine_two_heartlights',
  ),
  TrialKind.prismaticParade: TrialDefinition(
    kind: TrialKind.prismaticParade,
    focus: TrainingFocus.arcana,
    titleEn: 'Prismatic Parade',
    titleNl: 'Prismatische Parade',
    subtitleEn:
        'Match color and shape, weave seven radiant ribbons and keep the whole parade shining.',
    subtitleNl:
        'Combineer kleur en vorm, weef zeven stralende linten en laat de hele parade schitteren.',
    specialEventId: 'pride_every_color',
  ),
};

const standardTrialKinds = <TrialKind>[
  TrialKind.cavernFlight,
  TrialKind.ruinBreaker,
  TrialKind.runeweaver,
];

TrialKind? trialKindByName(String? name) {
  if (name == null || name.isEmpty) return null;
  for (final kind in TrialKind.values) {
    if (kind.name == name) return kind;
  }
  return null;
}

class TrialOffer {
  const TrialOffer({
    required this.id,
    required this.kind,
    required this.appearedAt,
    this.specialEventKey,
    this.startedAt,
  });

  final String id;
  final TrialKind kind;
  final DateTime appearedAt;
  final String? specialEventKey;
  final DateTime? startedAt;

  TrialOffer copyWith({DateTime? startedAt}) => TrialOffer(
        id: id,
        kind: kind,
        appearedAt: appearedAt,
        specialEventKey: specialEventKey,
        startedAt: startedAt ?? this.startedAt,
      );

  TrialDefinition get definition => trialDefinitions[kind]!;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'appearedAt': appearedAt.toIso8601String(),
        'specialEventKey': specialEventKey,
        'startedAt': startedAt?.toIso8601String(),
      };

  factory TrialOffer.fromJson(Map<String, dynamic> json) => TrialOffer(
        id: json['id']?.toString() ?? '',
        kind: TrialKind.values.firstWhere(
          (value) => value.name == json['kind'],
          orElse: () => TrialKind.cavernFlight,
        ),
        appearedAt: DateTime.tryParse(json['appearedAt']?.toString() ?? '') ??
            DateTime.now(),
        specialEventKey: json['specialEventKey']?.toString(),
        startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? ''),
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
    this.expertiseRewards = const {},
  });

  final TrialGrade grade;
  final int coins;
  final int xp;
  final int statPoints;
  final ChestTier? chestTier;
  final MysticRelic? relic;
  final DragonEmoteDefinition? emote;
  final Map<TrainingFocus, int> expertiseRewards;
}

class TrialCompletion {
  const TrialCompletion({
    required this.kind,
    required this.score,
    required this.newDragonBest,
    required this.reward,
    this.simulated = false,
    this.testEvent = false,
  });

  final TrialKind kind;
  final int score;
  final bool newDragonBest;
  final TrialReward reward;
  final bool simulated;
  final bool testEvent;
}

TrialGrade trialGradeForScore(TrialKind kind, int score) {
  final thresholds = switch (kind) {
    TrialKind.cavernFlight => const [250, 600, 1100, 1700, 2500],
    TrialKind.ruinBreaker => const [900, 2250, 4000, 6750, 9000],
    TrialKind.runeweaver => const [3, 6, 9, 12, 15],
    TrialKind.witchlightWard ||
    TrialKind.hollyfrostGiftforge ||
    TrialKind.midnightChime ||
    TrialKind.rosevowRelay ||
    TrialKind.prismaticParade =>
      const [500, 1200, 2000, 3000, 4200],
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
