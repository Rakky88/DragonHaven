-- DragonHaven: private friend messages and Conclaves.
-- Chat content is retained for at most 24 hours. Supabase Cron performs the
-- regular cleanup and every read/write also removes old rows as a fallback.

alter table public.profiles
  add column if not exists friend_messages_allowed boolean not null default true,
  add column if not exists share_achievements_with_conclave boolean not null default false;

alter table public.social_notifications
  drop constraint if exists social_notifications_kind_check;
alter table public.social_notifications add constraint social_notifications_kind_check
  check (kind in (
    'friend_request', 'friend_accepted', 'friend_message',
    'trade_request', 'trade_return', 'trade_completed'
  ));

create table public.friend_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(user_id) on delete cascade,
  recipient_id uuid not null references public.profiles(user_id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 500),
  created_at timestamptz not null default now(),
  read_at timestamptz,
  check (sender_id <> recipient_id)
);
create index friend_messages_pair_time_idx
  on public.friend_messages(sender_id, recipient_id, created_at desc);
create index friend_messages_unread_idx
  on public.friend_messages(recipient_id, created_at desc) where read_at is null;
alter table public.friend_messages enable row level security;
revoke all on table public.friend_messages from anon, authenticated;

create table public.conclaves (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 3 and 30),
  emblem_key text not null check (emblem_key ~ '^conclave_emblem_(0[1-9]|1[0-9]|20)$'),
  description text not null default '' check (char_length(description) <= 280),
  language text not null check (language in ('de','en','es','fr','it','nl','pt','ja')),
  visibility text not null check (visibility in ('public','request','invite')),
  member_limit integer not null check (member_limit between 4 and 20),
  xp integer not null default 0 check (xp >= 0),
  level integer not null default 1 check (level between 1 and 50),
  created_by uuid references public.profiles(user_id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index conclaves_name_unique_idx on public.conclaves(lower(btrim(name)));
alter table public.conclaves enable row level security;
revoke all on table public.conclaves from anon, authenticated;

create table public.conclave_members (
  conclave_id uuid not null references public.conclaves(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  role text not null check (role in ('flightmaster','warden','keeper')),
  joined_at timestamptz not null default now(),
  last_contribution_on date,
  contribution_streak integer not null default 0 check (contribution_streak >= 0),
  primary key (conclave_id, user_id),
  unique (user_id)
);
create unique index conclave_one_flightmaster_idx
  on public.conclave_members(conclave_id) where role = 'flightmaster';
alter table public.conclave_members enable row level security;
revoke all on table public.conclave_members from anon, authenticated;

-- This durable ledger prevents leaving/rejoining (or rapidly rotating the
-- roster) from earning more than twenty Aerie contributions per UTC day.
create table public.conclave_daily_contributions (
  id uuid primary key default gen_random_uuid(),
  conclave_id uuid not null references public.conclaves(id) on delete cascade,
  contribution_on date not null,
  user_id uuid references public.profiles(user_id) on delete set null,
  created_at timestamptz not null default now(),
  unique (conclave_id, contribution_on, user_id)
);
alter table public.conclave_daily_contributions enable row level security;
revoke all on table public.conclave_daily_contributions from anon, authenticated;

create table public.conclave_join_requests (
  id uuid primary key default gen_random_uuid(),
  conclave_id uuid not null references public.conclaves(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (conclave_id, user_id)
);
alter table public.conclave_join_requests enable row level security;
revoke all on table public.conclave_join_requests from anon, authenticated;

create table public.conclave_invites (
  id uuid primary key default gen_random_uuid(),
  conclave_id uuid not null references public.conclaves(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  invited_by uuid not null references public.profiles(user_id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days'),
  unique (conclave_id, user_id)
);
alter table public.conclave_invites enable row level security;
revoke all on table public.conclave_invites from anon, authenticated;

create table public.conclave_messages (
  id uuid primary key default gen_random_uuid(),
  conclave_id uuid not null references public.conclaves(id) on delete cascade,
  sender_id uuid not null references public.profiles(user_id) on delete cascade,
  kind text not null default 'text' check (kind in ('text','achievement','dragon','trial')),
  body text not null check (char_length(btrim(body)) between 1 and 500),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  check (pg_column_size(payload) <= 4096)
);
create index conclave_messages_time_idx
  on public.conclave_messages(conclave_id, created_at desc);
alter table public.conclave_messages enable row level security;
revoke all on table public.conclave_messages from anon, authenticated;

create table public.conclave_chronicle (
  id uuid primary key default gen_random_uuid(),
  conclave_id uuid not null references public.conclaves(id) on delete cascade,
  actor_id uuid references public.profiles(user_id) on delete set null,
  kind text not null check (kind in ('created','joined','left','role','level','achievement')),
  body text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now()
);
create index conclave_chronicle_time_idx
  on public.conclave_chronicle(conclave_id, created_at desc);
alter table public.conclave_chronicle enable row level security;
revoke all on table public.conclave_chronicle from anon, authenticated;

create table public.conclave_achievement_shares (
  conclave_id uuid not null references public.conclaves(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  achievement_id text not null check (char_length(achievement_id) between 1 and 80),
  shared_at timestamptz not null default now(),
  primary key (conclave_id, user_id, achievement_id)
);
alter table public.conclave_achievement_shares enable row level security;
revoke all on table public.conclave_achievement_shares from anon, authenticated;

-- A Conclave name is chosen once, when the Conclave is founded. Keep this
-- invariant in the database so a future client or RPC cannot rename it.
create or replace function private.prevent_conclave_name_change()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.name is distinct from old.name then
    raise exception 'conclave_name_immutable';
  end if;
  return new;
end
$$;

create trigger conclave_name_is_immutable
before update of name on public.conclaves
for each row execute function private.prevent_conclave_name_change();

-- Account deletion must never strand a Conclave without a Flightmaster.
-- Prefer a Warden, then the longest-serving Keeper; dissolve an empty group.
create or replace function private.reassign_departing_flightmaster()
returns trigger language plpgsql security definer set search_path = '' as $$
declare successor uuid;
begin
  if old.role <> 'flightmaster'
    or not exists(select 1 from public.conclaves where id = old.conclave_id) then
    return old;
  end if;
  select m.user_id into successor
  from public.conclave_members m
  where m.conclave_id = old.conclave_id and m.user_id <> old.user_id
  order by case m.role when 'warden' then 0 else 1 end, m.joined_at, m.user_id
  limit 1;
  if successor is null then
    delete from public.conclaves where id = old.conclave_id;
  else
    update public.conclave_members set role = 'flightmaster'
    where conclave_id = old.conclave_id and user_id = successor;
    insert into public.conclave_chronicle(conclave_id,actor_id,kind,body)
      values(old.conclave_id,successor,'role','A new Flightmaster now leads the Conclave.');
  end if;
  return old;
end
$$;

create trigger conclave_flightmaster_departure
after delete on public.conclave_members
for each row execute function private.reassign_departing_flightmaster();

create or replace function private.are_friends(p_first uuid, p_second uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and ((f.requester_id = p_first and f.addressee_id = p_second)
        or (f.requester_id = p_second and f.addressee_id = p_first))
  )
$$;

create or replace function private.cleanup_ephemeral_social_content()
returns void language plpgsql security definer set search_path = '' as $$
begin
  delete from public.friend_messages where created_at < now() - interval '24 hours';
  delete from public.conclave_messages where created_at < now() - interval '24 hours';
  delete from public.social_notifications n
  where n.kind = 'friend_message'
    and not exists(select 1 from public.friend_messages m where m.id = n.entity_id);
  delete from public.conclave_invites where expires_at <= now();
end
$$;

create or replace function public.set_social_preferences(
  p_friend_messages_allowed boolean,
  p_share_achievements_with_conclave boolean
) returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  update public.profiles set
    friend_messages_allowed = p_friend_messages_allowed,
    share_achievements_with_conclave = p_share_achievements_with_conclave
  where user_id = auth.uid();
end
$$;

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
    latest.body, latest.created_at, latest.sender_id = auth.uid()
  from friend_rows fr
  join public.profiles p on p.user_id = fr.id
  left join public.friend_messages m on
    (m.sender_id = auth.uid() and m.recipient_id = fr.id)
    or (m.sender_id = fr.id and m.recipient_id = auth.uid())
  left join lateral (
    select lm.body, lm.created_at, lm.sender_id from public.friend_messages lm
    where (lm.sender_id = auth.uid() and lm.recipient_id = fr.id)
       or (lm.sender_id = fr.id and lm.recipient_id = auth.uid())
    order by lm.created_at desc limit 1
  ) latest on true
  group by fr.id, p.friend_messages_allowed, latest.body, latest.created_at, latest.sender_id
  order by coalesce(latest.created_at, '-infinity'::timestamptz) desc, fr.id;
end
$$;

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

create or replace function public.send_friend_message(p_friend_id uuid, p_body text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare new_id uuid; recipient_allows boolean;
begin
  if auth.uid() is null or not private.are_friends(auth.uid(), p_friend_id) then
    raise exception 'messages_not_friends';
  end if;
  select friend_messages_allowed into recipient_allows from public.profiles where user_id = p_friend_id;
  if not coalesce(recipient_allows, false) then raise exception 'messages_disabled'; end if;
  if char_length(btrim(coalesce(p_body,''))) not between 1 and 500 then raise exception 'message_invalid'; end if;
  perform private.cleanup_ephemeral_social_content();
  if exists (select 1 from public.friend_messages where sender_id = auth.uid() and created_at > now() - interval '1 second')
    or (select count(*) from public.friend_messages where sender_id = auth.uid() and created_at > now() - interval '1 hour') >= 60 then
    raise exception 'message_rate_limited';
  end if;
  insert into public.friend_messages(sender_id, recipient_id, body)
    values (auth.uid(), p_friend_id, btrim(p_body)) returning id into new_id;
  insert into public.social_notifications(user_id, kind, actor_id, entity_id)
    values (p_friend_id, 'friend_message', auth.uid(), new_id);
  return new_id;
end
$$;

create or replace function public.create_conclave(
  p_name text, p_emblem_key text, p_description text, p_language text,
  p_visibility text, p_member_limit integer
) returns uuid language plpgsql security definer set search_path = '' as $$
declare new_id uuid;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if exists (select 1 from public.conclave_members where user_id = auth.uid()) then raise exception 'already_in_conclave'; end if;
  insert into public.conclaves(name, emblem_key, description, language, visibility, member_limit, created_by)
    values (btrim(p_name), p_emblem_key, btrim(coalesce(p_description,'')), p_language, p_visibility, p_member_limit, auth.uid())
    returning id into new_id;
  insert into public.conclave_members(conclave_id,user_id,role) values(new_id,auth.uid(),'flightmaster');
  insert into public.conclave_chronicle(conclave_id,actor_id,kind,body)
    values(new_id,auth.uid(),'created','The Conclave was founded and its first Aerie took shape.');
  return new_id;
exception when unique_violation then raise exception 'conclave_name_taken';
end
$$;

create or replace function public.list_conclaves()
returns table (
  conclave_id uuid, name text, emblem_key text, description text, language text,
  visibility text, member_limit integer, member_count bigint, level integer,
  xp integer, aerie_stage integer, requested boolean
) language sql stable security definer set search_path = '' as $$
  select c.id,c.name,c.emblem_key,c.description,c.language,c.visibility,c.member_limit,
    count(cm.user_id),c.level,c.xp,least(10,1+((c.level-1)/5)),
    exists(select 1 from public.conclave_join_requests r where r.conclave_id=c.id and r.user_id=auth.uid())
  from public.conclaves c left join public.conclave_members cm on cm.conclave_id=c.id
  where auth.uid() is not null and c.visibility <> 'invite'
  group by c.id order by c.level desc, count(cm.user_id) desc, lower(c.name) limit 100
$$;

create or replace function public.request_or_join_conclave(p_conclave_id uuid)
returns text language plpgsql security definer set search_path = '' as $$
declare target public.conclaves; member_count integer;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if exists(select 1 from public.conclave_members where user_id=auth.uid()) then raise exception 'already_in_conclave'; end if;
  select * into target from public.conclaves where id=p_conclave_id for update;
  if not found then raise exception 'conclave_not_found'; end if;
  select count(*) into member_count from public.conclave_members where conclave_id=p_conclave_id;
  if member_count >= target.member_limit then raise exception 'conclave_full'; end if;
  if target.visibility='invite' then raise exception 'conclave_invite_required'; end if;
  if target.visibility='request' then
    insert into public.conclave_join_requests(conclave_id,user_id) values(p_conclave_id,auth.uid()) on conflict do nothing;
    return 'requested';
  end if;
  insert into public.conclave_members(conclave_id,user_id,role) values(p_conclave_id,auth.uid(),'keeper');
  insert into public.conclave_chronicle(conclave_id,actor_id,kind,body) values(p_conclave_id,auth.uid(),'joined','A new Keeper joined the Conclave.');
  return 'joined';
end
$$;

create or replace function public.respond_conclave_join_request(p_request_id uuid, p_accept boolean)
returns void language plpgsql security definer set search_path = '' as $$
declare req public.conclave_join_requests; actor_role text; member_count integer; member_limit integer;
begin
  select * into req from public.conclave_join_requests where id=p_request_id for update;
  if not found then raise exception 'conclave_request_not_found'; end if;
  select role into actor_role from public.conclave_members where conclave_id=req.conclave_id and user_id=auth.uid();
  if actor_role is null or actor_role not in ('flightmaster','warden') then raise exception 'conclave_permission_denied'; end if;
  if p_accept then
    select c.member_limit into member_limit from public.conclaves c where c.id=req.conclave_id for update;
    select count(*) into member_count from public.conclave_members cm where cm.conclave_id=req.conclave_id;
    if member_count >= member_limit then raise exception 'conclave_full'; end if;
    if exists(select 1 from public.conclave_members where user_id=req.user_id) then raise exception 'already_in_conclave'; end if;
    insert into public.conclave_members(conclave_id,user_id,role) values(req.conclave_id,req.user_id,'keeper');
    insert into public.conclave_chronicle(conclave_id,actor_id,kind,body) values(req.conclave_id,req.user_id,'joined','A new Keeper joined the Conclave.');
  end if;
  delete from public.conclave_join_requests where id=p_request_id;
end
$$;

create or replace function public.invite_to_conclave(p_keeper_code text)
returns void language plpgsql security definer set search_path = '' as $$
declare cid uuid; actor_role text; target_id uuid;
begin
  select conclave_id,role into cid,actor_role from public.conclave_members where user_id=auth.uid();
  if actor_role is null or actor_role not in ('flightmaster','warden') then raise exception 'conclave_permission_denied'; end if;
  select user_id into target_id from public.profiles where keeper_code=upper(btrim(p_keeper_code));
  if target_id is null or target_id=auth.uid() then raise exception 'keeper_not_found'; end if;
  if exists(select 1 from public.conclave_members where user_id=target_id) then raise exception 'already_in_conclave'; end if;
  insert into public.conclave_invites(conclave_id,user_id,invited_by) values(cid,target_id,auth.uid())
  on conflict(conclave_id,user_id) do update set invited_by=excluded.invited_by,created_at=now(),expires_at=now()+interval '7 days';
end
$$;

create or replace function public.respond_conclave_invite(p_invite_id uuid, p_accept boolean)
returns void language plpgsql security definer set search_path = '' as $$
declare inv public.conclave_invites; member_count integer; member_limit integer;
begin
  perform private.cleanup_ephemeral_social_content();
  select * into inv from public.conclave_invites where id=p_invite_id and user_id=auth.uid() for update;
  if not found then raise exception 'conclave_invite_not_found'; end if;
  if p_accept then
    if exists(select 1 from public.conclave_members where user_id=auth.uid()) then raise exception 'already_in_conclave'; end if;
    select c.member_limit into member_limit from public.conclaves c where c.id=inv.conclave_id for update;
    select count(*) into member_count from public.conclave_members cm where cm.conclave_id=inv.conclave_id;
    if member_count >= member_limit then raise exception 'conclave_full'; end if;
    insert into public.conclave_members(conclave_id,user_id,role) values(inv.conclave_id,auth.uid(),'keeper');
    insert into public.conclave_chronicle(conclave_id,actor_id,kind,body) values(inv.conclave_id,auth.uid(),'joined','A new Keeper joined the Conclave.');
  end if;
  delete from public.conclave_invites where id=p_invite_id;
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

create or replace function public.send_conclave_message(p_kind text,p_body text,p_payload jsonb default '{}'::jsonb)
returns uuid language plpgsql security definer set search_path = '' as $$
declare cid uuid; new_id uuid;
begin
  select conclave_id into cid from public.conclave_members where user_id=auth.uid();
  if cid is null then raise exception 'not_in_conclave'; end if;
  if p_kind not in ('text','achievement','dragon','trial') or char_length(btrim(coalesce(p_body,''))) not between 1 and 500 or pg_column_size(coalesce(p_payload,'{}'::jsonb))>4096 then raise exception 'message_invalid'; end if;
  perform private.cleanup_ephemeral_social_content();
  if (select count(*) from public.conclave_messages where sender_id=auth.uid() and created_at>now()-interval '1 hour')>=90 then raise exception 'message_rate_limited'; end if;
  insert into public.conclave_messages(conclave_id,sender_id,kind,body,payload)
    values(cid,auth.uid(),p_kind,btrim(p_body),coalesce(p_payload,'{}'::jsonb)) returning id into new_id;
  return new_id;
end
$$;

create or replace function public.synchronize_conclave_achievements(p_achievement_ids text[])
returns integer language plpgsql security definer set search_path = '' as $$
declare cid uuid; achievement text; inserted_count integer:=0;
begin
  select cm.conclave_id into cid from public.conclave_members cm join public.profiles p on p.user_id=cm.user_id
    where cm.user_id=auth.uid() and p.share_achievements_with_conclave;
  if cid is null then return 0; end if;
  foreach achievement in array coalesce(p_achievement_ids,array[]::text[]) loop
    if char_length(achievement) between 1 and 80 then
      insert into public.conclave_achievement_shares(conclave_id,user_id,achievement_id) values(cid,auth.uid(),achievement) on conflict do nothing;
      if found then
        insert into public.conclave_messages(conclave_id,sender_id,kind,body,payload) values(cid,auth.uid(),'achievement','Achievement unlocked!',jsonb_build_object('achievement_id',achievement));
        insert into public.conclave_chronicle(conclave_id,actor_id,kind,body) values(cid,auth.uid(),'achievement','A Keeper shared a new achievement.');
        inserted_count:=inserted_count+1;
      end if;
    end if;
  end loop;
  return inserted_count;
end
$$;

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

create or replace function public.list_my_conclave_invites()
returns table(invite_id uuid,conclave_id uuid,name text,emblem_key text,level integer,member_count bigint,expires_at timestamptz)
language plpgsql security definer set search_path = '' as $$
begin
  perform private.cleanup_ephemeral_social_content();
  return query select i.id,c.id,c.name,c.emblem_key,c.level,count(m.user_id),i.expires_at
    from public.conclave_invites i join public.conclaves c on c.id=i.conclave_id left join public.conclave_members m on m.conclave_id=c.id
    where i.user_id=auth.uid() group by i.id,c.id,c.name,c.emblem_key,c.level,i.expires_at order by i.created_at desc;
end
$$;

create or replace function public.leave_conclave()
returns void language plpgsql security definer set search_path = '' as $$
declare member public.conclave_members;
begin
  select * into member from public.conclave_members where user_id=auth.uid();
  if not found then raise exception 'not_in_conclave'; end if;
  if member.role='flightmaster' then raise exception 'flightmaster_must_transfer_or_dissolve'; end if;
  delete from public.conclave_members where conclave_id=member.conclave_id and user_id=auth.uid();
  insert into public.conclave_chronicle(conclave_id,actor_id,kind,body) values(member.conclave_id,auth.uid(),'left','A Keeper left the Conclave.');
end
$$;

create or replace function public.set_conclave_member_role(p_user_id uuid,p_role text)
returns void language plpgsql security definer set search_path = '' as $$
declare cid uuid; actor_role text;
begin
  select conclave_id,role into cid,actor_role from public.conclave_members where user_id=auth.uid();
  if actor_role is null or actor_role<>'flightmaster' or p_user_id=auth.uid() or p_role not in ('warden','keeper') then raise exception 'conclave_permission_denied'; end if;
  update public.conclave_members set role=p_role where conclave_id=cid and user_id=p_user_id and role<>'flightmaster';
  if not found then raise exception 'conclave_member_not_found'; end if;
  insert into public.conclave_chronicle(conclave_id,actor_id,kind,body) values(cid,p_user_id,'role','A Conclave role was changed to '||p_role||'.');
end
$$;

create or replace function public.transfer_conclave(p_user_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare cid uuid;
begin
  select conclave_id into cid from public.conclave_members where user_id=auth.uid() and role='flightmaster';
  if cid is null or p_user_id=auth.uid() then raise exception 'conclave_permission_denied'; end if;
  if not exists(select 1 from public.conclave_members where conclave_id=cid and user_id=p_user_id) then raise exception 'conclave_member_not_found'; end if;
  update public.conclave_members set role='warden' where conclave_id=cid and user_id=auth.uid();
  update public.conclave_members set role='flightmaster' where conclave_id=cid and user_id=p_user_id;
  insert into public.conclave_chronicle(conclave_id,actor_id,kind,body) values(cid,p_user_id,'role','A new Flightmaster now leads the Conclave.');
end
$$;

create or replace function public.remove_conclave_member(p_user_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare cid uuid; actor_role text; target_role text;
begin
  select conclave_id,role into cid,actor_role from public.conclave_members where user_id=auth.uid();
  select role into target_role from public.conclave_members where conclave_id=cid and user_id=p_user_id;
  if p_user_id=auth.uid() or target_role is null or target_role='flightmaster' or actor_role not in ('flightmaster','warden') or (actor_role='warden' and target_role='warden') then raise exception 'conclave_permission_denied'; end if;
  delete from public.conclave_members where conclave_id=cid and user_id=p_user_id;
  insert into public.conclave_chronicle(conclave_id,actor_id,kind,body) values(cid,p_user_id,'left','A Keeper was removed from the Conclave.');
end
$$;

create or replace function public.dissolve_conclave()
returns void language plpgsql security definer set search_path = '' as $$
declare cid uuid;
begin
  select conclave_id into cid from public.conclave_members where user_id=auth.uid() and role='flightmaster';
  if cid is null then raise exception 'conclave_permission_denied'; end if;
  delete from public.conclaves where id=cid;
end
$$;

drop function if exists public.get_online_snapshot();
create function public.get_online_snapshot()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  if auth.uid() is null then raise exception 'group_login_required'; end if;
  select jsonb_build_object(
    'profile',(select to_jsonb(x) from public.get_my_profile() x limit 1),
    'friends',coalesce((select jsonb_agg(to_jsonb(x)) from public.list_my_friends() x),'[]'::jsonb),
    'requests',coalesce((select jsonb_agg(to_jsonb(x)) from public.list_friend_requests() x),'[]'::jsonb),
    'blocked_keepers',coalesce((select jsonb_agg(to_jsonb(x)) from public.list_blocked_keepers() x),'[]'::jsonb),
    'group_status',(select to_jsonb(x) from public.get_current_group_adventure_status() x limit 1),
    'group_lobbies',coalesce((select jsonb_agg(to_jsonb(x)) from public.list_group_adventures() x),'[]'::jsonb),
    'trades',coalesce((select jsonb_agg(to_jsonb(x)) from public.list_my_trades() x),'[]'::jsonb),
    'trade_inventory',coalesce((select jsonb_agg(to_jsonb(x)) from public.list_trade_inventory() x),'[]'::jsonb),
    'notifications',coalesce((select jsonb_agg(to_jsonb(x)) from public.list_social_notifications() x),'[]'::jsonb),
    'social_settings',(select jsonb_build_object('friend_messages_allowed',p.friend_messages_allowed,'share_achievements_with_conclave',p.share_achievements_with_conclave) from public.profiles p where p.user_id=auth.uid()),
    'friend_conversations',coalesce((select jsonb_agg(to_jsonb(x)) from public.list_friend_conversations() x),'[]'::jsonb),
    'conclave',public.get_my_conclave_snapshot(),
    'conclave_invites',coalesce((select jsonb_agg(to_jsonb(x)) from public.list_my_conclave_invites() x),'[]'::jsonb)
  ) into result;
  if result->'profile'='null'::jsonb or result->'group_status'='null'::jsonb then raise exception 'invalid_online_snapshot'; end if;
  return result;
end
$$;

revoke all on function private.are_friends(uuid,uuid) from public,anon,authenticated;
revoke all on function private.cleanup_ephemeral_social_content() from public,anon,authenticated;
revoke all on function private.prevent_conclave_name_change() from public,anon,authenticated;
revoke all on function private.reassign_departing_flightmaster() from public,anon,authenticated;
revoke all on function public.set_social_preferences(boolean,boolean) from public,anon;
revoke all on function public.list_friend_conversations() from public,anon;
revoke all on function public.open_friend_messages(uuid) from public,anon;
revoke all on function public.send_friend_message(uuid,text) from public,anon;
revoke all on function public.create_conclave(text,text,text,text,text,integer) from public,anon;
revoke all on function public.list_conclaves() from public,anon;
revoke all on function public.request_or_join_conclave(uuid) from public,anon;
revoke all on function public.respond_conclave_join_request(uuid,boolean) from public,anon;
revoke all on function public.invite_to_conclave(text) from public,anon;
revoke all on function public.respond_conclave_invite(uuid,boolean) from public,anon;
revoke all on function public.contribute_to_conclave() from public,anon;
revoke all on function public.send_conclave_message(text,text,jsonb) from public,anon;
revoke all on function public.synchronize_conclave_achievements(text[]) from public,anon;
revoke all on function public.get_my_conclave_snapshot() from public,anon;
revoke all on function public.list_my_conclave_invites() from public,anon;
revoke all on function public.leave_conclave() from public,anon;
revoke all on function public.set_conclave_member_role(uuid,text) from public,anon;
revoke all on function public.transfer_conclave(uuid) from public,anon;
revoke all on function public.remove_conclave_member(uuid) from public,anon;
revoke all on function public.dissolve_conclave() from public,anon;
revoke all on function public.get_online_snapshot() from public,anon;

grant execute on function public.set_social_preferences(boolean,boolean) to authenticated;
grant execute on function public.list_friend_conversations() to authenticated;
grant execute on function public.open_friend_messages(uuid) to authenticated;
grant execute on function public.send_friend_message(uuid,text) to authenticated;
grant execute on function public.create_conclave(text,text,text,text,text,integer) to authenticated;
grant execute on function public.list_conclaves() to authenticated;
grant execute on function public.request_or_join_conclave(uuid) to authenticated;
grant execute on function public.respond_conclave_join_request(uuid,boolean) to authenticated;
grant execute on function public.invite_to_conclave(text) to authenticated;
grant execute on function public.respond_conclave_invite(uuid,boolean) to authenticated;
grant execute on function public.contribute_to_conclave() to authenticated;
grant execute on function public.send_conclave_message(text,text,jsonb) to authenticated;
grant execute on function public.synchronize_conclave_achievements(text[]) to authenticated;
grant execute on function public.get_my_conclave_snapshot() to authenticated;
grant execute on function public.list_my_conclave_invites() to authenticated;
grant execute on function public.leave_conclave() to authenticated;
grant execute on function public.set_conclave_member_role(uuid,text) to authenticated;
grant execute on function public.transfer_conclave(uuid) to authenticated;
grant execute on function public.remove_conclave_member(uuid) to authenticated;
grant execute on function public.dissolve_conclave() to authenticated;
grant execute on function public.get_online_snapshot() to authenticated;

-- The existing Supabase Cron extension performs the retention guarantee even
-- while no player opens either chat. Opportunistic cleanup remains a fallback.
create extension if not exists pg_cron;
select cron.schedule(
  'dragonhaven-ephemeral-social-cleanup',
  '*/5 * * * *',
  'select private.cleanup_ephemeral_social_content()'
);
