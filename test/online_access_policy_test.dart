import 'dart:async';
import 'dart:io';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/privacy_screen.dart';
import 'package:dragon_haven/services/canonical_account_bootstrap.dart';
import 'package:dragon_haven/services/canonical_account_handoff.dart';
import 'package:dragon_haven/services/firebase_monitoring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'failed legacy heartbeat retires writers, blocks gameplay, reconnect restores once',
      () async {
    final directory = await Directory.systemTemp.createTemp('online-access-');
    final events = StreamController<int>.broadcast();
    const owner = '11111111-1111-4111-8111-111111111111';
    var connected = true, closes = 0, opens = 0;
    Future<CanonicalAccountStatus> status(String id) async {
      if (!connected) throw const SocketException('offline');
      return CanonicalAccountStatus.parse({
        'owner_id': id,
        'phase': 'legacy',
        'migration_enabled': false,
        'source_revision': null,
        'server_revision': null
      }, id);
    }

    final root = CanonicalAccountBootstrap<int>(
        directory: directory,
        currentOwner: () => owner,
        sessionEpoch: () => 1,
        accountChanges: events.stream,
        readStatus: status,
        checkConnection: status,
        prepareAndUploadLegacy: (_) async => throw StateError('unexpected'),
        activate: (_, __, ___) async => throw StateError('unexpected'),
        openServer: (_, __) async => throw StateError('unexpected'),
        openLegacy: (_) async =>
            CanonicalGameplayLease(++opens, close: () async {
              closes++;
            }));
    await root.synchronize();
    expect(root.gameplay, 1);
    await root.verifyConnection();
    expect(opens, 1); // Healthy checks must not restart a trial.
    connected = false;
    await root.verifyConnection();
    expect(root.gameplay, isNull);
    expect(closes, 1);
    expect(root.phase, CanonicalBootstrapPhase.failed);
    connected = true;
    await root.verifyConnection();
    expect(root.gameplay, 2);
    await root.shutdown();
    root.dispose();
    await events.close();
    await directory.delete(recursive: true);
  });

  test('server heartbeat never evicts gameplay for transport-only misses',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('server-heartbeat-');
    final events = StreamController<int>.broadcast();
    const owner = '11111111-1111-4111-8111-111111111111';
    var connected = true, closes = 0, opens = 0;
    Future<CanonicalAccountStatus> status(String id) async {
      if (!connected) throw const SocketException('offline');
      return CanonicalAccountStatus.parse({
        'owner_id': id,
        'phase': 'active',
        'migration_enabled': false,
        'source_revision': 6,
        'server_revision': 7
      }, id);
    }

    final root = CanonicalAccountBootstrap<int>(
        directory: directory,
        currentOwner: () => owner,
        sessionEpoch: () => 1,
        accountChanges: events.stream,
        readStatus: status,
        checkConnection: status,
        prepareAndUploadLegacy: (_) async => throw StateError('unexpected'),
        activate: (_, __, ___) async => throw StateError('unexpected'),
        openLegacy: (_) async => throw StateError('unexpected'),
        openServer: (_, __) async =>
            CanonicalGameplayLease(++opens, close: () async {
              closes++;
            }));
    await root.synchronize();
    expect(root.gameplay, 1);

    connected = false;
    for (var attempt = 0; attempt < 8; attempt++) {
      await root.verifyConnection();
    }
    expect(root.gameplay, 1);
    expect(root.phase, CanonicalBootstrapPhase.server);
    expect(closes, 0);

    connected = true;
    await root.verifyConnection();
    expect(root.gameplay, 1);
    expect(closes, 0);

    expect(root.phase, CanonicalBootstrapPhase.server);
    expect(opens, 1);
    expect(closes, 0);
    await root.shutdown();
    expect(closes, 1);
    root.dispose();
    await events.close();
    await directory.delete(recursive: true);
  });

  test('starter timer begins on name confirmation and cannot be reset twice',
      () async {
    var now = DateTime.utc(2026, 9, 20);
    final game = HouseholdProvider(clock: () => now, persistenceEnabled: false);
    now = now.add(const Duration(days: 2));
    await game.completeOnboarding('Keeper');
    expect(game.pet.stageStartedAt, now);
    final id = game.pet.id;
    now = now.add(const Duration(minutes: 30));
    await game.completeOnboarding('Second name');
    expect(game.pet.id, id);
    expect(game.accountName, 'Keeper');
    expect(game.pet.remainingForNextStage(now), const Duration(minutes: 30));
    game.dispose();
  });

  test('diagnostics choice persists separately and can be withdrawn', () async {
    expect(
        (await SharedPreferences.getInstance())
            .getBool(HavenFirebase.consentKey),
        isNull);
    await HavenFirebase.setDiagnosticsConsent(true);
    expect(HavenFirebase.diagnosticsEnabled.value, true);
    await HavenFirebase.setDiagnosticsConsent(false);
    expect(
        (await SharedPreferences.getInstance())
            .getBool(HavenFirebase.consentKey),
        false);
  });

  testWidgets(
      'age and notice require two explicit choices; failed save can retry',
      (tester) async {
    var calls = 0;
    await tester
        .pumpWidget(MaterialApp(home: PrivacyScreen(onAcknowledge: () async {
      calls++;
      if (calls == 1) throw const SocketException('offline');
    })));
    Future<void> reach(Key key) async {
      await tester.scrollUntilVisible(find.byKey(key), 500,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
    }

    const next = Key('privacy-continue');
    await reach(next);
    expect(tester.widget<FilledButton>(find.byKey(next)).onPressed, isNull);
    await reach(const Key('age-16-confirmation'));
    await tester.tap(find.byKey(const Key('age-16-confirmation')));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byKey(next)).onPressed, isNull);
    await reach(const Key('privacy-read-confirmation'));
    await tester.tap(find.byKey(const Key('privacy-read-confirmation')));
    await tester.pump();
    await reach(next);
    await tester.tap(find.byKey(next));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.textContaining('Could not save your confirmation'),
        findsOneWidget);
    await reach(next);
    await tester.tap(find.byKey(next));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });
}
