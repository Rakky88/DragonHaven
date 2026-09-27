import 'keeper_level.dart';

class KeeperBadgeDefinition {
  const KeeperBadgeDefinition({
    required this.id,
    required this.nameEn,
    required this.nameNl,
    required this.assetPath,
    this.keeperLevel,
  });

  final String id;
  final String nameEn;
  final String nameNl;
  final String assetPath;
  final int? keeperLevel;
  bool get isGeneratedKeeperLevelBadge => keeperLevel != null;
}

class KeeperFrameDefinition {
  const KeeperFrameDefinition({
    required this.id,
    required this.nameEn,
    required this.nameNl,
    required this.assetPath,
    this.keeperLevel,
  });

  final String id;
  final String nameEn;
  final String nameNl;
  final String assetPath;
  final int? keeperLevel;
  bool get isGeneratedKeeperLevelFrame => keeperLevel != null;
}

const supporterBadge = KeeperBadgeDefinition(
  id: 'badge_supporter_founder',
  nameEn: 'Founding Supporter Badge',
  nameNl: 'Oprichterssupporter-badge',
  assetPath: 'assets/images/supporter/supporter_badge.png',
);

const heartboundPairBadge = KeeperBadgeDefinition(
  id: 'heartbound_pair',
  nameEn: 'Heartbound Pair Badge',
  nameNl: 'Hartverbonden Paar-badge',
  assetPath: 'assets/images/events/valentine/heartbound_pair_badge.webp',
);

const supporterFrame = KeeperFrameDefinition(
  id: 'frame_supporter_founder',
  nameEn: 'Founding Supporter Frame',
  nameNl: 'Oprichterssupporter-frame',
  assetPath: 'assets/images/supporter/supporter_frame.png',
);

final keeperLevelBadges = List<KeeperBadgeDefinition>.unmodifiable([
  for (var level = 2; level <= maximumKeeperLevel; level++)
    KeeperBadgeDefinition(
      id: keeperLevelBadgeId(level),
      nameEn: 'Keeper Level $level Badge',
      nameNl: 'Hoederniveau $level-badge',
      assetPath: '',
      keeperLevel: level,
    ),
]);

final allKeeperBadges = <KeeperBadgeDefinition>[
  supporterBadge,
  heartboundPairBadge,
  ...keeperLevelBadges,
];

KeeperBadgeDefinition? keeperBadgeById(String? id) {
  if (id == null) return null;
  for (final badge in allKeeperBadges) {
    if (badge.id == id) return badge;
  }
  return null;
}

const keeperLevel40Frame = KeeperFrameDefinition(
  id: keeperLevel40FrameId,
  nameEn: 'Keeper Level 40 Frame',
  nameNl: 'Hoederniveau 40-lijst',
  assetPath: '',
  keeperLevel: 40,
);

const allKeeperFrames = <KeeperFrameDefinition>[
  supporterFrame,
  keeperLevel40Frame,
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
