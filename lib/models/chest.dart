import 'mystic_relic.dart';

enum ChestTier {
  wooden,
  silver,
  gold,
  dragon,
  mythical,
  sinister;
}

class ChestReward {
  const ChestReward({
    required this.tier,
    required this.coins,
    required this.gems,
    required this.eggFound,
    this.sinisterEgg = false,
    this.relicFound,
  });
  final ChestTier tier;
  final int coins;
  final int gems;
  final bool eggFound;
  final bool sinisterEgg;
  final MysticRelic? relicFound;
}

extension ChestTierPresentation on ChestTier {
  String label(bool isDutch) => switch (this) {
        ChestTier.wooden => isDutch ? 'Houten Kist' : 'Wooden Chest',
        ChestTier.silver => isDutch ? 'Zilveren Kist' : 'Silver Chest',
        ChestTier.gold => isDutch ? 'Gouden Kist' : 'Gold Chest',
        ChestTier.dragon => isDutch ? 'Drakenkist' : 'Dragon Chest',
        ChestTier.mythical => isDutch ? 'Mythische Kist' : 'Mythical Chest',
        ChestTier.sinister => isDutch ? 'Sinistere Kist' : 'Sinister Chest',
      };

  int get colorValue => switch (this) {
        ChestTier.wooden => 0xFF8B5A3C,
        ChestTier.silver => 0xFF8292A6,
        ChestTier.gold => 0xFFD39B21,
        ChestTier.dragon => 0xFF8D52C7,
        ChestTier.mythical => 0xFF2A9CB8,
        ChestTier.sinister => 0xFF6D204E,
      };

  String get assetPath => 'assets/images/chests/chest_$name.png';
}
