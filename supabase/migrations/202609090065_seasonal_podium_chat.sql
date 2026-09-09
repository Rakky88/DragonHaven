-- Permit the exact shipped podium emotes in both chats. Existing friendship,
-- recipient preferences, membership, payload size and rate limits are unchanged.
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
  if emote_id !~ '^((chest|trial|cozy|infernal|celestial)_[a-z0-9_]{2,70}|seasonal_(halloween|christmas|new_year|valentine|pride|sunwake|harvestmoon)_(gold|silver|bronze))$' then
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
    if emote_id !~ '^((chest|trial|cozy|infernal|celestial)_[a-z0-9_]{2,70}|seasonal_(halloween|christmas|new_year|valentine|pride|sunwake|harvestmoon)_(gold|silver|bronze))$' then
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
