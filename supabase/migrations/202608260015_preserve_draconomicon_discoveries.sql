-- Draconomicon discoveries are permanent progression. Never let a stale or
-- partially restored client replace an existing social showcase with a lower
-- discovery count or a smaller set of form keys.

create or replace function private.preserve_social_showcase_discoveries()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_normal text[] := '{}'::text[];
  previous_prismatic text[] := '{}'::text[];
  previous_count integer := 0;
  known_lineage_count integer := 0;
begin
  if tg_op = 'UPDATE' then
    previous_normal := coalesce(old.discovered_forms, '{}'::text[]);
    previous_prismatic := coalesce(old.prismatic_forms, '{}'::text[]);
    previous_count := coalesce(old.discovered_dragon_count, 0);
  end if;

  select coalesce(array_agg(form_key order by form_key), '{}'::text[])
  into new.discovered_forms
  from (
    select distinct form_key
    from unnest(
      coalesce(new.discovered_forms, '{}'::text[]) || previous_normal
    ) as forms(form_key)
  ) preserved;

  select coalesce(array_agg(form_key order by form_key), '{}'::text[])
  into new.prismatic_forms
  from (
    select distinct form_key
    from unnest(
      coalesce(new.prismatic_forms, '{}'::text[]) || previous_prismatic
    ) as forms(form_key)
  ) preserved;

  select count(distinct lineage_id)::integer
  into known_lineage_count
  from (
    select lineage_id
    from public.discovered_lineages
    where owner_id = new.user_id
    union
    select split_part(form_key, ':', 1)
    from unnest(new.discovered_forms || new.prismatic_forms) forms(form_key)
  ) known;

  new.discovered_dragon_count := greatest(
    coalesce(new.discovered_dragon_count, 0),
    previous_count,
    known_lineage_count
  );
  return new;
end;
$$;

drop trigger if exists preserve_social_showcase_discoveries
  on public.social_showcases;
create trigger preserve_social_showcase_discoveries
before insert or update of discovered_dragon_count, discovered_forms,
  prismatic_forms on public.social_showcases
for each row execute function private.preserve_social_showcase_discoveries();

-- Re-run every existing showcase through the guard. This restores counts from
-- the normalized legacy discovery table without guessing normal/spectral forms.
update public.social_showcases
set discovered_dragon_count = discovered_dragon_count,
    discovered_forms = discovered_forms,
    prismatic_forms = prismatic_forms;

revoke all on function private.preserve_social_showcase_discoveries()
  from public, anon, authenticated;
