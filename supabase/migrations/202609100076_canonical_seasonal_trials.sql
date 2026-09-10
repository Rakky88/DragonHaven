-- Publish only committed, replay-verified Trial results. The original event,
-- closing time and Conclave remain pinned through checkpoints/device resume.
-- Detached copies stay isolated unless staging explicitly enables projection.
alter table public.seasonal_trial_attempts
  add column canonical_owned boolean not null default false,
  add column canonical_offer_id text,
  add column canonical_event_key text,
  add column ranking_ends_at timestamptz,
  add column ranking_eligible boolean not null default false,
  add constraint canonical_seasonal_binding check (not canonical_owned or
    (canonical_offer_id is not null and canonical_event_key is not null and ranking_ends_at is not null));
create unique index canonical_seasonal_offer_once
  on public.seasonal_trial_attempts(user_id,canonical_offer_id) where canonical_owned;

create function private.canonical_seasonal_state_changed()
returns trigger language plpgsql security definer set search_path='' as $$
declare previous jsonb; active jsonb; finished jsonb; item record; event_name text;
  bound public.seasonal_trial_attempts%rowtype; window_row record;
  start_time timestamptz; closing_time timestamptz; preview boolean; occurrence text;
  final_score bigint; correct bigint; total bigint; duration bigint; accuracy integer;
begin
  if not new.is_prepared or not (new.authority_mode='server' or
      (select shadow_projection_enabled from private.game_engine_runtime where singleton)) then return new; end if;
  perform private.assert_game_service();
  perform pg_advisory_xact_lock(hashtextextended(new.owner_id::text,0));

  -- These public tables are read models, including for partner adventures.
  -- Optional keys keep older minimal migration fixtures compatible; prepared
  -- production saves always carry both maps, including their empty values.
  if new.state ? 'seasonalEventPreviewExpiresAt' then
    delete from public.seasonal_event_previews p where p.user_id=new.owner_id and
      not (coalesce(new.state->'seasonalEventPreviewExpiresAt','{}') ? p.event_id);
    for item in select key,value from jsonb_each_text(new.state->'seasonalEventPreviewExpiresAt') loop
      insert into public.seasonal_event_previews(user_id,event_id,activated_at,expires_at)
        values(new.owner_id,item.key,item.value::timestamptz-interval '48 hours',item.value::timestamptz)
        on conflict(user_id,event_id) do update set
          activated_at=case when public.seasonal_event_previews.expires_at=excluded.expires_at
            then public.seasonal_event_previews.activated_at else excluded.activated_at end,
          expires_at=excluded.expires_at;
    end loop;
  end if;
  if new.state ? 'seasonalEventDismissedUntil' then
    delete from public.seasonal_event_dismissals d where d.user_id=new.owner_id and
      not (coalesce(new.state->'seasonalEventDismissedUntil','{}') ? d.event_id);
    for item in select key,value from jsonb_each_text(new.state->'seasonalEventDismissedUntil') loop
      insert into public.seasonal_event_dismissals(user_id,event_id,expires_at)
        values(new.owner_id,item.key,item.value::timestamptz)
        on conflict(user_id,event_id) do update set expires_at=excluded.expires_at;
    end loop;
  end if;

  active:=new.state->'_activeGameAttempt';
  if tg_op='UPDATE' then previous:=old.state->'_activeGameAttempt'; end if;
  if active->>'type'='trial' and active->>'specialEventKey' is not null then
    select * into bound from public.seasonal_trial_attempts
      where user_id=new.owner_id and canonical_owned and canonical_offer_id=active->>'offerId' for update;
    if found then
      if bound.completed_at is not null or bound.trial_key<>active->>'gameId' or
          bound.canonical_event_key<>active->>'specialEventKey' or
          bound.seed<>(active->>'seed')::integer or bound.started_at<>(active->>'startedAt')::timestamptz then
        raise exception 'game_seasonal_binding_changed'; end if;
      update public.seasonal_trial_attempts set expires_at=(active->>'expiresAt')::timestamptz where id=bound.id;
    else
      event_name:=case active->>'gameId'
        when 'sunwakeSurf' then 'sunwake_summer_sea'
        when 'moonlitOrchard' then 'harvestmoon_moonlit_orchard'
        when 'wishcakeTower' then 'golden_wings_birthday'
        when 'witchlightWard' then 'halloween_witchlight'
        when 'hollyfrostGiftforge' then 'christmas_winter_hearth'
        when 'midnightChime' then 'new_year_first_dawn'
        when 'rosevowRelay' then 'valentine_two_heartlights'
        when 'prismaticParade' then 'pride_every_color' end;
      if event_name is null then raise exception 'game_seasonal_binding_invalid'; end if;
      start_time:=(active->>'startedAt')::timestamptz;
      preview:=(active->>'specialEventKey') like event_name||':preview:%';
      if preview then
        closing_time:=(new.state->'seasonalEventPreviewExpiresAt'->>event_name)::timestamptz;
        if closing_time is null or start_time>=closing_time or active->>'specialEventKey'<>
            event_name||':preview:'||floor(extract(epoch from closing_time)*1000)::bigint::text then
          raise exception 'game_seasonal_binding_invalid'; end if;
        occurrence:='preview:'||event_name||':'||new.owner_id::text;
      else
        select * into window_row from public.seasonal_event_window(event_name,start_time);
        if window_row.occurrence_key is null or active->>'specialEventKey'<>window_row.occurrence_key or
            start_time<window_row.starts_at or start_time>=window_row.ends_at or
            coalesce((new.state->'seasonalEventDismissedUntil'->>event_name)::timestamptz,'-infinity')>start_time or
            exists(select 1 from jsonb_each_text(coalesce(new.state->'seasonalEventPreviewExpiresAt','{}')) p
              where p.value::timestamptz>start_time) then
          raise exception 'game_seasonal_binding_invalid'; end if;
        closing_time:=window_row.ends_at; occurrence:=window_row.occurrence_key;
      end if;
      insert into public.seasonal_trial_attempts(user_id,event_id,trial_key,occurrence_key,seed,simulated,
          started_at,expires_at,conclave_id,canonical_owned,canonical_offer_id,canonical_event_key,ranking_ends_at)
        values(new.owner_id,event_name,active->>'gameId',occurrence,(active->>'seed')::integer,preview,
          start_time,(active->>'expiresAt')::timestamptz,
          (select conclave_id from public.conclave_members where user_id=new.owner_id),
          true,active->>'offerId',active->>'specialEventKey',closing_time);
    end if;
  end if;

  -- A rotating device attempt ID never changes this logical offer binding.
  if previous->>'type'='trial' and previous->>'specialEventKey' is not null and
      (active is null or active='null'::jsonb) then
    finished:=new.state->'_lastGameResult';
    if finished->>'attemptId' is distinct from previous->>'id' or
        finished->>'type' is distinct from 'trial' or
        finished->>'gameId' is distinct from previous->>'gameId' then
      raise exception 'game_seasonal_completion_invalid'; end if;
    select * into bound from public.seasonal_trial_attempts where user_id=new.owner_id and canonical_owned
      and canonical_offer_id=previous->>'offerId' for update;
    if not found or bound.completed_at is not null then raise exception 'game_seasonal_completion_invalid'; end if;
    finished:=finished->'result';
    if finished->>'accepted' is distinct from 'true' then raise exception 'game_seasonal_completion_invalid'; end if;
    if finished->>'cancelled'='true' then
      update public.seasonal_trial_attempts set completed_at=new.updated_at where id=bound.id;
      return new;
    end if;
    if finished->>'specialEventKey' is distinct from bound.canonical_event_key or
        finished->>'kind' is distinct from bound.trial_key then raise exception 'game_seasonal_completion_invalid'; end if;
    final_score:=(finished->>'score')::bigint; correct:=(finished->>'correctActions')::bigint;
    total:=(finished->>'totalActions')::bigint; duration:=(finished->>'durationMs')::bigint;
    if final_score is null or correct is null or total is null or duration is null or
        final_score<0 or correct<0 or total<correct or duration<0 then
      raise exception 'game_seasonal_completion_invalid'; end if;
    accuracy:=case when total=0 then 0 else round(correct::numeric*1000/total)::integer end;
    update public.seasonal_trial_attempts set completed_at=new.updated_at,score=final_score,
      correct_actions=correct,total_actions=total,duration_ms=duration,
      ranking_eligible=new.updated_at<bound.ranking_ends_at where id=bound.id;
    -- Personal rewards still finish after closing, but a closed podium cannot
    -- be rewritten by a paused run. No contribution is added after closing.
    if new.updated_at>=bound.ranking_ends_at then return new; end if;
    insert into public.seasonal_trial_bests(event_id,occurrence_key,user_id,score,accuracy_permille,duration_ms,achieved_at,preview)
      values(bound.event_id,bound.occurrence_key,new.owner_id,final_score,accuracy,duration,new.updated_at,bound.simulated)
      on conflict(event_id,occurrence_key,user_id) do update set score=excluded.score,
        accuracy_permille=excluded.accuracy_permille,duration_ms=excluded.duration_ms,
        achieved_at=excluded.achieved_at,preview=excluded.preview
      where (excluded.score,excluded.accuracy_permille,-excluded.duration_ms)>
        (public.seasonal_trial_bests.score,public.seasonal_trial_bests.accuracy_permille,-public.seasonal_trial_bests.duration_ms);
    if not bound.simulated and bound.conclave_id is not null and correct>0 and
        bound.event_id in ('sunwake_summer_sea','harvestmoon_moonlit_orchard') then
      insert into public.seasonal_conclave_projects(conclave_id,event_id,occurrence_key,completed_trials)
        values(bound.conclave_id,bound.event_id,bound.occurrence_key,1)
        on conflict(conclave_id,event_id,occurrence_key) do update
          set completed_trials=public.seasonal_conclave_projects.completed_trials+1,updated_at=new.updated_at;
    end if;
  end if;
  return new;
end $$;
revoke all on function private.canonical_seasonal_state_changed() from public,anon,authenticated,service_role;
create trigger canonical_seasonal_state_changed
  after insert or update of state,revision,is_prepared,authority_mode on private.canonical_game_states
  for each row execute function private.canonical_seasonal_state_changed();

-- A legacy RPC may not rewrite either server-owned activation or a verified
-- score, even if it retained an old completion token. Account deletion works.
create function private.guard_canonical_seasonal_write()
returns trigger language plpgsql security definer set search_path='' as $$
declare row_value jsonb; previous_value jsonb; keeper uuid;
begin
  if coalesce(auth.role(),'')='service_role' then if tg_op='DELETE' then return old; else return new; end if; end if;
  if tg_op<>'INSERT' then previous_value:=to_jsonb(old); end if;
  if tg_op='DELETE' then row_value:=previous_value; else row_value:=to_jsonb(new); end if;
  keeper:=(row_value->>'user_id')::uuid;
  if tg_op='DELETE' and not exists(select 1 from auth.users where id=keeper) then return old; end if;
  if tg_op='UPDATE' and tg_table_name='seasonal_trial_attempts' and
      previous_value->>'conclave_id' is not null and row_value->>'conclave_id' is null and
      previous_value-'conclave_id'=row_value-'conclave_id' and
      not exists(select 1 from public.conclaves where id=(previous_value->>'conclave_id')::uuid) then return new; end if;
  perform pg_advisory_xact_lock(hashtextextended(keeper::text,0));
  if coalesce((row_value->>'canonical_owned')::boolean,false) or coalesce((previous_value->>'canonical_owned')::boolean,false) or
      exists(select 1 from public.player_economy_authority where user_id=keeper and authority_mode='server') or
      exists(select 1 from private.canonical_game_states g cross join private.game_engine_runtime r
        where g.owner_id=keeper and g.is_prepared and r.singleton and r.shadow_projection_enabled) then
    raise exception 'economy_server_inventory_required'; end if;
  if tg_op='DELETE' then return old; else return new; end if;
end $$;
revoke all on function private.guard_canonical_seasonal_write() from public,anon,authenticated,service_role;
create trigger canonical_seasonal_attempt_write before insert or update or delete on public.seasonal_trial_attempts
  for each row execute function private.guard_canonical_seasonal_write();
create trigger canonical_seasonal_best_write before insert or update or delete on public.seasonal_trial_bests
  for each row execute function private.guard_canonical_seasonal_write();
create trigger canonical_seasonal_preview_write before insert or update or delete on public.seasonal_event_previews
  for each row execute function private.guard_canonical_seasonal_write();
create trigger canonical_seasonal_dismissal_write before insert or update or delete on public.seasonal_event_dismissals
  for each row execute function private.guard_canonical_seasonal_write();
