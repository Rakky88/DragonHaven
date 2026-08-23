import 'dart:math';

import 'package:dragon_haven/models/game_presentation.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/pet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('evolution builds suspense and the hidden target skips to reveal',
      (tester) async {
    final now = DateTime.utc(2026, 8, 23, 15);
    final game = HouseholdProvider(
      random: Random(104),
      clock: () => now,
      persistenceEnabled: false,
    );
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Ember'
      ..xp = Pet.wyrmlingXp;
    expect(await game.evolveActiveDragon(), isTrue);
    final presentation = game.orderedPendingPresentations.firstWhere(
      (item) => item.type == GamePresentationType.evolution,
    );

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          key: const Key('open-evolution-presentation'),
          onPressed: () => showEvolutionMilestonePresentation(
            context,
            game,
            presentation,
          ),
          child: const Text('Open evolution'),
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('open-evolution-presentation')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('A new form is awakening…'), findsOneWidget);
    expect(find.byKey(const Key('skip-evolution-animation')), findsOneWidget);
    expect(find.text('A new form awakens!'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('A new form awakens!'), findsNothing,
        reason:
            'The natural reveal should retain several seconds of suspense.');

    await tester.tap(find.byKey(const Key('skip-evolution-animation')));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('A new form awakens!'), findsOneWidget);
    expect(find.text('Wyrmling'), findsOneWidget);
    expect(find.byKey(const Key('skip-evolution-animation')), findsNothing);

    await tester.tap(find.text('Welcome'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
