-- Infernal Mastery combines the Infernal ceiling with Mastery's three-focus
-- behavior, so all three Expertise scores may reach 400. Public social
-- summaries count normal dragon forms rather than dragon families.

create or replace function private.dragon_expertise_maximum(
  p_stage text,
  p_evolution_path text,
  p_sinister boolean,
  p_focus text
)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case
    when coalesce(p_sinister, false)
      and p_stage = 'ascended'
      and (p_evolution_path = 'mastery' or p_evolution_path = p_focus)
      then 400
    when coalesce(p_sinister, false) then 350
    when p_stage = 'ascended'
      and (p_evolution_path = 'mastery' or p_evolution_path = p_focus)
      then 350
    else 300
  end
$$;

alter table public.social_showcases
  drop constraint if exists social_showcases_discovered_dragon_count_check;
alter table public.social_showcases
  add constraint social_showcases_discovered_dragon_count_check check (
    discovered_dragon_count between 0 and 300
  );

-- Keep the v24 parser and permanent form-union trigger, then derive the
-- summary from the preserved normal-form array. Empty legacy arrays retain
-- their prior family-based fallback until that keeper publishes current data.
alter function public.publish_social_showcase(jsonb)
  rename to publish_social_showcase_v24;

create function public.publish_social_showcase(p_showcase jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  normal_form_count integer;
begin
  perform public.publish_social_showcase_v24(p_showcase);
  select cardinality(discovered_forms)
  into normal_form_count
  from public.social_showcases
  where user_id = current_user_id;

  if coalesce(normal_form_count, 0) > 0 then
    update public.social_showcases
    set discovered_dragon_count = normal_form_count,
        updated_at = now()
    where user_id = current_user_id;
  end if;
exception
  when invalid_text_representation or numeric_value_out_of_range
    or check_violation or not_null_violation then
    raise exception 'invalid_profile';
end;
$$;

-- Repair existing summaries whenever preserved form data is already present.
update public.social_showcases
set discovered_dragon_count = cardinality(discovered_forms),
    updated_at = now()
where cardinality(discovered_forms) > discovered_dragon_count;

revoke all on function private.dragon_expertise_maximum(
  text, text, boolean, text
) from public, anon, authenticated;
revoke all on function public.publish_social_showcase_v24(jsonb)
  from public, anon, authenticated;
revoke all on function public.publish_social_showcase(jsonb)
  from public, anon;
grant execute on function public.publish_social_showcase(jsonb)
  to authenticated;
