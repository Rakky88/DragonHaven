import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:dragon_haven/widgets/ascension_requirements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpRequirements(
    WidgetTester tester,
    Pet dragon, {
    bool onDark = false,
    bool compact = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 390,
              child: AscensionRequirements(
                dragon: dragon,
                onDark: onDark,
                compact: compact,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows XP and total Expertise as separate Ascension gates',
      (tester) async {
    final dragon = Pet(
      stage: DragonStage.wyrmling,
      xp: Pet.ascendedXp - 1,
      training: const {'might': 100, 'arcana': 80, 'spirit': 60},
    );

    await pumpRequirements(tester, dragon);

    expect(find.text('Ascension requirements'), findsOneWidget);
    expect(find.text('Complete both requirements before Ascension.'),
        findsOneWidget);
    expect(find.text('Level & XP'), findsOneWidget);
    expect(find.text('Level 6/7 · 1949/1950 XP'), findsOneWidget);
    expect(find.text('Minimum total Expertise'), findsOneWidget);
    expect(find.text('240/300'), findsOneWidget);
    expect(
        find.byKey(const Key('ascension-level-requirement')), findsOneWidget);
    expect(find.byKey(const Key('ascension-expertise-requirement')),
        findsOneWidget);
    expect(find.byIcon(Icons.lock_clock_rounded), findsNWidgets(2));
    expect(find.byKey(const Key('ascension-ready')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('marks only the requirement that has been completed',
      (tester) async {
    final dragon = Pet(
      stage: DragonStage.wyrmling,
      xp: Pet.ascendedXp,
      training: const {'might': 90, 'arcana': 90, 'spirit': 90},
    );

    await pumpRequirements(tester, dragon, onDark: true, compact: true);

    expect(find.text('Level 7/7 · 1950/1950 XP'), findsOneWidget);
    expect(find.text('270/300'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_clock_rounded), findsOneWidget);
    expect(find.byKey(const Key('ascension-ready')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows ready only after both Ascension gates are complete',
      (tester) async {
    final dragon = Pet(
      stage: DragonStage.wyrmling,
      xp: Pet.ascendedXp,
      training: const {'might': 100, 'arcana': 100, 'spirit': 100},
    );

    await pumpRequirements(tester, dragon);

    expect(find.text('300/300'), findsOneWidget);
    expect(find.byIcon(Icons.lock_clock_rounded), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(3));
    expect(find.byKey(const Key('ascension-ready')), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
