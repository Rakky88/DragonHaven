-- Three additional standard Trials keep independent account bests and ranking
-- ladders. Existing Cavern Flight, Ruin Breaker and Runeweaver identities stay
-- unchanged for checkpoint and leaderboard continuity.
alter table public.social_showcases
  add column if not exists spirit_alignment_best bigint not null default 0,
  add column if not exists ruin_guard_best bigint not null default 0,
  add column if not exists rune_orbit_best bigint not null default 0;

alter table public.social_showcases
  drop constraint if exists social_showcases_spirit_alignment_best_check,
  add constraint social_showcases_spirit_alignment_best_check
    check (spirit_alignment_best between 0 and 9007199254740991),
  drop constraint if exists social_showcases_ruin_guard_best_check,
  add constraint social_showcases_ruin_guard_best_check
    check (ruin_guard_best between 0 and 9007199254740991),
  drop constraint if exists social_showcases_rune_orbit_best_check,
  add constraint social_showcases_rune_orbit_best_check
    check (rune_orbit_best between 0 and 9007199254740991);

create index if not exists social_showcases_spirit_alignment_rank_idx
  on public.social_showcases (spirit_alignment_best desc, user_id)
  where spirit_alignment_best > 0;
create index if not exists social_showcases_ruin_guard_rank_idx
  on public.social_showcases (ruin_guard_best desc, user_id)
  where ruin_guard_best > 0;
create index if not exists social_showcases_rune_orbit_rank_idx
  on public.social_showcases (rune_orbit_best desc, user_id)
  where rune_orbit_best > 0;

create or replace function private.project_standard_trial_bests()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  state jsonb;
  alignment bigint := 0;
  guard bigint := 0;
  orbit bigint := 0;
begin
  select g.state into state
  from private.canonical_game_states g
  where g.owner_id = new.owner_id
    and g.revision = new.revision
    and g.state_sha256 = new.state_sha256;
  if state is null then
    raise exception 'game_social_projection_unavailable';
  end if;
  select
    coalesce(max((d->'trialHighScores'->>'spiritAlignment')::bigint), 0),
    coalesce(max((d->'trialHighScores'->>'ruinGuard')::bigint), 0),
    coalesce(max((d->'trialHighScores'->>'runeOrbit')::bigint), 0)
  into alignment, guard, orbit
  from jsonb_array_elements(
    jsonb_build_array(state->'pet') ||
      coalesce(state->'sanctuaryDragons', '[]'::jsonb)
  ) d
  where d->>'stage' <> 'egg';

  update public.social_showcases
  set spirit_alignment_best = alignment,
      ruin_guard_best = guard,
      rune_orbit_best = orbit
  where user_id = new.owner_id;
  return new;
end
$$;

revoke all on function private.project_standard_trial_bests()
  from public, anon, authenticated;
drop trigger if exists project_standard_trial_bests
  on private.canonical_social_projections;
create trigger project_standard_trial_bests
after insert or update on private.canonical_social_projections
for each row execute function private.project_standard_trial_bests();

-- Backfill from the currently accepted canonical projection without changing
-- its revision or hash. The canonical showcase guard intentionally fences
-- ordinary SQL writes for server-owned accounts, so scope its existing
-- service-role bypass to this projection repair only.
do $backfill$
declare
  previous_role text := current_setting('request.jwt.claim.role', true);
begin
  perform set_config('request.jwt.claim.role', 'service_role', true);
  update public.social_showcases s
  set spirit_alignment_best = scores.alignment,
      ruin_guard_best = scores.guard,
      rune_orbit_best = scores.orbit
  from (
    select g.owner_id,
      coalesce(max((d->'trialHighScores'->>'spiritAlignment')::bigint), 0)
        as alignment,
      coalesce(max((d->'trialHighScores'->>'ruinGuard')::bigint), 0)
        as guard,
      coalesce(max((d->'trialHighScores'->>'runeOrbit')::bigint), 0)
        as orbit
    from private.canonical_game_states g
    join private.canonical_social_projections p
      on p.owner_id = g.owner_id
     and p.revision = g.revision
     and p.state_sha256 = g.state_sha256
    cross join lateral jsonb_array_elements(
      jsonb_build_array(g.state->'pet') ||
        coalesce(g.state->'sanctuaryDragons', '[]'::jsonb)
    ) d
    where d->>'stage' <> 'egg'
    group by g.owner_id
  ) scores
  where s.user_id = scores.owner_id;
  perform set_config(
    'request.jwt.claim.role',
    coalesce(previous_role, ''),
    true
  );
exception when others then
  perform set_config(
    'request.jwt.claim.role',
    coalesce(previous_role, ''),
    true
  );
  raise;
end
$backfill$;

-- Preserve the existing dispatcher, including all seasonal/event Trial
-- rankings. The public wrapper below owns only the three new standard keys and
-- delegates every older key so its event-window and preview semantics remain
-- byte-for-byte those of the already deployed function.
do $preserve_rankings$
begin
  if to_regprocedure(
    'public.get_trial_rankings_v96(text,text,integer)'
  ) is null then
    execute 'alter function public.get_trial_rankings(text,text,integer) '
      || 'rename to get_trial_rankings_v96';
  end if;
end
$preserve_rankings$;
revoke all on function public.get_trial_rankings_v96(text,text,integer)
  from public, anon, authenticated, service_role;

create or replace function public.get_trial_rankings(
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
  if p_scope not in ('world', 'friends', 'conclave') then
    raise exception 'trial_rankings_invalid';
  end if;
  if p_trial_key not in ('spiritAlignment', 'ruinGuard', 'runeOrbit') then
    return query
      select *
      from public.get_trial_rankings_v96(p_trial_key, p_scope, p_limit);
    return;
  end if;
  if p_scope = 'conclave' and not exists (
    select 1 from public.conclave_members mine
    where mine.user_id = current_user_id
  ) then
    raise exception 'not_in_conclave';
  end if;

  return query
  with scores as (
    select s.user_id, s.spirit_alignment_best as score
    from public.social_showcases s
    where p_trial_key = 'spiritAlignment' and s.spirit_alignment_best > 0
    union all
    select s.user_id, s.ruin_guard_best as score
    from public.social_showcases s
    where p_trial_key = 'ruinGuard' and s.ruin_guard_best > 0
    union all
    select s.user_id, s.rune_orbit_best as score
    from public.social_showcases s
    where p_trial_key = 'runeOrbit' and s.rune_orbit_best > 0
  ),
  candidates as (
    select p.user_id, p.display_name, p.title, p.portrait_key, p.frame_key,
      p.badge_key, scores.score
    from public.profiles p
    join scores on scores.user_id = p.user_id
    where (
      p_scope = 'world'
      or (
        p_scope = 'friends' and (
          p.user_id = current_user_id
          or exists (
            select 1 from public.friendships f
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
    select rank() over (order by candidates.score desc) as ranking_position,
      candidates.*
    from candidates
  )
  select ranked.ranking_position,
    ranked.ranking_position::text || '-' ||
      row_number() over (
        order by ranked.ranking_position, lower(ranked.display_name),
          ranked.user_id
      )::text,
    ranked.display_name, ranked.title, ranked.portrait_key, ranked.frame_key,
    ranked.badge_key, ranked.score, ranked.user_id = current_user_id
  from ranked
  where p_scope <> 'world'
     or ranked.ranking_position <= bounded_limit
     or ranked.user_id = current_user_id
  order by ranked.ranking_position, lower(ranked.display_name),
    ranked.user_id;
end
$$;

revoke all on function public.get_trial_rankings(text,text,integer)
  from public, anon;
grant execute on function public.get_trial_rankings(text,text,integer)
  to authenticated;
