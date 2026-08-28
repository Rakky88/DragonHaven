-- Migration 22 reached staging before the schema lint gate reported that the
-- RETURN TABLE output variable `revision` made the ON CONFLICT column target
-- ambiguous to PL/pgSQL. Name the unique constraint explicitly. Fresh database
-- replays also contain this correction in migration 22.

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

revoke all on function public.push_cloud_game_save_v2(bigint, jsonb, text, text)
  from public, anon;
grant execute on function public.push_cloud_game_save_v2(bigint, jsonb, text, text)
  to authenticated;
