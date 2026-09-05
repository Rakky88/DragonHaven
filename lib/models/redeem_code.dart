enum RedeemRewardType { dragonEmotePack }

class RedeemCodeDefinition {
  const RedeemCodeDefinition({
    required this.code,
    required this.rewardType,
    required this.rewardId,
  });

  final String code;
  final RedeemRewardType rewardType;
  final String rewardId;
}

const redeemCodeCatalog = <RedeemCodeDefinition>[
  RedeemCodeDefinition(
    code: 'EMOTEPACK1',
    rewardType: RedeemRewardType.dragonEmotePack,
    rewardId: 'cozy_hatchlings',
  ),
  RedeemCodeDefinition(
    code: 'EMOTEPACK2',
    rewardType: RedeemRewardType.dragonEmotePack,
    rewardId: 'infernal_reactions',
  ),
  RedeemCodeDefinition(
    code: 'EMOTEPACK3',
    rewardType: RedeemRewardType.dragonEmotePack,
    rewardId: 'celestial_court',
  ),
];

final redeemCodesByCode = <String, RedeemCodeDefinition>{
  for (final definition in redeemCodeCatalog) definition.code: definition,
};

RedeemCodeDefinition? redeemCodeDefinition(String code) =>
    redeemCodesByCode[code];
