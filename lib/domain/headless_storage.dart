import '../services/legacy_game_storage.dart';

class DeviceLegacyGameStorage implements LegacyGameStorage {
  const DeviceLegacyGameStorage();
  @override
  bool get allowsFreshState => false;
  @override
  Map<String, dynamic> prepareSave(Map<String, dynamic> state) => state;
  @override
  Future<Map<String, dynamic>?> load() => StorageService.load();
  @override
  Future<Map<String, dynamic>?> loadBackup() => StorageService.loadBackup();
  @override
  Future<void> preserveCurrentForRecovery() =>
      StorageService.preserveCurrentForRecovery();
  @override
  Future<bool> promoteBackup() => StorageService.promoteBackup();
  @override
  Future<void> save(Map<String, dynamic> state) => StorageService.save(state);
}

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
