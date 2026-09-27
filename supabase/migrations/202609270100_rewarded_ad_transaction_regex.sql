-- PostgreSQL ARE repetition bounds stop at 255. The original bounded
-- transaction-id expressions therefore raised SQLSTATE 2201B for every real SSV
-- callback. Keep the 256-character product limit as an explicit length check
-- and use an unbounded character-class regex for the allowed alphabet.

set local lock_timeout='5s';
set local statement_timeout='30s';

alter table private.canonical_game_intents
  drop constraint canonical_game_intents_rewarded_ad_context_check;
alter table private.canonical_game_intents
  add constraint canonical_game_intents_rewarded_ad_context_check check (
    rewarded_ad_context is null or (jsonb_typeof(rewarded_ad_context)='object'
    and octet_length(rewarded_ad_context::text)<=4096
    and rewarded_ad_context=jsonb_build_object(
      'version',rewarded_ad_context->'version',
      'ownerId',rewarded_ad_context->'ownerId',
      'action',rewarded_ad_context->'action',
      'claimId',rewarded_ad_context->'claimId',
      'currency',rewarded_ad_context->'currency',
      'amount',rewarded_ad_context->'amount',
      'transactionId',rewarded_ad_context->'transactionId',
      'fingerprint',rewarded_ad_context->'fingerprint')
    and jsonb_typeof(rewarded_ad_context->'version')='number'
    and rewarded_ad_context->'version'='1'::jsonb
    and jsonb_typeof(rewarded_ad_context->'ownerId')='string'
    and rewarded_ad_context->>'ownerId'~
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    and jsonb_typeof(rewarded_ad_context->'action')='string'
    and rewarded_ad_context->>'action'='claim_rewarded_ad'
    and jsonb_typeof(rewarded_ad_context->'claimId')='string'
    and rewarded_ad_context->>'claimId'~
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    and jsonb_typeof(rewarded_ad_context->'currency')='string'
    and rewarded_ad_context->>'currency' in ('gems','coins')
    and jsonb_typeof(rewarded_ad_context->'amount')='number'
    and ((rewarded_ad_context->>'currency'='gems' and
          rewarded_ad_context->'amount'='15'::jsonb) or
         (rewarded_ad_context->>'currency'='coins' and
          rewarded_ad_context->'amount'='150'::jsonb))
    and jsonb_typeof(rewarded_ad_context->'transactionId')='string'
    and length(rewarded_ad_context->>'transactionId') between 1 and 256
    and rewarded_ad_context->>'transactionId'~'^[A-Za-z0-9._~-]+$'
    and jsonb_typeof(rewarded_ad_context->'fingerprint')='string'
    and rewarded_ad_context->>'fingerprint'~'^[0-9a-f]{64}$'
    and private.game_json_sha256(rewarded_ad_context-'fingerprint')=
      rewarded_ad_context->>'fingerprint'));

create or replace function public.record_rewarded_ad_verification(
  p_custom_data text,p_currency text,p_ad_unit_id text,p_reward_item text,
  p_reward_amount integer,p_transaction_id text,p_ad_network text,
  p_timestamp_ms bigint,p_key_id bigint,p_callback_sha256 text
) returns text language plpgsql security definer set search_path='' as $$
declare claim private.rewarded_ad_claims%rowtype; previous private.rewarded_ad_claims%rowtype;
  claim_owner uuid; token_hash text;
  at_time timestamptz:=clock_timestamp(); signed_at timestamptz;
  expected_amount integer;
begin
  perform private.assert_game_service();
  if p_custom_data is null or p_custom_data !~ '^[0-9a-f]{64}$' or
      p_currency is null or p_currency not in ('gems','coins') or
      p_ad_unit_id is null or p_ad_unit_id !~ '^ca-app-pub-[0-9]{16}/[0-9]{10}$' or
      p_reward_item is distinct from p_currency or p_reward_amount is null or
      p_transaction_id is null or length(p_transaction_id) not between 1 and 256 or
      p_transaction_id !~ '^[A-Za-z0-9._~-]+$' or
      p_ad_network is null or length(p_ad_network) not between 1 and 128 or
      p_ad_network ~ '[[:cntrl:]]' or p_timestamp_ms is null or
      p_timestamp_ms not between 1 and 253402300799999 or
      p_key_id is null or p_key_id<1 or p_callback_sha256 is null or
      p_callback_sha256 !~ '^[0-9a-f]{64}$' then
    raise exception 'rewarded_ad_callback_invalid'; end if;
  select case when p_currency='gems' then gems_reward else coins_reward end into strict expected_amount
    from private.rewarded_ad_runtime where singleton;
  if p_reward_amount is distinct from expected_amount then
    raise exception 'rewarded_ad_callback_invalid'; end if;
  token_hash:=encode(extensions.digest(convert_to(p_custom_data,'utf8'),'sha256'),'hex');
  select owner_id into claim_owner from private.rewarded_ad_claims where token_sha256=token_hash;
  if not found then raise exception 'rewarded_ad_claim_unavailable'; end if;
  perform pg_advisory_xact_lock(
    hashtextextended('rewarded-ad-transaction:'||p_transaction_id,0));
  perform pg_advisory_xact_lock(hashtextextended(claim_owner::text,0));
  select * into claim from private.rewarded_ad_claims
    where token_sha256=token_hash for update;
  if not found or claim.currency<>p_currency then raise exception 'rewarded_ad_claim_unavailable'; end if;
  select * into previous from private.rewarded_ad_claims
    where transaction_id=p_transaction_id for update;
  if found then
    if previous.id=claim.id and previous.currency=p_currency and
        previous.ad_unit_id=p_ad_unit_id and previous.reward_item=p_reward_item and
        previous.reward_amount=p_reward_amount then return 'replayed'; end if;
    raise exception 'rewarded_ad_transaction_conflict';
  end if;
  if claim.status not in ('issued','expired') then
    raise exception 'rewarded_ad_claim_unavailable'; end if;
  signed_at:=to_timestamp(p_timestamp_ms/1000.0);
  if signed_at<claim.issued_at-interval '5 minutes' or
      signed_at>claim.expires_at+interval '10 minutes' or at_time>claim.expires_at+interval '1 day' then
    raise exception 'rewarded_ad_claim_expired'; end if;
  update private.rewarded_ad_claims set status='verified',verified_at=at_time,
    transaction_id=p_transaction_id,ad_unit_id=p_ad_unit_id,reward_item=p_reward_item,
    reward_amount=p_reward_amount,ad_network=p_ad_network,
    google_timestamp_ms=p_timestamp_ms,verifier_key_id=p_key_id,
    callback_sha256=p_callback_sha256 where id=claim.id;
  return 'verified';
end $$;

revoke all on function public.record_rewarded_ad_verification(
  text,text,text,text,integer,text,text,bigint,bigint,text)
  from public,anon,authenticated;
grant execute on function public.record_rewarded_ad_verification(
  text,text,text,text,integer,text,text,bigint,bigint,text) to service_role;

notify pgrst,'reload schema';
