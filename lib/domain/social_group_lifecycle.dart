import '../models/adventure.dart';
import '../providers/household_provider.dart';

/// Mutates only the acting keeper's dragon binding. The database seals lobby
/// eligibility and commits membership, start time and shared rewards alongside
/// this state. Leaving or removing a member invalidates that member's external
/// reservation view without editing a second owner's saved game.
abstract final class SocialGroupLifecycle {
  static const actions = {
    'create_group_adventure',
    'join_group_adventure',
    'leave_group_adventure',
    'remove_group_adventure_member',
  };

  static Map<String, dynamic> apply({
    required HouseholdProvider game,
    required String ownerId,
    required String action,
    required Map<String, dynamic> payload,
    required Map<String, dynamic>? context,
  }) {
    Never unavailable() => throw const SocialGroupException();
    final uuid = RegExp(r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$');
    if (!actions.contains(action) ||
        context == null ||
        context.length != 6 ||
        context['version'] != 1 ||
        context['ownerId'] != ownerId ||
        context['action'] != action ||
        context['sourceId'] is! String ||
        !uuid.hasMatch(context['sourceId'] as String) ||
        context['fingerprint'] is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(context['fingerprint'] as String) ||
        context['facts'] is! Map<String, dynamic>) {
      unavailable();
    }
    final source = context['sourceId'] as String;
    final facts = context['facts'] as Map<String, dynamic>;
    if (facts.length != 3 ||
        !const {'adventureId', 'dragonId', 'memberId'}
            .every(facts.containsKey) ||
        facts['adventureId'] is! String ||
        AdventureCatalog.byId[facts['adventureId']]?.kind !=
            AdventureKind.group ||
        facts['dragonId'] is! String ||
        (facts['dragonId'] as String).isEmpty ||
        (facts['dragonId'] as String).length > 100) {
      unavailable();
    }
    if (action == 'create_group_adventure') {
      if (payload['adventureId'] != facts['adventureId']) unavailable();
    } else if (payload['lobbyId'] != source) {
      unavailable();
    }
    if (action == 'remove_group_adventure_member') {
      final member = facts['memberId'];
      if (member is! String ||
          !uuid.hasMatch(member) ||
          member == ownerId ||
          payload['memberId'] != member) {
        unavailable();
      }
    } else {
      if (facts['memberId'] != null) unavailable();
      final id = facts['dragonId'] as String;
      final dragon = game.ownedDragons.where((d) => d.id == id).firstOrNull;
      if (dragon == null || dragon.isEgg) unavailable();
      if (action == 'leave_group_adventure') {
        if (dragon.activeAdventureId != 'online-group:$source') unavailable();
        dragon.activeAdventureId = null;
      } else {
        if (payload['dragonId'] != id || dragon.activeAdventureId != null) {
          unavailable();
        }
        dragon.activeAdventureId = 'online-group:$source';
      }
    }
    return {'accepted': true, 'sourceId': source};
  }
}

class SocialGroupException implements Exception {
  const SocialGroupException();
}
