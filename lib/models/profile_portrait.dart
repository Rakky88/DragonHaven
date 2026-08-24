enum PortraitRarity { common, rare, veryRare, legendary, infernal, mythical }

class ProfilePortrait {
  const ProfilePortrait({
    required this.id,
    required this.number,
    required this.rarity,
  });

  final String id;
  final int number;
  final PortraitRarity rarity;

  String get assetPath =>
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

final Map<String, ProfilePortrait> _profilePortraitsById = Map.unmodifiable({
  for (final portrait in profilePortraitCatalog) portrait.id: portrait,
});

ProfilePortrait? profilePortraitById(String? id) =>
    id == null ? null : _profilePortraitsById[id];
