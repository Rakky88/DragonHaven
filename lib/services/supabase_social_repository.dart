import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/social.dart';
import 'social_repository.dart';

class SupabaseSocialRepository implements SocialRepository {
  SupabaseSocialRepository(this._client) {
    _authSubscription = _client.auth.onAuthStateChange.listen(
      (event) => _authController.add(
        event.session != null && event.session?.user.emailConfirmedAt != null,
      ),
    );
  }

  final SupabaseClient _client;
  final _authController = StreamController<bool>.broadcast();
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  bool get isConfigured => true;
  @override
  bool get isSignedIn => _client.auth.currentSession != null && isEmailVerified;
  @override
  bool get isEmailVerified =>
      _client.auth.currentUser?.emailConfirmedAt != null;
  @override
  String? get currentEmail => _client.auth.currentUser?.email;
  @override
  Stream<bool> get authStateChanges => _authController.stream;

  @override
  Future<AccountAuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final result = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {'display_name': displayName.trim()},
      );
      final requiresConfirmation = result.user?.emailConfirmedAt == null;
      if (requiresConfirmation && result.session != null) {
        await _client.auth.signOut();
      }
      return AccountAuthResult(
        requiresEmailConfirmation: requiresConfirmation,
      );
    } on Object catch (error) {
      throw _socialError(error);
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      final result = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (result.user?.emailConfirmedAt == null) {
        await _client.auth.signOut();
        throw const SocialException('email_not_verified');
      }
    } on Object catch (error) {
      throw _socialError(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on Object catch (error) {
      throw _socialError(error);
    }
  }

  @override
  Future<KeeperProfile> loadMyProfile() async =>
      KeeperProfile.fromJson(await _singleRpc('get_my_profile'));

  @override
  Future<List<KeeperProfile>> loadFriends() async =>
      (await _listRpc('list_my_friends'))
          .map(KeeperProfile.fromJson)
          .toList(growable: false);

  @override
  Future<List<FriendshipRequest>> loadRequests() async =>
      (await _listRpc('list_friend_requests'))
          .map(FriendshipRequest.fromJson)
          .toList(growable: false);

  @override
  Future<List<KeeperProfile>> loadBlockedKeepers() async =>
      (await _listRpc('list_blocked_keepers'))
          .map(KeeperProfile.fromJson)
          .toList(growable: false);

  @override
  Future<void> updateProfile({
    required String displayName,
    required String title,
    required String portraitKey,
  }) async {
    await _rpc('update_my_profile', params: {
      'p_display_name': displayName.trim(),
      'p_title': title.trim(),
      'p_portrait_key': portraitKey,
    });
  }

  @override
  Future<void> importLegacyInventory(OnlineInventorySnapshot snapshot) async {
    await _rpc('import_legacy_inventory', params: {
      'p_inventory': snapshot.toJson(),
    });
  }

  @override
  Future<void> publishSocialShowcase(OnlineInventorySnapshot snapshot) async {
    await _rpc('publish_social_showcase', params: {
      'p_showcase': snapshot.toShowcaseJson(),
    });
  }

  @override
  Future<void> sendFriendRequest(String keeperCode) async {
    await _rpc('send_friend_request', params: {
      'p_keeper_code': keeperCode.trim().toUpperCase(),
    });
  }

  @override
  Future<void> respondToRequest(String requestId, String response) async {
    await _rpc('respond_friend_request', params: {
      'p_request_id': requestId,
      'p_response': response,
    });
  }

  @override
  Future<void> removeFriend(String userId) async {
    await _rpc('remove_friend', params: {'p_friend_id': userId});
  }

  @override
  Future<void> blockKeeper(String userId) async {
    await _rpc('block_keeper', params: {'p_keeper_id': userId});
  }

  @override
  Future<void> unblockKeeper(String userId) async {
    await _rpc('unblock_keeper', params: {'p_keeper_id': userId});
  }

  @override
  Future<GroupAdventureStatus> loadGroupAdventureStatus() async {
    final rows = await _listRpc('get_current_group_adventure_status');
    if (rows.isEmpty) throw const SocialException('group_offer_unavailable');
    return GroupAdventureStatus.fromJson(rows.first);
  }

  @override
  Future<List<GroupAdventureLobby>> loadGroupAdventures() async =>
      (await _listRpc('list_group_adventures'))
          .map(GroupAdventureLobby.fromJson)
          .toList(growable: false);

  @override
  Future<void> createGroupLobby(
    String adventureId,
    GroupDragonSubmission dragon,
  ) async {
    await _rpc('create_group_adventure_lobby', params: {
      'p_adventure_id': adventureId,
      'p_dragon': dragon.data,
    });
  }

  @override
  Future<void> joinGroupLobby(
    String lobbyId,
    GroupDragonSubmission dragon,
  ) async {
    await _rpc('join_group_adventure_lobby', params: {
      'p_lobby_id': lobbyId,
      'p_dragon': dragon.data,
    });
  }

  @override
  Future<void> leaveGroupLobby(String lobbyId) async {
    await _rpc('leave_group_adventure_lobby', params: {
      'p_lobby_id': lobbyId,
    });
  }

  @override
  Future<void> removeGroupParticipant(String lobbyId, String userId) async {
    await _rpc('remove_group_adventure_participant', params: {
      'p_lobby_id': lobbyId,
      'p_user_id': userId,
    });
  }

  @override
  Future<GroupAdventureReward?> claimGroupReward(String lobbyId) async {
    final rows = await _listRpc('claim_group_adventure_reward', params: {
      'p_lobby_id': lobbyId,
    });
    return rows.isEmpty ? null : GroupAdventureReward.fromJson(rows.first);
  }

  @override
  Future<void> acknowledgeGroupReward(String lobbyId) async {
    await _rpc('acknowledge_group_adventure_reward', params: {
      'p_lobby_id': lobbyId,
    });
  }

  @override
  Future<void> synchronizeTradeInventory(
    OnlineInventorySnapshot snapshot,
  ) async {
    await _rpc('synchronize_trade_inventory', params: {
      'p_inventory': snapshot.toTradeJson(),
    });
  }

  @override
  Future<List<TradeInventoryItem>> loadTradeInventory() async =>
      (await _listRpc('list_trade_inventory'))
          .map(TradeInventoryItem.fromJson)
          .toList(growable: false);

  @override
  Future<List<TradeOffer>> loadTrades() async =>
      (await _listRpc('list_my_trades'))
          .map(TradeOffer.fromJson)
          .toList(growable: false);

  @override
  Future<void> createTrade(String friendId, TradeItem item) async {
    await _rpc('create_trade', params: {
      'p_friend_id': friendId,
      'p_item': item.toRequestJson(),
    });
  }

  @override
  Future<void> respondToTrade(String tradeId, TradeItem item) async {
    await _rpc('respond_trade', params: {
      'p_trade_id': tradeId,
      'p_item': item.toRequestJson(),
    });
  }

  @override
  Future<void> completeTrade(String tradeId) async {
    await _rpc('complete_trade', params: {'p_trade_id': tradeId});
  }

  @override
  Future<void> cancelTrade(String tradeId) async {
    await _rpc('cancel_trade', params: {'p_trade_id': tradeId});
  }

  @override
  Future<void> rejectTrade(String tradeId) async {
    await _rpc('reject_trade', params: {'p_trade_id': tradeId});
  }

  @override
  Future<void> acknowledgeTrade(String tradeId) async {
    await _rpc('acknowledge_trade', params: {'p_trade_id': tradeId});
  }

  Future<dynamic> _rpc(String function, {Map<String, dynamic>? params}) async {
    try {
      return await _client.rpc(function, params: params);
    } on Object catch (error) {
      throw _socialError(error);
    }
  }

  Future<Map<String, dynamic>> _singleRpc(String function) async {
    final rows = await _listRpc(function);
    if (rows.isEmpty) throw const SocialException('profile_not_found');
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> _listRpc(
    String function, {
    Map<String, dynamic>? params,
  }) async {
    final result = await _rpc(function, params: params);
    if (result is! List) return const [];
    return result
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  SocialException _socialError(Object error) {
    final message = switch (error) {
      AuthException auth => auth.message,
      PostgrestException postgrest => postgrest.message,
      _ => error.toString(),
    };
    const knownCodes = {
      'keeper_not_found',
      'keeper_unavailable',
      'cannot_friend_self',
      'request_already_pending',
      'request_recently_rejected',
      'too_many_requests',
      'already_friends',
      'request_not_found',
      'invalid_response',
      'invalid_profile',
      'inventory_already_imported',
      'invalid_inventory',
      'email_not_verified',
      'group_login_required',
      'group_offer_unavailable',
      'group_lobby_not_found',
      'group_lobby_closed',
      'group_lobby_full',
      'group_lobby_already_exists',
      'group_already_joined',
      'group_adventure_already_completed',
      'group_not_friends',
      'group_not_owner',
      'group_owner_cannot_be_removed',
      'group_participant_not_found',
      'group_dragon_busy',
      'invalid_group_dragon',
      'group_reward_not_ready',
      'group_reward_already_claimed',
      'trade_not_found',
      'trade_not_friends',
      'trade_wrong_participant',
      'trade_wrong_state',
      'trade_item_invalid',
      'trade_item_unavailable',
      'trade_inventory_locked',
      'trade_apply_failed',
    };
    final normalized = message.trim().toLowerCase().replaceAll(' ', '_');
    if (normalized.contains('email_not_confirmed')) {
      return const SocialException('email_not_verified');
    }
    return SocialException(
      knownCodes.firstWhere(
        (code) => normalized.contains(code),
        orElse: () => message,
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _authController.close();
  }
}
