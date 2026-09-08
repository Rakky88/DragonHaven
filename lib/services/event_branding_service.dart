import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../providers/household_provider.dart';
import '../theme/event_appearance.dart';

/// Exports the existing Amsterdam calendar, plus this save's personal previews.
/// Android can change the launcher locally at boundaries while Flutter is idle.
List<Map<String, Object>> eventBrandingSchedule(
    DateTime now, Iterable<SpecialAdventureWindow> active) {
  final windows = {for (final window in active) window.key: window};
  var cursor = now;
  for (var year = 0; year < 3; year++) {
    for (final window in nextSpecialAdventureWindowsAfter(cursor)) {
      windows[window.key] = window;
    }
    cursor = DateTime.utc(cursor.year + 1, cursor.month, cursor.day);
  }
  final sorted = windows.values.where((w) => w.endsAt.isAfter(now)).toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return [
    for (final window in sorted)
      if (EventAppearance.logoKeys.containsKey(window.event.id))
        {
          'key': window.key,
          'logo': EventAppearance.logoKeys[window.event.id]!,
          'start': window.startsAt.millisecondsSinceEpoch,
          'end': window.endsAt.millisecondsSinceEpoch,
          'preview': window.key.contains(':preview:'),
        },
  ];
}

class EventBrandingService {
  static const channel = MethodChannel('nl.dragonhaven.app/event_branding');
  String? _lastSchedule;

  Future<void> synchronize(List<Map<String, Object>> schedule) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final encoded = jsonEncode(schedule);
    if (encoded == _lastSchedule) return;
    try {
      await channel.invokeMethod<void>('setSchedule', {'windows': schedule});
      _lastSchedule = encoded;
    } on MissingPluginException {
      // Older desktop/test hosts still show the event art inside Flutter.
    } on PlatformException {
      // Cosmetic work never prevents opening the game; retry on next refresh.
    }
  }
}
