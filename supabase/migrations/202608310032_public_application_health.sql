-- Public, read-only application health contract.
--
-- This deliberately reads no player or operational table. It proves that the
-- Supabase gateway, PostgREST and PostgreSQL function path are all responding,
-- while exposing only a fixed contract version and the database clock.

create or replace function public.dragonhaven_public_health()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select pg_catalog.jsonb_build_object(
    'status', 'ok',
    'service', 'dragonhaven-online',
    'contract_version', 1,
    'server_time_utc', pg_catalog.to_char(
      pg_catalog.statement_timestamp() at time zone 'utc',
      'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
    )
  );
$$;

comment on function public.dragonhaven_public_health() is
  'Privacy-safe public liveness contract; returns no account or gameplay data.';

revoke all on function public.dragonhaven_public_health() from public;
grant execute on function public.dragonhaven_public_health() to anon, authenticated;
