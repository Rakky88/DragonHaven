// Real network proof: only the guarded runner's synthetic Auth account.
import 'dart:convert';
import 'dart:io';
import 'package:dragon_haven/config/online_config.dart';
import 'package:dragon_haven/services/canonical_beacon.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_transport.dart';
import 'package:dragon_haven/widgets/weave_beacon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'canonical_game_session_probe.dart' show LostReplyClient;

void require(bool condition, String code) {
  if (!condition) throw StateError('client_probe_beacon_$code');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  testWidgets(
      'real Beacon donation recovers one shared milestone and one debit',
      (tester) async {
    final env = Platform.environment;
    require(
        env['STAGING_SUPABASE_PROJECT_REF'] == 'vtmjkhzalalozpfnbvsd' &&
            env['STAGING_SUPABASE_URL'] == CanonicalGameTransport.stagingUrl,
        'staging_required');
    final sessions = jsonDecode(env['STAGING_BEACON_SESSIONS'] ?? 'null');
    require(sessions is List && sessions.length == 1, 'account_required');
    final signed = sessions[0] as Map;
    require(
        signed['user']['app_metadata']['dragonhaven_game_probe'] ==
            env['STAGING_GAME_PROBE_RUN'],
        'synthetic_required');
    final conclave = env['STAGING_BEACON_ID']!;
    final config = OnlineConfig(
        url: CanonicalGameTransport.stagingUrl,
        publishableKey: env['STAGING_SUPABASE_PUBLISHABLE_KEY']!,
        environment: OnlineEnvironment.staging);
    final auth = SupabaseClient(config.url, config.publishableKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    Directory? directory;
    CanonicalGameSession? game;
    var loseReply = true;
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    try {
      stdout.writeln('PROBE: beacon_auth_begin');
      await tester.runAsync(() async {
        await auth.auth.recoverSession(jsonEncode(signed));
        require((await auth.auth.getUser()).user?.id == signed['user']['id'],
            'auth_mismatch');
        directory = await Directory.systemTemp.createTemp('dh-beacon-probe-');
        game = CanonicalGameSession(
            directory: directory!,
            connection: CanonicalGameTransport.staging(auth, config,
                httpClientFactory: () => LostReplyClient(() {
                      if (!loseReply) return false;
                      loseReply = false;
                      return true;
                    }, action: 'donate_beacon')));
        await game!.synchronize();
        stdout.writeln('PROBE: beacon_read_complete');
      });
      final session = game!;
      Future<void> settle() async {
        for (var n = 0; n < 600; n++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 25)));
          await tester
              .runAsync(() => tester.pump(const Duration(milliseconds: 25)));
          if (n > 20 && !session.busy) break;
        }
        require(!session.busy, 'command_timeout');
        require(tester.takeException() == null, 'render');
      }

      Future<void> tap(String key) async {
        final finder = find.byKey(Key(key));
        require(finder.evaluate().length == 1, 'control_missing');
        stdout.writeln('PROBE: beacon_tap_${key.replaceAll('-', '_')}_begin');
        await tester.runAsync(() => tester.ensureVisible(finder));
        await tester.runAsync(() => tester.tap(finder));
        await settle();
        stdout
            .writeln('PROBE: beacon_tap_${key.replaceAll('-', '_')}_complete');
      }

      await tester.runAsync(() => tester.pumpWidget(MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: session),
                Provider<CanonicalBeaconSource>(
                    create: (_) => SupabaseCanonicalBeaconSource(auth))
              ],
              child: MaterialApp(
                  home: Scaffold(
                      body: SingleChildScrollView(
                          child: WeaveBeaconCard(
                              conclaveId: conclave, active: true)))))));
      stdout.writeln('PROBE: beacon_rendered');
      await settle();
      for (var i = 0;
          i < 80 && find.text('490 / 5000').evaluate().isEmpty;
          i++) {
        await settle();
      }
      require(find.text('490 / 5000').evaluate().length == 1,
          'shared_total_missing');
      stdout.writeln('PROBE: beacon_initial_total_visible');
      await tap('weave-beacon-project');
      await tap('donate-weave-fragments');
      await tap('confirm-beacon-donation');
      require(!loseReply && !session.canAct, 'lost_reply_not_retained');
      await tester.runAsync(() async {
        require((await session.synchronize())?.replayed == true,
            'lost_receipt_not_replayed');
      });
      await settle();
      require(
          session.canAct &&
              session.snapshot!.inventory.materials.fragments == 175 &&
              session.snapshot!.inventory.materials.essence == 7 &&
              session.snapshot!.inventory.materials.hearts == 2,
          'material_debit_mismatch');
      require(session.snapshot!.coins == 1000, 'unearned_reward');
      await tap('weave-beacon-project');
      await tap('weave-beacon-project');
      await settle();
      stdout.writeln('PROBE: beacon_final_total_check');
      require(find.text('515 / 5000').evaluate().length == 1,
          'shared_total_not_updated');
      stdout.writeln(
          'PASS: real Beacon UI; one exact donation and shared milestone after lost reply recovery.');
    } finally {
      stdout.writeln('PROBE: beacon_cleanup_begin');
      await tester.runAsync(() => tester.pumpWidget(const SizedBox.shrink()));
      stdout.writeln('PROBE: beacon_widget_removed');
      await tester.runAsync(() async {
        game?.dispose();
        stdout.writeln('PROBE: beacon_auth_dispose_begin');
        await auth.dispose().timeout(const Duration(seconds: 15));
        stdout.writeln('PROBE: beacon_auth_disposed');
        if (directory != null) await directory!.delete(recursive: true);
      });
      stdout.writeln('PROBE: beacon_cleanup_complete');
      await tester.binding.setSurfaceSize(null);
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}
