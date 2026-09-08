-- Synthetic accounts, switches, rewards and assertions all roll back.
begin;
do $$
declare keeper uuid := gen_random_uuid(); other_keeper uuid := gen_random_uuid();
  ids uuid[]; request_id uuid := gen_random_uuid(); result jsonb; replay jsonb;
  before_coins bigint; before_gems bigint; before_ledger bigint; reserved_id uuid;
  probe uuid; rules jsonb; tier text; i integer; test_request uuid; item jsonb; relic_name text;
begin
  insert into auth.users(id, email, email_confirmed_at) values
    (keeper, keeper::text || '@economy-contract.invalid', now()),
    (other_keeper, other_keeper::text || '@economy-contract.invalid', now());
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  perform public.ensure_my_online_account();
  perform set_config('request.jwt.claim.sub', other_keeper::text, true);
  perform public.ensure_my_online_account();
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  if (select mutations_enabled from private.economy_contract) then
    raise exception 'contract_requires_dormant_server';
  end if;
  begin
    perform public.open_chest_instances(request_id, array[gen_random_uuid()], 1, 10066);
    raise exception 'contract_disabled_gate_missing';
  exception when others then if sqlerrm <> 'economy_mutations_disabled' then raise; end if; end;
  if has_function_privilege('anon', 'public.open_chest_instances(uuid,uuid[],integer,integer)', 'execute')
    or has_function_privilege('authenticated', 'private.economy_chest_roll(text,boolean,double precision[])', 'execute')
    or has_function_privilege('authenticated', 'public.synchronize_trade_inventory_v45(jsonb)', 'execute')
    or has_function_privilege('authenticated', 'public.import_legacy_inventory_v45(jsonb)', 'execute')
    or has_table_privilege('authenticated', 'private.economy_egg_details', 'select') then
    raise exception 'contract_permissions';
  end if;
  if jsonb_array_length(private.economy_relic_drop_pool(other_keeper)) <> 64 then
    raise exception 'contract_relic_pool_weight_total'; end if;
  foreach relic_name in array array['moralPrism','orderCompass','soulMirror','astralLens','chronoshard','wayfinderSigil'] loop
    if (select count(*) from jsonb_array_elements_text(private.economy_relic_drop_pool(other_keeper)) r(value)
      where r.value = relic_name) <> 10 then raise exception 'contract_ordinary_relic_weight'; end if;
  end loop;
  foreach relic_name in array array['twinstarBrooch','emberheartBrooch','moonweaveBrooch','soulbloomBrooch'] loop
    if (select count(*) from jsonb_array_elements_text(private.economy_relic_drop_pool(other_keeper)) r(value)
      where r.value = relic_name) <> 1 then raise exception 'contract_brooch_weight'; end if;
  end loop;
  -- Exact probability edges, pity, rarity, Sinister and independent rolls.
  foreach tier in array array['wooden','silver','gold','dragon','mythical','sinister'] loop
    rules := private.economy_chest_catalog()->'tiers'->tier;
    result := private.economy_chest_roll(tier, false, array[0,0,0,0,0,0]::double precision[]);
    if not (result->>'egg')::boolean or result->>'rarity' <> 'common' then raise exception 'contract_roll_low'; end if;
    result := private.economy_chest_roll(tier, false, array[.999999,.999999,.999999,.999999,.999999,.999999]);
    if result->>'rarity' <> 'mythical' or (result->>'sinister')::boolean then raise exception 'contract_roll_high'; end if;
    if tier in ('wooden','silver','gold') then
      result := private.economy_chest_roll(tier, true, array[.9,
        (rules->>'egg_chance')::double precision * 3 - .000001,.9,.9,.9,.9]);
      replay := private.economy_chest_roll(tier, true, array[.9,
        (rules->>'egg_chance')::double precision * 3,.9,.9,.9,.9]);
      if not (result->>'egg')::boolean or (replay->>'egg')::boolean then raise exception 'contract_pity_boundary'; end if;
    end if;
  end loop;
  result := private.economy_chest_roll('sinister', false, array[.9,.9,.9,.119999,.499999,.55]);
  replay := private.economy_chest_roll('sinister', false, array[.9,.9,.9,.12,.5,.55]);
  if not (result->>'sinister')::boolean or (replay->>'sinister')::boolean
    or not (result->>'emote')::boolean or (replay->>'emote')::boolean
    or not (result->>'relic')::boolean or result->>'rarity' <> 'veryRare' then
    raise exception 'contract_sinister_boundaries';
  end if;
  update private.economy_contract set mutations_enabled = true;
  update public.player_economy_authority set authority_mode = 'server', activated_at = now() where user_id = keeper;
  -- Import/restore must not overwrite a server wallet or resurrect an item.
  begin
    perform public.synchronize_trade_inventory('{"eggs":[],"coins":999999}');
    raise exception 'contract_server_sync_allowed';
  exception when others then if sqlerrm <> 'economy_server_inventory_required' then raise; end if; end;
  begin
    perform public.import_legacy_inventory('{"coins":999999}');
    raise exception 'contract_server_import_allowed';
  exception when others then if sqlerrm <> 'economy_server_inventory_required' then raise; end if; end;
  -- One mixed batch covers every chest branch, including exact Special rewards.
  with added as (
    insert into public.player_chest_instances(owner_id, tier, source_type, special_chest_id)
    select keeper, value, 'system', case when value = 'special' then 'witchlight_chest_v1' end
    from unnest(array['wooden','silver','gold','dragon','mythical','sinister','special','portrait','title','music']) value
    returning id
  ) select array_agg(id) into ids from added;
  select coins, gems into before_coins, before_gems from public.player_wallets where user_id = keeper;
  result := public.open_chest_instances(request_id, ids, 1, 10066);
  replay := public.open_chest_instances(request_id, ids, 1, 10066);
  if result <> replay or jsonb_array_length(result->'chests') <> 10 then raise exception 'contract_request_replay'; end if;
  if (result->>'coins')::bigint <> before_coins +
      (select sum((value->>'coins')::bigint) from jsonb_array_elements(result->'chests'))
    or (result->>'gems')::bigint <> before_gems +
      (select sum((value->>'gems')::bigint) from jsonb_array_elements(result->'chests')) then
    raise exception 'contract_wallet_conservation';
  end if;
  for item in select value from jsonb_array_elements(result->'chests') loop
    tier := item->>'tier'; rules := private.economy_chest_catalog()->'tiers'->tier;
    if rules is not null and ((item->>'coins')::integer not between
        (rules->>'coins_min')::integer and (rules->>'coins_max')::integer
      or (item->>'gems')::integer > (rules->>'gems_max')::integer) then raise exception 'contract_reward_range'; end if;
    if tier = 'special' and (item->>'coins' <> '313' or item->>'gems' <> '13'
      or item->'egg'->>'special_egg_id' <> 'witchlight_egg_v1'
      or item->'egg'->>'incubation_seconds' <> '47593') then raise exception 'contract_special_reward'; end if;
    if item->'egg' ? 'lineage' or item->'egg' ? 'hatch_seed' or item->'egg' ? 'moral' then raise exception 'contract_hidden_identity_leaked'; end if;
  end loop;
  if (select count(*) from public.player_chest_instances where owner_id = keeper and state = 'opened') <> 10
    or (select count(*) from public.economy_ledger_entries where owner_id = keeper and mutation_type = 'consume') <> 10
    or (select count(*) from public.player_eggs where owner_id = keeper) < 4 then raise exception 'contract_atomic_grants'; end if;
  select count(*) into before_ledger from public.economy_ledger_entries where owner_id = keeper;
  replay := public.open_chest_instances(gen_random_uuid(), ids, 1, 10066);
  if replay <> result or (select count(*) from public.economy_ledger_entries where owner_id = keeper) <> before_ledger then
    raise exception 'contract_new_id_rerolled';
  end if;
  begin
    perform public.open_chest_instances(request_id, array[ids[1]], 1, 10066);
    raise exception 'contract_payload_change_allowed';
  exception when others then if sqlerrm <> 'economy_idempotency_conflict' then raise; end if; end;
  begin
    perform public.open_chest_instances(gen_random_uuid(), array[ids[1],ids[1]], 1, 10066);
    raise exception 'contract_duplicate_ids_allowed';
  exception when others then if sqlerrm <> 'economy_chest_request_invalid' then raise; end if; end;
  insert into public.player_chest_instances(owner_id, tier, source_type, state)
    values(keeper, 'gold', 'system', 'reserved') returning id into reserved_id;
  insert into public.player_chest_instances(owner_id, tier, source_type)
    values(keeper, 'dragon', 'system') returning id into probe;
  begin
    perform public.open_chest_instances(gen_random_uuid(), array[probe,reserved_id], 1, 10066);
    raise exception 'contract_reserved_chest_allowed';
  exception when others then if sqlerrm <> 'economy_chest_reserved' then raise; end if; end;
  if (select state from public.player_chest_instances where id = probe) <> 'owned'
    or (select count(*) from public.economy_ledger_entries where owner_id = keeper) <> before_ledger then
    raise exception 'contract_batch_partial_commit';
  end if;
  insert into public.player_chest_instances(owner_id, tier, source_type)
    values(other_keeper, 'gold', 'system') returning id into reserved_id;
  begin
    perform public.open_chest_instances(gen_random_uuid(), array[reserved_id], 1, 10066);
    raise exception 'contract_other_owner_allowed';
  exception when others then if sqlerrm <> 'economy_chest_not_owned' then raise; end if; end;
  -- Full collection preserves its chest and does not create a duplicate.
  insert into private.economy_unique_acquisitions(owner_id, item_kind, catalog_id)
    select keeper, 'portrait', value from jsonb_array_elements_text(private.economy_chest_catalog()->'portrait')
    on conflict do nothing;
  insert into public.player_chest_instances(owner_id, tier, source_type)
    values(keeper, 'portrait', 'system') returning id into reserved_id;
  replay := public.open_chest_instances(gen_random_uuid(), array[reserved_id], 1, 10066);
  if replay->'chests'->0->>'outcome' <> 'collection_complete'
    or (select state from public.player_chest_instances where id = reserved_id) <> 'owned' then
    raise exception 'contract_full_collection_consumed';
  end if;
  -- Exhaust all but one title: selection is deterministic and never repeats.
  insert into private.economy_unique_acquisitions(owner_id, item_kind, catalog_id)
    select keeper, 'title', value from jsonb_array_elements_text(private.economy_chest_catalog()->'title')
    where value <> 'title_500' on conflict do nothing;
  -- If the random batch already awarded title_500, use a fresh account pool.
  if not exists(select 1 from public.player_item_instances where owner_id = keeper and catalog_id = 'title_500') then
    insert into public.player_chest_instances(owner_id, tier, source_type)
      values(keeper, 'title', 'system') returning id into reserved_id;
    replay := public.open_chest_instances(gen_random_uuid(), array[reserved_id], 1, 10066);
    if replay->'chests'->0->'items'->0->>'catalog_id' <> 'title_500' then raise exception 'contract_unique_pool'; end if;
  end if;
  -- Exercise fixed percentages and lifetime uniqueness without probabilistic tests.
  test_request := gen_random_uuid();
  perform private.begin_economy_mutation(test_request, 'contract.grants', 1, 10066, '{}');
  item := private.economy_grant_chest_item(keeper, test_request, probe, 'relic', 'chronoshard');
  if (item->>'reduction_percent')::integer not between 10 and 90
    or (select metadata->>'reduction_percent' from public.player_item_instances where id = (item->>'instance_id')::uuid)
      <> item->>'reduction_percent' then raise exception 'contract_fixed_chronoshard'; end if;
  if jsonb_array_length(private.economy_remaining_pool(keeper, 'relic', '["twinstarBrooch"]')) = 1 then
    item := private.economy_grant_chest_item(keeper, test_request, probe, 'relic', 'twinstarBrooch');
  end if;
  update public.player_item_instances set state = 'consumed', consumed_at = now()
    where owner_id = keeper and catalog_id = 'twinstarBrooch';
  if jsonb_array_length(private.economy_remaining_pool(keeper, 'relic', '["twinstarBrooch"]')) <> 0 then
    raise exception 'contract_twinstar_regranted';
  end if;
  foreach relic_name in array array['emberheartBrooch','moonweaveBrooch','soulbloomBrooch'] loop
    if jsonb_array_length(private.economy_remaining_pool(keeper, 'relic', jsonb_build_array(relic_name))) = 1 then
      item := private.economy_grant_chest_item(keeper, test_request, probe, 'relic', relic_name);
    end if;
    if exists(select 1 from public.player_item_instances where owner_id = keeper and catalog_id = relic_name and tradeable) then
      raise exception 'contract_brooch_tradeable'; end if;
    update public.player_item_instances set state = 'consumed', consumed_at = now()
      where owner_id = keeper and catalog_id = relic_name;
    if private.economy_relic_drop_pool(keeper) ? relic_name then raise exception 'contract_brooch_regranted'; end if;
  end loop;
  perform private.complete_economy_mutation(keeper, test_request, '{"ok":true}');
end;
$$;
rollback;
select true as chest_opening_contract_passed;
