-- Accept early Witchlight endings after exactly three mistakes. Other seasonal
-- Trials retain their minimum duration and all existing score/token checks.

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
  if attempt.completion_token::text <> p_completion_token then
    raise exception 'seasonal_attempt_token_invalid';
  end if;
  if p_score < 0 or p_score > 20000 or p_total_actions < 0
     or p_total_actions > 200 or p_correct_actions < 0
     or p_correct_actions > p_total_actions or p_duration_ms < 1000
     or (p_duration_ms < 30000 and not (attempt.trial_key = 'witchlightWard'
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
