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

// Keep the redemption infrastructure available for future campaigns, while an
// empty catalog makes every previously distributed code inactive.
const redeemCodeCatalog = <RedeemCodeDefinition>[];

final redeemCodesByCode = <String, RedeemCodeDefinition>{
  for (final definition in redeemCodeCatalog) definition.code: definition,
};

RedeemCodeDefinition? redeemCodeDefinition(String code) =>
    redeemCodesByCode[code];
