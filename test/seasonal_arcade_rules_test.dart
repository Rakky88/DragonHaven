import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/seasonal_minigame.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/screens/seasonal_trial_game.dart';
import 'package:dragon_haven/widgets/witchlight_trial_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seasonal grades include the requested S+ boundaries exactly', () {
    for (final entry in {
      TrialKind.sunwakeSurf: [500, 1500, 3000, 5000, 8000],
      TrialKind.moonlitOrchard: [500, 1500, 3000, 5000, 8000],
      TrialKind.wishcakeTower: [600, 1500, 2800, 4200, 10000],
      TrialKind.prismaticParade: [1200, 2900, 4800, 7200, 12000],
      TrialKind.rosevowRelay: [650, 1600, 2600, 3900, 10000],
      TrialKind.midnightChime: [500, 1200, 2000, 3000, 20000],
      TrialKind.hollyfrostGiftforge: [500, 1200, 2000, 3000, 7500],
      TrialKind.witchlightWard: [500, 1200, 1600, 1800, 2000],
    }.entries) {
      expect(trialGradeForScore(entry.key, 0), TrialGrade.d);
      for (var i = 0; i < entry.value.length; i++) {
        expect(trialGradeForScore(entry.key, entry.value[i] - 1),
            TrialGrade.values[i]);
        expect(trialGradeForScore(entry.key, entry.value[i]),
            TrialGrade.values[i + 1]);
      }
      expect(trialGradeForScore(entry.key, 20000), TrialGrade.sPlus);
    }
  });

  test('arcade acceleration has playable floors and bounded expertise help',
      () {
    for (var second = 0; second < 180; second++) {
      expect(
          SeasonalArcadePacing.parcelLifetime(second + 1.0, 0),
          lessThanOrEqualTo(
              SeasonalArcadePacing.parcelLifetime(second * 1.0, 0)));
      expect(SeasonalArcadePacing.parcelInterval(second + 1.0),
          lessThanOrEqualTo(SeasonalArcadePacing.parcelInterval(second * 1.0)));
      expect(SeasonalArcadePacing.chimeBeat(second + 1.0),
          lessThanOrEqualTo(SeasonalArcadePacing.chimeBeat(second * 1.0)));
      expect(SeasonalArcadePacing.chimeTravel(second + 1.0, 0),
          lessThanOrEqualTo(SeasonalArcadePacing.chimeTravel(second * 1.0, 0)));
    }
    expect(SeasonalArcadePacing.parcelLifetime(180, -1), .95);
    expect(SeasonalArcadePacing.parcelLifetime(180, 100), closeTo(1.30, .001));
    expect(SeasonalArcadePacing.parcelInterval(0), closeTo(1.315, .00001));
    expect(SeasonalArcadePacing.parcelLifetime(0, 0), closeTo(2.65, .00001));
    expect(SeasonalArcadePacing.parcelInterval(60), lessThan(.6));
    expect(SeasonalArcadePacing.parcelInterval(180), .36);
    expect(SeasonalArcadePacing.parcelInterval(0),
        lessThan(SeasonalArcadePacing.parcelLifetime(0, 0)));
    expect(SeasonalArcadePacing.chimeBeat(180), .42);
    expect(SeasonalArcadePacing.chimeTravel(180, 0), .9);
    expect(SeasonalArcadePacing.chimeTravel(180, 100), 1.3);
    for (final seconds in [0.0, 21.9, 22.0, 45.0, 100.0]) {
      for (var phrase = 0; phrase < 4; phrase++) {
        final beats = List.generate(32,
            (beat) => SeasonalArcadePacing.chimeLanes(beat, seconds, phrase));
        expect(beats.every((b) => b.length == b.toSet().length), isTrue);
        expect(beats.expand((b) => b).every((lane) => lane >= 0 && lane < 4),
            isTrue);
        expect(
            beats.where((b) => b.length == 2).length,
            seconds < 22
                ? 0
                : seconds < 45
                    ? 8
                    : 16);
      }
    }
  });

  for (final kind in [TrialKind.hollyfrostGiftforge, TrialKind.midnightChime]) {
    testWidgets(
        '${kind.name} ends once at three mistakes and locks further input',
        (tester) async {
      var now = DateTime.utc(2026, 9, 9);
      final results = <SeasonalTrialRunResult>[];
      await tester.pumpWidget(MaterialApp(
          home: SeasonalTrialGame(
              offer: TrialOffer(id: 'three', kind: kind, appearedAt: now),
              dragon: Pet(id: 'd', stage: DragonStage.hatchling),
              randomSeed: 24,
              clock: () => now,
              onFinished: (r) async {
                results.add(r);
              })));
      await tester.tap(find.byKey(const Key('start-seasonal-trial')));
      await tester.pump(const Duration(milliseconds: 50));
      for (var error = 1; error <= 3; error++) {
        if (kind == TrialKind.hollyfrostGiftforge) {
          if (error > 1) {
            now = now.add(const Duration(milliseconds: 1350));
            await tester.pump(const Duration(milliseconds: 50));
          }
          final parcel = find.byKey(ValueKey('giftforge-parcel-${error - 1}'));
          final label = tester
              .widgetList<Semantics>(
                  find.descendant(of: parcel, matching: find.byType(Semantics)))
              .map((w) => w.properties.label)
              .whereType<String>()
              .firstWhere((label) => label.startsWith('Parcel '));
          final wrongBay = int.parse(label.split(' ').last) % 3;
          final target = find.byKey(Key('giftforge-bay-$wrongBay'));
          await tester.drag(
              parcel, tester.getCenter(target) - tester.getCenter(parcel));
          await tester.pump();
        } else {
          await tester.tap(find.byKey(Key('midnight-chime-${error - 1}')));
          await tester.pump();
        }
        expect(find.text('Mistakes: $error / 3'), findsOneWidget);
        expect(results, isEmpty);
      }
      expect(find.text('Game over'), findsOneWidget);
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(results, hasLength(1));
      expect(results.single.totalActions, 3);
      expect(results.single.correctActions, 0);
      expect(
          results.single.duration.inMilliseconds, greaterThanOrEqualTo(1000));
      now = now.add(const Duration(seconds: 20));
      await tester.pump(const Duration(seconds: 20));
      expect(results, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Christmas batches missed arrivals into exactly three mistakes',
      (tester) async {
    var now = DateTime.utc(2026, 9, 9);
    final results = <SeasonalTrialRunResult>[];
    await tester.pumpWidget(MaterialApp(
        home: SeasonalTrialGame(
            offer: TrialOffer(
                id: 'queue',
                kind: TrialKind.hollyfrostGiftforge,
                appearedAt: now),
            dragon: Pet(id: 'd', stage: DragonStage.hatchling),
            randomSeed: 24,
            clock: () => now,
            onFinished: (r) async {
              results.add(r);
            })));
    await tester.tap(find.byKey(const Key('start-seasonal-trial')));
    await tester.pump(const Duration(milliseconds: 50));
    now = now.add(const Duration(seconds: 20));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Mistakes: 3 / 3'), findsOneWidget);
    expect(find.text('Game over'), findsOneWidget);
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(results, hasLength(1));
    expect(results.single.totalActions, 3);
    expect(results.single.correctActions, 0);
    now = now.add(const Duration(seconds: 20));
    await tester.pump(const Duration(seconds: 20));
    expect(results, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Halloween loops from memory through tracing back to memory',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var now = DateTime.utc(2026, 9, 9);
    await tester.pumpWidget(MaterialApp(
        home: SeasonalTrialGame(
            offer: TrialOffer(
                id: 'two', kind: TrialKind.witchlightWard, appearedAt: now),
            dragon: Pet(id: 'd', stage: DragonStage.hatchling),
            randomSeed: 24,
            clock: () => now,
            onFinished: (_) async {})));
    await tester.tap(find.byKey(const Key('start-seasonal-trial')));
    await tester.pump();
    for (var round = 0; round < 2; round++) {
      final target = tester
          .widgetList<WitchlightPumpkin>(find.byType(WitchlightPumpkin))
          .first
          .variant;
      final choice = List.generate(6, (i) => i).firstWhere((i) =>
          tester
              .widget<WitchlightPumpkin>(find.descendant(
                  of: find.byKey(Key('witchlight-rune-$i')),
                  matching: find.byType(WitchlightPumpkin)))
              .variant ==
          target);
      now = now.add(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(Key('witchlight-rune-$choice')));
      now = now.add(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 50));
      final trace =
          tester.widget<WitchlightTracePath>(find.byType(WitchlightTracePath));
      final surface = find.byKey(const Key('witchlight-trace-surface'));
      final origin = tester.getTopLeft(surface);
      final points = WitchlightTracePath.points(tester.getSize(surface),
          seed: trace.seed, mirrored: trace.mirrored);
      final gesture = await tester.startGesture(points.first + origin);
      for (final point in points.skip(1)) {
        await gesture.moveTo(point + origin);
      }
      await gesture.up();
      now = now.add(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(WitchlightTracePath), findsNothing);
      expect(find.byKey(const Key('witchlight-rune-0')), findsOneWidget);
      expect(find.textContaining('Might ·'), findsNothing);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
