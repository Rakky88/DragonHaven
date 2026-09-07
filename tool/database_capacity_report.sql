-- Read-only technical aggregates. Never return account/chat/save/credential data.
begin read only;
select jsonb_build_object(
  'captured_at', now(),
  'database_bytes', pg_database_size(current_database()),
  'connections', (select count(*) from pg_stat_activity where datname = current_database()),
  'active_connections', (select count(*) from pg_stat_activity where datname = current_database() and state = 'active'),
  'waiting_locks', (select count(*) from pg_stat_activity where datname = current_database() and wait_event_type = 'Lock'),
  'deadlocks_since_stats_reset', (select deadlocks from pg_stat_database where datname = current_database()),
  'stats_reset_at', (select stats_reset from pg_stat_database where datname = current_database()),
  'largest_tables', (select jsonb_agg(t) from (
    select schemaname, relname, n_live_tup as estimated_rows,
      n_dead_tup as estimated_dead_rows, pg_total_relation_size(relid) as bytes,
      last_autovacuum, last_autoanalyze
    from pg_stat_user_tables where schemaname in ('public','private','auth')
    order by pg_total_relation_size(relid) desc limit 20
  ) t),
  'note', 'Database observations are not peak load, provider quota usage, MAU or billable egress'
) as capacity_report;
commit;
