// Isolated PostgreSQL contract: actual projection functions, trigger order,
// table constraints and mutation counters. Never connects to a remote database.
// Usage: node tool/canonical_projection_noop_sql_test.mjs
import { PGlite } from '../build/event-points-tools/package/dist/index.js';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
const migration = name => readFileSync(`supabase/migrations/${name}.sql`, 'utf8');
function table(sql, name) {
  const start = sql.indexOf(`create table ${name} (`);
  assert.ok(start >= 0, name);
  return sql.slice(start, sql.indexOf('\n);', start) + 3);
}
function fn(sql, name) {
  const regex = new RegExp(`create (?:or replace )?function ${name.replaceAll('.', '\\.') }\\(`);
  const match = regex.exec(sql);
  assert.ok(match, name);
  return sql.slice(match.index, sql.indexOf('$$;', sql.indexOf('$$', match.index) + 2) + 3);
}
const db = new PGlite();
try {
  await db.exec(`
    create role anon; create role authenticated; create role service_role;
    create schema auth; create schema private;
    create table auth.users(id uuid primary key,email text,email_confirmed_at timestamptz,
      raw_user_meta_data jsonb default '{}'::jsonb);
    create function auth.role() returns text language sql stable as $$
      select nullif(current_setting('request.jwt.claim.role',true),'')
    $$;
    -- The fixture needs deterministic hash equality, not pgcrypto; the remote
    -- rollback contract uses the real deployed SHA256 implementation.
    create function private.game_json_sha256(v jsonb) returns text language sql immutable as $$
      select md5(v::text)||md5(v::text)
    $$;
    create table private.canonical_game_imports(import_id uuid primary key default gen_random_uuid(),
      owner_id uuid,source_revision bigint,source_sha256 text,source_state jsonb);
    create table private.canonical_game_states(owner_id uuid primary key,authority_mode text,
      revision bigint,state jsonb,state_sha256 text,source_import_id uuid,is_prepared boolean,
      updated_at timestamptz default now());
    create table private.game_engine_runtime(singleton boolean primary key,shadow_projection_enabled boolean);
    insert into private.game_engine_runtime values(true,false);
    create table public.player_economy_authority(user_id uuid,authority_mode text);
  `);
  const base = migration('202608240001_online_social_mvp');
  await db.exec(table(base, 'public.profiles'));
  await db.exec(`alter table public.profiles drop constraint profiles_title_check,
    drop constraint profiles_portrait_key_check,alter column title set default 'title_001',
    alter column portrait_key set default 'portrait_001',add column frame_key text,add column badge_key text;`);
  await db.exec(table(base, 'public.player_wallets'));
  await db.exec(`create function private.next_keeper_code() returns text language sql as $$
    select 'DH-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8))
  $$;`);
  // The real Auth bootstrap must run: omitting it hides duplicate-profile
  // fixture bugs that only appear against the deployed schema.
  await db.exec(fn(migration('202608270017_online_account_recovery'), 'public.handle_new_user'));
  await db.exec(`create trigger on_auth_user_created after insert on auth.users
    for each row execute function public.handle_new_user();`);
  await db.exec(table(base, 'public.player_dragons'));
  await db.exec(`alter table public.player_dragons add column canonical_owned boolean not null default true;
    create unique index player_dragons_one_favorite_per_owner
      on public.player_dragons(owner_id) where favorite;`);
  await db.exec(table(base, 'public.social_showcases'));
  for (const name of ['202608250008_trial_high_scores', '202608260011_friend_draconomicon',
    '202608260016_social_summary_counts']) {
    const text = migration(name);
    await db.exec(text.slice(0, text.indexOf('create or replace function')));
  }
  const baseSocial = migration('202609100068_canonical_social_projection');
  await db.exec(table(baseSocial, 'private.canonical_social_projections'));
  await db.exec(fn(migration('202609070052_canonical_game_commands'), 'private.assert_game_service'));
  await db.exec(fn(baseSocial, 'private.guard_canonical_social_write'));
  for (const name of ['player_dragons', 'player_wallets', 'social_showcases']) {
    await db.exec(`create trigger canonical_social_write before insert or update or delete on public.${name}
      for each row execute function private.guard_canonical_social_write();`);
  }
  await db.exec(fn(migration('202609200093_canonical_unnamed_hatch'), 'private.project_canonical_social_state'));
  await db.exec(fn(baseSocial, 'private.canonical_social_projection_changed'));
  await db.exec(`create trigger canonical_social_projection_changed
    after insert or update of state,revision,is_prepared,authority_mode on private.canonical_game_states
    for each row execute function private.canonical_social_projection_changed();`);
  const identity = migration('202609200090_canonical_profile_identity');
  await db.exec(fn(identity, 'private.project_canonical_profile_identity'));
  await db.exec(`create trigger zz_canonical_profile_identity after insert or update on private.canonical_game_states
    for each row execute function private.project_canonical_profile_identity();`);
  const trials = migration('202609240097_standard_trial_rotation');
  await db.exec(trials.slice(0, trials.indexOf('-- Backfill')));
  const signatures = [
    'private.project_canonical_social_state(uuid,jsonb,bigint,text,timestamptz)',
    'private.project_canonical_profile_identity()', 'private.project_standard_trial_bests()',
  ];
  for (const signature of signatures) {
    await db.exec(`revoke all on function ${signature} from public,anon,authenticated,service_role;`);
  }
  const grants = async () => (await db.query(`select oid::regprocedure::text as function,proacl::text
    from pg_proc where oid=any($1::regprocedure[]) order by 1`, [signatures])).rows;
  const before = await grants();
  const contract = readFileSync('tool/canonical_projection_noop_contract.sql', 'utf8');
  // Measure the same 27-dragon fixture on the previous deployed implementation.
  const baseline = contract.slice(0, contract.indexOf('  -- Only the changed dragon'))
    .replace('perform pg_temp.assert_projection_writes(0,0,1);',
      'perform pg_temp.assert_projection_writes(54,3,1);')
    + '\nend $contract$; rollback; select true as baseline_passed;';
  assert.equal((await db.exec(baseline)).at(-1).rows[0].baseline_passed, true);
  await db.exec(migration('202609270102_canonical_projection_noop_writes'));
  assert.deepEqual(await grants(), before, 'function ACLs must stay byte-for-byte identical');
  assert.equal((await db.exec(contract)).at(-1).rows[0].canonical_projection_noop_contract_passed, true);
  assert.equal((await db.query('select count(*)::int as n from auth.users')).rows[0].n, 0);
  console.log('Projection contract passed: unrelated revision 57 -> 0 dragon/showcase row writes (27 dragons); wallet revision retained.');
  console.log('Changed fields, unique favorites, six score fields, counts, release/restore UUID, null name, spectral, replay, hash/revision/service fences and ACLs passed; fixtures rolled back.');
} finally {
  await db.close();
}
