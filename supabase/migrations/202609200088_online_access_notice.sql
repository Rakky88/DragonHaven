-- Additive only: existing economy/authority switches and saves are untouched.
create table private.account_privacy_acknowledgements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  notice_version text not null,
  minimum_age_confirmed integer not null check (minimum_age_confirmed = 16),
  acknowledged_at timestamptz not null default now()
);
alter table private.account_privacy_acknowledgements enable row level security;
revoke all on private.account_privacy_acknowledgements from public, anon, authenticated;

create function public.get_my_privacy_acknowledgement()
returns boolean language plpgsql security definer set search_path='' as $$
declare keeper uuid := auth.uid();
begin
  if keeper is null or not exists(select 1 from auth.users
      where id=keeper and email_confirmed_at is not null) then
    raise exception 'online_login_required';
  end if;
  return exists(select 1 from private.account_privacy_acknowledgements
    where user_id=keeper and notice_version='2026-09-20' and minimum_age_confirmed=16);
end $$;

create function public.acknowledge_my_privacy_notice(p_version text, p_age_16_confirmed boolean)
returns boolean language plpgsql security definer set search_path='' as $$
declare keeper uuid := auth.uid();
begin
  if keeper is null or not exists(select 1 from auth.users
      where id=keeper and email_confirmed_at is not null) then
    raise exception 'online_login_required';
  end if;
  if p_version is distinct from '2026-09-20' or p_age_16_confirmed is distinct from true then
    raise exception 'privacy_confirmation_required';
  end if;
  insert into private.account_privacy_acknowledgements(user_id,notice_version,minimum_age_confirmed)
    values(keeper,p_version,16)
    on conflict(user_id) do update set notice_version=excluded.notice_version,
      minimum_age_confirmed=16,acknowledged_at=now()
      where account_privacy_acknowledgements.notice_version<>excluded.notice_version;
  return true;
end $$;
revoke all on function public.get_my_privacy_acknowledgement(),
  public.acknowledge_my_privacy_notice(text,boolean) from public,anon;
grant execute on function public.get_my_privacy_acknowledgement(),
  public.acknowledge_my_privacy_notice(text,boolean) to authenticated;

-- A cached JWT is not proof that the verified account still exists.
create function public.get_my_online_session_status()
returns jsonb language plpgsql security definer set search_path='' as $$
begin
  if auth.uid() is null or not exists(select 1 from auth.users
      where id=auth.uid() and email_confirmed_at is not null) then
    raise exception 'online_login_required';
  end if;
  return public.get_my_canonical_account_status();
end $$;
revoke all on function public.get_my_online_session_status() from public,anon;
grant execute on function public.get_my_online_session_status() to authenticated;
