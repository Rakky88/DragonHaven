import '../providers/household_provider.dart';
import 'game_time_bridge.dart';
import 'server_entropy.dart';

/// Called only by the trusted worker with database-owned entropy and time.
/// Creation does not start incubation; the confirmed keeper-name command does.
abstract final class GameAccountInitialization {
  static Map<String, dynamic> create(
      {required String secretSeed, required DateTime now}) {
    final game = HouseholdProvider(
      persistenceEnabled: false,
      random: ServerEntropy(secretSeed, stream: 'rewards'),
      idGenerator: ServerEntropy(secretSeed, stream: 'identities').uuid,
      clock: () => now.toUtc(),
    );
    try {
      return GameTimeBridge.forUpload(game.exportState());
    } finally {
      game.dispose();
    }
  }
}
