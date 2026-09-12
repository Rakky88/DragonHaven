begin;
do $$ declare w record; y integer; begin
for y in 2026..2029 loop
select * into w from public.seasonal_event_window('christmas_winter_hearth',make_timestamptz(y,12,24,12,0,0,'Europe/Amsterdam'));
if w.starts_at is distinct from make_timestamptz(y,12,20,0,0,0,'Europe/Amsterdam') or w.ends_at is distinct from make_timestamptz(y,12,27,0,0,0,'Europe/Amsterdam') or w.results_end_at is distinct from w.ends_at+interval '3 days' then raise exception 'Christmas boundary mismatch'; end if;
end loop;
for y in 2027..2030 loop
select * into w from public.seasonal_event_window('valentine_two_heartlights',make_timestamptz(y,2,14,12,0,0,'Europe/Amsterdam'));
if w.starts_at is distinct from make_timestamptz(y,2,12,0,0,0,'Europe/Amsterdam') or w.ends_at is distinct from make_timestamptz(y,2,17,0,0,0,'Europe/Amsterdam') or w.results_end_at is distinct from w.ends_at+interval '3 days' then raise exception 'Valentine boundary mismatch'; end if;
end loop;
end $$;
rollback;
select true as extended_event_windows_passed;
