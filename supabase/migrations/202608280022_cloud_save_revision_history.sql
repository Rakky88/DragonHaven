-- Keep a small, recoverable cloud-save history without weakening optimistic
-- concurrency. The current save plus four previous revisions are retained;
-- superseded revisions expire after thirty days.

alter table public.cloud_game_saves
  add column if not exists save_id uuid,
  add column if not exists parent_revision bigint,
  add column if not exists client_version text,
  add column if not exists schema_version integer,
  add column if not exists created_at timestamptz;

update public.cloud_game_saves save
set save_id = coalesce(save.save_id, extensions.gen_random_uuid()),
    parent_revision = case
      when save.parent_revision is not null then save.parent_revision
      when save.revision > 1 then save.revision - 1
      else null
    end,
    client_version = coalesce(nullif(save.client_version, ''), 'legacy'),
    schema_version = coalesce(
      save.schema_version,
      case
        when coalesce(save.state->>'schemaVersion', '') ~ '^[1-9][0-9]*$'
          then (save.state->>'schemaVersion')::integer
        else 1
      end
    ),
    created_at = coalesce(save.created_at, save.updated_at);

alter table public.cloud_game_saves
  alter column save_id set not null,
  alter column save_id set default extensions.gen_random_uuid(),
  alter column client_version set not null,
  alter column schema_version set not null,
  alter column created_at set not null,
  alter column created_at set default now();

alter table public.cloud_game_saves
  drop constraint if exists cloud_game_saves_parent_revision_check,
  add constraint cloud_game_saves_parent_revision_check
    check (parent_revision is null or parent_revision > 0),
  drop constraint if exists cloud_game_saves_client_version_check,
  add constraint cloud_game_saves_client_version_check
    check (char_length(client_version) between 1 and 40),
  drop constraint if exists cloud_game_saves_schema_version_check,
  add constraint cloud_game_saves_schema_version_check
    check (schema_version between 1 and 1000),
  drop constraint if exists cloud_game_saves_user_save_id_key,
  add constraint cloud_game_saves_user_save_id_key unique (user_id, save_id);

create table if not exists public.cloud_game_save_history (
  user_id uuid not null references auth.users(id) on delete cascade,
  save_id uuid not null,
  revision bigint not null check (revision > 0),
  parent_revision bigint check (parent_revision is null or parent_revision > 0),
  state jsonb not null check (jsonb_typeof(state) = 'object'),
  device_id text not null check (char_length(device_id) between 1 and 100),
  client_version text not null check (char_length(client_version) between 1 and 40),
  schema_version integer not null check (schema_version between 1 and 1000),
  created_at timestamptz not null,
  superseded_at timestamptz not null default now(),
  primary key (user_id, save_id),
  unique (user_id, revision)
);

create index if not exists cloud_game_save_history_user_revision_idx
  on public.cloud_game_save_history(user_id, revision desc);
create index if not exists cloud_game_save_history_expiry_idx
  on public.cloud_game_save_history(superseded_at);

alter table public.cloud_game_save_history enable row level security;
revoke all on table public.cloud_game_save_history
  from public, anon, authenticated;

create or replace function private.purge_expired_cloud_game_save_history()
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  removed_count bigint;
begin
  delete from public.cloud_game_save_history history
  where history.superseded_at < now() - interval '30 days';
  get diagnostics removed_count = row_count;
  return removed_count;
end;
$$;

revoke all on function private.purge_expired_cloud_game_save_history()
  from public, anon, authenticated;

create or replace function public.push_cloud_game_save_v2(
  p_expected_revision bigint,
  p_state jsonb,
  p_device_id text,
  p_client_version text
)
returns table (
  save_id uuid,
  revision bigint,
  parent_revision bigint,
  state jsonb,
  device_id text,
  client_version text,
  schema_version integer,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  existing public.cloud_game_saves%rowtype;
  incoming_schema_version integer;
  next_save_id uuid := extensions.gen_random_uuid();
begin
  if current_user_id is null then raise exception 'email_not_verified'; end if;
  if p_expected_revision < 0
    or jsonb_typeof(p_state) <> 'object'
    or coalesce(p_state->>'schemaVersion', '') !~ '^[1-9][0-9]*$'
    or char_length(trim(coalesce(p_device_id, ''))) not between 1 and 100
    or char_length(trim(coalesce(p_client_version, ''))) not between 1 and 40 then
    raise exception 'cloud_save_invalid';
  end if;
  if octet_length(p_state::text) > 2097152 then
    raise exception 'cloud_save_too_large';
  end if;

  incoming_schema_version := (p_state->>'schemaVersion')::integer;
  if incoming_schema_version not between 1 and 1000 then
    raise exception 'cloud_save_invalid';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(current_user_id::text, 0)
  );

  select * into existing
  from public.cloud_game_saves save
  where save.user_id = current_user_id
  for update;

  if not found then
    if p_expected_revision <> 0 then raise exception 'cloud_save_conflict'; end if;
    insert into public.cloud_game_saves(
      user_id,
      save_id,
      revision,
      parent_revision,
      state,
      device_id,
      client_version,
      schema_version,
      created_at,
      updated_at
    ) values (
      current_user_id,
      next_save_id,
      1,
      null,
      p_state,
      trim(p_device_id),
      trim(p_client_version),
      incoming_schema_version,
      now(),
      now()
    );
  else
    if existing.revision <> p_expected_revision then
      raise exception 'cloud_save_conflict';
    end if;

    insert into public.cloud_game_save_history(
      user_id,
      save_id,
      revision,
      parent_revision,
      state,
      device_id,
      client_version,
      schema_version,
      created_at,
      superseded_at
    ) values (
      existing.user_id,
      existing.save_id,
      existing.revision,
      existing.parent_revision,
      existing.state,
      existing.device_id,
      existing.client_version,
      existing.schema_version,
      existing.created_at,
      now()
    ) on conflict on constraint cloud_game_save_history_user_id_revision_key
      do nothing;

    update public.cloud_game_saves save
    set save_id = next_save_id,
        revision = existing.revision + 1,
        parent_revision = existing.revision,
        state = p_state,
        device_id = trim(p_device_id),
        client_version = trim(p_client_version),
        schema_version = incoming_schema_version,
        created_at = now(),
        updated_at = now()
    where save.user_id = current_user_id;
  end if;

  delete from public.cloud_game_save_history history
  where history.user_id = current_user_id
    and (
      history.superseded_at < now() - interval '30 days'
      or history.revision in (
        select stale.revision
        from public.cloud_game_save_history stale
        where stale.user_id = current_user_id
        order by stale.revision desc
        offset 4
      )
    );
  perform private.purge_expired_cloud_game_save_history();

  return query
  select save.save_id,
         save.revision,
         save.parent_revision,
         save.state,
         save.device_id,
         save.client_version,
         save.schema_version,
         save.updated_at
  from public.cloud_game_saves save
  where save.user_id = current_user_id;
end;
$$;

create or replace function public.push_cloud_game_save(
  p_expected_revision bigint,
  p_state jsonb,
  p_device_id text
)
returns table (
  revision bigint,
  state jsonb,
  device_id text,
  updated_at timestamptz
)
language sql
security definer
set search_path = ''
as $$
  select saved.revision, saved.state, saved.device_id, saved.updated_at
  from public.push_cloud_game_save_v2(
    p_expected_revision,
    p_state,
    p_device_id,
    'legacy-client'
  ) saved
$$;

drop function public.get_cloud_game_save();
create function public.get_cloud_game_save()
returns table (
  save_id uuid,
  revision bigint,
  parent_revision bigint,
  state jsonb,
  device_id text,
  client_version text,
  schema_version integer,
  updated_at timestamptz
)
language sql
security definer
set search_path = ''
stable
as $$
  select save.save_id,
         save.revision,
         save.parent_revision,
         save.state,
         save.device_id,
         save.client_version,
         save.schema_version,
         save.updated_at
  from public.cloud_game_saves save
  where save.user_id = auth.uid()
$$;

create or replace function public.list_my_cloud_game_save_revisions()
returns table (
  save_id uuid,
  revision bigint,
  parent_revision bigint,
  device_id text,
  client_version text,
  schema_version integer,
  updated_at timestamptz,
  is_current boolean
)
language sql
security definer
set search_path = ''
stable
as $$
  select versions.save_id,
         versions.revision,
         versions.parent_revision,
         versions.device_id,
         versions.client_version,
         versions.schema_version,
         versions.updated_at,
         versions.is_current
  from (
    select save.save_id,
           save.revision,
           save.parent_revision,
           save.device_id,
           save.client_version,
           save.schema_version,
           save.updated_at,
           true as is_current
    from public.cloud_game_saves save
    where save.user_id = auth.uid()
    union all
    select history.save_id,
           history.revision,
           history.parent_revision,
           history.device_id,
           history.client_version,
           history.schema_version,
           history.created_at as updated_at,
           false as is_current
    from public.cloud_game_save_history history
    where history.user_id = auth.uid()
      and history.superseded_at >= now() - interval '30 days'
  ) versions
  order by versions.revision desc
  limit 5
$$;

create or replace function public.get_my_cloud_game_save_revision(
  p_save_id uuid
)
returns table (
  save_id uuid,
  revision bigint,
  parent_revision bigint,
  state jsonb,
  device_id text,
  client_version text,
  schema_version integer,
  updated_at timestamptz
)
language sql
security definer
set search_path = ''
stable
as $$
  select versions.save_id,
         versions.revision,
         versions.parent_revision,
         versions.state,
         versions.device_id,
         versions.client_version,
         versions.schema_version,
         versions.updated_at
  from (
    select save.save_id,
           save.revision,
           save.parent_revision,
           save.state,
           save.device_id,
           save.client_version,
           save.schema_version,
           save.updated_at,
           true as is_current
    from public.cloud_game_saves save
    where save.user_id = auth.uid()
    union all
    select history.save_id,
           history.revision,
           history.parent_revision,
           history.state,
           history.device_id,
           history.client_version,
           history.schema_version,
           history.created_at as updated_at,
           false as is_current
    from public.cloud_game_save_history history
    where history.user_id = auth.uid()
      and history.superseded_at >= now() - interval '30 days'
  ) versions
  where versions.save_id = p_save_id
  order by versions.is_current desc
  limit 1
$$;

revoke all on function public.push_cloud_game_save_v2(bigint, jsonb, text, text)
  from public, anon;
revoke all on function public.get_cloud_game_save() from public, anon;
revoke all on function public.list_my_cloud_game_save_revisions()
  from public, anon;
revoke all on function public.get_my_cloud_game_save_revision(uuid)
  from public, anon;
grant execute on function public.push_cloud_game_save_v2(bigint, jsonb, text, text)
  to authenticated;
grant execute on function public.get_cloud_game_save() to authenticated;
grant execute on function public.list_my_cloud_game_save_revisions()
  to authenticated;
grant execute on function public.get_my_cloud_game_save_revision(uuid)
  to authenticated;

-- Supabase Cron runs the same privacy cleanup once a day even when no player
-- uploads a new save. Scheduling the same case-sensitive name again safely
-- replaces the existing job during environment recreation.
create extension if not exists pg_cron;
select cron.schedule(
  'dragonhaven-cloud-save-history-cleanup',
  '17 3 * * *',
  'select private.purge_expired_cloud_game_save_history()'
);
