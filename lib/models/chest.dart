import 'mystic_relic.dart';
import 'profile_portrait.dart';
import 'account_title.dart';
import 'music_track.dart';
import 'dragon_emote.dart';

const portraitChestGemPrice = 100;
const titleChestCoinPrice = 100;
const musicChestGemPrice = 250;

enum ChestTier {
  wooden,
  silver,
  gold,
  dragon,
  mythical,
  sinister,
  special,
  portrait,
  title,
  music;
}

class ChestReward {
  const ChestReward({
    required this.tier,
    required this.coins,
    required this.gems,
    required this.eggFound,
    this.sinisterEgg = false,
    this.specialEgg = false,
    this.relicFound,
    this.portraitFound,
    this.titleFound,
    this.musicTrackFound,
    this.emoteFound,
  });
  final ChestTier tier;
  final int coins;
  final int gems;
  final bool eggFound;
  final bool sinisterEgg;
  final bool specialEgg;
  final MysticRelic? relicFound;
  final ProfilePortrait? portraitFound;
  final AccountTitle? titleFound;
  final MusicTrack? musicTrackFound;
  final DragonEmoteDefinition? emoteFound;
}

class ChestRewardBundle {
  ChestRewardBundle({
    required this.tier,
    required List<ChestReward> rewards,
  }) : rewards = List.unmodifiable(rewards);

  factory ChestRewardBundle.single(ChestReward reward) => ChestRewardBundle(
        tier: reward.tier,
        rewards: [reward],
      );

  final ChestTier tier;
  final List<ChestReward> rewards;

  int get openedCount => rewards.length;
  int get coins => rewards.fold(0, (total, reward) => total + reward.coins);
  int get gems => rewards.fold(0, (total, reward) => total + reward.gems);
  int get mysteriousEggCount => rewards
      .where((reward) =>
          reward.eggFound && !reward.sinisterEgg && !reward.specialEgg)
      .length;
  int get sinisterEggCount =>
      rewards.where((reward) => reward.sinisterEgg).length;
  int get specialEggCount =>
      rewards.where((reward) => reward.specialEgg).length;
  List<MysticRelic> get relics => rewards
      .map((reward) => reward.relicFound)
      .whereType<MysticRelic>()
      .toList(growable: false);
  List<ProfilePortrait> get portraits => rewards
      .map((reward) => reward.portraitFound)
      .whereType<ProfilePortrait>()
      .toList(growable: false);
  List<AccountTitle> get titles => rewards
      .map((reward) => reward.titleFound)
      .whereType<AccountTitle>()
      .toList(growable: false);
  List<MusicTrack> get musicTracks => rewards
      .map((reward) => reward.musicTrackFound)
      .whereType<MusicTrack>()
      .toList(growable: false);
  List<DragonEmoteDefinition> get emotes => rewards
      .map((reward) => reward.emoteFound)
      .whereType<DragonEmoteDefinition>()
      .toList(growable: false);
}

extension ChestTierPresentation on ChestTier {
  bool get isTradeable =>
      this != ChestTier.portrait &&
      this != ChestTier.title &&
      this != ChestTier.music;

  String label(bool isDutch) => switch (this) {
        ChestTier.wooden => isDutch ? 'Houten Kist' : 'Wooden Chest',
        ChestTier.silver => isDutch ? 'Zilveren Kist' : 'Silver Chest',
        ChestTier.gold => isDutch ? 'Gouden Kist' : 'Gold Chest',
        ChestTier.dragon => isDutch ? 'Drakenkist' : 'Dragon Chest',
        ChestTier.mythical => isDutch ? 'Mythische Kist' : 'Mythical Chest',
        ChestTier.sinister => isDutch ? 'Sinistere Kist' : 'Sinister Chest',
        ChestTier.special => isDutch ? 'Speciale Kist' : 'Special Chest',
        ChestTier.portrait => isDutch ? 'Portretkist' : 'Portrait Chest',
        ChestTier.title => isDutch ? 'Titelkist' : 'Title Chest',
        ChestTier.music => isDutch ? 'Muziekkist' : 'Music Chest',
      };

  int get colorValue => switch (this) {
        ChestTier.wooden => 0xFF8B5A3C,
        ChestTier.silver => 0xFF8292A6,
        ChestTier.gold => 0xFFD39B21,
        ChestTier.dragon => 0xFF8D52C7,
        ChestTier.mythical => 0xFF2A9CB8,
        ChestTier.sinister => 0xFF6D204E,
        ChestTier.special => 0xFFE4A63A,
        ChestTier.portrait => 0xFF8D52C7,
        ChestTier.title => 0xFF8D52C7,
        ChestTier.music => 0xFF8D52C7,
      };

  String get assetPath => switch (this) {
        ChestTier.portrait ||
        ChestTier.title =>
          'assets/images/chests/chest_portrait.webp',
        ChestTier.music => 'assets/images/chests/chest_portrait.webp',
        ChestTier.special => 'assets/images/chests/chest_special.webp',
        _ => 'assets/images/chests/chest_$name.png',
      };
  String get openedAssetPath => switch (this) {
        ChestTier.portrait ||
        ChestTier.title =>
          'assets/images/chests/open/chest_portrait_open.webp',
        ChestTier.music => 'assets/images/chests/open/chest_music_open.png',
        ChestTier.special =>
          'assets/images/chests/open/chest_special_open.webp',
        _ => 'assets/images/chests/open/chest_${name}_open.png',
      };
}
