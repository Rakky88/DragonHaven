import 'package:dragon_haven/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('nl.dragonhaven.app/notifications');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
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
}
