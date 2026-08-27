-- Portrait and title chests are collection guarantees rather than economic
-- items. Release any old offers and reject them at every authoritative trade
-- boundary, including clients from older releases.

update public.trades
set status = 'expired'
where status in ('awaiting_recipient', 'awaiting_initiator')
  and (
    (initiator_item ->> 'kind' = 'chest'
      and initiator_item ->> 'key' in ('portrait', 'title'))
    or (recipient_item ->> 'kind' = 'chest'
      and recipient_item ->> 'key' in ('portrait', 'title'))
  );

delete from public.trade_reservations r
where r.item_type = 'chest' and r.item_key in ('portrait', 'title');

create or replace function private.reserve_trade_item(
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
  requested_type text := p_item ->> 'kind';
  requested_key text := p_item ->> 'key';
  egg public.player_eggs%rowtype;
  owned_quantity integer;
  reserved_quantity integer;
begin
  if p_side not in ('initiator', 'recipient')
    or requested_type not in ('egg', 'chest', 'relic')
    or requested_key is null
    or char_length(requested_key) not between 1 and 100 then
    raise exception 'trade_item_invalid';
  end if;

  if requested_type = 'egg' then
    select * into egg from public.player_eggs
    where owner_id = p_owner_id and legacy_client_id = requested_key
    for update;
    if not found or exists (
      select 1 from public.trade_reservations r
      where r.owner_id = p_owner_id and r.item_type = 'egg'
        and r.item_key = requested_key
    ) then
      raise exception 'trade_item_unavailable';
    end if;
    insert into public.trade_reservations(
      trade_id, side, owner_id, item_type, item_key
    ) values (p_trade_id, p_side, p_owner_id, requested_type, requested_key);
    return jsonb_build_object(
      'kind', 'egg', 'key', requested_key,
      'data', private.trade_egg_data(egg)
    );
  end if;

  if requested_type = 'chest' then
    if requested_key not in (
      'wooden', 'silver', 'gold', 'dragon', 'mythical', 'sinister'
    ) then raise exception 'trade_item_invalid'; end if;
    select quantity into owned_quantity from public.player_chests
    where owner_id = p_owner_id and tier = requested_key for update;
  else
    if requested_key not in ('moralPrism', 'orderCompass', 'soulMirror') then
      raise exception 'trade_item_invalid';
    end if;
    select quantity into owned_quantity from public.player_relics
    where owner_id = p_owner_id and relic_type = requested_key for update;
  end if;

  select count(*)::integer into reserved_quantity
  from public.trade_reservations r
  where r.owner_id = p_owner_id and r.item_type = requested_type
    and r.item_key = requested_key;
  if coalesce(owned_quantity, 0) <= reserved_quantity then
    raise exception 'trade_item_unavailable';
  end if;
  insert into public.trade_reservations(
    trade_id, side, owner_id, item_type, item_key
  ) values (p_trade_id, p_side, p_owner_id, requested_type, requested_key);
  return jsonb_build_object(
    'kind', requested_type, 'key', requested_key, 'data', '{}'::jsonb
  );
end;
$$;

create or replace function private.transfer_trade_item(
  p_from uuid,
  p_to uuid,
  p_item jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  item_type text := p_item ->> 'kind';
  item_key text := p_item ->> 'key';
begin
  if item_type = 'egg' then
    if exists (
      select 1 from public.player_eggs
      where owner_id = p_to and legacy_client_id = item_key
    ) then raise exception 'trade_item_unavailable'; end if;
    update public.player_eggs set owner_id = p_to
    where owner_id = p_from and legacy_client_id = item_key;
    if not found then raise exception 'trade_item_unavailable'; end if;
  elsif item_type = 'chest' then
    if item_key not in (
      'wooden', 'silver', 'gold', 'dragon', 'mythical', 'sinister'
    ) then raise exception 'trade_item_invalid'; end if;
    update public.player_chests set quantity = quantity - 1, updated_at = now()
    where owner_id = p_from and tier = item_key and quantity > 0;
    if not found then raise exception 'trade_item_unavailable'; end if;
    insert into public.player_chests(owner_id, tier, quantity)
    values (p_to, item_key, 1)
    on conflict (owner_id, tier) do update set
      quantity = public.player_chests.quantity + 1, updated_at = now();
  elsif item_type = 'relic' then
    update public.player_relics set quantity = quantity - 1, updated_at = now()
    where owner_id = p_from and relic_type = item_key and quantity > 0;
    if not found then raise exception 'trade_item_unavailable'; end if;
    insert into public.player_relics(owner_id, relic_type, quantity)
    values (p_to, item_key, 1)
    on conflict (owner_id, relic_type) do update set
      quantity = public.player_relics.quantity + 1, updated_at = now();
  else
    raise exception 'trade_item_invalid';
  end if;
end;
$$;

create or replace function public.list_trade_inventory()
returns table (
  item_type text,
  item_key text,
  available integer,
  item_data jsonb
)
language sql
security definer
set search_path = ''
stable
as $$
  select 'egg'::text, e.legacy_client_id, 1,
    private.trade_egg_data(e)
  from public.player_eggs e
  where e.owner_id = auth.uid()
    and not exists (
      select 1 from public.trade_reservations r
      where r.owner_id = e.owner_id and r.item_type = 'egg'
        and r.item_key = e.legacy_client_id
    )
  union all
  select 'chest'::text, c.tier,
    (c.quantity - count(r.trade_id))::integer, '{}'::jsonb
  from public.player_chests c
  left join public.trade_reservations r
    on r.owner_id = c.owner_id and r.item_type = 'chest'
      and r.item_key = c.tier
  where c.owner_id = auth.uid()
    and c.tier not in ('portrait', 'title')
  group by c.owner_id, c.tier, c.quantity
  having c.quantity - count(r.trade_id) > 0
  union all
  select 'relic'::text, x.relic_type,
    (x.quantity - count(r.trade_id))::integer, '{}'::jsonb
  from public.player_relics x
  left join public.trade_reservations r
    on r.owner_id = x.owner_id and r.item_type = 'relic'
      and r.item_key = x.relic_type
  where x.owner_id = auth.uid()
  group by x.owner_id, x.relic_type, x.quantity
  having x.quantity - count(r.trade_id) > 0
  order by 1, 2
$$;

revoke all on function private.reserve_trade_item(uuid, text, uuid, jsonb)
  from public, anon, authenticated;
revoke all on function private.transfer_trade_item(uuid, uuid, jsonb)
  from public, anon, authenticated;
revoke all on function public.list_trade_inventory() from public, anon;
grant execute on function public.list_trade_inventory() to authenticated;
