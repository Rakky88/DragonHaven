import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/rewarded_ad.dart';

abstract interface class RewardedAdsRepository {
  Future<RewardedAdsStatus> status();
  Future<RewardedAdClaim> issue(RewardedAdCurrency currency);
  Future<RewardedAdClaimStatus> claimStatus(String claimId);
  Future<bool> cancel(String claimId);
}

final class SupabaseRewardedAdsRepository implements RewardedAdsRepository {
  const SupabaseRewardedAdsRepository(this.client);
  final SupabaseClient client;

  @override
  Future<RewardedAdsStatus> status() async =>
      RewardedAdsStatus.fromJson(await client.rpc('get_my_rewarded_ad_status'));

  @override
  Future<RewardedAdClaim> issue(RewardedAdCurrency currency) async =>
      RewardedAdClaim.fromJson(await client.rpc('issue_my_rewarded_ad_claim',
          params: {'p_currency': currency.name}));

  @override
  Future<RewardedAdClaimStatus> claimStatus(String claimId) async =>
      RewardedAdClaimStatus.fromJson(await client
          .rpc('get_my_rewarded_ad_claim', params: {'p_claim_id': claimId}));

  @override
  Future<bool> cancel(String claimId) async {
    final result = await client
        .rpc('cancel_my_rewarded_ad_claim', params: {'p_claim_id': claimId});
    if (result is! bool) {
      throw const FormatException('rewarded_ad_cancel_response_invalid');
    }
    return result;
  }
}
