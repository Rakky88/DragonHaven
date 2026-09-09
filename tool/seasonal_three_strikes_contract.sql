-- Staging contract. Fixtures and helper function always roll back.
begin;
create function pg_temp.reject_trial(a uuid, token text, score integer,
    correct integer, total integer, duration integer, expected text)
returns void language plpgsql as $$
begin
  begin
    perform public.complete_seasonal_trial_attempt(a, token, score, correct, total, duration);
    raise exception 'three_strikes_contract_invalid_accepted';
  exception when others then
    if sqlerrm <> expected then raise; end if;
  end;
end $$;

do $$
declare keeper uuid := gen_random_uuid(); stranger uuid := gen_random_uuid();
  run public.seasonal_trial_attempts%rowtype; kind text; value record;
begin
  if has_function_privilege('anon',
      'public.complete_seasonal_trial_attempt(uuid,text,integer,integer,integer,integer)', 'execute') or
      has_table_privilege('authenticated','public.seasonal_trial_attempts','insert') then
    raise exception 'three_strikes_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text || '@three-strikes-contract.invalid',now()),
    (stranger,stranger::text || '@three-strikes-contract.invalid',now());
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  foreach kind in array array['witchlightWard','hollyfrostGiftforge','midnightChime','rosevowRelay','prismaticParade'] loop
    insert into public.seasonal_trial_attempts(user_id,event_id,trial_key,occurrence_key,seed,simulated,started_at,expires_at)
      values(keeper,'contract_' || kind,kind,'three-strikes-contract',24,true,now()-interval '1 minute',now()+interval '1 hour')
      returning * into run;
    perform pg_temp.reject_trial(run.id,null,100,1,4,1000,'seasonal_attempt_token_invalid');
    perform pg_temp.reject_trial(run.id,gen_random_uuid()::text,100,1,4,1000,'seasonal_attempt_token_invalid');
    perform pg_temp.reject_trial(run.id,run.completion_token::text,null,1,4,30000,'seasonal_score_rejected');
    perform pg_temp.reject_trial(run.id,run.completion_token::text,100,null,4,30000,'seasonal_score_rejected');
    perform pg_temp.reject_trial(run.id,run.completion_token::text,100,1,null,30000,'seasonal_score_rejected');
    perform pg_temp.reject_trial(run.id,run.completion_token::text,100,1,4,null,'seasonal_score_rejected');
    perform pg_temp.reject_trial(run.id,run.completion_token::text,100,1,4,999,'seasonal_score_rejected');
    perform pg_temp.reject_trial(run.id,run.completion_token::text,100,1,3,1000,'seasonal_score_rejected');
    perform pg_temp.reject_trial(run.id,run.completion_token::text,100,1,5,1000,'seasonal_score_rejected');
    perform pg_temp.reject_trial(run.id,run.completion_token::text,221,1,4,30000,'seasonal_score_rejected');
    perform pg_temp.reject_trial(run.id,run.completion_token::text,20001,100,103,30000,'seasonal_score_rejected');
    perform pg_temp.reject_trial(run.id,run.completion_token::text,100,1,201,30000,'seasonal_score_rejected');
    perform pg_temp.reject_trial(run.id,run.completion_token::text,100,1,4,180001,'seasonal_score_rejected');
    perform pg_temp.reject_trial(run.id,run.completion_token::text,100,1,4,66000,'seasonal_score_rejected');
    perform set_config('request.jwt.claim.sub', stranger::text, true);
    perform pg_temp.reject_trial(run.id,run.completion_token::text,100,1,4,30000,'seasonal_attempt_not_found');
    perform set_config('request.jwt.claim.sub', '', true);
    perform pg_temp.reject_trial(run.id,run.completion_token::text,100,1,4,30000,'online_login_required');
    perform set_config('request.jwt.claim.sub', keeper::text, true);
    update public.seasonal_trial_attempts set expires_at=now()-interval '1 second' where id=run.id;
    perform pg_temp.reject_trial(run.id,run.completion_token::text,100,1,4,30000,'seasonal_attempt_expired');
    update public.seasonal_trial_attempts set expires_at=now()+interval '1 hour' where id=run.id;
    if kind in ('witchlightWard','hollyfrostGiftforge','midnightChime') then
      select * into value from public.complete_seasonal_trial_attempt(run.id,run.completion_token::text,220,1,4,1000);
    else
      perform pg_temp.reject_trial(run.id,run.completion_token::text,220,1,4,1000,'seasonal_score_rejected');
      select * into value from public.complete_seasonal_trial_attempt(run.id,run.completion_token::text,220,1,4,30000);
    end if;
    if not value.accepted or not value.simulated or value.best_score <> 220 or value.ranking_position <> 1 then
      raise exception 'three_strikes_contract_completion'; end if;
    perform pg_temp.reject_trial(run.id,run.completion_token::text,220,1,4,30000,'seasonal_attempt_used');
    -- A legacy full-duration completion still works and cannot lower a best.
    insert into public.seasonal_trial_attempts(user_id,event_id,trial_key,occurrence_key,seed,simulated,started_at,expires_at)
      values(keeper,'contract_' || kind,kind,'three-strikes-contract',25,true,now()-interval '1 minute',now()+interval '1 hour')
      returning * into run;
    select * into value from public.complete_seasonal_trial_attempt(run.id,run.completion_token::text,100,1,2,30000);
    if not value.accepted or value.best_score <> 220 then raise exception 'three_strikes_contract_legacy'; end if;
  end loop;
end $$;
rollback;
select true as three_strikes_contract_passed;
