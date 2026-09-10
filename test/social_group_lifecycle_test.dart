import 'package:dragon_haven/models/adventure.dart';
import 'dart:convert';

import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/canonical_game_intent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all group requirements fit the available participants and levels', () {
    for (final adventure in AdventureCatalog.group) {
      expect(
          adventure.requirements.combinedLevel,
          lessThanOrEqualTo(
              adventure.requirements.players * Pet.levelThresholds.length),
          reason: adventure.id);
    }
    expect(AdventureCatalog.byId['group_13']!.requirements.combinedLevel, 18);
    expect(AdventureCatalog.byId['group_17']!.requirements.combinedLevel, 24);
  });

  const owner = '11111111-1111-4111-8111-111111111111';
  const source = '22222222-2222-4222-8222-222222222222';
  const member = '33333333-3333-4333-8333-333333333333';
  final now = DateTime.utc(2026, 9, 10, 12);
  late Map<String, dynamic> state;
  late String dragonId;
  setUp(() {
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => now);
    game.pet
      ..stage = DragonStage.hatchling
      ..favorite = true
      ..firstEgg = false;
    dragonId = game.pet.id;
    state = game.exportState();
    game.dispose();
  });
  Map<String, dynamic> context(String action, {bool removing = false}) => {
        'version': 1,
        'ownerId': owner,
        'action': action,
        'sourceId': source,
        'fingerprint': 'a7' * 32,
        'facts': {
          'adventureId': 'group_1',
          'dragonId': removing ? 'member-dragon' : dragonId,
          'memberId': removing ? member : null,
        },
      };
  Future<Map<String, dynamic>> command(String action,
          Map<String, dynamic> payload, Map<String, dynamic>? verified) =>
      GameCommandEngine.execute(
          state: state,
          action: action,
          payload: payload,
          secretSeed: 'a7' * 32,
          now: now,
          keeperId: owner,
          verifiedSocialContext: verified);
  Matcher unavailable() => throwsA(isA<GameCommandException>()
      .having((e) => e.code, 'source refusal', 'game_action_unavailable'));
  void sameInventory(Map<String, dynamic> before, Map<String, dynamic> after) {
    for (final key in ['coins', 'gems', 'xp', 'training']) {
      expect(after['pet'][key], before['pet'][key]);
    }
    for (final key in [
      'eggStash',
      'chestInventory',
      'specialChestInventory',
      'relicInventory',
      'untradeableRelicInventory',
      'eggAltar',
      'adventureRuns',
    ]) {
      expect(after[key], before[key]);
    }
  }

  test('create and join reserve only the sealed owned dragon without rewards',
      () async {
    for (final action in ['create_group_adventure', 'join_group_adventure']) {
      final payload = {
        if (action == 'create_group_adventure')
          'adventureId': 'group_1'
        else
          'lobbyId': source,
        'dragonId': dragonId,
      };
      final intent = CanonicalGameIntent(
          ownerId: owner,
          requestId: member,
          action: action,
          payload: payload,
          minimumRevision: 1);
      expect(intent.toRequest(10080)['payload'], payload);
      await expectLater(command(action, payload, null), unavailable());
      final result = await command(action, payload, context(action));
      expect(result['result'], {'accepted': true, 'sourceId': source});
      expect(
          result['state']['pet']['activeAdventureId'], 'online-group:$source');
      sameInventory(state, result['state']);
      expect(state['pet']['activeAdventureId'], isNull);
    }
  });

  test('foreign ownership, changed source and busy dragons cannot join',
      () async {
    const action = 'join_group_adventure';
    final payload = {'lobbyId': source, 'dragonId': dragonId};
    final valid = context(action);
    for (final invalid in [
      {...valid, 'ownerId': member},
      {...valid, 'sourceId': member},
      {...valid, 'action': 'create_group_adventure'},
      {
        ...valid,
        'facts': {...valid['facts'] as Map, 'dragonId': 'foreign'}
      },
      {
        ...valid,
        'facts': {...valid['facts'] as Map, 'adventureId': 'mini_1'}
      },
      {
        ...valid,
        'facts': {...valid['facts'] as Map, 'xp': 999}
      },
    ]) {
      await expectLater(command(action, payload, invalid), unavailable());
    }
    for (final busy in [
      'ordinary-run',
      'online-seasonal:$member',
      'online-group:$source'
    ]) {
      state['pet']['activeAdventureId'] = busy;
      await expectLater(command(action, payload, valid), unavailable());
      expect(state['pet']['activeAdventureId'], busy);
    }
    state['pet']['activeAdventureId'] = null;
    state['_activeGameAttempt'] = {'id': source, 'type': 'trial'};
    await expectLater(
        command(action, payload, valid),
        throwsA(isA<GameCommandException>().having(
            (e) => e.code, 'active attempt', 'game_attempt_in_progress')));
  });

  test(
      'leave releases only its own waiting lobby and kick does not edit another owner',
      () async {
    const leaving = 'leave_group_adventure';
    state['pet']['activeAdventureId'] = 'online-group:$source';
    final result =
        await command(leaving, {'lobbyId': source}, context(leaving));
    expect(result['state']['pet']['activeAdventureId'], isNull);
    sameInventory(state, result['state']);
    state['pet']['activeAdventureId'] = 'online-group:$member';
    await expectLater(
        command(leaving, {'lobbyId': source}, context(leaving)), unavailable());
    const removing = 'remove_group_adventure_member';
    final before = jsonEncode(state);
    final kicked = await command(
        removing,
        {'lobbyId': source, 'memberId': member},
        context(removing, removing: true));
    expect(kicked['result'], {'accepted': true, 'sourceId': source});
    sameInventory(state, kicked['state']);
    expect(kicked['state']['pet']['activeAdventureId'], 'online-group:$member');
    expect(jsonEncode(state), before);
    await expectLater(
        command(removing, {'lobbyId': source, 'memberId': owner},
            context(removing, removing: true)),
        unavailable());
  });
}
