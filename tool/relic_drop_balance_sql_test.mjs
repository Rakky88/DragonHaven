// Isolated PostgreSQL migration contract. Never connects to a remote database.
// Usage: node tool/relic_drop_balance_sql_test.mjs
import { PGlite } from '../build/event-points-tools/package/dist/index.js';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const db = new PGlite();
const owner = '11111111-1111-4111-8111-111111111111';
const other = '22222222-2222-4222-8222-222222222222';
try {
  await db.exec(`
    create role anon; create role authenticated; create role service_role;
    create schema auth; create schema private;
    create function auth.role() returns text language sql stable as $$
      select nullif(current_setting('request.jwt.claim.role',true),'')
    $$;
    create function private.assert_game_service() returns void language plpgsql as $$
    begin
      if auth.role() is distinct from 'service_role' then
        raise exception 'game_service_required';
      end if;
    end $$;
    create table private.canonical_game_states(
      owner_id uuid primary key, state jsonb, is_prepared boolean);
    -- These types compile the unchanged dormant chest RPC. Its business
    -- dependencies are deliberately not stubbed to suggest a full integration.
    create table public.player_chest_instances(id uuid primary key);
    create table public.player_wallets(user_id uuid primary key);
    create function private.economy_shop_catalog() returns jsonb language sql
      as $$ select '{}'::jsonb $$;
    revoke all on function private.economy_shop_catalog() from public,anon,authenticated;
    create function public.open_chest_instances(uuid,uuid[],integer,integer)
      returns jsonb language sql as $$ select '{}'::jsonb $$;
    revoke all on function public.open_chest_instances(uuid,uuid[],integer,integer)
      from public,anon;
    grant execute on function public.open_chest_instances(uuid,uuid[],integer,integer)
      to authenticated;
    create function private.canonical_trade_asset(uuid,text,text,integer)
      returns jsonb language sql as $$ select '{}'::jsonb $$;
    revoke all on function private.canonical_trade_asset(uuid,text,text,integer)
      from public,anon,authenticated;
    grant execute on function private.canonical_trade_asset(uuid,text,text,integer)
      to service_role;
  `);
  await db.exec(readFileSync(
    'supabase/migrations/202609270101_relic_drop_balance_and_quills.sql', 'utf8'));
  const catalog = (await db.query('select private.economy_chest_catalog() as c')).rows[0].c;
  assert.equal(catalog.version, 5);
  assert.deepEqual(catalog.quill_chances,
    {wooden: .01, silver: .02, gold: .04, dragon: .08, mythical: .16, sinister: 0});
  assert.equal(catalog.relic_weights.nameweaversQuill, 0);
  const shop = (await db.query('select private.economy_shop_catalog() as c')).rows[0].c;
  assert.equal(shop.version, 2);
  assert.deepEqual(shop.relic.nameweaversQuill,
    {currency:'gems',price:100,tradeable:false,unique_while_owned:false});
  assert.equal(Object.keys(shop.relic).length, 5);
  for (const key of ['moralPrism','orderCompass','soulMirror','astralLens']) {
    assert.equal(shop.relic[key].price, 500);
    assert.equal(shop.relic[key].tradeable, false);
  }
  for (const [tier, chance] of Object.entries(
    {wooden: 0, silver: 0, gold: .05, dragon: .10, mythical: .20, sinister: 1})) {
    assert.equal(catalog.tiers[tier].relic_chance, chance);
  }
  // Execute the actual SQL ticket generation: Quill contributes no ticket.
  const tickets = await db.query(`
    select value as relic, count(*)::int as count
    from jsonb_array_elements_text(private.economy_chest_catalog()->'relic') r(value)
    cross join lateral generate_series(1,
      (private.economy_chest_catalog()->'relic_weights'->>r.value)::integer) ticket
    group by value`);
  assert.equal(tickets.rows.reduce((sum,r) => sum+r.count, 0), 65);
  assert.equal(tickets.rows.some(r => r.relic === 'nameweaversQuill'), false);

  await db.query('insert into private.canonical_game_states values($1,$2,true)', [owner, {
    relicInventory: {nameweaversQuill: 3, moralPrism: 1, sparkAstrolabe: 1},
    untradeableRelicInventory: {nameweaversQuill: 2},
  }]);
  const select = (who=owner, key='nameweaversQuill', variant=0) => db.query(
    "select private.canonical_trade_asset($1,'relic',$2,$3) as item", [who,key,variant]);
  await db.query("select set_config('request.jwt.claim.role','authenticated',false)");
  await assert.rejects(() => select(), /game_service_required/);
  await db.query("select set_config('request.jwt.claim.role','service_role',false)");
  assert.deepEqual((await select()).rows[0].item,
    {kind:'relic',key:'nameweaversQuill',variant:0,data:{}});
  assert.equal((await select(owner,'moralPrism')).rows[0].item.key, 'moralPrism');
  await assert.rejects(() => select(other), /game_action_unavailable/);
  await assert.rejects(() => select(owner,'nameweaversQuill',1), /game_action_unavailable/);
  await assert.rejects(() => select(owner,'sparkAstrolabe'), /game_action_unavailable/);
  await db.query(`update private.canonical_game_states
    set state=jsonb_set(state,'{relicInventory,nameweaversQuill}','2') where owner_id=$1`, [owner]);
  await assert.rejects(() => select(), /game_action_unavailable/);
  await db.query(`update private.canonical_game_states
    set state=jsonb_set(state,'{untradeableRelicInventory,nameweaversQuill}','0') where owner_id=$1`, [owner]);
  assert.equal((await select()).rows[0].item.key, 'nameweaversQuill');
  for (const [role, signature, expected] of [
    ['anon','public.open_chest_instances(uuid,uuid[],integer,integer)',false],
    ['authenticated','public.open_chest_instances(uuid,uuid[],integer,integer)',true],
    ['authenticated','private.canonical_trade_asset(uuid,text,text,integer)',false],
    ['service_role','private.canonical_trade_asset(uuid,text,text,integer)',true],
    ['authenticated','private.economy_shop_catalog()',false],
    ['anon','private.economy_shop_catalog()',false],
  ]) {
    assert.equal((await db.query('select has_function_privilege($1,$2,\'execute\') as allowed',
      [role,signature])).rows[0].allowed, expected);
  }
  console.log('Relic migration: drop odds/pool, shop prices/binding, Quill trade ownership/binding, service guard and existing grants passed.');
} finally {
  await db.close();
}
