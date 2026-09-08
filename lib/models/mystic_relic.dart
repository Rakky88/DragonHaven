import 'pet.dart';

enum MysticRelic {
  moralPrism,
  orderCompass,
  soulMirror,
  astralLens,
  chronoshard,
  wayfinderSigil,
  twinstarBrooch,
  emberheartBrooch,
  moonweaveBrooch,
  soulbloomBrooch,
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
        MysticRelic.emberheartBrooch => 'Emberheart Brooch',
        MysticRelic.moonweaveBrooch => 'Moonweave Brooch',
        MysticRelic.soulbloomBrooch => 'Soulbloom Brooch',
      };

  String get nameNl => switch (this) {
        MysticRelic.moralPrism => 'Moreel Prisma',
        MysticRelic.orderCompass => 'Ordekompas',
        MysticRelic.soulMirror => 'Zielenspiegel',
        MysticRelic.astralLens => 'Astrale Lens',
        MysticRelic.chronoshard => 'Chronoscherf',
        MysticRelic.wayfinderSigil => 'Padvinderszegel',
        MysticRelic.twinstarBrooch => 'Tweesterbroche',
        MysticRelic.emberheartBrooch => 'Gloeihartbroche',
        MysticRelic.moonweaveBrooch => 'Maanweefbroche',
        MysticRelic.soulbloomBrooch => 'Zielenbloembroche',
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
        MysticRelic.emberheartBrooch =>
          'Doubles Might earned by its wearer in Adventures and Trials. One brooch per dragon.',
        MysticRelic.moonweaveBrooch =>
          'Doubles Arcana earned by its wearer in Adventures and Trials. One brooch per dragon.',
        MysticRelic.soulbloomBrooch =>
          'Doubles Spirit earned by its wearer in Adventures and Trials. One brooch per dragon.',
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
        MysticRelic.emberheartBrooch =>
          'Verdubbelt Might die de drager verdient in Adventures en Trials. Eén broche per draak.',
        MysticRelic.moonweaveBrooch =>
          'Verdubbelt Arcana die de drager verdient in Adventures en Trials. Eén broche per draak.',
        MysticRelic.soulbloomBrooch =>
          'Verdubbelt Spirit die de drager verdient in Adventures en Trials. Eén broche per draak.',
      };

  String get assetPath => 'assets/images/relics/${switch (this) {
        MysticRelic.moralPrism => 'moral_prism',
        MysticRelic.orderCompass => 'order_compass',
        MysticRelic.soulMirror => 'soul_mirror',
        MysticRelic.astralLens => 'astral_lens',
        MysticRelic.chronoshard => 'chronoshard',
        MysticRelic.wayfinderSigil => 'wayfinder_sigil',
        MysticRelic.twinstarBrooch => 'twinstar_brooch',
        MysticRelic.emberheartBrooch => 'emberheart_brooch',
        MysticRelic.moonweaveBrooch => 'moonweave_brooch',
        MysticRelic.soulbloomBrooch => 'soulbloom_brooch',
      }}.png';

  bool get isShopAvailable => switch (this) {
        MysticRelic.moralPrism ||
        MysticRelic.orderCompass ||
        MysticRelic.soulMirror ||
        MysticRelic.astralLens =>
          true,
        MysticRelic.chronoshard ||
        MysticRelic.wayfinderSigil ||
        MysticRelic.twinstarBrooch ||
        MysticRelic.emberheartBrooch ||
        MysticRelic.moonweaveBrooch ||
        MysticRelic.soulbloomBrooch =>
          false,
      };

  bool get hasUseAnimation => switch (this) {
        MysticRelic.moralPrism ||
        MysticRelic.orderCompass ||
        MysticRelic.soulMirror =>
          true,
        _ => false,
      };

  bool get isEquipable => switch (this) {
        MysticRelic.twinstarBrooch ||
        MysticRelic.emberheartBrooch ||
        MysticRelic.moonweaveBrooch ||
        MysticRelic.soulbloomBrooch =>
          true,
        _ => false,
      };

  TrainingFocus? get boostedExpertise => switch (this) {
        MysticRelic.emberheartBrooch => TrainingFocus.might,
        MysticRelic.moonweaveBrooch => TrainingFocus.arcana,
        MysticRelic.soulbloomBrooch => TrainingFocus.spirit,
        _ => null,
      };

  int get dropWeight => isEquipable ? 1 : 10;

  bool get isConsumable => !isEquipable;

  bool get isAlwaysUntradeable => isEquipable;

  String animationFrameAsset(int frame) =>
      'assets/images/relics/animations/$name/frame_${frame.toString().padLeft(2, '0')}.webp';
}

/// Conditional pool after the unchanged chest / S+ relic-drop gate succeeds.
/// Every ordinary relic has ten tickets; each unique brooch has one.
List<MysticRelic> mysticRelicDropPool({Set<MysticRelic> excluded = const {}}) =>
    [
      for (final relic in MysticRelic.values)
        if (!excluded.contains(relic))
          for (var ticket = 0; ticket < relic.dropWeight; ticket++) relic,
    ];
