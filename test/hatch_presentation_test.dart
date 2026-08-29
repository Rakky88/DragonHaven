import 'dart:math';

import 'package:dragon_haven/models/game_presentation.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/pet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('elapsed countdown invokes its hatch callback only once',
      (tester) async {
    final egg = Pet(
      id: 'ready-egg',
      stageStartedAt: DateTime.now().subtract(const Duration(hours: 25)),
    );
    var callbacks = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EggHatchCountdown(
          pet: egg,
          onElapsed: () => callbacks++,
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(callbacks, 1);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(callbacks, 1);
  });

  testWidgets('hatch starts automatically and closes cleanly after naming',
      (tester) async {
    final now = DateTime.utc(2026, 8, 22, 12);
    final game = HouseholdProvider(
      random: Random(37),
      clock: () => now,
      persistenceEnabled: false,
    );
    game.pet.stageStartedAt = now.subtract(const Duration(hours: 24));
    expect(await game.hatchActiveDragon(), isTrue);
    final presentation = game.orderedPendingPresentations.firstWhere(
      (item) => item.type == GamePresentationType.hatch,
    );

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          key: const Key('open-hatch-presentation'),
          onPressed: () => showHatchMilestonePresentation(
            context,
            game,
            presentation,
          ),
          child: const Text('Open hatch'),
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('open-hatch-presentation')));
    await tester.pump();

    expect(find.byKey(const Key('hatch-egg-tap')), findsOneWidget);
    expect(find.text('The shell is trembling...'), findsNothing);
    expect(find.text('Tap the egg once to begin hatching'), findsNothing);
    expect(find.byKey(const Key('hatchling-reveal')), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('CRACK'), findsNothing);
    expect(find.byKey(const Key('egg-crack-sprite')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 5200));
    expect(find.byKey(const Key('hatchling-reveal')), findsOneWidget);
    expect(find.text('Choose a name'), findsOneWidget);

    await tester.tap(find.byKey(const Key('choose-dragon-name')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'Nova');
    await tester.tap(find.text('Keep this name'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(game.pet.name, 'Nova');
    expect(find.byKey(const Key('hatchling-reveal')), findsNothing);
  });
}
