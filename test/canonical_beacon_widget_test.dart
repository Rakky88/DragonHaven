import 'dart:async';
import 'dart:io';
import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/canonical_beacon.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/widgets/weave_beacon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/canonical_ui_server.dart';

const conclave = '22222222-2222-4222-8222-222222222222';

class BeaconSource implements CanonicalBeaconSource {
  BeaconSource(this.server);
  final CanonicalUiServer server;
  Completer<int>? delayed;
  @override
  Future<int> load(String owner, String conclaveId) async {
    if (delayed != null) return delayed!.future;
    return server.receipts.isEmpty ? 490 : 515;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'existing Beacon card donates once after lost reply and ignores a signed-out read',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late Directory directory;
    late CanonicalUiServer server;
    late CanonicalUiConnection connection;
    late CanonicalGameSession session;
    late BeaconSource source;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('dh-beacon-ui-');
      final game = HouseholdProvider(
          persistenceEnabled: false, clock: () => DateTime.utc(2026, 9, 10));
      game.pet
        ..stage = DragonStage.hatchling
        ..firstEgg = false
        ..favorite = true
        ..name = 'Beacon';
      game.eggAltar = EggAltarState(
          ownerId: CanonicalUiServer.owner,
          wallet: const WeaveWallet(200, 7, 2));
      server = CanonicalUiServer(game.exportState());
      game.dispose();
      server.socialContexts['donate_beacon'] = {
        'version': 1,
        'ownerId': CanonicalUiServer.owner,
        'action': 'donate_beacon',
        'sourceId': conclave,
        'fingerprint': 'ab' * 32,
        'facts': {'beforeFragments': 490, 'amount': 25, 'goal': 5000}
      };
      connection = CanonicalUiConnection(server);
      session =
          CanonicalGameSession(connection: connection, directory: directory);
      source = BeaconSource(server);
      await session.synchronize();
    });
    addTearDown(() async {
      session.dispose();
      await directory.delete(recursive: true);
    });
    Future<void> settle() async {
      for (var i = 0; i < 35; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester
            .runAsync(() => tester.pump(const Duration(milliseconds: 25)));
      }
      expect(tester.takeException(), isNull);
    }

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.runAsync(() => tester.tap(finder));
      await settle();
    }

    await tester.runAsync(() => tester.pumpWidget(MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: session),
              Provider<CanonicalBeaconSource>.value(value: source)
            ],
            child: const MaterialApp(
                home: Scaffold(
                    body: SingleChildScrollView(
                        child: WeaveBeaconCard(
                            conclaveId: conclave, active: true)))))));
    await settle();
    expect(find.text('490 / 5000'), findsOneWidget);
    await tap(find.byKey(const Key('weave-beacon-project')));
    await tap(find.byKey(const Key('donate-weave-fragments')));
    server.loseReply = true;
    await tap(find.byKey(const Key('confirm-beacon-donation')));
    expect(session.canAct, isFalse);
    expect(server.state['eggAltar']['wallet']['fragments'], 175,
        reason:
            'busy=${session.busy}; error=${session.errorCode}; requests=${server.sent.length}; receipts=${server.receipts.values.map((r) => r["error"]).toList()}');
    await tester.runAsync(() async {
      expect((await session.synchronize())?.replayed, isTrue);
    });
    await settle();
    expect(session.snapshot!.inventory.materials.fragments, 175);
    expect(find.text('515 / 5000'), findsOneWidget);
    expect(server.receipts.length, 1);
    source.delayed = Completer<int>();
    await tap(find.byKey(const Key('weave-beacon-project')));
    await tap(find.byKey(const Key('weave-beacon-project')));
    connection.signOut();
    await tester.pump();
    source.delayed!.complete(999);
    await settle();
    expect(find.text('999 / 5000'), findsNothing);
    expect(find.text('515 / 5000'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
