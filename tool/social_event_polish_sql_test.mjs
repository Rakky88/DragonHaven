// Isolated PostgreSQL regression checks; never connects to a remote database.
import { PGlite } from '../build/event-points-tools/package/dist/index.js';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
const db = new PGlite();
const read = path => readFileSync(`supabase/migrations/${path}`, 'utf8');
const section = (source, start, end) => source.slice(source.indexOf(start), source.indexOf(end));
const base = readFileSync('tool/event_points_sql_test.mjs', 'utf8');
await db.exec(section(base, '  create role anon;', '`);'));
await db.exec(read('202609120080_event_points.sql'));
await db.exec(`
  create schema cron;
  create table cron.jobs(name text,schedule text,command text);
  create function cron.schedule(text,text,text) returns bigint language sql as
    $$ insert into cron.jobs values($1,$2,$3) returning 1::bigint $$;
  alter table profiles add column display_name text default 'Keeper',add column title text default 'title_001',
    add column portrait_key text default 'portrait_001',add column frame_key text,add column badge_key text;
  create table seasonal_event_previews(user_id uuid,event_id text,activated_at timestamptz default now(),expires_at timestamptz);
  create table social_notifications(user_id uuid,kind text,actor_id uuid,entity_id uuid);
  create table conclave_members(user_id uuid,conclave_id uuid);
  create table conclave_messages(id uuid primary key default gen_random_uuid(),conclave_id uuid,sender_id uuid,
    kind text,body text,payload jsonb,created_at timestamptz default now());
  create table player_wallets(owner_id uuid);
  create function private.assert_legacy_inventory_authority() returns void language plpgsql as $$ begin
    if auth.uid() is null then raise exception 'online_login_required'; end if; end $$;
  create function private.cleanup_ephemeral_social_content() returns void language sql as $$ select $$;
  create function get_trial_rankings(text,text,integer) returns table(ranking_position bigint,entry_key text,
    display_name text,title text,portrait_key text,frame_key text,badge_key text,score bigint,is_current_user boolean)
    language sql as $$ select 1::bigint,'regular','Regular Keeper','title_001','portrait_001',null::text,null::text,1234::bigint,true $$;
  create table seasonal_trial_bests(event_id text,occurrence_key text,user_id uuid,score bigint,
    accuracy_permille integer,duration_ms bigint,achieved_at timestamptz,preview boolean);
`);
const seasonal = read('202609070040_seasonal_events.sql');
await db.exec(section(seasonal, 'create table if not exists public.seasonal_pair_adventures', 'create or replace function public.invite_seasonal_pair_adventure'));
await db.exec(section(seasonal, 'create or replace function public.respond_seasonal_pair_adventure', 'create or replace function public.start_seasonal_pair_adventure'));
await db.exec(`alter table seasonal_pair_adventures add column canonical_owned boolean default false;
  alter function respond_seasonal_pair_adventure(uuid,boolean,text,integer,integer,integer) rename to respond_seasonal_pair_adventure_v68;`);
const chat = read('202609090065_seasonal_podium_chat.sql');
await db.exec(chat.slice(chat.indexOf('create or replace function public.send_conclave_message')));
await db.exec(section(seasonal, 'create table if not exists public.seasonal_trial_attempts', 'create table if not exists public.seasonal_trial_bests'));
await db.exec(`alter table seasonal_trial_attempts add column conclave_id uuid;
  alter table private.canonical_game_states add column revision bigint default 0,add column updated_at timestamptz default now();
  create table private.game_engine_runtime(singleton boolean,shadow_projection_enabled boolean);
  create table seasonal_event_dismissals(user_id uuid,event_id text,expires_at timestamptz);`);
const canonical = read('202609100076_canonical_seasonal_trials.sql');
await db.exec(canonical.slice(0,canonical.indexOf('create function private.canonical_seasonal_state_changed()')));
await db.exec(read('202609120081_social_event_polish.sql'));

const owners = [1,2,3].map(n => `${String(n).repeat(8)}-1111-4111-8111-111111111111`);
const cid = 'aaaaaaaa-1111-4111-8111-111111111111';
for (const [i,owner] of owners.entries()) {
  await db.query('insert into auth.users values($1,now())',[owner]);
  await db.query('insert into profiles(user_id,keeper_code,display_name) values($1,$2,$3)',[owner,`DH-0000000${i+1}`,`Keeper ${i+1}`]);
}
const auth = async owner => db.query("select set_config('request.jwt.claim.sub',$1,false)",[owner]);
await auth(owners[0]);
await db.query('insert into conclave_members values($1,$3),($2,$3)',[owners[0],owners[1],cid]);
await db.query("insert into friendships values($1,$2,'accepted')",[owners[0],owners[1]]);
const event = 'valentine_two_heartlights';
await db.query("insert into seasonal_event_previews values($1,$2,now()-interval '1 hour',now()+interval '1 hour')",[owners[0],event]);
async function pair(creator=owners[0],partner=owners[1]) {
  return (await db.query(`insert into seasonal_pair_adventures(occurrence_key,creator_id,partner_id,creator_dragon_id,
    creator_might,creator_arcana,creator_spirit,simulated) values($1,$2,$3,'dragon',10,10,10,true) returning id`,
    [`preview:${event}:${creator}`,creator,partner])).rows[0].id;
}
const pending = await pair();
await auth(owners[2]);
await assert.rejects(() => db.query('select respond_seasonal_pair_adventure($1,false)',[pending]),/seasonal_pair_not_found/);
await auth(owners[0]);
await db.query('select respond_seasonal_pair_adventure($1,false)',[pending]);
await db.query('select respond_seasonal_pair_adventure($1,false)',[pending]);
assert.equal((await db.query('select status from seasonal_pair_adventures where id=$1',[pending])).rows[0].status,'declined');
const expired = await pair();
const running = await pair();
await db.query("update seasonal_pair_adventures set invitation_expires_at=now()-interval '1 second' where id in ($1,$2)",[expired,running]);
await db.query("update seasonal_pair_adventures set status='running',ends_at=now()+interval '1 day' where id=$1",[running]);
await db.query('select private.expire_event_invitations()');
assert.equal((await db.query('select status from seasonal_pair_adventures where id=$1',[expired])).rows[0].status,'declined');
assert.equal((await db.query('select status from seasonal_pair_adventures where id=$1',[running])).rows[0].status,'running');
await auth(owners[1]);
await assert.rejects(() => db.query("select respond_seasonal_pair_adventure($1,true,'partner',10,10,10)",[expired]),/seasonal_pair_not_pending/);
assert.equal((await db.query('select count(*)::int n from list_my_seasonal_pair_adventures()')).rows[0].n,1);

const key = `${event}:year:2030`;
for (const owner of owners.slice(0,2)) {
  await db.query('insert into cloud_game_saves values($1,$2)',[owner,{eventProgress:{[key]:{
    eventId:event,key,points:1000,target:2000,partnerPoints:0,
    startsAt:new Date(Date.now()-3600000).toISOString(),endsAt:new Date(Date.now()+3600000).toISOString()}}}]);
}
await auth(owners[0]);
const invite = async () => (await db.query("select event_point_partner('invite',$1,'DH-00000002') value",[key])).rows[0].value.pairs[0].id;
let pointPair = await invite();
await db.query("select event_point_partner('cancel',null,null,$1)",[pointPair]);
assert.equal((await db.query('select count(*)::int n from private.event_point_pair_members')).rows[0].n,0);
pointPair = await invite();
await db.query("update private.event_point_pairs set ends_at=now()-interval '1 second' where id=$1",[pointPair]);
await db.query('select event_point_partner()');
assert.equal((await db.query('select status from private.event_point_pairs where id=$1',[pointPair])).rows[0].status,'declined');
assert.equal((await db.query('select count(*)::int n from private.event_point_pair_members')).rows[0].n,0);

// Retrying a delivered message does not insert it twice, even after chat expiry.
const receipt = 'bbbbbbbb-1111-4111-8111-111111111111';
const send = body => db.query("select send_conclave_message('text',$1,$2) id",[body,{client_message_id:receipt}]);
const first = (await send('Hello')).rows[0].id;
assert.equal((await send('Hello')).rows[0].id,first);
await assert.rejects(() => send('Changed message'),/message_invalid/);
await db.exec('delete from conclave_messages');
assert.equal((await send('Hello')).rows[0].id,first);
assert.equal((await db.query('select count(*)::int n from conclave_messages')).rows[0].n,0);

const window = (await db.query("select * from seasonal_event_window('new_year_first_dawn','2027-01-02')")).rows[0];
assert.equal(new Date(window.ends_at).toISOString(),'2027-01-06T23:00:00.000Z');
assert.equal(new Date(window.results_end_at)-new Date(window.ends_at),3*86400000);
assert.match((await db.query("select pg_get_functiondef('purchase_vanity_chest(uuid,text,integer,integer)'::regprocedure) source")).rows[0].source,/coins'::text, 500, 'title'/);

// Only the scheduled window is injected for date-independent scope/boundary tests.
await db.exec(`create table test_window(starts timestamptz,ends timestamptz);
  insert into test_window values(now()-interval '1 day',now()+interval '1 day');
  create or replace function seasonal_event_window(p_event_id text,p_now timestamptz default now())
  returns table(occurrence_key text,starts_at timestamptz,ends_at timestamptz,results_end_at timestamptz)
  language sql stable as $$ select p_event_id||':2030',starts,ends,ends+interval '3 days' from public.test_window $$;
  delete from seasonal_event_previews;`);
for (const [i,owner] of owners.entries()) {
  await db.query('insert into seasonal_trial_bests values($1,$2,$3,$4,$5,10000,now(),false)',
    [event,`${event}:2030`,owner,i===2?3000:2000,i===0?500:1000]);
}
const rankings = async scope => (await db.query("select * from get_trial_rankings('rosevowRelay',$1)",[scope])).rows;
assert.deepEqual((await rankings('world')).map(r => [r.score,Number(r.ranking_position)]),[[3000,1],[2000,2],[2000,2]]);
assert.equal((await rankings('friends')).length,2);
assert.equal((await rankings('conclave')).length,2);
await db.exec("update test_window set ends=now()-interval '2 days'");
assert.equal((await rankings('world')).length,3);
await db.exec("update test_window set ends=now()-interval '3 days'");
assert.equal((await rankings('world')).length,0);
assert.equal((await db.query("select score from get_trial_rankings('cavernFlight','world')")).rows[0].score,1234);
assert.equal((await db.query("select has_function_privilege('anon','send_conclave_message(text,text,jsonb)','execute') allowed")).rows[0].allowed,false);
assert.equal((await db.query("select has_function_privilege('authenticated','private.expire_event_invitations()','execute') allowed")).rows[0].allowed,false);
assert.equal((await db.query("select count(*)::int n from cron.jobs where name='dragonhaven-event-invitation-expiry'")).rows[0].n,1);
// Real canonical activation trigger accepts stable launch/year keys and rejects a wrong occurrence.
await db.exec(`create trigger canonical_seasonal_state_changed after insert on private.canonical_game_states
  for each row execute function private.canonical_seasonal_state_changed();
  update test_window set starts=now()-interval '1 day',ends=now()+interval '1 day';`);
for (const [i,owner] of owners.entries()) {
  const state = {_activeGameAttempt:{type:'trial',gameId:'rosevowRelay',offerId:`offer-${i}`,seed:42,
    specialEventKey:`${event}:${i===0?'launch':'year'}:${i===2?2020:2030}`,
    startedAt:new Date().toISOString(),expiresAt:new Date(Date.now()+3600000).toISOString()}};
  const activate = () => db.query("insert into private.canonical_game_states(owner_id,state,is_prepared,authority_mode) values($1,$2,true,'server')",[owner,state]);
  if (i===2) await assert.rejects(activate,/game_seasonal_binding_invalid/);
  else await activate();
}
assert.equal((await db.query('select count(*)::int n from seasonal_trial_attempts where canonical_owned')).rows[0].n,2);
console.log('PASS: migration 81; cancellation/expiry, live runs retained, message receipts, raw score ties/scopes, three-day cutoff, 500-gold price and private grants.');
await db.close();
