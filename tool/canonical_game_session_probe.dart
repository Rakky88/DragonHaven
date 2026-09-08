// Isolated real-network staging test. Credentials exist only in this child
// process's environment; they are never compiled into an app or written to disk.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/config/online_config.dart';
import 'package:dragon_haven/services/canonical_game_intent.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/canonical_game_transport.dart';
import 'package:dragon_haven/screens/shop_hub_screen.dart';
import 'package:dragon_haven/screens/canonical_inventory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

void require(bool condition, String code) {
  if (!condition) throw StateError(code);
}

class LostReplyClient extends http.BaseClient {
  LostReplyClient(this.shouldDrop);
  final bool Function() shouldDrop;
  final http.Client inner = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request ? jsonDecode(request.body) : null;
    final result = await inner.send(request);
    if (body is Map &&
        body['action'] == 'purchase_title_chest' &&
        shouldDrop()) {
      require(result.statusCode == 200, 'client_probe_purchase_refused');
      await result.stream.drain<void>();
      throw TimeoutException('simulated lost receipt after real commit');
    }
    return result;
  }

  @override
  void close() => inner.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // This dedicated, guarded probe intentionally uses the real network, rather
  // than Flutter test's default all-400 HttpClient. It is not in the unit suite.
  HttpOverrides.global = null;
  test(
      'real staging client resumes committed requests and repairs corrupt journals',
      () async {
    final env = Platform.environment;
    require(
        env['STAGING_SUPABASE_PROJECT_REF'] == 'vtmjkhzalalozpfnbvsd' &&
            env['STAGING_SUPABASE_URL'] == CanonicalGameTransport.stagingUrl &&
            (env['STAGING_SUPABASE_PUBLISHABLE_KEY']?.isNotEmpty ?? false),
        'client_probe_staging_required');
    final raw = env['STAGING_GAME_CLIENT_SESSION'];
    require(raw != null, 'client_probe_session_missing');
    final sessionJson = jsonDecode(raw!) as Map<String, dynamic>;
    final owner = sessionJson['user']['id'] as String;
    require(
        sessionJson['user']['app_metadata']['dragonhaven_game_probe'] ==
            env['STAGING_GAME_PROBE_RUN'],
        'client_probe_synthetic_owner_required');
    final config = OnlineConfig(
        url: CanonicalGameTransport.stagingUrl,
        publishableKey: env['STAGING_SUPABASE_PUBLISHABLE_KEY']!,
        environment: OnlineEnvironment.staging);
    final auth = SupabaseClient(config.url, config.publishableKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    final directory =
        await Directory.systemTemp.createTemp('dh-staging-client-probe-');
    CanonicalGameSession? game;
    try {
      await auth.auth.recoverSession(raw);
      require((await auth.auth.getUser()).user?.id == owner,
          'client_probe_auth_mismatch');
      var drop = true;
      game = CanonicalGameSession(
          directory: directory,
          connection: CanonicalGameTransport.staging(auth, config,
              httpClientFactory: () => LostReplyClient(() {
                    if (!drop) return false;
                    drop = false;
                    return true;
                  })));
      await game.synchronize();
      stdout.writeln('PROBE: session_synchronized');
      require(game.canAct, 'client_probe_not_ready');
      final before = game.snapshot!;
      final titles =
          (before.data['inventory']['chestInventory']['title'] as int?) ?? 0;
      require(before.coins >= 100, 'client_probe_fixture_balance');
      var lost = false;
      try {
        final first = game.execute('purchase_title_chest', {});
        final second = game.execute('purchase_title_chest', {});
        require(identical(first, second), 'client_probe_duplicate_dispatch');
        await first;
      } on CanonicalGameException catch (error) {
        lost = error.code == 'game_command_unavailable';
      }
      require(lost && !game.canAct && !drop,
          'client_probe_lost_reply_not_retained');
      final pending = await game.intents.pending(owner);
      require(pending != null, 'client_probe_intent_missing');
      game.dispose();
      game = CanonicalGameSession(
          directory: directory,
          connection: CanonicalGameTransport.staging(auth, config));
      final receipt = await game.synchronize();
      final after = game.snapshot!;
      require(
          receipt?.requestId == pending!.requestId &&
              receipt?.replayed == true &&
              receipt?.result == 'purchased' &&
              after.coins == before.coins - 100 &&
              after.data['inventory']['chestInventory']['title'] ==
                  titles + 1 &&
              await game.intents.pending(owner) == null &&
              game.canAct,
          'client_probe_resume_failed');
      await game.intents.prepare(CanonicalGameIntent(
          ownerId: owner,
          requestId: const Uuid().v4(),
          action: 'purchase_title_chest',
          payload: {},
          minimumRevision: after.serverRevision));
      for (final suffix in ['', '.backup']) {
        await File('${directory.path}/intent-v2-$owner$suffix.json')
            .writeAsString('synthetic damage', flush: true);
      }
      await game.synchronize();
      final recovered = game.snapshot!;
      require(
          recovered.serverRevision > after.serverRevision &&
              recovered.stateHash == after.stateHash &&
              recovered.coins == after.coins &&
              await game.intents.pending(owner) == null &&
              game.canAct,
          'client_probe_recovery_failed');
      // Success is deliberately fixed text; no account, token, raw state or
      // private egg facts are included in test output.
      stdout.writeln(
          'PASS: real SDK/session/journals; one charge after lost reply; corrupt intent recovery without another purchase.');
    } finally {
      game?.dispose();
      await auth.dispose();
      await directory.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('ordinary shop and chest reveal use the real staging economy',
      (tester) async {
    final env = Platform.environment;
    require(
        env['STAGING_SUPABASE_PROJECT_REF'] == 'vtmjkhzalalozpfnbvsd' &&
            env['STAGING_SUPABASE_URL'] == CanonicalGameTransport.stagingUrl,
        'client_probe_staging_required');
    final raw = env['STAGING_GAME_CLIENT_SESSION'];
    require(raw != null, 'client_probe_session_missing');
    final sessionJson = jsonDecode(raw!) as Map<String, dynamic>;
    final owner = sessionJson['user']['id'] as String;
    require(
        sessionJson['user']['app_metadata']['dragonhaven_game_probe'] ==
            env['STAGING_GAME_PROBE_RUN'],
        'client_probe_synthetic_owner_required');
    final config = OnlineConfig(
        url: CanonicalGameTransport.stagingUrl,
        publishableKey: env['STAGING_SUPABASE_PUBLISHABLE_KEY']!,
        environment: OnlineEnvironment.staging);
    final auth = SupabaseClient(config.url, config.publishableKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    late Directory directory;
    late CanonicalGameSession game;
    await tester.runAsync(() async {
      stdout.writeln('PROBE: ui_auth_start');
      await auth.auth.recoverSession(raw);
      require((await auth.auth.getUser()).user?.id == owner,
          'client_probe_auth_mismatch');
      directory = await Directory.systemTemp.createTemp('dh-staging-ui-probe-');
      game = CanonicalGameSession(
          directory: directory,
          connection: CanonicalGameTransport.staging(auth, config));
      await game.synchronize();
      stdout.writeln('PROBE: ui_synchronized');
    });
    Future<void> settleCommand() async {
      for (var n = 0; n < 500 && game.busy; n++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)));
        await tester.pump();
      }
      require(!game.busy && game.canAct, 'client_probe_ui_command_failed');
    }

    Future<void> mount(Widget child) async {
      await tester.pumpWidget(ChangeNotifierProvider.value(
          value: game, child: MaterialApp(home: Scaffold(body: child))));
      await tester.pump(const Duration(milliseconds: 400));
    }

    try {
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      final before = game.snapshot!;
      final initialChests = before.shop.chests['title'] ?? 0;
      final initialTitles = before.shop.titles.length;
      await mount(const ShopHubScreen(initialCategoryTab: 1));
      final purchase = find.byKey(const Key('buy-title-chest'));
      await tester.ensureVisible(purchase);
      await tester.pump(const Duration(milliseconds: 400));
      require(tester.widget<FilledButton>(purchase).onPressed != null,
          'client_probe_ui_buy_unavailable');
      // Start real filesystem/network callbacks outside the fake test clock.
      await tester.runAsync(() => tester.tap(purchase));
      await tester.pump();
      require(tester.widget<FilledButton>(purchase).onPressed == null,
          'client_probe_ui_double_tap_enabled');
      await settleCommand();
      stdout.writeln('PROBE: ui_purchase_settled');
      require(
          game.snapshot!.coins == before.coins - 100 &&
              game.snapshot!.shop.chests['title'] == initialChests + 1,
          'client_probe_ui_purchase_failed');
      await mount(const CanonicalInventoryScreen());
      final open = find.byKey(const Key('canonical-open-title'));
      await tester.ensureVisible(open);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(open);
      await tester.pump(const Duration(milliseconds: 400));
      require(game.snapshot!.shop.chests['title'] == initialChests + 1,
          'client_probe_ui_preview_consumed');
      await tester.runAsync(
          () => tester.tap(find.byKey(const Key('chest-reveal-tap-target'))));
      await settleCommand();
      stdout.writeln('PROBE: ui_reveal_settled');
      for (var n = 0; n < 30; n++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      require(
          find.byKey(const Key('chest-rewards')).evaluate().length == 1 &&
              game.snapshot!.shop.chests['title'] == initialChests &&
              game.snapshot!.shop.titles.length == initialTitles + 1 &&
              game.snapshot!.coins == before.coins - 100 &&
              tester.takeException() == null,
          'client_probe_ui_reveal_failed');
      stdout.writeln(
          'PASS: real shop UI purchase, durable inventory and server chest reveal; one debit and one title.');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      game.dispose();
      await tester.runAsync(() async {
        await auth.dispose();
        await directory.delete(recursive: true);
      });
      await tester.binding.setSurfaceSize(null);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
