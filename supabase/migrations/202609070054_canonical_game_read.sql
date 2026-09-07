-- Private read for the authenticated Edge projection. Raw state is never
-- granted to clients. Reads deliberately continue when mutations are paused.
create function public.read_canonical_game_state(
  p_owner_id uuid, p_client_build integer, p_ruleset_sha256 text
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_runtime private.game_engine_runtime%rowtype;
  v_game private.canonical_game_states%rowtype;
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_client_build is null or p_client_build < 1
    or p_ruleset_sha256 is null or p_ruleset_sha256 !~ '^[0-9a-f]{64}$' then
    raise exception 'game_request_invalid';
  end if;
  select * into strict v_runtime from private.game_engine_runtime where singleton;
  if p_client_build < v_runtime.minimum_client_build then
    raise exception 'game_client_upgrade_required';
  end if;
  if v_runtime.ruleset_sha256 is distinct from p_ruleset_sha256 then
    raise exception 'game_ruleset_mismatch';
  end if;
  -- A single MVCC row contains the state and matching revision/hash. No lease,
  -- clock advancement, wallet mutation, import or reward is created by a read.
  select * into v_game from private.canonical_game_states where owner_id = p_owner_id;
  if not found then raise exception 'game_import_required'; end if;
  if not v_game.is_prepared then raise exception 'game_import_preparation_required'; end if;
  return jsonb_build_object(
    'owner_id', p_owner_id, 'server_revision', v_game.revision,
    'state_sha256', v_game.state_sha256, 'authority_mode', v_game.authority_mode,
    'server_time', clock_timestamp(), 'state', v_game.state,
    'mutations_enabled', v_runtime.enabled);
end $$;

revoke all on function public.read_canonical_game_state(uuid,integer,text)
  from public, anon, authenticated;
grant execute on function public.read_canonical_game_state(uuid,integer,text)
  to service_role;
