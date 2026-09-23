begin;
set local statement_timeout='40s';
do $$
declare a uuid:=gen_random_uuid(); b uuid:=gen_random_uuid(); rules text:=repeat('a8',32);
  first_seed jsonb; second_seed jsonb; revision bigint; saved jsonb;
begin
  if has_function_privilege('authenticated','public.begin_server_account_initialization(uuid,integer,text)','execute')
    or has_function_privilege('authenticated','public.commit_server_account_initialization(uuid,text,jsonb)','execute')
    or has_table_privilege('authenticated','private.server_account_initializations','select')
    or has_function_privilege('anon','public.get_my_server_gameplay_status(integer,integer)','execute')
  then raise exception 'start_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (a,a::text||'@server-start.invalid',now()),(b,b::text||'@server-start.invalid',now());
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',a::text,true);
  perform public.ensure_my_online_account();
  perform public.acknowledge_my_privacy_notice('2026-09-23',true);
  perform set_config('request.jwt.claim.sub',b::text,true);
  perform public.ensure_my_online_account();
  update private.game_engine_runtime set migration_enabled=true,ruleset_sha256=rules,minimum_client_build=10091 where singleton;
  if public.get_my_online_session_status()->>'migration_enabled'<>'false' then raise exception 'start_contract_old_client'; end if;
  if public.get_my_server_gameplay_status(10091,1)->>'migration_enabled'<>'true' then raise exception 'start_contract_new_client'; end if;
  begin
    perform public.get_my_server_gameplay_status(10091,0);
    raise exception 'start_contract_protocol';
  exception when others then if sqlerrm<>'game_client_upgrade_required' then raise; end if; end;
  perform set_config('request.jwt.claim.role','service_role',true);
  begin
    perform public.begin_server_account_initialization(b,10091,rules);
    raise exception 'start_contract_notice';
  exception when others then if sqlerrm<>'privacy_confirmation_required' then raise; end if; end;
  first_seed:=public.begin_server_account_initialization(a,10091,rules);
  second_seed:=public.begin_server_account_initialization(a,10091,rules);
  if first_seed<>second_seed or first_seed->>'source_revision' is not null then raise exception 'start_contract_seed'; end if;
  saved:='{"schemaVersion":54,"onboardingComplete":false,"fixture":"no-player-data"}'::jsonb;
  revision:=public.commit_server_account_initialization(a,rules,saved);
  if revision<>1 or public.commit_server_account_initialization(a,rules,saved)<>1 then raise exception 'start_contract_replay'; end if;
  if public.begin_server_account_initialization(a,10091,rules)->>'source_revision'<>'1'
    or (select count(*) from public.cloud_game_saves where user_id=a)<>1
    or (select state from public.cloud_game_saves where user_id=a)<>saved
  then raise exception 'start_contract_saved'; end if;
  begin
    perform public.commit_server_account_initialization(a,rules,saved||'{"different":true}'::jsonb);
    raise exception 'start_contract_conflict';
  exception when others then if sqlerrm<>'game_idempotency_conflict' then raise; end if; end;
  perform set_config('request.jwt.claim.sub',b::text,true);
  perform public.acknowledge_my_privacy_notice('2026-09-23',true);
  update public.player_wallets set coins=26 where user_id=b;
  begin
    perform public.begin_server_account_initialization(b,10091,rules);
    raise exception 'start_contract_existing_asset';
  exception when others then if sqlerrm<>'game_existing_progress_requires_migration' then raise; end if; end;
  if exists(select 1 from private.server_account_initializations where owner_id=b) then raise exception 'start_contract_rejected_write'; end if;
  update private.game_engine_runtime set migration_enabled=false where singleton;
  begin
    perform public.begin_server_account_initialization(a,10091,rules);
    raise exception 'start_contract_disabled';
  exception when others then if sqlerrm<>'game_migration_disabled' then raise; end if; end;
end $$;
rollback;
select true as server_account_start_contract_passed;
