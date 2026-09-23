-- Rewarded ads remain dormant until the owner has configured AdMob, SSV and
-- consent and explicitly enables new issues. Google callbacks only verify a
-- private one-use claim; currency enters the canonical revisioned game commit.
create table private.rewarded_ad_runtime (
  singleton boolean primary key default true check (singleton),
  issue_enabled boolean not null default false,
  daily_limit integer not null default 3 check (daily_limit = 3),
  gems_reward integer not null default 15 check (gems_reward = 15),
  coins_reward integer not null default 150 check (coins_reward = 150),
  claim_lifetime interval not null default interval '15 minutes'
    check (claim_lifetime between interval '2 minutes' and interval '30 minutes')
);
insert into private.rewarded_ad_runtime(singleton) values (true);

create table private.rewarded_ad_claims (
  id uuid primary key default extensions.gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  currency text not null check (currency in ('gems','coins')),
  reward_day date not null,
  daily_slot integer not null check (daily_slot between 1 and 3),
  token_sha256 text not null unique check (token_sha256 ~ '^[0-9a-f]{64}$'),
  status text not null default 'issued'
    check (status in ('issued','verified','claimed','cancelled','expired')),
  issued_at timestamptz not null,
  expires_at timestamptz not null check (expires_at > issued_at),
  verified_at timestamptz,
  claimed_at timestamptz,
  transaction_id text unique check (transaction_id is null or
    (length(transaction_id) between 1 and 256 and transaction_id ~ '^[A-Za-z0-9._~-]+$')),
  ad_unit_id text check (ad_unit_id is null or
    ad_unit_id ~ '^ca-app-pub-[0-9]{16}/[0-9]{10}$'),
  reward_item text check (reward_item is null or reward_item in ('gems','coins')),
  reward_amount integer check (reward_amount is null or
    (currency='gems' and reward_amount=15) or
    (currency='coins' and reward_amount=150)),
  ad_network text check (ad_network is null or
    (length(ad_network) between 1 and 128 and ad_network !~ '[[:cntrl:]]')),
  google_timestamp_ms bigint check (google_timestamp_ms is null or
    google_timestamp_ms between 1 and 253402300799999),
  verifier_key_id bigint check (verifier_key_id is null or verifier_key_id>0),
  callback_sha256 text check (callback_sha256 is null or callback_sha256 ~ '^[0-9a-f]{64}$'),
  canonical_request_id uuid,
  canonical_revision bigint check (canonical_revision is null or
    canonical_revision between 1 and 9007199254740991),
  check ((issued_at at time zone 'UTC')::date=reward_day),
  check (expires_at <= ((reward_day + 1)::timestamp at time zone 'UTC')),
  check (verified_at is null or verified_at>=issued_at),
  check (claimed_at is null or (verified_at is not null and claimed_at>=verified_at)),
  check (
    (status in ('issued','cancelled','expired') and verified_at is null and
      claimed_at is null and transaction_id is null and ad_unit_id is null and
      reward_item is null and reward_amount is null and ad_network is null and
      google_timestamp_ms is null and verifier_key_id is null and
      callback_sha256 is null and canonical_request_id is null and
      canonical_revision is null) or
    (status = 'verified' and verified_at is not null and claimed_at is null and
      transaction_id is not null and ad_unit_id is not null and
      reward_item is not null and reward_item=currency and reward_amount is not null and
      ad_network is not null and
      google_timestamp_ms is not null and verifier_key_id is not null and
      callback_sha256 is not null and canonical_request_id is null and
      canonical_revision is null) or
    (status = 'claimed' and verified_at is not null and claimed_at is not null and
      transaction_id is not null and ad_unit_id is not null and
      reward_item is not null and reward_item=currency and reward_amount is not null and
      ad_network is not null and
      google_timestamp_ms is not null and verifier_key_id is not null and
      callback_sha256 is not null and canonical_request_id is not null and
      canonical_revision is not null)
  )
);
create unique index rewarded_ad_active_slot
  on private.rewarded_ad_claims(owner_id,currency,reward_day,daily_slot)
  where status in ('issued','verified','claimed','expired');
create unique index rewarded_ad_single_open_claim
  on private.rewarded_ad_claims(owner_id,currency)
  where status='issued';
create index rewarded_ad_owner_history
  on private.rewarded_ad_claims(owner_id,reward_day desc,currency,status);
create unique index rewarded_ad_canonical_request
  on private.rewarded_ad_claims(owner_id,canonical_request_id)
  where canonical_request_id is not null;
create unique index rewarded_ad_canonical_revision
  on private.rewarded_ad_claims(owner_id,canonical_revision)
  where canonical_revision is not null;

alter table private.rewarded_ad_runtime enable row level security;
alter table private.rewarded_ad_claims enable row level security;
revoke all on private.rewarded_ad_runtime,private.rewarded_ad_claims
  from public,anon,authenticated,service_role;

create function private.rewarded_ad_account_ready(p_owner uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from private.canonical_game_states g
    where g.owner_id=p_owner and g.is_prepared and g.authority_mode='server')
$$;

create function public.get_my_rewarded_ad_status()
returns jsonb language plpgsql security definer set search_path='' as $$
declare keeper uuid:=auth.uid(); at_time timestamptz:=clock_timestamp();
  today date:=(at_time at time zone 'UTC')::date;
  runtime private.rewarded_ad_runtime%rowtype; currency_name text;
  claimed integer; reserved integer; active jsonb; offers jsonb:='{}'::jsonb;
begin
  if keeper is null or not private.rewarded_ad_account_ready(keeper) then
    raise exception 'rewarded_ad_login_required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(keeper::text,0));
  update private.rewarded_ad_claims set status='expired'
    where owner_id=keeper and status='issued' and expires_at<=at_time;
  select * into strict runtime from private.rewarded_ad_runtime where singleton;
  foreach currency_name in array array['gems','coins'] loop
    select count(*)::integer into claimed from private.rewarded_ad_claims
      where owner_id=keeper and currency=currency_name and reward_day=today
        and status in ('verified','claimed');
    select count(*)::integer into reserved from private.rewarded_ad_claims
      where owner_id=keeper and currency=currency_name and reward_day=today
        and status in ('issued','verified','claimed','expired');
    select jsonb_build_object('id',c.id,'status',c.status,'expiresAt',c.expires_at)
      into active from private.rewarded_ad_claims c
      where c.owner_id=keeper and c.currency=currency_name
        and c.status in ('issued','verified')
      order by case when c.status='verified' then 0 else 1 end,
        c.issued_at desc limit 1;
    offers:=offers||jsonb_build_object(currency_name,jsonb_build_object(
      'reward',case when currency_name='gems' then runtime.gems_reward else runtime.coins_reward end,
      'claimedToday',claimed,
      'remaining',greatest(0,runtime.daily_limit-reserved),
      'activeClaim',active));
    active:=null;
  end loop;
  return jsonb_build_object('enabled',runtime.issue_enabled,
    'dailyLimit',runtime.daily_limit,
    'nextResetAt',((today+1)::timestamp at time zone 'UTC'),
    'offers',offers);
end $$;

create function public.issue_my_rewarded_ad_claim(p_currency text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare keeper uuid:=auth.uid(); at_time timestamptz:=clock_timestamp();
  today date:=(at_time at time zone 'UTC')::date;
  midnight timestamptz:=((today+1)::timestamp at time zone 'UTC');
  runtime private.rewarded_ad_runtime%rowtype; slot_number integer;
  token_value text; claim private.rewarded_ad_claims%rowtype;
begin
  if keeper is null or p_currency is null or p_currency not in ('gems','coins') or
      not private.rewarded_ad_account_ready(keeper) then
    raise exception 'rewarded_ad_claim_unavailable'; end if;
  perform pg_advisory_xact_lock(hashtextextended(keeper::text,0));
  select * into strict runtime from private.rewarded_ad_runtime where singleton for share;
  if not runtime.issue_enabled then raise exception 'rewarded_ad_claim_unavailable'; end if;
  update private.rewarded_ad_claims set status='expired'
    where owner_id=keeper and status='issued' and expires_at<=at_time;
  if exists(select 1 from private.rewarded_ad_claims where owner_id=keeper
      and currency=p_currency and status='issued') then
    raise exception 'rewarded_ad_claim_pending'; end if;
  -- Do not hand out a token too close to UTC reset for a rewarded video and
  -- its signed callback to finish before the old day's slot closes.
  if midnight-at_time < interval '2 minutes' then
    raise exception 'rewarded_ad_reset_pending'; end if;
  select slot into slot_number from generate_series(1,runtime.daily_limit) slot
    where not exists(select 1 from private.rewarded_ad_claims c
      where c.owner_id=keeper and c.currency=p_currency and c.reward_day=today
        and c.daily_slot=slot and c.status in ('issued','verified','claimed','expired'))
    order by slot limit 1;
  if slot_number is null then raise exception 'rewarded_ad_daily_limit'; end if;
  perform private.consume_economy_rate_limit(keeper,'rewarded_ad.issue',30,86400);
  token_value:=encode(extensions.gen_random_bytes(32),'hex');
  insert into private.rewarded_ad_claims(owner_id,currency,reward_day,daily_slot,
      token_sha256,issued_at,expires_at)
    values(keeper,p_currency,today,slot_number,
      encode(extensions.digest(convert_to(token_value,'utf8'),'sha256'),'hex'),
      at_time,least(at_time+runtime.claim_lifetime,midnight)) returning * into claim;
  return jsonb_build_object('id',claim.id,'token',token_value,
    'currency',claim.currency,'expiresAt',claim.expires_at);
end $$;

create function public.get_my_rewarded_ad_claim(p_claim_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare keeper uuid:=auth.uid(); claim private.rewarded_ad_claims%rowtype;
begin
  if keeper is null or p_claim_id is null then raise exception 'rewarded_ad_login_required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(keeper::text,0));
  update private.rewarded_ad_claims set status='expired'
    where id=p_claim_id and owner_id=keeper and status='issued'
      and expires_at<=clock_timestamp();
  select * into claim from private.rewarded_ad_claims
    where id=p_claim_id and owner_id=keeper;
  if not found then raise exception 'rewarded_ad_claim_unavailable'; end if;
  return jsonb_build_object('status',claim.status);
end $$;

create function public.cancel_my_rewarded_ad_claim(p_claim_id uuid)
returns boolean language plpgsql security definer set search_path='' as $$
declare keeper uuid:=auth.uid(); changed integer;
begin
  if keeper is null or p_claim_id is null then return false; end if;
  perform pg_advisory_xact_lock(hashtextextended(keeper::text,0));
  update private.rewarded_ad_claims set status='cancelled'
    where id=p_claim_id and owner_id=keeper and status='issued';
  get diagnostics changed=row_count;
  return changed=1;
end $$;

-- Called only by the signature-verifying Edge Function with service_role.
-- The Edge Function maps Google's signed numeric ad_unit suffix to the
-- configured canonical full ca-app-pub identifier before calling this RPC.
create function public.record_rewarded_ad_verification(
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
      p_transaction_id is null or p_transaction_id !~ '^[A-Za-z0-9._~-]{1,256}$' or
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
  -- Every verifier takes the transaction fence first. Other claim paths only
  -- take owner then row locks, so a conflicting replay cannot form a cycle.
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
  -- A status read may have expired the display claim already. Authentic
  -- signed evidence remains redeemable only inside the bounded grace below.
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

alter table private.canonical_game_intents add column rewarded_ad_context jsonb
  check (rewarded_ad_context is null or (jsonb_typeof(rewarded_ad_context)='object'
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
    and rewarded_ad_context->>'transactionId'~'^[A-Za-z0-9._~-]{1,256}$'
    and jsonb_typeof(rewarded_ad_context->'fingerprint')='string'
    and rewarded_ad_context->>'fingerprint'~'^[0-9a-f]{64}$'
    and private.game_json_sha256(rewarded_ad_context-'fingerprint')=
      rewarded_ad_context->>'fingerprint'));

-- Command recovery and reward commit both hold the owner's advisory lock.
-- Recovery may fail an uncertain intent, but deliberately leaves a verified
-- claim open so a later request can redeem it; a successful commit changes the
-- wallet and claim status in the same transaction below.
create function private.canonical_rewarded_ad_context(
  p_owner uuid,p_payload jsonb,p_at timestamptz
) returns jsonb language plpgsql security definer set search_path='' as $$
declare claim private.rewarded_ad_claims%rowtype; amount integer; context_value jsonb;
begin
  perform private.assert_game_service();
  if p_owner is null or p_at is null or
      jsonb_typeof(p_payload) is distinct from 'object' or
      p_payload is distinct from jsonb_build_object('claimId',p_payload->>'claimId') or
      nullif(p_payload->>'claimId','') is null or
      p_payload->>'claimId' !~
        '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' or
      not private.rewarded_ad_account_ready(p_owner) then
    raise exception 'rewarded_ad_claim_unavailable'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner::text,0));
  select * into claim from private.rewarded_ad_claims
    where id=(p_payload->>'claimId')::uuid and owner_id=p_owner for update;
  if not found or claim.status<>'verified' or claim.transaction_id is null or
      claim.verified_at is null or claim.verified_at>p_at then
    raise exception 'rewarded_ad_claim_unavailable'; end if;
  select case when claim.currency='gems' then gems_reward else coins_reward end
    into strict amount from private.rewarded_ad_runtime where singleton;
  context_value:=jsonb_build_object('version',1,'ownerId',p_owner,
    'action','claim_rewarded_ad','claimId',claim.id,'currency',claim.currency,
    'amount',amount,'transactionId',claim.transaction_id);
  return context_value||jsonb_build_object('fingerprint',private.game_json_sha256(context_value));
exception when invalid_text_representation then
  raise exception 'rewarded_ad_claim_unavailable';
end $$;

alter function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint)
  rename to begin_revisioned_game_command_v93;
create function public.begin_revisioned_game_command(
  p_owner_id uuid,p_request_id uuid,p_action text,p_payload jsonb,
  p_client_build integer,p_ruleset_sha256 text,p_expected_revision bigint
) returns jsonb language plpgsql security definer set search_path='' as $$
declare leased jsonb; context_value jsonb;
begin
  perform private.assert_game_service();
  leased:=public.begin_revisioned_game_command_v93(p_owner_id,p_request_id,p_action,
    p_payload,p_client_build,p_ruleset_sha256,p_expected_revision);
  if p_action<>'claim_rewarded_ad' or leased->>'status'<>'processing' then return leased; end if;
  select rewarded_ad_context into context_value from private.canonical_game_intents
    where owner_id=p_owner_id and request_id=p_request_id;
  if context_value is null then
    begin
      context_value:=private.canonical_rewarded_ad_context(
        p_owner_id,p_payload,(leased->>'now')::timestamptz);
    exception when raise_exception then
      if sqlerrm<>'rewarded_ad_claim_unavailable' then raise; end if;
      if not public.fail_canonical_game_command(p_owner_id,p_request_id,
          (leased->>'lease_token')::uuid,'rewarded_ad_claim_unavailable') then
        raise exception 'game_lease_lost'; end if;
      return jsonb_build_object('status','failed','failure_code','rewarded_ad_claim_unavailable',
        'response',null,'replayed',false);
    end;
    update private.canonical_game_intents set rewarded_ad_context=context_value
      where owner_id=p_owner_id and request_id=p_request_id;
  end if;
  return leased||jsonb_build_object('rewarded_ad_context',context_value);
end $$;

alter function public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb)
  rename to commit_canonical_game_command_v93;
create function public.commit_canonical_game_command(
  p_owner_id uuid,p_request_id uuid,p_lease_token uuid,p_state jsonb,p_result jsonb
) returns jsonb language plpgsql security definer set search_path='' as $$
declare intent private.canonical_game_intents%rowtype; current_context jsonb;
  game private.canonical_game_states%rowtype; claim_id uuid; currency_name text;
  amount integer; receipt jsonb; changed integer; presentation_matches integer;
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_request_id is null or p_lease_token is null then
    raise exception 'game_request_invalid'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0));
  select * into intent from private.canonical_game_intents
    where owner_id=p_owner_id and request_id=p_request_id for update;
  if not found or intent.lease_token<>p_lease_token then raise exception 'game_lease_lost'; end if;
  if intent.status<>'processing' or intent.action<>'claim_rewarded_ad' then
    return public.commit_canonical_game_command_v93(
      p_owner_id,p_request_id,p_lease_token,p_state,p_result); end if;
  if intent.leased_until<=clock_timestamp() then raise exception 'game_lease_lost'; end if;
  begin
    current_context:=private.canonical_rewarded_ad_context(
      p_owner_id,intent.payload,clock_timestamp());
  exception when raise_exception then
    if sqlerrm='rewarded_ad_claim_unavailable' then
      raise exception 'rewarded_ad_state_changed'; end if;
    raise;
  end;
  if current_context is distinct from intent.rewarded_ad_context then
    raise exception 'rewarded_ad_state_changed'; end if;
  claim_id:=(current_context->>'claimId')::uuid;
  currency_name:=current_context->>'currency'; amount:=(current_context->>'amount')::integer;
  select * into strict game from private.canonical_game_states
    where owner_id=p_owner_id for update;
  if currency_name not in ('gems','coins') or
      amount is distinct from (case when currency_name='gems' then 15 else 150 end) or
      jsonb_typeof(p_state->'pet'->currency_name) is distinct from 'number' or
      jsonb_typeof(game.state->'pet'->currency_name) is distinct from 'number' or
      jsonb_typeof(p_state->'pet'->(case when currency_name='gems' then 'coins' else 'gems' end))
        is distinct from 'number' or
      jsonb_typeof(game.state->'pet'->(case when currency_name='gems' then 'coins' else 'gems' end))
        is distinct from 'number' then
    raise exception 'rewarded_ad_state_changed'; end if;
  if (p_state->'pet'->>currency_name) !~ '^[0-9]{1,15}$' or
      (game.state->'pet'->>currency_name) !~ '^[0-9]{1,15}$' or
      (p_state->'pet'->>(case when currency_name='gems' then 'coins' else 'gems' end))
        !~ '^[0-9]{1,15}$' or
      (game.state->'pet'->>(case when currency_name='gems' then 'coins' else 'gems' end))
        !~ '^[0-9]{1,15}$' then raise exception 'rewarded_ad_state_changed'; end if;
  if (p_state->'pet'->>currency_name)::bigint<>
        (game.state->'pet'->>currency_name)::bigint+amount or
      (p_state->'pet'->>(case when currency_name='gems' then 'coins' else 'gems' end))::bigint<>
        (game.state->'pet'->>(case when currency_name='gems' then 'coins' else 'gems' end))::bigint or
      p_result is distinct from jsonb_build_object('accepted',true,'claimId',claim_id,
        'currency',currency_name,'amount',amount) or
      jsonb_typeof(game.state->'pendingPresentations') is distinct from 'array' or
      jsonb_typeof(p_state->'pendingPresentations') is distinct from 'array' then
    raise exception 'rewarded_ad_state_changed'; end if;
  if jsonb_array_length(p_state->'pendingPresentations')<>
        jsonb_array_length(game.state->'pendingPresentations')+1 or
      (p_state->'pendingPresentations'-
        (jsonb_array_length(p_state->'pendingPresentations')-1)) is distinct from
          game.state->'pendingPresentations' or
      exists(select 1 from jsonb_array_elements(game.state->'pendingPresentations') p
        where p->>'id'='rewarded-ad-'||claim_id::text) then
    raise exception 'rewarded_ad_state_changed'; end if;
  select count(*)::integer into presentation_matches
    from jsonb_array_elements(p_state->'pendingPresentations') p
    where p->>'id'='rewarded-ad-'||claim_id::text and p->>'type'='rewardedCurrency'
      and p->'payload'=jsonb_build_object('currency',currency_name,'amount',amount,
        'claimId',claim_id::text);
  if presentation_matches<>1 then raise exception 'rewarded_ad_state_changed'; end if;
  receipt:=public.commit_canonical_game_command_v93(
    p_owner_id,p_request_id,p_lease_token,p_state,p_result);
  update private.rewarded_ad_claims set status='claimed',claimed_at=clock_timestamp(),
    canonical_request_id=p_request_id,canonical_revision=(receipt->>'server_revision')::bigint
    where id=claim_id and owner_id=p_owner_id and status='verified';
  get diagnostics changed=row_count;
  if changed<>1 then raise exception 'rewarded_ad_state_changed'; end if;
  return receipt;
end $$;

revoke all on function private.rewarded_ad_account_ready(uuid),
  private.canonical_rewarded_ad_context(uuid,jsonb,timestamptz),
  public.begin_revisioned_game_command_v93(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command_v93(uuid,uuid,uuid,jsonb,jsonb)
  from public,anon,authenticated,service_role;
revoke all on function public.get_my_rewarded_ad_status(),
  public.issue_my_rewarded_ad_claim(text),public.get_my_rewarded_ad_claim(uuid),
  public.cancel_my_rewarded_ad_claim(uuid) from public,anon;
grant execute on function public.get_my_rewarded_ad_status(),
  public.issue_my_rewarded_ad_claim(text),public.get_my_rewarded_ad_claim(uuid),
  public.cancel_my_rewarded_ad_claim(uuid) to authenticated;
revoke all on function public.record_rewarded_ad_verification(text,text,text,text,integer,text,text,bigint,bigint,text),
  public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb)
  from public,anon,authenticated;
grant execute on function public.record_rewarded_ad_verification(text,text,text,text,integer,text,text,bigint,bigint,text),
  public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb) to service_role;
