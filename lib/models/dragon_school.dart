import 'pet.dart';

const int dragonSchoolMaximumAcademyScore = 1200;

extension DragonSchoolOutcomePresentation on DragonSchoolOutcome {
  String get titleEn => switch (this) {
        DragonSchoolOutcome.inTraining => 'Student',
        DragonSchoolOutcome.dropout => 'Dragon Academy Dropout',
        DragonSchoolOutcome.graduate => 'Graduate',
        DragonSchoolOutcome.honorsGraduate => 'Honors Graduate',
        DragonSchoolOutcome.highHonors => 'High Honors',
        DragonSchoolOutcome.valedictorian => 'Valedictorian',
      };

  String get titleNl => switch (this) {
        DragonSchoolOutcome.inTraining => 'Leerling',
        DragonSchoolOutcome.dropout => 'Drakenacademie-uitvaller',
        DragonSchoolOutcome.graduate => 'Afgestudeerd',
        DragonSchoolOutcome.honorsGraduate => 'Met onderscheiding',
        DragonSchoolOutcome.highHonors => 'Met grote onderscheiding',
        DragonSchoolOutcome.valedictorian => 'Lichtingsbeste',
      };

  String get badgeAsset => switch (this) {
        DragonSchoolOutcome.dropout =>
          'assets/images/ui/dragon_school/school_dropout.png',
        DragonSchoolOutcome.valedictorian =>
          'assets/images/ui/dragon_school/school_valedictorian.png',
        DragonSchoolOutcome.inTraining ||
        DragonSchoolOutcome.graduate ||
        DragonSchoolOutcome.honorsGraduate ||
        DragonSchoolOutcome.highHonors =>
          'assets/images/ui/dragon_school/school_graduate.png',
      };
}

enum DragonSchoolGameKind {
  runeRush,
  crystalChase,
  emberReflex,
  sigilMemory,
  scaleOrder,
  shadowMatch,
  breathBalance,
  cloudWeave,
  safeHoard,
  constellationTrace,
}

class DragonSchoolGameDefinition {
  const DragonSchoolGameDefinition({
    required this.kind,
    required this.titleEn,
    required this.titleNl,
    required this.descriptionEn,
    required this.descriptionNl,
    required this.bronzeScore,
    required this.silverScore,
    required this.goldScore,
    required this.iconAsset,
    this.focus,
    this.minimumDragons = 1,
    this.maximumDragons = 1,
  });

  final DragonSchoolGameKind kind;
  final String titleEn;
  final String titleNl;
  final String descriptionEn;
  final String descriptionNl;
  final int bronzeScore;
  final int silverScore;
  final int goldScore;
  final String iconAsset;
  final TrainingFocus? focus;
  final int minimumDragons;
  final int maximumDragons;

  String get id => kind.name;
  String get backgroundAsset => '$_schoolAssetRoot/background_${switch (kind) {
        DragonSchoolGameKind.runeRush => 'rune_rush',
        DragonSchoolGameKind.crystalChase => 'crystal_chase',
        DragonSchoolGameKind.emberReflex => 'ember_reflex',
        DragonSchoolGameKind.sigilMemory => 'sigil_memory',
        DragonSchoolGameKind.scaleOrder => 'scale_order',
        DragonSchoolGameKind.shadowMatch => 'shadow_match',
        DragonSchoolGameKind.breathBalance => 'breath_balance',
        DragonSchoolGameKind.cloudWeave => 'cloud_weave',
        DragonSchoolGameKind.safeHoard => 'safe_hoard',
        DragonSchoolGameKind.constellationTrace => 'constellation_trace',
      }}.jpg';
  bool get isTeamLesson => maximumDragons > 1;
  bool get isMasteryLesson => focus == null;

  int starsForScore(int score) {
    if (score >= goldScore) return 3;
    if (score >= silverScore) return 2;
    if (score >= bronzeScore) return 1;
    return 0;
  }
}

class DragonSchoolLessonResult {
  const DragonSchoolLessonResult({
    required this.accepted,
    required this.keeperBestImproved,
    this.newStarsByDragon = const {},
    this.xpByDragon = const {},
    this.graduatedDragonIds = const {},
    this.finalizedDragonIds = const {},
    this.attemptsByDragon = const {},
  });

  final bool accepted;
  final bool keeperBestImproved;
  final Map<String, int> newStarsByDragon;
  final Map<String, int> xpByDragon;
  final Set<String> graduatedDragonIds;
  final Set<String> finalizedDragonIds;
  final Map<String, int> attemptsByDragon;

  int get totalNewStars =>
      newStarsByDragon.values.fold(0, (total, stars) => total + stars);
}

const _schoolAssetRoot = 'assets/images/ui/dragon_school';

const dragonSchoolGames = <DragonSchoolGameDefinition>[
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.runeRush,
    titleEn: 'Rune Rush',
    titleNl: 'Runenrace',
    descriptionEn: 'Tap the glowing rune as quickly as you can.',
    descriptionNl: 'Tik zo snel mogelijk op de gloeiende rune.',
    bronzeScore: 8,
    silverScore: 16,
    goldScore: 25,
    iconAsset: '$_schoolAssetRoot/game_rune_rush.png',
    focus: TrainingFocus.arcana,
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.crystalChase,
    titleEn: 'Crystal Chase',
    titleNl: 'Kristaljacht',
    descriptionEn: 'Catch the crystal as it jumps across the grid.',
    descriptionNl: 'Vang het kristal terwijl het over het raster springt.',
    bronzeScore: 6,
    silverScore: 12,
    goldScore: 18,
    iconAsset: '$_schoolAssetRoot/game_crystal_chase.png',
    focus: TrainingFocus.might,
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.emberReflex,
    titleEn: 'Ember Reflex',
    titleNl: 'Sintelreflex',
    descriptionEn: 'Wait for the ember to ignite, then react.',
    descriptionNl: 'Wacht tot de sintel ontbrandt en reageer dan.',
    bronzeScore: 4,
    silverScore: 8,
    goldScore: 12,
    iconAsset: '$_schoolAssetRoot/game_ember_reflex.png',
    focus: TrainingFocus.might,
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.sigilMemory,
    titleEn: 'Sigil Memory',
    titleNl: 'Sigilgeheugen',
    descriptionEn: 'Remember which sigil briefly revealed itself.',
    descriptionNl: 'Onthoud welk sigil zich kort liet zien.',
    bronzeScore: 4,
    silverScore: 8,
    goldScore: 12,
    iconAsset: '$_schoolAssetRoot/game_sigil_memory.png',
    focus: TrainingFocus.arcana,
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.scaleOrder,
    titleEn: 'Scale Order',
    titleNl: 'Schubbenvolgorde',
    descriptionEn: 'Tap the numbered scales from low to high.',
    descriptionNl: 'Tik de genummerde schubben van laag naar hoog.',
    bronzeScore: 6,
    silverScore: 12,
    goldScore: 18,
    iconAsset: '$_schoolAssetRoot/game_scale_order.png',
    focus: TrainingFocus.arcana,
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.shadowMatch,
    titleEn: 'Shadow Match',
    titleNl: 'Schaduwzoeker',
    descriptionEn: 'Find the one shadow that is different.',
    descriptionNl: 'Vind de ene schaduw die anders is.',
    bronzeScore: 4,
    silverScore: 8,
    goldScore: 12,
    iconAsset: '$_schoolAssetRoot/game_shadow_match.png',
    focus: TrainingFocus.spirit,
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.breathBalance,
    titleEn: 'Breath Balance',
    titleNl: 'Adembalans',
    descriptionEn: 'Stop the opposing breaths in their calm center.',
    descriptionNl: 'Stop de tegengestelde ademstromen in hun rustige midden.',
    bronzeScore: 4,
    silverScore: 8,
    goldScore: 12,
    iconAsset: '$_schoolAssetRoot/game_breath_balance.png',
    focus: TrainingFocus.spirit,
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.cloudWeave,
    titleEn: 'Cloud Weave',
    titleNl: 'Wolkenweefsel',
    descriptionEn: 'Guide two dragons through matching cloud gates.',
    descriptionNl: 'Leid twee draken door passende wolkenpoorten.',
    bronzeScore: 6,
    silverScore: 12,
    goldScore: 18,
    iconAsset: '$_schoolAssetRoot/game_cloud_weave.png',
    focus: TrainingFocus.spirit,
    minimumDragons: 2,
    maximumDragons: 2,
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.safeHoard,
    titleEn: 'Safe Hoard',
    titleNl: 'Veilige schat',
    descriptionEn: 'Secure treasure together while avoiding cursed chests.',
    descriptionNl: 'Stel samen schatten veilig en vermijd vervloekte kisten.',
    bronzeScore: 5,
    silverScore: 10,
    goldScore: 15,
    iconAsset: '$_schoolAssetRoot/game_safe_hoard.png',
    focus: TrainingFocus.might,
    minimumDragons: 2,
    maximumDragons: 2,
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.constellationTrace,
    titleEn: 'Constellation Trace',
    titleNl: 'Constellatiespoor',
    descriptionEn: 'Trace a changing star path with up to three dragons.',
    descriptionNl: 'Trek met maximaal drie draken een wisselend sterrenpad.',
    bronzeScore: 6,
    silverScore: 12,
    goldScore: 18,
    iconAsset: '$_schoolAssetRoot/game_constellation_trace.png',
    minimumDragons: 1,
    maximumDragons: 3,
  ),
];

DragonSchoolGameDefinition? dragonSchoolGameById(String id) {
  for (final game in dragonSchoolGames) {
    if (game.id == id) return game;
  }
  return null;
}

/// A normalized ranking score keeps games with very different raw score
/// ranges comparable. Gold is worth 100 points per lesson; exceptional play
/// can add up to 20 bonus points, for a maximum of 1,200 across ten lessons.
int dragonSchoolAcademyScore(Pet dragon) {
  var total = 0.0;
  for (final game in dragonSchoolGames) {
    final normalized =
        (dragon.schoolBest(game.id) / game.goldScore).clamp(0.0, 1.2);
    total += normalized * 100;
  }
  return total.round().clamp(0, dragonSchoolMaximumAcademyScore);
}
