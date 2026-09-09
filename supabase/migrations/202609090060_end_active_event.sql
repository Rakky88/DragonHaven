-- Account-scoped event opt-out; no reward, inventory or running-attempt mutation.
create table public.seasonal_event_dismissals (
  user_id uuid not null references auth.users(id) on delete cascade,
  event_id text not null,
  expires_at timestamptz not null,
  primary key(user_id, event_id)
);
alter table public.seasonal_event_dismissals enable row level security;
revoke all on public.seasonal_event_dismissals from public, anon, authenticated;

create or replace function public.list_my_seasonal_event_dismissals()
returns table(event_id text, expires_at timestamptz)
language sql security definer set search_path = '' stable as $$
  select d.event_id, d.expires_at from public.seasonal_event_dismissals d
  where d.user_id = auth.uid() and d.expires_at > now() order by d.event_id;
$$;

create or replace function public.end_my_seasonal_event(p_code text)
returns table(event_id text, expires_at timestamptz)
language plpgsql security definer set search_path = '' as $$
declare keeper uuid := auth.uid(); current_event text; w record;
  calendar_year integer := extract(year from now() at time zone 'Europe/Amsterdam')::integer;
  birthday_start timestamptz; birthday_end timestamptz;
begin
  if keeper is null then raise exception 'online_login_required'; end if;
  if not exists(select 1 from auth.users u where u.id = keeper and u.email_confirmed_at is not null) then
    raise exception 'email_not_verified'; end if;
  if upper(trim(coalesce(p_code,''))) <> 'ENDEVENT' then
    raise exception 'seasonal_preview_invalid'; end if;
  perform pg_advisory_xact_lock(hashtextextended(keeper::text, 0));
  -- Suppress this occurrence only, so the next annual edition still starts.
  foreach current_event in array array['halloween_witchlight','christmas_winter_hearth',
      'new_year_first_dawn','valentine_two_heartlights','pride_every_color'] loop
    select * into w from public.seasonal_event_window(current_event, now());
    if now() >= w.starts_at and now() < w.ends_at then
      insert into public.seasonal_event_dismissals(user_id,event_id,expires_at)
        values(keeper,current_event,w.ends_at)
        on conflict on constraint seasonal_event_dismissals_pkey do update set expires_at = excluded.expires_at;
    end if;
  end loop;
  if calendar_year = 2026 then
    birthday_start := timestamp '2026-09-01 00:00' at time zone 'Europe/Amsterdam';
    birthday_end := timestamp '2026-09-03 00:00' at time zone 'Europe/Amsterdam';
  elsif calendar_year > 2026 then
    birthday_start := make_timestamp(calendar_year,5,13,0,0,0) at time zone 'Europe/Amsterdam';
    birthday_end := make_timestamp(calendar_year,5,14,0,0,0) at time zone 'Europe/Amsterdam';
  end if;
  if now() >= birthday_start and now() < birthday_end then
    insert into public.seasonal_event_dismissals(user_id,event_id,expires_at)
      values(keeper,'golden_wings_birthday',birthday_end)
      on conflict on constraint seasonal_event_dismissals_pkey do update set expires_at = excluded.expires_at;
  end if;
  delete from public.seasonal_event_previews p where p.user_id = keeper;
  return query select d.event_id,d.expires_at from public.list_my_seasonal_event_dismissals() d;
end;
$$;
revoke all on function public.list_my_seasonal_event_dismissals() from public, anon;
revoke all on function public.end_my_seasonal_event(text) from public, anon;
grant execute on function public.list_my_seasonal_event_dismissals() to authenticated;
grant execute on function public.end_my_seasonal_event(text) to authenticated;

create or replace function public.start_seasonal_trial_attempt(
  p_event_id text,
  p_trial_key text
)
returns table (
  attempt_id uuid,
  event_id text,
  occurrence_key text,
  completion_token uuid,
  seed integer,
  started_at timestamptz,
  expires_at timestamptz,
  simulated boolean
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  expected_trial text;
  window_row record;
  is_preview boolean := false;
  occurrence text;
  created public.seasonal_trial_attempts%rowtype;
begin
  if current_user_id is null then raise exception 'online_login_required'; end if;
  if coalesce((select u.email_confirmed_at from auth.users u
      where u.id = current_user_id), '-infinity'::timestamptz) = '-infinity' then
    raise exception 'email_not_verified';
  end if;
  expected_trial := case p_event_id
    when 'halloween_witchlight' then 'witchlightWard'
    when 'christmas_winter_hearth' then 'hollyfrostGiftforge'
    when 'new_year_first_dawn' then 'midnightChime'
    when 'valentine_two_heartlights' then 'rosevowRelay'
    when 'pride_every_color' then 'prismaticParade'
    else null end;
  if expected_trial is null or p_trial_key <> expected_trial then
    raise exception 'seasonal_trial_invalid';
  end if;
  select * into window_row from public.seasonal_event_window(p_event_id, now());
  if exists(select 1 from public.list_my_seasonal_event_previews() p where p.event_id = p_event_id) then
    is_preview := true;
    occurrence := 'preview:' || p_event_id || ':' || current_user_id::text;
  elsif exists(select 1 from public.list_my_seasonal_event_dismissals() d where d.event_id = p_event_id) then
    raise exception 'seasonal_trial_unavailable';
  elsif exists(select 1 from public.list_my_seasonal_event_previews()) then
    raise exception 'seasonal_trial_unavailable';
  elsif window_row.occurrence_key is not null and now() >= window_row.starts_at and now() < window_row.ends_at then
    occurrence := window_row.occurrence_key;
  else raise exception 'seasonal_trial_unavailable'; end if;

  insert into public.seasonal_trial_attempts(
    user_id, event_id, trial_key, occurrence_key, seed, simulated, expires_at
  ) values (
    current_user_id, p_event_id, p_trial_key, occurrence,
    floor(random() * 2147483646)::integer, is_preview, now() + interval '6 hours'
  ) returning * into created;
  return query select created.id, created.event_id, created.occurrence_key,
    created.completion_token, created.seed, created.started_at,
    created.expires_at, created.simulated;
end
$$;

create or replace function public.invite_seasonal_pair_adventure(
  p_keeper_code text, p_dragon_id text, p_might integer,
  p_arcana integer, p_spirit integer
)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  current_user_id uuid := auth.uid(); target_id uuid; window_row record;
  occurrence text; is_preview boolean := false; new_id uuid;
begin
  if current_user_id is null then raise exception 'online_login_required'; end if;
  select p.user_id into target_id from public.profiles p
    where upper(p.keeper_code) = upper(trim(p_keeper_code));
  if target_id is null then raise exception 'keeper_not_found'; end if;
  if target_id = current_user_id then raise exception 'cannot_invite_self'; end if;
  if nullif(trim(p_dragon_id), '') is null or p_might not between 0 and 400
    or p_arcana not between 0 and 400 or p_spirit not between 0 and 400 then
    raise exception 'seasonal_pair_invalid_dragon';
  end if;
  select * into window_row from public.seasonal_event_window(
    'valentine_two_heartlights', now());
  if exists(select 1 from public.list_my_seasonal_event_previews() p
    where p.event_id = 'valentine_two_heartlights') then
    is_preview := true;
    occurrence := 'preview:valentine_two_heartlights:' || current_user_id::text;
  elsif exists(select 1 from public.list_my_seasonal_event_dismissals() d where d.event_id = 'valentine_two_heartlights') then
    raise exception 'seasonal_adventure_unavailable';
  elsif exists(select 1 from public.list_my_seasonal_event_previews()) then
    raise exception 'seasonal_adventure_unavailable';
  elsif window_row.occurrence_key is not null and now() >= window_row.starts_at
    and now() < window_row.ends_at then
    occurrence := window_row.occurrence_key;
  else raise exception 'seasonal_adventure_unavailable'; end if;
  if exists(select 1 from public.seasonal_pair_occurrences o where
      o.event_id = 'valentine_two_heartlights' and o.occurrence_key = occurrence
      and o.user_id = current_user_id) then
    raise exception 'seasonal_adventure_already_completed';
  end if;
  if exists(select 1 from public.seasonal_pair_adventures a where
      a.occurrence_key = occurrence and a.creator_id = current_user_id
      and a.status in ('invited','accepted','running','reward_ready')) then
    raise exception 'seasonal_pair_already_active';
  end if;
  insert into public.seasonal_pair_adventures(
    occurrence_key, creator_id, partner_id, creator_dragon_id,
    creator_might, creator_arcana, creator_spirit, simulated
  ) values (occurrence, current_user_id, target_id, trim(p_dragon_id),
    p_might, p_arcana, p_spirit, is_preview) returning id into new_id;
  insert into public.social_notifications(user_id, kind, actor_id, entity_id)
    values(target_id, 'seasonal_pair_invite', current_user_id, new_id);
  return new_id;
end
$$;
