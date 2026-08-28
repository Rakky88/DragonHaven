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
