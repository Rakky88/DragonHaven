-- Rewarded ads add an optional Google Mobile Ads/UMP processing purpose.
-- Require every account to acknowledge the matching, accurately dated notice
-- before online gameplay opens. This migration is deployed before the client
-- that carries the same version constant.
create or replace function public.get_my_privacy_acknowledgement()
returns boolean language plpgsql security definer set search_path='' as $$
declare keeper uuid := auth.uid();
begin
  if keeper is null or not exists(select 1 from auth.users
      where id=keeper and email_confirmed_at is not null) then
    raise exception 'online_login_required';
  end if;
  return exists(select 1 from private.account_privacy_acknowledgements
    where user_id=keeper and notice_version='2026-09-23' and minimum_age_confirmed=16);
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
  if p_version is distinct from '2026-09-23' or
      p_age_16_confirmed is distinct from true then
    raise exception 'privacy_confirmation_required';
  end if;
  insert into private.account_privacy_acknowledgements(
      user_id,notice_version,minimum_age_confirmed)
    values(keeper,p_version,16)
    on conflict(user_id) do update set notice_version=excluded.notice_version,
      minimum_age_confirmed=16,acknowledged_at=now()
      where account_privacy_acknowledgements.notice_version<>excluded.notice_version;
  return true;
end $$;

-- Reward issuance is optional processing covered by this notice. Existing
-- prepared accounts must acknowledge the current version too; account setup
-- alone is not sufficient readiness for an ad claim.
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
      where user_id=p_owner_id and notice_version='2026-09-23'
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
