begin;
set local statement_timeout = '45s';

-- Domain binding and no-grant semantics are separately replayed in Dart/JS.
-- This synthetic evaluator exercises the real lease/commit SQL boundary.
create function pg_temp.group_step(p_owner uuid,p_action text,p_payload jsonb)
returns jsonb language plpgsql as $$
declare g private.canonical_game_states%rowtype; leased jsonb; request_id uuid:=gen_random_uuid();
  source_id text; next_state jsonb;
begin
  select * into g from private.canonical_game_states where owner_id=p_owner;
  leased:=public.begin_revisioned_game_command(p_owner,request_id,p_action,p_payload,10080,repeat('b1',32),g.revision);
  if leased->>'status'<>'processing' then return leased; end if;
  source_id:=leased->'social_context'->>'sourceId'; next_state:=g.state;
  if p_action in ('create_group_adventure','join_group_adventure') then
    next_state:=jsonb_set(next_state,'{pet,activeAdventureId}',to_jsonb('online-group:'||source_id));
  elsif p_action='leave_group_adventure' then next_state:=jsonb_set(next_state,'{pet,activeAdventureId}','null'); end if;
  return public.commit_canonical_game_command(p_owner,request_id,(leased->>'lease_token')::uuid,next_state,
    jsonb_build_object('accepted',true,'sourceId',source_id));
end $$;

do $$
declare keepers uuid[]:=array[gen_random_uuid(),gen_random_uuid(),gen_random_uuid(),gen_random_uuid()];
  keeper uuid; index_value integer; source_state jsonb; current_state jsonb; next_state jsonb;
  rules text:=repeat('b1',32); adventure text:=private.group_adventure_id(private.group_adventure_slot(now()));
  target_lobby uuid; payload_value jsonb; result_value jsonb; leased jsonb; receipt jsonb; retried jsonb;
  request_value uuid; revision_value bigint;
  expected_index integer:=substring(adventure from 7)::integer-1; running public.group_adventure_lobbies%rowtype;
begin
  if (select enabled or shadow_social_enabled or shadow_projection_enabled or shadow_lifecycle_enabled
      from private.game_engine_runtime where singleton) then raise exception 'group_lifecycle_contract_requires_dormant'; end if;
  if has_function_privilege('service_role','public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text)','execute')
      or has_function_privilege('authenticated','private.canonical_group_keeper_ready(uuid)','execute')
      or has_function_privilege('service_role','public.begin_revisioned_game_command_v70(uuid,uuid,text,jsonb,integer,text,bigint)','execute')
      or has_function_privilege('service_role','private.commit_canonical_group_lifecycle(uuid,text,jsonb,jsonb,jsonb,timestamptz)','execute') then
    raise exception 'group_lifecycle_contract_permissions'; end if;
  for index_value in 1..4 loop
    keeper:=keepers[index_value];
    insert into auth.users(id,email,email_confirmed_at) values(keeper,keeper::text||'@group-lifecycle-contract.invalid',now());
    perform set_config('request.jwt.claim.role','authenticated',true);
    perform set_config('request.jwt.claim.sub',keeper::text,true);
    perform public.ensure_my_online_account();
    source_state:=jsonb_build_object('schemaVersion',54,'pet',jsonb_build_object('id','crew-'||index_value,
      'name','Crew '||index_value,'stage','ascended','lineageId','copperflame','xp',3400,'coins',1000,'gems',10,
      'training',jsonb_build_object('might',300,'arcana',300,'spirit',300),'evolutionPath','mastery',
      'favorite',true,'spectral',false,'sinister',false,'trialHighScores','{}'::jsonb,'activeAdventureId',null),
      'eggStash','[]'::jsonb,'sanctuaryDragons','[]'::jsonb,'releasedDragons','[]'::jsonb,
      'chestInventory','{}'::jsonb,'specialChestInventory','{}'::jsonb,'relicInventory','{}'::jsonb,
      'untradeableRelicInventory','{}'::jsonb,'discoveredForms',jsonb_build_array('copperflame:ascended:mastery'),
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
    raise exception 'group_lifecycle_contract_prepared_read_models'; end if;
  for index_value in 2..4 loop
    insert into public.friendships(requester_id,addressee_id,status) values(keepers[1],keepers[index_value],'accepted');
  end loop;
  -- A sealed create has no effect until a matching commit succeeds.
  request_value:=gen_random_uuid(); payload_value:=jsonb_build_object('adventureId',adventure,'dragonId','crew-1');
  leased:=public.begin_revisioned_game_command(keepers[1],request_value,'create_group_adventure',payload_value,10080,rules,1);
  target_lobby:=(leased->'social_context'->>'sourceId')::uuid;
  if target_lobby is null or exists(select 1 from public.group_adventure_lobbies where id=target_lobby) then
    raise exception 'group_lifecycle_contract_prepare_mutated_source'; end if;
  select state into current_state from private.canonical_game_states where owner_id=keepers[1];
  next_state:=jsonb_set(current_state,'{pet,activeAdventureId}',to_jsonb('online-group:'||target_lobby::text));
  begin
    perform public.commit_canonical_game_command(keepers[1],request_value,(leased->>'lease_token')::uuid,next_state,
      jsonb_build_object('accepted',true,'sourceId',keepers[4]));
    raise exception 'group_lifecycle_contract_wrong_receipt';
  exception when others then if sqlerrm<>'game_social_state_changed' then raise; end if; end;
  if (select state from private.canonical_game_states where owner_id=keepers[1])<>current_state
      or (select revision from public.player_wallets where user_id=keepers[1])<>1
      or exists(select 1 from public.group_adventure_lobbies where id=target_lobby) then
    raise exception 'group_lifecycle_contract_partial_create'; end if;
  result_value:=jsonb_build_object('accepted',true,'sourceId',target_lobby);
  receipt:=public.commit_canonical_game_command(keepers[1],request_value,(leased->>'lease_token')::uuid,next_state,result_value);
  retried:=public.begin_revisioned_game_command(keepers[1],request_value,'create_group_adventure',payload_value,10080,rules,1);
  if retried->>'status'<>'succeeded' or retried->'response'<>receipt
      or (select count(*) from public.group_adventure_participants p where p.lobby_id=target_lobby)=0 then
    raise exception 'group_lifecycle_contract_create_replay'; end if;
  select * into running from public.group_adventure_lobbies l where l.id=target_lobby;
  if not running.canonical_owned or running.status<>'waiting'
      or running.required_players<>2+expected_index%3
      or running.xp<>360+(3+expected_index%4)*175+expected_index%59
      or running.stat_points<>52+(3+expected_index%4)*13+expected_index%9 then
    raise exception 'group_lifecycle_contract_catalog_terms'; end if;
  -- Keep four places for deterministic leave/kick coverage regardless of the
  -- actual weekly catalog entry. This changes only this rollback fixture.
  update public.group_adventure_lobbies l set required_players=4,combined_level_required=0 where l.id=target_lobby;
  result_value:=pg_temp.group_step(keepers[2],'join_group_adventure',jsonb_build_object('lobbyId',target_lobby,'dragonId','crew-2'));
  if result_value->'result'->>'accepted'<>'true' then raise exception 'group_lifecycle_contract_join'; end if;
  result_value:=pg_temp.group_step(keepers[1],'remove_group_adventure_member',jsonb_build_object('lobbyId',target_lobby,'memberId',keepers[2]));
  if result_value->'result'->>'accepted'<>'true'
      or private.canonical_social_reservations(keepers[2],now(),true)->'reservations'<>'[]'::jsonb then
    raise exception 'group_lifecycle_contract_kick_reservation'; end if;
  -- A removed member may rejoin despite its old local binding. New external
  -- source facts supersede that stale field before Dart evaluates the command.
  result_value:=pg_temp.group_step(keepers[2],'join_group_adventure',jsonb_build_object('lobbyId',target_lobby,'dragonId','crew-2'));
  if result_value->'result'->>'accepted'<>'true' then raise exception 'group_lifecycle_contract_rejoin'; end if;
  result_value:=pg_temp.group_step(keepers[3],'join_group_adventure',jsonb_build_object('lobbyId',target_lobby,'dragonId','crew-3'));
  result_value:=pg_temp.group_step(keepers[3],'leave_group_adventure',jsonb_build_object('lobbyId',target_lobby));
  if result_value->'result'->>'accepted'<>'true'
      or private.canonical_social_reservations(keepers[3],now(),true)->'reservations'<>'[]'::jsonb then
    raise exception 'group_lifecycle_contract_leave'; end if;
  -- Losing friendship between prepare and commit refuses the whole join.
  select revision,state into revision_value,current_state from private.canonical_game_states where owner_id=keepers[3];
  request_value:=gen_random_uuid(); payload_value:=jsonb_build_object('lobbyId',target_lobby,'dragonId','crew-3');
  leased:=public.begin_revisioned_game_command(keepers[3],request_value,'join_group_adventure',payload_value,10080,rules,revision_value);
  update public.friendships set status='declined' where requester_id=keepers[1] and addressee_id=keepers[3];
  begin
    perform public.commit_canonical_game_command(keepers[3],request_value,(leased->>'lease_token')::uuid,
      jsonb_set(current_state,'{pet,activeAdventureId}',to_jsonb('online-group:'||target_lobby::text)),
      jsonb_build_object('accepted',true,'sourceId',target_lobby));
    raise exception 'group_lifecycle_contract_changed_friendship_committed';
  exception when others then if sqlerrm<>'game_social_state_changed' then raise; end if; end;
  perform public.fail_canonical_game_command(keepers[3],request_value,(leased->>'lease_token')::uuid,'game_social_state_changed');
  update public.friendships set status='accepted' where requester_id=keepers[1] and addressee_id=keepers[3];
  result_value:=pg_temp.group_step(keepers[3],'join_group_adventure',payload_value);
  result_value:=pg_temp.group_step(keepers[4],'join_group_adventure',jsonb_build_object('lobbyId',target_lobby,'dragonId','crew-4'));
  select * into running from public.group_adventure_lobbies l where l.id=target_lobby;
  if result_value->'result'->>'accepted'<>'true' or running.status<>'running'
      or running.ends_at-running.started_at<>interval '24 hours' or running.chest_tier not in ('gold','dragon','mythical') then
    raise exception 'group_lifecycle_contract_shared_start'; end if;
  result_value:=pg_temp.group_step(keepers[1],'leave_group_adventure',jsonb_build_object('lobbyId',target_lobby));
  if result_value->>'failure_code'<>'game_action_unavailable' then raise exception 'group_lifecycle_contract_running_leave'; end if;
  -- Read-side clock maintenance remains compatible, but old clients cannot
  -- submit dragon snapshots or edit a canonical group's membership directly.
  update public.group_adventure_lobbies l set started_at=now()-interval '25 hours',ends_at=now()-interval '1 hour' where l.id=target_lobby;
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keepers[2]::text,true);
  perform private.refresh_group_adventures();
  if not exists(select 1 from public.group_adventure_lobbies l where l.id=target_lobby and status='completed') then
    raise exception 'group_lifecycle_contract_legacy_clock_maintenance'; end if;
  begin
    delete from public.group_adventure_participants p where p.lobby_id=target_lobby and p.user_id=keepers[2];
    raise exception 'group_lifecycle_contract_legacy_member_write';
  exception when others then if sqlerrm<>'economy_server_inventory_required' then raise; end if; end;
  if exists(select 1 from private.canonical_game_states where owner_id=any(keepers)
      and ((state->'pet'->>'coins')::integer<>1000 or (state->'pet'->>'xp')::integer<>3400)) then
    raise exception 'group_lifecycle_contract_unearned_rewards'; end if;
end $$;
rollback;
select true as canonical_group_lifecycle_contract_passed;
