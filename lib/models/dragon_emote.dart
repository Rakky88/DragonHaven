enum DragonEmoteSource {
  chest,
  trial,
  cozyPack,
  infernalPack,
  celestialPack;

  String get assetFolder => switch (this) {
        DragonEmoteSource.chest => 'chest',
        DragonEmoteSource.trial => 'trial',
        DragonEmoteSource.cozyPack => 'cozy',
        DragonEmoteSource.infernalPack => 'infernal',
        DragonEmoteSource.celestialPack => 'celestial',
      };

  bool get isPack => switch (this) {
        DragonEmoteSource.chest || DragonEmoteSource.trial => false,
        _ => true,
      };
}

class DragonEmoteDefinition {
  const DragonEmoteDefinition({
    required this.id,
    required this.assetName,
    required this.nameEn,
    required this.nameNl,
    required this.source,
  });

  final String id;
  final String assetName;
  final String nameEn;
  final String nameNl;
  final DragonEmoteSource source;

  String get assetPath =>
      'assets/images/emotes/${source.assetFolder}/$assetName.png';

  String label(String languageCode) => languageCode == 'nl' ? nameNl : nameEn;
}

class DragonEmotePackDefinition {
  const DragonEmotePackDefinition({
    required this.id,
    required this.internalProductId,
    required this.nameEn,
    required this.nameNl,
    required this.descriptionEn,
    required this.descriptionNl,
    required this.source,
  });

  final String id;
  final String internalProductId;
  final String nameEn;
  final String nameNl;
  final String descriptionEn;
  final String descriptionNl;
  final DragonEmoteSource source;

  List<DragonEmoteDefinition> get emotes => allDragonEmotes
      .where((emote) => emote.source == source)
      .toList(growable: false);

  String name(String languageCode) => languageCode == 'nl' ? nameNl : nameEn;
  String description(String languageCode) =>
      languageCode == 'nl' ? descriptionNl : descriptionEn;
}

const dragonEmotePackPriceCents = 199;

const _chestEmotes = <DragonEmoteDefinition>[
  DragonEmoteDefinition(
      id: 'chest_treasure_hello',
      assetName: 'treasure_hello',
      nameEn: 'Treasure Hello',
      nameNl: 'Schatgroet',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_coin_eyes',
      assetName: 'coin_eyes',
      nameEn: 'Coin Eyes',
      nameNl: 'Muntogen',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_sleepy_hoard',
      assetName: 'sleepy_hoard',
      nameEn: 'Sleepy Hoard',
      nameNl: 'Slaperige schat',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_surprise_egg',
      assetName: 'surprise_egg',
      nameEn: 'Egg Surprise',
      nameNl: 'Eierverrassing',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_lucky_gem',
      assetName: 'lucky_gem',
      nameEn: 'Lucky Gem',
      nameNl: 'Geluksedelsteen',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_chest_peek',
      assetName: 'chest_peek',
      nameEn: 'Chest Peek',
      nameNl: 'Kistkijker',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_gem_tears',
      assetName: 'gem_tears',
      nameEn: 'Gem Tears',
      nameNl: 'Edelsteentranen',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_golden_laugh',
      assetName: 'golden_laugh',
      nameEn: 'Golden Laugh',
      nameNl: 'Gouden lach',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_map_confused',
      assetName: 'map_confused',
      nameEn: 'Map Confused',
      nameNl: 'Kaartverwarring',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_key_found',
      assetName: 'key_found',
      nameEn: 'Key Found',
      nameNl: 'Sleutel gevonden',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_mimic_shock',
      assetName: 'mimic_shock',
      nameEn: 'Mimic Shock',
      nameNl: 'Mimic-schrik',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_coin_rain',
      assetName: 'coin_rain',
      nameEn: 'Coin Rain',
      nameNl: 'Muntenregen',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_tiny_hoard',
      assetName: 'tiny_hoard',
      nameEn: 'Tiny Hoard',
      nameNl: 'Kleine schat',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_pearl_proud',
      assetName: 'pearl_proud',
      nameEn: 'Pearl Proud',
      nameNl: 'Trots op parel',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_treasure_sleep',
      assetName: 'treasure_sleep',
      nameEn: 'Treasure Sleep',
      nameNl: 'Schatdutje',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_locked_out',
      assetName: 'locked_out',
      nameEn: 'Locked Out',
      nameNl: 'Buitengesloten',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_crown_try',
      assetName: 'crown_try',
      nameEn: 'Crown Try',
      nameNl: 'Kroonpassen',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_dusty_sneeze',
      assetName: 'dusty_sneeze',
      nameEn: 'Dusty Sneeze',
      nameNl: 'Stoffige nies',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_potion_find',
      assetName: 'potion_find',
      nameEn: 'Potion Find',
      nameNl: 'Drankje gevonden',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_silver_bell',
      assetName: 'silver_bell',
      nameEn: 'Silver Bell',
      nameNl: 'Zilveren bel',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_scroll_wow',
      assetName: 'scroll_wow',
      nameEn: 'Scroll Wow',
      nameNl: 'Rol-wow',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_ruby_blush',
      assetName: 'ruby_blush',
      nameEn: 'Ruby Blush',
      nameNl: 'Robijnblozen',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_sapphire_cool',
      assetName: 'sapphire_cool',
      nameEn: 'Sapphire Cool',
      nameNl: 'Saffiercool',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_jackpot',
      assetName: 'jackpot',
      nameEn: 'Jackpot',
      nameNl: 'Jackpot',
      source: DragonEmoteSource.chest),
  DragonEmoteDefinition(
      id: 'chest_dragon_detective',
      assetName: 'dragon_detective',
      nameEn: 'Dragon Detective',
      nameNl: 'Drakendetective',
      source: DragonEmoteSource.chest),
];

const _trialEmotes = <DragonEmoteDefinition>[
  DragonEmoteDefinition(
      id: 'trial_s_plus_crown',
      assetName: 's_plus_crown',
      nameEn: 'S+ Crown',
      nameNl: 'S+-kroon',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_perfect_smash',
      assetName: 'perfect_smash',
      nameEn: 'Perfect Smash',
      nameNl: 'Perfecte dreun',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_cavern_soar',
      assetName: 'cavern_soar',
      nameEn: 'Cavern Soar',
      nameNl: 'Grotvlucht',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_rune_genius',
      assetName: 'rune_genius',
      nameEn: 'Rune Genius',
      nameNl: 'Runengenie',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_focus',
      assetName: 'focus',
      nameEn: 'Deep Focus',
      nameNl: 'Diepe focus',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_victory_roar',
      assetName: 'victory_roar',
      nameEn: 'Victory Roar',
      nameNl: 'Overwinningsbrul',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_close_call',
      assetName: 'close_call',
      nameEn: 'Close Call',
      nameNl: 'Dat scheelde weinig',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_speed_blur',
      assetName: 'speed_blur',
      nameEn: 'Speed Blur',
      nameNl: 'Snelheidsflits',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_combo_fire',
      assetName: 'combo_fire',
      nameEn: 'Combo Fire',
      nameNl: 'Combovuur',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_dizzy',
      assetName: 'dizzy',
      nameEn: 'Trial Dizzy',
      nameNl: 'Trial-duizelig',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_sweating',
      assetName: 'sweating',
      nameEn: 'Still Trying',
      nameNl: 'Blijven proberen',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_might_flex',
      assetName: 'might_flex',
      nameEn: 'Might Flex',
      nameNl: 'Might-spieren',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_spirit_wings',
      assetName: 'spirit_wings',
      nameEn: 'Spirit Wings',
      nameNl: 'Spirit-vleugels',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_arcana_orbit',
      assetName: 'arcana_orbit',
      nameEn: 'Arcana Orbit',
      nameNl: 'Arcana-baan',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_new_record',
      assetName: 'new_record',
      nameEn: 'New Record',
      nameNl: 'Nieuw record',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_retry',
      assetName: 'retry',
      nameEn: 'One More Try',
      nameNl: 'Nog één keer',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_target_lock',
      assetName: 'target_lock',
      nameEn: 'Target Lock',
      nameNl: 'Doelwit vast',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_flawless',
      assetName: 'flawless',
      nameEn: 'Flawless',
      nameNl: 'Vlekkeloos',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_training',
      assetName: 'training',
      nameEn: 'Training Time',
      nameNl: 'Trainingstijd',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_medal_bite',
      assetName: 'medal_bite',
      nameEn: 'Medal Bite',
      nameNl: 'Medaillebeet',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_power_up',
      assetName: 'power_up',
      nameEn: 'Power Up',
      nameNl: 'Kracht erbij',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_team_cheer',
      assetName: 'team_cheer',
      nameEn: 'Team Cheer',
      nameNl: 'Teamjuich',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_zen',
      assetName: 'zen',
      nameEn: 'Trial Zen',
      nameNl: 'Trial-zen',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_countdown',
      assetName: 'countdown',
      nameEn: 'Ready!',
      nameNl: 'Klaar!',
      source: DragonEmoteSource.trial),
  DragonEmoteDefinition(
      id: 'trial_champion',
      assetName: 'champion',
      nameEn: 'Champion',
      nameNl: 'Kampioen',
      source: DragonEmoteSource.trial),
];

const _cozyPackEmotes = <DragonEmoteDefinition>[
  DragonEmoteDefinition(
      id: 'cozy_heart_hug',
      assetName: 'heart_hug',
      nameEn: 'Heart Hug',
      nameNl: 'Hartenknuffel',
      source: DragonEmoteSource.cozyPack),
  DragonEmoteDefinition(
      id: 'cozy_cocoa',
      assetName: 'cocoa',
      nameEn: 'Dragon Cocoa',
      nameNl: 'Drakencacao',
      source: DragonEmoteSource.cozyPack),
  DragonEmoteDefinition(
      id: 'cozy_blanket',
      assetName: 'blanket',
      nameEn: 'Blanket Burrito',
      nameNl: 'Dekenburrito',
      source: DragonEmoteSource.cozyPack),
  DragonEmoteDefinition(
      id: 'cozy_sleepy',
      assetName: 'sleepy',
      nameEn: 'Sweet Dreams',
      nameNl: 'Droom zacht',
      source: DragonEmoteSource.cozyPack),
  DragonEmoteDefinition(
      id: 'cozy_flower',
      assetName: 'flower',
      nameEn: 'For You',
      nameNl: 'Voor jou',
      source: DragonEmoteSource.cozyPack),
  DragonEmoteDefinition(
      id: 'cozy_shy_wave',
      assetName: 'shy_wave',
      nameEn: 'Shy Wave',
      nameNl: 'Verlegen zwaai',
      source: DragonEmoteSource.cozyPack),
  DragonEmoteDefinition(
      id: 'cozy_picnic',
      assetName: 'picnic',
      nameEn: 'Picnic Snack',
      nameNl: 'Picknicksnack',
      source: DragonEmoteSource.cozyPack),
  DragonEmoteDefinition(
      id: 'cozy_cuddle',
      assetName: 'cuddle',
      nameEn: 'Dragon Cuddle',
      nameNl: 'Drakenknuffel',
      source: DragonEmoteSource.cozyPack),
  DragonEmoteDefinition(
      id: 'cozy_happy_tears',
      assetName: 'happy_tears',
      nameEn: 'Happy Tears',
      nameNl: 'Blije tranen',
      source: DragonEmoteSource.cozyPack),
  DragonEmoteDefinition(
      id: 'cozy_good_night',
      assetName: 'good_night',
      nameEn: 'Good Night',
      nameNl: 'Welterusten',
      source: DragonEmoteSource.cozyPack),
];

const _infernalPackEmotes = <DragonEmoteDefinition>[
  DragonEmoteDefinition(
      id: 'infernal_evil_laugh',
      assetName: 'evil_laugh',
      nameEn: 'Evil Laugh',
      nameNl: 'Evil lach',
      source: DragonEmoteSource.infernalPack),
  DragonEmoteDefinition(
      id: 'infernal_rage',
      assetName: 'rage',
      nameEn: 'Infernal Rage',
      nameNl: 'Infernale woede',
      source: DragonEmoteSource.infernalPack),
  DragonEmoteDefinition(
      id: 'infernal_facepalm',
      assetName: 'facepalm',
      nameEn: 'Dragon Facepalm',
      nameNl: 'Drakenfacepalm',
      source: DragonEmoteSource.infernalPack),
  DragonEmoteDefinition(
      id: 'infernal_suspicious',
      assetName: 'suspicious',
      nameEn: 'Suspicious',
      nameNl: 'Achterdochtig',
      source: DragonEmoteSource.infernalPack),
  DragonEmoteDefinition(
      id: 'infernal_skull_grin',
      assetName: 'skull_grin',
      nameEn: 'Skull Grin',
      nameNl: 'Schedelgrijns',
      source: DragonEmoteSource.infernalPack),
  DragonEmoteDefinition(
      id: 'infernal_fire',
      assetName: 'fire',
      nameEn: 'Set It Ablaze',
      nameNl: 'Steek het aan',
      source: DragonEmoteSource.infernalPack),
  DragonEmoteDefinition(
      id: 'infernal_no',
      assetName: 'no',
      nameEn: 'Absolutely Not',
      nameNl: 'Absoluut niet',
      source: DragonEmoteSource.infernalPack),
  DragonEmoteDefinition(
      id: 'infernal_chaos',
      assetName: 'chaos',
      nameEn: 'Choose Chaos',
      nameNl: 'Kies chaos',
      source: DragonEmoteSource.infernalPack),
  DragonEmoteDefinition(
      id: 'infernal_shocked',
      assetName: 'shocked',
      nameEn: 'Infernal Shock',
      nameNl: 'Infernale schrik',
      source: DragonEmoteSource.infernalPack),
  DragonEmoteDefinition(
      id: 'infernal_smug',
      assetName: 'smug',
      nameEn: 'Smug',
      nameNl: 'Zelfvoldaan',
      source: DragonEmoteSource.infernalPack),
];

const _celestialPackEmotes = <DragonEmoteDefinition>[
  DragonEmoteDefinition(
      id: 'celestial_royal_wave',
      assetName: 'royal_wave',
      nameEn: 'Royal Wave',
      nameNl: 'Koninklijke zwaai',
      source: DragonEmoteSource.celestialPack),
  DragonEmoteDefinition(
      id: 'celestial_applause',
      assetName: 'applause',
      nameEn: 'Celestial Applause',
      nameNl: 'Hemels applaus',
      source: DragonEmoteSource.celestialPack),
  DragonEmoteDefinition(
      id: 'celestial_sparkle',
      assetName: 'sparkle',
      nameEn: 'Star Sparkle',
      nameNl: 'Sterrenfonkeling',
      source: DragonEmoteSource.celestialPack),
  DragonEmoteDefinition(
      id: 'celestial_moon_dream',
      assetName: 'moon_dream',
      nameEn: 'Moon Dream',
      nameNl: 'Maandroom',
      source: DragonEmoteSource.celestialPack),
  DragonEmoteDefinition(
      id: 'celestial_star_eyes',
      assetName: 'star_eyes',
      nameEn: 'Star Eyes',
      nameNl: 'Sterrenogen',
      source: DragonEmoteSource.celestialPack),
  DragonEmoteDefinition(
      id: 'celestial_bow',
      assetName: 'bow',
      nameEn: 'Courtly Bow',
      nameNl: 'Hoffelijke buiging',
      source: DragonEmoteSource.celestialPack),
  DragonEmoteDefinition(
      id: 'celestial_celebrate',
      assetName: 'celebrate',
      nameEn: 'Celestial Celebration',
      nameNl: 'Hemels feest',
      source: DragonEmoteSource.celestialPack),
  DragonEmoteDefinition(
      id: 'celestial_wisdom',
      assetName: 'wisdom',
      nameEn: 'Ancient Wisdom',
      nameNl: 'Oude wijsheid',
      source: DragonEmoteSource.celestialPack),
  DragonEmoteDefinition(
      id: 'celestial_salute',
      assetName: 'salute',
      nameEn: 'Guardian Salute',
      nameNl: 'Hoedersgroet',
      source: DragonEmoteSource.celestialPack),
  DragonEmoteDefinition(
      id: 'celestial_magic',
      assetName: 'magic',
      nameEn: 'Moon Magic',
      nameNl: 'Maanmagie',
      source: DragonEmoteSource.celestialPack),
];

const allDragonEmotes = <DragonEmoteDefinition>[
  ..._chestEmotes,
  ..._trialEmotes,
  ..._cozyPackEmotes,
  ..._infernalPackEmotes,
  ..._celestialPackEmotes,
];

final dragonEmotesById = <String, DragonEmoteDefinition>{
  for (final emote in allDragonEmotes) emote.id: emote,
};

const dragonEmotePacks = <DragonEmotePackDefinition>[
  DragonEmotePackDefinition(
    id: 'cozy_hatchlings',
    internalProductId: 'emote_pack_cozy_199',
    nameEn: 'Cozy Hatchlings',
    nameNl: 'Knusse Hatchlings',
    descriptionEn: 'Ten warm reactions for hugs, naps and gentle moments.',
    descriptionNl:
        'Tien warme reacties voor knuffels, dutjes en lieve momenten.',
    source: DragonEmoteSource.cozyPack,
  ),
  DragonEmotePackDefinition(
    id: 'infernal_reactions',
    internalProductId: 'emote_pack_infernal_199',
    nameEn: 'Infernal Reactions',
    nameNl: 'Infernale Reacties',
    descriptionEn:
        'Ten fiery reactions with mischief, rage and dramatic flair.',
    descriptionNl: 'Tien vurige reacties vol kattenkwaad, woede en drama.',
    source: DragonEmoteSource.infernalPack,
  ),
  DragonEmotePackDefinition(
    id: 'celestial_court',
    internalProductId: 'emote_pack_celestial_199',
    nameEn: 'Celestial Court',
    nameNl: 'Hemels Hof',
    descriptionEn: 'Ten regal moonlit reactions for accomplished Keepers.',
    descriptionNl: 'Tien vorstelijke maanreacties voor ervaren Hoeders.',
    source: DragonEmoteSource.celestialPack,
  ),
];

DragonEmoteDefinition? dragonEmoteById(String? id) =>
    id == null ? null : dragonEmotesById[id];

DragonEmotePackDefinition? dragonEmotePackById(String? id) {
  if (id == null) return null;
  for (final pack in dragonEmotePacks) {
    if (pack.id == id || pack.internalProductId == id) return pack;
  }
  return null;
}

List<DragonEmoteDefinition> dragonEmotesForSource(DragonEmoteSource source) =>
    allDragonEmotes
        .where((emote) => emote.source == source)
        .toList(growable: false);
