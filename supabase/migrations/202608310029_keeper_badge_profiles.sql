-- DragonHaven: publish the selected Keeper badge with online profiles.
-- Older app versions keep working through the existing three- and
-- four-argument update_my_profile overloads, which preserve badge_key.

alter table public.profiles
  add column if not exists badge_key text;

alter table public.profiles
  drop constraint if exists profiles_badge_key_check;
alter table public.profiles add constraint profiles_badge_key_check check (
  badge_key is null or badge_key = 'badge_supporter_founder'
);

create or replace function public.update_my_profile(
  p_display_name text,
  p_title text,
  p_portrait_key text,
  p_frame_key text,
  p_badge_key text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null
    or char_length(btrim(p_display_name)) not between 1 and 24
    or not (
      p_title ~ '^title_(00[1-9]|0[1-9][0-9]|[1-4][0-9]{2}|500)$'
      or p_title = 'title_supporter_founder'
    )
    or not (
      p_portrait_key ~ '^portrait_(00[1-9]|0[1-9][0-9]|100)$'
      or p_portrait_key = 'portrait_supporter_founder'
    )
    or not (
      p_frame_key is null or p_frame_key = 'frame_supporter_founder'
    )
    or not (
      p_badge_key is null or p_badge_key = 'badge_supporter_founder'
    ) then
    raise exception 'invalid_profile';
  end if;
  update public.profiles
  set display_name = btrim(p_display_name),
      title = p_title,
      portrait_key = p_portrait_key,
      frame_key = p_frame_key,
      badge_key = p_badge_key
  where user_id = auth.uid();
end;
$$;

drop function if exists public.get_online_snapshot();
drop function public.get_my_profile();
create function public.get_my_profile()
returns table (
  user_id uuid, keeper_code text, display_name text, title text,
  portrait_key text, frame_key text, badge_key text,
  discovered_dragon_count bigint,
  achievement_count integer, dragon_count integer,
  inventory_imported boolean, discovered_forms text[],
  prismatic_forms text[], cavern_flight_best integer,
  ruin_breaker_best integer, runeweaver_best integer,
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
    p.frame_key, p.badge_key,
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
  portrait_key text, frame_key text, badge_key text,
  discovered_dragon_count bigint,
  achievement_count integer, dragon_count integer,
  inventory_imported boolean, discovered_forms text[],
  prismatic_forms text[], cavern_flight_best integer,
  ruin_breaker_best integer, runeweaver_best integer,
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
    p.frame_key, p.badge_key,
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

drop function public.list_friend_requests();
create function public.list_friend_requests()
returns table (
  request_id uuid, direction text, created_at timestamptz,
  user_id uuid, keeper_code text, display_name text, title text,
  portrait_key text, frame_key text, badge_key text,
  discovered_dragon_count bigint, inventory_imported boolean,
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
    p.frame_key, p.badge_key,
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

drop function public.list_blocked_keepers();
create function public.list_blocked_keepers()
returns table (
  user_id uuid, keeper_code text, display_name text, title text,
  portrait_key text, frame_key text, badge_key text,
  discovered_dragon_count bigint, inventory_imported boolean,
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
    p.frame_key, p.badge_key,
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

create function public.get_online_snapshot()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  result jsonb;
begin
  if auth.uid() is null then
    raise exception 'group_login_required';
  end if;

  select jsonb_build_object(
    'profile', (
      select to_jsonb(profile_row)
      from public.get_my_profile() as profile_row
      limit 1
    ),
    'friends', coalesce((
      select jsonb_agg(to_jsonb(friend_row))
      from public.list_my_friends() as friend_row
    ), '[]'::jsonb),
    'requests', coalesce((
      select jsonb_agg(to_jsonb(request_row))
      from public.list_friend_requests() as request_row
    ), '[]'::jsonb),
    'blocked_keepers', coalesce((
      select jsonb_agg(to_jsonb(blocked_row))
      from public.list_blocked_keepers() as blocked_row
    ), '[]'::jsonb),
    'group_status', (
      select to_jsonb(status_row)
      from public.get_current_group_adventure_status() as status_row
      limit 1
    ),
    'group_lobbies', coalesce((
      select jsonb_agg(to_jsonb(lobby_row))
      from public.list_group_adventures() as lobby_row
    ), '[]'::jsonb),
    'trades', coalesce((
      select jsonb_agg(to_jsonb(trade_row))
      from public.list_my_trades() as trade_row
    ), '[]'::jsonb),
    'trade_inventory', coalesce((
      select jsonb_agg(to_jsonb(inventory_row))
      from public.list_trade_inventory() as inventory_row
    ), '[]'::jsonb),
    'notifications', coalesce((
      select jsonb_agg(to_jsonb(notification_row))
      from public.list_social_notifications() as notification_row
    ), '[]'::jsonb)
  ) into result;

  if result->'profile' = 'null'::jsonb
    or result->'group_status' = 'null'::jsonb then
    raise exception 'invalid_online_snapshot';
  end if;
  return result;
end;
$$;

revoke all on function public.update_my_profile(text, text, text, text, text)
  from public, anon;
revoke all on function public.get_my_profile() from public, anon;
revoke all on function public.list_my_friends() from public, anon;
revoke all on function public.list_friend_requests() from public, anon;
revoke all on function public.list_blocked_keepers() from public, anon;
revoke all on function public.get_online_snapshot() from public, anon;
grant execute on function public.update_my_profile(text, text, text, text, text)
  to authenticated;
grant execute on function public.get_my_profile() to authenticated;
grant execute on function public.list_my_friends() to authenticated;
grant execute on function public.list_friend_requests() to authenticated;
grant execute on function public.list_blocked_keepers() to authenticated;
grant execute on function public.get_online_snapshot() to authenticated;
