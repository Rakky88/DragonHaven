import 'dart:convert';
import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

const owner = '11111111-1111-4111-8111-111111111111';
const conclave = '22222222-2222-4222-8222-222222222222';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> state;
  late Map<String, dynamic> context;
  setUp(() {
    final game = HouseholdProvider(
        persistenceEnabled: false, clock: () => DateTime.utc(2026, 9, 10));
    game.pet
      ..stage = DragonStage.hatchling
      ..firstEgg = false
      ..favorite = true
      ..name = 'Beacon keeper';
    game.eggAltar =
        EggAltarState(ownerId: owner, wallet: const WeaveWallet(200, 7, 2));
    state = game.exportState();
    game.dispose();
    context = {
      'version': 1,
      'ownerId': owner,
      'action': 'donate_beacon',
      'sourceId': conclave,
      'fingerprint': 'ab' * 32,
      'facts': {'beforeFragments': 490, 'amount': 25, 'goal': 5000}
    };
  });
  Future<Map<String, dynamic>> run(
          {Map<String, dynamic>? facts, int amount = 25}) =>
      GameCommandEngine.execute(
          state: state,
          action: 'donate_beacon',
          payload: {'conclaveId': conclave, 'amount': amount},
          keeperId: owner,
          secretSeed: 'ab' * 32,
          now: DateTime.utc(2026, 9, 10),
          verifiedSocialContext: facts ?? context);
  test(
      'one exact voluntary debit preserves other materials and all personal rewards',
      () async {
    final before = jsonEncode(state);
    final result = await run();
    expect(result['result'], {'donated': 25, 'fragments': 515});
    expect(result['state']['eggAltar']['wallet'],
        {'fragments': 175, 'essence': 7, 'hearts': 2});
    expect(result['state']['pet'], state['pet']);
    expect(result['state']['chestInventory'], state['chestInventory']);
    expect(result['state']['eggAltar']['revision'], 1);
    expect(jsonEncode(state), before);
  });
  test('rejects forged owner, source, amount, capacity and extra reward facts',
      () async {
    for (final invalid in [
      {...context, 'ownerId': conclave},
      {...context, 'sourceId': owner},
      {...context, 'xp': 1000},
      {
        ...context,
        'facts': {'beforeFragments': 490, 'amount': 26, 'goal': 5000}
      },
      {
        ...context,
        'facts': {'beforeFragments': 4990, 'amount': 25, 'goal': 5000}
      },
      {
        ...context,
        'facts': {
          'beforeFragments': 490,
          'amount': 25,
          'goal': 5000,
          'xp': 1000
        }
      },
    ]) {
      await expectLater(
          run(facts: invalid),
          throwsA(isA<GameCommandException>()
              .having((e) => e.code, 'code', 'game_action_unavailable')));
    }
    for (final amount in [0, -1, 5001]) {
      await expectLater(
          run(amount: amount), throwsA(isA<GameCommandException>()));
    }
    state['eggAltar']['wallet']['fragments'] = 24;
    await expectLater(
        run(),
        throwsA(isA<GameCommandException>()
            .having((e) => e.code, 'code', 'insufficient_materials')));
    expect(state['eggAltar']['wallet']['fragments'], 24);
  });
}
