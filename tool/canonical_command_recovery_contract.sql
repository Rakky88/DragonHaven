begin;
set local statement_timeout = '45s';
do $$
declare keeper uuid := gen_random_uuid(); outsider uuid := gen_random_uuid();
  command_id uuid := gen_random_uuid(); recovery_id uuid := gen_random_uuid();
  late_id uuid := gen_random_uuid(); next_id uuid := gen_random_uuid();
  rules text := repeat('ab',32); source_state jsonb; original_wallet jsonb;
  leased jsonb; proof jsonb; replay jsonb; receipt jsonb; next_state jsonb;
  original_token uuid; base_revision bigint; frozen_hash text;
begin
  if (select enabled from private.game_engine_runtime) then raise exception 'recovery_contract_requires_dormant'; end if;
  if has_function_privilege('service_role','public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text)','execute')
    or has_function_privilege('anon','public.recover_canonical_game_commands(uuid,uuid,integer,text)','execute')
    or has_function_privilege('authenticated','public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint)','execute')
    or has_table_privilege('authenticated','private.canonical_game_recoveries','select')
    or not has_function_privilege('service_role','public.recover_canonical_game_commands(uuid,uuid,integer,text)','execute')
    or not has_function_privilege('service_role','public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint)','execute') then
    raise exception 'recovery_contract_permissions';
  end if;
  insert into auth.users(id,email,email_confirmed_at)
    values(keeper,keeper::text||'@recovery-contract.invalid',now());
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform public.ensure_my_online_account();
  select to_jsonb(w) into original_wallet from public.player_wallets w where user_id=keeper;
  source_state := '{"schemaVersion":54,"pet":{"id":"recovery-dragon","coins":1000,"gems":10},
    "eggStash":[],"sanctuaryDragons":[],"releasedDragons":[],"chestInventory":{"wooden":2},
    "specialChestInventory":{},"relicInventory":{},"untradeableRelicInventory":{}}'::jsonb;
  insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
    values(keeper,1,source_state,'synthetic-recovery-contract','0.5.19',54);
  begin
    perform public.recover_canonical_game_commands(keeper,recovery_id,10069,rules);
    raise exception 'recovery_contract_player_service';
  exception when others then if sqlerrm <> 'game_service_required' then raise; end if; end;
  perform set_config('request.jwt.claim.role','service_role',true);
  perform public.stage_canonical_game_copy(keeper,1,private.game_json_sha256(source_state));
  update private.game_engine_runtime set enabled=true,ruleset_sha256=rules where singleton;
  begin
    perform public.recover_canonical_game_commands(keeper,recovery_id,10069,rules);
    raise exception 'recovery_contract_unprepared';
  exception when others then if sqlerrm <> 'game_import_preparation_required' then raise; end if; end;
  -- Synthetic fixture preparation only, never a real account import.
  update private.canonical_game_states set is_prepared=true where owner_id=keeper;
  begin
    perform public.recover_canonical_game_commands(outsider,recovery_id,10069,rules);
    raise exception 'recovery_contract_outsider';
  exception when others then if sqlerrm <> 'game_import_required' then raise; end if; end;
  leased := public.begin_revisioned_game_command(keeper,command_id,'purchase_title_chest','{}',10069,rules,1);
  original_token := (leased->>'lease_token')::uuid;
  update private.game_engine_runtime set enabled=false where singleton;
  proof := public.recover_canonical_game_commands(keeper,recovery_id,10069,rules);
  if proof->>'barrier_revision' <> '2' or proof->>'cancelled_commands' <> '1'
    or proof->>'owner_id' <> keeper::text or proof->>'replayed' <> 'false'
    or (select state from private.canonical_game_states where owner_id=keeper) <> source_state then
    raise exception 'recovery_contract_paused_recovery';
  end if;
  replay := public.recover_canonical_game_commands(keeper,recovery_id,10069,rules);
  if replay-'replayed' <> proof-'replayed' or replay->>'replayed' <> 'true'
    or (select revision from private.canonical_game_states where owner_id=keeper) <> 2 then
    raise exception 'recovery_contract_idempotency';
  end if;
  -- A worker already evaluating when recovery began may never commit afterwards.
  update private.game_engine_runtime set enabled=true where singleton;
  begin
    perform public.commit_canonical_game_command(keeper,command_id,original_token,source_state,'{}');
    raise exception 'recovery_contract_late_worker';
  exception when others then if sqlerrm <> 'game_lease_lost' then raise; end if; end;
  receipt := public.begin_revisioned_game_command(keeper,command_id,'purchase_title_chest','{}',10069,rules,1);
  if receipt->>'status' <> 'failed' or receipt->>'failure_code' <> 'game_command_recovered' then
    raise exception 'recovery_contract_cancelled_replay';
  end if;
  -- This UUID was never seen before recovery; its delayed HTTP arrival is fenced too.
  receipt := public.begin_revisioned_game_command(keeper,late_id,'purchase_title_chest','{}',10069,rules,1);
  if receipt->>'status' <> 'failed' or receipt->>'failure_code' <> 'game_state_changed'
    or receipt->>'replayed' <> 'false' then raise exception 'recovery_contract_late_request'; end if;
  begin
    perform public.begin_revisioned_game_command(keeper,late_id,'purchase_title_chest','{}',10069,rules,2);
    raise exception 'recovery_contract_rewritten_revision';
  exception when others then if sqlerrm <> 'game_idempotency_conflict' then raise; end if; end;
  leased := public.begin_revisioned_game_command(keeper,next_id,'purchase_title_chest','{}',10069,rules,2);
  next_state := jsonb_set(source_state,'{pet,coins}','900');
  receipt := public.commit_canonical_game_command(keeper,next_id,(leased->>'lease_token')::uuid,next_state,'"purchased"');
  if receipt->>'server_revision' <> '3' then raise exception 'recovery_contract_next_action'; end if;
  frozen_hash := receipt->>'state_sha256';
  -- A completed action stays completed; another recovery changes no assets/hash.
  proof := public.recover_canonical_game_commands(keeper,gen_random_uuid(),10069,rules);
  if proof->>'barrier_revision' <> '4' or proof->>'cancelled_commands' <> '0'
    or (select state_sha256 from private.canonical_game_states where owner_id=keeper) <> frozen_hash then
    raise exception 'recovery_contract_committed_assets';
  end if;
  update private.game_engine_runtime set enabled=false where singleton;
  replay := public.begin_revisioned_game_command(keeper,next_id,'purchase_title_chest','{}',10069,rules,2);
  if replay->'response' <> receipt or replay->>'status' <> 'succeeded' then
    raise exception 'recovery_contract_committed_receipt';
  end if;
  if (select state from public.cloud_game_saves where user_id=keeper) <> source_state
    or (select to_jsonb(w) from public.player_wallets w where user_id=keeper) <> original_wallet
    or (select authority_mode from public.player_economy_authority where user_id=keeper) <> 'legacy_client'
    or (select count(*) from private.canonical_game_intents where owner_id=keeper and status='processing') <> 0 then
    raise exception 'recovery_contract_live_state';
  end if;
  base_revision := 4;
  for counter in 1..4 loop
    perform public.recover_canonical_game_commands(keeper,gen_random_uuid(),10069,rules);
    base_revision := base_revision+1;
  end loop;
  begin
    perform public.recover_canonical_game_commands(keeper,gen_random_uuid(),10069,rules);
    raise exception 'recovery_contract_rate_limit';
  exception when others then if sqlerrm <> 'economy_rate_limited' then raise; end if; end;
  if (select revision from private.canonical_game_states where owner_id=keeper) <> base_revision then
    raise exception 'recovery_contract_rate_limit_mutated';
  end if;
  begin
    delete from private.canonical_game_recoveries where owner_id=keeper;
    raise exception 'recovery_contract_mutable_history';
  exception when others then if sqlerrm <> 'economy_ledger_is_append_only' then raise; end if; end;
  delete from auth.users where id=keeper;
  if exists(select 1 from private.canonical_game_recoveries where owner_id=keeper) then
    raise exception 'recovery_contract_deletion';
  end if;
end $$;
rollback;
select true as canonical_command_recovery_contract_passed;
