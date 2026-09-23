-- Rewarded ads add an optional Google Mobile Ads/UMP processing purpose.
-- Keep the released 2026-09-20 client usable during rollout while the new
-- client asks for the exact 2026-09-23 notice through a versioned endpoint.
create or replace function public.get_my_privacy_acknowledgement()
returns boolean language plpgsql security definer set search_path='' as $$
declare keeper uuid := auth.uid();
begin
  if keeper is null or not exists(select 1 from auth.users
      where id=keeper and email_confirmed_at is not null) then
    raise exception 'online_login_required';
  end if;
  return exists(select 1 from private.account_privacy_acknowledgements
    where user_id=keeper and notice_version in ('2026-09-20','2026-09-23')
      and minimum_age_confirmed=16);
end $$;

create or replace function public.get_my_privacy_acknowledgement_for_version(
  p_version text
) returns boolean language plpgsql security definer set search_path='' as $$
declare keeper uuid := auth.uid();
begin
  if keeper is null or not exists(select 1 from auth.users
      where id=keeper and email_confirmed_at is not null) then
    raise exception 'online_login_required';
  end if;
  if p_version is distinct from '2026-09-23' then
    raise exception 'privacy_confirmation_required';
  end if;
  return exists(select 1 from private.account_privacy_acknowledgements
    where user_id=keeper and notice_version=p_version
      and minimum_age_confirmed=16);
end $$;

create or replace function public.acknowledge_my_privacy_notice(
  p_version text,p_age_16_confirmed boolean
) returns boolean language plpgsql security definer set search_path='' as $$
declare keeper uuid := auth.uid();
begin
  if keeper is null or not exists(select 1 from auth.users
      where id=keeper and email_confirmed_at is not null) then
    raise exception 'online_login_required';
  end if;
  if (p_version is distinct from '2026-09-20' and
      p_version is distinct from '2026-09-23') or
      p_age_16_confirmed is distinct from true then
    raise exception 'privacy_confirmation_required';
  end if;
  insert into private.account_privacy_acknowledgements(
      user_id,notice_version,minimum_age_confirmed)
    values(keeper,p_version,16)
    on conflict(user_id) do update set notice_version=excluded.notice_version,
      minimum_age_confirmed=16,acknowledged_at=now()
      where account_privacy_acknowledgements.notice_version<>excluded.notice_version
        and not (account_privacy_acknowledgements.notice_version='2026-09-23'
          and excluded.notice_version='2026-09-20');
  return true;
end $$;

revoke all on function public.get_my_privacy_acknowledgement_for_version(text)
  from public,anon;
grant execute on function public.get_my_privacy_acknowledgement_for_version(text)
  to authenticated;

-- Reward issuance is optional processing covered by this notice. Existing
-- prepared accounts must acknowledge the current version too; account setup
-- alone is not sufficient readiness for an ad claim. This exact check is the
-- feature boundary that keeps ads unavailable to legacy acknowledgements.
create or replace function private.rewarded_ad_account_ready(p_owner uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from private.canonical_game_states g
      where g.owner_id=p_owner and g.is_prepared and g.authority_mode='server')
    and exists(select 1 from private.account_privacy_acknowledgements a
      where a.user_id=p_owner and a.notice_version='2026-09-23'
        and a.minimum_age_confirmed=16)
$$;

create or replace function public.begin_server_account_initialization(
  p_owner_id uuid,p_client_build integer,p_ruleset_sha256 text
) returns jsonb language plpgsql security definer set search_path='' as $$
declare runtime private.game_engine_runtime%rowtype;
  initialization private.server_account_initializations%rowtype;
begin
  perform private.assert_game_service();
  if p_owner_id is null then raise exception 'game_request_invalid'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0));
  select * into strict runtime from private.game_engine_runtime where singleton for share;
  if not runtime.migration_enabled then raise exception 'game_migration_disabled'; end if;
  if p_client_build is null or p_client_build<runtime.minimum_client_build then
    raise exception 'game_client_upgrade_required'; end if;
  if p_ruleset_sha256 is distinct from runtime.ruleset_sha256 then
    raise exception 'game_ruleset_mismatch'; end if;
  if not exists(select 1 from auth.users
      where id=p_owner_id and email_confirmed_at is not null)
    or not exists(select 1 from private.account_privacy_acknowledgements
      where user_id=p_owner_id
        and notice_version in ('2026-09-20','2026-09-23')
        and minimum_age_confirmed=16)
  then raise exception 'privacy_confirmation_required'; end if;
  select * into initialization from private.server_account_initializations
    where owner_id=p_owner_id for update;
  if initialization.source_revision is not null then
    return jsonb_build_object('owner_id',p_owner_id,
      'source_revision',initialization.source_revision);
  end if;
  perform private.assert_unplayed_account(p_owner_id);
  if initialization.owner_id is null then
    insert into private.server_account_initializations(owner_id,ruleset_sha256)
      values(p_owner_id,p_ruleset_sha256) returning * into initialization;
  elsif initialization.ruleset_sha256<>p_ruleset_sha256 then
    update private.server_account_initializations set ruleset_sha256=p_ruleset_sha256
      where owner_id=p_owner_id returning * into initialization;
  end if;
  return jsonb_build_object('owner_id',p_owner_id,'source_revision',null,
    'secret_seed',encode(initialization.secret_seed,'hex'),
    'now',initialization.captured_at);
end $$;

-- Repair the already dormant rewarded commit path before claims can be enabled.
-- Parenthesizing the selected JSON array prevents PostgreSQL from parsing the
-- text key as the integer right operand of the JSONB subtraction operator.
create or replace function public.commit_canonical_game_command(
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
      ((p_state->'pendingPresentations')-
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

-- migration 95 rewarded commit repair end
