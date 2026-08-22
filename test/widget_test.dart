import 'dart:math';

import 'package:dragon_haven/dragonhaven_app.dart';
import 'package:dragon_haven/l10n/app_strings.dart';
import 'package:dragon_haven/models/achievement.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/dragon_egg.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/achievements_screen.dart';
import 'package:dragon_haven/screens/draconomicon_screen.dart';
import 'package:dragon_haven/widgets/achievement_badge_sprite.dart';
import 'package:dragon_haven/widgets/dragon_art.dart';
import 'package:flutter/material.dart';
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
        '中文',
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
        ..name = 'Ember';
    }
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: game,
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
    expect(find.byKey(const Key('egg-hatch-countdown')), findsOneWidget);
    expect(
      find.byKey(const Key('egg-hatch-countdown-value')),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('mysterious-egg-hint')));
    await tester.pump();
    expect(find.text(game.eggHint(isDutch: false)), findsOneWidget);
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
    await tester.tap(find.byKey(const Key('app-menu-account')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const Key('music-switch')), findsOneWidget);
    expect(find.byKey(const Key('sound-effects-switch')), findsOneWidget);
    await tester.tap(find.byKey(const Key('music-switch')));
    await tester.pump();
    expect(game.musicEnabled, isFalse);
    expect(game.soundEffectsEnabled, isTrue);
    await tester.tap(find.byKey(const Key('sound-effects-switch')));
    await tester.pump();
    expect(game.musicEnabled, isFalse);
    expect(game.soundEffectsEnabled, isFalse);
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
      ['Adventure', 'Stash', 'Tower', 'Friends', 'Shop'],
    );
    final towerRoof = find.byKey(const Key('tower-roof'));
    final openCodex = find.byKey(const Key('open-draconomicon'));
    expect(tester.getTopLeft(openCodex).dy,
        lessThan(tester.getTopLeft(towerRoof).dy));
    expect(
      find.descendant(of: towerRoof, matching: find.byType(DragonArt)),
      findsNothing,
    );

    await tester.tap(find.text('Adventure').last);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Short Adventures'), findsOneWidget);
    final adventureList = find.descendant(
      of: find.byKey(const PageStorageKey('available-adventures-scroll')),
      matching: find.byType(Scrollable),
    );
    for (final heading in const [
      'Long Adventures',
      'Group Adventures',
      'Special Adventures',
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
    await tester.tap(find.text('My dragons'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(Key('dragon-roaming-${game.pet.id}')), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Friends').last);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const PageStorageKey('friends-scroll')), findsOneWidget);

    await tester.tap(find.text('Stash').last);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Eggs'), findsOneWidget);
    expect(find.text('Chests'), findsOneWidget);
    expect(find.text('Furniture'), findsOneWidget);

    await tester.tap(find.text('Shop').last);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Coin furniture'), findsOneWidget);
    expect(find.text('Gem furniture'), findsOneWidget);
    expect(find.text('Buy gems'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('earned chests appear and open only from Stash', (tester) async {
    final game = await pumpGame(tester, onboarded: true, hatched: true);
    game.chestInventory[ChestTier.wooden] = 1;
    game.notifyListeners();
    await tester.pump();

    await tester.tap(find.text('Adventure').last);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const PageStorageKey('unopened-chests-scroll')),
        findsNothing);

    await tester.tap(find.text('Stash').last);
    await tester.pumpAndSettle();
    expect(game.chestCount(ChestTier.wooden), 1);
    await tester.tap(find.text('Chests'));
    await tester.pumpAndSettle();

    final openChest = find.byKey(const Key('stash-open-chest-wooden'));
    expect(openChest, findsOneWidget);
    await tester.tap(openChest);
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(game.chestCount(ChestTier.wooden), 0);
    expect(find.byKey(const Key('chest-rewards')), findsOneWidget);
    expect(find.text('Collect'), findsNothing);
    expect(find.text('Tap the chest'), findsNothing);
    expect(game.chestCount(ChestTier.wooden), 0);
    await tester.tap(find.byKey(const Key('chest-rewards')));
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

    await tester.tap(find.byKey(const Key('rooftop-nest-scene')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('nest-egg-picker')), findsOneWidget);
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
    expect(find.text('One hidden dragon is growing beneath the shell.'),
        findsOneWidget);
    expect(find.byKey(const Key('nest-egg-hatch-countdown')), findsOneWidget);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Adventure'), findsWidgets);
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
    await tester.pump();

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

  testWidgets('tapping the logo opens the complete About panel',
      (tester) async {
    await pumpGame(tester, onboarded: true);
    await tester.tap(find.byKey(const Key('app-logo-about-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('About DragonHaven'), findsOneWidget);
    expect(find.text('Rick Groot'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('v0.00.13'), findsOneWidget);
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
