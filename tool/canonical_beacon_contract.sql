begin;
set local statement_timeout='45s';
do $$
declare keeper uuid:=gen_random_uuid(); cid uuid:=gen_random_uuid(); source_state jsonb;
  rules text:=repeat('c3',32); request_id uuid:=gen_random_uuid(); payload jsonb; leased jsonb;
  next_state jsonb; receipt jsonb; replay jsonb; revision_before bigint; wallet_before jsonb;
begin
  if (select enabled or shadow_social_enabled or shadow_projection_enabled or shadow_lifecycle_enabled
      from private.game_engine_runtime where singleton) then raise exception 'beacon_contract_requires_dormant'; end if;
  if has_function_privilege('service_role','public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text)','execute')
      or has_function_privilege('service_role','public.begin_revisioned_game_command_v72(uuid,uuid,text,jsonb,integer,text,bigint)','execute')
      or has_function_privilege('authenticated','public.egg_altar_command_v72(text,text,jsonb)','execute') then
    raise exception 'beacon_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values(keeper,keeper::text||'@beacon-contract.invalid',now());
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  perform public.ensure_my_online_account();
    source_state:=jsonb_build_object('schemaVersion',54,'pet',jsonb_build_object('id','beacon-dragon',
      'name','Beacon Keeper','stage','ascended','lineageId','copperflame','xp',3400,'coins',1000,'gems',10,
      'training',jsonb_build_object('might',300,'arcana',300,'spirit',300),'evolutionPath','might',
      'favorite',true,'spectral',false,'sinister',false,'trialHighScores','{}'::jsonb,'activeAdventureId',null),
      'eggStash','[]'::jsonb,'sanctuaryDragons','[]'::jsonb,'releasedDragons','[]'::jsonb,
      'chestInventory','{}'::jsonb,'specialChestInventory','{}'::jsonb,'relicInventory','{}'::jsonb,
      'untradeableRelicInventory','{}'::jsonb,'discoveredForms',jsonb_build_array('copperflame:ascended:might'),
      'prismaticForms','[]'::jsonb);
    source_state:=source_state||jsonb_build_object('eggAltar',jsonb_build_object('ownerId',keeper,'revision',0,
      'wallet',jsonb_build_object('fragments',200,'essence',7,'hearts',2)));

  insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
    values(keeper,1,source_state,'synthetic-beacon','0.5.30',54);
  perform set_config('request.jwt.claim.role','service_role',true);
  perform public.stage_canonical_game_copy(keeper,1,private.game_json_sha256(source_state));
  update private.game_engine_runtime set enabled=true,ruleset_sha256=rules,shadow_lifecycle_enabled=true,
    shadow_projection_enabled=true where singleton;
  update private.canonical_game_states set is_prepared=true where owner_id=keeper;
  insert into public.conclaves(id,name,emblem_key,language,visibility,member_limit,created_by)
    values(cid,'Beacon '||left(cid::text,18),'conclave_emblem_01','en','invite',4,keeper);
  insert into public.conclave_members(conclave_id,user_id,role) values(cid,keeper,'flightmaster');
  insert into private.conclave_weave_beacons(conclave_id,fragments) values(cid,490);
  payload:=jsonb_build_object('conclaveId',cid,'amount',25);
  select revision into revision_before from private.canonical_game_states where owner_id=keeper;
  leased:=public.begin_revisioned_game_command(keeper,request_id,'donate_beacon',payload,10080,rules,revision_before);
  if leased->>'status'<>'processing' or leased->'social_context'->'facts' is distinct from
      jsonb_build_object('beforeFragments',490,'amount',25,'goal',5000) then raise exception 'beacon_contract_sealed_context'; end if;
  -- A forged worker receipt cannot record a donation without the exact debit.
  begin
    perform public.commit_canonical_game_command(keeper,request_id,(leased->>'lease_token')::uuid,source_state,
      jsonb_build_object('donated',25,'fragments',515));
    raise exception 'beacon_contract_missing_debit_accepted';
  exception when others then if sqlerrm<>'game_social_state_changed' then raise; end if; end;
  next_state:=jsonb_set(source_state,'{eggAltar,wallet,fragments}','175');
  receipt:=public.commit_canonical_game_command(keeper,request_id,(leased->>'lease_token')::uuid,next_state,
    jsonb_build_object('donated',25,'fragments',515));
  replay:=public.begin_revisioned_game_command(keeper,request_id,'donate_beacon',payload,10080,rules,revision_before);
  if replay->>'status'<>'succeeded' or replay->'response' is distinct from receipt
      or (select fragments from private.conclave_weave_beacons where conclave_id=cid)<>515
      or (select count(*) from public.conclave_messages where conclave_id=cid)<>1
      or (select state->'eggAltar'->'wallet' from private.canonical_game_states where owner_id=keeper)<>
        jsonb_build_object('fragments',175,'essence',7,'hearts',2) then raise exception 'beacon_contract_exact_once'; end if;
  -- Another donor may change capacity between lease and commit. No debit or
  -- stage notification from the obsolete attempt may survive that refusal.
  request_id:=gen_random_uuid();
  select revision,state->'eggAltar'->'wallet' into revision_before,wallet_before from private.canonical_game_states where owner_id=keeper;
  leased:=public.begin_revisioned_game_command(keeper,request_id,'donate_beacon',payload,10080,rules,revision_before);
  update private.conclave_weave_beacons set fragments=520 where conclave_id=cid;
  next_state:=jsonb_set(next_state,'{eggAltar,wallet,fragments}','150');
  begin
    perform public.commit_canonical_game_command(keeper,request_id,(leased->>'lease_token')::uuid,next_state,
      jsonb_build_object('donated',25,'fragments',540));
    raise exception 'beacon_contract_changed_capacity_accepted';
  exception when others then if sqlerrm<>'game_social_state_changed' then raise; end if; end;
  if (select revision from private.canonical_game_states where owner_id=keeper)<>revision_before
      or (select state->'eggAltar'->'wallet' from private.canonical_game_states where owner_id=keeper)<>wallet_before then
    raise exception 'beacon_contract_changed_capacity_debited'; end if;
  perform public.fail_canonical_game_command(keeper,request_id,(leased->>'lease_token')::uuid,'game_social_state_changed');
  update private.conclave_weave_beacons set fragments=4990 where conclave_id=cid;
  leased:=public.begin_revisioned_game_command(keeper,gen_random_uuid(),'donate_beacon',payload,10080,rules,revision_before);
  if leased->>'failure_code'<>'game_action_unavailable' then raise exception 'beacon_contract_overflow'; end if;
  update private.conclave_weave_beacons set fragments=515 where conclave_id=cid;
  delete from public.conclave_members where user_id=keeper;
  leased:=public.begin_revisioned_game_command(keeper,gen_random_uuid(),'donate_beacon',payload,10080,rules,revision_before);
  if leased->>'failure_code'<>'game_action_unavailable' then raise exception 'beacon_contract_membership'; end if;
  update public.player_economy_authority set authority_mode='server' where user_id=keeper;
  perform set_config('request.jwt.claim.role','authenticated',true);
  begin
    perform public.egg_altar_command('legacy-probe','donate',payload);
    raise exception 'beacon_contract_legacy_mutation';
  exception when others then if sqlerrm<>'economy_server_inventory_required' then raise; end if; end;
end $$;
rollback;
select true as canonical_beacon_contract_passed;
