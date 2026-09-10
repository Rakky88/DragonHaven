-- Additive compatibility update; no economy switches or saved balances change.
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
     or p_score::bigint > p_correct_actions::bigint * 220
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

-- Renewable inactivity lease: a player still surfing after six hours can keep
-- playing. A finished, abandoned/expired or foreign attempt cannot be revived.
create or replace function public.renew_seasonal_trial_attempt(
  p_attempt_id uuid, p_completion_token text
) returns timestamptz language plpgsql security definer set search_path = '' as $$
declare
  renewed timestamptz;
begin
  if auth.uid() is null then raise exception 'online_login_required'; end if;
  update public.seasonal_trial_attempts
    set expires_at = greatest(expires_at, now() + interval '6 hours')
    where id = p_attempt_id and user_id = auth.uid()
      and trial_key = 'sunwakeSurf' and completed_at is null
      and completion_token::text = p_completion_token and expires_at > now()
    returning expires_at into renewed;
  if renewed is null then raise exception 'seasonal_attempt_unavailable'; end if;
  return renewed;
end;
$$;
revoke all on function public.renew_seasonal_trial_attempt(uuid,text) from public, anon;
grant execute on function public.renew_seasonal_trial_attempt(uuid,text) to authenticated;
