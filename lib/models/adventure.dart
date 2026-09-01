import 'chest.dart';
import 'mystic_relic.dart';
import 'pet.dart';

enum AdventureKind { mini, short, long, group, special }

enum AdventureRunStatus { running, rewardReady }

class AdventureChestChance {
  const AdventureChestChance(this.tier, this.probability);

  final ChestTier tier;
  final double probability;
}

const adventureChestChances = <AdventureKind, List<AdventureChestChance>>{
  AdventureKind.mini: [
    AdventureChestChance(ChestTier.wooden, 1),
  ],
  AdventureKind.short: [
    AdventureChestChance(ChestTier.wooden, .20),
    AdventureChestChance(ChestTier.silver, .40),
    AdventureChestChance(ChestTier.gold, .35),
    AdventureChestChance(ChestTier.dragon, .045),
    AdventureChestChance(ChestTier.mythical, .005),
  ],
  AdventureKind.long: [
    AdventureChestChance(ChestTier.gold, .75),
    AdventureChestChance(ChestTier.dragon, .23),
    AdventureChestChance(ChestTier.mythical, .02),
  ],
  AdventureKind.group: [
    AdventureChestChance(ChestTier.gold, .70),
    AdventureChestChance(ChestTier.dragon, .25),
    AdventureChestChance(ChestTier.mythical, .05),
  ],
  AdventureKind.special: [
    AdventureChestChance(ChestTier.gold, 1),
  ],
};

ChestTier adventureChestForRoll(AdventureKind kind, double roll) {
  final chances = adventureChestChances[kind]!;
  var cumulative = 0.0;
  for (final chance in chances) {
    cumulative += chance.probability;
    if (roll < cumulative) return chance.tier;
  }
  return chances.last.tier;
}

class AdventureRequirements {
  const AdventureRequirements({
    this.players = 1,
    this.combinedLevel = 0,
    this.focus,
    this.combinedStat = 0,
  });

  final int players;
  final int combinedLevel;
  final TrainingFocus? focus;
  final int combinedStat;
}

class AdventureDefinition {
  const AdventureDefinition({
    required this.id,
    required this.kind,
    required this.titleEn,
    required this.titleNl,
    required this.descriptionEn,
    required this.descriptionNl,
    required this.duration,
    required this.xp,
    required this.focus,
    required this.statPoints,
    this.requirements = const AdventureRequirements(),
    this.knownChest,
    this.sinister = false,
    this.combinedExpertise = false,
    this.seasonalSpecial = false,
  });

  final String id;
  final AdventureKind kind;
  final String titleEn;
  final String titleNl;
  final String descriptionEn;
  final String descriptionNl;
  final Duration duration;
  final int xp;
  final TrainingFocus focus;
  final int statPoints;
  final AdventureRequirements requirements;
  final ChestTier? knownChest;
  final bool sinister;
  final bool combinedExpertise;
  final bool seasonalSpecial;
}

Duration expertiseAdjustedAdventureDuration(
  AdventureDefinition adventure,
  Iterable<Pet> dragons,
) {
  final expertiseScores = dragons
      .map((dragon) => dragon.trainingFor(adventure.focus))
      .toList(growable: false);
  final singleDragonExpertise =
      expertiseScores.isEmpty ? 0 : expertiseScores.first;
  final averageGroupExpertise = expertiseScores.isEmpty
      ? 0
      : expertiseScores.reduce((first, second) => first + second) ~/
          expertiseScores.length;
  final combinedExpertise = dragons.isEmpty
      ? 0
      : dragons.first.trainingFor(TrainingFocus.might) +
          dragons.first.trainingFor(TrainingFocus.arcana) +
          dragons.first.trainingFor(TrainingFocus.spirit);
  final reduction = switch (adventure.kind) {
    AdventureKind.mini => Duration(seconds: singleDragonExpertise),
    AdventureKind.short => Duration(minutes: singleDragonExpertise),
    AdventureKind.long => Duration(hours: singleDragonExpertise),
    AdventureKind.group => Duration(hours: averageGroupExpertise),
    AdventureKind.special => adventure.combinedExpertise
        ? Duration(hours: combinedExpertise)
        : Duration.zero,
  };
  final minimum = switch (adventure.kind) {
    AdventureKind.mini => const Duration(minutes: 1),
    AdventureKind.short => const Duration(hours: 1),
    AdventureKind.long || AdventureKind.group => const Duration(days: 1),
    AdventureKind.special => adventure.combinedExpertise
        ? const Duration(days: 1)
        : adventure.duration,
  };
  final adjusted = adventure.duration - reduction;
  return adjusted < minimum ? minimum : adjusted;
}

class AdventureRun {
  const AdventureRun({
    required this.id,
    required this.adventureId,
    required this.dragonId,
    required this.startedAt,
    required this.endsAt,
    required this.status,
    this.rewardTier,
    this.participantCount = 1,
    this.specialEventId,
    this.specialEventKey,
  });

  final String id;
  final String adventureId;
  final String dragonId;
  final DateTime startedAt;
  final DateTime endsAt;
  final AdventureRunStatus status;
  final ChestTier? rewardTier;
  final int participantCount;
  final String? specialEventId;
  final String? specialEventKey;

  AdventureRun copyWith({
    AdventureRunStatus? status,
    ChestTier? rewardTier,
  }) =>
      AdventureRun(
        id: id,
        adventureId: adventureId,
        dragonId: dragonId,
        startedAt: startedAt,
        endsAt: endsAt,
        status: status ?? this.status,
        rewardTier: rewardTier ?? this.rewardTier,
        participantCount: participantCount,
        specialEventId: specialEventId,
        specialEventKey: specialEventKey,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'adventureId': adventureId,
        'dragonId': dragonId,
        'startedAt': startedAt.toIso8601String(),
        'endsAt': endsAt.toIso8601String(),
        'status': status.name,
        'rewardTier': rewardTier?.name,
        'participantCount': participantCount,
        'specialEventId': specialEventId,
        'specialEventKey': specialEventKey,
      };

  factory AdventureRun.fromJson(Map<String, dynamic> json) => AdventureRun(
        id: json['id'] as String? ?? '',
        adventureId: json['adventureId'] as String? ?? '',
        dragonId: json['dragonId'] as String? ?? '',
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
            DateTime.now(),
        endsAt: DateTime.tryParse(json['endsAt'] as String? ?? '') ??
            DateTime.now(),
        status: AdventureRunStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => AdventureRunStatus.running,
        ),
        rewardTier: ChestTier.values.cast<ChestTier?>().firstWhere(
              (value) => value?.name == json['rewardTier'],
              orElse: () => null,
            ),
        participantCount: (json['participantCount'] as num?)?.toInt() ?? 1,
        specialEventId: json['specialEventId'] as String?,
        specialEventKey: json['specialEventKey'] as String?,
      );
}

class SpecialAdventureRewardBundle {
  const SpecialAdventureRewardBundle({
    required this.chestTier,
    required this.xp,
    this.randomRelicPool = const [],
    this.musicChest = false,
    this.expertiseRewards = const {},
  });

  final ChestTier chestTier;
  final int xp;
  final List<MysticRelic> randomRelicPool;
  final bool musicChest;
  final Map<TrainingFocus, int> expertiseRewards;
}

class SpecialAdventureEventDefinition {
  const SpecialAdventureEventDefinition({
    required this.id,
    required this.adventureId,
    required this.initialYear,
    required this.initialMonth,
    required this.initialDay,
    required this.initialAvailability,
    required this.rewards,
    required this.storyEn,
    required this.storyNl,
    this.showStoryInDetails = true,
    this.initialHour = 0,
    this.recursYearlyFrom,
    this.recurrenceMonth,
    this.recurrenceDay,
    this.recurrenceHour = 0,
    this.recurrenceAvailability,
  });

  final String id;
  final String adventureId;
  final int initialYear;
  final int initialMonth;
  final int initialDay;
  final int initialHour;
  final Duration initialAvailability;
  final int? recursYearlyFrom;
  final int? recurrenceMonth;
  final int? recurrenceDay;
  final int recurrenceHour;
  final Duration? recurrenceAvailability;
  final SpecialAdventureRewardBundle rewards;
  final String storyEn;
  final String storyNl;
  final bool showStoryInDetails;
}

abstract final class AdventureCatalog {
  static const goldenWingsBirthday = AdventureDefinition(
    id: 'special_golden_wings_birthday',
    kind: AdventureKind.special,
    titleEn: 'A Wish on Golden Wings',
    titleNl: 'Een Wens op Gouden Vleugels',
    descriptionEn:
        'For the birthday of a beautiful woman whose kindness makes every day brighter, the Haven sends one golden wish into the sky.',
    descriptionNl:
        'Voor de verjaardag van een mooie vrouw wier warmte elke dag lichter maakt, stuurt de Haven één gouden wens de hemel in.',
    duration: Duration(days: 10),
    xp: 500,
    focus: TrainingFocus.might,
    statPoints: 0,
    knownChest: ChestTier.special,
    combinedExpertise: true,
    seasonalSpecial: true,
  );

  static const _placesEn = [
    'Cloud Orchard',
    'Whispering Ruins',
    'Moonlit Mere',
    'Ember Pass',
    'Crystal Hollow',
    'Silver Canopy',
    'Clockwork Glen',
    'Starfall Coast',
    'Mossbound Gate',
    'Sunken Archive',
    'Aurora Ridge',
    'Lantern Marsh',
    'Thunder Mesa',
    'Sapphire Grotto',
    'Dawnwind Vale',
    'Comet Garden',
    'Forgotten Belfry',
    'Dreaming Dunes',
    'Tidal Observatory',
    'Rune Market'
  ];
  static const _placesNl = [
    'Wolkenboomgaard',
    'Fluisterruïnes',
    'Maanlichtmeer',
    'Gloedpas',
    'Kristalholte',
    'Zilveren Kruinen',
    'Klokkenwoud',
    'Sterrenvalkust',
    'Mospoort',
    'Verzonken Archief',
    'Aurorarug',
    'Lantaarnmoeras',
    'Dondervlakte',
    'Saffiergrot',
    'Dageraadvallei',
    'Komeettuin',
    'Vergeten Klokkentoren',
    'Dromende Duinen',
    'Getijdenwacht',
    'Runenmarkt'
  ];
  static const _missionsEn = [
    'Map',
    'Scout',
    'Gather',
    'Escort',
    'Decode',
    'Restore',
    'Observe',
    'Deliver',
    'Search',
    'Survey',
    'Catalog',
    'Protect',
    'Trace',
    'Recover',
    'Study'
  ];
  static const _missionsNl = [
    'Breng in kaart',
    'Verken',
    'Verzamel in',
    'Begeleid door',
    'Ontcijfer bij',
    'Herstel',
    'Observeer',
    'Bezorg in',
    'Doorzoek',
    'Onderzoek',
    'Catalogiseer',
    'Bescherm',
    'Volg een spoor in',
    'Vind terug in',
    'Bestudeer'
  ];

  static final List<AdventureDefinition> mini = List.unmodifiable(
    List.generate(200, (index) {
      final minutes = 2 + index % 14;
      return AdventureDefinition(
        id: 'mini_${index + 1}',
        kind: AdventureKind.mini,
        titleEn:
            '${_missionsEn[index % _missionsEn.length]} near the ${_placesEn[(index * 11) % _placesEn.length]}',
        titleNl:
            '${_missionsNl[index % _missionsNl.length]} bij ${_placesNl[(index * 11) % _placesNl.length]}',
        descriptionEn: 'A tiny tower outing with a modest wooden reward.',
        descriptionNl:
            'Een klein torenuitstapje met een bescheiden houten beloning.',
        duration: Duration(minutes: minutes),
        xp: 4 + index % 8,
        focus: TrainingFocus.values[index % 3],
        statPoints: 1 + index % 2,
        knownChest: ChestTier.wooden,
      );
    }),
  );

  static final List<AdventureDefinition> short = List.unmodifiable(
    List.generate(300, (index) {
      final hours = (2 + index % 5).clamp(3, 6);
      return AdventureDefinition(
        id: 'short_${index + 1}',
        kind: AdventureKind.short,
        titleEn:
            '${_missionsEn[index % _missionsEn.length]} the ${_placesEn[index % _placesEn.length]}',
        titleNl:
            '${_missionsNl[index % _missionsNl.length]} ${_placesNl[index % _placesNl.length]}',
        descriptionEn: 'A focused expedition with one curious detour.',
        descriptionNl: 'Een gerichte expeditie met één nieuwsgierige omweg.',
        duration: Duration(hours: hours),
        xp: 35 + hours * 18 + index % 13,
        focus: TrainingFocus.values[index % 3],
        statPoints: 4 + hours + index % 3,
      );
    }),
  );

  static final List<AdventureDefinition> long = List.unmodifiable(
    List.generate(200, (index) {
      final days = 3 + index % 4;
      return AdventureDefinition(
        id: 'long_${index + 1}',
        kind: AdventureKind.long,
        titleEn: '${_placesEn[(index * 7) % _placesEn.length]} Expedition',
        titleNl: '${_placesNl[(index * 7) % _placesNl.length]}-expeditie',
        descriptionEn: 'A careful multi-day journey through changing skies.',
        descriptionNl:
            'Een zorgvuldige meerdaagse reis door veranderende hemels.',
        duration: Duration(days: days),
        xp: 260 + days * 150 + index % 41,
        focus: TrainingFocus.values[(index + 1) % 3],
        statPoints: 35 + days * 11 + index % 7,
      );
    }),
  );

  static final List<AdventureDefinition> group = List.unmodifiable(
    List.generate(200, (index) {
      final days = 3 + index % 4;
      final players = 2 + index % 3;
      final focus = TrainingFocus.values[(index + 2) % 3];
      return AdventureDefinition(
        id: 'group_${index + 1}',
        kind: AdventureKind.group,
        titleEn: 'Concord of ${_placesEn[(index * 3) % _placesEn.length]}',
        titleNl: 'Verbond van ${_placesNl[(index * 3) % _placesNl.length]}',
        descriptionEn: 'A cooperative discovery for $players dragon keepers.',
        descriptionNl:
            'Een gezamenlijke ontdekking voor $players drakenhoeders.',
        duration: Duration(days: days),
        xp: 360 + days * 175 + index % 59,
        focus: focus,
        statPoints: 52 + days * 13 + index % 9,
        requirements: AdventureRequirements(
          players: players,
          combinedLevel: index % 4 == 0 ? 8 + index % 20 : 0,
          focus: index % 3 == 0 ? focus : null,
          combinedStat: index % 3 == 0 ? 50 + index % 150 : 0,
        ),
      );
    }),
  );

  static final List<AdventureDefinition> special = List.unmodifiable(
    List.generate(100, (index) {
      final sinister = index >= 90;
      final hours = 8 + (index * 7) % 113;
      return AdventureDefinition(
        id: 'special_${index + 1}',
        kind: AdventureKind.special,
        titleEn: sinister ? 'The Crooked Shadow' : 'A Strange Invitation',
        titleNl: sinister ? 'De Kromme Schaduw' : 'Een Vreemde Uitnodiging',
        descriptionEn: sinister
            ? 'A released dragon left a dangerous-looking map. Following it is optional.'
            : 'A one-off trail with a fully known reward.',
        descriptionNl: sinister
            ? 'Een vrijgelaten draak liet een gevaarlijk ogende kaart achter. Volgen is optioneel.'
            : 'Een eenmalig spoor met een volledig bekende beloning.',
        duration: Duration(hours: hours),
        xp: 180 + hours * 5,
        focus: TrainingFocus.values[index % 3],
        statPoints: 25 + hours ~/ 4,
        knownChest: sinister ? ChestTier.sinister : ChestTier.values[index % 5],
        sinister: sinister,
      );
    }),
  );

  static final Map<String, AdventureDefinition> byId = Map.unmodifiable({
    for (final adventure in [
      ...mini,
      ...short,
      ...long,
      ...group,
      ...special,
      goldenWingsBirthday,
    ])
      adventure.id: adventure,
  });
}

const specialAdventureEventCatalog = <SpecialAdventureEventDefinition>[
  SpecialAdventureEventDefinition(
    id: 'golden_wings_birthday',
    adventureId: 'special_golden_wings_birthday',
    initialYear: 2026,
    initialMonth: DateTime.september,
    initialDay: 1,
    initialAvailability: Duration(days: 2),
    recursYearlyFrom: 2027,
    recurrenceMonth: DateTime.may,
    recurrenceDay: 13,
    recurrenceAvailability: Duration(days: 1),
    rewards: SpecialAdventureRewardBundle(
      chestTier: ChestTier.special,
      xp: 500,
      randomRelicPool: [
        MysticRelic.moralPrism,
        MysticRelic.orderCompass,
        MysticRelic.soulMirror,
        MysticRelic.astralLens,
      ],
      musicChest: true,
      expertiseRewards: {
        TrainingFocus.might: 25,
        TrainingFocus.spirit: 25,
        TrainingFocus.arcana: 25,
      },
    ),
    storyEn:
        'A golden birthday wish for a beautiful woman whose kindness brightens the Haven.',
    storyNl:
        'Een gouden verjaardagswens voor een mooie vrouw wier warmte de Haven laat stralen.',
    showStoryInDetails: false,
  ),
];

SpecialAdventureEventDefinition? specialAdventureEventById(String? id) {
  for (final event in specialAdventureEventCatalog) {
    if (event.id == id) return event;
  }
  return null;
}

SpecialAdventureEventDefinition? specialAdventureEventForAdventure(
  String adventureId,
) {
  for (final event in specialAdventureEventCatalog) {
    if (event.adventureId == adventureId) return event;
  }
  return null;
}
