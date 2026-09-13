import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/config/online_config.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/canonical_game_transport.dart';
import 'package:dragon_haven/services/canonical_account_handoff.dart';
import 'package:dragon_haven/services/canonical_legacy_upload.dart';
import 'package:dragon_haven/services/supabase_social_repository.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'canonical_game_session_probe.dart' show LostReplyClient;

void require(bool condition, String code) {
  if (!condition) throw StateError('client_probe_activation_$code');
}

class _LostCloudReplyRepository extends SupabaseSocialRepository {
  _LostCloudReplyRepository(super.client);
  bool dropUpload = true;
  @override
  Future<CloudGameSave> pushCloudGameSave(
      {required int expectedRevision,
      required Map<String, dynamic> state,
      required String deviceId,
      required String clientVersion}) async {
    final saved = await super.pushCloudGameSave(
        expectedRevision: expectedRevision,
        state: state,
        deviceId: deviceId,
        clientVersion: clientVersion);
    if (dropUpload) {
      dropUpload = false;
      throw const SocialException('online_timeout');
    }
    return saved;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // This guarded tool is executed by flutter test, outside the unit-test tree.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
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
    CanonicalAccountHandoff? handoff;
    OnlineAccountProvider? socialReads;
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
      final social = _LostCloudReplyRepository(auth);
      final source = await social.loadCloudGameSave();
      require(source?.revision == 1, 'legacy_source');
      int? baseRevision =
          1; // The synthetic fixture owns this exact cloud base.
      final upload = CanonicalLegacyUpload(
          repository: social,
          directory: directory,
          sourceOwner: () => owner,
          currentOwner: () => migration!.currentOwner,
          sessionEpoch: () => migration!.sessionEpoch,
          settleLegacySources: (_) async {},
          exportState: () => source!.state,
          localRevision: () => 1,
          loadBaseRevision: (_) async => baseRevision,
          saveBaseRevision: (_, revision) async => baseRevision = revision,
          deviceId: () async => 'synthetic-activation-probe',
          clientVersion: '0.05.35');
      var preparations = 0;
      CanonicalAccountHandoff createHandoff() => CanonicalAccountHandoff(
          directory: directory,
          currentOwner: () => migration!.currentOwner,
          sessionEpoch: () => migration!.sessionEpoch,
          readStatus: (_) => migration!.readAccountStatus(),
          prepareAndUploadLegacy: (owner) async {
            preparations++;
            return upload.upload(owner);
          },
          activate: (_, request, revision) => migration!
              .migrateAccount(requestId: request, sourceRevision: revision));
      handoff = createHandoff();
      var lostUpload = false;
      try {
        await handoff.synchronize();
      } on SocialException catch (error) {
        lostUpload = error.code == 'online_timeout';
      }
      require(lostUpload && !social.dropUpload, 'lost_final_upload');
      handoff.dispose();
      handoff = createHandoff();
      var lost = false;
      try {
        await handoff.synchronize();
      } on CanonicalGameException catch (error) {
        lost = error.code == 'game_command_unavailable';
      }
      require(lost && !dropMigration, 'lost_activation');
      final journal = File('${directory.path}/migration-v1-$owner.json');
      final request = (jsonDecode(await journal.readAsString())
          as Map)['requestId'] as String;
      handoff.dispose();
      handoff = createHandoff();
      await handoff.synchronize();
      require(
          handoff.phase == CanonicalHandoffPhase.server &&
              handoff.minimumServerRevision == 3 &&
              preparations == 2 &&
              !await journal.exists(),
          'handoff_restart');
      final revision =
          await migration.migrateAccount(requestId: request, sourceRevision: 2);
      require(revision == 3, 'activation_replayed');
      final status = await migration.readAccountStatus();
      require(
          status.ownerId == owner && status.phase == 'active', 'live_status');
      stdout.writeln('PROBE: account_activation_replayed');
      socialReads = OnlineAccountProvider(
          repository: social,
          serverOwned: true,
          inventorySnapshot: () =>
              throw StateError('client_probe_activation_legacy_inventory'),
          profileSnapshot: () =>
              throw StateError('client_probe_activation_legacy_profile'));
      await socialReads.initialize();
      require(
          socialReads.errorCode == null && socialReads.profile?.userId == owner,
          'server_social_read');
      require(
          !await socialReads.backupToCloud() &&
              socialReads.errorCode == 'game_server_authority_required',
          'server_social_legacy_write_fenced');
      stdout.writeln('PROBE: server_social_read_and_write_fence');
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
      await game.synchronize(
          minimumServerRevision: handoff.minimumServerRevision!);
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
          receipt?.requestId == pending!.requestId && receipt?.replayed == true,
          'purchase_receipt_replayed');
      require(game.snapshot!.coins == before.coins - titleChestCoinPrice,
          'purchase_exact_debit');
      require(game.snapshot!.shop.chests['title'] == titles + 1,
          'purchase_exact_chest');
      require(await game.intents.pending(owner) == null && game.canAct,
          'purchase_journal_settled');
      stdout.writeln(
          'PASS: real account activation; lost activation/purchase replies, private import, live inventory and one debit.');
    } finally {
      socialReads?.dispose();
      handoff?.dispose();
      game?.dispose();
      await migration?.dispose();
      await auth.dispose();
      await directory.delete(recursive: true);
    }
  });
}
