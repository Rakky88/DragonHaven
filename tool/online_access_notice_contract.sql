begin;
do $$
declare a uuid:=gen_random_uuid(); b uuid:=gen_random_uuid(); accepted_at timestamptz;
begin
  if has_function_privilege('anon','public.acknowledge_my_privacy_notice(text,boolean)','execute')
     or has_function_privilege('anon','public.get_my_online_session_status()','execute')
     or has_table_privilege('authenticated','private.account_privacy_acknowledgements','insert') then
    raise exception 'privacy_contract_permissions';
  end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (a,a::text||'@privacy-contract.invalid',now()),(b,b::text||'@privacy-contract.invalid',null);
  perform set_config('request.jwt.claim.sub',a::text,true);
  if public.get_my_privacy_acknowledgement() then raise exception 'privacy_contract_default'; end if;
  begin
    perform public.acknowledge_my_privacy_notice('2026-09-20',false);
    raise exception 'privacy_contract_underage';
  exception when others then if sqlerrm<>'privacy_confirmation_required' then raise; end if; end;
  begin
    perform public.acknowledge_my_privacy_notice('2026-09-20',null);
    raise exception 'privacy_contract_missing_age';
  exception when others then if sqlerrm<>'privacy_confirmation_required' then raise; end if; end;
  begin
    perform public.acknowledge_my_privacy_notice('obsolete',true);
    raise exception 'privacy_contract_version';
  exception when others then if sqlerrm<>'privacy_confirmation_required' then raise; end if; end;
  perform public.acknowledge_my_privacy_notice('2026-09-20',true);
  if not public.get_my_privacy_acknowledgement() then raise exception 'privacy_contract_ack'; end if;
  select acknowledged_at into accepted_at from private.account_privacy_acknowledgements where user_id=a;
  perform public.acknowledge_my_privacy_notice('2026-09-20',true);
  if not exists(select 1 from private.account_privacy_acknowledgements where user_id=a and acknowledged_at=accepted_at)
      then raise exception 'privacy_contract_idempotency'; end if;
  if public.get_my_online_session_status()->>'owner_id'<>a::text then raise exception 'privacy_contract_owner'; end if;
  perform set_config('request.jwt.claim.sub',b::text,true);
  begin
    perform public.get_my_online_session_status();
    raise exception 'privacy_contract_unverified';
  exception when others then if sqlerrm<>'online_login_required' then raise; end if; end;
  update auth.users set email_confirmed_at=now() where id=b;
  if public.get_my_privacy_acknowledgement() then raise exception 'privacy_contract_account_isolation'; end if;
  delete from auth.users where id=a;
  if exists(select 1 from private.account_privacy_acknowledgements where user_id=a)
      then raise exception 'privacy_contract_delete_cascade'; end if;
  perform set_config('request.jwt.claim.sub',a::text,true);
  begin
    perform public.get_my_online_session_status();
    raise exception 'privacy_contract_deleted_user';
  exception when others then if sqlerrm<>'online_login_required' then raise; end if; end;
end $$;
rollback;
select true as online_access_contract_passed;
