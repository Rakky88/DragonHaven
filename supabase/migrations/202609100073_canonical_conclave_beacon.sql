-- A voluntary cosmetic contribution uses canonical fragments. No client can
-- submit the shared total or grant itself Altar resources through the old RPC.
create function private.canonical_beacon_context(p_owner uuid,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare cid uuid; amount_value integer; before_value integer; facts jsonb;
begin
  perform private.assert_game_service();
  perform pg_advisory_xact_lock(hashtextextended(p_owner::text,0));
  perform private.lock_canonical_social_sources(p_owner,null);
  if not private.canonical_group_keeper_ready(p_owner) or jsonb_typeof(p_payload->'amount') is distinct from 'number' then
    raise exception 'game_action_unavailable'; end if;
  cid:=(p_payload->>'conclaveId')::uuid;
  if (p_payload->>'amount') !~ '^[0-9]{1,4}$' then raise exception 'game_action_unavailable'; end if;
  amount_value:=(p_payload->>'amount')::integer;
  if cid is null or amount_value is null or amount_value not between 1 and 5000 then raise exception 'game_action_unavailable'; end if;
  perform 1 from public.conclave_members where user_id=p_owner and conclave_id=cid for share;
  if not found then raise exception 'game_action_unavailable'; end if;
  insert into private.conclave_weave_beacons(conclave_id) values(cid) on conflict do nothing;
  select fragments into before_value from private.conclave_weave_beacons where conclave_id=cid for update;
  if amount_value>5000-before_value then raise exception 'game_action_unavailable'; end if;
  facts:=jsonb_build_object('beforeFragments',before_value,'amount',amount_value,'goal',5000);
  return jsonb_build_object('version',1,'ownerId',p_owner,'action','donate_beacon','sourceId',cid,'facts',facts,
    'fingerprint',private.game_json_sha256(jsonb_build_object('ownerId',p_owner,'conclaveId',cid,'facts',facts)));
exception when invalid_text_representation or numeric_value_out_of_range then raise exception 'game_action_unavailable';
end $$;

alter function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint)
  rename to begin_revisioned_game_command_v72;
create function public.begin_revisioned_game_command(p_owner_id uuid,p_request_id uuid,p_action text,p_payload jsonb,
  p_client_build integer,p_ruleset_sha256 text,p_expected_revision bigint)
returns jsonb language plpgsql security definer set search_path='' as $$
declare leased jsonb; context_value jsonb;
begin
  perform private.assert_game_service();
  leased:=public.begin_revisioned_game_command_v72(p_owner_id,p_request_id,p_action,p_payload,p_client_build,p_ruleset_sha256,p_expected_revision);
  if leased->>'status'<>'processing' or p_action<>'donate_beacon' then return leased; end if;
  select social_context into context_value from private.canonical_game_intents where owner_id=p_owner_id and request_id=p_request_id;
  if context_value is null then
    begin context_value:=private.canonical_beacon_context(p_owner_id,p_payload);
    exception when raise_exception then
      if sqlerrm<>'game_action_unavailable' then raise; end if;
      if not public.fail_canonical_game_command(p_owner_id,p_request_id,(leased->>'lease_token')::uuid,'game_action_unavailable') then
        raise exception 'game_lease_lost'; end if;
      return jsonb_build_object('status','failed','failure_code','game_action_unavailable','response',null,'replayed',false);
    end;
    update private.canonical_game_intents set social_context=context_value where owner_id=p_owner_id and request_id=p_request_id;
  end if;
  return leased||jsonb_build_object('social_context',context_value);
end $$;

alter function public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb) rename to commit_canonical_game_command_v72;
create function public.commit_canonical_game_command(p_owner_id uuid,p_request_id uuid,p_lease_token uuid,p_state jsonb,p_result jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare intent private.canonical_game_intents%rowtype; context_value jsonb; receipt jsonb;
  before_value integer; after_value integer; amount_value integer; cid uuid; old_wallet jsonb; new_wallet jsonb;
begin
  perform private.assert_game_service();
  if p_owner_id is null or p_request_id is null or p_lease_token is null then raise exception 'game_request_invalid'; end if;
  -- Pair/trade commands acquire both owners before entering older wrappers.
  -- Do not take a single-owner lock until this action has been classified.
  select * into intent from private.canonical_game_intents where owner_id=p_owner_id and request_id=p_request_id;
  if not found or intent.lease_token<>p_lease_token then raise exception 'game_lease_lost'; end if;
  if intent.status<>'processing' or intent.action<>'donate_beacon' then
    return public.commit_canonical_game_command_v72(p_owner_id,p_request_id,p_lease_token,p_state,p_result); end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0));
  select * into intent from private.canonical_game_intents where owner_id=p_owner_id and request_id=p_request_id for update;
  if intent.status<>'processing' or intent.lease_token<>p_lease_token or intent.leased_until<=clock_timestamp() then
    raise exception 'game_lease_lost'; end if;
  begin context_value:=private.canonical_beacon_context(p_owner_id,intent.payload);
  exception when raise_exception then
    if sqlerrm='game_action_unavailable' then raise exception 'game_social_state_changed'; end if; raise;
  end;
  if context_value is distinct from intent.social_context then raise exception 'game_social_state_changed'; end if;
  cid:=(context_value->>'sourceId')::uuid;
  before_value:=(context_value->'facts'->>'beforeFragments')::integer;
  amount_value:=(context_value->'facts'->>'amount')::integer;
  after_value:=before_value+amount_value;
  select state->'eggAltar'->'wallet' into old_wallet from private.canonical_game_states where owner_id=p_owner_id;
  new_wallet:=p_state->'eggAltar'->'wallet';
  if p_result is distinct from jsonb_build_object('donated',amount_value,'fragments',after_value)
      or (old_wallet->>'fragments')::bigint<amount_value
      or new_wallet is distinct from jsonb_set(old_wallet,'{fragments}',to_jsonb((old_wallet->>'fragments')::bigint-amount_value)) then
    raise exception 'game_social_state_changed'; end if;
  receipt:=public.commit_canonical_game_command_v72(p_owner_id,p_request_id,p_lease_token,p_state,p_result);
  update private.conclave_weave_beacons set fragments=after_value where conclave_id=cid;
  if (before_value<500 and after_value>=500) or (before_value<2000 and after_value>=2000) or
      (before_value<5000 and after_value>=5000) then
    insert into public.conclave_messages(conclave_id,sender_id,kind,body,payload)
      values(cid,p_owner_id,'text','Our Weave Beacon reached a new stage!',jsonb_build_object('weave_beacon',true,'fragments',after_value));
  end if;
  return receipt;
end $$;
revoke all on function private.canonical_beacon_context(uuid,jsonb),
  public.begin_revisioned_game_command_v72(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command_v72(uuid,uuid,uuid,jsonb,jsonb) from public,anon,authenticated,service_role;
revoke all on function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb) from public,anon,authenticated;
grant execute on function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint),
  public.commit_canonical_game_command(uuid,uuid,uuid,jsonb,jsonb) to service_role;

alter function public.egg_altar_command(text,text,jsonb) rename to egg_altar_command_v72;
create function public.egg_altar_command(p_operation_id text,p_action text,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
begin
  perform private.assert_legacy_inventory_authority();
  return public.egg_altar_command_v72(p_operation_id,p_action,p_payload);
end $$;
revoke all on function public.egg_altar_command_v72(text,text,jsonb) from public,anon,authenticated,service_role;
revoke all on function public.egg_altar_command(text,text,jsonb) from public,anon,service_role;
grant execute on function public.egg_altar_command(text,text,jsonb) to authenticated;
