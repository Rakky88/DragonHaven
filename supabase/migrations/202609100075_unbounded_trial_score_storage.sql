-- Preserve existing scores while widening transport/storage for long runs.
-- No event window, rank cutoff, reward or runtime switch changes.
alter table public.seasonal_trial_attempts
  alter column score type bigint, alter column correct_actions type bigint,
  alter column total_actions type bigint, alter column duration_ms type bigint;
alter table public.seasonal_trial_bests
  alter column score type bigint, alter column duration_ms type bigint;
alter table public.seasonal_event_prizes alter column score type bigint;
alter table public.social_showcases
  alter column cavern_flight_best type bigint,
  alter column ruin_breaker_best type bigint,
  alter column runeweaver_best type bigint,
  alter column favorite_dragon_cavern_flight_best type bigint,
  alter column favorite_dragon_ruin_breaker_best type bigint,
  alter column favorite_dragon_runeweaver_best type bigint;

alter table public.seasonal_trial_attempts add constraint seasonal_trial_safe_integer
  check(score between 0 and 9007199254740991 and correct_actions between 0 and 9007199254740991
    and total_actions between 0 and 9007199254740991 and duration_ms between 0 and 9007199254740991);
alter table public.seasonal_trial_bests add constraint seasonal_best_safe_integer
  check(score between 0 and 9007199254740991 and duration_ms between 0 and 9007199254740991);
alter table public.seasonal_event_prizes add constraint seasonal_prize_safe_integer
  check(score between 0 and 9007199254740991);

alter function public.complete_seasonal_trial_attempt(uuid,text,integer,integer,integer,integer) rename to complete_seasonal_trial_attempt_v74;
revoke all on function public.complete_seasonal_trial_attempt_v74(uuid,text,integer,integer,integer,integer) from public,anon,authenticated,service_role;

create function public.complete_seasonal_trial_attempt(
  p_attempt_id uuid,
  p_completion_token text,
  p_score bigint,
  p_correct_actions bigint,
  p_total_actions bigint,
  p_duration_ms bigint
)
returns table (
  accepted boolean,
  best_score bigint,
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
  if p_score > 9007199254740991 or p_correct_actions > 9007199254740991 or
      p_total_actions > 9007199254740991 or p_duration_ms > 9007199254740991 then
    raise exception 'seasonal_score_rejected'; end if;
  if p_score is null or p_correct_actions is null or p_total_actions is null
     or p_duration_ms is null or p_score < 0 or p_total_actions < 0
     or p_correct_actions < 0
     or p_correct_actions > p_total_actions or p_duration_ms < 1000
     or (p_duration_ms < 30000 and not (
       (attempt.trial_key in ('witchlightWard', 'hollyfrostGiftforge', 'midnightChime',
         'sunwakeSurf', 'moonlitOrchard') and p_total_actions - p_correct_actions = 3)
       or (attempt.trial_key = 'wishcakeTower' and p_total_actions - p_correct_actions in (1,3))))
     or (attempt.trial_key <> 'sunwakeSurf' and
       (p_duration_ms > 180000 or p_score > 20000 or p_total_actions > 200))
     -- Sunwake has no game timer/score/action cap. Bound the rate of gates,
     -- not the total score, and retain old timed clients during rollout.
     or (attempt.trial_key = 'sunwakeSurf' and (
       p_total_actions > p_duration_ms::bigint / 560 + 2
       or p_total_actions - p_correct_actions > 3
       or (p_duration_ms > 81000 and p_total_actions - p_correct_actions <> 3)))
     or p_score::numeric > p_correct_actions::numeric * 220
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
revoke all on function public.complete_seasonal_trial_attempt(uuid,text,bigint,bigint,bigint,bigint) from public,anon;
grant execute on function public.complete_seasonal_trial_attempt(uuid,text,bigint,bigint,bigint,bigint) to authenticated;

alter function public.get_trial_rankings(text,text,integer) rename to get_trial_rankings_v74;
revoke all on function public.get_trial_rankings_v74(text,text,integer) from public,anon,authenticated,service_role;

create function public.get_trial_rankings(
  p_trial_key text,
  p_scope text,
  p_limit integer default 100
)
returns table (
  ranking_position bigint,
  entry_key text,
  display_name text,
  title text,
  portrait_key text,
  frame_key text,
  badge_key text,
  score bigint,
  is_current_user boolean
)
language plpgsql
security definer
set search_path = ''
stable
as $$
declare
  current_user_id uuid := auth.uid();
  bounded_limit integer := least(100, greatest(1, coalesce(p_limit, 100)));
begin
  if current_user_id is null then
    raise exception 'online_login_required';
  end if;
  if p_trial_key not in ('cavernFlight', 'ruinBreaker', 'runeweaver')
     or p_scope not in ('world', 'friends', 'conclave') then
    raise exception 'trial_rankings_invalid';
  end if;
  if p_scope = 'conclave' and not exists (
    select 1 from public.conclave_members mine
    where mine.user_id = current_user_id
  ) then
    raise exception 'not_in_conclave';
  end if;

  return query
  with scores as (
    select s.user_id, s.cavern_flight_best as score
    from public.social_showcases s
    where p_trial_key = 'cavernFlight' and s.cavern_flight_best > 0
    union all
    select s.user_id, s.ruin_breaker_best as score
    from public.social_showcases s
    where p_trial_key = 'ruinBreaker' and s.ruin_breaker_best > 0
    union all
    select s.user_id, s.runeweaver_best as score
    from public.social_showcases s
    where p_trial_key = 'runeweaver' and s.runeweaver_best > 0
  ),
  candidates as (
    select
      p.user_id,
      p.display_name,
      p.title,
      p.portrait_key,
      p.frame_key,
      p.badge_key,
      scores.score
    from public.profiles p
    join scores on scores.user_id = p.user_id
    where
      (
        p_scope = 'world'
        or (
          p_scope = 'friends'
          and (
            p.user_id = current_user_id
            or exists (
              select 1
              from public.friendships f
              where f.status = 'accepted'
                and (
                  (f.requester_id = current_user_id
                    and f.addressee_id = p.user_id)
                  or (f.addressee_id = current_user_id
                    and f.requester_id = p.user_id)
                )
            )
          )
        )
        or (
          p_scope = 'conclave'
          and exists (
            select 1
            from public.conclave_members mine
            join public.conclave_members theirs
              on theirs.conclave_id = mine.conclave_id
            where mine.user_id = current_user_id
              and theirs.user_id = p.user_id
          )
        )
      )
      and not exists (
        select 1
        from public.friendships blocked
        where blocked.status = 'blocked'
          and (
            (blocked.requester_id = current_user_id
              and blocked.addressee_id = p.user_id)
            or (blocked.addressee_id = current_user_id
              and blocked.requester_id = p.user_id)
          )
      )
  ),
  ranked as (
    select
      rank() over (order by candidates.score desc) as ranking_position,
      candidates.*
    from candidates
  )
  select
    ranked.ranking_position,
    ranked.ranking_position::text || '-' ||
      row_number() over (
        order by ranked.ranking_position, lower(ranked.display_name), ranked.user_id
      )::text,
    ranked.display_name,
    ranked.title,
    ranked.portrait_key,
    ranked.frame_key,
    ranked.badge_key,
    ranked.score,
    ranked.user_id = current_user_id
  from ranked
  where p_scope <> 'world'
     or ranked.ranking_position <= bounded_limit
     or ranked.user_id = current_user_id
  order by ranked.ranking_position, lower(ranked.display_name), ranked.user_id;
end
$$;
revoke all on function public.get_trial_rankings(text,text,integer) from public,anon;
grant execute on function public.get_trial_rankings(text,text,integer) to authenticated;

alter function public.get_seasonal_trial_rankings(text,text,boolean,integer) rename to get_seasonal_trial_rankings_v74;
revoke all on function public.get_seasonal_trial_rankings_v74(text,text,boolean,integer) from public,anon,authenticated,service_role;

create function public.get_seasonal_trial_rankings(
  p_event_id text,
  p_occurrence_key text,
  p_preview boolean default false,
  p_limit integer default 100
)
returns table (
  ranking_position bigint, user_id uuid, display_name text, title text,
  portrait_key text, frame_key text, badge_key text, score bigint,
  accuracy_permille integer, duration_ms bigint, is_current_user boolean
)
language sql
security definer
set search_path = ''
stable
as $$
  with ranked as (
    select b.*, rank() over(order by b.score desc, b.accuracy_permille desc,
      b.duration_ms, b.achieved_at, b.user_id) as pos
    from public.seasonal_trial_bests b
    where b.event_id = p_event_id and b.occurrence_key = p_occurrence_key
      and b.preview = p_preview
  )
  select r.pos, r.user_id, p.display_name, p.title, p.portrait_key,
    p.frame_key, p.badge_key, r.score, r.accuracy_permille, r.duration_ms,
    r.user_id = auth.uid()
  from ranked r join public.profiles p on p.user_id = r.user_id
  where auth.uid() is not null and (r.pos <= least(100, greatest(1, p_limit))
    or r.user_id = auth.uid())
    and (
      (p_preview
        and p_occurrence_key =
          'preview:' || p_event_id || ':' || auth.uid()::text
        and exists (
          select 1 from public.seasonal_event_previews ep
          where ep.user_id = auth.uid() and ep.event_id = p_event_id
            and ep.expires_at > now()
        ))
      or
      (not p_preview
        and p_occurrence_key ~ '^[a-z_]+:[0-9]{4}$'
        and exists (
          select 1
          from public.seasonal_event_window(
            p_event_id,
            (split_part(p_occurrence_key, ':', 2) || '-07-01')::date::timestamptz
          ) event_window
          where event_window.occurrence_key = p_occurrence_key
            and now() < event_window.results_end_at
        ))
    )
    and not exists (
      select 1 from public.friendships f where f.status = 'blocked' and
      ((f.requester_id = auth.uid() and f.addressee_id = r.user_id) or
       (f.addressee_id = auth.uid() and f.requester_id = r.user_id)))
  order by r.pos, lower(p.display_name), r.user_id;
$$;
revoke all on function public.get_seasonal_trial_rankings(text,text,boolean,integer) from public,anon;
grant execute on function public.get_seasonal_trial_rankings(text,text,boolean,integer) to authenticated;

alter function public.finalize_my_seasonal_event_prizes() rename to finalize_my_seasonal_event_prizes_v74;
revoke all on function public.finalize_my_seasonal_event_prizes_v74() from public,anon,authenticated,service_role;

create function public.finalize_my_seasonal_event_prizes()
returns table (
  event_id text, occurrence_key text, ranking_position integer,
  display_name text, score bigint, podium_emote_id text,
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
revoke all on function public.finalize_my_seasonal_event_prizes() from public,anon;
grant execute on function public.finalize_my_seasonal_event_prizes() to authenticated;

alter function public.list_seasonal_chronicle() rename to list_seasonal_chronicle_v74;
revoke all on function public.list_seasonal_chronicle_v74() from public,anon,authenticated,service_role;

create function public.list_seasonal_chronicle()
returns table (
  event_id text, occurrence_key text, ranking_position integer,
  display_name text, score bigint, podium_emote_id text,
  prize_id uuid, claimed boolean
)
language sql security definer set search_path = '' stable as $$
  select p.event_id, p.occurrence_key, p.ranking_position, pr.display_name,
    p.score, p.podium_emote_id,
    case when p.user_id = auth.uid() then p.id else null end,
    case when p.user_id = auth.uid() then p.claimed_at is not null else false end
  from public.seasonal_event_prizes p
  join public.profiles pr on pr.user_id = p.user_id
  where auth.uid() is not null
  order by p.occurrence_key desc, p.event_id, p.ranking_position;
$$;
revoke all on function public.list_seasonal_chronicle() from public,anon;
grant execute on function public.list_seasonal_chronicle() to authenticated;


alter function public.get_my_profile() rename to get_my_profile_v74;
revoke all on function public.get_my_profile_v74() from public,anon,authenticated,service_role;

create function public.get_my_profile()
returns table (
  user_id uuid, keeper_code text, display_name text, title text,
  portrait_key text, frame_key text, badge_key text,
  discovered_dragon_count bigint,
  achievement_count integer, dragon_count integer,
  inventory_imported boolean, discovered_forms text[],
  prismatic_forms text[], cavern_flight_best bigint,
  ruin_breaker_best bigint, runeweaver_best bigint,
  favorite_dragon_id text, favorite_dragon_name text,
  favorite_dragon_lineage_id text, favorite_dragon_stage text,
  favorite_dragon_level integer, favorite_dragon_might integer,
  favorite_dragon_arcana integer, favorite_dragon_spirit integer,
  favorite_dragon_evolution_path text, favorite_dragon_prismatic boolean,
  favorite_dragon_sinister boolean,
  favorite_dragon_cavern_flight_best bigint,
  favorite_dragon_ruin_breaker_best bigint,
  favorite_dragon_runeweaver_best bigint
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
revoke all on function public.get_my_profile() from public,anon;
grant execute on function public.get_my_profile() to authenticated;


alter function public.list_my_friends() rename to list_my_friends_v74;
revoke all on function public.list_my_friends_v74() from public,anon,authenticated,service_role;

create function public.list_my_friends()
returns table (
  user_id uuid, keeper_code text, display_name text, title text,
  portrait_key text, frame_key text, badge_key text,
  discovered_dragon_count bigint,
  achievement_count integer, dragon_count integer,
  inventory_imported boolean, discovered_forms text[],
  prismatic_forms text[], cavern_flight_best bigint,
  ruin_breaker_best bigint, runeweaver_best bigint,
  favorite_dragon_id text, favorite_dragon_name text,
  favorite_dragon_lineage_id text, favorite_dragon_stage text,
  favorite_dragon_level integer, favorite_dragon_might integer,
  favorite_dragon_arcana integer, favorite_dragon_spirit integer,
  favorite_dragon_evolution_path text, favorite_dragon_prismatic boolean,
  favorite_dragon_sinister boolean,
  favorite_dragon_cavern_flight_best bigint,
  favorite_dragon_ruin_breaker_best bigint,
  favorite_dragon_runeweaver_best bigint
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
revoke all on function public.list_my_friends() from public,anon;
grant execute on function public.list_my_friends() to authenticated;
