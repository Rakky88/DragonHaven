import '../models/notification_settings.dart';
export '../models/notification_settings.dart';

/// Android reminders are scheduled by the client after applying a committed
/// snapshot. The shared rules never send a notification before a transaction
/// commits. Server social push uses its separate durable SQL outbox.
abstract final class HavenNotifications {
  static void configure(Set<HavenNotificationCategory> enabled) {}
  static Future<HavenNotificationPermissionStatus>
      platformPermissionStatus() async =>
          HavenNotificationPermissionStatus.denied;
  static Future<bool> platformPermissionGranted() async => false;
  static Future<bool> exactAlarmPermissionGranted() async => false;
  static Future<void> cancel(String id) async {}

  static Future<void> schedule({
    required String id,
    required DateTime at,
    required String title,
    required String body,
    String kind = 'event',
  }) async {}

  static Future<void> eggReady({
    required String id,
    required DateTime at,
    required String title,
    required String body,
  }) async {}

  static Future<void> achievementUnlocked({
    required String id,
    required String title,
    required String body,
  }) async {}

  static Future<void> evolutionUnlocked({
    required String id,
    required String title,
    required String body,
  }) async {}

  static Future<void> trialsFull({
    required DateTime at,
    required String title,
    required String body,
  }) async {}

  static Future<void> specialAdventureAvailable({
    required String id,
    required String title,
    required String body,
    DateTime? at,
  }) async {}
}
