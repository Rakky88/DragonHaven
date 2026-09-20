begin;
do $$
declare
  keeper uuid := gen_random_uuid();
  a record; r record; spec record;
begin
  insert into auth.users(id,email,email_confirmed_at)
    values(keeper,keeper::text||'@uncapped-contract.invalid',now());
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  for spec in select * from (values
    ('halloween_witchlight','witchlightWard'),
    ('christmas_winter_hearth','hollyfrostGiftforge'),
    ('valentine_two_heartlights','rosevowRelay'),
    ('pride_every_color','prismaticParade'),
    ('golden_wings_birthday','wishcakeTower'),
    ('harvestmoon_moonlit_orchard','moonlitOrchard')
  ) v(event_id,trial_key) loop
    insert into public.seasonal_trial_attempts(user_id,event_id,trial_key,occurrence_key,
        seed,simulated,started_at,expires_at)
      values(keeper,spec.event_id,spec.trial_key,spec.event_id||':contract',5,false,
        now()-interval '90 seconds',now()+interval '1 hour')
      returning id,completion_token into a;
    select * into r from public.complete_seasonal_trial_attempt(
      a.id,a.completion_token::text,30000,210,211,90000);
    if not r.accepted or r.best_score<>30000 then
      raise exception 'uncapped_contract_score_ceiling'; end if;
    begin
      perform public.complete_seasonal_trial_attempt(a.id,a.completion_token::text,30000,210,211,90000);
      raise exception 'uncapped_contract_duplicate';
    exception when others then if sqlerrm<>'seasonal_attempt_used' then raise; end if; end;
  end loop;
  insert into public.seasonal_trial_attempts(user_id,event_id,trial_key,occurrence_key,
      seed,simulated,started_at,expires_at)
    values(keeper,'golden_wings_birthday','wishcakeTower','golden_wings_birthday:long',5,false,
      now()-interval '8 hours',now()+interval '1 minute')
    returning id,completion_token into a;
  if public.renew_seasonal_trial_attempt(a.id,a.completion_token::text) <> now()+interval '6 hours' then
    raise exception 'uncapped_contract_birthday_renewal'; end if;
  begin
    perform public.complete_seasonal_trial_attempt(a.id,a.completion_token::text,1000000,6000,6000,28800000);
    raise exception 'uncapped_contract_missing_miss';
  exception when others then if sqlerrm<>'seasonal_score_rejected' then raise; end if; end;
  select * into r from public.complete_seasonal_trial_attempt(
    a.id,a.completion_token::text,1000000,6000,6001,28800000);
  if not r.accepted or r.best_score<>1000000 then
    raise exception 'uncapped_contract_birthday_long'; end if;
end;
$$;
rollback;
select true as uncapped_contract_passed;
