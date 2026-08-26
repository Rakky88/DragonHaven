import 'package:flutter/services.dart';

enum HavenNotificationCategory {
  eggReady,
  achievements,
  evolutions,
  friendRequests,
  friendAcceptances,
  tradeRequests,
  tradeReturns,
  tradeCompletions,
  trialsFull,
}

abstract final class HavenNotifications {
  static const _channel = MethodChannel('nl.dragonhaven.app/notifications');
  static Set<HavenNotificationCategory> _enabled =
      HavenNotificationCategory.values.toSet();

  static void configure(Set<HavenNotificationCategory> enabled) {
    _enabled = Set.of(enabled);
  }

  static bool isEnabled(HavenNotificationCategory category) =>
      _enabled.contains(category);

  static Future<void> schedule({
    required String id,
    required DateTime at,
    required String title,
    required String body,
    String kind = 'event',
  }) async {
    if (!at.isAfter(DateTime.now())) return;
    try {
      await _channel.invokeMethod<void>('schedule', {
        'id': id,
        'at': at.millisecondsSinceEpoch,
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

  static Future<void> eggReady({
    required String id,
    required DateTime at,
    required String title,
    required String body,
  }) =>
      isEnabled(HavenNotificationCategory.eggReady)
          ? schedule(
              id: id,
              at: at,
              title: title,
              body: body,
              kind: 'egg',
            )
          : Future<void>.value();

  static Future<void> showEggReadyNow({
    required String id,
    required String title,
    required String body,
  }) async {
    if (!isEnabled(HavenNotificationCategory.eggReady)) return;
    try {
      await _channel.invokeMethod<bool>('showNow', {
        'id': id,
        'title': title,
        'body': body,
        'kind': 'egg',
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
        category: HavenNotificationCategory.achievements,
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
        category: HavenNotificationCategory.evolutions,
        id: id,
        title: title,
        body: body,
        kind: 'evolution',
      );

  static Future<void> tradeUpdate({
    required String id,
    required String title,
    required String body,
    required HavenNotificationCategory category,
  }) =>
      _showWhenBackground(
        category: category,
        id: 'trade-$id',
        title: title,
        body: body,
        kind: 'trade',
      );

  static Future<void> friendRequest({
    required String id,
    required String title,
    required String body,
  }) =>
      _showWhenBackground(
        category: HavenNotificationCategory.friendRequests,
        id: 'friend-request-$id',
        title: title,
        body: body,
        kind: 'friend_request',
      );

  static Future<void> friendAccepted({
    required String id,
    required String title,
    required String body,
  }) =>
      _showWhenBackground(
        category: HavenNotificationCategory.friendAcceptances,
        id: 'friend-accepted-$id',
        title: title,
        body: body,
        kind: 'friend_accepted',
      );

  static Future<void> trialsFull({
    required DateTime at,
    required String title,
    required String body,
  }) =>
      isEnabled(HavenNotificationCategory.trialsFull)
          ? schedule(
              id: 'trials-full',
              at: at,
              title: title,
              body: body,
              kind: 'trials_full',
            )
          : Future<void>.value();

  static Future<void> cancel(String id) async {
    try {
      await _channel.invokeMethod<void>('cancel', {'id': id});
    } on MissingPluginException {
      // Tests and unsupported platforms intentionally have no bridge.
    } on PlatformException {
      // Cancelling a reminder must never block saving its preference.
    }
  }

  static Future<void> _showWhenBackground({
    required HavenNotificationCategory category,
    required String id,
    required String title,
    required String body,
    required String kind,
  }) async {
    if (!isEnabled(category)) return;
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
