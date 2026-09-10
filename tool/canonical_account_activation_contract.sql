begin;
set local statement_timeout='45s';
do $$
declare keeper uuid:=gen_random_uuid(); outsider uuid:=gen_random_uuid(); request_id uuid:=gen_random_uuid();
  rules text:=repeat('a7',32); source_state jsonb; prepared_state jsonb; captured jsonb; imported jsonb;
  prepared jsonb; activated jsonb; reply jsonb; leased jsonb; command_id uuid; import_id uuid; rev bigint;
begin
  if (select enabled or migration_enabled or shadow_projection_enabled or shadow_social_enabled or shadow_lifecycle_enabled
      from private.game_engine_runtime where singleton) then raise exception 'activation_contract_requires_dormant'; end if;
  if has_function_privilege('authenticated','public.activate_canonical_account(uuid,uuid,uuid,bigint,text)','execute') or
    has_function_privilege('authenticated','public.begin_canonical_account_migration(uuid,uuid,bigint,integer,text)','execute') or
    has_table_privilege('authenticated','private.canonical_account_migrations','select') then
      raise exception 'activation_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text||'@activation-contract.invalid',now()),(outsider,outsider::text||'@activation-contract.invalid',now());
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keeper::text,true); perform public.ensure_my_online_account();
  perform set_config('request.jwt.claim.sub',outsider::text,true); perform public.ensure_my_online_account();
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
    "prismaticForms":["copperflame:ascended:might"]}'::jsonb || jsonb_build_object('eggAltar',jsonb_build_object('ownerId',keeper),
    'pendingAltarOperation',null,'futureMetadata',jsonb_build_object('preserved',true));
  insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
    values(keeper,1,source_state,'synthetic-activation','0.5.30',54);
  insert into private.egg_altar_accounts(owner_id,fragments,essence,hearts) values(keeper,25,3,1);
  perform set_config('request.jwt.claim.role','service_role',true);
  update private.game_engine_runtime set ruleset_sha256=rules where singleton;
  begin
    perform public.begin_canonical_account_migration(keeper,request_id,1,10080,rules);
    raise exception 'activation_contract_disabled_accepted';
  exception when others then if sqlerrm<>'game_migration_disabled' then raise; end if; end;
  update private.game_engine_runtime set migration_enabled=true where singleton;
  captured:=public.begin_canonical_account_migration(keeper,request_id,1,10080,rules);
  imported:=public.get_canonical_game_import(keeper); import_id:=(imported->>'import_id')::uuid;
  prepared_state:=source_state||jsonb_build_object('eggAltar',jsonb_build_object('ownerId',keeper,'revision',1));
  prepared:=public.commit_canonical_game_preparation(keeper,import_id,(imported->>'base_revision')::bigint,
    rules,prepared_state,array['eggAltar']);
  rev:=(prepared->>'server_revision')::bigint;
  begin
    perform public.read_canonical_game_state(keeper,10080,rules);
    raise exception 'activation_contract_captured_playable';
  exception when others then if sqlerrm<>'game_migration_in_progress' then raise; end if; end;
  -- Capture does not freeze the legacy save. A competing device invalidates
  -- promotion; no authority or economy transition happens on this failure.
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  update public.cloud_game_saves set revision=2 where user_id=keeper;
  perform set_config('request.jwt.claim.role','service_role',true);
  begin
    perform public.activate_canonical_account(keeper,request_id,import_id,rev,rules);
    raise exception 'activation_contract_stale_source_accepted';
  exception when others then if sqlerrm<>'game_import_source_changed' then raise; end if; end;
  if exists(select 1 from public.player_economy_authority where user_id=keeper and authority_mode='server') then
    raise exception 'activation_contract_failure_promoted'; end if;
  request_id:=gen_random_uuid();
  captured:=public.begin_canonical_account_migration(keeper,request_id,2,10080,rules);
  imported:=public.get_canonical_game_import(keeper); import_id:=(imported->>'import_id')::uuid;
  prepared:=public.commit_canonical_game_preparation(keeper,import_id,(imported->>'base_revision')::bigint,
    rules,prepared_state,array['eggAltar']); rev:=(prepared->>'server_revision')::bigint;
  -- Concurrent Altar and social inventory writes are independent fences.
  update private.egg_altar_accounts set fragments=26 where owner_id=keeper;
  begin
    perform public.activate_canonical_account(keeper,request_id,import_id,rev,rules);
    raise exception 'activation_contract_stale_altar_accepted';
  exception when others then if sqlerrm<>'game_import_altar_changed' then raise; end if; end;
  update private.egg_altar_accounts set fragments=25 where owner_id=keeper;
  update public.player_wallets set coins=coins+1 where user_id=keeper;
  begin
    perform public.activate_canonical_account(keeper,request_id,import_id,rev,rules);
    raise exception 'activation_contract_stale_social_accepted';
  exception when others then if sqlerrm<>'game_migration_social_changed' then raise; end if; end;
  request_id:=gen_random_uuid();
  perform public.begin_canonical_account_migration(keeper,request_id,2,10080,rules);
  begin
    perform public.activate_canonical_account(outsider,request_id,import_id,rev,rules);
    raise exception 'activation_contract_foreign_capture_accepted';
  exception when others then if sqlerrm<>'game_migration_capture_changed' then raise; end if; end;
  activated:=public.activate_canonical_account(keeper,request_id,import_id,rev,rules);
  if activated->>'phase'<>'active' or (activated->>'server_revision')::bigint<>rev+1 or
    (select state from private.canonical_game_states where owner_id=keeper)<>prepared_state or
    (select state from public.cloud_game_saves where user_id=keeper)<>source_state or
    not exists(select 1 from public.player_wallets where user_id=keeper and coins=12345 and gems=987) or
    not exists(select 1 from public.player_economy_authority where user_id=keeper and authority_mode='server' and protocol_version=2) then
      raise exception 'activation_contract_promotion_changed_assets'; end if;
  reply:=public.activate_canonical_account(keeper,request_id,import_id,rev,rules);
  if reply->>'replayed'<>'true' or reply->'server_revision'<>activated->'server_revision' then
    raise exception 'activation_contract_replay'; end if;
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  if public.get_my_canonical_account_status()->>'phase'<>'active' then raise exception 'activation_contract_status'; end if;
  begin
    update public.cloud_game_saves set revision=3 where user_id=keeper;
    raise exception 'activation_contract_old_cloud_accepted';
  exception when others then if sqlerrm<>'economy_server_inventory_required' then raise; end if; end;
  begin
    update private.egg_altar_accounts set fragments=100 where owner_id=keeper;
    raise exception 'activation_contract_old_altar_accepted';
  exception when others then if sqlerrm<>'economy_server_inventory_required' then raise; end if; end;
  perform set_config('request.jwt.claim.sub',outsider::text,true);
  if public.get_my_canonical_account_status()->>'phase'<>'legacy' then raise exception 'activation_contract_status_owner'; end if;
  perform set_config('request.jwt.claim.role','service_role',true);
  update private.game_engine_runtime set enabled=true where singleton;
  reply:=public.read_canonical_game_state(keeper,10080,rules);
  if reply->>'authority_mode'<>'server' then raise exception 'activation_contract_live_read'; end if;
  command_id:=gen_random_uuid();
  leased:=public.begin_revisioned_game_command(keeper,command_id,'refresh','{}',10080,rules,rev+1);
  prepared_state:=jsonb_set(prepared_state,'{pet,coins}','12340');
  reply:=public.commit_canonical_game_command(keeper,command_id,(leased->>'lease_token')::uuid,prepared_state,'true');
  if reply->>'authority_mode'<>'server' or (reply->>'server_revision')::bigint<>rev+2 then
    raise exception 'activation_contract_live_command'; end if;
  reply:=public.recover_canonical_game_commands(keeper,gen_random_uuid(),10080,rules);
  if reply->>'authority_mode'<>'server' or (reply->>'barrier_revision')::bigint<>rev+3 then
    raise exception 'activation_contract_live_recovery'; end if;
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keeper::text,true); perform public.delete_my_account();
  if exists(select 1 from private.canonical_account_migrations where owner_id=keeper) or
    exists(select 1 from private.canonical_game_imports where owner_id=keeper) or
    exists(select 1 from private.canonical_game_states where owner_id=keeper) or
    not exists(select 1 from auth.users where id=outsider) then raise exception 'activation_contract_account_cleanup'; end if;
  perform set_config('request.jwt.claim.role','service_role',true); delete from auth.users where id=outsider;
end $$;
select true as canonical_account_activation_contract_passed;
rollback;
