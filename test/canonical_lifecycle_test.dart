import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/services/canonical_game_actions.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/game_domain_probe.dart';
import 'support/canonical_ui_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> fixture;
  setUpAll(() async {
    fixture = (await runGameDomainProbe())['state'] as Map<String, dynamic>;
  });
  late CanonicalUiServer server;
  late CanonicalGameSession session;
  late Directory directory;
  CanonicalGameActions actions() => CanonicalGameActions(session);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dh-lifecycle-');
    server = CanonicalUiServer(
        jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>);
    server.state['eggAltar']
        ['wallet'] = {'fragments': 200, 'essence': 30, 'hearts': 4};
    server.state['relicInventory']['chronoshard'] = 1;
    server.state['chronoshardReductions'] = [50];
    for (final relic in MysticRelic.values.where((r) => r.isEquipable)) {
      server.state['relicInventory'][relic.name] = 1;
      server.state['untradeableRelicInventory'][relic.name] = 1;
    }
    server.state['twinstarBroochEverObtained'] = true;
    server.state['uniqueRelicsEverObtained'] = MysticRelic.values
        .where((r) => r.isEquipable)
        .map((r) => r.name)
        .toList();
    session = CanonicalGameSession(
        connection: CanonicalUiConnection(server), directory: directory);
    await session.synchronize();
  });
  tearDown(() async {
    session.dispose();
    await directory.delete(recursive: true);
  });
  Matcher error(String code) => throwsA(
      isA<CanonicalGameException>().having((e) => e.code, 'fixed error', code));

  test(
      'typed inventory keeps hidden genetics absent and rejects contradictory equipment or stock',
      () {
    final view = session.snapshot!;
    expect(view.inventory.materials.fragments, 200);
    expect(view.dragons.single.sex.name, anyOf('male', 'female'));
    expect(view.eggs.first.revealedLineageId, isNull);
    expect(view.eggs.first.revealedRarity, isNull);
    for (final modify in <void Function(Map<String, dynamic>)>[
      (d) => d['inventory']['altar']['wallet']['fragments'] = -1,
      (d) => d['inventory']['chronoshardReductions'] = [50, 80],
      (d) => d['inventory']
          ['equippedRelicDragonIds'] = {'emberheartBrooch': 'absent'},
      (d) => d['inventory']['equippedRelicDragonIds'] = {
            'emberheartBrooch': view.activeDragonId,
            'moonweaveBrooch': view.activeDragonId
          },
      (d) => d['dragons'][0]['training']['might'] = 999,
      (d) => d['dragons'][0]['sex'] = 'unknown',
    ]) {
      final wire = jsonDecode(jsonEncode(server.wire)) as Map<String, dynamic>;
      modify(wire['data'] as Map<String, dynamic>);
      expect(
          () => CanonicalGameSnapshot.parse(wire,
              expectedOwner: CanonicalUiServer.owner),
          error('game_snapshot_invalid'));
    }
  });

  test(
      'tag protects a Sinister egg; a lost return receipt survives restart without a second grant',
      () async {
    final egg = session.snapshot!.eggs.firstWhere((e) => e.kind == 'sinister');
    await actions().tagEgg(egg.id, true);
    await expectLater(actions().returnEgg(egg.id, sinisterConfirmed: true),
        error('egg_tagged'));
    expect(session.snapshot!.egg(egg.id)?.tagged, isTrue);
    await actions().tagEgg(egg.id, false);
    await expectLater(actions().returnEgg(egg.id, sinisterConfirmed: false),
        error('sinister_confirmation_required'));
    final wallet = session.snapshot!.inventory.materials;
    final before = server.receipts.length;
    server.loseReply = true;
    await expectLater(actions().returnEgg(egg.id, sinisterConfirmed: true),
        error('game_command_unavailable'));
    expect(session.snapshot!.egg(egg.id), isNotNull);
    session.dispose();
    session = CanonicalGameSession(
        connection: CanonicalUiConnection(server), directory: directory);
    await session.synchronize();
    expect(session.snapshot!.egg(egg.id), isNull);
    final after = session.snapshot!.inventory.materials;
    expect(after.fragments, wallet.fragments + 25);
    expect(after.essence - wallet.essence, inInclusiveRange(3, 5));
    expect(after.hearts - wallet.hearts, inInclusiveRange(0, 1));
    expect(server.receipts.length, before + 1);
    expect(await session.intents.pending(CanonicalUiServer.owner), isNull);
  });

  test(
      'craft and reveal only spend once, reveal known facts and reject an old selection',
      () async {
    final egg = session.snapshot!.eggs.first;
    final stale = actions();
    final held = Completer<void>();
    server.hold = held.future;
    final captured = actions();
    final a = captured.craft(AltarRelic.weaveOracle);
    final b = captured.craft(AltarRelic.weaveOracle);
    held.complete();
    await Future.wait([a, b]);
    server.hold = null;
    expect(session.snapshot!.inventory.materials.fragments, 75);
    expect(session.snapshot!.inventory.count(AltarRelic.weaveOracle), 1);
    await expectLater(stale.revealEgg(AltarRelic.weaveOracle, egg.id),
        error('game_refresh_required'));
    await actions().revealEgg(AltarRelic.weaveOracle, egg.id);
    expect(session.snapshot!.egg(egg.id)?.revealedLineageId, isNotNull);
    expect(session.snapshot!.egg(egg.id)?.revealedRarity, isNotNull);
    expect(session.snapshot!.inventory.count(AltarRelic.weaveOracle), 0);
    await expectLater(actions().revealEgg(AltarRelic.weaveOracle, egg.id),
        error('already_known'));
    expect(session.snapshot!.inventory.count(AltarRelic.weaveOracle), 0);
  });

  test(
      'incubation, fixed Chronoshard, server-time hatch, naming and one brooch slot round-trip',
      () async {
    final egg = session.snapshot!.eggs.first;
    final coins = session.snapshot!.coins;
    await actions().activateEgg(egg.id);
    expect(session.snapshot!.egg(egg.id)?.location, 'nest');
    await expectLater(
        actions().hatchEgg(egg.id), error('game_action_unavailable'));
    final oldHatch = session.snapshot!.nest!.hatchAt!;
    await actions().useChronoshard(50);
    expect(session.snapshot!.nest!.hatchAt!.isBefore(oldHatch), isTrue);
    expect(session.snapshot!.inventory.chronoshards, isEmpty);
    server.now = oldHatch.add(const Duration(seconds: 1));
    await session.synchronize();
    await actions().hatchEgg(egg.id);
    expect(session.snapshot!.egg(egg.id), isNull);
    expect(session.snapshot!.dragon(egg.id)?.owned, isTrue);
    expect(session.snapshot!.coins, coins);
    await actions().nameDragon(egg.id, 'New Light');
    await actions().craft(AltarRelic.nameweaversQuill);
    await actions().nameDragon(egg.id, 'Bright Light');
    expect(session.snapshot!.dragon(egg.id)?.name, 'Bright Light');
    expect(session.snapshot!.inventory.count(AltarRelic.nameweaversQuill), 0);
    await actions().equip(MysticRelic.twinstarBrooch, egg.id);
    await actions().equip(MysticRelic.emberheartBrooch, egg.id);
    expect(session.snapshot!.inventory.equipment,
        {MysticRelic.emberheartBrooch: egg.id});
    await actions().equip(MysticRelic.emberheartBrooch, null);
    expect(session.snapshot!.inventory.equipment, isEmpty);
    await actions().releaseDragon(egg.id);
    expect(session.snapshot!.dragon(egg.id)?.owned, isFalse);
    expect(session.snapshot!.coins, coins);
  });
}
