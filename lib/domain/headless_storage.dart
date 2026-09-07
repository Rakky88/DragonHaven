/// Device storage is unavailable to the server domain. Its caller owns the
/// database transaction and must persist the returned state atomically.
/// Accidental use of the device load/save path fails instead of losing a save.
abstract final class StorageService {
  static Never _unavailable() => throw UnsupportedError(
      'Device storage is unavailable in the game domain');

  static Future<Map<String, dynamic>?> load() async => _unavailable();
  static Future<Map<String, dynamic>?> loadBackup() async => _unavailable();
  static Future<void> preserveCurrentForRecovery() async => _unavailable();
  static Future<bool> promoteBackup() async => _unavailable();
  static Future<void> save(Map<String, dynamic> state) async => _unavailable();
}
