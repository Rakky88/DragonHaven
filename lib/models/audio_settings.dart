enum HavenSound {
  uiConfirm('ui_confirm'),
  chestWooden('chest_wooden'),
  chestSilver('chest_silver'),
  chestGold('chest_gold'),
  chestDragon('chest_dragon'),
  chestMythical('chest_mythical'),
  chestSinister('chest_sinister'),
  chestSpecial('chest_special'),
  hatchBuild('hatch_build'),
  hatchCrackOne('hatch_crack_1'),
  hatchCrackTwo('hatch_crack_2'),
  hatchCrackThree('hatch_crack_3'),
  hatchReveal('hatch_reveal'),
  spectralReveal('spectral_reveal'),
  evolutionYoung('evolution_young'),
  evolutionAscended('evolution_ascended'),
  achievement('achievement'),
  adventureStart('adventure_start'),
  adventureReturn('adventure_return'),
  floorBuilt('floor_built');

  const HavenSound(this.assetId);
  final String assetId;
}

enum HavenMusicScene {
  towerDay('tower_day'),
  towerNight('tower_night'),
  room('room'),
  reveal('reveal');

  const HavenMusicScene(this.assetId);
  final String assetId;
}

enum HavenMusicStyle {
  classic('classic');

  const HavenMusicStyle(this.assetId);
  final String assetId;
}
