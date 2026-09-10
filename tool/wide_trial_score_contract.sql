begin;
set local statement_timeout='45s';
do $$
declare keeper uuid:=gen_random_uuid(); friend_id uuid:=gen_random_uuid(); attempt public.seasonal_trial_attempts%rowtype;
  result record; occurrence text; prize uuid:=gen_random_uuid();
begin
  if (select enabled or shadow_social_enabled or shadow_projection_enabled or shadow_lifecycle_enabled
      from private.game_engine_runtime where singleton) then raise exception 'wide_score_contract_requires_dormant'; end if;
  if to_regprocedure('public.complete_seasonal_trial_attempt_v74(uuid,text,integer,integer,integer,integer)') is not null or
      not has_function_privilege('authenticated','public.complete_seasonal_trial_attempt(uuid,text,bigint,bigint,bigint,bigint)','execute') then
    raise exception 'wide_score_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values(keeper,keeper::text||'@wide-score-contract.invalid',now());
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  perform public.ensure_my_online_account();
  insert into auth.users(id,email,email_confirmed_at) values(friend_id,friend_id::text||'@wide-score-contract.invalid',now());
  perform set_config('request.jwt.claim.sub',friend_id::text,true);
  perform public.ensure_my_online_account();
  insert into public.friendships(requester_id,addressee_id,status) values(keeper,friend_id,'accepted');
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  occurrence:='preview:sunwake_summer_sea:'||keeper::text;
  insert into public.seasonal_event_previews(user_id,event_id,activated_at,expires_at)
    values(keeper,'sunwake_summer_sea',now(),now()+interval '2 days');
  insert into public.seasonal_trial_attempts(user_id,event_id,trial_key,occurrence_key,seed,simulated,started_at,expires_at)
    values(keeper,'sunwake_summer_sea','sunwakeSurf',occurrence,17,true,
      now()-interval '100 days',now()+interval '6 hours') returning * into attempt;
  select * into result from public.complete_seasonal_trial_attempt(attempt.id,attempt.completion_token::text,
    3000000000::bigint,13636364::bigint,13636367::bigint,8000000000::bigint);
  if not result.accepted or result.best_score<>3000000000 or not result.simulated then
    raise exception 'wide_score_contract_large_completion'; end if;
  select * into result from public.get_seasonal_trial_rankings('sunwake_summer_sea',occurrence,true,100)
    where user_id=keeper;
  if not found or result.score<>3000000000 or result.duration_ms<>8000000000 then
    raise exception 'wide_score_contract_large_ranking'; end if;
  begin
    perform public.complete_seasonal_trial_attempt(attempt.id,attempt.completion_token::text,
      3000000000::bigint,13636364::bigint,13636367::bigint,8000000000::bigint);
    raise exception 'wide_score_contract_repeated_completion';
  exception when others then if sqlerrm<>'seasonal_attempt_used' then raise; end if; end;
  insert into public.social_showcases(user_id,cavern_flight_best) values(keeper,3000000000)
    on conflict(user_id) do update set cavern_flight_best=excluded.cavern_flight_best;
  select * into result from public.get_trial_rankings('cavernFlight','world',100) where is_current_user;
  if not found or result.score<>3000000000 then raise exception 'wide_score_contract_ordinary_ranking'; end if;
  update public.social_showcases set favorite_dragon_cavern_flight_best=3000000000 where user_id=keeper;
  select * into result from public.get_my_profile();
  if result.cavern_flight_best<>3000000000 or result.favorite_dragon_cavern_flight_best<>3000000000 then
    raise exception 'wide_score_contract_profile'; end if;
  perform set_config('request.jwt.claim.sub',friend_id::text,true);
  select * into result from public.list_my_friends() where user_id=keeper;
  if not found or result.cavern_flight_best<>3000000000 or result.favorite_dragon_cavern_flight_best<>3000000000 then
    raise exception 'wide_score_contract_friend'; end if;
  if (public.get_online_snapshot()->'friends'->0->>'cavern_flight_best')::bigint<>3000000000 then
    raise exception 'wide_score_contract_snapshot'; end if;
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  insert into public.seasonal_event_prizes(id,event_id,occurrence_key,user_id,ranking_position,score,podium_emote_id)
    values(prize,'sunwake_summer_sea','sunwake_summer_sea:2027',keeper,1,3000000000,'seasonal_sunwake_gold');
  select * into result from public.list_seasonal_chronicle() where prize_id=prize;
  if not found or result.score<>3000000000 then raise exception 'wide_score_contract_chronicle'; end if;
  select * into result from public.finalize_my_seasonal_event_prizes() where prize_id=prize;
  if not found or result.score<>3000000000 then raise exception 'wide_score_contract_podium'; end if;
  -- Reject values that a phone/JavaScript client cannot represent exactly.
  insert into public.seasonal_trial_attempts(user_id,event_id,trial_key,occurrence_key,seed,simulated,started_at,expires_at)
    values(keeper,'sunwake_summer_sea','sunwakeSurf',occurrence,18,true,now()-interval '100 days',now()+interval '6 hours') returning * into attempt;
  begin
    perform public.complete_seasonal_trial_attempt(attempt.id,attempt.completion_token::text,
      9007199254740992::bigint,9007199254740992::bigint,9007199254740992::bigint,9007199254740992::bigint);
    raise exception 'wide_score_contract_imprecise_value_accepted';
  exception when others then if sqlerrm<>'seasonal_score_rejected' then raise; end if; end;
  if (select completed_at is not null from public.seasonal_trial_attempts where id=attempt.id) then
    raise exception 'wide_score_contract_rejection_mutated'; end if;
  perform set_config('request.jwt.claim.role','service_role',true);
  delete from auth.users where id in (keeper,friend_id);
end $$;
select true as wide_trial_score_contract_passed;
rollback;
