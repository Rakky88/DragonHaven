-- Versioned, per-account cloud backups. Writes use optimistic concurrency so
-- two devices can never silently overwrite each other's newer progress.

create table if not exists public.cloud_game_saves (
  user_id uuid primary key references auth.users(id) on delete cascade,
  revision bigint not null check (revision > 0),
  state jsonb not null check (jsonb_typeof(state) = 'object'),
  device_id text not null check (char_length(device_id) between 1 and 100),
  updated_at timestamptz not null default now()
);

alter table public.cloud_game_saves enable row level security;
revoke all on table public.cloud_game_saves from public, anon, authenticated;

create or replace function public.get_cloud_game_save()
returns table (
  revision bigint,
  state jsonb,
  device_id text,
  updated_at timestamptz
)
language sql
security definer
set search_path = ''
stable
as $$
  select save.revision, save.state, save.device_id, save.updated_at
  from public.cloud_game_saves save
  where save.user_id = auth.uid()
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
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  existing public.cloud_game_saves%rowtype;
begin
  if current_user_id is null then raise exception 'email_not_verified'; end if;
  if p_expected_revision < 0
    or jsonb_typeof(p_state) <> 'object'
    or coalesce(p_state->>'schemaVersion', '') !~ '^[1-9][0-9]*$'
    or char_length(trim(coalesce(p_device_id, ''))) not between 1 and 100 then
    raise exception 'cloud_save_invalid';
  end if;
  if octet_length(p_state::text) > 2097152 then
    raise exception 'cloud_save_too_large';
  end if;

  select * into existing
  from public.cloud_game_saves save
  where save.user_id = current_user_id
  for update;

  if not found then
    if p_expected_revision <> 0 then raise exception 'cloud_save_conflict'; end if;
    insert into public.cloud_game_saves(user_id, revision, state, device_id)
    values (current_user_id, 1, p_state, trim(p_device_id));
  else
    if existing.revision <> p_expected_revision then
      raise exception 'cloud_save_conflict';
    end if;
    update public.cloud_game_saves save
    set revision = existing.revision + 1,
        state = p_state,
        device_id = trim(p_device_id),
        updated_at = now()
    where save.user_id = current_user_id;
  end if;

  return query
  select save.revision, save.state, save.device_id, save.updated_at
  from public.cloud_game_saves save
  where save.user_id = current_user_id;
end;
$$;

revoke all on function public.get_cloud_game_save() from public, anon;
revoke all on function public.push_cloud_game_save(bigint, jsonb, text)
  from public, anon;
grant execute on function public.get_cloud_game_save() to authenticated;
grant execute on function public.push_cloud_game_save(bigint, jsonb, text)
  to authenticated;
