-- Fix the v0.02.01 trade inventory refresh. The PL/pgSQL loop variable
-- `tier` collided with player_chests.tier in the ON CONFLICT target, causing
-- every signed-in refresh to fail before social data could be loaded.

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

revoke all on function public.synchronize_trade_inventory(jsonb)
  from public, anon;
grant execute on function public.synchronize_trade_inventory(jsonb)
  to authenticated;
