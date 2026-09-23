import 'package:dragon_haven/config/rewarded_ads_config.dart';
import 'package:dragon_haven/models/rewarded_ad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const claimId = '11111111-1111-4111-8111-111111111111';
  const token =
      'a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5';
  final status = {
    'enabled': true,
    'dailyLimit': 3,
    'nextResetAt': '2026-09-24T00:00:00Z',
    'offers': {
      'gems': {
        'reward': 15,
        'claimedToday': 1,
        'remaining': 2,
        'activeClaim': {
          'id': claimId,
          'status': 'verified',
          'expiresAt': '2026-09-23T12:15:00Z',
        },
      },
      'coins': {
        'reward': 150,
        'claimedToday': 0,
        'remaining': 3,
        'activeClaim': null,
      },
    },
  };

  test('strict server status exposes the fixed rewards and pending claim', () {
    final parsed = RewardedAdsStatus.fromJson(status);
    expect(parsed.enabled, isTrue);
    expect(parsed.offer(RewardedAdCurrency.gems).reward, 15);
    expect(parsed.offer(RewardedAdCurrency.gems).activeClaim!.verified, isTrue);
    expect(parsed.offer(RewardedAdCurrency.coins).reward, 150);
  });

  test('server status rejects altered rewards, counts and extra fields', () {
    Map<String, dynamic> copy() => {
          ...status,
          'offers': {
            for (final entry in (status['offers'] as Map).entries)
              entry.key: Map<String, dynamic>.from(entry.value as Map),
          },
        };

    final alteredReward = copy();
    (alteredReward['offers'] as Map)['gems']['reward'] = 5000;
    expect(() => RewardedAdsStatus.fromJson(alteredReward),
        throwsA(isA<FormatException>()));

    final reservedAttempt = copy();
    (reservedAttempt['offers'] as Map)['coins']['remaining'] = 2;
    expect(
        RewardedAdsStatus.fromJson(reservedAttempt)
            .offer(RewardedAdCurrency.coins)
            .remaining,
        2);

    final alteredCount = copy();
    (alteredCount['offers'] as Map)['coins']['claimedToday'] = 2;
    (alteredCount['offers'] as Map)['coins']['remaining'] = 2;
    expect(() => RewardedAdsStatus.fromJson(alteredCount),
        throwsA(isA<FormatException>()));

    final extra = copy()..['clientMayGrant'] = true;
    expect(() => RewardedAdsStatus.fromJson(extra),
        throwsA(isA<FormatException>()));
  });

  test('claim parser accepts only opaque claims with exact fields', () {
    final claim = RewardedAdClaim.fromJson({
      'id': claimId,
      'token': token,
      'currency': 'coins',
      'expiresAt': '2026-09-23T12:15:00Z',
    });
    expect(claim.currency, RewardedAdCurrency.coins);
    expect(
        () => RewardedAdClaim.fromJson({
              'id': claimId,
              'token': token,
              'currency': 'gold',
              'expiresAt': '2026-09-23T12:15:00Z',
            }),
        throwsA(isA<FormatException>()));
  });

  test('build configuration fences test and production ad units', () {
    final testConfig = RewardedAdsConfig(
      mode: RewardedAdsMode.test,
      gemsAdUnitId: RewardedAdsConfig.androidRewardedTestUnitId,
      coinsAdUnitId: RewardedAdsConfig.androidRewardedTestUnitId,
    );
    expect(testConfig.testMode, isTrue);

    expect(
        () => RewardedAdsConfig(
              mode: RewardedAdsMode.production,
              gemsAdUnitId: RewardedAdsConfig.androidRewardedTestUnitId,
              coinsAdUnitId: RewardedAdsConfig.androidRewardedTestUnitId,
            ),
        throwsA(isA<FormatException>()));

    final production = RewardedAdsConfig(
      mode: RewardedAdsMode.production,
      gemsAdUnitId: 'ca-app-pub-1234567890123456/1234567890',
      coinsAdUnitId: 'ca-app-pub-1234567890123456/0987654321',
    );
    expect(
        production.adUnitId('gems'), 'ca-app-pub-1234567890123456/1234567890');
    expect(
        () => RewardedAdsConfig(
              mode: RewardedAdsMode.production,
              gemsAdUnitId: 'ca-app-pub-1234567890123456/1234567890',
              coinsAdUnitId: 'ca-app-pub-9999999999999999/0987654321',
            ),
        throwsA(isA<FormatException>()));
  });
}
