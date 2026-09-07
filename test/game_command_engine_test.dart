import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/domain/server_entropy.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/dragon_egg.dart';
import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 9, 7, 12);
final _seed = List.filled(32, 'a5').join();

Map<String, dynamic> _fixture() {
  final identities = ServerEntropy(_seed, stream: 'identities');
  final game = HouseholdProvider(
    random: ServerEntropy(_seed, stream: 'rewards'),
    clock: () => _now,
    idGenerator: identities.uuid,
    persistenceEnabled: false,
  );
  game.pet
    ..stage = DragonStage.hatchling
    ..firstEgg = false
    ..name = 'Mica'
    ..coins = 150
    ..gems = 300;
  game.chestInventory = {ChestTier.sinister: 3, ChestTier.wooden: 1};
  game.eggStash = [
    DragonEgg(
      id: 'legacy-egg-1720000000000',
      lineageId: 'sinisterra',
      acquiredAt: _now,
      hatchSeed: 123,
      prismatic: false,
      incubationMinutes: 60,
      altarKnowledge: const AltarEggKnowledge(moral: true),
    )
  ];
  game.eggAltar.wallet = const WeaveWallet(20, 2, 0);
  final result = game.exportState();
  game.dispose();
  return result;
}

Future<Map<String, dynamic>> _execute(Map<String, dynamic> state, String action,
        [Map<String, dynamic> payload = const {}, DateTime? now]) =>
    GameCommandEngine.execute(
        state: state,
        action: action,
        payload: payload,
        // Synthetic stable intent seeds. Production uses private random bytes.
        secretSeed: sha256
            .convert(utf8.encode(jsonEncode([state, action, payload])))
            .toString(),
        now: now ?? _now,
        keeperId: '11111111-1111-4111-8111-111111111111');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('secret entropy agrees with an independent HMAC vector', () {
    final random = ServerEntropy(_seed, stream: 'rewards');
    expect(List.generate(8, (_) => random.nextInt(4294967296)), [
      0x615eceeb,
      0x3bdecdaa,
      0xc3c70c98,
      0x1cd3f036,
      0x0722c31f,
      0x1364a7c5,
      0x0b5df29e,
      0xaa0cf42a,
    ]);
    expect(ServerEntropy(_seed, stream: 'identities').uuid(),
        '97fa765a-9bf2-4d59-ba8e-3473373da625');
  });

  test(
      'loading refuses missing fixed relic identities and unknown owned content',
      () async {
    final missingShard = _fixture();
    missingShard['relicInventory']['chronoshard'] = 2;
    missingShard['chronoshardReductions'] = [35];
    await expectLater(_execute(missingShard, 'purchase_title_chest'),
        throwsA(isA<FormatException>()));
    expect(missingShard['chronoshardReductions'], [35]);
    final unknownOwnedItem = _fixture();
    unknownOwnedItem['ownedItemIds'].add('future_furniture_must_not_disappear');
    await expectLater(_execute(unknownOwnedItem, 'purchase_title_chest'),
        throwsA(isA<FormatException>()));
    expect(unknownOwnedItem['ownedItemIds'],
        contains('future_furniture_must_not_disappear'));
  });

  test('loading refuses duplicate identities and silent incubation changes',
      () async {
    final duplicate = _fixture();
    duplicate['eggStash']
        .add(Map<String, dynamic>.from(duplicate['eggStash'].first));
    await expectLater(
        _execute(duplicate, 'refresh'), throwsA(isA<FormatException>()));
    final alteredTimer = _fixture();
    alteredTimer['eggStash'].first['incubationSeconds'] = 20;
    await expectLater(
        _execute(alteredTimer, 'refresh'), throwsA(isA<FormatException>()));
    expect(alteredTimer['eggStash'].first['incubationSeconds'], 20);
  });

  test('retrying private evaluation produces identical rewards and identities',
      () async {
    final state = _fixture();
    final original = jsonEncode(state);
    final first =
        await _execute(state, 'open_chests', {'tier': 'sinister', 'count': 3});
    final retry =
        await _execute(state, 'open_chests', {'tier': 'sinister', 'count': 3});
    expect(retry, first);
    expect(jsonEncode(state), original,
        reason: 'The input belongs to the transaction');
    final saved = first['state'] as Map<String, dynamic>;
    expect(saved['chestInventory']['sinister'], 0);
    expect(saved['pet']['coins'], greaterThanOrEqualTo(150 + 3 * 400));
    expect(saved['eggStash'].first['id'], 'legacy-egg-1720000000000');
  });

  test(
      'spending is bounded by the canonical wallet, including subsequent commands',
      () async {
    final purchased = await _execute(_fixture(), 'purchase_title_chest');
    expect(purchased['result'], 'purchased');
    final saved = purchased['state'] as Map<String, dynamic>;
    expect(saved['pet']['coins'], 50);
    final rejected = await _execute(saved, 'purchase_title_chest');
    expect(rejected['result'], 'insufficientCoins');
    expect(rejected['state']['pet']['coins'], 50);
    expect(rejected['state']['chestInventory']['title'], 1);
  });

  test('an unavailable batch consumes no chests and creates no eggs', () async {
    final state = _fixture();
    final rejected =
        await _execute(state, 'open_chests', {'tier': 'sinister', 'count': 4});
    expect(rejected['result'], isNull);
    expect(
        (rejected['state']['chestInventory'] as Map)
            .entries
            .where((entry) => entry.value != 0)
            .map((entry) => '${entry.key}:${entry.value}')
            .toSet(),
        {'sinister:3', 'wooden:1'});
    expect(rejected['state']['eggStash'], state['eggStash']);
    expect(rejected['state']['pet']['coins'], state['pet']['coins']);
  });

  test(
      'arbitrary grants, client scores, extra fields and oversized batches are rejected',
      () async {
    final state = _fixture();
    for (final intent in [
      ('grant_coins', {'amount': 100000}),
      ('complete_trial', {'offerId': 'x', 'score': 999999}),
      ('purchase_title_chest', {'coins': 999999}),
      ('open_chests', {'tier': 'sinister', 'count': 11}),
      ('open_chests', {'tier': 'sinister', 'count': 1.5}),
    ]) {
      await expectLater(_execute(state, intent.$1, intent.$2),
          throwsA(isA<GameCommandException>()));
    }
  });

  test('tagging protects a Sinister egg and its return requires confirmation',
      () async {
    final state = _fixture();
    const eggId = 'legacy-egg-1720000000000';
    final tagged =
        await _execute(state, 'tag_egg', {'eggId': eggId, 'tagged': true});
    await expectLater(
        _execute(tagged['state'], 'return_egg',
            {'eggId': eggId, 'sinisterConfirmed': true}),
        throwsA(isA<GameCommandException>()
            .having((e) => e.code, 'code', 'egg_tagged')));
    final untagged = await _execute(
        tagged['state'], 'tag_egg', {'eggId': eggId, 'tagged': false});
    await expectLater(
        _execute(untagged['state'], 'return_egg',
            {'eggId': eggId, 'sinisterConfirmed': false}),
        throwsA(isA<GameCommandException>()
            .having((e) => e.code, 'code', 'sinister_confirmation_required')));
    final returned = await _execute(untagged['state'], 'return_egg',
        {'eggId': eggId, 'sinisterConfirmed': true});
    expect(returned['result']['fragments'], 25);
    expect(returned['result']['essence'], inInclusiveRange(3, 5));
    expect(returned['result']['hearts'], inInclusiveRange(0, 1));
    expect(returned['state']['eggStash'], isEmpty);
    final replay = await _execute(returned['state'], 'return_egg',
        {'eggId': eggId, 'sinisterConfirmed': true});
    expect(replay['state']['eggAltar']['wallet'],
        returned['state']['eggAltar']['wallet']);
  });

  test(
      'crafting and renaming consume exactly one quill at the documented price',
      () async {
    final crafted = await _execute(
        _fixture(), 'craft_altar_relic', {'relic': 'nameweaversQuill'});
    final state = crafted['state'] as Map<String, dynamic>;
    expect(state['eggAltar']['wallet'],
        {'fragments': 10, 'essence': 1, 'hearts': 0});
    final renamed = await _execute(
        state, 'name_dragon', {'dragonId': state['pet']['id'], 'name': 'Nova'});
    expect(renamed['result'], true);
    expect(renamed['state']['pet']['name'], 'Nova');
    expect(renamed['state']['eggAltar']['crafted']['nameweaversQuill'], 0);
    final rejected = await _execute(renamed['state'], 'name_dragon',
        {'dragonId': state['pet']['id'], 'name': 'Sol'});
    expect(rejected['result'], false);
    expect(rejected['state']['pet']['name'], 'Nova');
  });

  test(
      'the server clock controls incubation and preserves the legacy egg identity',
      () async {
    const id = 'legacy-egg-1720000000000';
    final activated = await _execute(_fixture(), 'activate_egg', {'eggId': id});
    final saved = activated['state'] as Map<String, dynamic>;
    expect(saved['incubatingEgg']['stageStartedAt'], _now.toIso8601String());
    expect(saved['incubatingEgg']['needsUpdatedAt'], _now.toIso8601String());
    final early = await _execute(saved, 'hatch_egg', {'eggId': id});
    expect(early['result'], false);
    final hatched = await _execute(
        saved, 'hatch_egg', {'eggId': id}, _now.add(const Duration(hours: 2)));
    expect(hatched['result'], true);
    expect(hatched['state']['pet']['id'], id);
    expect(hatched['state']['pet']['stage'], 'hatchling');
    expect(hatched['state']['incubatingEgg'], isNull);
  });
}
