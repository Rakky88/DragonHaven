import 'dart:async';
import 'dart:math';

import 'package:dragon_haven/dragonhaven_app.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('first online refresh imports the legacy inventory exactly once',
      () async {
    final game = HouseholdProvider(random: Random(3));
    final repository = _FakeSocialRepository();
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );

    await online.initialize();
    await online.refresh();

    expect(repository.importCount, 1);
    expect(repository.lastImport?.eggs, hasLength(1));
    expect(online.profile?.inventoryImported, isTrue);
    online.dispose();
  });

  testWidgets(
      'friend profile shows favorite dragon and removal requires confirmation',
      (tester) async {
    final game = HouseholdProvider(random: Random(7))
      ..accountName = 'Rick'
      ..onboardingComplete = true;
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Ember';
    final repository = _FakeSocialRepository(inventoryImported: true);
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    await online.initialize();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider.value(value: online),
      ],
      child: const DragonHavenApp(),
    ));
    await tester.pump(const Duration(milliseconds: 450));

    await tester.tap(find.text('Friends').last);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Lyra'), findsOneWidget);
    expect(find.textContaining('Discovered: 12'), findsOneWidget);

    await tester.tap(find.byKey(const Key('friend-friend-user')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Skywarden'), findsOneWidget);
    expect(find.text('Nimbus'), findsOneWidget);
    expect(find.textContaining('Level 4'), findsOneWidget);
    expect(find.text('Might'), findsOneWidget);
    expect(find.text('Arcana'), findsOneWidget);
    expect(find.text('Spirit'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('remove-friend-button')),
      300,
      scrollable: find.descendant(
        of: find.byKey(const Key('friend-profile-friend-user')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('remove-friend-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Remove friend?'), findsOneWidget);
    expect(repository.removeCount, 0);

    await tester.tap(find.byKey(const Key('confirm-remove-friend')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(repository.removeCount, 1);
    expect(find.byKey(const Key('friend-friend-user')), findsNothing);
    online.dispose();
  });

  test('friend requests support accepted, rejected and blocked outcomes',
      () async {
    for (final response in ['accepted', 'rejected', 'blocked']) {
      final game = HouseholdProvider(random: Random(response.hashCode));
      final repository = _FakeSocialRepository(
        inventoryImported: true,
        includeFriend: false,
        includeRequest: true,
      );
      final online = OnlineAccountProvider(
        repository: repository,
        inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
      );
      await online.initialize();

      expect(online.incomingRequests, hasLength(1));
      expect(await online.respondToRequest('request-1', response), isTrue);
      expect(repository.lastResponse, response);
      expect(online.incomingRequests, isEmpty);
      expect(online.friends, hasLength(response == 'accepted' ? 1 : 0));
      expect(online.blockedKeepers, hasLength(response == 'blocked' ? 1 : 0));
      online.dispose();
    }
  });
}

class _FakeSocialRepository implements SocialRepository {
  _FakeSocialRepository({
    bool inventoryImported = false,
    bool includeFriend = true,
    bool includeRequest = false,
  }) : _inventoryImported = inventoryImported {
    if (includeFriend) friendRows.add(_friend);
    if (includeRequest) {
      requestRows.add(FriendshipRequest(
        id: 'request-1',
        direction: FriendRequestDirection.incoming,
        keeper: _friend,
        createdAt: DateTime.utc(2026, 8, 24),
      ));
    }
  }

  bool _inventoryImported;
  int importCount = 0;
  int removeCount = 0;
  OnlineInventorySnapshot? lastImport;
  String? lastResponse;
  bool signedIn = true;

  static const _favorite = FavoriteDragonSummary(
    id: 'dragon-1',
    name: 'Nimbus',
    lineageId: 'galeear',
    stage: 'wyrmling',
    level: 4,
    might: 34,
    arcana: 18,
    spirit: 57,
    evolutionPath: 'spirit',
    prismatic: false,
    sinister: false,
  );

  static const _friend = KeeperProfile(
    userId: 'friend-user',
    keeperCode: 'DH-1234ABCD',
    displayName: 'Lyra',
    title: 'Skywarden',
    portraitKey: 'storm',
    discoveredDragonCount: 12,
    inventoryImported: true,
    favoriteDragon: _favorite,
  );

  final List<KeeperProfile> friendRows = [];
  final List<FriendshipRequest> requestRows = [];
  final List<KeeperProfile> blockedRows = [];

  KeeperProfile get _profile => KeeperProfile(
        userId: 'my-user',
        keeperCode: 'DH-AABBCCDD',
        displayName: 'Rick',
        title: 'Dragon Keeper',
        portraitKey: 'moon',
        discoveredDragonCount: 1,
        inventoryImported: _inventoryImported,
      );

  @override
  Stream<bool> get authStateChanges => const Stream.empty();
  @override
  String? get currentEmail => 'rick@example.test';
  @override
  bool get isConfigured => true;
  @override
  bool get isSignedIn => signedIn;

  @override
  Future<void> importLegacyInventory(OnlineInventorySnapshot snapshot) async {
    importCount++;
    lastImport = snapshot;
    _inventoryImported = true;
  }

  @override
  Future<void> publishSocialShowcase(OnlineInventorySnapshot snapshot) async {}

  @override
  Future<List<KeeperProfile>> loadBlockedKeepers() async =>
      List.of(blockedRows);
  @override
  Future<List<KeeperProfile>> loadFriends() async => List.of(friendRows);
  @override
  Future<KeeperProfile> loadMyProfile() async => _profile;
  @override
  Future<List<FriendshipRequest>> loadRequests() async => List.of(requestRows);

  @override
  Future<void> removeFriend(String userId) async {
    removeCount++;
    friendRows.removeWhere((friend) => friend.userId == userId);
  }

  @override
  Future<void> signOut() async => signedIn = false;
  @override
  Future<void> blockKeeper(String userId) async => removeFriend(userId);
  @override
  Future<void> respondToRequest(String requestId, String response) async {
    lastResponse = response;
    final index = requestRows.indexWhere((request) => request.id == requestId);
    if (index < 0) throw const SocialException('request_not_found');
    final keeper = requestRows.removeAt(index).keeper;
    if (response == 'accepted') friendRows.add(keeper);
    if (response == 'blocked') blockedRows.add(keeper);
  }

  @override
  Future<void> sendFriendRequest(String keeperCode) async {}
  @override
  Future<void> unblockKeeper(String userId) async {}
  @override
  Future<void> signIn(
          {required String email, required String password}) async =>
      signedIn = true;
  @override
  Future<AccountAuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async =>
      const AccountAuthResult(requiresEmailConfirmation: false);
  @override
  Future<void> updateProfile({
    required String displayName,
    required String title,
    required String portraitKey,
  }) async {}
  @override
  void dispose() {}
}
