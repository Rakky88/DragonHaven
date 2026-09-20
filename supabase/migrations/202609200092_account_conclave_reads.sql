-- Read receipts are private account data, bounded by message retention.
create table private.account_conclave_reads (
  user_id uuid not null references auth.users(id) on delete cascade,
  message_id uuid not null references public.conclave_messages(id) on delete cascade,
  primary key(user_id,message_id)
);
create index account_conclave_reads_message on private.account_conclave_reads(message_id);
alter table private.account_conclave_reads enable row level security;
revoke all on private.account_conclave_reads from public,anon,authenticated,service_role;

create function public.mark_my_conclave_messages_read(p_message_ids uuid[])
returns void language plpgsql security definer set search_path='' as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if coalesce(cardinality(p_message_ids),0)>200 then raise exception 'too_many_messages'; end if;
  insert into private.account_conclave_reads(user_id,message_id)
    select auth.uid(),m.id from public.conclave_messages m
    join public.conclave_members cm on cm.conclave_id=m.conclave_id and cm.user_id=auth.uid()
    where m.id=any(p_message_ids) and m.created_at>=now()-interval '24 hours' and m.created_at<=now()
    on conflict do nothing;
end $$;
revoke all on function public.mark_my_conclave_messages_read(uuid[]) from public,anon;
grant execute on function public.mark_my_conclave_messages_read(uuid[]) to authenticated;

create or replace function public.get_my_conclave_snapshot()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare cid uuid; result jsonb;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  perform private.cleanup_ephemeral_social_content();
  select conclave_id into cid from public.conclave_members where user_id=auth.uid();
  if cid is null then return null; end if;
  select jsonb_build_object(
    'conclave',jsonb_build_object('conclave_id',c.id,'name',c.name,'emblem_key',c.emblem_key,'description',c.description,'language',c.language,'visibility',c.visibility,'member_limit',c.member_limit,'member_count',(select count(*) from public.conclave_members where conclave_id=c.id),'level',c.level,'xp',c.xp,'aerie_stage',least(10,1+((c.level-1)/5))),
    'read_message_ids',coalesce((select jsonb_agg(r.message_id order by r.message_id) from private.account_conclave_reads r join public.conclave_messages m on m.id=r.message_id where r.user_id=auth.uid() and m.conclave_id=cid and m.created_at>=now()-interval '24 hours'),'[]'::jsonb),
    'seasonal_projects',private.seasonal_conclave_project_snapshot(cid),
    'my_role',(select role from public.conclave_members where conclave_id=cid and user_id=auth.uid()),
    'contributed_today',(select last_contribution_on=(now() at time zone 'utc')::date from public.conclave_members where conclave_id=cid and user_id=auth.uid()),
    'members',coalesce((select jsonb_agg(jsonb_build_object('user_id',p.user_id,'keeper_code',p.keeper_code,'display_name',p.display_name,'title',p.title,'portrait_key',p.portrait_key,'frame_key',p.frame_key,'badge_key',p.badge_key,'role',m.role,'joined_at',m.joined_at,'contribution_streak',m.contribution_streak) order by case m.role when 'flightmaster' then 0 when 'warden' then 1 else 2 end,lower(p.display_name)) from public.conclave_members m join public.profiles p on p.user_id=m.user_id where m.conclave_id=cid),'[]'::jsonb),
    'messages',coalesce((select jsonb_agg(jsonb_build_object('message_id',m.id,'sender_id',m.sender_id,'sender_name',p.display_name,'sender_portrait_key',p.portrait_key,'kind',m.kind,'body',m.body,'payload',m.payload,'created_at',m.created_at) order by m.created_at) from public.conclave_messages m join public.profiles p on p.user_id=m.sender_id where m.conclave_id=cid and m.created_at>=now()-interval '24 hours'),'[]'::jsonb),
    'chronicle',coalesce((select jsonb_agg(entry order by created_at desc) from (select jsonb_build_object('entry_id',ch.id,'actor_name',p.display_name,'kind',ch.kind,'body',ch.body,'created_at',ch.created_at) entry,ch.created_at from public.conclave_chronicle ch left join public.profiles p on p.user_id=ch.actor_id where ch.conclave_id=cid order by ch.created_at desc limit 100) q),'[]'::jsonb),
    'join_requests',case when exists(select 1 from public.conclave_members where conclave_id=cid and user_id=auth.uid() and role in ('flightmaster','warden')) then coalesce((select jsonb_agg(jsonb_build_object('request_id',r.id,'user_id',p.user_id,'keeper_code',p.keeper_code,'display_name',p.display_name,'portrait_key',p.portrait_key,'created_at',r.created_at) order by r.created_at) from public.conclave_join_requests r join public.profiles p on p.user_id=r.user_id where r.conclave_id=cid),'[]'::jsonb) else '[]'::jsonb end
  ) into result from public.conclaves c where c.id=cid;
  return result;
end
$$;
