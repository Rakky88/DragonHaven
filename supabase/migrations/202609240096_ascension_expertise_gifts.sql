-- Final evolution grants Expertise without consuming the previously available
-- training budget: +10 on a specialist path, or +5 on all three Mastery paths.
-- The trusted Dart state stores the one-time marker. SQL only widens the
-- canonical/social transport ceiling for the resulting server-owned values.
create or replace function private.dragon_expertise_maximum(
  p_stage text, p_evolution_path text, p_sinister boolean, p_focus text
) returns integer language sql immutable set search_path='' as $$
  select (case when coalesce(p_sinister,false) then 1100 else 950 end)
    + (case when p_stage='ascended' and p_evolution_path='mastery' then 50 else 0 end)
    + (case when p_stage='ascended' and p_evolution_path='mastery' then 15
            when p_stage='ascended' then 10 else 0 end)
    + 50 -- Only the transport ceiling; exact secret capacity stays private.
$$;
revoke all on function private.dragon_expertise_maximum(text,text,boolean,text)
  from public,anon,authenticated;

alter table public.player_dragons drop constraint if exists player_dragons_might_check;
alter table public.player_dragons add constraint player_dragons_might_check
  check (might between 0 and 1215);
alter table public.player_dragons drop constraint if exists player_dragons_arcana_check;
alter table public.player_dragons add constraint player_dragons_arcana_check
  check (arcana between 0 and 1215);
alter table public.player_dragons drop constraint if exists player_dragons_spirit_check;
alter table public.player_dragons add constraint player_dragons_spirit_check
  check (spirit between 0 and 1215);
alter table public.social_showcases drop constraint if exists social_showcases_favorite_might_cap_check;
alter table public.social_showcases add constraint social_showcases_favorite_might_cap_check
  check (favorite_dragon_might between 0 and 1215);
alter table public.social_showcases drop constraint if exists social_showcases_favorite_arcana_cap_check;
alter table public.social_showcases add constraint social_showcases_favorite_arcana_cap_check
  check (favorite_dragon_arcana between 0 and 1215);
alter table public.social_showcases drop constraint if exists social_showcases_favorite_spirit_cap_check;
alter table public.social_showcases add constraint social_showcases_favorite_spirit_cap_check
  check (favorite_dragon_spirit between 0 and 1215);
alter table public.seasonal_pair_adventures drop constraint if exists seasonal_pair_adventures_creator_might_check;
alter table public.seasonal_pair_adventures add constraint seasonal_pair_adventures_creator_might_check
  check (creator_might between 0 and 1215);
alter table public.seasonal_pair_adventures drop constraint if exists seasonal_pair_adventures_creator_arcana_check;
alter table public.seasonal_pair_adventures add constraint seasonal_pair_adventures_creator_arcana_check
  check (creator_arcana between 0 and 1215);
alter table public.seasonal_pair_adventures drop constraint if exists seasonal_pair_adventures_creator_spirit_check;
alter table public.seasonal_pair_adventures add constraint seasonal_pair_adventures_creator_spirit_check
  check (creator_spirit between 0 and 1215);
alter table public.seasonal_pair_adventures drop constraint if exists seasonal_pair_adventures_partner_might_check;
alter table public.seasonal_pair_adventures add constraint seasonal_pair_adventures_partner_might_check
  check (partner_might between 0 and 1215);
alter table public.seasonal_pair_adventures drop constraint if exists seasonal_pair_adventures_partner_arcana_check;
alter table public.seasonal_pair_adventures add constraint seasonal_pair_adventures_partner_arcana_check
  check (partner_arcana between 0 and 1215);
alter table public.seasonal_pair_adventures drop constraint if exists seasonal_pair_adventures_partner_spirit_check;
alter table public.seasonal_pair_adventures add constraint seasonal_pair_adventures_partner_spirit_check
  check (partner_spirit between 0 and 1215);

-- These revoked compatibility implementations are still called through the
-- current guarded seasonal wrappers, so their validation must match the new
-- transport ceiling as well.
create or replace function public.invite_seasonal_pair_adventure_v68(
  p_keeper_code text, p_dragon_id text, p_might integer,
  p_arcana integer, p_spirit integer
)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  current_user_id uuid := auth.uid(); target_id uuid; window_row record;
  occurrence text; is_preview boolean := false; new_id uuid;
begin
  if current_user_id is null then raise exception 'online_login_required'; end if;
  select p.user_id into target_id from public.profiles p
    where upper(p.keeper_code) = upper(trim(p_keeper_code));
  if target_id is null then raise exception 'keeper_not_found'; end if;
  if target_id = current_user_id then raise exception 'cannot_invite_self'; end if;
  if nullif(trim(p_dragon_id), '') is null or p_might not between 0 and 1215
    or p_arcana not between 0 and 1215 or p_spirit not between 0 and 1215 then
    raise exception 'seasonal_pair_invalid_dragon';
  end if;
  select * into window_row from public.seasonal_event_window(
    'valentine_two_heartlights', now());
  if exists(select 1 from public.list_my_seasonal_event_previews() p
    where p.event_id = 'valentine_two_heartlights') then
    is_preview := true;
    occurrence := 'preview:valentine_two_heartlights:' || current_user_id::text;
  elsif exists(select 1 from public.list_my_seasonal_event_dismissals() d where d.event_id = 'valentine_two_heartlights') then
    raise exception 'seasonal_adventure_unavailable';
  elsif exists(select 1 from public.list_my_seasonal_event_previews()) then
    raise exception 'seasonal_adventure_unavailable';
  elsif window_row.occurrence_key is not null and now() >= window_row.starts_at
    and now() < window_row.ends_at then
    occurrence := window_row.occurrence_key;
  else raise exception 'seasonal_adventure_unavailable'; end if;
  if exists(select 1 from public.seasonal_pair_occurrences o where
      o.event_id = 'valentine_two_heartlights' and o.occurrence_key = occurrence
      and o.user_id = current_user_id) then
    raise exception 'seasonal_adventure_already_completed';
  end if;
  if exists(select 1 from public.seasonal_pair_adventures a where
      a.occurrence_key = occurrence and a.creator_id = current_user_id
      and a.status in ('invited','accepted','running','reward_ready')) then
    raise exception 'seasonal_pair_already_active';
  end if;
  insert into public.seasonal_pair_adventures(
    occurrence_key, creator_id, partner_id, creator_dragon_id,
    creator_might, creator_arcana, creator_spirit, simulated
  ) values (occurrence, current_user_id, target_id, trim(p_dragon_id),
    p_might, p_arcana, p_spirit, is_preview) returning id into new_id;
  insert into public.social_notifications(user_id, kind, actor_id, entity_id)
    values(target_id, 'seasonal_pair_invite', current_user_id, new_id);
  return new_id;
end
$$;

create or replace function public.respond_seasonal_pair_adventure_v68(
  p_adventure_id uuid, p_accept boolean, p_dragon_id text default null,
  p_might integer default 0, p_arcana integer default 0,
  p_spirit integer default 0
)
returns void language plpgsql security definer set search_path = '' as $$
declare a public.seasonal_pair_adventures%rowtype;
begin
  select * into a from public.seasonal_pair_adventures x
    where x.id = p_adventure_id and x.partner_id = auth.uid() for update;
  if a.id is null then raise exception 'seasonal_pair_not_found'; end if;
  if a.status <> 'invited' then raise exception 'seasonal_pair_not_pending'; end if;
  if not p_accept then
    update public.seasonal_pair_adventures set status = 'declined'
      where id = p_adventure_id;
    return;
  end if;
  if nullif(trim(p_dragon_id), '') is null or p_might not between 0 and 1215
    or p_arcana not between 0 and 1215 or p_spirit not between 0 and 1215 then
    raise exception 'seasonal_pair_invalid_dragon';
  end if;
  update public.seasonal_pair_adventures set status = 'accepted',
    partner_dragon_id = trim(p_dragon_id), partner_might = p_might,
    partner_arcana = p_arcana, partner_spirit = p_spirit, accepted_at = now()
    where id = p_adventure_id;
  insert into public.social_notifications(user_id, kind, actor_id, entity_id)
    values(a.creator_id, 'seasonal_pair_accepted', auth.uid(), p_adventure_id);
end
$$;

revoke all on function public.invite_seasonal_pair_adventure_v68(text,text,integer,integer,integer)
  from public,anon,authenticated,service_role;
revoke all on function public.respond_seasonal_pair_adventure_v68(uuid,boolean,text,integer,integer,integer)
  from public,anon,authenticated,service_role;
