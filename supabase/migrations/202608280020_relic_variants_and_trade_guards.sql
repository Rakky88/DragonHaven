-- Add the three tradeable gameplay Relics introduced in v0.04.06 while
-- keeping shop copies client-side/nontradeable. Chronoshards carry a fixed
-- 10-90% value, so their authoritative trade snapshot preserves that value.
-- Music Chests and the unique Twinstar Brooch remain rejected server-side.

alter table public.player_relics
  drop constraint if exists player_relics_relic_type_check;
alter table public.player_relics add constraint player_relics_relic_type_check
  check (relic_type in (
    'moralPrism', 'orderCompass', 'soulMirror', 'astralLens',
    'chronoshard', 'wayfinderSigil'
  ));
alter table public.player_relics
  add column item_data jsonb not null default '{}'::jsonb
    check (jsonb_typeof(item_data) = 'object');

create or replace function private.remove_int_once(
  p_values jsonb,
  p_target integer
)
returns jsonb
language plpgsql
immutable
set search_path = ''
as $$
declare
  value jsonb;
  result jsonb := '[]'::jsonb;
  removed boolean := false;
begin
  if jsonb_typeof(coalesce(p_values, '[]'::jsonb)) <> 'array' then
    return result;
  end if;
  for value in
    select element
    from jsonb_array_elements(p_values) as values_table(element)
  loop
    if not removed and jsonb_typeof(value) = 'number'
      and (value #>> '{}')::integer = p_target then
      removed := true;
    else
      result := result || jsonb_build_array(value);
    end if;
  end loop;
  return result;
exception
  when invalid_text_representation or numeric_value_out_of_range then
    return '[]'::jsonb;
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
  chest_tier text;
  relic text;
  requested integer;
  reserved integer;
  reductions jsonb;
begin
  if current_user_id is null or jsonb_typeof(p_inventory) <> 'object'
    or jsonb_typeof(coalesce(p_inventory -> 'eggs', '[]'::jsonb)) <> 'array'
    or jsonb_typeof(coalesce(p_inventory -> 'chests', '{}'::jsonb)) <> 'object'
    or jsonb_typeof(coalesce(p_inventory -> 'relics', '{}'::jsonb)) <> 'object'
    or jsonb_typeof(coalesce(p_inventory -> 'relic_variants', '{}'::jsonb)) <> 'object'
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

  foreach chest_tier in array array[
    'wooden', 'silver', 'gold', 'dragon', 'mythical', 'sinister',
    'portrait', 'title'
  ] loop
    requested := greatest(0, least(1000000,
      coalesce((p_inventory -> 'chests' ->> chest_tier)::integer, 0)));
    select count(*)::integer into reserved
    from public.trade_reservations r
    where r.owner_id = current_user_id and r.item_type = 'chest'
      and r.item_key = chest_tier;
    insert into public.player_chests(owner_id, tier, quantity)
    values (current_user_id, chest_tier, greatest(requested, reserved))
    on conflict (owner_id, tier) do update set
      quantity = greatest(excluded.quantity, reserved), updated_at = now();
  end loop;

  foreach relic in array array[
    'moralPrism', 'orderCompass', 'soulMirror', 'astralLens',
    'chronoshard', 'wayfinderSigil'
  ] loop
    requested := greatest(0, least(1000000,
      coalesce((p_inventory -> 'relics' ->> relic)::integer, 0)));
    if relic = 'chronoshard' then
      reductions := coalesce(
        p_inventory -> 'relic_variants' -> 'chronoshard', '[]'::jsonb
      );
      if jsonb_typeof(reductions) <> 'array'
        or jsonb_array_length(reductions) <> requested
        or requested > 500
        or exists (
          select 1 from jsonb_array_elements(reductions) value
          where jsonb_typeof(value) <> 'number'
            or (value #>> '{}')::integer not between 10 and 90
        ) then
        raise exception 'invalid_inventory';
      end if;
      if exists (
        select 1
        from public.trade_reservations r
        where r.owner_id = current_user_id and r.item_type = 'relic'
          and r.item_key like 'chronoshard:%'
        group by r.item_key
        having count(*) > (
          select count(*)
          from jsonb_array_elements(reductions) value
          where (value #>> '{}')::integer =
            substring(r.item_key from 13)::integer
        )
      ) then raise exception 'invalid_inventory'; end if;
      insert into public.player_relics(
        owner_id, relic_type, quantity, item_data
      ) values (
        current_user_id, relic, requested,
        jsonb_build_object('reductions', reductions)
      ) on conflict (owner_id, relic_type) do update set
        quantity = excluded.quantity,
        item_data = excluded.item_data,
        updated_at = now();
    else
      select count(*)::integer into reserved
      from public.trade_reservations r
      where r.owner_id = current_user_id and r.item_type = 'relic'
        and r.item_key = relic;
      insert into public.player_relics(
        owner_id, relic_type, quantity, item_data
      ) values (current_user_id, relic, greatest(requested, reserved), '{}')
      on conflict (owner_id, relic_type) do update set
        quantity = greatest(excluded.quantity, reserved),
        item_data = '{}',
        updated_at = now();
    end if;
  end loop;
exception
  when invalid_text_representation or numeric_value_out_of_range then
    raise exception 'invalid_inventory';
end;
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
  reservation_key text;
  reduction integer;
  relic_data jsonb;
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
      'wooden', 'silver', 'gold', 'dragon', 'mythical', 'sinister'
    ) then raise exception 'trade_item_invalid'; end if;
    reservation_key := requested_key;
    select quantity into owned_quantity from public.player_chests
    where owner_id = p_owner_id and tier = requested_key for update;
  else
    if requested_key not in (
      'moralPrism', 'orderCompass', 'soulMirror', 'astralLens',
      'chronoshard', 'wayfinderSigil'
    ) then raise exception 'trade_item_invalid'; end if;
    if requested_key = 'chronoshard' then
      reduction := (p_item -> 'data' ->> 'reductionPercent')::integer;
      if reduction not between 10 and 90 then
        raise exception 'trade_item_invalid';
      end if;
      reservation_key := 'chronoshard:' || reduction::text;
      select x.item_data into relic_data
      from public.player_relics x
      where x.owner_id = p_owner_id and x.relic_type = 'chronoshard'
      for update;
      select count(*)::integer into owned_quantity
      from jsonb_array_elements(
        coalesce(relic_data -> 'reductions', '[]'::jsonb)
      ) value
      where (value #>> '{}')::integer = reduction;
    else
      reservation_key := requested_key;
      select quantity into owned_quantity from public.player_relics
      where owner_id = p_owner_id and relic_type = requested_key for update;
    end if;
  end if;

  select count(*)::integer into reserved_quantity
  from public.trade_reservations r
  where r.owner_id = p_owner_id and r.item_type = requested_type
    and r.item_key = reservation_key;
  if coalesce(owned_quantity, 0) <= reserved_quantity then
    raise exception 'trade_item_unavailable';
  end if;
  insert into public.trade_reservations(
    trade_id, side, owner_id, item_type, item_key
  ) values (p_trade_id, p_side, p_owner_id, requested_type, reservation_key);
  return jsonb_build_object(
    'kind', requested_type,
    'key', requested_key,
    'data', case when requested_key = 'chronoshard'
      then jsonb_build_object('reductionPercent', reduction)
      else '{}'::jsonb end
  );
exception
  when invalid_text_representation or numeric_value_out_of_range then
    raise exception 'trade_item_invalid';
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
  reduction integer;
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
    if item_key not in (
      'wooden', 'silver', 'gold', 'dragon', 'mythical', 'sinister'
    ) then raise exception 'trade_item_invalid'; end if;
    update public.player_chests set quantity = quantity - 1, updated_at = now()
    where owner_id = p_from and tier = item_key and quantity > 0;
    if not found then raise exception 'trade_item_unavailable'; end if;
    insert into public.player_chests(owner_id, tier, quantity)
    values (p_to, item_key, 1)
    on conflict (owner_id, tier) do update set
      quantity = public.player_chests.quantity + 1, updated_at = now();
  elsif item_type = 'relic' then
    if item_key not in (
      'moralPrism', 'orderCompass', 'soulMirror', 'astralLens',
      'chronoshard', 'wayfinderSigil'
    ) then raise exception 'trade_item_invalid'; end if;
    if item_key = 'chronoshard' then
      reduction := (p_item -> 'data' ->> 'reductionPercent')::integer;
      if reduction not between 10 and 90 then
        raise exception 'trade_item_invalid';
      end if;
      update public.player_relics set
        quantity = quantity - 1,
        item_data = jsonb_set(
          item_data,
          '{reductions}',
          private.remove_int_once(item_data -> 'reductions', reduction)
        ),
        updated_at = now()
      where owner_id = p_from and relic_type = item_key and quantity > 0
        and coalesce(item_data -> 'reductions', '[]'::jsonb)
          @> jsonb_build_array(reduction);
      if not found then raise exception 'trade_item_unavailable'; end if;
      insert into public.player_relics(
        owner_id, relic_type, quantity, item_data
      ) values (
        p_to, item_key, 1,
        jsonb_build_object('reductions', jsonb_build_array(reduction))
      ) on conflict (owner_id, relic_type) do update set
        quantity = public.player_relics.quantity + 1,
        item_data = jsonb_set(
          public.player_relics.item_data,
          '{reductions}',
          coalesce(
            public.player_relics.item_data -> 'reductions', '[]'::jsonb
          ) || jsonb_build_array(reduction)
        ),
        updated_at = now();
    else
      update public.player_relics set quantity = quantity - 1, updated_at = now()
      where owner_id = p_from and relic_type = item_key and quantity > 0;
      if not found then raise exception 'trade_item_unavailable'; end if;
      insert into public.player_relics(owner_id, relic_type, quantity)
      values (p_to, item_key, 1)
      on conflict (owner_id, relic_type) do update set
        quantity = public.player_relics.quantity + 1, updated_at = now();
    end if;
  else
    raise exception 'trade_item_invalid';
  end if;
exception
  when invalid_text_representation or numeric_value_out_of_range then
    raise exception 'trade_item_invalid';
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
    and c.tier not in ('portrait', 'title')
  group by c.owner_id, c.tier, c.quantity
  having c.quantity - count(r.trade_id) > 0
  union all
  select 'relic'::text, x.relic_type,
    (x.quantity - count(r.trade_id))::integer, '{}'::jsonb
  from public.player_relics x
  left join public.trade_reservations r
    on r.owner_id = x.owner_id and r.item_type = 'relic'
      and r.item_key = x.relic_type
  where x.owner_id = auth.uid() and x.relic_type <> 'chronoshard'
  group by x.owner_id, x.relic_type, x.quantity
  having x.quantity - count(r.trade_id) > 0
  union all
  select 'relic'::text, 'chronoshard'::text,
    (owned.owned_quantity - (
      select count(*)::integer from public.trade_reservations r
      where r.owner_id = owned.owner_id and r.item_type = 'relic'
        and r.item_key = 'chronoshard:' || owned.reduction::text
    ))::integer,
    jsonb_build_object('reductionPercent', owned.reduction)
  from (
    select x.owner_id, (value #>> '{}')::integer as reduction,
      count(*)::integer as owned_quantity
    from public.player_relics x
    cross join jsonb_array_elements(
      coalesce(x.item_data -> 'reductions', '[]'::jsonb)
    ) value
    where x.owner_id = auth.uid() and x.relic_type = 'chronoshard'
    group by x.owner_id, (value #>> '{}')::integer
  ) owned
  where owned.owned_quantity - (
    select count(*)::integer from public.trade_reservations r
    where r.owner_id = owned.owner_id and r.item_type = 'relic'
      and r.item_key = 'chronoshard:' || owned.reduction::text
  ) > 0
  order by 1, 2, 4
$$;

revoke all on function private.remove_int_once(jsonb, integer)
  from public, anon, authenticated;
revoke all on function private.reserve_trade_item(uuid, text, uuid, jsonb)
  from public, anon, authenticated;
revoke all on function private.transfer_trade_item(uuid, uuid, jsonb)
  from public, anon, authenticated;
revoke all on function public.synchronize_trade_inventory(jsonb)
  from public, anon;
revoke all on function public.list_trade_inventory() from public, anon;
grant execute on function public.synchronize_trade_inventory(jsonb)
  to authenticated;
grant execute on function public.list_trade_inventory() to authenticated;
