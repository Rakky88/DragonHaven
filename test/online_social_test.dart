import 'dart:async';
import 'dart:math';

import 'package:dragon_haven/dragonhaven_app.dart';
import 'package:dragon_haven/models/account_title.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/screens/adventure_hub_screen.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:dragon_haven/widgets/online_account_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('keeper portraits preserve their complete circular artwork',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KeeperPortrait(
            portraitKey: 'portrait_001',
            displayName: 'Keeper',
            radius: 31,
          ),
        ),
      ),
    );

    final portrait = find.byType(KeeperPortrait);
    final image = find.descendant(of: portrait, matching: find.byType(Image));
    expect(tester.getSize(portrait), const Size.square(62));
    expect(tester.widget<Image>(image).fit, BoxFit.contain);
    expect(
      find.descendant(of: portrait, matching: find.byType(ClipOval)),
      findsNothing,
    );
  });

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

  test('new online accounts require email confirmation before sign-in',
      () async {
    final game = HouseholdProvider(random: Random(11));
    final repository = _FakeSocialRepository()..signedIn = false;
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    await online.initialize();

    final result = await online.signUp(
      email: 'keeper@example.test',
      password: 'secret-pass',
    );

    expect(result?.requiresEmailConfirmation, isTrue);
    expect(online.isSignedIn, isFalse);
    expect(online.noticeCode, 'confirm_email');
    online.dispose();
  });

  test('offline name portrait and title are the only online profile source',
      () async {
    final game = HouseholdProvider(random: Random(17))
      ..accountName = 'Offline Lyra'
      ..selectedPortraitId = 'portrait_042'
      ..selectedTitleId = 'title_321';
    final repository = _FakeSocialRepository(inventoryImported: true);
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
      profileSnapshot: () => OnlineProfileSnapshot.fromGame(game),
    );

    await online.initialize();

    expect(repository.updatedDisplayName, 'Offline Lyra');
    expect(repository.updatedPortraitKey, 'portrait_042');
    expect(repository.updatedTitle, 'title_321');
    expect(online.profile?.displayName, 'Offline Lyra');
    expect(online.profile?.portraitKey, 'portrait_042');
    expect(online.profile?.title, 'title_321');
    online.dispose();
  });

  test('group reward is applied locally once before server acknowledgement',
      () async {
    final game = HouseholdProvider(random: Random(19));
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Ember';
    final beforeXp = game.pet.xp;
    final beforeGold = game.chestInventory[ChestTier.gold] ?? 0;
    final participant = GroupAdventureParticipant(
      keeper: const KeeperProfile(
        userId: 'my-user',
        keeperCode: 'DH-AABBCCDD',
        displayName: 'Rick',
        title: 'title_001',
        portraitKey: 'portrait_001',
        discoveredDragonCount: 1,
        inventoryImported: true,
      ),
      dragonId: game.pet.id,
      dragonName: game.pet.displayName,
      lineageId: game.pet.lineageId,
      stage: game.pet.stage.name,
      level: game.pet.level,
      might: 0,
      arcana: 0,
      spirit: 0,
      evolutionPath: game.pet.activeEvolutionPath,
      prismatic: false,
      sinister: false,
      isOwner: true,
    );
    final lobby = GroupAdventureLobby(
      id: 'lobby-1',
      slot: 1,
      adventureId: 'group_1',
      ownerId: 'my-user',
      status: 'completed',
      requiredPlayers: 2,
      focus: 'spirit',
      startedAt: DateTime.utc(2026, 8, 20),
      endsAt: DateTime.utc(2026, 8, 22),
      isCurrentOffer: true,
      isOwner: true,
      isParticipant: true,
      myDragonId: game.pet.id,
      rewardAcknowledged: false,
      participants: [participant],
    );
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..groupRows.add(lobby)
      ..groupReward = GroupAdventureReward(
        lobbyId: lobby.id,
        adventureId: lobby.adventureId,
        dragonId: game.pet.id,
        xp: 25,
        focus: 'spirit',
        statPoints: 7,
        chestTier: 'gold',
        participantCount: 2,
      );
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
      profileSnapshot: () => OnlineProfileSnapshot.fromGame(game),
      synchronizeGroupReservations: game.synchronizeOnlineGroupReservations,
      applyGroupReward: (reward) => game.applyOnlineGroupReward(
        lobbyId: reward.lobbyId,
        adventureId: reward.adventureId,
        dragonId: reward.dragonId,
        xp: reward.xp,
        focus: reward.focus,
        statPoints: reward.statPoints,
        chestTier: reward.chestTier,
        participantCount: reward.participantCount,
      ),
    );
    await online.initialize();
    expect(game.pet.activeAdventureId, 'online-group:lobby-1');

    expect(await online.claimGroupReward(lobby.id), isNotNull);
    expect(game.pet.xp, beforeXp + 25);
    expect(game.pet.trainingFor(TrainingFocus.spirit), 7);
    expect(game.chestInventory[ChestTier.gold], beforeGold + 1);
    expect(game.pet.activeAdventureId, isNull);
    expect(repository.acknowledgeCount, 1);
    expect(game.appliedOnlineGroupRewardIds, contains('lobby-1'));
    online.dispose();
  });

  test('trade reservations block use and completed swaps apply only once',
      () async {
    final game = HouseholdProvider(random: Random(20));
    game.chestInventory[ChestTier.gold] = 1;

    await game.synchronizeOnlineTradeReservations(
      const {},
      const {'gold': 1},
      const {},
    );
    expect(game.tradeableChestCount(ChestTier.gold), 0);
    expect(await game.openChest(ChestTier.gold), isNull);

    final applied = await game.applyOnlineTradeSettlement(
      tradeId: 'trade-1',
      sentKind: 'chest',
      sentKey: 'gold',
      sentData: const {},
      receivedKind: 'relic',
      receivedKey: 'moralPrism',
      receivedData: const {},
    );
    expect(applied, isTrue);
    expect(game.chestCount(ChestTier.gold), 0);
    expect(game.relicCount(MysticRelic.moralPrism), 1);

    expect(
      await game.applyOnlineTradeSettlement(
        tradeId: 'trade-1',
        sentKind: 'chest',
        sentKey: 'gold',
        sentData: const {},
        receivedKind: 'relic',
        receivedKey: 'moralPrism',
        receivedData: const {},
      ),
      isTrue,
    );
    expect(game.relicCount(MysticRelic.moralPrism), 1);
  });

  test('a completed weekly Group Adventure cannot be entered a second time',
      () async {
    final game = HouseholdProvider(random: Random(21));
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..groupStatus = const GroupAdventureStatus(
        slot: 7,
        adventureId: 'group_120',
        alreadyCompleted: true,
      )
      ..createGroupError = 'group_adventure_already_completed';
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );

    await online.initialize();
    expect(online.groupAdventureStatus?.adventureId, 'group_120');
    expect(online.currentGroupOfferConsumed, isTrue);

    final created = await online.createGroupLobby(
      'group_120',
      GroupDragonSubmission.fromPet(game.pet),
    );
    expect(created, isFalse);
    expect(online.errorCode, 'group_adventure_already_completed');

    repository
      ..groupStatus = const GroupAdventureStatus(
        slot: 207,
        adventureId: 'group_120',
        alreadyCompleted: false,
      )
      ..createGroupError = null;
    await online.refresh();
    expect(online.currentGroupOfferConsumed, isFalse,
        reason: 'the same ID may be played again in a later weekly slot');
    expect(
      await online.createGroupLobby(
        'group_120',
        GroupDragonSubmission.fromPet(game.pet),
      ),
      isTrue,
    );
    online.dispose();
  });

  testWidgets(
      'Group Adventure card follows the global server offer and hides after completion',
      (tester) async {
    final game = HouseholdProvider(random: Random(25));
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Ember';
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..groupStatus = const GroupAdventureStatus(
        slot: 12,
        adventureId: 'group_120',
        alreadyCompleted: false,
      );
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
      child: const MaterialApp(
        home: Scaffold(body: AdventureHubScreen()),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    final offer = find.byKey(const Key('group-offer-group_120'));
    await tester.scrollUntilVisible(
      offer,
      350,
      scrollable: find.descendant(
        of: find.byKey(
          const PageStorageKey('available-adventures-scroll'),
        ),
        matching: find.byType(Scrollable),
      ),
    );
    expect(offer, findsOneWidget);

    repository.groupStatus = const GroupAdventureStatus(
      slot: 12,
      adventureId: 'group_120',
      alreadyCompleted: true,
    );
    await online.refresh();
    await tester.pump();
    expect(offer, findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    online.dispose();
  });

  testWidgets(
      'friend profile shows favorite dragon and removal requires confirmation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = HouseholdProvider(random: Random(7))
      ..accountName = 'Rick'
      ..onboardingComplete = true;
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Ember';
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..tradeInventoryRows.add(const TradeInventoryItem(
        item: TradeItem(
          kind: TradeItemKind.chest,
          key: 'gold',
          data: {},
        ),
        available: 2,
      ));
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
    expect(find.textContaining('12 dragons discovered'), findsOneWidget);
    final friendPortrait = tester.widget<KeeperPortrait>(find.descendant(
      of: find.byKey(const Key('friend-friend-user')),
      matching: find.byType(KeeperPortrait),
    ));
    expect(friendPortrait.portraitKey, 'portrait_042');
    final friendTitle = accountTitleById('title_321')!.label('en');
    expect(find.text(friendTitle), findsOneWidget);

    await tester.tap(find.byKey(const Key('friend-friend-user')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(friendTitle), findsWidgets);
    expect(find.text('Nimbus'), findsOneWidget);
    expect(find.textContaining('Level 4'), findsOneWidget);
    expect(find.text('Might'), findsOneWidget);
    expect(find.text('Arcana'), findsOneWidget);
    expect(find.text('Spirit'), findsOneWidget);
    expect(find.byKey(const Key('start-trade-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('start-trade-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byKey(const Key('trade-inventory-list')), findsOneWidget);
    await tester.tap(find.byKey(const Key('trade-item-chest-gold')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Send trade proposal?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-create-trade')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(repository.createTradeCount, 1);

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
  String? updatedDisplayName;
  String? updatedTitle;
  String? updatedPortraitKey;
  int acknowledgeCount = 0;
  int createTradeCount = 0;
  GroupAdventureReward? groupReward;
  String? createGroupError;
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
    title: 'title_321',
    portraitKey: 'portrait_042',
    discoveredDragonCount: 12,
    inventoryImported: true,
    favoriteDragon: _favorite,
  );

  final List<KeeperProfile> friendRows = [];
  final List<FriendshipRequest> requestRows = [];
  final List<KeeperProfile> blockedRows = [];
  final List<GroupAdventureLobby> groupRows = [];
  final List<TradeOffer> tradeRows = [];
  final List<TradeInventoryItem> tradeInventoryRows = [];
  GroupAdventureStatus groupStatus = const GroupAdventureStatus(
    slot: 1,
    adventureId: 'group_1',
    alreadyCompleted: false,
  );

  KeeperProfile get _profile => KeeperProfile(
        userId: 'my-user',
        keeperCode: 'DH-AABBCCDD',
        displayName: updatedDisplayName ?? 'Rick',
        title: updatedTitle ?? 'title_001',
        portraitKey: updatedPortraitKey ?? 'portrait_001',
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
  bool get isEmailVerified => signedIn;

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
      const AccountAuthResult(requiresEmailConfirmation: true);
  @override
  Future<void> updateProfile({
    required String displayName,
    required String title,
    required String portraitKey,
  }) async {
    updatedDisplayName = displayName;
    updatedTitle = title;
    updatedPortraitKey = portraitKey;
  }

  @override
  Future<List<GroupAdventureLobby>> loadGroupAdventures() async =>
      List.of(groupRows);
  @override
  Future<GroupAdventureStatus> loadGroupAdventureStatus() async => groupStatus;
  @override
  Future<void> createGroupLobby(
      String adventureId, GroupDragonSubmission dragon) async {
    if (createGroupError case final code?) throw SocialException(code);
  }

  @override
  Future<void> joinGroupLobby(
      String lobbyId, GroupDragonSubmission dragon) async {}
  @override
  Future<void> leaveGroupLobby(String lobbyId) async {}
  @override
  Future<void> removeGroupParticipant(String lobbyId, String userId) async {}
  @override
  Future<GroupAdventureReward?> claimGroupReward(String lobbyId) async =>
      groupReward;
  @override
  Future<void> acknowledgeGroupReward(String lobbyId) async {
    acknowledgeCount++;
    groupRows.removeWhere((lobby) => lobby.id == lobbyId);
    groupReward = null;
  }

  @override
  Future<void> synchronizeTradeInventory(
      OnlineInventorySnapshot snapshot) async {}
  @override
  Future<List<TradeInventoryItem>> loadTradeInventory() async =>
      List.of(tradeInventoryRows);
  @override
  Future<List<TradeOffer>> loadTrades() async => List.of(tradeRows);
  @override
  Future<void> createTrade(String friendId, TradeItem item) async {
    createTradeCount++;
  }

  @override
  Future<void> respondToTrade(String tradeId, TradeItem item) async {}
  @override
  Future<void> completeTrade(String tradeId) async {}
  @override
  Future<void> cancelTrade(String tradeId) async {}
  @override
  Future<void> rejectTrade(String tradeId) async {}
  @override
  Future<void> acknowledgeTrade(String tradeId) async {}

  @override
  void dispose() {}
}
