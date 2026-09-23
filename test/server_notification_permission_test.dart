import 'package:dragon_haven/screens/server_account_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const notifications = MethodChannel('nl.dragonhaven.app/notifications');

  testWidgets(
      'server Account Info shows and refreshes Android notification access',
      (tester) async {
    var status = 'notDetermined';
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notifications, (call) async {
      calls.add(call.method);
      return switch (call.method) {
        'permissionStatus' => status,
        'requestPermission' => switch (status) {
            'notDetermined' => () {
                status = 'granted';
                return true;
              }(),
            _ => status == 'granted',
          },
        'exactAlarmGranted' => true,
        'openNotificationSettings' => true,
        _ => true,
      };
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notifications, null));

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: DeviceNotificationAccess(hasEnabledCategories: true),
      ),
    ));
    await tester.pump();

    expect(find.byKey(const Key('allow-device-notifications')), findsOneWidget);
    expect(find.text('Allow Android to deliver DragonHaven notifications.'),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('allow-device-notifications')));
    await tester.pump();

    expect(find.text('Allowed on this device'), findsOneWidget);
    expect(
        find.byKey(const Key('manage-device-notifications')), findsOneWidget);
    expect(
        calls,
        containsAllInOrder([
          'permissionStatus',
          'exactAlarmGranted',
          'requestPermission',
          'permissionStatus',
          'exactAlarmGranted',
        ]));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('blocked access opens Android settings and explains exact timing',
      (tester) async {
    var status = 'denied';
    var exact = true;
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notifications, (call) async {
      calls.add(call.method);
      return switch (call.method) {
        'permissionStatus' => status,
        'exactAlarmGranted' => exact,
        'openNotificationSettings' => true,
        'openExactAlarmSettings' => true,
        _ => false,
      };
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notifications, null));

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: DeviceNotificationAccess(hasEnabledCategories: false),
      ),
    ));
    await tester.pump();

    expect(find.text('Android notifications are off for DragonHaven.'),
        findsOneWidget);
    expect(find.text('Choose at least one notification type below.'),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('allow-device-notifications')));
    await tester.pump();
    expect(calls, contains('openNotificationSettings'));
    expect(calls, isNot(contains('requestPermission')));

    status = 'granted';
    exact = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byKey(const Key('server-exact-alarm-permission-card')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('server-open-exact-alarm-settings')));
    await tester.pump();
    expect(calls, contains('openExactAlarmSettings'));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
