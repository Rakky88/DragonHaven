-- A legacy save is captured and prepared privately. Promotion rechecks every
-- source under the same owner lock as legacy writers; a changed source retries
-- without changing the player's authority or blocking their old game.
alter table private.game_engine_runtime add column migration_enabled boolean not null default false;
alter table private.canonical_game_states drop constraint canonical_game_states_authority_mode_check;
alter table private.canonical_game_states add constraint canonical_game_states_authority_mode_check
  check (authority_mode in ('shadow','server'));

create table private.canonical_account_migrations (
  owner_id uuid primary key references public.profiles(user_id) on delete cascade,
  request_id uuid not null,
  import_id uuid not null references private.canonical_game_imports(import_id),
  source_revision bigint not null,
  external_sha256 text not null check (external_sha256 ~ '^[0-9a-f]{64}$'),
  ruleset_sha256 text not null check (ruleset_sha256 ~ '^[0-9a-f]{64}$'),
  captured_at timestamptz not null default clock_timestamp(),
  activated_at timestamptz,
  activated_revision bigint,
  check ((activated_at is null) = (activated_revision is null))
);
alter table private.canonical_account_migrations enable row level security;
revoke all on private.canonical_account_migrations from public,anon,authenticated,service_role;

create function private.canonical_migration_external_hash(p_owner uuid)
returns text language sql stable security definer set search_path='' as $$
  select private.game_json_sha256(jsonb_build_object(
    'wallet',(select to_jsonb(x) from public.player_wallets x where user_id=p_owner),
    'dragons',(select coalesce(jsonb_agg(to_jsonb(x) order by id),'[]') from public.player_dragons x where owner_id=p_owner),
    'eggs',(select coalesce(jsonb_agg(to_jsonb(x) order by id),'[]') from public.player_eggs x where owner_id=p_owner),
    'chests',(select coalesce(jsonb_agg(to_jsonb(x) order by id),'[]') from public.player_chests x where owner_id=p_owner),
    'relics',(select coalesce(jsonb_agg(to_jsonb(x) order by id),'[]') from public.player_relics x where owner_id=p_owner),
    'trades',(select coalesce(jsonb_agg(to_jsonb(x) order by id),'[]') from public.trades x
      where p_owner in (initiator_id,recipient_id)),
    'groupParticipants',(select coalesce(jsonb_agg(to_jsonb(x) order by lobby_id),'[]')
      from public.group_adventure_participants x where user_id=p_owner),
    'pairs',(select coalesce(jsonb_agg(to_jsonb(x) order by id),'[]') from public.seasonal_pair_adventures x
      where p_owner in (creator_id,partner_id)),
    'prizes',(select coalesce(jsonb_agg(to_jsonb(x) order by id),'[]') from public.seasonal_event_prizes x where user_id=p_owner)
  ))
$$;
revoke all on function private.canonical_migration_external_hash(uuid) from public,anon,authenticated,service_role;

create function private.assert_canonical_migration_settled(p_owner uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  if exists(select 1 from public.trades where not canonical_owned and p_owner in(initiator_id,recipient_id)
    and ((status in('awaiting_recipient','awaiting_initiator') and expires_at>clock_timestamp()) or
      (status='completed' and case when initiator_id=p_owner then initiator_acknowledged_at is null
        else recipient_acknowledged_at is null end))) then raise exception 'game_migration_trade_pending'; end if;
end $$;
revoke all on function private.assert_canonical_migration_settled(uuid) from public,anon,authenticated,service_role;

create function public.begin_canonical_account_migration(p_owner_id uuid,p_request_id uuid,
  p_source_revision bigint,p_client_build integer,p_ruleset_sha256 text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare runtime private.game_engine_runtime%rowtype; source public.cloud_game_saves%rowtype;
  migration private.canonical_account_migrations%rowtype; copied jsonb; external_hash text;
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_request_id is null or p_source_revision is null or p_source_revision<1
    or p_client_build is null or p_ruleset_sha256 is null then raise exception 'game_request_invalid'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0));
  select * into strict runtime from private.game_engine_runtime where singleton for share;
  if p_client_build<runtime.minimum_client_build then raise exception 'game_client_upgrade_required'; end if;
  if p_ruleset_sha256 is distinct from runtime.ruleset_sha256 then raise exception 'game_ruleset_mismatch'; end if;
  select * into migration from private.canonical_account_migrations where owner_id=p_owner_id for update;
  if found and migration.activated_at is not null then
    return jsonb_build_object('owner_id',p_owner_id,'phase','active','server_revision',migration.activated_revision);
  end if;
  if not runtime.migration_enabled then raise exception 'game_migration_disabled'; end if;
  if exists(select 1 from public.player_economy_authority where user_id=p_owner_id and authority_mode='server') then
    raise exception 'game_migration_authority_conflict'; end if;
  perform private.assert_canonical_migration_settled(p_owner_id);
  select * into source from public.cloud_game_saves where user_id=p_owner_id for update;
  if not found or source.revision<>p_source_revision then raise exception 'game_import_source_changed'; end if;
  external_hash:=private.canonical_migration_external_hash(p_owner_id);
  if migration.owner_id is not null and migration.request_id=p_request_id and
    (migration.source_revision<>p_source_revision or migration.ruleset_sha256<>p_ruleset_sha256 or
      migration.external_sha256<>external_hash) then raise exception 'game_idempotency_conflict'; end if;
  copied:=public.stage_canonical_game_copy(p_owner_id,p_source_revision,private.game_json_sha256(source.state));
  insert into private.canonical_account_migrations(owner_id,request_id,import_id,source_revision,external_sha256,ruleset_sha256)
    values(p_owner_id,p_request_id,(copied->>'import_id')::uuid,p_source_revision,external_hash,p_ruleset_sha256)
    on conflict(owner_id) do update set request_id=excluded.request_id,import_id=excluded.import_id,
      source_revision=excluded.source_revision,external_sha256=excluded.external_sha256,
      ruleset_sha256=excluded.ruleset_sha256,captured_at=clock_timestamp();
  return jsonb_build_object('owner_id',p_owner_id,'phase','captured','import_id',copied->'import_id');
end $$;

create function public.activate_canonical_account(p_owner_id uuid,p_request_id uuid,p_import_id uuid,
  p_prepared_revision bigint,p_ruleset_sha256 text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare migration private.canonical_account_migrations%rowtype; game private.canonical_game_states%rowtype;
  imported private.canonical_game_imports%rowtype; prepared private.canonical_game_preparations%rowtype;
  source public.cloud_game_saves%rowtype; at_time timestamptz:=clock_timestamp();
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_request_id is null or p_import_id is null or p_prepared_revision is null
    or p_prepared_revision<1 or p_ruleset_sha256 is null then raise exception 'game_request_invalid'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0));
  select * into migration from private.canonical_account_migrations where owner_id=p_owner_id for update;
  if not found or migration.request_id<>p_request_id or migration.import_id<>p_import_id or
    migration.ruleset_sha256<>p_ruleset_sha256 then raise exception 'game_migration_capture_changed'; end if;
  select * into game from private.canonical_game_states where owner_id=p_owner_id for update;
  if migration.activated_at is not null then
    if game.authority_mode<>'server' then raise exception 'game_migration_authority_conflict'; end if;
    return jsonb_build_object('owner_id',p_owner_id,'phase','active',
      'server_revision',migration.activated_revision,'replayed',true);
  end if;
  if not exists(select 1 from private.game_engine_runtime where singleton and migration_enabled
    and ruleset_sha256=p_ruleset_sha256) then raise exception 'game_migration_disabled'; end if;
  select * into prepared from private.canonical_game_preparations where import_id=p_import_id and owner_id=p_owner_id;
  if not found or prepared.ruleset_sha256<>p_ruleset_sha256 or prepared.prepared_revision<>p_prepared_revision
    or game.source_import_id<>p_import_id or game.authority_mode<>'shadow' or not game.is_prepared
    or game.revision<>p_prepared_revision or game.state_sha256<>prepared.prepared_state_sha256 then
    raise exception 'game_migration_preparation_changed'; end if;
  if exists(select 1 from private.canonical_game_intents where owner_id=p_owner_id and status='processing') then
    raise exception 'game_pending_command_required'; end if;
  select * into imported from private.canonical_game_imports where import_id=p_import_id;
  select * into source from public.cloud_game_saves where user_id=p_owner_id for update;
  if not found or source.revision<>imported.source_revision or
    private.game_json_sha256(source.state)<>imported.source_sha256 then raise exception 'game_import_source_changed'; end if;
  if private.game_json_sha256(coalesce(private.egg_altar_state(p_owner_id),'null'::jsonb))<>imported.altar_sha256 then
    raise exception 'game_import_altar_changed'; end if;
  perform private.assert_canonical_migration_settled(p_owner_id);
  if private.canonical_migration_external_hash(p_owner_id)<>migration.external_sha256 then
    raise exception 'game_migration_social_changed'; end if;
  perform 1 from public.player_economy_authority where user_id=p_owner_id for update;
  if exists(select 1 from public.player_economy_authority where user_id=p_owner_id and authority_mode='server') then
    raise exception 'game_migration_authority_conflict'; end if;
  update public.player_economy_authority set authority_mode='server',protocol_version=2,
    activated_at=at_time,updated_at=at_time,server_revision=game.revision+1 where user_id=p_owner_id;
  update private.canonical_game_states set authority_mode='server',revision=revision+1,updated_at=at_time
    where owner_id=p_owner_id returning * into game;
  update private.canonical_account_migrations set activated_at=at_time,activated_revision=game.revision where owner_id=p_owner_id;
  return jsonb_build_object('owner_id',p_owner_id,'phase','active','server_revision',game.revision,'replayed',false);
end $$;

create function public.get_my_canonical_account_status()
returns jsonb language plpgsql security definer set search_path='' as $$
declare keeper uuid:=auth.uid(); migration private.canonical_account_migrations%rowtype; authority text;
begin
  if keeper is null then raise exception 'game_login_required'; end if;
  select authority_mode into authority from public.player_economy_authority where user_id=keeper;
  select * into migration from private.canonical_account_migrations where owner_id=keeper;
  return jsonb_build_object('owner_id',keeper,'phase',case when migration.activated_at is not null and authority='server'
    then 'active' when migration.owner_id is not null then 'captured' else 'legacy' end,
    'source_revision',migration.source_revision,'server_revision',migration.activated_revision,
    'migration_enabled',(select migration_enabled from private.game_engine_runtime where singleton));
end $$;
revoke all on function public.begin_canonical_account_migration(uuid,uuid,bigint,integer,text),
  public.activate_canonical_account(uuid,uuid,uuid,bigint,text) from public,anon,authenticated;
grant execute on function public.begin_canonical_account_migration(uuid,uuid,bigint,integer,text),
  public.activate_canonical_account(uuid,uuid,uuid,bigint,text) to service_role;
revoke all on function public.get_my_canonical_account_status() from public,anon;
grant execute on function public.get_my_canonical_account_status() to authenticated;

-- A prepared migration is never a playable shadow. Promotion is irreversible
-- through this API; failures leave the old game writable and its save intact.
create function private.assert_canonical_account_ready(p_owner uuid)
returns void language plpgsql security definer set search_path='' as $$
declare mode text;
begin
  perform private.assert_game_service();
  perform pg_advisory_xact_lock(hashtextextended(p_owner::text,0));
  select authority_mode into mode from private.canonical_game_states where owner_id=p_owner;
  if mode='shadow' and exists(select 1 from private.canonical_account_migrations where owner_id=p_owner) then
    raise exception 'game_migration_in_progress'; end if;
  if mode='server' and not exists(select 1 from public.player_economy_authority a
    join private.canonical_account_migrations m on m.owner_id=a.user_id
    where a.user_id=p_owner and a.authority_mode='server' and m.activated_at is not null) then
    raise exception 'game_migration_authority_conflict'; end if;
end $$;
revoke all on function private.assert_canonical_account_ready(uuid) from public,anon,authenticated,service_role;

alter function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint) rename to begin_revisioned_game_command_v78;
create function public.begin_revisioned_game_command(p_owner_id uuid,p_request_id uuid,p_action text,p_payload jsonb,
  p_client_build integer,p_ruleset_sha256 text,p_expected_revision bigint)
returns jsonb language plpgsql security definer set search_path='' as $$
begin
  perform private.lock_canonical_trade_keepers(p_owner_id,p_action,p_payload);
  perform private.assert_canonical_account_ready(p_owner_id);
  return public.begin_revisioned_game_command_v78(p_owner_id,p_request_id,p_action,p_payload,p_client_build,p_ruleset_sha256,p_expected_revision);
end $$;
alter function public.read_canonical_game_state(uuid,integer,text) rename to read_canonical_game_state_v78;
create function public.read_canonical_game_state(p_owner_id uuid,p_client_build integer,p_ruleset_sha256 text)
returns jsonb language plpgsql security definer set search_path='' as $$
begin
  perform private.assert_canonical_account_ready(p_owner_id);
  return public.read_canonical_game_state_v78(p_owner_id,p_client_build,p_ruleset_sha256);
end $$;
alter function public.recover_canonical_game_commands(uuid,uuid,integer,text) rename to recover_canonical_game_commands_v78;
create function public.recover_canonical_game_commands(p_owner_id uuid,p_request_id uuid,p_client_build integer,p_ruleset_sha256 text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb; mode text;
begin
  perform private.assert_canonical_account_ready(p_owner_id);
  result:=public.recover_canonical_game_commands_v78(p_owner_id,p_request_id,p_client_build,p_ruleset_sha256);
  select authority_mode into mode from private.canonical_game_states where owner_id=p_owner_id;
  return result||jsonb_build_object('authority_mode',mode);
end $$;
revoke all on function public.begin_revisioned_game_command_v78(uuid,uuid,text,jsonb,integer,text,bigint),
  public.read_canonical_game_state_v78(uuid,integer,text),public.recover_canonical_game_commands_v78(uuid,uuid,integer,text)
  from public,anon,authenticated,service_role;
revoke all on function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.read_canonical_game_state(uuid,integer,text),public.recover_canonical_game_commands(uuid,uuid,integer,text)
  from public,anon,authenticated;
grant execute on function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.read_canonical_game_state(uuid,integer,text),public.recover_canonical_game_commands(uuid,uuid,integer,text) to service_role;

-- Canonical JSON becomes the only economy store. Old normalized inventory,
-- Altar ledgers and cloud snapshots remain historical copies and cannot write
-- through authenticated old clients after activation. Social projections still
-- update atomically as service_role. Account deletion cascades remain allowed.
create trigger canonical_cloud_save_write before insert or update or delete on public.cloud_game_saves
  for each row execute function private.guard_canonical_social_write();
create trigger canonical_altar_account_write before insert or update or delete on private.egg_altar_accounts
  for each row execute function private.guard_canonical_social_write();
create trigger canonical_altar_egg_write before insert or update or delete on private.egg_altar_eggs
  for each row execute function private.guard_canonical_social_write();
create trigger canonical_altar_dragon_write before insert or update or delete on private.egg_altar_dragons
  for each row execute function private.guard_canonical_social_write();
create trigger canonical_altar_operation_write before insert or update or delete on private.egg_altar_operations
  for each row execute function private.guard_canonical_social_write();
