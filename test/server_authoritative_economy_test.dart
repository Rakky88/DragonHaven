import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/202609050037_economy_authority_foundation.sql',
  ).readAsStringSync();
  final timestampFix = File(
    'supabase/migrations/202609050038_economy_rate_limit_timestamp_fix.sql',
  ).readAsStringSync();
  final contract = File('SERVER_AUTHORITATIVE_ECONOMY.md').readAsStringSync();
  final stagingWorkflow = File(
    '.github/workflows/staging-economy-foundation.yml',
  ).readAsStringSync();
  final stagingE2e = File(
    'tool/staging_economy_foundation_e2e.ps1',
  ).readAsStringSync();
  final contractDrillWorkflow = File(
    '.github/workflows/staging-economy-contract-drill.yml',
  ).readAsStringSync();

  test('migration 37 is dormant and preserves all existing economy tables', () {
    expect(
      migration,
      contains('mutations_enabled boolean not null default false'),
    );
    expect(
      migration,
      contains("authority_mode text not null default 'legacy_client'"),
    );
    expect(migration,
        contains('minimum_client_build integer not null default 10061'));
    expect(migration, isNot(contains('drop table')));
    expect(migration, isNot(contains('truncate ')));
    expect(migration, isNot(contains('delete from public.player_')));
    expect(migration, isNot(contains('update public.player_wallets')));
    expect(migration, isNot(contains('alter table public.player_wallets')));
  });

  test('foundation covers authority instances claims requests and ledger', () {
    for (final table in const [
      'private.economy_contract',
      'public.player_economy_authority',
      'public.economy_mutation_requests',
      'public.player_item_instances',
      'public.player_chest_instances',
      'public.economy_reward_claims',
      'public.economy_ledger_entries',
      'private.economy_rate_limit_buckets',
    ]) {
      expect(migration, contains('create table $table'), reason: table);
    }
    expect(migration, contains('unique (owner_id, claim_type, claim_key)'));
    expect(
      migration,
      contains('primary key (owner_id, request_id)'),
    );
    expect(
      migration,
      contains(
          'references public.economy_mutation_requests(owner_id, request_id)'),
    );
  });

  test('valuable tables are RLS protected and have no client table grants', () {
    for (final table in const [
      'player_economy_authority',
      'economy_mutation_requests',
      'player_item_instances',
      'player_chest_instances',
      'economy_reward_claims',
      'economy_ledger_entries',
    ]) {
      expect(
        migration,
        contains('alter table public.$table enable row level security;'),
        reason: table,
      );
      expect(
        migration,
        contains('revoke all on table public.$table'),
        reason: table,
      );
    }
    expect(migration, isNot(contains('grant select on table public.')));
    expect(migration, isNot(contains('grant insert on table public.')));
    expect(migration, isNot(contains('grant update on table public.')));
    expect(migration, isNot(contains('grant delete on table public.')));
  });

  test('idempotency binds one request id to one operation and payload', () {
    final begin = migration.substring(
      migration
          .indexOf('create or replace function private.begin_economy_mutation'),
      migration.indexOf(
          'create or replace function private.complete_economy_mutation'),
    );
    expect(begin, contains('extensions.digest'));
    expect(begin, contains("'sha256'"));
    expect(begin, contains('economy_idempotency_conflict'));
    expect(begin, contains("'replayed', true"));
    expect(begin, contains("'replayed', false"));
    expect(
      begin.indexOf('if found then'),
      lessThan(begin.indexOf('private.consume_economy_rate_limit')),
      reason: 'a replay must not consume a fresh rate-limit slot',
    );
    expect(begin, contains('pg_advisory_xact_lock'));
    expect(begin, contains('p_payload is null'));
  });

  test('ledger is append-only and records source mutation delta and balance',
      () {
    expect(migration, contains('economy_ledger_entries_reject_change'));
    expect(
      migration,
      contains('before update or delete on public.economy_ledger_entries'),
    );
    expect(migration, contains('economy_ledger_is_append_only'));
    expect(migration, contains("tg_op = 'DELETE' and pg_trigger_depth() > 1"));
    expect(
      migration,
      contains('select 1 from public.profiles where user_id = old.owner_id'),
    );
    expect(
      migration,
      contains(
        'owner_id uuid not null references public.profiles(user_id)\n'
        '    on delete cascade',
      ),
    );
    expect(migration, contains('mutation_type text not null'));
    expect(migration, contains('source_type text not null'));
    expect(migration, contains('quantity_delta bigint not null'));
    expect(migration, contains('balance_after bigint'));
    expect(migration, contains("'purchase', 'refund'"));
    expect(migration, contains('private.append_economy_ledger_entry'));
  });

  test('compatibility gate rejects disabled old and mismatched clients', () {
    final assertion = migration.substring(
      migration
          .indexOf('create or replace function private.assert_economy_client'),
      migration.indexOf(
          'create or replace function private.consume_economy_rate_limit'),
    );
    expect(assertion, contains("authority.authority_mode <> 'server'"));
    expect(assertion, contains('not contract.mutations_enabled'));
    expect(assertion, contains('economy_mutations_disabled'));
    expect(assertion, contains('economy_contract_unavailable'));
    expect(assertion, contains('p_protocol_version is null'));
    expect(
        assertion, contains('p_protocol_version <> contract.protocol_version'));
    expect(assertion,
        contains('p_protocol_version <> authority.protocol_version'));
    expect(
        assertion, contains('p_client_build < contract.minimum_client_build'));
    expect(assertion, contains('economy_client_upgrade_required'));
  });

  test('the only new public RPC is a narrow read-only contract projection', () {
    final publicFunctions = RegExp(
      r'create or replace function public\.([a-z0-9_]+)',
    ).allMatches(migration).map((match) => match.group(1)).toSet();
    expect(publicFunctions, {'get_my_economy_contract'});

    final projection = migration.substring(
      migration
          .indexOf('create or replace function public.get_my_economy_contract'),
      migration.indexOf(
        'revoke all on function private.bootstrap_player_economy_authority',
      ),
    );
    expect(projection, contains('language sql'));
    expect(projection, contains('stable'));
    expect(projection, contains('auth.uid() is not null'));
    expect(projection, isNot(contains('insert into')));
    expect(projection, isNot(contains('update ')));
    expect(projection, isNot(contains('delete from')));
    expect(projection, isNot(contains('email')));
    expect(projection, isNot(contains('display_name')));
  });

  test('design remains free-first Play-upgradeable and production dormant', () {
    expect(contract, contains('free-first'));
    expect(contract, contains('Google Play purchase'));
    expect(contract, contains('without storing card details'));
    expect(contract, contains('legacy_client'));
    expect(contract, contains('shadow'));
    expect(contract, contains('server'));
    expect(contract, contains('Database rollback is fix-forward'));
    expect(contract, contains('production project'));
    expect(contract, contains('public release'));
    expect(contract, contains('global mutation'));
    expect(contract, contains('switch remains disabled'));
    for (final forbidden in const [
      'email address',
      'payment card data',
      'purchase token',
      'raw store receipt',
    ]) {
      expect(contract, contains(forbidden));
    }
    expect(contract, contains('full account/profile deletion'));
  });

  test('staging recovery accepts exact 37 to 38 and hard-blocks production',
      () {
    expect(
      stagingWorkflow,
      contains('APPLY_DRAGONHAVEN_STAGING_ECONOMY_37_38'),
    );
    expect(stagingWorkflow, contains("\$expectedRemote = '202609050037'"));
    expect(
      stagingWorkflow,
      contains("\$expectedPending = @('202609050038')"),
    );
    expect(
      stagingWorkflow,
      contains('supabase db push --linked --include-all --dry-run'),
    );
    expect(stagingWorkflow, contains('environment: staging'));
    expect(stagingWorkflow, contains("-Environment staging"));
    expect(stagingWorkflow, isNot(contains('-Environment production')));
    expect(
      stagingWorkflow,
      contains("\$projectRef -eq 'tnzathhutuwmohmjfrlo'"),
    );
    expect(
      stagingWorkflow,
      contains('./tool/staging_economy_foundation_e2e.ps1'),
    );
  });

  test('migration 38 fixes the ambiguous rate-limit timestamp forward', () {
    expect(timestampFix, contains('v_now timestamptz := clock_timestamp()'));
    expect(
      timestampFix,
      contains('v_now + make_interval(secs => p_window_seconds)'),
    );
    expect(timestampFix, contains('bucket.reset_at <= v_now'));
    expect(timestampFix, isNot(contains('current_time + make_interval')));
    expect(timestampFix, contains('revoke all on function'));
    expect(timestampFix, isNot(contains('drop ')));
    expect(timestampFix, isNot(contains('delete from')));
  });

  test('staging E2E proves dormant access and stores privacy-safe evidence',
      () {
    expect(stagingE2e,
        contains("\$productionProjectRef = 'tnzathhutuwmohmjfrlo'"));
    expect(stagingE2e, contains('migration_37_applied'));
    expect(stagingE2e, contains('migration_38_applied'));
    expect(stagingE2e, contains('all_valuable_tables_have_rls'));
    expect(stagingE2e, contains('direct_client_table_access_absent'));
    expect(stagingE2e, contains('append_only_trigger_enabled'));
    expect(stagingE2e, contains('timestamp_fix_active'));
    expect(stagingE2e, contains('economy_mutations_disabled'));
    expect(stagingE2e, contains('no_probe_was_persisted'));
    expect(stagingE2e, contains('pg_temp.run_economy_contract_drill'));
    expect(stagingE2e, contains('economy_client_upgrade_required'));
    expect(stagingE2e, contains('economy_idempotency_conflict'));
    expect(stagingE2e, contains('economy_rate_limited'));
    expect(stagingE2e, contains('economy_contract_drill_rollback'));
    expect(stagingE2e, contains('transaction_rollback_verified=true'));
    expect(stagingE2e, contains('raw_identifiers_recorded=false'));
    expect(stagingE2e, contains('credentials_recorded=false'));
    expect(stagingE2e, isNot(contains('Write-Host \$normalizedEmail')));
    expect(stagingE2e, isNot(contains('Set-Content -Value \$accessToken')));
  });

  test('contract drill workflow cannot migrate or target production', () {
    expect(
      contractDrillWorkflow,
      contains('TEST_DRAGONHAVEN_STAGING_ECONOMY_CONTRACT'),
    );
    expect(contractDrillWorkflow, contains('environment: staging'));
    expect(contractDrillWorkflow, contains('release_server_preflight.ps1'));
    expect(contractDrillWorkflow, contains('staging_economy_foundation_e2e'));
    expect(contractDrillWorkflow, isNot(contains('supabase db push')));
    expect(contractDrillWorkflow, isNot(contains('-Environment production')));
    expect(
      contractDrillWorkflow,
      contains("\$projectRef -eq 'tnzathhutuwmohmjfrlo'"),
    );
  });
}
