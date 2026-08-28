import 'package:dragon_haven/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('nl.dragonhaven.app/notifications');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    HavenNotifications.takePendingNavigation();
    HavenNotifications.configure(HavenNotificationCategory.values.toSet());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
  });

  test('notification kinds map to their logical in-app destinations', () {
    final cases = <String, HavenNotificationDestination>{
      'adventure_complete': HavenNotificationDestination.adventureCompleted,
      'special_adventure_available':
          HavenNotificationDestination.adventureAvailable,
      'trials_full': HavenNotificationDestination.adventureTrials,
      'friend_request': HavenNotificationDestination.friends,
      'friend_accepted': HavenNotificationDestination.friends,
      'trade': HavenNotificationDestination.friends,
      'achievement': HavenNotificationDestination.achievements,
      'egg': HavenNotificationDestination.tower,
      'evolution': HavenNotificationDestination.tower,
    };

    for (final entry in cases.entries) {
      HavenNotifications.handleNavigationKindForTest(entry.key);
      expect(HavenNotifications.takePendingNavigation(), entry.value,
          reason: entry.key);
    }
  });

  test('disabled notification reasons do not reach the native bridge',
      () async {
    HavenNotifications.configure(
      HavenNotificationCategory.values
          .where((category) =>
              category != HavenNotificationCategory.friendRequests)
          .toSet(),
    );

    await HavenNotifications.friendRequest(
      id: 'muted-request',
      title: 'New friend request',
      body: 'Lyra wants to be friends.',
    );

    expect(calls, isEmpty);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('achievement notifications include the exact unlocked achievement',
      () async {
    await HavenNotifications.achievementUnlocked(
      id: 'book_wyrm',
      title: 'Achievement unlocked!',
      body: 'Book Wyrm',
    );

    expect(calls, hasLength(1));
    expect(calls.single.method, 'showWhenBackground');
    expect(calls.single.arguments, {
      'id': 'achievement-book_wyrm',
      'title': 'Achievement unlocked!',
      'body': 'Book Wyrm',
      'kind': 'achievement',
    });
  });

  test('evolution notifications identify the dragon and new form', () async {
    await HavenNotifications.evolutionUnlocked(
      id: 'evolution-nova-ascended',
      title: 'New evolution!',
      body: 'Nova evolved into Ascended.',
    );

    expect(calls, hasLength(1));
    expect(calls.single.method, 'showWhenBackground');
    expect(calls.single.arguments, {
      'id': 'evolution-nova-ascended',
      'title': 'New evolution!',
      'body': 'Nova evolved into Ascended.',
      'kind': 'evolution',
    });
  });

  test('friend requests use a stable background notification identity',
      () async {
    await HavenNotifications.friendRequest(
      id: 'request-42',
      title: 'New friend request',
      body: 'Lyra wants to be friends.',
    );

    expect(calls, hasLength(1));
    expect(calls.single.method, 'showWhenBackground');
    expect(calls.single.arguments, {
      'id': 'friend-request-request-42',
      'title': 'New friend request',
      'body': 'Lyra wants to be friends.',
      'kind': 'friend_request',
    });
  });

  test('a full Trial board is scheduled for the exact refill boundary',
      () async {
    final at = DateTime(2036, 8, 26, 10, 45);
    await HavenNotifications.trialsFull(
      at: at,
      title: 'Three Trials are ready',
      body: 'Your Trial board is full.',
    );

    expect(calls, hasLength(1));
    expect(calls.single.method, 'schedule');
    expect(calls.single.arguments, {
      'id': 'trials-full',
      'at': at.millisecondsSinceEpoch,
      'title': 'Three Trials are ready',
      'body': 'Your Trial board is full.',
      'kind': 'trials_full',
    });
  });

  test('enabled Special Adventure availability is scheduled with deep link',
      () async {
    final at = DateTime(2036, 5, 13);
    await HavenNotifications.specialAdventureAvailable(
      id: 'special-adventure-birthday-2036',
      at: at,
      title: 'A Special Adventure has appeared',
      body: 'A Wish on Golden Wings is waiting.',
    );

    expect(calls, hasLength(1));
    expect(calls.single.method, 'schedule');
    expect(calls.single.arguments, {
      'id': 'special-adventure-birthday-2036',
      'at': at.millisecondsSinceEpoch,
      'title': 'A Special Adventure has appeared',
      'body': 'A Wish on Golden Wings is waiting.',
      'kind': 'special_adventure_available',
    });
  });

  test('disabled Special Event notifications do not reach native bridge',
      () async {
    HavenNotifications.configure(
      HavenNotificationCategory.values
          .where(
              (category) => category != HavenNotificationCategory.specialEvents)
          .toSet(),
    );

    await HavenNotifications.specialAdventureAvailable(
      id: 'special-adventure-muted',
      at: DateTime(2036, 5, 13),
      title: 'A Special Adventure has appeared',
      body: 'A Wish on Golden Wings is waiting.',
    );

    expect(calls, isEmpty);
  });

  test('egg-ready notifications retain their hatch time and event kind',
      () async {
    final at = DateTime(2036, 8, 23, 12, 34, 56);
    await HavenNotifications.eggReady(
      id: 'egg-fixed-037',
      at: at,
      title: 'Your Mysterious Egg is ready',
      body: 'Something inside wants to hatch in the Rooftop Nest.',
    );

    expect(calls, hasLength(1));
    expect(calls.single.method, 'schedule');
    expect(calls.single.arguments, {
      'id': 'egg-fixed-037',
      'at': at.millisecondsSinceEpoch,
      'title': 'Your Mysterious Egg is ready',
      'body': 'Something inside wants to hatch in the Rooftop Nest.',
      'kind': 'egg',
    });
  });

  test('an elapsed in-app egg timer shows the same notification immediately',
      () async {
    await HavenNotifications.showEggReadyNow(
      id: 'egg-fixed-037',
      title: 'Your Mysterious Egg is ready',
      body: 'Something inside wants to hatch in the Rooftop Nest.',
    );

    expect(calls, hasLength(1));
    expect(calls.single.method, 'showNow');
    expect(calls.single.arguments, {
      'id': 'egg-fixed-037',
      'title': 'Your Mysterious Egg is ready',
      'body': 'Something inside wants to hatch in the Rooftop Nest.',
      'kind': 'egg',
    });
  });
}
