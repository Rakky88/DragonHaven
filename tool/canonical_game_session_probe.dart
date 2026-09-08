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
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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
      print(
          'PASS: real SDK/session/journals; one charge after lost reply; corrupt intent recovery without another purchase.');
    } finally {
      game?.dispose();
      await auth.dispose();
      await directory.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
