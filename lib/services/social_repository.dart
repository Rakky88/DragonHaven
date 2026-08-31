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
  String? get currentUserId;
  Stream<bool> get authStateChanges;

  Future<AccountAuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> signIn({required String email, required String password});
  Future<void> resendSignupConfirmation(String email);
  Future<void> signOut();
  Future<void> ensureAccount();
  Future<void> deleteMyAccount(String password);
  Future<KeeperProfile> loadMyProfile();
  Future<OnlineSocialSnapshot> loadOnlineSnapshot();
  Future<CloudGameSave?> loadCloudGameSave();
  Future<List<CloudGameSaveSummary>> loadCloudGameSaveHistory();
  Future<CloudGameSave?> loadCloudGameSaveRevision(String saveId);
  Future<CloudGameSave> pushCloudGameSave({
    required int expectedRevision,
    required Map<String, dynamic> state,
    required String deviceId,
    required String clientVersion,
  });
  Future<List<KeeperProfile>> loadFriends();
  Future<List<FriendshipRequest>> loadRequests();
  Future<List<SocialNotification>> loadSocialNotifications();
  Future<void> acknowledgeSocialNotifications(List<String> notificationIds);
  Future<List<KeeperProfile>> loadBlockedKeepers();
  Future<void> updateProfile({
    required String displayName,
    required String title,
    required String portraitKey,
    String? frameKey,
    String? badgeKey,
  });
  Future<void> importLegacyInventory(OnlineInventorySnapshot snapshot);
  Future<void> publishSocialShowcase(OnlineInventorySnapshot snapshot);
  Future<void> sendFriendRequest(String keeperCode);
  Future<void> respondToRequest(String requestId, String response);
  Future<void> removeFriend(String userId);
  Future<void> blockKeeper(String userId);
  Future<void> unblockKeeper(String userId);
  Future<List<FriendMessage>> openFriendMessages(String friendId);
  Future<void> sendFriendMessage(String friendId, String body);
  Future<void> setSocialPreferences({
    required bool friendMessagesAllowed,
    required bool shareAchievementsWithConclave,
  });
  Future<List<ConclaveSummary>> listConclaves();
  Future<ConclaveSnapshot?> loadConclaveSnapshot();
  Future<void> createConclave({
    required String name,
    required String emblemKey,
    required String description,
    required String language,
    required ConclaveVisibility visibility,
    required int memberLimit,
  });
  Future<void> requestOrJoinConclave(String conclaveId);
  Future<void> respondConclaveJoinRequest(String requestId, bool accept);
  Future<void> inviteToConclave(String keeperCode);
  Future<void> respondConclaveInvite(String inviteId, bool accept);
  Future<void> contributeToConclave();
  Future<void> sendConclaveMessage({
    required String kind,
    required String body,
    Map<String, dynamic> payload = const {},
  });
  Future<void> synchronizeConclaveAchievements(List<String> achievementIds);
  Future<void> leaveConclave();
  Future<void> setConclaveMemberRole(String userId, ConclaveRole role);
  Future<void> transferConclave(String userId);
  Future<void> removeConclaveMember(String userId);
  Future<void> dissolveConclave();
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
  String? get currentUserId => null;
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
  Future<OnlineSocialSnapshot> loadOnlineSnapshot() async => _disabled();
  @override
  Future<CloudGameSave?> loadCloudGameSave() async => _disabled();
  @override
  Future<List<CloudGameSaveSummary>> loadCloudGameSaveHistory() async =>
      _disabled();
  @override
  Future<CloudGameSave?> loadCloudGameSaveRevision(String saveId) async =>
      _disabled();
  @override
  Future<CloudGameSave> pushCloudGameSave({
    required int expectedRevision,
    required Map<String, dynamic> state,
    required String deviceId,
    required String clientVersion,
  }) async =>
      _disabled();
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
  Future<void> resendSignupConfirmation(String email) async => _disabled();
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
  Future<void> ensureAccount() async => _disabled();
  @override
  Future<void> deleteMyAccount(String password) async => _disabled();
  @override
  Future<void> unblockKeeper(String userId) async => _disabled();
  @override
  Future<List<FriendMessage>> openFriendMessages(String friendId) async =>
      _disabled();
  @override
  Future<void> sendFriendMessage(String friendId, String body) async =>
      _disabled();
  @override
  Future<void> setSocialPreferences({
    required bool friendMessagesAllowed,
    required bool shareAchievementsWithConclave,
  }) async =>
      _disabled();
  @override
  Future<List<ConclaveSummary>> listConclaves() async => _disabled();
  @override
  Future<ConclaveSnapshot?> loadConclaveSnapshot() async => _disabled();
  @override
  Future<void> createConclave({
    required String name,
    required String emblemKey,
    required String description,
    required String language,
    required ConclaveVisibility visibility,
    required int memberLimit,
  }) async =>
      _disabled();
  @override
  Future<void> requestOrJoinConclave(String conclaveId) async => _disabled();
  @override
  Future<void> respondConclaveJoinRequest(
          String requestId, bool accept) async =>
      _disabled();
  @override
  Future<void> inviteToConclave(String keeperCode) async => _disabled();
  @override
  Future<void> respondConclaveInvite(String inviteId, bool accept) async =>
      _disabled();
  @override
  Future<void> contributeToConclave() async => _disabled();
  @override
  Future<void> sendConclaveMessage({
    required String kind,
    required String body,
    Map<String, dynamic> payload = const {},
  }) async =>
      _disabled();
  @override
  Future<void> synchronizeConclaveAchievements(
          List<String> achievementIds) async =>
      _disabled();
  @override
  Future<void> leaveConclave() async => _disabled();
  @override
  Future<void> setConclaveMemberRole(String userId, ConclaveRole role) async =>
      _disabled();
  @override
  Future<void> transferConclave(String userId) async => _disabled();
  @override
  Future<void> removeConclaveMember(String userId) async => _disabled();
  @override
  Future<void> dissolveConclave() async => _disabled();
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
    String? frameKey,
    String? badgeKey,
  }) async =>
      _disabled();
  @override
  void dispose() {}
}
