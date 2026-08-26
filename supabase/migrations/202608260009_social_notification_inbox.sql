-- Durable social-event inbox. The app converts these server-authored events
-- into Android notifications on its next authenticated refresh, so events are
-- not lost while a client is temporarily offline.

create table public.social_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  kind text not null check (kind in (
    'friend_request', 'friend_accepted',
    'trade_request', 'trade_return', 'trade_completed'
  )),
  actor_id uuid references public.profiles(user_id) on delete set null,
  entity_id uuid not null,
  created_at timestamptz not null default now(),
  acknowledged_at timestamptz
);

create index social_notifications_pending_idx
  on public.social_notifications(user_id, created_at)
  where acknowledged_at is null;

alter table public.social_notifications enable row level security;
revoke all on table public.social_notifications from anon, authenticated;

create or replace function private.enqueue_friendship_notifications()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.status = 'pending' then
      insert into public.social_notifications(
        user_id, kind, actor_id, entity_id
      ) values (
        new.addressee_id, 'friend_request', new.requester_id, new.id
      );
    elsif new.status = 'accepted' then
      insert into public.social_notifications(
        user_id, kind, actor_id, entity_id
      ) values (
        new.requester_id, 'friend_accepted', new.addressee_id, new.id
      );
    end if;
    return new;
  end if;
  if new.status = 'pending' and old.status is distinct from 'pending' then
    insert into public.social_notifications(
      user_id, kind, actor_id, entity_id
    ) values (
      new.addressee_id, 'friend_request', new.requester_id, new.id
    );
  elsif new.status = 'accepted' and old.status is distinct from 'accepted' then
    insert into public.social_notifications(
      user_id, kind, actor_id, entity_id
    ) values (
      new.requester_id, 'friend_accepted', new.addressee_id, new.id
    );
  end if;
  return new;
end
$$;

create trigger friendships_enqueue_notification
after insert or update of status on public.friendships
for each row execute function private.enqueue_friendship_notifications();

create or replace function private.enqueue_trade_notifications()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.status = 'awaiting_recipient' then
      insert into public.social_notifications(
        user_id, kind, actor_id, entity_id
      ) values (
        new.recipient_id, 'trade_request', new.initiator_id, new.id
      );
    end if;
    return new;
  end if;
  if new.status = 'awaiting_initiator'
      and old.status is distinct from 'awaiting_initiator' then
    insert into public.social_notifications(
      user_id, kind, actor_id, entity_id
    ) values (
      new.initiator_id, 'trade_return', new.recipient_id, new.id
    );
  elsif new.status = 'completed'
      and old.status is distinct from 'completed' then
    insert into public.social_notifications(
      user_id, kind, actor_id, entity_id
    ) values
      (new.initiator_id, 'trade_completed', new.recipient_id, new.id),
      (new.recipient_id, 'trade_completed', new.initiator_id, new.id);
  end if;
  return new;
end
$$;

create trigger trades_enqueue_notification
after insert or update of status on public.trades
for each row execute function private.enqueue_trade_notifications();

create or replace function public.list_social_notifications()
returns table (
  notification_id uuid,
  kind text,
  entity_id uuid,
  actor_display_name text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select n.id, n.kind, n.entity_id,
    coalesce(p.display_name, 'Keeper'), n.created_at
  from public.social_notifications n
  left join public.profiles p on p.user_id = n.actor_id
  where n.user_id = auth.uid()
    and n.acknowledged_at is null
  order by n.created_at
  limit 50
$$;

create or replace function public.acknowledge_social_notifications(
  p_notification_ids uuid[]
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  update public.social_notifications
  set acknowledged_at = now()
  where user_id = auth.uid()
    and id = any(coalesce(p_notification_ids, array[]::uuid[]));
end
$$;

revoke all on function public.list_social_notifications() from public, anon;
revoke all on function public.acknowledge_social_notifications(uuid[])
  from public, anon;
grant execute on function public.list_social_notifications() to authenticated;
grant execute on function public.acknowledge_social_notifications(uuid[])
  to authenticated;
