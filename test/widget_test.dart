import 'dart:math';

import 'package:dragon_haven/dragonhaven_app.dart';
import 'package:dragon_haven/l10n/app_strings.dart';
import 'package:dragon_haven/models/account_title.dart';
import 'package:dragon_haven/models/achievement.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/dragon_egg.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/profile_portrait.dart';
import 'package:dragon_haven/models/shop_item.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/screens/achievements_screen.dart';
import 'package:dragon_haven/screens/adventure_hub_screen.dart';
import 'package:dragon_haven/screens/draconomicon_screen.dart';
import 'package:dragon_haven/screens/house_screen.dart';
import 'package:dragon_haven/screens/inventory_screen.dart';
import 'package:dragon_haven/screens/shop_hub_screen.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:dragon_haven/services/audio_service.dart';
import 'package:dragon_haven/services/notification_service.dart';
import 'package:dragon_haven/widgets/achievement_badge_sprite.dart';
import 'package:dragon_haven/widgets/achievement_reveal.dart';
import 'package:dragon_haven/widgets/dragon_art.dart';
import 'package:dragon_haven/widgets/game_icon_sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('language names are presented alphabetically', () {
    expect(
      AppStrings.supportedLanguages.values,
      const [
        'Deutsch',
        'English',
        'Español',
        'Français',
        'Italiano',
        'Nederlands',
        'Português',
        '日本語',
      ],
    );
  });

  Future<HouseholdProvider> pumpGame(
    WidgetTester tester, {
    bool onboarded = false,
    bool hatched = false,
    Size surfaceSize = const Size(430, 900),
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = HouseholdProvider(random: Random(19));
    if (onboarded) {
      game
        ..accountName = 'Rick'
        ..onboardingComplete = true;
    }
    if (hatched) {
      game.pet
        ..stage = DragonStage.hatchling
        ..name = 'Ember'
        ..favorite = true;
      game.unlockedAchievementIds.add('not_picking_favorites');
    }
    final online = OnlineAccountProvider(
      repository: const DisabledSocialRepository(),
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    await online.initialize();
    addTearDown(online.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider.value(value: online),
      ],
      child: const DragonHavenApp(),
    ));
    await tester.pump(const Duration(milliseconds: 450));
    return game;
  }

  testWidgets('first launch is English and keeps the egg identity secret',
      (tester) async {
    final game = await pumpGame(tester);

    expect(find.text('DragonHaven'), findsOneWidget);
    expect(find.byKey(const Key('account-name-field')), findsOneWidget);
    expect(find.text('Claim the Starter Egg'), findsOneWidget);
    expect(find.textContaining('exactly 24 hours'), findsNothing);
    expect(find.text(game.pet.lineage.nameEn), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the egg phase shows only the rooftop nest', (tester) async {
    final game = await pumpGame(tester, onboarded: true);

    expect(find.byKey(const PageStorageKey('dragon-scroll')), findsOneWidget);
    expect(find.text('The tower nest'), findsOneWidget);
    expect(find.text('ROOFTOP NEST'), findsOneWidget);
    expect(find.text('Play'), findsNothing);
    expect(find.text('Rest'), findsNothing);
    expect(find.text('Care'), findsNothing);
    expect(find.text('The surprise is already decided'), findsNothing);
    expect(find.text('Clues from the shell'), findsNothing);
    expect(find.text('Care for the egg'), findsNothing);
    expect(find.text('Next form: Hatchling'), findsNothing);
    expect(find.text('Egg stash'), findsNothing);
    expect(find.text('Not ready yet'), findsNothing);
    final starterEggCard = find.byKey(const Key('mysterious-egg-hint'));
    expect(
      find.descendant(
        of: starterEggCard,
        matching: find.byIcon(Icons.star_rounded),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: starterEggCard,
        matching: find.byKey(const Key('rooftop-egg-nest-combined')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: starterEggCard,
        matching: find.byKey(const Key('rooftop-nest-egg')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: starterEggCard,
        matching: find.textContaining('Mysterious Egg'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: starterEggCard,
        matching: find.textContaining('Something is moving inside'),
      ),
      findsNothing,
    );
    expect(find.byKey(const Key('egg-hatch-countdown')), findsOneWidget);
    expect(find.byKey(const Key('starter-egg-clue')), findsOneWidget);
    expect(
      find.byKey(const Key('starter-egg-tap-instruction')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('egg-hatch-countdown-value')),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);

    final startedAt = game.pet.stageStartedAt;
    await tester.tap(find.byKey(const Key('mysterious-egg-hint')));
    await tester.pump();
    expect(
      game.pet.stageStartedAt,
      startedAt.subtract(const Duration(seconds: 1)),
    );
    expect(find.text(game.eggHint(isDutch: false)), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 350));
  });

  testWidgets('the animated egg timer stays centered on a compact screen',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    tester.platformDispatcher.textScaleFactorTestValue = 1.35;
    addTearDown(() {
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await pumpGame(
      tester,
      onboarded: true,
      surfaceSize: const Size(320, 900),
    );

    final timer = find.byKey(const Key('egg-hatch-countdown'));
    final timerRect = tester.getRect(timer);
    expect(timerRect.center.dx, closeTo(160, .5));
    expect(timerRect.left, greaterThanOrEqualTo(0));
    expect(timerRect.right, lessThanOrEqualTo(320));
    expect(find.byIcon(Icons.hourglass_bottom_rounded), findsNothing);
    expect(find.text('Hatches in'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact Adventure cards stay uniform on a small German phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 1.2;
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    var now = DateTime.utc(2026, 8, 23, 12, 12);
    final game = HouseholdProvider(random: Random(73), clock: () => now)
      ..languageCode = 'de';
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Ember';
    for (final focus in TrainingFocus.values) {
      game.pet.training[focus.name] = maxDragonExpertise;
    }
    final online = OnlineAccountProvider(
      repository: const DisabledSocialRepository(),
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    addTearDown(online.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider.value(value: online),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppStrings.supportedLanguages.keys.map(Locale.new),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(body: AdventureHubScreen()),
      ),
    ));
    await tester.pumpAndSettle();

    final cards = game
        .adventuresFor(AdventureKind.mini)
        .map((adventure) => find.byKey(Key('adventure-card-${adventure.id}')))
        .toList();
    expect(cards, hasLength(3));
    for (final card in cards) {
      expect(tester.getSize(card).height, 82);
    }
    final refillTimer = find.byKey(const Key('adventure-refresh-mini'));
    final timerText = find.descendant(
      of: refillTimer,
      matching: find.byType(Text),
    );
    final beforeTick = tester.widget<Text>(timerText).data;
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final afterTick = tester.widget<Text>(timerText).data;
    expect(afterTick, isNot(beforeTick));
    final first = game.adventuresFor(AdventureKind.mini).first;
    await tester.tap(find.byKey(Key('adventure-details-${first.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Mögliche Truhen'), findsOneWidget);
    expect(find.text(AppStrings('de').adventureDescription(first)),
        findsOneWidget);
    final chooseDragon =
        find.byKey(const Key('adventure-details-choose-dragon'));
    await tester.ensureVisible(chooseDragon);
    await tester.pumpAndSettle();
    await tester.tap(chooseDragon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(
      find.byKey(Key('expertise-max-${game.pet.id}-${first.focus.name}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('active Adventure countdown becomes claimable without reopening',
      (tester) async {
    var now = DateTime.utc(2026, 8, 23, 12);
    final game = HouseholdProvider(random: Random(74), clock: () => now);
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Ember'
      ..favorite = true;
    final adventure = game.adventuresFor(AdventureKind.mini).first;
    game.adventureRuns = [
      AdventureRun(
        id: 'live-countdown',
        adventureId: adventure.id,
        dragonId: game.pet.id,
        startedAt: now,
        endsAt: now.add(const Duration(minutes: 2)),
        status: AdventureRunStatus.running,
      ),
    ];
    game.pet.activeAdventureId = 'live-countdown';
    final online = OnlineAccountProvider(
      repository: const DisabledSocialRepository(),
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    addTearDown(online.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider.value(value: online),
      ],
      child: const MaterialApp(home: Scaffold(body: AdventureHubScreen())),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('adventure-tab-active')));
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller?.index, 2);
    final activeList = find.byKey(
      const PageStorageKey('active-adventures-scroll'),
    );
    expect(
      find.descendant(
        of: activeList,
        matching: find.textContaining(RegExp(r'^\d+m$')),
      ),
      findsOneWidget,
    );

    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Ready to return'), findsNothing);
    await tester.tap(find.byKey(const Key('adventure-tab-completed')));
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller?.index, 3);
    expect(
      find.byKey(const PageStorageKey('completed-adventures-scroll')),
      findsOneWidget,
    );
    expect(find.text('Ready to return'), findsOneWidget);
    final claim = find.byKey(const Key('claim-adventure-live-countdown'));
    expect(claim, findsOneWidget);
    await tester.tap(claim);
    await tester.pump();
    expect(game.chestCount(ChestTier.wooden), 1);
    expect(game.activeAdventureRuns, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an active solo Adventure can be aborted after confirmation',
      (tester) async {
    final now = DateTime.utc(2026, 8, 28, 12);
    final game = HouseholdProvider(
      random: Random(847),
      clock: () => now,
      persistenceEnabled: false,
    );
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Ember';
    final adventure = game.adventuresFor(AdventureKind.mini).first;
    final run = AdventureRun(
      id: 'abort-widget-run',
      adventureId: adventure.id,
      dragonId: game.pet.id,
      startedAt: now,
      endsAt: now.add(const Duration(minutes: 2)),
      status: AdventureRunStatus.running,
    );
    game.adventureRuns = [run];
    game.pet.activeAdventureId = run.id;
    final online = OnlineAccountProvider(
      repository: const DisabledSocialRepository(),
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    addTearDown(online.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider.value(value: online),
      ],
      child: const MaterialApp(home: Scaffold(body: AdventureHubScreen())),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('adventure-tab-active')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    await tester.tap(find.byKey(Key('abort-adventure-${run.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Abort adventure?'), findsOneWidget);
    expect(game.adventureRuns, hasLength(1));
    await tester.tap(find.byKey(Key('confirm-abort-adventure-${run.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(game.adventureRuns, isEmpty);
    expect(game.pet.activeAdventureId, isNull);
    expect(game.totalChestCount, 0);
    expect(game.totalAdventuresCompleted, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Trials sit between Available and Active and open a real game',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = HouseholdProvider(random: Random(714))
      ..pet = Pet(
        id: 'trial-widget-dragon',
        name: 'Moss',
        stage: DragonStage.hatchling,
        firstEgg: false,
        training: const {'might': 300, 'arcana': 300, 'spirit': 300},
      );
    final online = OnlineAccountProvider(
      repository: const DisabledSocialRepository(),
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    addTearDown(online.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider.value(value: online),
      ],
      child: const MaterialApp(home: Scaffold(body: AdventureHubScreen())),
    ));
    await tester.pump(const Duration(milliseconds: 350));

    final labels = tester
        .widgetList<Text>(find.descendant(
          of: find.byType(TabBar),
          matching: find.byType(Text),
        ))
        .map((text) => text.data)
        .whereType<String>()
        .toList();
    expect(
      labels,
      containsAllInOrder(['Available', 'Trials', 'Active', 'Completed']),
    );

    await tester.tap(find.byKey(const Key('adventure-tab-trials')));
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller?.index, 1);
    expect(find.byKey(const PageStorageKey('trials-scroll')), findsOneWidget);
    expect(find.byKey(const Key('trial-refresh-countdown')), findsOneWidget);
    expect(find.byKey(const Key('trial-dragon-picker')), findsNothing);
    final offers = game.availableTrials;
    expect(offers, hasLength(3));
    await tester.tap(find.byKey(Key('trial-offer-${offers.first.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byKey(const Key('trial-dragon-picker')), findsOneWidget);
    expect(
      find.byKey(Key(
        'expertise-max-trial-widget-dragon-'
        '${offers.first.definition.focus.name}',
      )),
      findsOneWidget,
    );

    final dragonChoice =
        find.byKey(const Key('trial-dragon-trial-widget-dragon'));
    await tester.ensureVisible(dragonChoice);
    await tester.pump();
    await tester.tap(dragonChoice);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    final gameKey = switch (offers.first.kind) {
      TrialKind.cavernFlight => const Key('cavern-flight-game'),
      TrialKind.ruinBreaker => const Key('ruin-breaker-game'),
      TrialKind.runeweaver => const Key('runeweaver-game'),
    };
    expect(find.byKey(gameKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('audio controls remain independent on a compact screen',
      (tester) async {
    final game = await pumpGame(
      tester,
      onboarded: true,
      hatched: true,
      surfaceSize: const Size(360, 640),
    );
    await tester.tap(find.byKey(const Key('app-overflow-menu')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(
      find.text(
        '${game.unlockedAchievementIds.length}/${achievementCatalog.length}',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('app-menu-account')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final accountScroll = find.descendant(
      of: find.byKey(const PageStorageKey('account-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Vanity'),
      180,
      scrollable: accountScroll,
    );
    expect(find.text('Vanity'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('music-switch')),
      260,
      scrollable: accountScroll,
    );
    expect(find.byKey(const Key('music-style-selector')), findsNothing);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.byKey(const Key('jukebox-settings-button')), findsOneWidget);
    expect(find.text('Jukebox'), findsOneWidget);
    expect(game.musicStyle, HavenMusicStyle.classic);
    expect(find.byKey(const Key('music-switch')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('music-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('music-switch')));
    await tester.pump();
    expect(game.musicEnabled, isFalse);
    expect(game.soundEffectsEnabled, isTrue);
    await tester.ensureVisible(find.byKey(const Key('sound-effects-switch')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sound-effects-switch')));
    await tester.pump();
    expect(game.musicEnabled, isFalse);
    expect(game.soundEffectsEnabled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification settings expose every reason and save each toggle',
      (tester) async {
    final game = await pumpGame(
      tester,
      onboarded: true,
      hatched: true,
      surfaceSize: const Size(390, 800),
    );
    await tester.tap(find.byKey(const Key('app-overflow-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('app-menu-account')));
    await tester.pumpAndSettle();
    final settingsButton = find.byKey(
      const Key('notification-settings-button'),
    );
    await tester.scrollUntilVisible(
      settingsButton,
      240,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('account-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    for (final category in HavenNotificationCategory.values) {
      expect(find.byKey(Key('notification-${category.name}')), findsOneWidget);
      expect(game.notificationEnabled(category), isTrue);
    }
    final tradeReturn = find.byKey(
      const Key('notification-tradeReturns'),
    );
    await tester.drag(
      find.byKey(const PageStorageKey('notification-settings-scroll')),
      const Offset(0, -650),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(tradeReturn);
    await tester.pumpAndSettle();
    await tester.tap(tradeReturn);
    await tester.pump();
    expect(
      game.notificationEnabled(HavenNotificationCategory.tradeReturns),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a dragon invited to the Tower renders inside its assigned room',
      (tester) async {
    final game = HouseholdProvider(random: Random(75));
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Ember'
      ..favorite = true
      ..roamsTower = true
      ..currentFloorIndex = 0
      ..currentRoomId = 'hearth';
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: game,
      child: MaterialApp(
        home: Scaffold(
          body: HouseScreen(
            active: true,
            floorIndex: 0,
            onOpenShop: () {},
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    expect(game.towerDragons, contains(game.pet));
    expect(find.byKey(Key('room-dragon-${game.pet.id}')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long screens scroll cleanly with large text on a small phone',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.35;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final game = await pumpGame(
      tester,
      onboarded: true,
      hatched: true,
      surfaceSize: const Size(360, 640),
    );
    game.towerFloorRoomIds = List.generate(
      20,
      (index) => const [
        'hearth',
        'crystal',
        'garden',
        'tidal_library',
        'loft',
        'cloud',
        'sunforge',
      ][index % 7],
    );
    game.notifyListeners();
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'initial Tower layout');

    await tester.scrollUntilVisible(
      find.byKey(const Key('add-tower-floor')),
      500,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('dragon-tower-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(const Key('add-tower-floor')), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'scrolled Tower layout');

    final shellContext = tester.element(find.byType(Scaffold).first);
    Navigator.of(shellContext).push(MaterialPageRoute<void>(
      builder: (_) => const AchievementsScreen(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    final achievementsError = tester.takeException();
    expect(
      achievementsError,
      isNull,
      reason: achievementsError is FlutterError
          ? achievementsError.toStringDeep()
          : 'Achievements layout: $achievementsError',
    );
    expect(
      find.byKey(const PageStorageKey('achievements-scroll')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('A Scale for Every Tale'),
      450,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('A Scale for Every Tale'), findsOneWidget);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull, reason: 'Achievements scrolling');

    await tester.tap(find.text('Shop').last);
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull, reason: 'Shop initial layout');
    final firstCoinItem =
        shopCatalog.firstWhere((item) => item.currency == ItemCurrency.coins);
    final itemCard = find.byKey(Key('shop-item-${firstCoinItem.id}'));
    final itemAction = find.byKey(Key('shop-action-${firstCoinItem.id}'));
    await tester.scrollUntilVisible(
      itemCard,
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('shop-coins-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pump();
    expect(tester.getRect(itemCard).contains(tester.getRect(itemAction).center),
        isTrue,
        reason: 'The shop action must stay inside its item card.');
    await tester.fling(
      find.byKey(const PageStorageKey('shop-coins-scroll')),
      const Offset(0, -900),
      2200,
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('shop-search')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all five primary destinations are reachable after hatching',
      (tester) async {
    final game = await pumpGame(tester, onboarded: true, hatched: true);

    expect(find.byKey(const PageStorageKey('dragon-tower-scroll')),
        findsOneWidget);
    final navigation = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      navigation.destinations
          .map((destination) => (destination as NavigationDestination).label),
      ['Friends', 'Adventure', 'Tower', 'Inventory', 'Shop'],
    );
    final towerRoof = find.byKey(const Key('tower-roof'));
    final openMyDragons = find.byKey(const Key('open-my-dragons'));
    final openCodex = find.byKey(const Key('open-draconomicon'));
    expect(openMyDragons, findsOneWidget);
    expect(openCodex, findsOneWidget);
    expect(tester.getSize(openMyDragons), const Size.square(64));
    expect(tester.getSize(openCodex), const Size.square(64));
    expect(tester.getTopLeft(openCodex).dy,
        lessThan(tester.getTopLeft(towerRoof).dy));
    expect(
      find.descendant(of: towerRoof, matching: find.byType(DragonArt)),
      findsNothing,
    );
    expect(
        find.byKey(Key('tower-floor-dragon-${game.pet.id}')), findsOneWidget);

    await tester.tap(find.text('Adventure').last);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Short'), findsOneWidget);
    expect(find.text('Tiny outings'), findsOneWidget);
    expect(
      find.text('Tiny outings, quick training and wooden chests.'),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('adventure-info-mini')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Refresh rules'), findsOneWidget);
    expect(find.textContaining('not automatically replaced'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    final shortCards = game
        .adventuresFor(AdventureKind.short)
        .map((adventure) => find.byKey(Key('adventure-card-${adventure.id}')))
        .toList();
    expect(shortCards, isNotEmpty);
    for (final card in shortCards) {
      expect(tester.getSize(card).height, 82);
    }
    final adventureList = find.descendant(
      of: find.byKey(const PageStorageKey('available-adventures-scroll')),
      matching: find.byType(Scrollable),
    );
    for (final heading in const [
      'Long',
      'Group',
      'Special',
    ]) {
      await tester.scrollUntilVisible(
        find.text(heading),
        480,
        scrollable: adventureList,
      );
      expect(find.text(heading), findsOneWidget);
    }

    await tester.tap(find.text('Tower').last);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const Key('open-my-dragons')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('owned-dragons-grid')), findsOneWidget);
    expect(find.text('Dragon type'), findsNothing);
    final ownedDragon = find.byKey(Key('owned-dragon-${game.pet.id}'));
    await tester.ensureVisible(ownedDragon);
    await tester.pump();
    await tester.tap(ownedDragon);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Dragon type'), findsOneWidget);
    expect(find.text('Maturity'), findsOneWidget);
    expect(find.byKey(const Key('dragon-level-progress')), findsOneWidget);
    expect(find.textContaining('Level'), findsWidgets);
    expect(find.text('Next evolution'), findsNothing);
    expect(find.textContaining('Next evolution:'), findsOneWidget);
    expect(find.text('Expertises'), findsOneWidget);
    expect(find.text('Might'), findsOneWidget);
    expect(find.text('Arcana'), findsOneWidget);
    expect(find.text('Spirit'), findsOneWidget);
    expect(find.byKey(const Key('dragon-trial-records')), findsOneWidget);
    expect(find.text('Moral nature'), findsOneWidget);
    expect(find.text('Order nature'), findsOneWidget);
    expect(find.text('Personality'), findsOneWidget);
    expect(find.text('Remove from Tower'), findsOneWidget);
    expect(
        find.byKey(const Key('dragon-favorite-action-sprite')), findsOneWidget);
    expect(
        tester
            .widget<GameIconSprite>(
                find.byKey(const Key('dragon-favorite-action-sprite')))
            .kind,
        GameIconKind.dragonFavorite);
    expect(
        find.byKey(const Key('dragon-release-action-sprite')), findsOneWidget);
    expect(
        tester
            .widget<GameIconSprite>(
                find.byKey(const Key('dragon-release-action-sprite')))
            .kind,
        GameIconKind.dragonRelease);
    final releaseTile = tester.widget<ListTile>(find.ancestor(
      of: find.text('Release dragon…'),
      matching: find.byType(ListTile),
    ));
    expect(releaseTile.enabled, isFalse);
    expect(find.byKey(Key('dragon-roaming-${game.pet.id}')), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tapAt(const Offset(8, 8));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Friends').last);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const PageStorageKey('friends-scroll')), findsOneWidget);

    await tester.tap(find.text('Inventory').last);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Eggs'), findsOneWidget);
    expect(find.text('Chests'), findsOneWidget);
    expect(find.text('Furniture'), findsOneWidget);
    expect(find.text('Relics'), findsOneWidget);

    await tester.tap(find.text('Shop').last);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Coins'), findsOneWidget);
    expect(find.text('Gems'), findsOneWidget);
    expect(find.text('Furniture'), findsOneWidget);
    expect(find.text('Chests'), findsOneWidget);
    expect(find.text('Buy'), findsOneWidget);
    await tester.tap(find.byKey(const Key('shop-coins-tab-buy')));
    await tester.pumpAndSettle();
    final packGrid = find.byKey(const Key('shop-coins-pack-grid'));
    expect(packGrid, findsOneWidget);
    for (var index = 0; index < 6; index++) {
      final tile = find.byKey(Key('shop-coins-pack-$index'));
      expect(tile, findsOneWidget);
      final size = tester.getSize(tile);
      expect((size.width - size.height).abs(), lessThan(.01));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the My Dragons shortcut tooltip localizes', (tester) async {
    final game = await pumpGame(tester, onboarded: true, hatched: true);
    await game.setLanguage('de');
    await tester.pump(const Duration(milliseconds: 300));

    final shortcut = find.byKey(const Key('open-my-dragons'));
    final tooltip = tester.widget<Tooltip>(
      find.descendant(of: shortcut, matching: find.byType(Tooltip)),
    );
    expect(tooltip.message, 'Meine Drachen');
    expect(tester.takeException(), isNull);
  });

  testWidgets('starter tutorial can be skipped and replayed to completion',
      (tester) async {
    final game = await pumpGame(tester, onboarded: true, hatched: true);
    game
      ..tutorialCompleted = false
      ..tutorialFullyViewed = false
      ..unlockedAchievementIds.add('hello_little_one');
    game.notifyListeners();

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('tutorial-step-0')), findsOneWidget);
    expect(find.byKey(const Key('tutorial-dragon-guide')), findsOneWidget);
    expect(find.text('Welcome to DragonHaven'), findsOneWidget);

    await tester.tap(find.byKey(const Key('next-tutorial-step')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const PageStorageKey('friends-scroll')), findsOneWidget);
    expect(find.text('Friends'), findsWidgets);

    await tester.tap(find.byKey(const Key('skip-tutorial')));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(game.tutorialCompleted, isTrue);
    expect(game.tutorialFullyViewed, isFalse);
    expect(game.unlockedAchievementIds, isNot(contains('guided_tour')));
    expect(
        find.byKey(const Key('tutorial-step-1')).hitTestable(), findsNothing);

    await tester.tap(find.byKey(const Key('app-overflow-menu')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    await tester.tap(find.byKey(const Key('app-menu-tutorial')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('tutorial-step-0')), findsOneWidget);
    for (var step = 1; step < 9; step++) {
      await tester.tap(find.byKey(const Key('next-tutorial-step')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(Key('tutorial-step-$step')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'tutorial step $step');
    }
    expect(find.text('The three-dot menu'), findsOneWidget);
    await tester.tap(find.byKey(const Key('next-tutorial-step')));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(game.tutorialFullyViewed, isTrue);
    expect(game.unlockedAchievementIds, contains('guided_tour'));
    expect(
        find.byKey(const Key('tutorial-step-8')).hitTestable(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('earned chests appear and open only from Inventory',
      (tester) async {
    final game = await pumpGame(tester, onboarded: true, hatched: true);
    game.chestInventory[ChestTier.wooden] = 1;
    game.notifyListeners();
    await tester.pump();

    await tester.tap(find.text('Adventure').last);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const PageStorageKey('unopened-chests-scroll')),
        findsNothing);

    await tester.tap(find.text('Inventory').last);
    await tester.pumpAndSettle();
    expect(game.chestCount(ChestTier.wooden), 1);
    DefaultTabController.of(tester.element(find.byType(TabBarView)))
        .animateTo(1);
    await tester.pumpAndSettle();

    final openChest = find.byKey(const Key('inventory-open-chest-wooden'));
    expect(openChest, findsOneWidget);
    await tester.tap(openChest);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('chest-reveal-tap-target')), findsOneWidget);
    expect(find.byKey(const Key('chest-rewards')), findsNothing);
    expect(game.chestCount(ChestTier.wooden), 1,
        reason: 'Opening the preview must not consume the chest yet.');
    await tester.tap(find.byKey(const Key('chest-reveal-tap-target')));
    await tester.pump();
    expect(game.chestCount(ChestTier.wooden), 0);
    for (var frame = 0; frame < 28; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(game.chestCount(ChestTier.wooden), 0);
    expect(find.byKey(const Key('chest-rewards')), findsOneWidget);
    expect(find.text('Collect'), findsNothing);
    expect(find.text('Tap the chest'), findsNothing);
    expect(game.chestCount(ChestTier.wooden), 0);
    await tester.tapAt(const Offset(30, 30));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('large egg inventories stay compact and open focused details',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 1.2;
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
    )..pet = Pet(stage: DragonStage.hatchling, firstEgg: false);
    game.eggStash = List.generate(
      12,
      (index) => DragonEgg(
        id: 'compact-egg-$index',
        lineageId: dragonLineages[index % dragonLineages.length].id,
        acquiredAt: DateTime.utc(2026, 8, index + 1),
        hatchSeed: index + 1,
        prismatic: false,
        incubationMinutes: 60 + index * 6,
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: const MaterialApp(
          home: Scaffold(body: InventoryScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('12 eggs'), findsOneWidget);
    expect(find.byKey(const PageStorageKey('inventory-eggs-scroll')),
        findsOneWidget);
    final newest = find.byKey(const Key('inventory-egg-compact-egg-11'));
    final nextNewest = find.byKey(const Key('inventory-egg-compact-egg-10'));
    expect(newest, findsOneWidget);
    expect(nextNewest, findsOneWidget);
    expect(tester.getTopLeft(newest).dy,
        closeTo(tester.getTopLeft(nextNewest).dy, 1));
    expect(tester.getTopLeft(newest).dx,
        isNot(closeTo(tester.getTopLeft(nextNewest).dx, 1)));

    await tester.tap(newest);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('inventory-egg-clue-compact-egg-11')),
        findsOneWidget);
    expect(find.byKey(const Key('inventory-incubate-egg-compact-egg-11')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('My Dragons switches view, sorts, and marks max expertise',
      (tester) async {
    final game = await pumpGame(
      tester,
      onboarded: true,
      hatched: true,
      surfaceSize: const Size(320, 640),
    );
    for (final focus in TrainingFocus.values) {
      game.pet.training[focus.name] = maxDragonExpertise;
    }
    final legendary = dragonLineages.firstWhere(
      (lineage) => lineage.rarity == DragonRarity.legendary,
    );
    game.sanctuaryDragons = [
      Pet(
        id: 'sorted-alpha',
        name: 'Alpha',
        stage: DragonStage.hatchling,
        firstEgg: false,
        lineageId: legendary.id,
        acquiredAt: DateTime.utc(2025, 1, 1),
      ),
      Pet(
        id: 'sorted-zephyr',
        name: 'Zephyr',
        stage: DragonStage.hatchling,
        firstEgg: false,
        lineageId: dragonLineages.first.id,
        acquiredAt: DateTime.utc(2024, 1, 1),
      ),
    ];
    game.notifyListeners();
    await tester.pump();

    await tester.tap(find.text('Tower').last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('open-my-dragons')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('owned-dragons-grid')), findsOneWidget);
    await tester.tap(find.byKey(const Key('owned-dragons-view-toggle')));
    await tester.pump();
    expect(find.byKey(const Key('owned-dragons-list')), findsOneWidget);

    await tester.tap(find.byKey(const Key('owned-dragons-sort')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(
      find.byKey(const Key('owned-dragons-sort-name')),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      tester
          .getTopLeft(find.byKey(const Key('owned-dragon-list-sorted-alpha')))
          .dy,
      lessThan(tester
          .getTopLeft(find.byKey(const Key('owned-dragon-list-sorted-zephyr')))
          .dy),
    );

    await tester.tap(
      find.byKey(Key('owned-dragon-list-${game.pet.id}')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    for (final focus in TrainingFocus.values) {
      expect(
        find.byKey(Key('expertise-max-${game.pet.id}-${focus.name}')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Portrait Chest reveals an enlarged portrait without equipping it',
      (tester) async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: Random(908),
    )
      ..pet = Pet(stage: DragonStage.hatchling, firstEgg: false)
      ..chestInventory[ChestTier.portrait] = 1;
    game.notifyListeners();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: const MaterialApp(
          home: Scaffold(body: InventoryScreen(initialTab: 1)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    expect(game.chestCount(ChestTier.portrait), 1);
    expect(find.byKey(const PageStorageKey('inventory-chests-scroll')),
        findsOneWidget);
    expect(find.text('Portrait Chest'), findsOneWidget);
    await tester.tap(find.byKey(const Key('inventory-open-chest-portrait')));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Portrait Chest'), findsWidgets);
    await tester.tap(find.byKey(const Key('chest-reveal-tap-target')));
    for (var frame = 0; frame < 34; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final portrait = find.byKey(const Key('portrait-chest-zoomed-reward'));
    expect(portrait, findsOneWidget);
    expect(tester.getSize(portrait), const Size(228, 228));
    expect(game.portraitCount, 1);
    expect(game.selectedPortrait, isNull);
    expect(game.chestCount(ChestTier.portrait), 0);
    await tester.tapAt(const Offset(30, 30));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('complete portrait collection warns on opening and buying',
      (tester) async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
    )..pet = Pet(stage: DragonStage.hatchling, firstEgg: false, gems: 999);
    game
      ..ownedPortraitIds =
          profilePortraitCatalog.map((portrait) => portrait.id).toSet()
      ..chestInventory[ChestTier.portrait] = 1;
    game.notifyListeners();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: const MaterialApp(
          home: Scaffold(body: InventoryScreen(initialTab: 1)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('inventory-open-chest-portrait')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Portrait collection complete'), findsOneWidget);
    expect(game.chestCount(ChestTier.portrait), 1);
    await tester.tap(find.text('Understood'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: const MaterialApp(
          home: Scaffold(
            body: ShopHubScreen(
              initialCurrencyTab: 1,
              initialCategoryTab: 2,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const Key('portrait-chest-collection-status')),
        findsOneWidget);
    expect(find.text('100 / 100'), findsOneWidget);
    expect(find.text('1 unopened chests'), findsOneWidget);
    final buyPortrait = tester.widget<FilledButton>(
      find.byKey(const Key('buy-portrait-chest')),
    );
    expect(buyPortrait.onPressed, isNull);
    expect(game.chestCount(ChestTier.portrait), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait chest shop shows live rarity odds and all pack art',
      (tester) async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
    )..pet = Pet(stage: DragonStage.hatchling, firstEgg: false, gems: 999);

    Future<void> pumpShop(int currencyTab, int categoryTab) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: game,
          child: MaterialApp(
            key: ValueKey('shop-$currencyTab-$categoryTab'),
            home: Scaffold(
              body: ShopHubScreen(
                initialCurrencyTab: currencyTab,
                initialCategoryTab: categoryTab,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
    }

    await pumpShop(1, 2);
    expect(find.byKey(const Key('portrait-chest-progress')), findsOneWidget);
    expect(find.text('0 / 100'), findsOneWidget);
    expect(find.text('Current portrait odds'), findsOneWidget);
    for (final rarity in PortraitRarity.values) {
      expect(find.byKey(Key('portrait-odds-${rarity.name}')), findsOneWidget);
    }

    await pumpShop(0, 2);
    for (var pack = 1; pack <= 6; pack++) {
      expect(
        find.byKey(Key(
          'currency-pack-art-coins-${pack.toString().padLeft(2, '0')}',
        )),
        findsOneWidget,
      );
    }
    await pumpShop(1, 3);
    for (var pack = 1; pack <= 6; pack++) {
      expect(
        find.byKey(Key(
          'currency-pack-art-gems-${pack.toString().padLeft(2, '0')}',
        )),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('gems shop sells unlimited untradeable Relics for 500 gems',
      (tester) async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
    )..pet = Pet(
        stage: DragonStage.hatchling,
        firstEgg: false,
        gems: 1000,
      );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: const MaterialApp(
          home: Scaffold(
            body: ShopHubScreen(
              initialCurrencyTab: 1,
              initialCategoryTab: 1,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const Key('shop-gems-tab-relics')), findsOneWidget);
    expect(find.textContaining('untradeable'), findsWidgets);
    expect(find.text('Moral Prism'), findsOneWidget);
    final buy = find.byKey(const Key('buy-relic-moralPrism'));
    expect(buy, findsOneWidget);

    await tester.tap(buy);
    await tester.pump(const Duration(milliseconds: 350));
    expect(game.pet.gems, 500);
    expect(game.untradeableRelicCount(MysticRelic.moralPrism), 1);
    await tester.tap(buy);
    await tester.pump(const Duration(milliseconds: 350));
    expect(game.pet.gems, 0);
    expect(game.relicCount(MysticRelic.moralPrism), 2);
    expect(game.untradeableRelicCount(MysticRelic.moralPrism), 2);
    expect(game.tradeableRelicCount(MysticRelic.moralPrism), 0);
    expect(tester.widget<FilledButton>(buy).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Title Chest reveals a translated title without equipping it',
      (tester) async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: Random(909),
    )
      ..pet = Pet(stage: DragonStage.hatchling, firstEgg: false)
      ..chestInventory[ChestTier.title] = 1;
    game.notifyListeners();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: const MaterialApp(
          home: Scaffold(body: InventoryScreen(initialTab: 1)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.byKey(const Key('inventory-open-chest-title')));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.tap(find.byKey(const Key('chest-reveal-tap-target')));
    for (var frame = 0; frame < 34; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('title-chest-zoomed-reward')), findsOneWidget);
    expect(game.titleCount, 1);
    expect(game.selectedAccountTitle, isNull);
    expect(game.chestCount(ChestTier.title), 0);
    await tester.tapAt(const Offset(30, 30));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('complete title collection warns on opening and buying',
      (tester) async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
    )..pet = Pet(stage: DragonStage.hatchling, firstEgg: false, coins: 999);
    game
      ..ownedTitleIds = accountTitleCatalog.map((title) => title.id).toSet()
      ..chestInventory[ChestTier.title] = 1;
    game.notifyListeners();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: const MaterialApp(
          home: Scaffold(body: InventoryScreen(initialTab: 1)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.byKey(const Key('inventory-open-chest-title')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Title collection complete'), findsOneWidget);
    expect(game.chestCount(ChestTier.title), 1);
    await tester.tap(find.text('Understood'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: const MaterialApp(
          home: Scaffold(
            body: ShopHubScreen(
              initialCurrencyTab: 0,
              initialCategoryTab: 1,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(
        find.byKey(const Key('title-chest-collection-status')), findsOneWidget);
    expect(find.text('500 / 500'), findsOneWidget);
    final buyTitle = tester.widget<FilledButton>(
      find.byKey(const Key('buy-title-chest')),
    );
    expect(buyTitle.onPressed, isNull);
    expect(game.pet.coins, 999);
    expect(game.chestCount(ChestTier.title), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a relic reveals one chosen dragon and updates My Dragons',
      (tester) async {
    final game = await pumpGame(tester, onboarded: true, hatched: true);
    game.relicInventory[MysticRelic.moralPrism] = 1;
    game.notifyListeners();
    await tester.pump();

    await tester.tap(find.text('Inventory').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Relics'));
    await tester.pumpAndSettle();
    expect(find.text('Relics'), findsWidgets);
    expect(find.text('Moral Prism'), findsOneWidget);

    await tester.tap(find.byKey(const Key('use-relic-moralPrism')));
    await tester.pump();
    expect(find.text('Use this Relic?'), findsOneWidget);
    expect(game.relicCount(MysticRelic.moralPrism), 1);
    await tester.tap(find.byKey(const Key('confirm-relic-use')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('relic-dragon-picker-scroll')), findsOneWidget);
    final dragonChoice = find.byKey(Key('relic-dragon-choice-${game.pet.id}'));
    await tester.ensureVisible(dragonChoice);
    await tester.pump();
    await tester.tap(dragonChoice);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(game.pet.moralAxisKnown, isTrue);
    expect(game.relicCount(MysticRelic.moralPrism), 0);
    expect(find.text('Moral Prism'), findsOneWidget);
    await tester.tapAt(const Offset(215, 250));
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text(AppStrings('en').moralAxisName(game.pet.moralAxis)),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('close-relic-reveal')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a Relic explains why it has no eligible dragon', (tester) async {
    final game = await pumpGame(tester, onboarded: true, hatched: true);
    game.pet.moralAxisKnown = true;
    game.relicInventory[MysticRelic.moralPrism] = 1;
    game.notifyListeners();
    await tester.pump();

    await tester.tap(find.text('Inventory').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Relics'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('use-relic-moralPrism')));
    await tester.pump();

    expect(find.text('Nothing left to reveal'), findsOneWidget);
    expect(game.relicCount(MysticRelic.moralPrism), 1);
    await tester.tap(find.text('Understood'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a later egg incubates in the nest while the app stays usable',
      (tester) async {
    final game = await pumpGame(tester, onboarded: true, hatched: true);
    final activeDragonId = game.pet.id;
    game.eggStash.add(DragonEgg(
      id: 'widget-later-egg',
      lineageId: dragonLineages.last.id,
      acquiredAt: DateTime(2026, 8, 22),
      hatchSeed: 991,
      prismatic: false,
    ));
    game.notifyListeners();
    await tester.pump();

    final towerRoof = find.byKey(const Key('tower-roof'));
    expect(towerRoof, findsOneWidget);
    await tester.ensureVisible(towerRoof);
    await tester.pump();
    await tester.tap(towerRoof);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rooftop-nest-scene')), findsOneWidget);
    expect(find.text('The nest is empty'), findsOneWidget);
    expect(find.text('Choose one egg from your inventory.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rooftop-nest-scene')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('nest-egg-picker')), findsOneWidget);
    expect(
      find.byKey(const Key('nest-egg-hatch-time-widget-later-egg')),
      findsOneWidget,
    );
    expect(find.textContaining('Hatch time:'), findsOneWidget);
    final eggChoice = find.text('Mysterious Egg').last;
    await tester.ensureVisible(eggChoice);
    await tester.pump();
    await tester.tap(eggChoice);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 200));

    expect(game.pet.id, activeDragonId);
    expect(game.incubatingEgg?.id, 'widget-later-egg');
    for (var frame = 0;
        frame < 10 &&
            find
                .byKey(const Key('nest-egg-hatch-countdown'))
                .evaluate()
                .isEmpty;
        frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('rooftop-nest-scene')), findsOneWidget);
    expect(find.text('The nest is empty'), findsNothing);
    expect(
      find.text('Rare eggs can be found in chests earned on Adventures.'),
      findsNothing,
    );
    expect(find.text('One hidden dragon is growing beneath the shell.'),
        findsOneWidget);
    expect(find.byKey(const Key('nest-egg-hatch-countdown')), findsOneWidget);
    final detailedNest = find.byKey(const Key('rooftop-nest-scene'));
    expect(
      find.descendant(
        of: detailedNest,
        matching: find.byKey(const Key('rooftop-egg-nest-combined')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: detailedNest,
        matching: find.byKey(const Key('rooftop-bird-nest-front')),
      ),
      findsNothing,
    );
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Adventure'), findsWidgets);
    final roofEggNest = find.descendant(
      of: towerRoof,
      matching: find.byKey(const Key('rooftop-egg-nest-combined')),
    );
    expect(roofEggNest, findsOneWidget);
    expect(find.byKey(const Key('rooftop-nest-egg')), findsNothing);
    expect(find.byKey(const Key('rooftop-bird-nest-front')), findsNothing);
    final roofEggNestSize = tester.getSize(roofEggNest);
    expect(roofEggNestSize.width, closeTo(148, .1));
    expect(roofEggNestSize.height, closeTo(148 / (960 / 700), .1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty nest explains where rare eggs can be found',
      (tester) async {
    await pumpGame(tester, onboarded: true, hatched: true);
    final towerRoof = find.byKey(const Key('tower-roof'));
    await tester.ensureVisible(towerRoof);
    await tester.tap(towerRoof);
    await tester.pumpAndSettle();

    expect(find.text('The nest is empty'), findsOneWidget);
    expect(
      find.text('Rare eggs can be found in chests earned on Adventures.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the complete Draconomicon scrolls without state collisions',
      (tester) async {
    await pumpGame(tester, onboarded: true, hatched: true);
    final openCodex = find.byKey(const Key('open-draconomicon'));
    await tester.ensureVisible(openCodex);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(openCodex);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('The Draconomicon'), findsWidgets);
    final finalLineage = find.byKey(PageStorageKey(
      'draconomicon-lineage-normal-${dragonLineages.last.id}',
    ));
    await tester.scrollUntilVisible(
      finalLineage,
      400,
      scrollable: find.byType(Scrollable).last,
    );

    expect(finalLineage, findsOneWidget);
    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
  });

  testWidgets('a discovered Draconomicon family expands all five forms',
      (tester) async {
    final game = HouseholdProvider.createShowcase();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: game,
      child: const MaterialApp(
        home: Scaffold(body: DraconomiconScreen()),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));

    final firstLineage = find.byKey(
      PageStorageKey(
        'draconomicon-lineage-normal-${dragonLineages.first.id}',
      ),
    );
    await tester.tap(firstLineage);
    await tester.pump(const Duration(milliseconds: 500));

    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
    expect(
      find.descendant(of: firstLineage, matching: find.byType(DragonArt)),
      findsNWidgets(6),
    );
  });

  testWidgets('Draconomicon counts every discovered evolved form',
      (tester) async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
    );
    final lineages = dragonLineages.take(4).toList();
    final forms = <String>{
      '${lineages[0].id}:hatchling',
      '${lineages[0].id}:wyrmling',
      '${lineages[0].id}:ascended:might',
      '${lineages[1].id}:hatchling',
      '${lineages[1].id}:wyrmling',
      '${lineages[2].id}:hatchling',
      '${lineages[2].id}:wyrmling',
      '${lineages[3].id}:hatchling',
    };
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: game,
      child: MaterialApp(
        home: Scaffold(
          body: DraconomiconScreen(discoveredForms: forms),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Dragons 8'), findsOneWidget);
    expect(find.text('Dragon families 4/42'), findsOneWidget);
  });

  testWidgets('every dragon artwork stage renders as a widget', (tester) async {
    final game = HouseholdProvider.createShowcase();
    for (final stage in const ['spark', 'nestDragon', 'homeGuardian']) {
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: game,
        child: MaterialApp(
          home: Scaffold(
            body: DragonArt(
              animate: false,
              stageKey: stage,
              lineageId: dragonLineages.first.id,
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      final error = tester.takeException();
      expect(error, isNull, reason: '$stage: $error');
    }
  });

  testWidgets('the overflow menu changes the complete app to Dutch',
      (tester) async {
    final game = await pumpGame(tester, onboarded: true, hatched: true);
    await tester.tap(find.byKey(const Key('app-overflow-menu')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    await tester.tap(find.byKey(const Key('app-menu-language')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.tap(find.byKey(const Key('language-option-nl')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(game.languageCode, 'nl');
    expect(find.text('Avontuur'), findsOneWidget);
    expect(find.text('Vrienden'), findsOneWidget);
    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
  });

  testWidgets('the language sheet pins its handle and pulls closed',
      (tester) async {
    await pumpGame(tester, onboarded: true, hatched: true);
    await tester.tap(find.byKey(const Key('app-overflow-menu')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    await tester.tap(find.byKey(const Key('app-menu-language')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final handle = find.byKey(const Key('language-drag-handle'));
    final scroll = find.byKey(const Key('language-picker-scroll'));
    final handleTop = tester.getTopLeft(handle).dy;
    await tester.drag(scroll, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.getTopLeft(handle).dy, closeTo(handleTop, .5));

    await tester.fling(scroll, const Offset(0, 1800), 2400);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('language-picker-scroll')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('achievements switch between one list and an icon-only grid',
      (tester) async {
    final game = await pumpGame(tester, onboarded: true, hatched: true);
    game.unlockedAchievementIds.add(achievementCatalog.first.id);
    game.notifyListeners();
    final shellContext = tester.element(find.byType(Scaffold).first);
    Navigator.of(shellContext).push(MaterialPageRoute<void>(
      builder: (_) => const AchievementsScreen(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(find.text('Starter'), findsNothing);
    expect(find.text('Easy'), findsNothing);
    expect(find.text('Challenging'), findsNothing);
    expect(find.text('Master'), findsNothing);
    expect(find.byType(AchievementBadgeSprite), findsWidgets);
    final lockedSprite =
        find.byKey(Key('achievement-sprite-${achievementCatalog[1].id}'));
    expect(
      find.ancestor(of: lockedSprite, matching: find.byType(ColorFiltered)),
      findsOneWidget,
    );
    expect(
      find.byKey(Key('achievement-zoom-${achievementCatalog[1].id}')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(Key('achievement-zoom-${achievementCatalog.first.id}')),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const Key('achievement-zoom-dialog')), findsOneWidget);
    expect(find.byKey(const Key('achievement-zoom-image')), findsOneWidget);
    await tester.tap(find.byKey(const Key('achievement-zoom-image')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const Key('achievement-zoom-dialog')), findsNothing);

    await tester.tap(find.byKey(const Key('achievements-view-toggle')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(game.achievementsCompact, isTrue);
    expect(find.byKey(const Key('achievements-compact-grid')), findsOneWidget);
    expect(find.byType(AchievementBadgeSprite),
        findsNWidgets(achievementCatalog.length));
    expect(find.text('Hello, Little One!'), findsNothing);

    await tester.tap(find.byKey(const Key('achievements-view-toggle')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(game.achievementsCompact, isFalse);
    expect(find.text('Hello, Little One!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('achievement reveal fits a compact large-text phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 1.35;
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    late BuildContext revealContext;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        revealContext = context;
        return const Scaffold();
      }),
    ));

    final reveal = showAchievementReveal(revealContext, achievementCatalog[4]);
    final revealFinder = find.byKey(
      Key('achievement-reveal-${achievementCatalog[4].id}'),
    );
    for (var frame = 0;
        frame < 30 && revealFinder.evaluate().isEmpty;
        frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(revealFinder, findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(revealFinder);
    for (var frame = 0; frame < 15; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await reveal;
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the logo opens the complete About panel',
      (tester) async {
    await pumpGame(tester, onboarded: true);
    await tester.tap(find.byKey(const Key('app-logo-about-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('About DragonHaven'), findsOneWidget);
    expect(find.text('Rick Groot'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('v0.04.06'), findsOneWidget);
    expect(find.byKey(const Key('about-copy-download-link')), findsOneWidget);
    expect(find.byKey(const Key('about-download-update')), findsOneWidget);
    expect(find.byKey(const Key('about-buy-me-coffee')), findsOneWidget);
    expect(find.text('Event codes use capital letters without spaces.'),
        findsNothing);
    expect(find.textContaining('currently stay on this device'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the About handle stays pinned while its content scrolls',
      (tester) async {
    await pumpGame(tester, onboarded: true);
    await tester.tap(find.byKey(const Key('app-logo-about-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final handle = find.byKey(const Key('about-drag-handle'));
    final initialTop = tester.getTopLeft(handle).dy;
    await tester.drag(
        find.byKey(const Key('about-scroll')), const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.getTopLeft(handle).dy, closeTo(initialTop, 0.1));
    expect(find.byKey(const Key('about-scroll')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pulling past the top dismisses the About sheet', (tester) async {
    await pumpGame(tester, onboarded: true);
    await tester.tap(find.byKey(const Key('app-logo-about-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.drag(
        find.byKey(const Key('about-scroll')), const Offset(0, 180));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('about-drag-handle')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
