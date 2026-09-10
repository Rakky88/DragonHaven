import '../providers/household_provider.dart';

/// Only owned dragon bindings change here. Event eligibility, both keeper
/// identities and the existing duration formula are sealed and committed by SQL.
abstract final class SocialPairLifecycle {
  static const actions = {
    'invite_pair_adventure',
    'accept_pair_adventure',
    'decline_pair_adventure',
    'start_pair_adventure',
    'cancel_pair_adventure',
  };
  static Map<String, dynamic> apply(
      {required HouseholdProvider game,
      required String ownerId,
      required String action,
      required Map<String, dynamic> payload,
      required Map<String, dynamic>? context}) {
    Never invalid() => throw const SocialPairException();
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
      invalid();
    }
    final source = context['sourceId'] as String;
    final facts = context['facts'] as Map<String, dynamic>;
    if (facts.length != 7 ||
        !const {
          'eventId',
          'dragonId',
          'otherId',
          'keeperCode',
          'occurrenceKey',
          'simulated',
          'role'
        }.every(facts.containsKey) ||
        facts['eventId'] != 'valentine_two_heartlights' ||
        facts['otherId'] is! String ||
        !uuid.hasMatch(facts['otherId'] as String) ||
        facts['otherId'] == ownerId ||
        facts['keeperCode'] is! String ||
        !RegExp(r'^DH-[0-9A-F]{8}$').hasMatch(facts['keeperCode'] as String) ||
        facts['occurrenceKey'] is! String ||
        (facts['occurrenceKey'] as String).isEmpty ||
        (facts['occurrenceKey'] as String).length > 200 ||
        facts['simulated'] is! bool ||
        !const {'creator', 'partner'}.contains(facts['role'])) {
      invalid();
    }
    final creator = facts['role'] == 'creator';
    if (action == 'invite_pair_adventure') {
      if (!creator ||
          payload['keeperCode'] is! String ||
          (payload['keeperCode'] as String).trim().toUpperCase() !=
              facts['keeperCode']) {
        invalid();
      }
    } else if (payload['adventureId'] != source) {
      invalid();
    }
    if ((action == 'accept_pair_adventure' ||
            action == 'decline_pair_adventure') &&
        creator) {
      invalid();
    }
    if (action == 'start_pair_adventure' && !creator) {
      invalid();
    }
    final id = facts['dragonId'];
    final noDragon = action == 'decline_pair_adventure' ||
        (action == 'cancel_pair_adventure' && !creator && id == null);
    if (noDragon) {
      if (id != null) {
        invalid();
      }
    } else {
      if (id is! String || id.isEmpty || id.length > 100) {
        invalid();
      }
      final dragon = game.ownedDragons.where((d) => d.id == id).firstOrNull;
      if (dragon == null || dragon.isEgg) {
        invalid();
      }
      if (action == 'invite_pair_adventure' ||
          action == 'accept_pair_adventure') {
        if (payload['dragonId'] != id || dragon.activeAdventureId != null) {
          invalid();
        }
        dragon.activeAdventureId = 'online-seasonal:$source';
      } else {
        if (dragon.activeAdventureId != 'online-seasonal:$source') {
          invalid();
        }
        if (action == 'cancel_pair_adventure') dragon.activeAdventureId = null;
      }
    }
    return {'accepted': true, 'sourceId': source};
  }
}

class SocialPairException implements Exception {
  const SocialPairException();
}
