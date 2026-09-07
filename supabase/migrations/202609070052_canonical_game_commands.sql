-- Detached, dormant evaluation of the full save with the shared Dart rules.
-- This migration cannot activate a player or mutate their live economy. The
-- shadow-only constraint is removed only after the full projection/cutover
-- contracts exist. No current wallet, inventory, Altar or cloud save is written.
create table private.game_engine_runtime (
  singleton boolean primary key default true check (singleton),
  enabled boolean not null default false,
  minimum_client_build integer not null default 10068 check (minimum_client_build > 0),
  ruleset_sha256 text check (ruleset_sha256 ~ '^[0-9a-f]{64}$'),
  updated_at timestamptz not null default now()
);
insert into private.game_engine_runtime(singleton) values (true);

create table private.canonical_game_imports (
  owner_id uuid primary key references public.profiles(user_id) on delete cascade,
  source_revision bigint not null check (source_revision > 0),
  source_sha256 text not null check (source_sha256 ~ '^[0-9a-f]{64}$'),
  source_state jsonb not null check (jsonb_typeof(source_state) = 'object'),
  altar_state jsonb check (jsonb_typeof(altar_state) = 'object'),
  imported_at timestamptz not null default now()
);

create table private.canonical_game_states (
  owner_id uuid primary key references private.canonical_game_imports(owner_id) on delete cascade,
  authority_mode text not null default 'shadow' check (authority_mode = 'shadow'),
  revision bigint not null default 1 check (revision > 0),
  state jsonb not null check (jsonb_typeof(state) = 'object'),
  state_sha256 text not null check (state_sha256 ~ '^[0-9a-f]{64}$'),
  updated_at timestamptz not null default now()
);

create trigger canonical_game_imports_immutable
before update or delete on private.canonical_game_imports
for each row execute function private.reject_economy_ledger_change();

create table private.canonical_game_intents (
  owner_id uuid not null references private.canonical_game_states(owner_id) on delete cascade,
  request_id uuid not null,
  action text not null check (action ~ '^[a-z][a-z0-9_]{2,79}$'),
  payload jsonb not null check (jsonb_typeof(payload) = 'object' and octet_length(payload::text) <= 4096),
  payload_sha256 text not null check (payload_sha256 ~ '^[0-9a-f]{64}$'),
  ruleset_sha256 text not null check (ruleset_sha256 ~ '^[0-9a-f]{64}$'),
  secret_seed bytea not null check (octet_length(secret_seed) = 32),
  base_revision bigint not null check (base_revision > 0),
  evaluated_at timestamptz not null,
  lease_token uuid not null,
  leased_until timestamptz not null,
  status text not null default 'processing' check (status in ('processing', 'succeeded', 'failed')),
  response jsonb check (jsonb_typeof(response) = 'object' and octet_length(response::text) <= 32768),
  failure_code text check (failure_code ~ '^[a-z][a-z0-9_]{2,79}$'),
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  primary key (owner_id, request_id),
  check (
    (status = 'processing' and response is null and failure_code is null and completed_at is null)
    or (status = 'succeeded' and response is not null and failure_code is null and completed_at is not null)
    or (status = 'failed' and response is null and failure_code is not null and completed_at is not null)
  )
);
create unique index canonical_game_one_pending_owner_idx
  on private.canonical_game_intents(owner_id) where status = 'processing';
create index canonical_game_intents_completed_idx
  on private.canonical_game_intents(completed_at) where completed_at is not null;

alter table private.game_engine_runtime enable row level security;
alter table private.canonical_game_imports enable row level security;
alter table private.canonical_game_states enable row level security;
alter table private.canonical_game_intents enable row level security;
revoke all on private.game_engine_runtime, private.canonical_game_imports,
  private.canonical_game_states, private.canonical_game_intents from public, anon, authenticated;

create function private.game_json_sha256(p_value jsonb)
returns text language sql immutable set search_path = '' as $$
  select encode(extensions.digest(convert_to(p_value::text, 'utf8'), 'sha256'), 'hex')
$$;

create function private.assert_game_service()
returns void language plpgsql stable set search_path = '' as $$
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'game_service_required';
  end if;
end
$$;

create function private.validate_canonical_game_state(p_state jsonb)
returns void language plpgsql immutable set search_path = '' as $$
declare key text; quantity jsonb;
begin
  if jsonb_typeof(p_state) is distinct from 'object'
    or octet_length(p_state::text) > 8388608
    or p_state->>'schemaVersion' is distinct from '54'
    or jsonb_typeof(p_state->'pet') is distinct from 'object'
    or nullif(p_state->'pet'->>'id', '') is null then
    raise exception 'game_state_invalid';
  end if;
  foreach key in array array['coins', 'gems'] loop
    quantity := p_state->'pet'->key;
    if jsonb_typeof(quantity) is distinct from 'number'
      or quantity::text !~ '^[0-9]{1,15}$' then
      raise exception 'game_wallet_invalid';
    end if;
  end loop;
  foreach key in array array['eggStash', 'sanctuaryDragons', 'releasedDragons'] loop
    if jsonb_typeof(p_state->key) is distinct from 'array' then
      raise exception 'game_inventory_invalid';
    end if;
  end loop;
  foreach key in array array['chestInventory', 'specialChestInventory', 'relicInventory',
      'untradeableRelicInventory'] loop
    if jsonb_typeof(p_state->key) is distinct from 'object' then
      raise exception 'game_inventory_invalid';
    end if;
    for quantity in select value from jsonb_each(p_state->key) loop
      if jsonb_typeof(quantity) is distinct from 'number'
        or quantity::text !~ '^[0-9]{1,9}$' then
        raise exception 'game_inventory_invalid';
      end if;
    end loop;
  end loop;
end
$$;

-- The only import input is an owner and an exact existing cloud revision/hash.
-- Preserve the complete source verbatim, including unknown non-economy fields,
-- and capture the authoritative Altar separately for the migration review.
create function public.stage_canonical_game_copy(
  p_owner_id uuid, p_source_revision bigint, p_source_sha256 text
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare source public.cloud_game_saves%rowtype; previous private.canonical_game_imports%rowtype;
  actual_hash text;
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_source_revision is null or p_source_revision < 1
    or p_source_sha256 is null or p_source_sha256 !~ '^[0-9a-f]{64}$' then
    raise exception 'game_request_invalid';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text, 0));
  select * into previous from private.canonical_game_imports where owner_id = p_owner_id;
  if found then
    if previous.source_revision <> p_source_revision or previous.source_sha256 <> p_source_sha256 then
      raise exception 'game_import_already_exists';
    end if;
    return jsonb_build_object('copied', false, 'source_revision', previous.source_revision,
      'source_sha256', previous.source_sha256, 'authority_mode', 'shadow');
  end if;
  select * into source from public.cloud_game_saves where user_id = p_owner_id for share;
  if not found or source.revision <> p_source_revision then
    raise exception 'game_import_source_changed';
  end if;
  actual_hash := private.game_json_sha256(source.state);
  if actual_hash <> p_source_sha256 then raise exception 'game_import_source_changed'; end if;
  perform private.validate_canonical_game_state(source.state);
  insert into private.canonical_game_imports(owner_id, source_revision, source_sha256, source_state, altar_state)
    values (p_owner_id, source.revision, actual_hash, source.state, private.egg_altar_state(p_owner_id));
  insert into private.canonical_game_states(owner_id, state, state_sha256)
    values (p_owner_id, source.state, actual_hash);
  return jsonb_build_object('copied', true, 'source_revision', source.revision,
    'source_sha256', actual_hash, 'authority_mode', 'shadow');
end
$$;

-- Only a trusted worker can obtain a state or seed. A lease token fences a
-- worker that finishes after a timeout, while the original time/seed remain
-- fixed for a retry. An owner can have only one uncommitted intent.
create function public.begin_canonical_game_command(
  p_owner_id uuid, p_request_id uuid, p_action text, p_payload jsonb,
  p_client_build integer, p_ruleset_sha256 text
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare runtime private.game_engine_runtime%rowtype; game private.canonical_game_states%rowtype;
  intent private.canonical_game_intents%rowtype; requested_hash text; at_time timestamptz := clock_timestamp();
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_request_id is null or p_action is null
    or p_action !~ '^[a-z][a-z0-9_]{2,79}$'
    or jsonb_typeof(p_payload) is distinct from 'object' or octet_length(p_payload::text) > 4096 then
    raise exception 'game_request_invalid';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text, 0));
  select * into runtime from private.game_engine_runtime where singleton;
  if not found or not runtime.enabled then raise exception 'game_engine_disabled'; end if;
  if p_client_build is null or p_client_build < runtime.minimum_client_build then
    raise exception 'game_client_upgrade_required';
  end if;
  if runtime.ruleset_sha256 is null or p_ruleset_sha256 is distinct from runtime.ruleset_sha256 then
    raise exception 'game_ruleset_mismatch';
  end if;
  select * into game from private.canonical_game_states where owner_id = p_owner_id for update;
  if not found then raise exception 'game_import_required'; end if;
  requested_hash := private.game_json_sha256(p_payload);
  select * into intent from private.canonical_game_intents
    where owner_id = p_owner_id and request_id = p_request_id for update;
  if found then
    if intent.action <> p_action or intent.payload_sha256 <> requested_hash then
      raise exception 'game_idempotency_conflict';
    end if;
    if intent.status <> 'processing' then
      return jsonb_build_object('status', intent.status, 'response', intent.response,
        'failure_code', intent.failure_code, 'replayed', true);
    end if;
    if intent.ruleset_sha256 <> p_ruleset_sha256 then raise exception 'game_pending_ruleset_changed'; end if;
    if intent.leased_until > at_time then raise exception 'game_command_busy'; end if;
    if intent.base_revision <> game.revision then raise exception 'game_revision_conflict'; end if;
    update private.canonical_game_intents set lease_token = gen_random_uuid(),
      leased_until = at_time + interval '60 seconds'
      where owner_id = p_owner_id and request_id = p_request_id returning * into intent;
  else
    if exists(select 1 from private.canonical_game_intents
        where owner_id = p_owner_id and status = 'processing') then
      raise exception 'game_pending_command_required';
    end if;
    perform private.consume_economy_rate_limit(p_owner_id, 'game.command', 60, 60);
    insert into private.canonical_game_intents(owner_id, request_id, action, payload, payload_sha256,
        ruleset_sha256, secret_seed, base_revision, evaluated_at, lease_token, leased_until)
      values (p_owner_id, p_request_id, p_action, p_payload, requested_hash, p_ruleset_sha256,
        extensions.gen_random_bytes(32), game.revision, at_time, gen_random_uuid(), at_time + interval '60 seconds')
      returning * into intent;
  end if;
  return jsonb_build_object('status', 'processing', 'replayed', false, 'owner_id', p_owner_id,
    'request_id', p_request_id, 'lease_token', intent.lease_token,
    'base_revision', intent.base_revision, 'now', intent.evaluated_at,
    'secret_seed', encode(intent.secret_seed, 'hex'), 'state', game.state,
    'authority_mode', game.authority_mode);
end
$$;

create function public.commit_canonical_game_command(
  p_owner_id uuid, p_request_id uuid, p_lease_token uuid,
  p_state jsonb, p_result jsonb
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare intent private.canonical_game_intents%rowtype; game private.canonical_game_states%rowtype;
  v_response jsonb; at_time timestamptz := clock_timestamp();
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_request_id is null or p_lease_token is null then
    raise exception 'game_request_invalid';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text, 0));
  select * into intent from private.canonical_game_intents
    where owner_id = p_owner_id and request_id = p_request_id for update;
  if not found or intent.lease_token <> p_lease_token then raise exception 'game_lease_lost'; end if;
  if intent.status = 'succeeded' then return intent.response; end if;
  if intent.status <> 'processing' or intent.leased_until <= at_time then raise exception 'game_lease_lost'; end if;
  if not exists(select 1 from private.game_engine_runtime r
      where r.singleton and r.enabled and r.ruleset_sha256 = intent.ruleset_sha256) then
    raise exception 'game_engine_disabled';
  end if;
  perform private.validate_canonical_game_state(p_state);
  if octet_length(coalesce(p_result::text, 'null')) > 30000 then raise exception 'game_result_invalid'; end if;
  select * into game from private.canonical_game_states where owner_id = p_owner_id for update;
  if not found or game.revision <> intent.base_revision then raise exception 'game_revision_conflict'; end if;
  update private.canonical_game_states set state = p_state,
    state_sha256 = private.game_json_sha256(p_state), revision = revision + 1, updated_at = at_time
    where owner_id = p_owner_id returning * into game;
  v_response := jsonb_build_object('owner_id', p_owner_id, 'request_id', p_request_id,
    'server_revision', game.revision, 'state_sha256', game.state_sha256,
    'result', p_result, 'authority_mode', game.authority_mode);
  update private.canonical_game_intents set status = 'succeeded', response = v_response,
    completed_at = at_time where owner_id = p_owner_id and request_id = p_request_id;
  return v_response;
end
$$;

create function public.fail_canonical_game_command(
  p_owner_id uuid, p_request_id uuid, p_lease_token uuid, p_failure_code text
) returns boolean language plpgsql security definer set search_path = '' as $$
declare changed integer;
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_request_id is null or p_lease_token is null
    or p_failure_code is null or p_failure_code !~ '^[a-z][a-z0-9_]{2,79}$' then
    raise exception 'game_request_invalid';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text, 0));
  update private.canonical_game_intents set status = 'failed', failure_code = p_failure_code,
    completed_at = clock_timestamp()
    where owner_id = p_owner_id and request_id = p_request_id and status = 'processing'
      and lease_token = p_lease_token and leased_until > clock_timestamp();
  get diagnostics changed = row_count;
  return changed = 1;
end
$$;

revoke all on function private.game_json_sha256(jsonb), private.assert_game_service(),
  private.validate_canonical_game_state(jsonb) from public, anon, authenticated;
revoke all on function public.stage_canonical_game_copy(uuid,bigint,text),
  public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb),
  public.fail_canonical_game_command(uuid,uuid,uuid,text) from public, anon, authenticated;
grant execute on function public.stage_canonical_game_copy(uuid,bigint,text),
  public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb),
  public.fail_canonical_game_command(uuid,uuid,uuid,text) to service_role;
