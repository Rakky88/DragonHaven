-- A server-owned account must never accept a client snapshot as inventory.
-- Legacy accounts retain their existing migration/trade synchronization path.
create function private.assert_legacy_inventory_authority()
returns void language plpgsql security definer set search_path = '' as $$
declare keeper uuid := auth.uid();
begin
  if keeper is null then raise exception 'online_login_required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(keeper::text, 0));
  -- The activation procedure must take this same owner lock and authority row
  -- lock; otherwise it could race with an already authorized legacy import.
  perform 1 from public.player_economy_authority
    where user_id = keeper and authority_mode = 'server' for update;
  if found then raise exception 'economy_server_inventory_required'; end if;
end;
$$;

alter function public.synchronize_trade_inventory(jsonb) rename to synchronize_trade_inventory_v45;
create function public.synchronize_trade_inventory(p_inventory jsonb)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.assert_legacy_inventory_authority();
  perform public.synchronize_trade_inventory_v45(p_inventory);
end;
$$;

alter function public.import_legacy_inventory(jsonb) rename to import_legacy_inventory_v45;
create function public.import_legacy_inventory(p_inventory jsonb)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.assert_legacy_inventory_authority();
  perform public.import_legacy_inventory_v45(p_inventory);
end;
$$;

revoke all on function private.assert_legacy_inventory_authority(),
  public.synchronize_trade_inventory_v45(jsonb), public.import_legacy_inventory_v45(jsonb)
  from public, anon, authenticated;
revoke all on function public.synchronize_trade_inventory(jsonb),
  public.import_legacy_inventory(jsonb) from public, anon;
grant execute on function public.synchronize_trade_inventory(jsonb),
  public.import_legacy_inventory(jsonb) to authenticated;
