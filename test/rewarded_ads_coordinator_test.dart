import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/config/rewarded_ads_config.dart';
import 'package:dragon_haven/models/rewarded_ad.dart';
import 'package:dragon_haven/services/canonical_game_connection.dart';
import 'package:dragon_haven/services/canonical_game_intent.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/canonical_rewarded_ads.dart';
import 'package:dragon_haven/services/rewarded_ads_platform.dart';
import 'package:dragon_haven/services/rewarded_ads_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _claimId = '22222222-2222-4222-8222-222222222222';
const _token =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dismissal allows a mediated reward callback to arrive afterwards',
      () async {
    final completion = RewardedAdShowCompletion(
        dismissalGrace: const Duration(milliseconds: 40));
    completion.dismissed();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    completion.rewardEarned();
    expect(await completion.future, isTrue);
    completion.dispose();
  });

  test('dismissal without a reward finishes after the grace period', () async {
    final completion = RewardedAdShowCompletion(
        dismissalGrace: const Duration(milliseconds: 5));
    completion.dismissed();
    expect(await completion.future, isFalse);
    completion.dispose();
  });

  group('canonical rewarded ads', () {
    late Directory directory;
    late _Connection connection;
    late CanonicalGameSession session;
    late _Repository repository;
    late _Platform platform;
    late CanonicalRewardedAds ads;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('rewarded-ads-test-');
      connection = _Connection();
      session = CanonicalGameSession(
          connection: connection,
          directory: directory,
          expectedAuthority: CanonicalGameAuthority.server);
      repository = _Repository();
      platform = _Platform();
      ads = CanonicalRewardedAds(
          session: session,
          repository: repository,
          platform: platform,
          config: RewardedAdsConfig(
              mode: RewardedAdsMode.test,
              gemsAdUnitId: RewardedAdsConfig.androidRewardedTestUnitId,
              coinsAdUnitId: RewardedAdsConfig.androidRewardedTestUnitId,
              platformSupported: true));
    });

    tearDown(() async {
      ads.dispose();
      session.dispose();
      await directory.delete(recursive: true);
    });

    test('a closed ad keeps its claim available for delayed signed SSV',
        () async {
      platform.loaded.result = false;
      repository.claimStates.add(const RewardedAdClaimStatus('expired'));
      await ads.initialize();

      expect(await ads.watch(RewardedAdCurrency.gems),
          RewardedAdWatchOutcome.closedEarly);
      expect(repository.cancelled, isEmpty);
      expect(platform.loaded.customData, _token);
    });

    test('an explicit pre-display failure releases its claim', () async {
      platform.loaded.error = const RewardedAdShowException(
          'rewarded_ad_show_0',
          claimMayHaveBeenShown: false);
      await ads.initialize();

      await expectLater(
          ads.watch(RewardedAdCurrency.gems),
          throwsA(isA<RewardedAdShowException>().having(
              (error) => error.claimMayHaveBeenShown,
              'claimMayHaveBeenShown',
              isFalse)));
      expect(repository.cancelled, [_claimId]);
    });

    test('an uncertain show failure preserves its claim', () async {
      platform.loaded.error = const RewardedAdShowException(
          'rewarded_ad_show_timeout',
          claimMayHaveBeenShown: true);
      await ads.initialize();

      await expectLater(ads.watch(RewardedAdCurrency.gems),
          throwsA(isA<RewardedAdShowException>()));
      expect(repository.cancelled, isEmpty);
    });

    test('UI handoff precedes showing and never grants a reward by itself',
        () async {
      final handoffStarted = Completer<void>();
      final painted = Completer<void>();
      final dismissed = Completer<bool>();
      platform.loaded.dismissal = dismissed.future;
      await ads.initialize();
      final watching = ads.watch(RewardedAdCurrency.gems, beforeShow: () {
        handoffStarted.complete();
        return painted.future;
      });
      await handoffStarted.future;
      expect(repository.issueCalls, 1);
      expect(ads.busy(RewardedAdCurrency.gems), isTrue);
      expect(ads.earnedPending(RewardedAdCurrency.gems), isFalse);
      painted.complete();
      await Future<void>.delayed(Duration.zero);
      expect(ads.earnedPending(RewardedAdCurrency.gems), isFalse);

      dismissed.complete(true);
      expect(await watching, RewardedAdWatchOutcome.rewardPreviewed);
      expect(ads.earnedPending(RewardedAdCurrency.gems), isTrue);
      expect(repository.cancelled, isEmpty);
    });

    test('consent failure does not prevent recovery and retries on resume',
        () async {
      platform.consentFailures = 1;
      await ads.initialize();
      expect(repository.statusCalls, 1);
      expect(ads.canRequestAds, isFalse);

      await ads.resumed();
      expect(platform.consentCalls, 2);
      expect(repository.statusCalls, 2);
      expect(ads.canRequestAds, isTrue);
    });

    test('preloads both currencies without reserving any reward', () async {
      await ads.initialize();
      await ads.prepare(RewardedAdCurrency.gems);
      await ads.prepare(RewardedAdCurrency.coins);
      expect(platform.loadCalls, 2);
      expect(repository.issueCalls, 0);
      await ads.prepare(RewardedAdCurrency.gems);
      expect(platform.loadCalls, 2);
      expect(ads.ready(RewardedAdCurrency.gems), isTrue);
    });

    test('earned dismissal returns immediately while verification is pending',
        () async {
      await ads.initialize();
      await ads.prepare(RewardedAdCurrency.gems);
      final statusReadsBeforeTap = repository.statusCalls;
      final outcome = await ads.watch(RewardedAdCurrency.gems);
      expect(outcome, RewardedAdWatchOutcome.rewardPreviewed);
      expect(ads.earnedPending(RewardedAdCurrency.gems), isTrue);
      expect(ads.busy(RewardedAdCurrency.gems), isFalse);
      expect(repository.issueCalls, 1);
      expect(repository.statusCalls, statusReadsBeforeTap);
      expect(repository.claimReads, 0);
      final journal = jsonDecode(
          await File('${directory.path}/rewarded-earned-$_owner.json')
              .readAsString());
      expect(journal['owner'], _owner);
      expect(journal['claims'], {_claimId: 'gems'});
    });

    test(
        'earned journal survives a restart and an explicit expiry rolls it back',
        () async {
      await ads.initialize();
      await ads.watch(RewardedAdCurrency.gems);
      ads.dispose();
      ads = CanonicalRewardedAds(
          session: session,
          repository: repository,
          platform: platform,
          config: RewardedAdsConfig(
              mode: RewardedAdsMode.test,
              gemsAdUnitId: RewardedAdsConfig.androidRewardedTestUnitId,
              coinsAdUnitId: RewardedAdsConfig.androidRewardedTestUnitId,
              platformSupported: true));
      await ads.initialize();
      expect(ads.earnedPending(RewardedAdCurrency.gems), isTrue);
      repository.claimStates.add(const RewardedAdClaimStatus('expired'));
      await ads.refresh();
      expect(ads.earnedPending(RewardedAdCurrency.gems), isFalse);
      expect(ads.error(RewardedAdCurrency.gems),
          'rewarded_ad_verification_failed');
      final journal = jsonDecode(
          await File('${directory.path}/rewarded-earned-$_owner.json')
              .readAsString());
      expect(journal['claims'], isEmpty);
    });

    test('an account change while showing never previews the old reward',
        () async {
      final dismissed = Completer<bool>();
      platform.loaded.dismissal = dismissed.future;
      await ads.initialize();
      final showing = ads.watch(RewardedAdCurrency.gems);
      while (platform.loaded.customData == null) {
        await Future<void>.delayed(Duration.zero);
      }
      connection.currentOwner = '99999999-9999-4999-8999-999999999999';
      connection.sessionEpoch++;
      final failure = expectLater(showing, throwsStateError);
      dismissed.complete(true);
      await failure;
      expect(ads.earnedPending(RewardedAdCurrency.gems), isFalse);
      expect(
          await File('${directory.path}/rewarded-earned-$_owner.json').exists(),
          isFalse);
    });

    test('claimed status alone cannot discard an unconfirmed wallet preview',
        () async {
      await ads.initialize();
      await ads.watch(RewardedAdCurrency.gems);
      repository.claimStates.add(const RewardedAdClaimStatus('claimed'));
      // This session has not synchronized yet, so a background wallet read
      // cannot run. Retain evidence and retry instead of losing the reward.
      await ads.refresh();
      expect(ads.earnedPending(RewardedAdCurrency.gems), isTrue);
    });
  });
}

final class _Connection implements CanonicalGameConnection {
  final _changes = StreamController<int>.broadcast();

  @override
  String? currentOwner = _owner;

  @override
  int sessionEpoch = 1;

  @override
  Stream<int> get accountChanges => _changes.stream;

  @override
  Future<void> dispose() => _changes.close();

  @override
  Future<Object?> read(Map<String, dynamic> request) =>
      throw UnimplementedError();

  @override
  Future<Object?> recover(String requestId) => throw UnimplementedError();

  @override
  Future<CanonicalGameHttpReply> send(CanonicalGameIntent intent) =>
      throw UnimplementedError();
}

final class _LoadedAd implements LoadedRewardedAd {
  bool result = true;
  Object? error;
  String? customData;
  Future<bool>? dismissal;

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> show(
      {required String customData,
      bool Function()? mayShow,
      Future<void> Function()? beforeShow}) async {
    this.customData = customData;
    final failure = error;
    if (failure != null) throw failure;
    await beforeShow?.call();
    return dismissal == null ? result : await dismissal!;
  }
}

final class _Platform implements RewardedAdsPlatform {
  final loaded = _LoadedAd();
  int consentCalls = 0;
  int consentFailures = 0;
  int loadCalls = 0;

  @override
  Future<RewardedAdsConsentState> initializeConsent() async {
    consentCalls++;
    if (consentFailures > 0) {
      consentFailures--;
      throw StateError('consent unavailable');
    }
    return const RewardedAdsConsentState(
        canRequestAds: true, privacyOptionsRequired: true);
  }

  @override
  Future<LoadedRewardedAd> load(String adUnitId) async {
    loadCalls++;
    return loaded;
  }

  @override
  Future<RewardedAdsConsentState> showPrivacyOptions() async =>
      const RewardedAdsConsentState(
          canRequestAds: true, privacyOptionsRequired: true);
}

final class _Repository implements RewardedAdsRepository {
  final cancelled = <String>[];
  final claimStates = <RewardedAdClaimStatus>[];
  int statusCalls = 0;
  int issueCalls = 0;
  int claimReads = 0;

  RewardedAdsStatus get currentStatus => RewardedAdsStatus(
          enabled: true,
          dailyLimit: 3,
          nextResetAt: DateTime.now().toUtc().add(const Duration(days: 1)),
          offers: {
            for (final currency in RewardedAdCurrency.values)
              currency: RewardedAdOffer(
                  currency: currency,
                  reward: currency.fallbackReward,
                  claimedToday: 0,
                  remaining: 3),
          });

  @override
  Future<bool> cancel(String claimId) async {
    cancelled.add(claimId);
    return true;
  }

  @override
  Future<RewardedAdClaimStatus> claimStatus(String claimId) async {
    claimReads++;
    return claimStates.isEmpty
        ? const RewardedAdClaimStatus('issued')
        : claimStates.removeAt(0);
  }

  @override
  Future<RewardedAdClaim> issue(RewardedAdCurrency currency) async {
    issueCalls++;
    return RewardedAdClaim(
        id: _claimId,
        token: _token,
        currency: currency,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)));
  }

  @override
  Future<RewardedAdsStatus> status() async {
    statusCalls++;
    return currentStatus;
  }
}
