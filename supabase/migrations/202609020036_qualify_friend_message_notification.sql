-- Qualify every social-notification column referenced by open_friend_messages.
-- The function returns a column named `kind`; without an explicit table alias,
-- PL/pgSQL can also interpret `kind` in the UPDATE as that output variable.

create or replace function public.open_friend_messages(p_friend_id uuid)
returns table (
  message_id uuid,
  sender_id uuid,
  recipient_id uuid,
  body text,
  created_at timestamptz,
  read_at timestamptz,
  kind text,
  payload jsonb
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or not private.are_friends(auth.uid(), p_friend_id) then
    raise exception 'messages_not_friends';
  end if;

  perform private.cleanup_ephemeral_social_content();

  update public.friend_messages as target_message
  set read_at = now()
  where target_message.sender_id = p_friend_id
    and target_message.recipient_id = auth.uid()
    and target_message.read_at is null;

  update public.social_notifications as target_notification
  set acknowledged_at = now()
  where target_notification.user_id = auth.uid()
    and target_notification.actor_id = p_friend_id
    and target_notification.kind = 'friend_message'
    and target_notification.acknowledged_at is null;

  return query
  select
    message.id,
    message.sender_id,
    message.recipient_id,
    message.body,
    message.created_at,
    message.read_at,
    message.kind,
    message.payload
  from public.friend_messages as message
  where (message.sender_id = auth.uid()
      and message.recipient_id = p_friend_id)
     or (message.sender_id = p_friend_id
      and message.recipient_id = auth.uid())
  order by message.created_at;
end
$$;

revoke all on function public.open_friend_messages(uuid) from public, anon;
grant execute on function public.open_friend_messages(uuid) to authenticated;
