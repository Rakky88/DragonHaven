-- A single database view binds group/partner dragons in command evaluation
-- and public display. Disabled for detached shadows unless explicitly tested.
alter table private.game_engine_runtime
  add column shadow_lifecycle_enabled boolean not null default false;
alter table private.canonical_game_intents
  add column social_reservations jsonb check (social_reservations is null or
    (jsonb_typeof(social_reservations)='object' and octet_length(social_reservations::text)<=262144)),
  add column social_reservations_captured boolean not null default false;

create function private.canonical_social_reservations(p_owner_id uuid,p_at timestamptz,p_lock boolean)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare entries jsonb; slot_value bigint;
begin
  perform private.assert_game_service();
  if not exists(select 1 from private.canonical_game_states g cross join private.game_engine_runtime r
      where g.owner_id=p_owner_id and g.is_prepared and r.singleton
        and (g.authority_mode='server' or r.shadow_lifecycle_enabled)) then return null; end if;
  slot_value := private.group_adventure_slot(p_at);
  if p_lock then
    -- Source locks prevent a leave/kick/acknowledgment between comparing the
    -- frozen view and committing the next activity or reward. The owner lock
    -- is always acquired by the outer command before any source row lock.
    perform l.id from public.group_adventure_lobbies l
      join public.group_adventure_participants p on p.lobby_id=l.id
      where p.user_id=p_owner_id and p.reward_acknowledged_at is null
        and ((l.status='waiting' and l.slot=slot_value) or l.status in ('running','completed'))
      order by l.id for update of l,p;
    perform a.id from public.seasonal_pair_adventures a
      where p_owner_id in (a.creator_id,a.partner_id)
        and a.status in ('invited','accepted','running','reward_ready','completed')
      order by a.id for update;
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('dragonId',s.dragon,'kind',s.kind,'sourceId',s.source)
      order by s.dragon,s.kind,s.source),'[]'::jsonb) into entries from (
    select d.legacy_client_id as dragon,'group' as kind,l.id as source
      from public.group_adventure_lobbies l join public.group_adventure_participants p on p.lobby_id=l.id
      join public.player_dragons d on d.id=p.dragon_id and d.owner_id=p_owner_id
      where p.user_id=p_owner_id and p.reward_acknowledged_at is null
        and ((l.status='waiting' and l.slot=slot_value) or l.status in ('running','completed'))
    union all
    select case when a.creator_id=p_owner_id then a.creator_dragon_id else a.partner_dragon_id end,
      'pair',a.id from public.seasonal_pair_adventures a
      where p_owner_id in (a.creator_id,a.partner_id)
        and a.status in ('invited','accepted','running','reward_ready','completed')
        and case when a.creator_id=p_owner_id then a.creator_reward_claimed_at is null
          else a.partner_reward_claimed_at is null and a.partner_dragon_id is not null end
  ) s;
  if jsonb_array_length(entries)>1000 then raise exception 'game_state_reconciliation_required'; end if;
  return jsonb_build_object('version',1,'ownerId',p_owner_id,'reservations',entries);
end $$;
revoke all on function private.canonical_social_reservations(uuid,timestamptz,boolean)
  from public,anon,authenticated,service_role;

alter function public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text)
  rename to begin_canonical_game_command_v68;
create function public.begin_canonical_game_command(
  p_owner_id uuid,p_request_id uuid,p_action text,p_payload jsonb,
  p_client_build integer,p_ruleset_sha256 text
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare leased jsonb; bindings jsonb; current_bindings jsonb; captured boolean;
begin
  perform private.assert_game_service();
  leased:=public.begin_canonical_game_command_v68(p_owner_id,p_request_id,p_action,p_payload,
    p_client_build,p_ruleset_sha256);
  if leased->>'status'<>'processing' then return leased; end if;
  current_bindings:=private.canonical_social_reservations(p_owner_id,clock_timestamp(),true);
  select social_reservations,social_reservations_captured into bindings,captured
    from private.canonical_game_intents where owner_id=p_owner_id and request_id=p_request_id;
  if not captured then
    bindings:=current_bindings;
    update private.canonical_game_intents set social_reservations=bindings,social_reservations_captured=true
      where owner_id=p_owner_id and request_id=p_request_id;
  end if;
  return leased || jsonb_build_object('social_reservations',bindings);
end $$;

alter function public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb)
  rename to commit_canonical_game_command_v68;
create function public.commit_canonical_game_command(
  p_owner_id uuid,p_request_id uuid,p_lease_token uuid,p_state jsonb,p_result jsonb
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare intent private.canonical_game_intents%rowtype;
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_request_id is null or p_lease_token is null then
    raise exception 'game_request_invalid'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0));
  select * into intent from private.canonical_game_intents
    where owner_id=p_owner_id and request_id=p_request_id for update;
  if not found or intent.lease_token<>p_lease_token then raise exception 'game_lease_lost'; end if;
  if intent.status='processing' then
    if intent.leased_until<=clock_timestamp() then raise exception 'game_lease_lost'; end if;
    if not intent.social_reservations_captured or intent.social_reservations is distinct from
        private.canonical_social_reservations(p_owner_id,clock_timestamp(),true) then
      raise exception 'game_social_state_changed';
    end if;
  end if;
  -- The previous implementation still owns revision/lease/ruleset validation,
  -- exact receipt replay and atomic social reward acknowledgment.
  return public.commit_canonical_game_command_v68(p_owner_id,p_request_id,p_lease_token,p_state,p_result);
end $$;

alter function public.read_canonical_game_state(uuid,integer,text) rename to read_canonical_game_state_v68;
create function public.read_canonical_game_state(p_owner_id uuid,p_client_build integer,p_ruleset_sha256 text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare snapshot jsonb; bindings jsonb;
begin
  perform private.assert_game_service();
  if p_owner_id is null then raise exception 'game_request_invalid'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0));
  bindings:=private.canonical_social_reservations(p_owner_id,clock_timestamp(),true);
  snapshot:=public.read_canonical_game_state_v68(p_owner_id,p_client_build,p_ruleset_sha256);
  return snapshot || jsonb_build_object('social_reservations',bindings);
end $$;

revoke all on function public.begin_canonical_game_command_v68(uuid,uuid,text,jsonb,integer,text),
  public.commit_canonical_game_command_v68(uuid,uuid,uuid,jsonb,jsonb),
  public.read_canonical_game_state_v68(uuid,integer,text)
  from public,anon,authenticated,service_role;
revoke all on function public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb),
  public.read_canonical_game_state(uuid,integer,text) from public,anon,authenticated;
grant execute on function public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb),
  public.read_canonical_game_state(uuid,integer,text) to service_role;

-- Fence old authenticated lifecycle and reward-ack RPCs for promoted users.
-- Every legacy call takes the same owner lock before a social source lock.
alter function public.create_group_adventure_lobby(text,jsonb) rename to create_group_adventure_lobby_v68;
create function public.create_group_adventure_lobby(p_adventure_id text, p_dragon jsonb)
returns uuid language plpgsql security definer set search_path = '' as $$
begin
  perform private.assert_legacy_inventory_authority();
  return public.create_group_adventure_lobby_v68(p_adventure_id,p_dragon);
end $$;
revoke all on function public.create_group_adventure_lobby_v68(text,jsonb) from public,anon,authenticated,service_role;
revoke all on function public.create_group_adventure_lobby(text,jsonb) from public,anon;
grant execute on function public.create_group_adventure_lobby(text,jsonb) to authenticated;

alter function public.join_group_adventure_lobby(uuid,jsonb) rename to join_group_adventure_lobby_v68;
create function public.join_group_adventure_lobby(p_lobby_id uuid, p_dragon jsonb)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.assert_legacy_inventory_authority();
  perform public.join_group_adventure_lobby_v68(p_lobby_id,p_dragon);
end $$;
revoke all on function public.join_group_adventure_lobby_v68(uuid,jsonb) from public,anon,authenticated,service_role;
revoke all on function public.join_group_adventure_lobby(uuid,jsonb) from public,anon;
grant execute on function public.join_group_adventure_lobby(uuid,jsonb) to authenticated;

alter function public.leave_group_adventure_lobby(uuid) rename to leave_group_adventure_lobby_v68;
create function public.leave_group_adventure_lobby(p_lobby_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.assert_legacy_inventory_authority();
  perform public.leave_group_adventure_lobby_v68(p_lobby_id);
end $$;
revoke all on function public.leave_group_adventure_lobby_v68(uuid) from public,anon,authenticated,service_role;
revoke all on function public.leave_group_adventure_lobby(uuid) from public,anon;
grant execute on function public.leave_group_adventure_lobby(uuid) to authenticated;

alter function public.remove_group_adventure_participant(uuid,uuid) rename to remove_group_adventure_participant_v68;
create function public.remove_group_adventure_participant(p_lobby_id uuid, p_user_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.assert_legacy_inventory_authority();
  perform public.remove_group_adventure_participant_v68(p_lobby_id,p_user_id);
end $$;
revoke all on function public.remove_group_adventure_participant_v68(uuid,uuid) from public,anon,authenticated,service_role;
revoke all on function public.remove_group_adventure_participant(uuid,uuid) from public,anon;
grant execute on function public.remove_group_adventure_participant(uuid,uuid) to authenticated;

alter function public.acknowledge_group_adventure_reward(uuid) rename to acknowledge_group_adventure_reward_v68;
create function public.acknowledge_group_adventure_reward(p_lobby_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.assert_legacy_inventory_authority();
  perform public.acknowledge_group_adventure_reward_v68(p_lobby_id);
end $$;
revoke all on function public.acknowledge_group_adventure_reward_v68(uuid) from public,anon,authenticated,service_role;
revoke all on function public.acknowledge_group_adventure_reward(uuid) from public,anon;
grant execute on function public.acknowledge_group_adventure_reward(uuid) to authenticated;

alter function public.acknowledge_seasonal_pair_adventure_reward(uuid) rename to acknowledge_seasonal_pair_adventure_reward_v68;
create function public.acknowledge_seasonal_pair_adventure_reward(p_adventure_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.assert_legacy_inventory_authority();
  perform public.acknowledge_seasonal_pair_adventure_reward_v68(p_adventure_id);
end $$;
revoke all on function public.acknowledge_seasonal_pair_adventure_reward_v68(uuid) from public,anon,authenticated,service_role;
revoke all on function public.acknowledge_seasonal_pair_adventure_reward(uuid) from public,anon;
grant execute on function public.acknowledge_seasonal_pair_adventure_reward(uuid) to authenticated;

alter function public.acknowledge_seasonal_event_prize(uuid) rename to acknowledge_seasonal_event_prize_v68;
create function public.acknowledge_seasonal_event_prize(p_prize_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.assert_legacy_inventory_authority();
  perform public.acknowledge_seasonal_event_prize_v68(p_prize_id);
end $$;
revoke all on function public.acknowledge_seasonal_event_prize_v68(uuid) from public,anon,authenticated,service_role;
revoke all on function public.acknowledge_seasonal_event_prize(uuid) from public,anon;
grant execute on function public.acknowledge_seasonal_event_prize(uuid) to authenticated;

alter function public.invite_seasonal_pair_adventure(text,text,integer,integer,integer) rename to invite_seasonal_pair_adventure_v68;
create function public.invite_seasonal_pair_adventure(p_keeper_code text, p_dragon_id text, p_might integer, p_arcana integer, p_spirit integer)
returns uuid language plpgsql security definer set search_path = '' as $$
begin
  perform private.assert_legacy_inventory_authority();
  return public.invite_seasonal_pair_adventure_v68(p_keeper_code,p_dragon_id,p_might,p_arcana,p_spirit);
end $$;
revoke all on function public.invite_seasonal_pair_adventure_v68(text,text,integer,integer,integer) from public,anon,authenticated,service_role;
revoke all on function public.invite_seasonal_pair_adventure(text,text,integer,integer,integer) from public,anon;
grant execute on function public.invite_seasonal_pair_adventure(text,text,integer,integer,integer) to authenticated;

alter function public.respond_seasonal_pair_adventure(uuid,boolean,text,integer,integer,integer) rename to respond_seasonal_pair_adventure_v68;
create function public.respond_seasonal_pair_adventure(p_adventure_id uuid, p_accept boolean, p_dragon_id text default null, p_might integer default 0, p_arcana integer default 0, p_spirit integer default 0)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.assert_legacy_inventory_authority();
  perform public.respond_seasonal_pair_adventure_v68(p_adventure_id,p_accept,p_dragon_id,p_might,p_arcana,p_spirit);
end $$;
revoke all on function public.respond_seasonal_pair_adventure_v68(uuid,boolean,text,integer,integer,integer) from public,anon,authenticated,service_role;
revoke all on function public.respond_seasonal_pair_adventure(uuid,boolean,text,integer,integer,integer) from public,anon;
grant execute on function public.respond_seasonal_pair_adventure(uuid,boolean,text,integer,integer,integer) to authenticated;

alter function public.start_seasonal_pair_adventure(uuid) rename to start_seasonal_pair_adventure_v68;
create function public.start_seasonal_pair_adventure(p_adventure_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.assert_legacy_inventory_authority();
  perform public.start_seasonal_pair_adventure_v68(p_adventure_id);
end $$;
revoke all on function public.start_seasonal_pair_adventure_v68(uuid) from public,anon,authenticated,service_role;
revoke all on function public.start_seasonal_pair_adventure(uuid) from public,anon;
grant execute on function public.start_seasonal_pair_adventure(uuid) to authenticated;

