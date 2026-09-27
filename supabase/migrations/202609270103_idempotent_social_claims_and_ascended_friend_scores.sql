-- A delayed second tap may arrive after a social reward was committed. Treat
-- the canonical applied-id ledger as the idempotency authority instead of
-- turning that harmless replay into an inventory error.
create or replace function private.canonical_social_claim_context(
  p_owner_id uuid, p_action text, p_payload jsonb, p_at timestamptz
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare source_id uuid; facts jsonb; allowed boolean; already_applied boolean := false;
  lobby public.group_adventure_lobbies%rowtype;
  participant public.group_adventure_participants%rowtype;
  pair public.seasonal_pair_adventures%rowtype;
  prize public.seasonal_event_prizes%rowtype;
  dragon_key text; headcount integer; claimed timestamptz;
begin
  perform private.assert_game_service();
  select g.is_prepared and (g.authority_mode='server' or r.shadow_social_enabled)
    into allowed from private.canonical_game_states g
    cross join private.game_engine_runtime r
    where g.owner_id=p_owner_id and r.singleton;
  if not coalesce(allowed,false) or p_at is null then
    raise exception 'game_social_claim_unavailable';
  end if;
  source_id := (p_payload ->> case p_action
    when 'claim_group_reward' then 'lobbyId'
    when 'claim_pair_reward' then 'adventureId'
    when 'claim_podium_prize' then 'prizeId' else '' end)::uuid;
  if source_id is null then raise exception 'game_social_claim_unavailable'; end if;

  if p_action='claim_group_reward' then
    select * into lobby from public.group_adventure_lobbies
      where id=source_id for update;
    if not found or lobby.status not in ('running','completed')
        or lobby.ends_at is null or lobby.ends_at > p_at then
      raise exception 'game_social_claim_unavailable';
    end if;
    select * into participant from public.group_adventure_participants
      where lobby_id=source_id and user_id=p_owner_id for update;
    if not found then raise exception 'game_social_claim_unavailable'; end if;
    select coalesce(g.state->'appliedOnlineGroupRewardIds','[]'::jsonb) ? source_id::text
      into already_applied
      from private.canonical_game_states g
      where g.owner_id=p_owner_id and g.is_prepared;
    if participant.reward_acknowledged_at is not null
        and not coalesce(already_applied,false) then
      raise exception 'game_social_claim_unavailable';
    end if;
    select legacy_client_id into dragon_key from public.player_dragons
      where id=participant.dragon_id and owner_id=p_owner_id;
    if dragon_key is null then raise exception 'game_social_claim_unavailable'; end if;
    select count(*)::integer into headcount from public.group_adventure_participants
      where lobby_id=source_id;
    facts := jsonb_build_object('adventureId',lobby.adventure_id,'dragonId',dragon_key,
      'xp',lobby.xp,'focus',lobby.focus,'statPoints',lobby.stat_points,
      'chestTier',lobby.chest_tier,'participantCount',headcount);
  elsif p_action='claim_pair_reward' then
    select * into pair from public.seasonal_pair_adventures
      where id=source_id and p_owner_id in (creator_id,partner_id) for update;
    if not found or pair.status not in ('running','reward_ready','completed')
        or pair.ends_at is null or pair.ends_at > p_at then
      raise exception 'game_social_claim_unavailable';
    end if;
    claimed := case when p_owner_id=pair.creator_id then pair.creator_reward_claimed_at
      else pair.partner_reward_claimed_at end;
    if claimed is not null then raise exception 'game_social_claim_unavailable'; end if;
    dragon_key := case when p_owner_id=pair.creator_id then pair.creator_dragon_id
      else pair.partner_dragon_id end;
    facts := jsonb_build_object('eventId',pair.event_id,'dragonId',dragon_key,
      'xp',650,'might',8,'arcana',8,'spirit',8,
      'specialChestId','twinheart_keepsake_chest_v1','simulated',pair.simulated);
  elsif p_action='claim_podium_prize' then
    select * into prize from public.seasonal_event_prizes
      where id=source_id and user_id=p_owner_id for update;
    if not found or prize.claimed_at is not null or prize.finalized_at > p_at then
      raise exception 'game_social_claim_unavailable';
    end if;
    facts := jsonb_build_object('eventId',prize.event_id,'position',prize.ranking_position);
  else
    raise exception 'game_social_claim_unavailable';
  end if;
  return jsonb_build_object('version',1,'ownerId',p_owner_id,'action',p_action,
    'sourceId',source_id,'facts',facts,
    'fingerprint',private.game_json_sha256(jsonb_build_object(
      'ownerId',p_owner_id,'action',p_action,'sourceId',source_id,'facts',facts)));
exception when invalid_text_representation then
  raise exception 'game_social_claim_unavailable';
end $$;

revoke all on function private.canonical_social_claim_context(uuid,text,jsonb,timestamptz)
  from public, anon, authenticated, service_role;

-- Social showcase projections already contain all six standard account bests.
-- Return the Ascended trio with friend profiles as well.
alter function public.get_my_profile() rename to get_my_profile_v102;
revoke all on function public.get_my_profile_v102()
  from public,anon,authenticated,service_role;

create function public.get_my_profile()
returns table (
  user_id uuid, keeper_code text, display_name text, title text,
  portrait_key text, frame_key text, badge_key text,
  discovered_dragon_count bigint,
  achievement_count integer, dragon_count integer,
  inventory_imported boolean, discovered_forms text[],
  prismatic_forms text[], cavern_flight_best bigint,
  ruin_breaker_best bigint, runeweaver_best bigint,
  spirit_alignment_best bigint, ruin_guard_best bigint, rune_orbit_best bigint,
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
language sql security definer set search_path = '' stable as $$
  select
    p.user_id, p.keeper_code, p.display_name, p.title, p.portrait_key,
    p.frame_key, p.badge_key,
    coalesce(s.discovered_dragon_count, 0)::bigint,
    coalesce(s.achievement_count, 0), coalesce(s.dragon_count, 0),
    p.inventory_imported_at is not null,
    coalesce(s.discovered_forms, '{}'::text[]),
    coalesce(s.prismatic_forms, '{}'::text[]),
    coalesce(s.cavern_flight_best, 0), coalesce(s.ruin_breaker_best, 0),
    coalesce(s.runeweaver_best, 0), coalesce(s.spirit_alignment_best, 0),
    coalesce(s.ruin_guard_best, 0), coalesce(s.rune_orbit_best, 0),
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

alter function public.list_my_friends() rename to list_my_friends_v102;
revoke all on function public.list_my_friends_v102()
  from public,anon,authenticated,service_role;

create function public.list_my_friends()
returns table (
  user_id uuid, keeper_code text, display_name text, title text,
  portrait_key text, frame_key text, badge_key text,
  discovered_dragon_count bigint,
  achievement_count integer, dragon_count integer,
  inventory_imported boolean, discovered_forms text[],
  prismatic_forms text[], cavern_flight_best bigint,
  ruin_breaker_best bigint, runeweaver_best bigint,
  spirit_alignment_best bigint, ruin_guard_best bigint, rune_orbit_best bigint,
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
language sql security definer set search_path = '' stable as $$
  select
    p.user_id, p.keeper_code, p.display_name, p.title, p.portrait_key,
    p.frame_key, p.badge_key,
    coalesce(s.discovered_dragon_count, 0)::bigint,
    coalesce(s.achievement_count, 0), coalesce(s.dragon_count, 0),
    p.inventory_imported_at is not null,
    coalesce(s.discovered_forms, '{}'::text[]),
    coalesce(s.prismatic_forms, '{}'::text[]),
    coalesce(s.cavern_flight_best, 0), coalesce(s.ruin_breaker_best, 0),
    coalesce(s.runeweaver_best, 0), coalesce(s.spirit_alignment_best, 0),
    coalesce(s.ruin_guard_best, 0), coalesce(s.rune_orbit_best, 0),
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
