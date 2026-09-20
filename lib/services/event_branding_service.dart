import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../providers/household_provider.dart';
import '../theme/event_appearance.dart';

/// Exports the existing Amsterdam calendar, plus this save's personal previews.
/// Android can change the launcher locally at boundaries while Flutter is idle.
List<Map<String, Object>> eventBrandingSchedule(
    DateTime now, Iterable<SpecialAdventureWindow> active,
    {Map<String, DateTime> dismissedUntil = const {}}) {
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
      if (EventAppearance.logoKeys.containsKey(window.event.id) &&
          (window.key.contains(':preview:') ||
              !(dismissedUntil[window.event.id]?.isAfter(window.startsAt) ??
                  false)))
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
  static String _launchLogoAsset = 'assets/images/dragonhaven_logo.png';
  static String get launchLogoAsset => _launchLogoAsset;

  static Future<String> readLaunchLogoAsset() async {
    try {
      final logo = await channel.invokeMethod<String>('getSelectedLogo');
      _launchLogoAsset = EventAppearance.logoKeys.values.contains(logo)
          ? 'assets/images/event_logos/$logo.png'
          : 'assets/images/dragonhaven_logo.png';
    } on MissingPluginException {
      // Unsupported hosts use the ordinary DragonHaven launch art.
    } on PlatformException {
      // A cosmetic lookup must not delay the authenticated server check.
    }
    return _launchLogoAsset;
  }

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
