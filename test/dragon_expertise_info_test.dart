import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/widgets/dragon_expertise_info.dart';
import 'package:dragon_haven/widgets/expertise_score_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'expertise inspection shows all scores without selecting a dragon',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dragon = Pet(
        id: 'chosen',
        name: 'Ember',
        firstEgg: false,
        stage: DragonStage.hatchling,
        training: {
          'might': 12,
          'arcana': 28,
          'spirit': 7,
        });
    var selections = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: InkWell(
      onTap: () => selections++,
      child: DragonExpertiseInfo(dragon: dragon),
    ))));
    await tester.tap(find.byKey(const Key('dragon-expertise-info-chosen')));
    await tester.pumpAndSettle();
    expect(selections, 0);
    expect(find.text('Ember'), findsOneWidget);
    final badges = tester
        .widgetList<ExpertiseScoreBadge>(find.byType(ExpertiseScoreBadge));
    expect(badges.map((b) => b.focus), TrainingFocus.values);
    expect(badges.map((b) => b.score), [12, 28, 7]);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(selections, 0);
    expect(tester.takeException(), isNull);
  });
}
