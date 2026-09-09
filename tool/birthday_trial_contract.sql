-- Synthetic verified/unverified accounts; all changes roll back on staging.
begin;
do $$
declare keeper uuid := gen_random_uuid(); stranger uuid := gen_random_uuid();
  unverified uuid := gen_random_uuid(); code text; first_expiry timestamptz;
  response record; stranger_expiry timestamptz;
begin
  if has_function_privilege('anon','public.redeem_seasonal_event_preview(text)','execute') or
     has_table_privilege('authenticated','public.seasonal_event_previews','insert') then
    raise exception 'preview_access_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text || '@preview-access-contract.invalid',now()),
    (stranger,stranger::text || '@preview-access-contract.invalid',now()),
    (unverified,unverified::text || '@preview-access-contract.invalid',null);
  perform set_config('request.jwt.claim.sub','',true);
  begin
    perform public.redeem_seasonal_event_preview('HALLOWEENEVENT');
    raise exception 'preview_access_contract_anonymous_accepted';
  exception when others then
    if sqlerrm <> 'online_login_required' then raise; end if;
  end;
  perform set_config('request.jwt.claim.sub',unverified::text,true);
  begin
    perform public.redeem_seasonal_event_preview('HALLOWEENEVENT');
    raise exception 'preview_access_contract_unverified_accepted';
  exception when others then
    if sqlerrm <> 'email_not_verified' then raise; end if;
  end;
  perform set_config('request.jwt.claim.sub',stranger::text,true);
  select p.expires_at into stranger_expiry from public.redeem_seasonal_event_preview('HALLOWEENEVENT') p;
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  begin
    perform public.redeem_seasonal_event_preview('INVALID');
    raise exception 'preview_access_contract_invalid_accepted';
  exception when others then
    if sqlerrm <> 'seasonal_preview_invalid' then raise; end if;
  end;
  foreach code in array array['BDAYEVENT','HALLOWEENEVENT','CHRISTMASEVENT','NEWYEARSEVENT','VALENTINEEVENT','PRIDEFESTEVENT'] loop
    select * into response from public.redeem_seasonal_event_preview(code);
    first_expiry := response.expires_at;
    if first_expiry <> now() + interval '48 hours' or
      (select count(*) from public.list_my_seasonal_event_previews()) <> 1 or
      (select count(*) from public.seasonal_event_previews p where p.user_id=keeper) <> 1 then
      raise exception 'preview_access_contract_activation'; end if;
    select * into response from public.redeem_seasonal_event_preview(lower(code));
    if response.expires_at <> first_expiry then raise exception 'preview_access_contract_retry_extended'; end if;
    if (select p.expires_at from public.seasonal_event_previews p where p.user_id=stranger) <> stranger_expiry then
      raise exception 'preview_access_contract_other_account_changed'; end if;
  end loop;
end $$;

do $$
declare keeper uuid := gen_random_uuid(); stranger uuid := gen_random_uuid();
  attempt record; result record; w record;
begin
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text || '@birthday-contract.invalid',now()),
    (stranger,stranger::text || '@birthday-contract.invalid',now());
  if exists(select 1 from public.seasonal_event_window('golden_wings_birthday','2025-09-01Z')) then
    raise exception 'birthday_contract_early_calendar'; end if;
  select * into w from public.seasonal_event_window('golden_wings_birthday','2026-09-01Z');
  if w.starts_at <> '2026-08-31T22:00:00Z' or w.ends_at <> '2026-09-02T22:00:00Z' then
    raise exception 'birthday_contract_launch_calendar'; end if;
  select * into w from public.seasonal_event_window('golden_wings_birthday','2027-07-01Z');
  if w.occurrence_key <> 'golden_wings_birthday:2027' or w.starts_at <> '2027-05-12T22:00:00Z'
      or w.ends_at <> '2027-05-13T22:00:00Z' or w.results_end_at <> '2027-05-18T22:00:00Z' then
    raise exception 'birthday_contract_recurring_calendar'; end if;
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  perform public.redeem_seasonal_event_preview('BDAYEVENT');
  begin
    perform public.start_seasonal_trial_attempt('golden_wings_birthday','witchlightWard');
    raise exception 'birthday_contract_wrong_game';
  exception when others then if sqlerrm <> 'seasonal_trial_invalid' then raise; end if; end;
  select * into attempt from public.start_seasonal_trial_attempt('golden_wings_birthday','wishcakeTower');
  if not attempt.simulated or attempt.occurrence_key <> 'preview:golden_wings_birthday:' || keeper::text then
    raise exception 'birthday_contract_preview_provenance'; end if;
  update public.seasonal_trial_attempts set started_at=now()-interval '5 seconds' where id=attempt.attempt_id;
  perform set_config('request.jwt.claim.sub',stranger::text,true);
  begin
    perform public.complete_seasonal_trial_attempt(attempt.attempt_id,attempt.completion_token::text,130,1,4,2000);
    raise exception 'birthday_contract_foreign_attempt';
  exception when others then if sqlerrm <> 'seasonal_attempt_not_found' then raise; end if; end;
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  begin
    perform public.complete_seasonal_trial_attempt(attempt.attempt_id,'wrong',130,1,4,2000);
    raise exception 'birthday_contract_bad_token';
  exception when others then if sqlerrm <> 'seasonal_attempt_token_invalid' then raise; end if; end;
  begin
    perform public.complete_seasonal_trial_attempt(attempt.attempt_id,attempt.completion_token::text,130,1,3,2000);
    raise exception 'birthday_contract_early_two_mistakes';
  exception when others then if sqlerrm <> 'seasonal_score_rejected' then raise; end if; end;
  begin
    perform public.complete_seasonal_trial_attempt(attempt.attempt_id,attempt.completion_token::text,221,1,4,2000);
    raise exception 'birthday_contract_inflated_score';
  exception when others then if sqlerrm <> 'seasonal_score_rejected' then raise; end if; end;
  perform public.end_my_seasonal_event('ENDEVENT');
  if exists(select 1 from public.list_my_seasonal_event_previews()) then
    raise exception 'birthday_contract_end_preview'; end if;
  -- A started run still completes after its event closes, with preview provenance.
  select * into result from public.complete_seasonal_trial_attempt(attempt.attempt_id,attempt.completion_token::text,130,1,4,2000);
  if not result.accepted or not result.simulated or result.best_score <> 130 then
    raise exception 'birthday_contract_completion'; end if;
  if not exists(select 1 from public.seasonal_trial_bests b where b.user_id=keeper
      and b.event_id='golden_wings_birthday' and b.preview and b.score=130) then
    raise exception 'birthday_contract_score_not_saved'; end if;
  if exists(select 1 from public.seasonal_event_prizes p where p.user_id=keeper) then
    raise exception 'birthday_contract_preview_podium'; end if;
  begin
    perform public.complete_seasonal_trial_attempt(attempt.attempt_id,attempt.completion_token::text,130,1,4,2000);
    raise exception 'birthday_contract_duplicate_completion';
  exception when others then if sqlerrm <> 'seasonal_attempt_used' then raise; end if; end;
end $$;

rollback;
select true as birthday_contract_passed;
