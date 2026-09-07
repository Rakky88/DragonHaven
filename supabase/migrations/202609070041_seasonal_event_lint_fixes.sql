-- Forward-only fixes for two PL/pgSQL identifiers reported as ambiguous by
-- the staging database linter after migration 40 was applied.

create or replace function public.redeem_seasonal_event_preview(p_code text)
returns table (event_id text, expires_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_code text := upper(trim(coalesce(p_code, '')));
  target_event text;
  keeper_id text;
  new_expiry timestamptz := now() + interval '48 hours';
begin
  if current_user_id is null then raise exception 'online_login_required'; end if;
  if coalesce((select u.email_confirmed_at from auth.users u
      where u.id = current_user_id), '-infinity'::timestamptz) = '-infinity' then
    raise exception 'email_not_verified';
  end if;
  select p.keeper_code into keeper_id from public.profiles p
    where p.user_id = current_user_id;
  if keeper_id <> 'DH-17792DC5' then raise exception 'seasonal_preview_restricted'; end if;
  target_event := case normalized_code
    when 'HALLOWEENEVENT' then 'halloween_witchlight'
    when 'CHRISTMASEVENT' then 'christmas_winter_hearth'
    when 'NEWYEARSEVENT' then 'new_year_first_dawn'
    when 'VALENTINEEVENT' then 'valentine_two_heartlights'
    when 'PRIDEFESTEVENT' then 'pride_every_color'
    else null end;
  if target_event is null then raise exception 'seasonal_preview_invalid'; end if;

  insert into public.seasonal_event_previews(user_id, event_id, activated_at, expires_at)
  values (current_user_id, target_event, now(), new_expiry)
  on conflict on constraint seasonal_event_previews_pkey do update
    set activated_at = excluded.activated_at, expires_at = excluded.expires_at;
  return query select target_event, new_expiry;
end
$$;

create or replace function public.get_seasonal_community_progress(p_event_id text)
returns table(event_id text, occurrence_key text, completed_runs integer,
  ribbon_count integer)
language plpgsql security definer set search_path = '' stable as $$
declare
  window_row record;
  run_count integer;
  edition_year integer;
  current_occurrence_key text;
begin
  if auth.uid() is null then raise exception 'online_login_required'; end if;
  if p_event_id <> 'pride_every_color' then
    raise exception 'seasonal_community_invalid';
  end if;
  select * into window_row from public.seasonal_event_window(p_event_id, now());
  if window_row.occurrence_key is null then
    edition_year := extract(year from now() at time zone 'Europe/Amsterdam')::integer;
    current_occurrence_key := p_event_id || ':' || edition_year::text;
  else
    current_occurrence_key := window_row.occurrence_key;
  end if;
  select count(*)::integer into run_count
  from public.seasonal_trial_attempts a
  where a.event_id = p_event_id
    and a.occurrence_key = current_occurrence_key
    and a.completed_at is not null and not a.simulated;
  event_id := p_event_id;
  occurrence_key := current_occurrence_key;
  completed_runs := run_count;
  ribbon_count := case
    when run_count >= 500 then 7 when run_count >= 250 then 6
    when run_count >= 100 then 5 when run_count >= 50 then 4
    when run_count >= 25 then 3 when run_count >= 10 then 2
    when run_count >= 1 then 1 else 0 end;
  return next;
end
$$;

revoke all on function public.redeem_seasonal_event_preview(text)
  from public, anon;
revoke all on function public.get_seasonal_community_progress(text)
  from public, anon;
grant execute on function public.redeem_seasonal_event_preview(text)
  to authenticated;
grant execute on function public.get_seasonal_community_progress(text)
  to authenticated;
