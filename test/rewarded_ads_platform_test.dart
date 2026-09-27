import 'dart:async';

import 'package:dragon_haven/services/rewarded_ads_platform.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class _Ad extends Fake implements RewardedAd {
  @override
  FullScreenContentCallback<RewardedAd>? fullScreenContentCallback;

  ServerSideVerificationOptions? verification;
  Future<void> Function()? onVerification;
  int shows = 0;
  int disposals = 0;

  @override
  Future<void> setServerSideOptions(
      ServerSideVerificationOptions options) async {
    verification = options;
    await onVerification?.call();
  }

  @override
  Future<void> show(
      {required OnUserEarnedRewardCallback onUserEarnedReward}) async {
    shows++;
    fullScreenContentCallback?.onAdShowedFullScreenContent?.call(this);
    onUserEarnedReward(this, RewardItem(15, 'gems'));
    fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(this);
  }

  @override
  Future<void> dispose() async => disposals++;
}

GoogleRewardedAdsPlatform _withAd(_Ad ad) =>
    GoogleRewardedAdsPlatform.forTesting(
      loadAd: (_, callback) async => callback.onAdLoaded(ad),
      foregroundTimeout: const Duration(seconds: 1),
    );

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(
      () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
  tearDown(
      () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));

  testWidgets('load deadline also covers an unresponsive native invocation',
      (tester) async {
    late RewardedAdLoadCallback callback;
    final nativeCall = Completer<void>();
    final platform = GoogleRewardedAdsPlatform.forTesting(
      loadTimeout: const Duration(seconds: 1),
      loadAd: (_, value) {
        callback = value;
        return nativeCall.future;
      },
    );
    final result = expectLater(
        platform.load('test-unit'), throwsA(isA<TimeoutException>()));
    await tester.pump(const Duration(seconds: 2));
    await result;

    final lateAd = _Ad();
    callback.onAdLoaded(lateAd);
    callback.onAdFailedToLoad(LoadAdError(3, 'test', 'late failure', null));
    nativeCall.completeError(StateError('late native failure'));
    await tester.pump();
    expect(lateAd.disposals, 1);
    expect(lateAd.shows, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a ready ad immediately shows in a resumed app and disposes once',
      (tester) async {
    final ad = _Ad();
    final loaded = await _withAd(ad).load('test-unit');

    expect(await loaded.show(customData: 'opaque-claim-token'), isTrue);
    expect(ad.shows, 1);
    expect(ad.verification?.customData, 'opaque-claim-token');
    await loaded.dispose();
    await loaded.dispose();
    expect(ad.disposals, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an ad waits for the app to return to the foreground',
      (tester) async {
    final ad = _Ad();
    final loaded = await _withAd(ad).load('test-unit');
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

    final result = loaded.show(customData: 'opaque-claim-token');
    await tester.pump();
    expect(ad.shows, 0);
    expect(ad.verification, isNull);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(await result, isTrue);
    expect(ad.shows, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('backgrounding during SSV setup cannot launch a hidden ad',
      (tester) async {
    final ad = _Ad();
    ad.onVerification = () async {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    };
    final loaded = await _withAd(ad).load('test-unit');
    final result = loaded.show(customData: 'opaque-claim-token');
    await tester.pump();
    expect(ad.verification?.customData, 'opaque-claim-token');
    expect(ad.shows, 0);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(await result, isTrue);
    expect(ad.shows, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remaining backgrounded releases a definitely unshown claim',
      (tester) async {
    final ad = _Ad();
    final loaded = await _withAd(ad).load('test-unit');
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

    final result = expectLater(
        loaded.show(customData: 'opaque-claim-token'),
        throwsA(isA<RewardedAdShowException>()
            .having((e) => e.code, 'code', 'rewarded_ad_not_foreground')
            .having((e) => e.claimMayHaveBeenShown, 'may have shown', false)));
    await tester.pump(const Duration(seconds: 2));
    await result;
    expect(ad.shows, 0);
    expect(ad.disposals, 1);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(ad.shows, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account change during setup prevents the native ad from opening',
      (tester) async {
    var currentAccount = true;
    final ad = _Ad();
    ad.onVerification = () async {
      currentAccount = false;
    };
    final loaded = await _withAd(ad).load('test-unit');
    await expectLater(
        loaded.show(customData: 'claim', mayShow: () => currentAccount),
        throwsA(isA<RewardedAdShowException>()
            .having((e) => e.claimMayHaveBeenShown, 'shown', false)));
    expect(ad.shows, 0);
    expect(ad.disposals, 1);
  });
}
