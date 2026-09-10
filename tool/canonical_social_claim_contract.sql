begin;
set local statement_timeout = '45s';
do $$
declare keeper uuid := gen_random_uuid(); partner uuid := gen_random_uuid();
  outsider uuid := gen_random_uuid(); dragon uuid := gen_random_uuid(); other_dragon uuid := gen_random_uuid();
  lobby uuid := gen_random_uuid(); pair_id uuid := gen_random_uuid(); prize_id uuid := gen_random_uuid();
  command_id uuid; leased jsonb; retried jsonb; receipt jsonb; result_value jsonb;
  source_state jsonb; next_state jsonb; facts jsonb; rules text := repeat('a5',32);
  revision bigint := 1; original_wallet jsonb; action_value text; source_id uuid; payload_value jsonb;
begin
  if (select enabled or shadow_social_enabled from private.game_engine_runtime where singleton) then
    raise exception 'social_claim_contract_requires_dormant'; end if;
  if has_function_privilege('authenticated','private.canonical_social_claim_context(uuid,text,jsonb,timestamptz)','execute')
    or has_function_privilege('service_role','private.commit_canonical_social_claim(uuid,text,jsonb,jsonb,jsonb,timestamptz)','execute')
    or has_table_privilege('authenticated','private.canonical_game_intents','select') then
    raise exception 'social_claim_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text||'@social-claim-contract.invalid',now()),
    (partner,partner::text||'@social-claim-contract.invalid',now()),
    (outsider,outsider::text||'@social-claim-contract.invalid',now());
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  perform public.ensure_my_online_account();
  select to_jsonb(w) into original_wallet from public.player_wallets w where user_id=keeper;
  perform set_config('request.jwt.claim.sub',partner::text,true);
  perform public.ensure_my_online_account();
  perform set_config('request.jwt.claim.sub',outsider::text,true);
  perform public.ensure_my_online_account();
  insert into public.player_dragons(id,owner_id,legacy_client_id,name,lineage_id,stage) values
    (dragon,keeper,'claim-dragon','Claim Probe','copperflame','hatchling'),
    (other_dragon,partner,'partner-dragon','Partner Probe','copperflame','hatchling');
  insert into public.group_adventure_lobbies(id,slot,adventure_id,owner_id,status,required_players,
    focus,base_duration_minutes,xp,stat_points,started_at,ends_at,chest_tier)
    values(lobby,0,'group_1',keeper,'running',2,'spirit',60,400,5,
      now()-interval '2 hours',now()-interval '1 hour','dragon');
  insert into public.group_adventure_participants(lobby_id,user_id,dragon_id)
    values(lobby,keeper,dragon),(lobby,partner,other_dragon);
  insert into public.seasonal_pair_adventures(id,occurrence_key,creator_id,partner_id,
    creator_dragon_id,partner_dragon_id,creator_might,creator_arcana,creator_spirit,
    partner_might,partner_arcana,partner_spirit,status,started_at,ends_at)
    values(pair_id,'valentine_two_heartlights:synthetic',keeper,partner,
      'claim-dragon','partner-dragon',10,10,10,10,10,10,'running',
      now()-interval '2 hours',now()-interval '1 hour');
  insert into public.seasonal_event_prizes(id,event_id,occurrence_key,user_id,ranking_position,score,podium_emote_id)
    values(prize_id,'sunwake_summer_sea','sunwake_summer_sea:synthetic',keeper,1,30000,'seasonal_sunwake_gold');
  source_state := '{"schemaVersion":54,"pet":{"id":"claim-dragon","coins":1000,"gems":10},
    "eggStash":[],"sanctuaryDragons":[],"releasedDragons":[],"chestInventory":{"dragon":0},
    "specialChestInventory":{},"relicInventory":{},"untradeableRelicInventory":{}}'::jsonb;
  insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
    values(keeper,1,source_state,'synthetic-social-claim','0.5.30',54),
      (outsider,1,source_state,'synthetic-social-claim','0.5.30',54);
  perform set_config('request.jwt.claim.role','service_role',true);
  perform public.stage_canonical_game_copy(keeper,1,private.game_json_sha256(source_state));
  perform public.stage_canonical_game_copy(outsider,1,private.game_json_sha256(source_state));
  update private.canonical_game_states set is_prepared=true where owner_id in (keeper,outsider);
  update private.game_engine_runtime set enabled=true,ruleset_sha256=rules where singleton;
  -- An ordinary shadow copy cannot consume a live social reward.
  leased := public.begin_revisioned_game_command(keeper,gen_random_uuid(),'claim_group_reward',
    jsonb_build_object('lobbyId',lobby),10080,rules,revision);
  if leased->>'failure_code' <> 'game_social_claim_unavailable' then
    raise exception 'social_claim_contract_shadow_isolation'; end if;
  update private.game_engine_runtime set shadow_social_enabled=true where singleton;
  if jsonb_array_length(public.read_canonical_game_state(keeper,10080,rules)->'social_claims') <> 3
    or public.read_canonical_game_state(outsider,10080,rules)->'social_claims' <> '[]'::jsonb then
    raise exception 'social_claim_contract_visible_offers'; end if;
  -- All three source lookups are owner-bound before evaluation begins.
  for action_value,source_id in select * from (values
      ('claim_group_reward',lobby),('claim_pair_reward',pair_id),('claim_podium_prize',prize_id)) as sources(a,s) loop
    payload_value := jsonb_build_object(case action_value when 'claim_group_reward' then 'lobbyId'
      when 'claim_pair_reward' then 'adventureId' else 'prizeId' end,source_id);
    leased := public.begin_revisioned_game_command(outsider,gen_random_uuid(),action_value,payload_value,10080,rules,1);
    if leased->>'failure_code' <> 'game_social_claim_unavailable' then
      raise exception 'social_claim_contract_foreign_source'; end if;
  end loop;
  -- Future journeys cannot be claimed by advancing a client clock.
  update public.group_adventure_lobbies set ends_at=now()+interval '1 hour' where id=lobby;
  leased := public.begin_revisioned_game_command(keeper,gen_random_uuid(),'claim_group_reward',
    jsonb_build_object('lobbyId',lobby),10080,rules,revision);
  if leased->>'failure_code' <> 'game_social_claim_unavailable' then
    raise exception 'social_claim_contract_early_claim'; end if;
  update public.group_adventure_lobbies set ends_at=now()-interval '1 hour' where id=lobby;
  command_id := gen_random_uuid();
  payload_value := jsonb_build_object('lobbyId',lobby);
  leased := public.begin_revisioned_game_command(keeper,command_id,'claim_group_reward',payload_value,10080,rules,revision);
  facts := leased->'social_context';
  if facts->>'ownerId' <> keeper::text or facts->>'sourceId' <> lobby::text
    or facts->'facts'->>'xp' <> '400' or facts->'facts'->>'dragonId' <> 'claim-dragon'
    or facts->'facts'->>'participantCount' <> '2' or length(facts->>'fingerprint') <> 64 then
    raise exception 'social_claim_contract_sealed_facts'; end if;
  -- A retry keeps the original sealed facts. A changed source then causes an
  -- atomic refusal, not a payout derived from a different reward or recipient.
  update private.canonical_game_intents set leased_until=now()-interval '1 second'
    where owner_id=keeper and canonical_game_intents.request_id=command_id;
  update public.group_adventure_lobbies set xp=401 where id=lobby;
  retried := public.begin_revisioned_game_command(keeper,command_id,'claim_group_reward',payload_value,10080,rules,revision);
  if retried->'social_context' <> facts then raise exception 'social_claim_contract_retry_changed_facts'; end if;
  result_value := jsonb_build_object('accepted',true,'alreadyApplied',false,'sourceId',lobby);
  next_state := jsonb_set(source_state,'{chestInventory,dragon}','1');
  begin
    perform public.commit_canonical_game_command(keeper,command_id,(retried->>'lease_token')::uuid,next_state,result_value);
    raise exception 'social_claim_contract_changed_source_committed';
  exception when others then if sqlerrm <> 'game_social_state_changed' then raise; end if; end;
  if (select state from private.canonical_game_states where owner_id=keeper) <> source_state
    or (select reward_acknowledged_at from public.group_adventure_participants where lobby_id=lobby and user_id=keeper) is not null then
    raise exception 'social_claim_contract_partial_commit'; end if;
  perform public.fail_canonical_game_command(keeper,command_id,(retried->>'lease_token')::uuid,'game_social_state_changed');
  update public.group_adventure_lobbies set xp=400 where id=lobby;
  for action_value,source_id in select * from (values
      ('claim_group_reward',lobby),('claim_pair_reward',pair_id),('claim_podium_prize',prize_id)) as sources(a,s) loop
    command_id := gen_random_uuid();
    payload_value := jsonb_build_object(case action_value when 'claim_group_reward' then 'lobbyId'
      when 'claim_pair_reward' then 'adventureId' else 'prizeId' end,source_id);
    leased := public.begin_revisioned_game_command(keeper,command_id,action_value,payload_value,10080,rules,revision);
    result_value := jsonb_build_object('accepted',true,'alreadyApplied',false,'sourceId',source_id);
    -- Domain reward amounts are verified by the Dart/JS and real Edge tests.
    -- This transaction checks exactly-once inventory/source commit semantics.
    next_state := jsonb_set(source_state,'{chestInventory,dragon}',to_jsonb(revision));
    begin
      perform public.commit_canonical_game_command(keeper,command_id,(leased->>'lease_token')::uuid,next_state,
        result_value || jsonb_build_object('sourceId',outsider));
      raise exception 'social_claim_contract_wrong_source_receipt';
    exception when others then if sqlerrm <> 'game_social_state_changed' then raise; end if; end;
    receipt := public.commit_canonical_game_command(keeper,command_id,(leased->>'lease_token')::uuid,next_state,result_value);
    if receipt->>'server_revision' <> (revision+1)::text then raise exception 'social_claim_contract_revision'; end if;
    if public.commit_canonical_game_command(keeper,command_id,(leased->>'lease_token')::uuid,next_state,result_value) <> receipt then
      raise exception 'social_claim_contract_commit_replay'; end if;
    retried := public.begin_revisioned_game_command(keeper,command_id,action_value,payload_value,10080,rules,revision);
    if retried->>'status' <> 'succeeded' or retried ? 'social_context' then raise exception 'social_claim_contract_receipt_replay'; end if;
    revision := revision+1;
    retried := public.begin_revisioned_game_command(keeper,gen_random_uuid(),action_value,payload_value,10080,rules,revision);
    if retried->>'failure_code' <> 'game_social_claim_unavailable' then raise exception 'social_claim_contract_second_payout'; end if;
  end loop;
  if (select reward_acknowledged_at from public.group_adventure_participants where lobby_id=lobby and user_id=keeper) is null
    or (select reward_acknowledged_at from public.group_adventure_participants where lobby_id=lobby and user_id=partner) is not null
    or not exists(select 1 from public.seasonal_pair_adventures where id=pair_id and creator_reward_claimed_at is not null
      and partner_reward_claimed_at is null and status='reward_ready')
    or (select count(*) from public.social_notifications where entity_id=pair_id and kind='seasonal_pair_ready') <> 2
    or (select claimed_at from public.seasonal_event_prizes where id=prize_id) is null then
    raise exception 'social_claim_contract_source_acknowledgments'; end if;
  if public.read_canonical_game_state(keeper,10080,rules)->'social_claims' <> '[]'::jsonb then
    raise exception 'social_claim_contract_claimed_offer_visible'; end if;
  if (select state from public.cloud_game_saves where user_id=keeper) <> source_state
    or (select to_jsonb(w) from public.player_wallets w where user_id=keeper) <> original_wallet
    or (select authority_mode from public.player_economy_authority where user_id=keeper) <> 'legacy_client' then
    raise exception 'social_claim_contract_live_state'; end if;
end $$;
rollback;
select true as canonical_social_claim_contract_passed;
