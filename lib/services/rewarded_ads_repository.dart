import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/rewarded_ad.dart';

abstract interface class RewardedAdsRepository {
  Future<RewardedAdsStatus> status();
  Future<RewardedAdClaim> issue(RewardedAdPlacement placement,
      {String? trialOfferId});
  Future<RewardedAdClaimStatus> claimStatus(String claimId);
  Future<bool> cancel(String claimId);
}

final class SupabaseRewardedAdsRepository implements RewardedAdsRepository {
  const SupabaseRewardedAdsRepository(this.client);
  final SupabaseClient client;
  static const _timeout = Duration(seconds: 15);

  @override
  Future<RewardedAdsStatus> status() async => RewardedAdsStatus.fromJson(
      await client.rpc('get_my_rewarded_ad_status').timeout(_timeout));

  @override
  Future<RewardedAdClaim> issue(RewardedAdPlacement placement,
          {String? trialOfferId}) async =>
      RewardedAdClaim.fromJson(placement == RewardedAdPlacement.trialRefresh
          ? await client.rpc('issue_my_trial_refresh_ad_claim', params: {
              'p_offer_id': trialOfferId,
            }).timeout(_timeout)
          : await client.rpc('issue_my_rewarded_ad_claim', params: {
              'p_currency': placement.wireName,
            }).timeout(_timeout));

  @override
  Future<RewardedAdClaimStatus> claimStatus(String claimId) async =>
      RewardedAdClaimStatus.fromJson(await client.rpc(
          'get_my_rewarded_ad_claim',
          params: {'p_claim_id': claimId}).timeout(_timeout));

  @override
  Future<bool> cancel(String claimId) async {
    final result = await client.rpc('cancel_my_rewarded_ad_claim',
        params: {'p_claim_id': claimId}).timeout(_timeout);
    if (result is! bool) {
      throw const FormatException('rewarded_ad_cancel_response_invalid');
    }
    return result;
  }
}
