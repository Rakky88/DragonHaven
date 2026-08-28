-- Record the one-time legacy save import without retaining names or other
-- player-authored values in the public report. The private pre-import snapshot
-- makes a manually reviewed rollback possible during the migration window.

create table public.legacy_inventory_import_audit (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(user_id)
    on delete cascade,
  import_version integer not null check (import_version between 0 and 1000),
  source_schema_version integer not null
    check (source_schema_version between 0 and 1000),
  source_sha256 text check (
    source_sha256 is null or source_sha256 ~ '^[a-f0-9]{64}$'
  ),
  report jsonb not null check (jsonb_typeof(report) = 'object'),
  imported_at timestamptz not null default now()
);

create table private.legacy_inventory_import_backups (
  import_id uuid primary key,
  user_id uuid not null unique references public.profiles(user_id)
    on delete cascade,
  pre_import_state jsonb not null
    check (jsonb_typeof(pre_import_state) = 'object'),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '30 days'),
  check (expires_at > created_at)
);

alter table public.legacy_inventory_import_audit enable row level security;
revoke all on table public.legacy_inventory_import_audit
  from public, anon, authenticated;
revoke all on table private.legacy_inventory_import_backups
  from public, anon, authenticated;

-- Older accounts were imported before this audit table existed. Preserve that
-- fact as a version-0 historical record, without pretending a source payload or
-- rollback snapshot is available.
insert into public.legacy_inventory_import_audit(
  user_id, import_version, source_schema_version, source_sha256,
  report, imported_at
)
select p.user_id, 0, 0, null,
  jsonb_build_object(
    'historical', true,
    'dragon_count', (
      select count(*) from public.player_dragons d where d.owner_id = p.user_id
    ),
    'egg_count', (
      select count(*) from public.player_eggs e where e.owner_id = p.user_id
    ),
    'furniture_count', (
      select count(*) from public.furniture_instances f
      where f.owner_id = p.user_id
    ),
    'lineage_count', (
      select count(*) from public.discovered_lineages l
      where l.owner_id = p.user_id
    )
  ),
  p.inventory_imported_at
from public.profiles p
where p.inventory_imported_at is not null
on conflict (user_id) do nothing;

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
  requested_coins bigint;
  requested_gems bigint;
  stored_coins bigint;
  stored_gems bigint;
  requested_chest_units bigint;
  stored_chest_units bigint;
  import_version integer;
  source_schema_version integer;
  import_id uuid := extensions.gen_random_uuid();
  imported_at timestamptz := now();
  pre_import_state jsonb;
begin
  if current_user_id is null or jsonb_typeof(p_inventory) <> 'object' then
    raise exception 'invalid_inventory';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(current_user_id::text, 0));
  select inventory_imported_at into profile_imported_at
  from public.profiles where user_id = current_user_id for update;
  if not found then raise exception 'profile_not_found'; end if;
  if profile_imported_at is not null then return; end if;

  import_version := coalesce(
    nullif(p_inventory ->> 'import_version', '')::integer, 1
  );
  source_schema_version := coalesce(
    nullif(p_inventory ->> 'source_schema_version', '')::integer, 0
  );
  if import_version <> 1 or source_schema_version not between 0 and 1000
    or jsonb_typeof(coalesce(p_inventory -> 'dragons', '[]'::jsonb)) <> 'array'
    or jsonb_typeof(coalesce(p_inventory -> 'eggs', '[]'::jsonb)) <> 'array'
    or jsonb_typeof(coalesce(
      p_inventory -> 'furniture_catalog_ids', '[]'::jsonb
    )) <> 'array'
    or jsonb_typeof(coalesce(
      p_inventory -> 'discovered_lineage_ids', '[]'::jsonb
    )) <> 'array'
    or jsonb_typeof(coalesce(p_inventory -> 'chests', '{}'::jsonb)) <> 'object'
    or jsonb_array_length(coalesce(p_inventory -> 'dragons', '[]'::jsonb)) > 250
    or jsonb_array_length(coalesce(p_inventory -> 'eggs', '[]'::jsonb)) > 500
    or jsonb_array_length(coalesce(
      p_inventory -> 'furniture_catalog_ids', '[]'::jsonb
    )) > 500
    or jsonb_array_length(coalesce(
      p_inventory -> 'discovered_lineage_ids', '[]'::jsonb
    )) > 100 then
    raise exception 'invalid_inventory';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(coalesce(p_inventory -> 'dragons', '[]'::jsonb)) d
    where jsonb_typeof(d) <> 'object'
      or char_length(coalesce(d ->> 'client_id', '')) not between 1 and 100
      or coalesce(d ->> 'lineage_id', '') !~ '^[a-z0-9_]{1,64}$'
      or coalesce(d ->> 'stage', '') not in (
        'hatchling', 'wyrmling', 'ascended'
      )
  ) or exists (
    select 1
    from jsonb_array_elements(coalesce(p_inventory -> 'dragons', '[]'::jsonb)) d
    group by d ->> 'client_id' having count(*) > 1
  ) or exists (
    select 1
    from jsonb_array_elements(coalesce(p_inventory -> 'eggs', '[]'::jsonb)) e
    where jsonb_typeof(e) <> 'object'
      or char_length(coalesce(e ->> 'client_id', '')) not between 1 and 100
      or coalesce(e ->> 'lineage_id', '') !~ '^[a-z0-9_]{1,64}$'
  ) or exists (
    select 1
    from jsonb_array_elements(coalesce(p_inventory -> 'eggs', '[]'::jsonb)) e
    group by e ->> 'client_id' having count(*) > 1
  ) or exists (
    select 1
    from jsonb_array_elements_text(coalesce(
      p_inventory -> 'furniture_catalog_ids', '[]'::jsonb
    )) value where value !~ '^[a-z0-9_]{1,80}$'
  ) or exists (
    select 1
    from jsonb_array_elements_text(coalesce(
      p_inventory -> 'discovered_lineage_ids', '[]'::jsonb
    )) value where value !~ '^[a-z0-9_]{1,64}$'
  ) then
    raise exception 'invalid_inventory';
  end if;

  requested_coins := coalesce((p_inventory ->> 'coins')::bigint, 0);
  requested_gems := coalesce((p_inventory ->> 'gems')::bigint, 0);
  stored_coins := greatest(0, least(100000000, requested_coins));
  stored_gems := greatest(0, least(1000000, requested_gems));
  select coalesce(sum(coalesce((p_inventory -> 'chests' ->> tier)::bigint, 0)), 0),
    coalesce(sum(greatest(0, least(1000000,
      coalesce((p_inventory -> 'chests' ->> tier)::bigint, 0)))), 0)
  into requested_chest_units, stored_chest_units
  from unnest(array[
    'wooden', 'silver', 'gold', 'dragon', 'mythical', 'sinister',
    'portrait', 'title'
  ]) tier;

  pre_import_state := jsonb_build_object(
    'wallet', coalesce((
      select to_jsonb(w) from public.player_wallets w
      where w.user_id = current_user_id
    ), 'null'::jsonb),
    'dragons', coalesce((
      select jsonb_agg(to_jsonb(d)) from public.player_dragons d
      where d.owner_id = current_user_id
    ), '[]'::jsonb),
    'eggs', coalesce((
      select jsonb_agg(to_jsonb(e)) from public.player_eggs e
      where e.owner_id = current_user_id
    ), '[]'::jsonb),
    'chests', coalesce((
      select jsonb_agg(to_jsonb(c)) from public.player_chests c
      where c.owner_id = current_user_id
    ), '[]'::jsonb),
    'relics', coalesce((
      select jsonb_agg(to_jsonb(r)) from public.player_relics r
      where r.owner_id = current_user_id
    ), '[]'::jsonb),
    'furniture', coalesce((
      select jsonb_agg(to_jsonb(f)) from public.furniture_instances f
      where f.owner_id = current_user_id
    ), '[]'::jsonb),
    'lineages', coalesce((
      select jsonb_agg(to_jsonb(l)) from public.discovered_lineages l
      where l.owner_id = current_user_id
    ), '[]'::jsonb)
  );

  update public.player_wallets
  set coins = stored_coins,
      gems = stored_gems,
      revision = revision + 1,
      updated_at = imported_at
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
      entry ->> 'client_id',
      left(coalesce(nullif(btrim(entry ->> 'name'), ''), 'Dragon'), 24),
      entry ->> 'lineage_id',
      entry ->> 'stage',
      greatest(0, least(100000000, coalesce((entry ->> 'xp')::integer, 0))),
      greatest(0, least(300, coalesce((entry ->> 'might')::integer, 0))),
      greatest(0, least(300, coalesce((entry ->> 'arcana')::integer, 0))),
      greatest(0, least(300, coalesce((entry ->> 'spirit')::integer, 0))),
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
      entry ->> 'client_id',
      entry ->> 'lineage_id',
      coalesce((entry ->> 'acquired_at')::timestamptz, imported_at),
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
  on conflict (owner_id, catalog_item_id) do nothing;

  insert into public.discovered_lineages(owner_id, lineage_id)
  select current_user_id, value
  from jsonb_array_elements_text(
    coalesce(p_inventory -> 'discovered_lineage_ids', '[]'::jsonb)
  ) as value
  on conflict (owner_id, lineage_id) do nothing;

  update public.profiles set inventory_imported_at = imported_at
  where user_id = current_user_id;

  insert into public.legacy_inventory_import_audit(
    id, user_id, import_version, source_schema_version, source_sha256,
    report, imported_at
  ) values (
    import_id, current_user_id, import_version, source_schema_version,
    encode(extensions.digest(p_inventory::text, 'sha256'), 'hex'),
    jsonb_build_object(
      'historical', false,
      'dragon_count', jsonb_array_length(coalesce(
        p_inventory -> 'dragons', '[]'::jsonb
      )),
      'egg_count', jsonb_array_length(coalesce(
        p_inventory -> 'eggs', '[]'::jsonb
      )),
      'furniture_count', jsonb_array_length(
        coalesce(p_inventory -> 'furniture_catalog_ids', '[]'::jsonb)
      ),
      'lineage_count', jsonb_array_length(
        coalesce(p_inventory -> 'discovered_lineage_ids', '[]'::jsonb)
      ),
      'coins_requested', requested_coins,
      'coins_stored', stored_coins,
      'coins_clamped', requested_coins <> stored_coins,
      'gems_requested', requested_gems,
      'gems_stored', stored_gems,
      'gems_clamped', requested_gems <> stored_gems,
      'chest_units_requested', requested_chest_units,
      'chest_units_stored', stored_chest_units,
      'chests_clamped', requested_chest_units <> stored_chest_units,
      'relics_deferred_to_inventory_sync', true
    ),
    imported_at
  );
  insert into private.legacy_inventory_import_backups(
    import_id, user_id, pre_import_state, created_at
  ) values (import_id, current_user_id, pre_import_state, imported_at);
exception
  when invalid_text_representation or numeric_value_out_of_range
    or check_violation or not_null_violation or unique_violation then
    raise exception 'invalid_inventory';
end;
$$;

create or replace function public.get_my_legacy_import_report()
returns table (
  import_version integer,
  source_schema_version integer,
  report jsonb,
  imported_at timestamptz,
  rollback_available_until timestamptz
)
language sql
security definer
set search_path = ''
stable
as $$
  select a.import_version, a.source_schema_version, a.report, a.imported_at,
    b.expires_at
  from public.legacy_inventory_import_audit a
  left join private.legacy_inventory_import_backups b on b.import_id = a.id
  where a.user_id = auth.uid()
$$;

revoke all on function public.import_legacy_inventory(jsonb)
  from public, anon;
grant execute on function public.import_legacy_inventory(jsonb)
  to authenticated;
revoke all on function public.get_my_legacy_import_report()
  from public, anon;
grant execute on function public.get_my_legacy_import_report()
  to authenticated;
