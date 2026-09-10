import '../models/egg_altar.dart';
import '../providers/household_provider.dart';

/// The selected amount is player input; membership and the shared project's
/// remaining capacity are facts sealed by the database. The commit stores the
/// debit and project progress atomically, without granting personal rewards.
abstract final class ConclaveBeacon {
  static Map<String, dynamic> donate({
    required HouseholdProvider game,
    required String ownerId,
    required String conclaveId,
    required int amount,
    required Map<String, dynamic>? context,
  }) {
    Never unavailable() =>
        throw const BeaconException('game_action_unavailable');
    if (!RegExp(r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$')
            .hasMatch(conclaveId) ||
        amount < 1 ||
        amount > 5000 ||
        context == null ||
        context.length != 6 ||
        context['version'] != 1 ||
        context['ownerId'] != ownerId ||
        context['action'] != 'donate_beacon' ||
        context['sourceId'] != conclaveId ||
        context['fingerprint'] is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(context['fingerprint'] as String) ||
        context['facts'] is! Map<String, dynamic>) {
      unavailable();
    }
    final facts = context['facts'] as Map<String, dynamic>;
    if (facts.length != 3 ||
        facts['goal'] != 5000 ||
        facts['amount'] != amount ||
        facts['beforeFragments'] is! int ||
        facts['beforeFragments'] < 0 ||
        facts['beforeFragments'] + amount > 5000) {
      unavailable();
    }
    final cost = WeaveWallet(amount, 0, 0);
    if (!game.eggAltar.wallet.covers(cost)) {
      throw const BeaconException('insufficient_materials');
    }
    game.eggAltar.wallet = game.eggAltar.wallet - cost;
    game.eggAltar.revision++;
    return {'donated': amount, 'fragments': facts['beforeFragments'] + amount};
  }
}

class BeaconException implements Exception {
  const BeaconException(this.code);
  final String code;
}
