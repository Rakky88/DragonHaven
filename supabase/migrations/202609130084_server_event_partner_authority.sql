-- Keep accepted event partnerships safe while accounts migrate independently.
-- No balances, earned points, memberships or runtime switches are modified.
create or replace function private.event_partner_progress(p_owner uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare pair record; own_state jsonb := private.event_point_state(p_owner);
  other_state jsonb; own_progress jsonb; other_progress jsonb; result jsonb := '[]';
  own_key text; other_key text;
begin
  for pair in select * from private.event_point_pairs where status='accepted'
    and p_owner in (creator_id,partner_id) loop
    -- An existing accepted pair can span the rolling account cutover. Never
    -- consume fresh legacy-cloud points in a server-owned reward calculation.
    -- Previously credited points and the membership are retained unchanged.
    if exists(select 1 from private.canonical_game_states where owner_id=p_owner
        and is_prepared and authority_mode='server') <>
       exists(select 1 from private.canonical_game_states where
        owner_id=case when pair.creator_id=p_owner then pair.partner_id else pair.creator_id end
        and is_prepared and authority_mode='server') then continue; end if;
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

create or replace function public.event_point_partner(p_action text default 'list',p_event_key text default null,
  p_keeper_code text default null,p_pair_id uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare keeper uuid:=auth.uid(); other_keeper uuid;
begin
  if keeper is null then raise exception 'online_login_required'; end if;
  perform pg_advisory_xact_lock(hashtextextended('event-point-partners',0));
  perform private.expire_event_invitations();
  if p_action='accept' then
    select creator_id into other_keeper from private.event_point_pairs
      where id=p_pair_id and partner_id=keeper and status='invited';
    if other_keeper is not null and
      exists(select 1 from private.canonical_game_states where owner_id=keeper and is_prepared and authority_mode='server') <>
      exists(select 1 from private.canonical_game_states where owner_id=other_keeper and is_prepared and authority_mode='server') then
      raise exception 'event_partner_unavailable'; end if;
  end if;
  return public.event_point_partner_v80(p_action,p_event_key,p_keeper_code,p_pair_id);
end $$;
revoke all on function private.event_partner_progress(uuid) from public,anon,authenticated,service_role;
revoke all on function public.event_point_partner(text,text,text,uuid) from public,anon;
grant execute on function public.event_point_partner(text,text,text,uuid) to authenticated;
