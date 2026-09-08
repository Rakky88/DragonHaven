-- Read-only calibration window requested on 8 September 2026. Amsterdam local
-- boundaries; all accepted test attempts remain in the existing attempt table
-- after a personal preview expires. Never merge them into the live leaderboard.
begin read only;
with calibration_window as (
  select '2026-09-08 00:00:00 Europe/Amsterdam'::timestamptz as starts_at,
         '2026-09-22 00:00:00 Europe/Amsterdam'::timestamptz as ends_at
), attempts as (
  select a.user_id, a.score, a.correct_actions, a.total_actions,
         a.duration_ms, a.completed_at
  from public.seasonal_trial_attempts a cross join calibration_window w
  where a.event_id = 'halloween_witchlight' and a.trial_key = 'witchlightWard'
    and a.simulated and a.completed_at >= w.starts_at
    and a.completed_at < w.ends_at
), keeper_bests as (
  select user_id, max(score) as score from attempts group by user_id
), cohorts as (
  select 'all_attempts' as cohort, score from attempts
  union all
  select 'one_best_per_keeper', score from keeper_bests
), distributions as (
  select cohort, count(*) as samples, min(score) as minimum, max(score) as maximum,
    percentile_disc(array[.10, .25, .50, .75, .90, .95, .99])
      within group (order by score) as p10_p25_p50_p75_p90_p95_p99
  from cohorts group by cohort
), daily as (
  select (completed_at at time zone 'Europe/Amsterdam')::date as day,
    count(*) as attempts, count(distinct user_id) as keepers, max(score) as best
  from attempts group by 1
), buckets as (
  select (score / 250) * 250 as score_from, count(*) as attempts
  from attempts group by 1
)
select jsonb_build_object(
  'event', 'halloween_witchlight',
  'generated_at', now(),
  'window_starts_at', w.starts_at,
  'window_ends_at', w.ends_at,
  'window_finished', now() >= w.ends_at,
  'accepted_attempts', (select count(*) from attempts),
  'participating_keepers', (select count(*) from keeper_bests),
  'percentiles', coalesce((select jsonb_agg(to_jsonb(d) order by cohort) from distributions d), '[]'::jsonb),
  'daily', coalesce((select jsonb_agg(to_jsonb(d) order by day) from daily d), '[]'::jsonb),
  'score_buckets_250', coalesce((select jsonb_agg(to_jsonb(b) order by score_from) from buckets b), '[]'::jsonb),
  'early_three_mistake_endings', (select count(*) from attempts where total_actions - correct_actions = 3 and duration_ms < 30000),
  'review_note', 'Review all attempts and one best per keeper together; percentiles are observations, not automatic rank thresholds. No names, account IDs or tokens are exported.'
) as calibration_report from calibration_window w;
commit;
