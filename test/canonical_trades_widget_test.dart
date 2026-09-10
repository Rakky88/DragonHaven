import 'dart:io';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/game_presentation.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/canonical_trades_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_trades.dart';
import 'package:dragon_haven/widgets/canonical_milestones.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/canonical_ui_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'trade picker, durable offer, exact variant reveal and account fence',
      (tester) async {
    const trade = '33333333-3333-4333-8333-333333333333';
    late Directory directory;
    late CanonicalUiServer server;
    late CanonicalUiConnection connection;
    late CanonicalGameSession session;
    await tester.binding.setSurfaceSize(const Size(390, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('dh-trade-ui-');
      final game = HouseholdProvider(
          persistenceEnabled: false, clock: () => DateTime.utc(2026, 9, 7, 12));
      game.pet
        ..stage = DragonStage.hatchling
        ..firstEgg = false
        ..favorite = true
        ..name = 'Keeper';
      game.eggAltar = EggAltarState(ownerId: CanonicalUiServer.owner);
      game.chestInventory[ChestTier.gold] = 2;
      game.relicInventory[MysticRelic.chronoshard] = 2;
      game.chronoshardReductions = [25, 60];
      game.relicInventory[MysticRelic.twinstarBrooch] = 1;
      game.untradeableRelicInventory[MysticRelic.twinstarBrooch] = 1;
      game.twinstarBroochEverObtained = true;
      game.uniqueRelicsEverObtained.add(MysticRelic.twinstarBrooch);
      server = CanonicalUiServer(game.exportState());
      game.dispose();
      connection = CanonicalUiConnection(server);
      session =
          CanonicalGameSession(connection: connection, directory: directory);
      await session.synchronize();
    });
    Future<void> settle({bool Function()? until}) async {
      final deadline = Stopwatch()..start();
      for (var i = 0;
          i < 40 ||
              ((session.busy || until != null && !until()) &&
                  deadline.elapsed.inSeconds < 15);
          i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester
            .runAsync(() => tester.pump(const Duration(milliseconds: 25)));
      }
      expect(session.busy, false, reason: session.errorCode);
      expect(tester.takeException(), isNull);
    }

    Future<void> tap(String key) async {
      final finder = find.byKey(Key(key));
      await tester.runAsync(() => tester.ensureVisible(finder));
      await tester.runAsync(() => tester.tap(finder));
      await settle();
    }

    try {
      final choices = CanonicalTradeChoice.available(session.snapshot!);
      expect(
          choices
              .where((i) => i.relic == MysticRelic.chronoshard)
              .map((i) => i.variant),
          [25, 60]);
      expect(choices.any((i) => i.relic == MysticRelic.twinstarBrooch), false);
      server.socialContexts['offer_trade'] = {
        'version': 1,
        'ownerId': CanonicalUiServer.owner,
        'action': 'offer_trade',
        'sourceId': trade,
        'fingerprint': 'ab' * 32,
        'facts': {
          'initiatorId': CanonicalUiServer.owner,
          'recipientId': '22222222-2222-4222-8222-222222222222',
          'otherOwnerId': '22222222-2222-4222-8222-222222222222',
          'beforeStatus': 'new',
          'afterStatus': 'awaiting_recipient',
          'sent': {
            'kind': 'chest',
            'key': 'gold',
            'variant': 0,
            'data': <String, dynamic>{}
          },
          'received': null
        }
      };
      await tester.runAsync(() => tester.pumpWidget(
          ChangeNotifierProvider.value(
              value: session,
              child: const MaterialApp(
                  home: Scaffold(
                      body:
                          CanonicalTradesScreen(keeperCode: 'DH-12345678'))))));
      await settle();
      await tap('canonical-offer-trade');
      // Opening details alone does not send any offer.
      await tap('canonical-trade-item-chest:gold:0');
      expect(server.sent, isEmpty);
      server.loseReply = true;
      await tap('canonical-trade-select-item');
      expect(session.canAct, false);
      expect(server.state['chestInventory']['gold'], 2);
      expect(server.state['reservedOnlineTradeChests']['gold'], 1);
      await tap('economy-reconnect');
      expect(session.canAct, true, reason: session.errorCode);
      expect(server.receipts.length, 1);
      final id = server.sent.first.requestId;
      expect(server.sent.every((intent) => intent.requestId == id), true);
      expect(server.sent.first.payload.keys,
          unorderedEquals(['keeperCode', 'kind', 'key', 'variant']));

      // A committed trade's animation uses the masked server display; closing
      // it acknowledges a presentation and grants no second item or reward.
      final coins = session.snapshot!.coins;
      server.state['pendingPresentations'] = [
        GamePresentation(
            id: 'trade-reveal-fixture',
            type: GamePresentationType.trade,
            createdAt: server.now,
            sortAt: server.now,
            payload: const {
              'sentKind': 'chest',
              'sentKey': 'gold',
              'sentData': <String, dynamic>{},
              'receivedKind': 'relic',
              'receivedKey': 'chronoshard',
              'receivedData': {'reductionPercent': 60},
            }).toJson()
      ];
      server.revision++;
      await tester.runAsync(() => session.synchronize());
      await tester.runAsync(() => tester.pumpWidget(
          ChangeNotifierProvider.value(
              value: session,
              child: const MaterialApp(
                  home: Scaffold(
                      body: CanonicalMilestones(
                          child: CanonicalTradesScreen(
                              keeperCode: 'DH-12345678')))))));
      await settle(
          until: () => find
              .byKey(const Key('trade-complete-reveal'))
              .evaluate()
              .isNotEmpty);
      expect(find.text('Chronoshard · 60%'), findsOneWidget);
      expect(find.text('Gold Chest'), findsOneWidget);
      server.loseReply = true;
      await tap('trade-reveal-continue');
      await tap('economy-reconnect');
      expect(session.snapshot!.presentations, isEmpty);
      expect(session.snapshot!.coins, coins);
      expect(server.state['relicInventory']['chronoshard'], 2);

      await tap('canonical-offer-trade');
      await tap('canonical-trade-item-relic:chronoshard:25');
      connection.signOut();
      await settle();
      expect(find.text('Chronoshard · 25%'), findsNothing);
      final select = tester.widget<FilledButton>(
          find.byKey(const Key('canonical-trade-select-item')));
      expect(select.onPressed, isNull);
    } finally {
      await tester.runAsync(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.runAsync(() async {
        session.dispose();
        await directory.delete(recursive: true);
      });
    }
  });
}
