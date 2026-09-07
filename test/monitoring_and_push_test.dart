import 'dart:async';

import 'package:dragon_haven/config/firebase_config.dart';
import 'package:dragon_haven/config/online_config.dart';
import 'package:dragon_haven/services/diagnostic_reporter.dart';
import 'package:dragon_haven/services/firebase_monitoring.dart';
import 'package:dragon_haven/services/monitoring_policy.dart';
import 'package:dragon_haven/services/push_device_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('missing Firebase config keeps diagnostics usable without a project',
      () async {
    final firebase = await HavenFirebase.initialize(const HavenFirebaseConfig(
        enabled: false,
        projectId: '',
        environment: OnlineEnvironment.production));
    expect(firebase.available, isFalse);
    firebase.reporter.record(event());
    expect(firebase.reporter.recentEvents, hasLength(1));
  });

  test('debug production and local builds cannot opt into staging collection',
      () {
    const production = HavenFirebaseConfig(
        enabled: true,
        projectId: 'dragonhaven-prod',
        environment: OnlineEnvironment.production,
        allowDebugCollection: true);
    const staging = HavenFirebaseConfig(
        enabled: true,
        projectId: 'dragonhaven-stage',
        environment: OnlineEnvironment.staging,
        allowDebugCollection: true);
    const local = HavenFirebaseConfig(
        enabled: true,
        projectId: 'dragonhaven-local',
        environment: OnlineEnvironment.local,
        allowDebugCollection: true);
    expect(production.collectInBuild(release: false), isFalse);
    expect(production.collectInBuild(release: true), isTrue);
    expect(staging.collectInBuild(release: false), isTrue);
    expect(local.collectInBuild(release: true), isFalse);
  });

  test(
      'external telemetry excludes dynamic strings and private stack locations',
      () {
    final safe = MonitoringPolicy.attributes(event(
      operation: 'messages.private-person@example.org?token=secret-value',
      error: 'server replied secret-value private-person@example.org',
    ));
    expect(safe, {
      'operation_family': 'messages',
      'outcome': 'failure',
      'failure_category': 'other'
    });
    expect(MonitoringPolicy.family('secret-value'), 'other');
    final stack = MonitoringPolicy.safeStack(StackTrace.fromString(
      '#0 /Users/private-person/save-secret.dart:4\n'
      '#1 fn (package:dragon_haven/main.dart:22:7)\n'
      'https://example.org?access_token=secret-value\n'
      '#2 dart:async/future.dart:55:2',
    )).toString();
    expect(stack, contains('package:dragon_haven/main.dart:22:7'));
    expect(stack, isNot(contains('private-person')));
    expect(stack, isNot(contains('secret-value')));
    expect(stack, isNot(contains('https')));
  });

  test('registration respects permission and reports actual server readiness',
      () async {
    final token = FakeToken();
    final backend = FakePushBackend()..ready = false;
    var permission = false;
    final states = <bool>[];
    final controller = PushDeviceController(
        messaging: token,
        backend: backend,
        hasPermission: () async => permission,
        availabilityChanged: states.add);
    addTearDown(controller.dispose);
    await controller.synchronize(intent('a'));
    expect(backend.registrations, isEmpty);
    expect(token.autoInit, isFalse);
    permission = true;
    await controller.synchronize(intent('a'), force: true);
    expect(backend.registrations, ['a']);
    expect(states.last, isFalse,
        reason: 'a stored token is not a running worker');
    backend.ready = true;
    await controller.synchronize(intent('a'), force: true);
    expect(states.last, isTrue);
  });

  test('unchanged UI rebuilds do not repeatedly register; rotation does',
      () async {
    final backend = FakePushBackend();
    final controller = PushDeviceController(
        messaging: FakeToken(),
        backend: backend,
        hasPermission: () async => true,
        availabilityChanged: (_) {});
    addTearDown(controller.dispose);
    await controller.synchronize(intent('a'));
    for (var i = 0; i < 100; i++) {
      await controller.synchronize(intent('a'));
    }
    expect(backend.registrations, ['a']);
    await controller.synchronize(intent('a'), force: true);
    expect(backend.registrations, ['a', 'a']);
  });

  test('logout during registration revokes the late registration and token',
      () async {
    final gate = Completer<void>();
    final backend = FakePushBackend()..gate = gate.future;
    final token = FakeToken();
    final states = <bool>[];
    final controller = PushDeviceController(
        messaging: token,
        backend: backend,
        hasPermission: () async => true,
        availabilityChanged: states.add);
    addTearDown(controller.dispose);
    final first = controller.synchronize(intent('a'));
    await Future<void>.delayed(Duration.zero);
    final logout = controller.unregisterBeforeSignOut();
    gate.complete();
    await Future.wait([first, logout]);
    expect(backend.revocations, ['a']);
    expect(token.deleted, 1);
    expect(states, isNot(contains(true)));
  });

  test('account switch invalidates old response before new registration',
      () async {
    final gate = Completer<void>();
    final backend = FakePushBackend()..gate = gate.future;
    final token = FakeToken();
    final controller = PushDeviceController(
        messaging: token,
        backend: backend,
        hasPermission: () async => true,
        availabilityChanged: (_) {});
    addTearDown(controller.dispose);
    final first = controller.synchronize(intent('a'));
    await Future<void>.delayed(Duration.zero);
    final second = controller.synchronize(intent('b'));
    gate.complete();
    await Future.wait([first, second]);
    expect(backend.registrations, ['a', 'b']);
    expect(backend.revocations, ['a']);
    expect(token.deleted, 1);
  });

  test(
      'network failure falls back to polling and can recover with same identity',
      () async {
    final backend = FakePushBackend()..fail = true;
    final states = <bool>[];
    final controller = PushDeviceController(
        messaging: FakeToken(),
        backend: backend,
        hasPermission: () async => true,
        availabilityChanged: states.add);
    addTearDown(controller.dispose);
    await controller.synchronize(intent('a'));
    expect(states.last, isFalse);
    backend.fail = false;
    await controller.synchronize(intent('a'), force: true);
    expect(states.last, isTrue);
  });
}

DiagnosticEvent event({String operation = 'social.refresh', String? error}) =>
    DiagnosticEvent(
        operation: operation,
        correlationId: 'private-correlation',
        outcome: DiagnosticOutcome.failure,
        startedAt: DateTime.utc(2026, 9, 7),
        duration: const Duration(milliseconds: 123),
        errorCode: error);
PushDeviceIntent intent(String owner) => PushDeviceIntent(
    ownerId: owner,
    installationId: 'installation-$owner',
    languageCode: 'nl',
    enabledKinds: const ['friend_message']);

class FakeToken implements PushTokenClient {
  bool autoInit = false;
  int deleted = 0;
  @override
  Future<String?> token() async => 'synthetic-fcm-token';
  @override
  Future<void> deleteToken() async {
    deleted++;
  }

  @override
  Future<void> setAutoInitEnabled(bool enabled) async {
    autoInit = enabled;
  }
}

class FakePushBackend implements PushDeviceBackend {
  final registrations = <String>[];
  final revocations = <String>[];
  Future<void>? gate;
  bool ready = true;
  bool fail = false;
  @override
  Future<bool> register(PushDeviceIntent intent, String token) async {
    registrations.add(intent.ownerId);
    await gate;
    if (fail) throw StateError('synthetic transport failure');
    return ready;
  }

  @override
  Future<void> unregister(PushDeviceIntent intent) async {
    revocations.add(intent.ownerId);
  }
}
