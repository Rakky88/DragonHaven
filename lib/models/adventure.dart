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
    this.specialChestId,
    this.specialReductionPerExpertisePoint = Duration.zero,
    this.minimumDuration,
    this.requiredDragonCount = 1,
    this.requiresOnlinePartner = false,
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
  final String? specialChestId;
  final Duration specialReductionPerExpertisePoint;
  final Duration? minimumDuration;
  final int requiredDragonCount;
  final bool requiresOnlinePartner;
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
  final combinedExpertise = dragons.fold<int>(
    0,
    (total, dragon) =>
        total +
        dragon.trainingFor(TrainingFocus.might) +
        dragon.trainingFor(TrainingFocus.arcana) +
        dragon.trainingFor(TrainingFocus.spirit),
  );
  final reduction = switch (adventure.kind) {
    AdventureKind.mini => Duration(seconds: singleDragonExpertise),
    AdventureKind.short => Duration(minutes: singleDragonExpertise),
    AdventureKind.long => Duration(minutes: singleDragonExpertise * 15),
    AdventureKind.group => Duration(hours: averageGroupExpertise),
    AdventureKind.special => adventure.combinedExpertise
        ? adventure.specialReductionPerExpertisePoint * combinedExpertise
        : Duration.zero,
  };
  final minimum = switch (adventure.kind) {
    AdventureKind.mini => const Duration(minutes: 1),
    AdventureKind.short => const Duration(hours: 1),
    AdventureKind.long || AdventureKind.group => const Duration(days: 1),
    AdventureKind.special => adventure.minimumDuration ?? adventure.duration,
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
    this.specialChestId,
    this.accountTitleId,
    this.keeperBadgeId,
  });

  final ChestTier chestTier;
  final int xp;
  final List<MysticRelic> randomRelicPool;
  final bool musicChest;
  final Map<TrainingFocus, int> expertiseRewards;
  final String? specialChestId;
  final String? accountTitleId;
  final String? keeperBadgeId;
}

class SpecialEggDefinition {
  const SpecialEggDefinition({
    required this.id,
    required this.version,
    required this.titleEn,
    required this.titleNl,
    required this.lineageId,
    required this.incubation,
    required this.assetPath,
    this.fixedMoral,
    this.moralKnownAtHatch = false,
    this.normalSpectralChance = .05,
    this.goldenHourSpectralChance = .10,
  });

  final String id;
  final int version;
  final String titleEn;
  final String titleNl;
  final String lineageId;
  final Duration incubation;
  final String assetPath;
  final MoralAxis? fixedMoral;
  final bool moralKnownAtHatch;
  final double normalSpectralChance;
  final double goldenHourSpectralChance;
}

class SpecialChestDefinition {
  const SpecialChestDefinition({
    required this.id,
    required this.version,
    required this.titleEn,
    required this.titleNl,
    required this.closedAssetPath,
    required this.openedAssetPath,
    required this.coins,
    required this.gems,
    required this.specialEggId,
    required this.openSoundId,
  });

  final String id;
  final int version;
  final String titleEn;
  final String titleNl;
  final String closedAssetPath;
  final String openedAssetPath;
  final int coins;
  final int gems;
  final String specialEggId;
  final String openSoundId;
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
    required this.titleEn,
    required this.titleNl,
    required this.trialKindName,
    required this.previewCode,
    required this.previewHours,
    required this.temporaryMusicTrackId,
    this.previewOwnerKeeperId = 'DH-17792DC5',
    this.previewRewardsSimulatedInProduction = true,
    this.rankingVisibleAfterEvent = const Duration(days: 5),
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
  final String titleEn;
  final String titleNl;
  final String trialKindName;
  final String previewCode;
  final int previewHours;
  final String temporaryMusicTrackId;
  final String? previewOwnerKeeperId;
  final bool previewRewardsSimulatedInProduction;
  final Duration rankingVisibleAfterEvent;
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
    specialChestId: 'golden_wings_chest_v1',
    combinedExpertise: true,
    seasonalSpecial: true,
    specialReductionPerExpertisePoint: Duration(hours: 1),
    minimumDuration: Duration(days: 1),
  );

  static const halloweenWitchlight = AdventureDefinition(
    id: 'special_halloween_witchlight',
    kind: AdventureKind.special,
    titleEn: 'Roots Beneath the Lanterns',
    titleNl: 'Wortels Onder de Lantaarns',
    descriptionEn:
        'Follow Gloamgourd through a lantern-lit grove and mend the ancient ward before the last witchlight fades.',
    descriptionNl:
        'Volg Gloamgourd door een lantaarnverlicht woud en herstel de oude bescherming voordat het laatste heksenlicht dooft.',
    duration: Duration(hours: 72),
    xp: 500,
    focus: TrainingFocus.arcana,
    statPoints: 0,
    knownChest: ChestTier.special,
    specialChestId: 'witchlight_chest_v1',
    combinedExpertise: true,
    seasonalSpecial: true,
    specialReductionPerExpertisePoint: Duration(minutes: 15),
    minimumDuration: Duration(hours: 24),
  );

  static const christmasWinterHearth = AdventureDefinition(
    id: 'special_christmas_winter_hearth',
    kind: AdventureKind.special,
    titleEn: 'The Starlight Sleigh',
    titleNl: 'De Sterrenlichtslee',
    descriptionEn:
        'Help Hollyfrost restore a lost starlight sleigh and carry warmth back to every winter hearth.',
    descriptionNl:
        'Help Hollyfrost een verloren sterrenlichtslee te herstellen en warmte terug te brengen naar elke winterhaard.',
    duration: Duration(hours: 96),
    xp: 600,
    focus: TrainingFocus.spirit,
    statPoints: 0,
    knownChest: ChestTier.special,
    specialChestId: 'starlight_gift_chest_v1',
    combinedExpertise: true,
    seasonalSpecial: true,
    specialReductionPerExpertisePoint: Duration(minutes: 15),
    minimumDuration: Duration(hours: 24),
  );

  static const newYearFirstDawn = AdventureDefinition(
    id: 'special_new_year_first_dawn',
    kind: AdventureKind.special,
    titleEn: 'The Bell Beyond Midnight',
    titleNl: 'De Klok Voorbij Middernacht',
    descriptionEn:
        'Guide Dawnchime beyond midnight and awaken the first bell of a hopeful new year.',
    descriptionNl:
        'Begeleid Dawnchime voorbij middernacht en wek de eerste klok van een hoopvol nieuw jaar.',
    duration: Duration(hours: 72),
    xp: 700,
    focus: TrainingFocus.arcana,
    statPoints: 0,
    knownChest: ChestTier.special,
    specialChestId: 'firstlight_celebration_chest_v1',
    combinedExpertise: true,
    seasonalSpecial: true,
    specialReductionPerExpertisePoint: Duration(minutes: 15),
    minimumDuration: Duration(hours: 24),
  );

  static const valentineTwoHeartlights = AdventureDefinition(
    id: 'special_valentine_two_heartlights',
    kind: AdventureKind.special,
    titleEn: 'The Rosebound Crossing',
    titleNl: 'De Rozenverbonden Oversteek',
    descriptionEn:
        'Two Keepers and two dragons cross a rosebound skybridge whose light only answers a shared promise.',
    descriptionNl:
        'Twee Hoeders en twee draken steken een rozenbrug over waarvan het licht alleen antwoordt op een gedeelde belofte.',
    duration: Duration(hours: 96),
    xp: 650,
    focus: TrainingFocus.spirit,
    statPoints: 0,
    requirements: AdventureRequirements(players: 2),
    knownChest: ChestTier.special,
    specialChestId: 'twinheart_keepsake_chest_v1',
    combinedExpertise: true,
    seasonalSpecial: true,
    specialReductionPerExpertisePoint: Duration(minutes: 15),
    minimumDuration: Duration(hours: 24),
    requiredDragonCount: 2,
    requiresOnlinePartner: true,
  );

  static const prideEveryColor = AdventureDefinition(
    id: 'special_pride_every_color',
    kind: AdventureKind.special,
    titleEn: 'The Aurora We Weave',
    titleNl: 'De Aurora Die Wij Weven',
    descriptionEn:
        'Weave every honest color into the Haven sky and help Spectrumplume make room for every Keeper to shine.',
    descriptionNl:
        'Weef elke oprechte kleur door de hemel van de Haven en help Spectrumplume ruimte te maken voor iedere Hoeder om te stralen.',
    duration: Duration(hours: 84),
    xp: 700,
    focus: TrainingFocus.spirit,
    statPoints: 0,
    knownChest: ChestTier.special,
    specialChestId: 'radiant_festival_chest_v1',
    combinedExpertise: true,
    seasonalSpecial: true,
    specialReductionPerExpertisePoint: Duration(minutes: 15),
    minimumDuration: Duration(hours: 24),
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
      halloweenWitchlight,
      christmasWinterHearth,
      newYearFirstDawn,
      valentineTwoHeartlights,
      prideEveryColor,
    ])
      adventure.id: adventure,
  });
}

const specialEggCatalog = <String, SpecialEggDefinition>{
  'golden_wings_egg_v1': SpecialEggDefinition(
    id: 'golden_wings_egg_v1',
    version: 1,
    titleEn: 'Golden Wings Special Egg',
    titleNl: 'Gouden Vleugels Speciaal Ei',
    lineageId: 'cluckatrice',
    incubation: Duration(hours: 21),
    assetPath: 'assets/images/ui/ui_special_egg.webp',
  ),
  'witchlight_egg_v1': SpecialEggDefinition(
    id: 'witchlight_egg_v1',
    version: 1,
    titleEn: 'Witchlight Egg',
    titleNl: 'Heksenlicht-ei',
    lineageId: 'gloamgourd',
    incubation: Duration(hours: 13, minutes: 13, seconds: 13),
    assetPath: 'assets/images/events/halloween/witchlight_egg.webp',
  ),
  'starlit_evergreen_egg_v1': SpecialEggDefinition(
    id: 'starlit_evergreen_egg_v1',
    version: 1,
    titleEn: 'Starlit Evergreen Egg',
    titleNl: 'Sterrenlicht-dennenei',
    lineageId: 'hollyfrost',
    incubation: Duration(hours: 25),
    assetPath: 'assets/images/events/christmas/starlit_evergreen_egg.webp',
    fixedMoral: MoralAxis.good,
    moralKnownAtHatch: true,
  ),
  'turning_year_egg_v1': SpecialEggDefinition(
    id: 'turning_year_egg_v1',
    version: 1,
    titleEn: 'Turning-Year Egg',
    titleNl: 'Jaarwende-ei',
    lineageId: 'dawnchime',
    incubation: Duration(hours: 24),
    assetPath: 'assets/images/events/new_year/turning_year_egg.webp',
    fixedMoral: MoralAxis.neutral,
    moralKnownAtHatch: true,
  ),
  'rosebound_egg_v1': SpecialEggDefinition(
    id: 'rosebound_egg_v1',
    version: 1,
    titleEn: 'Rosebound Egg',
    titleNl: 'Rozenverbonden Ei',
    lineageId: 'rosevow',
    incubation: Duration(hours: 14),
    assetPath: 'assets/images/events/valentine/rosebound_egg.webp',
    fixedMoral: MoralAxis.good,
    moralKnownAtHatch: true,
  ),
  'truecolor_egg_v1': SpecialEggDefinition(
    id: 'truecolor_egg_v1',
    version: 1,
    titleEn: 'Truecolor Egg',
    titleNl: 'Ware-Kleuren-ei',
    lineageId: 'spectrumplume',
    incubation: Duration(hours: 18),
    assetPath: 'assets/images/events/pride/truecolor_egg.webp',
    fixedMoral: MoralAxis.good,
    moralKnownAtHatch: true,
  ),
};

const specialChestCatalog = <String, SpecialChestDefinition>{
  'golden_wings_chest_v1': SpecialChestDefinition(
    id: 'golden_wings_chest_v1',
    version: 1,
    titleEn: 'Golden Wings Chest',
    titleNl: 'Gouden Vleugels-kist',
    closedAssetPath: 'assets/images/chests/chest_special.webp',
    openedAssetPath: 'assets/images/chests/open/chest_special_open.webp',
    coins: 269,
    gems: 10,
    specialEggId: 'golden_wings_egg_v1',
    openSoundId: 'golden_wings',
  ),
  'witchlight_chest_v1': SpecialChestDefinition(
    id: 'witchlight_chest_v1',
    version: 1,
    titleEn: 'Witchlight Chest',
    titleNl: 'Heksenlichtkist',
    closedAssetPath: 'assets/images/events/halloween/witchlight_chest.webp',
    openedAssetPath:
        'assets/images/events/halloween/witchlight_chest_open.webp',
    coins: 313,
    gems: 13,
    specialEggId: 'witchlight_egg_v1',
    openSoundId: 'witchlight',
  ),
  'starlight_gift_chest_v1': SpecialChestDefinition(
    id: 'starlight_gift_chest_v1',
    version: 1,
    titleEn: 'Starlight Gift Chest',
    titleNl: 'Sterrenlichtgeschenkkist',
    closedAssetPath: 'assets/images/events/christmas/starlight_chest.webp',
    openedAssetPath: 'assets/images/events/christmas/starlight_chest_open.webp',
    coins: 250,
    gems: 12,
    specialEggId: 'starlit_evergreen_egg_v1',
    openSoundId: 'starlight',
  ),
  'firstlight_celebration_chest_v1': SpecialChestDefinition(
    id: 'firstlight_celebration_chest_v1',
    version: 1,
    titleEn: 'Firstlight Celebration Chest',
    titleNl: 'Eerstelicht-feestkist',
    closedAssetPath: 'assets/images/events/new_year/firstlight_chest.webp',
    openedAssetPath: 'assets/images/events/new_year/firstlight_chest_open.webp',
    coins: 365,
    gems: 12,
    specialEggId: 'turning_year_egg_v1',
    openSoundId: 'firstlight',
  ),
  'twinheart_keepsake_chest_v1': SpecialChestDefinition(
    id: 'twinheart_keepsake_chest_v1',
    version: 1,
    titleEn: 'Twinheart Keepsake Chest',
    titleNl: 'Tweeharten-aandenkenkist',
    closedAssetPath: 'assets/images/events/valentine/twinheart_chest.webp',
    openedAssetPath: 'assets/images/events/valentine/twinheart_chest_open.webp',
    coins: 214,
    gems: 14,
    specialEggId: 'rosebound_egg_v1',
    openSoundId: 'twinheart',
  ),
  'radiant_festival_chest_v1': SpecialChestDefinition(
    id: 'radiant_festival_chest_v1',
    version: 1,
    titleEn: 'Radiant Festival Chest',
    titleNl: 'Stralend Festival-kist',
    closedAssetPath: 'assets/images/events/pride/radiant_chest.webp',
    openedAssetPath: 'assets/images/events/pride/radiant_chest_open.webp',
    coins: 300,
    gems: 15,
    specialEggId: 'truecolor_egg_v1',
    openSoundId: 'radiant',
  ),
};

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
      specialChestId: 'golden_wings_chest_v1',
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
    titleEn: 'A Wish on Golden Wings',
    titleNl: 'Een Wens op Gouden Vleugels',
    trialKindName: '',
    previewCode: '',
    previewHours: 0,
    temporaryMusicTrackId: '',
  ),
  SpecialAdventureEventDefinition(
    id: 'halloween_witchlight',
    adventureId: 'special_halloween_witchlight',
    initialYear: 2026,
    initialMonth: DateTime.october,
    initialDay: 25,
    initialAvailability: Duration(days: 8),
    recursYearlyFrom: 2027,
    recurrenceMonth: DateTime.october,
    recurrenceDay: 25,
    recurrenceAvailability: Duration(days: 8),
    rewards: SpecialAdventureRewardBundle(
      chestTier: ChestTier.special,
      specialChestId: 'witchlight_chest_v1',
      xp: 500,
      expertiseRewards: {
        TrainingFocus.might: 13,
        TrainingFocus.spirit: 13,
        TrainingFocus.arcana: 13,
      },
    ),
    titleEn: 'Night of the Witchlight',
    titleNl: 'Nacht van het Heksenlicht',
    storyEn:
        'Once each autumn, friendly witchlights guide brave dragons to mend the ward beneath the oldest lantern grove.',
    storyNl:
        'Elke herfst leiden vriendelijke heksenlichten moedige draken naar de bescherming onder het oudste lantaarnwoud.',
    trialKindName: 'witchlightWard',
    previewCode: 'HALLOWEENEVENT',
    previewHours: 48,
    previewOwnerKeeperId: null,
    temporaryMusicTrackId: 'event_witchlight_nocturne',
  ),
  SpecialAdventureEventDefinition(
    id: 'christmas_winter_hearth',
    adventureId: 'special_christmas_winter_hearth',
    initialYear: 2026,
    initialMonth: DateTime.december,
    initialDay: 25,
    initialAvailability: Duration(days: 2),
    recursYearlyFrom: 2027,
    recurrenceMonth: DateTime.december,
    recurrenceDay: 25,
    recurrenceAvailability: Duration(days: 2),
    rewards: SpecialAdventureRewardBundle(
      chestTier: ChestTier.special,
      specialChestId: 'starlight_gift_chest_v1',
      xp: 600,
      expertiseRewards: {
        TrainingFocus.might: 12,
        TrainingFocus.spirit: 12,
        TrainingFocus.arcana: 12,
      },
    ),
    titleEn: 'A Star for the Winter Hearth',
    titleNl: 'Een Ster voor de Winterhaard',
    storyEn:
        'A lost starlight sleigh needs one brave dragon to carry its warmth back to every winter hearth.',
    storyNl:
        'Een verloren sterrenlichtslee heeft één dappere draak nodig om warmte naar elke winterhaard terug te brengen.',
    trialKindName: 'hollyfrostGiftforge',
    previewCode: 'CHRISTMASEVENT',
    previewHours: 48,
    temporaryMusicTrackId: 'event_winter_hearth_carol',
  ),
  SpecialAdventureEventDefinition(
    id: 'new_year_first_dawn',
    adventureId: 'special_new_year_first_dawn',
    initialYear: 2026,
    initialMonth: DateTime.december,
    initialDay: 31,
    initialHour: 18,
    initialAvailability: Duration(hours: 30),
    recursYearlyFrom: 2027,
    recurrenceMonth: DateTime.december,
    recurrenceDay: 31,
    recurrenceHour: 18,
    recurrenceAvailability: Duration(hours: 30),
    rewards: SpecialAdventureRewardBundle(
      chestTier: ChestTier.special,
      specialChestId: 'firstlight_celebration_chest_v1',
      xp: 700,
      expertiseRewards: {
        TrainingFocus.might: 10,
        TrainingFocus.spirit: 10,
        TrainingFocus.arcana: 10,
      },
    ),
    titleEn: 'When the New Dawn Rings',
    titleNl: 'Wanneer de Nieuwe Dageraad Klinkt',
    storyEn:
        'Beyond midnight, Dawnchime searches for the bell whose first note welcomes every hopeful beginning.',
    storyNl:
        'Voorbij middernacht zoekt Dawnchime de klok waarvan de eerste toon elk hoopvol begin verwelkomt.',
    trialKindName: 'midnightChime',
    previewCode: 'NEWYEARSEVENT',
    previewHours: 48,
    temporaryMusicTrackId: 'event_first_dawn_waltz',
  ),
  SpecialAdventureEventDefinition(
    id: 'valentine_two_heartlights',
    adventureId: 'special_valentine_two_heartlights',
    initialYear: 2027,
    initialMonth: DateTime.february,
    initialDay: 14,
    initialAvailability: Duration(days: 1),
    recursYearlyFrom: 2028,
    recurrenceMonth: DateTime.february,
    recurrenceDay: 14,
    recurrenceAvailability: Duration(days: 1),
    rewards: SpecialAdventureRewardBundle(
      chestTier: ChestTier.special,
      specialChestId: 'twinheart_keepsake_chest_v1',
      xp: 650,
      keeperBadgeId: 'heartbound_pair',
      expertiseRewards: {
        TrainingFocus.might: 8,
        TrainingFocus.spirit: 8,
        TrainingFocus.arcana: 8,
      },
    ),
    titleEn: 'Where Two Heartlights Meet',
    titleNl: 'Waar Twee Hartlichten Samenkomen',
    storyEn:
        'A rosebound crossing appears for one day, but its path only shines when two Keepers choose to cross together.',
    storyNl:
        'Eén dag lang verschijnt een rozenbrug, maar haar pad straalt alleen wanneer twee Hoeders samen oversteken.',
    trialKindName: 'rosevowRelay',
    previewCode: 'VALENTINEEVENT',
    previewHours: 48,
    temporaryMusicTrackId: 'event_rosebound_romance',
  ),
  SpecialAdventureEventDefinition(
    id: 'pride_every_color',
    adventureId: 'special_pride_every_color',
    initialYear: 2027,
    initialMonth: DateTime.june,
    initialDay: 1,
    initialAvailability: Duration(days: 7),
    recursYearlyFrom: 2028,
    recurrenceMonth: DateTime.june,
    recurrenceDay: 1,
    recurrenceAvailability: Duration(days: 7),
    rewards: SpecialAdventureRewardBundle(
      chestTier: ChestTier.special,
      specialChestId: 'radiant_festival_chest_v1',
      xp: 700,
      accountTitleId: 'true_colors',
      expertiseRewards: {
        TrainingFocus.might: 10,
        TrainingFocus.spirit: 10,
        TrainingFocus.arcana: 10,
      },
    ),
    titleEn: 'The Haven of Every Color',
    titleNl: 'De Haven van Elke Kleur',
    storyEn:
        'Every honest color belongs in the Haven sky; together they become an aurora bright enough for everyone.',
    storyNl:
        'Elke oprechte kleur hoort in de hemel van de Haven; samen vormen ze een aurora die helder genoeg is voor iedereen.',
    trialKindName: 'prismaticParade',
    previewCode: 'PRIDEFESTEVENT',
    previewHours: 48,
    temporaryMusicTrackId: 'event_every_color_festival',
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

SpecialChestDefinition? specialChestById(String? id) =>
    id == null ? null : specialChestCatalog[id];

SpecialEggDefinition? specialEggById(String? id) =>
    id == null ? null : specialEggCatalog[id];

SpecialEggDefinition? specialEggForLineage(String lineageId) {
  for (final definition in specialEggCatalog.values) {
    if (definition.lineageId == lineageId) return definition;
  }
  return null;
}
