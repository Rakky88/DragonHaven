-- Rehearsal only. Helpers exist only in this transaction's temporary schema.
-- This deliberately does not expose an operational player-restore RPC.
begin;
set local statement_timeout = '45s';

create function pg_temp.inventory_snapshot(keeper uuid) returns jsonb
language plpgsql as $$
declare result jsonb := '{}'::jsonb; rows jsonb; part text; relation text;
begin
  select to_jsonb(w) into rows from public.player_wallets w where user_id = keeper;
  result := jsonb_build_object('wallet', coalesce(rows, 'null'::jsonb));
  foreach part in array array['dragons','eggs','chests','relics','furniture','lineages'] loop
    relation := case part when 'furniture' then 'furniture_instances'
      when 'lineages' then 'discovered_lineages' else 'player_' || part end;
    execute format('select coalesce(jsonb_agg(to_jsonb(r) order by to_jsonb(r)::text), ''[]''::jsonb) from public.%I r where owner_id = $1', relation)
      into rows using keeper;
    result := result || jsonb_build_object(part, rows);
  end loop;
  return result;
end;
$$;

create function pg_temp.inventory_hash(keeper uuid) returns text
language sql as $$
  select encode(extensions.digest(pg_temp.inventory_snapshot(keeper)::text, 'sha256'), 'hex');
$$;

create function pg_temp.restore_synthetic_import(keeper uuid, expected_after text)
returns void language plpgsql as $$
declare backup private.legacy_inventory_import_backups;
  part text; relation text; rows jsonb;
begin
  -- Defense in depth: even accidental reuse cannot select an ordinary account.
  if not exists(select 1 from auth.users where id = keeper
      and email = keeper::text || '@import-restore-contract.invalid') then
    raise exception 'restore_synthetic_only';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(keeper::text, 0));
  perform 1 from public.profiles where user_id = keeper for update;
  if not exists(select 1 from public.player_economy_authority
      where user_id = keeper and authority_mode = 'legacy_client') then
    raise exception 'restore_legacy_only';
  end if;
  if exists(select 1 from public.economy_mutation_requests where owner_id = keeper)
    or exists(select 1 from public.trades where initiator_id = keeper or recipient_id = keeper) then
    raise exception 'restore_account_not_quiescent';
  end if;
  select b.* into backup from private.legacy_inventory_import_backups b
    join public.legacy_inventory_import_audit a on a.id = b.import_id and a.user_id = b.user_id
    where b.user_id = keeper and a.import_version = 1 for update of b;
  if not found or backup.expires_at <= clock_timestamp() then
    raise exception 'restore_backup_unavailable';
  end if;
  if expected_after is null or pg_temp.inventory_hash(keeper) <> expected_after then
    raise exception 'restore_inventory_changed';
  end if;
  if backup.pre_import_state->'wallet'->>'user_id' is distinct from keeper::text then
    raise exception 'restore_backup_owner';
  end if;
  -- Validate every owner before the first deletion, including a corrupted backup.
  foreach part in array array['dragons','eggs','chests','relics','furniture','lineages'] loop
    rows := backup.pre_import_state->part;
    if rows is null or jsonb_typeof(rows) <> 'array' then
      raise exception 'restore_backup_shape';
    end if;
    if exists(select 1 from jsonb_array_elements(rows) r
      where r->>'owner_id' is distinct from keeper::text) then
      raise exception 'restore_backup_owner';
    end if;
  end loop;
  foreach part in array array['dragons','eggs','chests','relics','furniture','lineages'] loop
    relation := case part when 'furniture' then 'furniture_instances'
      when 'lineages' then 'discovered_lineages' else 'player_' || part end;
    execute format('delete from public.%I where owner_id = $1', relation) using keeper;
    execute format('insert into public.%I select * from jsonb_populate_recordset(null::public.%I, $1)', relation, relation)
      using backup.pre_import_state->part;
  end loop;
  delete from public.player_wallets where user_id = keeper;
  insert into public.player_wallets select * from jsonb_populate_record(
    null::public.player_wallets, backup.pre_import_state->'wallet');
  -- Keep the audit and one-time import marker: restore must not reopen import.
end;
$$;

do $$
declare keeper uuid := gen_random_uuid(); outsider uuid := gen_random_uuid();
  before_state jsonb; before_hash text; after_hash text; backup_state jsonb;
  payload jsonb; import_record uuid; result jsonb; restore_started timestamptz;
begin
  if (select mutations_enabled from private.economy_contract) then
    raise exception 'restore_contract_requires_dormant_economy';
  end if;
  if has_table_privilege('authenticated', 'private.legacy_inventory_import_backups', 'select')
    or has_table_privilege('anon', 'private.legacy_inventory_import_backups', 'select') then
    raise exception 'restore_contract_private_backup_access';
  end if;
  insert into auth.users(id, email, email_confirmed_at)
    values(keeper, keeper::text || '@import-restore-contract.invalid', now());
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  perform public.ensure_my_online_account();
  update public.player_wallets set coins = 321, gems = 17, revision = 5 where user_id = keeper;
  insert into public.player_dragons(owner_id, legacy_client_id, name, lineage_id, stage, xp)
    values(keeper, 'before-dragon', 'Synthetic', 'ember', 'wyrmling', 71);
  insert into public.player_eggs(owner_id, legacy_client_id, lineage_id, hatch_seed, incubation_seconds)
    values(keeper, 'before-egg', 'ember', 8317, 12345);
  insert into public.player_chests(owner_id, tier, quantity) values(keeper, 'special', 3);
  insert into public.player_relics(owner_id, relic_type, quantity, item_data)
    values(keeper, 'chronoshard', 2, '{"reductions":[0.2,0.4]}');
  insert into public.furniture_instances(owner_id, catalog_item_id) values(keeper, 'before_cushion');
  insert into public.discovered_lineages(owner_id, lineage_id) values(keeper, 'ember');
  before_state := pg_temp.inventory_snapshot(keeper);
  before_hash := pg_temp.inventory_hash(keeper);
  payload := '{"import_version":1,"source_schema_version":42,"coins":9876,"gems":123,
    "dragons":[{"client_id":"import-dragon","name":"Imported","lineage_id":"tide","stage":"hatchling"}],
    "eggs":[{"client_id":"import-egg","lineage_id":"tide","incubation_seconds":7891}],
    "chests":{"wooden":7,"gold":2,"special":5},
    "furniture_catalog_ids":["import_lamp"],"discovered_lineage_ids":["tide"]}';
  begin
    perform public.import_legacy_inventory(jsonb_set(payload, '{eggs}', '[{"client_id":"bad","lineage_id":"INVALID"}]'));
    raise exception 'restore_contract_invalid_import_accepted';
  exception when others then if sqlerrm <> 'invalid_inventory' then raise; end if; end;
  if pg_temp.inventory_hash(keeper) <> before_hash
    or exists(select 1 from public.legacy_inventory_import_audit where user_id = keeper)
    or exists(select 1 from private.legacy_inventory_import_backups where user_id = keeper) then
    raise exception 'restore_contract_invalid_import_not_atomic';
  end if;
  -- This fails after the wallet update and first dragon insert, exercising a
  -- partial-write failure rather than only the input-validation fast path.
  begin
    perform public.import_legacy_inventory(jsonb_set(payload, '{dragons}',
      (payload->'dragons') || '[{"client_id":"before-dragon","name":"Duplicate","lineage_id":"ember","stage":"hatchling"}]'));
    raise exception 'restore_contract_duplicate_import_accepted';
  exception when others then if sqlerrm <> 'invalid_inventory' then raise; end if; end;
  if pg_temp.inventory_hash(keeper) <> before_hash
    or exists(select 1 from public.legacy_inventory_import_audit where user_id = keeper)
    or exists(select 1 from private.legacy_inventory_import_backups where user_id = keeper) then
    raise exception 'restore_contract_partial_import_not_atomic';
  end if;
  perform public.import_legacy_inventory(payload);
  after_hash := pg_temp.inventory_hash(keeper);
  if before_hash = after_hash or (select coins from public.player_wallets where user_id = keeper) <> 9876
    or (select incubation_seconds from public.player_eggs where owner_id = keeper and legacy_client_id = 'import-egg') <> 7891
    or (select quantity from public.player_chests where owner_id = keeper and tier = 'special') <> 5 then
    raise exception 'restore_contract_import_not_applied';
  end if;
  select id into import_record from public.legacy_inventory_import_audit where user_id = keeper;
  select pre_import_state into backup_state from private.legacy_inventory_import_backups where user_id = keeper;
  if backup_state->'wallet' <> before_state->'wallet' then
    raise exception 'restore_contract_backup_wrong_wallet';
  end if;
  perform public.import_legacy_inventory(jsonb_set(payload, '{coins}', '99999'));
  if pg_temp.inventory_hash(keeper) <> after_hash then raise exception 'restore_contract_import_replayed'; end if;
  begin
    perform pg_temp.restore_synthetic_import(outsider, after_hash);
    raise exception 'restore_contract_foreign_restore_accepted';
  exception when others then if sqlerrm <> 'restore_synthetic_only' then raise; end if; end;
  begin
    update public.player_wallets set gems = gems + 1 where user_id = keeper;
    perform pg_temp.restore_synthetic_import(keeper, after_hash);
    raise exception 'restore_contract_new_progress_lost';
  exception when others then if sqlerrm <> 'restore_inventory_changed' then raise; end if; end;
  begin
    update private.legacy_inventory_import_backups set created_at = now() - interval '31 days',
      expires_at = now() - interval '1 day' where user_id = keeper;
    perform pg_temp.restore_synthetic_import(keeper, after_hash);
    raise exception 'restore_contract_expired_backup_accepted';
  exception when others then if sqlerrm <> 'restore_backup_unavailable' then raise; end if; end;
  begin
    update private.legacy_inventory_import_backups set pre_import_state = jsonb_set(
      pre_import_state, '{eggs,0,owner_id}', to_jsonb(outsider::text)) where user_id = keeper;
    perform pg_temp.restore_synthetic_import(keeper, after_hash);
    raise exception 'restore_contract_corrupt_owner_accepted';
  exception when others then if sqlerrm <> 'restore_backup_owner' then raise; end if; end;
  begin
    update public.player_economy_authority set authority_mode = 'server', activated_at = now() where user_id = keeper;
    perform pg_temp.restore_synthetic_import(keeper, after_hash);
    raise exception 'restore_contract_server_restore_accepted';
  exception when others then if sqlerrm <> 'restore_legacy_only' then raise; end if; end;
  begin
    perform pg_temp.restore_synthetic_import(keeper, after_hash);
    raise exception 'restore_contract_injected_failure';
  exception when others then if sqlerrm <> 'restore_contract_injected_failure' then raise; end if; end;
  if pg_temp.inventory_hash(keeper) <> after_hash then
    raise exception 'restore_contract_interrupted_restore_not_atomic';
  end if;
  restore_started := clock_timestamp();
  perform pg_temp.restore_synthetic_import(keeper, after_hash);
  if pg_temp.inventory_snapshot(keeper) <> before_state or pg_temp.inventory_hash(keeper) <> before_hash then
    raise exception 'restore_contract_full_snapshot_mismatch';
  end if;
  if clock_timestamp() - restore_started > interval '10 seconds' then
    raise exception 'restore_contract_synthetic_rto_exceeded';
  end if;
  if not exists(select 1 from public.legacy_inventory_import_audit where id = import_record)
    or not exists(select 1 from public.profiles where user_id = keeper and inventory_imported_at is not null) then
    raise exception 'restore_contract_audit_or_lock_lost';
  end if;
  perform public.import_legacy_inventory(payload);
  if pg_temp.inventory_hash(keeper) <> before_hash then
    raise exception 'restore_contract_restore_reopened_import';
  end if;
end;
$$;
rollback;
select true as legacy_import_restore_contract_passed;
