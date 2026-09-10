begin;
set local statement_timeout='45s';
do $$
declare keeper uuid:=gen_random_uuid(); friend_id uuid:=gen_random_uuid(); cid uuid:=gen_random_uuid(); other_cid uuid:=gen_random_uuid();
  fixture_state jsonb; original jsonb; active jsonb; result jsonb; recorded public.seasonal_trial_attempts%rowtype;
  play_at timestamptz:='2027-07-21T10:00:00Z'; ending timestamptz; key_value text; revision_before bigint;
begin
  if (select enabled or shadow_social_enabled or shadow_projection_enabled or shadow_lifecycle_enabled
      from private.game_engine_runtime where singleton) then raise exception 'seasonal_contract_requires_dormant'; end if;
  if has_function_privilege('service_role','private.canonical_seasonal_state_changed()','execute') or
      has_function_privilege('authenticated','private.guard_canonical_seasonal_write()','execute') then
    raise exception 'seasonal_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text||'@seasonal-contract.invalid',now()),(friend_id,friend_id::text||'@seasonal-contract.invalid',now());
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keeper::text,true); perform public.ensure_my_online_account();
  perform set_config('request.jwt.claim.sub',friend_id::text,true); perform public.ensure_my_online_account();
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  fixture_state:='{"schemaVersion":54,"pet":{"id":"seasonal-dragon","name":"Seasonal Keeper","stage":"ascended",
    "lineageId":"copperflame","xp":3400,"coins":1000,"gems":10,"training":{"might":300,"arcana":300,"spirit":300},
    "evolutionPath":"might","favorite":true,"spectral":false,"sinister":false,"trialHighScores":{}},
    "eggStash":[],"sanctuaryDragons":[],"releasedDragons":[],"chestInventory":{},"specialChestInventory":{},
    "relicInventory":{},"untradeableRelicInventory":{},"discoveredForms":["copperflame:ascended:might"],
    "prismaticForms":[],"seasonalEventPreviewExpiresAt":{},"seasonalEventDismissedUntil":{}}'::jsonb;
  insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
    values(keeper,1,fixture_state,'synthetic-seasonal','0.5.30',54);
  perform set_config('request.jwt.claim.role','service_role',true);
  perform public.stage_canonical_game_copy(keeper,1,private.game_json_sha256(fixture_state));
  update private.canonical_game_states set is_prepared=true where owner_id=keeper;
  if exists(select 1 from public.seasonal_trial_attempts where user_id=keeper) then
    raise exception 'seasonal_contract_detached_isolation'; end if;
  update private.game_engine_runtime set shadow_projection_enabled=true where singleton;
  update private.canonical_game_states set is_prepared=true where owner_id=keeper;
  insert into public.conclaves(id,name,emblem_key,language,visibility,member_limit,created_by) values
    (cid,'Seasonal '||left(cid::text,17),'conclave_emblem_01','en','invite',4,friend_id),
    (other_cid,'Seasonal '||left(other_cid::text,17),'conclave_emblem_01','en','invite',4,friend_id);
  insert into public.conclave_members(conclave_id,user_id,role) values(cid,friend_id,'flightmaster'),(cid,keeper,'keeper');
  active:=jsonb_build_object('version',1,'type','trial','id',gen_random_uuid(),'gameId','sunwakeSurf',
    'offerId','official-offer','seed',17,'specialEventKey','sunwake_summer_sea:2027',
    'startedAt',play_at,'expiresAt',play_at+interval '6 hours');
  fixture_state:=fixture_state||jsonb_build_object('_activeGameAttempt',active);
  update private.canonical_game_states g set state=fixture_state,state_sha256=private.game_json_sha256(fixture_state),
    revision=g.revision+1,updated_at=play_at where owner_id=keeper;
  select * into recorded from public.seasonal_trial_attempts where user_id=keeper and canonical_offer_id='official-offer';
  if not found or not recorded.canonical_owned or recorded.simulated or recorded.conclave_id<>cid then
    raise exception 'seasonal_contract_start_binding'; end if;
  -- A caller holding the old public token still cannot manufacture a score.
  perform set_config('request.jwt.claim.role','authenticated',true);
  begin
    perform public.complete_seasonal_trial_attempt(recorded.id,recorded.completion_token::text,100::bigint,1::bigint,4::bigint,30000::bigint);
    raise exception 'seasonal_contract_legacy_completion_accepted';
  exception when others then if sqlerrm not in ('seasonal_attempt_expired','seasonal_score_rejected','economy_server_inventory_required') then raise; end if; end;
  begin
    update public.seasonal_trial_attempts set expires_at=now()+interval '6 hours' where id=recorded.id;
    raise exception 'seasonal_contract_legacy_write_accepted';
  exception when others then if sqlerrm<>'economy_server_inventory_required' then raise; end if; end;
  perform set_config('request.jwt.claim.role','service_role',true);
  -- Move Conclave, switch event, and rotate device ID while the same run lasts.
  update public.conclave_members set conclave_id=other_cid where user_id=keeper;
  active:=active||jsonb_build_object('id',gen_random_uuid(),'expiresAt',play_at+interval '7 hours');
  fixture_state:=fixture_state||jsonb_build_object('_activeGameAttempt',active,'seasonalEventPreviewExpiresAt',
    jsonb_build_object('valentine_two_heartlights',play_at+interval '2 days'));
  update private.canonical_game_states g set state=fixture_state,state_sha256=private.game_json_sha256(fixture_state),
    revision=g.revision+1,updated_at=play_at+interval '1 hour' where owner_id=keeper;
  if (select count(*) from public.seasonal_trial_attempts where user_id=keeper)<>1 or
      not exists(select 1 from public.seasonal_event_previews where user_id=keeper and event_id='valentine_two_heartlights') then
    raise exception 'seasonal_contract_resume_or_preview'; end if;
  result:=jsonb_build_object('attemptId',active->>'id','gameId','sunwakeSurf','type','trial','result',jsonb_build_object(
    'accepted',true,'cancelled',false,'kind','sunwakeSurf','specialEventKey','sunwake_summer_sea:2027',
    'score',3000000000::bigint,'correctActions',13636364::bigint,'totalActions',13636367::bigint,'durationMs',8000000000::bigint));
  fixture_state:=fixture_state||jsonb_build_object('_activeGameAttempt',null,'_lastGameResult',result);
  update private.canonical_game_states g set state=fixture_state,state_sha256=private.game_json_sha256(fixture_state),
    revision=g.revision+1,updated_at=play_at+interval '2 hours' where owner_id=keeper;
  if not exists(select 1 from public.seasonal_trial_bests where user_id=keeper and score=3000000000 and not preview) or
      not exists(select 1 from public.seasonal_conclave_projects where conclave_id=cid and completed_trials=1) or
      exists(select 1 from public.seasonal_conclave_projects where conclave_id=other_cid) then
    raise exception 'seasonal_contract_exact_completion'; end if;
  update private.canonical_game_states g set state=fixture_state,state_sha256=private.game_json_sha256(fixture_state),revision=g.revision+1 where owner_id=keeper;
  if (select completed_trials from public.seasonal_conclave_projects where conclave_id=cid)<>1 then
    raise exception 'seasonal_contract_replayed_contribution'; end if;
  -- A preview remains a preview; finishing after its original deadline is
  -- recorded, but cannot change rankings or grant permanent Conclave progress.
  ending:=play_at+interval '48 hours'; key_value:='sunwake_summer_sea:preview:'||floor(extract(epoch from ending)*1000)::bigint::text;
  active:=active||jsonb_build_object('id',gen_random_uuid(),'offerId','preview-offer','specialEventKey',key_value,
    'startedAt',play_at,'expiresAt',ending+interval '6 hours');
  fixture_state:=fixture_state||jsonb_build_object('_activeGameAttempt',active,'seasonalEventPreviewExpiresAt',jsonb_build_object('sunwake_summer_sea',ending));
  update private.canonical_game_states g set state=fixture_state,state_sha256=private.game_json_sha256(fixture_state),revision=g.revision+1,updated_at=play_at where owner_id=keeper;
  if exists(select 1 from public.seasonal_event_previews where user_id=keeper and event_id='valentine_two_heartlights') then
    raise exception 'seasonal_contract_previous_preview_retained'; end if;
  original:=fixture_state; select g.revision into revision_before from private.canonical_game_states g where owner_id=keeper;
  begin
    fixture_state:=jsonb_set(fixture_state,'{_activeGameAttempt,specialEventKey}','"sunwake_summer_sea:2028"');
    fixture_state:=jsonb_set(fixture_state,'{pet,coins}','999999');
    update private.canonical_game_states g set state=fixture_state,state_sha256=private.game_json_sha256(fixture_state),revision=g.revision+1 where owner_id=keeper;
    raise exception 'seasonal_contract_binding_change_accepted';
  exception when others then if sqlerrm<>'game_seasonal_binding_changed' then raise; end if; end;
  if (select g.revision from private.canonical_game_states g where owner_id=keeper)<>revision_before or
      (select coins from public.player_wallets where user_id=keeper)<>1000 then raise exception 'seasonal_contract_atomic_rollback'; end if;
  fixture_state:=original;
  result:=jsonb_set(jsonb_set(result,'{attemptId}',active->'id'),'{result,specialEventKey}',to_jsonb(key_value));
  fixture_state:=fixture_state||jsonb_build_object('_activeGameAttempt',null,'_lastGameResult',result,
    'seasonalEventPreviewExpiresAt','{}'::jsonb,'seasonalEventDismissedUntil',jsonb_build_object('sunwake_summer_sea',ending));
  update private.canonical_game_states g set state=fixture_state,state_sha256=private.game_json_sha256(fixture_state),revision=g.revision+1,updated_at=ending where owner_id=keeper;
  if not exists(select 1 from public.seasonal_trial_attempts where user_id=keeper and canonical_offer_id='preview-offer'
      and simulated and completed_at is not null and not ranking_eligible) or
      exists(select 1 from public.seasonal_trial_bests where user_id=keeper and preview) or
      exists(select 1 from public.seasonal_event_previews where user_id=keeper) or
      not exists(select 1 from public.seasonal_event_dismissals where user_id=keeper) then
    raise exception 'seasonal_contract_closed_preview'; end if;
  perform set_config('request.jwt.claim.role','authenticated',true);
  begin
    delete from public.seasonal_event_dismissals where user_id=keeper;
    raise exception 'seasonal_contract_legacy_event_write_accepted';
  exception when others then if sqlerrm<>'economy_server_inventory_required' then raise; end if; end;
  -- A player can still delete their own account and its verified attempts.
  delete from auth.users where id=keeper;
  perform set_config('request.jwt.claim.role','service_role',true);
  delete from public.conclaves where id in (cid,other_cid);
  delete from auth.users where id=friend_id;
end $$;
select true as canonical_seasonal_trial_contract_passed;
rollback;
