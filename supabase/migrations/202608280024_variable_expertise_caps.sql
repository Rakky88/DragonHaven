-- DragonHaven v0.04.09: form-specific Expertise ceilings. Broad table
-- constraints protect storage while security-definer functions enforce the
-- exact ceiling for each dragon form and focus.

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
      and p_evolution_path <> 'mastery'
      and p_evolution_path = p_focus then 400
    when coalesce(p_sinister, false) then 350
    when p_stage = 'ascended'
      and (p_evolution_path = 'mastery' or p_evolution_path = p_focus) then 350
    else 300
  end
$$;

alter table public.player_dragons
  drop constraint if exists player_dragons_might_check,
  drop constraint if exists player_dragons_arcana_check,
  drop constraint if exists player_dragons_spirit_check;
alter table public.player_dragons
  add constraint player_dragons_might_check check (might between 0 and 400),
  add constraint player_dragons_arcana_check check (arcana between 0 and 400),
  add constraint player_dragons_spirit_check check (spirit between 0 and 400);

alter table public.social_showcases
  drop constraint if exists social_showcases_favorite_might_cap_check,
  drop constraint if exists social_showcases_favorite_arcana_cap_check,
  drop constraint if exists social_showcases_favorite_spirit_cap_check;
alter table public.social_showcases
  add constraint social_showcases_favorite_might_cap_check check (
    favorite_dragon_might is null or favorite_dragon_might between 0 and 400
  ),
  add constraint social_showcases_favorite_arcana_cap_check check (
    favorite_dragon_arcana is null or favorite_dragon_arcana between 0 and 400
  ),
  add constraint social_showcases_favorite_spirit_cap_check check (
    favorite_dragon_spirit is null or favorite_dragon_spirit between 0 and 400
  );

create or replace function private.upsert_group_dragon(
  p_user_id uuid,
  p_dragon jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  result_id uuid;
  legacy_id text := nullif(left(p_dragon ->> 'client_id', 100), '');
  dragon_name text := left(nullif(btrim(p_dragon ->> 'name'), ''), 24);
  lineage text := p_dragon ->> 'lineage_id';
  dragon_stage text := p_dragon ->> 'stage';
  dragon_xp integer;
  dragon_might integer;
  dragon_arcana integer;
  dragon_spirit integer;
  path text := p_dragon ->> 'evolution_path';
  is_sinister boolean := coalesce((p_dragon ->> 'sinister')::boolean, false);
begin
  if p_user_id is null or jsonb_typeof(p_dragon) <> 'object'
    or legacy_id is null or dragon_name is null
    or lineage !~ '^[a-z0-9_]{1,64}$'
    or dragon_stage not in ('hatchling', 'wyrmling', 'ascended')
    or path not in ('might', 'arcana', 'spirit', 'mastery') then
    raise exception 'invalid_group_dragon';
  end if;
  dragon_xp := (p_dragon ->> 'xp')::integer;
  dragon_might := (p_dragon ->> 'might')::integer;
  dragon_arcana := (p_dragon ->> 'arcana')::integer;
  dragon_spirit := (p_dragon ->> 'spirit')::integer;
  if dragon_xp < 0
    or dragon_might not between 0 and private.dragon_expertise_maximum(
      dragon_stage, path, is_sinister, 'might')
    or dragon_arcana not between 0 and private.dragon_expertise_maximum(
      dragon_stage, path, is_sinister, 'arcana')
    or dragon_spirit not between 0 and private.dragon_expertise_maximum(
      dragon_stage, path, is_sinister, 'spirit') then
    raise exception 'invalid_group_dragon';
  end if;

  insert into public.player_dragons(
    owner_id, legacy_client_id, name, lineage_id, stage, xp,
    might, arcana, spirit, evolution_path, favorite, prismatic, sinister
  ) values (
    p_user_id, legacy_id, dragon_name, lineage, dragon_stage,
    least(dragon_xp, 100000000), dragon_might, dragon_arcana, dragon_spirit,
    path, false,
    coalesce((p_dragon ->> 'prismatic')::boolean, false), is_sinister
  )
  on conflict (owner_id, legacy_client_id) do update set
    name = excluded.name,
    lineage_id = excluded.lineage_id,
    stage = excluded.stage,
    xp = excluded.xp,
    might = excluded.might,
    arcana = excluded.arcana,
    spirit = excluded.spirit,
    evolution_path = excluded.evolution_path,
    prismatic = excluded.prismatic,
    sinister = excluded.sinister,
    updated_at = now()
  returning id into result_id;
  return result_id;
exception
  when invalid_text_representation or numeric_value_out_of_range
    or check_violation or not_null_violation then
    raise exception 'invalid_group_dragon';
end;
$$;

-- Retain the fully audited v23 showcase parser, then raise only its already
-- validated favorite-dragon scores to the new form-specific ceilings.
alter function public.publish_social_showcase(jsonb)
  rename to publish_social_showcase_v23;

create function public.publish_social_showcase(p_showcase jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  favorite jsonb := p_showcase -> 'favorite_dragon';
  favorite_stage text := favorite ->> 'stage';
  favorite_path text := favorite ->> 'evolution_path';
  favorite_sinister boolean := coalesce(
    (favorite ->> 'sinister')::boolean, false);
begin
  perform public.publish_social_showcase_v23(p_showcase);
  if jsonb_typeof(favorite) = 'object' then
    update public.social_showcases set
      favorite_dragon_might = greatest(0, least(
        private.dragon_expertise_maximum(
          favorite_stage, favorite_path, favorite_sinister, 'might'),
        (favorite ->> 'might')::integer
      )),
      favorite_dragon_arcana = greatest(0, least(
        private.dragon_expertise_maximum(
          favorite_stage, favorite_path, favorite_sinister, 'arcana'),
        (favorite ->> 'arcana')::integer
      )),
      favorite_dragon_spirit = greatest(0, least(
        private.dragon_expertise_maximum(
          favorite_stage, favorite_path, favorite_sinister, 'spirit'),
        (favorite ->> 'spirit')::integer
      )),
      updated_at = now()
    where user_id = current_user_id;
  end if;
exception
  when invalid_text_representation or numeric_value_out_of_range
    or check_violation or not_null_violation then
    raise exception 'invalid_profile';
end;
$$;

create or replace function public.acknowledge_group_adventure_reward(
  p_lobby_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  lobby public.group_adventure_lobbies%rowtype;
  participant public.group_adventure_participants%rowtype;
begin
  if current_user_id is null then raise exception 'group_login_required'; end if;
  select * into lobby from public.group_adventure_lobbies
  where id = p_lobby_id for update;
  if not found or lobby.status <> 'completed' then
    raise exception 'group_reward_not_ready';
  end if;
  select * into participant from public.group_adventure_participants
  where lobby_id = lobby.id and user_id = current_user_id for update;
  if not found then raise exception 'group_participant_not_found'; end if;
  if participant.reward_acknowledged_at is not null then return; end if;

  update public.player_dragons set
    xp = least(100000000, xp + lobby.xp),
    might = case when lobby.focus = 'might' then least(
      private.dragon_expertise_maximum(
        stage, evolution_path, sinister, 'might'),
      might + lobby.stat_points
    ) else might end,
    arcana = case when lobby.focus = 'arcana' then least(
      private.dragon_expertise_maximum(
        stage, evolution_path, sinister, 'arcana'),
      arcana + lobby.stat_points
    ) else arcana end,
    spirit = case when lobby.focus = 'spirit' then least(
      private.dragon_expertise_maximum(
        stage, evolution_path, sinister, 'spirit'),
      spirit + lobby.stat_points
    ) else spirit end,
    updated_at = now()
  where id = participant.dragon_id;

  insert into public.player_chests(owner_id, tier, quantity)
  values (current_user_id, lobby.chest_tier, 1)
  on conflict (owner_id, tier) do update set
    quantity = public.player_chests.quantity + 1,
    updated_at = now();
  update public.group_adventure_participants
  set reward_acknowledged_at = now()
  where lobby_id = lobby.id and user_id = current_user_id;
end;
$$;

revoke all on function private.dragon_expertise_maximum(text, text, boolean, text)
  from public, anon, authenticated;
revoke all on function private.upsert_group_dragon(uuid, jsonb)
  from public, anon, authenticated;
revoke all on function public.publish_social_showcase_v23(jsonb)
  from public, anon, authenticated;
revoke all on function public.publish_social_showcase(jsonb)
  from public, anon;
revoke all on function public.acknowledge_group_adventure_reward(uuid)
  from public, anon;
grant execute on function public.publish_social_showcase(jsonb)
  to authenticated;
grant execute on function public.acknowledge_group_adventure_reward(uuid)
  to authenticated;
