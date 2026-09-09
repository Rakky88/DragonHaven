enum RedeemRewardType {
  dragonEmotePack,
  seasonalEventPreview,
  endSeasonalEvent
}

class RedeemCodeDefinition {
  const RedeemCodeDefinition({
    required this.code,
    required this.rewardType,
    required this.rewardId,
    this.restrictedKeeperId,
  });

  final String code;
  final RedeemRewardType rewardType;
  final String rewardId;
  final String? restrictedKeeperId;
}

// Preview codes are server-authorized for every verified keeper. Never expose active
// codes in public release notes; maintain the private REDEEM_CODES.md ledger.
const redeemCodeCatalog = <RedeemCodeDefinition>[
  RedeemCodeDefinition(
    code: 'ENDEVENT',
    rewardType: RedeemRewardType.endSeasonalEvent,
    rewardId: 'end_active_event',
  ),
  RedeemCodeDefinition(
    code: 'HALLOWEENEVENT',
    rewardType: RedeemRewardType.seasonalEventPreview,
    rewardId: 'halloween_witchlight',
  ),
  RedeemCodeDefinition(
    code: 'CHRISTMASEVENT',
    rewardType: RedeemRewardType.seasonalEventPreview,
    rewardId: 'christmas_winter_hearth',
  ),
  RedeemCodeDefinition(
    code: 'NEWYEARSEVENT',
    rewardType: RedeemRewardType.seasonalEventPreview,
    rewardId: 'new_year_first_dawn',
  ),
  RedeemCodeDefinition(
    code: 'VALENTINEEVENT',
    rewardType: RedeemRewardType.seasonalEventPreview,
    rewardId: 'valentine_two_heartlights',
  ),
  RedeemCodeDefinition(
    code: 'PRIDEFESTEVENT',
    rewardType: RedeemRewardType.seasonalEventPreview,
    rewardId: 'pride_every_color',
  ),
];

final redeemCodesByCode = <String, RedeemCodeDefinition>{
  for (final definition in redeemCodeCatalog) definition.code: definition,
};

RedeemCodeDefinition? redeemCodeDefinition(String code) =>
    redeemCodesByCode[code];
