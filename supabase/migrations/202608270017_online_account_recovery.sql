-- Make account provisioning idempotent and repair accounts whose Auth user was
-- created while one of the dependent profile rows was missing.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  chosen_name text;
begin
  chosen_name := left(
    coalesce(nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''), 'Keeper'),
    24
  );
  insert into public.profiles(user_id, keeper_code, display_name)
  values (new.id, private.next_keeper_code(), chosen_name)
  on conflict (user_id) do nothing;
  insert into public.player_wallets(user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

-- Repair any incomplete historical Auth accounts before clients start using
-- the self-healing command below.
insert into public.profiles(user_id, keeper_code, display_name)
select
  u.id,
  private.next_keeper_code(),
  left(
    coalesce(nullif(btrim(u.raw_user_meta_data ->> 'display_name'), ''), 'Keeper'),
    24
  )
from auth.users u
left join public.profiles p on p.user_id = u.id
where p.user_id is null
on conflict (user_id) do nothing;

insert into public.player_wallets(user_id)
select p.user_id
from public.profiles p
left join public.player_wallets w on w.user_id = p.user_id
where w.user_id is null
on conflict (user_id) do nothing;

create or replace function public.ensure_my_online_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  chosen_name text;
begin
  if current_user_id is null then
    raise exception 'online_login_required';
  end if;

  select left(
    coalesce(nullif(btrim(u.raw_user_meta_data ->> 'display_name'), ''), 'Keeper'),
    24
  )
  into chosen_name
  from auth.users u
  where u.id = current_user_id;

  if chosen_name is null then
    raise exception 'online_login_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(current_user_id::text, 0));
  insert into public.profiles(user_id, keeper_code, display_name)
  values (current_user_id, private.next_keeper_code(), chosen_name)
  on conflict (user_id) do nothing;
  insert into public.player_wallets(user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;
end;
$$;

revoke all on function public.ensure_my_online_account()
  from public, anon;
grant execute on function public.ensure_my_online_account()
  to authenticated;
