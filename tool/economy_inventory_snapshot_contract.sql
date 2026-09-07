begin;
do $$
declare keeper uuid := gen_random_uuid(); outsider uuid := gen_random_uuid();
  page jsonb; next_page jsonb; cursor jsonb; request_id uuid := gen_random_uuid(); item uuid;
begin
  if (select mutations_enabled from private.economy_contract) then
    raise exception 'snapshot_contract_requires_dormant_economy';
  end if;
  if has_function_privilege('anon', 'public.get_my_economy_inventory_page(integer,integer,bigint,text,uuid,integer)', 'execute')
    or not has_function_privilege('authenticated', 'public.get_my_economy_inventory_page(integer,integer,bigint,text,uuid,integer)', 'execute') then
    raise exception 'snapshot_contract_permissions';
  end if;
  insert into auth.users(id, email, email_confirmed_at) values
    (keeper, keeper::text || '@snapshot-contract.invalid', now()),
    (outsider, outsider::text || '@snapshot-contract.invalid', now());
  perform set_config('request.jwt.claim.sub', outsider::text, true);
  perform public.ensure_my_online_account();
  insert into public.player_chest_instances(owner_id, tier, source_type)
    values(outsider, 'mythical', 'system');
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  perform public.ensure_my_online_account();
  begin
    perform public.get_my_economy_inventory_page(1, 10067);
    raise exception 'snapshot_contract_legacy_accepted';
  exception when others then if sqlerrm <> 'economy_server_inventory_required' then raise; end if; end;
  update public.player_economy_authority set authority_mode = 'server', activated_at = now(), server_revision = 7 where user_id = keeper;
  update public.player_wallets set coins = 321, gems = 17, revision = 4 where user_id = keeper;
  -- A stopped mutation service must still allow read-only reconciliation.
  page := public.get_my_economy_inventory_page(1, 10067);
  if page->'instances' <> '[]'::jsonb or page->'next_cursor' <> 'null'::jsonb
    or page->>'owner_id' <> keeper::text or page->>'coins' <> '321'
    or page->>'wallet_revision' <> '4' or page->>'server_revision' <> '7' then
    raise exception 'snapshot_contract_empty_or_owner_isolation';
  end if;
  begin
    perform public.get_my_economy_inventory_page(1, 1);
    raise exception 'snapshot_contract_old_client_accepted';
  exception when others then if sqlerrm <> 'economy_client_upgrade_required' then raise; end if; end;
  begin
    perform public.get_my_economy_inventory_page(1, 10067, null, 'chest', gen_random_uuid());
    raise exception 'snapshot_contract_unfenced_cursor_accepted';
  exception when others then if sqlerrm <> 'economy_request_invalid' then raise; end if; end;
  insert into public.player_chest_instances(owner_id, tier, source_type)
    select keeper, 'wooden', 'system' from generate_series(1, 101);
  insert into public.economy_mutation_requests(owner_id, request_id, operation, request_sha256, protocol_version, client_build)
    values(keeper, request_id, 'snapshot.probe', repeat('0', 64), 1, 10067);
  insert into public.player_chest_instances(owner_id, tier, state, source_type, opened_at, opened_request_id)
    values(keeper, 'gold', 'opened', 'system', now(), request_id);
  insert into public.player_item_instances(owner_id, item_kind, catalog_id, state, source_type, consumed_at)
    values(keeper, 'relic', 'astralLens', 'consumed', 'system', now());
  insert into public.player_item_instances(owner_id, item_kind, catalog_id, state, source_type, metadata)
    values(keeper, 'relic', 'chronoshard', 'reserved', 'system', '{"reduction_percent":47,"private_support_note":"must never appear"}') returning id into item;
  page := public.get_my_economy_inventory_page(1, 10067, null, null, null, 100);
  cursor := page->'next_cursor';
  if jsonb_array_length(page->'instances') <> 100 or cursor->>'kind' <> 'chest'
    or cursor->>'id' <> page->'instances'->99->>'id' then
    raise exception 'snapshot_contract_first_page';
  end if;
  next_page := public.get_my_economy_inventory_page(1, 10067, 7, cursor->>'kind', (cursor->>'id')::uuid, 100);
  if jsonb_array_length(next_page->'instances') <> 2 or next_page->'next_cursor' <> 'null'::jsonb
    or next_page->'instances'->1->>'id' <> item::text
    or next_page->'instances'->1->>'reduction_percent' <> '47'
    or next_page->'instances'->1->>'state' <> 'reserved'
    or next_page::text like '%private_support_note%' or next_page::text like '%hatch_seed%' then
    raise exception 'snapshot_contract_terminal_page_or_private_metadata';
  end if;
  if exists(select 1 from jsonb_array_elements(page->'instances') a
    join jsonb_array_elements(next_page->'instances') b on a->>'id' = b->>'id') then
    raise exception 'snapshot_contract_duplicate_page_row';
  end if;
  update public.player_economy_authority set server_revision = 8 where user_id = keeper;
  begin
    perform public.get_my_economy_inventory_page(1, 10067, 7, cursor->>'kind', (cursor->>'id')::uuid, 100);
    raise exception 'snapshot_contract_changed_revision_accepted';
  exception when others then if sqlerrm <> 'economy_snapshot_changed' then raise; end if; end;
end;
$$;
rollback;
select true as economy_inventory_snapshot_contract_passed;
