-- Keep asynchronous trades small, fair and race-safe.
-- Each account can participate in one active trade, complete at most three
-- trades per Amsterdam calendar day, and gets ten minutes for each response.

alter table public.trades
  add column expires_at timestamptz not null
    default (now() + interval '10 minutes');

alter table public.trades
  drop constraint if exists trades_status_check;
alter table public.trades add constraint trades_status_check check (
  status in (
    'awaiting_recipient', 'awaiting_initiator', 'completed',
    'cancelled', 'rejected', 'expired'
  )
);

-- Old proposals predate the ten-minute promise and may violate the new
-- one-active-trade invariant. Release them once during this migration.
update public.trades
set status = 'expired'
where status in ('awaiting_recipient', 'awaiting_initiator');

delete from public.trade_reservations r
where exists (
  select 1 from public.trades t
  where t.id = r.trade_id and t.status = 'expired'
);

create index trades_active_expiry_idx
  on public.trades(expires_at)
  where status in ('awaiting_recipient', 'awaiting_initiator');

create or replace function private.expire_stale_trades()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  expired_count integer;
begin
  update public.trades
  set status = 'expired'
  where status in ('awaiting_recipient', 'awaiting_initiator')
    and expires_at <= now();
  get diagnostics expired_count = row_count;

  if expired_count > 0 then
    delete from public.trade_reservations r
    where exists (
      select 1 from public.trades t
      where t.id = r.trade_id and t.status = 'expired'
    );
  end if;
  return expired_count;
end;
$$;

create or replace function private.lock_trade_users(
  p_first uuid,
  p_second uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform pg_advisory_xact_lock(hashtextextended(
    least(p_first::text, p_second::text), 0
  ));
  perform pg_advisory_xact_lock(hashtextextended(
    greatest(p_first::text, p_second::text), 0
  ));
end;
$$;

create or replace function private.completed_trades_today(p_user_id uuid)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::integer
  from public.trades t
  where t.status = 'completed'
    and p_user_id in (t.initiator_id, t.recipient_id)
    and (t.completed_at at time zone 'Europe/Amsterdam')::date =
      (now() at time zone 'Europe/Amsterdam')::date
$$;

create or replace function public.create_trade(p_friend_id uuid, p_item jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  result_id uuid;
  snapshot jsonb;
begin
  perform private.expire_stale_trades();
  if current_user_id is null or p_friend_id is null
    or current_user_id = p_friend_id then
    raise exception 'trade_wrong_participant';
  end if;

  perform private.lock_trade_users(current_user_id, p_friend_id);
  if not private.trade_users_are_friends(current_user_id, p_friend_id) then
    raise exception 'trade_not_friends';
  end if;
  if exists (
    select 1 from public.trades t
    where t.status in ('awaiting_recipient', 'awaiting_initiator')
      and (
        current_user_id in (t.initiator_id, t.recipient_id)
        or p_friend_id in (t.initiator_id, t.recipient_id)
      )
  ) then
    raise exception 'trade_active_limit';
  end if;
  if private.completed_trades_today(current_user_id) >= 3
    or private.completed_trades_today(p_friend_id) >= 3 then
    raise exception 'trade_daily_limit';
  end if;

  insert into public.trades(initiator_id, recipient_id, expires_at)
  values (current_user_id, p_friend_id, now() + interval '10 minutes')
  returning id into result_id;
  snapshot := private.reserve_trade_item(
    result_id, 'initiator', current_user_id, p_item
  );
  update public.trades set initiator_item = snapshot where id = result_id;
  return result_id;
end;
$$;

create or replace function public.respond_trade(p_trade_id uuid, p_item jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  trade public.trades%rowtype;
  first_user uuid;
  second_user uuid;
  snapshot jsonb;
begin
  perform private.expire_stale_trades();
  select t.initiator_id, t.recipient_id into first_user, second_user
  from public.trades t where t.id = p_trade_id;
  if not found then raise exception 'trade_not_found'; end if;
  if current_user_id is null or second_user <> current_user_id then
    raise exception 'trade_wrong_participant';
  end if;

  perform private.lock_trade_users(first_user, second_user);
  select * into trade from public.trades t
  where t.id = p_trade_id for update;
  if trade.status = 'expired' then raise exception 'trade_expired'; end if;
  if trade.status <> 'awaiting_recipient' then
    raise exception 'trade_wrong_state';
  end if;
  if not private.trade_users_are_friends(
    trade.initiator_id, trade.recipient_id
  ) then
    raise exception 'trade_not_friends';
  end if;

  snapshot := private.reserve_trade_item(
    trade.id, 'recipient', current_user_id, p_item
  );
  update public.trades set
    recipient_item = snapshot,
    status = 'awaiting_initiator',
    expires_at = now() + interval '10 minutes'
  where id = trade.id;
end;
$$;

create or replace function public.complete_trade(p_trade_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  trade public.trades%rowtype;
  first_user uuid;
  second_user uuid;
begin
  perform private.expire_stale_trades();
  select t.initiator_id, t.recipient_id into first_user, second_user
  from public.trades t where t.id = p_trade_id;
  if not found then raise exception 'trade_not_found'; end if;
  if current_user_id is null or first_user <> current_user_id then
    raise exception 'trade_wrong_participant';
  end if;

  perform private.lock_trade_users(first_user, second_user);
  select * into trade from public.trades t
  where t.id = p_trade_id for update;
  if trade.status = 'expired' then raise exception 'trade_expired'; end if;
  if trade.status <> 'awaiting_initiator'
    or trade.recipient_item is null then
    raise exception 'trade_wrong_state';
  end if;
  if not private.trade_users_are_friends(
    trade.initiator_id, trade.recipient_id
  ) then
    raise exception 'trade_not_friends';
  end if;
  if private.completed_trades_today(trade.initiator_id) >= 3
    or private.completed_trades_today(trade.recipient_id) >= 3 then
    raise exception 'trade_daily_limit';
  end if;

  perform private.transfer_trade_item(
    trade.initiator_id, trade.recipient_id, trade.initiator_item
  );
  perform private.transfer_trade_item(
    trade.recipient_id, trade.initiator_id, trade.recipient_item
  );
  update public.trades set status = 'completed', completed_at = now()
  where id = trade.id;
  delete from public.trade_reservations where trade_id = trade.id;
end;
$$;

create or replace function public.cancel_trade(p_trade_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  trade public.trades%rowtype;
begin
  perform private.expire_stale_trades();
  select * into trade from public.trades t
  where t.id = p_trade_id for update;
  if not found then raise exception 'trade_not_found'; end if;
  if current_user_id is null or trade.initiator_id <> current_user_id then
    raise exception 'trade_wrong_participant';
  end if;
  if trade.status = 'expired' then raise exception 'trade_expired'; end if;
  if trade.status not in ('awaiting_recipient', 'awaiting_initiator') then
    raise exception 'trade_wrong_state';
  end if;
  update public.trades set status = 'cancelled' where id = trade.id;
  delete from public.trade_reservations where trade_id = trade.id;
end;
$$;

create or replace function public.reject_trade(p_trade_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  trade public.trades%rowtype;
begin
  perform private.expire_stale_trades();
  select * into trade from public.trades t
  where t.id = p_trade_id for update;
  if not found then raise exception 'trade_not_found'; end if;
  if current_user_id is null or trade.recipient_id <> current_user_id then
    raise exception 'trade_wrong_participant';
  end if;
  if trade.status = 'expired' then raise exception 'trade_expired'; end if;
  if trade.status not in ('awaiting_recipient', 'awaiting_initiator') then
    raise exception 'trade_wrong_state';
  end if;
  update public.trades set status = 'rejected' where id = trade.id;
  delete from public.trade_reservations where trade_id = trade.id;
end;
$$;

create or replace function public.list_my_trades()
returns table (
  trade_id uuid,
  status text,
  initiator_id uuid,
  recipient_id uuid,
  am_initiator boolean,
  initiator_item jsonb,
  recipient_item jsonb,
  my_acknowledged boolean,
  created_at timestamptz,
  updated_at timestamptz,
  user_id uuid,
  keeper_code text,
  display_name text,
  title text,
  portrait_key text,
  discovered_dragon_count bigint,
  inventory_imported boolean,
  favorite_dragon_id text,
  favorite_dragon_name text,
  favorite_dragon_lineage_id text,
  favorite_dragon_stage text,
  favorite_dragon_level integer,
  favorite_dragon_might integer,
  favorite_dragon_arcana integer,
  favorite_dragon_spirit integer,
  favorite_dragon_evolution_path text,
  favorite_dragon_prismatic boolean,
  favorite_dragon_sinister boolean
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.expire_stale_trades();
  return query
  select
    t.id, t.status, t.initiator_id, t.recipient_id,
    t.initiator_id = auth.uid(), t.initiator_item, t.recipient_item,
    case when t.initiator_id = auth.uid()
      then t.initiator_acknowledged_at is not null
      else t.recipient_acknowledged_at is not null end,
    t.created_at, t.updated_at,
    p.user_id, p.keeper_code, p.display_name, p.title, p.portrait_key,
    coalesce(s.discovered_dragon_count, 0)::bigint,
    p.inventory_imported_at is not null,
    s.favorite_dragon_id, s.favorite_dragon_name,
    s.favorite_dragon_lineage_id, s.favorite_dragon_stage,
    private.dragon_level(coalesce(s.favorite_dragon_xp, 0)),
    s.favorite_dragon_might, s.favorite_dragon_arcana,
    s.favorite_dragon_spirit, s.favorite_dragon_evolution_path,
    s.favorite_dragon_prismatic, s.favorite_dragon_sinister
  from public.trades t
  join public.profiles p on p.user_id = case
    when t.initiator_id = auth.uid()
      then t.recipient_id else t.initiator_id end
  left join public.social_showcases s on s.user_id = p.user_id
  where auth.uid() in (t.initiator_id, t.recipient_id)
    and (
      t.status in ('awaiting_recipient', 'awaiting_initiator')
      or (t.status = 'completed' and (
        (t.initiator_id = auth.uid()
          and t.initiator_acknowledged_at is null)
        or (t.recipient_id = auth.uid()
          and t.recipient_acknowledged_at is null)
      ))
      or t.updated_at > now() - interval '7 days'
    )
  order by
    (t.status in ('awaiting_recipient', 'awaiting_initiator')) desc,
    t.updated_at desc;
end;
$$;

revoke all on function private.expire_stale_trades()
  from public, anon, authenticated;
revoke all on function private.lock_trade_users(uuid, uuid)
  from public, anon, authenticated;
revoke all on function private.completed_trades_today(uuid)
  from public, anon, authenticated;

revoke all on function public.create_trade(uuid, jsonb) from public, anon;
revoke all on function public.respond_trade(uuid, jsonb) from public, anon;
revoke all on function public.complete_trade(uuid) from public, anon;
revoke all on function public.cancel_trade(uuid) from public, anon;
revoke all on function public.reject_trade(uuid) from public, anon;
revoke all on function public.list_my_trades() from public, anon;

grant execute on function public.create_trade(uuid, jsonb) to authenticated;
grant execute on function public.respond_trade(uuid, jsonb) to authenticated;
grant execute on function public.complete_trade(uuid) to authenticated;
grant execute on function public.cancel_trade(uuid) to authenticated;
grant execute on function public.reject_trade(uuid) to authenticated;
grant execute on function public.list_my_trades() to authenticated;
