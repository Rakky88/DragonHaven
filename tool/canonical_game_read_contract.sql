begin;
set local statement_timeout = '45s';
do $$
declare v_owner uuid := gen_random_uuid(); v_other uuid := gen_random_uuid();
  v_state jsonb; v_import jsonb; v_snapshot jsonb; v_wallet jsonb;
  v_rules text := repeat('ab',32); v_count bigint;
begin
  if (select enabled from private.game_engine_runtime) then raise exception 'read_contract_requires_dormant'; end if;
  if has_function_privilege('authenticated','public.read_canonical_game_state(uuid,integer,text)','execute')
    or has_function_privilege('anon','public.read_canonical_game_state(uuid,integer,text)','execute')
    or not has_function_privilege('service_role','public.read_canonical_game_state(uuid,integer,text)','execute') then
    raise exception 'read_contract_permissions';
  end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (v_owner,v_owner::text || '@game-read-contract.invalid',now()),
    (v_other,v_other::text || '@game-read-contract.invalid',now());
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',v_owner::text,true);
  perform public.ensure_my_online_account();
  select to_jsonb(w) into v_wallet from public.player_wallets w where user_id=v_owner;
  perform set_config('request.jwt.claim.sub',v_other::text,true);
  perform public.ensure_my_online_account();
  v_state := jsonb_build_object('schemaVersion',54,'pet',jsonb_build_object('id','existing-dragon','coins',100,'gems',50),
    'eggStash','[]'::jsonb,'sanctuaryDragons','[]'::jsonb,'releasedDragons','[]'::jsonb,
    'chestInventory','{}'::jsonb,'specialChestInventory','{}'::jsonb,
    'relicInventory','{}'::jsonb,'untradeableRelicInventory','{}'::jsonb,
    'eggAltar',jsonb_build_object('ownerId',v_owner),'pendingAltarOperation',null,
    'privateFutureField',jsonb_build_object('secret',17));
  insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
    values(v_owner,1,v_state,'synthetic-read-contract','0.5.18',54);
  perform set_config('request.jwt.claim.role','service_role',true);
  perform public.stage_canonical_game_copy(v_owner,1,private.game_json_sha256(v_state));
  update private.game_engine_runtime set ruleset_sha256=v_rules where singleton;
  begin
    perform public.read_canonical_game_state(v_owner,10068,v_rules);
    raise exception 'read_contract_unprepared_exposed';
  exception when others then if sqlerrm <> 'game_import_preparation_required' then raise; end if; end;
  v_import := public.get_canonical_game_import(v_owner);
  perform public.commit_canonical_game_preparation(v_owner,(v_import->>'import_id')::uuid,1,v_rules,v_state,array[]::text[]);
  select count(*) into v_count from private.canonical_game_intents;
  v_snapshot := public.read_canonical_game_state(v_owner,10068,v_rules);
  if v_snapshot->>'owner_id' <> v_owner::text or v_snapshot->>'server_revision' <> '2'
    or v_snapshot->'state' <> v_state or v_snapshot->>'state_sha256' <> private.game_json_sha256(v_state)
    or v_snapshot->>'authority_mode' <> 'shadow' or v_snapshot->'mutations_enabled' <> 'false'::jsonb
    or v_snapshot->>'server_time' is null then raise exception 'read_contract_snapshot'; end if;
  begin
    perform set_config('request.jwt.claim.role','authenticated',true);
    perform public.read_canonical_game_state(v_owner,10068,v_rules);
    raise exception 'read_contract_player_read_private_state';
  exception when others then if sqlerrm <> 'game_service_required' then raise; end if; end;
  perform set_config('request.jwt.claim.role','service_role',true);
  begin
    perform public.read_canonical_game_state(v_other,10068,v_rules);
    raise exception 'read_contract_cross_owner';
  exception when others then if sqlerrm <> 'game_import_required' then raise; end if; end;
  begin
    perform public.read_canonical_game_state(v_owner,10067,v_rules);
    raise exception 'read_contract_old_client';
  exception when others then if sqlerrm <> 'game_client_upgrade_required' then raise; end if; end;
  begin
    perform public.read_canonical_game_state(v_owner,10068,repeat('cd',32));
    raise exception 'read_contract_wrong_rules';
  exception when others then if sqlerrm <> 'game_ruleset_mismatch' then raise; end if; end;
  update private.game_engine_runtime set enabled=true where singleton;
  if (public.read_canonical_game_state(v_owner,10068,v_rules)->'mutations_enabled') <> 'true'::jsonb then
    raise exception 'read_contract_runtime_status';
  end if;
  if (select count(*) from private.canonical_game_intents) <> v_count
    or (select revision from private.canonical_game_states where owner_id=v_owner) <> 2
    or (select state from public.cloud_game_saves where user_id=v_owner) <> v_state
    or (select to_jsonb(w) from public.player_wallets w where user_id=v_owner) <> v_wallet then
    raise exception 'read_contract_mutated_game';
  end if;
  delete from auth.users where id in (v_owner,v_other);
  if exists(select 1 from private.canonical_game_states where owner_id in (v_owner,v_other)) then
    raise exception 'read_contract_cleanup';
  end if;
end $$;
rollback;
select true as canonical_game_read_contract_passed;
