begin;
set local statement_timeout='40s';
update private.game_engine_runtime set shadow_projection_enabled=false where singleton;
do $$
declare keeper uuid:=gen_random_uuid(); source_state jsonb; original_wallet jsonb; chosen_id uuid; request_id uuid:=gen_random_uuid(); leased jsonb; receipt jsonb; rules text;
begin
 insert into auth.users(id,email,email_confirmed_at) values(keeper,keeper::text||'@hatch-contract.invalid',now());
 perform set_config('request.jwt.claim.sub',keeper::text,true);
 perform set_config('request.jwt.claim.role','authenticated',true);
 perform public.ensure_my_online_account();
 select to_jsonb(w) into original_wallet from public.player_wallets w where user_id=keeper;
  source_state := '{"schemaVersion":54,
    "pet":{"id":"mirror-one","name":"Mirror One","stage":"ascended","lineageId":"copperflame",
      "xp":1000,"coins":12345,"gems":987,"training":{"might":310,"arcana":32,"spirit":43},
      "evolutionPath":"might","favorite":true,"spectral":true,"sinister":false,
      "trialHighScores":{"cavernFlight":234,"ruinBreaker":345,"runeweaver":456}},
    "sanctuaryDragons":[{"id":"mirror-two","name":"Mirror Two","stage":"hatchling","lineageId":"copperflame",
      "xp":25,"coins":999999,"gems":999999,"training":{"might":1,"arcana":2,"spirit":3},
      "evolutionPath":null,"favorite":false,"spectral":false,"sinister":false,
      "trialHighScores":{"cavernFlight":567,"ruinBreaker":45,"runeweaver":67}}],
    "eggStash":[],"releasedDragons":[],"chestInventory":{},"specialChestInventory":{},
    "relicInventory":{},"untradeableRelicInventory":{},
    "discoveredForms":["copperflame:hatchling","copperflame:ascended:might"],
    "prismaticForms":["copperflame:ascended:might"]}'::jsonb;
  insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
    values(keeper,1,source_state,'synthetic-social-projection','0.5.30',54);
  perform set_config('request.jwt.claim.role','service_role',true);
  perform public.stage_canonical_game_copy(keeper,1,private.game_json_sha256(source_state));
  update private.canonical_game_states set is_prepared=true where owner_id=keeper;
  if exists(select 1 from private.canonical_social_projections where owner_id=keeper)
      or (select to_jsonb(w) from public.player_wallets w where user_id=keeper)<>original_wallet then
    raise exception 'social_projection_contract_shadow_isolation'; end if;

 -- Reproduce both unnamed ordinary hatch and unnamed favourite/first hatch.
 source_state:=jsonb_set(source_state,'{pet,name}','""');
 source_state:=jsonb_set(source_state,'{sanctuaryDragons,0,name}','""');
 update private.game_engine_runtime set enabled=true,shadow_projection_enabled=true,ruleset_sha256=coalesce(ruleset_sha256,repeat('a6',32)) where singleton;
 select ruleset_sha256 into rules from private.game_engine_runtime where singleton;
 leased:=public.begin_revisioned_game_command(keeper,request_id,'hatch_egg','{"eggId":"mirror-one"}',10094,rules,1);
 receipt:=public.commit_canonical_game_command(keeper,request_id,(leased->>'lease_token')::uuid,source_state,'true');
 if receipt->>'server_revision'<>'2' or public.commit_canonical_game_command(keeper,request_id,(leased->>'lease_token')::uuid,source_state,'true')<>receipt then
   raise exception 'unnamed_hatch_replay_failed'; end if;
 if (select count(*) from public.player_dragons where owner_id=keeper and name='Unnamed dragon')<>2
   or (select favorite_dragon_name from public.social_showcases where user_id=keeper)<>'Unnamed dragon'
   or (select state#>>'{pet,name}' from private.canonical_game_states where owner_id=keeper)<>'' then
   raise exception 'unnamed_hatch_projection_failed'; end if;
 select id into chosen_id from public.player_dragons where owner_id=keeper and legacy_client_id='mirror-one';
 source_state:=jsonb_set(source_state,'{pet,name}','"First Light"');
 update private.canonical_game_states set state=source_state,state_sha256=private.game_json_sha256(source_state),revision=revision+1 where owner_id=keeper;
 if not exists(select 1 from public.player_dragons where id=chosen_id and name='First Light')
   or (select favorite_dragon_name from public.social_showcases where user_id=keeper)<>'First Light' then
   raise exception 'unnamed_hatch_first_name_failed'; end if;
 if (select coins from public.player_wallets where user_id=keeper)<>12345 then raise exception 'unnamed_hatch_wallet_changed'; end if;
end $$;
rollback;
select true as canonical_unnamed_hatch_contract_passed;
