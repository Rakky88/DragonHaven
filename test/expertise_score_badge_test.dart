import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/widgets/expertise_score_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MAX follows the dragon-specific expertise maximum',
      (tester) async {
    Future<void> pumpScore(int score) => tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ExpertiseScoreBadge(
              dragonId: 'specialist',
              focus: TrainingFocus.arcana,
              focusLabel: 'Arcana',
              score: score,
              maximum: 350,
            ),
          ),
        ));

    await pumpScore(300);
    expect(
      find.byKey(const Key('expertise-max-specialist-arcana')),
      findsNothing,
    );

    await pumpScore(350);
    expect(
      find.byKey(const Key('expertise-max-specialist-arcana')),
      findsOneWidget,
    );
  });
}
