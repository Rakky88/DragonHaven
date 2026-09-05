-- Forward-only correction for migration 37.
-- PostgreSQL resolves CURRENT_TIME as its time-with-time-zone keyword inside
-- SQL statements. Use an unambiguous PL/pgSQL variable name so the dormant
-- rate-limit bucket always receives a timestamptz.

create or replace function private.consume_economy_rate_limit(
  p_owner_id uuid,
  p_operation text,
  p_limit integer,
  p_window_seconds integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  bucket private.economy_rate_limit_buckets%rowtype;
  v_now timestamptz := clock_timestamp();
begin
  if p_owner_id is null or p_operation is null
    or p_operation !~ '^[a-z][a-z0-9_.]{2,79}$'
    or p_limit is null or p_window_seconds is null
    or p_limit not between 1 and 300
    or p_window_seconds not between 1 and 86400 then
    raise exception 'economy_rate_limit_invalid';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(
    p_owner_id::text || ':' || p_operation, 0
  ));
  select * into bucket
  from private.economy_rate_limit_buckets
  where owner_id = p_owner_id and operation = p_operation
  for update;
  if not found then
    insert into private.economy_rate_limit_buckets(
      owner_id, operation, request_count, reset_at
    ) values (
      p_owner_id, p_operation, 1,
      v_now + make_interval(secs => p_window_seconds)
    );
  elsif bucket.reset_at <= v_now then
    update private.economy_rate_limit_buckets
    set request_count = 1,
        reset_at = v_now + make_interval(secs => p_window_seconds),
        updated_at = v_now
    where owner_id = p_owner_id and operation = p_operation;
  elsif bucket.request_count >= p_limit then
    raise exception 'economy_rate_limited';
  else
    update private.economy_rate_limit_buckets
    set request_count = request_count + 1,
        updated_at = v_now
    where owner_id = p_owner_id and operation = p_operation;
  end if;
end;
$$;

revoke all on function private.consume_economy_rate_limit(
  uuid, text, integer, integer
) from public, anon, authenticated;

comment on function private.consume_economy_rate_limit(
  uuid, text, integer, integer
) is 'Fixed-window limiter using an unambiguous timestamptz clock value.';
