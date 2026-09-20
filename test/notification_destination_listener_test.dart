import 'dart:async';
import 'dart:io';
import 'package:dragon_haven/services/canonical_account_bootstrap.dart';
import 'package:dragon_haven/services/canonical_account_handoff.dart';
import 'package:dragon_haven/services/notification_service.dart';
import 'package:dragon_haven/widgets/canonical_account_gate.dart';
import 'package:dragon_haven/widgets/notification_destination_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'notification survives an old mounted shell, delayed server check and failed retry',
      (tester) async {
    const owner = '11111111-1111-4111-8111-111111111111';
    final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('dh-notification-gate-')))!;
    final accounts = StreamController<int>.broadcast(sync: true);
    final deliveries = <HavenNotificationDestination>[];
    Completer<void>? check;
    var offline = false;
    late CanonicalAccountBootstrap<Object> bootstrap;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('nl.dragonhaven.app/network'),
            (_) async => null);
    HavenNotifications.takePendingNavigation();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runAsync(() => tester.pumpWidget(CanonicalAccountGate<Object>(
          createBootstrap: (beforeRetire) =>
              bootstrap = CanonicalAccountBootstrap(
            directory: directory,
            currentOwner: () => owner,
            sessionEpoch: () => 1,
            accountChanges: accounts.stream,
            beforeRetire: beforeRetire,
            readStatus: (_) async {
              await check?.future;
              if (offline) throw StateError('Synthetic offline');
              return CanonicalAccountStatus.parse({
                'owner_id': owner,
                'phase': 'active',
                'migration_enabled': true,
                'server_revision': 1,
                'source_revision': null
              }, owner);
            },
            prepareAndUploadLegacy: (_) async =>
                throw StateError('No legacy game'),
            activate: (_, __, ___) async => throw StateError('No migration'),
            openLegacy: (_) async => throw StateError('No legacy game'),
            openServer: (_, __) async =>
                CanonicalGameplayLease(Object(), close: () async {}),
          ),
          gameplayBuilder: (_, __) => MaterialApp(
              home: NotificationDestinationListener(
                  onDestination: deliveries.add, child: const Text('Ready'))),
          statusBuilder: (_, __) => const MaterialApp(home: Text('Checking')),
        )));
    Future<void> until(bool Function() done) async {
      for (var i = 0; !done() && i < 200; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)));
        await tester.pump();
      }
      expect(done(), true,
          reason: '${bootstrap.phase}: ${bootstrap.errorCode}');
    }

    await until(() => find.text('Ready').evaluate().isNotEmpty);
    check = Completer<void>();
    await tester.runAsync(() async {
      unawaited(bootstrap.synchronize());
    });
    // Before Flutter removes the old Navigator, a notification opens the app.
    expect(find.text('Ready'), findsOneWidget);
    HavenNotifications.openRemoteDestination('adventure_complete');
    await tester.pump();
    expect(find.text('Checking'), findsOneWidget);
    expect(deliveries, isEmpty);
    expect(HavenNotifications.pendingNavigation, isNotNull);
    // No connection: the intent remains pending for the subsequent retry.
    offline = true;
    check.complete();
    await until(() => bootstrap.phase == CanonicalBootstrapPhase.failed);
    expect(deliveries, isEmpty);
    check = null;
    offline = false;
    await tester.runAsync(() async {
      unawaited(bootstrap.synchronize());
    });
    await until(() => deliveries.isNotEmpty);
    expect(deliveries, [HavenNotificationDestination.adventureCompleted]);
    expect(HavenNotifications.pendingNavigation, isNull);
    // A second delivery while backgrounded also waits for server verification.
    await tester.runAsync(() async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    });
    HavenNotifications.openRemoteDestination('trials_full');
    await tester.pump();
    expect(deliveries, hasLength(1));
    check = Completer<void>();
    await tester.runAsync(() async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    await tester.pump();
    expect(deliveries, hasLength(1));
    check.complete();
    await until(() => deliveries.length == 2);
    expect(deliveries.last, HavenNotificationDestination.adventureTrials);
    await tester.pump();
    expect(deliveries, hasLength(2));
    await tester.pumpWidget(const SizedBox());
    var closed = false;
    final closing = bootstrap.shutdown().then((_) => closed = true);
    await until(() => closed);
    await closing;
    await accounts.close();
    await tester.runAsync(() => directory.delete(recursive: true));
  });
}
