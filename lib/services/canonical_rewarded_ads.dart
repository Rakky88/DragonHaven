import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/rewarded_ads_config.dart';
import '../models/rewarded_ad.dart';
import 'canonical_game_actions.dart';
import 'canonical_game_session.dart';
import 'canonical_game_snapshot.dart';
import 'rewarded_ads_platform.dart';
import 'rewarded_ads_repository.dart';

enum RewardedAdWatchOutcome { rewarded, closedEarly, pendingVerification }

/// Account-scoped rewarded-ad coordinator.
///
/// Google callbacks never mutate the wallet. A reward becomes visible only
/// after SSV has marked the private claim verified and the canonical command
/// has committed the server revision.
final class CanonicalRewardedAds extends ChangeNotifier {
  static const _initialRefreshBackoff = Duration(seconds: 15);
  static const _maximumRefreshBackoff = Duration(minutes: 5);
  static const _initialVerificationBackoff = Duration(seconds: 5);
  static const _maximumVerificationBackoff = Duration(minutes: 1);

  CanonicalRewardedAds({
    required this.session,
    required this.repository,
    required this.platform,
    required this.config,
  })  : _owner = session.connection.currentOwner,
        _epoch = session.connection.sessionEpoch;

  final CanonicalGameSession session;
  final RewardedAdsRepository repository;
  final RewardedAdsPlatform platform;
  final RewardedAdsConfig config;
  final String? _owner;
  final int _epoch;
  final _busy = <RewardedAdCurrency>{};
  final _errors = <RewardedAdCurrency, String>{};
  RewardedAdsStatus? _status;
  RewardedAdsConsentState? _consent;
  bool _initializing = false;
  bool _disposed = false;
  bool _consentRetryNeeded = false;
  Duration _refreshBackoff = _initialRefreshBackoff;
  Duration _verificationBackoff = _initialVerificationBackoff;
  Timer? _nextRefresh;

  RewardedAdsStatus? get status => _current ? _status : null;
  bool get initializing => _initializing;
  bool get privacyOptionsRequired =>
      config.enabled && (_consent?.privacyOptionsRequired ?? false);
  bool get canRequestAds => config.enabled && _consent?.canRequestAds == true;
  bool busy(RewardedAdCurrency currency) => _busy.contains(currency);
  String? error(RewardedAdCurrency currency) => _errors[currency];

  bool get _current =>
      !_disposed &&
      _owner != null &&
      session.connection.currentOwner == _owner &&
      session.connection.sessionEpoch == _epoch;

  Future<void> initialize() async {
    if (_disposed || _initializing || !config.enabled) return;
    _initializing = true;
    notifyListeners();
    try {
      try {
        // Consent is refreshed on every app launch before any ad request.
        _consent = await platform.initializeConsent();
        _consentRetryNeeded = false;
        _requireCurrent();
      } on Object {
        // Reward recovery is independent from consent. Keep a prior UMP state
        // intact, retry consent on resume and still reconcile server claims.
        if (_current) _consentRetryNeeded = true;
      }
      try {
        await refresh(recoverVerified: true);
      } on Object {
        if (_current) _scheduleRefreshRetry();
      }
    } finally {
      if (_current) {
        _initializing = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh({bool recoverVerified = true}) async {
    if (!config.enabled || !_current) return;
    final next = await repository.status();
    _requireCurrent();
    _refreshBackoff = _initialRefreshBackoff;
    _status = next;
    _scheduleRefresh(next);
    notifyListeners();
    if (recoverVerified) {
      for (final offer in next.offers.values) {
        final claim = offer.activeClaim;
        if (claim?.verified == true && !_busy.contains(offer.currency)) {
          await _claimVerified(offer.currency, claim!.id);
        }
      }
    }
  }

  void _scheduleRefresh(RewardedAdsStatus value) {
    _nextRefresh?.cancel();
    final times = <DateTime>[value.nextResetAt];
    var hasIssuedClaim = false;
    for (final offer in value.offers.values) {
      final claim = offer.activeClaim;
      if (claim == null) continue;
      // An SSV callback may arrive while Android is returning from the ad.
      // Poll active issued claims with bounded backoff, then recover verified
      // claims as soon as the canonical session is ready.
      if (claim.verified) {
        times.add(DateTime.now().toUtc().add(const Duration(seconds: 5)));
      } else {
        hasIssuedClaim = true;
        times.add(DateTime.now().toUtc().add(_verificationBackoff));
      }
    }
    if (hasIssuedClaim) {
      final doubled = _verificationBackoff.inSeconds * 2;
      _verificationBackoff = Duration(
          seconds: doubled > _maximumVerificationBackoff.inSeconds
              ? _maximumVerificationBackoff.inSeconds
              : doubled);
    } else {
      _verificationBackoff = _initialVerificationBackoff;
    }
    times.sort();
    final delay = times.first.difference(DateTime.now().toUtc());
    _nextRefresh = Timer(
        delay > Duration.zero ? delay : const Duration(seconds: 1),
        _runScheduledRefresh);
  }

  void _runScheduledRefresh() {
    unawaited(refresh().catchError((_) {
      if (_current) _scheduleRefreshRetry();
    }));
  }

  void _scheduleRefreshRetry() {
    if (!config.enabled || !_current) return;
    _nextRefresh?.cancel();
    final delay = _refreshBackoff;
    final doubled = delay.inSeconds * 2;
    _refreshBackoff = Duration(
        seconds: doubled > _maximumRefreshBackoff.inSeconds
            ? _maximumRefreshBackoff.inSeconds
            : doubled);
    _nextRefresh = Timer(delay, _runScheduledRefresh);
  }

  Future<RewardedAdWatchOutcome> watch(RewardedAdCurrency currency) async {
    _requireCurrent();
    if (!config.enabled ||
        _consent?.canRequestAds != true ||
        _busy.contains(currency)) {
      throw StateError('rewarded_ad_unavailable');
    }
    _busy.add(currency);
    _errors.remove(currency);
    notifyListeners();
    LoadedRewardedAd? loaded;
    RewardedAdClaim? claim;
    var handedToPlatform = false;
    try {
      await refresh(recoverVerified: false);
      final offer = _status!.offer(currency);
      if (!_status!.enabled || offer.remaining <= 0) {
        throw StateError('rewarded_ad_daily_limit');
      }
      final active = offer.activeClaim;
      if (active != null) {
        if (active.verified) {
          final claimed =
              await _claimVerified(currency, active.id, alreadyBusy: true);
          return claimed
              ? RewardedAdWatchOutcome.rewarded
              : RewardedAdWatchOutcome.pendingVerification;
        }
        return RewardedAdWatchOutcome.pendingVerification;
      }

      // Load first so a no-fill does not reserve a server claim.
      loaded = await platform.load(config.adUnitId(currency.name));
      _requireCurrent();
      claim = await repository.issue(currency);
      _requireCurrent();
      _verificationBackoff = _initialVerificationBackoff;
      handedToPlatform = true;
      late final bool earned;
      try {
        earned = await loaded.show(customData: claim.token);
      } on RewardedAdShowException catch (error) {
        if (!error.claimMayHaveBeenShown) {
          await _cancelFailedShow(claim.id);
        } else {
          await _refreshAfterUncertainShow();
        }
        rethrow;
      } on Object {
        // A non-platform fake or adapter error has unknown delivery. Preserve
        // the claim so a genuine delayed SSV can still be redeemed.
        await _refreshAfterUncertainShow();
        rethrow;
      }
      _requireCurrent();

      // SSV normally arrives around dismissal. Bounded polling keeps the UI
      // responsive; delayed callbacks remain scheduled for reconciliation.
      var wait = const Duration(milliseconds: 250);
      for (var attempt = 0; attempt < 12; attempt++) {
        final state = await repository.claimStatus(claim.id);
        _requireCurrent();
        if (state.verified) {
          final claimed =
              await _claimVerified(currency, claim.id, alreadyBusy: true);
          if (claimed) return RewardedAdWatchOutcome.rewarded;
          // Keep the verified claim visible to the resume/refresh recovery
          // path when gameplay is still regaining foreground freshness.
          await refresh(recoverVerified: false);
          return RewardedAdWatchOutcome.pendingVerification;
        }
        if (state.terminal) break;
        await Future<void>.delayed(wait);
        if (wait < const Duration(seconds: 2)) wait *= 2;
      }
      await refresh(recoverVerified: false);
      return earned
          ? RewardedAdWatchOutcome.pendingVerification
          : RewardedAdWatchOutcome.closedEarly;
    } on Object catch (error) {
      if (_current) {
        _errors[currency] = _safeError(error);
        notifyListeners();
      }
      rethrow;
    } finally {
      if (!handedToPlatform && loaded != null) await loaded.dispose();
      if (_current) {
        _busy.remove(currency);
        notifyListeners();
      }
    }
  }

  Future<void> _cancelFailedShow(String claimId) async {
    try {
      await repository.cancel(claimId);
      _requireCurrent();
      await refresh(recoverVerified: false);
    } on Object {
      if (_current) _scheduleRefreshRetry();
    }
  }

  Future<void> _refreshAfterUncertainShow() async {
    try {
      await refresh(recoverVerified: false);
    } on Object {
      if (_current) _scheduleRefreshRetry();
    }
  }

  Future<bool> _claimVerified(RewardedAdCurrency currency, String claimId,
      {bool alreadyBusy = false}) async {
    // Full-screen ads background Android. The lifecycle owner first refreshes
    // the canonical session; only then may this automatic economic command run.
    if (!session.canRunAutomatic) return false;
    if (!alreadyBusy) {
      _busy.add(currency);
      notifyListeners();
    }
    try {
      await CanonicalGameActions(session).claimRewardedAd(claimId);
      _requireCurrent();
      RewardedAdsStatus? next;
      try {
        next = await repository.status();
      } on Object {
        // The canonical command already committed the wallet and persistent
        // reveal. A status-read outage must not turn that success into an
        // apparent failed reward; a later shop refresh reconciles the count.
      }
      _requireCurrent();
      if (next != null) {
        _refreshBackoff = _initialRefreshBackoff;
        _status = next;
        _scheduleRefresh(next);
      } else {
        _scheduleRefreshRetry();
      }
      return true;
    } on CanonicalGameException catch (error) {
      if (error.code == 'game_command_busy' ||
          error.code == 'game_refresh_required') {
        return false;
      }
      rethrow;
    } finally {
      if (!alreadyBusy && _current) {
        _busy.remove(currency);
        notifyListeners();
      }
    }
  }

  Future<void> showPrivacyOptions() async {
    if (!config.enabled || !_current) return;
    _consent = await platform.showPrivacyOptions();
    _requireCurrent();
    notifyListeners();
  }

  Future<void> resumed() async {
    if (!config.enabled || !_current) return;
    if (_consentRetryNeeded) {
      try {
        _consent = await platform.initializeConsent();
        _requireCurrent();
        _consentRetryNeeded = false;
        notifyListeners();
      } on Object {
        if (_current) _consentRetryNeeded = true;
      }
    }
    try {
      await refresh(recoverVerified: true);
    } on Object {
      // Gameplay reconnection and a later shop visit retry independently.
    }
  }

  /// Called when the shop is opened so a delayed SSV does not have to wait for
  /// a lifecycle transition or the next scheduled verification check.
  Future<void> shopOpened() async {
    if (!config.enabled || !_current) return;
    try {
      await refresh(recoverVerified: true);
    } on Object {
      if (_current) _scheduleRefreshRetry();
    }
  }

  void _requireCurrent() {
    if (!_current) throw StateError('rewarded_ad_account_changed');
  }

  static String _safeError(Object error) {
    final text = error.toString();
    for (final code in const [
      'rewarded_ad_daily_limit',
      'rewarded_ad_claim_pending',
      'rewarded_ad_unavailable',
      'rewarded_ad_account_changed',
    ]) {
      if (text.contains(code)) return code;
    }
    if (text.contains('rewarded_ad_load_')) return 'rewarded_ad_no_fill';
    return 'rewarded_ad_failed';
  }

  @override
  void dispose() {
    _disposed = true;
    _nextRefresh?.cancel();
    super.dispose();
  }
}
