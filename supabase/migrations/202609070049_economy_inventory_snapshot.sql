-- Read-only phase 4B reconciliation. No account conversion or activation.
create index player_chest_instances_snapshot_idx
  on public.player_chest_instances(owner_id, id) where state in ('owned', 'reserved');
create index player_item_instances_snapshot_idx
  on public.player_item_instances(owner_id, id) where state in ('owned', 'reserved', 'equipped');

create function public.get_my_economy_inventory_page(
  p_protocol_version integer, p_client_build integer,
  p_expected_revision bigint default null,
  p_after_kind text default null, p_after_id uuid default null,
  p_page_size integer default 50
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare keeper uuid := auth.uid(); contract private.economy_contract%rowtype;
  authority public.player_economy_authority%rowtype;
  wallet public.player_wallets%rowtype; entries jsonb; cursor jsonb := 'null'::jsonb;
begin
  if keeper is null then raise exception 'economy_login_required'; end if;
  if p_page_size is null or p_page_size not between 1 and 100
    or (p_after_kind is null) <> (p_after_id is null)
    or (p_after_kind is not null and p_after_kind not in ('chest', 'item'))
    or (p_after_id is not null and p_expected_revision is null)
    or p_expected_revision < 0 then raise exception 'economy_request_invalid'; end if;
  -- All economy writers use the same owner lock. Headers and rows therefore
  -- describe one revision even when the transaction's isolation is READ COMMITTED.
  perform pg_advisory_xact_lock(hashtextextended(keeper::text, 0));
  select * into contract from private.economy_contract where singleton;
  if not found then raise exception 'economy_contract_unavailable'; end if;
  select * into authority from public.player_economy_authority where user_id = keeper;
  if not found or authority.authority_mode <> 'server' then
    raise exception 'economy_server_inventory_required';
  end if;
  if p_protocol_version is null or p_client_build is null
    or p_protocol_version <> contract.protocol_version
    or p_protocol_version <> authority.protocol_version
    or p_client_build < contract.minimum_client_build then
    raise exception 'economy_client_upgrade_required';
  end if;
  -- Reads intentionally remain available when the global mutation switch is off.
  if p_expected_revision is not null and p_expected_revision <> authority.server_revision then
    raise exception 'economy_snapshot_changed';
  end if;
  select * into wallet from public.player_wallets where user_id = keeper;
  if not found then raise exception 'economy_wallet_unavailable'; end if;
  select coalesce(jsonb_agg(page.entry order by page.kind, page.id), '[]'::jsonb)
    into entries from (
      select inventory.* from (
        select 'chest'::text as kind, c.id, jsonb_build_object(
          'kind', 'chest', 'id', c.id, 'catalog_id', c.tier,
          'state', c.state, 'tradeable', c.tradeable,
          'special_chest_id', c.special_chest_id) as entry
        from public.player_chest_instances c where c.owner_id = keeper and c.state in ('owned', 'reserved')
        union all
        select 'item'::text, i.id, jsonb_build_object(
          'kind', 'item', 'id', i.id, 'catalog_id', i.catalog_id,
          'item_kind', i.item_kind, 'state', i.state, 'tradeable', i.tradeable,
          'reduction_percent', case when i.item_kind = 'relic' and i.catalog_id = 'chronoshard'
            then i.metadata->'reduction_percent' else null end)
        from public.player_item_instances i where i.owner_id = keeper and i.state in ('owned', 'reserved', 'equipped')
      ) inventory
      where p_after_id is null or (inventory.kind, inventory.id) > (p_after_kind, p_after_id)
      order by inventory.kind, inventory.id limit p_page_size + 1
    ) page;
  if jsonb_array_length(entries) > p_page_size then
    entries := entries - p_page_size;
    cursor := jsonb_build_object('kind', entries->(p_page_size - 1)->>'kind',
      'id', entries->(p_page_size - 1)->>'id');
  end if;
  return jsonb_build_object('snapshot_version', 1, 'owner_id', keeper,
    'server_revision', authority.server_revision, 'wallet_revision', wallet.revision,
    'coins', wallet.coins, 'gems', wallet.gems, 'instances', entries, 'next_cursor', cursor);
end;
$$;
revoke all on function public.get_my_economy_inventory_page(integer,integer,bigint,text,uuid,integer)
  from public, anon;
grant execute on function public.get_my_economy_inventory_page(integer,integer,bigint,text,uuid,integer)
  to authenticated;
