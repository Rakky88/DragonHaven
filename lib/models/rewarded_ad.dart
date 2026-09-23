enum RewardedAdCurrency { gems, coins }

extension RewardedAdCurrencyValue on RewardedAdCurrency {
  int get fallbackReward => this == RewardedAdCurrency.gems ? 15 : 150;
}

final class RewardedAdClaim {
  const RewardedAdClaim({
    required this.id,
    required this.token,
    required this.currency,
    required this.expiresAt,
  });

  final String id;
  final String token;
  final RewardedAdCurrency currency;
  final DateTime expiresAt;

  factory RewardedAdClaim.fromJson(Object? value) {
    final json = _object(value);
    final id = json['id'];
    final token = json['token'];
    final currency = json['currency'];
    final expiresAt = DateTime.tryParse(json['expiresAt']?.toString() ?? '');
    if (!_keys(json, const ['id', 'token', 'currency', 'expiresAt']) ||
        id is! String ||
        !_uuid.hasMatch(id) ||
        token is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(token) ||
        currency is! String ||
        !RewardedAdCurrency.values.any((item) => item.name == currency) ||
        expiresAt == null) {
      throw const FormatException('rewarded_ad_claim_invalid');
    }
    return RewardedAdClaim(
      id: id,
      token: token,
      currency: RewardedAdCurrency.values.byName(currency),
      expiresAt: expiresAt.toUtc(),
    );
  }
}

final class RewardedAdActiveClaim {
  const RewardedAdActiveClaim({
    required this.id,
    required this.status,
    required this.expiresAt,
  });
  final String id;
  final String status;
  final DateTime expiresAt;
  bool get verified => status == 'verified';

  factory RewardedAdActiveClaim.fromJson(Object? value) {
    final json = _object(value);
    final id = json['id'];
    final status = json['status'];
    final expiresAt = DateTime.tryParse(json['expiresAt']?.toString() ?? '');
    if (!_keys(json, const ['id', 'status', 'expiresAt']) ||
        id is! String ||
        !_uuid.hasMatch(id) ||
        status is! String ||
        !const {'issued', 'verified'}.contains(status) ||
        expiresAt == null) {
      throw const FormatException('rewarded_ad_active_claim_invalid');
    }
    return RewardedAdActiveClaim(
        id: id, status: status, expiresAt: expiresAt.toUtc());
  }
}

final class RewardedAdOffer {
  const RewardedAdOffer({
    required this.currency,
    required this.reward,
    required this.claimedToday,
    required this.remaining,
    this.activeClaim,
  });
  final RewardedAdCurrency currency;
  final int reward;
  final int claimedToday;
  final int remaining;
  final RewardedAdActiveClaim? activeClaim;

  factory RewardedAdOffer.fromJson(
      RewardedAdCurrency currency, Object? value, int dailyLimit) {
    final json = _object(value);
    final reward = json['reward'];
    final claimed = json['claimedToday'];
    final remaining = json['remaining'];
    if (!_keys(json,
            const ['reward', 'claimedToday', 'remaining', 'activeClaim']) ||
        reward is! int ||
        reward != currency.fallbackReward ||
        claimed is! int ||
        claimed < 0 ||
        claimed > dailyLimit ||
        remaining is! int ||
        remaining < 0 ||
        remaining > dailyLimit ||
        claimed + remaining > dailyLimit) {
      throw const FormatException('rewarded_ad_offer_invalid');
    }
    return RewardedAdOffer(
      currency: currency,
      reward: reward,
      claimedToday: claimed,
      remaining: remaining,
      activeClaim: json['activeClaim'] == null
          ? null
          : RewardedAdActiveClaim.fromJson(json['activeClaim']),
    );
  }
}

final class RewardedAdsStatus {
  const RewardedAdsStatus({
    required this.enabled,
    required this.dailyLimit,
    required this.nextResetAt,
    required this.offers,
  });
  final bool enabled;
  final int dailyLimit;
  final DateTime nextResetAt;
  final Map<RewardedAdCurrency, RewardedAdOffer> offers;
  RewardedAdOffer offer(RewardedAdCurrency currency) => offers[currency]!;

  factory RewardedAdsStatus.fromJson(Object? value) {
    final json = _object(value);
    final enabled = json['enabled'];
    final dailyLimit = json['dailyLimit'];
    final reset = DateTime.tryParse(json['nextResetAt']?.toString() ?? '');
    final offers = _object(json['offers']);
    if (!_keys(
            json, const ['enabled', 'dailyLimit', 'nextResetAt', 'offers']) ||
        !_keys(offers, const ['gems', 'coins']) ||
        enabled is! bool ||
        dailyLimit is! int ||
        dailyLimit < 1 ||
        dailyLimit > 20 ||
        reset == null ||
        !RewardedAdCurrency.values.every((c) => offers.containsKey(c.name))) {
      throw const FormatException('rewarded_ads_status_invalid');
    }
    return RewardedAdsStatus(
      enabled: enabled,
      dailyLimit: dailyLimit,
      nextResetAt: reset.toUtc(),
      offers: {
        for (final currency in RewardedAdCurrency.values)
          currency: RewardedAdOffer.fromJson(
              currency, offers[currency.name], dailyLimit),
      },
    );
  }
}

final class RewardedAdClaimStatus {
  const RewardedAdClaimStatus(this.status);
  final String status;
  bool get verified => status == 'verified';
  bool get terminal =>
      const {'claimed', 'cancelled', 'expired'}.contains(status);

  factory RewardedAdClaimStatus.fromJson(Object? value) {
    final json = _object(value);
    final status = json['status'];
    if (!_keys(json, const ['status']) ||
        status is! String ||
        !const {'issued', 'verified', 'claimed', 'cancelled', 'expired'}
            .contains(status)) {
      throw const FormatException('rewarded_ad_claim_status_invalid');
    }
    return RewardedAdClaimStatus(status);
  }
}

final _uuid = RegExp(r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$');

Map<String, dynamic> _object(Object? value) {
  if (value is! Map) {
    throw const FormatException('rewarded_ad_response_invalid');
  }
  return Map<String, dynamic>.from(value);
}

bool _keys(Map<String, dynamic> value, List<String> expected) =>
    value.length == expected.length && expected.every(value.containsKey);
