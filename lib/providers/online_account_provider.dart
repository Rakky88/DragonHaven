import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/social.dart';
import '../services/social_repository.dart';

class OnlineAccountProvider extends ChangeNotifier {
  OnlineAccountProvider({
    required SocialRepository repository,
    required OnlineInventorySnapshot Function() inventorySnapshot,
  })  : _repository = repository,
        _inventorySnapshot = inventorySnapshot;

  final SocialRepository _repository;
  final OnlineInventorySnapshot Function() _inventorySnapshot;
  StreamSubscription<bool>? _authSubscription;
  bool _disposed = false;

  KeeperProfile? profile;
  List<KeeperProfile> friends = const [];
  List<FriendshipRequest> requests = const [];
  List<KeeperProfile> blockedKeepers = const [];
  bool busy = false;
  String? errorCode;
  String? noticeCode;

  bool get isConfigured => _repository.isConfigured;
  bool get isSignedIn => _repository.isSignedIn;
  String? get currentEmail => _repository.currentEmail;
  List<FriendshipRequest> get incomingRequests => requests
      .where((request) => request.direction == FriendRequestDirection.incoming)
      .toList(growable: false);
  List<FriendshipRequest> get outgoingRequests => requests
      .where((request) => request.direction == FriendRequestDirection.outgoing)
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
  }

  Future<AccountAuthResult?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async =>
      _run(() async {
        final result = await _repository.signUp(
          email: email,
          password: password,
          displayName: displayName,
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

  Future<bool> updateProfile({
    required String displayName,
    required String title,
    required String portraitKey,
  }) async =>
      await _run(() async {
        await _repository.updateProfile(
          displayName: displayName,
          title: title,
          portraitKey: portraitKey,
        );
        await _refreshData();
        noticeCode = 'profile_saved';
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

  void clearMessages() {
    errorCode = null;
    noticeCode = null;
  }

  Future<void> _refreshData() async {
    final snapshot = _inventorySnapshot();
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
    ]);
    profile = ownProfile;
    friends = results[0] as List<KeeperProfile>;
    requests = results[1] as List<FriendshipRequest>;
    blockedKeepers = results[2] as List<KeeperProfile>;
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
