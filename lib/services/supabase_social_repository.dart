import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/social.dart';
import 'social_repository.dart';

class SupabaseSocialRepository implements SocialRepository {
  SupabaseSocialRepository(this._client) {
    _authSubscription = _client.auth.onAuthStateChange.listen(
      (event) => _authController.add(event.session != null),
    );
  }

  final SupabaseClient _client;
  final _authController = StreamController<bool>.broadcast();
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  bool get isConfigured => true;
  @override
  bool get isSignedIn => _client.auth.currentSession != null;
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
      return AccountAuthResult(
        requiresEmailConfirmation: result.session == null,
      );
    } on Object catch (error) {
      throw _socialError(error);
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
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

  Future<List<Map<String, dynamic>>> _listRpc(String function) async {
    final result = await _rpc(function);
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
    };
    final normalized = message.trim().toLowerCase().replaceAll(' ', '_');
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
