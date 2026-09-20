import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/widgets/expertise_score_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MAX belongs to the whole dragon and hidden Spark leaves no hint',
      (tester) async {
    Future<void> show({bool maxed = false, int? spark}) =>
        tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: Column(children: [
          DragonExpertiseStatus(dragonId: 'dragon', maxed: maxed, spark: spark),
          const ExpertiseScoreBadge(
              dragonId: 'dragon',
              focus: TrainingFocus.arcana,
              focusLabel: 'Arcana',
              score: 950,
              maximum: 950),
        ]))));
    await show();
    expect(find.byKey(const Key('expertise-max-dragon')), findsNothing);
    expect(find.textContaining('Spark'), findsNothing);
    await show(maxed: true);
    expect(find.byKey(const Key('expertise-max-dragon')), findsOneWidget);
    expect(find.byKey(const Key('expertise-max-dragon-arcana')), findsNothing);
    expect(find.textContaining('Spark'), findsNothing);
    await show(maxed: true, spark: 0);
    expect(find.text('Dragon Spark: +0'), findsOneWidget);
    await show(spark: 50);
    expect(find.text('Dragon Spark: +50'), findsOneWidget);
    expect(find.byKey(const Key('expertise-max-dragon')), findsNothing);
  });
}
