-- Firebase FCM is free; sending runs on the existing Supabase project.
-- No scheduled HTTP request until the operator supplies Vault configuration
-- and explicitly enables private.push_runtime after the staging device proof.
create extension if not exists pg_net with schema extensions;

alter table private.push_runtime
  add column endpoint text check (endpoint ~ '^https://[a-z0-9]{20}\.supabase\.co/functions/v1/dispatch-social-push$'),
  add column next_dispatch_at timestamptz not null default now(),
  add column last_request_id bigint;

create table private.push_dispatch_usage (
  month date primary key check (extract(day from month) = 1),
  dispatched integer not null default 0 check (dispatched >= 0)
);
alter table private.push_dispatch_usage enable row level security;
revoke all on private.push_dispatch_usage from public, anon, authenticated, service_role;

create function private.dispatch_social_push_tick() returns text
language plpgsql security definer set search_path = '' as $$
declare config private.push_runtime%rowtype; dispatch_secret text;
  current_month date := date_trunc('month', now() at time zone 'UTC')::date;
  used integer; request_id bigint; previous_status integer;
begin
  -- Serializes manual/cron overlap; no overlapping HTTP requests under 60s.
  select * into config from private.push_runtime where singleton for update;
  if not config.enabled then return 'disabled'; end if;
  if config.endpoint is null then return 'unconfigured'; end if;
  if config.next_dispatch_at > now() then return 'waiting'; end if;
  if not exists(select 1 from private.social_push_outbox o
    where o.attempts < 6 and o.next_attempt_at <= now()
      and o.created_at >= now() - interval '24 hours'
      and (o.state = 'pending' or (o.state = 'leased' and o.lease_until < now()))) then
    return 'empty';
  end if;
  select decrypted_secret into dispatch_secret from vault.decrypted_secrets
    where name = 'dragonhaven_push_dispatch_secret';
  if dispatch_secret is null or length(dispatch_secret) < 32 then return 'unconfigured'; end if;
  insert into private.push_dispatch_usage(month) values(current_month) on conflict do nothing;
  select dispatched into used from private.push_dispatch_usage where month = current_month for update;
  if used >= config.monthly_dispatch_limit then return 'monthly_limit'; end if;
  select status_code into previous_status from net._http_response where id = config.last_request_id;
  select net.http_post(url := config.endpoint,
    headers := jsonb_build_object('Content-Type','application/json',
      'Authorization','Bearer ' || dispatch_secret),
    body := '{}'::jsonb, timeout_milliseconds := 45000) into request_id;
  update private.push_runtime set last_request_id = request_id,
    next_dispatch_at = now() + case when previous_status in (401,403,429,500,502,503,504)
      then interval '15 minutes' else interval '60 seconds' end where singleton;
  update private.push_dispatch_usage set dispatched = dispatched + 1 where month = current_month;
  delete from private.push_dispatch_usage where month < current_month - interval '12 months';
  return 'queued';
end;
$$;
revoke all on function private.dispatch_social_push_tick() from public, anon, authenticated, service_role;
select cron.schedule('dragonhaven-push-dispatch', '* * * * *',
  'select private.dispatch_social_push_tick();');
