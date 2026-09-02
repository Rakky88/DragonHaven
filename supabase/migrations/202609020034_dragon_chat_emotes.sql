-- Dragon emotes are short-lived chat content just like text messages. The
-- client still limits sending to its owned collection; these checks keep the
-- public RPC payload small, typed and safe for older clients to ignore.

alter table public.friend_messages
  add column if not exists kind text not null default 'text',
  add column if not exists payload jsonb not null default '{}'::jsonb;

alter table public.friend_messages
  drop constraint if exists friend_messages_kind_check,
  drop constraint if exists friend_messages_payload_size_check;
alter table public.friend_messages
  add constraint friend_messages_kind_check
    check (kind in ('text', 'emote')),
  add constraint friend_messages_payload_size_check
    check (pg_column_size(payload) <= 1024);

alter table public.conclave_messages
  drop constraint if exists conclave_messages_kind_check;
alter table public.conclave_messages
  add constraint conclave_messages_kind_check
    check (kind in ('text','achievement','dragon','trial','emote'));

create or replace function public.list_friend_conversations()
returns table (
  friend_id uuid, messages_allowed boolean, unread_count bigint,
  last_message text, last_message_at timestamptz, last_message_from_me boolean
) language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  perform private.cleanup_ephemeral_social_content();
  return query
  with friend_rows as (
    select case when f.requester_id = auth.uid() then f.addressee_id else f.requester_id end as id
    from public.friendships f
    where f.status = 'accepted' and auth.uid() in (f.requester_id, f.addressee_id)
  )
  select fr.id, p.friend_messages_allowed,
    count(m.id) filter (where m.recipient_id = auth.uid() and m.read_at is null),
    case when latest.kind = 'emote' then 'Dragon emote' else latest.body end,
    latest.created_at, latest.sender_id = auth.uid()
  from friend_rows fr
  join public.profiles p on p.user_id = fr.id
  left join public.friend_messages m on
    (m.sender_id = auth.uid() and m.recipient_id = fr.id)
    or (m.sender_id = fr.id and m.recipient_id = auth.uid())
  left join lateral (
    select lm.body, lm.kind, lm.created_at, lm.sender_id
    from public.friend_messages lm
    where (lm.sender_id = auth.uid() and lm.recipient_id = fr.id)
       or (lm.sender_id = fr.id and lm.recipient_id = auth.uid())
    order by lm.created_at desc limit 1
  ) latest on true
  group by fr.id, p.friend_messages_allowed, latest.body, latest.kind,
    latest.created_at, latest.sender_id
  order by coalesce(latest.created_at, '-infinity'::timestamptz) desc, fr.id;
end
$$;

drop function if exists public.open_friend_messages(uuid);
create function public.open_friend_messages(p_friend_id uuid)
returns table (
  message_id uuid, sender_id uuid, recipient_id uuid, body text,
  created_at timestamptz, read_at timestamptz, kind text, payload jsonb
) language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null or not private.are_friends(auth.uid(), p_friend_id) then
    raise exception 'messages_not_friends';
  end if;
  perform private.cleanup_ephemeral_social_content();
  update public.friend_messages as target set read_at = now()
  where target.sender_id = p_friend_id
    and target.recipient_id = auth.uid()
    and target.read_at is null;
  update public.social_notifications set acknowledged_at = now()
  where user_id = auth.uid() and actor_id = p_friend_id
    and kind = 'friend_message' and acknowledged_at is null;
  return query
  select m.id, m.sender_id, m.recipient_id, m.body, m.created_at, m.read_at,
    m.kind, m.payload
  from public.friend_messages m
  where (m.sender_id = auth.uid() and m.recipient_id = p_friend_id)
     or (m.sender_id = p_friend_id and m.recipient_id = auth.uid())
  order by m.created_at;
end
$$;

create or replace function public.send_friend_chat_message(
  p_friend_id uuid,
  p_body text,
  p_kind text,
  p_payload jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer set search_path = '' as $$
declare new_id uuid; recipient_allows boolean; emote_id text;
begin
  if auth.uid() is null or not private.are_friends(auth.uid(), p_friend_id) then
    raise exception 'messages_not_friends';
  end if;
  select friend_messages_allowed into recipient_allows
    from public.profiles where user_id = p_friend_id;
  if not coalesce(recipient_allows, false) then raise exception 'messages_disabled'; end if;
  if p_kind <> 'emote'
     or char_length(btrim(coalesce(p_body,''))) not between 1 and 100
     or pg_column_size(coalesce(p_payload,'{}'::jsonb)) > 1024 then
    raise exception 'message_invalid';
  end if;
  emote_id := coalesce(p_payload->>'emote_id', '');
  if emote_id !~ '^(chest|trial|cozy|infernal|celestial)_[a-z0-9_]{2,70}$' then
    raise exception 'message_invalid';
  end if;
  perform private.cleanup_ephemeral_social_content();
  if exists (
      select 1 from public.friend_messages
      where sender_id = auth.uid() and created_at > now() - interval '1 second'
    ) or (
      select count(*) from public.friend_messages
      where sender_id = auth.uid() and created_at > now() - interval '1 hour'
    ) >= 60 then
    raise exception 'message_rate_limited';
  end if;
  insert into public.friend_messages(sender_id, recipient_id, body, kind, payload)
    values (auth.uid(), p_friend_id, btrim(p_body), 'emote', p_payload)
    returning id into new_id;
  insert into public.social_notifications(user_id, kind, actor_id, entity_id)
    values (p_friend_id, 'friend_message', auth.uid(), new_id);
  return new_id;
end
$$;

create or replace function public.send_conclave_message(
  p_kind text,p_body text,p_payload jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer set search_path = '' as $$
declare cid uuid; new_id uuid; emote_id text;
begin
  select conclave_id into cid from public.conclave_members where user_id=auth.uid();
  if cid is null then raise exception 'not_in_conclave'; end if;
  if p_kind not in ('text','achievement','dragon','trial','emote')
     or char_length(btrim(coalesce(p_body,''))) not between 1 and 500
     or pg_column_size(coalesce(p_payload,'{}'::jsonb))>4096 then
    raise exception 'message_invalid';
  end if;
  if p_kind = 'emote' then
    emote_id := coalesce(p_payload->>'emote_id', '');
    if emote_id !~ '^(chest|trial|cozy|infernal|celestial)_[a-z0-9_]{2,70}$' then
      raise exception 'message_invalid';
    end if;
  end if;
  perform private.cleanup_ephemeral_social_content();
  if (select count(*) from public.conclave_messages where sender_id=auth.uid()
      and created_at>now()-interval '1 hour')>=90 then
    raise exception 'message_rate_limited';
  end if;
  insert into public.conclave_messages(conclave_id,sender_id,kind,body,payload)
    values(cid,auth.uid(),p_kind,btrim(p_body),coalesce(p_payload,'{}'::jsonb))
    returning id into new_id;
  return new_id;
end
$$;

revoke all on function public.open_friend_messages(uuid) from public, anon;
revoke all on function public.send_friend_chat_message(uuid,text,text,jsonb)
  from public, anon;
revoke all on function public.send_conclave_message(text,text,jsonb)
  from public, anon;
grant execute on function public.open_friend_messages(uuid) to authenticated;
grant execute on function public.send_friend_chat_message(uuid,text,text,jsonb)
  to authenticated;
grant execute on function public.send_conclave_message(text,text,jsonb)
  to authenticated;
