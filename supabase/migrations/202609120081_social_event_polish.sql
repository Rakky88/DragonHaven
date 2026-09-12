-- Event invitation lifetimes, scoped Trial highscores, reliable chat and shop pricing.
-- Store the original deadline so redeeming another preview cannot extend an
-- invitation from a previous test. Adventure return times are separate.
alter table public.seasonal_pair_adventures add column invitation_expires_at timestamptz;
update public.seasonal_pair_adventures a set invitation_expires_at = case
  when a.simulated then least(a.created_at + interval '48 hours', coalesce(
    (select p.expires_at from public.seasonal_event_previews p
      where p.user_id=a.creator_id and p.event_id=a.event_id
        and p.activated_at<=a.created_at), a.created_at + interval '48 hours'))
  else (select w.ends_at from public.seasonal_event_window(a.event_id,a.created_at) w)
end;

create function private.set_pair_invitation_deadline()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if new.simulated then
    select least(new.created_at + interval '48 hours',p.expires_at)
      into new.invitation_expires_at from public.seasonal_event_previews p
      where p.user_id=new.creator_id and p.event_id=new.event_id;
    new.invitation_expires_at:=coalesce(new.invitation_expires_at,new.created_at + interval '48 hours');
  else
    select w.ends_at into new.invitation_expires_at
      from public.seasonal_event_window(new.event_id,new.created_at) w;
  end if;
  return new;
end $$;
create trigger pair_invitation_deadline before insert on public.seasonal_pair_adventures
  for each row execute function private.set_pair_invitation_deadline();

create function private.expire_event_invitations()
returns void language plpgsql security definer set search_path='' as $$
begin
  perform pg_advisory_xact_lock(hashtextextended('event-point-partners',0));
  update private.event_point_pairs set status='declined'
    where status='invited' and ends_at<=now();
  delete from private.event_point_pair_members m using private.event_point_pairs p
    where m.pair_id=p.id and p.status='declined';
  update public.seasonal_pair_adventures set status='declined'
    where status in ('invited','accepted') and
      (invitation_expires_at is null or invitation_expires_at<=now());
  delete from public.social_notifications n using public.seasonal_pair_adventures a
    where n.entity_id=a.id and n.kind in ('seasonal_pair_invite','seasonal_pair_accepted')
      and a.status='declined';
end $$;
revoke all on function private.expire_event_invitations(),private.set_pair_invitation_deadline()
  from public,anon,authenticated,service_role;
select private.expire_event_invitations();
select cron.schedule('dragonhaven-event-invitation-expiry','* * * * *',
  $$select private.expire_event_invitations();$$);

-- Clean on reads and actions too: an expired invitation cannot be accepted
-- during the gap before the next maintenance tick.
alter function public.list_my_seasonal_pair_adventures() rename to list_my_seasonal_pair_adventures_v80;
create function public.list_my_seasonal_pair_adventures()
returns table(id uuid,event_id text,occurrence_key text,status text,creator jsonb,partner jsonb,
  is_creator boolean,my_dragon_id text,other_dragon_id text,created_at timestamptz,
  started_at timestamptz,ends_at timestamptz,my_reward_claimed boolean)
language plpgsql security definer set search_path='' as $$
begin
  if auth.uid() is null then raise exception 'online_login_required'; end if;
  perform private.expire_event_invitations();
  return query select * from public.list_my_seasonal_pair_adventures_v80();
end $$;
revoke all on function public.list_my_seasonal_pair_adventures_v80() from public,anon,authenticated,service_role;
revoke all on function public.list_my_seasonal_pair_adventures() from public,anon;
grant execute on function public.list_my_seasonal_pair_adventures() to authenticated;

create or replace function public.respond_seasonal_pair_adventure(p_adventure_id uuid,
  p_accept boolean,p_dragon_id text default null,p_might integer default 0,
  p_arcana integer default 0,p_spirit integer default 0)
returns void language plpgsql security definer set search_path='' as $$
declare a public.seasonal_pair_adventures%rowtype;
begin
  perform private.assert_legacy_inventory_authority();
  perform private.expire_event_invitations();
  select * into a from public.seasonal_pair_adventures where id=p_adventure_id
    and auth.uid() in (creator_id,partner_id) and not canonical_owned for update;
  if not found then raise exception 'seasonal_pair_not_found'; end if;
  if not p_accept then
    if a.status='declined' then return; end if;
    if a.status<>'invited' then raise exception 'seasonal_pair_not_pending'; end if;
    update public.seasonal_pair_adventures set status='declined' where id=a.id;
    delete from public.social_notifications where entity_id=a.id and kind='seasonal_pair_invite';
    return;
  end if;
  if a.partner_id<>auth.uid() or a.status<>'invited' or a.invitation_expires_at<=now() then
    raise exception 'seasonal_pair_not_pending'; end if;
  perform public.respond_seasonal_pair_adventure_v68(p_adventure_id,p_accept,p_dragon_id,p_might,p_arcana,p_spirit);
end $$;

alter function public.event_point_partner(text,text,text,uuid) rename to event_point_partner_v80;
create function public.event_point_partner(p_action text default 'list',p_event_key text default null,
  p_keeper_code text default null,p_pair_id uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
begin
  if auth.uid() is null then raise exception 'online_login_required'; end if;
  perform private.expire_event_invitations();
  return public.event_point_partner_v80(p_action,p_event_key,p_keeper_code,p_pair_id);
end $$;
revoke all on function public.event_point_partner_v80(text,text,text,uuid) from public,anon,authenticated,service_role;
revoke all on function public.event_point_partner(text,text,text,uuid) from public,anon;
grant execute on function public.event_point_partner(text,text,text,uuid) to authenticated;

-- A lost HTTP acknowledgement may be retried with the same client message ID.
-- The receipt is checked before rate limiting and retained across chat cleanup.
create table private.conclave_message_receipts (
  sender_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null,
  conclave_id uuid not null,
  message_id uuid not null,
  request_fingerprint text not null,
  created_at timestamptz not null default now(),
  primary key(sender_id,request_id)
);
revoke all on private.conclave_message_receipts from public,anon,authenticated;
alter function public.send_conclave_message(text,text,jsonb) rename to send_conclave_message_v80;
create function public.send_conclave_message(p_kind text,p_body text,p_payload jsonb default '{}')
returns uuid language plpgsql security definer set search_path='' as $$
declare receipt uuid; cid uuid; result uuid; request_value text;
  previous private.conclave_message_receipts%rowtype;
begin
  if auth.uid() is null then raise exception 'online_login_required'; end if;
  if p_payload->>'client_message_id' is null then
    return public.send_conclave_message_v80(p_kind,p_body,p_payload);
  end if;
  receipt:=(p_payload->>'client_message_id')::uuid;
  select conclave_id into cid from public.conclave_members where user_id=auth.uid();
  if cid is null then raise exception 'not_in_conclave'; end if;
  request_value:=md5(jsonb_build_array(p_kind,btrim(p_body),p_payload-'client_message_id')::text);
  perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text||receipt::text,0));
  select * into previous from private.conclave_message_receipts
    where sender_id=auth.uid() and request_id=receipt;
  if found then
    if previous.conclave_id<>cid or previous.request_fingerprint<>request_value then raise exception 'message_invalid'; end if;
    return previous.message_id;
  end if;
  result:=public.send_conclave_message_v80(p_kind,p_body,p_payload-'client_message_id');
  insert into private.conclave_message_receipts(sender_id,request_id,conclave_id,message_id,request_fingerprint)
    values(auth.uid(),receipt,cid,result,request_value);
  return result;
end $$;
revoke all on function public.send_conclave_message_v80(text,text,jsonb) from public,anon,authenticated,service_role;
revoke all on function public.send_conclave_message(text,text,jsonb) from public,anon;
grant execute on function public.send_conclave_message(text,text,jsonb) to authenticated;
select cron.schedule('dragonhaven-chat-receipt-cleanup','43 3 * * *',
  $$delete from private.conclave_message_receipts where created_at<now()-interval '30 days';$$);

-- Event Trials use the same highscore API and scope filters as regular Trials.
-- Rank solely by each keeper's best raw score; equal scores share a position.
alter function public.get_trial_rankings(text,text,integer) rename to get_trial_rankings_v80;
create function public.get_trial_rankings(p_trial_key text,p_scope text,p_limit integer default 100)
returns table(ranking_position bigint,entry_key text,display_name text,title text,
  portrait_key text,frame_key text,badge_key text,score bigint,is_current_user boolean)
language plpgsql stable security definer set search_path='' as $$
declare event_id_value text; occurrence text; is_preview boolean:=false; event_window record;
begin
  if auth.uid() is null then raise exception 'online_login_required'; end if;
  if p_scope not in ('world','friends','conclave') then raise exception 'trial_rankings_invalid'; end if;
  if p_trial_key in ('cavernFlight','ruinBreaker','runeweaver') then
    return query select * from public.get_trial_rankings_v80(p_trial_key,p_scope,p_limit);
    return;
  end if;
  event_id_value:=case p_trial_key
    when 'witchlightWard' then 'halloween_witchlight'
    when 'hollyfrostGiftforge' then 'christmas_winter_hearth'
    when 'midnightChime' then 'new_year_first_dawn'
    when 'rosevowRelay' then 'valentine_two_heartlights'
    when 'prismaticParade' then 'pride_every_color'
    when 'wishcakeTower' then 'golden_wings_birthday'
    when 'moonlitOrchard' then 'harvestmoon_moonlit_orchard'
    when 'sunwakeSurf' then 'sunwake_summer_sea' end;
  if event_id_value is null then raise exception 'trial_rankings_invalid'; end if;
  if p_scope='conclave' and not exists(select 1 from public.conclave_members where user_id=auth.uid()) then
    raise exception 'not_in_conclave'; end if;
  if exists(select 1 from public.seasonal_event_previews p where p.user_id=auth.uid()
      and p.event_id=event_id_value and p.expires_at>now()) then
    is_preview:=true;
  else
    select * into event_window from public.seasonal_event_window(event_id_value,now());
    if event_window.occurrence_key is not null and now()>=event_window.starts_at
        and now()<event_window.results_end_at then
      occurrence:=event_window.occurrence_key;
    elsif exists(select 1 from public.seasonal_event_previews p where p.user_id=auth.uid()
        and p.event_id=event_id_value and p.expires_at+interval '3 days'>now()) then
      is_preview:=true;
    else return; end if;
  end if;
  if is_preview then occurrence:='preview:'||event_id_value||':'||auth.uid()::text; end if;
  return query
  with candidates as (
    select b.user_id,b.score,p.display_name,p.title,p.portrait_key,p.frame_key,p.badge_key
    from public.seasonal_trial_bests b join public.profiles p on p.user_id=b.user_id
    where b.event_id=event_id_value and b.occurrence_key=occurrence and b.preview=is_preview
      and (not is_preview or b.user_id=auth.uid())
      and (p_scope='world' or b.user_id=auth.uid()
        or (p_scope='friends' and exists(select 1 from public.friendships f where f.status='accepted'
          and ((f.requester_id=auth.uid() and f.addressee_id=b.user_id)
            or (f.addressee_id=auth.uid() and f.requester_id=b.user_id))))
        or (p_scope='conclave' and exists(select 1 from public.conclave_members mine
          join public.conclave_members theirs on mine.conclave_id=theirs.conclave_id
          where mine.user_id=auth.uid() and theirs.user_id=b.user_id)))
      and not exists(select 1 from public.friendships f where f.status='blocked'
        and ((f.requester_id=auth.uid() and f.addressee_id=b.user_id)
          or (f.addressee_id=auth.uid() and f.requester_id=b.user_id)))
  ), ranked as (
    select rank() over(order by c.score desc) pos,c.* from candidates c
  )
  select r.pos,r.user_id::text,r.display_name,r.title,r.portrait_key,r.frame_key,r.badge_key,
    r.score,r.user_id=auth.uid() from ranked r
    where p_scope<>'world' or r.pos<=least(100,greatest(1,coalesce(p_limit,100))) or r.user_id=auth.uid()
    order by r.pos,lower(r.display_name),r.user_id;
end $$;
revoke all on function public.get_trial_rankings_v80(text,text,integer) from public,anon,authenticated,service_role;
revoke all on function public.get_trial_rankings(text,text,integer) from public,anon;
grant execute on function public.get_trial_rankings(text,text,integer) to authenticated;
create or replace function public.seasonal_event_window(
  p_event_id text,
  p_now timestamptz default now()
)
returns table (
  occurrence_key text,
  starts_at timestamptz,
  ends_at timestamptz,
  results_end_at timestamptz
)
language plpgsql
set search_path = ''
stable
as $$
declare
  local_now timestamp := p_now at time zone 'Europe/Amsterdam';
  event_year integer := extract(year from local_now)::integer;
  local_start timestamp;
  local_end timestamp;
begin
  if p_event_id = 'golden_wings_birthday' then
    if event_year < 2026 then return; end if;
    if event_year = 2026 then
      local_start := make_timestamp(2026, 9, 1, 0, 0, 0);
      local_end := make_timestamp(2026, 9, 3, 0, 0, 0);
    else
      local_start := make_timestamp(event_year, 5, 13, 0, 0, 0);
      local_end := make_timestamp(event_year, 5, 14, 0, 0, 0);
    end if;
  elsif p_event_id = 'halloween_witchlight' then
    local_start := make_timestamp(event_year, 10, 25, 0, 0, 0);
    local_end := make_timestamp(event_year, 11, 2, 0, 0, 0);
  elsif p_event_id = 'christmas_winter_hearth' then
    local_start := make_timestamp(event_year, 12, 25, 0, 0, 0);
    local_end := make_timestamp(event_year, 12, 27, 0, 0, 0);
  elsif p_event_id = 'new_year_first_dawn' then
    if event_year < 2027 then return; end if;
    local_start := make_timestamp(event_year, 1, 1, 0, 0, 0);
    local_end := make_timestamp(event_year, 1, 7, 0, 0, 0);
  elsif p_event_id = 'valentine_two_heartlights' then
    local_start := make_timestamp(event_year, 2, 14, 0, 0, 0);
    local_end := make_timestamp(event_year, 2, 15, 0, 0, 0);
  elsif p_event_id = 'sunwake_summer_sea' then
    local_start := make_timestamp(event_year, 7, 20, 0, 0, 0);
    local_end := make_timestamp(event_year, 7, 27, 0, 0, 0);
  elsif p_event_id = 'harvestmoon_moonlit_orchard' then
    local_start := make_timestamp(event_year, 9, 7, 0, 0, 0);
    local_end := make_timestamp(event_year, 9, 14, 0, 0, 0);
  elsif p_event_id = 'pride_every_color' then
    local_start := make_timestamp(event_year, 6, 1, 0, 0, 0);
    local_end := make_timestamp(event_year, 6, 8, 0, 0, 0);
  else
    return;
  end if;

  -- The first configured editions are a hard lower boundary.
  if (p_event_id in ('halloween_witchlight', 'christmas_winter_hearth',
        'new_year_first_dawn') and event_year < 2026)
     or (p_event_id in ('valentine_two_heartlights', 'pride_every_color',
        'sunwake_summer_sea', 'harvestmoon_moonlit_orchard')
        and event_year < 2027) then
    return;
  end if;
  occurrence_key := p_event_id || ':' || event_year::text;
  starts_at := local_start at time zone 'Europe/Amsterdam';
  ends_at := local_end at time zone 'Europe/Amsterdam';
  results_end_at := ends_at + interval '3 days';
  return next;
end
$$;

create or replace function public.purchase_vanity_chest(
  p_request_id uuid,
  p_tier text,
  p_protocol_version integer,
  p_client_build integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_owner_id uuid := auth.uid();
  v_tier text := lower(btrim(coalesce(p_tier, '')));
  v_currency text;
  v_price integer;
  v_item_kind text;
  v_collection_cap integer;
  v_collected integer;
  v_unopened integer;
  v_begin jsonb;
  v_response jsonb;
  v_wallet public.player_wallets%rowtype;
  v_chest_id uuid;
  v_server_revision bigint;
begin
  -- Fail closed before revealing catalog behavior to an unauthenticated,
  -- legacy, disabled, old or protocol-mismatched client.
  perform private.assert_economy_client(p_protocol_version, p_client_build);

  select catalog.currency, catalog.price, catalog.item_kind, catalog.cap
  into v_currency, v_price, v_item_kind, v_collection_cap
  from (values
    ('portrait'::text, 'gems'::text, 100, 'portrait'::text, 100),
    ('title'::text, 'coins'::text, 500, 'title'::text, 500),
    ('music'::text, 'gems'::text, 250, 'music'::text, 80)
  ) as catalog(tier, currency, price, item_kind, cap)
  where catalog.tier = v_tier;
  if not found then
    raise exception 'economy_chest_tier_invalid';
  end if;

  v_begin := private.begin_economy_mutation(
    p_request_id,
    'shop.purchase_vanity_chest',
    p_protocol_version,
    p_client_build,
    jsonb_build_object('tier', v_tier),
    20,
    60
  );
  if (v_begin->>'replayed')::boolean then
    if v_begin->>'status' <> 'succeeded' or v_begin->'response' is null then
      raise exception 'economy_request_state_invalid';
    end if;
    return v_begin->'response';
  end if;

  -- Count active collectibles and unopened matching chests while holding the
  -- owner's authority row lock. This serializes capacity-sensitive purchases
  -- for the same keeper without globally blocking other keepers.
  perform 1
  from public.player_economy_authority
  where user_id = v_owner_id
  for update;
  if not found then
    raise exception 'economy_authority_missing';
  end if;

  select * into v_wallet
  from public.player_wallets
  where user_id = v_owner_id
  for update;
  if not found then
    raise exception 'economy_wallet_missing';
  end if;

  select count(*)::integer into v_collected
  from public.player_item_instances
  where owner_id = v_owner_id
    and item_kind = v_item_kind
    and state <> 'consumed';
  select count(*)::integer into v_unopened
  from public.player_chest_instances
  where owner_id = v_owner_id
    and tier = v_tier
    and state <> 'opened';

  if v_collected + v_unopened >= v_collection_cap then
    v_response := jsonb_build_object(
      'outcome', 'collection_complete',
      'tier', v_tier,
      'collected', v_collected,
      'unopened', v_unopened,
      'collection_cap', v_collection_cap,
      'coins', v_wallet.coins,
      'gems', v_wallet.gems,
      'wallet_revision', v_wallet.revision
    );
    perform private.complete_economy_mutation(
      v_owner_id, p_request_id, v_response
    );
    return v_response;
  end if;

  if (v_currency = 'coins' and v_wallet.coins < v_price)
    or (v_currency = 'gems' and v_wallet.gems < v_price) then
    v_response := jsonb_build_object(
      'outcome', 'insufficient_funds',
      'tier', v_tier,
      'currency', v_currency,
      'price', v_price,
      'coins', v_wallet.coins,
      'gems', v_wallet.gems,
      'wallet_revision', v_wallet.revision
    );
    perform private.complete_economy_mutation(
      v_owner_id, p_request_id, v_response
    );
    return v_response;
  end if;

  update public.player_wallets
  set coins = case
        when v_currency = 'coins' then coins - v_price else coins end,
      gems = case
        when v_currency = 'gems' then gems - v_price else gems end,
      revision = revision + 1,
      updated_at = clock_timestamp()
  where user_id = v_owner_id
  returning * into v_wallet;

  insert into public.player_chest_instances(
    owner_id, tier, state, tradeable, source_type, source_reference
  ) values (
    v_owner_id, v_tier, 'owned', false, 'shop',
    'vanity_chest_shop'
  )
  returning id into v_chest_id;

  perform private.append_economy_ledger_entry(
    v_owner_id,
    p_request_id,
    v_currency,
    v_currency,
    'debit',
    'shop',
    -v_price,
    case when v_currency = 'coins' then v_wallet.coins else v_wallet.gems end,
    'vanity_chest_shop',
    jsonb_build_object('tier', v_tier, 'unit_price', v_price)
  );
  perform private.append_economy_ledger_entry(
    v_owner_id,
    p_request_id,
    'chest',
    v_tier,
    'grant',
    'shop',
    1,
    null,
    'vanity_chest_shop',
    jsonb_build_object('chest_instance_id', v_chest_id)
  );

  update public.player_economy_authority
  set server_revision = server_revision + 1
  where user_id = v_owner_id
  returning server_revision into v_server_revision;

  v_response := jsonb_build_object(
    'outcome', 'purchased',
    'tier', v_tier,
    'currency', v_currency,
    'price', v_price,
    'chest_instance_id', v_chest_id,
    'coins', v_wallet.coins,
    'gems', v_wallet.gems,
    'wallet_revision', v_wallet.revision,
    'server_revision', v_server_revision
  );
  perform private.complete_economy_mutation(
    v_owner_id, p_request_id, v_response
  );
  return v_response;
end;
$$;


-- Dart keeps launch/year in its stable event key; the leaderboard occurrence
-- stores the event and year. Normalize only for the verified schedule check.
create or replace function private.canonical_seasonal_state_changed()
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
        if window_row.occurrence_key is null or regexp_replace(active->>'specialEventKey', ':(launch|year):', ':')<>window_row.occurrence_key or
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
