import 'dart:convert';

import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/domain/game_public_projection.dart';
import 'package:dragon_haven/domain/server_entropy.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/profile_portrait.dart';
import 'package:dragon_haven/models/supporter_pack.dart';

/// Synthetic VM/JavaScript parity only; these cosmetic grants never reach a
/// player or database. Production commands accept owned catalog identities.
Future<List<Map<String, dynamic>>> careCommandProbe(
    Map<String, dynamic> fixture, DateTime now) async {
  var state = jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
  final portrait = profilePortraitCatalog[1].id;
  state['ownedPortraitIds'] = [profilePortraitCatalog[0].id, portrait];
  state['selectedPortraitId'] = profilePortraitCatalog[0].id;
  state['ownedBadgeIds'] = [heartboundPairBadge.id];
  state['selectedBadgeId'] = null;
  final room =
      dragonLineageById(state['pet']['lineageId'] as String).primaryRoomId;
  state['towerFloorRoomIds'] = ['hearth', room];
  state['unlockedRoomIds'] = {'nest', 'hearth', room}.toList();
  state['damagedTowerFloors'] = <int>[];
  state['damagedTowerRepairFactors'] = <String, dynamic>{};
  state['pet']['roamsTower'] = true;
  state['pet']['favorite'] = true;
  state['pet']['currentFloorIndex'] = 0;
  state['pet']['currentRoomId'] = 'hearth';
  state['rareInteractionAt'] = <String, dynamic>{};
  final seed = [
    for (var i = 0; i < 256; i++) i.toRadixString(16).padLeft(2, '0') * 32
  ].firstWhere((s) => ServerEntropy(s, stream: 'rewards').nextDouble() < .05);
  final results = <Map<String, dynamic>>[];
  for (final (action, payload) in <(String, Map<String, dynamic>)>[
    ('select_portrait', {'catalogId': portrait}),
    ('select_title', {'catalogId': state['selectedTitleId']}),
    ('select_badge', {'catalogId': heartboundPairBadge.id}),
    ('select_badge', {'catalogId': null}),
    ('select_frame', {'catalogId': null}),
    ('call_dragon_to_floor', {'roomId': room, 'index': 1}),
    ('visit_tower_floor', {'roomId': room, 'index': 1}),
    ('visit_tower_floor', {'roomId': room, 'index': 1}),
    ('complete_presentation', {'presentationId': 'already-shown'}),
  ]) {
    final result = await GameCommandEngine.execute(
        state: state,
        action: action,
        payload: payload,
        secretSeed: seed,
        now: now,
        keeperId: '11111111-1111-4111-8111-111111111111');
    state = result['state'] as Map<String, dynamic>;
    results.add({
      'action': action,
      'result': result,
      'projection': GamePublicProjection.project(
          state: state,
          ownerId: '11111111-1111-4111-8111-111111111111',
          now: now)
    });
  }
  if (results[5]['result']['result'] != true ||
      results[6]['result']['result'] == null ||
      results[7]['result']['result'] != null) {
    throw StateError('Synthetic room command proof failed');
  }
  return results;
}
