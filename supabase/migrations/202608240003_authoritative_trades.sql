-- Server-owned, one-for-one asynchronous trades. Local inventory is mirrored
-- into the normalized ledger only while items are not held in an active trade;
-- reservations and the final swap are always validated and committed here.

alter table public.player_eggs
  add column hatch_seed bigint not null default 0 check (hatch_seed >= 0),
  add column law_axis text not null default 'neutral'
    check (law_axis in ('lawful', 'neutral', 'chaotic')),
  add column moral_axis text not null default 'neutral'
    check (moral_axis in ('good', 'neutral', 'evil')),
  add column size_factor double precision not null default 1
    check (size_factor between 0.5 and 1.5),
  add column incubation_minutes integer not null default 1008
    check (incubation_minutes between 1 and 20160),
  add column xp integer not null default 0 check (xp >= 0);

alter table public.player_chests
  drop constraint if exists player_chests_tier_check;
alter table public.player_chests add constraint player_chests_tier_check check (
  tier in (
    'wooden', 'silver', 'gold', 'dragon', 'mythical', 'sinister',
    'portrait', 'title'
  )
);

create table public.player_relics (
  owner_id uuid not null references public.profiles(user_id) on delete cascade,
  relic_type text not null
    check (relic_type in ('moralPrism', 'orderCompass', 'soulMirror')),
  quantity integer not null default 0 check (quantity >= 0),
  updated_at timestamptz not null default now(),
  primary key (owner_id, relic_type)
);

create table public.trades (
  id uuid primary key default gen_random_uuid(),
  initiator_id uuid not null references public.profiles(user_id) on delete cascade,
  recipient_id uuid not null references public.profiles(user_id) on delete cascade,
  status text not null default 'awaiting_recipient' check (
    status in (
      'awaiting_recipient', 'awaiting_initiator', 'completed',
      'cancelled', 'rejected'
    )
  ),
  initiator_item jsonb not null default '{}'::jsonb,
  recipient_item jsonb,
  initiator_acknowledged_at timestamptz,
  recipient_acknowledged_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  check (initiator_id <> recipient_id)
);

create index trades_initiator_status_idx
  on public.trades(initiator_id, status, updated_at desc);
create index trades_recipient_status_idx
  on public.trades(recipient_id, status, updated_at desc);

create table public.trade_reservations (
  trade_id uuid not null references public.trades(id) on delete cascade,
  side text not null check (side in ('initiator', 'recipient')),
  owner_id uuid not null references public.profiles(user_id) on delete cascade,
  item_type text not null check (item_type in ('egg', 'chest', 'relic')),
  item_key text not null check (char_length(item_key) between 1 and 100),
  created_at timestamptz not null default now(),
  primary key (trade_id, side)
);

create index trade_reservations_owner_item_idx
  on public.trade_reservations(owner_id, item_type, item_key);
create unique index trade_reservations_unique_egg
  on public.trade_reservations(owner_id, item_key)
  where item_type = 'egg';

alter table public.player_relics enable row level security;
alter table public.trades enable row level security;
alter table public.trade_reservations enable row level security;
revoke all on table public.player_relics from anon, authenticated;
revoke all on table public.trades from anon, authenticated;
revoke all on table public.trade_reservations from anon, authenticated;

create trigger trades_touch_updated_at
before update on public.trades
for each row execute function private.touch_updated_at();

create or replace function private.trade_users_are_friends(
  p_first uuid,
  p_second uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and ((f.requester_id = p_first and f.addressee_id = p_second)
        or (f.requester_id = p_second and f.addressee_id = p_first))
  )
$$;

create or replace function private.trade_egg_data(p_egg public.player_eggs)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select jsonb_build_object(
    'id', p_egg.legacy_client_id,
    'lineageId', p_egg.lineage_id,
    'acquiredAt', p_egg.acquired_at,
    'hatchSeed', p_egg.hatch_seed,
    'prismatic', p_egg.prismatic,
    'spectral', p_egg.prismatic,
    'lawAxis', p_egg.law_axis,
    'moralAxis', p_egg.moral_axis,
    'sizeFactor', p_egg.size_factor,
    'incubationMinutes', p_egg.incubation_minutes,
    'sinister', p_egg.sinister,
    'xp', p_egg.xp
  )
$$;

create or replace function private.reserve_trade_item(
  p_trade_id uuid,
  p_side text,
  p_owner_id uuid,
  p_item jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_type text := p_item ->> 'kind';
  requested_key text := p_item ->> 'key';
  egg public.player_eggs%rowtype;
  owned_quantity integer;
  reserved_quantity integer;
begin
  if p_side not in ('initiator', 'recipient')
    or requested_type not in ('egg', 'chest', 'relic')
    or requested_key is null
    or char_length(requested_key) not between 1 and 100 then
    raise exception 'trade_item_invalid';
  end if;

  if requested_type = 'egg' then
    select * into egg from public.player_eggs
    where owner_id = p_owner_id and legacy_client_id = requested_key
    for update;
    if not found or exists (
      select 1 from public.trade_reservations r
      where r.owner_id = p_owner_id and r.item_type = 'egg'
        and r.item_key = requested_key
    ) then
      raise exception 'trade_item_unavailable';
    end if;
    insert into public.trade_reservations(
      trade_id, side, owner_id, item_type, item_key
    ) values (p_trade_id, p_side, p_owner_id, requested_type, requested_key);
    return jsonb_build_object(
      'kind', 'egg', 'key', requested_key,
      'data', private.trade_egg_data(egg)
    );
  end if;

  if requested_type = 'chest' then
    if requested_key not in (
      'wooden', 'silver', 'gold', 'dragon', 'mythical', 'sinister',
      'portrait', 'title'
    ) then raise exception 'trade_item_invalid'; end if;
    select quantity into owned_quantity from public.player_chests
    where owner_id = p_owner_id and tier = requested_key for update;
  else
    if requested_key not in ('moralPrism', 'orderCompass', 'soulMirror') then
      raise exception 'trade_item_invalid';
    end if;
    select quantity into owned_quantity from public.player_relics
    where owner_id = p_owner_id and relic_type = requested_key for update;
  end if;

  select count(*)::integer into reserved_quantity
  from public.trade_reservations r
  where r.owner_id = p_owner_id and r.item_type = requested_type
    and r.item_key = requested_key;
  if coalesce(owned_quantity, 0) <= reserved_quantity then
    raise exception 'trade_item_unavailable';
  end if;
  insert into public.trade_reservations(
    trade_id, side, owner_id, item_type, item_key
  ) values (p_trade_id, p_side, p_owner_id, requested_type, requested_key);
  return jsonb_build_object(
    'kind', requested_type, 'key', requested_key, 'data', '{}'::jsonb
  );
end;
$$;

create or replace function public.synchronize_trade_inventory(p_inventory jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  entry jsonb;
  tier text;
  relic text;
  requested integer;
  reserved integer;
begin
  if current_user_id is null or jsonb_typeof(p_inventory) <> 'object'
    or jsonb_typeof(coalesce(p_inventory -> 'eggs', '[]'::jsonb)) <> 'array'
    or jsonb_typeof(coalesce(p_inventory -> 'chests', '{}'::jsonb)) <> 'object'
    or jsonb_typeof(coalesce(p_inventory -> 'relics', '{}'::jsonb)) <> 'object'
    or jsonb_array_length(coalesce(p_inventory -> 'eggs', '[]'::jsonb)) > 500 then
    raise exception 'invalid_inventory';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(current_user_id::text, 0));

  delete from public.player_eggs e
  where e.owner_id = current_user_id
    and not exists (
      select 1 from public.trade_reservations r
      where r.owner_id = current_user_id and r.item_type = 'egg'
        and r.item_key = e.legacy_client_id
    )
    and not exists (
      select 1 from jsonb_array_elements(
        coalesce(p_inventory -> 'eggs', '[]'::jsonb)
      ) value where value ->> 'client_id' = e.legacy_client_id
    );

  for entry in select value from jsonb_array_elements(
    coalesce(p_inventory -> 'eggs', '[]'::jsonb)
  ) loop
    if coalesce(entry ->> 'client_id', '') = ''
      or char_length(entry ->> 'client_id') > 100
      or coalesce(entry ->> 'lineage_id', '') !~ '^[a-z0-9_]{1,64}$' then
      raise exception 'invalid_inventory';
    end if;
    insert into public.player_eggs(
      owner_id, legacy_client_id, lineage_id, acquired_at, hatch_seed,
      prismatic, law_axis, moral_axis, size_factor, incubation_minutes,
      sinister, xp
    ) values (
      current_user_id,
      entry ->> 'client_id',
      entry ->> 'lineage_id',
      coalesce((entry ->> 'acquired_at')::timestamptz, now()),
      greatest(0, coalesce((entry ->> 'hatch_seed')::bigint, 0)),
      coalesce((entry ->> 'prismatic')::boolean, false),
      case when entry ->> 'law_axis' in ('lawful', 'neutral', 'chaotic')
        then entry ->> 'law_axis' else 'neutral' end,
      case when entry ->> 'moral_axis' in ('good', 'neutral', 'evil')
        then entry ->> 'moral_axis' else 'neutral' end,
      greatest(0.5, least(1.5,
        coalesce((entry ->> 'size_factor')::double precision, 1))),
      greatest(1, least(20160,
        coalesce((entry ->> 'incubation_minutes')::integer, 1008))),
      coalesce((entry ->> 'sinister')::boolean, false),
      greatest(0, least(100000000,
        coalesce((entry ->> 'xp')::integer, 0)))
    ) on conflict (owner_id, legacy_client_id) do update set
      lineage_id = excluded.lineage_id,
      acquired_at = excluded.acquired_at,
      hatch_seed = excluded.hatch_seed,
      prismatic = excluded.prismatic,
      law_axis = excluded.law_axis,
      moral_axis = excluded.moral_axis,
      size_factor = excluded.size_factor,
      incubation_minutes = excluded.incubation_minutes,
      sinister = excluded.sinister,
      xp = excluded.xp;
  end loop;

  foreach tier in array array[
    'wooden', 'silver', 'gold', 'dragon', 'mythical', 'sinister',
    'portrait', 'title'
  ] loop
    requested := greatest(0, least(1000000,
      coalesce((p_inventory -> 'chests' ->> tier)::integer, 0)));
    select count(*)::integer into reserved
    from public.trade_reservations r
    where r.owner_id = current_user_id and r.item_type = 'chest'
      and r.item_key = tier;
    insert into public.player_chests(owner_id, tier, quantity)
    values (current_user_id, tier, greatest(requested, reserved))
    on conflict (owner_id, tier) do update set
      quantity = greatest(excluded.quantity, reserved), updated_at = now();
  end loop;

  foreach relic in array array['moralPrism', 'orderCompass', 'soulMirror'] loop
    requested := greatest(0, least(1000000,
      coalesce((p_inventory -> 'relics' ->> relic)::integer, 0)));
    select count(*)::integer into reserved
    from public.trade_reservations r
    where r.owner_id = current_user_id and r.item_type = 'relic'
      and r.item_key = relic;
    insert into public.player_relics(owner_id, relic_type, quantity)
    values (current_user_id, relic, greatest(requested, reserved))
    on conflict (owner_id, relic_type) do update set
      quantity = greatest(excluded.quantity, reserved), updated_at = now();
  end loop;
exception
  when invalid_text_representation or numeric_value_out_of_range then
    raise exception 'invalid_inventory';
end;
$$;

create or replace function public.list_trade_inventory()
returns table (
  item_type text,
  item_key text,
  available integer,
  item_data jsonb
)
language sql
security definer
set search_path = ''
stable
as $$
  select 'egg'::text, e.legacy_client_id, 1,
    private.trade_egg_data(e)
  from public.player_eggs e
  where e.owner_id = auth.uid()
    and not exists (
      select 1 from public.trade_reservations r
      where r.owner_id = e.owner_id and r.item_type = 'egg'
        and r.item_key = e.legacy_client_id
    )
  union all
  select 'chest'::text, c.tier,
    (c.quantity - count(r.trade_id))::integer, '{}'::jsonb
  from public.player_chests c
  left join public.trade_reservations r
    on r.owner_id = c.owner_id and r.item_type = 'chest'
      and r.item_key = c.tier
  where c.owner_id = auth.uid()
  group by c.owner_id, c.tier, c.quantity
  having c.quantity - count(r.trade_id) > 0
  union all
  select 'relic'::text, x.relic_type,
    (x.quantity - count(r.trade_id))::integer, '{}'::jsonb
  from public.player_relics x
  left join public.trade_reservations r
    on r.owner_id = x.owner_id and r.item_type = 'relic'
      and r.item_key = x.relic_type
  where x.owner_id = auth.uid()
  group by x.owner_id, x.relic_type, x.quantity
  having x.quantity - count(r.trade_id) > 0
  order by 1, 2
$$;

create or replace function public.create_trade(p_friend_id uuid, p_item jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  result_id uuid;
  snapshot jsonb;
begin
  if current_user_id is null then raise exception 'trade_wrong_participant'; end if;
  if not private.trade_users_are_friends(current_user_id, p_friend_id) then
    raise exception 'trade_not_friends';
  end if;
  if (select count(*) from public.trades t
      where current_user_id in (t.initiator_id, t.recipient_id)
        and t.status in ('awaiting_recipient', 'awaiting_initiator')) >= 20 then
    raise exception 'trade_inventory_locked';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(current_user_id::text, 0));
  insert into public.trades(initiator_id, recipient_id)
  values (current_user_id, p_friend_id) returning id into result_id;
  snapshot := private.reserve_trade_item(
    result_id, 'initiator', current_user_id, p_item
  );
  update public.trades set initiator_item = snapshot where id = result_id;
  return result_id;
end;
$$;

create or replace function public.respond_trade(p_trade_id uuid, p_item jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  trade public.trades%rowtype;
  snapshot jsonb;
begin
  select * into trade from public.trades where id = p_trade_id for update;
  if not found then raise exception 'trade_not_found'; end if;
  if current_user_id is null or trade.recipient_id <> current_user_id then
    raise exception 'trade_wrong_participant';
  end if;
  if trade.status <> 'awaiting_recipient' then
    raise exception 'trade_wrong_state';
  end if;
  if not private.trade_users_are_friends(trade.initiator_id, trade.recipient_id) then
    raise exception 'trade_not_friends';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(current_user_id::text, 0));
  snapshot := private.reserve_trade_item(
    trade.id, 'recipient', current_user_id, p_item
  );
  update public.trades set recipient_item = snapshot,
    status = 'awaiting_initiator'
  where id = trade.id;
end;
$$;

create or replace function private.transfer_trade_item(
  p_from uuid,
  p_to uuid,
  p_item jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  item_type text := p_item ->> 'kind';
  item_key text := p_item ->> 'key';
begin
  if item_type = 'egg' then
    if exists (
      select 1 from public.player_eggs
      where owner_id = p_to and legacy_client_id = item_key
    ) then raise exception 'trade_item_unavailable'; end if;
    update public.player_eggs set owner_id = p_to
    where owner_id = p_from and legacy_client_id = item_key;
    if not found then raise exception 'trade_item_unavailable'; end if;
  elsif item_type = 'chest' then
    update public.player_chests set quantity = quantity - 1, updated_at = now()
    where owner_id = p_from and tier = item_key and quantity > 0;
    if not found then raise exception 'trade_item_unavailable'; end if;
    insert into public.player_chests(owner_id, tier, quantity)
    values (p_to, item_key, 1)
    on conflict (owner_id, tier) do update set
      quantity = public.player_chests.quantity + 1, updated_at = now();
  elsif item_type = 'relic' then
    update public.player_relics set quantity = quantity - 1, updated_at = now()
    where owner_id = p_from and relic_type = item_key and quantity > 0;
    if not found then raise exception 'trade_item_unavailable'; end if;
    insert into public.player_relics(owner_id, relic_type, quantity)
    values (p_to, item_key, 1)
    on conflict (owner_id, relic_type) do update set
      quantity = public.player_relics.quantity + 1, updated_at = now();
  else
    raise exception 'trade_item_invalid';
  end if;
end;
$$;

create or replace function public.complete_trade(p_trade_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  trade public.trades%rowtype;
begin
  select * into trade from public.trades where id = p_trade_id for update;
  if not found then raise exception 'trade_not_found'; end if;
  if current_user_id is null or trade.initiator_id <> current_user_id then
    raise exception 'trade_wrong_participant';
  end if;
  if trade.status <> 'awaiting_initiator' or trade.recipient_item is null then
    raise exception 'trade_wrong_state';
  end if;
  if not private.trade_users_are_friends(trade.initiator_id, trade.recipient_id) then
    raise exception 'trade_not_friends';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(
    least(trade.initiator_id::text, trade.recipient_id::text), 0
  ));
  perform pg_advisory_xact_lock(hashtextextended(
    greatest(trade.initiator_id::text, trade.recipient_id::text), 0
  ));
  perform private.transfer_trade_item(
    trade.initiator_id, trade.recipient_id, trade.initiator_item
  );
  perform private.transfer_trade_item(
    trade.recipient_id, trade.initiator_id, trade.recipient_item
  );
  update public.trades set status = 'completed', completed_at = now()
  where id = trade.id;
  delete from public.trade_reservations where trade_id = trade.id;
end;
$$;

create or replace function public.cancel_trade(p_trade_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  update public.trades set status = 'cancelled'
  where id = p_trade_id and initiator_id = current_user_id
    and status in ('awaiting_recipient', 'awaiting_initiator');
  if not found then raise exception 'trade_wrong_state'; end if;
  delete from public.trade_reservations where trade_id = p_trade_id;
end;
$$;

create or replace function public.reject_trade(p_trade_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  update public.trades set status = 'rejected'
  where id = p_trade_id and recipient_id = current_user_id
    and status in ('awaiting_recipient', 'awaiting_initiator');
  if not found then raise exception 'trade_wrong_state'; end if;
  delete from public.trade_reservations where trade_id = p_trade_id;
end;
$$;

create or replace function public.acknowledge_trade(p_trade_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  update public.trades set
    initiator_acknowledged_at = case when initiator_id = current_user_id
      then coalesce(initiator_acknowledged_at, now())
      else initiator_acknowledged_at end,
    recipient_acknowledged_at = case when recipient_id = current_user_id
      then coalesce(recipient_acknowledged_at, now())
      else recipient_acknowledged_at end
  where id = p_trade_id and status = 'completed'
    and current_user_id in (initiator_id, recipient_id);
  if not found then raise exception 'trade_not_found'; end if;
end;
$$;

create or replace function public.list_my_trades()
returns table (
  trade_id uuid,
  status text,
  initiator_id uuid,
  recipient_id uuid,
  am_initiator boolean,
  initiator_item jsonb,
  recipient_item jsonb,
  my_acknowledged boolean,
  created_at timestamptz,
  updated_at timestamptz,
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
    t.id, t.status, t.initiator_id, t.recipient_id,
    t.initiator_id = auth.uid(), t.initiator_item, t.recipient_item,
    case when t.initiator_id = auth.uid()
      then t.initiator_acknowledged_at is not null
      else t.recipient_acknowledged_at is not null end,
    t.created_at, t.updated_at,
    p.user_id, p.keeper_code, p.display_name, p.title, p.portrait_key,
    coalesce(s.discovered_dragon_count, 0)::bigint,
    p.inventory_imported_at is not null,
    s.favorite_dragon_id, s.favorite_dragon_name,
    s.favorite_dragon_lineage_id, s.favorite_dragon_stage,
    private.dragon_level(coalesce(s.favorite_dragon_xp, 0)),
    s.favorite_dragon_might, s.favorite_dragon_arcana,
    s.favorite_dragon_spirit, s.favorite_dragon_evolution_path,
    s.favorite_dragon_prismatic, s.favorite_dragon_sinister
  from public.trades t
  join public.profiles p on p.user_id = case
    when t.initiator_id = auth.uid() then t.recipient_id else t.initiator_id end
  left join public.social_showcases s on s.user_id = p.user_id
  where auth.uid() in (t.initiator_id, t.recipient_id)
    and (
      t.status in ('awaiting_recipient', 'awaiting_initiator')
      or (t.status = 'completed' and (
        (t.initiator_id = auth.uid() and t.initiator_acknowledged_at is null)
        or (t.recipient_id = auth.uid() and t.recipient_acknowledged_at is null)
      ))
      or t.updated_at > now() - interval '7 days'
    )
  order by
    (t.status in ('awaiting_recipient', 'awaiting_initiator')) desc,
    t.updated_at desc
$$;

revoke all on function private.trade_users_are_friends(uuid, uuid)
  from public, anon, authenticated;
revoke all on function private.trade_egg_data(public.player_eggs)
  from public, anon, authenticated;
revoke all on function private.reserve_trade_item(uuid, text, uuid, jsonb)
  from public, anon, authenticated;
revoke all on function private.transfer_trade_item(uuid, uuid, jsonb)
  from public, anon, authenticated;

revoke all on function public.synchronize_trade_inventory(jsonb) from public, anon;
revoke all on function public.list_trade_inventory() from public, anon;
revoke all on function public.create_trade(uuid, jsonb) from public, anon;
revoke all on function public.respond_trade(uuid, jsonb) from public, anon;
revoke all on function public.complete_trade(uuid) from public, anon;
revoke all on function public.cancel_trade(uuid) from public, anon;
revoke all on function public.reject_trade(uuid) from public, anon;
revoke all on function public.acknowledge_trade(uuid) from public, anon;
revoke all on function public.list_my_trades() from public, anon;

grant execute on function public.synchronize_trade_inventory(jsonb) to authenticated;
grant execute on function public.list_trade_inventory() to authenticated;
grant execute on function public.create_trade(uuid, jsonb) to authenticated;
grant execute on function public.respond_trade(uuid, jsonb) to authenticated;
grant execute on function public.complete_trade(uuid) to authenticated;
grant execute on function public.cancel_trade(uuid) to authenticated;
grant execute on function public.reject_trade(uuid) to authenticated;
grant execute on function public.acknowledge_trade(uuid) to authenticated;
grant execute on function public.list_my_trades() to authenticated;
