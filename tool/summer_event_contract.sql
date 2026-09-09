-- Synthetic accounts only. Staging rehearsal and post-apply verification roll back.
begin;
do $$
declare keeper uuid:=gen_random_uuid(); other_keeper uuid:=gen_random_uuid();
  group_id uuid:=gen_random_uuid(); other_group uuid:=gen_random_uuid();
  w record; a record; result record; eid text; game text; code text; j jsonb;
begin
  if has_table_privilege('authenticated','public.seasonal_conclave_projects','insert')
     or has_table_privilege('anon','public.seasonal_conclave_projects','select')
     or has_function_privilege('authenticated','private.seasonal_conclave_project_snapshot(uuid)','execute') then
    raise exception 'summer_contract_permissions'; end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text||'@summer-contract.invalid',now()),
    (other_keeper,other_keeper::text||'@summer-contract.invalid',now());
  insert into public.conclaves(id,name,emblem_key,language,visibility,member_limit,created_by) values
    (group_id,'Summer '||left(group_id::text,8),'conclave_emblem_01','en','invite',4,keeper),
    (other_group,'Summer '||left(other_group::text,8),'conclave_emblem_02','en','invite',4,other_keeper);
  insert into public.conclave_members(conclave_id,user_id,role) values
    (group_id,keeper,'flightmaster'),(other_group,other_keeper,'flightmaster');
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  foreach eid in array array['sunwake_summer_sea','harvestmoon_moonlit_orchard'] loop
    if exists(select 1 from public.seasonal_event_window(eid,'2026-08-01Z')) then
      raise exception 'summer_contract_before_initial_year'; end if;
    select * into w from public.seasonal_event_window(eid,'2027-08-01Z');
    if w.occurrence_key<>eid||':2027' or w.ends_at-w.starts_at<>interval '7 days'
       or w.results_end_at-w.ends_at<>interval '5 days' then
      raise exception 'summer_contract_window'; end if;
    if (eid='sunwake_summer_sea' and (w.starts_at<>'2027-07-19T22:00:00Z'
         or w.ends_at<>'2027-07-26T22:00:00Z'))
       or (eid='harvestmoon_moonlit_orchard' and (w.starts_at<>'2027-09-06T22:00:00Z'
         or w.ends_at<>'2027-09-13T22:00:00Z')) then
      raise exception 'summer_contract_amsterdam_calendar'; end if;
    game:=case eid when 'sunwake_summer_sea' then 'sunwakeSurf' else 'moonlitOrchard' end;
    code:=case eid when 'sunwake_summer_sea' then 'SUNWAKEEVENT' else 'HARVESTMOONEVENT' end;
    select * into result from public.redeem_seasonal_event_preview(lower(code));
    if result.event_id<>eid or result.expires_at<>now()+interval '48 hours' then
      raise exception 'summer_contract_preview'; end if;
    begin
      perform public.start_seasonal_trial_attempt(eid,null);
      raise exception 'summer_contract_null_game';
    exception when others then if sqlerrm<>'seasonal_trial_invalid' then raise; end if; end;
    select * into a from public.start_seasonal_trial_attempt(eid,game);
    if (select conclave_id from public.seasonal_trial_attempts where id=a.attempt_id)<>group_id then
      raise exception 'summer_contract_conclave_at_start'; end if;
    update public.seasonal_trial_attempts set started_at=now()-interval '5 seconds' where id=a.attempt_id;
    begin
      perform public.complete_seasonal_trial_attempt(a.attempt_id,a.completion_token::text,130,1,3,2000);
      raise exception 'summer_contract_two_errors_early';
    exception when others then if sqlerrm<>'seasonal_score_rejected' then raise; end if; end;
    select * into result from public.complete_seasonal_trial_attempt(a.attempt_id,a.completion_token::text,130,1,4,2000);
    if not result.accepted or not result.simulated then raise exception 'summer_contract_complete_preview'; end if;
    j:=public.get_my_conclave_snapshot();
    if not exists(select 1 from jsonb_array_elements(j->'seasonal_projects') p
        where p->>'event_id'=eid and p->>'preview'='true' and p->>'completed_trials'='1') then
      raise exception 'summer_contract_preview_cosmetic'; end if;
    if exists(select 1 from public.seasonal_conclave_projects where conclave_id=group_id) then
      raise exception 'summer_contract_preview_permanent_progress'; end if;
    begin
      perform public.complete_seasonal_trial_attempt(a.attempt_id,a.completion_token::text,130,1,4,2000);
      raise exception 'summer_contract_double_complete';
    exception when others then if sqlerrm<>'seasonal_attempt_used' then raise; end if; end;
    perform public.end_my_seasonal_event('ENDEVENT');
    if exists(select 1 from public.list_my_seasonal_event_previews()) then
      raise exception 'summer_contract_end'; end if;
  end loop;
  -- A synthetic already-started official run can finish after the event ends.
  -- This avoids changing the server clock or a live event activation.
  insert into public.seasonal_trial_attempts(user_id,event_id,trial_key,occurrence_key,
      seed,simulated,started_at,expires_at,conclave_id)
    values(keeper,'sunwake_summer_sea','sunwakeSurf','sunwake_summer_sea:2027',1,false,
      now()-interval '80 seconds',now()+interval '5 hours',group_id)
    returning id as attempt_id,completion_token into a;
  perform public.complete_seasonal_trial_attempt(a.attempt_id,a.completion_token::text,7500,40,42,75000);
  if (select completed_trials from public.seasonal_conclave_projects where conclave_id=group_id)<>1 then
    raise exception 'summer_contract_official_credit'; end if;
  if exists(select 1 from public.seasonal_conclave_projects where conclave_id=other_group) then
    raise exception 'summer_contract_other_group_credit'; end if;
  perform set_config('request.jwt.claim.sub',other_keeper::text,true);
  if private.seasonal_conclave_project_snapshot(group_id)<>'[]'::jsonb then
    raise exception 'summer_contract_foreign_group_read'; end if;
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  -- New birthday run: one successful layer and one miss can finish immediately.
  perform public.redeem_seasonal_event_preview('BDAYEVENT');
  select * into a from public.start_seasonal_trial_attempt('golden_wings_birthday','wishcakeTower');
  update public.seasonal_trial_attempts set started_at=now()-interval '5 seconds' where id=a.attempt_id;
  select * into result from public.complete_seasonal_trial_attempt(a.attempt_id,a.completion_token::text,100,1,2,2000);
  if not result.accepted then raise exception 'summer_contract_birthday_one_life'; end if;
  if private.economy_chest_catalog()->'special_chests'->'sunwake_chest_v1'<>
      '{"coins":300,"gems":12,"egg":"sunwake_egg_v1"}'::jsonb or
     private.economy_chest_catalog()->'special_eggs'->'harvestmoon_egg_v1'->>'lineage'<>'ciderhorn' then
    raise exception 'summer_contract_dormant_catalog'; end if;
end $$;
rollback;
select true as summer_contract_passed;
