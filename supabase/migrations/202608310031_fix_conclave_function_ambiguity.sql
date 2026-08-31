-- Migration 30 was applied to isolated staging before db lint identified two
-- PL/pgSQL output-column ambiguities. Qualify the affected table columns so
-- staging is repaired and clean installs receive the same definitions.

create or replace function public.open_friend_messages(p_friend_id uuid)
returns table (
  message_id uuid, sender_id uuid, recipient_id uuid, body text,
  created_at timestamptz, read_at timestamptz
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
  return query select m.id, m.sender_id, m.recipient_id, m.body, m.created_at, m.read_at
  from public.friend_messages m
  where (m.sender_id = auth.uid() and m.recipient_id = p_friend_id)
     or (m.sender_id = p_friend_id and m.recipient_id = auth.uid())
  order by m.created_at;
end
$$;

create or replace function public.contribute_to_conclave()
returns table(level integer,xp integer,aerie_stage integer,contribution_streak integer)
language plpgsql security definer set search_path = '' as $$
declare member public.conclave_members; old_level integer; new_level integer; today date := (now() at time zone 'utc')::date;
begin
  select * into member from public.conclave_members where user_id=auth.uid() for update;
  if not found then raise exception 'not_in_conclave'; end if;
  select c.level into old_level from public.conclaves c where c.id=member.conclave_id for update;
  if exists(select 1 from public.conclave_daily_contributions d where d.conclave_id=member.conclave_id and d.contribution_on=today and d.user_id=auth.uid()) then raise exception 'conclave_already_contributed'; end if;
  if (select count(*) from public.conclave_daily_contributions d where d.conclave_id=member.conclave_id and d.contribution_on=today)>=20 then raise exception 'conclave_daily_limit'; end if;
  insert into public.conclave_daily_contributions(conclave_id,contribution_on,user_id) values(member.conclave_id,today,auth.uid());
  update public.conclave_members as target set contribution_streak=case
      when target.last_contribution_on=today-1
        then target.contribution_streak+1 else 1 end,
    last_contribution_on=today
    where target.conclave_id=member.conclave_id
      and target.user_id=auth.uid();
  update public.conclaves c set xp=c.xp+10,
    level=least(50,1+((c.xp+10)/850)),updated_at=now() where c.id=member.conclave_id returning c.level into new_level;
  if new_level>old_level then insert into public.conclave_chronicle(conclave_id,actor_id,kind,body)
    values(member.conclave_id,auth.uid(),'level','The Conclave reached level '||new_level||'.'); end if;
  return query select c.level,c.xp,least(10,1+((c.level-1)/5)),cm.contribution_streak
    from public.conclaves c join public.conclave_members cm on cm.conclave_id=c.id
    where c.id=member.conclave_id and cm.user_id=auth.uid();
end
$$;

revoke all on function public.open_friend_messages(uuid) from public,anon;
revoke all on function public.contribute_to_conclave() from public,anon;
grant execute on function public.open_friend_messages(uuid) to authenticated;
grant execute on function public.contribute_to_conclave() to authenticated;
