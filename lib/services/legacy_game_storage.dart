/// A save destination captured by one legacy gameplay instance. Account changes
/// must replace the instance, never redirect an existing writer to another key.
abstract interface class LegacyGameStorage {
  bool get allowsFreshState;
  Map<String, dynamic> prepareSave(Map<String, dynamic> state);
  Future<Map<String, dynamic>?> load();
  Future<Map<String, dynamic>?> loadBackup();
  Future<void> preserveCurrentForRecovery();
  Future<bool> promoteBackup();
  Future<void> save(Map<String, dynamic> state);
}
