-- Sunwake / Harvestmoon: approved calendars, preview codes and trial identities.
-- Additive cosmetic Conclave progress; no economy switches or inventories change.
-- Birthday accepts one-miss completion; legacy three-miss clients remain compatible.

alter table public.seasonal_trial_attempts add column if not exists conclave_id uuid
  references public.conclaves(id) on delete set null;
create index if not exists seasonal_attempt_conclave_completed_idx
  on public.seasonal_trial_attempts(conclave_id, event_id, completed_at)
  where completed_at is not null;

create table public.seasonal_conclave_projects (
  conclave_id uuid not null references public.conclaves(id) on delete cascade,
  event_id text not null check(event_id in ('sunwake_summer_sea','harvestmoon_moonlit_orchard')),
  occurrence_key text not null,
  completed_trials bigint not null default 0 check(completed_trials >= 0),
  updated_at timestamptz not null default now(),
  primary key(conclave_id,event_id,occurrence_key)
);
alter table public.seasonal_conclave_projects enable row level security;
revoke all on public.seasonal_conclave_projects from public, anon, authenticated;

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
  elsif p_event_id = 'sunwake_summer_sea' then
    local_start := make_timestamp(event_year, 7, 20, 0, 0, 0);
    local_end := make_timestamp(event_year, 7, 27, 0, 0, 0);
  elsif p_event_id = 'harvestmoon_moonlit_orchard' then
    local_start := make_timestamp(event_year, 9, 7, 0, 0, 0);
    local_end := make_timestamp(event_year, 9, 14, 0, 0, 0);
  elsif p_event_id = 'pride_every_color' then
    local_start := make_timestamp(event_year, 6, 1, 0, 0, 0);
    local_end := make_timestamp(event_year, 6, 8, 0, 0, 0);
  else
    return;
  end if;

  -- The first configured editions are a hard lower boundary.
  if (p_event_id in ('halloween_witchlight', 'christmas_winter_hearth',
        'new_year_first_dawn') and event_year < 2026)
     or (p_event_id in ('valentine_two_heartlights', 'pride_every_color',
        'sunwake_summer_sea', 'harvestmoon_moonlit_orchard')
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
    when 'SUNWAKEEVENT' then 'sunwake_summer_sea'
    when 'HARVESTMOONEVENT' then 'harvestmoon_moonlit_orchard'
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
    when 'sunwake_summer_sea' then 'sunwakeSurf'
    when 'harvestmoon_moonlit_orchard' then 'moonlitOrchard'
    when 'golden_wings_birthday' then 'wishcakeTower'
    when 'halloween_witchlight' then 'witchlightWard'
    when 'christmas_winter_hearth' then 'hollyfrostGiftforge'
    when 'new_year_first_dawn' then 'midnightChime'
    when 'valentine_two_heartlights' then 'rosevowRelay'
    when 'pride_every_color' then 'prismaticParade'
    else null end;
  if expected_trial is null or p_trial_key is distinct from expected_trial then
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
    user_id, event_id, trial_key, occurrence_key, seed, simulated, expires_at, conclave_id
  ) values (
    current_user_id, p_event_id, p_trial_key, occurrence,
    floor(random() * 2147483646)::integer, is_preview, now() + interval '6 hours',
    (select cm.conclave_id from public.conclave_members cm where cm.user_id = current_user_id)
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
     or (p_duration_ms < 30000 and not (
       (attempt.trial_key in ('witchlightWard', 'hollyfrostGiftforge', 'midnightChime',
         'sunwakeSurf', 'moonlitOrchard') and p_total_actions - p_correct_actions = 3)
       or (attempt.trial_key = 'wishcakeTower' and p_total_actions - p_correct_actions in (1,3))))
     or p_duration_ms > 180000 or p_score > p_correct_actions * 220
     or extract(epoch from (now() - attempt.started_at)) * 1000 < p_duration_ms - 5000 then
    raise exception 'seasonal_score_rejected';
  end if;
  accuracy_value := case when p_total_actions = 0 then 0 else
    round(p_correct_actions::numeric * 1000 / p_total_actions)::integer end;
  update public.seasonal_trial_attempts set completed_at = now(), score = p_score,
    correct_actions = p_correct_actions, total_actions = p_total_actions,
    duration_ms = p_duration_ms where id = attempt.id;

  -- Credit the Conclave recorded at start, even if membership changes mid-run.
  -- The used-attempt lock makes a retry incapable of adding a second contribution.
  -- Preview runs are visible separately and never unlock a permanent decoration.
  if not attempt.simulated and attempt.conclave_id is not null and p_correct_actions > 0
      and attempt.event_id in ('sunwake_summer_sea','harvestmoon_moonlit_orchard') then
    insert into public.seasonal_conclave_projects(conclave_id,event_id,occurrence_key,completed_trials)
      values(attempt.conclave_id,attempt.event_id,attempt.occurrence_key,1)
      on conflict(conclave_id,event_id,occurrence_key) do update
        set completed_trials=public.seasonal_conclave_projects.completed_trials+1,updated_at=now();
  end if;
  -- Serialize different attempts by the same keeper so a slower completion cannot
  -- overwrite a newer, higher best while both transactions are still in flight.
  perform pg_advisory_xact_lock(hashtextextended(current_user_id::text, 0));
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


create or replace function public.finalize_my_seasonal_event_prizes()
returns table (
  event_id text, occurrence_key text, ranking_position integer,
  display_name text, score integer, podium_emote_id text,
  prize_id uuid, claimed boolean
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  event_name text;
  best_occurrence text;
  window_row record;
begin
  if auth.uid() is null then raise exception 'online_login_required'; end if;
  foreach event_name in array array[
    'halloween_witchlight','christmas_winter_hearth','new_year_first_dawn',
    'valentine_two_heartlights','pride_every_color',
    'sunwake_summer_sea','harvestmoon_moonlit_orchard'
  ] loop
    select b.occurrence_key into best_occurrence
    from public.seasonal_trial_bests b
    where b.event_id = event_name and not b.preview
    order by b.achieved_at desc limit 1;
    if best_occurrence is null then continue; end if;
    select * into window_row from public.seasonal_event_window(
      event_name,
      (split_part(best_occurrence, ':', 2) || '-07-01')::date::timestamptz
    );
    if window_row.ends_at is null or now() < window_row.ends_at then continue; end if;
    insert into public.seasonal_event_prizes(
      event_id, occurrence_key, user_id, ranking_position, score, podium_emote_id
    )
    select event_name, best_occurrence, ranked.user_id, ranked.pos, ranked.score,
      'seasonal_' || case event_name
        when 'halloween_witchlight' then 'halloween'
        when 'christmas_winter_hearth' then 'christmas'
        when 'new_year_first_dawn' then 'new_year'
        when 'valentine_two_heartlights' then 'valentine'
        when 'sunwake_summer_sea' then 'sunwake'
        when 'harvestmoon_moonlit_orchard' then 'harvestmoon'
        else 'pride' end || '_' || case ranked.pos
          when 1 then 'gold' when 2 then 'silver' else 'bronze' end
    from (
      select b.user_id, b.score, row_number() over(order by b.score desc,
        b.accuracy_permille desc, b.duration_ms, b.achieved_at, b.user_id)::integer pos
      from public.seasonal_trial_bests b
      where b.event_id = event_name and b.occurrence_key = best_occurrence
        and not b.preview
    ) ranked where ranked.pos <= 3
    on conflict do nothing;
  end loop;
  return query
  select p.event_id, p.occurrence_key, p.ranking_position, pr.display_name,
    p.score, p.podium_emote_id, p.id, p.claimed_at is not null
  from public.seasonal_event_prizes p
  join public.profiles pr on pr.user_id = p.user_id
  where p.user_id = auth.uid() and p.claimed_at is null
  order by p.finalized_at;
end
$$;

-- Only a member's own snapshot may read these cosmetic records.
create or replace function private.seasonal_conclave_project_snapshot(p_conclave_id uuid)
returns jsonb language plpgsql security definer set search_path = '' stable as $$
declare event_name text; win record; progress record; n bigint; is_preview boolean;
  active_now boolean; result jsonb := '[]'::jsonb; occurrence text;
begin
  if not exists(select 1 from public.conclave_members cm
      where cm.conclave_id=p_conclave_id and cm.user_id=auth.uid()) then
    return result;
  end if;
  foreach event_name in array array['sunwake_summer_sea','harvestmoon_moonlit_orchard'] loop
    n := 0; occurrence := null;
    select * into win from public.seasonal_event_window(event_name,now());
    is_preview := exists(select 1 from public.list_my_seasonal_event_previews() p
      where p.event_id=event_name);
    active_now := is_preview or (win.starts_at is not null and now()>=win.starts_at and now()<win.ends_at
      and not exists(select 1 from public.list_my_seasonal_event_previews())
      and not exists(select 1 from public.list_my_seasonal_event_dismissals() d where d.event_id=event_name));
    if is_preview then
      select count(*) into n from public.seasonal_trial_attempts a
        where a.conclave_id=p_conclave_id and a.event_id=event_name and a.simulated
          and a.completed_at>now()-interval '48 hours' and a.correct_actions>0;
      occurrence := 'preview:' || event_name;
    elsif active_now then
      occurrence := win.occurrence_key;
      select coalesce(max(p.completed_trials),0) into n from public.seasonal_conclave_projects p
        where p.conclave_id=p_conclave_id and p.event_id=event_name and p.occurrence_key=occurrence;
    else
      select p.* into progress from public.seasonal_conclave_projects p
        where p.conclave_id=p_conclave_id and p.event_id=event_name
        order by p.occurrence_key desc limit 1;
      if found then n:=progress.completed_trials; occurrence:=progress.occurrence_key; end if;
    end if;
    if active_now or n>0 then
      result := result || jsonb_build_array(jsonb_build_object('event_id',event_name,
        'occurrence_key',occurrence,'completed_trials',n,'preview',is_preview,'active',active_now));
    end if;
  end loop;
  return result;
end $$;
revoke all on function private.seasonal_conclave_project_snapshot(uuid) from public,anon,authenticated;

create or replace function public.get_my_conclave_snapshot()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare cid uuid; result jsonb;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  perform private.cleanup_ephemeral_social_content();
  select conclave_id into cid from public.conclave_members where user_id=auth.uid();
  if cid is null then return null; end if;
  select jsonb_build_object(
    'conclave',jsonb_build_object('conclave_id',c.id,'name',c.name,'emblem_key',c.emblem_key,'description',c.description,'language',c.language,'visibility',c.visibility,'member_limit',c.member_limit,'member_count',(select count(*) from public.conclave_members where conclave_id=c.id),'level',c.level,'xp',c.xp,'aerie_stage',least(10,1+((c.level-1)/5))),
    'seasonal_projects',private.seasonal_conclave_project_snapshot(cid),
    'my_role',(select role from public.conclave_members where conclave_id=cid and user_id=auth.uid()),
    'contributed_today',(select last_contribution_on=(now() at time zone 'utc')::date from public.conclave_members where conclave_id=cid and user_id=auth.uid()),
    'members',coalesce((select jsonb_agg(jsonb_build_object('user_id',p.user_id,'keeper_code',p.keeper_code,'display_name',p.display_name,'title',p.title,'portrait_key',p.portrait_key,'frame_key',p.frame_key,'badge_key',p.badge_key,'role',m.role,'joined_at',m.joined_at,'contribution_streak',m.contribution_streak) order by case m.role when 'flightmaster' then 0 when 'warden' then 1 else 2 end,lower(p.display_name)) from public.conclave_members m join public.profiles p on p.user_id=m.user_id where m.conclave_id=cid),'[]'::jsonb),
    'messages',coalesce((select jsonb_agg(jsonb_build_object('message_id',m.id,'sender_id',m.sender_id,'sender_name',p.display_name,'sender_portrait_key',p.portrait_key,'kind',m.kind,'body',m.body,'payload',m.payload,'created_at',m.created_at) order by m.created_at) from public.conclave_messages m join public.profiles p on p.user_id=m.sender_id where m.conclave_id=cid and m.created_at>=now()-interval '24 hours'),'[]'::jsonb),
    'chronicle',coalesce((select jsonb_agg(entry order by created_at desc) from (select jsonb_build_object('entry_id',ch.id,'actor_name',p.display_name,'kind',ch.kind,'body',ch.body,'created_at',ch.created_at) entry,ch.created_at from public.conclave_chronicle ch left join public.profiles p on p.user_id=ch.actor_id where ch.conclave_id=cid order by ch.created_at desc limit 100) q),'[]'::jsonb),
    'join_requests',case when exists(select 1 from public.conclave_members where conclave_id=cid and user_id=auth.uid() and role in ('flightmaster','warden')) then coalesce((select jsonb_agg(jsonb_build_object('request_id',r.id,'user_id',p.user_id,'keeper_code',p.keeper_code,'display_name',p.display_name,'portrait_key',p.portrait_key,'created_at',r.created_at) order by r.created_at) from public.conclave_join_requests r join public.profiles p on p.user_id=r.user_id where r.conclave_id=cid),'[]'::jsonb) else '[]'::jsonb end
  ) into result from public.conclaves c where c.id=cid;
  return result;
end
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
      'new_year_first_dawn','valentine_two_heartlights','pride_every_color',
      'sunwake_summer_sea','harvestmoon_moonlit_orchard'] loop
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

-- Keep dormant economy chest definitions in sync; mutation switches stay disabled.
create or replace function private.economy_chest_catalog()
returns jsonb language sql immutable set search_path = '' as $$
  select $catalog${"version":3,"portrait":["portrait_001","portrait_002","portrait_003","portrait_004","portrait_005","portrait_006","portrait_007","portrait_008","portrait_009","portrait_010","portrait_011","portrait_012","portrait_013","portrait_014","portrait_015","portrait_016","portrait_017","portrait_018","portrait_019","portrait_020","portrait_021","portrait_022","portrait_023","portrait_024","portrait_025","portrait_026","portrait_027","portrait_028","portrait_029","portrait_030","portrait_031","portrait_032","portrait_033","portrait_034","portrait_035","portrait_036","portrait_037","portrait_038","portrait_039","portrait_040","portrait_041","portrait_042","portrait_043","portrait_044","portrait_045","portrait_046","portrait_047","portrait_048","portrait_049","portrait_050","portrait_051","portrait_052","portrait_053","portrait_054","portrait_055","portrait_056","portrait_057","portrait_058","portrait_059","portrait_060","portrait_061","portrait_062","portrait_063","portrait_064","portrait_065","portrait_066","portrait_067","portrait_068","portrait_069","portrait_070","portrait_071","portrait_072","portrait_073","portrait_074","portrait_075","portrait_076","portrait_077","portrait_078","portrait_079","portrait_080","portrait_081","portrait_082","portrait_083","portrait_084","portrait_085","portrait_086","portrait_087","portrait_088","portrait_089","portrait_090","portrait_091","portrait_092","portrait_093","portrait_094","portrait_095","portrait_096","portrait_097","portrait_098","portrait_099","portrait_100"],"title":["title_001","title_002","title_003","title_004","title_005","title_006","title_007","title_008","title_009","title_010","title_011","title_012","title_013","title_014","title_015","title_016","title_017","title_018","title_019","title_020","title_021","title_022","title_023","title_024","title_025","title_026","title_027","title_028","title_029","title_030","title_031","title_032","title_033","title_034","title_035","title_036","title_037","title_038","title_039","title_040","title_041","title_042","title_043","title_044","title_045","title_046","title_047","title_048","title_049","title_050","title_051","title_052","title_053","title_054","title_055","title_056","title_057","title_058","title_059","title_060","title_061","title_062","title_063","title_064","title_065","title_066","title_067","title_068","title_069","title_070","title_071","title_072","title_073","title_074","title_075","title_076","title_077","title_078","title_079","title_080","title_081","title_082","title_083","title_084","title_085","title_086","title_087","title_088","title_089","title_090","title_091","title_092","title_093","title_094","title_095","title_096","title_097","title_098","title_099","title_100","title_101","title_102","title_103","title_104","title_105","title_106","title_107","title_108","title_109","title_110","title_111","title_112","title_113","title_114","title_115","title_116","title_117","title_118","title_119","title_120","title_121","title_122","title_123","title_124","title_125","title_126","title_127","title_128","title_129","title_130","title_131","title_132","title_133","title_134","title_135","title_136","title_137","title_138","title_139","title_140","title_141","title_142","title_143","title_144","title_145","title_146","title_147","title_148","title_149","title_150","title_151","title_152","title_153","title_154","title_155","title_156","title_157","title_158","title_159","title_160","title_161","title_162","title_163","title_164","title_165","title_166","title_167","title_168","title_169","title_170","title_171","title_172","title_173","title_174","title_175","title_176","title_177","title_178","title_179","title_180","title_181","title_182","title_183","title_184","title_185","title_186","title_187","title_188","title_189","title_190","title_191","title_192","title_193","title_194","title_195","title_196","title_197","title_198","title_199","title_200","title_201","title_202","title_203","title_204","title_205","title_206","title_207","title_208","title_209","title_210","title_211","title_212","title_213","title_214","title_215","title_216","title_217","title_218","title_219","title_220","title_221","title_222","title_223","title_224","title_225","title_226","title_227","title_228","title_229","title_230","title_231","title_232","title_233","title_234","title_235","title_236","title_237","title_238","title_239","title_240","title_241","title_242","title_243","title_244","title_245","title_246","title_247","title_248","title_249","title_250","title_251","title_252","title_253","title_254","title_255","title_256","title_257","title_258","title_259","title_260","title_261","title_262","title_263","title_264","title_265","title_266","title_267","title_268","title_269","title_270","title_271","title_272","title_273","title_274","title_275","title_276","title_277","title_278","title_279","title_280","title_281","title_282","title_283","title_284","title_285","title_286","title_287","title_288","title_289","title_290","title_291","title_292","title_293","title_294","title_295","title_296","title_297","title_298","title_299","title_300","title_301","title_302","title_303","title_304","title_305","title_306","title_307","title_308","title_309","title_310","title_311","title_312","title_313","title_314","title_315","title_316","title_317","title_318","title_319","title_320","title_321","title_322","title_323","title_324","title_325","title_326","title_327","title_328","title_329","title_330","title_331","title_332","title_333","title_334","title_335","title_336","title_337","title_338","title_339","title_340","title_341","title_342","title_343","title_344","title_345","title_346","title_347","title_348","title_349","title_350","title_351","title_352","title_353","title_354","title_355","title_356","title_357","title_358","title_359","title_360","title_361","title_362","title_363","title_364","title_365","title_366","title_367","title_368","title_369","title_370","title_371","title_372","title_373","title_374","title_375","title_376","title_377","title_378","title_379","title_380","title_381","title_382","title_383","title_384","title_385","title_386","title_387","title_388","title_389","title_390","title_391","title_392","title_393","title_394","title_395","title_396","title_397","title_398","title_399","title_400","title_401","title_402","title_403","title_404","title_405","title_406","title_407","title_408","title_409","title_410","title_411","title_412","title_413","title_414","title_415","title_416","title_417","title_418","title_419","title_420","title_421","title_422","title_423","title_424","title_425","title_426","title_427","title_428","title_429","title_430","title_431","title_432","title_433","title_434","title_435","title_436","title_437","title_438","title_439","title_440","title_441","title_442","title_443","title_444","title_445","title_446","title_447","title_448","title_449","title_450","title_451","title_452","title_453","title_454","title_455","title_456","title_457","title_458","title_459","title_460","title_461","title_462","title_463","title_464","title_465","title_466","title_467","title_468","title_469","title_470","title_471","title_472","title_473","title_474","title_475","title_476","title_477","title_478","title_479","title_480","title_481","title_482","title_483","title_484","title_485","title_486","title_487","title_488","title_489","title_490","title_491","title_492","title_493","title_494","title_495","title_496","title_497","title_498","title_499","title_500"],"music":["clair_de_lune","arabesque_1","reverie","flaxen_hair","golliwoggs_cakewalk","gymnopedie_1","gymnopedie_2","gymnopedie_3","gnossienne_1","gnossienne_3","je_te_veux","fur_elise","moonlight_1","moonlight_3","pathetique_2","ode_to_joy","symphony_5_1","symphony_7_2","eine_kleine_nachtmusik","rondo_alla_turca","symphony_40_1","sonata_k545_1","lacrimosa","dies_irae","ave_verum","canon_in_d","air_g_string","prelude_c_major","toccata_fugue_d_minor","cello_suite_1_prelude","jesu_joy","badinerie","minuet_g_major","spring","summer_presto","autumn_1","winter_1","winter_2","sugar_plum","waltz_flowers","trepak","swan_lake_scene","sleeping_beauty_waltz","1812_finale","mountain_king","morning_mood","anitras_dance","solveigs_song","nocturne_9_2","prelude_28_4","raindrop_prelude","minute_waltz","funeral_march","fantaisie_impromptu","hungarian_dance_5","hungarian_dance_6","lullaby","blue_danube","tritsch_tratsch","radetzky_march","can_can","barcarolle","ride_valkyries","bridal_chorus","bumblebee","scheherazade_prince_princess","procession_nobles","entertainer","maple_leaf_rag","easy_winners","solace","elite_syncopations","greensleeves","scarborough_fair","drunken_sailor","irish_washerwoman","korobeiniki","house_rising_sun","amazing_grace","auld_lang_syne"],"emote":["chest_treasure_hello","chest_coin_eyes","chest_sleepy_hoard","chest_surprise_egg","chest_lucky_gem","chest_chest_peek","chest_gem_tears","chest_golden_laugh","chest_map_confused","chest_key_found","chest_mimic_shock","chest_coin_rain","chest_tiny_hoard","chest_pearl_proud","chest_treasure_sleep","chest_locked_out","chest_crown_try","chest_dusty_sneeze","chest_potion_find","chest_silver_bell","chest_scroll_wow","chest_ruby_blush","chest_sapphire_cool","chest_jackpot","chest_dragon_detective","chest_adored","chest_nervous","chest_terrified","chest_furious","chest_sulking","chest_jealous","chest_guilty","chest_embarrassed","chest_shy","chest_skeptical","chest_disgusted","chest_curious","chest_awestruck","chest_hopeful","chest_relieved","chest_grateful","chest_lonely","chest_homesick","chest_protective","chest_generous","chest_mischievous","chest_impatient","chest_overwhelmed","chest_content","chest_bored","chest_misty_eyes","chest_single_tear","chest_happy_tears","chest_heartbroken_sob","chest_dramatic_bawl"],"relic":["moralPrism","orderCompass","soulMirror","astralLens","chronoshard","wayfinderSigil","twinstarBrooch","emberheartBrooch","moonweaveBrooch","soulbloomBrooch"],"relic_weights":{"moralPrism":10,"orderCompass":10,"soulMirror":10,"astralLens":10,"chronoshard":10,"wayfinderSigil":10,"twinstarBrooch":1,"emberheartBrooch":1,"moonweaveBrooch":1,"soulbloomBrooch":1},"unique_relics":["twinstarBrooch","emberheartBrooch","moonweaveBrooch","soulbloomBrooch"],"lineages":{"common":["mossprout","crystalwhisk","dustglimmer","gleamclaw","emberbun","copperflame","spicewing","bubblefin","linencloud","tidescale","clockskip","galeear","thunderpuff","dreammoth","dewhorn","quietstar","heartwing","twinflare","rainbowruff","harmonytail"],"uncommon":["bramblequill","cinderlynx","mistmantle","runehopper","petaldrift","ironwhistle","frostfable","sunmuzzle","echofern","velvetvolt"],"rare":["auroracrown","voidbloom","coraloracle","meteorhide","temporalark","opalchimera"],"veryRare":["eclipseantler","worldroot","seraphscale"],"legendary":["starforged","leviathanecho"],"mythical":["everwyrm"],"specialEvent":[]},"spectral_chance":0.05,"special_eggs":{"harvestmoon_egg_v1":{"lineage":"ciderhorn","incubation_seconds":64800,"moral":"good","moral_known_at_hatch":true,"spectral_chance":0.05},"sunwake_egg_v1":{"lineage":"solmanta","incubation_seconds":72000,"moral":"good","moral_known_at_hatch":true,"spectral_chance":0.05},"golden_wings_egg_v1":{"lineage":"cluckatrice","incubation_seconds":75600,"moral":null,"moral_known_at_hatch":false,"spectral_chance":0.05},"witchlight_egg_v1":{"lineage":"gloamgourd","incubation_seconds":47593,"moral":null,"moral_known_at_hatch":false,"spectral_chance":0.05},"starlit_evergreen_egg_v1":{"lineage":"hollyfrost","incubation_seconds":90000,"moral":"good","moral_known_at_hatch":true,"spectral_chance":0.05},"turning_year_egg_v1":{"lineage":"dawnchime","incubation_seconds":86400,"moral":"neutral","moral_known_at_hatch":true,"spectral_chance":0.05},"rosebound_egg_v1":{"lineage":"rosevow","incubation_seconds":50400,"moral":"good","moral_known_at_hatch":true,"spectral_chance":0.05},"truecolor_egg_v1":{"lineage":"spectrumplume","incubation_seconds":64800,"moral":"good","moral_known_at_hatch":true,"spectral_chance":0.05}},"special_chests":{"harvestmoon_chest_v1":{"coins":300,"gems":12,"egg":"harvestmoon_egg_v1"},"sunwake_chest_v1":{"coins":300,"gems":12,"egg":"sunwake_egg_v1"},"golden_wings_chest_v1":{"coins":269,"gems":10,"egg":"golden_wings_egg_v1"},"witchlight_chest_v1":{"coins":313,"gems":13,"egg":"witchlight_egg_v1"},"starlight_gift_chest_v1":{"coins":250,"gems":12,"egg":"starlit_evergreen_egg_v1"},"firstlight_celebration_chest_v1":{"coins":365,"gems":12,"egg":"turning_year_egg_v1"},"twinheart_keepsake_chest_v1":{"coins":214,"gems":14,"egg":"rosebound_egg_v1"},"radiant_festival_chest_v1":{"coins":300,"gems":15,"egg":"truecolor_egg_v1"}},"tiers":{"wooden":{"coins_min":20,"coins_max":40,"gem_chance":0.0,"gems_min":0,"gems_max":0,"egg_chance":0.01,"relic_chance":0.0,"emote_chance":0.005,"rarity":[0.75,0.95,0.995,0.9995,0.99999]},"silver":{"coins_min":45,"coins_max":80,"gem_chance":0.5,"gems_min":1,"gems_max":2,"egg_chance":0.04,"relic_chance":0.0,"emote_chance":0.01,"rarity":[0.65,0.9,0.98,0.997,0.9998]},"gold":{"coins_min":90,"coins_max":160,"gem_chance":0.72,"gems_min":2,"gems_max":4,"egg_chance":0.12,"relic_chance":0.01,"emote_chance":0.02,"rarity":[0.5,0.8,0.94,0.99,0.999]},"dragon":{"coins_min":180,"coins_max":300,"gem_chance":0.9,"gems_min":4,"gems_max":7,"egg_chance":1.0,"relic_chance":0.02,"emote_chance":0.04,"rarity":[0.25,0.55,0.8,0.95,0.995]},"mythical":{"coins_min":400,"coins_max":650,"gem_chance":1.0,"gems_min":8,"gems_max":13,"egg_chance":1.0,"relic_chance":0.04,"emote_chance":0.08,"rarity":[0.1,0.3,0.55,0.8,0.97]},"sinister":{"coins_min":400,"coins_max":650,"gem_chance":1.0,"gems_min":8,"gems_max":13,"egg_chance":1.0,"relic_chance":1.0,"emote_chance":0.12,"rarity":[0.1,0.3,0.55,0.8,0.97]}}}$catalog$::jsonb;
$$;
