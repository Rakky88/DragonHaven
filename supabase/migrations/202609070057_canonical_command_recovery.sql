-- Recovery advances only the shadow command boundary, never player assets.
-- Every fresh command must name the revision the player actually observed.
-- This also fences a pre-recovery request which reaches the server very late.
alter table private.canonical_game_intents add column requested_revision bigint
  check (requested_revision > 0 and requested_revision <= 9007199254740991);

create table private.canonical_game_recoveries (
  owner_id uuid not null references private.canonical_game_states(owner_id) on delete cascade,
  request_id uuid not null,
  barrier_revision bigint not null check (barrier_revision > 0 and barrier_revision <= 9007199254740991),
  cancelled_commands integer not null check (cancelled_commands between 0 and 1),
  created_at timestamptz not null default now(),
  primary key (owner_id, request_id)
);
alter table private.canonical_game_recoveries enable row level security;
revoke all on private.canonical_game_recoveries from public, anon, authenticated, service_role;
create trigger canonical_game_recoveries_immutable
  before update or delete on private.canonical_game_recoveries
  for each row execute function private.reject_economy_ledger_change();

-- Preserve the proven lease/receipt implementation, but remove its direct RPC
-- permission. Old workers cannot bypass the revision check after deployment.
revoke all on function public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text)
  from public, anon, authenticated, service_role;

create function public.begin_revisioned_game_command(
  p_owner_id uuid, p_request_id uuid, p_action text, p_payload jsonb,
  p_client_build integer, p_ruleset_sha256 text, p_expected_revision bigint
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare previous private.canonical_game_intents%rowtype; leased jsonb;
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_expected_revision is null
    or p_expected_revision < 1 or p_expected_revision > 9007199254740991 then
    raise exception 'game_request_invalid';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text, 0));
  select * into previous from private.canonical_game_intents
    where owner_id=p_owner_id and request_id=p_request_id;
  if found and previous.requested_revision is not null
    and previous.requested_revision <> p_expected_revision then
    raise exception 'game_idempotency_conflict';
  end if;
  leased := public.begin_canonical_game_command(p_owner_id, p_request_id, p_action,
    p_payload, p_client_build, p_ruleset_sha256);
  if leased->>'status' <> 'processing' then return leased; end if;
  update private.canonical_game_intents set requested_revision=p_expected_revision
    where owner_id=p_owner_id and request_id=p_request_id and requested_revision is null;
  if (leased->>'base_revision')::bigint <> p_expected_revision then
    -- Record a terminal refusal so reconnects can acknowledge it normally.
    -- No Dart evaluation or asset change takes place for stale commands.
    if not public.fail_canonical_game_command(p_owner_id, p_request_id,
        (leased->>'lease_token')::uuid, 'game_state_changed') then
      raise exception 'game_lease_lost';
    end if;
    return jsonb_build_object('status','failed','failure_code','game_state_changed',
      'response',null,'replayed',false);
  end if;
  return leased;
end $$;

create function public.recover_canonical_game_commands(
  p_owner_id uuid, p_request_id uuid, p_client_build integer, p_ruleset_sha256 text
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare runtime private.game_engine_runtime%rowtype;
  game private.canonical_game_states%rowtype;
  recovered private.canonical_game_recoveries%rowtype;
  cancelled integer; replayed boolean := false; at_time timestamptz := clock_timestamp();
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_request_id is null or p_client_build is null
    or p_client_build < 1 or p_ruleset_sha256 is null
    or p_ruleset_sha256 !~ '^[0-9a-f]{64}$' then raise exception 'game_request_invalid'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text, 0));
  select * into strict runtime from private.game_engine_runtime where singleton for share;
  if p_client_build < runtime.minimum_client_build then raise exception 'game_client_upgrade_required'; end if;
  if p_ruleset_sha256 is distinct from runtime.ruleset_sha256 then raise exception 'game_ruleset_mismatch'; end if;
  select * into game from private.canonical_game_states where owner_id=p_owner_id for update;
  if not found then raise exception 'game_import_required'; end if;
  if not game.is_prepared then raise exception 'game_import_preparation_required'; end if;
  select * into recovered from private.canonical_game_recoveries
    where owner_id=p_owner_id and request_id=p_request_id;
  if found then replayed := true;
  else
    if exists(select 1 from private.canonical_game_intents
        where owner_id=p_owner_id and request_id=p_request_id) then
      raise exception 'game_idempotency_conflict';
    end if;
    perform private.consume_economy_rate_limit(p_owner_id,'game.recovery',6,60);
    -- A paused engine still permits recovery. Commit uses the same owner lock
    -- and refuses these cancelled leases, including an already running worker.
    update private.canonical_game_intents set status='failed',
      failure_code='game_command_recovered', completed_at=at_time, leased_until=at_time
      where owner_id=p_owner_id and status='processing';
    get diagnostics cancelled = row_count;
    update private.canonical_game_states set revision=revision+1, updated_at=at_time
      where owner_id=p_owner_id returning * into game;
    insert into private.canonical_game_recoveries(owner_id,request_id,barrier_revision,cancelled_commands)
      values(p_owner_id,p_request_id,game.revision,cancelled) returning * into recovered;
  end if;
  return jsonb_build_object('protocol',2,'owner_id',p_owner_id,'request_id',p_request_id,
    'authority_mode','shadow','barrier_revision',recovered.barrier_revision,
    'cancelled_commands',recovered.cancelled_commands,'replayed',replayed);
end $$;

revoke all on function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.recover_canonical_game_commands(uuid,uuid,integer,text) from public, anon, authenticated;
grant execute on function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.recover_canonical_game_commands(uuid,uuid,integer,text) to service_role;
