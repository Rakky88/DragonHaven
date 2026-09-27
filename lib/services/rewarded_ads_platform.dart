import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

final class RewardedAdsConsentState {
  const RewardedAdsConsentState({
    required this.canRequestAds,
    required this.privacyOptionsRequired,
  });
  final bool canRequestAds;
  final bool privacyOptionsRequired;
}

/// A show failure distinguishes a claim that is safe to release from one that
/// may already have reached an ad network. The latter must remain available
/// for a delayed, signed server-side verification callback.
final class RewardedAdShowException implements Exception {
  const RewardedAdShowException(this.code,
      {required this.claimMayHaveBeenShown});

  final String code;
  final bool claimMayHaveBeenShown;

  @override
  String toString() => 'RewardedAdShowException: $code';
}

/// Resolves a mediated ad only after dismissal and allows the reward callback
/// to arrive just after dismissal, as permitted by mediation adapters.
final class RewardedAdShowCompletion {
  RewardedAdShowCompletion({this.dismissalGrace = const Duration(seconds: 2)});

  final Duration dismissalGrace;
  final Completer<bool> _completion = Completer<bool>();
  Timer? _graceTimer;
  bool _dismissed = false;
  bool _earned = false;

  Future<bool> get future => _completion.future;

  void rewardEarned() {
    _earned = true;
    if (_dismissed && !_completion.isCompleted) {
      _graceTimer?.cancel();
      _completion.complete(true);
    }
  }

  void dismissed() {
    if (_dismissed || _completion.isCompleted) return;
    _dismissed = true;
    if (_earned) {
      _completion.complete(true);
      return;
    }
    _graceTimer = Timer(dismissalGrace, () {
      if (!_completion.isCompleted) _completion.complete(_earned);
    });
  }

  void failed(Object error, [StackTrace? stackTrace]) {
    _graceTimer?.cancel();
    if (!_completion.isCompleted) {
      _completion.completeError(error, stackTrace);
    }
  }

  void dispose() => _graceTimer?.cancel();
}

abstract interface class LoadedRewardedAd {
  Future<bool> show({required String customData, bool Function()? mayShow});
  Future<void> dispose();
}

abstract interface class RewardedAdsPlatform {
  Future<RewardedAdsConsentState> initializeConsent();
  Future<RewardedAdsConsentState> showPrivacyOptions();
  Future<LoadedRewardedAd> load(String adUnitId);
}

final class GoogleRewardedAdsPlatform implements RewardedAdsPlatform {
  GoogleRewardedAdsPlatform()
      : _loadAd = _loadGoogleAd,
        _loadTimeout = const Duration(seconds: 30),
        _foregroundTimeout = const Duration(seconds: 5);

  @visibleForTesting
  GoogleRewardedAdsPlatform.forTesting({
    required Future<void> Function(String, RewardedAdLoadCallback) loadAd,
    Duration loadTimeout = const Duration(seconds: 30),
    Duration foregroundTimeout = const Duration(seconds: 5),
  })  : _loadAd = loadAd,
        _loadTimeout = loadTimeout,
        _foregroundTimeout = foregroundTimeout;

  final Future<void> Function(String, RewardedAdLoadCallback) _loadAd;
  final Duration _loadTimeout;
  final Duration _foregroundTimeout;
  Future<void>? _mobileAdsInitialization;

  static Future<void> _loadGoogleAd(
          String adUnitId, RewardedAdLoadCallback callback) =>
      RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: callback,
      );

  @override
  Future<RewardedAdsConsentState> initializeConsent() async {
    Object? refreshFailure;
    StackTrace? refreshStack;
    try {
      final updated = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        updated.complete,
        (error) => updated
            .completeError(StateError('ad_consent_update_${error.errorCode}')),
      );
      await updated.future.timeout(const Duration(seconds: 15));
      final form = Completer<void>();
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error == null) {
          form.complete();
        } else {
          form.completeError(StateError('ad_consent_form_${error.errorCode}'));
        }
      });
      await form.future.timeout(const Duration(seconds: 30));
    } on Object catch (error, stack) {
      // UMP explicitly allows the previous session's canRequestAds value to
      // remain usable when a refresh fails. Read it before deciding whether
      // this launch has to retry later.
      refreshFailure = error;
      refreshStack = stack;
    }
    final state = await _finishConsent();
    if (refreshFailure != null && !state.canRequestAds) {
      Error.throwWithStackTrace(refreshFailure, refreshStack!);
    }
    return state;
  }

  Future<RewardedAdsConsentState> _finishConsent() async {
    final canRequest = await ConsentInformation.instance.canRequestAds();
    final privacy =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    if (canRequest) {
      _mobileAdsInitialization ??= MobileAds.instance.initialize();
      await _mobileAdsInitialization;
    }
    return RewardedAdsConsentState(
      canRequestAds: canRequest,
      privacyOptionsRequired:
          privacy == PrivacyOptionsRequirementStatus.required,
    );
  }

  @override
  Future<RewardedAdsConsentState> showPrivacyOptions() async {
    final shown = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error == null) {
        shown.complete();
      } else {
        shown.completeError(StateError('ad_privacy_form_${error.errorCode}'));
      }
    });
    await shown.future.timeout(const Duration(seconds: 30));
    return _finishConsent();
  }

  @override
  Future<LoadedRewardedAd> load(String adUnitId) async {
    final loaded = Completer<RewardedAd>();
    var abandoned = false;
    void failed(Object error, StackTrace stack) {
      if (!abandoned && !loaded.isCompleted) {
        loaded.completeError(error, stack);
      }
    }

    // The timeout covers both the platform-channel invocation and the SDK's
    // callback. An ad delivered after that deadline has no owner and is freed.
    unawaited(() async {
      try {
        await _loadAd(
          adUnitId,
          RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              if (abandoned || loaded.isCompleted) {
                unawaited(ad.dispose().catchError((Object _) {}));
              } else {
                loaded.complete(ad);
              }
            },
            onAdFailedToLoad: (error) => failed(
                StateError('rewarded_ad_load_${error.code}'),
                StackTrace.current),
          ),
        );
      } on Object catch (error, stack) {
        failed(error, stack);
      }
    }());
    try {
      return _GoogleLoadedRewardedAd(await loaded.future.timeout(_loadTimeout),
          foregroundTimeout: _foregroundTimeout);
    } on Object {
      abandoned = true;
      rethrow;
    }
  }
}

final class _GoogleLoadedRewardedAd implements LoadedRewardedAd {
  _GoogleLoadedRewardedAd(this.ad, {required this.foregroundTimeout});
  final RewardedAd ad;
  final Duration foregroundTimeout;
  bool _used = false;
  Future<void>? _disposal;

  Future<void> _waitForForeground() async {
    final binding = WidgetsBinding.instance;
    if (binding.lifecycleState == AppLifecycleState.resumed) return;
    final resumed = Completer<void>();
    final listener = AppLifecycleListener(
      binding: binding,
      onResume: () {
        if (!resumed.isCompleted) resumed.complete();
      },
    );
    try {
      if (binding.lifecycleState != AppLifecycleState.resumed) {
        await resumed.future.timeout(foregroundTimeout,
            onTimeout: () => throw const RewardedAdShowException(
                'rewarded_ad_not_foreground',
                claimMayHaveBeenShown: false));
      }
    } finally {
      listener.dispose();
    }
  }

  @override
  Future<bool> show(
      {required String customData, bool Function()? mayShow}) async {
    if (_used) throw StateError('rewarded_ad_already_used');
    _used = true;
    final completion = RewardedAdShowCompletion();
    var handedToSdk = false;
    void requireAccount() {
      if (_disposal != null || mayShow?.call() == false) {
        throw const RewardedAdShowException('rewarded_ad_account_changed',
            claimMayHaveBeenShown: false);
      }
    }

    try {
      requireAccount();
      await _waitForForeground();
      requireAccount();
      await ad.setServerSideOptions(
          ServerSideVerificationOptions(customData: customData));
      await _waitForForeground();
      requireAccount();
      ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
        onAdFailedToShowFullScreenContent: (shownAd, error) {
          unawaited(dispose());
          completion.failed(RewardedAdShowException(
              'rewarded_ad_show_${error.code}',
              claimMayHaveBeenShown: false));
        },
        onAdDismissedFullScreenContent: (shownAd) {
          unawaited(dispose());
          completion.dismissed();
        },
      );
      handedToSdk = true;
      await ad.show(onUserEarnedReward: (_, __) => completion.rewardEarned());
      return await completion.future.timeout(const Duration(minutes: 10),
          onTimeout: () => throw const RewardedAdShowException(
              'rewarded_ad_show_timeout',
              claimMayHaveBeenShown: true));
    } on RewardedAdShowException {
      await dispose();
      rethrow;
    } on Object catch (_, stack) {
      await dispose();
      Error.throwWithStackTrace(
          RewardedAdShowException('rewarded_ad_show_setup_failed',
              claimMayHaveBeenShown: handedToSdk),
          stack);
    } finally {
      completion.dispose();
    }
  }

  @override
  Future<void> dispose() => _disposal ??= ad.dispose();
}
