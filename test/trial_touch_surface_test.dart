import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/seasonal_minigame.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/trial_input.dart';
import 'package:dragon_haven/screens/seasonal_trial_game.dart';
import 'package:dragon_haven/widgets/seasonal_minigames.dart';
import 'package:dragon_haven/widgets/trial_touch_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'New Year header taps and simultaneous fingers each play one lane',
      (tester) async {
    final results = <SeasonalTrialRunResult>[];
    final now = DateTime.utc(2026, 9, 20);
    await tester.pumpWidget(MaterialApp(
        home: SeasonalTrialGame(
            offer: TrialOffer(
                id: 'chimes', kind: TrialKind.midnightChime, appearedAt: now),
            dragon: Pet(stage: DragonStage.hatchling),
            randomSeed: 42,
            clock: () => now,
            onFinished: (result) async => results.add(result))));
    await tester.tap(find.byKey(const Key('start-seasonal-trial')));
    await tester.pump();
    expect(find.text('TIME'), findsNothing);
    expect(find.text('Midnight Chime'), findsOneWidget);
    Offset aboveLane(int lane) =>
        Offset(tester.getCenter(find.byKey(Key('midnight-chime-$lane'))).dx, 8);
    await tester.tapAt(aboveLane(0));
    await tester.pump();
    expect(find.text('Mistakes: 1 / 3'), findsOneWidget);
    final first = await tester.startGesture(aboveLane(1), pointer: 1);
    final second = await tester.startGesture(aboveLane(2), pointer: 2);
    await first.up();
    await second.up();
    await tester.pump(const Duration(seconds: 2));
    expect(results, hasLength(1));
    expect(results.single.totalActions, 3);
    expect(results.single.correctActions, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'birthday taps outside the game work and a child button drops only once',
      (tester) async {
    var drops = 0;
    final controls = TrialTouchControls()..dropCake = () => drops++;
    await tester.pumpWidget(MaterialApp(
        home: TrialTouchSurface(
            kind: TrialKind.wishcakeTower,
            active: true,
            controls: controls,
            child: Scaffold(
                body: Column(children: [
              const Expanded(
                  child: Center(child: Text('Header and empty space'))),
              FilledButton(
                  onPressed: () => controls.dropCake!(),
                  child: const Text('Drop')),
            ])))));
    await tester.tapAt(const Offset(10, 10));
    expect(drops, 1);
    await tester.tap(find.text('Drop'));
    expect(drops, 2);
  });

  testWidgets('Valentine swipes outside its board use the real game action',
      (tester) async {
    final inputs = <TrialInput>[];
    final controls = TrialTouchControls();
    final now = DateTime.utc(2026, 9, 20);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TrialTouchSurface(
                kind: TrialKind.rosevowRelay,
                active: true,
                controls: controls,
                child: Column(children: [
                  const SizedBox(
                      height: 100, child: Center(child: Text('Header'))),
                  Expanded(
                      child: SeasonalMinigames(
                          kind: TrialKind.rosevowRelay,
                          dragon: Pet(stage: DragonStage.hatchling),
                          seed: 4,
                          running: true,
                          clock: () => now,
                          touchControls: controls,
                          onInput: inputs.add,
                          onAction: (_,
                              {required points, required completesRound}) {})),
                ])))));
    await tester.dragFrom(const Offset(100, 30), const Offset(160, 0));
    expect(
        inputs
            .where((i) => i.control == TrialControl.moveHearts)
            .map((i) => i.a),
        [HeartDirection.right.index]);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
