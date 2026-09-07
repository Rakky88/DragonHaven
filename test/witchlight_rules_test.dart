import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/screens/seasonal_trial_game.dart';
import 'package:dragon_haven/widgets/witchlight_trial_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'preview lasts an extra second; every error flashes and third error ends the game',
      (tester) async {
    var now = DateTime(2026, 10, 26);
    SeasonalTrialRunResult? result;
    await tester.pumpWidget(MaterialApp(
        home: SeasonalTrialGame(
            offer: TrialOffer(
                id: 'witchlight',
                kind: TrialKind.witchlightWard,
                appearedAt: now),
            dragon:
                Pet(id: 'dragon', name: 'Moss', stage: DragonStage.hatchling),
            randomSeed: 5,
            clock: () => now,
            onFinished: (value) async {
              result = value;
            })));
    await tester.tap(find.byKey(const Key('start-seasonal-trial')));
    await tester.pump();
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(WitchlightPumpkin), findsNWidgets(7));
    for (var error = 1; error <= 3; error++) {
      final target = tester
          .widgetList<WitchlightPumpkin>(find.byType(WitchlightPumpkin))
          .first
          .variant;
      final wrong = List.generate(6, (i) => i).firstWhere((i) =>
          tester
              .widget<WitchlightPumpkin>(find.descendant(
                  of: find.byKey(Key('witchlight-rune-$i')),
                  matching: find.byType(WitchlightPumpkin)))
              .variant !=
          target);
      now = now.add(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(Key('witchlight-rune-$wrong')));
      await tester.pump();
      expect(find.byKey(ValueKey('witchlight-error-flash-$error')),
          findsOneWidget);
      expect(find.text('Mistakes: $error / 3'), findsOneWidget);
      if (error < 3) {
        now = now.add(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 50));
        expect(result, isNull);
      }
    }
    await tester.pump(const Duration(seconds: 1));
    expect(result, isNotNull);
    expect(result!.totalActions, 3);
    expect(result!.correctActions, 0);
    expect(find.text('Game over'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('time running out ends the game without requiring three errors',
      (tester) async {
    var now = DateTime(2026, 10, 26);
    SeasonalTrialRunResult? result;
    await tester.pumpWidget(MaterialApp(
        home: SeasonalTrialGame(
            offer: TrialOffer(
                id: 'witchlight',
                kind: TrialKind.witchlightWard,
                appearedAt: now),
            dragon:
                Pet(id: 'dragon', name: 'Moss', stage: DragonStage.hatchling),
            randomSeed: 5,
            clock: () => now,
            onFinished: (value) async {
              result = value;
            })));
    await tester.tap(find.byKey(const Key('start-seasonal-trial')));
    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 1));
    expect(result, isNotNull);
    expect(result!.totalActions, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
