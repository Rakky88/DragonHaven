begin;
set local statement_timeout='45s';
do $$
declare a uuid:=gen_random_uuid(); b uuid:=gen_random_uuid(); tid uuid; owner_value uuid;
  sa jsonb; sb jsonb; na jsonb; nb jsonb; leased jsonb; reply jsonb; receipt jsonb; replay jsonb;
  qa uuid:=gen_random_uuid(); qb uuid:=gen_random_uuid(); qc uuid:=gen_random_uuid(); payload jsonb;
  rules text:=repeat('e4',32); code_value text; revision_a bigint; revision_b bigint;
begin
  if (select enabled or shadow_social_enabled or shadow_projection_enabled or shadow_lifecycle_enabled from private.game_engine_runtime where singleton) then
    raise exception 'trade_contract_requires_dormant'; end if;
  if has_function_privilege('service_role','public.begin_revisioned_game_command_v73(uuid,uuid,text,jsonb,integer,text,bigint)','execute') or
      has_function_privilege('service_role','public.commit_canonical_game_command_v73(uuid,uuid,uuid,jsonb,jsonb)','execute') or
      has_function_privilege('authenticated','public.commit_canonical_trade_command(uuid,uuid,uuid,jsonb,jsonb,jsonb,jsonb)','execute') then
    raise exception 'trade_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values(a,a::text||'@trade-contract.invalid',now()),(b,b::text||'@trade-contract.invalid',now());
  foreach owner_value in array array[a,b] loop
    perform set_config('request.jwt.claim.role','authenticated',true);perform set_config('request.jwt.claim.sub',owner_value::text,true);
    perform public.ensure_my_online_account();
    sa:=jsonb_build_object('schemaVersion',54,'pet',jsonb_build_object('id','trade-dragon-'||owner_value::text,
      'name','Trade Keeper','stage','ascended','lineageId','copperflame','xp',3400,'coins',1000,'gems',10,
      'training',jsonb_build_object('might',300,'arcana',300,'spirit',300),'evolutionPath','might',
      'favorite',true,'spectral',false,'sinister',false,'trialHighScores','{}'::jsonb,'activeAdventureId',null),
      'eggStash','[]'::jsonb,'sanctuaryDragons','[]'::jsonb,'releasedDragons','[]'::jsonb,
      'chestInventory',jsonb_build_object('gold',case when owner_value=a then 2 else 0 end,'silver',case when owner_value=b then 3 else 0 end),
      'specialChestInventory','{}'::jsonb,'relicInventory','{}'::jsonb,'chronoshardReductions','[]'::jsonb,
      'untradeableRelicInventory','{}'::jsonb,'discoveredForms',jsonb_build_array('copperflame:ascended:might'),
      'prismaticForms','[]'::jsonb,'reservedOnlineTradeEggIds','[]'::jsonb,'reservedOnlineTradeChests','{}'::jsonb,'reservedOnlineTradeRelics','{}'::jsonb);
    insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
      values(owner_value,1,sa,'synthetic-trade','0.5.30',54);
    perform set_config('request.jwt.claim.role','service_role',true);
    perform public.stage_canonical_game_copy(owner_value,1,private.game_json_sha256(sa));
  end loop;
  update private.game_engine_runtime set enabled=true,ruleset_sha256=rules,shadow_projection_enabled=true,shadow_lifecycle_enabled=true where singleton;
  update private.canonical_game_states set is_prepared=true where owner_id in(a,b);
  insert into public.friendships(requester_id,addressee_id,status) values(a,b,'accepted');
  select keeper_code into code_value from public.profiles where user_id=b;
  select state into sa from private.canonical_game_states where owner_id=a;
  select state into sb from private.canonical_game_states where owner_id=b;
  payload:=jsonb_build_object('keeperCode',code_value,'kind','chest','key','gold','variant',0);
  leased:=public.begin_revisioned_game_command(a,qa,'offer_trade',payload,10080,rules,1);
  tid:=(leased->'social_context'->>'sourceId')::uuid;
  if tid is null or leased->'social_context'->'facts'->'sent' is distinct from
      jsonb_build_object('kind','chest','key','gold','variant',0,'data','{}'::jsonb) then raise exception 'trade_contract_sealed_offer'; end if;
  sa:=jsonb_set(sa,'{reservedOnlineTradeChests}',jsonb_build_object('gold',1));
  receipt:=public.commit_canonical_game_command(a,qa,(leased->>'lease_token')::uuid,sa,jsonb_build_object('tradeId',tid,'status','awaiting_recipient'));
  replay:=public.begin_revisioned_game_command(a,qa,'offer_trade',payload,10080,rules,1);
  if replay->'response' is distinct from receipt or (select count(*) from public.trades where id=tid)<>1 or
      (select initiator_item ? 'data' from public.trades where id=tid) then raise exception 'trade_contract_offer_replay'; end if;
  perform set_config('request.jwt.claim.role','authenticated',true);perform set_config('request.jwt.claim.sub',a::text,true);
  begin perform public.cancel_trade(tid);raise exception 'trade_contract_legacy_cancel_accepted';
  exception when others then if sqlerrm<>'economy_server_inventory_required' then raise; end if; end;
  perform set_config('request.jwt.claim.role','service_role',true);
  reply:=public.begin_revisioned_game_command(b,qb,'reply_trade',jsonb_build_object('tradeId',tid,'kind','chest','key','silver','variant',0),10080,rules,1);
  sb:=jsonb_set(sb,'{reservedOnlineTradeChests}',jsonb_build_object('silver',1));
  perform public.commit_canonical_game_command(b,qb,(reply->>'lease_token')::uuid,sb,jsonb_build_object('tradeId',tid,'status','awaiting_initiator'));
  leased:=public.begin_revisioned_game_command(a,qc,'confirm_trade',jsonb_build_object('tradeId',tid),10080,rules,2);
  if leased->'trade_counterparty'->>'owner_id'<>b::text or (leased->'trade_counterparty'->>'base_revision')::bigint<>2 then
    raise exception 'trade_contract_counterparty_lease'; end if;
  na:=sa||jsonb_build_object('chestInventory',jsonb_build_object('gold',1,'silver',1),'appliedOnlineTradeIds',jsonb_build_array(tid),
    'reservedOnlineTradeChests','{}'::jsonb);
  nb:=sb||jsonb_build_object('chestInventory',jsonb_build_object('gold',1,'silver',2),'appliedOnlineTradeIds',jsonb_build_array(tid),
    'reservedOnlineTradeChests','{}'::jsonb);
  -- The old one-owner commit and a forged second wallet must neither complete
  -- the trade nor leave a debit or receipt on the first account.
  begin
    update private.canonical_game_states set revision=revision+1 where owner_id=b;
    perform public.commit_canonical_trade_command(a,qc,(leased->>'lease_token')::uuid,na,
      jsonb_build_object('tradeId',tid,'status','completed'),nb,jsonb_build_object('tradeId',tid,'status','completed'));
    raise exception 'trade_contract_changed_counterparty_accepted';
  exception when others then if sqlerrm<>'game_social_state_changed' then raise; end if; end;
  begin perform public.commit_canonical_game_command(a,qc,(leased->>'lease_token')::uuid,na,jsonb_build_object('tradeId',tid,'status','completed'));
    raise exception 'trade_contract_single_commit_accepted';
  exception when others then if sqlerrm<>'game_social_state_changed' then raise; end if; end;
  begin perform public.commit_canonical_trade_command(a,qc,(leased->>'lease_token')::uuid,na,jsonb_build_object('tradeId',tid,'status','completed'),
      jsonb_set(nb,'{pet,coins}','99999'),jsonb_build_object('tradeId',tid,'status','completed'));
    raise exception 'trade_contract_counterparty_grant_accepted';
  exception when others then if sqlerrm<>'game_social_state_changed' then raise; end if; end;
  if (select revision from private.canonical_game_states where owner_id=a)<>2 or (select revision from private.canonical_game_states where owner_id=b)<>2 or
      (select status from public.trades where id=tid)<>'awaiting_initiator' then raise exception 'trade_contract_partial_commit'; end if;
  receipt:=public.commit_canonical_trade_command(a,qc,(leased->>'lease_token')::uuid,na,jsonb_build_object('tradeId',tid,'status','completed'),
      nb,jsonb_build_object('tradeId',tid,'status','completed'));
  replay:=public.begin_revisioned_game_command(a,qc,'confirm_trade',jsonb_build_object('tradeId',tid),10080,rules,2);
  if replay->'response' is distinct from receipt or (select revision from private.canonical_game_states where owner_id=a)<>3 or
      (select revision from private.canonical_game_states where owner_id=b)<>3 or
      (select count(*) from private.canonical_trade_settlements where trade_id=tid)<>2 or
      (select count(*) from public.trade_reservations where trade_id=tid)<>0 or
      (select state->'chestInventory' from private.canonical_game_states where owner_id=a)<>na->'chestInventory' or
      (select state->'chestInventory' from private.canonical_game_states where owner_id=b)<>nb->'chestInventory' then
    raise exception 'trade_contract_atomic_replay'; end if;
  -- A subsequent offer expires between its lease and commit. No reservation or
  -- revision change from that obsolete reply may survive.
  qa:=gen_random_uuid();qb:=gen_random_uuid();
  leased:=public.begin_revisioned_game_command(a,qa,'offer_trade',payload,10080,rules,3);tid:=(leased->'social_context'->>'sourceId')::uuid;
  na:=jsonb_set(na,'{reservedOnlineTradeChests}',jsonb_build_object('gold',1));
  perform public.commit_canonical_game_command(a,qa,(leased->>'lease_token')::uuid,na,jsonb_build_object('tradeId',tid,'status','awaiting_recipient'));
  reply:=public.begin_revisioned_game_command(b,qb,'reply_trade',jsonb_build_object('tradeId',tid,'kind','chest','key','silver','variant',0),10080,rules,3);
  update public.trades set expires_at=now()-interval '1 second' where id=tid;
  begin perform public.commit_canonical_game_command(b,qb,(reply->>'lease_token')::uuid,
      jsonb_set(nb,'{reservedOnlineTradeChests}',jsonb_build_object('silver',1)),jsonb_build_object('tradeId',tid,'status','awaiting_initiator'));
    raise exception 'trade_contract_expired_reply_accepted';
  exception when others then if sqlerrm<>'game_social_state_changed' then raise; end if; end;
  if (select revision from private.canonical_game_states where owner_id=b)<>3 or
      private.canonical_trade_reservations(a,clock_timestamp())->'items'<>'[]'::jsonb then raise exception 'trade_contract_expiry_rollback'; end if;
  perform public.fail_canonical_game_command(b,qb,(reply->>'lease_token')::uuid,'game_social_state_changed');
  -- Cascade cleanup must remove private items and settlement receipts too.
  delete from auth.users where id in(a,b);
  if exists(select 1 from private.canonical_trade_items where owner_id in(a,b)) or
      exists(select 1 from private.canonical_trade_settlements where owner_id in(a,b)) then raise exception 'trade_contract_cleanup'; end if;
end $$;
select true as canonical_trade_contract_passed;
rollback;
