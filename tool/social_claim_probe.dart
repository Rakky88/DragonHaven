import 'dart:convert';

import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/domain/game_public_projection.dart';

Future<List<Map<String, dynamic>>> socialClaimProbe(
    Map<String, dynamic> fixture, DateTime now) async {
  var state = jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
  const owner = '11111111-1111-4111-8111-111111111111';
  const source = '22222222-2222-4222-8222-222222222222';
  final results = <Map<String, dynamic>>[];
  for (final (action, key, facts) in <(String, String, Map<String, dynamic>)>[
    (
      'claim_group_reward',
      'lobbyId',
      {
        'adventureId': 'group_1',
        'dragonId': state['pet']['id'],
        'xp': 400,
        'focus': 'spirit',
        'statPoints': 5,
        'chestTier': 'dragon',
        'participantCount': 4
      }
    ),
    (
      'claim_pair_reward',
      'adventureId',
      {
        'eventId': 'valentine_two_heartlights',
        'dragonId': state['pet']['id'],
        'xp': 650,
        'might': 8,
        'arcana': 8,
        'spirit': 8,
        'specialChestId': 'twinheart_keepsake_chest_v1',
        'simulated': false
      }
    ),
    (
      'claim_podium_prize',
      'prizeId',
      {'eventId': 'sunwake_summer_sea', 'position': 1}
    ),
  ]) {
    for (final replay in [false, true]) {
      final result = await GameCommandEngine.execute(
          state: state,
          action: action,
          payload: {key: source},
          secretSeed: (128 + results.length).toRadixString(16).padLeft(64, '0'),
          now: now,
          keeperId: owner,
          verifiedSocialContext: {
            'version': 1,
            'ownerId': owner,
            'action': action,
            'sourceId': source,
            'fingerprint': 'a5' * 32,
            'facts': facts
          });
      if (result['result']['alreadyApplied'] != replay) {
        throw StateError('Social replay failed');
      }
      state = result['state'] as Map<String, dynamic>;
      results.add({
        'action': action,
        'result': result,
        'projection':
            GamePublicProjection.project(state: state, ownerId: owner, now: now)
      });
    }
  }
  return results;
}
