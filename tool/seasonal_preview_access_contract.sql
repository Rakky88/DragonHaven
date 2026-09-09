-- Synthetic verified/unverified accounts; all changes roll back on staging.
begin;
do $$
declare keeper uuid := gen_random_uuid(); stranger uuid := gen_random_uuid();
  unverified uuid := gen_random_uuid(); code text; first_expiry timestamptz;
  response record; stranger_expiry timestamptz;
begin
  if has_function_privilege('anon','public.redeem_seasonal_event_preview(text)','execute') or
     has_table_privilege('authenticated','public.seasonal_event_previews','insert') then
    raise exception 'preview_access_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text || '@preview-access-contract.invalid',now()),
    (stranger,stranger::text || '@preview-access-contract.invalid',now()),
    (unverified,unverified::text || '@preview-access-contract.invalid',null);
  perform set_config('request.jwt.claim.sub','',true);
  begin
    perform public.redeem_seasonal_event_preview('HALLOWEENEVENT');
    raise exception 'preview_access_contract_anonymous_accepted';
  exception when others then
    if sqlerrm <> 'online_login_required' then raise; end if;
  end;
  perform set_config('request.jwt.claim.sub',unverified::text,true);
  begin
    perform public.redeem_seasonal_event_preview('HALLOWEENEVENT');
    raise exception 'preview_access_contract_unverified_accepted';
  exception when others then
    if sqlerrm <> 'email_not_verified' then raise; end if;
  end;
  perform set_config('request.jwt.claim.sub',stranger::text,true);
  select p.expires_at into stranger_expiry from public.redeem_seasonal_event_preview('HALLOWEENEVENT') p;
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  begin
    perform public.redeem_seasonal_event_preview('INVALID');
    raise exception 'preview_access_contract_invalid_accepted';
  exception when others then
    if sqlerrm <> 'seasonal_preview_invalid' then raise; end if;
  end;
  foreach code in array array['HALLOWEENEVENT','CHRISTMASEVENT','NEWYEARSEVENT','VALENTINEEVENT','PRIDEFESTEVENT'] loop
    select * into response from public.redeem_seasonal_event_preview(code);
    first_expiry := response.expires_at;
    if first_expiry <> now() + interval '48 hours' or
      (select count(*) from public.list_my_seasonal_event_previews()) <> 1 or
      (select count(*) from public.seasonal_event_previews p where p.user_id=keeper) <> 1 then
      raise exception 'preview_access_contract_activation'; end if;
    select * into response from public.redeem_seasonal_event_preview(lower(code));
    if response.expires_at <> first_expiry then raise exception 'preview_access_contract_retry_extended'; end if;
    if (select p.expires_at from public.seasonal_event_previews p where p.user_id=stranger) <> stranger_expiry then
      raise exception 'preview_access_contract_other_account_changed'; end if;
  end loop;
end $$;
rollback;
select true as preview_access_contract_passed;
