enum DragonSchoolGameKind {
  runeRush,
  crystalChase,
  emberReflex,
  sigilMemory,
  scaleOrder,
  shadowMatch,
  breathBalance,
  wingRhythm,
  safeHoard,
  starCompass,
}

class DragonSchoolGameDefinition {
  const DragonSchoolGameDefinition({
    required this.kind,
    required this.titleEn,
    required this.titleNl,
    required this.descriptionEn,
    required this.descriptionNl,
  });

  final DragonSchoolGameKind kind;
  final String titleEn;
  final String titleNl;
  final String descriptionEn;
  final String descriptionNl;

  String get id => kind.name;
}

const dragonSchoolGames = <DragonSchoolGameDefinition>[
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.runeRush,
    titleEn: 'Rune Rush',
    titleNl: 'Runenrace',
    descriptionEn: 'Tap the glowing rune as quickly as you can.',
    descriptionNl: 'Tik zo snel mogelijk op de gloeiende rune.',
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.crystalChase,
    titleEn: 'Crystal Chase',
    titleNl: 'Kristaljacht',
    descriptionEn: 'Catch the crystal as it jumps across the grid.',
    descriptionNl: 'Vang het kristal terwijl het over het raster springt.',
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.emberReflex,
    titleEn: 'Ember Reflex',
    titleNl: 'Sintelreflex',
    descriptionEn: 'Wait for the ember to ignite, then react.',
    descriptionNl: 'Wacht tot de sintel ontbrandt en reageer dan.',
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.sigilMemory,
    titleEn: 'Sigil Memory',
    titleNl: 'Sigilgeheugen',
    descriptionEn: 'Remember which sigil briefly revealed itself.',
    descriptionNl: 'Onthoud welk sigil zich kort liet zien.',
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.scaleOrder,
    titleEn: 'Scale Order',
    titleNl: 'Schubbenvolgorde',
    descriptionEn: 'Tap the numbered scales from low to high.',
    descriptionNl: 'Tik de genummerde schubben van laag naar hoog.',
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.shadowMatch,
    titleEn: 'Shadow Match',
    titleNl: 'Schaduwzoeker',
    descriptionEn: 'Find the one shadow that is different.',
    descriptionNl: 'Vind de ene schaduw die anders is.',
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.breathBalance,
    titleEn: 'Breath Balance',
    titleNl: 'Adembalans',
    descriptionEn: 'Stop the flame as close to its calm center as possible.',
    descriptionNl: 'Stop de vlam zo dicht mogelijk bij haar rustige midden.',
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.wingRhythm,
    titleEn: 'Wing Rhythm',
    titleNl: 'Vleugelritme',
    descriptionEn: 'Tap when the beat flies through the golden ring.',
    descriptionNl: 'Tik wanneer de maat door de gouden ring vliegt.',
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.safeHoard,
    titleEn: 'Safe Hoard',
    titleNl: 'Veilige schat',
    descriptionEn: 'Choose treasure while avoiding the cursed chest.',
    descriptionNl: 'Kies schatten en vermijd de vervloekte kist.',
  ),
  DragonSchoolGameDefinition(
    kind: DragonSchoolGameKind.starCompass,
    titleEn: 'Star Compass',
    titleNl: 'Sterrenkompas',
    descriptionEn: 'Stop the compass needle inside the marked constellation.',
    descriptionNl: 'Stop de kompasnaald in de gemarkeerde constellatie.',
  ),
];
