-- Registered staging runner only. Entire fixture and all invitations roll back.
begin;
set local statement_timeout='30s';
do $$
declare keepers uuid[]:=array[gen_random_uuid(),gen_random_uuid(),gen_random_uuid()];
  keeper uuid; idx integer; source jsonb; progress jsonb; imported uuid;
  event_keys text[]; codes text[]; response jsonb; pair_id uuid; shared jsonb;
begin
  if (select enabled or migration_enabled or shadow_projection_enabled or
      shadow_social_enabled or shadow_lifecycle_enabled from private.game_engine_runtime where singleton) then
    raise exception 'event_points_contract_requires_dormant'; end if;
  if has_function_privilege('authenticated','private.event_point_state(uuid)','execute') or
      has_table_privilege('authenticated','private.event_point_pair_members','insert') then
    raise exception 'event_points_contract_permissions'; end if;
  for idx in 1..3 loop
    keeper:=keepers[idx];
    insert into auth.users(id,email,email_confirmed_at) values
      (keeper,keeper::text||'@event-points-contract.invalid',now());
    perform set_config('request.jwt.claim.sub',keeper::text,true);
    perform public.ensure_my_online_account();
    codes[idx]:=(select keeper_code from public.profiles where user_id=keeper);
    event_keys[idx]:='valentine_two_heartlights:preview:'||keeper;
    progress:=jsonb_build_object('key',event_keys[idx],'eventId','valentine_two_heartlights',
      'startsAt',now()-interval '1 hour','endsAt',now()+interval '1 hour',
      'target',4000,'chestId','twinheart_keepsake_chest_v1','points',idx*100,
      'partnerPoints',0,'claimed',false,'preview',true);
    source:=jsonb_build_object('schemaVersion',54,'eventProgress',jsonb_build_object(event_keys[idx],progress));
    insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
      values(keeper,1,jsonb_set(source,array['eventProgress',event_keys[idx],'points'],'999999'),
        'event-points-contract','0.05.35',54);
    if idx<=2 then
      insert into private.canonical_game_imports(owner_id,source_revision,source_sha256,source_state)
        values(keeper,1,private.game_json_sha256(source),source) returning import_id into imported;
      insert into private.canonical_game_states(owner_id,source_import_id,state,state_sha256,is_prepared,authority_mode)
        values(keeper,imported,source,private.game_json_sha256(source),true,'server');
    end if;
  end loop;
  insert into public.friendships(requester_id,addressee_id,status)
    values(keepers[1],keepers[2],'accepted'),(keepers[1],keepers[3],'accepted');
  perform set_config('request.jwt.claim.sub',keepers[1]::text,true);
  begin
    perform public.event_point_partner('invite',event_keys[1],codes[3]);
    raise exception 'event_points_contract_mixed_authority_accepted';
  exception when others then if sqlerrm<>'event_partner_unavailable' then raise; end if; end;
  response:=public.event_point_partner('invite',event_keys[1],codes[2]);
  pair_id:=(response->'pairs'->0->>'id')::uuid;
  perform set_config('request.jwt.claim.sub',keepers[2]::text,true);
  response:=public.event_point_partner('list',event_keys[2]);
  if response->'pairs'->0->>'eventKey'<>event_keys[2] or
      (response->'pairs'->0->>'incoming')::boolean is not true then
    raise exception 'event_points_contract_personal_preview_missing'; end if;
  response:=public.event_point_partner('accept',event_keys[2],null,pair_id);
  shared:=response->'shared'->'progress'->0;
  if shared is null or shared->>'key'<>event_keys[2] or (shared->>'points')::bigint<>200 or
      (shared->>'partnerPoints')::bigint<>100 or (shared->>'claimed')::boolean then
    raise exception 'event_points_contract_cloud_or_foreign_points_used'; end if;
  -- The other member sees new authoritative points without receiving ownership.
  update private.canonical_game_states set
    state=jsonb_set(state,array['eventProgress',event_keys[2],'points'],'300'),
    state_sha256=private.game_json_sha256(jsonb_set(state,array['eventProgress',event_keys[2],'points'],'300')),
    revision=revision+1
    where owner_id=keepers[2];
  perform set_config('request.jwt.claim.sub',keepers[1]::text,true);
  response:=public.event_point_partner('list',event_keys[1]);
  shared:=response->'shared'->'progress'->0;
  if shared is null or (shared->>'points')::bigint<>100 or (shared->>'partnerPoints')::bigint<>300 then
    raise exception 'event_points_contract_server_refresh_missing'; end if;
  if (select count(*) from private.event_point_pair_members where owner_id=any(keepers[1:2])) <> 2 then
    raise exception 'event_points_contract_members_missing'; end if;
  if exists(select 1 from private.event_point_pair_members where owner_id=keepers[3]) then
    raise exception 'event_points_contract_other_account_changed'; end if;
end $$;
rollback;
select true as canonical_event_points_passed;
