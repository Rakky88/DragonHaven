-- Special Chests are gameplay rewards and remain tradeable. Preserve the
-- hardened v20/v21 parsers behind narrow wrappers, adding only the new tier.

alter table public.player_chests
  drop constraint if exists player_chests_tier_check;
alter table public.player_chests add constraint player_chests_tier_check check (
  tier in (
    'wooden', 'silver', 'gold', 'dragon', 'mythical', 'sinister', 'special',
    'portrait', 'title'
  )
);

alter function public.synchronize_trade_inventory(jsonb)
  rename to synchronize_trade_inventory_v25;

create function public.synchronize_trade_inventory(p_inventory jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  requested integer;
  reserved integer;
begin
  if current_user_id is null or jsonb_typeof(p_inventory) <> 'object' then
    raise exception 'invalid_inventory';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(current_user_id::text, 0));
  perform public.synchronize_trade_inventory_v25(p_inventory);
  requested := greatest(0, least(1000000,
    coalesce((p_inventory -> 'chests' ->> 'special')::integer, 0)));
  select count(*)::integer into reserved
  from public.trade_reservations r
  where r.owner_id = current_user_id and r.item_type = 'chest'
    and r.item_key = 'special';
  insert into public.player_chests(owner_id, tier, quantity)
  values (current_user_id, 'special', greatest(requested, reserved))
  on conflict (owner_id, tier) do update set
    quantity = greatest(excluded.quantity, reserved), updated_at = now();
exception
  when invalid_text_representation or numeric_value_out_of_range then
    raise exception 'invalid_inventory';
end;
$$;

alter function private.reserve_trade_item(uuid, text, uuid, jsonb)
  rename to reserve_trade_item_v25;

create function private.reserve_trade_item(
  p_trade_id uuid,
  p_side text,
  p_owner_id uuid,
  p_item jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  owned_quantity integer;
  reserved_quantity integer;
begin
  if coalesce(p_item ->> 'kind', '') <> 'chest'
    or coalesce(p_item ->> 'key', '') <> 'special' then
    return private.reserve_trade_item_v25(
      p_trade_id, p_side, p_owner_id, p_item
    );
  end if;
  if p_side not in ('initiator', 'recipient') then
    raise exception 'trade_item_invalid';
  end if;
  select quantity into owned_quantity
  from public.player_chests
  where owner_id = p_owner_id and tier = 'special'
  for update;
  select count(*)::integer into reserved_quantity
  from public.trade_reservations r
  where r.owner_id = p_owner_id and r.item_type = 'chest'
    and r.item_key = 'special';
  if coalesce(owned_quantity, 0) <= reserved_quantity then
    raise exception 'trade_item_unavailable';
  end if;
  insert into public.trade_reservations(
    trade_id, side, owner_id, item_type, item_key
  ) values (p_trade_id, p_side, p_owner_id, 'chest', 'special');
  return jsonb_build_object(
    'kind', 'chest', 'key', 'special', 'data', '{}'::jsonb
  );
end;
$$;

alter function private.transfer_trade_item(uuid, uuid, jsonb)
  rename to transfer_trade_item_v25;

create function private.transfer_trade_item(
  p_from uuid,
  p_to uuid,
  p_item jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce(p_item ->> 'kind', '') <> 'chest'
    or coalesce(p_item ->> 'key', '') <> 'special' then
    perform private.transfer_trade_item_v25(p_from, p_to, p_item);
    return;
  end if;
  update public.player_chests
  set quantity = quantity - 1, updated_at = now()
  where owner_id = p_from and tier = 'special' and quantity > 0;
  if not found then raise exception 'trade_item_unavailable'; end if;
  insert into public.player_chests(owner_id, tier, quantity)
  values (p_to, 'special', 1)
  on conflict (owner_id, tier) do update set
    quantity = public.player_chests.quantity + 1, updated_at = now();
end;
$$;

alter function public.import_legacy_inventory(jsonb)
  rename to import_legacy_inventory_v25;

create function public.import_legacy_inventory(p_inventory jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  already_imported_at timestamptz;
  requested bigint;
  stored integer;
begin
  if current_user_id is null or jsonb_typeof(p_inventory) <> 'object' then
    raise exception 'invalid_inventory';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(current_user_id::text, 0));
  select inventory_imported_at into already_imported_at
  from public.profiles where user_id = current_user_id for update;
  if not found then raise exception 'profile_not_found'; end if;
  if already_imported_at is not null then return; end if;
  requested := coalesce(
    (p_inventory -> 'chests' ->> 'special')::bigint, 0
  );
  stored := greatest(0, least(1000000, requested))::integer;
  perform public.import_legacy_inventory_v25(p_inventory);
  insert into public.player_chests(owner_id, tier, quantity)
  values (current_user_id, 'special', stored)
  on conflict (owner_id, tier) do update set
    quantity = excluded.quantity, updated_at = now();
  update public.legacy_inventory_import_audit
  set report = report || jsonb_build_object(
    'special_chests_requested', requested,
    'special_chests_stored', stored,
    'special_chests_clamped', requested <> stored
  )
  where user_id = current_user_id;
exception
  when invalid_text_representation or numeric_value_out_of_range
    or check_violation or not_null_violation then
    raise exception 'invalid_inventory';
end;
$$;

revoke all on function public.synchronize_trade_inventory_v25(jsonb)
  from public, anon, authenticated;
revoke all on function private.reserve_trade_item_v25(uuid, text, uuid, jsonb)
  from public, anon, authenticated;
revoke all on function private.transfer_trade_item_v25(uuid, uuid, jsonb)
  from public, anon, authenticated;
revoke all on function public.import_legacy_inventory_v25(jsonb)
  from public, anon, authenticated;
revoke all on function private.reserve_trade_item(uuid, text, uuid, jsonb)
  from public, anon, authenticated;
revoke all on function private.transfer_trade_item(uuid, uuid, jsonb)
  from public, anon, authenticated;
revoke all on function public.synchronize_trade_inventory(jsonb)
  from public, anon;
grant execute on function public.synchronize_trade_inventory(jsonb)
  to authenticated;
revoke all on function public.import_legacy_inventory(jsonb)
  from public, anon;
grant execute on function public.import_legacy_inventory(jsonb)
  to authenticated;
