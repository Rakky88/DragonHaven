import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dragon_haven/dragonhaven_app.dart';
import 'package:dragon_haven/models/account_title.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/dragon_emote.dart';
import 'package:dragon_haven/models/game_presentation.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/profile_portrait.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/models/supporter_pack.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/screens/adventure_hub_screen.dart';
import 'package:dragon_haven/screens/conclave_screen.dart';
import 'package:dragon_haven/screens/friend_messages_screen.dart';
import 'package:dragon_haven/services/diagnostic_reporter.dart';
import 'package:dragon_haven/services/automatic_cloud_backup.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:dragon_haven/widgets/online_account_access.dart';
import 'package:dragon_haven/widgets/profile_portrait_sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final images = find.descendant(of: portrait, matching: find.byType(Image));
    expect(tester.getSize(portrait), const Size.square(62));
    expect(images, findsOneWidget);
    expect(
      tester.widgetList<Image>(images).map((image) => image.fit),
      everyElement(BoxFit.cover),
    );
    expect(
      find.descendant(of: portrait, matching: find.byType(ClipOval)),
      findsOneWidget,
    );
  });

  testWidgets('Founding Supporter portrait matches regular portrait scale',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              ProfilePortraitSprite(
                key: const Key('regular-portrait'),
                portrait: profilePortraitCatalog.first,
              ),
              const ProfilePortraitSprite(
                key: Key('supporter-portrait'),
                portrait: supporterProfilePortrait,
              ),
            ],
          ),
        ),
      ),
    );

    double scaleFor(Key key) {
      final transform = tester.widget<Transform>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(Transform),
        ),
      );
      return transform.transform.storage.first;
    }

    expect(scaleFor(const Key('regular-portrait')),
        ProfilePortraitSprite.portraitFillScale);
    expect(scaleFor(const Key('supporter-portrait')),
        ProfilePortraitSprite.portraitFillScale);
  });

  testWidgets('friend portraits use the correct rarity frame and glow',
      (tester) async {
    const expectedColors = {
      PortraitRarity.common: 0xFFD9B84E,
      PortraitRarity.rare: 0xFF3F8FE5,
      PortraitRarity.veryRare: 0xFF8157D9,
      PortraitRarity.legendary: 0xFFD39B21,
      PortraitRarity.infernal: 0xFFD94B3D,
      PortraitRarity.mythical: 0xFF2A9CB8,
    };

    for (final entry in expectedColors.entries) {
      expect(entry.key.colorValue, entry.value);
      expect(entry.key.hasGlow, entry.key != PortraitRarity.common);
    }

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KeeperPortrait(
            portraitKey: 'portrait_100',
            displayName: 'Mythical Keeper',
            radius: 31,
          ),
        ),
      ),
    );

    final decorated = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(KeeperPortrait),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = decorated.decoration as BoxDecoration;
    expect(decoration.border!.top.color, const Color(0xFF2A9CB8));
    expect(decoration.boxShadow, hasLength(1));
    final glowColor = decoration.boxShadow!.single.color;
    expect(glowColor.r, const Color(0xFF2A9CB8).r);
    expect(glowColor.g, const Color(0xFF2A9CB8).g);
    expect(glowColor.b, const Color(0xFF2A9CB8).b);
    expect(glowColor.a, closeTo(.58, .0001));
  });

  testWidgets('vanity frames grow and badges render without a holder',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              KeeperPortrait(
                key: Key('unframed-keeper'),
                portraitKey: 'portrait_042',
                displayName: 'Unframed Keeper',
                radius: 31,
              ),
              KeeperPortrait(
                key: Key('framed-keeper'),
                portraitKey: 'portrait_042',
                displayName: 'Framed Keeper',
                frameKey: 'frame_supporter_founder',
                badgeKey: 'badge_supporter_founder',
                radius: 31,
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      find.byKey(
        const Key('keeper-portrait-frame-frame_supporter_founder'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('unframed-keeper'))),
      const Size.square(62),
    );
    expect(
      tester.getSize(find.byKey(const Key('framed-keeper'))),
      const Size.square(62 / KeeperPortrait.framePortraitRatio),
    );
    final portraitSprites = tester
        .widgetList<ProfilePortraitSprite>(find.byType(ProfilePortraitSprite))
        .toList();
    expect(portraitSprites, hasLength(2));
    expect(portraitSprites[0].size, closeTo(57.6, .01));
    expect(portraitSprites[1].size, portraitSprites[0].size);
    final badgeAnchor = tester.widget<SizedBox>(find.byKey(
      const Key(
        'keeper-portrait-badge-anchor-badge_supporter_founder',
      ),
    ));
    expect(badgeAnchor.child, isA<Image>());
    expect(
      tester.getSize(find.byKey(
        const Key(
          'keeper-portrait-badge-anchor-badge_supporter_founder',
        ),
      )),
      const Size.square(31 * .82),
    );
    final framedBounds = tester.getRect(
      find.byKey(const Key('framed-keeper')),
    );
    final framedPortraitBounds = tester.getRect(
      find.descendant(
        of: find.byKey(const Key('framed-keeper')),
        matching: find.byType(ProfilePortraitSprite),
      ),
    );
    final badgeBounds = tester.getRect(find.byKey(
      const Key(
        'keeper-portrait-badge-anchor-badge_supporter_founder',
      ),
    ));
    expect(
      badgeBounds.left - framedBounds.left,
      closeTo(31 * .18, .01),
    );
    expect(
      framedBounds.bottom - badgeBounds.bottom,
      closeTo(31 * .18, .01),
    );
    expect(badgeBounds.overlaps(framedPortraitBounds), isTrue);
    expect(
      badgeBounds.left,
      lessThan(framedPortraitBounds.left),
      reason: 'part of the badge must cover the selected frame',
    );
    expect(
      badgeBounds.right,
      greaterThan(framedPortraitBounds.left),
      reason: 'part of the badge must cover the portrait',
    );
  });

  testWidgets('portrait and vanity frame stay round under tight layout',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 74,
              height: 58,
              child: KeeperPortrait(
                key: Key('tight-framed-keeper'),
                portraitKey: 'portrait_042',
                displayName: 'Tight Keeper',
                frameKey: 'frame_supporter_founder',
                badgeKey: 'badge_supporter_founder',
                radius: 31,
              ),
            ),
          ),
        ),
      ),
    );

    final portraitBounds = tester.getRect(find.descendant(
      of: find.byKey(const Key('tight-framed-keeper')),
      matching: find.byType(ProfilePortraitSprite),
    ));
    final frameBounds = tester.getRect(find.byKey(
      const Key('keeper-portrait-frame-frame_supporter_founder'),
    ));
    expect(
      (portraitBounds.width - portraitBounds.height).abs(),
      lessThan(.01),
    );
    expect(
      (frameBounds.width - frameBounds.height).abs(),
      lessThan(.01),
    );
  });

  test('social discovery summaries count forms rather than families', () {
    final game = HouseholdProvider(random: Random(30))
      ..discoveredForms = {
        'mossprout:hatchling',
        'mossprout:wyrmling',
        'stormwing:hatchling',
      };
    final snapshot = OnlineInventorySnapshot.fromGame(game);

    expect(snapshot.discoveredLineageIds, hasLength(2));
    expect(snapshot.toShowcaseJson()['discovered_dragon_count'], 3);
    const serverProfile = KeeperProfile(
      userId: 'friend',
      keeperCode: 'DH-FORMS001',
      displayName: 'Forms',
      title: 'title_001',
      portraitKey: 'portrait_001',
      discoveredDragonCount: 1,
      inventoryImported: true,
      discoveredForms: [
        'mossprout:hatchling',
        'mossprout:wyrmling',
      ],
    );
    expect(serverProfile.discoveredDragonFormCount, 2);
  });

  test('server-authored friend and trade events become notifications once',
      () async {
    const channel = MethodChannel('nl.dragonhaven.app/notifications');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final game = HouseholdProvider(random: Random(31));
    final now = DateTime.utc(2026, 8, 26);
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..notificationRows.addAll([
        SocialNotification(
          id: 'notice-request',
          kind: 'friend_request',
          entityId: 'friendship-1',
          actorDisplayName: 'Lyra',
          createdAt: now,
        ),
        SocialNotification(
          id: 'notice-accepted',
          kind: 'friend_accepted',
          entityId: 'friendship-2',
          actorDisplayName: 'Miriam',
          createdAt: now,
        ),
        SocialNotification(
          id: 'notice-trade',
          kind: 'trade_request',
          entityId: 'trade-1',
          actorDisplayName: 'Onosick',
          createdAt: now,
        ),
        SocialNotification(
          id: 'notice-return',
          kind: 'trade_return',
          entityId: 'trade-2',
          actorDisplayName: 'Lyra',
          createdAt: now,
        ),
        SocialNotification(
          id: 'notice-complete',
          kind: 'trade_completed',
          entityId: 'trade-3',
          actorDisplayName: 'Miriam',
          createdAt: now,
        ),
        SocialNotification(
          id: 'notice-message',
          kind: 'friend_message',
          entityId: 'message-1',
          actorDisplayName: 'Lyra',
          createdAt: now,
        ),
      ]);
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );

    await online.initialize();

    expect(calls, hasLength(6));
    expect(
      calls.map((call) => (call.arguments as Map)['kind']),
      containsAll([
        'friend_request',
        'friend_accepted',
        'friend_message',
        'trade',
      ]),
    );
    expect(repository.acknowledgedNotificationIds, hasLength(6));
    expect(repository.notificationRows, isEmpty);
    online.dispose();
  });

  test('private message polling retries before acknowledging failed delivery',
      () async {
    const channel = MethodChannel('nl.dragonhaven.app/notifications');
    var allowDelivery = false;
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'showNow' ? allowDelivery : true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final game = HouseholdProvider(random: Random(311));
    final repository = _FakeSocialRepository(inventoryImported: true);
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    await online.initialize();
    calls.clear();
    repository.notificationRows.add(SocialNotification(
      id: 'notice-message-retry',
      kind: 'friend_message',
      entityId: 'message-retry',
      actorDisplayName: 'Lyra',
      createdAt: DateTime.utc(2026, 9, 1),
    ));

    await online.pollSocialNotifications();
    expect(calls.single.method, 'showNow');
    expect(repository.acknowledgedNotificationIds, isEmpty);
    expect(repository.notificationRows, hasLength(1));

    allowDelivery = true;
    calls.clear();
    await online.pollSocialNotifications();
    expect(calls.single.method, 'showNow');
    expect(repository.acknowledgedNotificationIds, ['notice-message-retry']);
    expect(repository.notificationRows, isEmpty);
    online.dispose();
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
    expect(repository.lastImport?.toJson()['import_version'], 1);
    expect(
      repository.lastImport?.toJson()['source_schema_version'],
      HouseholdProvider.saveSchemaVersion,
    );
    expect(online.profile?.inventoryImported, isTrue);
    online.dispose();
  });

  test('automatic online refreshes are coalesced and rate limited', () async {
    final game = HouseholdProvider(random: Random(309));
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..ensureAccountGate = Completer<void>();
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );

    final first = online.refreshIfStale(
      minimumInterval: const Duration(hours: 1),
    );
    while (repository.ensureAccountCount == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    final duplicate = online.refreshIfStale(
      minimumInterval: const Duration(hours: 1),
    );
    expect(identical(first, duplicate), isTrue);
    expect(repository.ensureAccountCount, 1);

    repository.ensureAccountGate!.complete();
    expect(await first, isTrue);
    expect(await duplicate, isTrue);
    final snapshotCount = repository.snapshotLoadCount;

    expect(
      await online.refreshIfStale(
        minimumInterval: const Duration(hours: 1),
      ),
      isTrue,
    );
    expect(repository.snapshotLoadCount, snapshotCount,
        reason: 'a recent automatic refresh must not hit the server again');

    expect(await online.refresh(), isTrue,
        reason: 'manual refresh remains immediate');
    expect(repository.snapshotLoadCount, greaterThan(snapshotCount));
    online.dispose();
  });

  test('a refresh requested by a busy-state listener reuses the same request',
      () async {
    final game = HouseholdProvider(random: Random(310));
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..ensureAccountGate = Completer<void>();
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    Future<bool>? reentrantRefresh;
    online.addListener(() {
      if (online.busy && reentrantRefresh == null) {
        reentrantRefresh = online.refresh();
      }
    });

    final first = online.refresh();
    expect(reentrantRefresh, isNotNull);
    expect(identical(first, reentrantRefresh), isTrue);
    expect(repository.ensureAccountCount, 1);

    repository.ensureAccountGate!.complete();
    expect(await first, isTrue);
    expect(await reentrantRefresh, isTrue);
    expect(repository.ensureAccountCount, 1);
    online.dispose();
  });

  test('initial online refresh recovers from transient server failures',
      () async {
    final game = HouseholdProvider(random: Random(4));
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..transientSnapshotFailures = 2;
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );

    await online.initialize();

    expect(repository.snapshotLoadCount, 4,
        reason: 'three attempts plus the post-sync authoritative reload');
    expect(online.profile, isNotNull);
    expect(online.errorCode, isNull);
    online.dispose();
  });

  test('maintenance failure cannot hide a valid friends snapshot', () async {
    final game = HouseholdProvider(random: Random(407));
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..tradeInventorySyncError = 'invalid_inventory'
      ..showcasePublishError = 'invalid_profile'
      ..notificationAcknowledgeError = 'temporary_server_failure'
      ..notificationRows.add(SocialNotification(
        id: 'notice-qnosick-regression',
        kind: 'friend_request',
        entityId: 'request-qnosick-regression',
        actorDisplayName: 'Keeper',
        createdAt: DateTime.utc(2026, 8, 31),
      ));
    final diagnostics = BufferedDiagnosticReporter();
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
      diagnostics: diagnostics,
    );

    await online.initialize();

    expect(online.errorCode, isNull);
    expect(online.friends, hasLength(1));
    expect(online.profile?.keeperCode, 'DH-AABBCCDD');
    expect(
      diagnostics.recentEvents
          .where((event) => event.outcome == DiagnosticOutcome.failure)
          .map((event) => event.operation),
      containsAll(<String>[
        'social.refresh.trade_inventory',
        'social.refresh.showcase',
        'social.refresh.notifications',
      ]),
    );
    expect(diagnostics.recentEvents.last.operation, 'social.refresh');
    expect(diagnostics.recentEvents.last.outcome, DiagnosticOutcome.success);
    online.dispose();
  });

  test('an expired session fails once and can recover after signing in again',
      () async {
    final game = HouseholdProvider(random: Random(405));
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..signedIn = false;
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    await online.initialize();
    repository
      ..signedIn = true
      ..ensureAccountError = 'online_session_expired';

    expect(await online.refresh(), isFalse);
    expect(repository.ensureAccountCount, 1,
        reason: 'an expired credential must not be retried as a server outage');
    expect(online.errorCode, 'online_session_expired');

    repository.ensureAccountError = null;
    expect(await online.refresh(), isTrue);
    expect(online.profile, isNotNull);
    expect(online.errorCode, isNull);
    online.dispose();
  });

  test('app initialization does not wait for a slow online refresh', () async {
    final game = HouseholdProvider(random: Random(401));
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..ensureAccountGate = Completer<void>();
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );

    await online.initialize(waitForFirstRefresh: false);

    expect(online.busy, isTrue);
    repository.ensureAccountGate!.complete();
    while (online.busy) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(online.profile, isNotNull);
    online.dispose();
  });

  test('slow online actions time out without blocking the local game',
      () async {
    final game = HouseholdProvider(random: Random(402));
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..signedIn = false;
    final diagnostics = BufferedDiagnosticReporter();
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
      diagnostics: diagnostics,
      operationTimeout: const Duration(milliseconds: 10),
    );
    await online.initialize();
    repository
      ..signedIn = true
      ..ensureAccountGate = Completer<void>();

    expect(await online.refresh(), isFalse);
    expect(online.busy, isFalse);
    expect(online.errorCode, 'online_timeout');
    expect(online.supportCode, hasLength(8));
    expect(diagnostics.recentEvents, hasLength(1));
    expect(diagnostics.recentEvents.single.operation, 'social.refresh');
    expect(diagnostics.recentEvents.single.errorCode, 'online_timeout');
    expect(
      diagnostics.recentEvents.single.supportCode,
      online.supportCode,
    );

    expect(await online.refresh(), isFalse,
        reason: 'the timed-out source request is still running');
    expect(repository.ensureAccountCount, 1,
        reason: 'a retry must not overlap the timed-out request');
    repository.ensureAccountGate!.complete();
    while (repository.snapshotLoadCount == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(await online.refresh(), isTrue,
        reason: 'online actions recover after the source request settles');
    expect(online.errorCode, isNull);
    online.dispose();
  });

  test('rapid duplicate trade actions create only one server request',
      () async {
    final game = HouseholdProvider(random: Random(406))
      ..chestInventory[ChestTier.gold] = 1;
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..createTradeGate = Completer<void>();
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    await online.initialize();

    final first = online.createTrade(
      'friend-user',
      TradeItem.chest(ChestTier.gold),
    );
    while (repository.createTradeCount == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(
      await online.createTrade(
        'friend-user',
        TradeItem.chest(ChestTier.gold),
      ),
      isFalse,
    );
    expect(repository.createTradeCount, 1);

    repository.createTradeGate!.complete();
    expect(await first, isTrue);
    expect(repository.createTradeCount, 1);
    online.dispose();
  });

  test('unexpected online errors are redacted from diagnostics and UI',
      () async {
    final game = HouseholdProvider(random: Random(403));
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..signedIn = false;
    final diagnostics = BufferedDiagnosticReporter();
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
      diagnostics: diagnostics,
    );
    await online.initialize();
    repository
      ..signedIn = true
      ..ensureAccountGate = Completer<void>();

    final refresh = online.refresh();
    repository.ensureAccountGate!.completeError(
      StateError('token=private-secret keeper@example.test'),
    );

    expect(await refresh, isFalse);
    expect(online.errorCode, 'online_unexpected_error');
    expect(online.supportCode, hasLength(8));
    final encoded = jsonEncode(
      diagnostics.recentEvents.map((event) => event.toSafeJson()).toList(),
    );
    expect(encoded, isNot(contains('private-secret')));
    expect(encoded, isNot(contains('keeper@example.test')));
    expect(encoded, contains('online_unexpected_error'));
    online.dispose();
  });

  test('support report contains technical IDs but no e-mail or game state',
      () async {
    final game = HouseholdProvider(random: Random(404));
    await game.updateAccountName('Private Local Name');
    final diagnostics = BufferedDiagnosticReporter();
    final online = OnlineAccountProvider(
      repository: _FakeSocialRepository(inventoryImported: true),
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
      diagnostics: diagnostics,
    );
    await online.initialize();

    final report = online.buildSupportDiagnosticReport(appVersion: 'v-test');
    final decoded = jsonDecode(report) as Map<String, dynamic>;
    expect(decoded['keeperId'], 'DH-AABBCCDD');
    expect(decoded['userId'], 'my-user');
    expect(decoded['appVersion'], 'v-test');
    expect(report, isNot(contains('rick@example.test')));
    expect(report, isNot(contains('Private Local Name')));
    expect(report, isNot(contains('accountName')));
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

  test('confirmation email can be resent without a signed-in session',
      () async {
    final game = HouseholdProvider(random: Random(12));
    final repository = _FakeSocialRepository()..signedIn = false;
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    await online.initialize();

    expect(
      await online.resendSignupConfirmation('Visnet@Example.Test '),
      isTrue,
    );
    expect(repository.resentConfirmationEmail, 'Visnet@Example.Test ');
    expect(online.noticeCode, 'confirmation_resent');
    online.dispose();
  });

  test('offline vanity choices are the only online profile source', () async {
    final game = HouseholdProvider(random: Random(17))
      ..accountName = 'Offline Lyra'
      ..selectedPortraitId = 'portrait_042'
      ..selectedTitleId = 'title_321'
      ..selectedFrameId = supporterFrame.id
      ..selectedBadgeId = supporterBadge.id;
    final repository = _FakeSocialRepository(inventoryImported: true);
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
      profileSnapshot: () => OnlineProfileSnapshot.fromGame(game),
    );

    await online.initialize();

    expect(repository.ensureAccountCount, 1);
    expect(repository.updatedDisplayName, 'Offline Lyra');
    expect(repository.updatedPortraitKey, 'portrait_042');
    expect(repository.updatedTitle, 'title_321');
    expect(repository.updatedFrameKey, supporterFrame.id);
    expect(repository.updatedBadgeKey, supporterBadge.id);
    expect(online.profile?.displayName, 'Offline Lyra');
    expect(online.profile?.portraitKey, 'portrait_042');
    expect(online.profile?.title, 'title_321');
    expect(online.profile?.frameKey, supporterFrame.id);
    expect(online.profile?.badgeKey, supporterBadge.id);
    online.dispose();
  });

  test('an explicit empty frame and badge selection syncs online as empty',
      () async {
    final game = HouseholdProvider(
      random: Random(171),
      persistenceEnabled: false,
    );
    await game.applyVerifiedSupporterPack('online-empty-vanity');
    await game.selectKeeperFrame(null);
    await game.selectKeeperBadge(null);
    final repository = _FakeSocialRepository(inventoryImported: true);
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
      profileSnapshot: () => OnlineProfileSnapshot.fromGame(game),
    );

    await online.initialize();

    expect(repository.updateProfileCount, 1);
    expect(repository.updatedFrameKey, isNull);
    expect(repository.updatedBadgeKey, isNull);
    expect(online.profile?.frameKey, isNull);
    expect(online.profile?.badgeKey, isNull);
    online.dispose();
    game.dispose();
  });

  test('cosmetic chests never enter trade payloads or trade commands',
      () async {
    final game = HouseholdProvider(random: Random(18))
      ..chestInventory[ChestTier.gold] = 2
      ..chestInventory[ChestTier.portrait] = 3
      ..chestInventory[ChestTier.title] = 4;
    final tradeChests = OnlineInventorySnapshot.fromGame(game)
        .toTradeJson()['chests'] as Map<String, dynamic>;
    expect(tradeChests['gold'], 2);
    expect(tradeChests, isNot(contains(ChestTier.portrait.name)));
    expect(tradeChests, isNot(contains(ChestTier.title.name)));

    final repository = _FakeSocialRepository(inventoryImported: true);
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    await online.initialize();

    expect(
      await online.createTrade(
        'friend-user',
        TradeItem.chest(ChestTier.portrait),
      ),
      isFalse,
    );
    expect(online.errorCode, 'trade_item_invalid');
    expect(repository.createTradeCount, 0);
    online.dispose();
  });

  test('shop-bought Relics never enter the authoritative trade inventory',
      () async {
    final game = HouseholdProvider(random: Random(181));
    game.pet.gems = 500;
    await game.purchaseRelic(MysticRelic.soulMirror);
    final relics = OnlineInventorySnapshot.fromGame(game)
        .toTradeJson()['relics'] as Map<String, dynamic>;

    expect(game.relicCount(MysticRelic.soulMirror), 1);
    expect(game.untradeableRelicCount(MysticRelic.soulMirror), 1);
    expect(relics[MysticRelic.soulMirror.name], 0);

    game.relicInventory[MysticRelic.soulMirror] = 2;
    final withGameplayDrop = OnlineInventorySnapshot.fromGame(game)
        .toTradeJson()['relics'] as Map<String, dynamic>;
    expect(withGameplayDrop[MysticRelic.soulMirror.name], 1);
  });

  test('Chronoshard trade data and percentage-specific reservations persist',
      () async {
    final game = HouseholdProvider(random: Random(182))
      ..relicInventory[MysticRelic.chronoshard] = 2
      ..chronoshardReductions = [37, 64];
    final snapshot = OnlineInventorySnapshot.fromGame(game).toTradeJson();
    expect(
      (snapshot['relic_variants'] as Map)[MysticRelic.chronoshard.name],
      [37, 64],
    );
    final item = TradeItem.relic(
      MysticRelic.chronoshard,
      data: const {'reductionPercent': 37},
    );
    expect(item.toRequestJson()['data'], const {'reductionPercent': 37});

    await game.synchronizeOnlineTradeReservations(
      const {},
      const {},
      const {'chronoshard:37': 1},
    );
    expect(game.isChronoshardReserved(37), isTrue);
    expect(game.isChronoshardReserved(64), isFalse);
    expect(await game.useChronoshard(37), ChronoshardUseResult.notOwned);

    final applied = await game.applyOnlineTradeSettlement(
      tradeId: 'chrono-trade',
      sentKind: 'relic',
      sentKey: 'chronoshard',
      sentData: const {'reductionPercent': 37},
      receivedKind: 'relic',
      receivedKey: 'chronoshard',
      receivedData: const {'reductionPercent': 81},
    );
    expect(applied, isTrue);
    expect(game.chronoshardReductions, [64, 81]);
  });

  test('Twinstar Brooch is rejected by every client trade boundary', () async {
    final item = TradeItem.relic(MysticRelic.twinstarBrooch);
    expect(item.isTradeable, isFalse);

    final game = HouseholdProvider(random: Random(183))
      ..relicInventory[MysticRelic.twinstarBrooch] = 1;
    expect(
      await game.applyOnlineTradeSettlement(
        tradeId: 'invalid-twinstar-trade',
        sentKind: 'relic',
        sentKey: 'twinstarBrooch',
        sentData: const {},
        receivedKind: 'relic',
        receivedKey: 'moralPrism',
        receivedData: const {},
      ),
      isFalse,
    );
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
      ..acknowledgeGroupFailures = 1
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

    expect(await online.claimGroupReward(lobby.id), isNull,
        reason: 'the first server acknowledgement is intentionally failed');
    expect(game.pet.xp, beforeXp + 25);
    expect(game.pet.trainingFor(TrainingFocus.spirit), 7);
    expect(game.chestInventory[ChestTier.gold], beforeGold + 1);
    expect(game.pet.activeAdventureId, isNull);
    expect(repository.acknowledgeCount, 1);
    expect(game.appliedOnlineGroupRewardIds, contains('lobby-1'));

    expect(await online.claimGroupReward(lobby.id), isNotNull);
    expect(game.pet.xp, beforeXp + 25);
    expect(game.pet.trainingFor(TrainingFocus.spirit), 7);
    expect(game.chestInventory[ChestTier.gold], beforeGold + 1,
        reason: 'a replay must not grant the chest twice');
    expect(repository.acknowledgeCount, 2);
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
    expect(game.nextPresentation?.type, GamePresentationType.trade);
    expect(game.nextPresentation?.payload['receivedKey'], 'moralPrism');

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
    expect(
      game.pendingPresentations
          .where((item) => item.type == GamePresentationType.trade),
      hasLength(1),
    );
  });

  test('a half-acknowledged trade replays safely after an app restart',
      () async {
    final game = HouseholdProvider(random: Random(407))
      ..chestInventory[ChestTier.gold] = 1;
    final now = DateTime.utc(2026, 8, 28, 12);
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..tradeRows.add(_testTrade(
        status: 'completed',
        updatedAt: now,
        myAcknowledged: false,
      ))
      ..acknowledgeTradeFailures = 3;
    var online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
      applyTradeSettlement: (settlement) => game.applyOnlineTradeSettlement(
        tradeId: settlement.tradeId,
        sentKind: settlement.sent.kind.name,
        sentKey: settlement.sent.key,
        sentData: settlement.sent.data,
        receivedKind: settlement.received.kind.name,
        receivedKey: settlement.received.key,
        receivedData: settlement.received.data,
      ),
    );

    await online.initialize();
    expect(online.errorCode, 'temporary_server_failure');
    expect(game.chestCount(ChestTier.gold), 0);
    expect(game.relicCount(MysticRelic.moralPrism), 1);
    expect(game.appliedOnlineTradeIds, hasLength(1));
    expect(repository.acknowledgeTradeCount, 3);
    online.dispose();

    final restored = await HouseholdProvider.loadFromStorage();
    expect(restored.chestCount(ChestTier.gold), 0);
    expect(restored.relicCount(MysticRelic.moralPrism), 1);
    expect(
      restored.appliedOnlineTradeIds,
      contains(repository.tradeRows.single.id),
    );

    repository.acknowledgeTradeFailures = 0;
    online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(restored),
      applyTradeSettlement: (settlement) => restored.applyOnlineTradeSettlement(
        tradeId: settlement.tradeId,
        sentKind: settlement.sent.kind.name,
        sentKey: settlement.sent.key,
        sentData: settlement.sent.data,
        receivedKind: settlement.received.kind.name,
        receivedKey: settlement.received.key,
        receivedData: settlement.received.data,
      ),
    );
    await online.initialize();

    expect(online.errorCode, isNull);
    expect(restored.chestCount(ChestTier.gold), 0);
    expect(restored.relicCount(MysticRelic.moralPrism), 1,
        reason: 'the received Relic must not be granted twice');
    expect(restored.appliedOnlineTradeIds, hasLength(1));
    expect(repository.acknowledgeTradeCount, 4);
    expect(repository.tradeRows, isEmpty);
    online.dispose();
  });

  test('daily successful trade count ignores old and unfinished trades',
      () async {
    final now = DateTime.now();
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..tradeRows.addAll([
        _testTrade(status: 'completed', updatedAt: now),
        _testTrade(status: 'completed', updatedAt: now),
        _testTrade(
          status: 'completed',
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        _testTrade(status: 'awaiting_recipient', updatedAt: now),
      ]);
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(
        HouseholdProvider(random: Random(29)),
      ),
    );

    await online.initialize();

    expect(online.completedTradesOn(now), 2);
    expect(OnlineAccountProvider.maxSuccessfulTradesPerDay, 3);
    online.dispose();
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

  testWidgets('Trial rankings switch between world, friends and Trial types',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..trialRankingRows['world:cavernFlight'] = const [
        TrialRankingEntry(
          position: 1,
          entryKey: 'world-1',
          displayName: 'Sky Keeper',
          title: 'title_001',
          portraitKey: 'portrait_001',
          score: 2800,
          isCurrentUser: false,
        ),
      ]
      ..trialRankingRows['friends:cavernFlight'] = const [
        TrialRankingEntry(
          position: 1,
          entryKey: 'friend-1',
          displayName: 'Lyra',
          title: 'title_321',
          portraitKey: 'portrait_042',
          score: 211,
          isCurrentUser: false,
        ),
      ]
      ..trialRankingRows['friends:ruinBreaker'] = const [
        TrialRankingEntry(
          position: 1,
          entryKey: 'friend-might-1',
          displayName: 'Lyra',
          title: 'title_321',
          portraitKey: 'portrait_042',
          score: 1200,
          isCurrentUser: false,
        ),
      ];
    final game = HouseholdProvider(random: Random(315));
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
        home: Scaffold(body: AdventureHubScreen(initialTab: 1)),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('open-trial-rankings')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trial-rankings-sheet')), findsOneWidget);
    expect(find.text('Sky Keeper'), findsOneWidget);
    expect(find.text('2800'), findsOneWidget);
    expect(
      repository.trialRankingRequests,
      contains(('cavernFlight', TrialRankingScope.world)),
    );

    await tester.tap(find.descendant(
      of: find.byKey(const Key('trial-ranking-scope-selector')),
      matching: find.text('Friends'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Lyra'), findsOneWidget);
    expect(find.text('211'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('trial-ranking-kind-ruinBreaker')),
    );
    await tester.pumpAndSettle();
    expect(find.text('1200'), findsOneWidget);
    expect(
      repository.trialRankingRequests,
      contains(('ruinBreaker', TrialRankingScope.friends)),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    online.dispose();
  });

  testWidgets('Conclave Keepers opens rankings for every member',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..conclaveSnapshot = ConclaveSnapshot(
        conclave: const ConclaveSummary(
          id: 'ranked-conclave',
          name: 'Ranked Aerie',
          emblemKey: 'conclave_emblem_01',
          description: '',
          language: 'en',
          visibility: ConclaveVisibility.public,
          memberLimit: 20,
          memberCount: 2,
          level: 1,
          xp: 0,
          aerieStage: 1,
        ),
        myRole: ConclaveRole.keeper,
        contributedToday: false,
        members: const [],
        messages: const [],
        chronicle: const [],
        joinRequests: const [],
      )
      ..trialRankingRows['conclave:cavernFlight'] = const [
        TrialRankingEntry(
          position: 1,
          entryKey: 'conclave-1',
          displayName: 'Aerie Ace',
          title: 'title_001',
          portraitKey: 'portrait_001',
          score: 1490,
          isCurrentUser: false,
        ),
      ];
    final game = HouseholdProvider(random: Random(316));
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
      child: const MaterialApp(home: ConclaveScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Keepers'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('open-conclave-trial-rankings')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trial-rankings-sheet')), findsOneWidget);
    expect(find.text('Aerie Ace'), findsOneWidget);
    expect(find.text('1490'), findsOneWidget);
    expect(
      repository.trialRankingRequests,
      contains(('cavernFlight', TrialRankingScope.conclave)),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    online.dispose();
  });

  testWidgets('Conclave chat shows local send times for every message type',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final emote = dragonEmotesForSource(DragonEmoteSource.chest).first;
    final sentAt = <String, DateTime>{
      'text-time': DateTime(2026, 9, 2, 9, 5),
      'emote-time': DateTime(2026, 9, 2, 10, 6),
      'achievement-time': DateTime(2026, 9, 2, 11, 7),
    };
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..conclaveSnapshot = ConclaveSnapshot(
        conclave: const ConclaveSummary(
          id: 'message-time-conclave',
          name: 'Clockwork Aerie',
          emblemKey: 'conclave_emblem_01',
          description: '',
          language: 'en',
          visibility: ConclaveVisibility.public,
          memberLimit: 20,
          memberCount: 2,
          level: 1,
          xp: 0,
          aerieStage: 1,
        ),
        myRole: ConclaveRole.keeper,
        contributedToday: false,
        members: const [],
        messages: [
          ConclaveMessage(
            id: 'text-time',
            senderId: 'friend-user',
            senderName: 'Visnet',
            senderPortraitKey: 'portrait_042',
            kind: 'text',
            body: 'Good morning!',
            payload: const {},
            createdAt: sentAt['text-time']!,
          ),
          ConclaveMessage(
            id: 'emote-time',
            senderId: 'friend-user',
            senderName: 'Visnet',
            senderPortraitKey: 'portrait_042',
            kind: 'emote',
            body: emote.nameEn,
            payload: {'emote_id': emote.id},
            createdAt: sentAt['emote-time']!,
          ),
          ConclaveMessage(
            id: 'achievement-time',
            senderId: 'friend-user',
            senderName: 'Visnet',
            senderPortraitKey: 'portrait_042',
            kind: 'achievement',
            body: 'Achievement unlocked!',
            payload: const {'achievement_id': 'hello_little_one'},
            createdAt: sentAt['achievement-time']!,
          ),
        ],
        chronicle: const [],
        joinRequests: const [],
      );
    final game = HouseholdProvider(random: Random(313));
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
      child: const MaterialApp(home: ConclaveScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    for (final entry in sentAt.entries) {
      final finder = find.byKey(Key('conclave-message-time-${entry.key}'));
      expect(finder, findsOneWidget);
      final expected =
          TimeOfDay.fromDateTime(entry.value).format(tester.element(finder));
      expect(tester.widget<Text>(finder).data, expected);
    }
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    online.dispose();
  });

  testWidgets('Conclave renders achievement details in one compact batch',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final messages = <ConclaveMessage>[
      for (final entry in const [
        ('achievement-1', 'hello_little_one'),
        ('achievement-2', 'guided_tour'),
        ('achievement-3', 'first_flight'),
        ('achievement-4', 'chest_expectations'),
      ].indexed)
        ConclaveMessage(
          id: entry.$2.$1,
          senderId: 'friend-user',
          senderName: 'Visnet',
          senderPortraitKey: 'portrait_042',
          kind: 'achievement',
          body: 'Achievement unlocked!',
          payload: {'achievement_id': entry.$2.$2},
          createdAt: DateTime.utc(2026, 8, 31, 14, 0, entry.$1),
        ),
    ];
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..conclaveSnapshot = ConclaveSnapshot(
        conclave: const ConclaveSummary(
          id: 'conclave-1',
          name: 'The Test Aerie',
          emblemKey: 'conclave_emblem_01',
          description: '',
          language: 'en',
          visibility: ConclaveVisibility.public,
          memberLimit: 20,
          memberCount: 2,
          level: 1,
          xp: 0,
          aerieStage: 1,
        ),
        myRole: ConclaveRole.keeper,
        contributedToday: false,
        members: [
          ConclaveMember(
            userId: 'friend-user',
            keeperCode: 'DH-1234ABCD',
            displayName: 'Visnet',
            portraitKey: 'portrait_042',
            role: ConclaveRole.keeper,
            joinedAt: DateTime.utc(2026, 8, 30),
            contributionStreak: 2,
          ),
        ],
        messages: messages,
        chronicle: [
          ConclaveChronicleEntry(
            id: 'chronicle-1',
            kind: 'joined',
            body: 'Visnet joined the Conclave.',
            actorName: 'Visnet',
            createdAt: DateTime.utc(2026, 8, 30),
          ),
          ConclaveChronicleEntry(
            id: 'chronicle-2',
            kind: 'level',
            body: 'The Conclave reached level 2.',
            actorName: 'The Test Aerie',
            createdAt: DateTime.utc(2026, 8, 31),
          ),
        ],
        joinRequests: const [],
      );
    final game = HouseholdProvider(random: Random(31));
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
      child: const MaterialApp(home: ConclaveScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const Key('conclave-achievement-group-achievement-1')),
      findsOneWidget,
    );
    expect(find.text('4 achievements shared'), findsOneWidget);
    expect(find.text('Hello, Little One!'), findsOneWidget);
    expect(find.text('A Little Less Lost'), findsOneWidget);
    expect(find.text('First Flight'), findsOneWidget);
    expect(find.text('Chest Expectations'), findsNothing);
    expect(find.text('Achievement unlocked!'), findsNothing);
    expect(find.text('Show 1 more'), findsOneWidget);
    final chatList = tester.widget<ListView>(
      find.byKey(const Key('conclave-chat-list')),
    );
    expect(chatList.reverse, isFalse);
    expect(chatList.controller, isNotNull);

    await tester.tap(
      find.byKey(const Key('toggle-conclave-achievement-batch')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chest Expectations'), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Keepers'));
    await tester.pumpAndSettle();
    expect(find.text('Conclave Keepers'), findsOneWidget);
    expect(find.text('Visnet'), findsOneWidget);
    expect(
      find.byKey(const Key('conclave-member-actions-friend-user')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Chronicle'));
    await tester.pumpAndSettle();
    expect(find.text('Visnet joined the Conclave.'), findsOneWidget);
    expect(find.text('The Conclave reached level 2.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    online.dispose();
  });

  testWidgets(
      'Conclave Keeper rows keep vanity portraits aligned and fully sized',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..conclaveSnapshot = ConclaveSnapshot(
        conclave: const ConclaveSummary(
          id: 'vanity-conclave',
          name: 'Vanity Aerie',
          emblemKey: 'conclave_emblem_01',
          description: '',
          language: 'en',
          visibility: ConclaveVisibility.public,
          memberLimit: 20,
          memberCount: 2,
          level: 1,
          xp: 0,
          aerieStage: 1,
        ),
        myRole: ConclaveRole.keeper,
        contributedToday: false,
        members: [
          ConclaveMember(
            userId: 'framed-user',
            keeperCode: 'DH-FRAMED1',
            displayName: 'Framed Keeper',
            portraitKey: 'portrait_042',
            frameKey: 'frame_supporter_founder',
            badgeKey: 'badge_supporter_founder',
            role: ConclaveRole.keeper,
            joinedAt: DateTime.utc(2026, 9, 2),
            contributionStreak: 12,
          ),
          ConclaveMember(
            userId: 'plain-user',
            keeperCode: 'DH-PLAIN001',
            displayName: 'Plain Keeper',
            portraitKey: 'portrait_042',
            role: ConclaveRole.warden,
            joinedAt: DateTime.utc(2026, 9, 2),
            contributionStreak: 2,
          ),
        ],
        messages: const [],
        chronicle: const [],
        joinRequests: const [],
      );
    final game = HouseholdProvider(random: Random(314));
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
      child: const MaterialApp(home: ConclaveScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Keepers'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('conclave-member-avatar-slot-plain-user')),
      120,
      scrollable: find.descendant(
        of: find.byKey(const Key('conclave-members-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();

    final framedCard = find.byKey(const Key('conclave-member-framed-user'));
    final plainCard = find.byKey(const Key('conclave-member-plain-user'));
    final framedSlot =
        find.byKey(const Key('conclave-member-avatar-slot-framed-user'));
    final plainSlot =
        find.byKey(const Key('conclave-member-avatar-slot-plain-user'));
    final framedName =
        find.byKey(const Key('conclave-member-name-framed-user'));
    final plainName = find.byKey(const Key('conclave-member-name-plain-user'));

    expect(tester.getSize(framedSlot), const Size.square(86));
    expect(tester.getSize(plainSlot), const Size.square(86));
    expect(tester.getSize(framedCard).height,
        closeTo(tester.getSize(plainCard).height, .01));
    expect(tester.getTopLeft(framedSlot).dx,
        closeTo(tester.getTopLeft(plainSlot).dx, .01));
    expect(tester.getTopLeft(framedName).dx,
        closeTo(tester.getTopLeft(plainName).dx, .01));

    final frame = find.byKey(
      const Key('keeper-portrait-frame-frame_supporter_founder'),
    );
    expect(frame, findsOneWidget);
    expect(tester.getSize(frame).width, greaterThan(80));
    final frameBounds = tester.getRect(frame);
    final slotBounds = tester.getRect(framedSlot);
    expect(frameBounds.left, greaterThanOrEqualTo(slotBounds.left));
    expect(frameBounds.top, greaterThanOrEqualTo(slotBounds.top));
    expect(frameBounds.right, lessThanOrEqualTo(slotBounds.right));
    expect(frameBounds.bottom, lessThanOrEqualTo(slotBounds.bottom));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    online.dispose();
  });

  testWidgets('owned dragon emotes send in private and Conclave chat',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final emote = dragonEmotesForSource(DragonEmoteSource.chest).first;
    final game = HouseholdProvider(
      random: Random(311),
      persistenceEnabled: false,
    )..ownedDragonEmoteIds.add(emote.id);
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..conclaveSnapshot = ConclaveSnapshot(
        conclave: const ConclaveSummary(
          id: 'emote-conclave',
          name: 'Emoji Aerie',
          emblemKey: 'conclave_emblem_01',
          description: '',
          language: 'en',
          visibility: ConclaveVisibility.public,
          memberLimit: 20,
          memberCount: 1,
          level: 1,
          xp: 0,
          aerieStage: 1,
        ),
        myRole: ConclaveRole.flightmaster,
        contributedToday: false,
        members: const [],
        messages: const [],
        chronicle: const [],
        joinRequests: const [],
      );
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    addTearDown(game.dispose);
    await online.initialize();

    Widget app(Widget home) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: game),
            ChangeNotifierProvider.value(value: online),
          ],
          child: MaterialApp(home: home),
        );

    await tester.pumpWidget(app(const FriendMessagesScreen(
      friend: _FakeSocialRepository._friend,
    )));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const Key('friend-message-emote-picker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dragon-emote-picker-grid')), findsOneWidget);
    expect(find.byKey(Key('pick-dragon-emote-${emote.id}')), findsOneWidget);
    await tester.tap(find.byKey(Key('pick-dragon-emote-${emote.id}')));
    await tester.pumpAndSettle();
    expect(repository.sentFriendKind, 'emote');
    expect(repository.sentFriendPayload, {'emote_id': emote.id});
    expect(
      find.byKey(Key('dragon-emote-sprite-${emote.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull, reason: 'private emote chat');

    await tester.pumpWidget(app(const ConclaveScreen()));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull, reason: 'Conclave chat');
    expect(find.text('Message…'), findsOneWidget);
    final composer = find.byKey(
      const Key('conclave-message-composer-field'),
    );
    expect(tester.getSize(composer).height, inInclusiveRange(48, 52));
    expect(
      tester.getCenter(find.byKey(const Key('share-to-conclave-button'))).dy,
      closeTo(
        tester.getCenter(find.byKey(const Key('conclave-emote-picker'))).dy,
        .1,
      ),
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('send-conclave-message')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('conclave-emote-picker')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Conclave emote picker');
    await tester.tap(find.byKey(Key('pick-dragon-emote-${emote.id}')));
    await tester.pumpAndSettle();
    expect(repository.sentConclaveKind, 'emote');
    expect(repository.sentConclavePayload, {'emote_id': emote.id});
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const Key('conclave-message-field')),
      'Hello',
    );
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('send-conclave-message')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    online.dispose();
  });

  testWidgets('Conclave keepers can invite a member who is not a friend',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeSocialRepository(
      inventoryImported: true,
      includeFriend: false,
    )..conclaveSnapshot = ConclaveSnapshot(
        conclave: const ConclaveSummary(
          id: 'friend-invite-conclave',
          name: 'Friendship Aerie',
          emblemKey: 'conclave_emblem_01',
          description: '',
          language: 'en',
          visibility: ConclaveVisibility.public,
          memberLimit: 20,
          memberCount: 2,
          level: 1,
          xp: 0,
          aerieStage: 1,
        ),
        myRole: ConclaveRole.keeper,
        contributedToday: false,
        members: [
          ConclaveMember(
            userId: 'friend-user',
            keeperCode: 'DH-1234ABCD',
            displayName: 'Visnet',
            portraitKey: 'portrait_042',
            role: ConclaveRole.keeper,
            joinedAt: DateTime.utc(2026, 9, 2),
            contributionStreak: 1,
          ),
        ],
        messages: const [],
        chronicle: const [],
        joinRequests: const [],
      );
    final game = HouseholdProvider(random: Random(312));
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
      child: const MaterialApp(home: ConclaveScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Keepers'));
    await tester.pumpAndSettle();

    final memberActions =
        find.byKey(const Key('conclave-member-actions-friend-user'));
    expect(memberActions, findsOneWidget);
    await tester.tap(memberActions);
    await tester.pumpAndSettle();
    expect(find.text('Invite as friend'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('invite-conclave-member-friend-user')),
    );
    await tester.pumpAndSettle();
    expect(repository.sentFriendRequestKeeperCode, 'DH-1234ABCD');
    expect(online.outgoingRequests, hasLength(1));
    expect(memberActions, findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    online.dispose();
  });

  testWidgets('Group Create uses the normal no-dragon message', (tester) async {
    final game = HouseholdProvider(random: Random(26));
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..groupStatus = const GroupAdventureStatus(
        slot: 13,
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

    final create = find.byKey(const Key('create-group-lobby'));
    await tester.scrollUntilVisible(
      create,
      350,
      scrollable: find.descendant(
        of: find.byKey(
          const PageStorageKey('available-adventures-scroll'),
        ),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(create);
    await tester.pump();

    expect(
      find.text('No dragon is available for this adventure.'),
      findsOneWidget,
    );
    expect(find.text('That dragon is already away.'), findsNothing);
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
      ..conversationRows.add(const FriendConversationSummary(
        friendId: 'friend-user',
        messagesAllowed: true,
        unreadCount: 3,
        lastMessage: 'See you in the Aerie!',
        lastMessageFromMe: false,
      ))
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
    expect(
      tester.getTopLeft(find.byKey(const Key('open-conclave'))).dy,
      lessThan(
          tester.getTopLeft(find.byKey(const Key('add-friend-button'))).dy),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('friend-friend-user')),
      260,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('friends-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Lyra'), findsOneWidget);
    expect(find.textContaining('2 dragons discovered'), findsOneWidget);
    final discoveredCount = find.byKey(
      const Key('friend-dragons-discovered-friend-user'),
    );
    final discoveredText = tester.widget<Text>(discoveredCount);
    expect(discoveredText.maxLines, 1);
    expect(discoveredText.softWrap, isFalse);
    expect(find.text('0/3'), findsOneWidget);
    final friendPortrait = tester.widget<KeeperPortrait>(find.descendant(
      of: find.byKey(const Key('friend-friend-user')),
      matching: find.byType(KeeperPortrait),
    ));
    expect(friendPortrait.portraitKey, 'portrait_042');
    expect(friendPortrait.frameKey, supporterFrame.id);
    expect(friendPortrait.badgeKey, supporterBadge.id);
    expect(
      find.descendant(
        of: find.byKey(const Key('friend-friend-user')),
        matching: find.byKey(
          const Key('keeper-portrait-frame-frame_supporter_founder'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('friend-friend-user')),
        matching: find.byKey(
          const Key('keeper-portrait-badge-badge_supporter_founder'),
        ),
      ),
      findsOneWidget,
    );
    final friendTitle = accountTitleById('title_321')!.label('en');
    expect(find.text(friendTitle), findsOneWidget);
    final friendTitleFinder = find.byKey(const Key('friend-title-friend-user'));
    final friendTitleText = tester.widget<Text>(friendTitleFinder);
    expect(friendTitleText.maxLines, 2);
    expect(tester.getSize(friendTitleFinder).width, greaterThan(190));
    expect(
      tester.getTopLeft(find.byKey(const Key('friend-message-friend-user'))).dy,
      greaterThan(tester.getTopLeft(friendTitleFinder).dy),
    );
    expect(find.byKey(const Key('friend-trade-friend-user')), findsOneWidget);
    expect(find.byKey(const Key('friend-message-friend-user')), findsOneWidget);
    expect(
      find.byKey(const Key('friend-message-unread-friend-user')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('my-keeper-profile-card')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('own-account-profile')), findsOneWidget);
    expect(find.byKey(const Key('start-trade-button')), findsNothing);
    expect(find.byKey(const Key('remove-friend-button')), findsNothing);
    expect(find.text('Block keeper'), findsNothing);
    Navigator.of(tester.element(find.byKey(const Key('own-account-profile'))))
        .pop();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('friend-friend-user')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(friendTitle), findsWidgets);
    expect(find.byKey(const Key('start-trade-button')), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('17'), findsOneWidget);
    final friendCodex = find.byKey(const Key('friend-draconomicon-button'));
    await tester.ensureVisible(friendCodex);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(friendCodex);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text("Lyra's Draconomicon"), findsOneWidget);
    expect(find.text('Dragons 2'), findsOneWidget);
    expect(find.text('Dragon families 1/42'), findsOneWidget);
    expect(
      find.byKey(const PageStorageKey(
        'draconomicon-lineage-normal-mossprout',
      )),
      findsOneWidget,
    );
    Navigator.of(tester.element(find.text("Lyra's Draconomicon"))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.scrollUntilVisible(
      find.text('Nimbus'),
      180,
      scrollable: find.descendant(
        of: find.byKey(const Key('friend-profile-friend-user')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Nimbus'), findsOneWidget);
    expect(find.textContaining('Level 4'), findsOneWidget);
    expect(find.text('Might'), findsOneWidget);
    expect(find.text('Arcana'), findsOneWidget);
    expect(find.text('Spirit'), findsOneWidget);
    expect(find.byKey(const Key('account-trial-records')), findsOneWidget);
    expect(find.byKey(const Key('dragon-trial-records')), findsOneWidget);
    expect(find.text('Cavern Flight'), findsNothing);
    await tester.fling(
      find.byKey(const Key('friend-profile-friend-user')),
      const Offset(0, 700),
      1800,
    );
    await tester.pump(const Duration(milliseconds: 500));

    final startTrade = find.byKey(const Key('start-trade-button'));
    await tester.tap(startTrade);
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

    await tester.tap(find.byKey(const Key('toggle-account-trial-records')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Cavern Flight'), findsOneWidget);
    await tester.fling(
      find.byKey(const Key('friend-profile-friend-user')),
      const Offset(0, -700),
      1800,
    );
    await tester.pump(const Duration(milliseconds: 500));
    final dragonRecordsToggle =
        find.byKey(const Key('toggle-dragon-trial-records'));
    await tester.ensureVisible(dragonRecordsToggle);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(dragonRecordsToggle);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Cavern Flight'), findsNWidgets(2));

    // Restore the modal's default compact state before exercising the
    // destructive action at its foot. This also verifies that both sections
    // can be collapsed again after being inspected.
    final accountRecordsToggle =
        find.byKey(const Key('toggle-account-trial-records'));
    await tester.ensureVisible(accountRecordsToggle);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(accountRecordsToggle);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.ensureVisible(dragonRecordsToggle);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const Key('toggle-dragon-trial-records')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Cavern Flight'), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('remove-friend-button')),
      300,
      scrollable: find.descendant(
        of: find.byKey(const Key('friend-profile-friend-user')),
        matching: find.byType(Scrollable),
      ),
    );
    final removeFriend = find.byKey(const Key('remove-friend-button'));
    await tester.ensureVisible(removeFriend);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(removeFriend);
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

  test('cloud backup uses revisions and can safely restore local progress',
      () async {
    final game = HouseholdProvider(random: Random(991));
    await game.updateAccountName('Cloud Keeper');
    final repository = _FakeSocialRepository(inventoryImported: true);
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
      profileSnapshot: () => OnlineProfileSnapshot.fromGame(game),
      gameStateSnapshot: game.exportState,
      applyCloudState: game.restoreCloudState,
      deviceId: () async => 'test-device',
    );
    await online.initialize();

    expect(await online.backupToCloud(), isTrue);
    expect(repository.cloudSave?.revision, 1);
    expect(repository.cloudSave?.state['accountName'], 'Cloud Keeper');

    await game.updateAccountName('Local Change');
    expect(await online.restoreFromCloud(), isTrue);
    expect(game.accountName, 'Cloud Keeper');
    online.dispose();
  });

  test('automatic backup coalesces progress to a fifteen-minute cadence',
      () async {
    var now = DateTime.utc(2026, 8, 28, 12);
    final game = HouseholdProvider(random: Random(990), clock: () => now);
    final repository = _FakeSocialRepository(inventoryImported: true);
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
      gameStateSnapshot: game.exportState,
      deviceId: () async => 'automatic-device',
    );
    await online.initialize();
    final savedCadence = <DateTime>[];
    final coordinator = AutomaticCloudBackupCoordinator(
      game: game,
      online: online,
      clock: () => now,
      loadLastSuccessfulAt: (_) async => null,
      saveLastSuccessfulAt: (_, at) async => savedCadence.add(at),
    );
    await coordinator.initialize();

    await game.updateAccountName('First automatic change');
    while (repository.cloudSave == null || online.busy) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(repository.cloudSave?.revision, 1);
    expect(savedCadence, [now]);
    expect(online.noticeCode, isNull,
        reason: 'a background save must not show a foreground success toast');

    await game.updateAccountName('Coalesced change');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(repository.cloudSave?.revision, 1);

    now = now.add(const Duration(minutes: 1));
    expect(await coordinator.tryWhenBackgrounded(), isTrue);
    expect(repository.cloudSave?.revision, 2);
    expect(repository.cloudSave?.state['accountName'], 'Coalesced change');

    await game.updateAccountName('Next foreground change');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(repository.cloudSave?.revision, 2);

    now = now.add(const Duration(minutes: 15));
    expect(await coordinator.tryWhenBackgrounded(), isTrue);
    expect(repository.cloudSave?.revision, 3);
    expect(
        repository.cloudSave?.state['accountName'], 'Next foreground change');

    coordinator.dispose();
    online.dispose();
  });

  test('cloud backup refuses to silently replace a different device revision',
      () async {
    final game = HouseholdProvider(random: Random(993));
    await game.updateAccountName('Local Keeper');
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..cloudSave = CloudGameSave(
        revision: 4,
        state: game.exportState()..['accountName'] = 'Cloud Keeper',
        updatedAt: DateTime.utc(2026, 8, 28, 10, 30),
        deviceId: 'other-device',
      );
    int? storedBaseRevision;
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
      gameStateSnapshot: game.exportState,
      applyCloudState: game.restoreCloudState,
      deviceId: () async => 'this-device',
      loadCloudBaseRevision: (_) async => storedBaseRevision,
      saveCloudBaseRevision: (_, revision) async {
        storedBaseRevision = revision;
      },
    );
    await online.initialize();

    expect(await online.backupToCloud(), isFalse);
    expect(online.errorCode, 'cloud_save_conflict');
    expect(online.cloudConflictSave?.revision, 4);
    expect(repository.cloudSave?.state['accountName'], 'Cloud Keeper');
    expect(game.accountName, 'Local Keeper');
    expect(storedBaseRevision, isNull);

    expect(await online.restoreFromCloud(), isTrue);
    expect(game.accountName, 'Cloud Keeper');
    expect(storedBaseRevision, 4);

    await game.updateAccountName('Safely Updated');
    expect(await online.backupToCloud(), isTrue);
    expect(repository.cloudSave?.revision, 5);
    expect(repository.cloudSave?.state['accountName'], 'Safely Updated');
    expect(storedBaseRevision, 5);
    online.dispose();
  });

  test('cloud history keeps five revisions and restores an older snapshot',
      () async {
    final game = HouseholdProvider(random: Random(994));
    final repository = _FakeSocialRepository(inventoryImported: true);
    int? storedBaseRevision;
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
      gameStateSnapshot: game.exportState,
      applyCloudState: game.restoreCloudState,
      deviceId: () async => 'history-device',
      clientVersion: '0.04.08-test',
      loadCloudBaseRevision: (_) async => storedBaseRevision,
      saveCloudBaseRevision: (_, revision) async {
        storedBaseRevision = revision;
      },
    );
    await online.initialize();

    for (var revision = 1; revision <= 6; revision++) {
      await game.updateAccountName('Keeper $revision');
      expect(await online.backupToCloud(), isTrue);
    }
    expect(storedBaseRevision, 6);
    expect(await online.loadCloudSaveHistory(), isTrue);
    expect(
      online.cloudSaveHistory.map((save) => save.revision),
      orderedEquals([6, 5, 4, 3, 2]),
    );
    expect(online.cloudSaveHistory.first.isCurrent, isTrue);
    expect(
      online.cloudSaveHistory.every(
        (save) => save.clientVersion == '0.04.08-test',
      ),
      isTrue,
    );

    final older = online.cloudSaveHistory.last;
    expect(await online.restoreCloudRevision(older.saveId), isTrue);
    expect(game.accountName, 'Keeper 2');
    expect(storedBaseRevision, 6,
        reason:
            'restoring history must remain based on the current server head');

    await game.updateAccountName('Keeper restored safely');
    expect(await online.backupToCloud(), isTrue);
    expect(repository.cloudSave?.revision, 7);
    expect(repository.cloudSave?.parentRevision, 6);
    expect(
        repository.cloudSave?.state['accountName'], 'Keeper restored safely');
    online.dispose();
  });

  test('explicit local replacement preserves the previous cloud revision',
      () async {
    final game = HouseholdProvider(random: Random(995));
    await game.updateAccountName('Local keeper');
    final remoteState = game.exportState()..['accountName'] = 'Cloud keeper';
    final repository = _FakeSocialRepository(inventoryImported: true)
      ..cloudSave = CloudGameSave(
        saveId: 'save-4',
        revision: 4,
        parentRevision: 3,
        state: remoteState,
        updatedAt: DateTime.utc(2026, 8, 28, 10, 30),
        deviceId: 'other-device',
        clientVersion: '0.04.06',
        schemaVersion: HouseholdProvider.saveSchemaVersion,
      );
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
      gameStateSnapshot: game.exportState,
      applyCloudState: game.restoreCloudState,
      deviceId: () async => 'this-device',
      clientVersion: '0.04.08',
    );
    await online.initialize();

    expect(await online.backupToCloud(), isFalse);
    expect(online.errorCode, 'cloud_save_conflict');
    expect(await online.replaceCloudWithLocal(), isTrue);
    expect(repository.cloudSave?.revision, 5);
    expect(repository.cloudSave?.state['accountName'], 'Local keeper');
    expect(repository.cloudSaveRevisions.single.state['accountName'],
        'Cloud keeper');
    online.dispose();
  });

  test('online account deletion requires the repository password flow',
      () async {
    final game = HouseholdProvider(random: Random(992));
    final repository = _FakeSocialRepository(inventoryImported: true);
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    await online.initialize();

    expect(await online.deleteAccount('correct horse battery staple'), isTrue);
    expect(repository.deletedWithPassword, 'correct horse battery staple');
    expect(online.isSignedIn, isFalse);
    expect(online.profile, isNull);
    online.dispose();
  });
}

TradeOffer _testTrade({
  required String status,
  required DateTime updatedAt,
  bool myAcknowledged = true,
}) =>
    TradeOffer(
      id: 'trade-$status-${updatedAt.microsecondsSinceEpoch}',
      status: status,
      initiatorId: 'my-user',
      recipientId: 'friend-user',
      otherKeeper: const KeeperProfile(
        userId: 'friend-user',
        keeperCode: 'DH-1234ABCD',
        displayName: 'Lyra',
        title: 'title_321',
        portraitKey: 'portrait_042',
        discoveredDragonCount: 12,
        inventoryImported: true,
      ),
      amInitiator: true,
      initiatorItem: const TradeItem(
        kind: TradeItemKind.chest,
        key: 'gold',
        data: {},
      ),
      recipientItem: const TradeItem(
        kind: TradeItemKind.relic,
        key: 'moralPrism',
        data: {},
      ),
      myAcknowledged: myAcknowledged,
      createdAt: updatedAt.subtract(const Duration(minutes: 1)),
      updatedAt: updatedAt,
    );

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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  bool _inventoryImported;
  int importCount = 0;
  int removeCount = 0;
  OnlineInventorySnapshot? lastImport;
  String? lastResponse;
  String? updatedDisplayName;
  String? updatedTitle;
  String? updatedPortraitKey;
  String? updatedFrameKey;
  String? updatedBadgeKey;
  int updateProfileCount = 0;
  int acknowledgeCount = 0;
  int acknowledgeGroupFailures = 0;
  int createTradeCount = 0;
  int acknowledgeTradeCount = 0;
  int acknowledgeTradeFailures = 0;
  int ensureAccountCount = 0;
  int snapshotLoadCount = 0;
  int transientSnapshotFailures = 0;
  String? tradeInventorySyncError;
  String? showcasePublishError;
  String? notificationAcknowledgeError;
  Completer<void>? ensureAccountGate;
  Completer<void>? createTradeGate;
  String? ensureAccountError;
  String? resentConfirmationEmail;
  GroupAdventureReward? groupReward;
  String? createGroupError;
  bool signedIn = true;
  CloudGameSave? cloudSave;
  ConclaveSnapshot? conclaveSnapshot;
  final List<CloudGameSave> cloudSaveRevisions = [];
  String? deletedWithPassword;

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
    cavernFlightBest: 148,
    ruinBreakerBest: 720,
    runeweaverBest: 8,
  );

  static const _friend = KeeperProfile(
    userId: 'friend-user',
    keeperCode: 'DH-1234ABCD',
    displayName: 'Lyra',
    title: 'title_321',
    portraitKey: 'portrait_042',
    frameKey: 'frame_supporter_founder',
    badgeKey: 'badge_supporter_founder',
    discoveredDragonCount: 12,
    achievementCount: 17,
    dragonCount: 7,
    inventoryImported: true,
    discoveredForms: [
      'mossprout:hatchling',
      'mossprout:wyrmling',
    ],
    prismaticForms: ['mossprout:hatchling'],
    cavernFlightBest: 211,
    ruinBreakerBest: 1200,
    runeweaverBest: 11,
    favoriteDragon: _favorite,
  );

  final List<KeeperProfile> friendRows = [];
  final List<FriendshipRequest> requestRows = [];
  final List<SocialNotification> notificationRows = [];
  final List<String> acknowledgedNotificationIds = [];
  final List<KeeperProfile> blockedRows = [];
  final List<GroupAdventureLobby> groupRows = [];
  final List<TradeOffer> tradeRows = [];
  final List<TradeInventoryItem> tradeInventoryRows = [];
  final List<FriendConversationSummary> conversationRows = [];
  final List<FriendMessage> friendMessageRows = [];
  final Map<String, List<TrialRankingEntry>> trialRankingRows = {};
  final List<(String, TrialRankingScope)> trialRankingRequests = [];
  String? sentFriendKind;
  Map<String, dynamic>? sentFriendPayload;
  String? sentFriendRequestKeeperCode;
  String? sentConclaveKind;
  Map<String, dynamic>? sentConclavePayload;
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
        frameKey: updatedFrameKey,
        badgeKey: updatedBadgeKey,
        discoveredDragonCount: 1,
        inventoryImported: _inventoryImported,
      );

  @override
  Stream<bool> get authStateChanges => const Stream.empty();
  @override
  String? get currentEmail => 'rick@example.test';
  @override
  String? get currentUserId => 'my-user';
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
  Future<void> publishSocialShowcase(OnlineInventorySnapshot snapshot) async {
    if (showcasePublishError case final code?) throw SocialException(code);
  }

  @override
  Future<List<KeeperProfile>> loadBlockedKeepers() async =>
      List.of(blockedRows);
  @override
  Future<List<KeeperProfile>> loadFriends() async => List.of(friendRows);
  @override
  Future<List<TrialRankingEntry>> loadTrialRankings({
    required String trialKey,
    required TrialRankingScope scope,
    int limit = 100,
  }) async {
    trialRankingRequests.add((trialKey, scope));
    return List.of(trialRankingRows['${scope.name}:$trialKey'] ?? const []);
  }

  @override
  Future<KeeperProfile> loadMyProfile() async => _profile;
  @override
  Future<OnlineSocialSnapshot> loadOnlineSnapshot() async {
    snapshotLoadCount++;
    if (transientSnapshotFailures > 0) {
      transientSnapshotFailures--;
      throw const SocialException('temporary_server_failure');
    }
    return OnlineSocialSnapshot(
      profile: _profile,
      friends: List.of(friendRows),
      requests: List.of(requestRows),
      blockedKeepers: List.of(blockedRows),
      groupAdventureStatus: groupStatus,
      groupLobbies: List.of(groupRows),
      trades: List.of(tradeRows),
      tradeInventory: List.of(tradeInventoryRows),
      notifications: List.of(notificationRows),
      friendConversations: List.of(conversationRows),
      conclave: conclaveSnapshot,
    );
  }

  @override
  Future<List<FriendMessage>> openFriendMessages(String friendId) async =>
      List.of(friendMessageRows);

  @override
  Future<void> sendFriendMessage(
    String friendId,
    String body, {
    String kind = 'text',
    Map<String, dynamic> payload = const {},
  }) async {
    sentFriendKind = kind;
    sentFriendPayload = Map.of(payload);
    friendMessageRows.add(FriendMessage(
      id: 'sent-friend-${friendMessageRows.length}',
      senderId: 'my-user',
      recipientId: friendId,
      body: body,
      kind: kind,
      payload: Map.of(payload),
      createdAt: DateTime.utc(2026, 9, 2, 12),
    ));
  }

  @override
  Future<void> sendConclaveMessage({
    required String kind,
    required String body,
    Map<String, dynamic> payload = const {},
  }) async {
    sentConclaveKind = kind;
    sentConclavePayload = Map.of(payload);
  }

  @override
  Future<CloudGameSave?> loadCloudGameSave() async => cloudSave;
  @override
  Future<List<CloudGameSaveSummary>> loadCloudGameSaveHistory() async {
    final saves = [
      if (cloudSave case final current?) current,
      ...cloudSaveRevisions.reversed,
    ].take(5);
    return [
      for (final save in saves)
        CloudGameSaveSummary(
          saveId: save.saveId,
          revision: save.revision,
          parentRevision: save.parentRevision,
          updatedAt: save.updatedAt,
          deviceId: save.deviceId,
          clientVersion: save.clientVersion,
          schemaVersion: save.schemaVersion,
          isCurrent: identical(save, cloudSave),
        ),
    ];
  }

  @override
  Future<CloudGameSave?> loadCloudGameSaveRevision(String saveId) async {
    if (cloudSave?.saveId == saveId) return cloudSave;
    for (final save in cloudSaveRevisions) {
      if (save.saveId == saveId) return save;
    }
    return null;
  }

  @override
  Future<CloudGameSave> pushCloudGameSave({
    required int expectedRevision,
    required Map<String, dynamic> state,
    required String deviceId,
    required String clientVersion,
  }) async {
    if ((cloudSave?.revision ?? 0) != expectedRevision) {
      throw const SocialException('cloud_save_conflict');
    }
    if (cloudSave case final previous?) {
      cloudSaveRevisions.add(previous);
      while (cloudSaveRevisions.length > 4) {
        cloudSaveRevisions.removeAt(0);
      }
    }
    return cloudSave = CloudGameSave(
      saveId: 'save-${expectedRevision + 1}',
      revision: expectedRevision + 1,
      parentRevision: expectedRevision == 0 ? null : expectedRevision,
      state: state,
      updatedAt: DateTime.utc(2026, 8, 26),
      deviceId: deviceId,
      clientVersion: clientVersion,
      schemaVersion: state['schemaVersion'] as int? ?? 1,
    );
  }

  @override
  Future<List<FriendshipRequest>> loadRequests() async => List.of(requestRows);
  @override
  Future<List<SocialNotification>> loadSocialNotifications() async =>
      List.of(notificationRows);
  @override
  Future<void> acknowledgeSocialNotifications(
      List<String> notificationIds) async {
    if (notificationAcknowledgeError case final code?) {
      throw SocialException(code);
    }
    acknowledgedNotificationIds.addAll(notificationIds);
    notificationRows.removeWhere(
      (notification) => notificationIds.contains(notification.id),
    );
  }

  @override
  Future<void> removeFriend(String userId) async {
    removeCount++;
    friendRows.removeWhere((friend) => friend.userId == userId);
  }

  @override
  Future<void> signOut() async => signedIn = false;
  @override
  Future<void> deleteMyAccount(String password) async {
    deletedWithPassword = password;
    signedIn = false;
  }

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
  Future<void> sendFriendRequest(String keeperCode) async {
    sentFriendRequestKeeperCode = keeperCode;
    final keeper = keeperCode == _friend.keeperCode
        ? _friend
        : KeeperProfile(
            userId: 'requested-user',
            keeperCode: keeperCode,
            displayName: 'Requested Keeper',
            title: 'title_001',
            portraitKey: 'portrait_001',
            discoveredDragonCount: 0,
            inventoryImported: true,
          );
    requestRows.add(FriendshipRequest(
      id: 'request-${requestRows.length + 1}',
      direction: FriendRequestDirection.outgoing,
      keeper: keeper,
      createdAt: DateTime.utc(2026, 9, 2),
    ));
  }

  @override
  Future<void> unblockKeeper(String userId) async {}
  @override
  Future<void> signIn(
          {required String email, required String password}) async =>
      signedIn = true;
  @override
  Future<void> resendSignupConfirmation(String email) async {
    resentConfirmationEmail = email;
  }

  @override
  Future<AccountAuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async =>
      const AccountAuthResult(requiresEmailConfirmation: true);
  @override
  Future<void> ensureAccount() async {
    ensureAccountCount++;
    await ensureAccountGate?.future;
    if (ensureAccountError case final code?) throw SocialException(code);
  }

  @override
  Future<void> updateProfile({
    required String displayName,
    required String title,
    required String portraitKey,
    String? frameKey,
    String? badgeKey,
  }) async {
    updateProfileCount++;
    updatedDisplayName = displayName;
    updatedTitle = title;
    updatedPortraitKey = portraitKey;
    updatedFrameKey = frameKey;
    updatedBadgeKey = badgeKey;
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
    if (acknowledgeGroupFailures > 0) {
      acknowledgeGroupFailures--;
      throw const SocialException('temporary_server_failure');
    }
    groupRows.removeWhere((lobby) => lobby.id == lobbyId);
    groupReward = null;
  }

  @override
  Future<void> synchronizeTradeInventory(
      OnlineInventorySnapshot snapshot) async {
    if (tradeInventorySyncError case final code?) throw SocialException(code);
  }

  @override
  Future<List<TradeInventoryItem>> loadTradeInventory() async =>
      List.of(tradeInventoryRows);
  @override
  Future<List<TradeOffer>> loadTrades() async => List.of(tradeRows);
  @override
  Future<void> createTrade(String friendId, TradeItem item) async {
    createTradeCount++;
    await createTradeGate?.future;
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
  Future<void> acknowledgeTrade(String tradeId) async {
    acknowledgeTradeCount++;
    if (acknowledgeTradeFailures > 0) {
      acknowledgeTradeFailures--;
      throw const SocialException('temporary_server_failure');
    }
    tradeRows.removeWhere((trade) => trade.id == tradeId);
  }

  @override
  void dispose() {}
}
