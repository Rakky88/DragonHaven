import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationPath = 'supabase/migrations/202609230094_rewarded_ads.sql';

String _compact(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();

String _between(String source, String start, String end) {
  final from = source.indexOf(start);
  final to = source.indexOf(end, from + start.length);
  expect(from, greaterThanOrEqualTo(0), reason: 'Missing $start');
  expect(to, greaterThan(from), reason: 'Missing $end after $start');
  return source.substring(from, to);
}

void main() {
  late String sql;
  late String compact;

  setUpAll(() {
    sql = File(_migrationPath).readAsStringSync();
    compact = _compact(sql);
  });

  test('reward issuance is dormant with fixed product limits and rewards', () {
    expect(compact, contains('issue_enabled boolean not null default false'));
    expect(
        compact,
        contains(
            'daily_limit integer not null default 3 check (daily_limit = 3)'));
    expect(
        compact,
        contains(
            'gems_reward integer not null default 15 check (gems_reward = 15)'));
    expect(
        compact,
        contains(
            'coins_reward integer not null default 150 check (coins_reward = 150)'));
    expect(
        compact,
        contains(
            'daily_slot integer not null check (daily_slot between 1 and 3)'));
    expect(
        compact,
        contains(
            "private.consume_economy_rate_limit(keeper,'rewarded_ad.issue',30,86400)"));
    expect(
        compact,
        contains(
            'where status in (\'issued\',\'verified\',\'claimed\',\'expired\')'));
  });

  test('expired slots stay reserved while late signed callbacks remain valid',
      () {
    expect(compact,
        contains("where status in ('issued','verified','claimed','expired')"));
    expect(compact, contains("where status='issued'"));
    expect(compact, contains("claim.status not in ('issued','expired')"));
    expect(compact,
        contains("'remaining',greatest(0,runtime.daily_limit-reserved)"));
    expect(compact,
        contains("order by case when c.status='verified' then 0 else 1 end"));
    expect(
        compact,
        contains(
            "signed_at>claim.expires_at+interval '10 minutes' or at_time>claim.expires_at+interval '1 day'"));
    expect(RegExp("status='expired'").allMatches(compact).length, 3,
        reason: 'every status path expires the open display claim normally');
  });

  test(
      'SSV record rejects nullable fields and locks without an owner-row cycle',
      () {
    final callback = _between(
        sql,
        'create function public.record_rewarded_ad_verification(',
        'alter table private.canonical_game_intents');
    final normalized = _compact(callback);
    for (final guard in [
      'p_custom_data is null',
      'p_currency is null',
      'p_ad_unit_id is null',
      'p_reward_amount is null',
      'p_transaction_id is null',
      'p_ad_network is null',
      'p_timestamp_ms is null',
      'p_key_id is null',
      'p_callback_sha256 is null',
    ]) {
      expect(normalized, contains(guard), reason: guard);
    }
    expect(normalized, contains('p_reward_item is distinct from p_currency'));
    expect(normalized,
        contains('p_timestamp_ms not between 1 and 253402300799999'));

    final transactionFence =
        callback.indexOf("'rewarded-ad-transaction:'||p_transaction_id");
    final ownerFence = callback.indexOf(
        'pg_advisory_xact_lock(hashtextextended(claim_owner::text,0))');
    final claimRowLock =
        callback.indexOf('where token_sha256=token_hash for update');
    expect(transactionFence, greaterThanOrEqualTo(0));
    expect(ownerFence, greaterThan(transactionFence));
    expect(claimRowLock, greaterThan(ownerFence));
  });

  test('reward context is private, owner-bound and sealed before evaluation',
      () {
    expect(
        compact,
        contains(
            "p_payload is distinct from jsonb_build_object('claimId',p_payload->>'claimId')"));
    expect(
        compact,
        contains(
            'where id=(p_payload->>\'claimId\')::uuid and owner_id=p_owner for update'));
    expect(compact,
        contains("'fingerprint',private.game_json_sha256(context_value)"));
    expect(
        compact,
        contains(
            "private.game_json_sha256(rewarded_ad_context-'fingerprint')= rewarded_ad_context->>'fingerprint'"));
    expect(
        compact,
        contains(
            'update private.canonical_game_intents set rewarded_ad_context=context_value'));
    expect(
        compact,
        contains(
            'private.canonical_rewarded_ad_context(uuid,jsonb,timestamptz)'));
  });

  test('wallet and one-use claim commit in one guarded transaction', () {
    final commit = _between(
        sql,
        'create function public.commit_canonical_game_command(',
        'revoke all on function private.rewarded_ad_account_ready');
    final normalized = _compact(commit);
    expect(normalized, contains("intent.status<>'processing'"));
    expect(
        normalized,
        contains(
            "jsonb_typeof(p_state->'pendingPresentations') is distinct from 'array'"));
    expect(
        normalized,
        contains(
            "(p_state->'pendingPresentations'- (jsonb_array_length(p_state->'pendingPresentations')-1)) is distinct from game.state->'pendingPresentations'"));
    expect(normalized, contains('if presentation_matches<>1 then'));

    final canonicalCommit =
        commit.indexOf('receipt:=public.commit_canonical_game_command_v93(');
    final claimCommit = commit
        .indexOf("update private.rewarded_ad_claims set status='claimed'");
    final rowCountCheck = commit.indexOf(
        "if changed<>1 then raise exception 'rewarded_ad_state_changed'");
    expect(canonicalCommit, greaterThanOrEqualTo(0));
    expect(claimCommit, greaterThan(canonicalCommit));
    expect(rowCountCheck, greaterThan(claimCommit));
  });

  test('tables stay private and only intended RPC roles receive execute', () {
    expect(
        compact,
        contains(
            'revoke all on private.rewarded_ad_runtime,private.rewarded_ad_claims from public,anon,authenticated,service_role'));
    expect(
        compact,
        contains(
            'grant execute on function public.get_my_rewarded_ad_status(), public.issue_my_rewarded_ad_claim(text),public.get_my_rewarded_ad_claim(uuid), public.cancel_my_rewarded_ad_claim(uuid) to authenticated'));
    expect(
        compact,
        contains(
            'public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb) to service_role'));
  });
}
