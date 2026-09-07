begin;
set local statement_timeout = '45s';

do $$
declare keeper uuid := gen_random_uuid(); outsider uuid := gen_random_uuid();
  v_request_id uuid := gen_random_uuid(); second_request uuid := gen_random_uuid();
  v_source_state jsonb; source_hash text; original_wallet jsonb;
  started jsonb; resumed jsonb; receipt jsonb; replay jsonb; next_state jsonb;
  ruleset text := repeat('ab', 32); old_token uuid; new_token uuid;
begin
  if (select enabled from private.game_engine_runtime) then raise exception 'game_contract_requires_dormant'; end if;
  if has_function_privilege('authenticated','public.stage_canonical_game_copy(uuid,bigint,text)','execute')
    or has_function_privilege('anon','public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text)','execute')
    or has_function_privilege('authenticated','public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb)','execute')
    or has_table_privilege('authenticated','private.canonical_game_intents','select')
    or not has_function_privilege('service_role','public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text)','execute') then
    raise exception 'game_contract_permissions';
  end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text || '@canonical-contract.invalid',now()),
    (outsider,outsider::text || '@canonical-contract.invalid',now());
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform public.ensure_my_online_account();
  select to_jsonb(w) into original_wallet from public.player_wallets w where user_id = keeper;
  v_source_state := '{
    "schemaVersion":54,
    "pet":{"id":"legacy-dragon-123456789","coins":12345,"gems":678},
    "eggStash":[{"id":"legacy-special-egg","specialEggId":"witchlight_egg_v1",
      "altarKnowledge":{"tagged":true}}],
    "sanctuaryDragons":[],"releasedDragons":[{"id":"legacy-released-dragon"}],
    "chestInventory":{"wooden":123},"specialChestInventory":{"witchlight_chest_v1":4},
    "relicInventory":{"chronoshard":3,"astralLens":2},
    "untradeableRelicInventory":{"astralLens":1},"chronoshardReductions":[10,35,80],
    "preserveUnknownField":{"nested":["future-value",true,17]}
  }'::jsonb;
  source_hash := private.game_json_sha256(v_source_state);
  insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
    values(keeper,7,v_source_state,'synthetic-canonical-contract','0.5.18',54);
  insert into private.egg_altar_accounts(owner_id,fragments,essence,hearts)
    values(keeper,25,3,1);
  begin
    perform public.stage_canonical_game_copy(keeper,7,source_hash);
    raise exception 'game_contract_player_imported';
  exception when others then if sqlerrm <> 'game_service_required' then raise; end if; end;
  perform set_config('request.jwt.claim.role','service_role',true);
  begin
    perform public.stage_canonical_game_copy(keeper,6,source_hash);
    raise exception 'game_contract_stale_source';
  exception when others then if sqlerrm <> 'game_import_source_changed' then raise; end if; end;
  begin
    perform public.stage_canonical_game_copy(keeper,7,repeat('00',32));
    raise exception 'game_contract_wrong_hash';
  exception when others then if sqlerrm <> 'game_import_source_changed' then raise; end if; end;
  receipt := public.stage_canonical_game_copy(keeper,7,source_hash);
  if receipt->>'copied' <> 'true'
    or (select i.source_state from private.canonical_game_imports i where owner_id = keeper) <> v_source_state
    or (select state from private.canonical_game_states where owner_id = keeper) <> v_source_state
    or (select altar_state->'wallet'->>'hearts' from private.canonical_game_imports where owner_id = keeper) <> '1' then
    raise exception 'game_contract_lossless_copy';
  end if;
  if public.stage_canonical_game_copy(keeper,7,source_hash)->>'copied' <> 'false' then
    raise exception 'game_contract_duplicate_copy';
  end if;
  begin
    update private.canonical_game_imports set source_state = '{}' where owner_id = keeper;
    raise exception 'game_contract_mutable_source';
  exception when others then if sqlerrm <> 'economy_ledger_is_append_only' then raise; end if; end;
  begin
    perform public.begin_canonical_game_command(keeper,v_request_id,'purchase_title_chest','{}',10068,ruleset);
    raise exception 'game_contract_disabled_begin';
  exception when others then if sqlerrm <> 'game_engine_disabled' then raise; end if; end;
  update private.game_engine_runtime set enabled = true, ruleset_sha256 = ruleset;
  begin
    perform public.begin_canonical_game_command(keeper,v_request_id,'purchase_title_chest','{}',10067,ruleset);
    raise exception 'game_contract_old_client';
  exception when others then if sqlerrm <> 'game_client_upgrade_required' then raise; end if; end;
  begin
    perform public.begin_canonical_game_command(keeper,v_request_id,'purchase_title_chest','{}',10068,repeat('cd',32));
    raise exception 'game_contract_wrong_ruleset';
  exception when others then if sqlerrm <> 'game_ruleset_mismatch' then raise; end if; end;
  started := public.begin_canonical_game_command(keeper,v_request_id,'purchase_title_chest','{}',10068,ruleset);
  old_token := (started->>'lease_token')::uuid;
  if started->>'authority_mode' <> 'shadow' or started->'state' <> v_source_state
    or length(started->>'secret_seed') <> 64 then raise exception 'game_contract_begin'; end if;
  begin
    perform public.begin_canonical_game_command(keeper,v_request_id,'purchase_title_chest','{}',10068,ruleset);
    raise exception 'game_contract_duplicate_running';
  exception when others then if sqlerrm <> 'game_command_busy' then raise; end if; end;
  begin
    perform public.begin_canonical_game_command(keeper,second_request,'purchase_title_chest','{}',10068,ruleset);
    raise exception 'game_contract_parallel_intent';
  exception when others then if sqlerrm <> 'game_pending_command_required' then raise; end if; end;
  begin
    perform public.begin_canonical_game_command(keeper,v_request_id,'purchase_title_chest','{"extra":true}',10068,ruleset);
    raise exception 'game_contract_changed_payload';
  exception when others then if sqlerrm <> 'game_idempotency_conflict' then raise; end if; end;
  update private.canonical_game_intents set leased_until = now() - interval '1 second'
    where owner_id = keeper and request_id = v_request_id;
  resumed := public.begin_canonical_game_command(keeper,v_request_id,'purchase_title_chest','{}',10068,ruleset);
  new_token := (resumed->>'lease_token')::uuid;
  if new_token = old_token or resumed->>'secret_seed' <> started->>'secret_seed'
    or resumed->>'now' <> started->>'now' or resumed->'state' <> started->'state' then
    raise exception 'game_contract_retry_changed_evaluation';
  end if;
  next_state := jsonb_set(v_source_state,'{pet,coins}','12245');
  begin
    perform public.commit_canonical_game_command(keeper,v_request_id,old_token,next_state,'"purchased"');
    raise exception 'game_contract_stale_worker';
  exception when others then if sqlerrm <> 'game_lease_lost' then raise; end if; end;
  begin
    perform public.commit_canonical_game_command(outsider,v_request_id,new_token,next_state,'"purchased"');
    raise exception 'game_contract_cross_owner';
  exception when others then if sqlerrm <> 'game_lease_lost' then raise; end if; end;
  begin
    perform public.commit_canonical_game_command(keeper,v_request_id,new_token,
      jsonb_set(next_state,'{pet,coins}','-1'),'"purchased"');
    raise exception 'game_contract_negative_wallet';
  exception when others then if sqlerrm <> 'game_wallet_invalid' then raise; end if; end;
  receipt := public.commit_canonical_game_command(keeper,v_request_id,new_token,next_state,'"purchased"');
  replay := public.commit_canonical_game_command(keeper,v_request_id,new_token,next_state,'"purchased"');
  if replay <> receipt or receipt->>'server_revision' <> '2'
    or (select state from private.canonical_game_states where owner_id = keeper) <> next_state then
    raise exception 'game_contract_commit_replay';
  end if;
  replay := public.begin_canonical_game_command(keeper,v_request_id,'purchase_title_chest','{}',10068,ruleset);
  if replay->>'status' <> 'succeeded' or replay->'response' <> receipt or replay ? 'secret_seed' then
    raise exception 'game_contract_final_receipt';
  end if;
  resumed := public.begin_canonical_game_command(keeper,second_request,'purchase_title_chest','{}',10068,ruleset);
  if not public.fail_canonical_game_command(keeper,second_request,(resumed->>'lease_token')::uuid,'invalid_command') then
    raise exception 'game_contract_failure_not_recorded';
  end if;
  if (select state from public.cloud_game_saves where user_id = keeper) <> v_source_state
    or (select to_jsonb(w) from public.player_wallets w where user_id = keeper) <> original_wallet
    or (select authority_mode from public.player_economy_authority where user_id = keeper) <> 'legacy_client'
    or (select mutations_enabled from private.economy_contract)
    or (select hearts from private.egg_altar_accounts where owner_id = keeper) <> 1 then
    raise exception 'game_contract_live_state_changed';
  end if;
  delete from auth.users where id in (keeper,outsider);
  if exists(select 1 from private.canonical_game_imports where owner_id = keeper)
    or exists(select 1 from private.canonical_game_states where owner_id = keeper)
    or exists(select 1 from private.canonical_game_intents where owner_id = keeper) then
    raise exception 'game_contract_account_cleanup';
  end if;
end
$$;
rollback;
select true as canonical_game_contract_passed;
