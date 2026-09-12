import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/services/canonical_game_actions.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dragon_haven/domain/game_command_engine.dart';

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
    directory = await Directory.systemTemp.createTemp('dh-house-');
    server = CanonicalUiServer(
        jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>);
    server.state['pet']['coins'] = 10000;
    server.state['pet']['xp'] = 0;
    server.state['towerFloorRoomIds'] = ['hearth'];
    server.state['unlockedRoomIds'] = ['nest'];
    server.state['activeRoomId'] = 'nest';
    server.state['dragonWardLevel'] = 0;
    server.state['damagedTowerFloors'] = [0];
    // A damaged only floor has no roaming residents in a valid saved game.
    server.state['pet']['roamsTower'] = false;
    server.state['damagedTowerRepairFactors'] = {'0': .60};
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
  Future<void> restart() async {
    session.dispose();
    session = CanonicalGameSession(
        connection: CanonicalUiConnection(server), directory: directory);
    await session.synchronize();
  }

  test('free room changes work at maximum floors and recover a lost response',
      () async {
    server.state['towerFloorRoomIds'] = List.filled(20, 'hearth');
    server.state['pet']['coins'] = 0;
    server.revision++;
    await session.synchronize();
    server.loseReply = true;
    await expectLater(actions().changeFloorRoom(19, 'sunforge'),
        error('game_command_unavailable'));
    await restart();
    expect(session.snapshot!.house.floorRoomIds[19], 'sunforge');
    expect(session.snapshot!.house.floorRoomIds, hasLength(20));
    expect(session.snapshot!.coins, 0);
    expect(session.snapshot!.house.damagedFloors, {0});
    await actions().changeFloorRoom(19, 'crystal');
    await actions().changeFloorRoom(19, 'hearth');
    expect(session.snapshot!.coins, 0);
    await expectLater(actions().changeFloorRoom(19, 'nest'),
        error('game_action_unavailable'));
    await expectLater(actions().changeFloorRoom(19, 'unknown'),
        error('game_action_unavailable'));
  });

  test('lost floor purchase recovers once and stale quotes cannot buy again',
      () async {
    final old = actions();
    expect(session.snapshot!.house.nextFloorPrice, 2050);
    server.loseReply = true;
    await expectLater(
        actions().buildFloor('crystal'), error('game_command_unavailable'));
    await restart();
    expect(session.snapshot!.coins, 7950);
    expect(session.snapshot!.house.floorRoomIds, ['hearth', 'crystal']);
    expect(session.snapshot!.house.nextFloorPrice, 2900);
    expect(session.snapshot!.house.activeRoomId, 'crystal');
    final sent = server.sent.length;
    await expectLater(old.buildFloor('garden'), error('game_refresh_required'));
    expect(server.sent, hasLength(sent));
    // Selecting an already unlocked room is free.
    await actions().unlockRoom('nest');
    await actions().unlockRoom('crystal');
    expect(session.snapshot!.coins, 7950);
    expect(session.snapshot!.house.floorRoomIds, hasLength(2));
  });

  test('stored repair factor and ward charge once; repairs gate later upgrades',
      () async {
    expect(session.snapshot!.house.repairPrice(0), 270);
    expect(session.snapshot!.house.nextWardPrice, 150);
    server.loseReply = true;
    await expectLater(
        actions().upgradeWard(), error('game_command_unavailable'));
    await restart();
    expect(session.snapshot!.house.wardLevel, 1);
    expect(session.snapshot!.coins, 9850);
    server.loseReply = true;
    await expectLater(
        actions().repairFloor(0), error('game_command_unavailable'));
    await restart();
    expect(session.snapshot!.coins, 9580);
    expect(session.snapshot!.house.damagedFloors, isEmpty);
    expect(session.snapshot!.house.repairFactors, isEmpty);
    await expectLater(
        actions().repairFloor(0), error('game_action_unavailable'));
    await expectLater(
        actions().upgradeWard(), error('game_action_unavailable'));
    expect(session.snapshot!.coins, 9580);
    expect(session.snapshot!.house.wardLevel, 1);
  });

  test('server refuses level, funds, invalid rooms and tower maximum',
      () async {
    await expectLater(
        actions().unlockRoom('crystal'), error('game_action_unavailable'));
    await expectLater(
        actions().buildFloor('nest'), error('game_action_unavailable'));
    expect(session.snapshot!.coins, 10000);
    server.state['pet']['xp'] = 350;
    server.revision++;
    await session.synchronize();
    server.loseReply = true;
    await expectLater(
        actions().unlockRoom('crystal'), error('game_command_unavailable'));
    await restart();
    expect(session.snapshot!.coins, 9935);
    expect(session.snapshot!.house.unlockedRooms, contains('crystal'));
    await actions().unlockRoom('nest');
    await actions().unlockRoom('crystal');
    expect(session.snapshot!.coins, 9935);
    server.state['pet']['coins'] = 1;
    server.revision++;
    await session.synchronize();
    await expectLater(
        actions().buildFloor('hearth'), error('game_action_unavailable'));
    await expectLater(
        actions().repairFloor(0), error('game_action_unavailable'));
    await expectLater(
        actions().upgradeWard(), error('game_action_unavailable'));
    expect(session.snapshot!.coins, 1);
    server.state['pet']['coins'] = 999999;
    server.state['towerFloorRoomIds'] = List.filled(20, 'hearth');
    server.revision++;
    await session.synchronize();
    expect(session.snapshot!.house.nextFloorPrice, isNull);
    await expectLater(
        actions().buildFloor('hearth'), error('game_action_unavailable'));
    expect(session.snapshot!.house.floorRoomIds, hasLength(20));
    expect(session.snapshot!.coins, 999999);
  });

  test('malformed damage or quotes cannot enable a house action', () {
    for (final corrupt in <void Function(Map<String, dynamic>)>[
      (h) => h['dragonWardLevel'] = 4,
      (h) => h['damagedTowerFloors'] = [0, 0],
      (h) => h['damagedTowerFloors'] = [1],
      (h) => h['damagedTowerRepairFactors'] = {'0': .01},
      (h) => h['damagedTowerRepairFactors'] = {'00': .40},
      (h) => h['unlockedRoomIds'] = [],
      (h) => h['towerFloorRoomIds'] = ['nest'],
    ]) {
      final wire = jsonDecode(jsonEncode(server.wire)) as Map<String, dynamic>;
      corrupt(wire['data']['house'] as Map<String, dynamic>);
      expect(
          () => CanonicalGameSnapshot.parse(wire,
              expectedOwner: CanonicalUiServer.owner),
          error('game_snapshot_invalid'));
    }
  });
  Future<void> prepareFurniture() async {
    server.state['ownedItemIds'] = ['moss_cushion', 'moon_fern'];
    server.state['equippedItemIds'] = <String, dynamic>{};
    server.state['housePlacements'] = <dynamic>[];
    server.state['unlockedRoomIds'] = ['nest', 'hearth', 'crystal'];
    server.revision++;
    await session.synchronize();
  }

  test(
      'furniture survives lost replies and restart without spending or duplicating stock',
      () async {
    await prepareFurniture();
    final coins = session.snapshot!.coins;
    final stock = session.snapshot!.shop.ownedItems;
    final before = actions();
    server.loseReply = true;
    await expectLater(
        actions().placeHouseItem('moss_cushion', 'hearth', .2, .8),
        error('game_command_unavailable'));
    await restart();
    expect(session.snapshot!.house.placements.single.itemId, 'moss_cushion');
    expect(session.snapshot!.house.placements.single.x, .2);
    await expectLater(
        before.removeHouseItem('moss_cushion'), error('game_refresh_required'));
    server.loseReply = true;
    await expectLater(actions().moveHouseItem('moss_cushion', .7, .6),
        error('game_command_unavailable'));
    await restart();
    expect(session.snapshot!.house.placements.single.x, .7);
    await actions().placeHouseItem('moss_cushion', 'crystal', .3, .7);
    expect(session.snapshot!.house.placements.single.roomId, 'crystal');
    server.loseReply = true;
    await expectLater(actions().removeHouseItem('moss_cushion'),
        error('game_command_unavailable'));
    await restart();
    expect(session.snapshot!.house.placements, isEmpty);
    expect(session.snapshot!.shop.placedItems, isEmpty);
    expect(session.snapshot!.shop.ownedItems, stock);
    expect(session.snapshot!.coins, coins);
  });

  test(
      'server rejects unknown or unowned furniture, locked rooms and invalid coordinates',
      () async {
    await prepareFurniture();
    for (final pair in [
      ('cloud_basket', 'hearth'),
      ('moss_cushion', 'garden'),
      ('unknown', 'nest')
    ]) {
      await expectLater(actions().placeHouseItem(pair.$1, pair.$2, .5, .7),
          error('game_action_unavailable'));
    }
    await expectLater(actions().moveHouseItem('moss_cushion', .4, .7),
        error('game_action_unavailable'));
    for (final value in [-.01, 1.01, double.nan, double.infinity, '0.5']) {
      await expectLater(
          GameCommandEngine.execute(
              state: server.state,
              action: 'place_house_item',
              payload: {
                'itemId': 'moss_cushion',
                'roomId': 'hearth',
                'x': value,
                'y': .7
              },
              secretSeed: 'ab' * 32,
              now: server.now,
              keeperId: CanonicalUiServer.owner),
          throwsA(isA<GameCommandException>()
              .having((e) => e.code, 'code', 'invalid_argument')));
    }
    expect(session.snapshot!.house.placements, isEmpty);
    expect(session.snapshot!.coins, 10000);
  });

  test(
      'floor reorder keeps damage, repair factors and residents attached after lost reply',
      () async {
    server.state['towerFloorRoomIds'] = ['hearth', 'crystal', 'garden'];
    server.state['unlockedRoomIds'] = ['nest', 'hearth', 'crystal', 'garden'];
    server.state['pet']['roamsTower'] = false;
    server.state['pet']['currentFloorIndex'] = 0;
    server.state['pet']['currentRoomId'] = 'hearth';
    server.revision++;
    await session.synchronize();
    final coins = session.snapshot!.coins;
    final repair = session.snapshot!.house.repairPrice(0);
    server.loseReply = true;
    // Move the bottom visible row (2) to the top (0).
    await expectLater(
        actions().reorderFloor(2, 0), error('game_command_unavailable'));
    await restart();
    expect(
        session.snapshot!.house.floorRoomIds, ['crystal', 'garden', 'hearth']);
    expect(session.snapshot!.house.damagedFloors, {2});
    expect(session.snapshot!.house.repairPrice(2), repair);
    expect(session.snapshot!.dragon(server.state['pet']['id'])!.floorIndex, 2);
    expect(
        session.snapshot!.dragon(server.state['pet']['id'])!.roomId, 'hearth');
    expect(session.snapshot!.coins, coins);
    await expectLater(
        actions().reorderFloor(0, 3), error('game_action_unavailable'));
    await expectLater(
        actions().reorderFloor(1, 1), error('game_action_unavailable'));
    expect(
        session.snapshot!.house.floorRoomIds, ['crystal', 'garden', 'hearth']);
  });

  test(
      'roaming uses desired state across retries and respects ownership and capacity',
      () async {
    server.state['damagedTowerFloors'] = <int>[];
    server.state['damagedTowerRepairFactors'] = <String, double>{};
    server.revision++;
    await session.synchronize();
    final id = session.snapshot!.dragons.firstWhere((d) => d.owned).id;
    final coins = session.snapshot!.coins;
    server.loseReply = true;
    await expectLater(actions().setDragonRoaming(id, false),
        error('game_command_unavailable'));
    await restart();
    expect(session.snapshot!.dragon(id)!.roamsTower, isFalse);
    await actions().setDragonRoaming(id, false);
    expect(session.snapshot!.dragon(id)!.roamsTower, isFalse);
    await actions().setDragonRoaming(id, true);
    expect(session.snapshot!.dragon(id)!.roamsTower, isTrue);
    await expectLater(actions().setDragonRoaming('not-owned', true),
        error('game_action_unavailable'));
    await expectLater(
        actions().clearFloor(19), error('game_action_unavailable'));
    await expectLater(
        actions().clearFloor(0), error('game_action_unavailable'));
    expect(session.snapshot!.coins, coins);
    server.state['pet']['roamsTower'] = false;
    server.state['pet']['activeAdventureId'] = null;
    server.state['sanctuaryDragons'] = [
      for (var i = 0; i < 3; i++)
        {
          ...server.state['pet'] as Map<String, dynamic>,
          'id': 'roamer-$i',
          'favorite': false,
          'roamsTower': true,
          'currentFloorIndex': 0,
          'currentRoomId': 'hearth'
        }
    ];
    server.revision++;
    await session.synchronize();
    await expectLater(
        actions().setDragonRoaming(id, true), error('game_action_unavailable'));
    expect(session.snapshot!.dragon(id)!.roamsTower, isFalse);
    server.state['towerFloorRoomIds'] = ['hearth', 'crystal'];
    server.state['unlockedRoomIds'] = ['nest', 'hearth', 'crystal'];
    server.revision++;
    await session.synchronize();
    server.loseReply = true;
    await expectLater(
        actions().clearFloor(0), error('game_command_unavailable'));
    await restart();
    expect(
        session.snapshot!.dragons
            .where((d) => d.owned && d.roamsTower)
            .every((d) => d.floorIndex == 1),
        isTrue);
    expect(session.snapshot!.coins, coins);
  });

  test('malformed placement or roaming facts reject the entire public view',
      () async {
    await prepareFurniture();
    await actions().placeHouseItem('moss_cushion', 'hearth', .5, .7);
    for (final corrupt in <void Function(Map<String, dynamic>)>[
      (data) => data['house']['placements'][0]['x'] = '0.5',
      (data) => data['house']['placements'][0]['y'] = 1.1,
      (data) => data['house']['placements'][0]['scale'] = 0,
      (data) => data['house']['placements'][0]['roomId'] = 'locked',
      (data) => data['house']['placements'].add(data['house']['placements'][0]),
      (data) => data['dragons'][0]['roamsTower'] = 1,
      (data) => data['dragons'][0]['currentFloorIndex'] = 20,
      (data) => data['dragons'][0]['currentRoomId'] = '',
    ]) {
      final wire = jsonDecode(jsonEncode(server.wire)) as Map<String, dynamic>;
      corrupt(wire['data'] as Map<String, dynamic>);
      expect(
          () => CanonicalGameSnapshot.parse(wire,
              expectedOwner: CanonicalUiServer.owner),
          error('game_snapshot_invalid'));
    }
  });
}
