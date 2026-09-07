-- One explicitly authorized production support action, not a schema migration.
-- Never modify a real player's save, adventure timer or reward acknowledgement.
begin;
do $verify$
begin
  if not exists(select 1 from public.group_adventure_lobbies l join public.profiles p
    on p.user_id=l.owner_id where l.id='2abfc0ab-e313-466a-9a64-11346dfcdc29'
    and p.keeper_code='DH-4132F5C7') then
    raise exception 'approved_lobby_missing';
  end if;
end $verify$;
-- Correct the fixture's artwork identifier only; expertise/timing stay intact.
update public.player_dragons d set lineage_id='thunderpuff'
from auth.users u where u.id=d.owner_id
  and u.raw_app_meta_data->>'dragonhaven_companions'='companions-4132f5c7-20260907'
  and d.legacy_client_id in ('companion-love','companion-kisses','companion-hugs')
  and d.lineage_id='moon';
select cron.schedule('dh-companions-4132f5c7-cleanup', '23 * * * *', $job$
do $cleanup$
declare approved_ids uuid[] := array[
  '7cd4b46e-d7ed-46f2-b29b-8a00b0b8df10'::uuid,
  'dee9d03e-3400-40b6-a989-b04d7b7a8c2e'::uuid,
  'cc0f27c0-c914-46cb-b5c5-f1d4209b172b'::uuid];
begin
  -- Match both independently recorded IDs and private administrator metadata.
  perform 1 from public.group_adventure_lobbies
    where id='2abfc0ab-e313-466a-9a64-11346dfcdc29' for update;
  if exists(select 1 from public.group_adventure_lobbies l
    where l.id='2abfc0ab-e313-466a-9a64-11346dfcdc29'
    and l.owner_id='55e93ae4-a734-433c-a126-0edb303cb33e'
    and l.status='completed' and l.ends_at<=now()
    and not exists(select 1 from public.group_adventure_participants p
      where p.lobby_id=l.id and not(p.user_id=any(approved_ids))
      and p.reward_acknowledged_at is null)) then
    delete from auth.users u where u.id=any(approved_ids)
      and u.raw_app_meta_data->>'dragonhaven_companions'='companions-4132f5c7-20260907'
      and u.email like '%@dragonhaven-companions.invalid'
      and not exists(select 1 from public.group_adventure_participants p
        join public.group_adventure_lobbies l on l.id=p.lobby_id
        where p.user_id=u.id and l.id<>'2abfc0ab-e313-466a-9a64-11346dfcdc29'
        and (l.status<>'completed' or p.reward_acknowledged_at is null));
  end if;
  if not exists(select 1 from auth.users where id=any(approved_ids)) then
    perform cron.unschedule('dh-companions-4132f5c7-cleanup');
  end if;
end $cleanup$;
$job$);
commit;
