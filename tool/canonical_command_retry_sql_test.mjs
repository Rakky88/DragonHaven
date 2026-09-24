// Isolated PostgreSQL contract; never connects to a remote database.
// Usage: node tool/canonical_command_retry_sql_test.mjs
import { PGlite } from '../build/event-points-tools/package/dist/index.js';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const db = new PGlite();
const migration = readFileSync(
  'supabase/migrations/202609240098_canonical_command_retry_handoff.sql',
  'utf8',
);
const owner = '11111111-1111-4111-8111-111111111111';
const requestId = '22222222-2222-4222-8222-222222222222';
const secondRequestId = '33333333-3333-4333-8333-333333333333';
const ruleset = 'a'.repeat(64);

async function rejectedWith(statement, code, params = []) {
  let failure;
  try {
    await db.query(statement, params);
  } catch (error) {
    failure = error;
  }
  assert.ok(failure, `expected ${code}`);
  assert.match(String(failure.message), new RegExp(code));
}

await db.exec(`
  create role anon;
  create role authenticated;
  create role service_role;
  create schema auth;
  create schema private;
  create schema extensions;

  create function auth.role() returns text language sql stable as $$
    select nullif(current_setting('request.jwt.claim.role', true), '')
  $$;
  create function extensions.gen_random_bytes(p_length integer)
  returns bytea language sql volatile set search_path='' as $$
    select decode(repeat('ab', p_length), 'hex')
  $$;
  create function private.assert_game_service()
  returns void language plpgsql stable set search_path='' as $$
  begin
    if auth.role() is distinct from 'service_role' then
      raise exception 'game_service_required';
    end if;
  end
  $$;
  create function private.game_json_sha256(p_value jsonb)
  returns text language sql immutable set search_path='' as $$
    select md5(p_value::text || ':first') || md5(p_value::text || ':second')
  $$;
  create function private.consume_economy_rate_limit(uuid,text,integer,integer)
  returns void language sql set search_path='' as $$ select $$;

  create table private.game_engine_runtime(
    singleton boolean primary key,
    enabled boolean not null,
    minimum_client_build integer not null,
    ruleset_sha256 text,
    updated_at timestamptz not null default now()
  );
  create table private.canonical_game_states(
    owner_id uuid primary key,
    authority_mode text not null,
    revision bigint not null,
    state jsonb not null,
    state_sha256 text not null,
    updated_at timestamptz not null default now()
  );
  create table private.canonical_game_intents(
    owner_id uuid not null,
    request_id uuid not null,
    action text not null,
    payload jsonb not null,
    payload_sha256 text not null,
    ruleset_sha256 text not null,
    secret_seed bytea not null,
    base_revision bigint not null,
    evaluated_at timestamptz not null,
    lease_token uuid not null,
    leased_until timestamptz not null,
    status text not null default 'processing',
    response jsonb,
    failure_code text,
    created_at timestamptz not null default now(),
    completed_at timestamptz,
    social_reservations jsonb,
    social_reservations_captured boolean not null default false,
    trade_reservations jsonb,
    trade_reservations_captured boolean not null default false,
    primary key(owner_id,request_id)
  );
  create unique index canonical_game_one_pending_owner_idx
    on private.canonical_game_intents(owner_id) where status='processing';

  -- Model the deployed wrapper chain: v68 is the lease primitive, v73 adds
  -- the frozen social view, and the public entry adds the frozen trade view.
  -- Migration 098 must replace v68 without overwriting either wrapper.
  create function public.begin_canonical_game_command_v68(
    uuid,uuid,text,jsonb,integer,text
  ) returns jsonb language plpgsql security definer set search_path='' as $$
  begin
    raise exception 'old_lease_primitive';
  end
  $$;
  create function public.begin_canonical_game_command_v73(
    p_owner_id uuid,p_request_id uuid,p_action text,p_payload jsonb,
    p_client_build integer,p_ruleset_sha256 text
  ) returns jsonb language plpgsql security definer set search_path='' as $$
  declare leased jsonb; bindings jsonb; captured boolean;
  begin
    perform private.assert_game_service();
    leased:=public.begin_canonical_game_command_v68(p_owner_id,p_request_id,p_action,
      p_payload,p_client_build,p_ruleset_sha256);
    if leased->>'status'<>'processing' then return leased; end if;
    select social_reservations,social_reservations_captured into bindings,captured
      from private.canonical_game_intents
      where owner_id=p_owner_id and request_id=p_request_id;
    if not captured then
      bindings:=jsonb_build_object('version',1,'reservations',jsonb_build_array('social-sentinel'));
      update private.canonical_game_intents set social_reservations=bindings,
        social_reservations_captured=true
        where owner_id=p_owner_id and request_id=p_request_id;
    end if;
    return leased||jsonb_build_object('social_reservations',bindings);
  end
  $$;
  create function public.begin_canonical_game_command(
    p_owner_id uuid,p_request_id uuid,p_action text,p_payload jsonb,
    p_client_build integer,p_ruleset_sha256 text
  ) returns jsonb language plpgsql security definer set search_path='' as $$
  declare leased jsonb; bindings jsonb; captured boolean;
  begin
    perform private.assert_game_service();
    leased:=public.begin_canonical_game_command_v73(p_owner_id,p_request_id,p_action,
      p_payload,p_client_build,p_ruleset_sha256);
    if leased->>'status'<>'processing' then return leased; end if;
    select trade_reservations,trade_reservations_captured into bindings,captured
      from private.canonical_game_intents
      where owner_id=p_owner_id and request_id=p_request_id;
    if not captured then
      bindings:=jsonb_build_object('version',1,'reservations',jsonb_build_array('trade-sentinel'));
      update private.canonical_game_intents set trade_reservations=bindings,
        trade_reservations_captured=true
        where owner_id=p_owner_id and request_id=p_request_id;
    end if;
    return leased||jsonb_build_object('trade_reservations',bindings);
  end
  $$;
  revoke all on function
    public.begin_canonical_game_command_v68(uuid,uuid,text,jsonb,integer,text),
    public.begin_canonical_game_command_v73(uuid,uuid,text,jsonb,integer,text),
    public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text)
    from public,anon,authenticated,service_role;

  -- This models the deployed commit fence.  The retry migration must rotate
  -- the token so this function can never accept a stale worker's result.
  create function public.commit_canonical_game_command(
    p_owner_id uuid,p_request_id uuid,p_lease_token uuid,p_state jsonb,p_result jsonb
  ) returns jsonb language plpgsql security definer set search_path='' as $$
  declare intent private.canonical_game_intents%rowtype;
    game private.canonical_game_states%rowtype; receipt jsonb;
  begin
    perform private.assert_game_service();
    perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text,0));
    select * into intent from private.canonical_game_intents
      where owner_id=p_owner_id and request_id=p_request_id for update;
    if not found or intent.lease_token<>p_lease_token then
      raise exception 'game_lease_lost';
    end if;
    if intent.status='succeeded' then return intent.response; end if;
    if intent.status<>'processing' or intent.leased_until<=clock_timestamp() then
      raise exception 'game_lease_lost';
    end if;
    update private.canonical_game_states set state=p_state,revision=revision+1,
      state_sha256=private.game_json_sha256(p_state),updated_at=clock_timestamp()
      where owner_id=p_owner_id returning * into game;
    receipt:=jsonb_build_object('owner_id',p_owner_id,'request_id',p_request_id,
      'server_revision',game.revision,'state_sha256',game.state_sha256,
      'result',p_result,'authority_mode',game.authority_mode);
    update private.canonical_game_intents set status='succeeded',response=receipt,
      completed_at=clock_timestamp()
      where owner_id=p_owner_id and request_id=p_request_id;
    return receipt;
  end
  $$;

  insert into private.game_engine_runtime
    values(true,true,10102,'${ruleset}',clock_timestamp());
  insert into private.canonical_game_states(owner_id,authority_mode,revision,state,state_sha256)
    values('${owner}','server',2,'{"pet":{"coins":1}}','${'b'.repeat(64)}');
  select set_config('request.jwt.claim.role','service_role',false);
`);

await db.exec(migration);

const begin = async (id = requestId, payload = { tier: 'wooden', count: 1 }) =>
  (await db.query(
    `select public.begin_canonical_game_command(
       $1,$2,'open_chests',$3::jsonb,10102,$4
     ) as value`,
    [owner, id, JSON.stringify(payload), ruleset],
  )).rows[0].value;

const first = await begin();
assert.equal(first.status, 'processing');
assert.deepEqual(first.social_reservations, {
  version: 1,
  reservations: ['social-sentinel'],
});
assert.deepEqual(first.trade_reservations, {
  version: 1,
  reservations: ['trade-sentinel'],
});

// A transport duplicate arriving almost simultaneously is collapsed and a
// different request cannot bypass the one-pending-command invariant.
await rejectedWith(
  `select public.begin_canonical_game_command(
     $1,$2,'open_chests',$3::jsonb,10102,$4
   )`,
  'game_command_busy',
  [owner, requestId, JSON.stringify({ tier: 'wooden', count: 1 }), ruleset],
);
await rejectedWith(
  `select public.begin_canonical_game_command(
     $1,$2,'open_chests',$3::jsonb,10102,$4
   )`,
  'game_pending_command_required',
  [owner, secondRequestId, JSON.stringify({ tier: 'wooden', count: 1 }), ruleset],
);
await rejectedWith(
  `select public.begin_canonical_game_command(
     $1,$2,'open_chests',$3::jsonb,10102,$4
   )`,
  'game_idempotency_conflict',
  [owner, requestId, JSON.stringify({ tier: 'gold', count: 1 }), ruleset],
);

// Model the same request returning after the eight-second collapse window while
// its original sixty-second lease is still active.
await db.query(
  `update private.canonical_game_intents
     set leased_until=clock_timestamp()+interval '51 seconds'
     where owner_id=$1 and request_id=$2`,
  [owner, requestId],
);
const retried = await begin();
assert.equal(retried.status, 'processing');
assert.notEqual(retried.lease_token, first.lease_token);
assert.equal(retried.secret_seed, first.secret_seed);
assert.equal(retried.now, first.now);
assert.equal(retried.base_revision, first.base_revision);
assert.deepEqual(retried.social_reservations, first.social_reservations);
assert.deepEqual(retried.trade_reservations, first.trade_reservations);

await rejectedWith(
  `select public.commit_canonical_game_command($1,$2,$3,$4::jsonb,$5::jsonb)`,
  'game_lease_lost',
  [owner, requestId, first.lease_token, JSON.stringify({ pet: { coins: 2 } }), JSON.stringify({ coins: 1 })],
);
const committed = (await db.query(
  `select public.commit_canonical_game_command($1,$2,$3,$4::jsonb,$5::jsonb) as value`,
  [owner, requestId, retried.lease_token, JSON.stringify({ pet: { coins: 2 } }), JSON.stringify({ coins: 1 })],
)).rows[0].value;
assert.equal(Number(committed.server_revision), 3);

const replay = await begin();
assert.equal(replay.status, 'succeeded');
assert.equal(replay.replayed, true);
assert.deepEqual(replay.response, committed);

const privileges = (await db.query(`
  select
    has_function_privilege('anon',
      'public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text)','execute') as anon,
    has_function_privilege('authenticated',
      'public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text)','execute') as authenticated,
    has_function_privilege('service_role',
      'public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text)','execute') as service_role,
    has_function_privilege('service_role',
      'public.begin_canonical_game_command_v68(uuid,uuid,text,jsonb,integer,text)','execute') as primitive_service_role,
    pg_get_functiondef(
      'public.begin_canonical_game_command(uuid,uuid,text,jsonb,integer,text)'::regprocedure
    ) like '%begin_canonical_game_command_v73%' as trade_wrapper_preserved,
    pg_get_functiondef(
      'public.begin_canonical_game_command_v73(uuid,uuid,text,jsonb,integer,text)'::regprocedure
    ) like '%begin_canonical_game_command_v68%' as social_wrapper_preserved
`)).rows[0];
assert.deepEqual(privileges, {
  anon: false,
  authenticated: false,
  service_role: false,
  primitive_service_role: false,
  trade_wrapper_preserved: true,
  social_wrapper_preserved: true,
});

console.log('canonical_command_retry_sql_test: ok');
