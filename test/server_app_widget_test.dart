import 'dart:io';
import 'package:dragon_haven/models/achievement.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:dragon_haven/server_dragonhaven_app.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:dragon_haven/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'support/canonical_ui_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    const font = String.fromEnvironment('ECONOMY_UI_FONT');
    if (font.isNotEmpty) {
      for (final e in {
        'Roboto': font,
        'Ahem': font,
        'MaterialIcons': '${File(font).parent.path}/materialicons-regular.otf'
      }.entries) {
        await (FontLoader(e.key)
              ..addFont(File(e.value).readAsBytes().then(ByteData.sublistView)))
            .load();
      }
    }
  });
  for (final starter in [false, true]) {
    testWidgets(
        'all five production tabs and account pages render from server facts without a local game (starter=$starter)',
        (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.view.physicalSize =
          starter ? const Size(320, 640) : const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late Directory directory;
      late CanonicalGameSession session;
      final auth = SupabaseClient(
          'https://synthetic.invalid', 'synthetic-public',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((_) async => http.Response('{}', 200)));
      final online = OnlineAccountProvider(
          repository: DisabledSocialRepository(),
          serverOwned: true,
          inventorySnapshot: () => throw StateError(
              'A server screen attempted to read a local inventory.'));
      await tester.runAsync(() async {
        directory = await Directory.systemTemp.createTemp('dh-server-app-ui-');
        final game = HouseholdProvider(
            persistenceEnabled: false,
            clock: () => DateTime.utc(2026, 9, 7, 12));
        game.onboardingComplete = true;
        game.tutorialCompleted = true;
        game.unlockedAchievementIds.addAll(achievementCatalog.map((a) => a.id));
        if (!starter) {
          game.pet
            ..stage = DragonStage.hatchling
            ..firstEgg = false
            ..favorite = true
            ..name = 'Restored';
        }
        game.pendingPresentations.clear();
        final server = CanonicalUiServer(game.exportState());
        game.dispose();
        session = CanonicalGameSession(
            connection: CanonicalUiConnection(server), directory: directory);
        await session.synchronize();
      });
      await tester.runAsync(() => tester.pumpWidget(RepaintBoundary(
          key: const Key('server-review-frame'),
          child: MultiProvider(providers: [
            ChangeNotifierProvider.value(value: session),
            ChangeNotifierProvider.value(value: online),
          ], child: ServerDragonHavenApp(auth: auth)))));
      await tester.pump(const Duration(milliseconds: 500));
      for (var attempt = 0; session.busy && attempt < 100; attempt++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(session.canAct, true,
          reason:
              'busy=${session.busy}; fresh=${session.fresh}; error=${session.errorCode}');
      expect(find.text('Dragon Tower'), findsOneWidget);
      for (final tab in [
        'friends',
        'adventure',
        'inventory',
        'shop',
        'tower'
      ]) {
        await tester.tap(find.byKey(Key('nav-$tab')));
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: 'Server tab $tab');
        if (const bool.fromEnvironment('SERVER_UI_REVIEW')) {
          for (var frame = 0; frame < 5; frame++) {
            await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 40)));
            await tester.pump(const Duration(milliseconds: 40));
          }
          final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('server-review-frame')));
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            final dir = Directory('.tools/server-ui-review');
            await dir.create(recursive: true);
            await File('${dir.path}/$tab-${starter ? 'starter' : 'keeper'}.png')
                .writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      for (final page in ['Account Info', 'Keeper Journal', 'Achievements']) {
        await tester.tap(find.byKey(const Key('haven-menu-button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text(page), findsWidgets,
            reason:
                'Open menu page: $page; ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList()}');
        await tester.tap(find.text(page).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Server page $page');
        Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
        await tester.pumpAndSettle();
      }
      HavenNotifications.openRemoteDestination('adventure_complete');
      await tester.pump();
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<ChoiceChip>(
                  find.byKey(const Key('canonical-tab-completed')))
              .selected,
          true);
      final available = find.widgetWithText(ChoiceChip, 'Adventures');
      await tester.ensureVisible(available);
      await tester.tap(available);
      await tester.pump();
      expect(
          tester
              .widget<ChoiceChip>(
                  find.byKey(const Key('canonical-tab-completed')))
              .selected,
          false);
      HavenNotifications.openRemoteDestination('adventure_complete');
      await tester.pump();
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<ChoiceChip>(
                  find.byKey(const Key('canonical-tab-completed')))
              .selected,
          true);
      HavenNotifications.openRemoteDestination('trials_full');
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Dragon Trials'), findsWidgets);
      HavenNotifications.openRemoteDestination('egg');
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Dragon Tower'), findsOneWidget);
      expect(Navigator.of(tester.element(find.byType(Scaffold).first)).canPop(),
          false);
      expect(tester.takeException(), isNull);
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
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(disposed, true);
      await closing;
      expect(tester.takeException(), isNull);
    });
  }
}
