import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../l10n/app_strings.dart';
import '../models/social.dart';
import '../services/notification_service.dart';
import '../services/social_repository.dart';

class OnlineAccountProvider extends ChangeNotifier {
  static const maxSuccessfulTradesPerDay = 3;

  OnlineAccountProvider({
    required SocialRepository repository,
    required OnlineInventorySnapshot Function() inventorySnapshot,
    OnlineProfileSnapshot Function()? profileSnapshot,
    Future<void> Function(Map<String, String> reservations)?
        synchronizeGroupReservations,
    Future<bool> Function(GroupAdventureReward reward)? applyGroupReward,
    Future<void> Function(
      Set<String> eggIds,
      Map<String, int> chests,
      Map<String, int> relics,
    )? synchronizeTradeReservations,
    Future<bool> Function(TradeSettlement settlement)? applyTradeSettlement,
    Map<String, dynamic> Function()? gameStateSnapshot,
    Future<bool> Function(Map<String, dynamic> state)? applyCloudState,
    Future<String> Function()? deviceId,
    String Function()? languageCode,
  })  : _repository = repository,
        _inventorySnapshot = inventorySnapshot,
        _profileSnapshot = profileSnapshot ?? _fallbackProfileSnapshot,
        _synchronizeGroupReservations =
            synchronizeGroupReservations ?? _ignoreGroupReservations,
        _applyGroupReward = applyGroupReward ?? _rejectGroupReward,
        _synchronizeTradeReservations =
            synchronizeTradeReservations ?? _ignoreTradeReservations,
        _applyTradeSettlement = applyTradeSettlement ?? _rejectTradeSettlement,
        _gameStateSnapshot = gameStateSnapshot,
        _applyCloudState = applyCloudState,
        _deviceId = deviceId,
        _languageCode = languageCode ?? _defaultLanguageCode;

  final SocialRepository _repository;
  final OnlineInventorySnapshot Function() _inventorySnapshot;
  final OnlineProfileSnapshot Function() _profileSnapshot;
  final Future<void> Function(Map<String, String> reservations)
      _synchronizeGroupReservations;
  final Future<bool> Function(GroupAdventureReward reward) _applyGroupReward;
  final Future<void> Function(
    Set<String> eggIds,
    Map<String, int> chests,
    Map<String, int> relics,
  ) _synchronizeTradeReservations;
  final Future<bool> Function(TradeSettlement settlement) _applyTradeSettlement;
  final Map<String, dynamic> Function()? _gameStateSnapshot;
  final Future<bool> Function(Map<String, dynamic> state)? _applyCloudState;
  final Future<String> Function()? _deviceId;
  final String Function() _languageCode;
  StreamSubscription<bool>? _authSubscription;
  Timer? _refreshTimer;
  String? _lastProfileFingerprint;
  String? _lastTradeInventoryFingerprint;
  String? _lastShowcaseFingerprint;
  DateTime? _lastPresenceUpdate;
  bool _disposed = false;

  KeeperProfile? profile;
  List<KeeperProfile> friends = const [];
  List<FriendshipRequest> requests = const [];
  List<KeeperProfile> blockedKeepers = const [];
  List<GroupAdventureLobby> groupLobbies = const [];
  GroupAdventureStatus? groupAdventureStatus;
  List<TradeOffer> trades = const [];
  List<TradeInventoryItem> tradeInventory = const [];
  CloudGameSave? cloudGameSave;
  bool busy = false;
  String? errorCode;
  String? noticeCode;

  bool get isConfigured => _repository.isConfigured;
  bool get isSignedIn => _repository.isSignedIn;
  bool get isEmailVerified => _repository.isEmailVerified;
  String? get currentEmail => _repository.currentEmail;
  List<FriendshipRequest> get incomingRequests => requests
      .where((request) => request.direction == FriendRequestDirection.incoming)
      .toList(growable: false);
  List<FriendshipRequest> get outgoingRequests => requests
      .where((request) => request.direction == FriendRequestDirection.outgoing)
      .toList(growable: false);
  List<GroupAdventureLobby> get myGroupAdventures => groupLobbies
      .where((lobby) => lobby.isParticipant && !lobby.rewardAcknowledged)
      .toList(growable: false);
  List<GroupAdventureLobby> get joinableGroupAdventures => groupLobbies
      .where((lobby) =>
          lobby.isWaiting && lobby.isCurrentOffer && !lobby.isParticipant)
      .toList(growable: false);
  bool get currentGroupOfferConsumed =>
      groupAdventureStatus?.alreadyCompleted == true ||
      groupLobbies.any((lobby) => lobby.isCurrentOffer && lobby.isParticipant);
  List<TradeOffer> tradesWith(String userId) => trades
      .where((trade) => trade.otherKeeper.userId == userId && trade.isActive)
      .toList(growable: false);
  int get completedTradesToday => completedTradesOn(DateTime.now());

  int completedTradesOn(DateTime day) {
    final localDay = day.toLocal();
    return trades.where((trade) {
      if (!trade.isCompleted) return false;
      final completedDay = trade.updatedAt.toLocal();
      return completedDay.year == localDay.year &&
          completedDay.month == localDay.month &&
          completedDay.day == localDay.day;
    }).length;
  }

  Future<void> initialize() async {
    _authSubscription = _repository.authStateChanges.listen((signedIn) {
      if (signedIn) {
        unawaited(refresh());
      } else {
        _clearAccountData();
        _notify();
      }
    });
    if (isSignedIn) await refresh();
    _ensureRefreshTimer();
  }

  Future<AccountAuthResult?> signUp({
    required String email,
    required String password,
  }) async =>
      _run(() async {
        final localProfile = _profileSnapshot();
        final result = await _repository.signUp(
          email: email,
          password: password,
          displayName: localProfile.displayName,
        );
        noticeCode = result.requiresEmailConfirmation
            ? 'confirm_email'
            : 'account_created';
        if (isSignedIn) await _refreshData();
        return result;
      });

  Future<bool> signIn({
    required String email,
    required String password,
  }) async =>
      await _run(() async {
        await _repository.signIn(email: email, password: password);
        await _refreshData();
        _ensureRefreshTimer();
        noticeCode = 'signed_in';
        return true;
      }) ??
      false;

  Future<bool> resendSignupConfirmation(String email) async =>
      await _run(() async {
        await _repository.resendSignupConfirmation(email);
        noticeCode = 'confirmation_resent';
        return true;
      }) ??
      false;

  Future<bool> signOut() async =>
      await _run(() async {
        await _repository.signOut();
        _clearAccountData();
        return true;
      }) ??
      false;

  Future<bool> deleteAccount(String password) async =>
      await _run(() async {
        await _repository.deleteMyAccount(password);
        _clearAccountData();
        noticeCode = 'account_deleted';
        return true;
      }) ??
      false;

  Future<bool> refresh() async =>
      await _run(() async {
        if (!isSignedIn) return false;
        await _refreshData();
        return true;
      }) ??
      false;

  Future<bool> synchronizeProfile() => refresh();

  Future<bool> loadCloudSaveStatus() async =>
      await _run(() async {
        if (!isSignedIn) return false;
        cloudGameSave = await _repository.loadCloudGameSave();
        return true;
      }) ??
      false;

  Future<bool> backupToCloud() async =>
      await _run(() async {
        final snapshot = _gameStateSnapshot;
        final loadDeviceId = _deviceId;
        if (!isSignedIn || snapshot == null || loadDeviceId == null) {
          throw const SocialException('cloud_save_unavailable');
        }
        cloudGameSave = await _repository.loadCloudGameSave();
        cloudGameSave = await _repository.pushCloudGameSave(
          expectedRevision: cloudGameSave?.revision ?? 0,
          state: snapshot(),
          deviceId: await loadDeviceId(),
        );
        noticeCode = 'cloud_save_backed_up';
        return true;
      }) ??
      false;

  Future<bool> restoreFromCloud() async =>
      await _run(() async {
        final apply = _applyCloudState;
        if (!isSignedIn || apply == null) {
          throw const SocialException('cloud_save_unavailable');
        }
        final remote = await _repository.loadCloudGameSave();
        if (remote == null) throw const SocialException('cloud_save_missing');
        if (!await apply(remote.state)) {
          throw const SocialException('cloud_save_invalid');
        }
        cloudGameSave = remote;
        _lastTradeInventoryFingerprint = null;
        _lastShowcaseFingerprint = null;
        await _refreshData();
        noticeCode = 'cloud_save_restored';
        return true;
      }) ??
      false;

  Future<bool> sendFriendRequest(String keeperCode) async =>
      await _run(() async {
        await _repository.sendFriendRequest(keeperCode);
        await _refreshData();
        noticeCode = 'request_sent';
        return true;
      }) ??
      false;

  Future<bool> respondToRequest(String requestId, String response) async =>
      await _run(() async {
        await _repository.respondToRequest(requestId, response);
        await _refreshData();
        noticeCode = 'request_$response';
        return true;
      }) ??
      false;

  Future<bool> removeFriend(String userId) async =>
      await _run(() async {
        await _repository.removeFriend(userId);
        await _refreshData();
        noticeCode = 'friend_removed';
        return true;
      }) ??
      false;

  Future<bool> blockKeeper(String userId) async =>
      await _run(() async {
        await _repository.blockKeeper(userId);
        await _refreshData();
        noticeCode = 'keeper_blocked';
        return true;
      }) ??
      false;

  Future<bool> unblockKeeper(String userId) async =>
      await _run(() async {
        await _repository.unblockKeeper(userId);
        await _refreshData();
        noticeCode = 'keeper_unblocked';
        return true;
      }) ??
      false;

  Future<bool> createGroupLobby(
    String adventureId,
    GroupDragonSubmission dragon,
  ) async =>
      await _run(() async {
        await _repository.createGroupLobby(adventureId, dragon);
        await _refreshData();
        noticeCode = 'group_lobby_created';
        return true;
      }) ??
      false;

  Future<bool> joinGroupLobby(
    String lobbyId,
    GroupDragonSubmission dragon,
  ) async =>
      await _run(() async {
        await _repository.joinGroupLobby(lobbyId, dragon);
        await _refreshData();
        noticeCode = 'group_joined';
        return true;
      }) ??
      false;

  Future<bool> leaveGroupLobby(String lobbyId) async =>
      await _run(() async {
        await _repository.leaveGroupLobby(lobbyId);
        await _refreshData();
        noticeCode = 'group_left';
        return true;
      }) ??
      false;

  Future<bool> removeGroupParticipant(String lobbyId, String userId) async =>
      await _run(() async {
        await _repository.removeGroupParticipant(lobbyId, userId);
        await _refreshData();
        noticeCode = 'group_participant_removed';
        return true;
      }) ??
      false;

  Future<GroupAdventureReward?> claimGroupReward(String lobbyId) =>
      _run(() async {
        final reward = await _repository.claimGroupReward(lobbyId);
        if (reward == null) {
          throw const SocialException('group_reward_not_ready');
        }
        if (!await _applyGroupReward(reward)) {
          throw const SocialException('group_reward_apply_failed');
        }
        await _repository.acknowledgeGroupReward(lobbyId);
        await _refreshData();
        noticeCode = 'group_reward_claimed';
        return reward;
      });

  Future<bool> prepareTradeInventory() async =>
      await _run(() async {
        await _refreshData();
        return true;
      }) ??
      false;

  Future<bool> createTrade(String friendId, TradeItem item) async =>
      await _run(() async {
        if (!item.isTradeable) {
          throw const SocialException('trade_item_invalid');
        }
        await _refreshData();
        await _repository.createTrade(friendId, item);
        await _refreshData();
        noticeCode = 'trade_sent';
        return true;
      }) ??
      false;

  Future<bool> respondToTrade(String tradeId, TradeItem item) async =>
      await _run(() async {
        if (!item.isTradeable) {
          throw const SocialException('trade_item_invalid');
        }
        await _refreshData();
        await _repository.respondToTrade(tradeId, item);
        await _refreshData();
        noticeCode = 'trade_response_sent';
        return true;
      }) ??
      false;

  Future<bool> completeTrade(String tradeId) async =>
      await _run(() async {
        await _repository.completeTrade(tradeId);
        await _refreshData();
        noticeCode = 'trade_completed';
        return true;
      }) ??
      false;

  Future<bool> cancelTrade(String tradeId) async =>
      await _run(() async {
        await _repository.cancelTrade(tradeId);
        await _refreshData();
        noticeCode = 'trade_cancelled';
        return true;
      }) ??
      false;

  Future<bool> rejectTrade(String tradeId) async =>
      await _run(() async {
        await _repository.rejectTrade(tradeId);
        await _refreshData();
        noticeCode = 'trade_rejected';
        return true;
      }) ??
      false;

  void clearMessages() {
    errorCode = null;
    noticeCode = null;
  }

  Future<void> _refreshData() async {
    await _repository.ensureAccount();
    final snapshot = _inventorySnapshot();
    final localProfile = _profileSnapshot();
    final profileFingerprint = jsonEncode({
      'displayName': localProfile.displayName,
      'title': localProfile.titleId,
      'portrait': localProfile.portraitId,
    });
    final now = DateTime.now();
    final presenceExpired = _lastPresenceUpdate == null ||
        now.difference(_lastPresenceUpdate!) >= const Duration(minutes: 5);
    if (_lastProfileFingerprint != profileFingerprint || presenceExpired) {
      await _repository.updateProfile(
        displayName: localProfile.displayName,
        title: localProfile.titleId,
        portraitKey: localProfile.portraitId,
      );
      _lastProfileFingerprint = profileFingerprint;
      _lastPresenceUpdate = now;
    }
    var serverChanged = false;
    var onlineSnapshot = await _repository.loadOnlineSnapshot();
    var ownProfile = onlineSnapshot.profile;
    if (!ownProfile.inventoryImported) {
      await _repository.importLegacyInventory(snapshot);
      serverChanged = true;
    }
    final pendingTrades = onlineSnapshot.trades;
    trades = pendingTrades;
    await _synchronizeLocalTradeReservations();
    for (final trade in pendingTrades.where(
      (trade) => trade.isCompleted && !trade.myAcknowledged,
    )) {
      final applied = await _applyTradeSettlement(TradeSettlement(
        tradeId: trade.id,
        sent: trade.myItem,
        received: trade.receivedItem,
      ));
      if (!applied) throw const SocialException('trade_apply_failed');
      await _repository.acknowledgeTrade(trade.id);
      serverChanged = true;
    }
    final currentSnapshot = _inventorySnapshot();
    final tradeInventoryFingerprint = jsonEncode(currentSnapshot.toTradeJson());
    if (_lastTradeInventoryFingerprint != tradeInventoryFingerprint) {
      await _repository.synchronizeTradeInventory(currentSnapshot);
      _lastTradeInventoryFingerprint = tradeInventoryFingerprint;
      serverChanged = true;
    }
    final showcaseFingerprint = jsonEncode(currentSnapshot.toShowcaseJson());
    if (_lastShowcaseFingerprint != showcaseFingerprint) {
      await _repository.publishSocialShowcase(currentSnapshot);
      _lastShowcaseFingerprint = showcaseFingerprint;
      serverChanged = true;
    }
    if (serverChanged) {
      onlineSnapshot = await _repository.loadOnlineSnapshot();
      ownProfile = onlineSnapshot.profile;
    }
    profile = ownProfile;
    friends = onlineSnapshot.friends;
    requests = onlineSnapshot.requests;
    blockedKeepers = onlineSnapshot.blockedKeepers;
    groupAdventureStatus = onlineSnapshot.groupAdventureStatus;
    groupLobbies = onlineSnapshot.groupLobbies;
    trades = onlineSnapshot.trades;
    tradeInventory = onlineSnapshot.tradeInventory
        .where((entry) => entry.item.isTradeable)
        .toList(growable: false);
    await _synchronizeGroupReservations({
      for (final lobby in myGroupAdventures)
        if (lobby.myDragonId case final dragonId?) dragonId: lobby.id,
    });
    await _synchronizeLocalTradeReservations();
    await _deliverSocialNotifications(onlineSnapshot.notifications);
  }

  Future<void> _deliverSocialNotifications(
      List<SocialNotification> notifications) async {
    if (notifications.isEmpty) return;
    final strings = AppStrings(_languageCode());
    for (final notification in notifications) {
      final name = notification.actorDisplayName;
      String withName(String english, String dutch) =>
          strings.pick(english, dutch).replaceAll('{name}', name);
      switch (notification.kind) {
        case 'friend_request':
          await HavenNotifications.friendRequest(
            id: notification.id,
            title: strings.pick(
              'New friend request',
              'Nieuw vriendschapsverzoek',
            ),
            body: withName(
              '{name} wants to be friends.',
              '{name} wil vrienden worden.',
            ),
          );
        case 'friend_accepted':
          await HavenNotifications.friendAccepted(
            id: notification.id,
            title: strings.pick(
              'Friend request accepted',
              'Vriendschapsverzoek geaccepteerd',
            ),
            body: withName(
              '{name} is now in your friends list.',
              '{name} staat nu in je vriendenlijst.',
            ),
          );
        case 'trade_request':
          await HavenNotifications.tradeUpdate(
            id: notification.id,
            title: strings.pick('New trade offer', 'Nieuw ruilvoorstel'),
            body: withName(
              '{name} wants to trade an item with you.',
              '{name} wil een item met je ruilen.',
            ),
            category: HavenNotificationCategory.tradeRequests,
          );
        case 'trade_return':
          await HavenNotifications.tradeUpdate(
            id: notification.id,
            title: strings.pick(
              'Return item offered',
              'Tegenaanbod ontvangen',
            ),
            body: withName(
              '{name} offered an item. Confirm the trade.',
              '{name} heeft een item aangeboden. Bevestig de ruil.',
            ),
            category: HavenNotificationCategory.tradeReturns,
          );
        case 'trade_completed':
          await HavenNotifications.tradeUpdate(
            id: notification.id,
            title: strings.pick('Trade completed', 'Ruil afgerond'),
            body: withName(
              'Your trade with {name} completed safely.',
              'Je ruil met {name} is veilig afgerond.',
            ),
            category: HavenNotificationCategory.tradeCompletions,
          );
      }
    }
    await _repository.acknowledgeSocialNotifications(
      notifications.map((notification) => notification.id).toList(),
    );
  }

  Future<void> _synchronizeLocalTradeReservations() async {
    final eggs = <String>{};
    final chests = <String, int>{};
    final relics = <String, int>{};
    for (final trade in trades.where((trade) => trade.isActive)) {
      final item =
          trade.amInitiator ? trade.initiatorItem : trade.recipientItem;
      if (item == null) continue;
      switch (item.kind) {
        case TradeItemKind.egg:
          eggs.add(item.key);
        case TradeItemKind.chest:
          chests.update(item.key, (value) => value + 1, ifAbsent: () => 1);
        case TradeItemKind.relic:
          relics.update(item.key, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    await _synchronizeTradeReservations(eggs, chests, relics);
  }

  void _ensureRefreshTimer() {
    if (!isConfigured || !isSignedIn || _refreshTimer != null) return;
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (isSignedIn && !busy) unawaited(refresh());
    });
  }

  Future<T?> _run<T>(Future<T> Function() operation) async {
    if (busy) return null;
    busy = true;
    errorCode = null;
    _notify();
    try {
      return await operation();
    } on SocialException catch (error) {
      errorCode = error.code;
      return null;
    } on Object catch (error) {
      errorCode = error.toString();
      return null;
    } finally {
      busy = false;
      _notify();
    }
  }

  void _clearAccountData() {
    profile = null;
    friends = const [];
    requests = const [];
    blockedKeepers = const [];
    groupLobbies = const [];
    groupAdventureStatus = null;
    trades = const [];
    tradeInventory = const [];
    cloudGameSave = null;
    _lastProfileFingerprint = null;
    _lastTradeInventoryFingerprint = null;
    _lastShowcaseFingerprint = null;
    _lastPresenceUpdate = null;
    unawaited(_synchronizeGroupReservations(const {}));
    unawaited(_synchronizeTradeReservations(const {}, const {}, const {}));
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    _refreshTimer?.cancel();
    _repository.dispose();
    super.dispose();
  }
}

const _fallbackOnlineProfile = OnlineProfileSnapshot(
  displayName: 'Keeper',
  titleId: 'title_001',
  portraitId: 'portrait_001',
);

OnlineProfileSnapshot _fallbackProfileSnapshot() => _fallbackOnlineProfile;

Future<void> _ignoreGroupReservations(Map<String, String> _) async {}

Future<bool> _rejectGroupReward(GroupAdventureReward _) async => false;

Future<void> _ignoreTradeReservations(
  Set<String> _,
  Map<String, int> __,
  Map<String, int> ___,
) async {}

Future<bool> _rejectTradeSettlement(TradeSettlement _) async => false;

String _defaultLanguageCode() => 'en';
