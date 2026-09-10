-- Partner invitations reserve real owned dragons. Both keeper locks precede
-- source locks; one receipt commits eligibility, membership and shared timing.
alter table public.seasonal_pair_adventures add column canonical_owned boolean not null default false;

create function private.lock_canonical_pair_keepers(p_owner uuid,p_action text,p_payload jsonb)
returns void language plpgsql security definer set search_path='' as $$
declare other_keeper uuid; keeper uuid;
begin
  perform private.assert_game_service();
  if p_owner is null then raise exception 'game_request_invalid'; end if;
  if p_action='invite_pair_adventure' then
    select user_id into other_keeper from public.profiles where keeper_code=upper(trim(p_payload->>'keeperCode'));
  else
    select case when creator_id=p_owner then partner_id else creator_id end into other_keeper
      from public.seasonal_pair_adventures where id=(p_payload->>'adventureId')::uuid
        and p_owner in (creator_id,partner_id);
  end if;
  for keeper in select distinct value from unnest(array[p_owner,other_keeper]) value
      where value is not null order by value loop
    perform pg_advisory_xact_lock(hashtextextended(keeper::text,0));
  end loop;
exception when invalid_text_representation then raise exception 'game_request_invalid';
end $$;

create function private.canonical_pair_window(p_owner uuid,p_at timestamptz)
returns jsonb language plpgsql security definer set search_path='' as $$
declare preview public.seasonal_event_previews%rowtype; window_row record;
begin
  select * into preview from public.seasonal_event_previews where user_id=p_owner and expires_at>p_at
    order by activated_at desc,event_id limit 1;
  if found then
    if preview.event_id<>'valentine_two_heartlights' then raise exception 'game_action_unavailable'; end if;
    return jsonb_build_object('occurrenceKey','preview:valentine_two_heartlights:'||p_owner::text,
      'simulated',true,'expiresAt',preview.expires_at);
  end if;
  if exists(select 1 from public.seasonal_event_dismissals where user_id=p_owner
      and event_id='valentine_two_heartlights' and expires_at>p_at) then raise exception 'game_action_unavailable'; end if;
  select * into window_row from public.seasonal_event_window('valentine_two_heartlights',p_at);
  if window_row.occurrence_key is null or p_at<window_row.starts_at or p_at>=window_row.ends_at then
    raise exception 'game_action_unavailable'; end if;
  return jsonb_build_object('occurrenceKey',window_row.occurrence_key,'simulated',false,'expiresAt',window_row.ends_at);
end $$;

create function private.canonical_pair_dragon(p_owner uuid,p_dragon text,p_source uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare dragon public.player_dragons%rowtype; raw_dragon jsonb; game_state jsonb; bindings jsonb;
begin
  if not private.canonical_group_keeper_ready(p_owner) then raise exception 'game_action_unavailable'; end if;
  select state into game_state from private.canonical_game_states where owner_id=p_owner;
  if game_state->'_activeGameAttempt' is not null and game_state->'_activeGameAttempt'<>'null'::jsonb then
    raise exception 'game_action_unavailable'; end if;
  select * into dragon from public.player_dragons where owner_id=p_owner and legacy_client_id=p_dragon and canonical_owned;
  if not found then raise exception 'game_action_unavailable'; end if;
  select d into raw_dragon from jsonb_array_elements(jsonb_build_array(game_state->'pet')||coalesce(game_state->'sanctuaryDragons','[]')) d
    where d->>'id'=p_dragon and d->>'stage'<>'egg';
  if raw_dragon is null or (raw_dragon->>'activeAdventureId' is not null
      and raw_dragon->>'activeAdventureId' not like 'online-group:%'
      and raw_dragon->>'activeAdventureId' not like 'online-seasonal:%') then raise exception 'game_action_unavailable'; end if;
  bindings:=private.canonical_social_reservations(p_owner,clock_timestamp(),false)->'reservations';
  if p_source is null then
    if exists(select 1 from jsonb_array_elements(bindings) b where b->>'dragonId'=p_dragon) then
      raise exception 'game_action_unavailable'; end if;
  elsif (select count(*) from jsonb_array_elements(bindings) b where b->>'dragonId'=p_dragon)<>1
      or not exists(select 1 from jsonb_array_elements(bindings) b where b->>'dragonId'=p_dragon
        and b->>'kind'='pair' and b->>'sourceId'=p_source::text) then raise exception 'game_action_unavailable';
  end if;
  return jsonb_build_object('id',dragon.legacy_client_id,'xp',dragon.xp,
    'might',dragon.might,'arcana',dragon.arcana,'spirit',dragon.spirit);
end $$;

create function private.canonical_pair_lifecycle_context(p_owner uuid,p_action text,p_payload jsonb,p_at timestamptz,p_source uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare source_id uuid; other_keeper uuid; other_code text; dragon_id text; keeper_role text;
  pair public.seasonal_pair_adventures%rowtype; window_value jsonb; facts jsonb;
  selected_dragon jsonb; creator_dragon jsonb; partner_dragon jsonb; game_state jsonb;
begin
  perform private.assert_game_service();
  if p_action not in ('invite_pair_adventure','accept_pair_adventure','decline_pair_adventure','start_pair_adventure','cancel_pair_adventure')
      or not private.canonical_group_keeper_ready(p_owner) then raise exception 'game_action_unavailable'; end if;
  select state into game_state from private.canonical_game_states where owner_id=p_owner;
  if game_state->'_activeGameAttempt' is not null and game_state->'_activeGameAttempt'<>'null'::jsonb then
    raise exception 'game_action_unavailable'; end if;
  -- The caller already acquired both ordered owner locks, before any sources.
  perform private.lock_canonical_social_sources(p_owner,null);
  if p_action='invite_pair_adventure' then
    source_id:=coalesce(p_source,gen_random_uuid());
    select user_id,keeper_code into other_keeper,other_code from public.profiles
      where keeper_code=upper(trim(p_payload->>'keeperCode'));
    if other_keeper is null or other_keeper=p_owner or not private.canonical_group_keeper_ready(other_keeper)
        or exists(select 1 from public.seasonal_pair_adventures where id=source_id)
        or exists(select 1 from public.friendships where status='blocked'
          and least(requester_id,addressee_id)=least(p_owner,other_keeper)
          and greatest(requester_id,addressee_id)=greatest(p_owner,other_keeper)) then
      raise exception 'game_action_unavailable'; end if;
    window_value:=private.canonical_pair_window(p_owner,p_at);
    if exists(select 1 from public.seasonal_pair_occurrences where event_id='valentine_two_heartlights'
        and occurrence_key=window_value->>'occurrenceKey' and user_id in (p_owner,other_keeper))
        or exists(select 1 from public.seasonal_pair_adventures where creator_id=p_owner
          and occurrence_key=window_value->>'occurrenceKey' and status in ('invited','accepted','running','reward_ready')) then
      raise exception 'game_action_unavailable'; end if;
    keeper_role:='creator'; dragon_id:=p_payload->>'dragonId';
    selected_dragon:=private.canonical_pair_dragon(p_owner,dragon_id,null);
  else
    source_id:=(p_payload->>'adventureId')::uuid;
    if source_id is null or (p_source is not null and source_id<>p_source) then raise exception 'game_action_unavailable'; end if;
    select * into pair from public.seasonal_pair_adventures where id=source_id and p_owner in (creator_id,partner_id) for update;
    if not found or not pair.canonical_owned then raise exception 'game_action_unavailable'; end if;
    keeper_role:=case when pair.creator_id=p_owner then 'creator' else 'partner' end;
    other_keeper:=case when pair.creator_id=p_owner then pair.partner_id else pair.creator_id end;
    select keeper_code into other_code from public.profiles where user_id=other_keeper;
    if p_action='cancel_pair_adventure' then
      if pair.status not in ('invited','accepted') then raise exception 'game_action_unavailable'; end if;
      dragon_id:=case when keeper_role='creator' then pair.creator_dragon_id else pair.partner_dragon_id end;
      if dragon_id is not null then selected_dragon:=private.canonical_pair_dragon(p_owner,dragon_id,source_id); end if;
    elsif p_action='decline_pair_adventure' then
      if keeper_role<>'partner' or pair.status<>'invited' then raise exception 'game_action_unavailable'; end if;
    else
      if (p_action='accept_pair_adventure' and (keeper_role<>'partner' or pair.status<>'invited'))
          or (p_action='start_pair_adventure' and (keeper_role<>'creator' or pair.status<>'accepted')) then
        raise exception 'game_action_unavailable'; end if;
      window_value:=private.canonical_pair_window(pair.creator_id,p_at);
      if window_value->>'occurrenceKey'<>pair.occurrence_key or (window_value->>'simulated')::boolean<>pair.simulated
          or exists(select 1 from public.seasonal_pair_occurrences where event_id=pair.event_id
            and occurrence_key=pair.occurrence_key and user_id in (pair.creator_id,pair.partner_id))
          or exists(select 1 from public.friendships where status='blocked'
            and least(requester_id,addressee_id)=least(p_owner,other_keeper)
            and greatest(requester_id,addressee_id)=greatest(p_owner,other_keeper)) then raise exception 'game_action_unavailable'; end if;
      creator_dragon:=private.canonical_pair_dragon(pair.creator_id,pair.creator_dragon_id,source_id);
      if p_action='accept_pair_adventure' then
        dragon_id:=p_payload->>'dragonId';partner_dragon:=private.canonical_pair_dragon(p_owner,dragon_id,null);
        selected_dragon:=partner_dragon;
      else
        dragon_id:=pair.creator_dragon_id;partner_dragon:=private.canonical_pair_dragon(pair.partner_id,pair.partner_dragon_id,source_id);
        selected_dragon:=creator_dragon;
      end if;
    end if;
  end if;
  facts:=jsonb_build_object('eventId','valentine_two_heartlights','dragonId',dragon_id,'otherId',other_keeper,
    'keeperCode',other_code,'role',keeper_role,'occurrenceKey',coalesce(pair.occurrence_key,window_value->>'occurrenceKey'),
    'simulated',coalesce(pair.simulated,(window_value->>'simulated')::boolean));
  return jsonb_build_object('version',1,'ownerId',p_owner,'action',p_action,'sourceId',source_id,'facts',facts,
    'fingerprint',private.game_json_sha256(jsonb_build_object('source',source_id,'action',p_action,'owner',p_owner,
      'facts',facts,'pair',to_jsonb(pair),'selected',selected_dragon,'creator',creator_dragon,'partner',partner_dragon,'window',window_value)));
exception when invalid_text_representation then raise exception 'game_action_unavailable';
end $$;

create function private.commit_canonical_pair_lifecycle(p_owner uuid,p_action text,p_payload jsonb,p_context jsonb,p_result jsonb,p_at timestamptz)
returns void language plpgsql security definer set search_path='' as $$
declare source_id uuid:=(p_context->>'sourceId')::uuid; facts jsonb:=p_context->'facts';
  pair public.seasonal_pair_adventures%rowtype; dragon public.player_dragons%rowtype;
  other_dragon public.player_dragons%rowtype; trip_minutes integer;
begin
  perform private.assert_game_service();
  if p_result is distinct from jsonb_build_object('accepted',true,'sourceId',source_id) then raise exception 'game_social_state_changed'; end if;
  if p_action in ('invite_pair_adventure','accept_pair_adventure') then
    select * into dragon from public.player_dragons where owner_id=p_owner and legacy_client_id=facts->>'dragonId' and canonical_owned;
    if not found then raise exception 'game_social_state_changed'; end if;
  end if;
  if p_action='invite_pair_adventure' then
    insert into public.seasonal_pair_adventures(id,occurrence_key,creator_id,partner_id,creator_dragon_id,
      creator_might,creator_arcana,creator_spirit,simulated,canonical_owned)
      values(source_id,facts->>'occurrenceKey',p_owner,(facts->>'otherId')::uuid,dragon.legacy_client_id,
        dragon.might,dragon.arcana,dragon.spirit,(facts->>'simulated')::boolean,true);
    insert into public.social_notifications(user_id,kind,actor_id,entity_id)
      values((facts->>'otherId')::uuid,'seasonal_pair_invite',p_owner,source_id);
  elsif p_action='accept_pair_adventure' then
    update public.seasonal_pair_adventures set status='accepted',partner_dragon_id=dragon.legacy_client_id,
      partner_might=dragon.might,partner_arcana=dragon.arcana,partner_spirit=dragon.spirit,accepted_at=p_at where id=source_id;
    insert into public.social_notifications(user_id,kind,actor_id,entity_id)
      values((facts->>'otherId')::uuid,'seasonal_pair_accepted',p_owner,source_id);
  elsif p_action in ('decline_pair_adventure','cancel_pair_adventure') then
    update public.seasonal_pair_adventures set status='declined' where id=source_id;
  elsif p_action='start_pair_adventure' then
    select * into pair from public.seasonal_pair_adventures where id=source_id;
    select * into dragon from public.player_dragons where owner_id=pair.creator_id and legacy_client_id=pair.creator_dragon_id and canonical_owned;
    select * into other_dragon from public.player_dragons where owner_id=pair.partner_id and legacy_client_id=pair.partner_dragon_id and canonical_owned;
    if dragon.id is null or other_dragon.id is null then raise exception 'game_social_state_changed'; end if;
    insert into public.seasonal_pair_occurrences(event_id,occurrence_key,user_id,adventure_id) values
      (pair.event_id,pair.occurrence_key,pair.creator_id,source_id),(pair.event_id,pair.occurrence_key,pair.partner_id,source_id);
    trip_minutes:=greatest(1440,5760-(dragon.might+dragon.arcana+dragon.spirit+other_dragon.might+other_dragon.arcana+other_dragon.spirit)*15);
    update public.seasonal_pair_adventures set status='running',started_at=p_at,ends_at=p_at+make_interval(mins=>trip_minutes),
      creator_might=dragon.might,creator_arcana=dragon.arcana,creator_spirit=dragon.spirit,
      partner_might=other_dragon.might,partner_arcana=other_dragon.arcana,partner_spirit=other_dragon.spirit where id=source_id;
  else raise exception 'game_social_state_changed'; end if;
end $$;

create function private.guard_canonical_pair_write()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if coalesce(auth.role(),'')<>'service_role' then
    if tg_op='DELETE' and old.canonical_owned then
      -- Auth removal may cascade after its parent has already disappeared.
      if exists(select 1 from auth.users where id=old.creator_id)
          and exists(select 1 from auth.users where id=old.partner_id) then raise exception 'economy_server_inventory_required'; end if;
    elsif tg_op='INSERT' and new.canonical_owned then raise exception 'economy_server_inventory_required';
    elsif tg_op='UPDATE' and (old.canonical_owned or new.canonical_owned) then
      if old.status<>'running' or new.status<>'reward_ready' or old.ends_at>now()
          or (to_jsonb(old)-'status')<>(to_jsonb(new)-'status') then raise exception 'economy_server_inventory_required'; end if;
    end if;
  end if;
  if tg_op='DELETE' then return old; else return new; end if;
end $$;
create trigger canonical_pair_write before insert or update or delete on public.seasonal_pair_adventures
  for each row execute function private.guard_canonical_pair_write();

alter function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint)
  rename to begin_revisioned_game_command_v71;
create function public.begin_revisioned_game_command(
  p_owner_id uuid,p_request_id uuid,p_action text,p_payload jsonb,p_client_build integer,
  p_ruleset_sha256 text,p_expected_revision bigint
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare leased jsonb; context_value jsonb;
begin
  perform private.assert_game_service();
  if p_owner_id is null then raise exception 'game_request_invalid'; end if;
  if p_action in ('invite_pair_adventure','accept_pair_adventure','decline_pair_adventure','start_pair_adventure','cancel_pair_adventure') then
    perform private.lock_canonical_pair_keepers(p_owner_id,p_action,p_payload);
  end if;
  leased:=public.begin_revisioned_game_command_v71(p_owner_id,p_request_id,p_action,p_payload,
    p_client_build,p_ruleset_sha256,p_expected_revision);
  if leased->>'status'<>'processing' or p_action not in
      ('invite_pair_adventure','accept_pair_adventure','decline_pair_adventure','start_pair_adventure','cancel_pair_adventure') then return leased; end if;
  select social_context into context_value from private.canonical_game_intents where owner_id=p_owner_id and request_id=p_request_id;
  if context_value is null then
    begin
      context_value:=private.canonical_pair_lifecycle_context(p_owner_id,p_action,p_payload,(leased->>'now')::timestamptz);
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

alter function public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb) rename to commit_canonical_game_command_v71;
create function public.commit_canonical_game_command(p_owner_id uuid,p_request_id uuid,p_lease_token uuid,p_state jsonb,p_result jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare intent private.canonical_game_intents%rowtype; current_context jsonb; receipt jsonb;
  at_time timestamptz:=clock_timestamp();
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_request_id is null or p_lease_token is null then raise exception 'game_request_invalid'; end if;
  select * into intent from private.canonical_game_intents where owner_id=p_owner_id and request_id=p_request_id;
  if not found or intent.lease_token<>p_lease_token then raise exception 'game_lease_lost'; end if;
  if intent.status<>'processing' or intent.action not in ('invite_pair_adventure','accept_pair_adventure','decline_pair_adventure','start_pair_adventure','cancel_pair_adventure') then
    return public.commit_canonical_game_command_v71(p_owner_id,p_request_id,p_lease_token,p_state,p_result); end if;
  perform private.lock_canonical_pair_keepers(p_owner_id,intent.action,intent.payload);
  select * into intent from private.canonical_game_intents where owner_id=p_owner_id and request_id=p_request_id for update;
  if intent.status<>'processing' or intent.lease_token<>p_lease_token or intent.leased_until<=at_time then
    raise exception 'game_lease_lost'; end if;
  begin
    current_context:=private.canonical_pair_lifecycle_context(p_owner_id,intent.action,intent.payload,at_time,
      (intent.social_context->>'sourceId')::uuid);
  exception when raise_exception then
    if sqlerrm='game_action_unavailable' then raise exception 'game_social_state_changed'; end if; raise;
  end;
  if current_context is distinct from intent.social_context then raise exception 'game_social_state_changed'; end if;
  -- The original commit validates the frozen reservations before membership
  -- changes. A later failure rolls back its receipt, revision and projections.
  receipt:=public.commit_canonical_game_command_v71(p_owner_id,p_request_id,p_lease_token,p_state,p_result);
  perform private.commit_canonical_pair_lifecycle(p_owner_id,intent.action,intent.payload,intent.social_context,p_result,at_time);
  return receipt;
end $$;

revoke all on function private.lock_canonical_pair_keepers(uuid,text,jsonb),
  private.canonical_pair_window(uuid,timestamptz),private.canonical_pair_dragon(uuid,text,uuid),
  private.canonical_pair_lifecycle_context(uuid,text,jsonb,timestamptz,uuid),
  private.commit_canonical_pair_lifecycle(uuid,text,jsonb,jsonb,jsonb,timestamptz),private.guard_canonical_pair_write(),
  public.begin_revisioned_game_command_v71(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command_v71(uuid,uuid,uuid,jsonb,jsonb) from public,anon,authenticated,service_role;
revoke all on function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb) from public,anon,authenticated;
grant execute on function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb) to service_role;

-- Available only for the authenticated canonical keeper; read-only offer data.
create function public.get_canonical_pair_offer()
returns boolean language plpgsql security definer set search_path='' as $$
declare keeper uuid:=auth.uid(); window_value jsonb;
begin
  if keeper is null or not private.canonical_group_keeper_ready(keeper) then return false; end if;
  begin window_value:=private.canonical_pair_window(keeper,now());
  exception when raise_exception then if sqlerrm='game_action_unavailable' then return false; else raise; end if; end;
  return not exists(select 1 from public.seasonal_pair_occurrences where event_id='valentine_two_heartlights'
      and occurrence_key=window_value->>'occurrenceKey' and user_id=keeper)
    and not exists(select 1 from public.seasonal_pair_adventures where creator_id=keeper
      and occurrence_key=window_value->>'occurrenceKey' and status in ('invited','accepted','running','reward_ready'));
end $$;
revoke all on function public.get_canonical_pair_offer() from public,anon,service_role;
grant execute on function public.get_canonical_pair_offer() to authenticated;
