begin;
set local statement_timeout = '45s';
do $$
declare v_owner uuid := gen_random_uuid(); v_other uuid := gen_random_uuid();
  v_request uuid := gen_random_uuid(); v_first uuid; v_second uuid; v_third uuid;
  v_state jsonb; v_ready jsonb; v_copy jsonb; v_input jsonb; v_lease jsonb; v_receipt jsonb;
  v_original_wallet jsonb; v_source_hash text; v_rules text := repeat('cd',32);
begin
  if (select enabled from private.game_engine_runtime) then raise exception 'import_contract_requires_dormant'; end if;
  if has_function_privilege('authenticated','public.get_canonical_game_import(uuid)','execute')
    or has_function_privilege('anon','public.commit_canonical_game_preparation(uuid,uuid,bigint,text,jsonb,text[])','execute')
    or has_table_privilege('authenticated','private.canonical_game_preparations','select') then
    raise exception 'import_contract_permissions';
  end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (v_owner,v_owner::text || '@game-import-contract.invalid',now()),
    (v_other,v_other::text || '@game-import-contract.invalid',now());
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',v_owner::text,true);
  perform public.ensure_my_online_account();
  select to_jsonb(w) into v_original_wallet from public.player_wallets w where user_id=v_owner;
  perform set_config('request.jwt.claim.sub',v_other::text,true);
  perform public.ensure_my_online_account();
  v_state := jsonb_build_object('schemaVersion',54,'pet',jsonb_build_object('id','existing-dragon','coins',100,'gems',50),
    'eggStash','[]'::jsonb,'sanctuaryDragons','[]'::jsonb,'releasedDragons','[]'::jsonb,
    'chestInventory','{}'::jsonb,'specialChestInventory','{}'::jsonb,
    'relicInventory','{}'::jsonb,'untradeableRelicInventory','{}'::jsonb,
    'eggAltar',jsonb_build_object('ownerId',v_owner),'pendingAltarOperation',null,
    'futureField',jsonb_build_object('preserved',true));
  insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
    values(v_owner,1,v_state,'synthetic-import-contract','0.5.18',54);
  insert into private.egg_altar_accounts(owner_id,fragments,essence,hearts) values(v_owner,25,3,1);
  perform set_config('request.jwt.claim.role','service_role',true);
  v_source_hash := private.game_json_sha256(v_state);
  v_copy := public.stage_canonical_game_copy(v_owner,1,v_source_hash);
  v_first := (v_copy->>'import_id')::uuid;
  v_input := public.get_canonical_game_import(v_owner);
  if v_input->>'import_id' <> v_first::text or v_input->>'base_revision' <> '1'
    or v_input->'source' <> v_state or length(v_input->>'secret_seed') <> 64
    or (v_input->'authoritative_altar'->'wallet'->>'fragments')::int <> 25 then
    raise exception 'import_contract_private_source';
  end if;
  update private.game_engine_runtime set ruleset_sha256=v_rules where singleton;
  begin
    perform set_config('request.jwt.claim.role','authenticated',true);
    perform public.get_canonical_game_import(v_owner);
    raise exception 'import_contract_player_read_seed';
  exception when others then if sqlerrm <> 'game_service_required' then raise; end if; end;
  perform set_config('request.jwt.claim.role','service_role',true);
  begin
    perform public.commit_canonical_game_preparation(v_other,v_first,1,v_rules,v_state,array['eggAltar']);
    raise exception 'import_contract_cross_owner';
  exception when others then if sqlerrm <> 'game_import_generation_changed' then raise; end if; end;
  begin
    perform public.commit_canonical_game_preparation(v_owner,v_first,2,v_rules,v_state,array['eggAltar']);
    raise exception 'import_contract_stale_revision';
  exception when others then if sqlerrm <> 'game_revision_conflict' then raise; end if; end;
  begin
    perform public.commit_canonical_game_preparation(v_owner,v_first,1,v_rules,
      jsonb_set(v_state,'{pet,coins}','101'),array['wallet']);
    raise exception 'import_contract_import_granted_coins';
  exception when others then if sqlerrm <> 'game_import_economy_invalid' then raise; end if; end;
  update public.cloud_game_saves set revision=2,state=state || '{"newField":17}'::jsonb where user_id=v_owner;
  begin
    perform public.commit_canonical_game_preparation(v_owner,v_first,1,v_rules,v_state,array['eggAltar']);
    raise exception 'import_contract_source_race';
  exception when others then if sqlerrm <> 'game_import_source_changed' then raise; end if; end;
  v_state := v_state || '{"newField":17}'::jsonb;
  v_source_hash := private.game_json_sha256(v_state);
  v_copy := public.stage_canonical_game_copy(v_owner,2,v_source_hash);
  v_second := (v_copy->>'import_id')::uuid;
  if v_second=v_first or (select count(*) from private.canonical_game_imports where owner_id=v_owner) <> 2
    or (select source_state->'futureField' from private.canonical_game_imports where import_id=v_first) <> '{"preserved":true}'::jsonb then
    raise exception 'import_contract_generation_history';
  end if;
  begin
    perform public.commit_canonical_game_preparation(v_owner,v_first,1,v_rules,v_state,array['eggAltar']);
    raise exception 'import_contract_old_generation_committed';
  exception when others then if sqlerrm <> 'game_import_generation_changed' then raise; end if; end;
  update private.egg_altar_accounts set revision=revision+1,fragments=26 where owner_id=v_owner;
  begin
    perform public.commit_canonical_game_preparation(v_owner,v_second,2,v_rules,v_state,array['eggAltar']);
    raise exception 'import_contract_altar_race';
  exception when others then if sqlerrm <> 'game_import_altar_changed' then raise; end if; end;
  v_copy := public.stage_canonical_game_copy(v_owner,2,v_source_hash);
  v_third := (v_copy->>'import_id')::uuid;
  if v_third=v_second or (select count(*) from private.canonical_game_imports where owner_id=v_owner) <> 3 then
    raise exception 'import_contract_altar_generation';
  end if;
  if public.stage_canonical_game_copy(v_owner,2,v_source_hash)->>'copied' <> 'false' then
    raise exception 'import_contract_generation_replay';
  end if;
  update private.game_engine_runtime set enabled=true where singleton;
  v_lease := public.begin_canonical_game_command(v_owner,v_request,'refresh','{}',10068,v_rules);
  begin
    perform public.commit_canonical_game_preparation(v_owner,v_third,3,v_rules,v_state,array['eggAltar']);
    raise exception 'import_contract_pending_command';
  exception when others then if sqlerrm <> 'game_pending_command_required' then raise; end if; end;
  perform public.fail_canonical_game_command(v_owner,v_request,(v_lease->>'lease_token')::uuid,'game_import_reconciliation_required');
  update private.game_engine_runtime set enabled=false where singleton;
  v_ready := jsonb_set(v_state,'{eggAltar}',private.egg_altar_state(v_owner));
  v_receipt := public.commit_canonical_game_preparation(v_owner,v_third,3,v_rules,v_ready,array['eggAltar']);
  if v_receipt->>'server_revision' <> '4' or v_receipt->>'replayed' <> 'false'
    or not (select is_prepared from private.canonical_game_states where owner_id=v_owner)
    or (select state from private.canonical_game_states where owner_id=v_owner) <> v_ready
    or (select count(*) from private.canonical_game_preparations where owner_id=v_owner) <> 1 then
    raise exception 'import_contract_atomic_preparation';
  end if;
  if public.commit_canonical_game_preparation(v_owner,v_third,3,v_rules,v_ready,array['eggAltar'])->>'replayed' <> 'true' then
    raise exception 'import_contract_preparation_replay';
  end if;
  begin
    perform public.commit_canonical_game_preparation(v_owner,v_third,3,v_rules,
      v_ready || '{"changed":true}',array['eggAltar']);
    raise exception 'import_contract_changed_replay';
  exception when others then if sqlerrm <> 'game_idempotency_conflict' then raise; end if; end;
  begin
    update private.canonical_game_preparations set prepared_revision=99 where owner_id=v_owner;
    raise exception 'import_contract_mutable_preparation';
  exception when others then if sqlerrm <> 'economy_ledger_is_append_only' then raise; end if; end;
  if (select to_jsonb(w) from public.player_wallets w where user_id=v_owner) <> v_original_wallet
    or (select state from public.cloud_game_saves where user_id=v_owner) <> v_state
    or (select fragments from private.egg_altar_accounts where owner_id=v_owner) <> 26
    or (select authority_mode from public.player_economy_authority where user_id=v_owner) <> 'legacy_client'
    or (select mutations_enabled from private.economy_contract where singleton) then
    raise exception 'import_contract_live_state_changed';
  end if;
  delete from auth.users where id in (v_owner,v_other);
  if exists(select 1 from private.canonical_game_imports where owner_id in (v_owner,v_other))
    or exists(select 1 from private.canonical_game_states where owner_id in (v_owner,v_other))
    or exists(select 1 from private.canonical_game_preparations where owner_id in (v_owner,v_other)) then
    raise exception 'import_contract_account_cleanup';
  end if;
end $$;
rollback;
select true as canonical_import_contract_passed;
