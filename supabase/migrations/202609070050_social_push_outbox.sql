-- Optional, dormant push delivery. No Firebase credentials in SQL or app builds.
create table private.push_runtime (
  singleton boolean primary key default true check (singleton),
  enabled boolean not null default false,
  monthly_dispatch_limit integer not null default 45000
    check (monthly_dispatch_limit between 1 and 45000)
);
insert into private.push_runtime(singleton) values (true);

create table private.push_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  installation_id uuid not null unique,
  token text not null unique check (length(token) between 20 and 4096),
  generation uuid not null default gen_random_uuid(),
  language_code text not null default 'en'
    check (language_code in ('de','en','es','fr','it','nl','pt','ja')),
  enabled_kinds text[] not null,
  updated_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '30 days',
  check (enabled_kinds <@ array['friend_request','friend_accepted','friend_message',
    'trade_request','trade_return','trade_completed','seasonal_pair_invite',
    'seasonal_pair_accepted','seasonal_pair_ready']::text[])
);
create index push_devices_owner_idx on private.push_devices(user_id, expires_at);

create table private.social_push_outbox (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references public.social_notifications(id) on delete cascade,
  device_id uuid not null references private.push_devices(id) on delete cascade,
  device_generation uuid not null,
  state text not null default 'pending'
    check (state in ('pending','leased','accepted','cancelled','failed')),
  attempts integer not null default 0 check (attempts between 0 and 6),
  next_attempt_at timestamptz not null default now(),
  lease_token uuid,
  lease_until timestamptz,
  last_result text check (last_result in ('accepted','unregistered','retry','permanent_error')),
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  unique(notification_id, device_id, device_generation)
);
create index social_push_pending_idx on private.social_push_outbox(next_attempt_at, id)
  where state in ('pending','leased');

alter table private.push_runtime enable row level security;
alter table private.push_devices enable row level security;
alter table private.social_push_outbox enable row level security;
revoke all on private.push_runtime, private.push_devices, private.social_push_outbox
  from public, anon, authenticated, service_role;

create function public.register_my_push_device(
  p_expected_user_id uuid, p_installation_id uuid, p_token text, p_language_code text,
  p_enabled_kinds text[]
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare keeper uuid := auth.uid(); existing private.push_devices%rowtype;
  kinds text[]; device uuid; delivery_enabled boolean;
begin
  if keeper is null or keeper is distinct from p_expected_user_id or not exists(select 1 from auth.users u
    where u.id = keeper and u.email_confirmed_at is not null) then
    raise exception 'push_login_required';
  end if;
  if p_installation_id is null or p_token is null or length(p_token) not between 20 and 4096
    or p_token ~ '[[:space:]]' or p_language_code is null
    or p_language_code not in ('de','en','es','fr','it','nl','pt','ja')
    or p_enabled_kinds is null or cardinality(p_enabled_kinds) > 9
    or array_position(p_enabled_kinds, null) is not null
    or not (p_enabled_kinds <@ array['friend_request','friend_accepted','friend_message',
      'trade_request','trade_return','trade_completed','seasonal_pair_invite',
      'seasonal_pair_accepted','seasonal_pair_ready']::text[]) then
    raise exception 'push_request_invalid';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(keeper::text, 50));
  select coalesce(array_agg(distinct k order by k), '{}'::text[]) into kinds
    from unnest(p_enabled_kinds) k;
  select * into existing from private.push_devices d
    where d.installation_id = p_installation_id for update;
  -- Ownership transitions require the current opaque FCM token or prior logout.
  -- An installation ID alone is never authority to remove another owner's row.
  if found and existing.user_id <> keeper and existing.token <> p_token then
    raise exception 'push_installation_owned';
  end if;
  delete from private.push_devices d where d.token = p_token
    and d.installation_id <> p_installation_id;
  insert into private.push_devices(user_id, installation_id, token, language_code, enabled_kinds)
    values(keeper, p_installation_id, p_token, p_language_code, kinds)
  on conflict (installation_id) do update set
    user_id = excluded.user_id, token = excluded.token,
    language_code = excluded.language_code, enabled_kinds = excluded.enabled_kinds,
    generation = case when private.push_devices.user_id <> excluded.user_id
      or private.push_devices.token <> excluded.token
      then gen_random_uuid() else private.push_devices.generation end,
    updated_at = now(), expires_at = now() + interval '30 days'
  returning id into device;
  -- Limit push installations, not players' accounts or inventory.
  delete from private.push_devices d where d.user_id = keeper and d.id in (
    select old.id from private.push_devices old where old.user_id = keeper
    order by old.updated_at desc, old.id desc offset 5
  );
  update private.social_push_outbox o set state = 'cancelled', completed_at = now()
    from private.push_devices d, public.social_notifications n
    where o.device_id = device and d.id = o.device_id and n.id = o.notification_id
      and o.state in ('pending','leased')
      and (o.device_generation <> d.generation or n.user_id <> keeper
        or not (n.kind = any(kinds)));
  select r.enabled into delivery_enabled from private.push_runtime r where singleton;
  return jsonb_build_object('registered', true, 'delivery_enabled', delivery_enabled);
end;
$$;

create function public.unregister_my_push_device(p_installation_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'push_login_required'; end if;
  delete from private.push_devices where user_id = auth.uid()
    and installation_id = p_installation_id;
end;
$$;

create function private.enqueue_social_push() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.acknowledged_at is not null then
    update private.social_push_outbox set state = 'cancelled', completed_at = now()
      where notification_id = new.id and state in ('pending','leased');
  elsif tg_op = 'INSERT' and (select enabled from private.push_runtime where singleton) then
    insert into private.social_push_outbox(notification_id, device_id, device_generation)
      select new.id, d.id, d.generation from private.push_devices d
      where d.user_id = new.user_id and d.expires_at > now()
        and new.kind = any(d.enabled_kinds)
      on conflict do nothing;
  end if;
  return new;
end;
$$;
create trigger social_notifications_enqueue_push
after insert or update of acknowledged_at on public.social_notifications
for each row execute function private.enqueue_social_push();

create function public.lease_social_pushes(p_limit integer default 30)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  if auth.role() is distinct from 'service_role' then raise exception 'push_worker_required'; end if;
  if p_limit is null or p_limit not between 1 and 30 then raise exception 'push_request_invalid'; end if;
  if not (select enabled from private.push_runtime where singleton) then return '[]'::jsonb; end if;
  update private.social_push_outbox o set state = 'cancelled', completed_at = now()
    from private.push_devices d, public.social_notifications n
    where o.device_id = d.id and o.notification_id = n.id
      and o.state in ('pending','leased')
      and (d.generation <> o.device_generation or d.user_id <> n.user_id
        or d.expires_at <= now() or n.acknowledged_at is not null
        or not (n.kind = any(d.enabled_kinds))
        or n.created_at < now() - interval '24 hours');
  update private.social_push_outbox set state = 'failed', completed_at = now()
    where state in ('pending','leased') and attempts >= 6
      and (lease_until is null or lease_until < now());
  with candidates as (
    select o.id from private.social_push_outbox o
    where o.attempts < 6 and o.next_attempt_at <= now()
      and (o.state = 'pending' or (o.state = 'leased' and o.lease_until < now()))
    order by o.next_attempt_at, o.id limit p_limit for update skip locked
  ), leased as (
    update private.social_push_outbox o set state = 'leased', attempts = attempts + 1,
      lease_token = gen_random_uuid(), lease_until = now() + interval '2 minutes'
    from candidates c where o.id = c.id
    returning o.id, o.notification_id, o.device_id, o.lease_token
  ) select coalesce(jsonb_agg(jsonb_build_object(
      'job_id', l.id, 'lease_token', l.lease_token,
      'notification_id', l.notification_id, 'token', d.token,
      'language_code', d.language_code, 'kind', n.kind)), '[]'::jsonb)
    into result from leased l join private.push_devices d on d.id = l.device_id
    join public.social_notifications n on n.id = l.notification_id;
  return result;
end;
$$;

create function public.complete_social_push(
  p_job_id uuid, p_lease_token uuid, p_result text,
  p_retry_after_seconds integer default 0
) returns boolean language plpgsql security definer set search_path = '' as $$
declare job private.social_push_outbox%rowtype;
begin
  if auth.role() is distinct from 'service_role' then raise exception 'push_worker_required'; end if;
  if p_result is null or p_result not in ('accepted','unregistered','retry','permanent_error')
    or p_retry_after_seconds is null or p_retry_after_seconds not between 0 and 3600 then
    raise exception 'push_request_invalid';
  end if;
  select * into job from private.social_push_outbox where id = p_job_id
    and lease_token = p_lease_token and state = 'leased' for update;
  if not found then return false; end if;
  if p_result = 'unregistered' then
    -- A delayed failure must never delete a freshly rotated token.
    delete from private.push_devices where id = job.device_id
      and generation = job.device_generation;
    if not exists(select 1 from private.social_push_outbox where id = job.id) then return true; end if;
  end if;
  update private.social_push_outbox set
    state = case when p_result = 'accepted' then 'accepted'
      when p_result = 'retry' and job.attempts < 6 then 'pending' else 'failed' end,
    last_result = p_result, lease_token = null, lease_until = null,
    next_attempt_at = now() + make_interval(secs => greatest(p_retry_after_seconds,
      least(3600, (15 * power(2, job.attempts))::integer))),
    completed_at = case when p_result <> 'retry' or job.attempts >= 6 then now() else null end
  where id = job.id;
  -- FCM acceptance is not acknowledgement of reading or device delivery.
  return true;
end;
$$;

create function private.cleanup_social_push() returns void
language sql security definer set search_path = '' as $$
  delete from private.push_devices where expires_at < now();
  delete from private.social_push_outbox where created_at < now() - interval '7 days';
$$;
select cron.schedule('dragonhaven-push-cleanup', '17 3 * * *',
  'select private.cleanup_social_push();');

revoke all on function public.register_my_push_device(uuid,uuid,text,text,text[]),
  public.unregister_my_push_device(uuid) from public, anon;
grant execute on function public.register_my_push_device(uuid,uuid,text,text,text[]),
  public.unregister_my_push_device(uuid) to authenticated;
revoke all on function public.lease_social_pushes(integer),
  public.complete_social_push(uuid,uuid,text,integer) from public, anon, authenticated;
grant execute on function public.lease_social_pushes(integer),
  public.complete_social_push(uuid,uuid,text,integer) to service_role;
revoke all on function private.enqueue_social_push(), private.cleanup_social_push()
  from public, anon, authenticated, service_role;
