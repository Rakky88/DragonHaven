import 'dart:io';

import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/models/achievement.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/server_dragonhaven_app.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/canonical_ui_server.dart';

class _MountedServerApp {
  _MountedServerApp({
    required this.directory,
    required this.server,
    required this.session,
    required this.online,
    required this.auth,
  });

  final Directory directory;
  final CanonicalUiServer server;
  final CanonicalGameSession session;
  final OnlineAccountProvider online;
  final SupabaseClient auth;

  static Future<_MountedServerApp> mount(
    WidgetTester tester, {
    required Map<String, dynamic> state,
    required DateTime now,
  }) async {
    late Directory directory;
    late CanonicalGameSession session;
    final server = CanonicalUiServer(state)..now = now;
    final online = OnlineAccountProvider(
      repository: DisabledSocialRepository(),
      serverOwned: true,
      inventorySnapshot: () => throw StateError(
        'A server screen attempted to read a local inventory.',
      ),
    );
    final auth = SupabaseClient(
      'https://synthetic.invalid',
      'synthetic-public',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );
    await tester.runAsync(() async {
      directory =
          await Directory.systemTemp.createTemp('dh-trial-refresh-widget-');
      session = CanonicalGameSession(
        connection: CanonicalUiConnection(server),
        directory: directory,
      );
      await session.synchronize();
    });
    await tester.runAsync(() => tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: session),
            ChangeNotifierProvider.value(value: online),
          ],
          child: ServerDragonHavenApp(auth: auth),
        )));
    await tester.pump(const Duration(milliseconds: 500));
    return _MountedServerApp(
      directory: directory,
      server: server,
      session: session,
      online: online,
      auth: auth,
    );
  }

  Future<void> drain(WidgetTester tester) async {
    // Parallel Windows runs can hold the filesystem-backed receipt journal
    // longer than an isolated test, while the production transport timeout is
    // much larger. Wait for the real session fence instead of using settle().
    for (var attempt = 0; attempt < 1000 && session.busy; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(
      session.busy,
      isFalse,
      reason: 'sent=${server.sent.map((intent) => intent.action).toList()} '
          'revision=${server.revision} '
          'confirmed=${session.confirmedSnapshot?.serverRevision} '
          'display=${session.snapshot?.serverRevision} '
          'speculative=${session.snapshot?.isSpeculative} '
          'canAct=${session.canAct} '
          'error=${session.errorCode}',
    );
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    online.dispose();
    await tester.runAsync(() async {
      await session.close();
      await directory.delete(recursive: true);
    });
    var disposed = false;
    final closing = auth.dispose().then((_) => disposed = true);
    final deadline = Stopwatch()..start();
    while (!disposed && deadline.elapsed < const Duration(seconds: 10)) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(disposed, isTrue);
    await closing;
  }
}

Map<String, dynamic> _trialState(
  DateTime now, {
  required DateTime refilledAt,
}) {
  final game = HouseholdProvider(
    persistenceEnabled: false,
    clock: () => now,
  )
    ..onboardingComplete = true
    ..tutorialCompleted = true
    ..trialOffers = []
    ..trialRefilledAt = refilledAt;
  game.pet
    ..stage = DragonStage.hatchling
    ..firstEgg = false
    ..favorite = true
    ..name = 'Refresh keeper';
  game.pendingPresentations.clear();
  game.unlockedAchievementIds.addAll(achievementCatalog.map((a) => a.id));
  final state = game.exportState();
  game.dispose();
  return state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'opening an overdue account performs one silent canonical refresh',
      (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final now = DateTime.utc(2026, 9, 26, 12, 14, 59);
    final app = await _MountedServerApp.mount(
      tester,
      state: _trialState(
        now,
        refilledAt: DateTime.utc(2026, 9, 26, 11, 45),
      ),
      now: now,
    );
    await app.drain(tester);

    expect(app.server.sent.map((intent) => intent.action), ['refresh']);
    expect(app.session.snapshot!.trialOffers, hasLength(1));
    // The optimistic refresh keeps the ordinary shell rendered; it does not
    // replace gameplay with a blocking connection screen.
    expect(find.text('Checking your progress'), findsNothing);
    await tester.pump();
    expect(app.server.sent, hasLength(1));

    await app.close(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'an overdue refill waits for an active Trial then refreshes exactly once',
      (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final before = DateTime.utc(2026, 9, 26, 12, 14, 59);
    var state = _trialState(
      before,
      refilledAt: DateTime.utc(2026, 9, 26, 11, 45),
    );
    final dragonId = state['pet']['id'] as String;
    state['trialOffers'] = [
      TrialOffer(
        id: 'boundary-trial',
        kind: TrialKind.cavernFlight,
        appearedAt: DateTime.utc(2026, 9, 26, 12),
      ).toJson(),
    ];
    final started = await GameCommandEngine.execute(
      state: state,
      action: 'start_trial',
      payload: {'offerId': 'boundary-trial', 'dragonId': dragonId},
      secretSeed: List.filled(32, 'a1').join(),
      now: before,
      keeperId: CanonicalUiServer.owner,
    );
    final startedState = started['state'] as Map<String, dynamic>;
    startedState['trialRefilledAt'] =
        DateTime.utc(2026, 9, 26, 11, 45).toIso8601String();
    final app = await _MountedServerApp.mount(
      tester,
      state: startedState,
      now: before,
    );

    await tester.pump();
    expect(app.server.sent, isEmpty);

    // Ending the reserved game changes the authoritative session. The pending
    // boundary is released by that session transition, without a polling loop.
    app.server.state.remove('_activeGameAttempt');
    app.server.revision++;
    await tester.runAsync(app.session.synchronize);
    expect(app.session.snapshot!.trialAttempt, isNull);
    expect(app.session.canAct, isTrue);
    await app.drain(tester);

    expect(app.server.sent.map((intent) => intent.action), ['refresh']);
    expect(
      app.session.snapshot!.data['trials']['trialRefilledAt'],
      DateTime.utc(2026, 9, 26, 12).toIso8601String(),
    );
    await tester.pump();
    expect(app.server.sent, hasLength(1));

    await app.close(tester);
    expect(tester.takeException(), isNull);
  });
}
