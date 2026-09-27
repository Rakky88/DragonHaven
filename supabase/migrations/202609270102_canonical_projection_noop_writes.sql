-- Avoid rewriting unchanged social read models for every game command.
-- Canonical hashes/revisions, wallet revision writes, service-role checks,
-- per-owner locks, unique favorites and historical dragon identities stay intact.
-- CREATE OR REPLACE retains the existing function privileges and triggers;
-- there is no backfill, account rewrite, runtime switch or gameplay change.

create or replace function private.project_canonical_social_state(
  p_owner_id uuid, p_state jsonb, p_revision bigint, p_hash text, p_at timestamptz
) returns void language plpgsql security definer set search_path = '' as $$
declare residents jsonb; dragon jsonb; v_favorite jsonb; normal_forms text[]; spectral_forms text[];
  current_projection private.canonical_social_projections%rowtype;
  cavern bigint; breaker bigint; weaver bigint;
begin
  perform private.assert_game_service();
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0));
  if not exists(select 1 from private.canonical_game_states g cross join private.game_engine_runtime r
      where g.owner_id=p_owner_id and g.is_prepared and r.singleton
        and (g.authority_mode='server' or r.shadow_projection_enabled)
        and g.revision=p_revision and g.state_sha256=p_hash and g.state=p_state) then
    raise exception 'game_social_projection_unavailable';
  end if;
  select * into current_projection from private.canonical_social_projections where owner_id=p_owner_id for update;
  if found then
    if current_projection.revision > p_revision or
        (current_projection.revision=p_revision and current_projection.state_sha256<>p_hash) then
      raise exception 'game_social_projection_conflict';
    end if;
    if current_projection.revision=p_revision then return; end if;
  end if;
  residents := jsonb_build_array(p_state->'pet') || coalesce(p_state->'sanctuaryDragons','[]'::jsonb);
  if exists(select 1 from jsonb_array_elements(residents) d
      where d->>'stage' is null or d->>'stage' not in ('egg','hatchling','wyrmling','ascended'))
      or (select count(*) from jsonb_array_elements(residents) d where d->>'stage'<>'egg') <>
         (select count(distinct d->>'id') from jsonb_array_elements(residents) d where d->>'stage'<>'egg')
      or (select count(*) from jsonb_array_elements(residents) d where d->>'stage'<>'egg' and (d->>'favorite')::boolean)>1 then
    raise exception 'game_social_projection_invalid';
  end if;
  -- Keep historical row identities for completed group adventures. Released
  -- dragons are explicitly unavailable; a later return reuses the same UUID.
  update public.player_dragons existing
    set canonical_owned=false,favorite=false,updated_at=p_at
    where existing.owner_id=p_owner_id and (existing.canonical_owned or existing.favorite)
      and not exists (select 1 from jsonb_array_elements(residents) d
        where d->>'stage'<>'egg' and d->>'id'=existing.legacy_client_id);
  -- Clear the previous favorite before an insert/upsert can claim the unique
  -- favorite slot. Keep an unchanged favorite and every other resident intact.
  update public.player_dragons existing set favorite=false,updated_at=p_at
    where existing.owner_id=p_owner_id and existing.favorite
      and not exists (select 1 from jsonb_array_elements(residents) d
        where d->>'stage'<>'egg' and d->>'id'=existing.legacy_client_id
          and (d->>'favorite')::boolean);
  for dragon in select d from jsonb_array_elements(residents) d where d->>'stage'<>'egg' loop
    insert into public.player_dragons as existing(owner_id,legacy_client_id,name,lineage_id,stage,xp,
        might,arcana,spirit,evolution_path,favorite,prismatic,sinister,canonical_owned)
      values(p_owner_id,dragon->>'id',coalesce(nullif(btrim(dragon->>'name'),''),'Unnamed dragon'),dragon->>'lineageId',dragon->>'stage',
        (dragon->>'xp')::integer,(dragon->'training'->>'might')::integer,
        (dragon->'training'->>'arcana')::integer,(dragon->'training'->>'spirit')::integer,
        coalesce(dragon->>'evolutionPath','spirit'),(dragon->>'favorite')::boolean,
        coalesce((dragon->>'spectral')::boolean,(dragon->>'prismatic')::boolean,false),
        (dragon->>'sinister')::boolean,true)
      on conflict(owner_id,legacy_client_id) do update set name=excluded.name,lineage_id=excluded.lineage_id,
        stage=excluded.stage,xp=excluded.xp,might=excluded.might,arcana=excluded.arcana,spirit=excluded.spirit,
        evolution_path=excluded.evolution_path,favorite=excluded.favorite,prismatic=excluded.prismatic,
        sinister=excluded.sinister,canonical_owned=true,updated_at=p_at
      where (existing.name,existing.lineage_id,existing.stage,existing.xp,
        existing.might,existing.arcana,existing.spirit,existing.evolution_path,
        existing.favorite,existing.prismatic,existing.sinister,existing.canonical_owned)
        is distinct from (excluded.name,excluded.lineage_id,excluded.stage,excluded.xp,
          excluded.might,excluded.arcana,excluded.spirit,excluded.evolution_path,
          excluded.favorite,excluded.prismatic,excluded.sinister,excluded.canonical_owned);
    if (dragon->>'favorite')::boolean then v_favorite := dragon; end if;
  end loop;
  insert into public.player_wallets(user_id,coins,gems,revision,updated_at)
    values(p_owner_id,(p_state->'pet'->>'coins')::bigint,(p_state->'pet'->>'gems')::bigint,p_revision,p_at)
    on conflict(user_id) do update set coins=excluded.coins,gems=excluded.gems,
      revision=excluded.revision,updated_at=excluded.updated_at;
  select coalesce(array_agg(distinct f order by f),'{}'::text[]) into normal_forms
    from jsonb_array_elements_text(p_state->'discoveredForms') f;
  select coalesce(array_agg(distinct f order by f),'{}'::text[]) into spectral_forms
    from jsonb_array_elements_text(p_state->'prismaticForms') f;
  select coalesce(max((d->'trialHighScores'->>'cavernFlight')::bigint),0),
      coalesce(max((d->'trialHighScores'->>'ruinBreaker')::bigint),0),
      coalesce(max((d->'trialHighScores'->>'runeweaver')::bigint),0)
    into cavern,breaker,weaver from jsonb_array_elements(residents) d where d->>'stage'<>'egg';
  insert into public.social_showcases as existing(user_id,discovered_dragon_count,discovered_forms,prismatic_forms,
      cavern_flight_best,ruin_breaker_best,runeweaver_best,favorite_dragon_id,favorite_dragon_name,
      favorite_dragon_lineage_id,favorite_dragon_stage,favorite_dragon_xp,favorite_dragon_might,
      favorite_dragon_arcana,favorite_dragon_spirit,favorite_dragon_evolution_path,
      favorite_dragon_prismatic,favorite_dragon_sinister,favorite_dragon_cavern_flight_best,
      favorite_dragon_ruin_breaker_best,favorite_dragon_runeweaver_best,updated_at)
    values(p_owner_id,cardinality(normal_forms),normal_forms,spectral_forms,cavern,breaker,weaver,
      v_favorite->>'id',case when v_favorite is null then null else coalesce(nullif(btrim(v_favorite->>'name'),''),'Unnamed dragon') end,v_favorite->>'lineageId',v_favorite->>'stage',(v_favorite->>'xp')::integer,
      (v_favorite->'training'->>'might')::integer,(v_favorite->'training'->>'arcana')::integer,
      (v_favorite->'training'->>'spirit')::integer,coalesce(v_favorite->>'evolutionPath','spirit'),
      coalesce((v_favorite->>'spectral')::boolean,(v_favorite->>'prismatic')::boolean),
      (v_favorite->>'sinister')::boolean,(v_favorite->'trialHighScores'->>'cavernFlight')::bigint,
      (v_favorite->'trialHighScores'->>'ruinBreaker')::bigint,(v_favorite->'trialHighScores'->>'runeweaver')::bigint,p_at)
    on conflict(user_id) do update set discovered_dragon_count=excluded.discovered_dragon_count,
      discovered_forms=excluded.discovered_forms,prismatic_forms=excluded.prismatic_forms,
      cavern_flight_best=excluded.cavern_flight_best,ruin_breaker_best=excluded.ruin_breaker_best,
      runeweaver_best=excluded.runeweaver_best,favorite_dragon_id=excluded.favorite_dragon_id,
      favorite_dragon_name=excluded.favorite_dragon_name,favorite_dragon_lineage_id=excluded.favorite_dragon_lineage_id,
      favorite_dragon_stage=excluded.favorite_dragon_stage,favorite_dragon_xp=excluded.favorite_dragon_xp,
      favorite_dragon_might=excluded.favorite_dragon_might,favorite_dragon_arcana=excluded.favorite_dragon_arcana,
      favorite_dragon_spirit=excluded.favorite_dragon_spirit,favorite_dragon_evolution_path=excluded.favorite_dragon_evolution_path,
      favorite_dragon_prismatic=excluded.favorite_dragon_prismatic,favorite_dragon_sinister=excluded.favorite_dragon_sinister,
      favorite_dragon_cavern_flight_best=excluded.favorite_dragon_cavern_flight_best,
      favorite_dragon_ruin_breaker_best=excluded.favorite_dragon_ruin_breaker_best,
      favorite_dragon_runeweaver_best=excluded.favorite_dragon_runeweaver_best,updated_at=p_at
    where (
        existing.discovered_dragon_count,
        existing.discovered_forms,
        existing.prismatic_forms,
        existing.cavern_flight_best,
        existing.ruin_breaker_best,
        existing.runeweaver_best,
        existing.favorite_dragon_id,
        existing.favorite_dragon_name,
        existing.favorite_dragon_lineage_id,
        existing.favorite_dragon_stage,
        existing.favorite_dragon_xp,
        existing.favorite_dragon_might,
        existing.favorite_dragon_arcana,
        existing.favorite_dragon_spirit,
        existing.favorite_dragon_evolution_path,
        existing.favorite_dragon_prismatic,
        existing.favorite_dragon_sinister,
        existing.favorite_dragon_cavern_flight_best,
        existing.favorite_dragon_ruin_breaker_best,
        existing.favorite_dragon_runeweaver_best
      ) is distinct from (
        excluded.discovered_dragon_count,
        excluded.discovered_forms,
        excluded.prismatic_forms,
        excluded.cavern_flight_best,
        excluded.ruin_breaker_best,
        excluded.runeweaver_best,
        excluded.favorite_dragon_id,
        excluded.favorite_dragon_name,
        excluded.favorite_dragon_lineage_id,
        excluded.favorite_dragon_stage,
        excluded.favorite_dragon_xp,
        excluded.favorite_dragon_might,
        excluded.favorite_dragon_arcana,
        excluded.favorite_dragon_spirit,
        excluded.favorite_dragon_evolution_path,
        excluded.favorite_dragon_prismatic,
        excluded.favorite_dragon_sinister,
        excluded.favorite_dragon_cavern_flight_best,
        excluded.favorite_dragon_ruin_breaker_best,
        excluded.favorite_dragon_runeweaver_best
      );
  insert into private.canonical_social_projections(owner_id,revision,state_sha256,updated_at)
    values(p_owner_id,p_revision,p_hash,p_at) on conflict(owner_id) do update set
      revision=excluded.revision,state_sha256=excluded.state_sha256,updated_at=excluded.updated_at;
end $$;

create or replace function private.project_canonical_profile_identity()
returns trigger language plpgsql security definer set search_path='' as $$
declare chosen_title text; chosen_portrait text; chosen_frame text; chosen_badge text;
  achievements integer; dragons integer;
begin
  if not new.is_prepared or new.authority_mode<>'server' then return new; end if;
  perform private.assert_game_service();
  chosen_title:=coalesce(new.state->>'selectedTitleId',new.state#>>'{ownedTitleIds,0}');
  chosen_portrait:=coalesce(new.state->>'selectedPortraitId',new.state#>>'{ownedPortraitIds,0}');
  chosen_frame:=new.state->>'selectedFrameId';
  chosen_badge:=new.state->>'selectedBadgeId';
  if chosen_title is null or chosen_portrait is null
    or not coalesce(new.state->'ownedTitleIds' ? chosen_title,false)
    or not coalesce(new.state->'ownedPortraitIds' ? chosen_portrait,false)
    or (chosen_frame is not null and not coalesce(new.state->'ownedFrameIds' ? chosen_frame,false))
    or (chosen_badge is not null and not coalesce(new.state->'ownedBadgeIds' ? chosen_badge,false))
  then raise exception 'game_social_projection_invalid'; end if;
  update public.profiles set
    display_name=coalesce(nullif(btrim(new.state->>'accountName'),''),display_name),
    title=chosen_title,portrait_key=chosen_portrait,frame_key=chosen_frame,badge_key=chosen_badge
    where user_id=new.owner_id and (display_name,title,portrait_key,frame_key,badge_key) is distinct from
      (coalesce(nullif(btrim(new.state->>'accountName'),''),display_name),chosen_title,chosen_portrait,chosen_frame,chosen_badge);
  achievements:=jsonb_array_length(coalesce(new.state->'achievements','[]'::jsonb));
  select count(*) into dragons from public.player_dragons
    where owner_id=new.owner_id and canonical_owned;
  update public.social_showcases set achievement_count=achievements,dragon_count=dragons,updated_at=new.updated_at
    where user_id=new.owner_id
      and (achievement_count,dragon_count) is distinct from (achievements,dragons);
  return new;
end $$;

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
      rune_orbit_best = orbit,
      updated_at = new.updated_at
  where user_id = new.owner_id
    and (spirit_alignment_best, ruin_guard_best, rune_orbit_best)
      is distinct from (alignment, guard, orbit);
  return new;
end
$$;

