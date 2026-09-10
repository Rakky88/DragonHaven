// Guarded real-network partner UI probe; all credentials stay in this child.
import 'dart:convert';
import 'dart:io';
import 'package:dragon_haven/config/online_config.dart';
import 'package:dragon_haven/app_info.dart';
import 'package:dragon_haven/screens/canonical_partners_screen.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_transport.dart';
import 'package:dragon_haven/services/canonical_partners.dart';
import 'package:dragon_haven/widgets/expertise_score_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'canonical_game_session_probe.dart' show LostReplyClient;

void require(bool condition, String code) {
  if (!condition) throw StateError('client_probe_pair_$code');
}

Object? ordered(Object? value) => switch (value) {
      Map value => {
          for (final key in value.keys.cast<String>().toList()..sort())
            key: ordered(value[key])
        },
      List value => value.map(ordered).toList(),
      _ => value,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  testWidgets(
      'real partner UI binds two keepers and recovers a lost invite receipt',
      (tester) async {
    final env = Platform.environment;
    require(
        env['STAGING_SUPABASE_PROJECT_REF'] == 'vtmjkhzalalozpfnbvsd' &&
            env['STAGING_SUPABASE_URL'] == CanonicalGameTransport.stagingUrl,
        'staging_required');
    final raw = jsonDecode(env['STAGING_PAIR_SESSIONS'] ?? 'null');
    require(raw is List && raw.length == 2, 'sessions_required');
    final config = OnlineConfig(
        url: CanonicalGameTransport.stagingUrl,
        publishableKey: env['STAGING_SUPABASE_PUBLISHABLE_KEY']!,
        environment: OnlineEnvironment.staging);
    final auths = <SupabaseClient>[];
    final games = <CanonicalGameSession>[];
    final partners = <CanonicalPartners>[];
    final directories = <Directory>[];
    var dropCreate = true;
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
              await Directory.systemTemp.createTemp('dh-pair-probe-');
          directories.add(directory);
          final game = CanonicalGameSession(
              directory: directory,
              connection: CanonicalGameTransport.staging(auth, config,
                  httpClientFactory: i == 0
                      ? () => LostReplyClient(() {
                            if (!dropCreate) return false;
                            dropCreate = false;
                            return true;
                          }, action: 'invite_pair_adventure')
                      : null));
          games.add(game);
          partners.add(CanonicalPartners(
              connection: game.connection,
              source: SupabaseCanonicalPartnersSource(auth)));
          await game.synchronize();
        }
      });
      stdout.writeln('PROBE: pair_accounts_ready');
      Future<void> settle({bool permitLost = false}) async {
        for (var n = 0; n < 600; n++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 25)));
          await tester.pump();
          if (n > 6 && !games[active].busy && !partners[active].loading) break;
        }
        require(!games[active].busy, 'command_timeout');
        if (!permitLost &&
            games[active].errorCode == 'game_command_unavailable') {
          await tester.runAsync(() async {
            final pending = await games[active]
                .intents
                .pending(games[active].connection.currentOwner!);
            if (pending != null) {
              stdout.writeln('PROBE: pair_recover_same_pending_request');
              try {
                final receipt = await games[active].synchronize();
                stdout.writeln(
                    'PROBE: pair_pending_${receipt?.replayed == true ? 'replayed' : 'resolved'}');
              } on Object {
                stdout.writeln('PROBE: pair_pending_still_unavailable');
              }
            }
          });
        }
        if (!permitLost && !games[active].canAct) {
          final error = games[active].errorCode;
          final code = error != null &&
                  RegExp(r'^(game|economy|invalid)_[a-z_]{1,70}$')
                      .hasMatch(error)
              ? error
              : 'unavailable';
          stdout.writeln(
              'PROBE: pair_state_${games[active].fresh ? 'fresh' : 'stale'}_${games[active].snapshot == null ? 'no_view' : 'has_view'}_${games[active].snapshot?.mutationsEnabled == true ? 'enabled' : 'paused'}');
          if (error == 'game_snapshot_conflict') {
            await tester.runAsync(() async {
              final game = games[active];
              final owner = game.connection.currentOwner!;
              final cached = (await game.snapshots.inspect(owner)).snapshot;
              final wire = await game.connection.read({
                'protocol': 2,
                'clientBuild': AppInfo.buildNumber,
                'action': 'read_state'
              }) as Map;
              stdout.writeln(
                  'PROBE: pair_cache_revision_${cached?.serverRevision == wire['server_revision'] ? 'same' : 'different'}');
              stdout.writeln(
                  'PROBE: pair_cache_hash_${cached?.stateHash == wire['state_sha256'] ? 'same' : 'different'}');
              if (cached != null) {
                for (final key in cached.data.keys) {
                  if (jsonEncode(ordered(cached.data[key])) !=
                      jsonEncode(ordered(wire['data'][key]))) {
                    stdout.writeln('PROBE: pair_changed_${key.toLowerCase()}');
                  }
                }
              }
              final pending = await game.intents.pending(owner);
              if (pending != null) {
                final reply = await game.connection.send(pending);
                final body = reply.body;
                if (body is Map) {
                  stdout.writeln(
                      'PROBE: pair_receipt_revision_${body['server_revision'] == wire['server_revision'] ? 'same' : 'different'}');
                  stdout.writeln(
                      'PROBE: pair_receipt_hash_${body['state_sha256'] == wire['state_sha256'] ? 'same' : 'different'}');
                }
              }
            });
          }
          throw StateError('client_probe_pair_command_$code');
        }
        require(partners[active].error == null, 'read_unavailable');
        require(tester.takeException() == null, 'render');
        await tester.pump(const Duration(milliseconds: 400));
      }

      Future<void> mount(int index) async {
        active = index;
        await tester.runAsync(() async {
          await games[index].synchronize();
        });
        await tester.runAsync(() => tester.pumpWidget(MultiProvider(
            key: UniqueKey(),
            providers: [
              ChangeNotifierProvider.value(value: games[index]),
              ChangeNotifierProvider.value(value: partners[index])
            ],
            child: MaterialApp(
                home: const Scaffold(
                    body: SafeArea(child: CanonicalPartnersScreen()))))));
        await settle();
      }

      Future<void> tap(String key) async {
        final finder = find.byKey(Key(key));
        if (finder.evaluate().isEmpty) {
          final scrollable = find
              .descendant(
                  of: find.byKey(const Key('canonical-partners-list')),
                  matching: find.byType(Scrollable))
              .first;
          tester.state<ScrollableState>(scrollable).position.jumpTo(0);
          await tester.pump();
          if (finder.evaluate().isEmpty) {
            await tester.scrollUntilVisible(finder, 180,
                scrollable: scrollable);
          }
        }
        require(finder.evaluate().length == 1, 'control_missing');
        await tester.ensureVisible(finder);
        await tester.runAsync(() => tester.tap(finder));
        await tester.pump(const Duration(milliseconds: 400));
      }

      Future<void> confirm() async {
        await tester.runAsync(
            () => tester.tap(find.widgetWithText(FilledButton, 'Confirm')));
        await tester.pump();
        await settle();
      }

      Future<void> choose({required String button, bool lost = false}) async {
        await tap(button);
        final dragon = games[active]
            .snapshot!
            .dragons
            .firstWhere((d) => d.owned && d.adventureId == null);
        await tap('canonical-partner-expertise-${dragon.id}');
        require(find.byType(ExpertiseScoreBadge).evaluate().length >= 3,
            'expertise_missing');
        await tester.runAsync(() => tester.tap(find.text('Close')));
        await tester.pump(const Duration(milliseconds: 400));
        await tap('canonical-partner-dragon-${dragon.id}');
        await tap('canonical-confirm-partner');
        await settle(permitLost: lost);
      }

      Future<String> invite({bool lost = false}) async {
        await tester.enterText(find.byKey(const Key('canonical-partner-code')),
            env['STAGING_PAIR_TARGET_CODE']!);
        await tester.pump();
        await choose(button: 'canonical-invite-partner', lost: lost);
        if (lost) {
          require(!dropCreate && !games[0].canAct, 'lost_reply_not_retained');
          await tester.runAsync(() async {
            final receipt = await games[0].synchronize();
            require(receipt?.replayed == true, 'lost_receipt_not_replayed');
          });
          await tester.runAsync(() => tester.tap(find.text('Cancel')));
          await tester.pump(const Duration(milliseconds: 400));
          await tap('canonical-refresh-partners');
          await settle();
        }
        return partners[0].pairs.singleWhere((p) => p.isActive).id;
      }

      void released(int i) => require(
          games[i]
              .snapshot!
              .dragons
              .where((d) => d.owned)
              .every((d) => d.adventureId == null),
          'dragon_not_released');
      await mount(0);
      var source = await invite(lost: true);
      stdout.writeln('PROBE: pair_invite_recovered');
      await mount(1);
      await tap('canonical-decline-partner-$source');
      await settle();
      await mount(0);
      released(0);
      stdout.writeln('PROBE: pair_decline_released');
      source = await invite();
      await mount(1);
      await choose(button: 'canonical-accept-partner-$source');
      await mount(0);
      await tap('canonical-cancel-partner-$source');
      await confirm();
      await mount(1);
      released(1);
      await mount(0);
      released(0);
      stdout.writeln('PROBE: pair_cancel_released');
      source = await invite();
      await mount(1);
      await choose(button: 'canonical-accept-partner-$source');
      await mount(0);
      await tap('canonical-start-partner-$source');
      await settle();
      DateTime? end;
      for (var i = 0; i < 2; i++) {
        await mount(i);
        final pair = partners[i].pairs.singleWhere((p) => p.id == source);
        end ??= pair.endsAt;
        require(
            pair.status == SeasonalPairAdventureStatus.running &&
                pair.endsAt == end &&
                pair.endsAt!.difference(pair.startedAt!) ==
                    const Duration(hours: 24),
            'shared_start_mismatch');
        require(
            games[i]
                    .snapshot!
                    .dragons
                    .where((d) => d.owned)
                    .single
                    .adventureId ==
                'online-seasonal:$source',
            'dragon_not_reserved');
        require(games[i].snapshot!.coins == 1000, 'unearned_reward');
      }
      stdout.writeln(
          'PASS: real partner UI; lost invite replay, decline, accept, cancellation and one shared running adventure.');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        for (final partner in partners) {
          partner.dispose();
        }
        for (final game in games) {
          game.dispose();
        }
        for (final auth in auths) {
          await auth.dispose();
        }
        for (final directory in directories) {
          await directory.delete(recursive: true);
        }
      });
      await tester.binding.setSurfaceSize(null);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
