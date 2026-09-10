-- Keep group requirements attainable at the current nine-level progression.
-- Auth cascades must remove owned social rows even after the player is promoted.
create function private.cap_group_level_requirement()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  new.combined_level_required:=least(new.combined_level_required,new.required_players*9);
  return new;
end $$;
revoke all on function private.cap_group_level_requirement() from public,anon,authenticated,service_role;
create trigger attainable_group_level_requirement before insert on public.group_adventure_lobbies
  for each row execute function private.cap_group_level_requirement();

create or replace function private.guard_canonical_social_write()
returns trigger language plpgsql security definer set search_path = '' as $$
declare previous_owner uuid; next_owner uuid; keeper uuid;
begin
  if coalesce(auth.role(),'') = 'service_role' then
    if tg_op='DELETE' then return old; else return new; end if;
  end if;
  if tg_op <> 'INSERT' then
    previous_owner := coalesce(to_jsonb(old)->>'owner_id',to_jsonb(old)->>'user_id')::uuid;
  end if;
  if tg_op <> 'DELETE' then
    next_owner := coalesce(to_jsonb(new)->>'owner_id',to_jsonb(new)->>'user_id')::uuid;
  end if;
  for keeper in select distinct x from unnest(array[previous_owner,next_owner]) x
      where x is not null order by x loop
    if tg_op='DELETE' and not exists(select 1 from auth.users where id=keeper) then continue; end if;
    perform pg_advisory_xact_lock(hashtextextended(keeper::text,0));
    if exists(select 1 from public.player_economy_authority
        where user_id=keeper and authority_mode='server') or
        exists(select 1 from private.canonical_game_states g cross join private.game_engine_runtime r
          where g.owner_id=keeper and g.is_prepared and r.singleton and r.shadow_projection_enabled) then
      raise exception 'economy_server_inventory_required';
    end if;
  end loop;
  if tg_op='DELETE' then return old; else return new; end if;
end $$;

create or replace function private.guard_canonical_group_lobby()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if coalesce(auth.role(),'')<>'service_role' then
    if tg_op='DELETE' and not exists(select 1 from auth.users where id=old.owner_id) then return old; end if;
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

create or replace function private.guard_canonical_group_participant()
returns trigger language plpgsql security definer set search_path = '' as $$
declare previous_source uuid; next_source uuid;
begin
  if coalesce(auth.role(),'')<>'service_role' then
    if tg_op='DELETE' and not exists(select 1 from auth.users where id=old.user_id) then return old; end if;
    if tg_op<>'INSERT' then previous_source:=old.lobby_id; end if;
    if tg_op<>'DELETE' then next_source:=new.lobby_id; end if;
    if exists(select 1 from public.group_adventure_lobbies where id in (previous_source,next_source) and canonical_owned) then
      raise exception 'economy_server_inventory_required'; end if;
  end if;
  if tg_op='DELETE' then return old; else return new; end if;
end $$;

-- Repair waiting offers only; journeys already running keep their record.
do $$
declare previous_role text:=current_setting('request.jwt.claim.role',true);
begin
  perform set_config('request.jwt.claim.role','service_role',true);
  update public.group_adventure_lobbies set combined_level_required=required_players*9
    where status='waiting' and combined_level_required>required_players*9;
  perform set_config('request.jwt.claim.role',coalesce(previous_role,''),true);
end $$;
