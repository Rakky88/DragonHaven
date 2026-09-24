// Isolated PostgreSQL contract; never connects to a remote database.
// Usage: node tool/standard_trial_rotation_sql_test.mjs
import { PGlite } from '../build/event-points-tools/package/dist/index.js';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const db = new PGlite();
const migration = readFileSync(
  'supabase/migrations/202609240097_standard_trial_rotation.sql',
  'utf8',
);
const owners = [
  '11111111-1111-4111-8111-111111111111',
  '22222222-2222-4222-8222-222222222222',
];
const hashes = ['a'.repeat(64), 'b'.repeat(64)];
const numericScores = (row) =>
  Object.fromEntries(
    Object.entries(row).map(([key, value]) => [key, Number(value)]),
  );

await db.exec(`
  create role anon;
  create role authenticated;
  create role service_role;
  create schema auth;
  create schema private;
  create function auth.uid() returns uuid language sql stable as $$
    select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
  $$;
  create function auth.role() returns text language sql stable as $$
    select nullif(current_setting('request.jwt.claim.role', true), '')
  $$;

  create table public.profiles(
    user_id uuid primary key,
    display_name text not null,
    title text,
    portrait_key text,
    frame_key text,
    badge_key text
  );
  create table public.friendships(
    requester_id uuid not null,
    addressee_id uuid not null,
    status text not null
  );
  create table public.conclave_members(
    user_id uuid not null,
    conclave_id uuid not null
  );
  create table public.player_economy_authority(
    user_id uuid primary key,
    authority_mode text not null
  );
  create table public.social_showcases(
    user_id uuid primary key,
    cavern_flight_best bigint not null default 0,
    ruin_breaker_best bigint not null default 0,
    runeweaver_best bigint not null default 0
  );
  create table private.canonical_game_states(
    owner_id uuid primary key,
    state jsonb not null,
    revision bigint not null,
    state_sha256 text not null
  );
  create table private.canonical_social_projections(
    owner_id uuid primary key,
    revision bigint not null,
    state_sha256 text not null,
    updated_at timestamptz not null default now()
  );

  create function private.guard_canonical_social_write()
  returns trigger language plpgsql security definer set search_path='' as $$
  begin
    if coalesce(auth.role(), '') = 'service_role' then return new; end if;
    if exists(
      select 1 from public.player_economy_authority
      where user_id = new.user_id and authority_mode = 'server'
    ) then
      raise exception 'economy_server_inventory_required';
    end if;
    return new;
  end
  $$;
  create trigger canonical_showcase_write
    before update on public.social_showcases
    for each row execute function private.guard_canonical_social_write();

  -- Models the already-deployed dispatcher. Migration 097 must preserve it,
  -- because it owns seasonal windows/previews as well as the classic Trials.
  create function public.get_trial_rankings(text,text,integer default 100)
  returns table(
    ranking_position bigint,
    entry_key text,
    display_name text,
    title text,
    portrait_key text,
    frame_key text,
    badge_key text,
    score bigint,
    is_current_user boolean
  ) language sql stable security definer set search_path='' as $$
    select 7::bigint, 'seasonal-sentinel', 'Seasonal Keeper', null::text,
      null::text, null::text, null::text, 777::bigint, true
  $$;
`);

for (const [index, owner] of owners.entries()) {
  const best = index === 0 ? 321 : 654;
  const state = {
    pet: {
      id: `pet-${index}`,
      stage: 'ascended',
      trialHighScores: {
        spiritAlignment: best,
        ruinGuard: best - 1,
        runeOrbit: 10 + index,
      },
    },
    sanctuaryDragons: [],
  };
  await db.query(
    `insert into public.profiles(user_id,display_name)
       values($1,$2)`,
    [owner, `Keeper ${index + 1}`],
  );
  await db.query(
    `insert into public.player_economy_authority values($1,'server')`,
    [owner],
  );
  await db.query(`insert into public.social_showcases(user_id) values($1)`, [
    owner,
  ]);
  await db.query(
    `insert into private.canonical_game_states values($1,$2,$3,$4)`,
    [owner, JSON.stringify(state), 1, hashes[index]],
  );
  await db.query(
    `insert into private.canonical_social_projections(owner_id,revision,state_sha256)
       values($1,1,$2)`,
    [owner, hashes[index]],
  );
}

await db.exec(migration);
// Migration files normally execute once, but a rehearsal/recovery rerun must
// retain the original dispatcher instead of wrapping the new wrapper again.
await db.exec(migration);

// The migration-time repair must cross the canonical write fence and restore
// the previous claim afterwards.
const restoredRole = await db.query(
  `select current_setting('request.jwt.claim.role', true) as role`,
);
assert.equal(restoredRole.rows[0].role, '');
const backfill = await db.query(
  `select spirit_alignment_best,ruin_guard_best,rune_orbit_best
     from public.social_showcases where user_id=$1`,
  [owners[1]],
);
assert.deepEqual(numericScores(backfill.rows[0]), {
  spirit_alignment_best: 654,
  ruin_guard_best: 653,
  rune_orbit_best: 11,
});

await db.query(`select set_config('request.jwt.claim.sub',$1,false)`, [owners[0]]);
await db.query(
  `select set_config('request.jwt.claim.role','authenticated',false)`,
);
const standard = await db.query(
  `select ranking_position,display_name,score,is_current_user
     from public.get_trial_rankings('spiritAlignment','world',100)`,
);
assert.deepEqual(
  standard.rows.map((row) => ({
    ...row,
    ranking_position: Number(row.ranking_position),
    score: Number(row.score),
  })),
  [
  {
    ranking_position: 1,
    display_name: 'Keeper 2',
    score: 654,
    is_current_user: false,
  },
  {
    ranking_position: 2,
    display_name: 'Keeper 1',
    score: 321,
    is_current_user: true,
  },
  ],
);

const seasonal = await db.query(
  `select entry_key,score
     from public.get_trial_rankings('rosevowRelay','world',100)`,
);
assert.deepEqual(
  seasonal.rows.map((row) => ({ ...row, score: Number(row.score) })),
  [{ entry_key: 'seasonal-sentinel', score: 777 }],
);

const privileges = await db.query(`
  select
    has_function_privilege(
      'authenticated',
      'public.get_trial_rankings(text,text,integer)',
      'execute'
    ) as authenticated_wrapper,
    has_function_privilege(
      'anon',
      'public.get_trial_rankings(text,text,integer)',
      'execute'
    ) as anon_wrapper,
    has_function_privilege(
      'authenticated',
      'public.get_trial_rankings_v96(text,text,integer)',
      'execute'
    ) as authenticated_legacy,
    has_function_privilege(
      'service_role',
      'public.get_trial_rankings_v96(text,text,integer)',
      'execute'
    ) as service_legacy
`);
assert.deepEqual(privileges.rows[0], {
  authenticated_wrapper: true,
  anon_wrapper: false,
  authenticated_legacy: false,
  service_legacy: false,
});

// A later canonical projection must replace all three maxima atomically.
await db.query(
  `select set_config('request.jwt.claim.role','service_role',false)`,
);
const nextState = {
  pet: {
    id: 'pet-0',
    stage: 'ascended',
    trialHighScores: {
      spiritAlignment: 999,
      ruinGuard: 888,
      runeOrbit: 77,
    },
  },
  sanctuaryDragons: [],
};
await db.query(
  `update private.canonical_game_states
      set state=$2,revision=2,state_sha256=$3 where owner_id=$1`,
  [owners[0], JSON.stringify(nextState), 'c'.repeat(64)],
);
await db.query(
  `update private.canonical_social_projections
      set revision=2,state_sha256=$2 where owner_id=$1`,
  [owners[0], 'c'.repeat(64)],
);
const projected = await db.query(
  `select spirit_alignment_best,ruin_guard_best,rune_orbit_best
     from public.social_showcases where user_id=$1`,
  [owners[0]],
);
assert.deepEqual(numericScores(projected.rows[0]), {
  spirit_alignment_best: 999,
  ruin_guard_best: 888,
  rune_orbit_best: 77,
});

console.log('standard_trial_rotation_sql_test: ok');
