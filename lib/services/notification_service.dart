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

  static Future<void> achievementUnlocked({
    required String id,
    required String title,
    required String body,
  }) =>
      _showWhenBackground(
        id: 'achievement-$id',
        title: title,
        body: body,
        kind: 'achievement',
      );

  static Future<void> evolutionUnlocked({
    required String id,
    required String title,
    required String body,
  }) =>
      _showWhenBackground(
        id: id,
        title: title,
        body: body,
        kind: 'evolution',
      );

  static Future<void> _showWhenBackground({
    required String id,
    required String title,
    required String body,
    required String kind,
  }) async {
    try {
      await _channel.invokeMethod<bool>('showWhenBackground', {
        'id': id,
        'title': title,
        'body': body,
        'kind': kind,
      });
    } on MissingPluginException {
      // Tests and unsupported platforms intentionally have no native bridge.
    } on PlatformException {
      // Denied permission never changes gameplay state.
    }
  }
}
