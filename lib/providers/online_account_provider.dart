import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/social.dart';
import '../services/notification_service.dart';
import '../services/social_repository.dart';

class OnlineAccountProvider extends ChangeNotifier {
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
  final String Function() _languageCode;
  StreamSubscription<bool>? _authSubscription;
  Timer? _refreshTimer;
  final Set<String> _notifiedTradeStates = {};
  bool _disposed = false;

  KeeperProfile? profile;
  List<KeeperProfile> friends = const [];
  List<FriendshipRequest> requests = const [];
  List<KeeperProfile> blockedKeepers = const [];
  List<GroupAdventureLobby> groupLobbies = const [];
  GroupAdventureStatus? groupAdventureStatus;
  List<TradeOffer> trades = const [];
  List<TradeInventoryItem> tradeInventory = const [];
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

  Future<bool> signOut() async =>
      await _run(() async {
        await _repository.signOut();
        _clearAccountData();
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
        await _refreshData();
        await _repository.createTrade(friendId, item);
        await _refreshData();
        noticeCode = 'trade_sent';
        return true;
      }) ??
      false;

  Future<bool> respondToTrade(String tradeId, TradeItem item) async =>
      await _run(() async {
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
    final snapshot = _inventorySnapshot();
    final localProfile = _profileSnapshot();
    await _repository.updateProfile(
      displayName: localProfile.displayName,
      title: localProfile.titleId,
      portraitKey: localProfile.portraitId,
    );
    var ownProfile = await _repository.loadMyProfile();
    if (!ownProfile.inventoryImported) {
      await _repository.importLegacyInventory(snapshot);
    }
    final pendingTrades = await _repository.loadTrades();
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
    }
    await _repository.synchronizeTradeInventory(_inventorySnapshot());
    await _repository.publishSocialShowcase(_inventorySnapshot());
    ownProfile = await _repository.loadMyProfile();
    final results = await Future.wait([
      _repository.loadFriends(),
      _repository.loadRequests(),
      _repository.loadBlockedKeepers(),
      _repository.loadGroupAdventureStatus(),
      _repository.loadGroupAdventures(),
      _repository.loadTrades(),
      _repository.loadTradeInventory(),
    ]);
    profile = ownProfile;
    friends = results[0] as List<KeeperProfile>;
    requests = results[1] as List<FriendshipRequest>;
    blockedKeepers = results[2] as List<KeeperProfile>;
    groupAdventureStatus = results[3] as GroupAdventureStatus;
    groupLobbies = results[4] as List<GroupAdventureLobby>;
    trades = results[5] as List<TradeOffer>;
    tradeInventory = results[6] as List<TradeInventoryItem>;
    await _synchronizeGroupReservations({
      for (final lobby in myGroupAdventures)
        if (lobby.myDragonId case final dragonId?) dragonId: lobby.id,
    });
    await _synchronizeLocalTradeReservations();
    _notifyAboutTradeUpdates();
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

  void _notifyAboutTradeUpdates() {
    for (final trade in trades.where((trade) => trade.needsMyResponse)) {
      final state = '${trade.id}:${trade.status}';
      if (!_notifiedTradeStates.add(state)) continue;
      final dutch = _languageCode() == 'nl';
      unawaited(HavenNotifications.tradeUpdate(
        id: state,
        title: dutch ? 'Nieuwe ruil' : 'New trade',
        body: trade.amInitiator
            ? (dutch
                ? '${trade.otherKeeper.displayName} heeft een item aangeboden. Bevestig de ruil.'
                : '${trade.otherKeeper.displayName} offered an item. Confirm the trade.')
            : (dutch
                ? '${trade.otherKeeper.displayName} wil een item met je ruilen.'
                : '${trade.otherKeeper.displayName} wants to trade with you.'),
      ));
    }
  }

  void _ensureRefreshTimer() {
    if (!isConfigured || !isSignedIn || _refreshTimer != null) return;
    _refreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
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
    unawaited(_synchronizeGroupReservations(const {}));
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
