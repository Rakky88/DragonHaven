-- Least-privilege support lookup and physical cleanup for privacy-bounded
-- operational records. The client never receives this RPC: only a server-side
-- service-role caller with an explicit case reference may execute it.

create table private.support_access_log (
  id uuid primary key default extensions.gen_random_uuid(),
  target_user_id uuid references auth.users(id) on delete set null,
  keeper_code_sha256 text not null
    check (keeper_code_sha256 ~ '^[a-f0-9]{64}$'),
  operator_ref text not null
    check (operator_ref ~ '^[a-z0-9][a-z0-9._-]{2,63}$'),
  case_reference text not null
    check (case_reference ~ '^DH-SUP-[A-Z0-9-]{6,40}$'),
  reason_code text not null check (reason_code in (
    'account_recovery', 'email_delivery', 'trade', 'cloud_backup',
    'account_deletion', 'abuse_review', 'incident_review'
  )),
  result_found boolean not null,
  accessed_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '30 days'),
  check (expires_at > accessed_at)
);

create index support_access_log_expiry_idx
  on private.support_access_log(expires_at);

revoke all on table private.support_access_log
  from public, anon, authenticated, service_role;

create or replace function public.support_lookup_keeper(
  p_keeper_code text,
  p_case_reference text,
  p_reason_code text,
  p_operator_ref text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_profile public.profiles%rowtype;
  access_id uuid;
  normalized_keeper_code text := upper(btrim(coalesce(p_keeper_code, '')));
  normalized_case_reference text := upper(btrim(coalesce(p_case_reference, '')));
  normalized_reason_code text := lower(btrim(coalesce(p_reason_code, '')));
  normalized_operator_ref text := lower(btrim(coalesce(p_operator_ref, '')));
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'support_access_denied' using errcode = '42501';
  end if;

  if normalized_keeper_code !~ '^DH-[A-F0-9]{8}$'
    or normalized_case_reference !~ '^DH-SUP-[A-Z0-9-]{6,40}$'
    or normalized_operator_ref !~ '^[a-z0-9][a-z0-9._-]{2,63}$'
    or normalized_reason_code not in (
      'account_recovery', 'email_delivery', 'trade', 'cloud_backup',
      'account_deletion', 'abuse_review', 'incident_review'
    ) then
    raise exception 'support_lookup_invalid';
  end if;

  select profile.* into target_profile
  from public.profiles profile
  where profile.keeper_code = normalized_keeper_code;

  insert into private.support_access_log(
    target_user_id,
    keeper_code_sha256,
    operator_ref,
    case_reference,
    reason_code,
    result_found
  ) values (
    target_profile.user_id,
    encode(
      extensions.digest(normalized_keeper_code, 'sha256'),
      'hex'
    ),
    normalized_operator_ref,
    normalized_case_reference,
    normalized_reason_code,
    target_profile.user_id is not null
  ) returning id into access_id;

  if target_profile.user_id is null then
    return jsonb_build_object(
      'access_id', access_id,
      'case_reference', normalized_case_reference,
      'found', false,
      'correlation_ids_available', false
    );
  end if;

  return jsonb_build_object(
    'access_id', access_id,
    'case_reference', normalized_case_reference,
    'found', true,
    'user_id', target_profile.user_id,
    'account', coalesce((
      select jsonb_build_object(
        'created_at', account.created_at,
        'email_confirmed', account.email_confirmed_at is not null,
        'banned', coalesce(account.banned_until > now(), false),
        'last_sign_in_at', account.last_sign_in_at
      )
      from auth.users account
      where account.id = target_profile.user_id
    ), jsonb_build_object('present', false)),
    'profile', jsonb_build_object(
      'created_at', target_profile.created_at,
      'updated_at', target_profile.updated_at,
      'inventory_imported_at', target_profile.inventory_imported_at
    ),
    'cloud_save', coalesce((
      select jsonb_build_object(
        'present', true,
        'revision', save.revision,
        'client_version', save.client_version,
        'schema_version', save.schema_version,
        'updated_at', save.updated_at
      )
      from public.cloud_game_saves save
      where save.user_id = target_profile.user_id
    ), jsonb_build_object('present', false)),
    'cloud_history', jsonb_build_object(
      'retained_revisions', (
        select count(*)
        from public.cloud_game_save_history history
        where history.user_id = target_profile.user_id
          and history.superseded_at >= now() - interval '30 days'
      ),
      'latest_superseded_at', (
        select max(history.superseded_at)
        from public.cloud_game_save_history history
        where history.user_id = target_profile.user_id
          and history.superseded_at >= now() - interval '30 days'
      )
    ),
    'trades', jsonb_build_object(
      'active_count', (
        select count(*)
        from public.trades trade
        where target_profile.user_id in (trade.initiator_id, trade.recipient_id)
          and trade.status in ('awaiting_recipient', 'awaiting_initiator')
      ),
      'completed_count', (
        select count(*)
        from public.trades trade
        where target_profile.user_id in (trade.initiator_id, trade.recipient_id)
          and trade.status = 'completed'
      ),
      'latest_updated_at', (
        select max(trade.updated_at)
        from public.trades trade
        where target_profile.user_id in (trade.initiator_id, trade.recipient_id)
      )
    ),
    'pending_social_notifications', (
      select count(*)
      from public.social_notifications notification
      where notification.user_id = target_profile.user_id
        and notification.acknowledged_at is null
    ),
    'legacy_import', coalesce((
      select jsonb_build_object(
        'present', true,
        'import_version', audit.import_version,
        'source_schema_version', audit.source_schema_version,
        'imported_at', audit.imported_at,
        'recovery_expires_at', backup.expires_at
      )
      from public.legacy_inventory_import_audit audit
      left join private.legacy_inventory_import_backups backup
        on backup.import_id = audit.id
      where audit.user_id = target_profile.user_id
    ), jsonb_build_object('present', false)),
    'correlation_ids_available', false
  );
end;
$$;

revoke all on function public.support_lookup_keeper(text, text, text, text)
  from public, anon, authenticated, service_role;
grant execute on function public.support_lookup_keeper(text, text, text, text)
  to service_role;

create or replace function private.purge_expired_support_privacy_records()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  removed_import_backups bigint;
  removed_access_logs bigint;
begin
  delete from private.legacy_inventory_import_backups backup
  where backup.expires_at <= now();
  get diagnostics removed_import_backups = row_count;

  delete from private.support_access_log access_log
  where access_log.expires_at <= now();
  get diagnostics removed_access_logs = row_count;

  return jsonb_build_object(
    'legacy_import_backups', removed_import_backups,
    'support_access_logs', removed_access_logs
  );
end;
$$;

revoke all on function private.purge_expired_support_privacy_records()
  from public, anon, authenticated, service_role;

create extension if not exists pg_cron;
select cron.schedule(
  'dragonhaven-support-privacy-cleanup',
  '47 3 * * *',
  'select private.purge_expired_support_privacy_records()'
);
