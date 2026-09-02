-- Read-only Trial leaderboards. Scores already live in social_showcases and
-- are published through the bounded publish_social_showcase RPC. This RPC
-- exposes only public Keeper vanity plus one best score; Keeper IDs, email,
-- inventory and cloud-save data never leave their existing trust boundaries.

create index if not exists social_showcases_cavern_flight_ranking_idx
  on public.social_showcases (cavern_flight_best desc, user_id)
  where cavern_flight_best > 0;
create index if not exists social_showcases_ruin_breaker_ranking_idx
  on public.social_showcases (ruin_breaker_best desc, user_id)
  where ruin_breaker_best > 0;
create index if not exists social_showcases_runeweaver_ranking_idx
  on public.social_showcases (runeweaver_best desc, user_id)
  where runeweaver_best > 0;

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
  score integer,
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

revoke all on function public.get_trial_rankings(text, text, integer)
  from public, anon;
grant execute on function public.get_trial_rankings(text, text, integer)
  to authenticated;
