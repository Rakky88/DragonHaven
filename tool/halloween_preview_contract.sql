begin;
do $$
declare keeper uuid := gen_random_uuid(); unverified uuid := gen_random_uuid();
  result record; original_expiry timestamptz; wallet_before jsonb; probe text;
begin
  if has_function_privilege('anon', 'public.redeem_seasonal_event_preview(text)', 'execute') then
    raise exception 'preview_contract_anonymous_access';
  end if;
  insert into auth.users(id, email, email_confirmed_at) values
    (keeper, keeper::text || '@preview-contract.invalid', now()),
    (unverified, unverified::text || '@preview-contract.invalid', null);
  perform set_config('request.jwt.claim.sub', unverified::text, true);
  begin
    perform public.redeem_seasonal_event_preview('HALLOWEENEVENT');
    raise exception 'preview_contract_unverified_accepted';
  exception when others then if sqlerrm <> 'email_not_verified' then raise; end if; end;
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  perform public.ensure_my_online_account();
  if (select keeper_code from public.profiles where user_id = keeper) = 'DH-17792DC5' then
    raise exception 'preview_contract_requires_ordinary_keeper';
  end if;
  select to_jsonb(w) into wallet_before from public.player_wallets w where user_id = keeper;
  select * into result from public.redeem_seasonal_event_preview('HALLOWEENEVENT');
  if result.event_id <> 'halloween_witchlight' or result.expires_at <> now() + interval '48 hours' then
    raise exception 'preview_contract_public_entitlement';
  end if;
  -- Simulate an already-running preview. A retry cannot renew its 48 hours.
  update public.seasonal_event_previews set expires_at = now() + interval '1 hour' where user_id = keeper;
  select * into result from public.redeem_seasonal_event_preview('HALLOWEENEVENT');
  if result.expires_at <> now() + interval '1 hour' then
    raise exception 'preview_contract_retry_extended_window';
  end if;
  update public.seasonal_event_previews set activated_at = now() - interval '3 days',
    expires_at = now() - interval '1 day' where user_id = keeper;
  select * into result from public.redeem_seasonal_event_preview('HALLOWEENEVENT');
  if result.expires_at <> now() + interval '48 hours' then
    raise exception 'preview_contract_expired_not_reusable';
  end if;
  foreach probe in array array['CHRISTMASEVENT','NEWYEARSEVENT','VALENTINEEVENT','PRIDEFESTEVENT'] loop
    begin
      perform public.redeem_seasonal_event_preview(probe);
      raise exception 'preview_contract_other_event_unlocked';
    exception when others then if sqlerrm <> 'seasonal_preview_restricted' then raise; end if; end;
  end loop;
  begin
    perform public.redeem_seasonal_event_preview('NOTACODE');
    raise exception 'preview_contract_unknown_accepted';
  exception when others then if sqlerrm <> 'seasonal_preview_invalid' then raise; end if; end;
  if (select count(*) from public.seasonal_event_previews where user_id = keeper) <> 1
    or (select to_jsonb(w) from public.player_wallets w where user_id = keeper) <> wallet_before
    or exists(select 1 from public.player_eggs where owner_id = keeper)
    or exists(select 1 from public.player_chests where owner_id = keeper and quantity > 0)
    or exists(select 1 from public.player_item_instances where owner_id = keeper)
    or exists(select 1 from public.economy_ledger_entries where owner_id = keeper) then
    raise exception 'preview_contract_unexpected_permanent_reward';
  end if;
end;
$$;
rollback;
select true as halloween_preview_contract_passed;
