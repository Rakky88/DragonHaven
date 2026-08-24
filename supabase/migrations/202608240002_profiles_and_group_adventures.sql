-- DragonHaven v0.02.00: offline-profile mirroring and authoritative,
-- asynchronous Group Adventures. Clients receive projections through RPCs;
-- every lobby, participant, timer and reward mutation remains database-owned.

alter table public.profiles
  drop constraint if exists profiles_title_check;
alter table public.profiles
  drop constraint if exists profiles_portrait_key_check;

update public.profiles
set title = 'title_001'
where title !~ '^title_(00[1-9]|0[1-9][0-9]|[1-4][0-9]{2}|500)$';
update public.profiles
set portrait_key = 'portrait_001'
where portrait_key !~ '^portrait_(00[1-9]|0[1-9][0-9]|100)$';

alter table public.profiles alter column title set default 'title_001';
alter table public.profiles alter column portrait_key set default 'portrait_001';
alter table public.profiles add constraint profiles_title_id_check check (
  title ~ '^title_(00[1-9]|0[1-9][0-9]|[1-4][0-9]{2}|500)$'
);
alter table public.profiles add constraint profiles_portrait_id_check check (
  portrait_key ~ '^portrait_(00[1-9]|0[1-9][0-9]|100)$'
);

update public.player_dragons set
  might = least(might, 300),
  arcana = least(arcana, 300),
  spirit = least(spirit, 300);
alter table public.player_dragons
  drop constraint if exists player_dragons_might_check;
alter table public.player_dragons
  drop constraint if exists player_dragons_arcana_check;
alter table public.player_dragons
  drop constraint if exists player_dragons_spirit_check;
alter table public.player_dragons add constraint player_dragons_might_check
  check (might between 0 and 300);
alter table public.player_dragons add constraint player_dragons_arcana_check
  check (arcana between 0 and 300);
alter table public.player_dragons add constraint player_dragons_spirit_check
  check (spirit between 0 and 300);

update public.social_showcases set
  favorite_dragon_might = least(favorite_dragon_might, 300),
  favorite_dragon_arcana = least(favorite_dragon_arcana, 300),
  favorite_dragon_spirit = least(favorite_dragon_spirit, 300);
alter table public.social_showcases
  add constraint social_showcases_favorite_might_cap_check
    check (favorite_dragon_might is null or favorite_dragon_might between 0 and 300),
  add constraint social_showcases_favorite_arcana_cap_check
    check (favorite_dragon_arcana is null or favorite_dragon_arcana between 0 and 300),
  add constraint social_showcases_favorite_spirit_cap_check
    check (favorite_dragon_spirit is null or favorite_dragon_spirit between 0 and 300);

create or replace function public.update_my_profile(
  p_display_name text,
  p_title text,
  p_portrait_key text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null
    or char_length(btrim(p_display_name)) not between 1 and 24
    or p_title !~ '^title_(00[1-9]|0[1-9][0-9]|[1-4][0-9]{2}|500)$'
    or p_portrait_key !~ '^portrait_(00[1-9]|0[1-9][0-9]|100)$' then
    raise exception 'invalid_profile';
  end if;
  update public.profiles
  set display_name = btrim(p_display_name),
      title = p_title,
      portrait_key = p_portrait_key
  where user_id = auth.uid();
end;
$$;

create table public.group_adventure_lobbies (
  id uuid primary key default gen_random_uuid(),
  slot bigint not null,
  adventure_id text not null check (adventure_id ~ '^group_([1-9]|[1-9][0-9]|1[0-9]{2}|200)$'),
  owner_id uuid not null references public.profiles(user_id) on delete cascade,
  status text not null default 'waiting'
    check (status in ('waiting', 'running', 'completed')),
  required_players smallint not null check (required_players between 2 and 4),
  focus text not null check (focus in ('might', 'arcana', 'spirit')),
  base_duration_minutes integer not null check (base_duration_minutes > 0),
  xp integer not null check (xp > 0),
  stat_points integer not null check (stat_points > 0),
  combined_level_required integer not null default 0
    check (combined_level_required >= 0),
  combined_stat_required integer not null default 0
    check (combined_stat_required >= 0),
  started_at timestamptz,
  ends_at timestamptz,
  completed_at timestamptz,
  chest_tier text check (chest_tier in ('gold', 'dragon', 'mythical')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_id, slot),
  check (
    (status = 'waiting' and started_at is null and ends_at is null and chest_tier is null)
    or (status in ('running', 'completed') and started_at is not null
      and ends_at is not null and chest_tier is not null)
  )
);

create table public.group_adventure_participants (
  lobby_id uuid not null references public.group_adventure_lobbies(id)
    on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  dragon_id uuid not null references public.player_dragons(id) on delete cascade,
  joined_at timestamptz not null default now(),
  reward_acknowledged_at timestamptz,
  primary key (lobby_id, user_id),
  unique (lobby_id, dragon_id)
);

create index group_adventure_lobbies_slot_status_idx
  on public.group_adventure_lobbies(slot, status);
create index group_adventure_participants_user_idx
  on public.group_adventure_participants(user_id, lobby_id);

alter table public.group_adventure_lobbies enable row level security;
alter table public.group_adventure_participants enable row level security;
revoke all on table public.group_adventure_lobbies from anon, authenticated;
revoke all on table public.group_adventure_participants from anon, authenticated;

create trigger group_adventure_lobbies_touch_updated_at
before update on public.group_adventure_lobbies
for each row execute function private.touch_updated_at();

create or replace function private.group_adventure_slot(p_at timestamptz)
returns bigint
language sql
stable
set search_path = ''
as $$
  with moment as (
    select pg_catalog.timezone('Europe/Amsterdam', p_at) as wall_time
  ), boundary as (
    select wall_time,
      pg_catalog.date_trunc('week', wall_time)
        + interval '6 days 12 hours' as sunday_noon
    from moment
  )
  select pg_catalog.floor(extract(epoch from (
    (case when wall_time < sunday_noon
      then sunday_noon - interval '7 days' else sunday_noon end)
      - timestamp '2020-01-05 12:00:00'
  )) / 604800)::bigint
  from boundary
$$;

create or replace function private.group_adventure_id(p_slot bigint)
returns text
language sql
immutable
set search_path = ''
as $$
  select 'group_' || ((pg_catalog.abs(p_slot * 17) % 200) + 1)::text
$$;

create or replace function private.upsert_group_dragon(
  p_user_id uuid,
  p_dragon jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  result_id uuid;
  legacy_id text := nullif(left(p_dragon ->> 'client_id', 100), '');
  dragon_name text := left(nullif(btrim(p_dragon ->> 'name'), ''), 24);
  lineage text := p_dragon ->> 'lineage_id';
  dragon_stage text := p_dragon ->> 'stage';
  dragon_xp integer;
  dragon_might integer;
  dragon_arcana integer;
  dragon_spirit integer;
  path text := p_dragon ->> 'evolution_path';
begin
  if p_user_id is null or jsonb_typeof(p_dragon) <> 'object'
    or legacy_id is null or dragon_name is null
    or lineage !~ '^[a-z0-9_]{1,64}$'
    or dragon_stage not in ('hatchling', 'wyrmling', 'ascended')
    or path not in ('might', 'arcana', 'spirit') then
    raise exception 'invalid_group_dragon';
  end if;
  dragon_xp := (p_dragon ->> 'xp')::integer;
  dragon_might := (p_dragon ->> 'might')::integer;
  dragon_arcana := (p_dragon ->> 'arcana')::integer;
  dragon_spirit := (p_dragon ->> 'spirit')::integer;
  if dragon_xp < 0
    or dragon_might not between 0 and 300
    or dragon_arcana not between 0 and 300
    or dragon_spirit not between 0 and 300 then
    raise exception 'invalid_group_dragon';
  end if;

  insert into public.player_dragons(
    owner_id, legacy_client_id, name, lineage_id, stage, xp,
    might, arcana, spirit, evolution_path, favorite, prismatic, sinister
  ) values (
    p_user_id, legacy_id, dragon_name, lineage, dragon_stage,
    least(dragon_xp, 100000000), dragon_might, dragon_arcana, dragon_spirit,
    path, false,
    coalesce((p_dragon ->> 'prismatic')::boolean, false),
    coalesce((p_dragon ->> 'sinister')::boolean, false)
  )
  on conflict (owner_id, legacy_client_id) do update set
    name = excluded.name,
    lineage_id = excluded.lineage_id,
    stage = excluded.stage,
    xp = excluded.xp,
    might = excluded.might,
    arcana = excluded.arcana,
    spirit = excluded.spirit,
    evolution_path = excluded.evolution_path,
    prismatic = excluded.prismatic,
    sinister = excluded.sinister,
    updated_at = now()
  returning id into result_id;
  return result_id;
exception
  when invalid_text_representation or numeric_value_out_of_range
    or check_violation or not_null_violation then
    raise exception 'invalid_group_dragon';
end;
$$;

create or replace function private.refresh_group_adventures()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_slot bigint := private.group_adventure_slot(now());
begin
  delete from public.group_adventure_lobbies
  where status = 'waiting' and slot < current_slot;

  update public.group_adventure_lobbies
  set status = 'completed', completed_at = coalesce(completed_at, now())
  where status = 'running' and ends_at <= now();
end;
$$;

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

  effective_minutes := greatest(1, lobby.base_duration_minutes - combined_focus);
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
      and (l.status = 'running' or (l.status = 'waiting' and l.slot = current_slot))
  ) then
    raise exception 'group_dragon_busy';
  end if;

  zero_index := substring(p_adventure_id from 7)::integer - 1;
  days := 2 + zero_index % 4;
  required_count := 2 + zero_index % 3;
  adventure_focus := (array['might', 'arcana', 'spirit'])[(zero_index + 2) % 3 + 1];
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

create or replace function public.join_group_adventure_lobby(
  p_lobby_id uuid,
  p_dragon jsonb
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  current_slot bigint := private.group_adventure_slot(now());
  lobby public.group_adventure_lobbies%rowtype;
  server_dragon_id uuid;
  legacy_id text := nullif(left(p_dragon ->> 'client_id', 100), '');
  participant_count integer;
begin
  if current_user_id is null then raise exception 'group_login_required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(current_user_id::text, 0));
  perform private.refresh_group_adventures();
  select * into lobby from public.group_adventure_lobbies
  where id = p_lobby_id for update;
  if not found then raise exception 'group_lobby_not_found'; end if;
  if lobby.status <> 'waiting' or lobby.slot <> current_slot then
    raise exception 'group_lobby_closed';
  end if;
  if not exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and ((f.requester_id = current_user_id and f.addressee_id = lobby.owner_id)
        or (f.addressee_id = current_user_id and f.requester_id = lobby.owner_id))
  ) then
    raise exception 'group_not_friends';
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
  select count(*)::integer into participant_count
  from public.group_adventure_participants where lobby_id = lobby.id;
  if participant_count >= lobby.required_players then
    raise exception 'group_lobby_full';
  end if;
  if exists (
    select 1 from public.group_adventure_participants gp
    join public.group_adventure_lobbies l on l.id = gp.lobby_id
    join public.player_dragons d on d.id = gp.dragon_id
    where gp.user_id = current_user_id and d.legacy_client_id = legacy_id
      and (l.status = 'running' or (l.status = 'waiting' and l.slot = current_slot))
  ) then
    raise exception 'group_dragon_busy';
  end if;

  server_dragon_id := private.upsert_group_dragon(current_user_id, p_dragon);
  insert into public.group_adventure_participants(lobby_id, user_id, dragon_id)
  values (lobby.id, current_user_id, server_dragon_id);
  return private.try_start_group_adventure(lobby.id);
end;
$$;

create or replace function public.leave_group_adventure_lobby(p_lobby_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  lobby public.group_adventure_lobbies%rowtype;
begin
  if current_user_id is null then raise exception 'group_login_required'; end if;
  select * into lobby from public.group_adventure_lobbies
  where id = p_lobby_id for update;
  if not found then raise exception 'group_lobby_not_found'; end if;
  if lobby.status <> 'waiting' then raise exception 'group_lobby_closed'; end if;
  if not exists (select 1 from public.group_adventure_participants
      where lobby_id = lobby.id and user_id = current_user_id) then
    raise exception 'group_participant_not_found';
  end if;
  if lobby.owner_id = current_user_id then
    delete from public.group_adventure_lobbies where id = lobby.id;
  else
    delete from public.group_adventure_participants
    where lobby_id = lobby.id and user_id = current_user_id;
  end if;
end;
$$;

create or replace function public.remove_group_adventure_participant(
  p_lobby_id uuid,
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  lobby public.group_adventure_lobbies%rowtype;
begin
  if current_user_id is null then raise exception 'group_login_required'; end if;
  select * into lobby from public.group_adventure_lobbies
  where id = p_lobby_id for update;
  if not found then raise exception 'group_lobby_not_found'; end if;
  if lobby.owner_id <> current_user_id then raise exception 'group_not_owner'; end if;
  if lobby.status <> 'waiting' then raise exception 'group_lobby_closed'; end if;
  if p_user_id = lobby.owner_id then
    raise exception 'group_owner_cannot_be_removed';
  end if;
  delete from public.group_adventure_participants
  where lobby_id = lobby.id and user_id = p_user_id;
  if not found then raise exception 'group_participant_not_found'; end if;
end;
$$;

create or replace function public.list_group_adventures()
returns table (
  lobby_id uuid,
  slot bigint,
  adventure_id text,
  owner_id uuid,
  status text,
  required_players integer,
  focus text,
  started_at timestamptz,
  ends_at timestamptz,
  is_current_offer boolean,
  is_owner boolean,
  is_participant boolean,
  my_dragon_id text,
  reward_acknowledged boolean,
  participants jsonb
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  current_slot bigint := private.group_adventure_slot(now());
begin
  if current_user_id is null then raise exception 'group_login_required'; end if;
  perform private.refresh_group_adventures();
  return query
  select
    l.id, l.slot, l.adventure_id, l.owner_id, l.status,
    l.required_players::integer, l.focus, l.started_at, l.ends_at,
    l.slot = current_slot,
    l.owner_id = current_user_id,
    exists (select 1 from public.group_adventure_participants mine
      where mine.lobby_id = l.id and mine.user_id = current_user_id),
    (select d.legacy_client_id
      from public.group_adventure_participants mine
      join public.player_dragons d on d.id = mine.dragon_id
      where mine.lobby_id = l.id and mine.user_id = current_user_id),
    coalesce((select mine.reward_acknowledged_at is not null
      from public.group_adventure_participants mine
      where mine.lobby_id = l.id and mine.user_id = current_user_id), false),
    (select jsonb_agg(jsonb_build_object(
      'user_id', gp.user_id,
      'keeper_code', p.keeper_code,
      'display_name', p.display_name,
      'title', p.title,
      'portrait_key', p.portrait_key,
      'discovered_dragon_count', 0,
      'inventory_imported', true,
      'dragon_id', d.legacy_client_id,
      'dragon_name', d.name,
      'dragon_lineage_id', d.lineage_id,
      'dragon_stage', d.stage,
      'dragon_level', private.dragon_level(d.xp),
      'dragon_might', d.might,
      'dragon_arcana', d.arcana,
      'dragon_spirit', d.spirit,
      'dragon_evolution_path', d.evolution_path,
      'dragon_prismatic', d.prismatic,
      'dragon_sinister', d.sinister,
      'is_owner', gp.user_id = l.owner_id
    ) order by (gp.user_id = l.owner_id) desc, gp.joined_at)
    from public.group_adventure_participants gp
    join public.profiles p on p.user_id = gp.user_id
    join public.player_dragons d on d.id = gp.dragon_id
    where gp.lobby_id = l.id)
  from public.group_adventure_lobbies l
  where (
    l.status = 'waiting' and l.slot = current_slot and (
      l.owner_id = current_user_id or exists (
        select 1 from public.friendships f
        where f.status = 'accepted'
          and ((f.requester_id = current_user_id and f.addressee_id = l.owner_id)
            or (f.addressee_id = current_user_id and f.requester_id = l.owner_id))
      )
    )
  ) or (
    l.status in ('running', 'completed') and exists (
      select 1 from public.group_adventure_participants mine
      where mine.lobby_id = l.id and mine.user_id = current_user_id
        and (l.status <> 'completed' or mine.reward_acknowledged_at is null)
    )
  )
  order by (l.owner_id = current_user_id) desc, l.created_at desc;
end;
$$;

create or replace function public.get_current_group_adventure_status()
returns table (
  slot bigint,
  adventure_id text,
  already_completed boolean
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  current_slot bigint := private.group_adventure_slot(now());
  current_adventure_id text := private.group_adventure_id(current_slot);
begin
  if current_user_id is null then raise exception 'group_login_required'; end if;
  return query select
    current_slot,
    current_adventure_id,
    exists (
      select 1
      from public.group_adventure_participants gp
      join public.group_adventure_lobbies l on l.id = gp.lobby_id
      where gp.user_id = current_user_id
        and l.slot = current_slot
        and l.status in ('running', 'completed')
    );
end;
$$;

create or replace function public.claim_group_adventure_reward(p_lobby_id uuid)
returns table (
  lobby_id uuid,
  adventure_id text,
  dragon_id text,
  xp integer,
  focus text,
  stat_points integer,
  chest_tier text,
  participant_count integer
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then raise exception 'group_login_required'; end if;
  perform private.refresh_group_adventures();
  return query
  select l.id, l.adventure_id, d.legacy_client_id, l.xp, l.focus,
    l.stat_points, l.chest_tier, count(all_participants.user_id)::integer
  from public.group_adventure_lobbies l
  join public.group_adventure_participants mine
    on mine.lobby_id = l.id and mine.user_id = current_user_id
  join public.player_dragons d on d.id = mine.dragon_id
  join public.group_adventure_participants all_participants
    on all_participants.lobby_id = l.id
  where l.id = p_lobby_id and l.status = 'completed'
    and mine.reward_acknowledged_at is null
  group by l.id, d.legacy_client_id;
  if not found then raise exception 'group_reward_not_ready'; end if;
end;
$$;

create or replace function public.acknowledge_group_adventure_reward(
  p_lobby_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  lobby public.group_adventure_lobbies%rowtype;
  participant public.group_adventure_participants%rowtype;
begin
  if current_user_id is null then raise exception 'group_login_required'; end if;
  select * into lobby from public.group_adventure_lobbies
  where id = p_lobby_id for update;
  if not found or lobby.status <> 'completed' then
    raise exception 'group_reward_not_ready';
  end if;
  select * into participant from public.group_adventure_participants
  where lobby_id = lobby.id and user_id = current_user_id for update;
  if not found then raise exception 'group_participant_not_found'; end if;
  if participant.reward_acknowledged_at is not null then return; end if;

  update public.player_dragons set
    xp = least(100000000, xp + lobby.xp),
    might = case when lobby.focus = 'might'
      then least(300, might + lobby.stat_points) else might end,
    arcana = case when lobby.focus = 'arcana'
      then least(300, arcana + lobby.stat_points) else arcana end,
    spirit = case when lobby.focus = 'spirit'
      then least(300, spirit + lobby.stat_points) else spirit end,
    updated_at = now()
  where id = participant.dragon_id;

  insert into public.player_chests(owner_id, tier, quantity)
  values (current_user_id, lobby.chest_tier, 1)
  on conflict (owner_id, tier) do update set
    quantity = public.player_chests.quantity + 1,
    updated_at = now();
  update public.group_adventure_participants
  set reward_acknowledged_at = now()
  where lobby_id = lobby.id and user_id = current_user_id;
end;
$$;

revoke all on function private.group_adventure_slot(timestamptz) from public, anon, authenticated;
revoke all on function private.group_adventure_id(bigint) from public, anon, authenticated;
revoke all on function private.upsert_group_dragon(uuid, jsonb) from public, anon, authenticated;
revoke all on function private.refresh_group_adventures() from public, anon, authenticated;
revoke all on function private.try_start_group_adventure(uuid) from public, anon, authenticated;

revoke all on function public.create_group_adventure_lobby(text, jsonb) from public, anon;
revoke all on function public.join_group_adventure_lobby(uuid, jsonb) from public, anon;
revoke all on function public.leave_group_adventure_lobby(uuid) from public, anon;
revoke all on function public.remove_group_adventure_participant(uuid, uuid) from public, anon;
revoke all on function public.list_group_adventures() from public, anon;
revoke all on function public.get_current_group_adventure_status() from public, anon;
revoke all on function public.claim_group_adventure_reward(uuid) from public, anon;
revoke all on function public.acknowledge_group_adventure_reward(uuid) from public, anon;

grant execute on function public.create_group_adventure_lobby(text, jsonb) to authenticated;
grant execute on function public.join_group_adventure_lobby(uuid, jsonb) to authenticated;
grant execute on function public.leave_group_adventure_lobby(uuid) to authenticated;
grant execute on function public.remove_group_adventure_participant(uuid, uuid) to authenticated;
grant execute on function public.list_group_adventures() to authenticated;
grant execute on function public.get_current_group_adventure_status() to authenticated;
grant execute on function public.claim_group_adventure_reward(uuid) to authenticated;
grant execute on function public.acknowledge_group_adventure_reward(uuid) to authenticated;
