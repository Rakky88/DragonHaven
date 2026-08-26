-- Friends may see only the number of unlocked achievements and the number of
-- owned dragons. Achievement identities and the private inventory stay hidden.

alter table public.social_showcases
  add column achievement_count integer not null default 0
    check (achievement_count between 0 and 1000),
  add column dragon_count integer not null default 0
    check (dragon_count between 0 and 100000);

create or replace function public.publish_social_summary_counts(
  p_achievement_count integer,
  p_dragon_count integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null
    or p_achievement_count is null
    or p_achievement_count < 0
    or p_achievement_count > 1000
    or p_dragon_count is null
    or p_dragon_count < 0
    or p_dragon_count > 100000 then
    raise exception 'invalid_profile';
  end if;

  insert into public.social_showcases(
    user_id,
    achievement_count,
    dragon_count
  ) values (
    current_user_id,
    p_achievement_count,
    p_dragon_count
  )
  on conflict (user_id) do update set
    achievement_count = excluded.achievement_count,
    dragon_count = excluded.dragon_count,
    updated_at = now();
end;
$$;

drop function public.get_my_profile();
create function public.get_my_profile()
returns table (
  user_id uuid, keeper_code text, display_name text, title text,
  portrait_key text, discovered_dragon_count bigint,
  achievement_count integer, dragon_count integer,
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
    coalesce(s.achievement_count, 0),
    coalesce(s.dragon_count, 0),
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
  achievement_count integer, dragon_count integer,
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
    coalesce(s.achievement_count, 0),
    coalesce(s.dragon_count, 0),
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

revoke all on function public.publish_social_summary_counts(integer, integer)
  from public, anon;
revoke all on function public.get_my_profile() from public, anon;
revoke all on function public.list_my_friends() from public, anon;
grant execute on function public.publish_social_summary_counts(integer, integer)
  to authenticated;
grant execute on function public.get_my_profile() to authenticated;
grant execute on function public.list_my_friends() to authenticated;
