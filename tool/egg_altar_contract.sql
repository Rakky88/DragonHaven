-- Staging contract: all test accounts and mutations roll back together.
begin;
do $$
declare
  keeper uuid := gen_random_uuid(); other_keeper uuid := gen_random_uuid(); cid uuid := gen_random_uuid();
  egg_one text := gen_random_uuid()::text; egg_sinister text := gen_random_uuid()::text;
  egg_special text := gen_random_uuid()::text; egg_scan text := gen_random_uuid()::text;
  dragon_key text := gen_random_uuid()::text; inventory jsonb; result jsonb; again jsonb;
  before_wallet jsonb; old_tag jsonb; new_tag jsonb;
begin
  insert into auth.users(id, email, email_confirmed_at) values
    (keeper, keeper::text || '@altar-test.invalid', now()),
    (other_keeper, other_keeper::text || '@altar-test.invalid', now());
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  perform public.ensure_my_online_account();
  perform set_config('request.jwt.claim.sub', other_keeper::text, true);
  perform public.ensure_my_online_account();
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  inventory := jsonb_build_object('eggs', jsonb_build_array(
    jsonb_build_object('client_id', egg_one, 'lineage_id', 'mossprout', 'tradeable', true),
    jsonb_build_object('client_id', egg_sinister, 'lineage_id', 'sinisterra', 'tradeable', true),
    jsonb_build_object('client_id', egg_special, 'lineage_id', 'gloamgourd', 'tradeable', true),
    jsonb_build_object('client_id', egg_scan, 'lineage_id', 'mossprout', 'tradeable', true)),
    'altar_dragons', jsonb_build_array(jsonb_build_object('client_id', dragon_key, 'custom_name', 'Ember')));
  perform public.synchronize_trade_inventory(inventory);
  result := public.get_egg_altar_state();
  if has_table_privilege('authenticated', 'private.egg_altar_accounts', 'update')
    or has_function_privilege('anon', 'public.egg_altar_command(text,text,jsonb)', 'execute') then
    raise exception 'altar_contract_permissions';
  end if;
  result := public.egg_altar_command('tag-one', 'tag', jsonb_build_object('eggId', egg_one, 'tagged', true));
  old_tag := result->'state'->'eggs'->egg_one;
  begin
    perform public.egg_altar_command('blocked-tag', 'return', jsonb_build_object('eggId', egg_one));
    raise exception 'altar_contract_tag_not_blocked';
  exception when others then if sqlerrm <> 'egg_tagged' then raise; end if; end;
  perform public.synchronize_trade_inventory(inventory);
  if not ((public.get_egg_altar_state()->'eggs'->egg_one->>'tagged')::boolean) then
    raise exception 'altar_contract_stale_backup_removed_tag';
  end if;
  result := public.egg_altar_command('untag-one', 'tag', jsonb_build_object('eggId', egg_one, 'tagged', false));
  new_tag := result->'state'->'eggs'->egg_one;
  if (new_tag->>'tagRevision')::bigint <= (old_tag->>'tagRevision')::bigint then raise exception 'altar_contract_tag_revision'; end if;
  result := public.egg_altar_command('return-one', 'return', jsonb_build_object('eggId', egg_one));
  again := public.egg_altar_command('return-one', 'return', jsonb_build_object('eggId', egg_one));
  if result <> again or (result->'state'->'wallet'->>'fragments')::integer <> 5 then raise exception 'altar_contract_retry'; end if;
  perform public.synchronize_trade_inventory(inventory);
  if exists(select 1 from public.player_eggs where legacy_client_id = egg_one) then raise exception 'altar_contract_resurrected_egg'; end if;
  begin
    perform public.egg_altar_command('special', 'return', jsonb_build_object('eggId', egg_special));
    raise exception 'altar_contract_special_not_blocked';
  exception when others then if sqlerrm <> 'special_egg' then raise; end if; end;
  begin
    perform public.egg_altar_command('sinister', 'return', jsonb_build_object('eggId', egg_sinister));
    raise exception 'altar_contract_sinister_not_confirmed';
  exception when others then if sqlerrm <> 'sinister_confirmation_required' then raise; end if; end;
  update private.egg_altar_accounts set misses = 39 where owner_id = keeper;
  result := public.egg_altar_command('sinister-confirmed', 'return', jsonb_build_object('eggId', egg_sinister, 'sinisterConfirmed', true));
  if (result->'receipt'->'reward'->>'fragments')::integer <> 25 or
    (result->'receipt'->'reward'->>'hearts')::integer <> 5 or
    (result->'state'->>'misses')::integer <> 0 then raise exception 'altar_contract_sinister_pity'; end if;
  perform set_config('request.jwt.claim.sub', other_keeper::text, true);
  begin
    perform public.egg_altar_command('not-mine', 'tag', jsonb_build_object('eggId', egg_scan, 'tagged', false));
    raise exception 'altar_contract_ownership_not_enforced';
  exception when others then if sqlerrm <> 'egg_not_found' then raise; end if; end;
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  update private.egg_altar_accounts set fragments = 3000, essence = 30, hearts = 5 where owner_id = keeper;
  result := public.egg_altar_command('craft-oracle', 'craft', '{"relic":"weaveOracle"}');
  if (result->'state'->'wallet'->>'fragments')::integer <> 2875 or
    (result->'state'->'wallet'->>'essence')::integer <> 18 or
    (result->'state'->'wallet'->>'hearts')::integer <> 3 then raise exception 'altar_contract_oracle_cost'; end if;
  result := public.egg_altar_command('scan', 'reveal', jsonb_build_object('eggId', egg_scan, 'relic', 'weaveOracle'));
  if not (result->'state'->'eggs'->egg_scan->>'lineage')::boolean or
    not (result->'state'->'eggs'->egg_scan->>'rarity')::boolean then raise exception 'altar_contract_oracle_result'; end if;
  begin
    perform public.egg_altar_command('repeat-scan', 'reveal', jsonb_build_object('eggId', egg_scan, 'relic', 'weaveOracle'));
    raise exception 'altar_contract_repeat_scan_consumed';
  exception when others then if sqlerrm <> 'already_known' then raise; end if; end;
  perform public.egg_altar_command('craft-quill', 'craft', '{"relic":"nameweaversQuill"}');
  before_wallet := public.get_egg_altar_state()->'wallet';
  result := public.egg_altar_command('rename', 'rename', jsonb_build_object('dragonId', dragon_key, 'name', 'Moss'));
  again := public.egg_altar_command('rename', 'rename', jsonb_build_object('dragonId', dragon_key, 'name', 'Moss'));
  if again <> result or result->'state'->'wallet' <> before_wallet or
    result->'state'->'names'->>dragon_key <> 'Moss' or
    (result->'state'->'crafted'->>'nameweaversQuill')::integer <> 0 then raise exception 'altar_contract_quill'; end if;
  perform public.synchronize_trade_inventory(inventory);
  if public.get_egg_altar_state()->'names'->>dragon_key <> 'Moss' then raise exception 'altar_contract_old_name_restore'; end if;
  -- Protected metadata is carried by the existing authorized trade transfer.
  perform public.egg_altar_command('tag-scan', 'tag', jsonb_build_object('eggId', egg_scan, 'tagged', true));
  update public.player_eggs set owner_id = other_keeper where legacy_client_id = egg_scan;
  perform set_config('request.jwt.claim.sub', other_keeper::text, true);
  result := public.get_egg_altar_state();
  if not (result->'eggs'->egg_scan->>'tagged')::boolean or
    not (result->'eggs'->egg_scan->>'lineage')::boolean then raise exception 'altar_contract_trade_metadata'; end if;
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  insert into public.conclaves(id, name, emblem_key, language, visibility, member_limit, created_by)
    values(cid, 'Altar ' || left(cid::text, 8), 'conclave_emblem_01', 'en', 'invite', 4, keeper);
  insert into public.conclave_members(conclave_id, user_id, role) values(cid, keeper, 'flightmaster');
  result := public.egg_altar_command('donate', 'donate', jsonb_build_object('conclaveId', cid, 'amount', 500));
  again := public.egg_altar_command('donate', 'donate', jsonb_build_object('conclaveId', cid, 'amount', 500));
  if again <> result or (public.get_conclave_weave_beacon(cid)->>'fragments')::integer <> 500 then raise exception 'altar_contract_donation'; end if;
  if (select count(*) from public.conclave_messages where conclave_id = cid) <> 1 then raise exception 'altar_contract_beacon_chat_spam'; end if;
  -- A non-member cannot spend into somebody else's Beacon.
  perform set_config('request.jwt.claim.sub', other_keeper::text, true);
  begin
    perform public.egg_altar_command('donate-other', 'donate', jsonb_build_object('conclaveId', cid, 'amount', 1));
    raise exception 'altar_contract_nonmember_donation';
  exception when others then if sqlerrm <> 'conclave_member_not_found' then raise; end if; end;
end
$$;
rollback;
select true as egg_altar_contract_passed;
