import 'dart:convert';

import 'package:dragon_haven/domain/game_import_preparation.dart';
import 'package:dragon_haven/domain/server_entropy.dart';
import 'package:dragon_haven/models/dragon_egg.dart';
import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

const owner = '11111111-1111-4111-8111-111111111111';
final now = DateTime.utc(2026, 9, 7, 12);
final seed = 'ab' * 32;

Map<String, dynamic> source() {
  final identities = ServerEntropy(seed, stream: 'identities');
  final game = HouseholdProvider(
      random: ServerEntropy(seed, stream: 'rewards'),
      clock: () => now,
      idGenerator: identities.uuid,
      persistenceEnabled: false);
  game.pet
    ..stage = DragonStage.hatchling
    ..firstEgg = false
    ..name = 'Mica';
  game.eggStash = [
    DragonEgg(
        id: 'existing-egg',
        lineageId: 'sinisterra',
        acquiredAt: now,
        hatchSeed: 123,
        prismatic: false)
  ];
  final state = game.exportState();
  game.dispose();
  state['eggAltar']['ownerId'] = owner;
  state['futureMetadata'] = {
    'nested': ['retained', 7]
  };
  return state;
}

Map<String, dynamic> altar() => EggAltarState(
        ownerId: owner, revision: 1, wallet: const WeaveWallet(25, 4, 1))
    .toJson();

PreparedGameImport prepare(
        Map<String, dynamic> state, Map<String, dynamic>? ledger) =>
    GameImportPreparation.prepare(
        ownerId: owner,
        source: state,
        authoritativeAltar: ledger,
        now: now,
        secretSeed: seed);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'server tags win over larger client tag revisions while discoveries survive',
      () {
    final saved = source();
    saved['eggStash'].first['altarKnowledge'] =
        const AltarEggKnowledge(tagged: false, tagRevision: 999, lineage: true)
            .toJson();
    final server = altar();
    server['eggs']['existing-egg'] =
        const AltarEggKnowledge(tagged: true, tagRevision: 2).toJson();
    final untouchedSource = jsonEncode(saved);
    final untouchedServer = jsonEncode(server);
    final result = prepare(saved, server);
    final knowledge = result.state['eggStash'].first['altarKnowledge'];
    expect(knowledge['tagged'], isTrue);
    expect(knowledge['tagRevision'], 2);
    expect(knowledge['lineage'], isTrue);
    expect(knowledge['moral'], isTrue);
    expect(result.state['eggAltar']['wallet'], server['wallet']);
    expect(result.state['futureMetadata'], saved['futureMetadata']);
    expect(result.altarRevision, 1);
    expect(result.changedAssetKinds, contains('eggAltar'));
    expect(jsonEncode(saved), untouchedSource);
    expect(jsonEncode(server), untouchedServer);
  });

  test(
      'an authoritative return removes an old stashed egg without granting a second reward',
      () {
    final saved = source();
    final server = altar();
    server['returnedIds'] = ['existing-egg'];
    final result = prepare(saved, server);
    expect(result.state['eggStash'], isEmpty);
    expect(result.state['eggAltar']['returnedIds'], ['existing-egg']);
    expect(result.state['eggAltar']['wallet'], server['wallet']);
    expect(result.state['pet']['coins'], saved['pet']['coins']);
    expect(result.state['pet']['gems'], saved['pet']['gems']);
  });

  test(
      'contradictory returned dragons and protected Special eggs require review',
      () {
    final saved = source();
    final server = altar();
    server['returnedIds'] = [saved['pet']['id']];
    expect(
        () => prepare(saved, server),
        throwsA(isA<GameImportException>().having((value) => value.code, 'code',
            'game_import_returned_dragon_conflict')));
    server['returnedIds'] = ['existing-egg'];
    saved['eggStash'].first['specialEggId'] = 'witchlight_egg_v1';
    expect(
        () => prepare(saved, server),
        throwsA(isA<GameImportException>().having((value) => value.code, 'code',
            'game_import_protected_return_conflict')));
    expect(saved['eggStash'], hasLength(1));
  });

  test(
      'missing or older authoritative Altar and unresolved operations are refused',
      () {
    final saved = source();
    expect(
        () => prepare(saved, null),
        throwsA(isA<GameImportException>().having((value) => value.code, 'code',
            'game_import_altar_snapshot_missing')));
    saved['eggAltar']['revision'] = 2;
    expect(
        () => prepare(saved, altar()),
        throwsA(isA<GameImportException>().having((value) => value.code, 'code',
            'game_import_altar_snapshot_stale')));
    saved['eggAltar']['revision'] = 0;
    saved['pendingAltarOperation'] = {'id': 'pending', 'action': 'return'};
    expect(
        () => prepare(saved, altar()),
        throwsA(isA<GameImportException>().having(
            (value) => value.code, 'code', 'game_import_pending_altar')));
  });

  test(
      'foreign owners, missing consumed history and offline stock are not silently combined',
      () {
    final saved = source();
    final server = altar();
    server['ownerId'] = '22222222-2222-4222-8222-222222222222';
    expect(
        () => prepare(saved, server),
        throwsA(isA<GameImportException>().having(
            (value) => value.code, 'code', 'game_import_foreign_altar')));
    saved['eggAltar']['returnedIds'] = ['already-consumed'];
    expect(
        () => prepare(saved, altar()),
        throwsA(isA<GameImportException>().having((value) => value.code, 'code',
            'game_import_return_history_conflict')));
    saved['eggAltar']['returnedIds'] = <String>[];
    saved['eggAltar']['ownerId'] = null;
    saved['eggAltar']['wallet']['fragments'] = 10;
    expect(
        () => prepare(saved, altar()),
        throwsA(isA<GameImportException>().having((value) => value.code, 'code',
            'game_import_offline_altar_review')));
    final offline = prepare(saved, null);
    expect(offline.state['eggAltar']['wallet']['fragments'], 10);
    expect(offline.state['eggAltar']['ownerId'], owner);
  });

  test(
      'preparation cannot silently discard unknown inventory or reroll fixed relic values',
      () {
    final saved = source();
    saved['ownedItemIds'].add('future_owned_furniture');
    expect(() => prepare(saved, altar()), throwsA(isA<FormatException>()));
    saved['ownedItemIds'].remove('future_owned_furniture');
    saved['relicInventory']['chronoshard'] = 2;
    saved['chronoshardReductions'] = [35];
    expect(() => prepare(saved, altar()), throwsA(isA<FormatException>()));
    expect(saved['chronoshardReductions'], [35]);
  });
}
