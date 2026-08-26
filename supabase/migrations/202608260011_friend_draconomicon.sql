-- Share only discovered Draconomicon form keys with accepted friends. The
-- authoritative inventory remains private and inaccessible to clients.

alter table public.social_showcases
  add column discovered_forms text[] not null default '{}'::text[]
    check (cardinality(discovered_forms) <= 300),
  add column prismatic_forms text[] not null default '{}'::text[]
    check (cardinality(prismatic_forms) <= 300);

create or replace function public.publish_social_showcase(p_showcase jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  favorite jsonb := p_showcase -> 'favorite_dragon';
  trial_scores jsonb := p_showcase -> 'trial_high_scores';
  favorite_scores jsonb := favorite -> 'trial_high_scores';
  normal_forms_json jsonb := coalesce(
    p_showcase -> 'discovered_forms', '[]'::jsonb);
  spectral_forms_json jsonb := coalesce(
    p_showcase -> 'prismatic_forms', '[]'::jsonb);
  normal_forms text[];
  spectral_forms text[];
  discovered_count integer;
begin
  if current_user_id is null
    or jsonb_typeof(p_showcase) <> 'object'
    or jsonb_typeof(normal_forms_json) <> 'array'
    or jsonb_typeof(spectral_forms_json) <> 'array' then
    raise exception 'invalid_profile';
  end if;

  select coalesce(array_agg(form_key order by form_key), '{}'::text[])
  into normal_forms
  from (
    select distinct value as form_key
    from jsonb_array_elements_text(normal_forms_json)
  ) forms;

  select coalesce(array_agg(form_key order by form_key), '{}'::text[])
  into spectral_forms
  from (
    select distinct value as form_key
    from jsonb_array_elements_text(spectral_forms_json)
  ) forms;

  if cardinality(normal_forms) > 300
    or cardinality(spectral_forms) > 300
    or exists (
      select 1
      from unnest(normal_forms || spectral_forms) as forms(form_key)
      where forms.form_key !~ '^[a-z0-9_]{1,40}:(hatchling|wyrmling|ascended:(might|arcana|spirit|mastery))$'
    )
    or (favorite is not null and jsonb_typeof(favorite) not in ('object', 'null'))
    or (trial_scores is not null and jsonb_typeof(trial_scores) not in ('object', 'null'))
    or (favorite_scores is not null and jsonb_typeof(favorite_scores) not in ('object', 'null')) then
    raise exception 'invalid_profile';
  end if;

  select count(distinct split_part(forms.form_key, ':', 1))::integer
  into discovered_count
  from unnest(normal_forms || spectral_forms) as forms(form_key);

  insert into public.social_showcases(
    user_id, discovered_dragon_count, discovered_forms, prismatic_forms,
    cavern_flight_best, ruin_breaker_best, runeweaver_best,
    favorite_dragon_id, favorite_dragon_name,
    favorite_dragon_lineage_id, favorite_dragon_stage,
    favorite_dragon_xp, favorite_dragon_might, favorite_dragon_arcana,
    favorite_dragon_spirit, favorite_dragon_evolution_path,
    favorite_dragon_prismatic, favorite_dragon_sinister,
    favorite_dragon_cavern_flight_best,
    favorite_dragon_ruin_breaker_best,
    favorite_dragon_runeweaver_best
  ) values (
    current_user_id, discovered_count, normal_forms, spectral_forms,
    greatest(0, least(1000000000,
      coalesce((trial_scores ->> 'cavernFlight')::integer, 0))),
    greatest(0, least(1000000000,
      coalesce((trial_scores ->> 'ruinBreaker')::integer, 0))),
    greatest(0, least(1000000000,
      coalesce((trial_scores ->> 'runeweaver')::integer, 0))),
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
      then greatest(0, least(300, (favorite ->> 'might')::integer)) end,
    case when jsonb_typeof(favorite) = 'object'
      then greatest(0, least(300, (favorite ->> 'arcana')::integer)) end,
    case when jsonb_typeof(favorite) = 'object'
      then greatest(0, least(300, (favorite ->> 'spirit')::integer)) end,
    case when jsonb_typeof(favorite) = 'object'
      then favorite ->> 'evolution_path' end,
    case when jsonb_typeof(favorite) = 'object'
      then coalesce((favorite ->> 'prismatic')::boolean, false) end,
    case when jsonb_typeof(favorite) = 'object'
      then coalesce((favorite ->> 'sinister')::boolean, false) end,
    case when jsonb_typeof(favorite) = 'object' then
      greatest(0, least(1000000000,
        coalesce((favorite_scores ->> 'cavernFlight')::integer, 0))) end,
    case when jsonb_typeof(favorite) = 'object' then
      greatest(0, least(1000000000,
        coalesce((favorite_scores ->> 'ruinBreaker')::integer, 0))) end,
    case when jsonb_typeof(favorite) = 'object' then
      greatest(0, least(1000000000,
        coalesce((favorite_scores ->> 'runeweaver')::integer, 0))) end
  )
  on conflict (user_id) do update set
    discovered_dragon_count = excluded.discovered_dragon_count,
    discovered_forms = excluded.discovered_forms,
    prismatic_forms = excluded.prismatic_forms,
    cavern_flight_best = excluded.cavern_flight_best,
    ruin_breaker_best = excluded.ruin_breaker_best,
    runeweaver_best = excluded.runeweaver_best,
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
    favorite_dragon_cavern_flight_best =
      excluded.favorite_dragon_cavern_flight_best,
    favorite_dragon_ruin_breaker_best =
      excluded.favorite_dragon_ruin_breaker_best,
    favorite_dragon_runeweaver_best =
      excluded.favorite_dragon_runeweaver_best,
    updated_at = now();
exception
  when invalid_text_representation or numeric_value_out_of_range
    or check_violation or not_null_violation then
    raise exception 'invalid_profile';
end;
$$;

drop function public.get_my_profile();
create function public.get_my_profile()
returns table (
  user_id uuid, keeper_code text, display_name text, title text,
  portrait_key text, discovered_dragon_count bigint,
  inventory_imported boolean, discovered_forms text[],
  prismatic_forms text[],
  cavern_flight_best integer, ruin_breaker_best integer,
  runeweaver_best integer,
  favorite_dragon_id text, favorite_dragon_name text,
  favorite_dragon_lineage_id text, favorite_dragon_stage text,
  favorite_dragon_level integer, favorite_dragon_might integer,
  favorite_dragon_arcana integer, favorite_dragon_spirit integer,
  favorite_dragon_evolution_path text, favorite_dragon_prismatic boolean,
  favorite_dragon_sinister boolean,
  favorite_dragon_cavern_flight_best integer,
  favorite_dragon_ruin_breaker_best integer,
  favorite_dragon_runeweaver_best integer
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
    coalesce(s.discovered_forms, '{}'::text[]),
    coalesce(s.prismatic_forms, '{}'::text[]),
    coalesce(s.cavern_flight_best, 0),
    coalesce(s.ruin_breaker_best, 0),
    coalesce(s.runeweaver_best, 0),
    s.favorite_dragon_id, s.favorite_dragon_name,
    s.favorite_dragon_lineage_id, s.favorite_dragon_stage,
    private.dragon_level(coalesce(s.favorite_dragon_xp, 0)),
    s.favorite_dragon_might, s.favorite_dragon_arcana,
    s.favorite_dragon_spirit, s.favorite_dragon_evolution_path,
    s.favorite_dragon_prismatic, s.favorite_dragon_sinister,
    s.favorite_dragon_cavern_flight_best,
    s.favorite_dragon_ruin_breaker_best,
    s.favorite_dragon_runeweaver_best
  from public.profiles p
  left join public.social_showcases s on s.user_id = p.user_id
  where p.user_id = auth.uid()
$$;

drop function public.list_my_friends();
create function public.list_my_friends()
returns table (
  user_id uuid, keeper_code text, display_name text, title text,
  portrait_key text, discovered_dragon_count bigint,
  inventory_imported boolean, discovered_forms text[],
  prismatic_forms text[],
  cavern_flight_best integer, ruin_breaker_best integer,
  runeweaver_best integer,
  favorite_dragon_id text, favorite_dragon_name text,
  favorite_dragon_lineage_id text, favorite_dragon_stage text,
  favorite_dragon_level integer, favorite_dragon_might integer,
  favorite_dragon_arcana integer, favorite_dragon_spirit integer,
  favorite_dragon_evolution_path text, favorite_dragon_prismatic boolean,
  favorite_dragon_sinister boolean,
  favorite_dragon_cavern_flight_best integer,
  favorite_dragon_ruin_breaker_best integer,
  favorite_dragon_runeweaver_best integer
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
    coalesce(s.discovered_forms, '{}'::text[]),
    coalesce(s.prismatic_forms, '{}'::text[]),
    coalesce(s.cavern_flight_best, 0),
    coalesce(s.ruin_breaker_best, 0),
    coalesce(s.runeweaver_best, 0),
    s.favorite_dragon_id, s.favorite_dragon_name,
    s.favorite_dragon_lineage_id, s.favorite_dragon_stage,
    private.dragon_level(coalesce(s.favorite_dragon_xp, 0)),
    s.favorite_dragon_might, s.favorite_dragon_arcana,
    s.favorite_dragon_spirit, s.favorite_dragon_evolution_path,
    s.favorite_dragon_prismatic, s.favorite_dragon_sinister,
    s.favorite_dragon_cavern_flight_best,
    s.favorite_dragon_ruin_breaker_best,
    s.favorite_dragon_runeweaver_best
  from public.friendships f
  join public.profiles p on p.user_id = case
    when f.requester_id = auth.uid() then f.addressee_id else f.requester_id end
  left join public.social_showcases s on s.user_id = p.user_id
  where f.status = 'accepted'
    and auth.uid() in (f.requester_id, f.addressee_id)
  order by lower(p.display_name), p.user_id
$$;

revoke all on function public.get_my_profile() from public, anon;
revoke all on function public.list_my_friends() from public, anon;
grant execute on function public.get_my_profile() to authenticated;
grant execute on function public.list_my_friends() to authenticated;
