import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/domain/server_entropy.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/game_presentation.dart';
import 'package:dragon_haven/models/profile_portrait.dart';
import 'package:dragon_haven/models/supporter_pack.dart';
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
  Map<String, dynamic> copy(Map<String, dynamic> value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dh-care-');
    server = CanonicalUiServer(copy(fixture));
    server.state['ownedPortraitIds'] = [
      profilePortraitCatalog[0].id,
      profilePortraitCatalog[1].id
    ];
    server.state['selectedPortraitId'] = profilePortraitCatalog[0].id;
    server.state['ownedBadgeIds'] = [heartboundPairBadge.id];
    server.state['selectedBadgeId'] = null;
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

  test('cosmetic choices recover exactly once and cannot grant ownership',
      () async {
    final before = session.snapshot!;
    final second = profilePortraitCatalog[1].id;
    server.loseReply = true;
    await expectLater(
        actions().selectPortrait(second), error('game_command_unavailable'));
    await restart();
    expect(session.snapshot!.profile.selected('portrait'), second);
    await actions().selectPortrait(second);
    await actions().selectBadge(heartboundPairBadge.id);
    expect(session.snapshot!.profile.selected('badge'), heartboundPairBadge.id);
    server.loseReply = true;
    await expectLater(
        actions().selectBadge(null), error('game_command_unavailable'));
    await restart();
    expect(session.snapshot!.profile.selected('badge'), isNull);
    for (final action in [
      () => actions().selectPortrait(profilePortraitCatalog[99].id),
      () => actions().selectTitle('not-owned'),
      () => actions().selectBadge(supporterBadge.id),
      () => actions().selectFrame(supporterFrame.id),
    ]) {
      await expectLater(action(), error('game_action_unavailable'));
    }
    expect(session.snapshot!.profile.owned('portrait'),
        before.profile.owned('portrait'));
    expect(session.snapshot!.coins, before.coins);
    expect(session.snapshot!.shop.relics, before.shop.relics);
  });

  test(
      'presentation acknowledgment survives loss without repeating a hatch or reward',
      () async {
    await actions().refresh();
    final dragon = session.snapshot!.dragons.first;
    final event = GamePresentation(
        id: 'owned-milestone',
        type: GamePresentationType.hatch,
        createdAt: server.now,
        sortAt: server.now,
        dragonId: dragon.id);
    server.state['pendingPresentations'] = [event.toJson()];
    server.revision++;
    await session.synchronize();
    final before = copy(server.state);
    server.loseReply = true;
    await expectLater(actions().completePresentation(event.id),
        error('game_command_unavailable'));
    await restart();
    expect(session.snapshot!.presentations, isEmpty);
    await actions().completePresentation(event.id);
    await actions().completePresentation('someone-elses-milestone');
    final after = copy(server.state);
    before.remove('pendingPresentations');
    after.remove('pendingPresentations');
    expect(after, before);
  });

  Future<void> prepareFloors({bool damaged = false}) async {
    final primary =
        dragonLineageById(server.state['pet']['lineageId'] as String)
            .primaryRoomId;
    server.state['towerFloorRoomIds'] = ['hearth', primary];
    server.state['unlockedRoomIds'] = {'nest', 'hearth', primary}.toList();
    server.state['damagedTowerFloors'] = damaged ? [1] : <int>[];
    server.state['damagedTowerRepairFactors'] =
        damaged ? {'1': .6} : <String, dynamic>{};
    server.state['pet']['roamsTower'] = true;
    server.state['pet']['favorite'] = true;
    server.state['pet']['currentFloorIndex'] = 0;
    server.state['pet']['currentRoomId'] = 'hearth';
    server.state['rareInteractionAt'] = <String, dynamic>{};
    server.revision++;
    await session.synchronize();
  }

  test(
      'calling a resident checks room identity, damage, capacity and lost receipts',
      () async {
    await prepareFloors(damaged: true);
    final room = session.snapshot!.house.floorRoomIds[1];
    final dragonId = server.state['pet']['id'] as String;
    final coins = session.snapshot!.coins;
    await expectLater(
        actions().callDragonToFloor(room, 1), error('game_action_unavailable'));
    await expectLater(
        actions().visitFloor(room, 1), error('game_action_unavailable'));
    await prepareFloors();
    await expectLater(actions().callDragonToFloor('absent', 1),
        error('game_action_unavailable'));
    server.loseReply = true;
    await expectLater(actions().callDragonToFloor(room, 1),
        error('game_command_unavailable'));
    await restart();
    expect(session.snapshot!.dragon(dragonId)!.floorIndex, 1);
    expect(session.snapshot!.dragon(dragonId)!.roomId, room);
    expect(session.snapshot!.coins, coins);
    server.state['sanctuaryDragons'] = [
      for (var i = 0; i < 3; i++)
        {
          ...copy(server.state['pet'] as Map<String, dynamic>),
          'id': 'resident-$i',
          'favorite': false,
          'currentFloorIndex': 0,
          'currentRoomId': 'hearth',
        }
    ];
    server.revision++;
    await session.synchronize();
    await expectLater(actions().callDragonToFloor('hearth', 0),
        error('game_action_unavailable'));
    expect(session.snapshot!.dragon(dragonId)!.floorIndex, 1);
  });

  test(
      'room interactions use private entropy and a 12-hour server cooldown, without rewards',
      () async {
    await prepareFloors();
    final room = session.snapshot!.house.floorRoomIds[1];
    await actions().callDragonToFloor(room, 1);
    final seed = [
      for (var i = 0; i < 256; i++) i.toRadixString(16).padLeft(2, '0') * 32
    ].firstWhere((s) => ServerEntropy(s, stream: 'rewards').nextDouble() < .05);
    Future<Map<String, dynamic>> visit(
            Map<String, dynamic> state, DateTime now) =>
        GameCommandEngine.execute(
            state: state,
            action: 'visit_tower_floor',
            payload: {'roomId': room, 'index': 1},
            secretSeed: seed,
            now: now,
            keeperId: CanonicalUiServer.owner);
    final before = copy(server.state);
    final first = await visit(before, server.now);
    expect(
        first['result'], containsPair('dragonId', server.state['pet']['id']));
    final nextState = first['state'] as Map<String, dynamic>;
    final repeat = await visit(
        nextState, server.now.add(const Duration(hours: 11, minutes: 59)));
    expect(repeat['result'], isNull);
    final tomorrow =
        await visit(nextState, server.now.add(const Duration(hours: 12)));
    expect(tomorrow['result'], isNotNull);
    before.remove('rareInteractionAt');
    final after = copy(nextState)..remove('rareInteractionAt');
    expect(after, before);
    await expectLater(
        actions().execute('visit_tower_floor', {
          'roomId': room,
          'index': 1,
          'interactionId': 'snack_inspection',
        }),
        error('game_intent_invalid'));
  });

  test(
      'unowned selections and malformed milestone facts reject the public view',
      () {
    for (final corrupt in <void Function(Map<String, dynamic>)>[
      (data) => data['collection']['selectedPortraitId'] = 'not-owned',
      (data) => data['collection']['selectedBadgeId'] = supporterBadge.id,
      (data) => data['collection']['ownedFrameIds'] = [42],
      (data) => data['presentations'] = [
            {'id': 'broken', 'type': 'hatch'}
          ],
    ]) {
      final wire = copy(server.wire);
      corrupt(wire['data'] as Map<String, dynamic>);
      expect(
          () => CanonicalGameSnapshot.parse(wire,
              expectedOwner: CanonicalUiServer.owner),
          error('game_snapshot_invalid'));
    }
  });
}
