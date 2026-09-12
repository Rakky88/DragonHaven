-- Preserve event schedules, authorities and all earned points. Each accepted
-- friend retains their own preview occurrence key and chest entitlement.
create or replace function private.event_partner_progress(p_owner uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare pair record; own_state jsonb := private.event_point_state(p_owner);
  other_state jsonb; own_progress jsonb; other_progress jsonb; result jsonb := '[]';
  own_key text; other_key text;
begin
  for pair in select * from private.event_point_pairs where status='accepted'
    and p_owner in (creator_id,partner_id) loop
    other_state:=private.event_point_state(case when pair.creator_id=p_owner then pair.partner_id else pair.creator_id end);
    select event_key into own_key from private.event_point_pair_members
      where pair_id=pair.id and owner_id=p_owner;
    select event_key into other_key from private.event_point_pair_members
      where pair_id=pair.id and owner_id<>p_owner;
    own_progress:=own_state->'eventProgress'->coalesce(own_key,pair.event_key);
    other_progress:=other_state->'eventProgress'->coalesce(other_key,pair.event_key);
    if other_progress is null then continue; end if;
    if own_progress is null then
      own_progress:=other_progress||jsonb_build_object('points',0,'partnerPoints',0,'claimed',false);
    end if;
    result:=result||jsonb_build_array(own_progress||jsonb_build_object('partnerPoints',
      greatest(coalesce((own_progress->>'partnerPoints')::bigint,0),coalesce((other_progress->>'points')::bigint,0))));
  end loop;
  return jsonb_build_object('version',1,'ownerId',p_owner,'progress',result);
end $$;

create or replace function public.event_point_partner_v80(p_action text default 'list',p_event_key text default null,
  p_keeper_code text default null,p_pair_id uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare keeper uuid := auth.uid(); other_keeper uuid; event jsonb;
  pair private.event_point_pairs%rowtype; new_id uuid; rows jsonb; other_key text;
begin
  if keeper is null then raise exception 'online_login_required'; end if;
  if not exists(select 1 from auth.users where id=keeper and email_confirmed_at is not null) then
    raise exception 'email_not_verified'; end if;
  -- Serialize the tiny event invitation board, including crossed invitations.
  perform pg_advisory_xact_lock(hashtextextended('event-point-partners',0));
  delete from private.event_point_pair_members m using private.event_point_pairs p
    where m.pair_id=p.id and p.status='invited' and p.ends_at<=now();
  if p_action='invite' then
    select user_id into other_keeper from public.profiles where keeper_code=upper(trim(p_keeper_code));
    if other_keeper is null or other_keeper=keeper or not exists(select 1 from public.friendships
      where status='accepted' and ((requester_id=keeper and addressee_id=other_keeper)
        or (requester_id=other_keeper and addressee_id=keeper))) then raise exception 'event_friend_required'; end if;
    if exists(select 1 from private.canonical_game_states where owner_id=keeper and is_prepared and authority_mode='server')
        <> exists(select 1 from private.canonical_game_states where owner_id=other_keeper and is_prepared and authority_mode='server') then
      raise exception 'event_partner_unavailable'; end if;
    event:=private.event_point_state(keeper)->'eventProgress'->p_event_key;
    if event is null or event->>'eventId'<>'valentine_two_heartlights'
      or now()<(event->>'startsAt')::timestamptz or now()>=(event->>'endsAt')::timestamptz then
      raise exception 'event_partner_unavailable'; end if;
    other_key:=p_event_key;
    -- Preview windows are personal. Pair each keeper's own active occurrence;
    -- never combine a production occurrence with a preview or another year.
    if coalesce((event->>'preview')::boolean,false) and p_event_key like '%:preview:%' then
      select e.key into other_key
        from jsonb_each(coalesce(private.event_point_state(other_keeper)->'eventProgress','{}')) e
        where e.value->>'eventId'=event->>'eventId'
          and coalesce((e.value->>'preview')::boolean,false)
          and e.key like '%:preview:%'
          and e.value->>'target'=event->>'target'
          and now()>=(e.value->>'startsAt')::timestamptz
          and now()<(e.value->>'endsAt')::timestamptz
        order by (e.value->>'startsAt')::timestamptz desc limit 1;
      other_key:=coalesce(other_key,p_event_key);
    end if;
    if exists(select 1 from private.event_point_pair_members
      where (owner_id=keeper and event_key=p_event_key)
         or (owner_id=other_keeper and event_key=other_key)) then raise exception 'event_partner_already_selected'; end if;
    insert into private.event_point_pairs(creator_id,partner_id,event_key,ends_at)
      values(keeper,other_keeper,p_event_key,(event->>'endsAt')::timestamptz) returning id into new_id;
    insert into private.event_point_pair_members values(keeper,p_event_key,new_id),(other_keeper,other_key,new_id);
  elsif p_action in ('accept','decline') then
    select * into pair from private.event_point_pairs where id=p_pair_id for update;
    if not found or pair.partner_id<>keeper or pair.status<>'invited' or pair.ends_at<=now() then
      raise exception 'event_invitation_unavailable'; end if;
    if p_action='accept' then
      if not exists(select 1 from public.friendships where status='accepted'
        and ((requester_id=pair.creator_id and addressee_id=keeper)
          or (requester_id=keeper and addressee_id=pair.creator_id))) then raise exception 'event_friend_required'; end if;
      update private.event_point_pairs set status='accepted' where id=pair.id;
    else
      update private.event_point_pairs set status='declined' where id=pair.id;
      delete from private.event_point_pair_members where pair_id=pair.id;
    end if;
  elsif p_action='cancel' then
    select * into pair from private.event_point_pairs where id=p_pair_id for update;
    if not found or pair.creator_id<>keeper or pair.status<>'invited' then raise exception 'event_invitation_unavailable'; end if;
    update private.event_point_pairs set status='declined' where id=pair.id;
    delete from private.event_point_pair_members where pair_id=pair.id;
  elsif p_action<>'list' then raise exception 'invalid_command'; end if;
  select coalesce(jsonb_agg(jsonb_build_object('id',p.id,'eventKey',coalesce(m.event_key,p.event_key),'status',p.status,
    'incoming',p.partner_id=keeper,'partnerCode',q.keeper_code,'endsAt',p.ends_at)), '[]') into rows
    from private.event_point_pairs p
    left join private.event_point_pair_members m on m.pair_id=p.id and m.owner_id=keeper
    join public.profiles q
      on q.user_id=case when p.creator_id=keeper then p.partner_id else p.creator_id end
    where keeper in (p.creator_id,p.partner_id) and p.status in ('invited','accepted')
      and (p.status='accepted' or p.ends_at>now());
  return jsonb_build_object('pairs',rows,'shared',private.event_partner_progress(keeper));
end $$;

revoke all on function public.event_point_partner_v80(text,text,text,uuid),
  private.event_partner_progress(uuid) from public,anon,authenticated,service_role;
