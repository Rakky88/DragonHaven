enum MysticRelic { moralPrism, orderCompass, soulMirror }

extension MysticRelicPresentation on MysticRelic {
  String get nameEn => switch (this) {
        MysticRelic.moralPrism => 'Moral Prism',
        MysticRelic.orderCompass => 'Order Compass',
        MysticRelic.soulMirror => 'Soul Mirror',
      };

  String get nameNl => switch (this) {
        MysticRelic.moralPrism => 'Moreel Prisma',
        MysticRelic.orderCompass => 'Ordekompas',
        MysticRelic.soulMirror => 'Zielenspiegel',
      };

  String get descriptionEn => switch (this) {
        MysticRelic.moralPrism =>
          'Reveals whether one dragon leans toward Good, Neutral or Evil.',
        MysticRelic.orderCompass =>
          'Reveals whether one dragon is Lawful, Neutral or Chaotic.',
        MysticRelic.soulMirror =>
          'Reveals the hidden personality traits of one dragon.',
      };

  String get descriptionNl => switch (this) {
        MysticRelic.moralPrism =>
          'Onthult of één draak naar Goed, Neutraal of Kwaad neigt.',
        MysticRelic.orderCompass =>
          'Onthult of één draak Ordelijk, Neutraal of Chaotisch is.',
        MysticRelic.soulMirror =>
          'Onthult de verborgen karaktereigenschappen van één draak.',
      };

  String get assetPath => 'assets/images/relics/${switch (this) {
        MysticRelic.moralPrism => 'moral_prism',
        MysticRelic.orderCompass => 'order_compass',
        MysticRelic.soulMirror => 'soul_mirror',
      }}.png';
}
