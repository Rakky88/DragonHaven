-- A newly hatched dragon legitimately has no chosen name yet. Only the social
-- display receives a fallback; canonical naming state and free first naming stay
-- unchanged. Existing pending hatch requests can retry with their original seed.
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
  update public.player_dragons set canonical_owned=false,favorite=false,updated_at=p_at
    where owner_id=p_owner_id and (canonical_owned or favorite);
  for dragon in select d from jsonb_array_elements(residents) d where d->>'stage'<>'egg' loop
    insert into public.player_dragons(owner_id,legacy_client_id,name,lineage_id,stage,xp,
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
        sinister=excluded.sinister,canonical_owned=true,updated_at=p_at;
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
  insert into public.social_showcases(user_id,discovered_dragon_count,discovered_forms,prismatic_forms,
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
      favorite_dragon_runeweaver_best=excluded.favorite_dragon_runeweaver_best,updated_at=p_at;
  insert into private.canonical_social_projections(owner_id,revision,state_sha256,updated_at)
    values(p_owner_id,p_revision,p_hash,p_at) on conflict(owner_id) do update set
      revision=excluded.revision,state_sha256=excluded.state_sha256,updated_at=excluded.updated_at;
end $$;
