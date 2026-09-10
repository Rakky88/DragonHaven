-- The raw begin helper remains callable only from the security-definer
-- revisioned entry. Migration 69 replaced its implementation and accidentally
-- restored a service-role grant that migration 57 had deliberately removed.
-- Keep the reviewed migration history immutable and restore that boundary.
-- No account, state, runtime switch or balance changes in this repair.
revoke all on function public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text)
  from public,anon,authenticated,service_role;
