// Real network UI proof; only the guarded runner's two synthetic Auth users.
import 'dart:convert';
import 'dart:io';
import 'package:dragon_haven/config/online_config.dart';
import 'package:dragon_haven/screens/canonical_trades_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_transport.dart';
import 'package:dragon_haven/widgets/canonical_milestones.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'canonical_game_session_probe.dart' show LostReplyClient;

void require(bool condition, String code) {
  if (!condition) throw StateError('client_probe_trade_$code');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  testWidgets(
      'real two-owner trade UI preserves exact items after a lost reply',
      (tester) async {
    final env = Platform.environment;
    require(
        env['STAGING_SUPABASE_PROJECT_REF'] == 'vtmjkhzalalozpfnbvsd' &&
            env['STAGING_SUPABASE_URL'] == CanonicalGameTransport.stagingUrl,
        'staging_required');
    final raw = jsonDecode(env['STAGING_TRADE_SESSIONS'] ?? 'null');
    require(raw is List && raw.length == 2, 'sessions_required');
    final config = OnlineConfig(
        url: CanonicalGameTransport.stagingUrl,
        publishableKey: env['STAGING_SUPABASE_PUBLISHABLE_KEY']!,
        environment: OnlineEnvironment.staging);
    final auths = <SupabaseClient>[];
    final games = <CanonicalGameSession>[];
    final directories = <Directory>[];
    var dropConfirm = true;
    var active = 0;
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    try {
      await tester.runAsync(() async {
        for (var i = 0; i < 2; i++) {
          final entry = raw[i] as Map;
          require(
              entry['user']['app_metadata']['dragonhaven_game_probe'] ==
                  env['STAGING_GAME_PROBE_RUN'],
              'synthetic_required');
          final auth = SupabaseClient(config.url, config.publishableKey,
              authOptions: const AuthClientOptions(autoRefreshToken: false));
          auths.add(auth);
          await auth.auth.recoverSession(jsonEncode(entry));
          require((await auth.auth.getUser()).user?.id == entry['user']['id'],
              'auth_mismatch');
          final directory =
              await Directory.systemTemp.createTemp('dh-trade-probe-');
          directories.add(directory);
          final game = CanonicalGameSession(
              directory: directory,
              connection: CanonicalGameTransport.staging(auth, config,
                  httpClientFactory: i == 0
                      ? () => LostReplyClient(() {
                            if (!dropConfirm) return false;
                            dropConfirm = false;
                            return true;
                          }, action: 'confirm_trade')
                      : null));
          games.add(game);
          await game.synchronize();
        }
      });
      stdout.writeln('PROBE: trade_accounts_ready');
      Future<void> settle(
          {bool permitLost = false, bool Function()? until}) async {
        for (var n = 0; n < 800; n++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 25)));
          await tester
              .runAsync(() => tester.pump(const Duration(milliseconds: 25)));
          if (n > 28 && !games[active].busy && (until == null || until()))
            break;
        }
        require(!games[active].busy, 'command_timeout');
        if (!permitLost &&
            games[active].errorCode == 'game_command_unavailable') {
          await tester.runAsync(() async {
            final pending = await games[active]
                .intents
                .pending(games[active].connection.currentOwner!);
            if (pending != null) {
              stdout.writeln('PROBE: trade_recover_same_request');
              try {
                await games[active].synchronize();
              } on Object {/* Report the fixed error below. */}
            }
          });
        }
        if (!permitLost && !games[active].canAct) {
          final error = games[active].errorCode;
          final safe = error != null &&
                  RegExp(r'^(game|economy|invalid)_[a-z_]{1,70}$')
                      .hasMatch(error)
              ? error
              : 'unavailable';
          throw StateError('client_probe_trade_command_$safe');
        }
        require(tester.takeException() == null, 'render');
      }

      Future<void> mount(int index) async {
        active = index;
        await tester.runAsync(() => games[index].synchronize());
        await tester.runAsync(() => tester.pumpWidget(
            ChangeNotifierProvider.value(
                key: UniqueKey(),
                value: games[index],
                child: MaterialApp(
                    home: Scaffold(
                        body: SafeArea(
                            child: CanonicalMilestones(
                                child: CanonicalTradesScreen(
                                    keeperCode: env[
                                        'STAGING_TRADE_TARGET_CODE']!))))))));
        await settle();
      }

      Future<void> tap(String key, {bool permitLost = false}) async {
        final finder = find.byKey(Key(key));
        require(finder.evaluate().length == 1, 'control_missing');
        await tester.runAsync(() => tester.ensureVisible(finder));
        await tester.runAsync(() => tester.tap(finder));
        await settle(permitLost: permitLost);
      }

      Future<String> offer(String identity) async {
        await tap('canonical-offer-trade');
        await tap('canonical-trade-item-$identity');
        await tap('canonical-trade-select-item');
        require(
            games[0].snapshot!.trades.offers.where((t) => t.active).length == 1,
            'offer_missing');
        return games[0].snapshot!.trades.offers.singleWhere((t) => t.active).id;
      }

      await mount(0);
      var id = await offer('chest:gold:0');
      await mount(1);
      await tap('canonical-cancel-trade-$id');
      await mount(0);
      require(!games[0].snapshot!.trades.hasActive, 'rejected_still_active');
      require(games[0].snapshot!.shop.reservedChests.isEmpty,
          'rejected_still_reserved');
      stdout.writeln('PROBE: trade_rejection_complete');
      id = await offer('chest:gold:0');
      await tap('canonical-cancel-trade-$id');
      require(!games[0].snapshot!.trades.hasActive, 'cancelled_still_active');
      stdout.writeln('PROBE: trade_cancellation_complete');
      id = await offer('egg:trade-probe-special-egg:0');
      await mount(1);
      final received = games[1]
          .snapshot!
          .trades
          .offers
          .singleWhere((t) => t.active)
          .received!
          .egg!;
      require(
          received.tagged &&
              received.revealedRarity != null &&
              received.revealedLineageId == null,
          'public_egg_knowledge');
      await tap('canonical-reply-trade-$id');
      await tap('canonical-trade-item-relic:chronoshard:60');
      await tap('canonical-trade-select-item');
      stdout.writeln('PROBE: trade_reply_complete');
      await mount(0);
      require(
          games[0]
                  .snapshot!
                  .trades
                  .offers
                  .singleWhere((t) => t.active)
                  .received!
                  .variant ==
              60,
          'variant_changed');
      await tap('canonical-confirm-trade-$id');
      final confirm = find.widgetWithText(FilledButton, 'Confirm');
      require(confirm.evaluate().length == 1, 'confirmation_missing');
      await tester.runAsync(() => tester.tap(confirm));
      await settle(permitLost: true);
      require(!games[0].canAct && !dropConfirm, 'lost_reply_not_pending');
      await tap('economy-reconnect');
      require(
          games[0].snapshot!.trades.completedToday == 1 &&
              games[0].snapshot!.egg('trade-probe-special-egg') == null &&
              games[0].snapshot!.inventory.chronoshards.single == 60,
          'sender_inventory');
      require(games[0].snapshot!.presentations.any((e) => e.id == 'trade-$id'),
          'sender_presentation_missing');
      final first = games[0].snapshot!.presentations.first;
      stdout.writeln('PROBE: trade_first_presentation_${first.type.name}');
      await settle(
          until: () => find
              .byKey(const Key('trade-complete-reveal'))
              .evaluate()
              .isNotEmpty);
      require(
          find.byKey(const Key('trade-complete-reveal')).evaluate().isNotEmpty,
          'sender_reveal_not_open');
      require(find.text('Chronoshard · 60%').evaluate().isNotEmpty,
          'sender_reveal_missing');
      await tap('trade-reveal-continue');
      stdout.writeln('PROBE: trade_sender_recovered');
      await mount(1);
      final egg = games[1].snapshot!.egg('trade-probe-special-egg');
      require(
          egg?.tagged == true &&
              egg?.revealedRarity != null &&
              egg?.revealedLawAxis != null &&
              egg?.revealedMoralAxis != null &&
              egg?.revealedLineageId == null &&
              games[1].snapshot!.inventory.chronoshards.single == 25,
          'receiver_inventory');
      await tap('trade-reveal-continue');
      for (final game in games) {
        require(
            game.snapshot!.coins == 1000 &&
                game.snapshot!.gems == 10 &&
                game.snapshot!.presentations.isEmpty &&
                game.snapshot!.trades.completedToday == 1,
            'reward_or_presentation_mismatch');
      }
      stdout.writeln(
          'PASS: real trade UI; reject, cancel, exact egg/variant exchange, lost confirm and both persistent reveals.');
    } finally {
      await tester.runAsync(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.runAsync(() async {
        for (final game in games) {
          game.dispose();
        }
        for (final auth in auths) {
          await auth.dispose().timeout(const Duration(seconds: 15));
        }
        for (final directory in directories) {
          await directory.delete(recursive: true);
        }
      });
      await tester.binding.setSurfaceSize(null);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
