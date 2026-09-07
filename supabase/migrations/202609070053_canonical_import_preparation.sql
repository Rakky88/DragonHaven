-- Versioned, immutable import generations and a fenced preparation receipt.
-- All records remain detached shadow copies; no live economy is activated.
alter table private.canonical_game_imports
  add column import_id uuid not null default gen_random_uuid(),
  add column altar_sha256 text generated always as
    (private.game_json_sha256(coalesce(altar_state, 'null'::jsonb))) stored,
  add column preparation_seed bytea not null default extensions.gen_random_bytes(32)
    check (octet_length(preparation_seed) = 32);

alter table private.canonical_game_states
  drop constraint canonical_game_states_owner_id_fkey,
  add column source_import_id uuid,
  add column is_prepared boolean not null default false;
update private.canonical_game_states g set source_import_id = i.import_id
  from private.canonical_game_imports i where i.owner_id = g.owner_id;
alter table private.canonical_game_imports
  drop constraint canonical_game_imports_pkey,
  add primary key (import_id),
  add unique (import_id, owner_id),
  add unique (owner_id, source_revision, source_sha256, altar_sha256);
alter table private.canonical_game_states
  alter column source_import_id set not null,
  add foreign key (owner_id) references public.profiles(user_id) on delete cascade,
  add foreign key (source_import_id, owner_id)
    references private.canonical_game_imports(import_id, owner_id) on delete cascade;

create table private.canonical_game_preparations (
  import_id uuid primary key,
  owner_id uuid not null,
  ruleset_sha256 text not null check (ruleset_sha256 ~ '^[0-9a-f]{64}$'),
  prepared_state_sha256 text not null check (prepared_state_sha256 ~ '^[0-9a-f]{64}$'),
  changed_asset_kinds text[] not null check (cardinality(changed_asset_kinds) <= 100),
  prepared_revision bigint not null check (prepared_revision > 0),
  prepared_at timestamptz not null default now(),
  foreign key (import_id, owner_id)
    references private.canonical_game_imports(import_id, owner_id) on delete cascade
);
alter table private.canonical_game_preparations enable row level security;
revoke all on private.canonical_game_preparations from public, anon, authenticated;
create trigger canonical_game_preparations_immutable
before update or delete on private.canonical_game_preparations
for each row execute function private.reject_economy_ledger_change();

create or replace function public.stage_canonical_game_copy(
  p_owner_id uuid, p_source_revision bigint, p_source_sha256 text
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_source public.cloud_game_saves%rowtype; v_import private.canonical_game_imports%rowtype;
  v_game private.canonical_game_states%rowtype; v_altar jsonb; v_altar_hash text; v_hash text;
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_source_revision is null or p_source_revision < 1
    or p_source_sha256 is null or p_source_sha256 !~ '^[0-9a-f]{64}$' then
    raise exception 'game_request_invalid';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text, 0));
  select * into v_game from private.canonical_game_states where owner_id = p_owner_id for update;
  if found and v_game.authority_mode <> 'shadow' then raise exception 'game_import_shadow_required'; end if;
  if exists(select 1 from private.canonical_game_intents where owner_id = p_owner_id and status = 'processing') then
    raise exception 'game_pending_command_required';
  end if;
  select * into v_source from public.cloud_game_saves where user_id = p_owner_id for update;
  if not found or v_source.revision <> p_source_revision then raise exception 'game_import_source_changed'; end if;
  v_hash := private.game_json_sha256(v_source.state);
  if v_hash <> p_source_sha256 then raise exception 'game_import_source_changed'; end if;
  perform private.validate_canonical_game_state(v_source.state);
  v_altar := private.egg_altar_state(p_owner_id);
  v_altar_hash := private.game_json_sha256(coalesce(v_altar, 'null'::jsonb));
  select * into v_import from private.canonical_game_imports where owner_id = p_owner_id
    and source_revision = p_source_revision and source_sha256 = v_hash and altar_sha256 = v_altar_hash;
  if found then
    if v_game.source_import_id is distinct from v_import.import_id then
      raise exception 'game_import_generation_already_used';
    end if;
    return jsonb_build_object('copied', false, 'import_id', v_import.import_id,
      'source_revision', v_import.source_revision, 'source_sha256', v_hash, 'authority_mode', 'shadow');
  end if;
  insert into private.canonical_game_imports(owner_id, source_revision, source_sha256, source_state, altar_state)
    values(p_owner_id, v_source.revision, v_hash, v_source.state, v_altar) returning * into v_import;
  insert into private.canonical_game_states(owner_id, source_import_id, state, state_sha256)
    values(p_owner_id, v_import.import_id, v_source.state, v_hash)
    on conflict (owner_id) do update set source_import_id = excluded.source_import_id,
      state = excluded.state, state_sha256 = excluded.state_sha256,
      revision = private.canonical_game_states.revision + 1, is_prepared = false, updated_at = clock_timestamp();
  return jsonb_build_object('copied', true, 'import_id', v_import.import_id,
    'source_revision', v_import.source_revision, 'source_sha256', v_hash, 'authority_mode', 'shadow');
end
$$;

create function public.get_canonical_game_import(p_owner_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_import private.canonical_game_imports%rowtype; v_game private.canonical_game_states%rowtype;
begin
  perform private.assert_game_service();
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text, 0));
  select * into v_game from private.canonical_game_states where owner_id = p_owner_id and authority_mode = 'shadow';
  if not found then raise exception 'game_import_required'; end if;
  select * into v_import from private.canonical_game_imports
    where import_id = v_game.source_import_id and owner_id = p_owner_id;
  if not found then raise exception 'game_import_required'; end if;
  return jsonb_build_object('owner_id', p_owner_id, 'import_id', v_import.import_id,
    'base_revision', v_game.revision, 'source_revision', v_import.source_revision, 'source_sha256', v_import.source_sha256,
    'altar_sha256', v_import.altar_sha256, 'source', v_import.source_state,
    'authoritative_altar', v_import.altar_state, 'now', v_import.imported_at,
    'secret_seed', encode(v_import.preparation_seed, 'hex'));
end
$$;

create function public.commit_canonical_game_preparation(
  p_owner_id uuid, p_import_id uuid, p_expected_revision bigint, p_ruleset_sha256 text,
  p_state jsonb, p_changed_asset_kinds text[]
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_game private.canonical_game_states%rowtype; v_import private.canonical_game_imports%rowtype;
  v_source public.cloud_game_saves%rowtype; v_prepared private.canonical_game_preparations%rowtype;
  v_hash text; v_kinds text[]; v_kind text;
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_import_id is null or p_expected_revision is null or p_expected_revision < 1 or p_ruleset_sha256 is null
    or p_ruleset_sha256 !~ '^[0-9a-f]{64}$' or p_changed_asset_kinds is null
    or cardinality(p_changed_asset_kinds) > 100 then raise exception 'game_request_invalid'; end if;
  foreach v_kind in array p_changed_asset_kinds loop
    if v_kind is null or v_kind !~ '^[a-zA-Z][a-zA-Z0-9_]{0,79}$' then raise exception 'game_request_invalid'; end if;
  end loop;
  select coalesce(array_agg(distinct k order by k), '{}') into v_kinds from unnest(p_changed_asset_kinds) k;
  perform private.validate_canonical_game_state(p_state);
  v_hash := private.game_json_sha256(p_state);
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text, 0));
  select * into v_game from private.canonical_game_states where owner_id = p_owner_id for update;
  if not found or v_game.authority_mode <> 'shadow' or v_game.source_import_id <> p_import_id then
    raise exception 'game_import_generation_changed';
  end if;
  select * into v_prepared from private.canonical_game_preparations where import_id = p_import_id;
  if found then
    if v_prepared.prepared_state_sha256 <> v_hash or v_prepared.ruleset_sha256 <> p_ruleset_sha256
      or v_prepared.changed_asset_kinds <> v_kinds then raise exception 'game_idempotency_conflict'; end if;
    return jsonb_build_object('owner_id', p_owner_id, 'import_id', p_import_id,
      'server_revision', v_prepared.prepared_revision, 'state_sha256', v_hash,
      'changed_asset_kinds', v_kinds, 'authority_mode', 'shadow', 'replayed', true);
  end if;
  if exists(select 1 from private.canonical_game_intents where owner_id = p_owner_id and status = 'processing') then
    raise exception 'game_pending_command_required';
  end if;
  if v_game.revision <> p_expected_revision then raise exception 'game_revision_conflict'; end if;
  select * into v_import from private.canonical_game_imports where import_id = p_import_id and owner_id = p_owner_id;
  if not found or v_game.state_sha256 <> v_import.source_sha256 then raise exception 'game_import_copy_changed'; end if;
  select * into v_source from public.cloud_game_saves where user_id = p_owner_id for update;
  if not found or v_source.revision <> v_import.source_revision
    or private.game_json_sha256(v_source.state) <> v_import.source_sha256 then raise exception 'game_import_source_changed'; end if;
  if private.game_json_sha256(coalesce(private.egg_altar_state(p_owner_id), 'null'::jsonb)) <> v_import.altar_sha256 then
    raise exception 'game_import_altar_changed';
  end if;
  if not exists(select 1 from private.game_engine_runtime where singleton and ruleset_sha256 = p_ruleset_sha256) then
    raise exception 'game_ruleset_mismatch';
  end if;
  if p_state#>'{pet,coins}' is distinct from v_import.source_state#>'{pet,coins}'
    or p_state#>'{pet,gems}' is distinct from v_import.source_state#>'{pet,gems}'
    or p_state#>>'{eggAltar,ownerId}' is distinct from p_owner_id::text
    or p_state->'pendingAltarOperation' is distinct from 'null'::jsonb then
    raise exception 'game_import_economy_invalid';
  end if;
  update private.canonical_game_states set state = p_state, state_sha256 = v_hash,
    revision = revision + 1, is_prepared = true, updated_at = clock_timestamp()
    where owner_id = p_owner_id returning * into v_game;
  insert into private.canonical_game_preparations(import_id, owner_id, ruleset_sha256,
      prepared_state_sha256, changed_asset_kinds, prepared_revision)
    values(p_import_id, p_owner_id, p_ruleset_sha256, v_hash, v_kinds, v_game.revision);
  return jsonb_build_object('owner_id', p_owner_id, 'import_id', p_import_id,
    'server_revision', v_game.revision, 'state_sha256', v_hash, 'changed_asset_kinds', v_kinds,
    'authority_mode', 'shadow', 'replayed', false);
end
$$;

revoke all on function public.get_canonical_game_import(uuid),
  public.commit_canonical_game_preparation(uuid,uuid,bigint,text,jsonb,text[]) from public, anon, authenticated;
grant execute on function public.get_canonical_game_import(uuid),
  public.commit_canonical_game_preparation(uuid,uuid,bigint,text,jsonb,text[]) to service_role;
