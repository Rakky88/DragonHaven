enum ItemSlot { bed, plant, wall, light }

enum ItemRarity { common, special, rare }

enum ItemCurrency { coins, gems }

enum FurnitureLightType { none, warm, cool, fire, arcane }

enum FurnitureNightActivation { none, always, duskAndNight, manualVisualOnly }

const int shopPriceMultiplier = 10;

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.nameNl,
    required this.description,
    required this.descriptionNl,
    required this.slot,
    required int price,
    required this.rarity,
    required this.visualSeed,
    this.interactionTags = const <String>[],
    this.emitsLight = false,
    this.lightType = FurnitureLightType.none,
    this.nightActivation = FurnitureNightActivation.none,
    this.glowRadius = 0,
    this.hasAmbientAnimation = false,
    this.daySpriteAsset,
    this.nightSpriteAsset,
    this.currency = ItemCurrency.coins,
  }) : price = price * shopPriceMultiplier;

  final String id;
  final String name;
  final String nameNl;
  final String description;
  final String descriptionNl;
  final ItemSlot slot;
  final int price;
  final ItemRarity rarity;
  final int visualSeed;
  final List<String> interactionTags;
  final bool emitsLight;
  final FurnitureLightType lightType;
  final FurnitureNightActivation nightActivation;
  final double glowRadius;
  final bool hasAmbientAnimation;
  final String? daySpriteAsset;
  final String? nightSpriteAsset;
  final ItemCurrency currency;
}

const _originalShopItems = <ShopItem>[
  ShopItem(
    id: 'moss_cushion',
    name: 'Moss cushion',
    nameNl: 'Moskussen',
    description: 'A soft cushion that smells like rain.',
    descriptionNl: 'Een zacht kussen dat ruikt naar regen.',
    slot: ItemSlot.bed,
    price: 12,
    rarity: ItemRarity.common,
    visualSeed: 0,
  ),
  ShopItem(
    id: 'cloud_basket',
    name: 'Cloud basket',
    nameNl: 'Wolkenmand',
    description: 'For dragon dreams without sharp edges.',
    descriptionNl: 'Voor drakendromen zonder scherpe randjes.',
    slot: ItemSlot.bed,
    price: 28,
    rarity: ItemRarity.special,
    visualSeed: 1,
  ),
  ShopItem(
    id: 'moon_fern',
    name: 'Moon fern',
    nameNl: 'Maanvaren',
    description: 'Its leaves unfold in moonlight.',
    descriptionNl: 'Vouwt zijn blaadjes open bij maanlicht.',
    slot: ItemSlot.plant,
    price: 8,
    rarity: ItemRarity.common,
    visualSeed: 2,
  ),
  ShopItem(
    id: 'star_bonsai',
    name: 'Star bonsai',
    nameNl: 'Sterrenbonsai',
    description: 'A rare little tree with golden buds.',
    descriptionNl: 'Een zeldzaam boompje met gouden knoppen.',
    slot: ItemSlot.plant,
    price: 34,
    rarity: ItemRarity.rare,
    visualSeed: 3,
  ),
  ShopItem(
    id: 'spire_map',
    name: 'Spire map',
    nameNl: 'Spirekaart',
    description: 'Every marked balcony promises a small discovery.',
    descriptionNl: 'Elk gemarkeerd balkon belooft een kleine ontdekking.',
    slot: ItemSlot.wall,
    price: 16,
    rarity: ItemRarity.common,
    visualSeed: 4,
  ),
  ShopItem(
    id: 'moon_banner',
    name: 'Moon banner',
    nameNl: 'Maanvaandel',
    description: 'Gives the nest a heroic glow.',
    descriptionNl: 'Geeft het nest een heldhaftige gloed.',
    slot: ItemSlot.wall,
    price: 30,
    rarity: ItemRarity.special,
    visualSeed: 5,
  ),
  ShopItem(
    id: 'firefly_lamp',
    name: 'Firefly lamp',
    nameNl: 'Vuurvlieglamp',
    description: 'Warm light, politely kept in a jar.',
    descriptionNl: 'Warm licht, netjes in een potje gevraagd.',
    slot: ItemSlot.light,
    price: 22,
    rarity: ItemRarity.special,
    visualSeed: 6,
    interactionTags: ['magic', 'fireplace'],
    emitsLight: true,
    lightType: FurnitureLightType.warm,
    nightActivation: FurnitureNightActivation.duskAndNight,
    glowRadius: .2,
    hasAmbientAnimation: true,
  ),
  ShopItem(
    id: 'crystal_lantern',
    name: 'Crystal lantern',
    nameNl: 'Kristallantaarn',
    description: 'A turquoise glow for late-night reading.',
    descriptionNl: 'Een turquoise gloed voor lezen in de late uurtjes.',
    slot: ItemSlot.light,
    price: 45,
    rarity: ItemRarity.rare,
    visualSeed: 7,
    interactionTags: ['magic'],
    emitsLight: true,
    lightType: FurnitureLightType.arcane,
    nightActivation: FurnitureNightActivation.duskAndNight,
    glowRadius: .24,
    hasAmbientAnimation: true,
  ),
];

class _FurnitureTheme {
  const _FurnitureTheme(
    this.id,
    this.nameEn,
    this.nameNl,
    this.colorValue,
  );

  final String id;
  final String nameEn;
  final String nameNl;
  final int colorValue;
}

class _FurnitureForm {
  const _FurnitureForm(
    this.id,
    this.nameEn,
    this.nameNl,
    this.descriptionEn,
    this.descriptionNl,
    this.slot,
  );

  final String id;
  final String nameEn;
  final String nameNl;
  final String descriptionEn;
  final String descriptionNl;
  final ItemSlot slot;
}

const _themes = <_FurnitureTheme>[
  _FurnitureTheme('aurora', 'Aurora', 'Noorderlicht', 0xFF6D7CFF),
  _FurnitureTheme('ember', 'Ember', 'Gloed', 0xFFE45B36),
  _FurnitureTheme('moon', 'Moon', 'Maan', 0xFF8472CA),
  _FurnitureTheme('forest', 'Forest', 'Woud', 0xFF3F946A),
  _FurnitureTheme('ocean', 'Ocean', 'Oceaan', 0xFF258BB0),
  _FurnitureTheme('crystal', 'Crystal', 'Kristal', 0xFF66C7DA),
  _FurnitureTheme('cloud', 'Cloud', 'Wolk', 0xFF9BAAC6),
  _FurnitureTheme('sun', 'Sun', 'Zon', 0xFFF1B83F),
  _FurnitureTheme('lavender', 'Lavender', 'Lavendel', 0xFF9C71C8),
  _FurnitureTheme('copper', 'Copper', 'Koper', 0xFFA9663B),
  _FurnitureTheme('starlight', 'Starlight', 'Sterlicht', 0xFF3D4D9B),
  _FurnitureTheme('meadow', 'Meadow', 'Weide', 0xFF73A94D),
  _FurnitureTheme('storm', 'Storm', 'Storm', 0xFF506C9E),
  _FurnitureTheme('cherry', 'Cherry', 'Kersenbloesem', 0xFFD96D91),
  _FurnitureTheme('frost', 'Frost', 'Rijp', 0xFF8CC9D8),
  _FurnitureTheme('honey', 'Honey', 'Honing', 0xFFD89C2B),
  _FurnitureTheme('mushroom', 'Mushroom', 'Paddenstoel', 0xFFB45A56),
  _FurnitureTheme('velvet', 'Velvet', 'Fluweel', 0xFF713A79),
  _FurnitureTheme('rainbow', 'Rainbow', 'Regenboog', 0xFF5ABCA8),
  _FurnitureTheme('twilight', 'Twilight', 'Schemer', 0xFF514478),
  _FurnitureTheme('coral', 'Coral', 'Koraal', 0xFFE4776B),
  _FurnitureTheme('sapphire', 'Sapphire', 'Saffier', 0xFF316BB5),
  _FurnitureTheme('rose', 'Rose', 'Roos', 0xFFC64F75),
  _FurnitureTheme('dragon', 'Dragon', 'Draken', 0xFF5F3E9D),
];

const _forms = <_FurnitureForm>[
  _FurnitureForm(
    'cushion',
    'cushion',
    'kussen',
    'A plump resting spot woven with themed magic.',
    'Een volle rustplek, geweven met thematische magie.',
    ItemSlot.bed,
  ),
  _FurnitureForm(
    'daybed',
    'daybed',
    'rustbed',
    'A roomy dragon bed for naps between adventures.',
    'Een ruim drakenbed voor dutjes tussen avonturen.',
    ItemSlot.bed,
  ),
  _FurnitureForm(
    'planter',
    'planter',
    'plantenpot',
    'A living accent that changes the feeling of a room.',
    'Levend groen dat de sfeer van een kamer verandert.',
    ItemSlot.plant,
  ),
  _FurnitureForm(
    'bonsai',
    'bonsai',
    'bonsai',
    'A tiny enchanted tree with a strong personality.',
    'Een betoverd boompje met een sterke persoonlijkheid.',
    ItemSlot.plant,
  ),
  _FurnitureForm(
    'tapestry',
    'tapestry',
    'wandkleed',
    'A hand-finished wall piece for a grander room.',
    'Een handgemaakt wandstuk voor een statige kamer.',
    ItemSlot.wall,
  ),
  _FurnitureForm(
    'shelf',
    'curio shelf',
    'pronkkastje',
    'A wall shelf filled with harmless little mysteries.',
    'Een wandplank vol ongevaarlijke kleine mysteries.',
    ItemSlot.wall,
  ),
  _FurnitureForm(
    'lantern',
    'glow lantern',
    'gloedlantaarn',
    'A warm magical light with its own soft color.',
    'Een warm magisch licht met een eigen zachte kleur.',
    ItemSlot.light,
  ),
  _FurnitureForm(
    'orb',
    'magic orb',
    'magische bol',
    'A floating spark of room-sized atmosphere.',
    'Een zwevende vonk die de hele kamer sfeer geeft.',
    ItemSlot.light,
  ),
];

final List<ShopItem> shopCatalog = List<ShopItem>.unmodifiable([
  ..._originalShopItems,
  for (final themeEntry in _themes.indexed)
    for (final formEntry in _forms.indexed)
      _generatedItem(
        themeEntry.$2,
        formEntry.$2,
        themeEntry.$1,
        formEntry.$1,
      ),
]);

final Map<String, ShopItem> _shopItemsById =
    Map<String, ShopItem>.unmodifiable({
  for (final item in shopCatalog) item.id: item,
});

ShopItem? shopItemById(String id) => _shopItemsById[id];

ShopItem _generatedItem(
  _FurnitureTheme theme,
  _FurnitureForm form,
  int themeIndex,
  int formIndex,
) {
  final visualSeed = 8 + themeIndex * _forms.length + formIndex;
  final rarityScore = (themeIndex * 3 + formIndex * 5) % 11;
  final rarity = rarityScore == 0
      ? ItemRarity.rare
      : rarityScore < 4
          ? ItemRarity.special
          : ItemRarity.common;
  final rarityPrice = switch (rarity) {
    ItemRarity.common => 0,
    ItemRarity.special => 9,
    ItemRarity.rare => 20,
  };
  final coinPrice = 8 + themeIndex * 2 + formIndex * 3 + rarityPrice;
  final currency = rarity == ItemRarity.rare && themeIndex.isEven
      ? ItemCurrency.gems
      : ItemCurrency.coins;
  return ShopItem(
    id: 'decor_${theme.id}_${form.id}',
    name: '${theme.nameEn} ${form.nameEn}',
    nameNl: '${theme.nameNl} ${form.nameNl}',
    description: form.descriptionEn,
    descriptionNl: form.descriptionNl,
    slot: form.slot,
    price: currency == ItemCurrency.gems ? (coinPrice / 9).ceil() : coinPrice,
    rarity: rarity,
    visualSeed: visualSeed,
    interactionTags: _interactionTags(form),
    emitsLight: form.slot == ItemSlot.light,
    lightType: _lightType(theme, form),
    nightActivation: form.slot == ItemSlot.light
        ? FurnitureNightActivation.duskAndNight
        : FurnitureNightActivation.none,
    glowRadius: form.slot == ItemSlot.light ? 0.22 : 0,
    hasAmbientAnimation:
        form.slot == ItemSlot.light || form.slot == ItemSlot.plant,
    currency: currency,
  );
}

List<String> _interactionTags(_FurnitureForm form) => switch (form.id) {
      'cushion' || 'daybed' => const ['bed'],
      'planter' || 'bonsai' => const ['plants'],
      'shelf' => const ['books', 'treasure'],
      'tapestry' => const ['treasure'],
      'lantern' || 'orb' => const ['magic'],
      _ => const [],
    };

FurnitureLightType _lightType(_FurnitureTheme theme, _FurnitureForm form) {
  if (form.slot != ItemSlot.light) return FurnitureLightType.none;
  if (const {'ember', 'sun'}.contains(theme.id)) {
    return FurnitureLightType.fire;
  }
  if (const {'honey', 'copper', 'meadow'}.contains(theme.id)) {
    return FurnitureLightType.warm;
  }
  if (const {'ocean', 'frost', 'cloud', 'sapphire'}.contains(theme.id)) {
    return FurnitureLightType.cool;
  }
  return FurnitureLightType.arcane;
}

int furnitureThemeColorValue(ShopItem item) {
  if (item.visualSeed < _originalShopItems.length) {
    return switch (item.slot) {
      ItemSlot.bed => 0xFFE4776B,
      ItemSlot.plant => 0xFF3F946A,
      ItemSlot.wall => 0xFF5F3E9D,
      ItemSlot.light => 0xFFD89C2B,
    };
  }
  final themeIndex = (item.visualSeed - 8) ~/ _forms.length;
  return _themes[themeIndex % _themes.length].colorValue;
}
