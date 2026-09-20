-- Keep the social profile in the same transaction as confirmed gameplay.
-- No runtime switches or existing player states are changed by this migration.
-- A repeated login must not attempt even a no-op wallet INSERT: its BEFORE
-- trigger correctly fences legacy writes before ON CONFLICT is evaluated.
create or replace function public.ensure_my_online_account()
returns void language plpgsql security definer set search_path='' as $$
declare keeper uuid:=auth.uid(); chosen_name text;
begin
  if keeper is null then raise exception 'online_login_required'; end if;
  select left(coalesce(nullif(btrim(raw_user_meta_data->>'display_name'),''),'Keeper'),24)
    into chosen_name from auth.users where id=keeper;
  if chosen_name is null then raise exception 'online_login_required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(keeper::text,0));
  if exists(select 1 from public.player_economy_authority where user_id=keeper and authority_mode='server') then
    if not exists(select 1 from public.profiles where user_id=keeper)
      or not exists(select 1 from public.player_wallets where user_id=keeper) then
      raise exception 'game_state_reconciliation_required';
    end if;
    return;
  end if;
  if not exists(select 1 from public.profiles where user_id=keeper) then
    insert into public.profiles(user_id,keeper_code,display_name) values(keeper,private.next_keeper_code(),chosen_name);
  end if;
  if not exists(select 1 from public.player_wallets where user_id=keeper) then
    insert into public.player_wallets(user_id) values(keeper);
  end if;
end $$;

create function private.project_canonical_profile_identity()
returns trigger language plpgsql security definer set search_path='' as $$
declare chosen_title text; chosen_portrait text; chosen_frame text; chosen_badge text;
begin
  if not new.is_prepared or new.authority_mode<>'server' then return new; end if;
  perform private.assert_game_service();
  chosen_title:=coalesce(new.state->>'selectedTitleId',new.state#>>'{ownedTitleIds,0}');
  chosen_portrait:=coalesce(new.state->>'selectedPortraitId',new.state#>>'{ownedPortraitIds,0}');
  chosen_frame:=new.state->>'selectedFrameId';
  chosen_badge:=new.state->>'selectedBadgeId';
  if chosen_title is null or chosen_portrait is null
    or not coalesce(new.state->'ownedTitleIds' ? chosen_title,false)
    or not coalesce(new.state->'ownedPortraitIds' ? chosen_portrait,false)
    or (chosen_frame is not null and not coalesce(new.state->'ownedFrameIds' ? chosen_frame,false))
    or (chosen_badge is not null and not coalesce(new.state->'ownedBadgeIds' ? chosen_badge,false))
  then raise exception 'game_social_projection_invalid'; end if;
  update public.profiles set
    display_name=coalesce(nullif(btrim(new.state->>'accountName'),''),display_name),
    title=chosen_title,portrait_key=chosen_portrait,frame_key=chosen_frame,badge_key=chosen_badge
    where user_id=new.owner_id and (display_name,title,portrait_key,frame_key,badge_key) is distinct from
      (coalesce(nullif(btrim(new.state->>'accountName'),''),display_name),chosen_title,chosen_portrait,chosen_frame,chosen_badge);
  update public.social_showcases set
    achievement_count=jsonb_array_length(coalesce(new.state->'achievements','[]'::jsonb)),
    dragon_count=(select count(*) from public.player_dragons where owner_id=new.owner_id and canonical_owned)
    where user_id=new.owner_id;
  return new;
end $$;
revoke all on function private.project_canonical_profile_identity() from public,anon,authenticated,service_role;
-- Run after the existing social projection has inserted its showcase row.
create trigger zz_canonical_profile_identity after insert or update on private.canonical_game_states
  for each row execute function private.project_canonical_profile_identity();

create function private.guard_canonical_profile_identity()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if coalesce(auth.role(),'')='service_role' or
    (new.display_name,new.title,new.portrait_key,new.frame_key,new.badge_key) is not distinct from
    (old.display_name,old.title,old.portrait_key,old.frame_key,old.badge_key) then return new; end if;
  perform pg_advisory_xact_lock(hashtextextended(old.user_id::text,0));
  if exists(select 1 from public.player_economy_authority where user_id=old.user_id and authority_mode='server') then
    raise exception 'economy_server_inventory_required';
  end if;
  return new;
end $$;
revoke all on function private.guard_canonical_profile_identity() from public,anon,authenticated,service_role;
create trigger canonical_profile_write before update on public.profiles
  for each row execute function private.guard_canonical_profile_identity();
