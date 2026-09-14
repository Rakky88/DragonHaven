import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

abstract final class StorageService {
  static const currentKey = 'dragon_haven_state_v1';
  static const backupKey = 'dragon_haven_state_v1_backup';
  static const recoveryKey = 'dragon_haven_state_v1_recovery';
  static const deviceIdKey = 'dragon_haven_device_id_v1';
  static const cloudBaseRevisionPrefix = 'dragon_haven_cloud_base_revision_v1_';
  static const automaticCloudBackupPrefix =
      'dragon_haven_automatic_cloud_backup_v1_';

  static const legacyRecoveryEvidenceKey =
      'dragon_haven_pre_recovery_upgrade_v1';

  /// Capture older installations' surviving slots before startup migrations or
  /// autosaves rotate them. Unknown account ownership is intentionally retained;
  /// these bytes are evidence, never silently imported into a signed-in account.
  static Future<void> preserveLegacyRecoveryEvidence() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(legacyRecoveryEvidenceKey)) return;
    final slots = <String, String>{
      for (final key in [currentKey, backupKey, recoveryKey])
        if (prefs.getString(key) case final raw?) key: raw,
    };
    if (slots.isEmpty) return;
    if (!await prefs.setString(legacyRecoveryEvidenceKey, jsonEncode(slots))) {
      throw StateError('Existing recovery evidence could not be preserved.');
    }
  }

  static Future<List<Map<String, dynamic>>> legacyRecoverySummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final evidence = _decode(prefs.getString(legacyRecoveryEvidenceKey));
    if (evidence == null) return const [];
    final result = <Map<String, dynamic>>[];
    for (final key in [currentKey, backupKey, recoveryKey]) {
      final raw = evidence[key];
      final state = raw is String ? _decode(raw) : null;
      if (state == null || state['pet'] is! Map) continue;
      final pet = state['pet'] as Map;
      result.add({
        'slot': key == currentKey
            ? 1
            : key == backupKey
                ? 2
                : 3,
        'accountName': state['accountName']?.toString() ?? '',
        'pet': {'coins': pet['coins'], 'gems': pet['gems']},
        'totalAdventuresCompleted': state['totalAdventuresCompleted'],
      });
    }
    return result;
  }

  static bool lastLoadRecoveredFromBackup = false;

  static Future<void> save(Map<String, dynamic> state) async {
    final encodedState = jsonEncode(state);
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString(currentKey);
    if (previous != null && _decode(previous) != null) {
      final backedUp = await prefs.setString(backupKey, previous);
      if (!backedUp) {
        throw StateError('DragonHaven backup could not be saved.');
      }
    }
    final saved = await prefs.setString(currentKey, encodedState);
    if (!saved) throw StateError('DragonHaven state could not be saved.');
  }

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    lastLoadRecoveredFromBackup = false;
    final raw = prefs.getString(currentKey);
    final current = _decode(raw);
    if (current != null) return current;
    if (raw != null) await prefs.setString(recoveryKey, raw);

    final backupRaw = prefs.getString(backupKey);
    final backup = _decode(backupRaw);
    if (backup == null) return null;
    if (backupRaw != null) await prefs.setString(currentKey, backupRaw);
    lastLoadRecoveredFromBackup = true;
    return backup;
  }

  static Future<Map<String, dynamic>?> loadBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(backupKey));
  }

  static Future<void> preserveCurrentForRecovery() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(currentKey);
    if (raw != null) await prefs.setString(recoveryKey, raw);
  }

  static const restoreCheckpointPrefix = 'dragon_haven_restore_checkpoints_v1_';
  static const recoveryReviewPrefix = 'dragon_haven_recovery_review_v1_';

  /// Separate from rolling autosave/corruption backups. Retain the first
  /// checkpoint and four recent ones, so repeated restores cannot erase it.
  static Future<void> preserveBeforeCloudRestore(Map<String, dynamic> state,
      {String? ownerId}) async {
    final encoded = jsonEncode(state); // Freeze before the first await.
    final prefs = await SharedPreferences.getInstance();
    final key = '$restoreCheckpointPrefix${ownerId ?? "local"}';
    final existing = prefs.getStringList(key) ?? <String>[];
    final entry = jsonEncode({
      'id': const Uuid().v4(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'ownerId': ownerId,
      'state': jsonDecode(encoded),
    });
    final next = [...existing, entry];
    if (next.length > 5) next.removeRange(1, next.length - 4);
    if (!await prefs.setStringList(key, next)) {
      throw StateError('Pre-restore checkpoint could not be saved.');
    }
  }

  static Future<List<Map<String, dynamic>>> loadRestoreCheckpoints(
      String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    return [
      for (final raw
          in (prefs.getStringList('$restoreCheckpointPrefix$ownerId') ??
                  <String>[])
              .reversed)
        if (_decode(raw) case final entry?)
          if (entry['ownerId'] == ownerId &&
              entry['state'] is Map &&
              entry['id'] is String &&
              (entry['id'] as String).isNotEmpty &&
              entry['createdAt'] is String &&
              DateTime.tryParse(entry['createdAt'] as String) != null)
            entry,
    ];
  }

  static Future<bool> promoteBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(backupKey);
    if (_decode(raw) == null || raw == null) return false;
    final promoted = await prefs.setString(currentKey, raw);
    if (promoted) lastLoadRecoveredFromBackup = true;
    return promoted;
  }

  static Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = const Uuid().v4();
    final saved = await prefs.setString(deviceIdKey, generated);
    if (!saved) throw StateError('DragonHaven device ID could not be saved.');
    return generated;
  }

  static Future<int?> loadCloudBaseRevision(String userId) async {
    if (userId.trim().isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$cloudBaseRevisionPrefix$userId');
  }

  static Future<void> saveCloudBaseRevision(
    String userId,
    int revision,
  ) async {
    if (userId.trim().isEmpty || revision < 0) {
      throw ArgumentError('Invalid cloud base revision.');
    }
    final prefs = await SharedPreferences.getInstance();
    final saved =
        await prefs.setInt('$cloudBaseRevisionPrefix$userId', revision);
    if (!saved) {
      throw StateError('Cloud base revision could not be saved.');
    }
  }

  static Future<DateTime?> loadAutomaticCloudBackupAt(String userId) async {
    if (userId.trim().isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final milliseconds = prefs.getInt('$automaticCloudBackupPrefix$userId');
    return milliseconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }

  static Future<void> saveAutomaticCloudBackupAt(
    String userId,
    DateTime at,
  ) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('Invalid automatic cloud backup account.');
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setInt(
      '$automaticCloudBackupPrefix$userId',
      at.millisecondsSinceEpoch,
    );
    if (!saved) {
      throw StateError('Automatic cloud backup timestamp could not be saved.');
    }
  }

  static Map<String, dynamic>? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
