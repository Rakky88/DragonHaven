import 'dart:async';
import 'dart:math';

import 'package:dragon_haven/dragonhaven_app.dart';
import 'package:dragon_haven/models/game_presentation.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/screens/trial_game_screen.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpApp(
    WidgetTester tester,
    HouseholdProvider game,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('nest egg hatches when its timer ends without opening the nest',
      (tester) async {
    var now = DateTime.utc(2026, 8, 29, 12);
    final game = HouseholdProvider(
      random: Random(20260829),
      clock: () => now,
      persistenceEnabled: false,
    )
      ..accountName = 'Automatic Hatch Keeper'
      ..onboardingComplete = true
      ..tutorialCompleted = true
      ..tutorialFullyViewed = true;
    game.pet.stageStartedAt =
        now.subtract(game.pet.incubationDuration - const Duration(seconds: 2));

    await pumpApp(tester, game);
    expect(game.pet.isEgg, isTrue);

    now = now.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(game.pet.stage, DragonStage.hatchling);
    expect(game.totalHatched, 1);
    expect(
      game.pendingPresentations
          .where((item) => item.type == GamePresentationType.hatch),
      hasLength(1),
    );
  });

  testWidgets('tower roof shows the remaining incubation time', (tester) async {
    final now = DateTime.now();
    final game = HouseholdProvider(
      random: Random(20260830),
      persistenceEnabled: false,
    )
      ..accountName = 'Tower Timer Keeper'
      ..onboardingComplete = true
      ..tutorialCompleted = true
      ..tutorialFullyViewed = true;
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Ember'
      ..favorite = true;
    game.incubatingEgg = Pet(
      id: 'tower-timer-egg',
      stage: DragonStage.egg,
      firstEgg: false,
      incubationMinutes: 125,
      acquiredAt: now,
      stageStartedAt: now,
      needsUpdatedAt: now,
      hatchSeed: 20260830,
    );

    await pumpApp(tester, game);

    final timer = find.byKey(const Key('tower-nest-hatch-remaining'));
    expect(timer, findsOneWidget);
    expect(
      tester.widget<Text>(timer).data,
      matches(RegExp(r'^02:0[45]:[0-5][0-9]$')),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hatch reveal starts while a regular secondary route is open',
      (tester) async {
    var now = DateTime.utc(2026, 8, 30, 15);
    final game = HouseholdProvider(
      random: Random(60606),
      clock: () => now,
      persistenceEnabled: false,
    )
      ..accountName = 'Roaming Hatch Keeper'
      ..onboardingComplete = true
      ..tutorialCompleted = true
      ..tutorialFullyViewed = true;
    game.pet.stageStartedAt =
        now.subtract(game.pet.incubationDuration - const Duration(seconds: 2));

    await pumpApp(tester, game);
    final navigator = Navigator.of(
      tester.element(find.byType(DragonHavenShell)),
    );
    unawaited(navigator.push<void>(MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Regular secondary route')),
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Regular secondary route'), findsOneWidget);

    now = now.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 2));
    for (var attempt = 0;
        attempt < 20 &&
            find.byKey(const Key('hatch-egg-tap')).evaluate().isEmpty;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(game.pet.stage, DragonStage.hatchling);
    expect(find.byKey(const Key('hatch-egg-tap')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('evolution reveal waits until an active Trial route has closed',
      (tester) async {
    final game = HouseholdProvider(
      random: Random(20260831),
      persistenceEnabled: false,
    )
      ..accountName = 'Trial Keeper'
      ..onboardingComplete = true
      ..tutorialCompleted = true
      ..tutorialFullyViewed = true;
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Moss'
      ..favorite = true;

    await pumpApp(tester, game);
    final offer = game.availableTrials.first;
    final navigator = Navigator.of(
      tester.element(find.byType(DragonHavenShell)),
    );
    game.beginPresentationDeferral();
    unawaited(navigator.push<void>(MaterialPageRoute(
      builder: (_) => TrialGameScreen(
        offerId: offer.id,
        dragonId: game.pet.id,
      ),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    game.pet.xp = Pet.wyrmlingXp;
    expect(await game.evolveActiveDragon(), isTrue);
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(TrialGameScreen), findsOneWidget);
    expect(find.byKey(const Key('evolution-frame-sequence')), findsNothing);
    expect(find.byKey(const Key('skip-evolution-animation')), findsNothing);

    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    game.endPresentationDeferral();
    for (var attempt = 0;
        attempt < 20 &&
            find
                .byKey(const Key('evolution-frame-sequence'))
                .evaluate()
                .isEmpty;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TrialGameScreen), findsNothing);
    expect(find.byKey(const Key('evolution-frame-sequence')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
