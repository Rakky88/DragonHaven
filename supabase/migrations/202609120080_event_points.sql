-- Event points replace seasonal adventure entry. Existing runs remain claimable.
create or replace function public.seasonal_event_window(
  p_event_id text,
  p_now timestamptz default now()
)
returns table (
  occurrence_key text,
  starts_at timestamptz,
  ends_at timestamptz,
  results_end_at timestamptz
)
language plpgsql
set search_path = ''
stable
as $$
declare
  local_now timestamp := p_now at time zone 'Europe/Amsterdam';
  event_year integer := extract(year from local_now)::integer;
  local_start timestamp;
  local_end timestamp;
begin
  if p_event_id = 'golden_wings_birthday' then
    if event_year < 2026 then return; end if;
    if event_year = 2026 then
      local_start := make_timestamp(2026, 9, 1, 0, 0, 0);
      local_end := make_timestamp(2026, 9, 3, 0, 0, 0);
    else
      local_start := make_timestamp(event_year, 5, 13, 0, 0, 0);
      local_end := make_timestamp(event_year, 5, 14, 0, 0, 0);
    end if;
  elsif p_event_id = 'halloween_witchlight' then
    local_start := make_timestamp(event_year, 10, 25, 0, 0, 0);
    local_end := make_timestamp(event_year, 11, 2, 0, 0, 0);
  elsif p_event_id = 'christmas_winter_hearth' then
    local_start := make_timestamp(event_year, 12, 25, 0, 0, 0);
    local_end := make_timestamp(event_year, 12, 27, 0, 0, 0);
  elsif p_event_id = 'new_year_first_dawn' then
    if event_year < 2027 then return; end if;
    local_start := make_timestamp(event_year, 1, 1, 0, 0, 0);
    local_end := make_timestamp(event_year, 1, 7, 0, 0, 0);
  elsif p_event_id = 'valentine_two_heartlights' then
    local_start := make_timestamp(event_year, 2, 14, 0, 0, 0);
    local_end := make_timestamp(event_year, 2, 15, 0, 0, 0);
  elsif p_event_id = 'sunwake_summer_sea' then
    local_start := make_timestamp(event_year, 7, 20, 0, 0, 0);
    local_end := make_timestamp(event_year, 7, 27, 0, 0, 0);
  elsif p_event_id = 'harvestmoon_moonlit_orchard' then
    local_start := make_timestamp(event_year, 9, 7, 0, 0, 0);
    local_end := make_timestamp(event_year, 9, 14, 0, 0, 0);
  elsif p_event_id = 'pride_every_color' then
    local_start := make_timestamp(event_year, 6, 1, 0, 0, 0);
    local_end := make_timestamp(event_year, 6, 8, 0, 0, 0);
  else
    return;
  end if;

  -- The first configured editions are a hard lower boundary.
  if (p_event_id in ('halloween_witchlight', 'christmas_winter_hearth',
        'new_year_first_dawn') and event_year < 2026)
     or (p_event_id in ('valentine_two_heartlights', 'pride_every_color',
        'sunwake_summer_sea', 'harvestmoon_moonlit_orchard')
        and event_year < 2027) then
    return;
  end if;
  occurrence_key := p_event_id || ':' || event_year::text;
  starts_at := local_start at time zone 'Europe/Amsterdam';
  ends_at := local_end at time zone 'Europe/Amsterdam';
  results_end_at := ends_at + interval '5 days';
  return next;
end
$$;

-- Invitations reserve one partner slot per occurrence for each keeper. Accepted
-- bonds are permanent for that occurrence, so a claimed contribution cannot be
-- recycled through a series of partners. No dragon is reserved.
create table private.event_point_pairs (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references auth.users(id) on delete cascade,
  partner_id uuid not null references auth.users(id) on delete cascade,
  event_key text not null,
  ends_at timestamptz not null,
  status text not null default 'invited' check(status in ('invited','accepted','declined')),
  created_at timestamptz not null default now(),
  check(creator_id <> partner_id)
);
create table private.event_point_pair_members (
  owner_id uuid not null references auth.users(id) on delete cascade,
  event_key text not null,
  pair_id uuid not null references private.event_point_pairs(id) on delete cascade,
  primary key(owner_id,event_key)
);
revoke all on private.event_point_pairs,private.event_point_pair_members from public,anon,authenticated;

create function private.event_point_state(p_owner uuid)
returns jsonb language sql stable security definer set search_path='' as $$
  select coalesce(
    (select state from private.canonical_game_states where owner_id=p_owner and is_prepared and authority_mode='server'),
    (select state from public.cloud_game_saves where user_id=p_owner), '{}');
$$;

create function private.event_partner_progress(p_owner uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare pair record; own_state jsonb := private.event_point_state(p_owner);
  other_state jsonb; own_progress jsonb; other_progress jsonb; result jsonb := '[]';
begin
  for pair in select * from private.event_point_pairs where status='accepted'
    and p_owner in (creator_id,partner_id) loop
    other_state:=private.event_point_state(case when pair.creator_id=p_owner then pair.partner_id else pair.creator_id end);
    own_progress:=own_state->'eventProgress'->pair.event_key;
    other_progress:=other_state->'eventProgress'->pair.event_key;
    if other_progress is null then continue; end if;
    if own_progress is null then
      own_progress:=other_progress||jsonb_build_object('points',0,'partnerPoints',0,'claimed',false);
    end if;
    result:=result||jsonb_build_array(own_progress||jsonb_build_object('partnerPoints',
      greatest(coalesce((own_progress->>'partnerPoints')::bigint,0),coalesce((other_progress->>'points')::bigint,0))));
  end loop;
  return jsonb_build_object('version',1,'ownerId',p_owner,'progress',result);
end $$;

create function public.event_point_partner(p_action text default 'list',p_event_key text default null,
  p_keeper_code text default null,p_pair_id uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare keeper uuid := auth.uid(); other_keeper uuid; event jsonb;
  pair private.event_point_pairs%rowtype; new_id uuid; rows jsonb;
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
    if exists(select 1 from private.event_point_pair_members where event_key=p_event_key
      and owner_id in (keeper,other_keeper)) then raise exception 'event_partner_already_selected'; end if;
    insert into private.event_point_pairs(creator_id,partner_id,event_key,ends_at)
      values(keeper,other_keeper,p_event_key,(event->>'endsAt')::timestamptz) returning id into new_id;
    insert into private.event_point_pair_members values(keeper,p_event_key,new_id),(other_keeper,p_event_key,new_id);
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
  select coalesce(jsonb_agg(jsonb_build_object('id',p.id,'eventKey',p.event_key,'status',p.status,
    'incoming',p.partner_id=keeper,'partnerCode',q.keeper_code,'endsAt',p.ends_at)), '[]') into rows
    from private.event_point_pairs p join public.profiles q
      on q.user_id=case when p.creator_id=keeper then p.partner_id else p.creator_id end
    where keeper in (p.creator_id,p.partner_id) and p.status in ('invited','accepted')
      and (p.status='accepted' or p.ends_at>now());
  return jsonb_build_object('pairs',rows,'shared',private.event_partner_progress(keeper));
end $$;
revoke all on function private.event_point_state(uuid),private.event_partner_progress(uuid) from public,anon,authenticated,service_role;
revoke all on function public.event_point_partner(text,text,text,uuid) from public,anon;
grant execute on function public.event_point_partner(text,text,text,uuid) to authenticated;

alter function public.read_canonical_game_state(uuid,integer,text) rename to read_canonical_game_state_v79;
create function public.read_canonical_game_state(p_owner_id uuid,p_client_build integer,p_ruleset_sha256 text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare snapshot jsonb;
begin
  perform private.assert_game_service();
  snapshot:=public.read_canonical_game_state_v79(p_owner_id,p_client_build,p_ruleset_sha256);
  return snapshot||jsonb_build_object('event_progress',private.event_partner_progress(p_owner_id));
end $$;
alter function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint)
  rename to begin_revisioned_game_command_v79;
create function public.begin_revisioned_game_command(p_owner_id uuid,p_request_id uuid,p_action text,p_payload jsonb,
  p_client_build integer,p_ruleset_sha256 text,p_expected_revision bigint)
returns jsonb language plpgsql security definer set search_path='' as $$
declare leased jsonb;
begin
  perform private.assert_game_service();
  if p_action in ('invite_pair_adventure','accept_pair_adventure','start_pair_adventure') then
    raise exception 'game_action_unavailable'; end if;
  leased:=public.begin_revisioned_game_command_v79(p_owner_id,p_request_id,p_action,p_payload,
    p_client_build,p_ruleset_sha256,p_expected_revision);
  return leased||jsonb_build_object('event_progress',private.event_partner_progress(p_owner_id),
    'social_claims',private.canonical_social_claim_offers(p_owner_id,clock_timestamp()));
end $$;
revoke all on function public.read_canonical_game_state_v79(uuid,integer,text),
  public.begin_revisioned_game_command_v79(uuid,uuid,text,jsonb,integer,text,bigint) from public,anon,authenticated,service_role;
revoke all on function public.read_canonical_game_state(uuid,integer,text),
  public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint) from public,anon,authenticated;
grant execute on function public.read_canonical_game_state(uuid,integer,text),
  public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint) to service_role;

