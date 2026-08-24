-- Align server-authoritative Group Adventures with the 3-6 day catalog and
-- subtract the participating dragons' average relevant expertise in hours.
-- Running adventures are deliberately left untouched so they always finish
-- under the terms on which they started.

update public.group_adventure_lobbies
set
  base_duration_minutes = (
    3 + ((substring(adventure_id from 7)::integer - 1) % 4)
  ) * 1440,
  xp = 360 + (
    3 + ((substring(adventure_id from 7)::integer - 1) % 4)
  ) * 175 + ((substring(adventure_id from 7)::integer - 1) % 59),
  stat_points = 52 + (
    3 + ((substring(adventure_id from 7)::integer - 1) % 4)
  ) * 13 + ((substring(adventure_id from 7)::integer - 1) % 9)
where status = 'waiting'
  and adventure_id ~ '^group_([1-9]|[1-9][0-9]|1[0-9]{2}|200)$';

create or replace function private.try_start_group_adventure(p_lobby_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  lobby public.group_adventure_lobbies%rowtype;
  participant_count integer;
  combined_level integer;
  combined_focus integer;
  average_focus integer;
  effective_minutes integer;
  reward_roll double precision;
  reward_chest text;
begin
  select * into lobby from public.group_adventure_lobbies
  where id = p_lobby_id for update;
  if not found or lobby.status <> 'waiting' then return false; end if;

  select count(*)::integer,
    coalesce(sum(private.dragon_level(d.xp)), 0)::integer,
    coalesce(sum(case lobby.focus
      when 'might' then d.might
      when 'arcana' then d.arcana
      else d.spirit end), 0)::integer
  into participant_count, combined_level, combined_focus
  from public.group_adventure_participants gp
  join public.player_dragons d on d.id = gp.dragon_id
  where gp.lobby_id = lobby.id;

  if participant_count <> lobby.required_players
    or combined_level < lobby.combined_level_required
    or combined_focus < lobby.combined_stat_required then
    return false;
  end if;

  average_focus := combined_focus / participant_count;
  effective_minutes := greatest(
    1440,
    lobby.base_duration_minutes - average_focus * 60
  );
  reward_roll := random();
  reward_chest := case
    when reward_roll < 0.70 then 'gold'
    when reward_roll < 0.95 then 'dragon'
    else 'mythical'
  end;
  update public.group_adventure_lobbies set
    status = 'running',
    started_at = now(),
    ends_at = now() + effective_minutes * interval '1 minute',
    chest_tier = reward_chest
  where id = lobby.id;
  return true;
end;
$$;

create or replace function public.create_group_adventure_lobby(
  p_adventure_id text,
  p_dragon jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  current_slot bigint := private.group_adventure_slot(now());
  zero_index integer;
  days integer;
  required_count integer;
  adventure_focus text;
  server_dragon_id uuid;
  new_lobby_id uuid;
  legacy_id text := nullif(left(p_dragon ->> 'client_id', 100), '');
begin
  if current_user_id is null then raise exception 'group_login_required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(current_user_id::text, 0));
  perform private.refresh_group_adventures();
  if p_adventure_id <> private.group_adventure_id(current_slot) then
    raise exception 'group_offer_unavailable';
  end if;
  if exists (
    select 1 from public.group_adventure_participants gp
    join public.group_adventure_lobbies l on l.id = gp.lobby_id
    where gp.user_id = current_user_id and l.slot = current_slot
      and l.status in ('running', 'completed')
  ) then
    raise exception 'group_adventure_already_completed';
  end if;
  if exists (
    select 1 from public.group_adventure_participants gp
    join public.group_adventure_lobbies l on l.id = gp.lobby_id
    where gp.user_id = current_user_id and l.slot = current_slot
      and l.status = 'waiting'
  ) then
    raise exception 'group_already_joined';
  end if;
  if exists (
    select 1 from public.group_adventure_lobbies
    where owner_id = current_user_id and slot = current_slot
  ) then
    raise exception 'group_lobby_already_exists';
  end if;
  if exists (
    select 1 from public.group_adventure_participants gp
    join public.group_adventure_lobbies l on l.id = gp.lobby_id
    join public.player_dragons d on d.id = gp.dragon_id
    where gp.user_id = current_user_id and d.legacy_client_id = legacy_id
      and (l.status = 'running'
        or (l.status = 'waiting' and l.slot = current_slot))
  ) then
    raise exception 'group_dragon_busy';
  end if;

  zero_index := substring(p_adventure_id from 7)::integer - 1;
  days := 3 + zero_index % 4;
  required_count := 2 + zero_index % 3;
  adventure_focus :=
    (array['might', 'arcana', 'spirit'])[(zero_index + 2) % 3 + 1];
  server_dragon_id := private.upsert_group_dragon(current_user_id, p_dragon);

  insert into public.group_adventure_lobbies(
    slot, adventure_id, owner_id, required_players, focus,
    base_duration_minutes, xp, stat_points,
    combined_level_required, combined_stat_required
  ) values (
    current_slot, p_adventure_id, current_user_id, required_count,
    adventure_focus, days * 1440,
    360 + days * 175 + zero_index % 59,
    52 + days * 13 + zero_index % 9,
    case when zero_index % 4 = 0 then 8 + zero_index % 20 else 0 end,
    case when zero_index % 3 = 0 then 50 + zero_index % 150 else 0 end
  ) returning id into new_lobby_id;

  insert into public.group_adventure_participants(lobby_id, user_id, dragon_id)
  values (new_lobby_id, current_user_id, server_dragon_id);
  return new_lobby_id;
end;
$$;

revoke all on function private.try_start_group_adventure(uuid)
  from public, anon, authenticated;
revoke all on function public.create_group_adventure_lobby(text, jsonb)
  from public, anon;
grant execute on function public.create_group_adventure_lobby(text, jsonb)
  to authenticated;
