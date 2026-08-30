enum PortraitRarity { common, rare, veryRare, legendary, infernal, mythical }

extension PortraitRarityPresentation on PortraitRarity {
  int get colorValue => switch (this) {
        PortraitRarity.common => 0xFFD9B84E,
        PortraitRarity.rare => 0xFF3F8FE5,
        PortraitRarity.veryRare => 0xFF8157D9,
        PortraitRarity.legendary => 0xFFD39B21,
        PortraitRarity.infernal => 0xFFD94B3D,
        PortraitRarity.mythical => 0xFF2A9CB8,
      };

  bool get hasGlow => this != PortraitRarity.common;
}

class ProfilePortrait {
  const ProfilePortrait({
    required this.id,
    required this.number,
    required this.rarity,
    this.assetPathOverride,
    this.supporterExclusive = false,
  });

  final String id;
  final int number;
  final PortraitRarity rarity;
  final String? assetPathOverride;
  final bool supporterExclusive;

  String get assetPath =>
      assetPathOverride ??
      'assets/images/portraits/portrait_${number.toString().padLeft(3, '0')}.webp';
}

final List<ProfilePortrait> profilePortraitCatalog = List.unmodifiable(
  List.generate(100, (index) {
    final number = index + 1;
    final rarity = switch (number) {
      <= 88 => PortraitRarity.common,
      <= 93 => PortraitRarity.rare,
      <= 96 => PortraitRarity.veryRare,
      <= 98 => PortraitRarity.legendary,
      99 => PortraitRarity.infernal,
      _ => PortraitRarity.mythical,
    };
    return ProfilePortrait(
      id: 'portrait_${number.toString().padLeft(3, '0')}',
      number: number,
      rarity: rarity,
    );
  }),
);

const supporterProfilePortrait = ProfilePortrait(
  id: 'portrait_supporter_founder',
  number: 0,
  rarity: PortraitRarity.legendary,
  assetPathOverride: 'assets/images/supporter/supporter_portrait.png',
  supporterExclusive: true,
);

final List<ProfilePortrait> allProfilePortraits = List.unmodifiable([
  ...profilePortraitCatalog,
  supporterProfilePortrait,
]);

final Map<String, ProfilePortrait> _profilePortraitsById = Map.unmodifiable({
  for (final portrait in allProfilePortraits) portrait.id: portrait,
});

ProfilePortrait? profilePortraitById(String? id) =>
    id == null ? null : _profilePortraitsById[id];
