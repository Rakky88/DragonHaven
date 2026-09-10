// Guarded real-network group UI probe; all credentials stay in this child.
import 'dart:convert';
import 'dart:io';
import 'package:dragon_haven/config/online_config.dart';
import 'package:dragon_haven/app_info.dart';
import 'package:dragon_haven/screens/canonical_groups_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_transport.dart';
import 'package:dragon_haven/services/canonical_groups.dart';
import 'package:dragon_haven/widgets/expertise_score_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'canonical_game_session_probe.dart' show LostReplyClient;

void require(bool condition, String code) {
  if (!condition) throw StateError('client_probe_group_$code');
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
      'real group UI binds four keepers and recovers a lost lobby receipt',
      (tester) async {
    final env = Platform.environment;
    require(
        env['STAGING_SUPABASE_PROJECT_REF'] == 'vtmjkhzalalozpfnbvsd' &&
            env['STAGING_SUPABASE_URL'] == CanonicalGameTransport.stagingUrl,
        'staging_required');
    final raw = jsonDecode(env['STAGING_GROUP_SESSIONS'] ?? 'null');
    require(raw is List && raw.length == 4, 'sessions_required');
    final config = OnlineConfig(
        url: CanonicalGameTransport.stagingUrl,
        publishableKey: env['STAGING_SUPABASE_PUBLISHABLE_KEY']!,
        environment: OnlineEnvironment.staging);
    final auths = <SupabaseClient>[];
    final games = <CanonicalGameSession>[];
    final groups = <CanonicalGroups>[];
    final directories = <Directory>[];
    var dropCreate = true;
    var active = 0;
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    try {
      await tester.runAsync(() async {
        for (var i = 0; i < 4; i++) {
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
              await Directory.systemTemp.createTemp('dh-group-probe-');
          directories.add(directory);
          final game = CanonicalGameSession(
              directory: directory,
              connection: CanonicalGameTransport.staging(auth, config,
                  httpClientFactory: i == 0
                      ? () => LostReplyClient(() {
                            if (!dropCreate) return false;
                            dropCreate = false;
                            return true;
                          }, action: 'create_group_adventure')
                      : null));
          games.add(game);
          groups.add(CanonicalGroups(
              connection: game.connection,
              source: SupabaseCanonicalGroupsSource(auth)));
          await game.synchronize();
        }
      });
      stdout.writeln('PROBE: group_accounts_ready');
      Future<void> settle({bool permitLost = false}) async {
        for (var n = 0; n < 600; n++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 25)));
          await tester.pump();
          if (n > 6 && !games[active].busy && !groups[active].loading) break;
        }
        require(!games[active].busy, 'command_timeout');
        if (!permitLost && !games[active].canAct) {
          final error = games[active].errorCode;
          final code = error != null &&
                  RegExp(r'^(game|economy|invalid)_[a-z_]{1,70}$')
                      .hasMatch(error)
              ? error
              : 'unavailable';
          stdout.writeln(
              'PROBE: group_state_${games[active].fresh ? 'fresh' : 'stale'}_${games[active].snapshot == null ? 'no_view' : 'has_view'}_${games[active].snapshot?.mutationsEnabled == true ? 'enabled' : 'paused'}');
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
                  'PROBE: group_cache_revision_${cached?.serverRevision == wire['server_revision'] ? 'same' : 'different'}');
              stdout.writeln(
                  'PROBE: group_cache_hash_${cached?.stateHash == wire['state_sha256'] ? 'same' : 'different'}');
              if (cached != null) {
                for (final key in cached.data.keys) {
                  if (jsonEncode(ordered(cached.data[key])) !=
                      jsonEncode(ordered(wire['data'][key]))) {
                    stdout.writeln('PROBE: group_changed_${key.toLowerCase()}');
                  }
                }
              }
              final pending = await game.intents.pending(owner);
              if (pending != null) {
                final reply = await game.connection.send(pending);
                final body = reply.body;
                if (body is Map) {
                  stdout.writeln(
                      'PROBE: group_receipt_revision_${body['server_revision'] == wire['server_revision'] ? 'same' : 'different'}');
                  stdout.writeln(
                      'PROBE: group_receipt_hash_${body['state_sha256'] == wire['state_sha256'] ? 'same' : 'different'}');
                }
              }
            });
          }
          throw StateError('client_probe_group_command_$code');
        }
        require(groups[active].error == null, 'read_unavailable');
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
              ChangeNotifierProvider.value(value: groups[index])
            ],
            child: MaterialApp(
                home: const Scaffold(
                    body: SafeArea(child: CanonicalGroupsScreen()))))));
        await settle();
      }

      Future<void> tap(String key) async {
        final finder = find.byKey(Key(key));
        if (finder.evaluate().isEmpty) {
          final scrollable = find
              .descendant(
                  of: find.byKey(const Key('canonical-groups-list')),
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
        await tap('canonical-group-expertise-${dragon.id}');
        require(find.byType(ExpertiseScoreBadge).evaluate().length >= 3,
            'expertise_missing');
        await tester.runAsync(() => tester.tap(find.text('Close')));
        await tester.pump(const Duration(milliseconds: 400));
        await tap('canonical-group-dragon-${dragon.id}');
        await tap('canonical-confirm-group');
        await settle(permitLost: lost);
      }

      await mount(0);
      await choose(button: 'canonical-create-group', lost: true);
      require(!dropCreate && !games[0].canAct, 'lost_reply_not_retained');
      await tester.runAsync(() async {
        final receipt = await games[0].synchronize();
        require(receipt?.replayed == true, 'lost_receipt_not_replayed');
      });
      await tester.runAsync(() => tester.tap(find.text('Cancel')));
      await tester.pump(const Duration(milliseconds: 400));
      await tap('canonical-refresh-groups');
      await settle();
      var own = groups[0].lobbies.singleWhere((l) => l.isOwner);
      require(
          own.isWaiting && own.participants.length == 1, 'create_duplicate');
      stdout.writeln('PROBE: group_create_recovered');
      stdout.writeln('PROBE: group_owner_leave_begin');
      await tap('canonical-leave-group-${own.id}');
      await confirm();
      require(
          groups[0].lobbies.where((l) => l.isOwner).isEmpty &&
              games[0]
                  .snapshot!
                  .dragons
                  .where((d) => d.owned)
                  .every((d) => d.adventureId == null),
          'owner_leave');
      stdout.writeln('PROBE: group_owner_recreate_begin');
      await choose(button: 'canonical-create-group');
      own = groups[0].lobbies.singleWhere((l) => l.isOwner);
      final source = own.id;
      final requiredPlayers = own.requiredPlayers;
      stdout.writeln('PROBE: group_first_member_join_begin');
      await mount(1);
      stdout.writeln('PROBE: group_first_member_mounted');
      await choose(button: 'canonical-join-group-$source');
      if (requiredPlayers > 2) {
        await mount(0);
        await tap('canonical-remove-group-${games[1].snapshot!.ownerId}');
        await confirm();
        await mount(1);
        require(
            games[1]
                .snapshot!
                .dragons
                .where((d) => d.owned)
                .every((d) => d.adventureId == null),
            'removed_dragon_reserved');
        await choose(button: 'canonical-join-group-$source');
      }
      stdout.writeln('PROBE: group_join_and_removal_verified');
      for (var i = 2; i < requiredPlayers; i++) {
        await mount(i);
        await choose(button: 'canonical-join-group-$source');
      }
      DateTime? end;
      for (var i = 0; i < requiredPlayers; i++) {
        await mount(i);
        final lobby = groups[i].lobbies.singleWhere((l) => l.id == source);
        end ??= lobby.endsAt;
        require(
            lobby.isRunning &&
                lobby.endsAt == end &&
                lobby.participants.length == requiredPlayers,
            'shared_start_mismatch');
        require(
            games[i]
                    .snapshot!
                    .dragons
                    .where((d) => d.owned)
                    .single
                    .adventureId ==
                'online-group:$source',
            'dragon_not_reserved');
        require(games[i].snapshot!.coins == 1000, 'unearned_reward');
      }
      stdout.writeln(
          'PASS: real group UI; lost create replay, owner leave, member join/removal and one shared running adventure.');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        for (final group in groups) {
          group.dispose();
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
