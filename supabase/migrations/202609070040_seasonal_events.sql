-- Server-authoritative seasonal Trial previews, attempts, leaderboards and
-- one-time podium prizes. All schedule decisions use Europe/Amsterdam.

create table if not exists public.seasonal_event_previews (
  user_id uuid not null references auth.users(id) on delete cascade,
  event_id text not null,
  activated_at timestamptz not null default now(),
  expires_at timestamptz not null,
  primary key (user_id, event_id)
);

create table if not exists public.seasonal_trial_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  event_id text not null,
  trial_key text not null,
  occurrence_key text not null,
  completion_token uuid not null default gen_random_uuid(),
  seed integer not null,
  simulated boolean not null default false,
  started_at timestamptz not null default now(),
  expires_at timestamptz not null,
  completed_at timestamptz,
  score integer,
  correct_actions integer,
  total_actions integer,
  duration_ms integer
);

create unique index if not exists seasonal_trial_attempt_token_idx
  on public.seasonal_trial_attempts (completion_token);
create index if not exists seasonal_trial_attempt_user_idx
  on public.seasonal_trial_attempts (user_id, started_at desc);

create table if not exists public.seasonal_trial_bests (
  event_id text not null,
  occurrence_key text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  score integer not null,
  accuracy_permille integer not null,
  duration_ms integer not null,
  achieved_at timestamptz not null,
  preview boolean not null default false,
  primary key (event_id, occurrence_key, user_id)
);

create index if not exists seasonal_trial_bests_ranking_idx
  on public.seasonal_trial_bests (
    event_id, occurrence_key, preview, score desc,
    accuracy_permille desc, duration_ms, achieved_at, user_id
  );

create table if not exists public.seasonal_event_prizes (
  id uuid primary key default gen_random_uuid(),
  event_id text not null,
  occurrence_key text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  ranking_position integer not null check (ranking_position between 1 and 3),
  score integer not null,
  podium_emote_id text not null,
  finalized_at timestamptz not null default now(),
  claimed_at timestamptz,
  unique (event_id, occurrence_key, ranking_position),
  unique (event_id, occurrence_key, user_id)
);

alter table public.seasonal_event_previews enable row level security;
alter table public.seasonal_trial_attempts enable row level security;
alter table public.seasonal_trial_bests enable row level security;
alter table public.seasonal_event_prizes enable row level security;
revoke all on public.seasonal_event_previews from public, anon, authenticated;
revoke all on public.seasonal_trial_attempts from public, anon, authenticated;
revoke all on public.seasonal_trial_bests from public, anon, authenticated;
revoke all on public.seasonal_event_prizes from public, anon, authenticated;

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
  if p_event_id = 'halloween_witchlight' then
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

create or replace function public.list_my_seasonal_event_previews()
returns table (event_id text, expires_at timestamptz)
language sql
security definer
set search_path = ''
stable
as $$
  select p.event_id, p.expires_at
  from public.seasonal_event_previews p
  where p.user_id = auth.uid() and p.expires_at > now()
  order by p.expires_at;
$$;

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
  on conflict (user_id, event_id) do update
    set activated_at = excluded.activated_at, expires_at = excluded.expires_at;
  return query select target_event, new_expiry;
end
$$;

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
  if window_row.occurrence_key is not null
     and now() >= window_row.starts_at and now() < window_row.ends_at then
    occurrence := window_row.occurrence_key;
  elsif exists (
    select 1 from public.seasonal_event_previews p
    where p.user_id = current_user_id and p.event_id = p_event_id
      and p.expires_at > now()
  ) then
    is_preview := true;
    occurrence := 'preview:' || p_event_id || ':' || current_user_id::text;
  else
    raise exception 'seasonal_trial_unavailable';
  end if;

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
  if attempt.completion_token::text <> p_completion_token then
    raise exception 'seasonal_attempt_token_invalid';
  end if;
  if p_score < 0 or p_score > 20000 or p_total_actions < 0
     or p_total_actions > 200 or p_correct_actions < 0
     or p_correct_actions > p_total_actions or p_duration_ms < 30000
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

create or replace function public.get_seasonal_trial_rankings(
  p_event_id text,
  p_occurrence_key text,
  p_preview boolean default false,
  p_limit integer default 100
)
returns table (
  ranking_position bigint, user_id uuid, display_name text, title text,
  portrait_key text, frame_key text, badge_key text, score integer,
  accuracy_permille integer, duration_ms integer, is_current_user boolean
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
    'valentine_two_heartlights','pride_every_color'
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

create or replace function public.acknowledge_seasonal_event_prize(p_prize_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  update public.seasonal_event_prizes set claimed_at = coalesce(claimed_at, now())
  where id = p_prize_id and user_id = auth.uid();
  if not found then raise exception 'seasonal_prize_not_found'; end if;
end
$$;

create or replace function public.list_seasonal_chronicle()
returns table (
  event_id text, occurrence_key text, ranking_position integer,
  display_name text, score integer, podium_emote_id text,
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

revoke all on function public.seasonal_event_window(text, timestamptz)
  from public, anon, authenticated;
revoke all on function public.list_my_seasonal_event_previews()
  from public, anon;
revoke all on function public.redeem_seasonal_event_preview(text)
  from public, anon;
revoke all on function public.start_seasonal_trial_attempt(text, text)
  from public, anon;
revoke all on function public.complete_seasonal_trial_attempt(uuid, text, integer, integer, integer, integer)
  from public, anon;
revoke all on function public.get_seasonal_trial_rankings(text, text, boolean, integer)
  from public, anon;
revoke all on function public.finalize_my_seasonal_event_prizes()
  from public, anon;
revoke all on function public.acknowledge_seasonal_event_prize(uuid)
  from public, anon;
revoke all on function public.list_seasonal_chronicle()
  from public, anon;
grant execute on function public.list_my_seasonal_event_previews() to authenticated;
grant execute on function public.redeem_seasonal_event_preview(text) to authenticated;
grant execute on function public.start_seasonal_trial_attempt(text, text) to authenticated;
grant execute on function public.complete_seasonal_trial_attempt(uuid, text, integer, integer, integer, integer) to authenticated;
grant execute on function public.get_seasonal_trial_rankings(text, text, boolean, integer) to authenticated;
grant execute on function public.finalize_my_seasonal_event_prizes() to authenticated;
grant execute on function public.acknowledge_seasonal_event_prize(uuid) to authenticated;
grant execute on function public.list_seasonal_chronicle() to authenticated;

-- Valentine is a true two-Keeper Adventure. An invitation only reserves local
-- dragons; the occurrence is consumed atomically when the creator starts.
alter table public.social_notifications
  drop constraint if exists social_notifications_kind_check;
alter table public.social_notifications add constraint social_notifications_kind_check
  check (kind in (
    'friend_request', 'friend_accepted', 'friend_message',
    'trade_request', 'trade_return', 'trade_completed',
    'seasonal_pair_invite', 'seasonal_pair_accepted', 'seasonal_pair_ready'
  ));

create table if not exists public.seasonal_pair_adventures (
  id uuid primary key default gen_random_uuid(),
  event_id text not null default 'valentine_two_heartlights'
    check (event_id = 'valentine_two_heartlights'),
  occurrence_key text not null,
  creator_id uuid not null references public.profiles(user_id) on delete cascade,
  partner_id uuid not null references public.profiles(user_id) on delete cascade,
  creator_dragon_id text not null,
  partner_dragon_id text,
  creator_might integer not null check (creator_might between 0 and 400),
  creator_arcana integer not null check (creator_arcana between 0 and 400),
  creator_spirit integer not null check (creator_spirit between 0 and 400),
  partner_might integer check (partner_might between 0 and 400),
  partner_arcana integer check (partner_arcana between 0 and 400),
  partner_spirit integer check (partner_spirit between 0 and 400),
  status text not null default 'invited'
    check (status in ('invited','accepted','running','reward_ready','completed','declined')),
  simulated boolean not null default false,
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  started_at timestamptz,
  ends_at timestamptz,
  creator_reward_claimed_at timestamptz,
  partner_reward_claimed_at timestamptz,
  check (creator_id <> partner_id)
);
create index if not exists seasonal_pair_creator_idx
  on public.seasonal_pair_adventures(creator_id, created_at desc);
create index if not exists seasonal_pair_partner_idx
  on public.seasonal_pair_adventures(partner_id, created_at desc);

create table if not exists public.seasonal_pair_occurrences (
  event_id text not null,
  occurrence_key text not null,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  adventure_id uuid not null references public.seasonal_pair_adventures(id) on delete cascade,
  primary key (event_id, occurrence_key, user_id)
);
alter table public.seasonal_pair_adventures enable row level security;
alter table public.seasonal_pair_occurrences enable row level security;
revoke all on public.seasonal_pair_adventures from public, anon, authenticated;
revoke all on public.seasonal_pair_occurrences from public, anon, authenticated;

create or replace function public.list_my_seasonal_pair_adventures()
returns table (
  id uuid, event_id text, occurrence_key text, status text,
  creator jsonb, partner jsonb, is_creator boolean, my_dragon_id text,
  other_dragon_id text, created_at timestamptz, started_at timestamptz,
  ends_at timestamptz, my_reward_claimed boolean
)
language sql security definer set search_path = '' stable as $$
  select a.id, a.event_id, a.occurrence_key,
    case when a.status = 'reward_ready' then 'rewardReady' else a.status end,
    jsonb_build_object(
      'user_id', cp.user_id, 'keeper_code', cp.keeper_code,
      'display_name', cp.display_name, 'title', cp.title,
      'portrait_key', cp.portrait_key, 'frame_key', cp.frame_key,
      'badge_key', cp.badge_key, 'discovered_dragon_count', 0,
      'inventory_imported', true
    ),
    jsonb_build_object(
      'user_id', pp.user_id, 'keeper_code', pp.keeper_code,
      'display_name', pp.display_name, 'title', pp.title,
      'portrait_key', pp.portrait_key, 'frame_key', pp.frame_key,
      'badge_key', pp.badge_key, 'discovered_dragon_count', 0,
      'inventory_imported', true
    ),
    a.creator_id = auth.uid(),
    case when a.creator_id = auth.uid() then a.creator_dragon_id
      else coalesce(a.partner_dragon_id, '') end,
    case when a.creator_id = auth.uid() then a.partner_dragon_id
      else a.creator_dragon_id end,
    a.created_at, a.started_at, a.ends_at,
    case when a.creator_id = auth.uid() then a.creator_reward_claimed_at is not null
      else a.partner_reward_claimed_at is not null end
  from public.seasonal_pair_adventures a
  join public.profiles cp on cp.user_id = a.creator_id
  join public.profiles pp on pp.user_id = a.partner_id
  where auth.uid() in (a.creator_id, a.partner_id)
    and a.status <> 'declined'
    and (a.status <> 'completed' or a.created_at > now() - interval '30 days')
  order by a.created_at desc;
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
  if window_row.occurrence_key is not null and now() >= window_row.starts_at
    and now() < window_row.ends_at then
    occurrence := window_row.occurrence_key;
  elsif exists(select 1 from public.seasonal_event_previews p where
    p.user_id = current_user_id and p.event_id = 'valentine_two_heartlights'
    and p.expires_at > now()) then
    is_preview := true;
    occurrence := 'preview:valentine_two_heartlights:' || current_user_id::text;
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

create or replace function public.respond_seasonal_pair_adventure(
  p_adventure_id uuid, p_accept boolean, p_dragon_id text default null,
  p_might integer default 0, p_arcana integer default 0,
  p_spirit integer default 0
)
returns void language plpgsql security definer set search_path = '' as $$
declare a public.seasonal_pair_adventures%rowtype;
begin
  select * into a from public.seasonal_pair_adventures x
    where x.id = p_adventure_id and x.partner_id = auth.uid() for update;
  if a.id is null then raise exception 'seasonal_pair_not_found'; end if;
  if a.status <> 'invited' then raise exception 'seasonal_pair_not_pending'; end if;
  if not p_accept then
    update public.seasonal_pair_adventures set status = 'declined'
      where id = p_adventure_id;
    return;
  end if;
  if nullif(trim(p_dragon_id), '') is null or p_might not between 0 and 400
    or p_arcana not between 0 and 400 or p_spirit not between 0 and 400 then
    raise exception 'seasonal_pair_invalid_dragon';
  end if;
  update public.seasonal_pair_adventures set status = 'accepted',
    partner_dragon_id = trim(p_dragon_id), partner_might = p_might,
    partner_arcana = p_arcana, partner_spirit = p_spirit, accepted_at = now()
    where id = p_adventure_id;
  insert into public.social_notifications(user_id, kind, actor_id, entity_id)
    values(a.creator_id, 'seasonal_pair_accepted', auth.uid(), p_adventure_id);
end
$$;

create or replace function public.start_seasonal_pair_adventure(p_adventure_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare a public.seasonal_pair_adventures%rowtype; reduction_minutes integer;
  trip_minutes integer;
begin
  select * into a from public.seasonal_pair_adventures x
    where x.id = p_adventure_id and x.creator_id = auth.uid() for update;
  if a.id is null then raise exception 'seasonal_pair_not_found'; end if;
  if a.status <> 'accepted' then raise exception 'seasonal_pair_not_accepted'; end if;
  if not a.simulated then
    if not exists(select 1 from public.seasonal_event_window(a.event_id, now()) w
      where now() >= w.starts_at and now() < w.ends_at) then
      raise exception 'seasonal_adventure_unavailable';
    end if;
  end if;
  begin
    insert into public.seasonal_pair_occurrences(
      event_id, occurrence_key, user_id, adventure_id
    ) values
      (a.event_id, a.occurrence_key, a.creator_id, a.id),
      (a.event_id, a.occurrence_key, a.partner_id, a.id);
  exception when unique_violation then
    raise exception 'seasonal_pair_already_active';
  end;
  reduction_minutes := (a.creator_might + a.creator_arcana + a.creator_spirit +
    coalesce(a.partner_might,0) + coalesce(a.partner_arcana,0) +
    coalesce(a.partner_spirit,0)) * 15;
  trip_minutes := greatest(24 * 60, 96 * 60 - reduction_minutes);
  update public.seasonal_pair_adventures set status = 'running',
    started_at = now(), ends_at = now() + make_interval(mins => trip_minutes)
    where id = a.id;
end
$$;

create or replace function public.claim_seasonal_pair_adventure_reward(
  p_adventure_id uuid
)
returns table(adventure_id uuid, event_id text, dragon_id text, xp integer,
  might integer, arcana integer, spirit integer, special_chest_id text,
  simulated boolean)
language plpgsql security definer set search_path = '' as $$
declare a public.seasonal_pair_adventures%rowtype; already_claimed boolean;
begin
  select * into a from public.seasonal_pair_adventures x where x.id = p_adventure_id
    and auth.uid() in (x.creator_id, x.partner_id) for update;
  if a.id is null then raise exception 'seasonal_pair_not_found'; end if;
  if a.status = 'running' and a.ends_at <= now() then
    update public.seasonal_pair_adventures set status = 'reward_ready' where id = a.id;
    a.status := 'reward_ready';
    insert into public.social_notifications(user_id, kind, actor_id, entity_id)
      values(a.creator_id, 'seasonal_pair_ready', a.partner_id, a.id),
            (a.partner_id, 'seasonal_pair_ready', a.creator_id, a.id);
  end if;
  if a.status not in ('reward_ready','completed') then
    raise exception 'seasonal_pair_reward_not_ready';
  end if;
  already_claimed := case when auth.uid() = a.creator_id
    then a.creator_reward_claimed_at is not null
    else a.partner_reward_claimed_at is not null end;
  if already_claimed then return; end if;
  adventure_id := a.id; event_id := a.event_id;
  dragon_id := case when auth.uid() = a.creator_id then a.creator_dragon_id
    else a.partner_dragon_id end;
  xp := 650; might := 8; arcana := 8; spirit := 8;
  special_chest_id := 'twinheart_keepsake_chest_v1';
  simulated := a.simulated;
  return next;
end
$$;

create or replace function public.acknowledge_seasonal_pair_adventure_reward(
  p_adventure_id uuid
)
returns void language plpgsql security definer set search_path = '' as $$
declare a public.seasonal_pair_adventures%rowtype;
begin
  select * into a from public.seasonal_pair_adventures x where x.id = p_adventure_id
    and auth.uid() in (x.creator_id, x.partner_id) for update;
  if a.id is null then raise exception 'seasonal_pair_not_found'; end if;
  if auth.uid() = a.creator_id then
    update public.seasonal_pair_adventures set creator_reward_claimed_at =
      coalesce(creator_reward_claimed_at, now()) where id = a.id;
  else
    update public.seasonal_pair_adventures set partner_reward_claimed_at =
      coalesce(partner_reward_claimed_at, now()) where id = a.id;
  end if;
  update public.seasonal_pair_adventures set status = 'completed'
    where id = a.id and creator_reward_claimed_at is not null
      and partner_reward_claimed_at is not null;
end
$$;

revoke all on function public.list_my_seasonal_pair_adventures() from public, anon;
revoke all on function public.invite_seasonal_pair_adventure(text,text,integer,integer,integer) from public, anon;
revoke all on function public.respond_seasonal_pair_adventure(uuid,boolean,text,integer,integer,integer) from public, anon;
revoke all on function public.start_seasonal_pair_adventure(uuid) from public, anon;
revoke all on function public.claim_seasonal_pair_adventure_reward(uuid) from public, anon;
revoke all on function public.acknowledge_seasonal_pair_adventure_reward(uuid) from public, anon;
grant execute on function public.list_my_seasonal_pair_adventures() to authenticated;
grant execute on function public.invite_seasonal_pair_adventure(text,text,integer,integer,integer) to authenticated;
grant execute on function public.respond_seasonal_pair_adventure(uuid,boolean,text,integer,integer,integer) to authenticated;
grant execute on function public.start_seasonal_pair_adventure(uuid) to authenticated;
grant execute on function public.claim_seasonal_pair_adventure_reward(uuid) to authenticated;
grant execute on function public.acknowledge_seasonal_pair_adventure_reward(uuid) to authenticated;

create or replace function public.get_seasonal_community_progress(p_event_id text)
returns table(event_id text, occurrence_key text, completed_runs integer,
  ribbon_count integer)
language plpgsql security definer set search_path = '' stable as $$
declare window_row record; run_count integer; edition_year integer;
begin
  if auth.uid() is null then raise exception 'online_login_required'; end if;
  if p_event_id <> 'pride_every_color' then
    raise exception 'seasonal_community_invalid';
  end if;
  select * into window_row from public.seasonal_event_window(p_event_id, now());
  if window_row.occurrence_key is null then
    edition_year := extract(year from now() at time zone 'Europe/Amsterdam')::integer;
    occurrence_key := p_event_id || ':' || edition_year::text;
  else occurrence_key := window_row.occurrence_key; end if;
  select count(*)::integer into run_count
  from public.seasonal_trial_attempts a
  where a.event_id = p_event_id and a.occurrence_key = occurrence_key
    and a.completed_at is not null and not a.simulated;
  event_id := p_event_id;
  completed_runs := run_count;
  ribbon_count := case
    when run_count >= 500 then 7 when run_count >= 250 then 6
    when run_count >= 100 then 5 when run_count >= 50 then 4
    when run_count >= 25 then 3 when run_count >= 10 then 2
    when run_count >= 1 then 1 else 0 end;
  return next;
end
$$;
revoke all on function public.get_seasonal_community_progress(text) from public, anon;
grant execute on function public.get_seasonal_community_progress(text) to authenticated;
