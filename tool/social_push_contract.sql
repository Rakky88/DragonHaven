begin;
do $$
declare keeper uuid := gen_random_uuid(); outsider uuid := gen_random_uuid();
  installation uuid := gen_random_uuid(); notification uuid; second_notice uuid;
  device uuid; old_generation uuid; answer jsonb; jobs jsonb; job jsonb;
  token_a text := 'synthetic-token-a-' || gen_random_uuid()::text;
  token_b text := 'synthetic-token-b-' || gen_random_uuid()::text;
begin
  if (select enabled from private.push_runtime) then raise exception 'push_contract_requires_dormant_push'; end if;
  if private.dispatch_social_push_tick() <> 'disabled' then raise exception 'push_contract_disabled_tick'; end if;
  if has_function_privilege('anon','public.register_my_push_device(uuid,uuid,text,text,text[])','execute')
    or not has_function_privilege('authenticated','public.register_my_push_device(uuid,uuid,text,text,text[])','execute')
    or has_function_privilege('authenticated','public.lease_social_pushes(integer)','execute')
    or has_function_privilege('service_role','private.dispatch_social_push_tick()','execute')
    or has_table_privilege('authenticated','private.push_devices','select') then
    raise exception 'push_contract_permissions';
  end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text || '@push-contract.invalid',now()),
    (outsider,outsider::text || '@push-contract.invalid',now());
  perform set_config('request.jwt.claim.sub', outsider::text,true);
  perform public.ensure_my_online_account();
  perform set_config('request.jwt.claim.sub', keeper::text,true);
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform public.ensure_my_online_account();
  begin
    perform public.register_my_push_device(outsider,installation,token_a,'nl',array['friend_message']);
    raise exception 'push_contract_wrong_session_accepted';
  exception when others then if sqlerrm <> 'push_login_required' then raise; end if; end;
  answer := public.register_my_push_device(keeper,installation,token_a,'nl',array['friend_message']);
  if answer <> '{"registered":true,"delivery_enabled":false}'::jsonb then raise exception 'push_contract_disabled_registration'; end if;
  select id,generation into device,old_generation from private.push_devices where installation_id = installation;
  insert into public.social_notifications(user_id,kind,entity_id) values(keeper,'friend_message',gen_random_uuid()) returning id into notification;
  if exists(select 1 from private.social_push_outbox where notification_id = notification) then raise exception 'push_contract_disabled_enqueue'; end if;
  update private.push_runtime set enabled = true;
  if private.dispatch_social_push_tick() <> 'unconfigured' then raise exception 'push_contract_unconfigured_tick'; end if;
  insert into public.social_notifications(user_id,kind,entity_id) values(keeper,'friend_request',gen_random_uuid()) returning id into second_notice;
  if exists(select 1 from private.social_push_outbox where notification_id = second_notice) then raise exception 'push_contract_preferences'; end if;
  insert into public.social_notifications(user_id,kind,entity_id) values(keeper,'friend_message',gen_random_uuid()) returning id into notification;
  if (select count(*) from private.social_push_outbox where notification_id = notification) <> 1 then raise exception 'push_contract_enqueue'; end if;
  begin
    perform public.lease_social_pushes();
    raise exception 'push_contract_player_leased';
  exception when others then if sqlerrm <> 'push_worker_required' then raise; end if; end;
  perform set_config('request.jwt.claim.role','service_role',true);
  jobs := public.lease_social_pushes(); job := jobs->0;
  if jsonb_array_length(jobs) <> 1 or job->>'token' <> token_a or job->>'language_code' <> 'nl' then
    raise exception 'push_contract_lease';
  end if;
  if public.lease_social_pushes() <> '[]'::jsonb then raise exception 'push_contract_duplicate_lease'; end if;
  if public.complete_social_push((job->>'job_id')::uuid,gen_random_uuid(),'accepted') then raise exception 'push_contract_stale_lease'; end if;
  perform public.complete_social_push((job->>'job_id')::uuid,(job->>'lease_token')::uuid,'retry',60);
  if public.lease_social_pushes() <> '[]'::jsonb then raise exception 'push_contract_retry_backoff'; end if;
  update private.social_push_outbox set next_attempt_at = now() where id = (job->>'job_id')::uuid;
  jobs := public.lease_social_pushes(); job := jobs->0;
  perform public.complete_social_push((job->>'job_id')::uuid,(job->>'lease_token')::uuid,'accepted');
  if (select acknowledged_at is not null from public.social_notifications where id = notification)
    or (select state <> 'accepted' from private.social_push_outbox where id = (job->>'job_id')::uuid) then
    raise exception 'push_contract_acceptance_not_read';
  end if;
  insert into public.social_notifications(user_id,kind,entity_id) values(keeper,'friend_message',gen_random_uuid()) returning id into second_notice;
  update public.social_notifications set acknowledged_at = now() where id = second_notice;
  if public.lease_social_pushes() <> '[]'::jsonb then raise exception 'push_contract_read_cancellation'; end if;
  insert into public.social_notifications(user_id,kind,entity_id) values(keeper,'friend_message',gen_random_uuid()) returning id into notification;
  jobs := public.lease_social_pushes(); job := jobs->0;
  perform public.register_my_push_device(keeper,installation,token_b,'nl',array['friend_message']);
  perform public.complete_social_push((job->>'job_id')::uuid,(job->>'lease_token')::uuid,'unregistered');
  if not exists(select 1 from private.push_devices where id = device and token = token_b and generation <> old_generation) then
    raise exception 'push_contract_rotation_protection';
  end if;
  perform set_config('request.jwt.claim.sub',outsider::text,true);
  perform public.unregister_my_push_device(installation);
  if not exists(select 1 from private.push_devices where id = device) then raise exception 'push_contract_owner_isolation'; end if;
  begin
    perform public.register_my_push_device(outsider,installation,token_a,'en',array['friend_message']);
    raise exception 'push_contract_installation_takeover';
  exception when others then if sqlerrm <> 'push_installation_owned' then raise; end if; end;
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  perform public.register_my_push_device(keeper,installation,token_b,'nl',array[]::text[]);
  insert into public.social_notifications(user_id,kind,entity_id) values(keeper,'friend_message',gen_random_uuid()) returning id into notification;
  if exists(select 1 from private.social_push_outbox where notification_id = notification) then raise exception 'push_contract_unsubscribed'; end if;
  perform public.register_my_push_device(keeper,installation,token_b,'nl',array['friend_message']);
  insert into public.social_notifications(user_id,kind,entity_id) values(keeper,'friend_message',gen_random_uuid()) returning id into notification;
  jobs := public.lease_social_pushes(); job := jobs->0;
  perform public.complete_social_push((job->>'job_id')::uuid,(job->>'lease_token')::uuid,'unregistered');
  if exists(select 1 from private.push_devices where id = device) then raise exception 'push_contract_invalid_token_cleanup'; end if;
  -- No HTTP call is made by this rehearsal, including when enabled but empty.
  update private.push_runtime set endpoint = 'https://vtmjkhzalalozpfnbvsd.supabase.co/functions/v1/dispatch-social-push';
  if private.dispatch_social_push_tick() <> 'empty' then raise exception 'push_contract_empty_tick'; end if;
  if exists(select 1 from private.push_dispatch_usage) then raise exception 'push_contract_unnecessary_invocation'; end if;
end;
$$;
rollback;
select true as social_push_contract_passed;
