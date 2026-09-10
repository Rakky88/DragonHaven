-- Canonical group membership uses only reconciled server dragon facts. The
-- command receipt, owned dragon reservation and shared lobby change commit
-- together. Existing duration, weekly offer and chest probabilities are kept.
alter table public.group_adventure_lobbies
  add column canonical_owned boolean not null default false;

create function private.canonical_group_keeper_ready(p_owner_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from private.canonical_game_states g
    join private.canonical_social_projections p on p.owner_id=g.owner_id
      and p.revision=g.revision and p.state_sha256=g.state_sha256
    join public.player_economy_authority a on a.user_id=g.owner_id
    cross join private.game_engine_runtime r
    where g.owner_id=p_owner_id and g.is_prepared and r.singleton and
      ((g.authority_mode='server' and a.authority_mode='server') or
        (g.authority_mode='shadow' and r.shadow_lifecycle_enabled and r.shadow_projection_enabled)))
$$;

-- Include the prospective join target in the same global source ordering as
-- the keeper's existing trips; otherwise two groups can acquire reversed locks.
create function private.lock_canonical_social_sources(p_owner_id uuid,p_extra_group uuid default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.assert_game_service();
  perform l.id from public.group_adventure_lobbies l
    where l.id=p_extra_group or exists(select 1 from public.group_adventure_participants p
      where p.lobby_id=l.id and p.user_id=p_owner_id and p.reward_acknowledged_at is null
        and ((l.status='waiting' and l.slot=private.group_adventure_slot(clock_timestamp()))
          or l.status in ('running','completed')))
    order by l.id for update;
  perform a.id from public.seasonal_pair_adventures a
    where p_owner_id in (a.creator_id,a.partner_id)
      and a.status in ('invited','accepted','running','reward_ready','completed')
    order by a.id for update;
end $$;

create function private.guard_canonical_group_lobby()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if coalesce(auth.role(),'')<>'service_role' then
    if tg_op='DELETE' and old.canonical_owned then
      -- The existing server-clock maintenance may expire an old waiting slot.
      if old.status<>'waiting' or old.slot>=private.group_adventure_slot(now()) then
        raise exception 'economy_server_inventory_required'; end if;
    elsif tg_op='INSERT' and new.canonical_owned then
      raise exception 'economy_server_inventory_required';
    elsif tg_op='UPDATE' and (old.canonical_owned or new.canonical_owned) then
      -- Read-side maintenance can mark an already-finished trip ready. It may
      -- not change participants, prices, eligibility, timing or its chest roll.
      if old.status<>'running' or new.status<>'completed' or old.ends_at>now()
          or new.completed_at is null or new.completed_at<old.ends_at or new.completed_at>clock_timestamp()
          or (to_jsonb(old)-array['status','completed_at','updated_at'])<>
             (to_jsonb(new)-array['status','completed_at','updated_at']) then
        raise exception 'economy_server_inventory_required'; end if;
    end if;
  end if;
  if tg_op='DELETE' then return old; else return new; end if;
end $$;
create trigger canonical_group_lobby_write before insert or update or delete on public.group_adventure_lobbies
  for each row execute function private.guard_canonical_group_lobby();

create function private.guard_canonical_group_participant()
returns trigger language plpgsql security definer set search_path = '' as $$
declare previous_source uuid; next_source uuid;
begin
  if coalesce(auth.role(),'')<>'service_role' then
    if tg_op<>'INSERT' then previous_source:=old.lobby_id; end if;
    if tg_op<>'DELETE' then next_source:=new.lobby_id; end if;
    if exists(select 1 from public.group_adventure_lobbies where id in (previous_source,next_source) and canonical_owned) then
      raise exception 'economy_server_inventory_required'; end if;
  end if;
  if tg_op='DELETE' then return old; else return new; end if;
end $$;
create trigger canonical_group_participant_write before insert or update or delete on public.group_adventure_participants
  for each row execute function private.guard_canonical_group_participant();

create or replace function private.refresh_group_adventures()
returns void language plpgsql security definer set search_path = '' as $$
declare current_slot bigint:=private.group_adventure_slot(now());
begin
  perform id from public.group_adventure_lobbies
    where (status='waiting' and slot<current_slot) or (status='running' and ends_at<=now())
    order by id for update;
  delete from public.group_adventure_lobbies where status='waiting' and slot<current_slot;
  update public.group_adventure_lobbies set status='completed',completed_at=coalesce(completed_at,now())
    where status='running' and ends_at<=now();
end $$;

create function private.canonical_group_lifecycle_context(
  p_owner_id uuid,p_action text,p_payload jsonb,p_at timestamptz,p_source_id uuid default null
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_source uuid; v_slot bigint:=private.group_adventure_slot(p_at); v_adventure text;
  v_lobby public.group_adventure_lobbies%rowtype; v_dragon public.player_dragons%rowtype;
  v_participant public.group_adventure_participants%rowtype; v_target uuid;
  v_members jsonb; v_facts jsonb; v_selected jsonb; v_raw_dragon jsonb; v_state jsonb;
begin
  perform private.assert_game_service();
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0));
  if not private.canonical_group_keeper_ready(p_owner_id) or p_at is null
      or p_action not in ('create_group_adventure','join_group_adventure','leave_group_adventure','remove_group_adventure_member') then
    raise exception 'game_action_unavailable'; end if;
  select state into v_state from private.canonical_game_states where owner_id=p_owner_id;
  if v_state->'_activeGameAttempt' is not null and v_state->'_activeGameAttempt'<>'null'::jsonb then
    raise exception 'game_action_unavailable'; end if;
  if p_action='create_group_adventure' then
    v_source:=coalesce(p_source_id,gen_random_uuid());
    v_adventure:=private.group_adventure_id(v_slot);
    if p_payload->>'adventureId' is distinct from v_adventure
        or exists(select 1 from public.group_adventure_lobbies where id=v_source or (owner_id=p_owner_id and slot=v_slot)) then
      raise exception 'game_action_unavailable'; end if;
  else
    v_source:=(p_payload->>'lobbyId')::uuid;
    if v_source is null or (p_source_id is not null and p_source_id<>v_source) then
      raise exception 'game_action_unavailable'; end if;
    perform private.lock_canonical_social_sources(p_owner_id,v_source);
    select * into v_lobby from public.group_adventure_lobbies where id=v_source for update;
    if not found or v_lobby.status<>'waiting' or v_lobby.slot<>v_slot then
      raise exception 'game_action_unavailable'; end if;
    v_adventure:=v_lobby.adventure_id;
  end if;
  if p_action in ('create_group_adventure','join_group_adventure') then
    if exists(select 1 from public.group_adventure_participants p join public.group_adventure_lobbies l on l.id=p.lobby_id
        where p.user_id=p_owner_id and l.slot=v_slot and l.status in ('waiting','running','completed')) then
      raise exception 'game_action_unavailable'; end if;
    select * into v_dragon from public.player_dragons where owner_id=p_owner_id
      and legacy_client_id=p_payload->>'dragonId' and canonical_owned;
    if not found then raise exception 'game_action_unavailable'; end if;
    select d into v_raw_dragon from jsonb_array_elements(jsonb_build_array(v_state->'pet')||(v_state->'sanctuaryDragons')) d
      where d->>'id'=v_dragon.legacy_client_id and d->>'stage'<>'egg';
    if v_raw_dragon is null or
        (v_raw_dragon->>'activeAdventureId' is not null and
          v_raw_dragon->>'activeAdventureId' not like 'online-group:%' and
          v_raw_dragon->>'activeAdventureId' not like 'online-seasonal:%')
        or exists(select 1 from jsonb_array_elements(private.canonical_social_reservations(p_owner_id,p_at,false)->'reservations') r
          where r->>'dragonId'=v_dragon.legacy_client_id) then
      raise exception 'game_action_unavailable'; end if;
    if p_action='join_group_adventure' then
      if not private.trade_users_are_friends(p_owner_id,v_lobby.owner_id)
          or (select count(*) from public.group_adventure_participants where lobby_id=v_source)>=v_lobby.required_players
          or exists(select 1 from public.group_adventure_participants p join public.player_dragons d on d.id=p.dragon_id
            where p.lobby_id=v_source and (not d.canonical_owned or not private.canonical_group_keeper_ready(p.user_id))) then
        raise exception 'game_action_unavailable'; end if;
    end if;
  else
    v_target:=case when p_action='remove_group_adventure_member' then (p_payload->>'memberId')::uuid else p_owner_id end;
    if v_target is null or (p_action='remove_group_adventure_member' and
        (v_lobby.owner_id<>p_owner_id or v_target=p_owner_id)) then raise exception 'game_action_unavailable'; end if;
    select * into v_participant from public.group_adventure_participants
      where lobby_id=v_source and user_id=v_target for update;
    if not found then raise exception 'game_action_unavailable'; end if;
    select * into v_dragon from public.player_dragons where id=v_participant.dragon_id and owner_id=v_target;
    if not found then raise exception 'game_action_unavailable'; end if;
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('userId',p.user_id,'dragonId',d.id,
      'xp',d.xp,'might',d.might,'arcana',d.arcana,'spirit',d.spirit) order by p.user_id),'[]'::jsonb)
    into v_members from public.group_adventure_participants p join public.player_dragons d on d.id=p.dragon_id
    where p.lobby_id=v_source;
  v_selected:=jsonb_build_object('id',v_dragon.id,'xp',v_dragon.xp,'might',v_dragon.might,'arcana',v_dragon.arcana,'spirit',v_dragon.spirit);
  v_facts:=jsonb_build_object('adventureId',v_adventure,'dragonId',v_dragon.legacy_client_id,
    'memberId',case when p_action='remove_group_adventure_member' then v_target else null end);
  return jsonb_build_object('version',1,'ownerId',p_owner_id,'action',p_action,'sourceId',v_source,'facts',v_facts,
    'fingerprint',private.game_json_sha256(jsonb_build_object('ownerId',p_owner_id,'action',p_action,
      'sourceId',v_source,'facts',v_facts,'slot',v_slot,'selectedDragon',v_selected,'members',v_members,
      'lobby',to_jsonb(v_lobby)-array['created_at','updated_at'])));
exception when invalid_text_representation then raise exception 'game_action_unavailable';
end $$;

create function private.commit_canonical_group_lifecycle(
  p_owner_id uuid,p_action text,p_payload jsonb,p_context jsonb,p_result jsonb,p_at timestamptz
) returns void language plpgsql security definer set search_path = '' as $$
declare v_source uuid:=(p_context->>'sourceId')::uuid; v_index integer; v_days integer; v_dragon uuid;
begin
  perform private.assert_game_service();
  if p_result is distinct from jsonb_build_object('accepted',true,'sourceId',v_source) then
    raise exception 'game_social_state_changed'; end if;
  if p_action in ('create_group_adventure','join_group_adventure') then
    select id into v_dragon from public.player_dragons where owner_id=p_owner_id
      and legacy_client_id=p_context->'facts'->>'dragonId' and canonical_owned;
    if v_dragon is null then raise exception 'game_social_state_changed'; end if;
  end if;
  if p_action='create_group_adventure' then
    v_index:=substring(p_context->'facts'->>'adventureId' from 7)::integer-1;
    v_days:=3+v_index%4;
    insert into public.group_adventure_lobbies(id,slot,adventure_id,owner_id,required_players,focus,
      base_duration_minutes,xp,stat_points,combined_level_required,combined_stat_required,canonical_owned)
      values(v_source,private.group_adventure_slot(p_at),p_context->'facts'->>'adventureId',p_owner_id,
        2+v_index%3,(array['might','arcana','spirit'])[(v_index+2)%3+1],v_days*1440,
        360+v_days*175+v_index%59,52+v_days*13+v_index%9,
        case when v_index%4=0 then 8+v_index%20 else 0 end,
        case when v_index%3=0 then 50+v_index%150 else 0 end,true);
    insert into public.group_adventure_participants(lobby_id,user_id,dragon_id) values(v_source,p_owner_id,v_dragon);
  elsif p_action='join_group_adventure' then
    update public.group_adventure_lobbies set canonical_owned=true where id=v_source;
    insert into public.group_adventure_participants(lobby_id,user_id,dragon_id) values(v_source,p_owner_id,v_dragon);
    perform private.try_start_group_adventure(v_source);
  elsif p_action='leave_group_adventure' then
    if exists(select 1 from public.group_adventure_lobbies where id=v_source and owner_id=p_owner_id) then
      delete from public.group_adventure_lobbies where id=v_source;
    else
      delete from public.group_adventure_participants where lobby_id=v_source and user_id=p_owner_id;
    end if;
  elsif p_action='remove_group_adventure_member' then
    delete from public.group_adventure_participants where lobby_id=v_source and user_id=(p_payload->>'memberId')::uuid;
  else raise exception 'game_social_state_changed';
  end if;
end $$;

alter function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint)
  rename to begin_revisioned_game_command_v70;
create function public.begin_revisioned_game_command(
  p_owner_id uuid,p_request_id uuid,p_action text,p_payload jsonb,p_client_build integer,
  p_ruleset_sha256 text,p_expected_revision bigint
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare leased jsonb; context_value jsonb; target_group uuid;
begin
  perform private.assert_game_service();
  if p_owner_id is null then raise exception 'game_request_invalid'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0));
  if p_action in ('join_group_adventure','leave_group_adventure','remove_group_adventure_member') then
    begin target_group:=(p_payload->>'lobbyId')::uuid;
    exception when invalid_text_representation then raise exception 'game_request_invalid'; end;
    perform private.lock_canonical_social_sources(p_owner_id,target_group);
  end if;
  leased:=public.begin_revisioned_game_command_v70(p_owner_id,p_request_id,p_action,p_payload,
    p_client_build,p_ruleset_sha256,p_expected_revision);
  if leased->>'status'<>'processing' or p_action not in
      ('create_group_adventure','join_group_adventure','leave_group_adventure','remove_group_adventure_member') then return leased; end if;
  select social_context into context_value from private.canonical_game_intents where owner_id=p_owner_id and request_id=p_request_id;
  if context_value is null then
    begin
      context_value:=private.canonical_group_lifecycle_context(p_owner_id,p_action,p_payload,(leased->>'now')::timestamptz);
    exception when raise_exception then
      if sqlerrm<>'game_action_unavailable' then raise; end if;
      if not public.fail_canonical_game_command(p_owner_id,p_request_id,(leased->>'lease_token')::uuid,'game_action_unavailable') then
        raise exception 'game_lease_lost'; end if;
      return jsonb_build_object('status','failed','failure_code','game_action_unavailable','response',null,'replayed',false);
    end;
    update private.canonical_game_intents set social_context=context_value where owner_id=p_owner_id and request_id=p_request_id;
  end if;
  return leased||jsonb_build_object('social_context',context_value);
end $$;

alter function public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb) rename to commit_canonical_game_command_v70;
create function public.commit_canonical_game_command(p_owner_id uuid,p_request_id uuid,p_lease_token uuid,p_state jsonb,p_result jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare intent private.canonical_game_intents%rowtype; current_context jsonb; receipt jsonb;
  at_time timestamptz:=clock_timestamp(); target_group uuid;
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_request_id is null or p_lease_token is null then raise exception 'game_request_invalid'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0));
  select * into intent from private.canonical_game_intents where owner_id=p_owner_id and request_id=p_request_id for update;
  if not found or intent.lease_token<>p_lease_token then raise exception 'game_lease_lost'; end if;
  if intent.status<>'processing' or intent.action not in
      ('create_group_adventure','join_group_adventure','leave_group_adventure','remove_group_adventure_member') then
    return public.commit_canonical_game_command_v70(p_owner_id,p_request_id,p_lease_token,p_state,p_result); end if;
  if intent.leased_until<=at_time then raise exception 'game_lease_lost'; end if;
  if intent.action<>'create_group_adventure' then target_group:=(intent.payload->>'lobbyId')::uuid; end if;
  perform private.lock_canonical_social_sources(p_owner_id,target_group);
  begin
    current_context:=private.canonical_group_lifecycle_context(p_owner_id,intent.action,intent.payload,at_time,
      (intent.social_context->>'sourceId')::uuid);
  exception when raise_exception then
    if sqlerrm='game_action_unavailable' then raise exception 'game_social_state_changed'; end if; raise;
  end;
  if current_context is distinct from intent.social_context then raise exception 'game_social_state_changed'; end if;
  -- The original commit validates the frozen reservations before membership
  -- changes. A later failure rolls back its receipt, revision and projections.
  receipt:=public.commit_canonical_game_command_v70(p_owner_id,p_request_id,p_lease_token,p_state,p_result);
  perform private.commit_canonical_group_lifecycle(p_owner_id,intent.action,intent.payload,intent.social_context,p_result,at_time);
  return receipt;
end $$;

revoke all on function private.canonical_group_keeper_ready(uuid),
  private.lock_canonical_social_sources(uuid,uuid),private.guard_canonical_group_lobby(),
  private.guard_canonical_group_participant(),private.canonical_group_lifecycle_context(uuid,text,jsonb,timestamptz,uuid),
  private.commit_canonical_group_lifecycle(uuid,text,jsonb,jsonb,jsonb,timestamptz),
  public.begin_revisioned_game_command_v70(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command_v70(uuid,uuid,uuid,jsonb,jsonb) from public,anon,authenticated,service_role;
revoke all on function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb) from public,anon,authenticated;
grant execute on function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb) to service_role;

create or replace function private.canonical_social_reservations(p_owner_id uuid,p_at timestamptz,p_lock boolean)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare entries jsonb; slot_value bigint;
begin
  perform private.assert_game_service();
  if not exists(select 1 from private.canonical_game_states g cross join private.game_engine_runtime r
      where g.owner_id=p_owner_id and g.is_prepared and r.singleton
        and (g.authority_mode='server' or r.shadow_lifecycle_enabled)) then return null; end if;
  slot_value := private.group_adventure_slot(p_at);
  if p_lock then
    perform private.lock_canonical_social_sources(p_owner_id,null);
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
