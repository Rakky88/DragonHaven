-- Canonical exchanges reserve one item per keeper and swap both private
-- inventories atomically. Public social rows contain no private egg genetics.
alter table public.trades add column canonical_owned boolean not null default false;
create table private.canonical_trade_items (
  trade_id uuid not null references public.trades(id) on delete cascade,
  owner_id uuid not null references public.profiles(user_id) on delete cascade,
  item jsonb not null check(jsonb_typeof(item)='object'),
  primary key(trade_id,owner_id)
);
create table private.canonical_trade_settlements (
  trade_id uuid not null references public.trades(id) on delete cascade,
  owner_id uuid not null references public.profiles(user_id) on delete cascade,
  before_revision bigint not null,
  after_revision bigint not null check(after_revision=before_revision+1),
  state_sha256 text not null check(state_sha256 ~ '^[0-9a-f]{64}$'),
  primary key(trade_id,owner_id)
);
revoke all on private.canonical_trade_items,private.canonical_trade_settlements from public,anon,authenticated,service_role;
alter table private.canonical_game_intents
  add column trade_reservations jsonb,
  add column trade_reservations_captured boolean not null default false,
  add column trade_counterparty jsonb;

create function private.lock_canonical_trade_keepers(p_owner uuid,p_action text,p_payload jsonb)
returns void language plpgsql security definer set search_path='' as $$
declare other_keeper uuid; keeper uuid;
begin
  perform private.assert_game_service();
  if p_owner is null then raise exception 'game_request_invalid'; end if;
  if p_action='offer_trade' then
    select user_id into other_keeper from public.profiles where keeper_code=upper(trim(p_payload->>'keeperCode'));
  elsif (p_payload->>'tradeId') ~ '^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$' then
    select case when initiator_id=p_owner then recipient_id else initiator_id end into other_keeper
      from public.trades where id=(p_payload->>'tradeId')::uuid and p_owner in (initiator_id,recipient_id);
  end if;
  for keeper in select distinct x from unnest(array[p_owner,other_keeper]) x where x is not null order by x loop
    perform pg_advisory_xact_lock(hashtextextended(keeper::text,0));
  end loop;
end $$;

create function private.canonical_trade_reservations(p_owner uuid,p_at timestamptz)
returns jsonb language plpgsql security definer set search_path='' as $$
declare items jsonb;
begin
  perform private.assert_game_service();
  if not private.canonical_group_keeper_ready(p_owner) then return null; end if;
  if exists(select 1 from public.trades where not canonical_owned and p_owner in(initiator_id,recipient_id)
      and status in('awaiting_recipient','awaiting_initiator') and expires_at>p_at) then
    raise exception 'game_state_reconciliation_required'; end if;
  select coalesce(jsonb_agg(jsonb_build_object('kind',i.item->>'kind','key',i.item->>'key','variant',i.item->'variant')
      order by t.id),'[]'::jsonb) into items from public.trades t join private.canonical_trade_items i on i.trade_id=t.id
      where i.owner_id=p_owner and t.canonical_owned and t.status in('awaiting_recipient','awaiting_initiator') and t.expires_at>p_at;
  if jsonb_array_length(items)>1 then raise exception 'game_state_reconciliation_required'; end if;
  return jsonb_build_object('version',1,'ownerId',p_owner,'items',items);
end $$;

create function private.canonical_trade_asset(p_owner uuid,p_kind text,p_key text,p_variant integer)
returns jsonb language plpgsql security definer set search_path='' as $$
declare saved jsonb; data_value jsonb:='{}'; knowledge jsonb; own_knowledge jsonb; tag_source jsonb;
  quantity bigint;
begin
  perform private.assert_game_service();
  select state into saved from private.canonical_game_states where owner_id=p_owner and is_prepared;
  if not found or p_key is null or length(p_key) not between 1 and 100 or p_variant is null then
    raise exception 'game_action_unavailable'; end if;
  if p_kind='egg' then
    select e into data_value from jsonb_array_elements(saved->'eggStash') e where e->>'id'=p_key;
    if not found or p_variant<>0 or data_value->>'sex' is null or data_value->>'sex' not in('male','female') then raise exception 'game_action_unavailable'; end if;
    knowledge:=coalesce(data_value->'altarKnowledge','{}');
    own_knowledge:=coalesce(saved->'eggAltar'->'eggs'->p_key,'{}');
    tag_source:=case when coalesce((knowledge->>'tagRevision')::bigint,0)>coalesce((own_knowledge->>'tagRevision')::bigint,0)
      then knowledge when coalesce((knowledge->>'tagRevision')::bigint,0)<coalesce((own_knowledge->>'tagRevision')::bigint,0)
      then own_knowledge else jsonb_build_object('tagged',coalesce((knowledge->>'tagged')::boolean,false) or
          coalesce((own_knowledge->>'tagged')::boolean,false),'tagRevision',coalesce((knowledge->>'tagRevision')::bigint,0)) end;
    knowledge:=knowledge||jsonb_build_object('tagged',coalesce((tag_source->>'tagged')::boolean,false),
      'tagRevision',coalesce((tag_source->>'tagRevision')::bigint,0),
      'moral',coalesce((knowledge->>'moral')::boolean,false) or coalesce((own_knowledge->>'moral')::boolean,false)
          or coalesce((data_value->>'moralAxisKnown')::boolean,false) or data_value->>'lineageId'='sinisterra',
      'order',coalesce((knowledge->>'order')::boolean,false) or coalesce((own_knowledge->>'order')::boolean,false),
      'rarity',coalesce((knowledge->>'rarity')::boolean,false) or coalesce((own_knowledge->>'rarity')::boolean,false)
          or coalesce(saved->'eggRarityRevealedIds','[]') ? p_key,
      'lineage',coalesce((knowledge->>'lineage')::boolean,false) or coalesce((own_knowledge->>'lineage')::boolean,false));
    data_value:=jsonb_set(data_value,'{altarKnowledge}',knowledge);
  elsif p_kind='chest' then
    if p_variant<>0 or p_key not in('wooden','silver','gold','dragon','mythical','sinister') or
        coalesce((saved->'chestInventory'->>p_key)::bigint,0)<1 then raise exception 'game_action_unavailable'; end if;
  elsif p_kind='relic' then
    quantity:=coalesce((saved->'relicInventory'->>p_key)::bigint,0)-coalesce((saved->'untradeableRelicInventory'->>p_key)::bigint,0);
    if p_key not in('moralPrism','orderCompass','soulMirror','astralLens','chronoshard','wayfinderSigil') or quantity<1 then raise exception 'game_action_unavailable'; end if;
    if p_key='chronoshard' then
      if p_variant not between 10 and 90 or not coalesce(saved->'chronoshardReductions','[]') @> jsonb_build_array(p_variant) then
        raise exception 'game_action_unavailable'; end if;
      data_value:=jsonb_build_object('reductionPercent',p_variant);
    elsif p_variant<>0 then raise exception 'game_action_unavailable'; end if;
  else raise exception 'game_action_unavailable'; end if;
  return jsonb_build_object('kind',p_kind,'key',p_key,'variant',p_variant,'data',data_value);
exception when invalid_text_representation or numeric_value_out_of_range then raise exception 'game_action_unavailable';
end $$;

create function private.canonical_trade_context(p_owner uuid,p_action text,p_payload jsonb,p_at timestamptz,p_id uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare trade_row public.trades%rowtype; first_owner uuid; second_owner uuid; other_owner uuid;
  source_id uuid; before_value text; after_value text; sent jsonb; received jsonb; item jsonb; facts jsonb;
begin
  perform private.assert_game_service();
  perform private.lock_canonical_social_sources(p_owner,null);
  if not private.canonical_group_keeper_ready(p_owner) then raise exception 'game_action_unavailable'; end if;
  if p_action='offer_trade' then
    first_owner:=p_owner;
    select user_id into second_owner from public.profiles where keeper_code=upper(trim(p_payload->>'keeperCode'));
    source_id:=coalesce(p_id,gen_random_uuid());before_value:='new';after_value:='awaiting_recipient';
  else
    source_id:=(p_payload->>'tradeId')::uuid;
    select * into trade_row from public.trades where id=source_id and canonical_owned and p_owner in(initiator_id,recipient_id) for update;
    if not found or trade_row.expires_at<=p_at or trade_row.status not in('awaiting_recipient','awaiting_initiator') then
      raise exception 'game_action_unavailable'; end if;
    first_owner:=trade_row.initiator_id;second_owner:=trade_row.recipient_id;before_value:=trade_row.status;
    after_value:=case p_action when 'reply_trade' then 'awaiting_initiator' when 'confirm_trade' then 'completed'
      when 'cancel_trade' then 'cancelled' when 'reject_trade' then 'rejected' end;
    if after_value is null or (p_action='reply_trade' and(p_owner<>second_owner or before_value<>'awaiting_recipient')) or
        (p_action='confirm_trade' and(p_owner<>first_owner or before_value<>'awaiting_initiator')) or
        (p_action='reject_trade' and p_owner<>second_owner) then raise exception 'game_action_unavailable'; end if;
  end if;
  other_owner:=case when p_owner=first_owner then second_owner else first_owner end;
  if other_owner is null or other_owner=p_owner or not private.canonical_group_keeper_ready(other_owner) or
      (select authority_mode from private.canonical_game_states where owner_id=p_owner) is distinct from
      (select authority_mode from private.canonical_game_states where owner_id=other_owner) then raise exception 'game_action_unavailable'; end if;
  if p_action in('offer_trade','reply_trade','confirm_trade') then
    perform 1 from public.friendships where status='accepted' and
      ((requester_id=first_owner and addressee_id=second_owner) or(requester_id=second_owner and addressee_id=first_owner)) for share;
    if not found or private.completed_trades_today(first_owner)>=3 or private.completed_trades_today(second_owner)>=3 then
      raise exception 'game_action_unavailable'; end if;
  end if;
  if p_action='offer_trade' and exists(select 1 from public.trades where status in('awaiting_recipient','awaiting_initiator')
      and expires_at>p_at and(first_owner in(initiator_id,recipient_id) or second_owner in(initiator_id,recipient_id))) then
    raise exception 'game_action_unavailable'; end if;
  if p_action in('offer_trade','reply_trade') then
    if jsonb_typeof(p_payload->'variant') is distinct from 'number' or (p_payload->>'variant') !~ '^[0-9]{1,2}$' then
      raise exception 'game_action_unavailable'; end if;
    sent:=private.canonical_trade_asset(p_owner,p_payload->>'kind',p_payload->>'key',(p_payload->>'variant')::integer);
  else
    select i.item into item from private.canonical_trade_items i where i.trade_id=source_id and i.owner_id=p_owner;
    if found then sent:=private.canonical_trade_asset(p_owner,item->>'kind',item->>'key',(item->>'variant')::integer); end if;
  end if;
  if p_action<>'offer_trade' then
    select i.item into item from private.canonical_trade_items i where i.trade_id=source_id and i.owner_id=other_owner;
    if found then received:=private.canonical_trade_asset(other_owner,item->>'kind',item->>'key',(item->>'variant')::integer); end if;
  end if;
  if p_action='confirm_trade' then
    if sent is null or received is null or exists(select 1 from private.canonical_game_intents where owner_id=other_owner and status='processing')
        or exists(select 1 from private.canonical_game_states where owner_id=other_owner and state->'_activeGameAttempt'<>'null'::jsonb) then
      raise exception 'game_action_unavailable'; end if;
  end if;
  facts:=jsonb_build_object('initiatorId',first_owner,'recipientId',second_owner,'otherOwnerId',other_owner,
    'beforeStatus',before_value,'afterStatus',after_value,'sent',sent,'received',received);
  return jsonb_build_object('version',1,'ownerId',p_owner,'action',p_action,'sourceId',source_id,'facts',facts,
    'fingerprint',private.game_json_sha256(jsonb_build_object('ownerId',p_owner,'sourceId',source_id,'action',p_action,'facts',facts)));
exception when invalid_text_representation or numeric_value_out_of_range then raise exception 'game_action_unavailable';
end $$;

-- Validate a one-for-one asset delta in SQL as well as in the shared rules.
-- The only additional changes allowed are the existing activity/reveal queues,
-- settlement deduplication and release of the reservation for this exchange.
create function private.assert_canonical_trade_delta(p_before jsonb,p_after jsonb,p_sent jsonb,p_received jsonb,p_trade uuid)
returns void language plpgsql security definer set search_path='' as $$
declare eggs jsonb:=coalesce(p_before->'eggStash','[]'); chests jsonb:=coalesce(p_before->'chestInventory','{}');
  known_rarities jsonb:=coalesce(p_before->'eggRarityRevealedIds','[]');
  relics jsonb:=coalesce(p_before->'relicInventory','{}'); shards jsonb:=coalesce(p_before->'chronoshardReductions','[]');
  item jsonb; direction integer; key_value text; count_value bigint; remove_index bigint;
  mutable text[]:=array['eggStash','chestInventory','relicInventory','chronoshardReductions','activities','pendingPresentations',
    'appliedOnlineTradeIds','eggRarityRevealedIds','reservedOnlineTradeEggIds','reservedOnlineTradeChests','reservedOnlineTradeRelics'];
begin
  perform private.assert_game_service();
  perform private.validate_canonical_game_state(p_after);
  if p_before-mutable is distinct from p_after-mutable then raise exception 'game_social_state_changed'; end if;
  for direction in select x from unnest(array[-1,1]) x loop
    item:=case when direction=-1 then p_sent else p_received end; key_value:=item->>'key';
    if item->>'kind'='egg' then
      if direction=-1 then
        if not exists(select 1 from jsonb_array_elements(eggs) e where e->>'id'=key_value) then raise exception 'game_social_state_changed'; end if;
        select coalesce(jsonb_agg(e order by n),'[]') into eggs from jsonb_array_elements(eggs) with ordinality x(e,n) where e->>'id'<>key_value;
        select coalesce(jsonb_agg(e order by n),'[]') into known_rarities from jsonb_array_elements(known_rarities) with ordinality x(e,n) where e<>to_jsonb(key_value);
      else
        if exists(select 1 from jsonb_array_elements(eggs||jsonb_build_array(p_before->'pet')||coalesce(p_before->'sanctuaryDragons','[]')||
            coalesce(p_before->'releasedDragons','[]')||jsonb_build_array(p_before->'incubatingEgg')) e where e->>'id'=key_value) or
            coalesce(p_before->'eggAltar'->'returnedIds','[]') ? key_value then raise exception 'game_social_state_changed'; end if;
        eggs:=eggs||jsonb_build_array(item->'data');
        if (item->'data'->'altarKnowledge'->>'rarity')::boolean and not known_rarities ? key_value then
          known_rarities:=known_rarities||jsonb_build_array(key_value); end if;
      end if;
    elsif item->>'kind'='chest' then
      count_value:=coalesce((chests->>key_value)::bigint,0)+direction;
      if count_value<0 then raise exception 'game_social_state_changed'; end if;
      chests:=jsonb_set(chests,array[key_value],to_jsonb(count_value));
    elsif item->>'kind'='relic' then
      count_value:=coalesce((relics->>key_value)::bigint,0)+direction;
      if count_value<0 then raise exception 'game_social_state_changed'; end if;
      relics:=jsonb_set(relics,array[key_value],to_jsonb(count_value));
      if key_value='chronoshard' then
        if direction=-1 then
          select min(n)-1 into remove_index from jsonb_array_elements(shards) with ordinality x(e,n) where e=item->'variant';
          if remove_index is null then raise exception 'game_social_state_changed'; end if;
          shards:=shards-remove_index::integer;
        else shards:=shards||jsonb_build_array(item->'variant'); end if;
      end if;
    else raise exception 'game_social_state_changed'; end if;
  end loop;
  if coalesce(p_after->'eggRarityRevealedIds','[]') is distinct from known_rarities or
      p_after->'eggStash' is distinct from eggs or p_after->'chestInventory' is distinct from chests or
      p_after->'relicInventory' is distinct from relics or p_after->'chronoshardReductions' is distinct from shards or
      not coalesce(p_after->'appliedOnlineTradeIds','[]') ? p_trade::text or
      coalesce(p_before->'appliedOnlineTradeIds','[]') ? p_trade::text or
      coalesce(p_after->'reservedOnlineTradeEggIds','[]')<>'[]'::jsonb or
      coalesce(p_after->'reservedOnlineTradeChests','{}')<>'{}'::jsonb or
      coalesce(p_after->'reservedOnlineTradeRelics','{}')<>'{}'::jsonb then raise exception 'game_social_state_changed'; end if;
end $$;

-- The internal compatibility entry captures the same reservation view. It
-- remains revoked from service_role; only the revisioned entry is callable.
alter function public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text) rename to begin_canonical_game_command_v73;
create function public.begin_canonical_game_command(p_owner_id uuid,p_request_id uuid,p_action text,p_payload jsonb,
  p_client_build integer,p_ruleset_sha256 text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare leased jsonb; bindings jsonb; captured boolean;
begin
  perform private.assert_game_service();
  leased:=public.begin_canonical_game_command_v73(p_owner_id,p_request_id,p_action,p_payload,p_client_build,p_ruleset_sha256);
  if leased->>'status'<>'processing' then return leased; end if;
  select trade_reservations,trade_reservations_captured into bindings,captured from private.canonical_game_intents
    where owner_id=p_owner_id and request_id=p_request_id;
  if not captured then
    bindings:=private.canonical_trade_reservations(p_owner_id,clock_timestamp());
    update private.canonical_game_intents set trade_reservations=bindings,trade_reservations_captured=true
      where owner_id=p_owner_id and request_id=p_request_id;
  end if;
  return leased||jsonb_build_object('trade_reservations',bindings);
end $$;
revoke all on function public.begin_canonical_game_command_v73(uuid,uuid,text,jsonb,integer,text),
  public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text) from public,anon,authenticated,service_role;

alter function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint) rename to begin_revisioned_game_command_v73;
create function public.begin_revisioned_game_command(p_owner_id uuid,p_request_id uuid,p_action text,p_payload jsonb,
  p_client_build integer,p_ruleset_sha256 text,p_expected_revision bigint)
returns jsonb language plpgsql security definer set search_path='' as $$
declare leased jsonb; context_value jsonb; bindings jsonb; captured boolean; other_value jsonb; other_owner uuid;
  other_game private.canonical_game_states%rowtype; other_context jsonb; other_facts jsonb;
begin
  perform private.assert_game_service();
  if p_action in('offer_trade','reply_trade','confirm_trade','cancel_trade','reject_trade') then
    perform private.lock_canonical_trade_keepers(p_owner_id,p_action,p_payload); end if;
  leased:=public.begin_revisioned_game_command_v73(p_owner_id,p_request_id,p_action,p_payload,p_client_build,p_ruleset_sha256,p_expected_revision);
  if leased->>'status'<>'processing' then return leased; end if;
  select trade_reservations,trade_reservations_captured,social_context,trade_counterparty into bindings,captured,context_value,other_value
    from private.canonical_game_intents where owner_id=p_owner_id and request_id=p_request_id;
  if not captured then
    bindings:=private.canonical_trade_reservations(p_owner_id,clock_timestamp());
    update private.canonical_game_intents set trade_reservations=bindings,trade_reservations_captured=true
      where owner_id=p_owner_id and request_id=p_request_id;
  end if;
  if p_action in('offer_trade','reply_trade','confirm_trade','cancel_trade','reject_trade') and context_value is null then
    begin
      context_value:=private.canonical_trade_context(p_owner_id,p_action,p_payload,(leased->>'now')::timestamptz);
      if p_action='confirm_trade' then
        other_owner:=(context_value->'facts'->>'otherOwnerId')::uuid;
        select * into strict other_game from private.canonical_game_states where owner_id=other_owner for update;
        other_facts:=context_value->'facts'||jsonb_build_object('otherOwnerId',p_owner_id,
          'sent',context_value->'facts'->'received','received',context_value->'facts'->'sent');
        other_context:=jsonb_build_object('version',1,'ownerId',other_owner,'action',p_action,'sourceId',context_value->>'sourceId',
          'facts',other_facts,'fingerprint',private.game_json_sha256(jsonb_build_object('ownerId',other_owner,
            'sourceId',context_value->>'sourceId','action',p_action,'facts',other_facts)));
        other_value:=jsonb_build_object('owner_id',other_owner,'base_revision',other_game.revision,'state_sha256',other_game.state_sha256,
          'authority_mode',other_game.authority_mode,'state',other_game.state,
          'secret_seed',private.game_json_sha256(jsonb_build_array(leased->>'secret_seed',other_owner)),
          'social_context',other_context,'social_reservations',private.canonical_social_reservations(other_owner,clock_timestamp(),true),
          'trade_reservations',private.canonical_trade_reservations(other_owner,clock_timestamp()));
      end if;
    exception when raise_exception then
      if sqlerrm<>'game_action_unavailable' then raise; end if;
      if not public.fail_canonical_game_command(p_owner_id,p_request_id,(leased->>'lease_token')::uuid,'game_action_unavailable') then
        raise exception 'game_lease_lost'; end if;
      return jsonb_build_object('status','failed','failure_code','game_action_unavailable','response',null,'replayed',false);
    end;
    update private.canonical_game_intents set social_context=context_value,trade_counterparty=other_value
      where owner_id=p_owner_id and request_id=p_request_id;
  end if;
  return leased||jsonb_build_object('social_context',context_value,'trade_reservations',bindings,'trade_counterparty',other_value);
end $$;

create function private.commit_canonical_trade_lifecycle(p_owner uuid,p_action text,p_context jsonb,p_result jsonb,p_at timestamptz)
returns void language plpgsql security definer set search_path='' as $$
declare tid uuid:=(p_context->>'sourceId')::uuid; facts jsonb:=p_context->'facts'; sent jsonb:=facts->'sent';
  other_owner uuid:=(facts->>'otherOwnerId')::uuid; side_value text;
begin
  perform private.assert_game_service();
  if p_result is distinct from jsonb_build_object('tradeId',tid,'status',facts->>'afterStatus') then
    raise exception 'game_social_state_changed'; end if;
  side_value:=case when p_owner=(facts->>'initiatorId')::uuid then 'initiator' else 'recipient' end;
  if p_action='offer_trade' then
    insert into public.trades(id,initiator_id,recipient_id,canonical_owned,initiator_item,created_at,expires_at)
      values(tid,p_owner,other_owner,true,sent-'data',p_at,p_at+interval '10 minutes');
  elsif p_action='reply_trade' then
    update public.trades set status='awaiting_initiator',recipient_item=sent-'data' where id=tid;
  else
    update public.trades set status=facts->>'afterStatus',completed_at=case when p_action='confirm_trade' then p_at end,
      initiator_acknowledged_at=case when p_action='confirm_trade' then p_at end,
      recipient_acknowledged_at=case when p_action='confirm_trade' then p_at end where id=tid;
    delete from public.trade_reservations where trade_id=tid;
  end if;
  if p_action in('offer_trade','reply_trade') then
    insert into private.canonical_trade_items(trade_id,owner_id,item) values(tid,p_owner,sent);
    insert into public.trade_reservations(trade_id,side,owner_id,item_type,item_key) values(tid,side_value,p_owner,
      sent->>'kind',case when sent->>'key'='chronoshard' and sent->>'kind'='relic' then 'chronoshard:'||(sent->>'variant') else sent->>'key' end);
  elsif p_action='confirm_trade' then
    update private.canonical_trade_items set item=case when owner_id=p_owner then sent else facts->'received' end where trade_id=tid;
  end if;
end $$;

alter function public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb) rename to commit_canonical_game_command_v73;
create function public.commit_canonical_game_command(p_owner_id uuid,p_request_id uuid,p_lease_token uuid,p_state jsonb,p_result jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare intent private.canonical_game_intents%rowtype; current_context jsonb; receipt jsonb;
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_request_id is null or p_lease_token is null then raise exception 'game_request_invalid'; end if;
  select * into intent from private.canonical_game_intents where owner_id=p_owner_id and request_id=p_request_id;
  if not found or intent.lease_token<>p_lease_token then raise exception 'game_lease_lost'; end if;
  if intent.status='succeeded' then return intent.response; end if;
  if intent.action='confirm_trade' then raise exception 'game_social_state_changed'; end if;
  if intent.action in('offer_trade','reply_trade','cancel_trade','reject_trade') then
    perform private.lock_canonical_trade_keepers(p_owner_id,intent.action,intent.payload);
  elsif intent.action in('invite_pair_adventure','accept_pair_adventure','decline_pair_adventure','start_pair_adventure','cancel_pair_adventure') then
    perform private.lock_canonical_pair_keepers(p_owner_id,intent.action,intent.payload);
  else perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0)); end if;
  select * into intent from private.canonical_game_intents where owner_id=p_owner_id and request_id=p_request_id for update;
  if intent.status<>'processing' or intent.lease_token<>p_lease_token or intent.leased_until<=clock_timestamp() then raise exception 'game_lease_lost'; end if;
  if not intent.trade_reservations_captured or intent.trade_reservations is distinct from private.canonical_trade_reservations(p_owner_id,clock_timestamp()) then
    raise exception 'game_social_state_changed'; end if;
  if intent.action in('offer_trade','reply_trade','cancel_trade','reject_trade') then
    begin current_context:=private.canonical_trade_context(p_owner_id,intent.action,intent.payload,clock_timestamp(),(intent.social_context->>'sourceId')::uuid);
    exception when raise_exception then if sqlerrm='game_action_unavailable' then raise exception 'game_social_state_changed'; end if; raise; end;
    if current_context is distinct from intent.social_context then raise exception 'game_social_state_changed'; end if;
  end if;
  receipt:=public.commit_canonical_game_command_v73(p_owner_id,p_request_id,p_lease_token,p_state,p_result);
  if current_context is not null then
    perform private.commit_canonical_trade_lifecycle(p_owner_id,intent.action,intent.social_context,p_result,clock_timestamp()); end if;
  return receipt;
end $$;

create function public.commit_canonical_trade_command(p_owner_id uuid,p_request_id uuid,p_lease_token uuid,
  p_state jsonb,p_result jsonb,p_counterparty_state jsonb,p_counterparty_result jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare intent private.canonical_game_intents%rowtype; current_context jsonb; receipt jsonb;
  other_owner uuid; other_game private.canonical_game_states%rowtype; own_game private.canonical_game_states%rowtype;
  at_time timestamptz:=clock_timestamp(); tid uuid;
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_request_id is null or p_lease_token is null then raise exception 'game_request_invalid'; end if;
  select * into intent from private.canonical_game_intents where owner_id=p_owner_id and request_id=p_request_id;
  if not found or intent.lease_token<>p_lease_token then raise exception 'game_lease_lost'; end if;
  if intent.action<>'confirm_trade' then raise exception 'game_social_state_changed'; end if;
  perform private.lock_canonical_trade_keepers(p_owner_id,intent.action,intent.payload);
  select * into intent from private.canonical_game_intents where owner_id=p_owner_id and request_id=p_request_id for update;
  if intent.status='succeeded' then return intent.response; end if;
  if intent.status<>'processing' or intent.lease_token<>p_lease_token or intent.leased_until<=at_time then raise exception 'game_lease_lost'; end if;
  begin current_context:=private.canonical_trade_context(p_owner_id,intent.action,intent.payload,at_time);
  exception when raise_exception then if sqlerrm='game_action_unavailable' then raise exception 'game_social_state_changed'; end if; raise; end;
  if current_context is distinct from intent.social_context or intent.trade_counterparty is null then raise exception 'game_social_state_changed'; end if;
  other_owner:=(intent.trade_counterparty->>'owner_id')::uuid;
  if other_owner<>(current_context->'facts'->>'otherOwnerId')::uuid or p_result is distinct from p_counterparty_result then
    raise exception 'game_social_state_changed'; end if;
  select * into strict other_game from private.canonical_game_states where owner_id=other_owner for update;
  select * into strict own_game from private.canonical_game_states where owner_id=p_owner_id for update;
  if other_game.revision<>(intent.trade_counterparty->>'base_revision')::bigint or
      other_game.state_sha256<>intent.trade_counterparty->>'state_sha256' or
      other_game.authority_mode<>intent.trade_counterparty->>'authority_mode' or
      not intent.trade_reservations_captured or intent.trade_reservations is distinct from private.canonical_trade_reservations(p_owner_id,at_time) or
      intent.trade_counterparty->'trade_reservations' is distinct from private.canonical_trade_reservations(other_owner,at_time) or
      intent.trade_counterparty->'social_reservations' is distinct from private.canonical_social_reservations(other_owner,at_time,true) then
    raise exception 'game_social_state_changed'; end if;
  tid:=(current_context->>'sourceId')::uuid;
  perform private.assert_canonical_trade_delta(own_game.state,p_state,current_context->'facts'->'sent',current_context->'facts'->'received',tid);
  perform private.assert_canonical_trade_delta(other_game.state,p_counterparty_state,current_context->'facts'->'received',current_context->'facts'->'sent',tid);
  -- Both owners are locked and validated. Any following error rolls back both
  -- inventories, their social projections, the receipt and the shared status.
  receipt:=public.commit_canonical_game_command_v73(p_owner_id,p_request_id,p_lease_token,p_state,p_result);
  update private.canonical_game_states set state=p_counterparty_state,state_sha256=private.game_json_sha256(p_counterparty_state),
      revision=revision+1,updated_at=at_time where owner_id=other_owner;
  insert into private.canonical_trade_settlements(trade_id,owner_id,before_revision,after_revision,state_sha256) values
    (tid,p_owner_id,own_game.revision,own_game.revision+1,private.game_json_sha256(p_state)),
    (tid,other_owner,other_game.revision,other_game.revision+1,private.game_json_sha256(p_counterparty_state));
  perform private.commit_canonical_trade_lifecycle(p_owner_id,intent.action,current_context,p_result,at_time);
  return receipt;
end $$;

create function private.canonical_trade_offers(p_owner uuid,p_at timestamptz)
returns jsonb language plpgsql security definer set search_path='' as $$
declare offers jsonb;
begin
  perform private.assert_game_service();
  if not private.canonical_group_keeper_ready(p_owner) then return jsonb_build_object('completedToday',0,'offers','[]'::jsonb); end if;
  select coalesce(jsonb_agg(jsonb_build_object('id',t.id,'otherOwnerId',p.user_id,'otherName',p.display_name,'otherKeeperCode',p.keeper_code,
      'amInitiator',t.initiator_id=p_owner,'status',case when t.status in('awaiting_recipient','awaiting_initiator') and t.expires_at<=p_at then 'expired' else t.status end,
      'createdAt',t.created_at,'expiresAt',t.expires_at,'sent',own_item.item,'received',other_item.item)
      order by t.created_at desc,t.id),'[]'::jsonb) into offers
    from (select * from public.trades where canonical_owned and p_owner in(initiator_id,recipient_id)
        order by created_at desc,id limit 20) t
    join public.profiles p on p.user_id=case when t.initiator_id=p_owner then t.recipient_id else t.initiator_id end
    left join private.canonical_trade_items own_item on own_item.trade_id=t.id and own_item.owner_id=p_owner
    left join private.canonical_trade_items other_item on other_item.trade_id=t.id and other_item.owner_id=p.user_id;
  return jsonb_build_object('completedToday',private.completed_trades_today(p_owner),'offers',offers);
end $$;
alter function public.read_canonical_game_state(uuid,integer,text) rename to read_canonical_game_state_v73;
create function public.read_canonical_game_state(p_owner_id uuid,p_client_build integer,p_ruleset_sha256 text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare snapshot jsonb; at_time timestamptz;
begin
  perform private.assert_game_service();
  snapshot:=public.read_canonical_game_state_v73(p_owner_id,p_client_build,p_ruleset_sha256);
  at_time:=(snapshot->>'server_time')::timestamptz;
  return snapshot||jsonb_build_object('trade_reservations',private.canonical_trade_reservations(p_owner_id,at_time),
    'trade_offers',private.canonical_trade_offers(p_owner_id,at_time));
end $$;

create function private.guard_canonical_trade_write()
returns trigger language plpgsql security definer set search_path='' as $$
declare previous_value jsonb; next_value jsonb; row_value jsonb; tid uuid; keeper uuid; protected boolean;
begin
  if coalesce(auth.role(),'')='service_role' then if tg_op='DELETE' then return old; else return new; end if; end if;
  if tg_op<>'INSERT' then previous_value:=to_jsonb(old); end if;
  if tg_op<>'DELETE' then next_value:=to_jsonb(new); end if;
  row_value:=coalesce(next_value,previous_value);
  if tg_table_name='trades' then
    protected:=coalesce((previous_value->>'canonical_owned')::boolean,false) or coalesce((next_value->>'canonical_owned')::boolean,false);
    -- Existing expiry housekeeping may close a timed-out exchange. No owner,
    -- item, acknowledgment or arbitrary status change is allowed through it.
    if tg_op='UPDATE' and protected and previous_value->>'status' in('awaiting_recipient','awaiting_initiator') and
        next_value->>'status'='expired' and (previous_value->>'expires_at')::timestamptz<=clock_timestamp() and
        previous_value-array['status','updated_at'] = next_value-array['status','updated_at'] then return new; end if;
    -- Auth/profile deletion must keep its cascade working.
    if tg_op='DELETE' and(not exists(select 1 from public.profiles where user_id=(row_value->>'initiator_id')::uuid) or
        not exists(select 1 from public.profiles where user_id=(row_value->>'recipient_id')::uuid)) then return old; end if;
    for keeper in select distinct x from unnest(array[(row_value->>'initiator_id')::uuid,(row_value->>'recipient_id')::uuid]) x
        where x is not null order by x loop
      if protected or exists(select 1 from public.player_economy_authority where user_id=keeper and authority_mode='server') then
        raise exception 'economy_server_inventory_required'; end if;
    end loop;
  else
    tid:=(row_value->>'trade_id')::uuid;keeper:=(row_value->>'owner_id')::uuid;
    if tg_op='DELETE' and(not exists(select 1 from public.trades where id=tid) or
        not exists(select 1 from public.profiles where user_id=keeper) or
        exists(select 1 from public.trades where id=tid and status='expired' and expires_at<=clock_timestamp())) then return old; end if;
    if exists(select 1 from public.trades where id=tid and canonical_owned) or
        exists(select 1 from public.player_economy_authority where user_id=keeper and authority_mode='server') then
      raise exception 'economy_server_inventory_required'; end if;
  end if;
  if tg_op='DELETE' then return old; else return new; end if;
end $$;
create trigger canonical_trade_write before insert or update or delete on public.trades
  for each row execute function private.guard_canonical_trade_write();
create trigger canonical_trade_reservation_write before insert or update or delete on public.trade_reservations
  for each row execute function private.guard_canonical_trade_write();

revoke all on function private.lock_canonical_trade_keepers(uuid,text,jsonb),private.canonical_trade_reservations(uuid,timestamptz),
  private.canonical_trade_asset(uuid,text,text,integer),private.canonical_trade_context(uuid,text,jsonb,timestamptz,uuid),
  private.assert_canonical_trade_delta(jsonb,jsonb,jsonb,jsonb,uuid),private.commit_canonical_trade_lifecycle(uuid,text,jsonb,jsonb,timestamptz),
  private.canonical_trade_offers(uuid,timestamptz),private.guard_canonical_trade_write(),
  public.begin_revisioned_game_command_v73(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command_v73(uuid,uuid,uuid,jsonb,jsonb),public.read_canonical_game_state_v73(uuid,integer,text)
  from public,anon,authenticated,service_role;
revoke all on function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb),public.read_canonical_game_state(uuid,integer,text),
  public.commit_canonical_trade_command(uuid,uuid,uuid,jsonb,jsonb,jsonb,jsonb) from public,anon,authenticated;
grant execute on function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb),public.read_canonical_game_state(uuid,integer,text),
  public.commit_canonical_trade_command(uuid,uuid,uuid,jsonb,jsonb,jsonb,jsonb) to service_role;
