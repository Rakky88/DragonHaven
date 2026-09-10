-- Sealed social reward facts and atomic source acknowledgments. Dormant by
-- default. Detached shadow copies may use this only in an explicitly enabled
-- staging rehearsal; no live economy or account authority is activated here.
alter table private.game_engine_runtime
  add column shadow_social_enabled boolean not null default false;
alter table private.canonical_game_intents
  add column social_context jsonb
    check (social_context is null or (jsonb_typeof(social_context) = 'object'
      and octet_length(social_context::text) <= 16384));

create function private.canonical_social_claim_context(
  p_owner_id uuid, p_action text, p_payload jsonb, p_at timestamptz
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare source_id uuid; facts jsonb; allowed boolean;
  lobby public.group_adventure_lobbies%rowtype;
  participant public.group_adventure_participants%rowtype;
  pair public.seasonal_pair_adventures%rowtype;
  prize public.seasonal_event_prizes%rowtype;
  dragon_key text; headcount integer; claimed timestamptz;
begin
  perform private.assert_game_service();
  select g.is_prepared and (g.authority_mode='server' or r.shadow_social_enabled)
    into allowed from private.canonical_game_states g
    cross join private.game_engine_runtime r
    where g.owner_id=p_owner_id and r.singleton;
  if not coalesce(allowed,false) or p_at is null then
    raise exception 'game_social_claim_unavailable';
  end if;
  source_id := (p_payload ->> case p_action
    when 'claim_group_reward' then 'lobbyId'
    when 'claim_pair_reward' then 'adventureId'
    when 'claim_podium_prize' then 'prizeId' else '' end)::uuid;
  if source_id is null then raise exception 'game_social_claim_unavailable'; end if;

  if p_action='claim_group_reward' then
    select * into lobby from public.group_adventure_lobbies
      where id=source_id for update;
    if not found or lobby.status not in ('running','completed')
        or lobby.ends_at is null or lobby.ends_at > p_at then
      raise exception 'game_social_claim_unavailable';
    end if;
    select * into participant from public.group_adventure_participants
      where lobby_id=source_id and user_id=p_owner_id for update;
    if not found or participant.reward_acknowledged_at is not null then
      raise exception 'game_social_claim_unavailable';
    end if;
    select legacy_client_id into dragon_key from public.player_dragons
      where id=participant.dragon_id and owner_id=p_owner_id;
    if dragon_key is null then raise exception 'game_social_claim_unavailable'; end if;
    select count(*)::integer into headcount from public.group_adventure_participants
      where lobby_id=source_id;
    facts := jsonb_build_object('adventureId',lobby.adventure_id,'dragonId',dragon_key,
      'xp',lobby.xp,'focus',lobby.focus,'statPoints',lobby.stat_points,
      'chestTier',lobby.chest_tier,'participantCount',headcount);
  elsif p_action='claim_pair_reward' then
    select * into pair from public.seasonal_pair_adventures
      where id=source_id and p_owner_id in (creator_id,partner_id) for update;
    if not found or pair.status not in ('running','reward_ready','completed')
        or pair.ends_at is null or pair.ends_at > p_at then
      raise exception 'game_social_claim_unavailable';
    end if;
    claimed := case when p_owner_id=pair.creator_id then pair.creator_reward_claimed_at
      else pair.partner_reward_claimed_at end;
    if claimed is not null then raise exception 'game_social_claim_unavailable'; end if;
    dragon_key := case when p_owner_id=pair.creator_id then pair.creator_dragon_id
      else pair.partner_dragon_id end;
    facts := jsonb_build_object('eventId',pair.event_id,'dragonId',dragon_key,
      'xp',650,'might',8,'arcana',8,'spirit',8,
      'specialChestId','twinheart_keepsake_chest_v1','simulated',pair.simulated);
  elsif p_action='claim_podium_prize' then
    select * into prize from public.seasonal_event_prizes
      where id=source_id and user_id=p_owner_id for update;
    if not found or prize.claimed_at is not null or prize.finalized_at > p_at then
      raise exception 'game_social_claim_unavailable';
    end if;
    facts := jsonb_build_object('eventId',prize.event_id,'position',prize.ranking_position);
  else
    raise exception 'game_social_claim_unavailable';
  end if;
  return jsonb_build_object('version',1,'ownerId',p_owner_id,'action',p_action,
    'sourceId',source_id,'facts',facts,
    'fingerprint',private.game_json_sha256(jsonb_build_object(
      'ownerId',p_owner_id,'action',p_action,'sourceId',source_id,'facts',facts)));
exception when invalid_text_representation then
  raise exception 'game_social_claim_unavailable';
end $$;

create function private.commit_canonical_social_claim(
  p_owner_id uuid, p_action text, p_payload jsonb, p_context jsonb,
  p_result jsonb, p_at timestamptz
) returns void language plpgsql security definer set search_path = '' as $$
declare current_context jsonb; source_id uuid;
begin
  perform private.assert_game_service();
  if p_action not in ('claim_group_reward','claim_pair_reward','claim_podium_prize') then
    return;
  end if;
  begin
    current_context := private.canonical_social_claim_context(p_owner_id,p_action,p_payload,p_at);
  exception when raise_exception then
    if sqlerrm='game_social_claim_unavailable' then
      raise exception 'game_social_state_changed';
    end if;
    raise;
  end;
  if p_context is distinct from current_context or p_result->'accepted' is distinct from 'true'::jsonb
      or p_result->>'sourceId' is distinct from p_context->>'sourceId' then
    raise exception 'game_social_state_changed';
  end if;
  source_id := (p_context->>'sourceId')::uuid;
  if p_action='claim_group_reward' then
    update public.group_adventure_lobbies set status='completed',
      completed_at=coalesce(completed_at,p_at) where id=source_id;
    update public.group_adventure_participants set reward_acknowledged_at=p_at
      where lobby_id=source_id and user_id=p_owner_id;
  elsif p_action='claim_pair_reward' then
    insert into public.social_notifications(user_id,kind,actor_id,entity_id)
      select creator_id,'seasonal_pair_ready',partner_id,id
        from public.seasonal_pair_adventures where id=source_id and status='running'
      union all select partner_id,'seasonal_pair_ready',creator_id,id
        from public.seasonal_pair_adventures where id=source_id and status='running';
    update public.seasonal_pair_adventures set
      creator_reward_claimed_at=case when creator_id=p_owner_id then p_at else creator_reward_claimed_at end,
      partner_reward_claimed_at=case when partner_id=p_owner_id then p_at else partner_reward_claimed_at end
      where id=source_id;
    update public.seasonal_pair_adventures set status=case
      when creator_reward_claimed_at is not null and partner_reward_claimed_at is not null
      then 'completed' else 'reward_ready' end where id=source_id;
  else
    update public.seasonal_event_prizes set claimed_at=p_at
      where id=source_id and user_id=p_owner_id;
  end if;
end $$;

revoke all on function private.canonical_social_claim_context(uuid,text,jsonb,timestamptz),
  private.commit_canonical_social_claim(uuid,text,jsonb,jsonb,jsonb,timestamptz)
  from public, anon, authenticated, service_role;

create or replace function public.begin_revisioned_game_command(
  p_owner_id uuid, p_request_id uuid, p_action text, p_payload jsonb,
  p_client_build integer, p_ruleset_sha256 text, p_expected_revision bigint
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare previous private.canonical_game_intents%rowtype; leased jsonb; context_value jsonb;
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
  if p_action in ('claim_group_reward','claim_pair_reward','claim_podium_prize') then
    select social_context into context_value from private.canonical_game_intents
      where owner_id=p_owner_id and request_id=p_request_id;
    if context_value is null then
      begin
        context_value := private.canonical_social_claim_context(
          p_owner_id,p_action,p_payload,(leased->>'now')::timestamptz);
      exception when raise_exception then
        if sqlerrm <> 'game_social_claim_unavailable' then raise; end if;
        if not public.fail_canonical_game_command(p_owner_id,p_request_id,
            (leased->>'lease_token')::uuid,'game_social_claim_unavailable') then
          raise exception 'game_lease_lost';
        end if;
        return jsonb_build_object('status','failed','failure_code','game_social_claim_unavailable',
          'response',null,'replayed',false);
      end;
      update private.canonical_game_intents set social_context=context_value
        where owner_id=p_owner_id and request_id=p_request_id;
    end if;
    leased := leased || jsonb_build_object('social_context',context_value);
  end if;
  return leased;
end $$;


create or replace function public.commit_canonical_game_command(
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
  perform private.commit_canonical_social_claim(p_owner_id,intent.action,intent.payload,
    intent.social_context,p_result,at_time);
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


create function private.canonical_social_claim_offers(p_owner_id uuid,p_at timestamptz)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare offers jsonb;
begin
  perform private.assert_game_service();
  if not exists(select 1 from private.canonical_game_states g cross join private.game_engine_runtime r
      where g.owner_id=p_owner_id and g.is_prepared and r.singleton
        and (g.authority_mode='server' or r.shadow_social_enabled)) then return '[]'::jsonb; end if;
  select coalesce(jsonb_agg(jsonb_build_object('id',o.id,'kind',o.kind,'catalogId',o.catalog,
    'dragonId',o.dragon,'position',o.position,'readyAt',o.ready) order by o.ready,o.id),'[]'::jsonb)
    into offers from (
      (select l.id,'group' as kind,l.adventure_id as catalog,d.legacy_client_id as dragon,
        null::integer as position,l.ends_at as ready
        from public.group_adventure_lobbies l join public.group_adventure_participants p on p.lobby_id=l.id
        join public.player_dragons d on d.id=p.dragon_id and d.owner_id=p_owner_id
        where p.user_id=p_owner_id and p.reward_acknowledged_at is null and d.legacy_client_id is not null
          and l.status in ('running','completed') and l.ends_at<=p_at order by l.ends_at,l.id limit 100)
      union all
      (select a.id,'pair',a.event_id,case when a.creator_id=p_owner_id then a.creator_dragon_id else a.partner_dragon_id end,
        null::integer,a.ends_at from public.seasonal_pair_adventures a
        where p_owner_id in (a.creator_id,a.partner_id) and a.status in ('running','reward_ready','completed') and a.ends_at<=p_at
          and case when a.creator_id=p_owner_id then a.creator_reward_claimed_at is null else a.partner_reward_claimed_at is null end
          and case when a.creator_id=p_owner_id then a.creator_dragon_id is not null else a.partner_dragon_id is not null end
        order by a.ends_at,a.id limit 100)
      union all
      (select p.id,'podium',p.event_id,null::text,p.ranking_position,p.finalized_at
        from public.seasonal_event_prizes p where p.user_id=p_owner_id and p.claimed_at is null and p.finalized_at<=p_at
        order by p.finalized_at,p.id limit 100)
    ) o;
  return offers;
end $$;
revoke all on function private.canonical_social_claim_offers(uuid,timestamptz)
  from public,anon,authenticated,service_role;

create or replace function public.read_canonical_game_state(
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
  select * into strict v_runtime from private.game_engine_runtime where singleton for share;
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
    'social_claims', private.canonical_social_claim_offers(p_owner_id,clock_timestamp()),
    'mutations_enabled', v_runtime.enabled, 'ruleset_revision', v_runtime.ruleset_revision);
end $$;
