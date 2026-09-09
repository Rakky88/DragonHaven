-- Birthday preview, exact Amsterdam calendar and one-use trial attempts.
-- No existing economy switches, rewards, inventories or tables are changed.

create or replace function public.seasonal_event_window(
  p_event_id text,
  p_now timestamptz default now()
)
returns table (
  occurrence_key text,
  starts_at timestamptz,
  ends_at timestamptz,
  results_end_at timestamptz
)
language plpgsql
set search_path = ''
stable
as $$
declare
  local_now timestamp := p_now at time zone 'Europe/Amsterdam';
  event_year integer := extract(year from local_now)::integer;
  local_start timestamp;
  local_end timestamp;
begin
  if p_event_id = 'golden_wings_birthday' then
    if event_year < 2026 then return; end if;
    if event_year = 2026 then
      local_start := make_timestamp(2026, 9, 1, 0, 0, 0);
      local_end := make_timestamp(2026, 9, 3, 0, 0, 0);
    else
      local_start := make_timestamp(event_year, 5, 13, 0, 0, 0);
      local_end := make_timestamp(event_year, 5, 14, 0, 0, 0);
    end if;
  elsif p_event_id = 'halloween_witchlight' then
    local_start := make_timestamp(event_year, 10, 25, 0, 0, 0);
    local_end := make_timestamp(event_year, 11, 2, 0, 0, 0);
  elsif p_event_id = 'christmas_winter_hearth' then
    local_start := make_timestamp(event_year, 12, 25, 0, 0, 0);
    local_end := make_timestamp(event_year, 12, 27, 0, 0, 0);
  elsif p_event_id = 'new_year_first_dawn' then
    if extract(month from local_now) = 1 then event_year := event_year - 1; end if;
    local_start := make_timestamp(event_year, 12, 31, 18, 0, 0);
    local_end := make_timestamp(event_year + 1, 1, 2, 0, 0, 0);
  elsif p_event_id = 'valentine_two_heartlights' then
    local_start := make_timestamp(event_year, 2, 14, 0, 0, 0);
    local_end := make_timestamp(event_year, 2, 15, 0, 0, 0);
  elsif p_event_id = 'pride_every_color' then
    local_start := make_timestamp(event_year, 6, 1, 0, 0, 0);
    local_end := make_timestamp(event_year, 6, 8, 0, 0, 0);
  else
    return;
  end if;

  -- The first configured editions are a hard lower boundary.
  if (p_event_id in ('halloween_witchlight', 'christmas_winter_hearth',
        'new_year_first_dawn') and event_year < 2026)
     or (p_event_id in ('valentine_two_heartlights', 'pride_every_color')
        and event_year < 2027) then
    return;
  end if;
  occurrence_key := p_event_id || ':' || event_year::text;
  starts_at := local_start at time zone 'Europe/Amsterdam';
  ends_at := local_end at time zone 'Europe/Amsterdam';
  results_end_at := ends_at + interval '5 days';
  return next;
end
$$;

create or replace function public.redeem_seasonal_event_preview(p_code text)
returns table (event_id text, expires_at timestamptz)
language plpgsql security definer set search_path = '' as $$
declare keeper uuid := auth.uid(); normalized_code text := upper(trim(coalesce(p_code, '')));
  target_event text; preview_expiry timestamptz;
begin
  if keeper is null then raise exception 'online_login_required'; end if;
  if not exists(select 1 from auth.users u where u.id = keeper and u.email_confirmed_at is not null) then
    raise exception 'email_not_verified';
  end if;
  target_event := case normalized_code
    when 'BDAYEVENT' then 'golden_wings_birthday'
    when 'HALLOWEENEVENT' then 'halloween_witchlight'
    when 'CHRISTMASEVENT' then 'christmas_winter_hearth'
    when 'NEWYEARSEVENT' then 'new_year_first_dawn'
    when 'VALENTINEEVENT' then 'valentine_two_heartlights'
    when 'PRIDEFESTEVENT' then 'pride_every_color'
    else null end;
  if target_event is null then raise exception 'seasonal_preview_invalid'; end if;
  if not exists(select 1 from public.profiles p where p.user_id = keeper) then
    raise exception 'profile_not_found';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(keeper::text, 0));
  -- Switching affects only this authenticated keeper's preview activation.
  -- Attempts, highscores, running adventures and earned items retain provenance.
  delete from public.seasonal_event_previews p
    where p.user_id = keeper and p.event_id <> target_event;
  select p.expires_at into preview_expiry from public.seasonal_event_previews p
    where p.user_id = keeper and p.event_id = target_event for update;
  -- Retrying an active preview must not extend the window or reset its ranking key.
  if not found or preview_expiry <= now() then
    preview_expiry := now() + interval '48 hours';
    insert into public.seasonal_event_previews(user_id, event_id, activated_at, expires_at)
      values(keeper, target_event, now(), preview_expiry)
      on conflict on constraint seasonal_event_previews_pkey do update
        set activated_at = excluded.activated_at, expires_at = excluded.expires_at;
  end if;
  return query select target_event, preview_expiry;
end;
$$;

revoke all on function public.redeem_seasonal_event_preview(text) from public, anon;
grant execute on function public.redeem_seasonal_event_preview(text) to authenticated;

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
    when 'golden_wings_birthday' then 'wishcakeTower'
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

create or replace function public.complete_seasonal_trial_attempt(
  p_attempt_id uuid,
  p_completion_token text,
  p_score integer,
  p_correct_actions integer,
  p_total_actions integer,
  p_duration_ms integer
)
returns table (
  accepted boolean,
  best_score integer,
  ranking_position bigint,
  simulated boolean
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  attempt public.seasonal_trial_attempts%rowtype;
  accuracy_value integer;
  current_best public.seasonal_trial_bests%rowtype;
  should_replace boolean;
begin
  if current_user_id is null then raise exception 'online_login_required'; end if;
  select * into attempt from public.seasonal_trial_attempts a
  where a.id = p_attempt_id and a.user_id = current_user_id for update;
  if attempt.id is null then raise exception 'seasonal_attempt_not_found'; end if;
  if attempt.completed_at is not null then raise exception 'seasonal_attempt_used'; end if;
  if attempt.expires_at <= now() then raise exception 'seasonal_attempt_expired'; end if;
  if attempt.completion_token::text is distinct from p_completion_token then
    raise exception 'seasonal_attempt_token_invalid';
  end if;
  if p_score is null or p_correct_actions is null or p_total_actions is null
     or p_duration_ms is null or p_score < 0 or p_score > 20000 or p_total_actions < 0
     or p_total_actions > 200 or p_correct_actions < 0
     or p_correct_actions > p_total_actions or p_duration_ms < 1000
     or (p_duration_ms < 30000 and not (attempt.trial_key in ('witchlightWard', 'hollyfrostGiftforge', 'midnightChime', 'wishcakeTower')
       and p_total_actions - p_correct_actions = 3))
     or p_duration_ms > 180000 or p_score > p_correct_actions * 220
     or extract(epoch from (now() - attempt.started_at)) * 1000 < p_duration_ms - 5000 then
    raise exception 'seasonal_score_rejected';
  end if;
  accuracy_value := case when p_total_actions = 0 then 0 else
    round(p_correct_actions::numeric * 1000 / p_total_actions)::integer end;
  update public.seasonal_trial_attempts set completed_at = now(), score = p_score,
    correct_actions = p_correct_actions, total_actions = p_total_actions,
    duration_ms = p_duration_ms where id = attempt.id;

  select * into current_best from public.seasonal_trial_bests b
  where b.event_id = attempt.event_id and b.occurrence_key = attempt.occurrence_key
    and b.user_id = current_user_id;
  should_replace := current_best.user_id is null
    or p_score > current_best.score
    or (p_score = current_best.score and accuracy_value > current_best.accuracy_permille)
    or (p_score = current_best.score and accuracy_value = current_best.accuracy_permille
      and p_duration_ms < current_best.duration_ms);
  if should_replace then
    insert into public.seasonal_trial_bests(
      event_id, occurrence_key, user_id, score, accuracy_permille,
      duration_ms, achieved_at, preview
    ) values (attempt.event_id, attempt.occurrence_key, current_user_id,
      p_score, accuracy_value, p_duration_ms, now(), attempt.simulated)
    on conflict (event_id, occurrence_key, user_id) do update set
      score = excluded.score, accuracy_permille = excluded.accuracy_permille,
      duration_ms = excluded.duration_ms, achieved_at = excluded.achieved_at,
      preview = excluded.preview;
  end if;
  select b.score into best_score from public.seasonal_trial_bests b
    where b.event_id = attempt.event_id and b.occurrence_key = attempt.occurrence_key
      and b.user_id = current_user_id;
  select ranked.pos into ranking_position from (
    select b.user_id, rank() over(order by b.score desc, b.accuracy_permille desc,
      b.duration_ms, b.achieved_at, b.user_id) pos
    from public.seasonal_trial_bests b
    where b.event_id = attempt.event_id and b.occurrence_key = attempt.occurrence_key
      and b.preview = attempt.simulated
  ) ranked where ranked.user_id = current_user_id;
  accepted := true;
  simulated := attempt.simulated;
  return next;
end
$$;
