begin;
set local statement_timeout = '45s';
do $$
declare keeper uuid:=gen_random_uuid(); partner uuid:=gen_random_uuid();
  dragon_one uuid:=gen_random_uuid(); dragon_two uuid:=gen_random_uuid(); partner_dragon uuid:=gen_random_uuid();
  lobby uuid:=gen_random_uuid(); pair_id uuid:=gen_random_uuid(); command_id uuid;
  source_state jsonb; rules text:=repeat('a9',32); leased jsonb; retried jsonb; bindings jsonb; receipt jsonb;
  payload_value jsonb; original_wallet jsonb; source_slot bigint:=private.group_adventure_slot(now());
begin
  if (select enabled or shadow_social_enabled or shadow_projection_enabled or shadow_lifecycle_enabled
      from private.game_engine_runtime where singleton) then
    raise exception 'social_reservation_contract_requires_dormant'; end if;
  if has_function_privilege('service_role','public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text)','execute')
      or has_function_privilege('authenticated','private.canonical_social_reservations(uuid,timestamptz,boolean)','execute')
      or has_function_privilege('service_role','public.begin_canonical_game_command_v68(uuid,uuid,text,jsonb,integer,text)','execute')
      or has_function_privilege('authenticated','public.respond_seasonal_pair_adventure_v68(uuid,boolean,text,integer,integer,integer)','execute') then
    raise exception 'social_reservation_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text||'@social-reservation-contract.invalid',now()),
    (partner,partner::text||'@social-reservation-contract.invalid',now());
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  perform public.ensure_my_online_account();
  select to_jsonb(w) into original_wallet from public.player_wallets w where user_id=keeper;
  perform set_config('request.jwt.claim.sub',partner::text,true);
  perform public.ensure_my_online_account();
  insert into public.player_dragons(id,owner_id,legacy_client_id,name,lineage_id,stage) values
    (dragon_one,keeper,'reserved-one','Reserved One','copperflame','hatchling'),
    (dragon_two,keeper,'reserved-two','Reserved Two','copperflame','hatchling'),
    (partner_dragon,partner,'partner-dragon','Partner','copperflame','hatchling');
  insert into public.group_adventure_lobbies(id,slot,adventure_id,owner_id,status,required_players,
      focus,base_duration_minutes,xp,stat_points)
    values(lobby,source_slot,private.group_adventure_id(source_slot),keeper,'waiting',2,'spirit',1440,400,5);
  insert into public.group_adventure_participants(lobby_id,user_id,dragon_id)
    values(lobby,keeper,dragon_one),(lobby,partner,partner_dragon);
  insert into public.seasonal_pair_adventures(id,occurrence_key,creator_id,partner_id,creator_dragon_id,
      creator_might,creator_arcana,creator_spirit)
    values(pair_id,'valentine_two_heartlights:synthetic',keeper,partner,'reserved-two',10,10,10);
  source_state:='{"schemaVersion":54,"pet":{"id":"reserved-one","coins":1000,"gems":10},
    "eggStash":[],"sanctuaryDragons":[],"releasedDragons":[],"chestInventory":{},
    "specialChestInventory":{},"relicInventory":{},"untradeableRelicInventory":{}}'::jsonb;
  insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
    values(keeper,1,source_state,'synthetic-reservation','0.5.30',54);
  perform set_config('request.jwt.claim.role','service_role',true);
  perform public.stage_canonical_game_copy(keeper,1,private.game_json_sha256(source_state));
  update private.canonical_game_states set is_prepared=true where owner_id=keeper;
  update private.game_engine_runtime set enabled=true,ruleset_sha256=rules where singleton;
  if private.canonical_social_reservations(keeper,now(),true) is not null then
    raise exception 'social_reservation_contract_shadow_isolation'; end if;
  -- Both the revisioned and internal compatibility entry points capture a
  -- null view while the feature is disabled, so existing command contracts work.
  command_id:=gen_random_uuid();
  leased:=public.begin_canonical_game_command(keeper,command_id,'refresh','{}',10080,rules);
  receipt:=public.commit_canonical_game_command(keeper,command_id,(leased->>'lease_token')::uuid,source_state,'true');
  if receipt->>'server_revision'<>'2' then raise exception 'social_reservation_contract_compatibility'; end if;
  update private.game_engine_runtime set shadow_lifecycle_enabled=true where singleton;
  bindings:=private.canonical_social_reservations(keeper,now(),true);
  if bindings->>'ownerId'<>keeper::text or bindings->>'version'<>'1'
      or bindings->'reservations'<>jsonb_build_array(
        jsonb_build_object('dragonId','reserved-one','kind','group','sourceId',lobby),
        jsonb_build_object('dragonId','reserved-two','kind','pair','sourceId',pair_id))
      or public.read_canonical_game_state(keeper,10080,rules)->'social_reservations'<>bindings then
    raise exception 'social_reservation_contract_owner_view'; end if;
  -- An old waiting slot expires; a running trip remains reserved across weeks.
  update public.group_adventure_lobbies set slot=source_slot-1 where id=lobby;
  if jsonb_array_length(private.canonical_social_reservations(keeper,now(),false)->'reservations')<>1 then
    raise exception 'social_reservation_contract_expired_waiting'; end if;
  update public.group_adventure_lobbies set slot=source_slot where id=lobby;
  command_id:=gen_random_uuid();
  leased:=public.begin_revisioned_game_command(keeper,command_id,'refresh','{}',10080,rules,2);
  if leased->'social_reservations'<>bindings then raise exception 'social_reservation_contract_lease'; end if;
  -- A lobby closure after a lease must not let an old evaluation commit.
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  perform public.leave_group_adventure_lobby(lobby);
  perform set_config('request.jwt.claim.role','service_role',true);
  update private.canonical_game_intents set leased_until=now()-interval '1 second'
    where owner_id=keeper and request_id=command_id;
  retried:=public.begin_revisioned_game_command(keeper,command_id,'refresh','{}',10080,rules,2);
  if retried->'social_reservations'<>bindings then raise exception 'social_reservation_contract_frozen_retry'; end if;
  begin
    perform public.commit_canonical_game_command(keeper,command_id,(retried->>'lease_token')::uuid,
      jsonb_set(source_state,'{pet,coins}','999'),'true');
    raise exception 'social_reservation_contract_stale_commit';
  exception when others then if sqlerrm<>'game_social_state_changed' then raise; end if; end;
  if (select state from private.canonical_game_states where owner_id=keeper)<>source_state
      or (select revision from private.canonical_game_states where owner_id=keeper)<>2 then
    raise exception 'social_reservation_contract_partial_commit'; end if;
  perform public.fail_canonical_game_command(keeper,command_id,(retried->>'lease_token')::uuid,'game_social_state_changed');
  -- A verified claim releases the source in the very transaction that grants
  -- the reward. Receipt replay still works after its source is acknowledged.
  update public.seasonal_pair_adventures set status='running',partner_dragon_id='partner-dragon',
    partner_might=10,partner_arcana=10,partner_spirit=10,started_at=now()-interval '2 hours',
    ends_at=now()-interval '1 hour' where id=pair_id;
  update private.game_engine_runtime set shadow_social_enabled=true where singleton;
  command_id:=gen_random_uuid(); payload_value:=jsonb_build_object('adventureId',pair_id);
  leased:=public.begin_revisioned_game_command(keeper,command_id,'claim_pair_reward',payload_value,10080,rules,2);
  receipt:=public.commit_canonical_game_command(keeper,command_id,(leased->>'lease_token')::uuid,source_state,
    jsonb_build_object('accepted',true,'sourceId',pair_id));
  if receipt->>'server_revision'<>'3'
      or private.canonical_social_reservations(keeper,now(),true)->'reservations'<>'[]'::jsonb
      or public.commit_canonical_game_command(keeper,command_id,(leased->>'lease_token')::uuid,source_state,
        jsonb_build_object('accepted',true,'sourceId',pair_id))<>receipt then
    raise exception 'social_reservation_contract_claim_release_replay'; end if;
  -- Old apps must not acknowledge an ungranted reward or invent a new social
  -- dragon snapshot after their keeper has moved to canonical ownership.
  update public.player_economy_authority set authority_mode='server',activated_at=now() where user_id=keeper;
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  begin
    perform public.acknowledge_seasonal_event_prize(gen_random_uuid());
    raise exception 'social_reservation_contract_old_prize_ack';
  exception when others then if sqlerrm<>'economy_server_inventory_required' then raise; end if; end;
  begin
    perform public.respond_seasonal_pair_adventure(pair_id,true,'invented',300,300,300);
    raise exception 'social_reservation_contract_old_pair_accept';
  exception when others then if sqlerrm<>'economy_server_inventory_required' then raise; end if; end;
  if (select to_jsonb(w) from public.player_wallets w where user_id=keeper)<>original_wallet
      or (select state from public.cloud_game_saves where user_id=keeper)<>source_state then
    raise exception 'social_reservation_contract_live_assets'; end if;
end $$;
rollback;
select true as canonical_social_reservation_contract_passed;
