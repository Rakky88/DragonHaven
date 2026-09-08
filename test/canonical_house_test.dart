import 'dart:convert';
import 'dart:io';

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
}
