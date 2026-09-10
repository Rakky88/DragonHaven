-- Server-owned social read models. No existing account is activated and no
-- detached shadow inventory is copied unless a staging rehearsal opts in.
alter table private.game_engine_runtime
  add column shadow_projection_enabled boolean not null default false;
alter table public.player_dragons
  add column canonical_owned boolean not null default true;
create table private.canonical_social_projections (
  owner_id uuid primary key references public.profiles(user_id) on delete cascade,
  revision bigint not null check (revision > 0),
  state_sha256 text not null check (state_sha256 ~ '^[0-9a-f]{64}$'),
  updated_at timestamptz not null
);
revoke all on private.canonical_social_projections from public,anon,authenticated,service_role;

-- Old clients may still read their social data. They must never overwrite a
-- server-owned read model, including via an older security-definer RPC.
create function private.guard_canonical_social_write()
returns trigger language plpgsql security definer set search_path = '' as $$
declare previous_owner uuid; next_owner uuid; keeper uuid;
begin
  if coalesce(auth.role(),'') = 'service_role' then
    if tg_op='DELETE' then return old; else return new; end if;
  end if;
  if tg_op <> 'INSERT' then
    previous_owner := coalesce(to_jsonb(old)->>'owner_id',to_jsonb(old)->>'user_id')::uuid;
  end if;
  if tg_op <> 'DELETE' then
    next_owner := coalesce(to_jsonb(new)->>'owner_id',to_jsonb(new)->>'user_id')::uuid;
  end if;
  for keeper in select distinct x from unnest(array[previous_owner,next_owner]) x
      where x is not null order by x loop
    perform pg_advisory_xact_lock(hashtextextended(keeper::text,0));
    if exists(select 1 from public.player_economy_authority
        where user_id=keeper and authority_mode='server') then
      raise exception 'economy_server_inventory_required';
    end if;
  end loop;
  if tg_op='DELETE' then return old; else return new; end if;
end $$;
revoke all on function private.guard_canonical_social_write() from public,anon,authenticated,service_role;
create trigger canonical_wallet_write before insert or update or delete on public.player_wallets
  for each row execute function private.guard_canonical_social_write();
create trigger canonical_dragon_write before insert or update or delete on public.player_dragons
  for each row execute function private.guard_canonical_social_write();
create trigger canonical_egg_write before insert or update or delete on public.player_eggs
  for each row execute function private.guard_canonical_social_write();
create trigger canonical_chest_write before insert or update or delete on public.player_chests
  for each row execute function private.guard_canonical_social_write();
create trigger canonical_relic_write before insert or update or delete on public.player_relics
  for each row execute function private.guard_canonical_social_write();
create trigger canonical_showcase_write before insert or update or delete on public.social_showcases
  for each row execute function private.guard_canonical_social_write();

create function private.project_canonical_social_state(
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
      values(p_owner_id,dragon->>'id',dragon->>'name',dragon->>'lineageId',dragon->>'stage',
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
      v_favorite->>'id',v_favorite->>'name',v_favorite->>'lineageId',v_favorite->>'stage',(v_favorite->>'xp')::integer,
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
revoke all on function private.project_canonical_social_state(uuid,jsonb,bigint,text,timestamptz)
  from public,anon,authenticated,service_role;

create function private.canonical_social_projection_changed()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.is_prepared and (new.authority_mode='server' or
      (select shadow_projection_enabled from private.game_engine_runtime where singleton)) then
    perform private.project_canonical_social_state(new.owner_id,new.state,new.revision,new.state_sha256,new.updated_at);
  end if;
  return new;
end $$;
revoke all on function private.canonical_social_projection_changed() from public,anon,authenticated,service_role;
create trigger canonical_social_projection_changed
  after insert or update of state,revision,is_prepared,authority_mode on private.canonical_game_states
  for each row execute function private.canonical_social_projection_changed();

create or replace function private.preserve_social_showcase_discoveries()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_normal text[] := '{}'::text[];
  previous_prismatic text[] := '{}'::text[];
  previous_count integer := 0;
  known_lineage_count integer := 0;
begin
  -- Canonical progression was reconciled during import. Its exact committed
  -- form collection replaces stale cosmetic publications; legacy keeps union.
  if exists(select 1 from private.canonical_game_states g cross join private.game_engine_runtime r
      where g.owner_id=new.user_id and g.is_prepared and r.singleton
        and (g.authority_mode='server' or r.shadow_projection_enabled)) then
    return new;
  end if;
  if tg_op = 'UPDATE' then
    previous_normal := coalesce(old.discovered_forms, '{}'::text[]);
    previous_prismatic := coalesce(old.prismatic_forms, '{}'::text[]);
    previous_count := coalesce(old.discovered_dragon_count, 0);
  end if;

  select coalesce(array_agg(form_key order by form_key), '{}'::text[])
  into new.discovered_forms
  from (
    select distinct form_key
    from unnest(
      coalesce(new.discovered_forms, '{}'::text[]) || previous_normal
    ) as forms(form_key)
  ) preserved;

  select coalesce(array_agg(form_key order by form_key), '{}'::text[])
  into new.prismatic_forms
  from (
    select distinct form_key
    from unnest(
      coalesce(new.prismatic_forms, '{}'::text[]) || previous_prismatic
    ) as forms(form_key)
  ) preserved;

  select count(distinct lineage_id)::integer
  into known_lineage_count
  from (
    select lineage_id
    from public.discovered_lineages
    where owner_id = new.user_id
    union
    select split_part(form_key, ':', 1)
    from unnest(new.discovered_forms || new.prismatic_forms) forms(form_key)
  ) known;

  new.discovered_dragon_count := greatest(
    coalesce(new.discovered_dragon_count, 0),
    previous_count,
    known_lineage_count
  );
  return new;
end;
$$;
