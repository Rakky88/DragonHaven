import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/screens/adventure_hub_screen.dart';
import 'package:dragon_haven/screens/dragon_tower_screen.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('an existing floor has a usable free room picker with no gold',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = HouseholdProvider(persistenceEnabled: false);
    game.pet
      ..stage = DragonStage.hatchling
      ..coins = 0;
    game.towerFloorRoomIds = List.filled(20, 'hearth');
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: game,
        child: const MaterialApp(home: Scaffold(body: DragonTowerScreen()))));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('change-tower-room-19')));
    await tester.tap(find.byKey(const Key('change-tower-room-19')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sunforge'), 250,
        scrollable: find.descendant(
            of: find.byKey(const Key('tower-room-picker-scroll')),
            matching: find.byType(Scrollable)));
    await tester.tap(find.text('Sunforge'));
    await tester.pumpAndSettle();
    expect(game.towerFloorRoomIds.last, 'sunforge');
    expect(game.pet.coins, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    game.dispose();
  });

  testWidgets(
      'creator cancels a legacy Valentine test invite and frees the dragon',
      (tester) async {
    final game = HouseholdProvider(persistenceEnabled: false);
    game.pet
      ..stage = DragonStage.hatchling
      ..activeAdventureId = 'online-seasonal:old-test';
    final repository = _PairRepository(game.pet.id);
    final online = OnlineAccountProvider(
        repository: repository,
        inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
        synchronizeSeasonalPairReservations:
            game.synchronizeOnlineSeasonalPairReservations)
      ..seasonalPairAdventures = repository.pairs;
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: game),
      ChangeNotifierProvider.value(value: online)
    ], child: const MaterialApp(home: Scaffold(body: AdventureHubScreen()))));
    await tester.pump(const Duration(milliseconds: 300));
    final cancel = find.byKey(const Key('cancel-seasonal-pair-old-test'));
    await tester.scrollUntilVisible(cancel, 350,
        scrollable: find.descendant(
            of: find.byKey(const PageStorageKey('available-adventures-scroll')),
            matching: find.byType(Scrollable)));
    await tester.tap(cancel);
    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.cancelled, isTrue);
    expect(online.seasonalPairAdventures, isEmpty);
    expect(game.pet.activeAdventureId, isNull);
    expect(find.byKey(const Key('seasonal-pair-old-test')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    online.dispose();
    game.dispose();
  });
}

class _PairRepository extends DisabledSocialRepository {
  _PairRepository(String dragonId)
      : pairs = [
          SeasonalPairAdventure(
              id: 'old-test',
              eventId: 'valentine_two_heartlights',
              occurrenceKey: 'preview:valentine_two_heartlights:creator',
              status: SeasonalPairAdventureStatus.invited,
              creator: keeper,
              partner: keeper,
              isCreator: true,
              myDragonId: dragonId,
              otherDragonId: null,
              createdAt: DateTime.now())
        ];
  static const keeper = KeeperProfile(
      userId: 'creator',
      keeperCode: 'DH-00000001',
      displayName: 'Keeper',
      title: 'title_001',
      portraitKey: 'portrait_001',
      discoveredDragonCount: 1,
      inventoryImported: true);
  List<SeasonalPairAdventure> pairs;
  bool cancelled = false;
  @override
  bool get isSignedIn => true;
  @override
  String get currentUserId => 'creator';
  @override
  Future<List<SeasonalPairAdventure>> loadSeasonalPairAdventures() async =>
      pairs;
  @override
  Future<void> respondSeasonalPairAdventure(
      {required String adventureId,
      required bool accept,
      String? dragonId,
      int might = 0,
      int arcana = 0,
      int spirit = 0}) async {
    expect(adventureId, 'old-test');
    expect(accept, isFalse);
    cancelled = true;
    pairs = [];
  }
}
