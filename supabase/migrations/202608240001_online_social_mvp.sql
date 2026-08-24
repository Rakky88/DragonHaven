-- DragonHaven asynchronous social MVP.
-- Clients may read social projections only through the RPCs below. Inventory
-- tables deliberately have no authenticated write grants: future gameplay and
-- trading mutations must be added as validated database commands.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  keeper_code text not null unique
    check (keeper_code ~ '^DH-[A-F0-9]{8}$'),
  display_name text not null
    check (char_length(display_name) between 1 and 24),
  title text not null default 'Dragon Keeper'
    check (title in (
      'Dragon Keeper', 'Nest Guardian', 'Sky Explorer',
      'Draconomicon Scholar', 'Tower Architect'
    )),
  portrait_key text not null default 'moon'
    check (portrait_key in ('moon', 'ember', 'forest', 'tide', 'storm')),
  inventory_imported_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.player_wallets (
  user_id uuid primary key references public.profiles(user_id)
    on delete cascade,
  coins bigint not null default 25 check (coins >= 0),
  gems bigint not null default 3 check (gems >= 0),
  revision bigint not null default 1 check (revision > 0),
  updated_at timestamptz not null default now()
);

create table public.player_dragons (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(user_id)
    on delete cascade,
  legacy_client_id text,
  name text not null check (char_length(name) between 1 and 24),
  lineage_id text not null check (lineage_id ~ '^[a-z0-9_]{1,64}$'),
  stage text not null check (stage in ('hatchling', 'wyrmling', 'ascended')),
  xp integer not null default 0 check (xp >= 0),
  might integer not null default 0 check (might >= 0),
  arcana integer not null default 0 check (arcana >= 0),
  spirit integer not null default 0 check (spirit >= 0),
  evolution_path text not null default 'spirit'
    check (evolution_path in ('might', 'arcana', 'spirit')),
  favorite boolean not null default false,
  prismatic boolean not null default false,
  sinister boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_id, legacy_client_id)
);

create unique index player_dragons_one_favorite_per_owner
  on public.player_dragons(owner_id) where favorite;
create index player_dragons_owner_idx on public.player_dragons(owner_id);

create table public.player_eggs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(user_id)
    on delete cascade,
  legacy_client_id text,
  lineage_id text not null check (lineage_id ~ '^[a-z0-9_]{1,64}$'),
  acquired_at timestamptz not null default now(),
  prismatic boolean not null default false,
  sinister boolean not null default false,
  created_at timestamptz not null default now(),
  unique (owner_id, legacy_client_id)
);

create index player_eggs_owner_idx on public.player_eggs(owner_id);

create table public.player_chests (
  owner_id uuid not null references public.profiles(user_id)
    on delete cascade,
  tier text not null check (
    tier in ('wooden', 'silver', 'gold', 'dragon', 'mythical', 'sinister')
  ),
  quantity integer not null default 0 check (quantity >= 0),
  updated_at timestamptz not null default now(),
  primary key (owner_id, tier)
);

create table public.furniture_instances (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(user_id)
    on delete cascade,
  catalog_item_id text not null
    check (catalog_item_id ~ '^[a-z0-9_]{1,80}$'),
  created_at timestamptz not null default now(),
  unique (owner_id, catalog_item_id)
);

create index furniture_instances_owner_idx
  on public.furniture_instances(owner_id);

create table public.discovered_lineages (
  owner_id uuid not null references public.profiles(user_id)
    on delete cascade,
  lineage_id text not null check (lineage_id ~ '^[a-z0-9_]{1,64}$'),
  discovered_at timestamptz not null default now(),
  primary key (owner_id, lineage_id)
);

-- A cosmetic, player-published projection used by the friends UI. It never
-- proves ownership and must never be consulted by rewards, trading or economy
-- commands; those use the normalized inventory tables above.
create table public.social_showcases (
  user_id uuid primary key references public.profiles(user_id)
    on delete cascade,
  discovered_dragon_count integer not null default 0
    check (discovered_dragon_count between 0 and 100),
  favorite_dragon_id text,
  favorite_dragon_name text,
  favorite_dragon_lineage_id text,
  favorite_dragon_stage text,
  favorite_dragon_xp integer,
  favorite_dragon_might integer,
  favorite_dragon_arcana integer,
  favorite_dragon_spirit integer,
  favorite_dragon_evolution_path text,
  favorite_dragon_prismatic boolean,
  favorite_dragon_sinister boolean,
  updated_at timestamptz not null default now(),
  check (favorite_dragon_name is null or
    char_length(favorite_dragon_name) between 1 and 24),
  check (favorite_dragon_lineage_id is null or
    favorite_dragon_lineage_id ~ '^[a-z0-9_]{1,64}$'),
  check (favorite_dragon_stage is null or
    favorite_dragon_stage in ('hatchling', 'wyrmling', 'ascended')),
  check (favorite_dragon_xp is null or favorite_dragon_xp >= 0),
  check (favorite_dragon_might is null or favorite_dragon_might >= 0),
  check (favorite_dragon_arcana is null or favorite_dragon_arcana >= 0),
  check (favorite_dragon_spirit is null or favorite_dragon_spirit >= 0),
  check (favorite_dragon_evolution_path is null or
    favorite_dragon_evolution_path in ('might', 'arcana', 'spirit'))
);

create table public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(user_id)
    on delete cascade,
  addressee_id uuid not null references public.profiles(user_id)
    on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'blocked')),
  blocked_by uuid references public.profiles(user_id) on delete cascade,
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  updated_at timestamptz not null default now(),
  check (requester_id <> addressee_id),
  check (
    (status = 'blocked' and blocked_by in (requester_id, addressee_id))
    or (status <> 'blocked' and blocked_by is null)
  )
);

create unique index friendships_one_row_per_pair on public.friendships (
  least(requester_id, addressee_id), greatest(requester_id, addressee_id)
);
create index friendships_requester_idx on public.friendships(requester_id);
create index friendships_addressee_idx on public.friendships(addressee_id);

alter table public.profiles enable row level security;
alter table public.player_wallets enable row level security;
alter table public.player_dragons enable row level security;
alter table public.player_eggs enable row level security;
alter table public.player_chests enable row level security;
alter table public.furniture_instances enable row level security;
alter table public.discovered_lineages enable row level security;
alter table public.social_showcases enable row level security;
alter table public.friendships enable row level security;

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.player_wallets from anon, authenticated;
revoke all on table public.player_dragons from anon, authenticated;
revoke all on table public.player_eggs from anon, authenticated;
revoke all on table public.player_chests from anon, authenticated;
revoke all on table public.furniture_instances from anon, authenticated;
revoke all on table public.discovered_lineages from anon, authenticated;
revoke all on table public.social_showcases from anon, authenticated;
revoke all on table public.friendships from anon, authenticated;

create or replace function private.next_keeper_code()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  candidate text;
begin
  loop
    candidate := 'DH-' || upper(substr(
      encode(extensions.gen_random_bytes(5), 'hex'), 1, 8
    ));
    exit when not exists (
      select 1 from public.profiles where keeper_code = candidate
    );
  end loop;
  return candidate;
end;
$$;

create or replace function private.dragon_level(value integer)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case
    when value >= 3400 then 9
    when value >= 2600 then 8
    when value >= 1950 then 7
    when value >= 1450 then 6
    when value >= 1000 then 5
    when value >= 650 then 4
    when value >= 350 then 3
    when value >= 150 then 2
    else 1
  end
$$;

create or replace function private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function private.touch_updated_at();

create trigger friendships_touch_updated_at
before update on public.friendships
for each row execute function private.touch_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  chosen_name text;
begin
  chosen_name := left(
    coalesce(nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''), 'Keeper'),
    24
  );
  insert into public.profiles(user_id, keeper_code, display_name)
  values (new.id, private.next_keeper_code(), chosen_name);
  insert into public.player_wallets(user_id) values (new.id);
  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.publish_social_showcase(p_showcase jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  favorite jsonb := p_showcase -> 'favorite_dragon';
  discovered_count integer;
begin
  if current_user_id is null or jsonb_typeof(p_showcase) <> 'object' then
    raise exception 'invalid_profile';
  end if;
  discovered_count := (p_showcase ->> 'discovered_dragon_count')::integer;
  if discovered_count not between 0 and 100
    or (favorite is not null and jsonb_typeof(favorite) not in ('object', 'null')) then
    raise exception 'invalid_profile';
  end if;

  insert into public.social_showcases(
    user_id, discovered_dragon_count,
    favorite_dragon_id, favorite_dragon_name,
    favorite_dragon_lineage_id, favorite_dragon_stage,
    favorite_dragon_xp, favorite_dragon_might, favorite_dragon_arcana,
    favorite_dragon_spirit, favorite_dragon_evolution_path,
    favorite_dragon_prismatic, favorite_dragon_sinister
  ) values (
    current_user_id,
    discovered_count,
    case when jsonb_typeof(favorite) = 'object'
      then nullif(left(favorite ->> 'client_id', 100), '') end,
    case when jsonb_typeof(favorite) = 'object'
      then left(nullif(btrim(favorite ->> 'name'), ''), 24) end,
    case when jsonb_typeof(favorite) = 'object'
      then favorite ->> 'lineage_id' end,
    case when jsonb_typeof(favorite) = 'object'
      then favorite ->> 'stage' end,
    case when jsonb_typeof(favorite) = 'object'
      then greatest(0, least(100000000, (favorite ->> 'xp')::integer)) end,
    case when jsonb_typeof(favorite) = 'object'
      then greatest(0, least(1000000, (favorite ->> 'might')::integer)) end,
    case when jsonb_typeof(favorite) = 'object'
      then greatest(0, least(1000000, (favorite ->> 'arcana')::integer)) end,
    case when jsonb_typeof(favorite) = 'object'
      then greatest(0, least(1000000, (favorite ->> 'spirit')::integer)) end,
    case when jsonb_typeof(favorite) = 'object'
      then favorite ->> 'evolution_path' end,
    case when jsonb_typeof(favorite) = 'object'
      then coalesce((favorite ->> 'prismatic')::boolean, false) end,
    case when jsonb_typeof(favorite) = 'object'
      then coalesce((favorite ->> 'sinister')::boolean, false) end
  )
  on conflict (user_id) do update set
    discovered_dragon_count = excluded.discovered_dragon_count,
    favorite_dragon_id = excluded.favorite_dragon_id,
    favorite_dragon_name = excluded.favorite_dragon_name,
    favorite_dragon_lineage_id = excluded.favorite_dragon_lineage_id,
    favorite_dragon_stage = excluded.favorite_dragon_stage,
    favorite_dragon_xp = excluded.favorite_dragon_xp,
    favorite_dragon_might = excluded.favorite_dragon_might,
    favorite_dragon_arcana = excluded.favorite_dragon_arcana,
    favorite_dragon_spirit = excluded.favorite_dragon_spirit,
    favorite_dragon_evolution_path = excluded.favorite_dragon_evolution_path,
    favorite_dragon_prismatic = excluded.favorite_dragon_prismatic,
    favorite_dragon_sinister = excluded.favorite_dragon_sinister,
    updated_at = now();
exception
  when invalid_text_representation or numeric_value_out_of_range
    or check_violation or not_null_violation then
    raise exception 'invalid_profile';
end;
$$;

create or replace function public.get_my_profile()
returns table (
  user_id uuid,
  keeper_code text,
  display_name text,
  title text,
  portrait_key text,
  discovered_dragon_count bigint,
  inventory_imported boolean,
  favorite_dragon_id text,
  favorite_dragon_name text,
  favorite_dragon_lineage_id text,
  favorite_dragon_stage text,
  favorite_dragon_level integer,
  favorite_dragon_might integer,
  favorite_dragon_arcana integer,
  favorite_dragon_spirit integer,
  favorite_dragon_evolution_path text,
  favorite_dragon_prismatic boolean,
  favorite_dragon_sinister boolean
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    p.user_id,
    p.keeper_code,
    p.display_name,
    p.title,
    p.portrait_key,
    coalesce(s.discovered_dragon_count, 0)::bigint,
    p.inventory_imported_at is not null,
    s.favorite_dragon_id,
    s.favorite_dragon_name,
    s.favorite_dragon_lineage_id,
    s.favorite_dragon_stage,
    private.dragon_level(coalesce(s.favorite_dragon_xp, 0)),
    s.favorite_dragon_might,
    s.favorite_dragon_arcana,
    s.favorite_dragon_spirit,
    s.favorite_dragon_evolution_path,
    s.favorite_dragon_prismatic,
    s.favorite_dragon_sinister
  from public.profiles p
  left join public.social_showcases s on s.user_id = p.user_id
  where p.user_id = auth.uid()
$$;

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
    or btrim(p_title) not in (
      'Dragon Keeper', 'Nest Guardian', 'Sky Explorer',
      'Draconomicon Scholar', 'Tower Architect'
    )
    or p_portrait_key not in ('moon', 'ember', 'forest', 'tide', 'storm') then
    raise exception 'invalid_profile';
  end if;
  update public.profiles
  set display_name = btrim(p_display_name),
      title = btrim(p_title),
      portrait_key = p_portrait_key
  where user_id = auth.uid();
end;
$$;

create or replace function public.import_legacy_inventory(p_inventory jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  profile_imported_at timestamptz;
  entry jsonb;
  favorite_already_added boolean := false;
  requested_favorite boolean;
begin
  if current_user_id is null or jsonb_typeof(p_inventory) <> 'object' then
    raise exception 'invalid_inventory';
  end if;
  select inventory_imported_at into profile_imported_at
  from public.profiles where user_id = current_user_id for update;
  if not found then raise exception 'profile_not_found'; end if;
  if profile_imported_at is not null then
    raise exception 'inventory_already_imported';
  end if;
  if jsonb_typeof(coalesce(p_inventory -> 'dragons', '[]'::jsonb)) <> 'array'
    or jsonb_typeof(coalesce(p_inventory -> 'eggs', '[]'::jsonb)) <> 'array'
    or jsonb_typeof(coalesce(p_inventory -> 'furniture_catalog_ids', '[]'::jsonb)) <> 'array'
    or jsonb_typeof(coalesce(p_inventory -> 'discovered_lineage_ids', '[]'::jsonb)) <> 'array'
    or jsonb_array_length(coalesce(p_inventory -> 'dragons', '[]'::jsonb)) > 250
    or jsonb_array_length(coalesce(p_inventory -> 'eggs', '[]'::jsonb)) > 500
    or jsonb_array_length(coalesce(p_inventory -> 'furniture_catalog_ids', '[]'::jsonb)) > 500
    or jsonb_array_length(coalesce(p_inventory -> 'discovered_lineage_ids', '[]'::jsonb)) > 100 then
    raise exception 'invalid_inventory';
  end if;

  update public.player_wallets
  set coins = greatest(0, least(100000000, (p_inventory ->> 'coins')::bigint)),
      gems = greatest(0, least(1000000, (p_inventory ->> 'gems')::bigint)),
      revision = revision + 1,
      updated_at = now()
  where user_id = current_user_id;

  for entry in select value from jsonb_array_elements(
    coalesce(p_inventory -> 'dragons', '[]'::jsonb)
  ) loop
    requested_favorite := coalesce((entry ->> 'favorite')::boolean, false);
    insert into public.player_dragons(
      owner_id, legacy_client_id, name, lineage_id, stage, xp,
      might, arcana, spirit, evolution_path, favorite, prismatic, sinister
    ) values (
      current_user_id,
      nullif(left(entry ->> 'client_id', 100), ''),
      left(coalesce(nullif(btrim(entry ->> 'name'), ''), 'Dragon'), 24),
      entry ->> 'lineage_id',
      entry ->> 'stage',
      greatest(0, least(100000000, (entry ->> 'xp')::integer)),
      greatest(0, least(1000000, (entry ->> 'might')::integer)),
      greatest(0, least(1000000, (entry ->> 'arcana')::integer)),
      greatest(0, least(1000000, (entry ->> 'spirit')::integer)),
      case when entry ->> 'evolution_path' in ('might', 'arcana', 'spirit')
        then entry ->> 'evolution_path' else 'spirit' end,
      requested_favorite and not favorite_already_added,
      coalesce((entry ->> 'prismatic')::boolean, false),
      coalesce((entry ->> 'sinister')::boolean, false)
    );
    favorite_already_added := favorite_already_added or requested_favorite;
  end loop;

  for entry in select value from jsonb_array_elements(
    coalesce(p_inventory -> 'eggs', '[]'::jsonb)
  ) loop
    insert into public.player_eggs(
      owner_id, legacy_client_id, lineage_id, acquired_at, prismatic, sinister
    ) values (
      current_user_id,
      nullif(left(entry ->> 'client_id', 100), ''),
      entry ->> 'lineage_id',
      coalesce((entry ->> 'acquired_at')::timestamptz, now()),
      coalesce((entry ->> 'prismatic')::boolean, false),
      coalesce((entry ->> 'sinister')::boolean, false)
    );
  end loop;

  insert into public.player_chests(owner_id, tier, quantity)
  select current_user_id, tier, greatest(0, least(1000000,
    coalesce((p_inventory -> 'chests' ->> tier)::integer, 0)))
  from unnest(array['wooden', 'silver', 'gold', 'dragon', 'mythical', 'sinister']) tier;

  insert into public.furniture_instances(owner_id, catalog_item_id)
  select current_user_id, value
  from jsonb_array_elements_text(
    coalesce(p_inventory -> 'furniture_catalog_ids', '[]'::jsonb)
  ) as value
  where value ~ '^[a-z0-9_]{1,80}$'
  on conflict (owner_id, catalog_item_id) do nothing;

  insert into public.discovered_lineages(owner_id, lineage_id)
  select current_user_id, value
  from jsonb_array_elements_text(
    coalesce(p_inventory -> 'discovered_lineage_ids', '[]'::jsonb)
  ) as value
  where value ~ '^[a-z0-9_]{1,64}$'
  on conflict (owner_id, lineage_id) do nothing;

  update public.profiles set inventory_imported_at = now()
  where user_id = current_user_id;
exception
  when invalid_text_representation or numeric_value_out_of_range or check_violation then
    raise exception 'invalid_inventory';
end;
$$;

create or replace function public.send_friend_request(p_keeper_code text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  target_user_id uuid;
  existing public.friendships%rowtype;
  result_id uuid;
begin
  if current_user_id is null then raise exception 'keeper_unavailable'; end if;
  select user_id into target_user_id from public.profiles
  where keeper_code = upper(btrim(p_keeper_code));
  if target_user_id is null then raise exception 'keeper_not_found'; end if;
  if target_user_id = current_user_id then raise exception 'cannot_friend_self'; end if;
  if (select count(*) from public.friendships
      where requester_id = current_user_id and status = 'pending') >= 50 then
    raise exception 'too_many_requests';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    least(current_user_id::text, target_user_id::text) || ':' ||
    greatest(current_user_id::text, target_user_id::text), 0
  ));

  select * into existing from public.friendships
  where (requester_id = current_user_id and addressee_id = target_user_id)
     or (requester_id = target_user_id and addressee_id = current_user_id)
  for update;

  if found then
    if existing.status = 'blocked' then raise exception 'keeper_unavailable'; end if;
    if existing.status = 'accepted' then raise exception 'already_friends'; end if;
    if existing.status = 'pending' then
      if existing.addressee_id = current_user_id then
        update public.friendships set status = 'accepted', responded_at = now()
        where id = existing.id returning id into result_id;
        return result_id;
      end if;
      raise exception 'request_already_pending';
    end if;
    if existing.status = 'rejected'
      and existing.updated_at > now() - interval '24 hours' then
      raise exception 'request_recently_rejected';
    end if;
    update public.friendships
    set requester_id = current_user_id,
        addressee_id = target_user_id,
        status = 'pending',
        blocked_by = null,
        created_at = now(),
        responded_at = null
    where id = existing.id returning id into result_id;
    return result_id;
  end if;

  insert into public.friendships(requester_id, addressee_id)
  values (current_user_id, target_user_id)
  returning id into result_id;
  return result_id;
end;
$$;

create or replace function public.respond_friend_request(
  p_request_id uuid,
  p_response text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if p_response not in ('accepted', 'rejected', 'blocked') then
    raise exception 'invalid_response';
  end if;
  update public.friendships
  set status = p_response,
      blocked_by = case when p_response = 'blocked' then current_user_id end,
      responded_at = now()
  where id = p_request_id and status = 'pending'
    and addressee_id = current_user_id;
  if not found then raise exception 'request_not_found'; end if;
end;
$$;

create or replace function public.remove_friend(p_friend_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.friendships
  where status = 'accepted'
    and ((requester_id = auth.uid() and addressee_id = p_friend_id)
      or (requester_id = p_friend_id and addressee_id = auth.uid()));
  if not found then raise exception 'request_not_found'; end if;
end;
$$;

create or replace function public.block_keeper(p_keeper_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  existing public.friendships%rowtype;
begin
  if current_user_id is null or p_keeper_id = current_user_id
    or not exists (select 1 from public.profiles where user_id = p_keeper_id) then
    raise exception 'keeper_unavailable';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(
    least(current_user_id::text, p_keeper_id::text) || ':' ||
    greatest(current_user_id::text, p_keeper_id::text), 0
  ));
  select * into existing from public.friendships
  where (requester_id = current_user_id and addressee_id = p_keeper_id)
     or (requester_id = p_keeper_id and addressee_id = current_user_id)
  for update;
  if not found then
    insert into public.friendships(
      requester_id, addressee_id, status, blocked_by, responded_at
    ) values (current_user_id, p_keeper_id, 'blocked', current_user_id, now());
  elsif existing.status = 'blocked' and existing.blocked_by <> current_user_id then
    raise exception 'keeper_unavailable';
  else
    update public.friendships set status = 'blocked',
      blocked_by = current_user_id, responded_at = now()
    where id = existing.id;
  end if;
end;
$$;

create or replace function public.unblock_keeper(p_keeper_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.friendships
  where status = 'blocked' and blocked_by = auth.uid()
    and ((requester_id = auth.uid() and addressee_id = p_keeper_id)
      or (requester_id = p_keeper_id and addressee_id = auth.uid()));
  if not found then raise exception 'request_not_found'; end if;
end;
$$;

create or replace function public.list_my_friends()
returns table (
  user_id uuid, keeper_code text, display_name text, title text,
  portrait_key text, discovered_dragon_count bigint,
  inventory_imported boolean,
  favorite_dragon_id text, favorite_dragon_name text,
  favorite_dragon_lineage_id text, favorite_dragon_stage text,
  favorite_dragon_level integer, favorite_dragon_might integer,
  favorite_dragon_arcana integer, favorite_dragon_spirit integer,
  favorite_dragon_evolution_path text, favorite_dragon_prismatic boolean,
  favorite_dragon_sinister boolean
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    p.user_id, p.keeper_code, p.display_name, p.title, p.portrait_key,
    coalesce(s.discovered_dragon_count, 0)::bigint,
    p.inventory_imported_at is not null,
    s.favorite_dragon_id, s.favorite_dragon_name,
    s.favorite_dragon_lineage_id, s.favorite_dragon_stage,
    private.dragon_level(coalesce(s.favorite_dragon_xp, 0)),
    s.favorite_dragon_might, s.favorite_dragon_arcana,
    s.favorite_dragon_spirit, s.favorite_dragon_evolution_path,
    s.favorite_dragon_prismatic, s.favorite_dragon_sinister
  from public.friendships f
  join public.profiles p on p.user_id = case
    when f.requester_id = auth.uid() then f.addressee_id else f.requester_id end
  left join public.social_showcases s on s.user_id = p.user_id
  where f.status = 'accepted'
    and auth.uid() in (f.requester_id, f.addressee_id)
  order by lower(p.display_name), p.user_id
$$;

create or replace function public.list_friend_requests()
returns table (
  request_id uuid, direction text, created_at timestamptz,
  user_id uuid, keeper_code text, display_name text, title text,
  portrait_key text, discovered_dragon_count bigint,
  inventory_imported boolean,
  favorite_dragon_id text, favorite_dragon_name text,
  favorite_dragon_lineage_id text, favorite_dragon_stage text,
  favorite_dragon_level integer, favorite_dragon_might integer,
  favorite_dragon_arcana integer, favorite_dragon_spirit integer,
  favorite_dragon_evolution_path text, favorite_dragon_prismatic boolean,
  favorite_dragon_sinister boolean
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    f.id,
    case when f.addressee_id = auth.uid() then 'incoming' else 'outgoing' end,
    f.created_at,
    p.user_id, p.keeper_code, p.display_name, p.title, p.portrait_key,
    0::bigint,
    p.inventory_imported_at is not null,
    null::text, null::text, null::text, null::text, null::integer,
    null::integer, null::integer, null::integer, null::text,
    null::boolean, null::boolean
  from public.friendships f
  join public.profiles p on p.user_id = case
    when f.requester_id = auth.uid() then f.addressee_id else f.requester_id end
  where f.status = 'pending'
    and auth.uid() in (f.requester_id, f.addressee_id)
  order by f.created_at desc
$$;

create or replace function public.list_blocked_keepers()
returns table (
  user_id uuid, keeper_code text, display_name text, title text,
  portrait_key text, discovered_dragon_count bigint,
  inventory_imported boolean,
  favorite_dragon_id text, favorite_dragon_name text,
  favorite_dragon_lineage_id text, favorite_dragon_stage text,
  favorite_dragon_level integer, favorite_dragon_might integer,
  favorite_dragon_arcana integer, favorite_dragon_spirit integer,
  favorite_dragon_evolution_path text, favorite_dragon_prismatic boolean,
  favorite_dragon_sinister boolean
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    p.user_id, p.keeper_code, p.display_name, p.title, p.portrait_key,
    0::bigint, true,
    null::text, null::text, null::text, null::text, null::integer,
    null::integer, null::integer, null::integer, null::text,
    null::boolean, null::boolean
  from public.friendships f
  join public.profiles p on p.user_id = case
    when f.requester_id = auth.uid() then f.addressee_id else f.requester_id end
  where f.status = 'blocked' and f.blocked_by = auth.uid()
  order by lower(p.display_name), p.user_id
$$;

revoke all on function public.get_my_profile() from public, anon;
revoke all on function public.publish_social_showcase(jsonb) from public, anon;
revoke all on function public.update_my_profile(text, text, text) from public, anon;
revoke all on function public.import_legacy_inventory(jsonb) from public, anon;
revoke all on function public.send_friend_request(text) from public, anon;
revoke all on function public.respond_friend_request(uuid, text) from public, anon;
revoke all on function public.remove_friend(uuid) from public, anon;
revoke all on function public.block_keeper(uuid) from public, anon;
revoke all on function public.unblock_keeper(uuid) from public, anon;
revoke all on function public.list_my_friends() from public, anon;
revoke all on function public.list_friend_requests() from public, anon;
revoke all on function public.list_blocked_keepers() from public, anon;

grant execute on function public.get_my_profile() to authenticated;
grant execute on function public.publish_social_showcase(jsonb) to authenticated;
grant execute on function public.update_my_profile(text, text, text) to authenticated;
grant execute on function public.import_legacy_inventory(jsonb) to authenticated;
grant execute on function public.send_friend_request(text) to authenticated;
grant execute on function public.respond_friend_request(uuid, text) to authenticated;
grant execute on function public.remove_friend(uuid) to authenticated;
grant execute on function public.block_keeper(uuid) to authenticated;
grant execute on function public.unblock_keeper(uuid) to authenticated;
grant execute on function public.list_my_friends() to authenticated;
grant execute on function public.list_friend_requests() to authenticated;
grant execute on function public.list_blocked_keepers() to authenticated;
