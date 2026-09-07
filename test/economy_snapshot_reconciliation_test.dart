import 'dart:async';
import 'dart:io';

import 'package:dragon_haven/services/economy_chest_intent_store.dart';
import 'package:dragon_haven/services/economy_chest_reconciler.dart';
import 'package:dragon_haven/services/economy_inventory_snapshot.dart';
import 'package:dragon_haven/services/economy_snapshot_store.dart';
import 'package:dragon_haven/services/server_economy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'economy_inventory_snapshot_test.dart' as fixtures;

const owner = fixtures.owner;
const request = '33333333-3333-4333-8333-333333333333';
const outsider = '44444444-4444-4444-8444-444444444444';
const receipt = ChestOpeningReceipt(
    chests: [], coins: 100, gems: 5, walletRevision: 3, serverRevision: 6);

void main() {
  late Directory directory;
  late EconomySnapshotStore snapshots;
  late EconomyChestIntentStore intents;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dragonhaven-reconcile-');
    snapshots = EconomySnapshotStore(Directory('${directory.path}/snapshots'));
    intents = EconomyChestIntentStore(Directory('${directory.path}/intents'));
  });
  tearDown(() => directory.delete(recursive: true));

  test(
      'complete snapshots survive restart including multiple pages and fixed relic metadata',
      () async {
    final data = fixtures.page(
        [for (var i = 0; i < 201; i++) fixtures.chest(i), fixtures.shard(250)]);
    final snapshot = EconomyInventorySnapshot.fromCache(data);
    await snapshots.persist(snapshot);
    final restored =
        await EconomySnapshotStore(snapshots.directory).load(owner);
    expect(restored!.toJson(), snapshot.toJson());
    expect(restored.instances.last.reductionPercent, 47);
    expect(restored.instances.last.tradeable, false);
    expect(restored.instances.last.state, 'reserved');
    expect(await snapshots.load(outsider), null);
  });

  test(
      'revision fences reject stale balances, changed contents at same revision and duplicate rows',
      () async {
    await snapshots
        .persist(EconomyInventorySnapshot.fromCache(fixtures.page([])));
    await expectLater(
        snapshots.persist(
            EconomyInventorySnapshot.fromCache(fixtures.page([], revision: 6))),
        fixtures.code('economy_snapshot_stale'));
    final changed = fixtures.page([])..['coins'] = 999;
    await expectLater(
        snapshots.persist(EconomyInventorySnapshot.fromCache(changed)),
        fixtures.code('economy_snapshot_invalid'));
    expect(
        () => EconomyInventorySnapshot.fromCache(
            fixtures.page([fixtures.chest(1), fixtures.chest(1)])),
        fixtures.code('economy_snapshot_invalid'));
    expect((await snapshots.load(owner))!.coins, 321);
  });

  Future<void> prepare() => intents
      .prepare(EconomyChestIntent(
          ownerId: owner,
          requestId: request,
          chestIds: [fixtures.instanceId(1)]))
      .then((_) {});

  EconomyChestReconciler reconciler(
          {required Future<ChestOpeningReceipt> Function(EconomyChestIntent)
              open,
          required Future<void> Function(EconomyInventorySnapshot) apply,
          String? Function()? currentOwner,
          EconomySnapshotStore? store}) =>
      EconomyChestReconciler(
          intents: intents,
          snapshots: store ?? snapshots,
          reader: EconomyInventoryReader((_, __) async => fixtures.page([])),
          currentOwner: currentOwner ?? () => owner,
          open: open,
          applyToGame: apply);

  test(
      'timeout retains original intent; retry applies newer absolute snapshot before acknowledging',
      () async {
    await prepare();
    final seen = <String>[];
    final controller = reconciler(open: (intent) async {
      seen.add(intent.requestId);
      if (seen.length == 1) throw TimeoutException('synthetic lost response');
      return receipt;
    }, apply: (snapshot) async {
      expect(await intents.pending(owner), isNotNull);
      expect((await snapshots.load(owner))!.serverRevision, 7);
      expect(snapshot.coins, 321,
          reason: 'old receipt coins must never rewind or add currency');
    });
    await expectLater(
        controller.resume(owner), throwsA(isA<TimeoutException>()));
    expect(await intents.pending(owner), isNotNull);
    await controller.resume(owner);
    expect(seen, [request, request]);
    expect(await intents.pending(owner), isNull);
  });

  test(
      'failed snapshot persistence never changes game state or acknowledges the purchase',
      () async {
    await prepare();
    final blocker = File('${directory.path}/not-a-directory');
    await blocker.writeAsString('existing file');
    var applied = false;
    final controller = reconciler(
        open: (_) async => receipt,
        store: EconomySnapshotStore(Directory('${blocker.path}/snapshots')),
        apply: (_) async {
          applied = true;
        });
    await expectLater(
        controller.resume(owner), throwsA(isA<FileSystemException>()));
    expect(applied, false);
    expect((await intents.pending(owner))!.requestId, request);
  });

  test(
      'game save failure retains journal and request, and a fresh coordinator reconciles them',
      () async {
    await prepare();
    await expectLater(
        reconciler(
            open: (_) async => receipt,
            apply: (_) async =>
                throw StateError('synthetic local save failure')).resume(owner),
        throwsStateError);
    expect((await snapshots.load(owner))!.serverRevision, 7);
    expect(await intents.pending(owner), isNotNull);
    await reconciler(
            open: (intent) async {
              expect(intent.requestId, request);
              return receipt;
            },
            apply: (_) async {})
        .resume(owner);
    expect(await intents.pending(owner), isNull);
  });

  test(
      'account switch during RPC cannot apply or acknowledge the previous account result',
      () async {
    await prepare();
    var active = owner;
    final entered = Completer<void>();
    final response = Completer<ChestOpeningReceipt>();
    var applied = false;
    final controller = reconciler(
        currentOwner: () => active,
        open: (_) {
          entered.complete();
          return response.future;
        },
        apply: (_) async {
          applied = true;
        });
    final pending = controller.resume(owner);
    await entered.future;
    active = outsider;
    final assertion =
        expectLater(pending, fixtures.code('economy_account_changed'));
    response.complete(receipt);
    await assertion;
    expect(applied, false);
    expect(await intents.pending(owner), isNotNull);
    expect(await snapshots.load(owner), isNull);
  });
}
