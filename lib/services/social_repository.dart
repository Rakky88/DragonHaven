import '../models/social.dart';

class SocialException implements Exception {
  const SocialException(this.code);

  final String code;

  @override
  String toString() => code;
}

abstract interface class SocialRepository {
  bool get isConfigured;
  bool get isSignedIn;
  bool get isEmailVerified;
  String? get currentEmail;
  Stream<bool> get authStateChanges;

  Future<AccountAuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
  Future<KeeperProfile> loadMyProfile();
  Future<List<KeeperProfile>> loadFriends();
  Future<List<FriendshipRequest>> loadRequests();
  Future<List<SocialNotification>> loadSocialNotifications();
  Future<void> acknowledgeSocialNotifications(List<String> notificationIds);
  Future<List<KeeperProfile>> loadBlockedKeepers();
  Future<void> updateProfile({
    required String displayName,
    required String title,
    required String portraitKey,
  });
  Future<void> importLegacyInventory(OnlineInventorySnapshot snapshot);
  Future<void> publishSocialShowcase(OnlineInventorySnapshot snapshot);
  Future<void> sendFriendRequest(String keeperCode);
  Future<void> respondToRequest(String requestId, String response);
  Future<void> removeFriend(String userId);
  Future<void> blockKeeper(String userId);
  Future<void> unblockKeeper(String userId);
  Future<GroupAdventureStatus> loadGroupAdventureStatus();
  Future<List<GroupAdventureLobby>> loadGroupAdventures();
  Future<void> createGroupLobby(
    String adventureId,
    GroupDragonSubmission dragon,
  );
  Future<void> joinGroupLobby(
    String lobbyId,
    GroupDragonSubmission dragon,
  );
  Future<void> leaveGroupLobby(String lobbyId);
  Future<void> removeGroupParticipant(String lobbyId, String userId);
  Future<GroupAdventureReward?> claimGroupReward(String lobbyId);
  Future<void> acknowledgeGroupReward(String lobbyId);
  Future<void> synchronizeTradeInventory(OnlineInventorySnapshot snapshot);
  Future<List<TradeInventoryItem>> loadTradeInventory();
  Future<List<TradeOffer>> loadTrades();
  Future<void> createTrade(String friendId, TradeItem item);
  Future<void> respondToTrade(String tradeId, TradeItem item);
  Future<void> completeTrade(String tradeId);
  Future<void> cancelTrade(String tradeId);
  Future<void> rejectTrade(String tradeId);
  Future<void> acknowledgeTrade(String tradeId);
  void dispose();
}

class DisabledSocialRepository implements SocialRepository {
  const DisabledSocialRepository();

  @override
  bool get isConfigured => false;
  @override
  bool get isSignedIn => false;
  @override
  bool get isEmailVerified => false;
  @override
  String? get currentEmail => null;
  @override
  Stream<bool> get authStateChanges => const Stream.empty();

  Never _disabled() => throw const SocialException('online_not_configured');

  @override
  Future<List<KeeperProfile>> loadBlockedKeepers() async => _disabled();
  @override
  Future<List<KeeperProfile>> loadFriends() async => _disabled();
  @override
  Future<KeeperProfile> loadMyProfile() async => _disabled();
  @override
  Future<List<FriendshipRequest>> loadRequests() async => _disabled();
  @override
  Future<List<SocialNotification>> loadSocialNotifications() async =>
      _disabled();
  @override
  Future<void> acknowledgeSocialNotifications(
          List<String> notificationIds) async =>
      _disabled();
  @override
  Future<void> blockKeeper(String userId) async => _disabled();
  @override
  Future<void> importLegacyInventory(OnlineInventorySnapshot snapshot) async =>
      _disabled();
  @override
  Future<void> publishSocialShowcase(OnlineInventorySnapshot snapshot) async =>
      _disabled();
  @override
  Future<void> removeFriend(String userId) async => _disabled();
  @override
  Future<void> respondToRequest(String requestId, String response) async =>
      _disabled();
  @override
  Future<void> sendFriendRequest(String keeperCode) async => _disabled();
  @override
  Future<void> signIn(
          {required String email, required String password}) async =>
      _disabled();
  @override
  Future<AccountAuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async =>
      _disabled();
  @override
  Future<void> signOut() async => _disabled();
  @override
  Future<void> unblockKeeper(String userId) async => _disabled();
  @override
  Future<GroupAdventureStatus> loadGroupAdventureStatus() async => _disabled();
  @override
  Future<List<GroupAdventureLobby>> loadGroupAdventures() async => _disabled();
  @override
  Future<void> createGroupLobby(
          String adventureId, GroupDragonSubmission dragon) async =>
      _disabled();
  @override
  Future<void> joinGroupLobby(
          String lobbyId, GroupDragonSubmission dragon) async =>
      _disabled();
  @override
  Future<void> leaveGroupLobby(String lobbyId) async => _disabled();
  @override
  Future<void> removeGroupParticipant(String lobbyId, String userId) async =>
      _disabled();
  @override
  Future<GroupAdventureReward?> claimGroupReward(String lobbyId) async =>
      _disabled();
  @override
  Future<void> acknowledgeGroupReward(String lobbyId) async => _disabled();
  @override
  Future<void> synchronizeTradeInventory(
          OnlineInventorySnapshot snapshot) async =>
      _disabled();
  @override
  Future<List<TradeInventoryItem>> loadTradeInventory() async => _disabled();
  @override
  Future<List<TradeOffer>> loadTrades() async => _disabled();
  @override
  Future<void> createTrade(String friendId, TradeItem item) async =>
      _disabled();
  @override
  Future<void> respondToTrade(String tradeId, TradeItem item) async =>
      _disabled();
  @override
  Future<void> completeTrade(String tradeId) async => _disabled();
  @override
  Future<void> cancelTrade(String tradeId) async => _disabled();
  @override
  Future<void> rejectTrade(String tradeId) async => _disabled();
  @override
  Future<void> acknowledgeTrade(String tradeId) async => _disabled();
  @override
  Future<void> updateProfile({
    required String displayName,
    required String title,
    required String portraitKey,
  }) async =>
      _disabled();
  @override
  void dispose() {}
}
