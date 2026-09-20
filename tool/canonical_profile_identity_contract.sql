begin;
set local statement_timeout='40s';
do $$
declare keeper uuid:=gen_random_uuid();
begin
  if has_function_privilege('authenticated','private.project_canonical_profile_identity()','execute')
    or has_function_privilege('authenticated','private.guard_canonical_profile_identity()','execute')
  then raise exception 'profile_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values(keeper,keeper::text||'@profile-contract.invalid',now());
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform public.ensure_my_online_account();
  perform public.update_my_profile('Legacy Keeper','title_001','portrait_001');
  update public.player_economy_authority set authority_mode='server',protocol_version=2,
    server_revision=1,activated_at=now() where user_id=keeper;
  begin
    perform public.update_my_profile('Unauthorized replacement','title_002','portrait_002');
    raise exception 'profile_contract_old_client_write';
  exception when others then if sqlerrm<>'economy_server_inventory_required' then raise; end if; end;
  -- Social privacy flags and ordinary account bootstrap remain available.
  update public.profiles set friend_messages_allowed=false where user_id=keeper;
  perform public.ensure_my_online_account();
  if (select display_name from public.profiles where user_id=keeper)<>'Legacy Keeper' then
    raise exception 'profile_contract_identity_changed'; end if;
  perform set_config('request.jwt.claim.role','service_role',true);
  delete from auth.users where id=keeper;
end $$;
rollback;
select true as canonical_profile_identity_contract_passed;
