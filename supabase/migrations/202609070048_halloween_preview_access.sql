-- Publicly redeemable Halloween preview; other previews remain Keeper-scoped.
-- Existing clients already call this RPC. Preview rewards remain simulated.
create or replace function public.redeem_seasonal_event_preview(p_code text)
returns table (event_id text, expires_at timestamptz)
language plpgsql security definer set search_path = '' as $$
declare keeper uuid := auth.uid(); normalized_code text := upper(trim(coalesce(p_code, '')));
  target_event text; keeper_code text; preview_expiry timestamptz;
begin
  if keeper is null then raise exception 'online_login_required'; end if;
  if not exists(select 1 from auth.users u where u.id = keeper and u.email_confirmed_at is not null) then
    raise exception 'email_not_verified';
  end if;
  target_event := case normalized_code
    when 'HALLOWEENEVENT' then 'halloween_witchlight'
    when 'CHRISTMASEVENT' then 'christmas_winter_hearth'
    when 'NEWYEARSEVENT' then 'new_year_first_dawn'
    when 'VALENTINEEVENT' then 'valentine_two_heartlights'
    when 'PRIDEFESTEVENT' then 'pride_every_color'
    else null end;
  if target_event is null then raise exception 'seasonal_preview_invalid'; end if;
  select p.keeper_code into keeper_code from public.profiles p where p.user_id = keeper;
  if not found then raise exception 'profile_not_found'; end if;
  if target_event <> 'halloween_witchlight' and keeper_code is distinct from 'DH-17792DC5' then
    raise exception 'seasonal_preview_restricted';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(keeper::text, 0));
  select p.expires_at into preview_expiry from public.seasonal_event_previews p
    where p.user_id = keeper and p.event_id = target_event for update;
  -- Retrying an active preview must not extend the window or reset its ranking key.
  if not found or preview_expiry <= now() then
    preview_expiry := now() + interval '48 hours';
    insert into public.seasonal_event_previews(user_id, event_id, activated_at, expires_at)
      values(keeper, target_event, now(), preview_expiry)
      on conflict on constraint seasonal_event_previews_pkey do update
        set activated_at = excluded.activated_at, expires_at = excluded.expires_at;
  end if;
  return query select target_event, preview_expiry;
end;
$$;
revoke all on function public.redeem_seasonal_event_preview(text) from public, anon;
grant execute on function public.redeem_seasonal_event_preview(text) to authenticated;
