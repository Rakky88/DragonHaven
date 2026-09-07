begin;
do $$
declare keeper uuid := gen_random_uuid(); request_id uuid := gen_random_uuid();
  result jsonb; again jsonb; probe text; balance bigint; entries bigint;
begin
  insert into auth.users(id, email, email_confirmed_at)
    values(keeper, keeper::text || '@shop-contract.invalid', now());
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  perform public.ensure_my_online_account();
  begin
    perform public.purchase_economy_item(request_id, 'furniture', 'moss_cushion', 1, 10066);
    raise exception 'shop_contract_disabled_gate';
  exception when others then if sqlerrm <> 'economy_mutations_disabled' then raise; end if; end;
  if has_function_privilege('anon', 'public.purchase_economy_item(uuid,text,text,integer,integer)', 'execute')
    or has_function_privilege('authenticated', 'private.economy_shop_catalog()', 'execute') then
    raise exception 'shop_contract_permissions';
  end if;
  update private.economy_contract set mutations_enabled = true;
  update public.player_economy_authority set authority_mode = 'server', activated_at = now() where user_id = keeper;
  update public.player_wallets set coins = 10000, gems = 1000 where user_id = keeper;
  result := public.purchase_economy_item(request_id, 'furniture', 'moss_cushion', 1, 10066);
  again := public.purchase_economy_item(request_id, 'furniture', 'moss_cushion', 1, 10066);
  if result <> again or result->>'outcome' <> 'purchased' or result->>'price' <> '120'
    or result->>'coins' <> '9880' or result->>'gems' <> '1000'
    or (select count(*) from public.player_item_instances where owner_id = keeper) <> 1
    or (select count(*) from public.economy_ledger_entries where owner_id = keeper) <> 2 then
    raise exception 'shop_contract_atomic_purchase';
  end if;
  again := public.purchase_economy_item(gen_random_uuid(), 'furniture', 'moss_cushion', 1, 10066);
  if again->>'outcome' <> 'already_owned' or again->>'instance_id' <> result->>'instance_id'
    or again->>'coins' <> '9880' then raise exception 'shop_contract_duplicate_furniture'; end if;
  begin
    perform public.purchase_economy_item(request_id, 'relic', 'astralLens', 1, 10066);
    raise exception 'shop_contract_conflicting_intent';
  exception when others then if sqlerrm <> 'economy_idempotency_conflict' then raise; end if; end;
  foreach probe in array array['chronoshard','twinstarBrooch','wayfinderSigil','weaveOracle','nameweaversQuill'] loop
    begin
      perform public.purchase_economy_item(gen_random_uuid(), 'relic', probe, 1, 10066);
      raise exception 'shop_contract_exclusive_bought';
    exception when others then if sqlerrm <> 'economy_shop_item_unknown' then raise; end if; end;
  end loop;
  begin
    perform public.purchase_economy_item(gen_random_uuid(), 'furniture', 'supporter_dragon_throne', 1, 10066);
    raise exception 'shop_contract_supporter_bought';
  exception when others then if sqlerrm <> 'economy_shop_item_unknown' then raise; end if; end;
  result := public.purchase_economy_item(gen_random_uuid(), 'relic', 'astralLens', 1, 10066);
  again := public.purchase_economy_item(gen_random_uuid(), 'relic', 'astralLens', 1, 10066);
  if result->>'gems' <> '500' or again->>'gems' <> '0' or result->>'instance_id' = again->>'instance_id'
    or exists(select 1 from public.player_item_instances where owner_id = keeper and item_kind = 'relic' and tradeable) then
    raise exception 'shop_contract_relic_price_or_tradeability';
  end if;
  request_id := gen_random_uuid();
  select count(*) into entries from public.economy_ledger_entries where owner_id = keeper;
  result := public.purchase_economy_item(request_id, 'relic', 'moralPrism', 1, 10066);
  if result->>'outcome' <> 'insufficient_funds' or result->>'instance_id' is not null
    or (select count(*) from public.economy_ledger_entries where owner_id = keeper) <> entries then
    raise exception 'shop_contract_insufficient_funds_mutated';
  end if;
  update public.player_wallets set gems = 500 where user_id = keeper;
  again := public.purchase_economy_item(request_id, 'relic', 'moralPrism', 1, 10066);
  if result <> again or (select gems from public.player_wallets where user_id = keeper) <> 500 then
    raise exception 'shop_contract_insufficient_replay_charged';
  end if;
end;
$$;
rollback;
select true as item_shop_contract_passed;
