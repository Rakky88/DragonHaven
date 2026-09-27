import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/standard_trial_games.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/screens/standard_trial_game_widgets.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _offerId = 'alignment-timer-widget';
const _spirit = 300;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpGame(
    WidgetTester tester, {
    Size size = const Size(390, 800),
    double textScale = 1,
    Future<void> Function(int)? onFinished,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: SpiritAlignmentTrialGame(
        offer: TrialOffer(
          id: _offerId,
          kind: TrialKind.spiritAlignment,
          appearedAt: DateTime.utc(2026, 9, 27),
        ),
        dragon: Pet(
          id: 'alignment-dragon',
          name: 'Moss',
          firstEgg: false,
          training: const {'spirit': _spirit},
        ),
        onFinished: onFinished ?? (_) async {},
      ),
    ));
    await tester.pump();
  }

  final board = find.byKey(const Key('spirit-alignment-game'));
  final timer = find.byKey(const Key('spirit-time-remaining'));

  Finder time(String text) => find.descendant(
        of: timer,
        matching: find.text(text),
      );

  testWidgets('countdown starts on tap and finishes only when time expires',
      (tester) async {
    final scores = <int>[];
    await pumpGame(tester, onFinished: (score) async => scores.add(score));
    expect(time('01:00'), findsOneWidget);
    expect(find.textContaining('Every 100% overlap adds 5 seconds'),
        findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(time('01:00'), findsOneWidget);
    await tester.tap(board);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 999));
    expect(time('01:00'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(time('00:59'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 58999));
    expect(time('00:01'), findsOneWidget);
    expect(scores, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(time('00:00'), findsOneWidget);
    expect(find.text("Time's up!"), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750));
    expect(scores, [0]);
    await tester.tap(board);
    await tester.pump(const Duration(seconds: 1));
    expect(scores, [0]);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('three misses continue to a fourth shape without a bonus',
      (tester) async {
    var finished = false;
    await pumpGame(tester, onFinished: (_) async => finished = true);
    await tester.tap(board);
    await tester.pump();
    for (var attempt = 0; attempt < 3; attempt++) {
      await tester.tap(board);
      await tester.tap(board);
      await tester.pump();
      expect(find.text('0%'), findsOneWidget);
      expect(find.byKey(const Key('spirit-time-bonus')), findsNothing);
      await tester.pump(const Duration(milliseconds: 700));
    }
    expect(find.text('Shape 4'), findsOneWidget);
    expect(time('00:58'), findsOneWidget);
    expect(find.text('Tap to lock the height'), findsOneWidget);
    expect(finished, isFalse);
    await tester.tap(board);
    await tester.pump();
    expect(find.text('Tap to stop on the outline'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('each individual perfect shape shows its own five-second bonus',
      (tester) async {
    await pumpGame(tester);
    final model = SpiritAlignmentGame(seed: _offerId.hashCode, spirit: _spirit);
    await tester.tap(board);
    await tester.pump();
    var elapsed = 0;
    for (var attempt = 0; attempt < 2; attempt++) {
      var at = elapsed;
      while ((model.playerY - model.targetY).abs() >
          SpiritAlignmentGeometry.snapTolerance * .75) {
        model.advanceTo(++at);
      }
      await tester.pump(Duration(milliseconds: at - elapsed));
      elapsed = at;
      model.tap(at);
      await tester.tap(board);
      while ((model.playerX - model.targetX).abs() >
          SpiritAlignmentGeometry.snapTolerance * .75) {
        model.advanceTo(++at);
      }
      await tester.pump(Duration(milliseconds: at - elapsed));
      elapsed = at;
      final beforeBonus = model.remainingMs;
      model.tap(at);
      await tester.tap(board);
      await tester.pump();
      expect(model.remainingMs, beforeBonus + 5000);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('+5s'), findsOneWidget);
      final seconds = (model.remainingMs / 1000).ceil();
      expect(
        time('${(seconds ~/ 60).toString().padLeft(2, '0')}:'
            '${(seconds % 60).toString().padLeft(2, '0')}'),
        findsOneWidget,
      );
      model.advanceTo(elapsed += 700);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const Key('spirit-time-bonus')), findsNothing);
    }
    expect(find.text('Shape 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('timer and instructions fit a narrow screen with larger text',
      (tester) async {
    await pumpGame(tester, size: const Size(320, 700), textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(time('01:00'), findsOneWidget);
    await tester.tap(board);
    await tester.pump();
    expect(find.text('Shape 1'), findsOneWidget);
    final timerRect = tester.getRect(timer);
    final shapeRect =
        tester.getRect(find.byKey(const Key('spirit-shape-count')));
    expect(timerRect.right, lessThan(shapeRect.left));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
