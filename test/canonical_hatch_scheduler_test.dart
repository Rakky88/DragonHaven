import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_hatch_scheduler.dart';
import 'support/canonical_ui_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late CanonicalUiServer server;
  late CanonicalGameSession session;
  late CanonicalHatchScheduler scheduler;
  Future<void> setup(WidgetTester tester, {bool ready = true}) async {
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('dh-auto-hatch-');
      final now = DateTime.utc(2026, 9, 20, 12);
      final game =
          HouseholdProvider(persistenceEnabled: false, clock: () => now);
      game.onboardingComplete = true;
      game.pet.stageStartedAt =
          ready ? now.subtract(const Duration(days: 3)) : now;
      server = CanonicalUiServer(game.exportState())..now = now;
      game.dispose();
      session = CanonicalGameSession(
          connection: CanonicalUiConnection(server), directory: directory);
      await session.synchronize();
    });
    scheduler = CanonicalHatchScheduler(session);
    addTearDown(() async {
      scheduler.dispose();
      session.dispose();
      await directory.delete(recursive: true);
    });
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 1));
    for (var i = 0; i < 500 && session.busy; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(session.busy, false);
  }

  testWidgets(
      'ready egg hatches automatically once and preserves the naming reveal',
      (tester) async {
    await setup(tester);
    final egg = session.snapshot!.nest!.id;
    await finish(tester);
    expect(server.sent.where((i) => i.action == 'hatch_egg'), hasLength(1));
    expect(session.snapshot!.nest, isNull);
    expect(session.snapshot!.dragon(egg), isNotNull);
    expect(session.snapshot!.presentations.any((p) => p.dragonId == egg), true);
    await tester.pump(const Duration(seconds: 3));
    expect(server.receipts, hasLength(1));
  });
  testWidgets('lost automatic hatch response resumes the same durable request',
      (tester) async {
    await setup(tester);
    server.loseReply = true;
    await finish(tester);
    expect(session.fresh, false);
    expect(server.receipts, hasLength(1));
    await tester.pump(const Duration(seconds: 10));
    expect(server.sent, hasLength(1));
    await tester.runAsync(session.synchronize);
    await finish(tester);
    expect(session.snapshot!.nest, isNull);
    expect(server.receipts, hasLength(1));
    expect(server.sent.map((i) => i.requestId).toSet(), hasLength(1));
  });
  testWidgets('not-ready or signed-out eggs never dispatch a hatch',
      (tester) async {
    await setup(tester, ready: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(server.sent, isEmpty);
    (session.connection as CanonicalUiConnection).signOut();
    await tester.pump(const Duration(days: 2));
    expect(server.sent, isEmpty);
  });
}
