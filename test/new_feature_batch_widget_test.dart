import 'dart:math';

import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/dragon_school.dart';
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

  testWidgets('Tower exposes fixed Rooftop ordering and the level-five School',
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
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dragon School enrolls a pupil and starts its visual lesson',
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

  testWidgets('every Dragon School lesson renders its sprite environment',
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

    await tester.tap(find.byKey(const Key('account-frame-collection')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(Key('select-frame-${supporterFrame.id}')),
    );
    await tester.pumpAndSettle();
    expect(game.selectedFrameId, supporterFrame.id);
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
