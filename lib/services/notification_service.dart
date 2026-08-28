import 'dart:async';

import 'package:flutter/foundation.dart';
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
  specialEvents,
}

enum HavenNotificationDestination {
  tower,
  friends,
  adventureCompleted,
  adventureAvailable,
  adventureTrials,
  achievements,
}

abstract final class HavenNotifications {
  static const _channel = MethodChannel('nl.dragonhaven.app/notifications');
  static final _navigationEvents =
      StreamController<HavenNotificationDestination>.broadcast();
  static Set<HavenNotificationCategory> _enabled =
      HavenNotificationCategory.values.toSet();
  static HavenNotificationDestination? _pendingNavigation;

  static Stream<HavenNotificationDestination> get navigationEvents =>
      _navigationEvents.stream;

  static Future<void> initializeNavigation() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'notificationTap') return;
      _recordNavigation(call.arguments is Map
          ? (call.arguments as Map)['kind']?.toString()
          : null);
    });
    try {
      final kind = await _channel.invokeMethod<String>('takePendingNavigation');
      if (kind != null) _recordNavigation(kind, emit: false);
    } on MissingPluginException {
      // Tests and unsupported platforms intentionally have no native bridge.
    } on PlatformException {
      // A malformed launch intent must never block application startup.
    }
  }

  static HavenNotificationDestination? takePendingNavigation() {
    final destination = _pendingNavigation;
    _pendingNavigation = null;
    return destination;
  }

  @visibleForTesting
  static void handleNavigationKindForTest(String kind) =>
      _recordNavigation(kind);

  static void _recordNavigation(String? kind, {bool emit = true}) {
    final destination = switch (kind) {
      'adventure_complete' => HavenNotificationDestination.adventureCompleted,
      'special_adventure_available' =>
        HavenNotificationDestination.adventureAvailable,
      'trials_full' => HavenNotificationDestination.adventureTrials,
      'friend_request' ||
      'friend_accepted' ||
      'trade' =>
        HavenNotificationDestination.friends,
      'achievement' => HavenNotificationDestination.achievements,
      'egg' ||
      'evolution' ||
      'event' ||
      null =>
        HavenNotificationDestination.tower,
      _ => HavenNotificationDestination.tower,
    };
    _pendingNavigation = destination;
    if (emit) _navigationEvents.add(destination);
  }

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

  static Future<void> specialAdventureAvailable({
    required String id,
    required String title,
    required String body,
    DateTime? at,
  }) {
    if (!isEnabled(HavenNotificationCategory.specialEvents)) {
      return Future<void>.value();
    }
    if (at != null && at.isAfter(DateTime.now())) {
      return schedule(
        id: id,
        at: at,
        title: title,
        body: body,
        kind: 'special_adventure_available',
      );
    }
    return _showWhenBackground(
      category: HavenNotificationCategory.specialEvents,
      id: id,
      title: title,
      body: body,
      kind: 'special_adventure_available',
    );
  }

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
