-- A session-local replay of the real migration-37 timestamp defect and its
-- migration-38 correction. Existing functions and migration history stay intact.
begin;
create temp table hotfix_probe on commit drop as
select gen_random_uuid() as keeper,
  pg_get_functiondef(p.oid) as original_definition,
  p.proacl as original_acl,
  (select to_jsonb(c) from private.economy_contract c) as original_contract
from pg_proc p
where p.oid = 'private.consume_economy_rate_limit(uuid,text,integer,integer)'::regprocedure;

-- INSTALL HISTORICAL FUNCTION

do $$
declare keeper uuid := (select h.keeper from hotfix_probe h);
begin
  insert into auth.users(id, email, email_confirmed_at)
    values(keeper, keeper::text || '@hotfix-contract.invalid', now());
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  perform public.ensure_my_online_account();
  begin
    perform pg_temp.consume_economy_rate_limit(keeper, 'hotfix.probe', 2, 60);
    raise exception 'hotfix_historical_fault_not_reproduced';
  exception when datatype_mismatch then
    -- SQLSTATE 42804: CURRENT_TIME is interpreted as timetz in the INSERT.
    null;
  end;
  if exists(select 1 from private.economy_rate_limit_buckets where owner_id = keeper) then
    raise exception 'hotfix_failed_write_was_not_atomic';
  end if;
end;
$$;

-- INSTALL CORRECTED FUNCTION

do $$
declare keeper uuid := (select h.keeper from hotfix_probe h);
  reset_before timestamptz;
begin
  perform pg_temp.consume_economy_rate_limit(keeper, 'hotfix.probe', 2, 60);
  select reset_at into reset_before from private.economy_rate_limit_buckets
    where owner_id = keeper and operation = 'hotfix.probe';
  if reset_before is null or reset_before <= clock_timestamp()
    or reset_before > clock_timestamp() + interval '61 seconds' then
    raise exception 'hotfix_timestamp_window_invalid';
  end if;
  perform pg_temp.consume_economy_rate_limit(keeper, 'hotfix.probe', 2, 60);
  begin
    perform pg_temp.consume_economy_rate_limit(keeper, 'hotfix.probe', 2, 60);
    raise exception 'hotfix_limit_not_enforced';
  exception when others then if sqlerrm <> 'economy_rate_limited' then raise; end if; end;
  if not exists(select 1 from private.economy_rate_limit_buckets
    where owner_id = keeper and operation = 'hotfix.probe'
      and request_count = 2 and reset_at = reset_before) then
    raise exception 'hotfix_limit_changed_bucket';
  end if;
  update private.economy_rate_limit_buckets set reset_at = clock_timestamp() - interval '1 second'
    where owner_id = keeper and operation = 'hotfix.probe';
  perform pg_temp.consume_economy_rate_limit(keeper, 'hotfix.probe', 2, 60);
  if not exists(select 1 from private.economy_rate_limit_buckets
    where owner_id = keeper and operation = 'hotfix.probe'
      and request_count = 1 and reset_at > clock_timestamp()) then
    raise exception 'hotfix_expired_window_not_reset';
  end if;
  begin
    perform pg_temp.consume_economy_rate_limit(keeper, 'hotfix.probe', 0, 60);
    raise exception 'hotfix_invalid_limit_accepted';
  exception when others then if sqlerrm <> 'economy_rate_limit_invalid' then raise; end if; end;

  -- Prove that the installed implementation, grants and activation flag were
  -- never replaced or relaxed while the historical defect was being exercised.
  if exists(select 1 from hotfix_probe h join pg_proc p
    on p.oid = 'private.consume_economy_rate_limit(uuid,text,integer,integer)'::regprocedure
    where h.original_definition is distinct from pg_get_functiondef(p.oid)
      or h.original_acl is distinct from p.proacl
      or h.original_contract is distinct from (select to_jsonb(c) from private.economy_contract c)) then
    raise exception 'hotfix_installed_function_or_contract_changed';
  end if;
  if has_function_privilege('authenticated', 'private.consume_economy_rate_limit(uuid,text,integer,integer)', 'execute')
    or has_function_privilege('anon', 'private.consume_economy_rate_limit(uuid,text,integer,integer)', 'execute') then
    raise exception 'hotfix_private_function_exposed';
  end if;
end;
$$;
rollback;
select true as economy_hotfix_contract_passed;
