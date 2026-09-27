import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/rewarded_ads_config.dart';
import '../models/rewarded_ad.dart';
import 'canonical_game_actions.dart';
import 'canonical_game_session.dart';
import 'canonical_game_snapshot.dart';
import 'rewarded_ads_platform.dart';
import 'rewarded_ads_repository.dart';

enum RewardedAdWatchOutcome {
  rewarded,
  rewardPreviewed,
  closedEarly,
  pendingVerification
}

/// Account-scoped rewarded-ad coordinator.
///
/// An SDK-earned reward is displayed immediately. Signed SSV and a canonical
/// commit remain responsible for authoritative currency and deduplication.
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
  final _prepared =
      <RewardedAdCurrency, ({LoadedRewardedAd ad, DateTime at})>{};
  final _preparing = <RewardedAdCurrency, Future<void>>{};
  final _earned = <String, RewardedAdCurrency>{};
  Future<void> _journalWrites = Future.value();
  Future<void>? _refreshing;
  bool _journalLoaded = false;

  File get _journal =>
      File('${session.snapshots.directory.path}/rewarded-earned-$_owner.json');
  bool preparing(RewardedAdCurrency currency) =>
      _preparing.containsKey(currency);
  bool ready(RewardedAdCurrency currency) => _prepared.containsKey(currency);
  bool earnedPending(RewardedAdCurrency currency) =>
      _earned.containsValue(currency);

  Future<void> prepare(RewardedAdCurrency currency) {
    final pending = _preparing[currency];
    if (pending != null) return pending;
    if (!_current || !canRequestAds || _busy.isNotEmpty) return Future.value();
    final offer = _status?.offers[currency];
    if (_status?.enabled != true ||
        offer == null ||
        offer.remaining <= 0 ||
        offer.activeClaim != null) {
      return Future.value();
    }
    final cached = _prepared[currency];
    if (cached != null &&
        DateTime.now().difference(cached.at) < const Duration(minutes: 45)) {
      return Future.value();
    }
    final completion = Completer<void>();
    _preparing[currency] = completion.future;
    unawaited(() async {
      try {
        if (cached != null) {
          _prepared.remove(currency);
          await cached.ad.dispose();
        }
        final ad = await platform.load(config.adUnitId(currency.name));
        if (!_current || !canRequestAds) {
          await ad.dispose();
        } else {
          _prepared[currency] = (ad: ad, at: DateTime.now());
        }
      } on Object {
        // A later shop opening or tap can retry a no-fill. Never reserve a
        // daily server slot merely because the player visits the shop.
      } finally {
        _preparing.remove(currency);
        if (_current) notifyListeners();
        completion.complete();
      }
    }());
    return completion.future;
  }

  void _warmAds() {
    if (!_current || !canRequestAds || _busy.isNotEmpty) return;
    for (final currency in RewardedAdCurrency.values) {
      unawaited(prepare(currency));
    }
  }

  Future<void> _loadEarned() async {
    if (_journalLoaded || !_current) return;
    _journalLoaded = true;
    try {
      if (!await _journal.exists() || await _journal.length() > 8192) return;
      final value = jsonDecode(await _journal.readAsString());
      _requireCurrent();
      if (value is! Map ||
          value['owner'] != _owner ||
          value['claims'] is! Map) {
        return;
      }
      final claims = value['claims'] as Map;
      if (claims.length > 20) return;
      for (final entry in claims.entries) {
        if (entry.key is String &&
            RegExp(r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$')
                .hasMatch(entry.key as String) &&
            RewardedAdCurrency.values.any((c) => c.name == entry.value)) {
          _earned[entry.key as String] =
              RewardedAdCurrency.values.byName(entry.value as String);
        }
      }
    } on Object {/* A local display journal cannot authorize currency. */}
  }

  Future<void> _saveEarned() {
    final contents = jsonEncode({
      'owner': _owner,
      'claims': {for (final e in _earned.entries) e.key: e.value.name}
    });
    _journalWrites = _journalWrites.then((_) async {
      await _journal.parent.create(recursive: true);
      await _journal.writeAsString(contents, flush: true);
    }).catchError((Object _) {});
    return _journalWrites;
  }

  Future<void> _reconcileEarned() async {
    for (final entry in _earned.entries.toList()) {
      final state = await repository.claimStatus(entry.key);
      _requireCurrent();
      if (state.terminal) {
        if (state.status == 'claimed' &&
            !session.hasConfirmedRewardedAd(entry.key)) {
          final refreshed = await session.refreshWalletAfterReward();
          _requireCurrent();
          // This best-effort read can be skipped while another command or
          // resume is running. Retain the display until a real read confirms
          // the wallet; a status reply alone does not contain that wallet.
          if (!refreshed) continue;
        }
        _requireCurrent();
        _earned.remove(entry.key);
        session.settleRewardedAdPreview(entry.key);
        if (state.status != 'claimed') {
          _errors[entry.value] = 'rewarded_ad_verification_failed';
        }
        await _saveEarned();
      } else {
        final committed = session.hasConfirmedRewardedAd(entry.key);
        if (!committed) session.previewRewardedAd(entry.key, entry.value.name);
      }
    }
  }

  RewardedAdsStatus? get status => _current ? _status : null;
  bool get initializing => _initializing;
  bool get privacyOptionsRequired =>
      config.enabled && (_consent?.privacyOptionsRequired ?? false);
  bool get canRequestAds => config.enabled && _consent?.canRequestAds == true;
  bool busy(RewardedAdCurrency currency) => _busy.contains(currency);
  String? error(RewardedAdCurrency currency) => _errors[currency];
  bool get current => _current;

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
      await _loadEarned();
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
        _warmAds();
        notifyListeners();
      }
    }
  }

  Future<void> refresh({bool recoverVerified = true}) async {
    final running = _refreshing;
    if (running != null) {
      await running;
      return;
    }
    final future = _refresh(recoverVerified: recoverVerified);
    _refreshing = future;
    try {
      await future;
    } finally {
      if (identical(_refreshing, future)) _refreshing = null;
    }
  }

  Future<void> _refresh({required bool recoverVerified}) async {
    if (!config.enabled || !_current) return;
    final next = await repository.status();
    _requireCurrent();
    _refreshBackoff = _initialRefreshBackoff;
    _status = next;
    await _reconcileEarned();
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
    _warmAds();
  }

  void _scheduleRefresh(RewardedAdsStatus value) {
    _nextRefresh?.cancel();
    final times = <DateTime>[value.nextResetAt];
    if (_earned.isNotEmpty) {
      times.add(DateTime.now().toUtc().add(_verificationBackoff));
    }
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
        _busy.isNotEmpty) {
      throw StateError('rewarded_ad_unavailable');
    }
    // Warm cached creative is consumed once. A tap never races another
    // full-screen ad, even when the player switches currency shops.
    await prepare(currency);
    _requireCurrent();
    if (_busy.isNotEmpty) throw StateError('rewarded_ad_unavailable');
    _busy.add(currency);
    _errors.remove(currency);
    notifyListeners();
    LoadedRewardedAd? loaded;
    RewardedAdClaim? claim;
    var handedToPlatform = false;
    try {
      if (_status == null) await refresh(recoverVerified: false);
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
      loaded = _prepared.remove(currency)?.ad;
      if (loaded == null) throw StateError('rewarded_ad_load_unavailable');
      _requireCurrent();
      claim =
          await repository.issue(currency).timeout(const Duration(seconds: 15));
      _requireCurrent();
      _verificationBackoff = _initialVerificationBackoff;
      handedToPlatform = true;
      late final bool earned;
      try {
        earned =
            await loaded.show(customData: claim.token, mayShow: () => _current);
      } on RewardedAdShowException catch (error) {
        if (!error.claimMayHaveBeenShown) {
          unawaited(_cancelFailedShow(claim.id));
        } else {
          unawaited(_refreshAfterUncertainShow());
        }
        rethrow;
      } on Object {
        // A non-platform fake or adapter error has unknown delivery. Preserve
        // the claim so a genuine delayed SSV can still be redeemed.
        unawaited(_refreshAfterUncertainShow());
        rethrow;
      }
      _requireCurrent();

      if (earned) {
        if (session.hasConfirmedRewardedAd(claim.id)) {
          return RewardedAdWatchOutcome.rewarded;
        }
        _earned[claim.id] = currency;
        session.previewRewardedAd(claim.id, currency.name);
        await _saveEarned();
        _requireCurrent();
        // Return to play immediately; verification and durable credit proceed
        // independently from the fullscreen ad's dismissal future.
        _nextRefresh?.cancel();
        _nextRefresh = Timer(Duration.zero, _runScheduledRefresh);
        return RewardedAdWatchOutcome.rewardPreviewed;
      }

      unawaited(_refreshAfterUncertainShow());
      return RewardedAdWatchOutcome.closedEarly;
    } on Object catch (error) {
      if (_current) {
        _errors[currency] = _safeError(error);
        _nextRefresh?.cancel();
        _nextRefresh = Timer(const Duration(seconds: 1), _runScheduledRefresh);
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
      _earned.remove(claimId);
      session.settleRewardedAdPreview(claimId);
      await _saveEarned();
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
    for (final entry in _prepared.values) {
      await entry.ad.dispose();
    }
    _prepared.clear();
    _warmAds();
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
      _warmAds();
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
      _warmAds();
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
    for (final entry in _prepared.values) {
      unawaited(entry.ad.dispose());
    }
    _prepared.clear();
    for (final claimId in _earned.keys) {
      session.settleRewardedAdPreview(claimId);
    }
    super.dispose();
  }
}
