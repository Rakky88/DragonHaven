-- A client stops waiting after ten seconds.  A lost begin-RPC response can
-- nevertheless leave the durable request leased for sixty seconds, making
-- every reconnect report game_command_busy even though the request UUID is
-- identical.  Collapse only near-simultaneous duplicates; after that short
-- window an exact retry rotates the lease token.  The old worker is then
-- fenced by commit_canonical_game_command's token check.
-- Migration 069 renamed this lease primitive to v68 and wrapped it with
-- captured social reservations; migration 074 wrapped that entry again with
-- trade reservations.  Replace only the primitive so both outer wrappers stay
-- intact.
create or replace function public.begin_canonical_game_command_v68(
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
  if not found then raise exception 'game_engine_disabled'; end if;
  if p_client_build is null or p_client_build < runtime.minimum_client_build then
    raise exception 'game_client_upgrade_required';
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
  end if;
  -- Completed receipts remain recoverable while mutations are paused or a new
  -- ruleset is active.  An unfinished request may only renew under the exact
  -- ruleset that fixed its seed, time and evaluation inputs.
  if not runtime.enabled then raise exception 'game_engine_disabled'; end if;
  if runtime.ruleset_sha256 is null or p_ruleset_sha256 is distinct from runtime.ruleset_sha256 then
    raise exception 'game_ruleset_mismatch';
  end if;
  if intent.owner_id is not null then
    if intent.ruleset_sha256 <> p_ruleset_sha256 then raise exception 'game_pending_ruleset_changed'; end if;
    -- Every lease issued below ends exactly sixty seconds after it starts.
    -- Keep an eight-second duplicate-collapse window, then let the same durable
    -- UUID take over after the worker's 7.5-second response budget without
    -- waiting for the rest of the sixty-second lease.  Eight seconds avoids
    -- stealing an ordinarily healthy evaluation near its completion.
    if intent.leased_until > at_time + interval '52 seconds' then
      raise exception 'game_command_busy';
    end if;
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

-- This primitive remains callable only through the revision-, account-,
-- social- and trade-aware service wrappers.
revoke all on function public.begin_canonical_game_command_v68(uuid,uuid,text,jsonb,integer,text)
  from public, anon, authenticated, service_role;
