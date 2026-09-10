begin;
set local statement_timeout = '45s';
do $$
declare keeper uuid:=gen_random_uuid(); outsider uuid:=gen_random_uuid();
  source_state jsonb; next_state jsonb; before_state jsonb; original_wallet jsonb;
  rules text:=repeat('a6',32); command_id uuid; leased jsonb; receipt jsonb;
  first_dragon uuid; second_dragon uuid; previous_projection jsonb;
begin
  if (select enabled or shadow_social_enabled or shadow_projection_enabled
      from private.game_engine_runtime where singleton) then
    raise exception 'social_projection_contract_requires_dormant'; end if;
  if has_function_privilege('service_role','private.project_canonical_social_state(uuid,jsonb,bigint,text,timestamptz)','execute')
      or has_function_privilege('authenticated','private.guard_canonical_social_write()','execute')
      or has_table_privilege('authenticated','private.canonical_social_projections','select') then
    raise exception 'social_projection_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text||'@social-projection-contract.invalid',now()),
    (outsider,outsider::text||'@social-projection-contract.invalid',now());
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  perform public.ensure_my_online_account();
  select to_jsonb(w) into original_wallet from public.player_wallets w where user_id=keeper;
  perform set_config('request.jwt.claim.sub',outsider::text,true);
  perform public.ensure_my_online_account();
  source_state := '{"schemaVersion":54,
    "pet":{"id":"mirror-one","name":"Mirror One","stage":"ascended","lineageId":"copperflame",
      "xp":1000,"coins":12345,"gems":987,"training":{"might":310,"arcana":32,"spirit":43},
      "evolutionPath":"might","favorite":true,"spectral":true,"sinister":false,
      "trialHighScores":{"cavernFlight":234,"ruinBreaker":345,"runeweaver":456}},
    "sanctuaryDragons":[{"id":"mirror-two","name":"Mirror Two","stage":"hatchling","lineageId":"copperflame",
      "xp":25,"coins":999999,"gems":999999,"training":{"might":1,"arcana":2,"spirit":3},
      "evolutionPath":null,"favorite":false,"spectral":false,"sinister":false,
      "trialHighScores":{"cavernFlight":567,"ruinBreaker":45,"runeweaver":67}}],
    "eggStash":[],"releasedDragons":[],"chestInventory":{},"specialChestInventory":{},
    "relicInventory":{},"untradeableRelicInventory":{},
    "discoveredForms":["copperflame:hatchling","copperflame:ascended:might"],
    "prismaticForms":["copperflame:ascended:might"]}'::jsonb;
  insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
    values(keeper,1,source_state,'synthetic-social-projection','0.5.30',54);
  perform set_config('request.jwt.claim.role','service_role',true);
  perform public.stage_canonical_game_copy(keeper,1,private.game_json_sha256(source_state));
  update private.canonical_game_states set is_prepared=true where owner_id=keeper;
  if exists(select 1 from private.canonical_social_projections where owner_id=keeper)
      or (select to_jsonb(w) from public.player_wallets w where user_id=keeper)<>original_wallet then
    raise exception 'social_projection_contract_shadow_isolation'; end if;
  -- A stale cosmetic publication is not allowed to invent canonical discovery.
  insert into public.social_showcases(user_id,discovered_dragon_count,discovered_forms)
    values(keeper,3,array['copperflame:ascended:arcana']);
  update private.game_engine_runtime set enabled=true,shadow_projection_enabled=true,ruleset_sha256=rules where singleton;
  update private.canonical_game_states set is_prepared=true where owner_id=keeper;
  select id into first_dragon from public.player_dragons where owner_id=keeper and legacy_client_id='mirror-one';
  select id into second_dragon from public.player_dragons where owner_id=keeper and legacy_client_id='mirror-two';
  if first_dragon is null or second_dragon is null
      or not exists(select 1 from public.player_wallets where user_id=keeper and coins=12345 and gems=987 and revision=1)
      or not exists(select 1 from public.player_dragons where id=first_dragon and might=310 and xp=1000 and favorite and prismatic and canonical_owned)
      or not exists(select 1 from public.social_showcases where user_id=keeper and favorite_dragon_id='mirror-one'
        and favorite_dragon_might=310 and cavern_flight_best=567 and discovered_dragon_count=2
        and discovered_forms=array['copperflame:ascended:might','copperflame:hatchling']) then
    raise exception 'social_projection_contract_exact_initial_state'; end if;
  -- Frozen source and revision must agree, even on a service-only retry.
  begin
    perform private.project_canonical_social_state(keeper,source_state,2,private.game_json_sha256(source_state),now());
    raise exception 'social_projection_contract_wrong_revision_accepted';
  exception when others then if sqlerrm<>'game_social_projection_unavailable' then raise; end if; end;
  select to_jsonb(p) into previous_projection from private.canonical_social_projections p where owner_id=keeper;
  perform private.project_canonical_social_state(keeper,source_state,1,private.game_json_sha256(source_state),now()+interval '1 hour');
  if (select to_jsonb(p) from private.canonical_social_projections p where owner_id=keeper)<>previous_projection then
    raise exception 'social_projection_contract_retry_changed_snapshot'; end if;
  -- A committed command changes state, wallet, dragon XP and showcase together.
  command_id:=gen_random_uuid();
  leased:=public.begin_revisioned_game_command(keeper,command_id,'refresh','{}',10080,rules,1);
  next_state:=jsonb_set(jsonb_set(source_state,'{pet,coins}','12000'),'{pet,xp}','1234');
  next_state:=jsonb_set(next_state,'{pet,trialHighScores,cavernFlight}','789');
  receipt:=public.commit_canonical_game_command(keeper,command_id,(leased->>'lease_token')::uuid,next_state,'true');
  if receipt->>'server_revision'<>'2'
      or not exists(select 1 from public.player_wallets where user_id=keeper and coins=12000 and revision=2)
      or not exists(select 1 from public.player_dragons where id=first_dragon and xp=1234)
      or not exists(select 1 from public.social_showcases where user_id=keeper and cavern_flight_best=789) then
    raise exception 'social_projection_contract_atomic_commit'; end if;
  if public.commit_canonical_game_command(keeper,command_id,(leased->>'lease_token')::uuid,next_state,'true')<>receipt then
    raise exception 'social_projection_contract_commit_replay'; end if;
  -- A projection failure rolls back the entire command, including its receipt.
  command_id:=gen_random_uuid();
  leased:=public.begin_revisioned_game_command(keeper,command_id,'refresh','{}',10080,rules,2);
  before_state:=next_state;
  begin
    perform public.commit_canonical_game_command(keeper,command_id,(leased->>'lease_token')::uuid,
      jsonb_set(next_state,'{pet,training,might}','999'),'true');
    raise exception 'social_projection_contract_invalid_projection_committed';
  exception when check_violation then null; end;
  if (select state from private.canonical_game_states where owner_id=keeper)<>before_state
      or not exists(select 1 from public.player_wallets where user_id=keeper and coins=12000 and revision=2)
      or not exists(select 1 from private.canonical_game_intents where owner_id=keeper and request_id=command_id and status='processing') then
    raise exception 'social_projection_contract_partial_commit'; end if;
  -- Releasing a dragon preserves historical UUID references but removes it
  -- from the authoritative collection; returning the same identity restores it.
  next_state:=jsonb_set(before_state,'{sanctuaryDragons}','[]');
  receipt:=public.commit_canonical_game_command(keeper,command_id,(leased->>'lease_token')::uuid,next_state,'true');
  if not exists(select 1 from public.player_dragons where id=second_dragon and not canonical_owned) then
    raise exception 'social_projection_contract_release_history'; end if;
  update private.canonical_game_states set state=before_state,state_sha256=private.game_json_sha256(before_state),revision=4
    where owner_id=keeper;
  if not exists(select 1 from public.player_dragons where id=second_dragon and canonical_owned) then
    raise exception 'social_projection_contract_return_identity'; end if;
  -- Simulate a promoted authority solely inside this rollback transaction.
  update public.player_economy_authority set authority_mode='server',activated_at=now() where user_id=keeper;
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  begin
    perform public.publish_social_showcase('{"discovered_forms":[],"prismatic_forms":[],"trial_high_scores":{"cavernFlight":999999}}');
    raise exception 'social_projection_contract_old_showcase_accepted';
  exception when others then if sqlerrm<>'economy_server_inventory_required' then raise; end if; end;
  begin
    perform private.upsert_group_dragon(keeper,'{"client_id":"mirror-one","name":"Forgery","lineage_id":"copperflame", "stage":"hatchling", "xp":999999,"might":1,"arcana":1,"spirit":1,"evolution_path":"spirit"}');
    raise exception 'social_projection_contract_old_dragon_accepted';
  exception when others then if sqlerrm<>'economy_server_inventory_required' then raise; end if; end;
  begin
    delete from public.player_dragons where id=first_dragon;
    raise exception 'social_projection_contract_old_delete_accepted';
  exception when others then if sqlerrm<>'economy_server_inventory_required' then raise; end if; end;
  -- Legacy accounts continue using the previous publication path unchanged.
  perform set_config('request.jwt.claim.sub',outsider::text,true);
  perform public.publish_social_showcase('{"discovered_forms":["copperflame:hatchling"],"prismatic_forms":[],"trial_high_scores":{"cavernFlight":123}}');
  if not exists(select 1 from public.social_showcases where user_id=outsider and cavern_flight_best=123)
      or (select state from public.cloud_game_saves where user_id=keeper)<>source_state then
    raise exception 'social_projection_contract_legacy_changed'; end if;
end $$;
rollback;
select true as canonical_social_projection_contract_passed;
