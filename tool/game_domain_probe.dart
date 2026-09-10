import 'social_claim_probe.dart';
import 'care_command_probe.dart';
import 'trial_command_probe.dart';
import 'dart:convert';

import 'trial_model_probe.dart';

import 'package:dragon_haven/domain/server_entropy.dart';
import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/domain/game_public_projection.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/dragon_school.dart';
import 'package:dragon_haven/models/school_lesson_game.dart';
import 'package:dragon_haven/models/game_input_transcript.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';

/// Synthetic parity fixture only. It never connects to a database or device.
Future<Map<String, dynamic>> runGameDomainProbe(
    {bool includeTrialCommands = false}) async {
  final now = DateTime.utc(2026, 9, 7, 12);
  final seed = List.filled(32, 'a5').join();
  final initialIds = ServerEntropy(seed, stream: 'identities');
  final fixture = HouseholdProvider(
    random: ServerEntropy(seed, stream: 'rewards'),
    idGenerator: initialIds.uuid,
    clock: () => now,
    persistenceEnabled: false,
  );
  fixture.pet
    ..stage = DragonStage.hatchling
    ..favorite = true
    ..firstEgg = false
    ..name = 'Domain Probe'
    ..needsUpdatedAt = now
    ..coins = 1000
    ..gems = 1000;
  fixture.chestInventory = {ChestTier.sinister: 3, ChestTier.wooden: 2};
  final stored = fixture.exportState();
  fixture.dispose();
  final commandIds =
      ServerEntropy(List.filled(32, '7b').join(), stream: 'identities');
  final game = HouseholdProvider.forServerState(
    stored,
    now: now,
    random: ServerEntropy(List.filled(32, '7b').join(), stream: 'rewards'),
    idGenerator: commandIds.uuid,
  );
  try {
    final reward = await game.openChests(ChestTier.sinister, count: 3);
    if (reward == null) {
      throw StateError('Synthetic chests could not be opened');
    }
    final purchase = await game.purchasePortraitChest();
    final state = game.exportState();
    Future<Map<String, dynamic>> command(Map<String, dynamic> current,
            String action, Map<String, dynamic> payload, int ordinal,
            {DateTime? at}) =>
        GameCommandEngine.execute(
          state: current,
          action: action,
          payload: payload,
          secretSeed:
              List.filled(32, ordinal.toRadixString(16).padLeft(2, '0')).join(),
          now: at ?? now,
          keeperId: '11111111-1111-4111-8111-111111111111',
        );
    final refreshed = await command(state, 'refresh', {}, 1);
    final eggId =
        (refreshed['state']['eggStash'] as List).first['id'] as String;
    final activated =
        await command(refreshed['state'], 'activate_egg', {'eggId': eggId}, 2);
    final early =
        await command(activated['state'], 'hatch_egg', {'eggId': eggId}, 3);
    final hatched = await command(
        early['state'], 'hatch_egg', {'eggId': eggId}, 4,
        at: now.add(const Duration(days: 15)));
    final highlighted = await command(hatched['state'], 'set_dragon_highlight',
        {'dragonId': eggId, 'focus': 'might', 'highlighted': true}, 5,
        at: now.add(const Duration(days: 15)));
    final highlightedAgain = await command(
        highlighted['state'],
        'set_dragon_highlight',
        {'dragonId': eggId, 'focus': 'might', 'highlighted': true},
        6,
        at: now.add(const Duration(days: 15)));
    final favorite = await command(highlightedAgain['state'],
        'set_favorite_dragon', {'dragonId': eggId}, 7,
        at: now.add(const Duration(days: 15)));
    if ([highlighted, highlightedAgain, favorite]
        .any((c) => c['result'] != true)) {
      throw StateError('Synthetic dragon preferences must be accepted');
    }
    final roomUnlocked =
        await command(favorite['state'], 'unlock_room', {'roomId': 'nest'}, 8);
    final furniture = await command(roomUnlocked['state'], 'purchase_furniture',
        {'catalogId': 'moss_cushion'}, 9);
    final placed = await command(furniture['state'], 'place_house_item',
        {'itemId': 'moss_cushion', 'roomId': 'nest', 'x': .25, 'y': .7}, 10);
    final moved = await command(placed['state'], 'move_house_item',
        {'itemId': 'moss_cushion', 'x': .72, 'y': .8}, 11);
    final removed = await command(
        moved['state'], 'remove_house_item', {'itemId': 'moss_cushion'}, 12);
    final resting = await command(removed['state'], 'set_dragon_roaming',
        {'dragonId': eggId, 'enabled': false}, 13);
    if ([placed, moved, removed].any((c) => c['result'] != true) ||
        !['updated', 'unchanged'].contains(resting['result'])) {
      throw StateError('Synthetic house commands must be accepted');
    }
    final commands = [
      refreshed,
      activated,
      early,
      hatched,
      highlighted,
      highlightedAgain,
      favorite,
      roomUnlocked,
      furniture,
      placed,
      moved,
      removed,
      resting
    ];
    final school = <Map<String, dynamic>>[];
    final schoolBase = jsonDecode(jsonEncode(state)) as Map<String, dynamic>;
    schoolBase['towerFloorRoomIds'] = List.filled(5, 'hearth');
    (schoolBase['sanctuaryDragons'] as List).add(Pet(
            id: 'school-second',
            stage: DragonStage.hatchling,
            hatchSeed: 17,
            acquiredAt: now,
            stageStartedAt: now,
            needsUpdatedAt: now)
        .toJson());
    for (final definition in dragonSchoolGames) {
      final started = await command(
          schoolBase,
          'start_school',
          {
            'gameId': definition.id,
            'dragonIds': jsonEncode([
              schoolBase['pet']['id'],
              if (definition.minimumDragons > 1) 'school-second'
            ]),
            'mentorId': null,
          },
          40 + definition.kind.index);
      final attempt = started['result'] as Map<String, dynamic>;
      final model =
          SchoolLessonGame(kind: definition.kind, seed: attempt['seed'] as int);
      for (var ms = 50; ms < 20000; ms += 50) {
        final count = switch (definition.kind) {
          DragonSchoolGameKind.runeRush ||
          DragonSchoolGameKind.crystalChase =>
            9,
          DragonSchoolGameKind.cloudWeave => 3,
          DragonSchoolGameKind.emberReflex ||
          DragonSchoolGameKind.breathBalance =>
            1,
          _ => 6,
        };
        model.tap((ms ~/ 50) % count, ms);
      }
      final finished = await command(
          started['state'],
          'finish_school',
          {
            'attemptId': attempt['id'],
            'inputs': SchoolInputTranscript.encode(model.inputs),
          },
          60 + definition.kind.index,
          at: now.add(const Duration(seconds: 21)));
      school.add({
        'game': definition.id,
        'seed': attempt['seed'],
        'inputs': SchoolInputTranscript.encode(model.inputs),
        'clientScore': model.score,
        'server': finished['result'],
        'state': finished['state']
      });
    }
    return {
      'school': school,
      'socialClaims':
          includeTrialCommands ? await socialClaimProbe(state, now) : const [],
      'careCommands':
          includeTrialCommands ? await careCommandProbe(state, now) : const [],
      'trialModels': trialModelProbe(),
      'trialCommands':
          includeTrialCommands ? await trialCommandProbe() : const [],
      'purchase': purchase.name,
      'state': state,
      'commands': commands,
      'projections': [
        for (final value in commands)
          GamePublicProjection.project(
              state: value['state'],
              now: now,
              ownerId: '11111111-1111-4111-8111-111111111111'),
      ],
      'entropy': List.generate(8, (_) => commandIds.nextInt(4294967296)),
    };
  } finally {
    game.dispose();
  }
}
