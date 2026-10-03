import 'dart:io';

enum RewardedAdsMode { disabled, test, production }

/// Compile-time-only Mobile Ads configuration.
///
/// Public AdMob identifiers are deliberately build defines. Account secrets,
/// payment details and service credentials never belong in the application.
final class RewardedAdsConfig {
  factory RewardedAdsConfig({
    required RewardedAdsMode mode,
    required String gemsAdUnitId,
    required String coinsAdUnitId,
    required String trialRefreshAdUnitId,
    bool? platformSupported,
  }) {
    final config = RewardedAdsConfig._(
      mode: mode,
      gemsAdUnitId: gemsAdUnitId.trim(),
      coinsAdUnitId: coinsAdUnitId.trim(),
      trialRefreshAdUnitId: trialRefreshAdUnitId.trim(),
      platformSupported: platformSupported ?? Platform.isAndroid,
    );
    config._validate();
    return config;
  }

  const RewardedAdsConfig._({
    required this.mode,
    required this.gemsAdUnitId,
    required this.coinsAdUnitId,
    required this.trialRefreshAdUnitId,
    required this.platformSupported,
  });

  static const androidTestAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const androidRewardedTestUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  final RewardedAdsMode mode;
  final String gemsAdUnitId;
  final String coinsAdUnitId;
  final String trialRefreshAdUnitId;
  final bool platformSupported;

  bool get enabled => mode != RewardedAdsMode.disabled && platformSupported;
  bool get testMode => mode == RewardedAdsMode.test;

  String adUnitId(String currency) => switch (currency) {
        'gems' => gemsAdUnitId,
        'coins' => coinsAdUnitId,
        'trial_refresh' => trialRefreshAdUnitId,
        _ => throw ArgumentError.value(currency, 'currency'),
      };

  factory RewardedAdsConfig.fromEnvironment() {
    const rawMode = String.fromEnvironment('DRAGONHAVEN_REWARDED_ADS_MODE',
        defaultValue: 'disabled');
    final mode =
        RewardedAdsMode.values.where((m) => m.name == rawMode).firstOrNull;
    if (mode == null) {
      throw const FormatException('rewarded_ads_mode_invalid');
    }
    const gems = String.fromEnvironment('DRAGONHAVEN_ADMOB_REWARDED_GEMS_ID',
        defaultValue: androidRewardedTestUnitId);
    const coins = String.fromEnvironment('DRAGONHAVEN_ADMOB_REWARDED_COINS_ID',
        defaultValue: androidRewardedTestUnitId);
    const trialRefresh = String.fromEnvironment(
        'DRAGONHAVEN_ADMOB_REWARDED_TRIAL_REFRESH_ID',
        defaultValue: androidRewardedTestUnitId);
    return RewardedAdsConfig(
        mode: mode,
        gemsAdUnitId: gems,
        coinsAdUnitId: coins,
        trialRefreshAdUnitId: trialRefresh);
  }

  void _validate() {
    final pattern = RegExp(r'^ca-app-pub-[0-9]{16}/[0-9]{10}$');
    if (mode == RewardedAdsMode.disabled) return;
    if (mode == RewardedAdsMode.test) {
      if (gemsAdUnitId != androidRewardedTestUnitId ||
          coinsAdUnitId != androidRewardedTestUnitId ||
          trialRefreshAdUnitId != androidRewardedTestUnitId) {
        throw const FormatException('rewarded_ads_test_id_required');
      }
      return;
    }
    if (!pattern.hasMatch(gemsAdUnitId) ||
        !pattern.hasMatch(coinsAdUnitId) ||
        !pattern.hasMatch(trialRefreshAdUnitId) ||
        {gemsAdUnitId, coinsAdUnitId, trialRefreshAdUnitId}.length != 3 ||
        gemsAdUnitId.split('/').first != coinsAdUnitId.split('/').first ||
        gemsAdUnitId.split('/').first !=
            trialRefreshAdUnitId.split('/').first ||
        gemsAdUnitId == androidRewardedTestUnitId ||
        coinsAdUnitId == androidRewardedTestUnitId ||
        trialRefreshAdUnitId == androidRewardedTestUnitId) {
      throw const FormatException('rewarded_ads_production_ids_invalid');
    }
  }
}
