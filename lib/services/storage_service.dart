import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract final class StorageService {
  static const currentKey = 'dragon_haven_state_v1';

  static Future<void> save(Map<String, dynamic> state) async {
    final encodedState = jsonEncode(state);
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(currentKey, encodedState);
    if (!saved) throw StateError('DragonHaven state could not be saved.');
  }

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(currentKey);
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
