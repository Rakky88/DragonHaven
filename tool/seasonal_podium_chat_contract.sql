-- Synthetic accounts only. Staging rehearsal and post-apply verification roll back.
begin;
do $$
declare keeper uuid:=gen_random_uuid(); other_keeper uuid:=gen_random_uuid();
  group_id uuid:=gen_random_uuid(); other_group uuid:=gen_random_uuid();
  w record; a record; result record; eid text; game text; code text; j jsonb;
begin
  if has_table_privilege('authenticated','public.seasonal_conclave_projects','insert')
     or has_table_privilege('anon','public.seasonal_conclave_projects','select')
     or has_function_privilege('authenticated','private.seasonal_conclave_project_snapshot(uuid)','execute') then
    raise exception 'summer_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text||'@summer-contract.invalid',now()),
    (other_keeper,other_keeper::text||'@summer-contract.invalid',now());
  insert into public.conclaves(id,name,emblem_key,language,visibility,member_limit,created_by) values
    (group_id,'Summer '||left(group_id::text,8),'conclave_emblem_01','en','invite',4,keeper),
    (other_group,'Summer '||left(other_group::text,8),'conclave_emblem_02','en','invite',4,other_keeper);
  insert into public.conclave_members(conclave_id,user_id,role) values
    (group_id,keeper,'flightmaster'),(other_group,other_keeper,'flightmaster');
  perform set_config('request.jwt.claim.sub',keeper::text,true);

  insert into public.friendships(requester_id,addressee_id,status) values(keeper,other_keeper,'accepted');
  update public.profiles set friend_messages_allowed=true where user_id=other_keeper;
  foreach eid in array array['seasonal_sunwake_gold','seasonal_harvestmoon_silver','seasonal_pride_bronze'] loop
    perform public.send_conclave_message('emote','Podium',jsonb_build_object('emote_id',eid));
    perform public.send_friend_chat_message(other_keeper,'Podium','emote',jsonb_build_object('emote_id',eid));
    update public.friend_messages set created_at=now()-interval '2 seconds' where sender_id=keeper;
  end loop;
  begin
    perform public.send_conclave_message('emote','Nope','{"emote_id":"seasonal_unknown_gold"}');
    raise exception 'podium_contract_unknown_accepted';
  exception when others then if sqlerrm<>'message_invalid' then raise; end if; end;
  begin
    perform public.send_friend_chat_message(other_keeper,'Nope','emote','{"emote_id":"seasonal_sunwake_platinum"}');
    raise exception 'podium_contract_medal_accepted';
  exception when others then if sqlerrm<>'message_invalid' then raise; end if; end;
  update public.profiles set friend_messages_allowed=false where user_id=other_keeper;
  begin
    perform public.send_friend_chat_message(other_keeper,'Podium','emote','{"emote_id":"seasonal_sunwake_gold"}');
    raise exception 'podium_contract_preference_bypassed';
  exception when others then if sqlerrm<>'messages_disabled' then raise; end if; end;
end $$;
rollback;
select true as podium_contract_passed;
