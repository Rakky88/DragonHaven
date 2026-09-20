begin;
set local statement_timeout='40s';
do $$
declare keeper uuid:=gen_random_uuid(); stranger uuid:=gen_random_uuid(); cid uuid:=gen_random_uuid();
  message uuid:=gen_random_uuid(); old_message uuid:=gen_random_uuid(); snapshot jsonb;
begin
  if has_table_privilege('authenticated','private.account_conclave_reads','select')
    or has_table_privilege('authenticated','private.account_conclave_reads','insert')
    or has_function_privilege('anon','public.mark_my_conclave_messages_read(uuid[])','execute')
  then raise exception 'read_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text||'@read-contract.invalid',now()),(stranger,stranger::text||'@read-contract.invalid',now());
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform public.ensure_my_online_account();
  insert into public.conclaves(id,name,emblem_key,language,visibility,member_limit,created_by)
    values(cid,'Read '||left(cid::text,20),'conclave_emblem_01','en','invite',4,keeper);
  insert into public.conclave_members(conclave_id,user_id,role) values(cid,keeper,'flightmaster');
  insert into public.conclave_messages(id,conclave_id,sender_id,kind,body,created_at) values
    (message,cid,keeper,'text','Synthetic read',now()-interval '1 minute'),
    (old_message,cid,keeper,'text','Synthetic expired',now()-interval '25 hours');
  perform set_config('request.jwt.claim.sub',stranger::text,true);
  perform public.mark_my_conclave_messages_read(array[message,old_message]);
  if exists(select 1 from private.account_conclave_reads where user_id=stranger) then raise exception 'read_contract_foreign'; end if;
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  perform public.mark_my_conclave_messages_read(array[message,old_message]);
  perform public.mark_my_conclave_messages_read(array[message]);
  snapshot:=public.get_my_conclave_snapshot();
  if snapshot->'read_message_ids'<>jsonb_build_array(message) then raise exception 'read_contract_restore'; end if;
  if (select count(*) from private.account_conclave_reads where user_id=keeper)<>1 then raise exception 'read_contract_duplicate'; end if;
  delete from public.conclave_messages where id=message;
  if exists(select 1 from private.account_conclave_reads where user_id=keeper) then raise exception 'read_contract_retention'; end if;
  perform set_config('request.jwt.claim.role','service_role',true);
  delete from auth.users where id in (keeper,stranger);
end $$;
rollback;
select true as account_conclave_reads_contract_passed;
