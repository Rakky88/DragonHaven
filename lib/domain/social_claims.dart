import '../models/adventure.dart';
import '../models/pet.dart';
import '../providers/household_provider.dart';

/// Facts sealed by the database lease, never accepted from the request payload
/// or a legacy save. Commit compares the source record again and acknowledges
/// it in the same transaction as the canonical inventory update.
abstract final class SocialClaims {
  static const actions = {
    'claim_group_reward',
    'claim_pair_reward',
    'claim_podium_prize'
  };

  static Future<Map<String, dynamic>> apply({
    required HouseholdProvider game,
    required String ownerId,
    required String action,
    required String sourceId,
    required Map<String, dynamic>? context,
  }) async {
    Never invalid() =>
        throw const SocialClaimException('game_social_claim_unavailable');
    if (!actions.contains(action) ||
        context == null ||
        context.length != 6 ||
        context['version'] != 1 ||
        context['ownerId'] != ownerId ||
        context['action'] != action ||
        context['sourceId'] != sourceId ||
        context['fingerprint'] is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(context['fingerprint'] as String) ||
        context['facts'] is! Map<String, dynamic>) {
      invalid();
    }
    final facts = context['facts'] as Map<String, dynamic>;
    String text(String key) {
      final value = facts[key];
      if (value is! String || value.isEmpty || value.length > 200) {
        invalid();
      }
      return value;
    }

    int count(String key, int low, int high) {
      final value = facts[key];
      if (value is! int || value < low || value > high) {
        invalid();
      }
      return value;
    }

    void keys(Set<String> expected) {
      if (facts.length != expected.length ||
          !expected.every(facts.containsKey)) {
        invalid();
      }
    }

    Pet dragon(String prefix) {
      final id = text('dragonId');
      final selected = game.ownedDragons.where((d) => d.id == id).firstOrNull;
      if (selected == null ||
          selected.isEgg ||
          (selected.activeAdventureId != null &&
              selected.activeAdventureId != '$prefix:$sourceId')) {
        invalid();
      }
      return selected;
    }

    final bool alreadyApplied;
    final bool applied;
    switch (action) {
      case 'claim_group_reward':
        keys({
          'adventureId',
          'dragonId',
          'xp',
          'focus',
          'statPoints',
          'chestTier',
          'participantCount'
        });
        final definition = AdventureCatalog.byId[text('adventureId')];
        if (definition == null ||
            definition.kind != AdventureKind.group ||
            !const {'gold', 'dragon', 'mythical'}.contains(text('chestTier')) ||
            !TrainingFocus.values.any((f) => f.name == text('focus'))) {
          invalid();
        }
        alreadyApplied = game.appliedOnlineGroupRewardIds.contains(sourceId);
        final xp = count('xp', 1, 10000);
        final statPoints = count('statPoints', 1, 400);
        final participants = count('participantCount', 2, 4);
        final selectedId =
            alreadyApplied ? text('dragonId') : dragon('online-group').id;
        applied = await game.applyOnlineGroupReward(
            lobbyId: sourceId,
            adventureId: definition.id,
            dragonId: selectedId,
            xp: xp,
            focus: text('focus'),
            statPoints: statPoints,
            chestTier: text('chestTier'),
            participantCount: participants);
      case 'claim_pair_reward':
        keys({
          'eventId',
          'dragonId',
          'xp',
          'might',
          'arcana',
          'spirit',
          'specialChestId',
          'simulated'
        });
        if (facts['simulated'] is! bool) {
          invalid();
        }
        alreadyApplied =
            game.appliedOnlineSeasonalPairRewardIds.contains(sourceId);
        final event = specialAdventureEventById(text('eventId'));
        if (event == null ||
            AdventureCatalog.byId[event.adventureId]?.requiresOnlinePartner !=
                true ||
            specialChestById(text('specialChestId')) == null) {
          invalid();
        }
        final selectedId =
            alreadyApplied ? text('dragonId') : dragon('online-seasonal').id;
        applied = await game.applyOnlineSeasonalPairReward(
            adventureId: sourceId,
            eventId: text('eventId'),
            dragonId: selectedId,
            xp: count('xp', 0, 1000),
            might: count('might', 0, 25),
            arcana: count('arcana', 0, 25),
            spirit: count('spirit', 0, 25),
            specialChestId: text('specialChestId'),
            simulated: facts['simulated'] as bool);
      case 'claim_podium_prize':
        keys({'eventId', 'position'});
        final position = count('position', 1, 3);
        final eventId = text('eventId');
        if (specialAdventureEventById(eventId) == null) {
          invalid();
        }
        alreadyApplied = game.appliedSeasonalPrizeIds.contains(sourceId);
        applied = alreadyApplied ||
            await game.applySeasonalPodiumPrize(
                prizeId: sourceId, eventId: eventId, position: position);
      default:
        invalid();
    }
    if (!applied) {
      invalid();
    }
    return {
      'accepted': true,
      'alreadyApplied': alreadyApplied,
      'sourceId': sourceId
    };
  }
}

class SocialClaimException implements Exception {
  const SocialClaimException(this.code);
  final String code;
}
