-- Preserve second-accurate incubation durations in the authoritative egg
-- ledger. Existing eggs remain unchanged: their whole-minute duration is
-- converted to seconds. The compatibility minute field stays populated for
-- older clients and always rounds up client-side.

alter table public.player_eggs
  add column incubation_seconds integer;

update public.player_eggs
set incubation_seconds = incubation_minutes * 60;

alter table public.player_eggs
  alter column incubation_seconds set default 60480,
  alter column incubation_seconds set not null,
  add constraint player_eggs_incubation_seconds_check
    check (incubation_seconds between 60 and 1209600);

create or replace function private.trade_egg_data(p_egg public.player_eggs)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select jsonb_build_object(
    'id', p_egg.legacy_client_id,
    'lineageId', p_egg.lineage_id,
    'acquiredAt', p_egg.acquired_at,
    'hatchSeed', p_egg.hatch_seed,
    'prismatic', p_egg.prismatic,
    'spectral', p_egg.prismatic,
    'lawAxis', p_egg.law_axis,
    'moralAxis', p_egg.moral_axis,
    'sizeFactor', p_egg.size_factor,
    'incubationMinutes', p_egg.incubation_minutes,
    'incubationSeconds', p_egg.incubation_seconds,
    'sinister', p_egg.sinister,
    'xp', p_egg.xp
  )
$$;

alter function public.synchronize_trade_inventory(jsonb)
  rename to synchronize_trade_inventory_v26;

create function public.synchronize_trade_inventory(p_inventory jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  entry jsonb;
begin
  if current_user_id is null then raise exception 'invalid_inventory'; end if;
  perform public.synchronize_trade_inventory_v26(p_inventory);
  for entry in select value from jsonb_array_elements(
    coalesce(p_inventory -> 'eggs', '[]'::jsonb)
  ) loop
    update public.player_eggs
    set incubation_seconds = greatest(60, least(1209600, coalesce(
      (entry ->> 'incubation_seconds')::integer,
      (entry ->> 'incubation_minutes')::integer * 60,
      60480
    )))
    where owner_id = current_user_id
      and legacy_client_id = entry ->> 'client_id';
  end loop;
exception
  when invalid_text_representation or numeric_value_out_of_range then
    raise exception 'invalid_inventory';
end;
$$;

alter function public.import_legacy_inventory(jsonb)
  rename to import_legacy_inventory_v26;

create function public.import_legacy_inventory(p_inventory jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  already_imported_at timestamptz;
  entry jsonb;
begin
  if current_user_id is null then raise exception 'invalid_inventory'; end if;
  perform pg_advisory_xact_lock(hashtextextended(current_user_id::text, 0));
  select inventory_imported_at into already_imported_at
  from public.profiles where user_id = current_user_id for update;
  if not found then raise exception 'profile_not_found'; end if;
  if already_imported_at is not null then return; end if;

  perform public.import_legacy_inventory_v26(p_inventory);
  for entry in select value from jsonb_array_elements(
    coalesce(p_inventory -> 'eggs', '[]'::jsonb)
  ) loop
    update public.player_eggs
    set incubation_seconds = greatest(60, least(1209600, coalesce(
      (entry ->> 'incubation_seconds')::integer,
      (entry ->> 'incubation_minutes')::integer * 60,
      60480
    )))
    where owner_id = current_user_id
      and legacy_client_id = entry ->> 'client_id';
  end loop;
exception
  when invalid_text_representation or numeric_value_out_of_range
    or check_violation or not_null_violation then
    raise exception 'invalid_inventory';
end;
$$;

revoke all on function public.synchronize_trade_inventory_v26(jsonb)
  from public, anon, authenticated;
revoke all on function public.import_legacy_inventory_v26(jsonb)
  from public, anon, authenticated;
revoke all on function private.trade_egg_data(public.player_eggs)
  from public, anon, authenticated;
revoke all on function public.synchronize_trade_inventory(jsonb)
  from public, anon;
grant execute on function public.synchronize_trade_inventory(jsonb)
  to authenticated;
revoke all on function public.import_legacy_inventory(jsonb)
  from public, anon;
grant execute on function public.import_legacy_inventory(jsonb)
  to authenticated;
