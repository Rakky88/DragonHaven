begin;
set local statement_timeout='40s';
do $$
declare keeper uuid:=gen_random_uuid();
begin
  if has_function_privilege('anon','public.synchronize_conclave_achievements(text[])','execute')
    or not has_function_privilege('authenticated','public.synchronize_conclave_achievements(text[])','execute')
  then raise exception 'achievement_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values(keeper,keeper::text||'@achievement-contract.invalid',now());
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform public.ensure_my_online_account();
  -- A legacy non-member can still synchronize without requiring a canonical save.
  if public.synchronize_conclave_achievements(array['hello_little_one'])<>0 then
    raise exception 'achievement_contract_legacy'; end if;
  update public.player_economy_authority set authority_mode='server',protocol_version=2,
    server_revision=1,activated_at=now() where user_id=keeper;
  begin
    perform public.synchronize_conclave_achievements(array['made_up_achievement']);
    raise exception 'achievement_contract_missing_state_accepted';
  exception when others then if sqlerrm<>'game_state_reconciliation_required' then raise; end if; end;
  perform set_config('request.jwt.claim.role','service_role',true);
  delete from auth.users where id=keeper;
end $$;
rollback;
select true as canonical_achievement_sharing_contract_passed;
