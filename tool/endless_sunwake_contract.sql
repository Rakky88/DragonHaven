begin;
do $$
declare
  keeper uuid := gen_random_uuid();
  stranger uuid := gen_random_uuid();
  a record; r record; extended timestamptz;
begin
  if has_function_privilege('anon','public.renew_seasonal_trial_attempt(uuid,text)','execute') then
    raise exception 'endless_contract_anonymous_renewal'; end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text||'@endless-contract.invalid',now()),
    (stranger,stranger::text||'@endless-contract.invalid',now());
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  -- A run may continue past the old time, action and score ceilings, even
  -- after its event ends. A lease renewal preserves its original provenance.
  insert into public.seasonal_trial_attempts(user_id,event_id,trial_key,occurrence_key,
      seed,simulated,started_at,expires_at)
    values(keeper,'sunwake_summer_sea','sunwakeSurf','sunwake_summer_sea:2027',5,false,
      now()-interval '8 hours',now()+interval '1 minute')
    returning id,completion_token into a;
  perform set_config('request.jwt.claim.sub',stranger::text,true);
  begin
    perform public.renew_seasonal_trial_attempt(a.id,a.completion_token::text);
    raise exception 'endless_contract_foreign_renewal';
  exception when others then if sqlerrm<>'seasonal_attempt_unavailable' then raise; end if; end;
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  begin
    perform public.renew_seasonal_trial_attempt(a.id,gen_random_uuid()::text);
    raise exception 'endless_contract_wrong_token';
  exception when others then if sqlerrm<>'seasonal_attempt_unavailable' then raise; end if; end;
  extended := public.renew_seasonal_trial_attempt(a.id,a.completion_token::text);
  if extended <> now()+interval '6 hours' then raise exception 'endless_contract_lease'; end if;
  begin
    perform public.complete_seasonal_trial_attempt(a.id,a.completion_token::text,50000,250,252,200000);
    raise exception 'endless_contract_missing_third_mistake';
  exception when others then if sqlerrm<>'seasonal_score_rejected' then raise; end if; end;
  begin
    perform public.complete_seasonal_trial_attempt(a.id,a.completion_token::text,50000,250,253,10000);
    raise exception 'endless_contract_impossible_gate_rate';
  exception when others then if sqlerrm<>'seasonal_score_rejected' then raise; end if; end;
  begin
    perform public.complete_seasonal_trial_attempt(a.id,a.completion_token::text,60000,250,253,200000);
    raise exception 'endless_contract_impossible_points';
  exception when others then if sqlerrm<>'seasonal_score_rejected' then raise; end if; end;
  select * into r from public.complete_seasonal_trial_attempt(
      a.id,a.completion_token::text,50000,250,253,28800000);
  if not r.accepted or r.simulated or r.best_score<>50000 then
    raise exception 'endless_contract_long_run'; end if;
  begin
    perform public.renew_seasonal_trial_attempt(a.id,a.completion_token::text);
    raise exception 'endless_contract_finished_renewal';
  exception when others then if sqlerrm<>'seasonal_attempt_unavailable' then raise; end if; end;
  begin
    perform public.complete_seasonal_trial_attempt(a.id,a.completion_token::text,50000,250,253,28800000);
    raise exception 'endless_contract_replay';
  exception when others then if sqlerrm<>'seasonal_attempt_used' then raise; end if; end;
  insert into public.seasonal_trial_attempts(user_id,event_id,trial_key,occurrence_key,
      seed,simulated,started_at,expires_at)
    values(keeper,'sunwake_summer_sea','sunwakeSurf','sunwake_summer_sea:2027',5,false,
      now()-interval '8 hours',now()-interval '1 minute')
    returning id,completion_token into a;
  begin
    perform public.renew_seasonal_trial_attempt(a.id,a.completion_token::text);
    raise exception 'endless_contract_expired_renewal';
  exception when others then if sqlerrm<>'seasonal_attempt_unavailable' then raise; end if; end;
  -- Other event games keep their existing validation.
  insert into public.seasonal_trial_attempts(user_id,event_id,trial_key,occurrence_key,
      seed,simulated,started_at,expires_at)
    values(keeper,'harvestmoon_moonlit_orchard','moonlitOrchard','harvestmoon_moonlit_orchard:2027',5,false,
      now()-interval '8 hours',now()+interval '1 hour')
    returning id,completion_token into a;
  begin
    perform public.complete_seasonal_trial_attempt(a.id,a.completion_token::text,50000,250,253,28800000);
    raise exception 'endless_contract_other_game';
  exception when others then if sqlerrm<>'seasonal_score_rejected' then raise; end if; end;
end;
$$;
rollback;
select true as endless_contract_passed;
