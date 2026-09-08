import 'dart:math';

import 'package:dragon_haven/app_info.dart';
import 'package:dragon_haven/dragonhaven_app.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/services/release_service.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  LatestRelease newerRelease() {
    final parts = AppInfo.version.split('.');
    parts[2] = (int.parse(parts[2]) + 1).toString().padLeft(2, '0');
    final tag = 'v${parts.join('.')}';
    return LatestRelease(
      tagName: tag,
      pageUrl: 'https://github.com/Rakky88/DragonHaven/releases/tag/$tag',
      downloadUrl:
          'https://github.com/Rakky88/DragonHaven/releases/download/$tag/DragonHaven.apk',
      hasApk: true,
    );
  }

  Future<OnlineAccountProvider> pumpShell(
    WidgetTester tester, {
    required SocialRepository repository,
    required LatestReleaseLoader loader,
    ExternalUrlOpener? opener,
  }) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = HouseholdProvider(
      random: Random(609),
      persistenceEnabled: false,
    )
      ..accountName = 'Registered Keeper'
      ..onboardingComplete = true
      ..tutorialCompleted = true;
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Ember';
    final online = OnlineAccountProvider(
      repository: repository,
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    addTearDown(online.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: game),
          ChangeNotifierProvider.value(value: online),
        ],
        child: MaterialApp(
          home: DragonHavenShell(
            latestReleaseLoader: loader,
            externalUrlOpener: opener,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return online;
  }

  testWidgets('registered keepers see one dismissible prompt for a newer app',
      (tester) async {
    var checks = 0;
    final online = await pumpShell(
      tester,
      repository: const _RegisteredRepository(),
      loader: () async {
        checks++;
        return newerRelease();
      },
    );

    expect(find.byKey(const Key('startup-update-dialog')), findsOneWidget);
    expect(find.text('Update available'), findsOneWidget);
    expect(find.text(AppInfo.displayVersion), findsOneWidget);
    expect(find.text(newerRelease().tagName), findsOneWidget);
    expect(checks, 1);

    await tester.tap(find.byKey(const Key('startup-update-later')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const Key('startup-update-dialog')), findsNothing);

    await online.refreshIfStale(minimumInterval: Duration.zero);
    await tester.pump(const Duration(seconds: 1));
    expect(checks, 1, reason: 'the same app start must not prompt twice');
    expect(find.byKey(const Key('startup-update-dialog')), findsNothing);
  });

  testWidgets('the update action opens the APK from the detected release',
      (tester) async {
    String? openedUrl;
    final release = newerRelease();
    await pumpShell(
      tester,
      repository: const _RegisteredRepository(),
      loader: () async => release,
      opener: (url) async => openedUrl = url,
    );

    await tester.tap(find.byKey(const Key('startup-update-now')));
    await tester.pump(const Duration(milliseconds: 350));

    expect(openedUrl, release.downloadUrl);
    expect(find.byKey(const Key('startup-update-dialog')), findsNothing);
  });

  testWidgets('local-only players never run the automatic release check',
      (tester) async {
    var checks = 0;
    await pumpShell(
      tester,
      repository: const DisabledSocialRepository(),
      loader: () async {
        checks++;
        return newerRelease();
      },
    );
    await tester.pump(const Duration(seconds: 1));

    expect(checks, 0);
    expect(find.byKey(const Key('startup-update-dialog')), findsNothing);
  });
}

class _RegisteredRepository extends DisabledSocialRepository {
  const _RegisteredRepository();

  static const profile = KeeperProfile(
    userId: 'registered-keeper',
    keeperCode: 'DH-UPDATE1',
    displayName: 'Registered Keeper',
    title: 'title_001',
    portraitKey: 'portrait_001',
    discoveredDragonCount: 1,
    inventoryImported: true,
  );

  @override
  bool get isConfigured => true;

  @override
  bool get isSignedIn => true;

  @override
  bool get isEmailVerified => true;

  @override
  String? get currentUserId => profile.userId;

  @override
  Future<void> ensureAccount() async {}

  @override
  Future<void> updateProfile({
    required String displayName,
    required String title,
    required String portraitKey,
    String? frameKey,
    String? badgeKey,
  }) async {}

  @override
  Future<OnlineSocialSnapshot> loadOnlineSnapshot() async =>
      const OnlineSocialSnapshot(
        profile: profile,
        friends: [],
        requests: [],
        blockedKeepers: [],
        groupAdventureStatus: GroupAdventureStatus(
          slot: 1,
          adventureId: 'group_1',
          alreadyCompleted: false,
        ),
        groupLobbies: [],
        trades: [],
        tradeInventory: [],
        notifications: [],
      );

  @override
  Future<void> synchronizeTradeInventory(
    OnlineInventorySnapshot snapshot,
  ) async {}

  @override
  Future<void> publishSocialShowcase(
    OnlineInventorySnapshot snapshot,
  ) async {}
}
