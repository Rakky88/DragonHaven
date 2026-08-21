import 'dart:math';

import 'package:dragon_haven/dragonhaven_app.dart';
import 'package:dragon_haven/models/house.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('DragonHaven Tower, rooms, dragon and Draconomicon work',
      (tester) async {
    final game = HouseholdProvider(random: Random(7))
      ..accountName = 'Rick'
      ..onboardingComplete = true;
    game.pet
      ..stage = DragonStage.ascended
      ..name = 'Ember'
      ..xp = 5000
      ..coins = 5000
      ..evolutionPath = 'spirit'
      ..addTraining(TrainingFocus.spirit, 400);
    game.discoveredForms.addAll({
      '${game.pet.lineageId}:hatchling',
      '${game.pet.lineageId}:wyrmling',
      '${game.pet.lineageId}:ascended:spirit',
    });
    game.unlockedRoomIds.addAll(houseRoomCatalog.map((room) => room.id));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: game,
      child: const DragonHavenApp(),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('DragonHaven'), findsOneWidget);

    final floor = find.byKey(const Key('tower-floor-0'));
    await tester.ensureVisible(floor);
    await tester.tap(floor);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('house-room-scene')), findsOneWidget);

    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.byKey(const Key('tower-roof')));
    await tester.tap(find.byKey(const Key('tower-roof')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Ember'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const Key('talk-to-dragon')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('talk-to-dragon')), findsOneWidget);

    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));
    final codex = find.byKey(const Key('open-draconomicon'));
    await tester.ensureVisible(codex);
    await tester.tap(codex);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('The Draconomicon'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text(game.pet.lineage.nameEn),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text(game.pet.lineage.nameEn), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
