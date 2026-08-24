import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/social.dart';
import '../services/social_repository.dart';

class OnlineAccountProvider extends ChangeNotifier {
  OnlineAccountProvider({
    required SocialRepository repository,
    required OnlineInventorySnapshot Function() inventorySnapshot,
    OnlineProfileSnapshot Function()? profileSnapshot,
    Future<void> Function(Map<String, String> reservations)?
        synchronizeGroupReservations,
    Future<bool> Function(GroupAdventureReward reward)? applyGroupReward,
  })  : _repository = repository,
        _inventorySnapshot = inventorySnapshot,
        _profileSnapshot = profileSnapshot ?? _fallbackProfileSnapshot,
        _synchronizeGroupReservations =
            synchronizeGroupReservations ?? _ignoreGroupReservations,
        _applyGroupReward = applyGroupReward ?? _rejectGroupReward;

  final SocialRepository _repository;
  final OnlineInventorySnapshot Function() _inventorySnapshot;
  final OnlineProfileSnapshot Function() _profileSnapshot;
  final Future<void> Function(Map<String, String> reservations)
      _synchronizeGroupReservations;
  final Future<bool> Function(GroupAdventureReward reward) _applyGroupReward;
  StreamSubscription<bool>? _authSubscription;
  bool _disposed = false;

  KeeperProfile? profile;
  List<KeeperProfile> friends = const [];
  List<FriendshipRequest> requests = const [];
  List<KeeperProfile> blockedKeepers = const [];
  List<GroupAdventureLobby> groupLobbies = const [];
  GroupAdventureStatus? groupAdventureStatus;
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
    await _repository.publishSocialShowcase(snapshot);
    ownProfile = await _repository.loadMyProfile();
    final results = await Future.wait([
      _repository.loadFriends(),
      _repository.loadRequests(),
      _repository.loadBlockedKeepers(),
      _repository.loadGroupAdventureStatus(),
      _repository.loadGroupAdventures(),
    ]);
    profile = ownProfile;
    friends = results[0] as List<KeeperProfile>;
    requests = results[1] as List<FriendshipRequest>;
    blockedKeepers = results[2] as List<KeeperProfile>;
    groupAdventureStatus = results[3] as GroupAdventureStatus;
    groupLobbies = results[4] as List<GroupAdventureLobby>;
    await _synchronizeGroupReservations({
      for (final lobby in myGroupAdventures)
        if (lobby.myDragonId case final dragonId?) dragonId: lobby.id,
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
    unawaited(_synchronizeGroupReservations(const {}));
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
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
