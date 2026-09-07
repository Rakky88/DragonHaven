-- Forward-only balance update. Existing operation receipts and wallets are preserved.
-- Independent uniform rolls in [0, 1): Sinister always grants 25 fragments,
-- 3/4/5 Essence with equal probability, and a 10% chance of ONE Weaveheart.
-- Ordinary rewards and the account-wide guarantee after 39 misses are unchanged.
create function private.egg_altar_return_reward(
  p_sinister boolean, p_misses integer,
  p_essence_roll double precision, p_heart_roll double precision
) returns jsonb language sql immutable set search_path = '' as $$
  select jsonb_build_object(
    'fragments', case when p_sinister then 25 else 5 end,
    'essence', case when p_sinister then 3 + floor(p_essence_roll * 3)::integer
      when p_essence_roll < 0.25 then 1 else 0 end,
    'hearts', case when p_heart_roll < (case when p_sinister then 0.10 else 0.02 end)
      or p_misses >= 39 then 1 else 0 end
  );
$$;
revoke all on function private.egg_altar_return_reward(boolean, integer, double precision, double precision)
  from public, anon, authenticated;

create or replace function public.egg_altar_command(p_operation_id text, p_action text, p_payload jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid(); account private.egg_altar_accounts;
  egg private.egg_altar_eggs; dragon private.egg_altar_dragons;
  operation private.egg_altar_operations; receipt jsonb := '{}'::jsonb;
  egg_key text := p_payload->>'eggId'; relic_key text := p_payload->>'relic';
  reward jsonb; reward_fragments integer; reward_essence integer; reward_hearts integer;
  cost_fragments integer; cost_essence integer; cost_hearts integer;
  owned integer; new_name text; cid uuid; donated integer; before_amount integer; after_amount integer;
begin
  if uid is null then raise exception 'online_login_required'; end if;
  if not exists(select 1 from auth.users u where u.id = uid and u.email_confirmed_at is not null) then
    raise exception 'email_not_verified';
  end if;
  if p_operation_id is null or char_length(p_operation_id) not between 1 and 150
    or jsonb_typeof(p_payload) is distinct from 'object' or pg_column_size(p_payload) > 4096 then
    raise exception 'invalid_action';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(uid::text, 0));
  insert into private.egg_altar_accounts(owner_id) values (uid) on conflict do nothing;
  select * into account from private.egg_altar_accounts where owner_id = uid for update;
  select * into operation from private.egg_altar_operations
    where owner_id = uid and operation_id = p_operation_id;
  if found then
    if operation.action <> p_action or operation.payload <> p_payload then raise exception 'operation_mismatch'; end if;
    return jsonb_build_object('state', private.egg_altar_state(uid), 'receipt', operation.receipt);
  end if;

  if p_action in ('tag', 'return', 'reveal') then
    select * into egg from private.egg_altar_eggs e where e.egg_id = egg_key and e.owner_id = uid for update;
    if not found or egg.returned then raise exception 'egg_not_found'; end if;
    if not egg.in_nest and not exists(select 1 from public.player_eggs e
        where e.owner_id = uid and e.legacy_client_id = egg_key) then raise exception 'egg_not_owned'; end if;
    if exists(select 1 from public.trade_reservations r where r.owner_id = uid
      and r.item_type = 'egg' and r.item_key = egg_key) and p_action <> 'tag' then
      raise exception 'egg_reserved';
    end if;
  end if;

  case p_action
  when 'tag' then
    if jsonb_typeof(p_payload->'tagged') is distinct from 'boolean' then raise exception 'invalid_action'; end if;
    update private.egg_altar_eggs set tagged = (p_payload->>'tagged')::boolean,
      tag_revision = greatest(egg.tag_revision + 1, (extract(epoch from clock_timestamp()) * 1000000)::bigint)
      where egg_id = egg_key;
  when 'return' then
    if egg.in_nest then raise exception 'egg_in_nest'; end if;
    if egg.tagged then raise exception 'egg_tagged'; end if;
    if not private.can_return_egg_lineage(egg.lineage_id) then
      raise exception 'special_egg';
    end if;
    if egg.lineage_id = 'sinisterra' and coalesce((p_payload->>'sinisterConfirmed')::boolean, false) = false then
      raise exception 'sinister_confirmation_required';
    end if;
    reward := private.egg_altar_return_reward(
      egg.lineage_id = 'sinisterra', account.misses, random(), random());
    reward_fragments := (reward->>'fragments')::integer;
    reward_essence := (reward->>'essence')::integer;
    reward_hearts := (reward->>'hearts')::integer;
    update private.egg_altar_accounts set fragments = fragments + reward_fragments,
      essence = essence + reward_essence, hearts = hearts + reward_hearts,
      misses = case when reward_hearts > 0 then 0 else misses + 1 end,
      total_returned = total_returned + 1 where owner_id = uid;
    update private.egg_altar_eggs set returned = true where egg_id = egg_key;
    delete from public.player_eggs where owner_id = uid and legacy_client_id = egg_key;
    receipt := jsonb_build_object('reward', jsonb_build_object('fragments', reward_fragments,
      'essence', reward_essence, 'hearts', reward_hearts));
  when 'craft' then
    case relic_key
      when 'moralEcho' then cost_fragments := 20; cost_essence := 1; cost_hearts := 0;
      when 'orderSigil' then cost_fragments := 30; cost_essence := 2; cost_hearts := 0;
      when 'astralLens' then cost_fragments := 50; cost_essence := 5; cost_hearts := 1;
      when 'weaveOracle' then cost_fragments := 125; cost_essence := 12; cost_hearts := 2;
      when 'nameweaversQuill' then cost_fragments := 10; cost_essence := 1; cost_hearts := 0;
      else raise exception 'invalid_relic';
    end case;
    if account.fragments < cost_fragments or account.essence < cost_essence or account.hearts < cost_hearts then
      raise exception 'insufficient_materials';
    end if;
    owned := coalesce((account.crafted->>relic_key)::integer, 0);
    update private.egg_altar_accounts set fragments = fragments - cost_fragments,
      essence = essence - cost_essence, hearts = hearts - cost_hearts,
      crafted = jsonb_set(crafted, array[relic_key], to_jsonb(owned + 1)) where owner_id = uid;
  when 'reveal' then
    if relic_key is null or relic_key not in ('moralEcho', 'orderSigil', 'astralLens', 'weaveOracle') then raise exception 'invalid_relic'; end if;
    if (relic_key = 'moralEcho' and egg.moral_known) or (relic_key = 'orderSigil' and egg.order_known)
      or (relic_key = 'astralLens' and egg.rarity_known) or (relic_key = 'weaveOracle' and egg.lineage_known) then raise exception 'already_known'; end if;
    owned := coalesce((account.crafted->>relic_key)::integer, 0);
    if owned < 1 then raise exception 'relic_not_owned'; end if;
    update private.egg_altar_accounts set crafted = jsonb_set(crafted, array[relic_key], to_jsonb(owned - 1)) where owner_id = uid;
    update private.egg_altar_eggs set moral_known = moral_known or relic_key = 'moralEcho',
      order_known = order_known or relic_key = 'orderSigil',
      rarity_known = rarity_known or relic_key in ('astralLens', 'weaveOracle'),
      lineage_known = lineage_known or relic_key = 'weaveOracle' where egg_id = egg_key;
  when 'rename' then
    select * into dragon from private.egg_altar_dragons d
      where d.dragon_id = p_payload->>'dragonId' and d.owner_id = uid for update;
    new_name := btrim(p_payload->>'name');
    if not found or new_name is null or char_length(new_name) not between 1 and 24
      or dragon.custom_name = '' or dragon.custom_name = new_name then raise exception 'invalid_name'; end if;
    owned := coalesce((account.crafted->>'nameweaversQuill')::integer, 0);
    if owned < 1 then raise exception 'relic_not_owned'; end if;
    update private.egg_altar_accounts set crafted = jsonb_set(crafted, '{nameweaversQuill}', to_jsonb(owned - 1)) where owner_id = uid;
    update private.egg_altar_dragons set custom_name = new_name, renamed = true where dragon_id = dragon.dragon_id;
    update public.player_dragons set name = new_name where owner_id = uid and legacy_client_id = dragon.dragon_id;
    update public.social_showcases set favorite_dragon_name = new_name
      where user_id = uid and favorite_dragon_id = dragon.dragon_id;
  when 'donate' then
    cid := (p_payload->>'conclaveId')::uuid;
    donated := (p_payload->>'amount')::integer;
    if donated is null or donated not between 1 and 5000 then raise exception 'invalid_amount'; end if;
    perform 1 from public.conclave_members m where m.user_id = uid and m.conclave_id = cid for share;
    if not found then raise exception 'conclave_member_not_found'; end if;
    insert into private.conclave_weave_beacons(conclave_id) values (cid) on conflict do nothing;
    select b.fragments into before_amount from private.conclave_weave_beacons b where b.conclave_id = cid for update;
    if donated > 5000 - before_amount then raise exception 'beacon_amount_exceeds_goal'; end if;
    if account.fragments < donated then raise exception 'insufficient_materials'; end if;
    after_amount := before_amount + donated;
    update private.conclave_weave_beacons set fragments = after_amount where conclave_id = cid;
    update private.egg_altar_accounts set fragments = fragments - donated where owner_id = uid;
    if (before_amount < 500 and after_amount >= 500) or (before_amount < 2000 and after_amount >= 2000)
      or (before_amount < 5000 and after_amount >= 5000) then
      insert into public.conclave_messages(conclave_id, sender_id, kind, body, payload)
      values (cid, uid, 'text', 'Our Weave Beacon reached a new stage!',
        jsonb_build_object('weave_beacon', true, 'fragments', after_amount));
    end if;
    receipt := jsonb_build_object('fragments', after_amount, 'donated', donated);
  else raise exception 'invalid_action';
  end case;
  update private.egg_altar_accounts set revision = revision + 1 where owner_id = uid;
  receipt := receipt || jsonb_build_object('action', p_action);
  insert into private.egg_altar_operations(owner_id, operation_id, action, payload, receipt)
    values (uid, p_operation_id, p_action, p_payload, receipt);
  return jsonb_build_object('state', private.egg_altar_state(uid), 'receipt', receipt);
end
$$;

