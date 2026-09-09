-- Registered staging only. Every fixture and the temporary calendar roll back.
begin;

-- Exercise an official calendar occurrence on any date without changing clocks.
create or replace function public.seasonal_event_window(p_event_id text, p_now timestamptz default now())
returns table(occurrence_key text, starts_at timestamptz, ends_at timestamptz, results_end_at timestamptz)
language sql set search_path = '' stable as $$
  select 'halloween_witchlight:contract', p_now - interval '1 hour',
    p_now + interval '1 day', p_now + interval '6 days'
  where p_event_id = 'halloween_witchlight';
$$;

do $$
declare keeper uuid := gen_random_uuid(); other_keeper uuid := gen_random_uuid();
  attempt record; completed record; expiry timestamptz;
begin
  if has_function_privilege('anon','public.end_my_seasonal_event(text)','execute') or
      has_table_privilege('authenticated','public.seasonal_event_dismissals','insert') then
    raise exception 'end_event_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text || '@end-event-contract.invalid',now()),
    (other_keeper,other_keeper::text || '@end-event-contract.invalid',now());
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  perform public.ensure_my_online_account();
  perform public.redeem_seasonal_event_preview('HALLOWEENEVENT');
  select * into attempt from public.start_seasonal_trial_attempt('halloween_witchlight','witchlightWard');
  update public.seasonal_trial_attempts set started_at = now() - interval '1 minute' where id = attempt.attempt_id;
  perform set_config('request.jwt.claim.sub', other_keeper::text, true);
  perform public.ensure_my_online_account();
  perform public.redeem_seasonal_event_preview('HALLOWEENEVENT');
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  begin
    perform public.end_my_seasonal_event('NOTACODE');
    raise exception 'end_event_contract_invalid_accepted';
  exception when others then if sqlerrm <> 'seasonal_preview_invalid' then raise; end if; end;
  if not exists(select 1 from public.list_my_seasonal_event_previews()) then
    raise exception 'end_event_contract_invalid_mutated'; end if;
  perform public.end_my_seasonal_event('ENDEVENT');
  if exists(select 1 from public.list_my_seasonal_event_previews()) then
    raise exception 'end_event_contract_preview_survived'; end if;
  select expires_at into expiry from public.list_my_seasonal_event_dismissals()
    where event_id = 'halloween_witchlight';
  if expiry is distinct from now() + interval '1 day' then
    raise exception 'end_event_contract_calendar_not_stopped'; end if;
  perform public.end_my_seasonal_event('ENDEVENT');
  if (select expires_at from public.list_my_seasonal_event_dismissals()
      where event_id = 'halloween_witchlight') is distinct from expiry then
    raise exception 'end_event_contract_retry_changed_expiry'; end if;
  begin
    perform public.start_seasonal_trial_attempt('halloween_witchlight','witchlightWard');
    raise exception 'end_event_contract_stopped_trial_started';
  exception when others then if sqlerrm <> 'seasonal_trial_unavailable' then raise; end if; end;
  select * into completed from public.complete_seasonal_trial_attempt(
    attempt.attempt_id, attempt.completion_token::text, 100, 1, 2, 30000);
  if not completed.accepted then raise exception 'end_event_contract_started_run_lost'; end if;
  perform public.redeem_seasonal_event_preview('HALLOWEENEVENT');
  perform public.start_seasonal_trial_attempt('halloween_witchlight','witchlightWard');
  perform set_config('request.jwt.claim.sub', other_keeper::text, true);
  if exists(select 1 from public.list_my_seasonal_event_dismissals()) or
      not exists(select 1 from public.list_my_seasonal_event_previews()) then
    raise exception 'end_event_contract_other_account_changed'; end if;
  -- Email verification is checked before any destructive operation.
  update auth.users set email_confirmed_at = null where id = other_keeper;
  begin
    perform public.end_my_seasonal_event('ENDEVENT');
    raise exception 'end_event_contract_unverified_accepted';
  exception when others then if sqlerrm <> 'email_not_verified' then raise; end if; end;
  if not exists(select 1 from public.list_my_seasonal_event_previews()) then
    raise exception 'end_event_contract_unverified_mutated'; end if;
end;
$$;
rollback;
select true as end_event_contract_passed;
