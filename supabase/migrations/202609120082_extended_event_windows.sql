-- Extend annual point-event windows; existing claimed rewards and preview windows remain intact.
create or replace function public.seasonal_event_window(
  p_event_id text,
  p_now timestamptz default now()
)
returns table (
  occurrence_key text,
  starts_at timestamptz,
  ends_at timestamptz,
  results_end_at timestamptz
)
language plpgsql
set search_path = ''
stable
as $$
declare
  local_now timestamp := p_now at time zone 'Europe/Amsterdam';
  event_year integer := extract(year from local_now)::integer;
  local_start timestamp;
  local_end timestamp;
begin
  if p_event_id = 'golden_wings_birthday' then
    if event_year < 2026 then return; end if;
    if event_year = 2026 then
      local_start := make_timestamp(2026, 9, 1, 0, 0, 0);
      local_end := make_timestamp(2026, 9, 3, 0, 0, 0);
    else
      local_start := make_timestamp(event_year, 5, 13, 0, 0, 0);
      local_end := make_timestamp(event_year, 5, 14, 0, 0, 0);
    end if;
  elsif p_event_id = 'halloween_witchlight' then
    local_start := make_timestamp(event_year, 10, 25, 0, 0, 0);
    local_end := make_timestamp(event_year, 11, 2, 0, 0, 0);
  elsif p_event_id = 'christmas_winter_hearth' then
    local_start := make_timestamp(event_year, 12, 20, 0, 0, 0);
    local_end := make_timestamp(event_year, 12, 27, 0, 0, 0);
  elsif p_event_id = 'new_year_first_dawn' then
    if event_year < 2027 then return; end if;
    local_start := make_timestamp(event_year, 1, 1, 0, 0, 0);
    local_end := make_timestamp(event_year, 1, 7, 0, 0, 0);
  elsif p_event_id = 'valentine_two_heartlights' then
    local_start := make_timestamp(event_year, 2, 12, 0, 0, 0);
    local_end := make_timestamp(event_year, 2, 17, 0, 0, 0);
  elsif p_event_id = 'sunwake_summer_sea' then
    local_start := make_timestamp(event_year, 7, 20, 0, 0, 0);
    local_end := make_timestamp(event_year, 7, 27, 0, 0, 0);
  elsif p_event_id = 'harvestmoon_moonlit_orchard' then
    local_start := make_timestamp(event_year, 9, 7, 0, 0, 0);
    local_end := make_timestamp(event_year, 9, 14, 0, 0, 0);
  elsif p_event_id = 'pride_every_color' then
    local_start := make_timestamp(event_year, 6, 1, 0, 0, 0);
    local_end := make_timestamp(event_year, 6, 8, 0, 0, 0);
  else
    return;
  end if;

  -- The first configured editions are a hard lower boundary.
  if (p_event_id in ('halloween_witchlight', 'christmas_winter_hearth',
        'new_year_first_dawn') and event_year < 2026)
     or (p_event_id in ('valentine_two_heartlights', 'pride_every_color',
        'sunwake_summer_sea', 'harvestmoon_moonlit_orchard')
        and event_year < 2027) then
    return;
  end if;
  occurrence_key := p_event_id || ':' || event_year::text;
  starts_at := local_start at time zone 'Europe/Amsterdam';
  ends_at := local_end at time zone 'Europe/Amsterdam';
  results_end_at := ends_at + interval '3 days';
  return next;
end
$$;

