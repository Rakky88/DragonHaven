-- Dormant until the existing migration switch is explicitly enabled. Existing
-- saves/authority are untouched; incompatible apps cannot begin the cutover.
create function public.get_my_server_gameplay_status(p_client_build integer, p_gameplay_protocol integer)
returns jsonb language plpgsql security definer set search_path='' as $$
begin
  if auth.uid() is null or not exists(select 1 from auth.users
      where id=auth.uid() and email_confirmed_at is not null) then
    raise exception 'online_login_required';
  end if;
  if p_gameplay_protocol is distinct from 1 or p_client_build is null or
      p_client_build < (select minimum_client_build from private.game_engine_runtime where singleton) then
    raise exception 'game_client_upgrade_required';
  end if;
  return public.get_my_canonical_account_status();
end $$;
revoke all on function public.get_my_server_gameplay_status(integer,integer) from public,anon;
grant execute on function public.get_my_server_gameplay_status(integer,integer) to authenticated;

-- Version 41 and older use this endpoint. They retain legacy play until their
-- account is migrated, after which they must upgrade rather than open a test UI.
create or replace function public.get_my_online_session_status()
returns jsonb language plpgsql security definer set search_path='' as $$
declare status jsonb;
begin
  if auth.uid() is null or not exists(select 1 from auth.users
      where id=auth.uid() and email_confirmed_at is not null) then
    raise exception 'online_login_required';
  end if;
  status := public.get_my_canonical_account_status();
  if status->>'phase' in ('active','captured') then raise exception 'game_client_upgrade_required'; end if;
  return status || jsonb_build_object('migration_enabled',false);
end $$;

create table private.server_account_initializations (
  owner_id uuid primary key references public.profiles(user_id) on delete cascade,
  secret_seed bytea not null default extensions.gen_random_bytes(32) check(octet_length(secret_seed)=32),
  captured_at timestamptz not null default clock_timestamp(),
  ruleset_sha256 text not null check(ruleset_sha256 ~ '^[0-9a-f]{64}$'),
  source_revision bigint check(source_revision>0),
  source_sha256 text check(source_sha256 ~ '^[0-9a-f]{64}$'),
  check((source_revision is null)=(source_sha256 is null))
);
alter table private.server_account_initializations enable row level security;
revoke all on private.server_account_initializations from public,anon,authenticated,service_role;

create function private.assert_unplayed_account(p_owner uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  if not exists(select 1 from public.profiles where user_id=p_owner and inventory_imported_at is null)
    or exists(select 1 from public.cloud_game_saves where user_id=p_owner)
    or exists(select 1 from public.cloud_game_save_history where user_id=p_owner)
    or exists(select 1 from private.canonical_game_states where owner_id=p_owner)
    or exists(select 1 from public.player_dragons where owner_id=p_owner)
    or exists(select 1 from public.player_eggs where owner_id=p_owner)
    or exists(select 1 from public.player_chests where owner_id=p_owner)
    or exists(select 1 from public.player_relics where owner_id=p_owner)
    or exists(select 1 from private.egg_altar_accounts where owner_id=p_owner)
    or exists(select 1 from public.economy_ledger_entries where owner_id=p_owner)
    or exists(select 1 from public.player_wallets where user_id=p_owner and (coins<>25 or gems<>3 or revision<>1))
  then raise exception 'game_existing_progress_requires_migration'; end if;
end $$;
revoke all on function private.assert_unplayed_account(uuid) from public,anon,authenticated,service_role;

create function public.begin_server_account_initialization(p_owner_id uuid,p_client_build integer,p_ruleset_sha256 text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare runtime private.game_engine_runtime%rowtype; initialization private.server_account_initializations%rowtype;
begin
  perform private.assert_game_service();
  if p_owner_id is null then raise exception 'game_request_invalid'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0));
  select * into strict runtime from private.game_engine_runtime where singleton for share;
  if not runtime.migration_enabled then raise exception 'game_migration_disabled'; end if;
  if p_client_build is null or p_client_build<runtime.minimum_client_build then raise exception 'game_client_upgrade_required'; end if;
  if p_ruleset_sha256 is distinct from runtime.ruleset_sha256 then raise exception 'game_ruleset_mismatch'; end if;
  if not exists(select 1 from auth.users where id=p_owner_id and email_confirmed_at is not null)
    or not exists(select 1 from private.account_privacy_acknowledgements
      where user_id=p_owner_id and notice_version='2026-09-20' and minimum_age_confirmed=16)
  then raise exception 'privacy_confirmation_required'; end if;
  select * into initialization from private.server_account_initializations where owner_id=p_owner_id for update;
  if initialization.source_revision is not null then
    return jsonb_build_object('owner_id',p_owner_id,'source_revision',initialization.source_revision);
  end if;
  perform private.assert_unplayed_account(p_owner_id);
  if initialization.owner_id is null then
    insert into private.server_account_initializations(owner_id,ruleset_sha256)
      values(p_owner_id,p_ruleset_sha256) returning * into initialization;
  elsif initialization.ruleset_sha256<>p_ruleset_sha256 then
    -- Keep entropy/time fixed across worker upgrades; an account cannot reroll.
    update private.server_account_initializations set ruleset_sha256=p_ruleset_sha256
      where owner_id=p_owner_id returning * into initialization;
  end if;
  return jsonb_build_object('owner_id',p_owner_id,'source_revision',null,
    'secret_seed',encode(initialization.secret_seed,'hex'),'now',initialization.captured_at);
end $$;

create function public.commit_server_account_initialization(p_owner_id uuid,p_ruleset_sha256 text,p_state jsonb)
returns bigint language plpgsql security definer set search_path='' as $$
declare initialization private.server_account_initializations%rowtype;
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_state is null or jsonb_typeof(p_state)<>'object'
    or octet_length(p_state::text)>8388608 or p_state->>'onboardingComplete' is distinct from 'false'
  then raise exception 'game_request_invalid'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0));
  if not exists(select 1 from private.game_engine_runtime where singleton and migration_enabled
      and ruleset_sha256=p_ruleset_sha256) then raise exception 'game_migration_disabled'; end if;
  select * into initialization from private.server_account_initializations where owner_id=p_owner_id for update;
  if not found or initialization.ruleset_sha256<>p_ruleset_sha256 then raise exception 'game_ruleset_mismatch'; end if;
  if initialization.source_revision is not null then
    if initialization.source_sha256<>private.game_json_sha256(p_state) then raise exception 'game_idempotency_conflict'; end if;
    return initialization.source_revision;
  end if;
  perform private.assert_unplayed_account(p_owner_id);
  insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
    values(p_owner_id,1,p_state,'server-initialization','server',coalesce((p_state->>'schemaVersion')::integer,1));
  update private.server_account_initializations set source_revision=1,source_sha256=private.game_json_sha256(p_state)
    where owner_id=p_owner_id;
  return 1;
end $$;
revoke all on function public.begin_server_account_initialization(uuid,integer,text),
  public.commit_server_account_initialization(uuid,text,jsonb) from public,anon,authenticated;
grant execute on function public.begin_server_account_initialization(uuid,integer,text),
  public.commit_server_account_initialization(uuid,text,jsonb) to service_role;
