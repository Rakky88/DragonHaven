class KeeperBadgeDefinition {
  const KeeperBadgeDefinition({
    required this.id,
    required this.nameEn,
    required this.nameNl,
    required this.assetPath,
  });

  final String id;
  final String nameEn;
  final String nameNl;
  final String assetPath;
}

class KeeperFrameDefinition {
  const KeeperFrameDefinition({
    required this.id,
    required this.nameEn,
    required this.nameNl,
    required this.assetPath,
  });

  final String id;
  final String nameEn;
  final String nameNl;
  final String assetPath;
}

const supporterBadge = KeeperBadgeDefinition(
  id: 'badge_supporter_founder',
  nameEn: 'Founding Supporter Badge',
  nameNl: 'Oprichterssupporter-badge',
  assetPath: 'assets/images/supporter/supporter_badge.png',
);

const supporterFrame = KeeperFrameDefinition(
  id: 'frame_supporter_founder',
  nameEn: 'Founding Supporter Frame',
  nameNl: 'Oprichterssupporter-frame',
  assetPath: 'assets/images/supporter/supporter_frame.png',
);

const allKeeperFrames = <KeeperFrameDefinition>[
  supporterFrame,
];

KeeperFrameDefinition? keeperFrameById(String? id) {
  if (id == null) return null;
  for (final frame in allKeeperFrames) {
    if (frame.id == id) return frame;
  }
  return null;
}

const supporterPackInternalProductId = 'supporter_pack_founder_299';
const supporterPackPlannedEuroPriceCents = 299;
