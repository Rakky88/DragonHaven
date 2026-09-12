// Isolated PostgreSQL contract. Usage: node tool/event_points_sql_test.mjs
// Uses the locally staged @electric-sql/pglite package; no external database.
import { PGlite } from '../build/event-points-tools/package/dist/index.js';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
const db = new PGlite();
await db.exec(`
  create role anon; create role authenticated; create role service_role;
  create schema auth; create schema private;
  create table auth.users(id uuid primary key, email_confirmed_at timestamptz);
  create function auth.uid() returns uuid language sql stable as
    $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
  create table public.profiles(user_id uuid primary key,keeper_code text);
  create table public.friendships(requester_id uuid,addressee_id uuid,status text);
  create table public.cloud_game_saves(user_id uuid primary key,state jsonb);
  create table private.canonical_game_states(owner_id uuid primary key,state jsonb,is_prepared boolean,authority_mode text);
  create function private.assert_game_service() returns void language plpgsql as $$ begin return; end $$;
  create function private.canonical_social_claim_offers(uuid,timestamptz) returns jsonb language sql as $$ select '[]'::jsonb $$;
  create function public.read_canonical_game_state(uuid,integer,text) returns jsonb language sql as $$ select '{}'::jsonb $$;
  create function public.begin_revisioned_game_command(uuid,uuid,text,jsonb,integer,text,bigint)
    returns jsonb language sql as $$ select '{"status":"processing"}'::jsonb $$;
`);
await db.exec(readFileSync('supabase/migrations/202609120080_event_points.sql','utf8'));
await db.exec(readFileSync('supabase/migrations/202609120082_extended_event_windows.sql','utf8'));
await db.exec('alter function public.event_point_partner(text,text,text,uuid) rename to event_point_partner_v80');
await db.exec(readFileSync('supabase/migrations/202609120083_event_claim_partner_windows.sql','utf8'));
await db.exec(`create function public.event_point_partner(p_action text default 'list',p_event_key text default null,
  p_keeper_code text default null,p_pair_id uuid default null) returns jsonb language sql security definer set search_path='' as
  $$ select public.event_point_partner_v80(p_action,p_event_key,p_keeper_code,p_pair_id) $$;
  revoke all on function public.event_point_partner(text,text,text,uuid) from public,anon;
  grant execute on function public.event_point_partner(text,text,text,uuid) to authenticated;`);
const owners = ['11111111','22222222','33333333'].map(x => `${x}-1111-4111-8111-111111111111`);
let key = 'valentine_two_heartlights:year:2030';
const now = Date.now();
function progress(points) { return {eventId:'valentine_two_heartlights',key,
  startsAt:new Date(now-3600000).toISOString(), endsAt:new Date(now+3600000).toISOString(),
  target:2000,chestId:'twinheart_keepsake_chest_v1',points,partnerPoints:0,claimed:false,preview:false}; }
for (const [i,owner] of owners.entries()) {
  await db.query('insert into auth.users values($1,now())',[owner]);
  await db.query('insert into public.profiles values($1,$2)',[owner,`DH-0000000${i+1}`]);
  await db.query('insert into public.cloud_game_saves values($1,$2)',[owner,{eventProgress:{[key]:progress(i===0?750:1250)}}]);
}
await db.query(`insert into public.friendships values($1,$2,'accepted'),($1,$3,'accepted'),($2,$3,'accepted')`,owners);
async function as(owner,action='list',code=null,id=null) {
  await db.query("select set_config('request.jwt.claim.sub',$1,false)",[owner]);
  return (await db.query('select public.event_point_partner($1,$2,$3,$4) as result',[action,key,code,id])).rows[0].result;
}
async function rejects(fn,code) { await assert.rejects(fn,e => e.message.includes(code)); }
const invitation = await as(owners[0],'invite','DH-00000002');
const id = invitation.pairs[0].id;
assert.equal(invitation.shared.progress.length,0);
assert.equal((await as(owners[1])).pairs[0].incoming,true);
await rejects(() => as(owners[2],'accept',null,id),'event_invitation_unavailable');
await rejects(() => as(owners[2],'invite','DH-00000002'),'event_partner_already_selected');
const accepted = await as(owners[1],'accept',null,id);
assert.equal(accepted.shared.progress[0].partnerPoints,750);
assert.equal((await as(owners[0])).shared.progress[0].partnerPoints,1250);
await rejects(() => as(owners[0],'cancel',null,id),'event_invitation_unavailable');
await rejects(() => as(owners[0],'invite','DH-00000003'),'event_partner_already_selected');
await db.query(`update public.cloud_game_saves set state=jsonb_set(state,array['eventProgress',$2,'points'],'1275') where user_id=$1`,[owners[1],key]);
assert.equal((await as(owners[0])).shared.progress[0].partnerPoints,1275);
// Closing does not destroy the bond or the earned reward evidence.
await db.exec("update private.event_point_pairs set ends_at=now()-interval '1 day'");
assert.equal((await as(owners[0])).shared.progress[0].partnerPoints,1275);
const windows = await db.query(`select * from public.seasonal_event_window('new_year_first_dawn','2027-01-01T00:00:00Z')`);
assert.equal(new Date(windows.rows[0].starts_at).toISOString(),'2026-12-31T23:00:00.000Z');
assert.equal(new Date(windows.rows[0].ends_at).toISOString(),'2027-01-06T23:00:00.000Z');
assert.equal((await db.query("select * from public.seasonal_event_window('new_year_first_dawn','2026-01-01')")).rows.length,0);
assert.equal((await db.query("select has_function_privilege('anon','public.event_point_partner(text,text,text,uuid)','execute') as allowed")).rows[0].allowed,false);
assert.equal((await db.query("select has_function_privilege('authenticated','private.event_partner_progress(uuid)','execute') as allowed")).rows[0].allowed,false);
// Decline releases both reserved slots.
await db.exec('delete from private.event_point_pairs');
const declined = await as(owners[0],'invite','DH-00000002');
await as(owners[1],'decline',null,declined.pairs[0].id);
assert.equal((await db.query('select count(*)::int as n from private.event_point_pair_members')).rows[0].n,0);
await db.query(`update public.cloud_game_saves set state=jsonb_set(jsonb_set(state,array['eventProgress',$2,'points'],'2000'),array['eventProgress',$2,'claimed'],'true') where user_id=$1`,[owners[0],key]);
const afterClaim = await as(owners[0],'invite','DH-00000003');
assert.equal((await as(owners[2],'accept',null,afterClaim.pairs[0].id)).shared.progress[0].partnerPoints,2000);
for (const [id, firstYear, month, startDay, endDay] of [
  ['christmas_winter_hearth',2026,12,20,27],
  ['valentine_two_heartlights',2027,2,12,17],
]) {
  for (const year of [firstYear,firstYear+1,firstYear+2]) {
    const row=(await db.query('select * from public.seasonal_event_window($1,$2)',[id,`${year}-${month}-15T12:00:00Z`])).rows[0];
    assert.equal(new Date(row.starts_at).toISOString(),new Date(Date.UTC(year,month-1,startDay-1,23)).toISOString());
    assert.equal(new Date(row.ends_at).toISOString(),new Date(Date.UTC(year,month-1,endDay-1,23)).toISOString());
    assert.equal(new Date(row.results_end_at)-new Date(row.ends_at),3*86400000);
  }
}
// Independently activated previews use each member's own progress key.
await db.exec('delete from private.event_point_pairs');
const previewKeys=owners.map((_,i)=>`valentine_two_heartlights:preview:${now+i}`);
for (const [i,owner] of owners.entries()) {
  const p={...progress(100+i*50),key:previewKeys[i],preview:true};
  await db.query('update public.cloud_game_saves set state=$2 where user_id=$1',
    [owner,{eventProgress:{[previewKeys[i]]:p}}]);
}
key=previewKeys[0];
const previewInvite=await as(owners[0],'invite','DH-00000002');
key=previewKeys[1];
const incoming=await as(owners[1]);
assert.equal(incoming.pairs[0].eventKey,previewKeys[1]);
assert.equal(incoming.pairs[0].incoming,true);
const combined=await as(owners[1],'accept',null,previewInvite.pairs[0].id);
assert.equal(combined.shared.progress[0].key,previewKeys[1]);
assert.equal(combined.shared.progress[0].points,150);
assert.equal(combined.shared.progress[0].partnerPoints,100);
assert.equal((await as(owners[0])).shared.progress[0].partnerPoints,150);
key=previewKeys[2];
await rejects(()=>as(owners[2],'invite','DH-00000002'),'event_partner_already_selected');
console.log('PASS: distinct preview keys, incoming visibility, own points retained, shared totals and one-partner reservation.');
console.log('PASS: isolated PostgreSQL migration, invitation acceptance/decline, one partner, existing/future totals, post-close retention, New Year dates, private grants.');
await db.close();
