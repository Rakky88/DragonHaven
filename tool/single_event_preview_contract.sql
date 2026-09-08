-- Staging-only synthetic fixtures; all state and scores are rolled back.
begin;
do $$
declare keeper uuid := gen_random_uuid(); other_keeper uuid := gen_random_uuid();
  attempt record; activated record; retried record; completed record;
begin
  insert into auth.users(id, email, email_confirmed_at) values
    (keeper, keeper::text || '@event-contract.invalid', now()),
    (other_keeper, other_keeper::text || '@event-contract.invalid', now());
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  perform public.ensure_my_online_account();
  perform set_config('request.jwt.claim.sub', other_keeper::text, true);
  perform public.ensure_my_online_account();
  perform set_config('request.jwt.claim.sub', keeper::text, true);
  insert into public.seasonal_event_previews(user_id,event_id,activated_at,expires_at) values
    (keeper, 'christmas_winter_hearth', now(), now() + interval '48 hours'),
    (other_keeper, 'christmas_winter_hearth', now(), now() + interval '48 hours');
  select * into attempt from public.start_seasonal_trial_attempt('christmas_winter_hearth','hollyfrostGiftforge');
  update public.seasonal_trial_attempts set started_at = now() - interval '1 minute' where id = attempt.attempt_id;
  select * into activated from public.redeem_seasonal_event_preview('HALLOWEENEVENT');
  if activated.event_id <> 'halloween_witchlight' or
    (select count(*) from public.list_my_seasonal_event_previews()) <> 1 or
    exists(select 1 from public.seasonal_event_previews where user_id = keeper and event_id <> 'halloween_witchlight') then
    raise exception 'event_contract_switch_failed'; end if;
  if not exists(select 1 from public.seasonal_event_previews where user_id = other_keeper and event_id = 'christmas_winter_hearth') then
    raise exception 'event_contract_other_account_changed'; end if;
  select * into retried from public.redeem_seasonal_event_preview('HALLOWEENEVENT');
  if retried.expires_at <> activated.expires_at then raise exception 'event_contract_retry_extended'; end if;
  begin
    perform public.start_seasonal_trial_attempt('christmas_winter_hearth','hollyfrostGiftforge');
    raise exception 'event_contract_old_event_started';
  exception when others then if sqlerrm <> 'seasonal_trial_unavailable' then raise; end if; end;
  select * into completed from public.complete_seasonal_trial_attempt(
    attempt.attempt_id, attempt.completion_token::text, 100, 1, 2, 30000);
  if not completed.accepted or not exists(select 1 from public.seasonal_trial_bests
      where user_id = keeper and event_id = 'christmas_winter_hearth' and score = 100) then
    raise exception 'event_contract_started_attempt_lost'; end if;
  begin
    perform public.redeem_seasonal_event_preview('CHRISTMASEVENT');
    raise exception 'event_contract_restriction_missing';
  exception when others then if sqlerrm <> 'seasonal_preview_restricted' then raise; end if; end;
  if (select event_id from public.list_my_seasonal_event_previews()) <> 'halloween_witchlight' then
    raise exception 'event_contract_refusal_changed_event'; end if;
end;
$$;
rollback;
select true as single_event_preview_contract_passed;
