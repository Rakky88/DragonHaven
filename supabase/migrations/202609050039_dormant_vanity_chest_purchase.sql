-- First concrete server-authoritative economy mutation.
--
-- This RPC remains unreachable for every current keeper because migration 37
-- leaves the global mutation switch disabled and every authority row in
-- legacy_client mode. A later, separately approved migration must import and
-- verify server-owned balances/collections before enabling any account.

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
    ('title'::text, 'coins'::text, 100, 'title'::text, 500),
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

revoke all on function public.purchase_vanity_chest(
  uuid, text, integer, integer
) from public, anon;
grant execute on function public.purchase_vanity_chest(
  uuid, text, integer, integer
) to authenticated;

comment on function public.purchase_vanity_chest(
  uuid, text, integer, integer
) is
  'Dormant idempotent server purchase for capped non-tradeable vanity chests.';
