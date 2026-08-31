import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../l10n/app_strings.dart';
import '../models/mystic_relic.dart';
import '../models/social.dart';
import '../services/diagnostic_reporter.dart';
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
    String clientVersion = 'unknown',
    Future<int?> Function(String userId)? loadCloudBaseRevision,
    Future<void> Function(String userId, int revision)? saveCloudBaseRevision,
    String Function()? languageCode,
    DiagnosticReporter diagnostics = const NoopDiagnosticReporter(),
    Duration operationTimeout = const Duration(seconds: 75),
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
        _clientVersion = clientVersion,
        _loadCloudBaseRevision =
            loadCloudBaseRevision ?? _missingCloudBaseRevision,
        _saveCloudBaseRevision =
            saveCloudBaseRevision ?? _ignoreCloudBaseRevision,
        _languageCode = languageCode ?? _defaultLanguageCode,
        _diagnostics = diagnostics,
        _operationTimeout = operationTimeout;

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
  final String _clientVersion;
  final Future<int?> Function(String userId) _loadCloudBaseRevision;
  final Future<void> Function(String userId, int revision)
      _saveCloudBaseRevision;
  final String Function() _languageCode;
  final DiagnosticReporter _diagnostics;
  final Duration _operationTimeout;
  StreamSubscription<bool>? _authSubscription;
  Timer? _refreshTimer;
  Timer? _authRecoveryTimer;
  Future<bool>? _refreshInFlight;
  DateTime? _lastRefreshStartedAt;
  bool _lastRefreshSucceeded = false;
  String? _lastProfileFingerprint;
  String? _lastTradeInventoryFingerprint;
  String? _lastShowcaseFingerprint;
  String? _lastConclaveAchievementFingerprint;
  DateTime? _lastPresenceUpdate;
  bool _operationInFlight = false;
  bool _disposed = false;
  String? _cloudBaseUserId;
  int? _cloudBaseRevision;

  KeeperProfile? profile;
  List<KeeperProfile> friends = const [];
  List<FriendshipRequest> requests = const [];
  List<KeeperProfile> blockedKeepers = const [];
  List<GroupAdventureLobby> groupLobbies = const [];
  GroupAdventureStatus? groupAdventureStatus;
  List<TradeOffer> trades = const [];
  List<TradeInventoryItem> tradeInventory = const [];
  List<FriendConversationSummary> friendConversations = const [];
  bool friendMessagesAllowed = true;
  bool shareAchievementsWithConclave = false;
  ConclaveSnapshot? conclave;
  List<ConclaveInvite> conclaveInvites = const [];
  CloudGameSave? cloudGameSave;
  CloudGameSave? cloudConflictSave;
  List<CloudGameSaveSummary> cloudSaveHistory = const [];
  bool busy = false;
  String? errorCode;
  String? noticeCode;
  String? supportCode;

  List<DiagnosticEvent> get recentDiagnostics => _diagnostics.recentEvents;

  String buildSupportDiagnosticReport({required String appVersion}) =>
      const JsonEncoder.withIndent('  ').convert({
        'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'appVersion': appVersion,
        'onlineConfigured': isConfigured,
        'signedIn': isSignedIn,
        'emailVerified': isEmailVerified,
        if (profile case final currentProfile?) ...{
          'keeperId': currentProfile.keeperCode,
          'userId': currentProfile.userId,
        },
        if (errorCode case final currentError?) 'lastErrorCode': currentError,
        if (supportCode case final currentSupport?)
          'lastSupportCode': currentSupport,
        'recentOnlineEvents': recentDiagnostics
            .map((event) => event.toSafeJson())
            .toList(growable: false),
      });

  bool get isConfigured => _repository.isConfigured;
  bool get isSignedIn => _repository.isSignedIn;
  bool get isEmailVerified => _repository.isEmailVerified;
  String? get currentUserId => _repository.currentUserId;
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
  int get unreadFriendMessageCount => friendConversations.fold(
        0,
        (total, conversation) => total + conversation.unreadCount,
      );
  FriendConversationSummary? conversationWith(String friendId) =>
      friendConversations.cast<FriendConversationSummary?>().firstWhere(
            (conversation) => conversation?.friendId == friendId,
            orElse: () => null,
          );

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

  Future<void> initialize({bool waitForFirstRefresh = true}) async {
    _authSubscription = _repository.authStateChanges.listen(
      (signedIn) {
        if (signedIn) {
          unawaited(refresh());
        } else {
          _clearAccountData();
          _notify();
        }
      },
      onError: (Object error) {
        final correlationId = DiagnosticIds.create();
        errorCode =
            error is SocialException ? error.code : 'online_unexpected_error';
        supportCode = DiagnosticIds.supportCode(correlationId);
        _diagnostics.record(DiagnosticEvent(
          operation: 'auth.state_change',
          correlationId: correlationId,
          outcome: DiagnosticOutcome.failure,
          startedAt: DateTime.now(),
          duration: Duration.zero,
          errorCode: errorCode,
        ));
        _notify();
        _authRecoveryTimer?.cancel();
        _authRecoveryTimer = Timer(const Duration(seconds: 2), () {
          if (isSignedIn && !busy) unawaited(refresh());
        });
      },
    );
    if (isSignedIn) {
      final firstRefresh = refresh();
      if (waitForFirstRefresh) {
        await firstRefresh;
      } else {
        unawaited(firstRefresh);
      }
    }
    _ensureRefreshTimer();
  }

  Future<AccountAuthResult?> signUp({
    required String email,
    required String password,
  }) async =>
      _run('auth.sign_up', () async {
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
      await _run('auth.sign_in', () async {
        await _repository.signIn(email: email, password: password);
        await _refreshData();
        _ensureRefreshTimer();
        noticeCode = 'signed_in';
        return true;
      }) ??
      false;

  Future<bool> resendSignupConfirmation(String email) async =>
      await _run('auth.resend_confirmation', () async {
        await _repository.resendSignupConfirmation(email);
        noticeCode = 'confirmation_resent';
        return true;
      }) ??
      false;

  Future<bool> signOut() async =>
      await _run('auth.sign_out', () async {
        await _repository.signOut();
        _clearAccountData();
        return true;
      }) ??
      false;

  Future<bool> deleteAccount(String password) async =>
      await _run('auth.delete_account', () async {
        await _repository.deleteMyAccount(password);
        _clearAccountData();
        noticeCode = 'account_deleted';
        return true;
      }) ??
      false;

  /// Performs an explicit online refresh.
  ///
  /// Multiple callers that arrive while the same refresh is running share one
  /// request. This prevents rebuilds and lifecycle callbacks from creating a
  /// queue of identical server calls.
  Future<bool> refresh() {
    final pending = _refreshInFlight;
    if (pending != null) return pending;
    final completer = Completer<bool>();
    final sharedRequest = completer.future;
    // Publish the shared future before _performRefresh can notify listeners.
    // A listener that immediately asks for another refresh then receives this
    // same request instead of starting a re-entrant operation.
    _refreshInFlight = sharedRequest;
    unawaited(() async {
      try {
        completer.complete(await _performRefresh());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        if (identical(_refreshInFlight, sharedRequest)) {
          _refreshInFlight = null;
        }
      }
    }());
    return sharedRequest;
  }

  /// Refreshes only when the latest automatic refresh is old enough.
  ///
  /// User-initiated refresh actions should call [refresh] so they remain
  /// immediate. Screen initialization, navigation and app resume use this
  /// guarded variant to avoid refresh storms.
  Future<bool> refreshIfStale({
    Duration minimumInterval = const Duration(seconds: 15),
  }) {
    final pending = _refreshInFlight;
    if (pending != null) return pending;
    final lastStartedAt = _lastRefreshStartedAt;
    if (lastStartedAt != null &&
        DateTime.now().difference(lastStartedAt) < minimumInterval) {
      return Future.value(_lastRefreshSucceeded);
    }
    return refresh();
  }

  Future<bool> _performRefresh() async {
    _lastRefreshStartedAt = DateTime.now();
    final succeeded = await _run('social.refresh', () async {
          if (!isSignedIn) return false;
          await _refreshData();
          return true;
        }) ??
        false;
    _lastRefreshSucceeded = succeeded;
    return succeeded;
  }

  Future<bool> synchronizeProfile() => refresh();

  Future<bool> loadCloudSaveStatus() async =>
      await _run('cloud_save.status', () async {
        if (!isSignedIn) return false;
        cloudGameSave = await _repository.loadCloudGameSave();
        return true;
      }) ??
      false;

  Future<bool> loadCloudSaveHistory() async =>
      await _run('cloud_save.history', () async {
        if (!isSignedIn) return false;
        cloudSaveHistory = await _repository.loadCloudGameSaveHistory();
        return true;
      }) ??
      false;

  Future<bool> backupToCloud({bool automatic = false}) async =>
      await _run('cloud_save.backup', () async {
        final snapshot = _gameStateSnapshot;
        final loadDeviceId = _deviceId;
        if (!isSignedIn || snapshot == null || loadDeviceId == null) {
          throw const SocialException('cloud_save_unavailable');
        }
        final remote = await _repository.loadCloudGameSave();
        cloudGameSave = remote;
        final baseRevision = await _currentCloudBaseRevision();
        final remoteRevision = remote?.revision ?? 0;
        if ((baseRevision == null && remote != null) ||
            (baseRevision != null && baseRevision != remoteRevision)) {
          cloudConflictSave = remote;
          throw const SocialException('cloud_save_conflict');
        }
        try {
          cloudGameSave = await _repository.pushCloudGameSave(
            expectedRevision: baseRevision ?? 0,
            state: snapshot(),
            deviceId: await loadDeviceId(),
            clientVersion: _clientVersion,
          );
        } on SocialException catch (error) {
          if (error.code == 'cloud_save_conflict') {
            try {
              cloudConflictSave = await _repository.loadCloudGameSave();
              cloudGameSave = cloudConflictSave;
            } on Object {
              cloudConflictSave = remote;
            }
          }
          rethrow;
        }
        await _rememberCloudBaseRevision(cloudGameSave!.revision);
        cloudConflictSave = null;
        cloudSaveHistory = const [];
        if (!automatic) noticeCode = 'cloud_save_backed_up';
        return true;
      }, background: automatic) ??
      false;

  Future<bool> replaceCloudWithLocal() async =>
      await _run('cloud_save.replace_with_local', () async {
        final snapshot = _gameStateSnapshot;
        final loadDeviceId = _deviceId;
        if (!isSignedIn || snapshot == null || loadDeviceId == null) {
          throw const SocialException('cloud_save_unavailable');
        }
        final remote = await _repository.loadCloudGameSave();
        try {
          cloudGameSave = await _repository.pushCloudGameSave(
            expectedRevision: remote?.revision ?? 0,
            state: snapshot(),
            deviceId: await loadDeviceId(),
            clientVersion: _clientVersion,
          );
        } on SocialException catch (error) {
          if (error.code == 'cloud_save_conflict') {
            cloudConflictSave = await _repository.loadCloudGameSave();
            cloudGameSave = cloudConflictSave;
          }
          rethrow;
        }
        await _rememberCloudBaseRevision(cloudGameSave!.revision);
        cloudConflictSave = null;
        cloudSaveHistory = const [];
        noticeCode = 'cloud_save_backed_up';
        return true;
      }) ??
      false;

  Future<bool> restoreFromCloud() async =>
      await _run('cloud_save.restore', () async {
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
        await _rememberCloudBaseRevision(remote.revision);
        cloudConflictSave = null;
        _lastTradeInventoryFingerprint = null;
        _lastShowcaseFingerprint = null;
        await _refreshData();
        noticeCode = 'cloud_save_restored';
        return true;
      }) ??
      false;

  Future<bool> restoreCloudRevision(String saveId) async =>
      await _run('cloud_save.restore_revision', () async {
        final apply = _applyCloudState;
        if (!isSignedIn || apply == null || saveId.isEmpty) {
          throw const SocialException('cloud_save_unavailable');
        }
        final current = await _repository.loadCloudGameSave();
        if (current == null) throw const SocialException('cloud_save_missing');
        final selected = await _repository.loadCloudGameSaveRevision(saveId);
        if (selected == null) throw const SocialException('cloud_save_missing');
        if (!await apply(selected.state)) {
          throw const SocialException('cloud_save_invalid');
        }
        cloudGameSave = current;
        await _rememberCloudBaseRevision(current.revision);
        cloudConflictSave = null;
        _lastTradeInventoryFingerprint = null;
        _lastShowcaseFingerprint = null;
        await _refreshData();
        noticeCode = 'cloud_save_restored';
        return true;
      }) ??
      false;

  Future<bool> sendFriendRequest(String keeperCode) async =>
      await _run('friends.send_request', () async {
        await _repository.sendFriendRequest(keeperCode);
        await _refreshData();
        noticeCode = 'request_sent';
        return true;
      }) ??
      false;

  Future<bool> respondToRequest(String requestId, String response) async =>
      await _run('friends.respond_request', () async {
        await _repository.respondToRequest(requestId, response);
        await _refreshData();
        noticeCode = 'request_$response';
        return true;
      }) ??
      false;

  Future<bool> removeFriend(String userId) async =>
      await _run('friends.remove', () async {
        await _repository.removeFriend(userId);
        await _refreshData();
        noticeCode = 'friend_removed';
        return true;
      }) ??
      false;

  Future<bool> blockKeeper(String userId) async =>
      await _run('friends.block', () async {
        await _repository.blockKeeper(userId);
        await _refreshData();
        noticeCode = 'keeper_blocked';
        return true;
      }) ??
      false;

  Future<bool> unblockKeeper(String userId) async =>
      await _run('friends.unblock', () async {
        await _repository.unblockKeeper(userId);
        await _refreshData();
        noticeCode = 'keeper_unblocked';
        return true;
      }) ??
      false;

  Future<List<FriendMessage>?> openFriendMessages(
    String friendId, {
    bool background = false,
  }) =>
      _run('messages.open', () async {
        final messages = await _repository.openFriendMessages(friendId);
        final previous = conversationWith(friendId);
        final last = messages.isEmpty ? null : messages.last;
        friendConversations = [
          for (final conversation in friendConversations)
            if (conversation.friendId == friendId)
              FriendConversationSummary(
                friendId: friendId,
                messagesAllowed: conversation.messagesAllowed,
                unreadCount: 0,
                lastMessage: last?.body ?? conversation.lastMessage,
                lastMessageAt: last?.createdAt ?? conversation.lastMessageAt,
                lastMessageFromMe: last == null
                    ? conversation.lastMessageFromMe
                    : last.senderId == currentUserId,
              )
            else
              conversation,
          if (previous == null && last != null)
            FriendConversationSummary(
              friendId: friendId,
              messagesAllowed: true,
              unreadCount: 0,
              lastMessage: last.body,
              lastMessageAt: last.createdAt,
              lastMessageFromMe: last.senderId == currentUserId,
            ),
        ];
        return messages;
      }, background: background);

  Future<bool> sendFriendMessage(String friendId, String body) async =>
      await _run('messages.send', () async {
        await _repository.sendFriendMessage(friendId, body.trim());
        return true;
      }) ??
      false;

  Future<bool> setFriendMessagesAllowed(bool allowed) =>
      _setSocialPreferences(messagesAllowed: allowed);

  Future<bool> setShareAchievementsWithConclave(bool share) =>
      _setSocialPreferences(shareAchievements: share);

  Future<bool> _setSocialPreferences({
    bool? messagesAllowed,
    bool? shareAchievements,
  }) async =>
      await _run('social.preferences', () async {
        await _repository.setSocialPreferences(
          friendMessagesAllowed: messagesAllowed ?? friendMessagesAllowed,
          shareAchievementsWithConclave:
              shareAchievements ?? shareAchievementsWithConclave,
        );
        _lastConclaveAchievementFingerprint = null;
        await _refreshData();
        return true;
      }) ??
      false;

  Future<List<ConclaveSummary>?> loadConclaveDirectory() =>
      _run('conclave.directory', _repository.listConclaves);

  Future<bool> refreshConclave({bool background = false}) async =>
      await _run('conclave.refresh', () async {
        conclave = await _repository.loadConclaveSnapshot();
        return true;
      }, background: background) ??
      false;

  Future<bool> createConclave({
    required String name,
    required String emblemKey,
    required String description,
    required String language,
    required ConclaveVisibility visibility,
    required int memberLimit,
  }) async =>
      await _run('conclave.create', () async {
        await _repository.createConclave(
          name: name,
          emblemKey: emblemKey,
          description: description,
          language: language,
          visibility: visibility,
          memberLimit: memberLimit,
        );
        await _refreshData();
        return true;
      }) ??
      false;

  Future<bool> requestOrJoinConclave(String id) async =>
      await _run('conclave.join', () async {
        await _repository.requestOrJoinConclave(id);
        await _refreshData();
        return true;
      }) ??
      false;

  Future<bool> respondConclaveJoinRequest(String id, bool accept) async =>
      await _run('conclave.respond_request', () async {
        await _repository.respondConclaveJoinRequest(id, accept);
        await _refreshData();
        return true;
      }) ??
      false;

  Future<bool> inviteToConclave(String keeperCode) async =>
      await _run('conclave.invite', () async {
        await _repository.inviteToConclave(keeperCode);
        noticeCode = 'conclave_invite_sent';
        return true;
      }) ??
      false;

  Future<bool> respondConclaveInvite(String id, bool accept) async =>
      await _run('conclave.respond_invite', () async {
        await _repository.respondConclaveInvite(id, accept);
        await _refreshData();
        return true;
      }) ??
      false;

  Future<bool> contributeToConclave() async =>
      await _run('conclave.contribute', () async {
        await _repository.contributeToConclave();
        await _refreshData();
        return true;
      }) ??
      false;

  Future<bool> sendConclaveMessage({
    required String kind,
    required String body,
    Map<String, dynamic> payload = const {},
  }) async =>
      await _run('conclave.message', () async {
        await _repository.sendConclaveMessage(
          kind: kind,
          body: body,
          payload: payload,
        );
        await _refreshData();
        return true;
      }) ??
      false;

  Future<bool> leaveConclave() async =>
      await _run('conclave.leave', () async {
        await _repository.leaveConclave();
        _lastConclaveAchievementFingerprint = null;
        await _refreshData();
        return true;
      }) ??
      false;

  Future<bool> setConclaveMemberRole(String id, ConclaveRole role) async =>
      await _run('conclave.role', () async {
        await _repository.setConclaveMemberRole(id, role);
        await _refreshData();
        return true;
      }) ??
      false;

  Future<bool> transferConclave(String id) async =>
      await _run('conclave.transfer', () async {
        await _repository.transferConclave(id);
        await _refreshData();
        return true;
      }) ??
      false;

  Future<bool> removeConclaveMember(String id) async =>
      await _run('conclave.remove_member', () async {
        await _repository.removeConclaveMember(id);
        await _refreshData();
        return true;
      }) ??
      false;

  Future<bool> dissolveConclave() async =>
      await _run('conclave.dissolve', () async {
        await _repository.dissolveConclave();
        _lastConclaveAchievementFingerprint = null;
        await _refreshData();
        return true;
      }) ??
      false;

  Future<bool> createGroupLobby(
    String adventureId,
    GroupDragonSubmission dragon,
  ) async =>
      await _run('group.create', () async {
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
      await _run('group.join', () async {
        await _repository.joinGroupLobby(lobbyId, dragon);
        await _refreshData();
        noticeCode = 'group_joined';
        return true;
      }) ??
      false;

  Future<bool> leaveGroupLobby(String lobbyId) async =>
      await _run('group.leave', () async {
        await _repository.leaveGroupLobby(lobbyId);
        await _refreshData();
        noticeCode = 'group_left';
        return true;
      }) ??
      false;

  Future<bool> removeGroupParticipant(String lobbyId, String userId) async =>
      await _run('group.remove_participant', () async {
        await _repository.removeGroupParticipant(lobbyId, userId);
        await _refreshData();
        noticeCode = 'group_participant_removed';
        return true;
      }) ??
      false;

  Future<GroupAdventureReward?> claimGroupReward(String lobbyId) =>
      _run('group.claim_reward', () async {
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
      await _run('trade.prepare_inventory', () async {
        await _refreshData();
        return true;
      }) ??
      false;

  Future<bool> createTrade(String friendId, TradeItem item) async =>
      await _run('trade.create', () async {
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
      await _run('trade.respond', () async {
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
      await _run('trade.complete', () async {
        await _repository.completeTrade(tradeId);
        await _refreshData();
        noticeCode = 'trade_completed';
        return true;
      }) ??
      false;

  Future<bool> cancelTrade(String tradeId) async =>
      await _run('trade.cancel', () async {
        await _repository.cancelTrade(tradeId);
        await _refreshData();
        noticeCode = 'trade_cancelled';
        return true;
      }) ??
      false;

  Future<bool> rejectTrade(String tradeId) async =>
      await _run('trade.reject', () async {
        await _repository.rejectTrade(tradeId);
        await _refreshData();
        noticeCode = 'trade_rejected';
        return true;
      }) ??
      false;

  void clearMessages() {
    errorCode = null;
    noticeCode = null;
    supportCode = null;
    _notify();
  }

  Future<void> _refreshData() async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _refreshDataOnce();
        return;
      } on SocialException catch (error) {
        lastError = error;
        if (!_retryableRefreshCode(error.code) || attempt == 2) rethrow;
      } on Object catch (error) {
        lastError = error;
        if (attempt == 2) rethrow;
      }
      await Future<void>.delayed(
        attempt == 0
            ? const Duration(milliseconds: 250)
            : const Duration(milliseconds: 750),
      );
    }
    throw lastError!;
  }

  Future<void> _refreshDataOnce() async {
    await _repository.ensureAccount();
    final snapshot = _inventorySnapshot();
    final localProfile = _profileSnapshot();
    final profileFingerprint = jsonEncode({
      'displayName': localProfile.displayName,
      'title': localProfile.titleId,
      'portrait': localProfile.portraitId,
      'frame': localProfile.frameId,
      'badge': localProfile.badgeId,
    });
    final now = DateTime.now();
    final presenceExpired = _lastPresenceUpdate == null ||
        now.difference(_lastPresenceUpdate!) >= const Duration(minutes: 5);
    if (_lastProfileFingerprint != profileFingerprint || presenceExpired) {
      await _repository.updateProfile(
        displayName: localProfile.displayName,
        title: localProfile.titleId,
        portraitKey: localProfile.portraitId,
        frameKey: localProfile.frameId,
        badgeKey: localProfile.badgeId,
      );
      _lastProfileFingerprint = profileFingerprint;
      _lastPresenceUpdate = now;
    }
    var serverChanged = false;
    var onlineSnapshot = await _repository.loadOnlineSnapshot();
    _applyOnlineSnapshot(onlineSnapshot);
    if (!onlineSnapshot.profile.inventoryImported) {
      await _repository.importLegacyInventory(snapshot);
      serverChanged = true;
    }
    final pendingTrades = onlineSnapshot.trades;
    await _runRefreshMaintenanceStep(
      'social.refresh.trade_reservations',
      _synchronizeLocalTradeReservations,
    );
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
      final synchronized = await _runRefreshMaintenanceStep(
        'social.refresh.trade_inventory',
        () => _repository.synchronizeTradeInventory(currentSnapshot),
      );
      if (synchronized) {
        _lastTradeInventoryFingerprint = tradeInventoryFingerprint;
        serverChanged = true;
      }
    }
    final showcaseFingerprint = jsonEncode(currentSnapshot.toShowcaseJson());
    if (_lastShowcaseFingerprint != showcaseFingerprint) {
      final published = await _runRefreshMaintenanceStep(
        'social.refresh.showcase',
        () => _repository.publishSocialShowcase(currentSnapshot),
      );
      if (published) {
        _lastShowcaseFingerprint = showcaseFingerprint;
        serverChanged = true;
      }
    }
    final sortedAchievements = currentSnapshot.achievementIds.toList()..sort();
    final achievementFingerprint = jsonEncode({
      'conclave': onlineSnapshot.conclave?.conclave.id,
      'share': onlineSnapshot.shareAchievementsWithConclave,
      'achievements': sortedAchievements,
    });
    if (onlineSnapshot.conclave != null &&
        onlineSnapshot.shareAchievementsWithConclave &&
        _lastConclaveAchievementFingerprint != achievementFingerprint) {
      final synchronized = await _runRefreshMaintenanceStep(
        'social.refresh.conclave_achievements',
        () => _repository.synchronizeConclaveAchievements(
          sortedAchievements,
        ),
      );
      if (synchronized) {
        _lastConclaveAchievementFingerprint = achievementFingerprint;
        serverChanged = true;
      }
    }
    if (serverChanged) {
      await _runRefreshMaintenanceStep(
        'social.refresh.snapshot_reload',
        () async {
          onlineSnapshot = await _repository.loadOnlineSnapshot();
        },
      );
    }
    _applyOnlineSnapshot(onlineSnapshot);
    await _runRefreshMaintenanceStep(
      'social.refresh.group_reservations',
      () => _synchronizeGroupReservations({
        for (final lobby in myGroupAdventures)
          if (lobby.myDragonId case final dragonId?) dragonId: lobby.id,
      }),
    );
    await _runRefreshMaintenanceStep(
      'social.refresh.trade_reservations',
      _synchronizeLocalTradeReservations,
    );
    await _runRefreshMaintenanceStep(
      'social.refresh.notifications',
      () => _deliverSocialNotifications(onlineSnapshot.notifications),
    );
  }

  void _applyOnlineSnapshot(OnlineSocialSnapshot snapshot) {
    profile = snapshot.profile;
    friends = snapshot.friends;
    requests = snapshot.requests;
    blockedKeepers = snapshot.blockedKeepers;
    groupAdventureStatus = snapshot.groupAdventureStatus;
    groupLobbies = snapshot.groupLobbies;
    trades = snapshot.trades;
    tradeInventory = snapshot.tradeInventory
        .where((entry) => entry.item.isTradeable)
        .toList(growable: false);
    friendMessagesAllowed = snapshot.friendMessagesAllowed;
    shareAchievementsWithConclave = snapshot.shareAchievementsWithConclave;
    friendConversations = snapshot.friendConversations;
    conclave = snapshot.conclave;
    conclaveInvites = snapshot.conclaveInvites;
  }

  /// Online reads are the useful result of a refresh. Follow-up publication,
  /// reservation persistence and notification delivery are maintenance work:
  /// a malformed local item or a platform notification failure must never
  /// discard an already valid friends snapshot. Failed maintenance remains
  /// retryable because its fingerprint is only stored after success.
  Future<bool> _runRefreshMaintenanceStep(
    String operationName,
    Future<void> Function() operation,
  ) async {
    final correlationId = DiagnosticIds.create();
    final startedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    try {
      await operation();
      return true;
    } on SocialException catch (error) {
      stopwatch.stop();
      _diagnostics.record(DiagnosticEvent(
        operation: operationName,
        correlationId: correlationId,
        outcome: DiagnosticOutcome.failure,
        startedAt: startedAt,
        duration: stopwatch.elapsed,
        errorCode: error.code,
      ));
      return false;
    } on Object {
      stopwatch.stop();
      _diagnostics.record(DiagnosticEvent(
        operation: operationName,
        correlationId: correlationId,
        outcome: DiagnosticOutcome.failure,
        startedAt: startedAt,
        duration: stopwatch.elapsed,
        errorCode: 'online_unexpected_error',
      ));
      return false;
    }
  }

  bool _retryableRefreshCode(String code) => !const {
        'invalid_profile',
        'invalid_inventory',
        'email_not_verified',
        'online_login_required',
        'online_session_expired',
      }.contains(code);

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
        case 'friend_message':
          await HavenNotifications.friendMessage(
            id: notification.id,
            title: withName(
              'New message from {name}',
              'Nieuw bericht van {name}',
            ),
            body: strings.pick(
              'Open DragonHaven to read it.',
              'Open DragonHaven om het te lezen.',
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
          final reduction = item.key == MysticRelic.chronoshard.name
              ? (item.data['reductionPercent'] as num?)?.toInt()
              : null;
          final reservationKey = reduction == null
              ? item.key
              : '${MysticRelic.chronoshard.name}:$reduction';
          relics.update(reservationKey, (value) => value + 1,
              ifAbsent: () => 1);
      }
    }
    await _synchronizeTradeReservations(eggs, chests, relics);
  }

  void _ensureRefreshTimer() {
    if (!isConfigured || !isSignedIn || _refreshTimer != null) return;
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (isSignedIn && !busy) unawaited(refreshIfStale());
    });
  }

  Future<T?> _run<T>(String operationName, Future<T> Function() operation,
      {bool background = false}) async {
    // Future.timeout does not cancel its source future. Keep the single-flight
    // guard active until that source really settles, so a retry after a timeout
    // cannot overlap the original server mutation.
    if (busy || _operationInFlight) return null;
    final correlationId = DiagnosticIds.create();
    final startedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    _operationInFlight = true;
    busy = true;
    if (!background) {
      errorCode = null;
      supportCode = null;
      _notify();
    }
    final operationFuture = Future<T>.sync(operation);
    unawaited(operationFuture.then<void>(
      (_) => _operationInFlight = false,
      onError: (Object _, StackTrace __) => _operationInFlight = false,
    ));
    try {
      final result = await operationFuture.timeout(
        _operationTimeout,
        onTimeout: () => throw const SocialException('online_timeout'),
      );
      stopwatch.stop();
      _diagnostics.record(DiagnosticEvent(
        operation: operationName,
        correlationId: correlationId,
        outcome: DiagnosticOutcome.success,
        startedAt: startedAt,
        duration: stopwatch.elapsed,
      ));
      return result;
    } on SocialException catch (error) {
      stopwatch.stop();
      if (!background) {
        errorCode = error.code;
        supportCode = DiagnosticIds.supportCode(correlationId);
      }
      _diagnostics.record(DiagnosticEvent(
        operation: operationName,
        correlationId: correlationId,
        outcome: DiagnosticOutcome.failure,
        startedAt: startedAt,
        duration: stopwatch.elapsed,
        errorCode: error.code,
      ));
      return null;
    } on Object {
      stopwatch.stop();
      if (!background) {
        errorCode = 'online_unexpected_error';
        supportCode = DiagnosticIds.supportCode(correlationId);
      }
      _diagnostics.record(DiagnosticEvent(
        operation: operationName,
        correlationId: correlationId,
        outcome: DiagnosticOutcome.failure,
        startedAt: startedAt,
        duration: stopwatch.elapsed,
        errorCode: 'online_unexpected_error',
      ));
      return null;
    } finally {
      busy = false;
      if (!background) _notify();
    }
  }

  Future<int?> _currentCloudBaseRevision() async {
    final userId = _repository.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw const SocialException('online_login_required');
    }
    if (_cloudBaseUserId == userId) return _cloudBaseRevision;
    _cloudBaseUserId = userId;
    _cloudBaseRevision = await _loadCloudBaseRevision(userId);
    return _cloudBaseRevision;
  }

  Future<void> _rememberCloudBaseRevision(int revision) async {
    final userId = _repository.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw const SocialException('online_login_required');
    }
    await _saveCloudBaseRevision(userId, revision);
    _cloudBaseUserId = userId;
    _cloudBaseRevision = revision;
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
    friendConversations = const [];
    friendMessagesAllowed = true;
    shareAchievementsWithConclave = false;
    conclave = null;
    conclaveInvites = const [];
    cloudGameSave = null;
    cloudConflictSave = null;
    cloudSaveHistory = const [];
    _cloudBaseUserId = null;
    _cloudBaseRevision = null;
    _lastProfileFingerprint = null;
    _lastTradeInventoryFingerprint = null;
    _lastShowcaseFingerprint = null;
    _lastConclaveAchievementFingerprint = null;
    _lastPresenceUpdate = null;
    _lastRefreshStartedAt = null;
    _lastRefreshSucceeded = false;
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
    _authRecoveryTimer?.cancel();
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

Future<int?> _missingCloudBaseRevision(String _) async => null;

Future<void> _ignoreCloudBaseRevision(String _, int __) async {}
