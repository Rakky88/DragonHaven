-- Internal presence timestamp. It is deliberately absent from every public
-- profile projection and is updated only by authenticated account activity.

alter table public.profiles
  add column last_online_datetime timestamptz not null default now();

create or replace function private.touch_last_online_datetime()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.last_online_datetime = now();
  return new;
end
$$;

create trigger profiles_touch_last_online_datetime
before update on public.profiles
for each row execute function private.touch_last_online_datetime();

comment on column public.profiles.last_online_datetime is
  'Private server timestamp of the most recent authenticated profile sync.';
