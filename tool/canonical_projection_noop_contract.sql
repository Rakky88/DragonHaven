-- STAGING/LOCAL ONLY: rollback integration contract for actual projection triggers.
-- Its temporary counting triggers take DDL locks: do not run on production.
-- Uses a random synthetic keeper; never changes runtime switches or real accounts.
begin;
set local statement_timeout = '45s';
create temporary table projection_write_events(kind text, row_id text, operation text);
create function pg_temp.capture_projection_write() returns trigger language plpgsql as $$
begin
  insert into pg_temp.projection_write_events values(
    tg_table_name,coalesce(to_jsonb(new)->>'id',to_jsonb(new)->>'user_id'),tg_op);
  return new;
end $$;
create trigger projection_contract_count_dragons after insert or update on public.player_dragons
  for each row execute function pg_temp.capture_projection_write();
create trigger projection_contract_count_showcase after insert or update on public.social_showcases
  for each row execute function pg_temp.capture_projection_write();
create trigger projection_contract_count_wallet after insert or update on public.player_wallets
  for each row execute function pg_temp.capture_projection_write();
create function pg_temp.advance_projection(p_owner uuid,p_state jsonb) returns void language sql as $$
  update private.canonical_game_states set state=p_state,
    state_sha256=private.game_json_sha256(p_state),revision=revision+1,updated_at=clock_timestamp()
    where owner_id=p_owner
$$;
create function pg_temp.assert_projection_writes(p_dragons integer,p_showcases integer,p_wallets integer)
returns void language plpgsql as $$
declare actual_dragons integer; actual_showcases integer; actual_wallets integer;
begin
  select count(*) filter(where kind='player_dragons'),count(*) filter(where kind='social_showcases'),
    count(*) filter(where kind='player_wallets')
    into actual_dragons,actual_showcases,actual_wallets from pg_temp.projection_write_events;
  if (actual_dragons,actual_showcases,actual_wallets) is distinct from (p_dragons,p_showcases,p_wallets) then
    raise exception 'projection_noop_write_counts expected=(%,%,%), actual=(%,%,%)',
      p_dragons,p_showcases,p_wallets,actual_dragons,actual_showcases,actual_wallets;
  end if;
  truncate pg_temp.projection_write_events;
end $$;
do $contract$
declare keeper uuid:=gen_random_uuid(); import_id uuid; roster jsonb; state jsonb; restored jsonb;
  current_revision bigint; current_hash text; row_id uuid; favorite_id uuid; before_projection jsonb;
begin
  perform set_config('request.jwt.claim.role','service_role',true);
  insert into auth.users(id,email,email_confirmed_at)
    values(keeper,keeper::text||'@projection-noop-contract.invalid',now());
  insert into public.profiles(user_id,keeper_code,display_name)
    values(keeper,'DH-'||upper(substr(replace(keeper::text,'-',''),1,8)),'Projection contract')
    on conflict(user_id) do nothing;
  select jsonb_agg(jsonb_build_object('id','resident-'||n,'name','Resident '||n,
    'stage','hatchling','lineageId','copperflame','xp',25,
    'training',jsonb_build_object('might',1,'arcana',2,'spirit',3),
    'evolutionPath','spirit','favorite',n=27,'spectral',false,'sinister',false,
    'coins',250,'gems',30,'trialHighScores',jsonb_build_object(
      'cavernFlight',10,'ruinBreaker',20,'runeweaver',30,
      'spiritAlignment',40,'ruinGuard',50,'runeOrbit',60)) order by n)
    into roster from generate_series(1,27) n;
  state:=jsonb_build_object('schemaVersion',54,'pet',roster->0,
    'sanctuaryDragons',roster-0,'eggStash','[]'::jsonb,'releasedDragons','[]'::jsonb,
    'chestInventory','{}'::jsonb,'specialChestInventory','{}'::jsonb,
    'relicInventory','{}'::jsonb,'untradeableRelicInventory','{}'::jsonb,
    'discoveredForms',jsonb_build_array('copperflame:hatchling'),'prismaticForms','[]'::jsonb,
    'ownedTitleIds',jsonb_build_array('title_001'),'ownedPortraitIds',jsonb_build_array('portrait_001'),
    'achievements','[]'::jsonb);
  insert into private.canonical_game_imports(owner_id,source_revision,source_sha256,source_state)
    values(keeper,1,private.game_json_sha256(state),state) returning canonical_game_imports.import_id into import_id;
  insert into private.canonical_game_states(owner_id,authority_mode,revision,state,state_sha256,
    source_import_id,is_prepared) values(keeper,'server',1,state,private.game_json_sha256(state),import_id,true);
  select id into row_id from public.player_dragons where owner_id=keeper and legacy_client_id='resident-1';
  select id into favorite_id from public.player_dragons where owner_id=keeper and legacy_client_id='resident-27';
  if row_id is null or favorite_id is null then raise exception 'projection_noop_initial_dragons'; end if;
  truncate pg_temp.projection_write_events;

  -- An unrelated egg-tag/refresh revision rewrites neither 27 dragons nor any
  -- of the three showcase projections. Wallet and private revision still advance.
  state:=jsonb_set(state,'{eggTaggedIds}',jsonb_build_array('example-egg'));
  perform pg_temp.advance_projection(keeper,state);
  perform pg_temp.assert_projection_writes(0,0,1);
  if not exists(select 1 from public.player_wallets where user_id=keeper and revision=2)
    or not exists(select 1 from private.canonical_social_projections where owner_id=keeper and revision=2) then
    raise exception 'projection_noop_revision_stale'; end if;

  -- Only the changed dragon is written; unchanged favorite/showcase stay intact.
  state:=jsonb_set(jsonb_set(state,'{pet,name}','"Renamed"'),'{pet,xp}','26');
  perform pg_temp.advance_projection(keeper,state);
  perform pg_temp.assert_projection_writes(1,0,1);
  if not exists(select 1 from public.player_dragons where id=row_id and name='Renamed' and xp=26) then
    raise exception 'projection_noop_name_xp'; end if;

  -- Move the favorite from the last resident to the first (the new favorite is
  -- processed first). The unique slot must be released BEFORE the loop/upsert.
  state:=jsonb_set(jsonb_set(state,'{pet,favorite}','true'),'{sanctuaryDragons,25,favorite}','false');
  perform pg_temp.advance_projection(keeper,state);
  perform pg_temp.assert_projection_writes(2,1,1);
  if (select count(*) from public.player_dragons where owner_id=keeper and favorite)<>1
    or not exists(select 1 from public.player_dragons where id=row_id and favorite and canonical_owned)
    or not exists(select 1 from public.player_dragons where id=favorite_id and not favorite and canonical_owned) then
    raise exception 'projection_noop_favorite_slot'; end if;
  perform pg_temp.advance_projection(keeper,state);
  perform pg_temp.assert_projection_writes(0,0,1);

  -- Every basic/ascended best writer and the counts writer still fires exactly
  -- when its fields change. Trial scores are not columns in player_dragons.
  state:=jsonb_set(state,'{sanctuaryDragons,0,trialHighScores,cavernFlight}','111');
  state:=jsonb_set(state,'{sanctuaryDragons,0,trialHighScores,ruinBreaker}','112');
  state:=jsonb_set(state,'{sanctuaryDragons,0,trialHighScores,runeweaver}','113');
  state:=jsonb_set(state,'{sanctuaryDragons,0,trialHighScores,spiritAlignment}','222');
  state:=jsonb_set(state,'{sanctuaryDragons,0,trialHighScores,ruinGuard}','223');
  state:=jsonb_set(state,'{sanctuaryDragons,0,trialHighScores,runeOrbit}','224');
  state:=jsonb_set(state,'{achievements}',jsonb_build_array('first-test'));
  perform pg_temp.advance_projection(keeper,state);
  perform pg_temp.assert_projection_writes(0,3,1);
  if not exists(select 1 from public.social_showcases where user_id=keeper and cavern_flight_best=111
    and ruin_breaker_best=112 and runeweaver_best=113 and spirit_alignment_best=222
    and ruin_guard_best=223 and rune_orbit_best=224 and achievement_count=1 and dragon_count=27) then
    raise exception 'projection_noop_scores_counts'; end if;
  perform pg_temp.advance_projection(keeper,state);
  perform pg_temp.assert_projection_writes(0,0,1);

  -- Removing a resident preserves its historical UUID; restoring it reuses it.
  -- Remove the former favorite rather than the high-scoring resident.
  restored:=state;
  state:=jsonb_set(state,'{sanctuaryDragons}',(state->'sanctuaryDragons')-25);
  perform pg_temp.advance_projection(keeper,state);
  perform pg_temp.assert_projection_writes(1,1,1);
  if not exists(select 1 from public.player_dragons where id=favorite_id and not canonical_owned and not favorite) then
    raise exception 'projection_noop_release_history'; end if;
  state:=restored;
  perform pg_temp.advance_projection(keeper,state);
  perform pg_temp.assert_projection_writes(1,1,1);
  if not exists(select 1 from public.player_dragons where id=favorite_id and canonical_owned and not favorite) then
    raise exception 'projection_noop_restore_identity'; end if;

  -- Spectral aliases and name fallback preserve their established projection.
  state:=jsonb_set(jsonb_set(state,'{pet,name}','"  "'),'{pet,spectral}','true');
  perform pg_temp.advance_projection(keeper,state);
  perform pg_temp.assert_projection_writes(1,1,1);
  if not exists(select 1 from public.player_dragons where id=row_id and name='Unnamed dragon' and prismatic) then
    raise exception 'projection_noop_unnamed_spectral'; end if;
  perform pg_temp.advance_projection(keeper,state);
  perform pg_temp.assert_projection_writes(0,0,1);

  -- Null favorite fields compare null-safely and do not rewrite on each tick.
  restored:=state;
  state:=jsonb_set(state,'{pet,favorite}','false');
  perform pg_temp.advance_projection(keeper,state);
  perform pg_temp.assert_projection_writes(1,1,1);
  if exists(select 1 from public.player_dragons where owner_id=keeper and favorite)
    or not exists(select 1 from public.social_showcases where user_id=keeper and favorite_dragon_id is null) then
    raise exception 'projection_noop_clear_favorite'; end if;
  perform pg_temp.advance_projection(keeper,state);
  perform pg_temp.assert_projection_writes(0,0,1);
  state:=restored;
  perform pg_temp.advance_projection(keeper,state);
  perform pg_temp.assert_projection_writes(1,1,1);

  -- Every changed read-model timestamp still denotes its actual latest change.
  state:=jsonb_set(state,'{sanctuaryDragons,0,trialHighScores,runeOrbit}','225');
  perform pg_temp.advance_projection(keeper,state);
  perform pg_temp.assert_projection_writes(0,1,1);
  if (select updated_at from public.social_showcases where user_id=keeper) is distinct from
    (select updated_at from private.canonical_game_states where owner_id=keeper) then
    raise exception 'projection_noop_trial_timestamp'; end if;
  state:=jsonb_set(state,'{achievements}',jsonb_build_array('first-test','second-test'));
  perform pg_temp.advance_projection(keeper,state);
  perform pg_temp.assert_projection_writes(0,1,1);
  if (select updated_at from public.social_showcases where user_id=keeper) is distinct from
    (select updated_at from private.canonical_game_states where owner_id=keeper) then
    raise exception 'projection_noop_count_timestamp'; end if;

  select revision,state_sha256 into current_revision,current_hash from private.canonical_game_states where owner_id=keeper;
  select to_jsonb(p) into before_projection from private.canonical_social_projections p where owner_id=keeper;
  perform private.project_canonical_social_state(keeper,state,current_revision,current_hash,now()+interval '1 day');
  perform pg_temp.assert_projection_writes(0,0,0);
  if (select to_jsonb(p) from private.canonical_social_projections p where owner_id=keeper)<>before_projection then
    raise exception 'projection_noop_replay_mutated'; end if;
  begin
    perform private.project_canonical_social_state(keeper,state,current_revision+1,current_hash,now());
    raise exception 'projection_noop_wrong_revision_accepted';
  exception when others then if sqlerrm<>'game_social_projection_unavailable' then raise; end if; end;
  begin
    perform private.project_canonical_social_state(keeper,state,current_revision,repeat('f',64),now());
    raise exception 'projection_noop_wrong_hash_accepted';
  exception when others then if sqlerrm<>'game_social_projection_unavailable' then raise; end if; end;
  begin
    perform private.project_canonical_social_state(keeper,jsonb_set(state,'{pet,xp}','999'),current_revision,current_hash,now());
    raise exception 'projection_noop_wrong_state_accepted';
  exception when others then if sqlerrm<>'game_social_projection_unavailable' then raise; end if; end;
  begin
    perform pg_temp.advance_projection(keeper,jsonb_set(state,'{sanctuaryDragons,0,favorite}','true'));
    raise exception 'projection_noop_duplicate_favorite_accepted';
  exception when others then if sqlerrm<>'game_social_projection_invalid' then raise; end if; end;
  if (select revision from private.canonical_game_states where owner_id=keeper)<>current_revision then
    raise exception 'projection_noop_partial_commit'; end if;
  perform set_config('request.jwt.claim.role','authenticated',true);
  begin
    perform private.project_canonical_social_state(keeper,state,current_revision,current_hash,now());
    raise exception 'projection_noop_nonservice_accepted';
  exception when others then if sqlerrm<>'game_service_required' then raise; end if; end;
  perform pg_temp.assert_projection_writes(0,0,0);
end
$contract$;
rollback;
select true as canonical_projection_noop_contract_passed;
