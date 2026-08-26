import 'package:dragon_haven/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('nl.dragonhaven.app/notifications');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    HavenNotifications.configure(HavenNotificationCategory.values.toSet());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
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
