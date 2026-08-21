import 'package:flutter/services.dart';

abstract final class HavenNotifications {
  static const _channel = MethodChannel('nl.dragonhaven.app/notifications');

  static Future<void> schedule({
    required String id,
    required DateTime at,
    required String title,
    required String body,
  }) async {
    if (!at.isAfter(DateTime.now())) return;
    try {
      await _channel.invokeMethod<void>('schedule', {
        'id': id,
        'at': at.millisecondsSinceEpoch,
        'title': title,
        'body': body,
      });
    } on MissingPluginException {
      // Tests and unsupported platforms intentionally have no native bridge.
    } on PlatformException {
      // Denied permission never changes gameplay state.
    }
  }
}
