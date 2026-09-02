import 'dart:math';

import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/dragon_school.dart';
import 'package:dragon_haven/models/dragon_emote.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/supporter_pack.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/screens/adventure_hub_screen.dart';
import 'package:dragon_haven/screens/account_screen.dart';
import 'package:dragon_haven/screens/dragon_school_screen.dart';
import 'package:dragon_haven/screens/dragon_tower_screen.dart';
import 'package:dragon_haven/screens/keeper_journal_screen.dart';
import 'package:dragon_haven/screens/shop_hub_screen.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:dragon_haven/widgets/furniture_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tower exposes fixed Rooftop ordering and the level-five Academy',
      (tester) async {
    final game = HouseholdProvider.createReleaseDemo()
      ..towerFloorRoomIds = [
        'hearth',
        'crystal',
        'garden',
        'tidal_library',
        'loft',
      ];
    addTearDown(game.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: game,
      child: const MaterialApp(home: Scaffold(body: DragonTowerScreen())),
    ));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('reorder-tower-rooms')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('fixed-rooftop-room')), findsOneWidget);
    expect(find.byKey(const Key('tower-room-order-list')), findsOneWidget);
    Navigator.of(tester.element(find.byKey(const Key('fixed-rooftop-room'))))
        .pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.scrollUntilVisible(
      find.byKey(const Key('dragon-school-entrance')),
      450,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('dragon-tower-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.drag(
      find.descendant(
        of: find.byKey(const PageStorageKey('dragon-tower-scroll')),
        matching: find.byType(Scrollable),
      ),
      const Offset(0, -140),
    );
    await tester.pump();
    expect(find.byKey(const Key('dragon-school-entrance')), findsOneWidget);

    await tester.tap(find.byKey(const Key('dragon-school-entrance')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(DragonSchoolScreen), findsOneWidget);
    expect(find.byKey(const Key('dragon-school-games')), findsOneWidget);
    expect(dragonSchoolGames, hasLength(10));
    expect(
        find.byKey(const Key('dragon-school-game-runeRush')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('dragon-school-game-constellationTrace')),
      350,
      scrollable: find.descendant(
        of: find.byKey(const Key('dragon-school-games')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(const Key('dragon-school-game-constellationTrace')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Trial streak and group offer separate requirements and rewards',
      (tester) async {
    final now = DateTime(2026, 8, 30, 12);
    final game = HouseholdProvider(
      random: Random(940),
      clock: () => now,
      persistenceEnabled: false,
    )
      ..onboardingComplete = true
      ..trialStreakCount = 3
      ..trialStreakLastDayKey = '2026-08-30';
    game.pet
      ..stage = DragonStage.hatchling
      ..firstEgg = false;
    final online = OnlineAccountProvider(
      repository: const _SignedInSocialRepository(),
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    addTearDown(game.dispose);
    addTearDown(online.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider.value(value: online),
      ],
      child: const MaterialApp(home: Scaffold(body: AdventureHubScreen())),
    ));
    await tester.pump(const Duration(milliseconds: 500));

    final group = game.adventuresFor(AdventureKind.group).first;
    final groupOffer = find.byKey(Key('group-offer-${group.id}'));
    final availableList =
        find.byKey(const PageStorageKey('available-adventures-scroll'));
    expect(availableList, findsOneWidget);
    for (var attempt = 0;
        attempt < 10 && groupOffer.evaluate().isEmpty;
        attempt++) {
      await tester.drag(availableList, const Offset(0, -400));
      await tester.pump();
    }
    expect(groupOffer, findsOneWidget);
    await tester.tap(groupOffer);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('group-adventure-requirements')), findsOneWidget);
    expect(
        find.byKey(const Key('group-offer-expected-rewards')), findsOneWidget);
    Navigator.of(tester
            .element(find.byKey(const Key('group-adventure-requirements'))))
        .pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('adventure-tab-trials')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trial-streak-card')), findsOneWidget);
    for (var day = 1; day <= 7; day++) {
      expect(find.byKey(Key('trial-streak-day-$day')), findsOneWidget);
    }
    final constellationSprites = find.descendant(
      of: find.byKey(const Key('trial-streak-card')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.endsWith(
                  'trial_constellation_node.png',
                ),
      ),
    );
    expect(constellationSprites, findsNWidgets(7));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Special Event counts down and keeps its sealed rewards concise',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var now = DateTime.utc(2026, 8, 31, 22);
    final game = HouseholdProvider(
      random: Random(269),
      clock: () => now,
      persistenceEnabled: false,
    )
      ..onboardingComplete = true
      ..pet.stage = DragonStage.hatchling;
    final online = OnlineAccountProvider(
      repository: const DisabledSocialRepository(),
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    addTearDown(game.dispose);
    addTearDown(online.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider.value(value: online),
      ],
      child: const MaterialApp(home: Scaffold(body: AdventureHubScreen())),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    final adventure = game.adventuresFor(AdventureKind.special).single;
    final card = find.byKey(Key('adventure-card-${adventure.id}'));
    final list = find.byKey(
      const PageStorageKey('available-adventures-scroll'),
    );
    for (var attempt = 0; attempt < 12 && card.evaluate().isEmpty; attempt++) {
      await tester.drag(list, const Offset(0, -420));
      await tester.pump();
    }
    expect(card, findsOneWidget);
    expect(tester.takeException(), isNull);
    final compactCountdown = find.byKey(
      const Key('special-event-availability-countdown-compact'),
    );
    expect(compactCountdown, findsOneWidget);
    final countdownText = find.descendant(
      of: compactCountdown,
      matching: find.byType(Text),
    );
    final beforeTick = tester
        .widgetList<Text>(countdownText)
        .map((text) => text.data)
        .whereType<String>()
        .join(' ');
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final afterTick = tester
        .widgetList<Text>(countdownText)
        .map((text) => text.data)
        .whereType<String>()
        .join(' ');
    expect(afterTick, isNot(beforeTick));
    expect(tester.takeException(), isNull);

    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      find.byKey(const Key('special-event-availability-countdown-detail')),
      findsOneWidget,
    );
    final event = specialAdventureEventCatalog.single;
    expect(find.text(event.storyEn), findsNothing);
    expect(find.text(adventure.descriptionEn), findsNothing);
    expect(find.text('+25 Might'), findsOneWidget);
    expect(find.text('+25 Spirit'), findsOneWidget);
    expect(find.text('+25 Arcana'), findsOneWidget);
    expect(find.text('1 Special Chest'), findsOneWidget);
    expect(find.text('1 random relic'), findsOneWidget);
    expect(find.text('1 Music Chest'), findsOneWidget);
    expect(find.textContaining('269 coins'), findsNothing);
    expect(find.textContaining('event dragon'), findsNothing);
    expect(find.textContaining('rolled only'), findsNothing);
    expect(find.textContaining('surprise until'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dragon Academy enrolls a pupil and starts its visual lesson',
      (tester) async {
    final game = HouseholdProvider.createReleaseDemo()
      ..towerFloorRoomIds = List.filled(5, 'hearth');
    addTearDown(game.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: game,
      child: const MaterialApp(home: DragonSchoolScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('dragon-school-game-runeRush')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(Key('school-pupil-${game.pet.id}')), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-school-dragons')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byType(DragonSchoolGameScreen), findsOneWidget);
    expect(find.byKey(const Key('school-session-runeRush')), findsOneWidget);
    expect(find.byKey(const Key('school-background-runeRush')), findsOneWidget);

    await tester.tap(find.byKey(const Key('start-school-game')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('school-rune-rush-target')), findsOneWidget);
    await tester.tap(find.byKey(const Key('school-rune-rush-target')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('1'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dragon Academy offers passing pupils early graduation',
      (tester) async {
    final game = HouseholdProvider(
      random: Random(934),
      persistenceEnabled: false,
    )
      ..towerFloorRoomIds = List.filled(5, 'hearth')
      ..pet.stage = DragonStage.hatchling
      ..pet.firstEgg = false;
    for (var index = 0; index < dragonSchoolGames.length; index++) {
      final lesson = dragonSchoolGames[index];
      game.pet.dragonSchoolAttempts[lesson.id] = 1;
      game.pet.dragonSchoolStars[lesson.id] = index < 5 ? 2 : 1;
    }
    addTearDown(game.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: game,
      child: const MaterialApp(home: DragonSchoolScreen()),
    ));
    await tester.pump();

    final graduateButton = find.byKey(Key('graduate-academy-${game.pet.id}'));
    expect(graduateButton, findsOneWidget);
    await tester.tap(graduateButton);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.widgetWithText(FilledButton, 'Graduate'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(game.pet.dragonSchoolComplete, isTrue);
    expect(game.pet.dragonSchoolAttemptTotal, dragonSchoolLessonCount);
    expect(graduateButton, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Dragon Academy holds a dropout reveal until the final report is visible',
      (tester) async {
    final game = HouseholdProvider(
      random: Random(935),
      persistenceEnabled: false,
    )
      ..towerFloorRoomIds = List.filled(5, 'hearth')
      ..pet.stage = DragonStage.hatchling
      ..pet.firstEgg = false;
    for (final lesson in dragonSchoolGames) {
      game.pet.dragonSchoolAttempts[lesson.id] =
          lesson.id == 'runeRush' ? 2 : dragonSchoolAttemptsPerLesson;
      game.pet.dragonSchoolStars[lesson.id] = 1;
    }
    addTearDown(game.dispose);

    bool? deferredWhenDropoutQueued;
    game.addListener(() {
      if (game.pendingPresentations.any(
        (presentation) => presentation.achievementId == 'dragon_school_dropout',
      )) {
        deferredWhenDropoutQueued ??= game.presentationsDeferred;
      }
    });

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: game,
      child: MaterialApp(
        home: DragonSchoolGameScreen(
          definition: dragonSchoolGames.firstWhere(
            (lesson) => lesson.id == 'runeRush',
          ),
          dragonIds: [game.pet.id],
          lessonDuration: Duration.zero,
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('start-school-game')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(game.pet.dragonSchoolOutcome, DragonSchoolOutcome.dropout);
    expect(deferredWhenDropoutQueued, isTrue);
    expect(game.presentationsDeferred, isTrue);
    expect(find.text('Lesson complete'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(game.presentationsDeferred, isFalse);
    expect(
      game.pendingPresentations.where(
        (presentation) => presentation.achievementId == 'dragon_school_dropout',
      ),
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('every Dragon Academy lesson renders its sprite environment',
      (tester) async {
    final game = HouseholdProvider.createReleaseDemo()
      ..towerFloorRoomIds = List.filled(5, 'hearth');
    addTearDown(game.dispose);
    final availableIds = game.ownedDragons.map((dragon) => dragon.id).toList();

    for (final definition in dragonSchoolGames) {
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: game,
        child: MaterialApp(
          home: DragonSchoolGameScreen(
            key: ValueKey(definition.id),
            definition: definition,
            dragonIds: availableIds.take(definition.minimumDragons).toList(),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        find.byKey(Key('school-background-${definition.id}')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('start-school-game')));
      await tester.pump(const Duration(milliseconds: 120));
      if (definition.kind == DragonSchoolGameKind.sigilMemory) {
        expect(find.byKey(const Key('school-sigil-preview')), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 850));
        expect(find.byKey(const Key('school-sigil-grid')), findsOneWidget);
      }
      if (definition.kind == DragonSchoolGameKind.shadowMatch) {
        expect(find.byKey(const Key('school-shadow-grid')), findsOneWidget);
      }
      expect(tester.takeException(), isNull, reason: definition.id);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Keeper Journal and Packs shop render their new collections',
      (tester) async {
    final game = HouseholdProvider.createReleaseDemo();
    addTearDown(game.dispose);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: game,
      child: const MaterialApp(home: KeeperJournalScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('keeper-journal-header')), findsOneWidget);
    expect(find.byKey(const Key('journal-filter-all')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: game,
      child: const MaterialApp(
        home: Scaffold(body: ShopHubScreen(initialCurrencyTab: 2)),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('shop-tab-packs')), findsOneWidget);
    expect(find.textContaining('2,99'), findsOneWidget);
    expect(find.byKey(const Key('buy-supporter-pack')), findsOneWidget);
    await tester
        .tap(find.byKey(const Key('supporter-pack-everything-included')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Complete supporter furniture set'),
      350,
      scrollable: find
          .byWidgetPredicate((widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down)
          .first,
    );
    expect(find.byType(FurnitureArt), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Packs shop presents three exclusive ten-emote collections',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = HouseholdProvider(
      random: Random(944),
      persistenceEnabled: false,
    );
    final ownedPack = dragonEmotePacks.first;
    await game.applyVerifiedDragonEmotePack(
      internalProductId: ownedPack.internalProductId,
      serverTransactionId: 'widget-emote-pack',
    );
    addTearDown(game.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: game,
      child: const MaterialApp(
        home: Scaffold(body: ShopHubScreen(initialCurrencyTab: 2)),
      ),
    ));
    await tester.pumpAndSettle();

    final scrollable = find.descendant(
      of: find.byKey(const Key('packs-shop-scroll')),
      matching: find.byType(Scrollable),
    );
    expect(dragonEmotePacks, hasLength(3));
    for (final pack in dragonEmotePacks) {
      await tester.scrollUntilVisible(
        find.byKey(Key('dragon-emote-pack-${pack.id}')),
        300,
        scrollable: scrollable,
      );
      expect(
        find.byKey(Key('buy-dragon-emote-pack-${pack.id}')),
        findsOneWidget,
      );
      expect(pack.emotes, hasLength(10));
    }

    await tester.ensureVisible(
      find.byKey(Key('expand-dragon-emote-pack-${ownedPack.id}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(Key('expand-dragon-emote-pack-${ownedPack.id}')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(Key('dragon-emote-pack-grid-${ownedPack.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'owned Supporter Pack stays finite after leaving and reopening Packs',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = HouseholdProvider(
      random: Random(940),
      persistenceEnabled: false,
    );
    await game.applyVerifiedSupporterPack('packs-revisit-regression');
    addTearDown(game.dispose);
    final bucket = PageStorageBucket();

    Widget buildApp({required bool showShop}) => ChangeNotifierProvider.value(
          value: game,
          child: MaterialApp(
            home: PageStorage(
              bucket: bucket,
              child: Scaffold(
                body: showShop
                    ? const ShopHubScreen(initialCurrencyTab: 2)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        );

    Finder packsScrollable() => find.descendant(
          of: find.byKey(const Key('packs-shop-scroll')),
          matching: find.byType(Scrollable),
        );

    await tester.pumpWidget(buildApp(showShop: true));
    await tester.pumpAndSettle();
    expect(find.text('OWNED'), findsOneWidget);
    await tester
        .tap(find.byKey(const Key('supporter-pack-everything-included')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Complete supporter furniture set'),
      300,
      scrollable: packsScrollable(),
    );
    var position = tester.state<ScrollableState>(packsScrollable()).position;
    expect(position.maxScrollExtent.isFinite, isTrue);
    expect(position.maxScrollExtent, lessThan(4000));
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();

    await tester.pumpWidget(buildApp(showShop: false));
    await tester.pump();
    await tester.pumpWidget(buildApp(showShop: true));
    await tester.pumpAndSettle();

    expect(find.text('OWNED'), findsOneWidget);
    expect(find.byKey(const Key('supporter-pack-contents')), findsNothing);
    position = tester.state<ScrollableState>(packsScrollable()).position;
    expect(position.pixels, 0);
    expect(position.maxScrollExtent.isFinite, isTrue);

    await tester
        .tap(find.byKey(const Key('supporter-pack-everything-included')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Complete supporter furniture set'),
      300,
      scrollable: packsScrollable(),
    );
    expect(find.byType(FurnitureArt), findsNWidgets(4));
    position = tester.state<ScrollableState>(packsScrollable()).position;
    expect(position.maxScrollExtent.isFinite, isTrue);
    expect(position.maxScrollExtent, lessThan(4000));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Account Vanity can select and remove a portrait frame',
      (tester) async {
    final game = HouseholdProvider(
      random: Random(941),
      persistenceEnabled: false,
    )
      ..ownedFrameIds.add(supporterFrame.id)
      ..selectedFrameId = supporterFrame.id;
    final online = OnlineAccountProvider(
      repository: const DisabledSocialRepository(),
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    addTearDown(game.dispose);
    addTearDown(online.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider.value(value: online),
      ],
      child: const MaterialApp(home: AccountScreen()),
    ));
    await tester.pump();

    expect(find.byKey(const Key('account-frame-collection')), findsOneWidget);
    expect(
      find.byKey(
        const Key('keeper-portrait-frame-frame_supporter_founder'),
      ),
      findsWidgets,
    );

    await tester.ensureVisible(
      find.byKey(const Key('account-frame-collection')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('account-frame-collection')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-frame-list')), findsOneWidget);
    await tester.tap(find.byKey(const Key('select-frame-none')));
    await tester.pumpAndSettle();
    expect(game.selectedFrameId, isNull);
    expect(
      find.byKey(
        const Key('keeper-portrait-frame-frame_supporter_founder'),
      ),
      findsNothing,
    );

    await tester.ensureVisible(
      find.byKey(const Key('account-frame-collection')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('account-frame-collection')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(Key('select-frame-${supporterFrame.id}')),
    );
    await tester.pumpAndSettle();
    expect(game.selectedFrameId, supporterFrame.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Account Vanity portrait thumbnails stay circular',
      (tester) async {
    final game = HouseholdProvider(
      random: Random(943),
      persistenceEnabled: false,
    )
      ..ownedFrameIds.add(supporterFrame.id)
      ..selectedFrameId = null;
    final online = OnlineAccountProvider(
      repository: const DisabledSocialRepository(),
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    addTearDown(game.dispose);
    addTearDown(online.dispose);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 640),
          textScaler: TextScaler.linear(1.2),
        ),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: game),
            ChangeNotifierProvider.value(value: online),
          ],
          child: const MaterialApp(home: AccountScreen()),
        ),
      ),
    );
    await tester.pump();

    void expectCircularPortrait(Key key) {
      final thumbnail = find.byKey(key);
      expect(thumbnail, findsOneWidget);
      final portraitClip = find.descendant(
        of: thumbnail,
        matching: find.byType(ClipOval),
      );
      expect(portraitClip, findsOneWidget);
      final portraitBounds = tester.getRect(portraitClip);
      expect(
        (portraitBounds.width - portraitBounds.height).abs(),
        lessThan(0.01),
      );
    }

    expectCircularPortrait(const Key('account-portrait-thumbnail'));
    await tester.ensureVisible(
      find.byKey(const Key('account-frame-thumbnail')),
    );
    await tester.pump();
    expectCircularPortrait(const Key('account-frame-thumbnail'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Account Vanity can select and remove a keeper badge',
      (tester) async {
    final game = HouseholdProvider(
      random: Random(942),
      persistenceEnabled: false,
    )
      ..ownedBadgeIds.add(supporterBadge.id)
      ..selectedBadgeId = supporterBadge.id;
    final online = OnlineAccountProvider(
      repository: const DisabledSocialRepository(),
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    addTearDown(game.dispose);
    addTearDown(online.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider.value(value: online),
      ],
      child: const MaterialApp(home: AccountScreen()),
    ));
    await tester.pump();

    expect(find.byKey(const Key('account-badge-collection')), findsOneWidget);
    expect(
      find.byKey(
        const Key('keeper-portrait-badge-badge_supporter_founder'),
      ),
      findsWidgets,
    );

    await tester.tap(find.byKey(const Key('account-badge-collection')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-badge-list')), findsOneWidget);
    await tester.tap(find.byKey(const Key('select-badge-none')));
    await tester.pumpAndSettle();
    expect(game.selectedBadgeId, isNull);

    await tester.tap(find.byKey(const Key('account-badge-collection')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(Key('select-badge-${supporterBadge.id}')),
    );
    await tester.pumpAndSettle();
    expect(game.selectedBadgeId, supporterBadge.id);
    expect(tester.takeException(), isNull);
  });
}

class _SignedInSocialRepository implements SocialRepository {
  const _SignedInSocialRepository();

  @override
  bool get isConfigured => true;

  @override
  bool get isSignedIn => true;

  @override
  bool get isEmailVerified => true;

  @override
  String? get currentEmail => 'keeper@example.test';

  @override
  String? get currentUserId => 'keeper-test';

  @override
  Stream<bool> get authStateChanges => const Stream.empty();

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
