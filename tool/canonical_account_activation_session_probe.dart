import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/config/online_config.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/canonical_game_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'canonical_game_session_probe.dart' show LostReplyClient;

void require(bool condition, String code) {
  if (!condition) throw StateError('client_probe_activation_$code');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  test('real account activation survives lost migration and purchase replies',
      () async {
    final env = Platform.environment;
    require(
        env['STAGING_SUPABASE_PROJECT_REF'] == 'vtmjkhzalalozpfnbvsd' &&
            env['STAGING_SUPABASE_URL'] == CanonicalGameTransport.stagingUrl,
        'staging_required');
    final raw = jsonDecode(env['STAGING_ACTIVATION_SESSION'] ?? 'null') as Map;
    require(
        raw['user']['app_metadata']['dragonhaven_game_probe'] ==
            env['STAGING_GAME_PROBE_RUN'],
        'synthetic_required');
    final owner = raw['user']['id'] as String;
    final config = OnlineConfig(
        url: CanonicalGameTransport.stagingUrl,
        publishableKey: env['STAGING_SUPABASE_PUBLISHABLE_KEY']!,
        environment: OnlineEnvironment.staging);
    final auth = SupabaseClient(config.url, config.publishableKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    final directory =
        await Directory.systemTemp.createTemp('dh-activation-probe-');
    CanonicalGameSession? game;
    CanonicalGameTransport? migration;
    try {
      await auth.auth.recoverSession(jsonEncode(raw));
      require((await auth.auth.getUser()).user?.id == owner, 'auth_mismatch');
      var dropMigration = true;
      migration = CanonicalGameTransport.staging(auth, config,
          timeout: const Duration(seconds: 30),
          httpClientFactory: () => LostReplyClient(() {
                if (!dropMigration) return false;
                dropMigration = false;
                return true;
              }, action: 'migrate_account'));
      final request = const Uuid().v4();
      var lost = false;
      try {
        await migration.migrateAccount(requestId: request, sourceRevision: 1);
      } on CanonicalGameException catch (error) {
        lost = error.code == 'game_command_unavailable';
      }
      require(lost && !dropMigration, 'lost_activation');
      final revision =
          await migration.migrateAccount(requestId: request, sourceRevision: 1);
      require(revision == 3, 'activation_replayed');
      final status = await auth.rpc('get_my_canonical_account_status') as Map;
      require(status['owner_id'] == owner && status['phase'] == 'active',
          'live_status');
      stdout.writeln('PROBE: account_activation_replayed');
      var dropPurchase = true;
      game = CanonicalGameSession(
          directory: directory,
          expectedAuthority: CanonicalGameAuthority.server,
          connection: CanonicalGameTransport.staging(auth, config,
              httpClientFactory: () => LostReplyClient(() {
                    if (!dropPurchase) return false;
                    dropPurchase = false;
                    return true;
                  })));
      await game.synchronize();
      final before = game.snapshot!;
      require(
          before.authorityMode == 'server' &&
              before.canApplyToLiveGame &&
              before.coins == 1000 &&
              before.gems == 10 &&
              game.canAct,
          'live_inventory');
      final titles = before.shop.chests['title'] ?? 0;
      lost = false;
      try {
        await game.execute('purchase_title_chest', {});
      } on CanonicalGameException catch (error) {
        lost = error.code == 'game_command_unavailable';
      }
      require(lost && !dropPurchase, 'lost_purchase');
      final pending = await game.intents.pending(owner);
      require(pending != null, 'purchase_journal');
      game.dispose();
      game = CanonicalGameSession(
          directory: directory,
          expectedAuthority: CanonicalGameAuthority.server,
          connection: CanonicalGameTransport.staging(auth, config));
      final receipt = await game.synchronize();
      require(
          receipt?.requestId == pending!.requestId &&
              receipt?.replayed == true &&
              game.snapshot!.coins == 900 &&
              game.snapshot!.shop.chests['title'] == titles + 1 &&
              await game.intents.pending(owner) == null &&
              game.canAct,
          'purchase_replayed');
      stdout.writeln(
          'PASS: real account activation; lost activation/purchase replies, private import, live inventory and one debit.');
    } finally {
      game?.dispose();
      await migration?.dispose();
      await auth.dispose();
      await directory.delete(recursive: true);
    }
  });
}
