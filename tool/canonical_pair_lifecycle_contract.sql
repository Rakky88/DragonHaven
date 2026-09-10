begin;
set local statement_timeout='45s';
create function pg_temp.pair_step(p_owner uuid,p_action text,p_payload jsonb)
returns jsonb language plpgsql as $$
declare g private.canonical_game_states%rowtype; leased jsonb; request_id uuid:=gen_random_uuid(); next_state jsonb;
begin
  select * into g from private.canonical_game_states where owner_id=p_owner;
  leased:=public.begin_revisioned_game_command(p_owner,request_id,p_action,p_payload,10080,repeat('b2',32),g.revision);
  if leased->>'status'<>'processing' then return leased; end if;
  next_state:=g.state;
  if p_action in ('invite_pair_adventure','accept_pair_adventure') then
    next_state:=jsonb_set(next_state,'{pet,activeAdventureId}',to_jsonb('online-seasonal:'||(leased->'social_context'->>'sourceId')));
  elsif p_action='cancel_pair_adventure' and leased->'social_context'->'facts'->>'dragonId' is not null then
    next_state:=jsonb_set(next_state,'{pet,activeAdventureId}','null');
  end if;
  return public.commit_canonical_game_command(p_owner,request_id,(leased->>'lease_token')::uuid,next_state,
    jsonb_build_object('accepted',true,'sourceId',leased->'social_context'->>'sourceId'));
end $$;
do $$
declare keepers uuid[]:=array[gen_random_uuid(),gen_random_uuid()];keeper uuid;index_value integer;source_state jsonb;
  rules text:=repeat('b2',32);target_code text;source_id uuid;request_id uuid;leased jsonb;result_value jsonb;
  request_payload jsonb;before_state jsonb;next_state jsonb;before_revision bigint;pair public.seasonal_pair_adventures%rowtype;
begin
  if (select enabled or shadow_social_enabled or shadow_projection_enabled or shadow_lifecycle_enabled
      from private.game_engine_runtime where singleton) then raise exception 'pair_lifecycle_contract_requires_dormant'; end if;
  if has_function_privilege('service_role','public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text)','execute')
      or has_function_privilege('service_role','private.canonical_pair_lifecycle_context(uuid,text,jsonb,timestamptz,uuid)','execute')
      or has_function_privilege('service_role','public.begin_revisioned_game_command_v71(uuid,uuid,text,jsonb,integer,text,bigint)','execute')
      or has_function_privilege('authenticated','private.canonical_pair_window(uuid,timestamptz)','execute') then
    raise exception 'pair_lifecycle_contract_permissions'; end if;
  for index_value in 1..2 loop
    keeper:=keepers[index_value];
    insert into auth.users(id,email,email_confirmed_at) values(keeper,keeper::text||'@pair-lifecycle-contract.invalid',now());
    perform set_config('request.jwt.claim.role','authenticated',true);
    perform set_config('request.jwt.claim.sub',keeper::text,true);
    perform public.ensure_my_online_account();
    source_state:=jsonb_build_object('schemaVersion',54,'pet',jsonb_build_object('id','crew-'||index_value,
      'name','Crew '||index_value,'stage','ascended','lineageId','copperflame','xp',3400,'coins',1000,'gems',10,
      'training',jsonb_build_object('might',300,'arcana',300,'spirit',300),'evolutionPath','might',
      'favorite',true,'spectral',false,'sinister',false,'trialHighScores','{}'::jsonb,'activeAdventureId',null),
      'eggStash','[]'::jsonb,'sanctuaryDragons','[]'::jsonb,'releasedDragons','[]'::jsonb,
      'chestInventory','{}'::jsonb,'specialChestInventory','{}'::jsonb,'relicInventory','{}'::jsonb,
      'untradeableRelicInventory','{}'::jsonb,'discoveredForms',jsonb_build_array('copperflame:ascended:might'),
      'prismaticForms','[]'::jsonb);
    insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
      values(keeper,1,source_state,'synthetic-group-lifecycle','0.5.30',54);
    perform set_config('request.jwt.claim.role','service_role',true);
    perform public.stage_canonical_game_copy(keeper,1,private.game_json_sha256(source_state));
    update private.canonical_game_states set is_prepared=true where owner_id=keeper;
  end loop;
  update private.game_engine_runtime set enabled=true,ruleset_sha256=rules,shadow_lifecycle_enabled=true,
    shadow_projection_enabled=true where singleton;
  update private.canonical_game_states set is_prepared=true where owner_id=any(keepers);
  if exists(select 1 from unnest(keepers) k where not private.canonical_group_keeper_ready(k)) then
    raise exception 'pair_lifecycle_contract_prepared_read_models'; end if;

  select keeper_code into target_code from public.profiles where user_id=keepers[2];
  insert into public.seasonal_event_previews(user_id,event_id,expires_at,activated_at)
    values(keepers[1],'valentine_two_heartlights',now()+interval '2 days',now());
  request_payload:=jsonb_build_object('keeperCode',target_code,'dragonId','crew-1');
  result_value:=pg_temp.pair_step(keepers[1],'invite_pair_adventure',request_payload);
  source_id:=(result_value->'result'->>'sourceId')::uuid;
  select * into pair from public.seasonal_pair_adventures where id=source_id;
  if pair.id is null or not pair.canonical_owned or not pair.simulated or pair.status<>'invited'
      or pair.creator_might<>300 or pair.creator_arcana<>300 or pair.creator_spirit<>300
      or (select count(*) from public.social_notifications where entity_id=source_id and kind='seasonal_pair_invite')<>1 then
    raise exception 'pair_lifecycle_contract_invite'; end if;
  result_value:=pg_temp.pair_step(keepers[1],'accept_pair_adventure',jsonb_build_object('adventureId',source_id,'dragonId','crew-1'));
  if result_value->>'failure_code'<>'game_action_unavailable' then raise exception 'pair_lifecycle_contract_wrong_role'; end if;
  -- Older shadow clients cannot insert unverified partner scores into this row.
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keepers[2]::text,true);
  begin
    perform public.respond_seasonal_pair_adventure(source_id,true,'crew-2',1,2,3);
    raise exception 'pair_lifecycle_contract_legacy_accept';
  exception when others then if sqlerrm<>'economy_server_inventory_required' then raise; end if; end;
  perform set_config('request.jwt.claim.role','service_role',true);
  result_value:=pg_temp.pair_step(keepers[2],'decline_pair_adventure',jsonb_build_object('adventureId',source_id));
  if result_value->'result'->>'accepted'<>'true'
      or private.canonical_social_reservations(keepers[1],now(),true)->'reservations'<>'[]'::jsonb then
    raise exception 'pair_lifecycle_contract_decline_releases_creator'; end if;
  result_value:=pg_temp.pair_step(keepers[1],'invite_pair_adventure',request_payload);
  source_id:=(result_value->'result'->>'sourceId')::uuid;
  result_value:=pg_temp.pair_step(keepers[2],'accept_pair_adventure',jsonb_build_object('adventureId',source_id,'dragonId','crew-2'));
  select * into pair from public.seasonal_pair_adventures where id=source_id;
  if result_value->'result'->>'accepted'<>'true' or pair.status<>'accepted' or pair.partner_might<>300
      or jsonb_array_length(private.canonical_social_reservations(keepers[2],now(),true)->'reservations')<>1 then
    raise exception 'pair_lifecycle_contract_accept'; end if;
  result_value:=pg_temp.pair_step(keepers[1],'cancel_pair_adventure',jsonb_build_object('adventureId',source_id));
  if result_value->'result'->>'accepted'<>'true'
      or private.canonical_social_reservations(keepers[2],now(),true)->'reservations'<>'[]'::jsonb then
    raise exception 'pair_lifecycle_contract_cancel_releases_partner'; end if;
  result_value:=pg_temp.pair_step(keepers[1],'invite_pair_adventure',request_payload);
  source_id:=(result_value->'result'->>'sourceId')::uuid;
  result_value:=pg_temp.pair_step(keepers[2],'accept_pair_adventure',jsonb_build_object('adventureId',source_id,'dragonId','crew-2'));
  request_id:=gen_random_uuid();
  select state,revision into before_state,before_revision from private.canonical_game_states where owner_id=keepers[1];
  leased:=public.begin_revisioned_game_command(keepers[1],request_id,'start_pair_adventure',jsonb_build_object('adventureId',source_id),10080,rules,before_revision);
  if leased->>'status'<>'processing' then raise exception 'pair_lifecycle_contract_start_lease'; end if;
  update public.seasonal_event_previews set expires_at=now()-interval '1 minute' where user_id=keepers[1];
  begin
    perform public.commit_canonical_game_command(keepers[1],request_id,(leased->>'lease_token')::uuid,before_state,
      jsonb_build_object('accepted',true,'sourceId',source_id));
    raise exception 'pair_lifecycle_contract_expired_window_committed';
  exception when others then if sqlerrm<>'game_social_state_changed' then raise; end if; end;
  if exists(select 1 from public.seasonal_pair_occurrences where adventure_id=source_id)
      or (select state from private.canonical_game_states where owner_id=keepers[1])<>before_state
      or (select revision from private.canonical_game_states where owner_id=keepers[1])<>before_revision then
    raise exception 'pair_lifecycle_contract_partial_start'; end if;
  perform public.fail_canonical_game_command(keepers[1],request_id,(leased->>'lease_token')::uuid,'game_social_state_changed');
  update public.seasonal_event_previews set expires_at=now()+interval '2 days' where user_id=keepers[1];
  result_value:=pg_temp.pair_step(keepers[1],'start_pair_adventure',jsonb_build_object('adventureId',source_id));
  select * into pair from public.seasonal_pair_adventures where id=source_id;
  if result_value->'result'->>'accepted'<>'true' or pair.status<>'running'
      or pair.ends_at-pair.started_at<>interval '24 hours'
      or (select count(*) from public.seasonal_pair_occurrences where adventure_id=source_id)<>2 then
    raise exception 'pair_lifecycle_contract_shared_start'; end if;
  result_value:=pg_temp.pair_step(keepers[1],'start_pair_adventure',jsonb_build_object('adventureId',source_id));
  if result_value->>'failure_code'<>'game_action_unavailable' then raise exception 'pair_lifecycle_contract_restart'; end if;
  result_value:=pg_temp.pair_step(keepers[2],'cancel_pair_adventure',jsonb_build_object('adventureId',source_id));
  if result_value->>'failure_code'<>'game_action_unavailable' then raise exception 'pair_lifecycle_contract_running_cancel'; end if;
  if exists(select 1 from private.canonical_game_states where owner_id=any(keepers)
      and ((state->'pet'->>'coins')::integer<>1000 or (state->'pet'->>'xp')::integer<>3400)) then
    raise exception 'pair_lifecycle_contract_unearned_reward'; end if;
end $$;
rollback;
select true as canonical_pair_lifecycle_contract_passed;
