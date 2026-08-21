import 'pet.dart';

class SanctuaryActivity {
  const SanctuaryActivity({
    required this.id,
    required this.nameEn,
    required this.nameNl,
    required this.descriptionEn,
    required this.descriptionNl,
    required this.xp,
    required this.coins,
    required this.dailyUses,
    this.trainingFocus,
    this.trainingPoints = 0,
    this.chestChance = 0,
    this.gemChance = 0,
  });

  final String id;
  final String nameEn;
  final String nameNl;
  final String descriptionEn;
  final String descriptionNl;
  final int xp;
  final int coins;
  final int dailyUses;
  final TrainingFocus? trainingFocus;
  final int trainingPoints;
  final double chestChance;
  final double gemChance;
}

const sanctuaryActivities = <SanctuaryActivity>[
  SanctuaryActivity(
      id: 'nest_tending',
      nameEn: 'Nest tending',
      nameNl: 'Nest verzorgen',
      descriptionEn: 'Warm the blankets, listen closely and check the shell.',
      descriptionNl: 'Warm de dekens, luister goed en controleer de schaal.',
      xp: 24,
      coins: 5,
      dailyUses: 1,
      trainingFocus: TrainingFocus.spirit,
      trainingPoints: 8),
  SanctuaryActivity(
      id: 'cliff_course',
      nameEn: 'Cliff course',
      nameNl: 'Klifparcours',
      descriptionEn: 'Climb, glide and learn where every paw should land.',
      descriptionNl: 'Klim, zweef en leer waar elke poot veilig landt.',
      xp: 42,
      coins: 8,
      dailyUses: 2,
      trainingFocus: TrainingFocus.might,
      trainingPoints: 18,
      chestChance: 0.12),
  SanctuaryActivity(
      id: 'rune_observatory',
      nameEn: 'Rune observatory',
      nameNl: 'Runenobservatorium',
      descriptionEn: 'Study the old constellations and one mildly rude rune.',
      descriptionNl:
          'Bestudeer oude sterrenbeelden en één ietwat brutale rune.',
      xp: 42,
      coins: 6,
      dailyUses: 2,
      trainingFocus: TrainingFocus.arcana,
      trainingPoints: 18,
      gemChance: 0.12),
  SanctuaryActivity(
      id: 'cloud_walk',
      nameEn: 'Cloud walk',
      nameNl: 'Wolkenwandeling',
      descriptionEn:
          'A quiet trip around the Spire with no destination needed.',
      descriptionNl: 'Een rustig rondje om de Spire, zonder bestemming.',
      xp: 38,
      coins: 10,
      dailyUses: 2,
      trainingFocus: TrainingFocus.spirit,
      trainingPoints: 18),
  SanctuaryActivity(
      id: 'spire_expedition',
      nameEn: 'Spire expedition',
      nameNl: 'Spire-expeditie',
      descriptionEn: 'Search forgotten balconies for a guaranteed cache.',
      descriptionNl: 'Doorzoek vergeten balkons voor een gegarandeerde kist.',
      xp: 65,
      coins: 12,
      dailyUses: 1,
      chestChance: 1),
  SanctuaryActivity(
      id: 'starlight_forage',
      nameEn: 'Starlight forage',
      nameNl: 'Sterlicht zoeken',
      descriptionEn: 'Collect useful glitter before it becomes regular dust.',
      descriptionNl:
          'Verzamel nuttige glinsters voordat het gewoon stof wordt.',
      xp: 20,
      coins: 7,
      dailyUses: 3,
      gemChance: 0.08),
];
