-- A rewarded Trial refresh is a one-use server-bound placement. It shares the
-- signed AdMob callback ledger, but has no inventory reward or daily currency
-- quota. The claim is bound to the exact visible offer before the ad opens.
set local lock_timeout='5s';
set local statement_timeout='30s';

alter table private.rewarded_ad_claims
  add column target_offer_id text;
-- The initial table used unnamed column checks. PostgreSQL can suffix their
-- generated names when a restored project has seen another check with the
-- same base name, so identify only these four narrow checks by their columns.
do $migration$
declare check_name text; currency_attnum smallint; slot_attnum smallint;
  item_attnum smallint; amount_attnum smallint; removed integer:=0;
begin
  select max(attnum) filter (where attname='currency'),
    max(attnum) filter (where attname='daily_slot'),
    max(attnum) filter (where attname='reward_item'),
    max(attnum) filter (where attname='reward_amount')
    into currency_attnum,slot_attnum,item_attnum,amount_attnum
    from pg_catalog.pg_attribute
    where attrelid='private.rewarded_ad_claims'::regclass and attnum>0;
  if currency_attnum is null or slot_attnum is null or item_attnum is null or
      amount_attnum is null then
    raise exception 'rewarded_ad_schema_invalid'; end if;
  for check_name in select conname from pg_catalog.pg_constraint
      where conrelid='private.rewarded_ad_claims'::regclass and contype='c' and (
        conkey=array[currency_attnum]::smallint[] or
        conkey=array[slot_attnum]::smallint[] or
        conkey=array[item_attnum]::smallint[] or
        (conkey@>array[currency_attnum,amount_attnum]::smallint[] and
          cardinality(conkey)=2))
  loop
    execute format('alter table private.rewarded_ad_claims drop constraint %I',check_name);
    removed:=removed+1;
  end loop;
  if removed<>4 then raise exception 'rewarded_ad_schema_invalid'; end if;
end $migration$;
alter table private.rewarded_ad_claims
  add constraint rewarded_ad_claims_currency_check
    check (currency in ('gems','coins','trial_refresh')),
  add constraint rewarded_ad_claims_daily_slot_check
    check (daily_slot between 1 and 10000),
  add constraint rewarded_ad_claims_reward_item_check
    check (reward_item is null or reward_item in ('gems','coins','trial_refresh')),
  add constraint rewarded_ad_claims_reward_amount_check
    check (reward_amount is null or
      (currency='gems' and reward_amount=15) or
      (currency='coins' and reward_amount=150) or
      (currency='trial_refresh' and reward_amount=1)),
  add constraint rewarded_ad_claims_trial_offer_check
    check ((currency='trial_refresh' and target_offer_id is not null and
              target_offer_id~'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') or
           (currency in ('gems','coins') and target_offer_id is null));

create function public.issue_my_trial_refresh_ad_claim(p_offer_id text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare keeper uuid:=auth.uid(); runtime private.rewarded_ad_runtime%rowtype;
  game private.canonical_game_states%rowtype; claim private.rewarded_ad_claims%rowtype;
  at_time timestamptz:=clock_timestamp(); today date; midnight timestamptz;
  slot_number integer; token_value text;
begin
  if keeper is null or p_offer_id is null or p_offer_id !~
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' or
      not private.rewarded_ad_account_ready(keeper) then
    raise exception 'rewarded_ad_claim_unavailable'; end if;
  perform pg_advisory_xact_lock(hashtextextended(keeper::text,0));
  select * into strict runtime from private.rewarded_ad_runtime where singleton for share;
  if not runtime.issue_enabled then raise exception 'rewarded_ad_disabled'; end if;
  today:=(at_time at time zone 'UTC')::date;
  midnight:=((today+1)::timestamp at time zone 'UTC');
  if midnight-at_time<interval '2 minutes' then
    raise exception 'rewarded_ad_reset_pending'; end if;
  update private.rewarded_ad_claims set status='expired'
    where owner_id=keeper and currency='trial_refresh' and status='issued'
      and expires_at<=at_time;
  if exists(select 1 from private.rewarded_ad_claims
      where owner_id=keeper and currency='trial_refresh'
        and status in ('issued','verified')) then
    raise exception 'rewarded_ad_claim_pending'; end if;
  select * into game from private.canonical_game_states
    where owner_id=keeper and is_prepared and authority_mode='server' for share;
  if not found or jsonb_typeof(game.state->'trialOffers') is distinct from 'array' or
      not exists(select 1 from jsonb_array_elements(game.state->'trialOffers') offer
        where offer->>'id'=p_offer_id and offer->>'startedAt' is null) then
    raise exception 'game_action_unavailable'; end if;
  perform private.consume_economy_rate_limit(
    keeper,'rewarded_ad.trial_refresh_issue',120,86400);
  select coalesce(max(daily_slot),0)+1 into slot_number
    from private.rewarded_ad_claims
    where owner_id=keeper and currency='trial_refresh' and reward_day=today;
  if slot_number>10000 then raise exception 'rewarded_ad_daily_limit'; end if;
  token_value:=encode(extensions.gen_random_bytes(32),'hex');
  insert into private.rewarded_ad_claims(owner_id,currency,reward_day,daily_slot,
      token_sha256,issued_at,expires_at,target_offer_id)
    values(keeper,'trial_refresh',today,slot_number,
      encode(extensions.digest(convert_to(token_value,'utf8'),'sha256'),'hex'),
      at_time,least(at_time+runtime.claim_lifetime,midnight),p_offer_id)
    returning * into claim;
  return jsonb_build_object('id',claim.id,'token',token_value,
    'currency',claim.currency,'expiresAt',claim.expires_at);
end $$;

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
      p_currency is null or p_currency not in ('gems','coins','trial_refresh') or
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
  select case p_currency when 'gems' then gems_reward
      when 'coins' then coins_reward else 1 end into strict expected_amount
    from private.rewarded_ad_runtime where singleton;
  if p_reward_amount is distinct from expected_amount then
    raise exception 'rewarded_ad_callback_invalid'; end if;
  token_hash:=encode(extensions.digest(convert_to(p_custom_data,'utf8'),'sha256'),'hex');
  select owner_id into claim_owner from private.rewarded_ad_claims where token_sha256=token_hash;
  if not found then raise exception 'rewarded_ad_claim_unavailable'; end if;
  perform pg_advisory_xact_lock(hashtextextended('rewarded-ad-transaction:'||p_transaction_id,0));
  perform pg_advisory_xact_lock(hashtextextended(claim_owner::text,0));
  select * into claim from private.rewarded_ad_claims
    where token_sha256=token_hash for update;
  if not found or claim.currency<>p_currency then
    raise exception 'rewarded_ad_claim_unavailable'; end if;
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
      signed_at>claim.expires_at+interval '10 minutes' or
      at_time>claim.expires_at+interval '1 day' then
    raise exception 'rewarded_ad_claim_expired'; end if;
  update private.rewarded_ad_claims set status='verified',verified_at=at_time,
    transaction_id=p_transaction_id,ad_unit_id=p_ad_unit_id,reward_item=p_reward_item,
    reward_amount=p_reward_amount,ad_network=p_ad_network,
    google_timestamp_ms=p_timestamp_ms,verifier_key_id=p_key_id,
    callback_sha256=p_callback_sha256 where id=claim.id;
  return 'verified';
end $$;

alter table private.canonical_game_intents
  drop constraint canonical_game_intents_rewarded_ad_context_check;
alter table private.canonical_game_intents
  add constraint canonical_game_intents_rewarded_ad_context_check check (
    rewarded_ad_context is null or (jsonb_typeof(rewarded_ad_context)='object'
    and octet_length(rewarded_ad_context::text)<=4096
    and ((rewarded_ad_context->>'action'='claim_rewarded_ad' and
          rewarded_ad_context=jsonb_build_object(
            'version',rewarded_ad_context->'version','ownerId',rewarded_ad_context->'ownerId',
            'action',rewarded_ad_context->'action','claimId',rewarded_ad_context->'claimId',
            'currency',rewarded_ad_context->'currency','amount',rewarded_ad_context->'amount',
            'transactionId',rewarded_ad_context->'transactionId',
            'fingerprint',rewarded_ad_context->'fingerprint')) or
         (rewarded_ad_context->>'action'='refresh_trial_with_ad' and
          rewarded_ad_context=jsonb_build_object(
            'version',rewarded_ad_context->'version','ownerId',rewarded_ad_context->'ownerId',
            'action',rewarded_ad_context->'action','claimId',rewarded_ad_context->'claimId',
            'offerId',rewarded_ad_context->'offerId','currency',rewarded_ad_context->'currency',
            'amount',rewarded_ad_context->'amount','transactionId',rewarded_ad_context->'transactionId',
            'fingerprint',rewarded_ad_context->'fingerprint')))
    and rewarded_ad_context->'version'='1'::jsonb
    and rewarded_ad_context->>'ownerId'~
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    and rewarded_ad_context->>'claimId'~
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    and ((rewarded_ad_context->>'action'='claim_rewarded_ad' and
          rewarded_ad_context->>'currency' in ('gems','coins') and
          ((rewarded_ad_context->>'currency'='gems' and rewarded_ad_context->'amount'='15'::jsonb) or
           (rewarded_ad_context->>'currency'='coins' and rewarded_ad_context->'amount'='150'::jsonb))) or
         (rewarded_ad_context->>'action'='refresh_trial_with_ad' and
          rewarded_ad_context->>'offerId'~
            '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' and
          rewarded_ad_context->>'currency'='trial_refresh' and
          rewarded_ad_context->'amount'='1'::jsonb))
    and length(rewarded_ad_context->>'transactionId') between 1 and 256
    and rewarded_ad_context->>'transactionId'~'^[A-Za-z0-9._~-]+$'
    and rewarded_ad_context->>'fingerprint'~'^[0-9a-f]{64}$'
    and private.game_json_sha256(rewarded_ad_context-'fingerprint')=
      rewarded_ad_context->>'fingerprint'));

create function private.canonical_trial_refresh_ad_context(
  p_owner uuid,p_payload jsonb,p_at timestamptz
) returns jsonb language plpgsql security definer set search_path='' as $$
declare claim private.rewarded_ad_claims%rowtype; game private.canonical_game_states%rowtype;
  context_value jsonb;
begin
  perform private.assert_game_service();
  if p_owner is null or p_at is null or jsonb_typeof(p_payload) is distinct from 'object' or
      p_payload is distinct from jsonb_build_object(
        'claimId',p_payload->>'claimId','offerId',p_payload->>'offerId') or
      p_payload->>'claimId' !~
        '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' or
      p_payload->>'offerId' !~
        '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' or
      not private.rewarded_ad_account_ready(p_owner) then
    raise exception 'rewarded_ad_claim_unavailable'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner::text,0));
  select * into claim from private.rewarded_ad_claims
    where id=(p_payload->>'claimId')::uuid and owner_id=p_owner for update;
  if not found or claim.status<>'verified' or claim.currency<>'trial_refresh' or
      claim.target_offer_id<>p_payload->>'offerId' or claim.transaction_id is null or
      claim.verified_at is null or claim.verified_at>p_at then
    raise exception 'rewarded_ad_claim_unavailable'; end if;
  select * into game from private.canonical_game_states where owner_id=p_owner for share;
  if not found or jsonb_typeof(game.state->'trialOffers') is distinct from 'array' or
      not exists(select 1 from jsonb_array_elements(game.state->'trialOffers') offer
        where offer->>'id'=claim.target_offer_id and offer->>'startedAt' is null) then
    raise exception 'rewarded_ad_claim_unavailable'; end if;
  context_value:=jsonb_build_object('version',1,'ownerId',p_owner,
    'action','refresh_trial_with_ad','claimId',claim.id,
    'offerId',claim.target_offer_id,'currency','trial_refresh','amount',1,
    'transactionId',claim.transaction_id);
  return context_value||jsonb_build_object(
    'fingerprint',private.game_json_sha256(context_value));
exception when invalid_text_representation then
  raise exception 'rewarded_ad_claim_unavailable';
end $$;

alter function public.begin_revisioned_game_command(
  uuid,uuid,text,jsonb,integer,text,bigint)
  rename to begin_revisioned_game_command_v105;
create function public.begin_revisioned_game_command(
  p_owner_id uuid,p_request_id uuid,p_action text,p_payload jsonb,
  p_client_build integer,p_ruleset_sha256 text,p_expected_revision bigint
) returns jsonb language plpgsql security definer set search_path='' as $$
declare leased jsonb; context_value jsonb;
begin
  perform private.assert_game_service();
  leased:=public.begin_revisioned_game_command_v105(p_owner_id,p_request_id,p_action,
    p_payload,p_client_build,p_ruleset_sha256,p_expected_revision);
  if p_action<>'refresh_trial_with_ad' or leased->>'status'<>'processing' then
    return leased; end if;
  select rewarded_ad_context into context_value from private.canonical_game_intents
    where owner_id=p_owner_id and request_id=p_request_id;
  if context_value is null then
    begin
      context_value:=private.canonical_trial_refresh_ad_context(
        p_owner_id,p_payload,(leased->>'now')::timestamptz);
    exception when raise_exception then
      if sqlerrm<>'rewarded_ad_claim_unavailable' then raise; end if;
      if not public.fail_canonical_game_command(p_owner_id,p_request_id,
          (leased->>'lease_token')::uuid,'rewarded_ad_claim_unavailable') then
        raise exception 'game_lease_lost'; end if;
      return jsonb_build_object('status','failed',
        'failure_code','rewarded_ad_claim_unavailable','response',null,'replayed',false);
    end;
    update private.canonical_game_intents set rewarded_ad_context=context_value
      where owner_id=p_owner_id and request_id=p_request_id;
  end if;
  return leased||jsonb_build_object('rewarded_ad_context',context_value);
end $$;

alter function public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb)
  rename to commit_canonical_game_command_v105;
create function public.commit_canonical_game_command(
  p_owner_id uuid,p_request_id uuid,p_lease_token uuid,p_state jsonb,p_result jsonb
) returns jsonb language plpgsql security definer set search_path='' as $$
declare intent private.canonical_game_intents%rowtype; current_context jsonb;
  receipt jsonb; claim_id uuid; changed integer;
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_request_id is null or p_lease_token is null then
    raise exception 'game_request_invalid'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0));
  select * into intent from private.canonical_game_intents
    where owner_id=p_owner_id and request_id=p_request_id for update;
  if not found or intent.lease_token<>p_lease_token then
    raise exception 'game_lease_lost'; end if;
  if intent.status<>'processing' or intent.action<>'refresh_trial_with_ad' then
    return public.commit_canonical_game_command_v105(
      p_owner_id,p_request_id,p_lease_token,p_state,p_result); end if;
  if intent.leased_until<=clock_timestamp() then raise exception 'game_lease_lost'; end if;
  begin
    current_context:=private.canonical_trial_refresh_ad_context(
      p_owner_id,intent.payload,clock_timestamp());
  exception when raise_exception then
    if sqlerrm='rewarded_ad_claim_unavailable' then
      raise exception 'rewarded_ad_state_changed'; end if;
    raise;
  end;
  if current_context is distinct from intent.rewarded_ad_context or
      p_result->'accepted' is distinct from 'true'::jsonb or
      p_result->>'claimId'<>current_context->>'claimId' or
      p_result->>'replacedOfferId'<>current_context->>'offerId' or
      jsonb_typeof(p_result->'offer') is distinct from 'object' or
      p_result->'offer'->>'id'=current_context->>'offerId' then
    raise exception 'rewarded_ad_state_changed'; end if;
  receipt:=public.commit_canonical_game_command_v105(
    p_owner_id,p_request_id,p_lease_token,p_state,p_result);
  claim_id:=(current_context->>'claimId')::uuid;
  update private.rewarded_ad_claims set status='claimed',claimed_at=clock_timestamp(),
    canonical_request_id=p_request_id,
    canonical_revision=(receipt->>'server_revision')::bigint
    where id=claim_id and owner_id=p_owner_id and status='verified';
  get diagnostics changed=row_count;
  if changed<>1 then raise exception 'rewarded_ad_state_changed'; end if;
  return receipt;
end $$;

revoke all on function public.issue_my_trial_refresh_ad_claim(text)
  from public,anon;
grant execute on function public.issue_my_trial_refresh_ad_claim(text)
  to authenticated;
revoke all on function private.canonical_trial_refresh_ad_context(uuid,jsonb,timestamptz),
  public.begin_revisioned_game_command_v105(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command_v105(uuid,uuid,uuid,jsonb,jsonb)
  from public,anon,authenticated,service_role;
revoke all on function public.record_rewarded_ad_verification(
  text,text,text,text,integer,text,text,bigint,bigint,text),
  public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb)
  from public,anon,authenticated;
grant execute on function public.record_rewarded_ad_verification(
  text,text,text,text,integer,text,text,bigint,bigint,text),
  public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb)
  to service_role;

notify pgrst,'reload schema';
