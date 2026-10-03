-- Keep public Keeper names suitable for every social surface. The trigger is
-- the final boundary so older or modified clients cannot bypass the policy.

create or replace function private.keeper_display_name_issue(value text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  trimmed text := btrim(coalesce(value, ''));
  folded text;
  words text;
  compact text;
begin
  if char_length(trimmed) not between 1 and 24 then
    return 'invalid_profile';
  end if;
  if trimmed ~ '[[:cntrl:]]' then
    return 'invalid_profile';
  end if;

  folded := translate(lower(trimmed), '0134578@$!', 'oieastbasi');
  folded := regexp_replace(folded, '[áàâäãå]', 'a', 'g');
  folded := regexp_replace(folded, '[éèêë]', 'e', 'g');
  folded := regexp_replace(folded, '[íìîï]', 'i', 'g');
  folded := regexp_replace(folded, '[óòôöõ]', 'o', 'g');
  folded := regexp_replace(folded, '[úùûü]', 'u', 'g');
  folded := regexp_replace(folded, 'ç', 'c', 'g');
  folded := regexp_replace(folded, 'ñ', 'n', 'g');
  words := ' ' || regexp_replace(folded, '[^a-z0-9]+', ' ', 'g') || ' ';
  compact := regexp_replace(folded, '[^a-z0-9]+', '', 'g');

  if exists (
    select 1
    from unnest(array[
      'bastard', 'bitch', 'cunt', 'debiel', 'dick', 'fagg', 'fuck',
      'godverdom', 'hoer', 'kanker', 'klootzak', 'mongool',
      'motherfucker', 'neuk', 'nigg', 'pussy', 'retard', 'shit', 'slet',
      'slut', 'tering', 'tyfus', 'whore'
    ]) as blocked(term)
    where strpos(compact, blocked.term) > 0
  )
  or words ~ ' (kut|lul) '
  or (strpos(compact, 'kut') > 0 and strpos(folded, 'kut') = 0)
  or (strpos(compact, 'lul') > 0 and strpos(folded, 'lul') = 0) then
    return 'keeper_name_inappropriate';
  end if;

  return null;
end;
$$;

create or replace function private.guard_keeper_display_name()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  issue text;
begin
  new.display_name := btrim(new.display_name);
  issue := private.keeper_display_name_issue(new.display_name);
  if issue is not null then
    raise exception using errcode = 'P0001', message = issue;
  end if;
  return new;
end;
$$;

drop trigger if exists guard_keeper_display_name_insert on public.profiles;
create trigger guard_keeper_display_name_insert
before insert on public.profiles
for each row execute function private.guard_keeper_display_name();

drop trigger if exists guard_keeper_display_name_update on public.profiles;
create trigger guard_keeper_display_name_update
before update of display_name on public.profiles
for each row execute function private.guard_keeper_display_name();

revoke all on function private.keeper_display_name_issue(text)
  from public, anon, authenticated, service_role;
revoke all on function private.guard_keeper_display_name()
  from public, anon, authenticated, service_role;
