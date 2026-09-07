-- Isolated Altar ledger. This does not enable the broader economy rollout.
-- Legacy inventory registration remains the existing trust boundary; after
-- registration, returns, materials, crafting and consumptions are server owned.
create table private.egg_altar_accounts (
  owner_id uuid primary key references public.profiles(user_id) on delete cascade,
  fragments bigint not null default 0 check (fragments >= 0),
  essence bigint not null default 0 check (essence >= 0),
  hearts bigint not null default 0 check (hearts >= 0),
  misses integer not null default 0 check (misses between 0 and 39),
  total_returned integer not null default 0,
  crafted jsonb not null default '{}'::jsonb,
  revision bigint not null default 1
);
create table private.egg_altar_eggs (
  egg_id text primary key check (char_length(egg_id) between 1 and 100),
  owner_id uuid not null references public.profiles(user_id) on delete cascade,
  lineage_id text not null,
  in_nest boolean not null default false,
  tagged boolean not null default false,
  tag_revision bigint not null default 0,
  moral_known boolean not null default false,
  order_known boolean not null default false,
  rarity_known boolean not null default false,
  lineage_known boolean not null default false,
  returned boolean not null default false
);
create index egg_altar_eggs_owner_idx on private.egg_altar_eggs(owner_id);
create table private.egg_altar_dragons (
  dragon_id text primary key check (char_length(dragon_id) between 1 and 100),
  owner_id uuid not null references public.profiles(user_id) on delete cascade,
  custom_name text not null default '' check (char_length(custom_name) <= 24),
  renamed boolean not null default false
);
create table private.egg_altar_operations (
  owner_id uuid not null references public.profiles(user_id) on delete cascade,
  operation_id text not null check (char_length(operation_id) between 1 and 150),
  action text not null,
  payload jsonb not null,
  receipt jsonb not null,
  created_at timestamptz not null default now(),
  primary key (owner_id, operation_id)
);
create table private.conclave_weave_beacons (
  conclave_id uuid primary key references public.conclaves(id) on delete cascade,
  fragments integer not null default 0 check (fragments between 0 and 5000)
);
revoke all on private.egg_altar_accounts, private.egg_altar_eggs, private.egg_altar_dragons,
  private.egg_altar_operations, private.conclave_weave_beacons from public, anon, authenticated;

create function private.can_return_egg_lineage(p_lineage text)
returns boolean language sql immutable set search_path = '' as $$
  select p_lineage = any(array[
    'mossprout',
    'crystalwhisk',
    'dustglimmer',
    'gleamclaw',
    'emberbun',
    'copperflame',
    'spicewing',
    'bubblefin',
    'linencloud',
    'tidescale',
    'clockskip',
    'galeear',
    'thunderpuff',
    'dreammoth',
    'dewhorn',
    'quietstar',
    'heartwing',
    'twinflare',
    'rainbowruff',
    'harmonytail',
    'bramblequill',
    'cinderlynx',
    'mistmantle',
    'runehopper',
    'petaldrift',
    'ironwhistle',
    'frostfable',
    'sunmuzzle',
    'echofern',
    'velvetvolt',
    'auroracrown',
    'voidbloom',
    'coraloracle',
    'meteorhide',
    'temporalark',
    'opalchimera',
    'eclipseantler',
    'worldroot',
    'seraphscale',
    'starforged',
    'leviathanecho',
    'everwyrm',
    'sinisterra'
  ])
$$;

create function private.altar_knowledge(p_egg private.egg_altar_eggs)
returns jsonb language sql stable set search_path = '' as $$
  select jsonb_build_object('tagged', p_egg.tagged, 'tagRevision', p_egg.tag_revision,
    'moral', p_egg.moral_known, 'order', p_egg.order_known,
    'rarity', p_egg.rarity_known, 'lineage', p_egg.lineage_known)
$$;

-- Metadata follows an authorized trade, and remains after an inventory sync
-- removes the corresponding egg row. A returned ID can never be re-imported.
create function private.guard_altar_egg_ledger()
returns trigger language plpgsql set search_path = '' as $$
declare meta private.egg_altar_eggs;
begin
  select * into meta from private.egg_altar_eggs where egg_id = new.legacy_client_id for update;
  if found then
    if meta.returned then return null; end if;
    if tg_op = 'UPDATE' and old.owner_id <> new.owner_id then
      update private.egg_altar_eggs set owner_id = new.owner_id, in_nest = false
        where egg_id = new.legacy_client_id;
    elsif meta.owner_id <> new.owner_id then
      raise exception 'egg_not_owned';
    end if;
    new.lineage_id := meta.lineage_id;
  end if;
  return new;
end
$$;
create trigger egg_altar_ledger_guard before insert or update on public.player_eggs
  for each row execute function private.guard_altar_egg_ledger();

alter function public.synchronize_trade_inventory(jsonb) rename to synchronize_trade_inventory_v41;
create function public.synchronize_trade_inventory(p_inventory jsonb)
returns void language plpgsql security definer set search_path = '' as $$
declare uid uuid := auth.uid(); item jsonb;
begin
  if uid is null then raise exception 'online_login_required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(uid::text, 0));
  if jsonb_typeof(coalesce(p_inventory->'altar_eggs', '[]')) <> 'array'
    or jsonb_array_length(coalesce(p_inventory->'altar_eggs', '[]')) > 500
    or jsonb_typeof(coalesce(p_inventory->'altar_dragons', '[]')) <> 'array'
    or jsonb_array_length(coalesce(p_inventory->'altar_dragons', '[]')) > 10000 then
    raise exception 'invalid_inventory';
  end if;
  for item in select value from jsonb_array_elements(
      coalesce(p_inventory->'altar_eggs', p_inventory->'eggs', '[]')) loop
    insert into private.egg_altar_eggs(egg_id, owner_id, lineage_id, in_nest,
      tagged, tag_revision, moral_known, order_known, rarity_known, lineage_known)
    values (item->>'client_id', uid, item->>'lineage_id',
      coalesce((item->>'tradeable')::boolean, true) = false,
      coalesce((item->'altar_knowledge'->>'tagged')::boolean, false),
      coalesce((item->'altar_knowledge'->>'tagRevision')::bigint, 0),
      item->>'lineage_id' = 'sinisterra' or coalesce((item->'altar_knowledge'->>'moral')::boolean, false),
      coalesce((item->'altar_knowledge'->>'order')::boolean, false),
      coalesce((item->'altar_knowledge'->>'rarity')::boolean, false),
      coalesce((item->'altar_knowledge'->>'lineage')::boolean, false))
    on conflict (egg_id) do update set
      in_nest = excluded.in_nest,
      moral_known = private.egg_altar_eggs.moral_known or excluded.moral_known,
      order_known = private.egg_altar_eggs.order_known or excluded.order_known,
      rarity_known = private.egg_altar_eggs.rarity_known or excluded.rarity_known,
      lineage_known = private.egg_altar_eggs.lineage_known or excluded.lineage_known
    where private.egg_altar_eggs.owner_id = uid and not private.egg_altar_eggs.returned;
    -- Existing tags are only changed by the explicit tag command, never by a backup.
  end loop;
  for item in select value from jsonb_array_elements(coalesce(p_inventory->'altar_dragons', '[]')) loop
    insert into private.egg_altar_dragons(dragon_id, owner_id, custom_name)
      values (item->>'client_id', uid, left(coalesce(item->>'custom_name', ''), 24))
    on conflict (dragon_id) do update set custom_name = excluded.custom_name
      where private.egg_altar_dragons.owner_id = uid
        and private.egg_altar_dragons.custom_name = '' and not private.egg_altar_dragons.renamed;
  end loop;
  perform public.synchronize_trade_inventory_v41(p_inventory);
end
$$;

alter function private.trade_egg_data(public.player_eggs) rename to trade_egg_data_v41;
create function private.trade_egg_data(p_egg public.player_eggs)
returns jsonb language sql stable set search_path = '' as $$
  select private.trade_egg_data_v41(p_egg) || jsonb_build_object('altarKnowledge',
    coalesce((select private.altar_knowledge(e) from private.egg_altar_eggs e
      where e.egg_id = p_egg.legacy_client_id), '{}'::jsonb))
$$;

create function private.egg_altar_state(p_owner uuid)
returns jsonb language sql stable set search_path = '' as $$
  select jsonb_build_object('ownerId', p_owner, 'revision', a.revision,
    'wallet', jsonb_build_object('fragments', a.fragments, 'essence', a.essence, 'hearts', a.hearts),
    'misses', a.misses, 'totalReturned', a.total_returned, 'crafted', a.crafted,
    'eggs', coalesce((select jsonb_object_agg(e.egg_id, private.altar_knowledge(e))
      from private.egg_altar_eggs e where e.owner_id = p_owner and not e.returned), '{}'),
    'returnedIds', coalesce((select jsonb_agg(e.egg_id) from private.egg_altar_eggs e
      where e.owner_id = p_owner and e.returned), '[]'),
    'names', coalesce((select jsonb_object_agg(d.dragon_id, d.custom_name)
      from private.egg_altar_dragons d where d.owner_id = p_owner and d.renamed), '{}'))
  from private.egg_altar_accounts a where a.owner_id = p_owner
$$;

create function public.get_egg_altar_state()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare uid uuid := auth.uid();
begin
  if uid is null then raise exception 'online_login_required'; end if;
  insert into private.egg_altar_accounts(owner_id) values (uid) on conflict do nothing;
  return private.egg_altar_state(uid);
end
$$;

create function public.get_conclave_weave_beacon(p_conclave_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare amount integer;
begin
  if not exists(select 1 from public.conclave_members m
    where m.user_id = auth.uid() and m.conclave_id = p_conclave_id) then
    raise exception 'conclave_member_not_found';
  end if;
  select b.fragments into amount from private.conclave_weave_beacons b where b.conclave_id = p_conclave_id;
  return jsonb_build_object('fragments', coalesce(amount, 0), 'goal', 5000);
end
$$;

create function public.egg_altar_command(p_operation_id text, p_action text, p_payload jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid(); account private.egg_altar_accounts;
  egg private.egg_altar_eggs; dragon private.egg_altar_dragons;
  operation private.egg_altar_operations; receipt jsonb := '{}'::jsonb;
  egg_key text := p_payload->>'eggId'; relic_key text := p_payload->>'relic';
  multiplier integer; reward_fragments integer; reward_essence integer; reward_hearts integer;
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
    multiplier := case when egg.lineage_id = 'sinisterra' then 5 else 1 end;
    if multiplier = 5 and coalesce((p_payload->>'sinisterConfirmed')::boolean, false) = false then
      raise exception 'sinister_confirmation_required';
    end if;
    reward_fragments := 5 * multiplier;
    reward_essence := case when random() < 0.25 then multiplier else 0 end;
    reward_hearts := case when random() < 0.02 or account.misses = 39 then multiplier else 0 end;
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

revoke all on function public.synchronize_trade_inventory_v41(jsonb) from public, anon, authenticated;
revoke all on function public.synchronize_trade_inventory(jsonb) from public, anon;
grant execute on function public.synchronize_trade_inventory(jsonb) to authenticated;
revoke all on function public.get_egg_altar_state() from public, anon;
revoke all on function public.get_conclave_weave_beacon(uuid) from public, anon;
revoke all on function public.egg_altar_command(text, text, jsonb) from public, anon;
grant execute on function public.get_egg_altar_state() to authenticated;
grant execute on function public.get_conclave_weave_beacon(uuid) to authenticated;
grant execute on function public.egg_altar_command(text, text, jsonb) to authenticated;
revoke all on function private.can_return_egg_lineage(text),
  private.altar_knowledge(private.egg_altar_eggs), private.guard_altar_egg_ledger(),
  private.trade_egg_data(public.player_eggs), private.trade_egg_data_v41(public.player_eggs),
  private.egg_altar_state(uuid) from public, anon, authenticated;
