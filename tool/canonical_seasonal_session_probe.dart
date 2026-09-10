// Real network proof restricted to one marked, disposable staging account.
import 'dart:convert';
import 'dart:io';
import 'package:dragon_haven/config/online_config.dart';
import 'package:dragon_haven/models/redeem_code.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/screens/canonical_trials_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void require(bool condition, String code) {
  if (!condition) throw StateError('client_probe_seasonal_$code');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  testWidgets('real Sunwake UI publishes only its server-verified result',
      (tester) async {
    final env = Platform.environment;
    require(
        env['STAGING_SUPABASE_PROJECT_REF'] == 'vtmjkhzalalozpfnbvsd' &&
            env['STAGING_SUPABASE_URL'] == CanonicalGameTransport.stagingUrl,
        'staging_required');
    final raw = jsonDecode(env['STAGING_SEASONAL_SESSION'] ?? 'null') as Map;
    require(
        raw['user']['app_metadata']['dragonhaven_game_probe'] ==
            env['STAGING_GAME_PROBE_RUN'],
        'synthetic_required');
    final owner = raw['user']['id'] as String;
    final config = OnlineConfig(
        url: CanonicalGameTransport.stagingUrl,
        publishableKey: env['STAGING_SUPABASE_PUBLISHABLE_KEY']!,
        environment: OnlineEnvironment.staging);
    late SupabaseClient auth;
    late CanonicalGameSession game;
    late Directory directory;
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.runAsync(() async {
      auth = SupabaseClient(config.url, config.publishableKey,
          authOptions: const AuthClientOptions(autoRefreshToken: false));
      await auth.auth.recoverSession(jsonEncode(raw));
      require((await auth.auth.getUser()).user?.id == owner, 'auth_mismatch');
      directory = await Directory.systemTemp.createTemp('dh-seasonal-probe-');
      game = CanonicalGameSession(
          directory: directory,
          connection: CanonicalGameTransport.staging(auth, config));
      await game.synchronize();
    });
    try {
      Future<void> settle({bool Function()? until}) async {
        for (var n = 0; n < 1000; n++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 25)));
          await tester
              .runAsync(() => tester.pump(const Duration(milliseconds: 25)));
          if (n > 28 && !game.busy && (until == null || until())) {
            break;
          }
        }
        require(!game.busy && game.canAct, 'command_unavailable');
        require(tester.takeException() == null, 'render');
      }

      Future<void> command(String action, Map<String, dynamic> payload) async {
        await tester.runAsync(() async {
          final receipt = await game.execute(action, payload);
          require(receipt?.succeeded == true, 'command_failed');
        });
        await settle();
      }

      Future<void> tap(Finder finder) async {
        require(finder.evaluate().length == 1, 'control_missing');
        await tester.runAsync(() => tester.ensureVisible(finder));
        await tester.runAsync(() => tester.tap(finder));
        await settle();
      }

      const event = 'sunwake_summer_sea';
      final previewCode = redeemCodeCatalog
          .singleWhere((c) =>
              c.rewardType == RedeemRewardType.seasonalEventPreview &&
              c.rewardId == event)
          .code;
      await command('redeem_code', {'code': previewCode});
      await command('refresh', {});
      final preview = await tester
          .runAsync(() => auth.rpc('list_my_seasonal_event_previews'));
      require(
          preview is List &&
              preview.length == 1 &&
              preview.single['event_id'] == event,
          'activation_not_published');
      final offer = game.snapshot!.trialOffers
          .firstWhere((o) => o.kind == TrialKind.sunwakeSurf);
      final dragon = game.snapshot!.dragons.firstWhere((d) => d.owned);
      final oldXp = dragon.xp;
      await tester.runAsync(() => tester.pumpWidget(
          ChangeNotifierProvider.value(
              value: game,
              child: const MaterialApp(
                  home: Scaffold(body: CanonicalTrialsScreen())))));
      await settle();
      await tap(find.byKey(Key('choose-trial-${offer.id}')));
      await tap(find.byKey(Key('trial-dragon-${dragon.id}')));
      await tap(find.text('Begin Trial'));
      stdout.writeln('PROBE: seasonal_ui_started');
      // No inputs: the displayed dragon meets three obstacles. Advance real
      // time along with Flutter frames; submitting a client score is impossible.
      await settle(
          until: () => find
              .byKey(const Key('trial-result-continue'))
              .evaluate()
              .isNotEmpty);
      require(
          game.snapshot!.trialAttempt == null &&
              find
                  .byKey(const Key('trial-result-continue'))
                  .evaluate()
                  .isNotEmpty,
          'third_mistake_not_finished');
      final result =
          game.snapshot!.data['trials']['lastResult']['result'] as Map;
      require(
          result['kind'] == 'sunwakeSurf' &&
              result['accepted'] == true &&
              result['totalActions'] - result['correctActions'] == 3 &&
              game.snapshot!.dragon(dragon.id)!.xp == oldXp + result['xp'],
          'verified_reward');
      final ranking = await tester
          .runAsync(() => auth.rpc('get_seasonal_trial_rankings', params: {
                'p_event_id': event,
                'p_occurrence_key': 'preview:$event:$owner',
                'p_preview': true,
                'p_limit': 100
              }));
      require(
          ranking is List &&
              ranking.length == 1 &&
              ranking.single['user_id'] == owner &&
              ranking.single['score'] == result['score'] &&
              ranking.single['duration_ms'] == result['durationMs'],
          'ranking_not_published');
      await command('refresh', {});
      require(game.snapshot!.dragon(dragon.id)!.xp == oldXp + result['xp'],
          'duplicate_reward');
      await command('redeem_code', {
        'code': redeemCodeCatalog
            .singleWhere(
                (c) => c.rewardType == RedeemRewardType.endSeasonalEvent)
            .code
      });
      final ended = await tester
          .runAsync(() => auth.rpc('list_my_seasonal_event_previews'));
      require(ended is List && ended.isEmpty, 'end_not_published');
      require(game.snapshot!.dragon(dragon.id)!.xp == oldXp + result['xp'],
          'end_changed_reward');
      stdout.writeln(
          'PASS: real seasonal UI; preview activation, three-mistake Sunwake finish, exact verified ranking/reward and event end.');
    } finally {
      await tester.runAsync(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.runAsync(() async {
        game.dispose();
        await auth.dispose().timeout(const Duration(seconds: 15));
        await directory.delete(recursive: true);
      });
      await tester.binding.setSurfaceSize(null);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
