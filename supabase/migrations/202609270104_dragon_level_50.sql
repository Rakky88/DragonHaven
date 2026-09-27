-- Keep server-side social and Group Adventure level reads aligned with the
-- app's 50-level dragon curve. Evolution requirements remain unchanged.
create or replace function private.dragon_level(value integer)
returns integer
language sql
immutable
set search_path = ''
as $$
  select coalesce(max(level), 1)::integer
  from unnest(array[
    0,150,350,650,1000,1450,1950,2600,3400,4400,
    5600,7000,8600,10400,12400,14600,17000,19600,22400,25400,
    28600,32000,35600,39400,43400,47600,52000,56600,61400,66400,
    71600,77000,82600,88400,94400,100600,107000,113600,120400,127400,
    134600,142000,149600,157400,165400,173600,182000,190600,199400,208400
  ]::integer[]) with ordinality as thresholds(xp, level)
  where greatest(value, 0) >= xp
$$;

revoke all on function private.dragon_level(integer)
  from public, anon, authenticated, service_role;

-- Level rewards can become the selected public identity cosmetic. Keep the
-- database allow-list aligned with the canonical inventory allow-list so a
-- legitimate level-up can never make the next game-state commit fail.
alter table public.profiles
  drop constraint if exists profiles_badge_key_check;
alter table public.profiles add constraint profiles_badge_key_check check (
  badge_key is null
  or badge_key in ('badge_supporter_founder', 'heartbound_pair')
  or badge_key ~ '^keeper_level_badge_([2-9]|[1-3][0-9]|40)$'
);

alter table public.profiles
  drop constraint if exists profiles_frame_key_check;
alter table public.profiles add constraint profiles_frame_key_check check (
  frame_key is null
  or frame_key in ('frame_supporter_founder', 'keeper_level_frame_40')
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
      p_frame_key is null
      or p_frame_key in ('frame_supporter_founder', 'keeper_level_frame_40')
    )
    or not (
      p_badge_key is null
      or p_badge_key in ('badge_supporter_founder', 'heartbound_pair')
      or p_badge_key ~ '^keeper_level_badge_([2-9]|[1-3][0-9]|40)$'
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

revoke all on function public.update_my_profile(text, text, text, text, text)
  from public, anon;
grant execute on function public.update_my_profile(text, text, text, text, text)
  to authenticated;
