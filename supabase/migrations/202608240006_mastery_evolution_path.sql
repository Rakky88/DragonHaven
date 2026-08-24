-- Runs after the v0.02.02 trade-limit migration.
-- The hidden Mastery evolution is a fourth authoritative Ascended path.

alter table public.player_dragons
  drop constraint if exists player_dragons_evolution_path_check;
alter table public.player_dragons add constraint player_dragons_evolution_path_check
  check (evolution_path in ('might', 'arcana', 'spirit', 'mastery'));

alter table public.social_showcases
  drop constraint if exists social_showcases_favorite_dragon_evolution_path_check;
alter table public.social_showcases
  add constraint social_showcases_favorite_dragon_evolution_path_check check (
    favorite_dragon_evolution_path is null or
    favorite_dragon_evolution_path in ('might', 'arcana', 'spirit', 'mastery')
  );

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
    or path not in ('might', 'arcana', 'spirit', 'mastery') then
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
      greatest(0, least(300, (entry ->> 'might')::integer)),
      greatest(0, least(300, (entry ->> 'arcana')::integer)),
      greatest(0, least(300, (entry ->> 'spirit')::integer)),
      case when entry ->> 'evolution_path' in (
        'might', 'arcana', 'spirit', 'mastery'
      ) then entry ->> 'evolution_path' else 'spirit' end,
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
  from unnest(array[
    'wooden', 'silver', 'gold', 'dragon', 'mythical', 'sinister',
    'portrait', 'title'
  ]) tier;

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
  when invalid_text_representation or numeric_value_out_of_range
    or check_violation then
    raise exception 'invalid_inventory';
end;
$$;
