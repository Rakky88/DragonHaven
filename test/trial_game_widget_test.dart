import 'dart:math';

import 'package:dragon_haven/l10n/app_strings.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/trial_game_screen.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(HouseholdProvider, TrialOffer)> pumpTrial(
    WidgetTester tester,
    TrialKind kind,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = HouseholdProvider(random: Random(824))
      ..pet = Pet(
        id: 'trial-game-dragon',
        name: 'Moss',
        stage: DragonStage.hatchling,
        firstEgg: false,
        hatchSeed: 824,
        training: const {'might': 300, 'arcana': 300, 'spirit': 300},
      );
    game.availableTrials;
    game
      ..trialOffers = [
        TrialOffer(
          id: 'widget-${kind.name}',
          kind: kind,
          appearedAt: DateTime.now(),
        ),
      ]
      ..trialRefilledAt = DateTime.now();
    final offer = game.availableTrials.firstWhere((item) => item.kind == kind);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: MaterialApp(
          theme: buildAppTheme(),
          locale: const Locale('en'),
          supportedLocales: AppStrings.supportedLanguages.keys.map(Locale.new),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: TrialGameScreen(
            offerId: offer.id,
            dragonId: game.pet.id,
          ),
        ),
      ),
    );
    await tester.pump();
    return (game, offer);
  }

  testWidgets('Cavern Flight renders smoothly and starts on tap',
      (tester) async {
    await pumpTrial(tester, TrialKind.cavernFlight);
    final game = find.byKey(const Key('cavern-flight-game'));
    expect(game, findsOneWidget);
    expect(find.text('Tap to flap'), findsOneWidget);
    await tester.tap(game);
    await tester.pump(const Duration(milliseconds: 48));
    expect(find.text('Tap to flap'), findsNothing);
    expect(find.text('RECOVERING...'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Ruin Breaker renders smoothly and starts its power meter',
      (tester) async {
    await pumpTrial(tester, TrialKind.ruinBreaker);
    final game = find.byKey(const Key('ruin-breaker-game'));
    expect(game, findsOneWidget);
    expect(find.text('Tap for the perfect hit'), findsOneWidget);
    await tester.tap(game);
    await tester.pump(const Duration(milliseconds: 48));
    expect(find.text('Tap for the perfect hit'), findsNothing);
    expect(find.text('SCORING TURNS LEFT: 30'), findsOneWidget);
    expect(find.text('Misses left: 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Runeweaver renders five runes and begins its sequence',
      (tester) async {
    await pumpTrial(tester, TrialKind.runeweaver);
    final game = find.byKey(const Key('runeweaver-game'));
    expect(game, findsOneWidget);
    expect(find.text('Tap to awaken the gate'), findsOneWidget);
    for (var rune = 0; rune < 5; rune++) {
      expect(find.byKey(Key('rune-$rune')), findsOneWidget);
    }
    await tester.tap(game);
    await tester.pump();
    expect(find.byKey(const Key('runeweaver-timer')), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Tap to awaken the gate'), findsNothing);
    expect(find.text('WATCH THE RUNES'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('finished run presents the animated grade and exact rewards',
      (tester) async {
    final (gameState, offer) = await pumpTrial(tester, TrialKind.ruinBreaker);
    final game = find.byKey(const Key('ruin-breaker-game'));
    final startingXp = gameState.pet.xp;

    await tester.tap(game); // Start.
    await tester.pump();
    for (var miss = 0; miss < 3; miss++) {
      await tester.tap(game); // The marker starts outside every success zone.
      await tester.pump(const Duration(milliseconds: 330));
      await tester.pump();
    }
    expect(find.text('SCORING TURNS LEFT: 0'), findsOneWidget);
    expect(find.text('Misses left: 0'), findsOneWidget);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const Key('ruin-power-meter-fade')),
          )
          .opacity,
      0,
    );
    expect(gameState.pet.xp, startingXp);
    expect(
        gameState.availableTrials.any((item) => item.id == offer.id), isTrue);
    await tester.pump(const Duration(milliseconds: 999));
    expect(gameState.pet.xp, startingXp,
        reason: 'The reward waits for the full meter fade.');
    expect(
        gameState.availableTrials.any((item) => item.id == offer.id), isTrue);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('trial-result-grade')), findsOneWidget);
    expect(find.byKey(const Key('trial-result-score')), findsOneWidget);
    expect(
      find.byKey(const Key('trial-result-expertise-multiplier')),
      findsNothing,
    );
    expect(find.byType(RotationTransition), findsWidgets);
    final grade = tester.widget<Image>(
      find.byKey(const Key('trial-result-grade')),
    );
    expect(
      (grade.image as AssetImage).assetName,
      'assets/images/ui/trials/grade_d.png',
    );
    expect(find.textContaining('coins'), findsNothing);
    expect(find.text('+10 XP'), findsOneWidget);
    expect(
      gameState.availableTrials.any((item) => item.id == offer.id),
      isFalse,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('trial-result-continue')));
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('wrong Arcana rune glows red for one second before reward',
      (tester) async {
    final (gameState, offer) = await pumpTrial(tester, TrialKind.runeweaver);
    final startingXp = gameState.pet.xp;
    const runeKeys = ['fire', 'water', 'moon', 'star', 'wind'];
    final correct =
        Random(offer.id.hashCode ^ gameState.pet.hatchSeed).nextInt(5);
    final wrong = (correct + 1) % 5;

    await tester.tap(find.byKey(const Key('runeweaver-game')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.byKey(Key('rune-$wrong')));
    await tester.pump();
    expect(find.byKey(Key('rune-error-${runeKeys[wrong]}')), findsOneWidget);
    expect(gameState.pet.xp, startingXp);
    expect(
        gameState.availableTrials.any((item) => item.id == offer.id), isTrue);

    await tester.pump(const Duration(milliseconds: 999));
    expect(gameState.pet.xp, startingXp);
    expect(
        gameState.availableTrials.any((item) => item.id == offer.id), isTrue);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('trial-result-score')), findsOneWidget);
    expect(
        gameState.availableTrials.any((item) => item.id == offer.id), isFalse);
    expect(gameState.pet.xp, greaterThan(startingXp));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arcana has no time limit and waits indefinitely for input',
      (tester) async {
    final (gameState, offer) = await pumpTrial(tester, TrialKind.runeweaver);
    final startingXp = gameState.pet.xp;
    await tester.tap(find.byKey(const Key('runeweaver-game')));
    await tester.pump(const Duration(minutes: 10));

    expect(find.byKey(const Key('runeweaver-timer')), findsNothing);
    expect(find.byKey(const Key('runeweaver-game')), findsOneWidget);
    expect(
      gameState.availableTrials.any((item) => item.id == offer.id),
      isTrue,
    );
    expect(gameState.pet.xp, startingXp);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Spirit crash freezes then arcs before reward', (tester) async {
    final (gameState, offer) = await pumpTrial(tester, TrialKind.cavernFlight);
    final startingXp = gameState.pet.xp;
    await tester.tap(find.byKey(const Key('cavern-flight-game')));
    await tester.pump();

    for (var frame = 0;
        frame < 140 &&
            find.byKey(const Key('cavern-crash-freeze')).evaluate().isEmpty;
        frame++) {
      await tester.pump(const Duration(milliseconds: 35));
    }
    expect(find.byKey(const Key('cavern-crash-freeze')), findsOneWidget);
    expect(gameState.pet.xp, startingXp);
    expect(
        gameState.availableTrials.any((item) => item.id == offer.id), isTrue);

    await tester.pump(const Duration(milliseconds: 249));
    expect(find.byKey(const Key('cavern-crash-freeze')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('cavern-crash-arc-active')), findsOneWidget);
    expect(gameState.pet.xp, startingXp);
    await tester.pump(const Duration(milliseconds: 899));
    expect(gameState.pet.xp, startingXp);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('trial-result-score')), findsOneWidget);
    expect(
        gameState.availableTrials.any((item) => item.id == offer.id), isFalse);
    expect(gameState.pet.xp, greaterThan(startingXp));
    expect(tester.takeException(), isNull);
  });

  testWidgets('result transition remains usable with reduced motion',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    final (gameState, offer) = await pumpTrial(tester, TrialKind.ruinBreaker);
    final game = find.byKey(const Key('ruin-breaker-game'));

    await tester.tap(game);
    await tester.pump();
    for (var miss = 0; miss < 3; miss++) {
      await tester.tap(game);
      await tester.pump(const Duration(milliseconds: 330));
    }
    await tester.pump(const Duration(seconds: 2));

    expect(find.byKey(const Key('trial-result-score')), findsOneWidget);
    expect(find.byKey(const Key('trial-result-continue')), findsOneWidget);
    expect(
      gameState.availableTrials.any((item) => item.id == offer.id),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}
