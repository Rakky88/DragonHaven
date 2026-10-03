-- Expand the account-name policy while preserving the trigger installed by
-- migration 107. Terms are matched after punctuation and common substitutions
-- are removed, including when they are embedded inside a longer name.

create or replace function private.keeper_display_name_issue(value text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  trimmed text := btrim(coalesce(value, ''));
  folded text;
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
  compact := regexp_replace(folded, '[^a-z0-9]+', '', 'g');

  if exists (
    select 1
    from unnest(array[
      'bastard', 'bitch', 'bollock', 'cunt', 'debiel', 'dick', 'douchebag',
      'eikel', 'fagg', 'fuck', 'godverdom', 'hoer', 'idioot', 'kanker',
      'klere', 'klote', 'klotzak', 'klootzak', 'kut', 'lul', 'mongool',
      'motherfucker', 'neuk', 'nigg', 'pussy', 'retard', 'shit', 'slet',
      'slut', 'sukkel', 'teef', 'tering', 'trut', 'twat', 'tyfus', 'wanker',
      'whore', 'wijf'
    ]) as blocked(term)
    where strpos(compact, blocked.term) > 0
  ) then
    return 'keeper_name_inappropriate';
  end if;

  return null;
end;
$$;

revoke all on function private.keeper_display_name_issue(text)
  from public, anon, authenticated, service_role;
