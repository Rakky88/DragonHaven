enum MysticRelic {
  moralPrism,
  orderCompass,
  soulMirror,
  astralLens,
  chronoshard,
  wayfinderSigil,
  twinstarBrooch,
}

const relicShopGemPrice = 500;

extension MysticRelicPresentation on MysticRelic {
  String get nameEn => switch (this) {
        MysticRelic.moralPrism => 'Moral Prism',
        MysticRelic.orderCompass => 'Order Compass',
        MysticRelic.soulMirror => 'Soul Mirror',
        MysticRelic.astralLens => 'Astral Lens',
        MysticRelic.chronoshard => 'Chronoshard',
        MysticRelic.wayfinderSigil => 'Wayfinder Sigil',
        MysticRelic.twinstarBrooch => 'Twinstar Brooch',
      };

  String get nameNl => switch (this) {
        MysticRelic.moralPrism => 'Moreel Prisma',
        MysticRelic.orderCompass => 'Ordekompas',
        MysticRelic.soulMirror => 'Zielenspiegel',
        MysticRelic.astralLens => 'Astrale Lens',
        MysticRelic.chronoshard => 'Chronoscherf',
        MysticRelic.wayfinderSigil => 'Padvinderszegel',
        MysticRelic.twinstarBrooch => 'Tweesterbroche',
      };

  String get descriptionEn => switch (this) {
        MysticRelic.moralPrism =>
          'Reveals whether one dragon leans toward Good, Neutral or Evil.',
        MysticRelic.orderCompass =>
          'Reveals whether one dragon is Lawful, Neutral or Chaotic.',
        MysticRelic.soulMirror =>
          'Reveals the hidden personality traits of one dragon.',
        MysticRelic.astralLens =>
          'Reveals only the hidden rarity of one unhatched dragon egg.',
        MysticRelic.chronoshard =>
          'Shortens the remaining incubation time of the egg in the nest by its fixed percentage.',
        MysticRelic.wayfinderSigil =>
          'Rerolls one chosen adventure or creates a new adventure of a chosen type when space is available.',
        MysticRelic.twinstarBrooch =>
          'A unique equipable relic that doubles all experience received only while its chosen dragon wears it.',
      };

  String get descriptionNl => switch (this) {
        MysticRelic.moralPrism =>
          'Onthult of één draak naar Goed, Neutraal of Kwaad neigt.',
        MysticRelic.orderCompass =>
          'Onthult of één draak Ordelijk, Neutraal of Chaotisch is.',
        MysticRelic.soulMirror =>
          'Onthult de verborgen karaktereigenschappen van één draak.',
        MysticRelic.astralLens =>
          'Onthult alleen de verborgen zeldzaamheid van één nog niet uitgekomen drakenei.',
        MysticRelic.chronoshard =>
          'Verkort de resterende broedtijd van het ei in het nest met het vastgelegde percentage.',
        MysticRelic.wayfinderSigil =>
          'Rerollt één gekozen avontuur of maakt een nieuw avontuur van een gekozen type als er ruimte is.',
        MysticRelic.twinstarBrooch =>
          'Een unieke uitrustbare relic die alle ontvangen ervaring alleen verdubbelt zolang de gekozen draak hem draagt.',
      };

  String get assetPath => 'assets/images/relics/${switch (this) {
        MysticRelic.moralPrism => 'moral_prism',
        MysticRelic.orderCompass => 'order_compass',
        MysticRelic.soulMirror => 'soul_mirror',
        MysticRelic.astralLens => 'astral_lens',
        MysticRelic.chronoshard => 'chronoshard',
        MysticRelic.wayfinderSigil => 'wayfinder_sigil',
        MysticRelic.twinstarBrooch => 'twinstar_brooch',
      }}.png';

  bool get isShopAvailable => switch (this) {
        MysticRelic.moralPrism ||
        MysticRelic.orderCompass ||
        MysticRelic.soulMirror ||
        MysticRelic.astralLens =>
          true,
        MysticRelic.chronoshard ||
        MysticRelic.wayfinderSigil ||
        MysticRelic.twinstarBrooch =>
          false,
      };

  bool get hasUseAnimation => switch (this) {
        MysticRelic.moralPrism ||
        MysticRelic.orderCompass ||
        MysticRelic.soulMirror =>
          true,
        _ => false,
      };

  bool get isConsumable => this != MysticRelic.twinstarBrooch;

  bool get isAlwaysUntradeable => this == MysticRelic.twinstarBrooch;

  String animationFrameAsset(int frame) =>
      'assets/images/relics/animations/$name/frame_${frame.toString().padLeft(2, '0')}.webp';
}
