import 'dart:convert';
import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const owner = '11111111-1111-4111-8111-111111111111';
  const other = '22222222-2222-4222-8222-222222222222';
  const source = '33333333-3333-4333-8333-333333333333';
  final now = DateTime.utc(2026, 9, 10, 12);
  late Map<String, dynamic> state;
  late String dragon;
  setUp(() {
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => now);
    game.pet
      ..stage = DragonStage.hatchling
      ..favorite = true
      ..firstEgg = false;
    state = game.exportState();
    dragon = game.pet.id;
    game.dispose();
  });
  Map<String, dynamic> context(String action,
          {String role = 'creator', bool noDragon = false}) =>
      {
        'version': 1,
        'ownerId': owner,
        'action': action,
        'sourceId': source,
        'fingerprint': 'ab' * 32,
        'facts': {
          'eventId': 'valentine_two_heartlights',
          'dragonId': noDragon ? null : dragon,
          'otherId': other,
          'keeperCode': 'DH-1234ABCD',
          'occurrenceKey': 'preview:valentine_two_heartlights:$owner',
          'simulated': true,
          'role': role
        }
      };
  Future<Map<String, dynamic>> execute(String action,
          Map<String, dynamic> payload, Map<String, dynamic>? facts) =>
      GameCommandEngine.execute(
          state: state,
          action: action,
          payload: payload,
          secretSeed: 'ab' * 32,
          now: now,
          keeperId: owner,
          verifiedSocialContext: facts);
  final denied = throwsA(isA<GameCommandException>()
      .having((e) => e.code, 'code', 'game_action_unavailable'));
  void unchangedRewards(Map result) {
    for (final key in ['coins', 'gems', 'xp', 'training']) {
      expect(result['state']['pet'][key], state['pet'][key]);
    }
    for (final key in [
      'eggStash',
      'chestInventory',
      'specialChestInventory',
      'relicInventory',
      'adventureRuns'
    ]) {
      expect(result['state'][key], state[key]);
    }
  }

  test(
      'invite and accept reserve exactly one owned dragon without granting rewards',
      () async {
    for (final action in ['invite_pair_adventure', 'accept_pair_adventure']) {
      final payload = {
        'dragonId': dragon,
        if (action == 'invite_pair_adventure')
          'keeperCode': ' dh-1234abcd '
        else
          'adventureId': source
      };
      await expectLater(execute(action, payload, null), denied);
      final result = await execute(
          action,
          payload,
          context(action,
              role: action == 'invite_pair_adventure' ? 'creator' : 'partner'));
      expect(result['result'], {'accepted': true, 'sourceId': source});
      expect(result['state']['pet']['activeAdventureId'],
          'online-seasonal:$source');
      expect(state['pet']['activeAdventureId'], isNull);
      unchangedRewards(result);
    }
  });
  test(
      'start preserves binding; cancel clears only its exact source; decline has no owned dragon',
      () async {
    state['pet']['activeAdventureId'] = 'online-seasonal:$source';
    for (final action in ['start_pair_adventure', 'cancel_pair_adventure']) {
      final result =
          await execute(action, {'adventureId': source}, context(action));
      unchangedRewards(result);
      expect(result['state']['pet']['activeAdventureId'],
          action == 'start_pair_adventure' ? 'online-seasonal:$source' : null);
    }
    state['pet']['activeAdventureId'] = null;
    for (final action in ['decline_pair_adventure', 'cancel_pair_adventure']) {
      final result = await execute(action, {'adventureId': source},
          context(action, role: 'partner', noDragon: true));
      expect(result['state']['pet']['activeAdventureId'], isNull);
      unchangedRewards(result);
    }
  });
  test('refuses foreign role, owner, target, dragon and extra reward facts',
      () async {
    final good = context('invite_pair_adventure');
    final payload = {'keeperCode': 'DH-1234ABCD', 'dragonId': dragon};
    for (final field in [
      'role',
      'otherId',
      'dragonId',
      'keeperCode',
      'eventId'
    ]) {
      final invalid = jsonDecode(jsonEncode(good)) as Map<String, dynamic>;
      invalid['facts'][field] = switch (field) {
        'role' => 'partner',
        'otherId' => owner,
        'keeperCode' => 'DH-99999999',
        _ => 'foreign'
      };
      await expectLater(
          execute('invite_pair_adventure', payload, invalid), denied);
    }
    final invalid = jsonDecode(jsonEncode(good)) as Map<String, dynamic>;
    invalid['facts']['xp'] = 999;
    await expectLater(
        execute('invite_pair_adventure', payload, invalid), denied);
    for (final binding in [
      'solo-trip',
      'online-group:$source',
      'online-seasonal:$source'
    ]) {
      state['pet']['activeAdventureId'] = binding;
      await expectLater(
          execute('invite_pair_adventure', payload, good), denied);
    }
    state['pet']['activeAdventureId'] = 'online-seasonal:$other';
    await expectLater(
        execute('cancel_pair_adventure', {'adventureId': source},
            context('cancel_pair_adventure')),
        denied);
  });
}
